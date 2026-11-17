"""Local generative engine for HomeStyle AI.

Runs a real text-to-image model on the local NVIDIA GPU, so the AI section
does not depend on any external/free service (no 502, no rate limits).
"""

import os
import threading
import traceback

MODEL_ID = os.environ.get("AI_LOCAL_MODEL", "stabilityai/sd-turbo")

_pipe = None
_load_error = None
_lock = threading.Lock()


def cuda_ready() -> bool:
    try:
        import torch

        return bool(torch.cuda.is_available())
    except Exception:
        return False


def _load():
    global _pipe, _load_error

    if _pipe is not None:
        return _pipe

    import torch
    from diffusers import AutoPipelineForText2Image

    print(f"[local-ai] loading model: {MODEL_ID}", flush=True)
    pipe = AutoPipelineForText2Image.from_pretrained(
        MODEL_ID,
        torch_dtype=torch.float16,
        variant="fp16",
        safety_checker=None,
        requires_safety_checker=False,
    )
    pipe = pipe.to("cuda")
    pipe.enable_attention_slicing()

    try:
        pipe.enable_vae_slicing()
    except Exception:
        pass

    try:
        pipe.enable_vae_tiling()
    except Exception:
        pass

    _pipe = pipe
    print("[local-ai] model ready on GPU", flush=True)
    return pipe


def warmup() -> None:
    try:
        generate("a clean modern living room", steps=1, width=512, height=512, seed=7)
    except Exception:
        traceback.print_exc()


def generate(
    prompt: str,
    steps: int = 4,
    width: int = 768,
    height: int = 512,
    seed: int | None = None,
):
    """Return a PIL image generated locally on the GPU."""
    import torch

    with _lock:
        pipe = _load()

        generator = None
        if seed is not None:
            generator = torch.Generator(device="cuda").manual_seed(int(seed))

        # sd-turbo is a distilled model: guidance must be 0 and steps are few.
        guidance = 0.0 if steps <= 4 else 7.5

        sizes = [(width, height), (512, 512), (448, 448)]
        last_error = None

        for w, h in sizes:
            try:
                result = pipe(
                    prompt=prompt,
                    num_inference_steps=int(steps),
                    width=int(w),
                    height=int(h),
                    guidance_scale=guidance,
                    generator=generator,
                )
                return result.images[0]
            except torch.cuda.OutOfMemoryError as exc:
                last_error = exc
                try:
                    torch.cuda.empty_cache()
                except Exception:
                    pass
                print(f"[local-ai] OOM at {w}x{h}, retrying smaller", flush=True)

        raise last_error

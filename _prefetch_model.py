import time
from huggingface_hub import snapshot_download

ALLOW = [
    "model_index.json",
    "scheduler/*",
    "tokenizer/*",
    "text_encoder/config.json",
    "text_encoder/model.fp16.safetensors",
    "unet/config.json",
    "unet/diffusion_pytorch_model.fp16.safetensors",
    "vae/config.json",
    "vae/diffusion_pytorch_model.fp16.safetensors",
]

t0 = time.time()
print("PREFETCH BEGIN", flush=True)
try:
    path = snapshot_download(
        "stabilityai/sd-turbo",
        allow_patterns=ALLOW,
        resume_download=True,
    )
    print("PREFETCH OK " + path, flush=True)
except Exception as exc:
    print("PREFETCH FAIL " + repr(exc), flush=True)
    raise SystemExit(1)
print("PREFETCH SECONDS %.1f" % (time.time() - t0), flush=True)

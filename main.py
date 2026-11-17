import asyncio
import os
import random
import re
import shutil
import time
import traceback
import urllib.parse
import uuid

import httpx
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

app = FastAPI(title="HomeStyle AI Room Designer API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

GENERATED_DIR = os.path.join(os.path.dirname(__file__), "generated")
os.makedirs(GENERATED_DIR, exist_ok=True)

SAVE_DIR = r"C:\xampp\htdocs\homestyle_api\images\AI Images"
os.makedirs(SAVE_DIR, exist_ok=True)

app.mount("/generated", StaticFiles(directory=GENERATED_DIR), name="generated")

ROOM_STYLES = {
    "Kitchen": "a modern stylish kitchen",
    "Bedroom": "a cozy elegant bedroom",
    "Living Room": "a luxurious warm living room",
    "Bathroom": "a clean luxurious bathroom",
}

PROMPT_TEMPLATE = (
    "{style}, {description}, professional interior design photography, "
    "high detail, warm lighting, photorealistic render"
)


class GenerateRequest(BaseModel):
    room: str = "Living Room"
    description: str = "modern and cozy"
    style: str | None = None


class SaveDesignRequest(BaseModel):
    filename: str
    name: str
    price: float | None = None


@app.post("/save-design")
def save_design(req: SaveDesignRequest):
    source_name = os.path.basename(req.filename)
    source_path = os.path.join(GENERATED_DIR, source_name)

    if not os.path.isfile(source_path) or not source_name.endswith(".png"):
        return JSONResponse(
            status_code=404,
            content={
                "success": False,
                "message": "Generated image not found on the server.",
            },
        )

    clean_name = re.sub(r'[\\/:*?"<>|]', "", req.name).strip()

    if not clean_name:
        clean_name = "AI Design"

    # الأسماء الطويلة تنقص لمدة مقبولة لاسم الملف
    if len(clean_name) > 40:
        clean_name = clean_name[:40].strip()

    price = req.price if req.price is not None and req.price > 0 else None

    base_stem = f"{int(price)}_{clean_name}" if price else clean_name
    target_name = f"{base_stem}.png"

    # نتأكد أن الملف ما يتكرر، وإذا تكرر نضيف رقم
    counter = 2
    while os.path.exists(os.path.join(SAVE_DIR, target_name)):
        target_name = f"{base_stem} ({counter}).png"
        counter += 1

    target_path = os.path.join(SAVE_DIR, target_name)

    try:
        shutil.copy2(source_path, target_path)
    except Exception:
        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "message": "Could not save the design into the AI Images folder.",
            },
        )

    encoded = urllib.parse.quote(target_name)

    return {
        "success": True,
        "message": "Design added to the AI Images section.",
        "image_url": (
            "http://localhost/homestyle_api/images/"
            f"{urllib.parse.quote('AI Images')}/{encoded}"
        ),
    }


@app.get("/health")
def health():
    return {"status": "ok", "service": "HomeStyle AI Room Designer"}


def build_prompt(req: GenerateRequest) -> str:
    """Customer's own words are the core of the prompt."""
    customer = (req.description or "").strip()

    parts = []

    if req.style:
        parts.append(f"{req.style.strip()} interior design style,")

    parts.append(ROOM_STYLES.get(req.room, "an elegant room") + ",")

    if customer:
        parts.append(customer + ",")

    parts.append(
        "professional interior design photography, high detail, "
        "warm lighting, photorealistic render, no people"
    )

    return " ".join(parts)


def _generate_local(prompt: str, filename: str) -> str | None:
    """Try the on-GPU model first. Returns URL or None."""
    try:
        import local_engine
    except Exception:
        return None

    if not local_engine.cuda_ready():
        return None

    try:
        image = local_engine.generate(
            prompt=prompt,
            steps=4,
            width=768,
            height=512,
            seed=random.randint(1, 1000000),
        )
    except Exception:
        traceback.print_exc()
        return None

    filepath = os.path.join(GENERATED_DIR, filename)
    image.save(filepath, format="PNG")

    host = os.environ.get("AI_HOST", "localhost")
    port = os.environ.get("AI_PORT", "8000")

    return f"http://{host}:{port}/generated/{filename}"


def _generate_cloud(prompt: str, filename: str) -> str | None:
    """Fallback: external generative service."""
    encoded = urllib.parse.quote(prompt)
    seed = random.randint(1, 1000000)

    image_url = (
        f"https://image.pollinations.ai/prompt/{encoded}"
        f"?width=1024&height=1024&seed={seed}&nologo=true&enhance=true"
    )

    image_bytes = asyncio.run(_fetch_image(image_url))

    if image_bytes is None:
        return None

    filepath = os.path.join(GENERATED_DIR, filename)
    with open(filepath, "wb") as f:
        f.write(image_bytes)

    host = os.environ.get("AI_HOST", "localhost")
    port = os.environ.get("AI_PORT", "8000")

    return f"http://{host}:{port}/generated/{filename}"


@app.post("/generate")
def generate(req: GenerateRequest):
    prompt = build_prompt(req)

    filename = f"{uuid.uuid4().hex}.png"

    image_url = _generate_local(prompt, filename)
    engine = "local"

    if image_url is None:
        image_url = _generate_cloud(prompt, filename)
        engine = "cloud"

    if image_url is None:
        return JSONResponse(
            status_code=502,
            content={
                "success": False,
                "message": "AI image service is not responding. Please try again.",
            },
        )

    return {
        "success": True,
        "image_url": image_url,
        "prompt": prompt,
        "room": req.room,
        "engine": engine,
    }



async def _fetch_image(url: str, timeout: int = 120) -> bytes | None:
    timeout_obj = httpx.Timeout(timeout, connect=20.0)
    attempt = 0

    while attempt < 10:
        try:
            async with httpx.AsyncClient(timeout=timeout_obj, follow_redirects=True) as client:
                response = await client.get(url, headers={"User-Agent": "HomeStyleAI/1.0"})

            content_type = response.headers.get("content-type", "")

            if response.status_code == 200 and content_type.startswith("image"):
                return response.content

            if response.status_code in (404, 429, 500, 502, 503):
                attempt += 1
                await asyncio_sleep(3.0)
                continue

            attempt += 1
            await asyncio_sleep(2.0)
        except httpx.HTTPError:
            attempt += 1
            await asyncio_sleep(3.0)

    return None


async def asyncio_sleep(seconds: float):
    import asyncio

    await asyncio.sleep(seconds)
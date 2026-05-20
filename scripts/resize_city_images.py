#!/usr/bin/env python3
"""
Downloads all city images from Supabase, resizes them to max 1400px wide
at 82% JPEG quality, and re-uploads them in place.

Usage:
    export SUPABASE_SERVICE_ROLE_KEY="your-service-role-key"
    python3 scripts/resize_city_images.py
"""

import os
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

SUPABASE_URL = "https://tyttgzrqntyzehfufeqx.supabase.co"
CDN_BASE = "https://images.sidequesttravel.co/storage/v1/object/public"
MAX_WIDTH = 1400
JPEG_QUALITY = 82

# All 69 city image URLs from the database
IMAGE_URLS = [
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/andorra.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/athens.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//rome.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/vienna.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/zagreb.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/sintra.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/naples.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//reykjavik.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//granada.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/split.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//segovia.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//venice.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/istanbul.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/thessaloniki.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//lisbon.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/nice.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/nazare.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//dubrovnik.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/bruges.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/interlaken.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//tenerife.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//zurich.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/girona.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/bristol.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/krakow.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/pompeii.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/toulouse.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/warsaw.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/rotterdam.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/berlin.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/budapest.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//munich.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/stockholm.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//eiffel-tower.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//san-sebastian.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//seville.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/rovinj.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/bergen.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/galway.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/lucerne.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//madrid.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//marrakech.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//toledo.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/oslo.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/florence.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/lagos.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/mykonos.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/mallorca.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//copenhagen.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/frankfurt.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/milan.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/geneva.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//chur.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//amsterdam.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/santorini.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/edinburgh.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//barcelona.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//lyon.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//valencia.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/hamburg.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//prague.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/dublin.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/cesky-krumlov.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/brussels.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/orvieto.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images//ibiza.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/porto.jpg",
    "https://tyttgzrqntyzehfufeqx.supabase.co/storage/v1/object/public/city-images/london.jpg",
]

def get_storage_path(url: str) -> str:
    """Extract the storage path after /object/public/ from a Supabase URL."""
    marker = "/object/public/"
    idx = url.find(marker)
    return url[idx + len(marker):]  # e.g. "city-images//rome.jpg"

def get_pixel_width(path: str) -> int:
    result = subprocess.run(
        ["sips", "-g", "pixelWidth", path],
        capture_output=True, text=True
    )
    for line in result.stdout.splitlines():
        if "pixelWidth" in line:
            return int(line.strip().split()[-1])
    return 0

def resize_image(src: str, dst: str, max_width: int, quality: int):
    width = get_pixel_width(src)
    if width > max_width:
        subprocess.run(
            ["sips", "-Z", str(max_width), "--setProperty", "formatOptions", str(quality),
             src, "--out", dst],
            capture_output=True
        )
    else:
        # Still re-compress to reduce quality if needed
        subprocess.run(
            ["sips", "--setProperty", "formatOptions", str(quality),
             src, "--out", dst],
            capture_output=True
        )

def upload_image(local_path: str, storage_path: str, service_key: str) -> int:
    """Upload a file to Supabase storage, replacing the existing file."""
    upload_url = f"{SUPABASE_URL}/storage/v1/object/{storage_path}"
    result = subprocess.run(
        [
            "curl", "-s", "-o", "/dev/null", "-w", "%{http_code}",
            "-X", "POST",
            "-H", f"Authorization: Bearer {service_key}",
            "-H", "Content-Type: image/jpeg",
            "-H", "x-upsert: true",
            "--data-binary", f"@{local_path}",
            upload_url,
        ],
        capture_output=True, text=True
    )
    return int(result.stdout.strip())

def main():
    service_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")
    if not service_key:
        print("Error: set SUPABASE_SERVICE_ROLE_KEY environment variable")
        sys.exit(1)

    success, failed, skipped = 0, 0, 0

    with tempfile.TemporaryDirectory() as tmpdir:
        for url in IMAGE_URLS:
            storage_path = get_storage_path(url)
            filename = Path(storage_path).name
            original = os.path.join(tmpdir, f"orig_{filename}")
            resized = os.path.join(tmpdir, f"resized_{filename}")

            # Download directly from Supabase origin
            try:
                urllib.request.urlretrieve(url, original)
            except Exception as e:
                print(f"  SKIP  {filename} (download failed: {e})")
                skipped += 1
                continue

            orig_size = os.path.getsize(original)

            # Resize
            resize_image(original, resized, MAX_WIDTH, JPEG_QUALITY)
            new_size = os.path.getsize(resized)
            saving = (1 - new_size / orig_size) * 100

            # Upload
            status = upload_image(resized, storage_path, service_key)
            if status in (200, 201):
                print(f"  OK    {filename}  {orig_size//1024}KB → {new_size//1024}KB  ({saving:.0f}% smaller)")
                success += 1
            else:
                print(f"  FAIL  {filename}  HTTP {status}")
                failed += 1

    print(f"\nDone: {success} resized, {failed} failed, {skipped} skipped")

if __name__ == "__main__":
    main()

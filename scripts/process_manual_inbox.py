#!/usr/bin/env python
"""
process_manual_inbox.py
Proses PNG dari manual_inbox: resize -> upload -> registry update -> generate lua.
Usage: python scripts\process_manual_inbox.py [--dry-run]
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from PIL import Image

DRY_RUN = False
INBOX_DIR = Path("assets/generated/images/manual_inbox")
DONE_DIR = Path("assets/generated/images/manual_inbox_done")
REGISTRY = Path("assets/manifest/ASSET_ID_REGISTRY.json")
TARGET_SIZE = (512, 512)
OWNER_USER_ID = os.environ.get("ROBLOX_OWNER_USER_ID", "8603977492")
UPLOAD_ENDPOINT = "https://apis.roblox.com/assets/v1/assets"
OPERATIONS_ENDPOINT = "https://apis.roblox.com/assets/v1/operations/{operation_id}"


class CredentialError(RuntimeError):
    """Raised when Open Cloud credentials are missing or rejected."""


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def load_registry() -> dict[str, Any]:
    with REGISTRY.open(encoding="utf-8") as handle:
        return json.load(handle)


def save_registry(data: dict[str, Any]) -> None:
    REGISTRY.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def find_registry_entry(reg: dict[str, Any], key: str) -> tuple[str | None, dict[str, Any] | None]:
    entries = reg.get("images", {})
    if key in entries:
        return "images", entries[key]
    return None, None


def resize_image(src_path: Path, target_size: tuple[int, int] = TARGET_SIZE) -> Image.Image:
    img = Image.open(src_path).convert("RGBA")
    img.thumbnail(target_size, Image.LANCZOS)
    canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
    offset = (
        (target_size[0] - img.width) // 2,
        (target_size[1] - img.height) // 2,
    )
    canvas.paste(img, offset)
    return canvas


def resolve_asset_id(payload: dict[str, Any] | None) -> str | None:
    if not payload:
        return None
    asset_id = payload.get("assetId")
    if asset_id:
        return str(asset_id)
    response = payload.get("response")
    if isinstance(response, dict):
        asset_id = response.get("assetId")
        if asset_id:
            return str(asset_id)
        path = response.get("path")
        if isinstance(path, str) and "assets/" in path:
            return path.rsplit("/", 1)[-1]
    path = payload.get("path")
    if isinstance(path, str) and "assets/" in path:
        return path.rsplit("/", 1)[-1]
    return None


def upload_image_to_open_cloud(png_path: Path, asset_name: str) -> str | None:
    try:
        import requests
    except ImportError as exc:
        raise RuntimeError("requests is required for upload flow") from exc

    api_key = (os.environ.get("ROBLOX_OPEN_CLOUD_API_KEY") or os.environ.get("ROBLOX_API_KEY") or "").strip()
    if not api_key:
        raise CredentialError("ROBLOX_OPEN_CLOUD_API_KEY not set")

    request_body = {
        "assetType": "Image",
        "displayName": asset_name,
        "description": f"PASRAHPHOBIA manual inbox asset: {asset_name}",
        "creationContext": {
            "creator": {
                "userId": OWNER_USER_ID,
            }
        },
    }

    with png_path.open("rb") as handle:
        files = {
            "request": (None, json.dumps(request_body, separators=(",", ":")), "application/json"),
            "fileContent": (png_path.name, handle, "image/png"),
        }
        response = requests.post(
            UPLOAD_ENDPOINT,
            headers={"x-api-key": api_key},
            files=files,
            timeout=120,
        )

    if response.status_code in (401, 403):
        raise CredentialError(f"upload rejected with status {response.status_code}: {response.text[:300]}")

    response.raise_for_status()
    payload = response.json()
    if payload.get("errors"):
        error_blob = json.dumps(payload["errors"], ensure_ascii=False)
        if "permission" in error_blob.lower() or "auth" in error_blob.lower():
            raise CredentialError(f"upload rejected by API: {error_blob[:300]}")
        raise RuntimeError(f"upload create failed: {error_blob[:300]}")

    operation_id = payload.get("operationId")
    if not operation_id and payload.get("path"):
        operation_id = str(payload["path"]).replace("operations/", "", 1)
    if not operation_id:
        raise RuntimeError(f"operation ID missing in create response: {payload}")

    for _ in range(120):
        poll = requests.get(
            OPERATIONS_ENDPOINT.format(operation_id=operation_id),
            headers={"x-api-key": api_key},
            timeout=60,
        )
        if poll.status_code in (401, 403):
            raise CredentialError(f"poll rejected with status {poll.status_code}: {poll.text[:300]}")
        poll.raise_for_status()
        op = poll.json()
        if op.get("done") is True:
            if op.get("error"):
                raise RuntimeError(f"upload operation failed: {json.dumps(op['error'], ensure_ascii=False)[:300]}")
            return resolve_asset_id(op)
        time.sleep(3)

    raise RuntimeError(f"operation poll timeout for {asset_name} ({operation_id})")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    global DRY_RUN
    DRY_RUN = args.dry_run

    INBOX_DIR.mkdir(parents=True, exist_ok=True)
    DONE_DIR.mkdir(parents=True, exist_ok=True)

    png_files = sorted(INBOX_DIR.glob("*.png"))
    if not png_files:
        print("Inbox kosong. Tidak ada file untuk diproses.")
        return 0

    print(f"Ditemukan {len(png_files)} file di inbox:")
    for item in png_files:
        print(f"  {item.name}")

    reg = load_registry()
    processed = 0
    failed = 0

    for png_path in png_files:
        key = png_path.stem
        print(f"\n--- Processing: {key} ---")

        _, entry = find_registry_entry(reg, key)
        if entry is None:
            print(f"  [WARN] Key '{key}' tidak ditemukan di registry. Skip.")
            failed += 1
            continue

        try:
            resized = resize_image(png_path)
        except Exception as exc:
            print(f"  [ERROR] Resize gagal: {exc}")
            failed += 1
            continue

        filename = entry.get("filename") or f"assets/generated/images/{key}.png"
        out_path = Path(filename)
        out_path.parent.mkdir(parents=True, exist_ok=True)

        if DRY_RUN:
            print(f"  [DRY RUN] Would save resized: {out_path}")
        else:
            resized.save(out_path, "PNG")
            print(f"  Saved resized: {out_path}")

        try:
            if DRY_RUN:
                asset_id = "DRY_RUN_ID"
                print(f"  [DRY RUN] Would upload via {UPLOAD_ENDPOINT}")
            else:
                print("  Uploading to Roblox Open Cloud...")
                asset_id = upload_image_to_open_cloud(out_path, key)
        except CredentialError as exc:
            print(f"  [FATAL] Credential failure: {exc}")
            print("  Batch dihentikan. File inbox dipertahankan.")
            return 2
        except Exception as exc:
            print(f"  [ERROR] Upload exception: {exc}")
            failed += 1
            continue

        if not asset_id:
            print(f"  [FAIL] Upload gagal untuk {key}. File tetap di inbox.")
            failed += 1
            continue

        print(f"  Uploaded: rbxassetid://{asset_id}")
        image_entry = reg["images"][key]
        image_entry["status"] = "CONFIRMED"
        image_entry["asset_id"] = int(asset_id) if str(asset_id).isdigit() else asset_id
        image_entry["rbx_asset_id"] = f"rbxassetid://{asset_id}"
        image_entry["roblox_asset_id"] = f"rbxassetid://{asset_id}"
        image_entry["uploaded_at"] = now_iso()

        if DRY_RUN:
            print("  [DRY RUN] Would update registry and copy original to done folder.")
        else:
            save_registry(reg)
            done_path = DONE_DIR / png_path.name
            shutil.copy2(png_path, done_path)
            print(f"  Copied original to done: {done_path}")

        processed += 1

    print(f"\n=== SELESAI: {processed} uploaded, {failed} failed ===")

    if processed > 0 and not DRY_RUN:
        print("\nRegenerating AssetIdConfig.lua...")
        os.system("python tools\\asset_id_manager\\registry_manager.py --sync")
        os.system("python tools\\asset_id_manager\\registry_manager.py --audit")
        os.system("python tools\\asset_id_manager\\registry_manager.py --generate-lua")
        print("AssetIdConfig.lua regenerated.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

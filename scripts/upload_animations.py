import json
import os
from pathlib import Path

import requests

API_KEY = os.environ.get("ROBLOX_API_KEY") or os.environ.get("ROBLOX_OPEN_CLOUD_API_KEY")
UNIVERSE_ID = os.environ.get("ROBLOX_UNIVERSE_ID", "10138560838")
REGISTRY = Path("assets/manifest/ASSET_ID_REGISTRY.json")

ANIMATIONS = [
    {
        "key": "emote_pasrah_bow",
        "file": "assets/animations/rbxanim/emote_pasrah_bow_emote.rbxanim",
        "name": "PASRAHPHOBIA_emote_pasrah_bow",
        "description": "PASRAHPHOBIA S1 emote - Pasrah Bow",
    },
    {
        "key": "emote_pasrah_ascend",
        "file": "assets/animations/rbxanim/emote_pasrah_ascend_emote.rbxanim",
        "name": "PASRAHPHOBIA_emote_pasrah_ascend",
        "description": "PASRAHPHOBIA S1 emote - Pasrah Ascend",
    },
]


def load_registry() -> dict:
    return json.loads(REGISTRY.read_text(encoding="utf-8"))


def save_registry(reg: dict) -> None:
    REGISTRY.write_text(json.dumps(reg, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def already_confirmed(reg: dict, key: str) -> tuple[bool, str]:
    entry = (reg.get("animations") or {}).get(key) or {}
    status = str(entry.get("status") or "").upper()
    asset_id = str(entry.get("asset_id") or "").strip()
    return status == "CONFIRMED" and asset_id != "", asset_id


def upload_animation(anim_info: dict) -> str | None:
    if not API_KEY:
        print("ERROR: No API key set.")
        return None

    file_path = Path(anim_info["file"])
    if not file_path.exists():
        print(f"ERROR: missing file {file_path}")
        return None

    print(f"\nUploading: {anim_info['name']}")
    body = file_path.read_bytes()

    files = {
        "fileContent": (anim_info["name"] + ".rbxmx", body, "application/xml"),
    }
    data = {
        "request": json.dumps(
            {
                "assetType": "Animation",
                "displayName": anim_info["name"],
                "description": anim_info["description"],
                "creationContext": {"creator": {"userId": "1"}},
            }
        )
    }

    url = "https://apis.roblox.com/assets/v1/assets"
    resp = requests.post(url, headers={"x-api-key": API_KEY}, files=files, data=data, timeout=60)
    print(f"  Status: {resp.status_code}")
    print(f"  Response: {resp.text[:500]}")
    if resp.status_code in (200, 201):
        payload = resp.json()
        return str(payload.get("assetId") or payload.get("id") or "").strip() or None
    return None


def update_registry(reg: dict, key: str, asset_id: str) -> None:
    reg.setdefault("animations", {}).setdefault(key, {})
    reg["animations"][key]["status"] = "CONFIRMED"
    reg["animations"][key]["asset_id"] = int(asset_id)
    reg["animations"][key]["rbx_asset_id"] = f"rbxassetid://{asset_id}"
    source_files = reg["animations"][key].setdefault("source_files", {})
    source_files["roblox_animation_id"] = int(asset_id)


def main() -> int:
    print(f"UniverseId: {UNIVERSE_ID}")
    reg = load_registry()
    dirty = False

    for anim in ANIMATIONS:
        is_ok, existing = already_confirmed(reg, anim["key"])
        if is_ok:
            print(f"SKIP {anim['key']}: already CONFIRMED with asset_id={existing}")
            continue

        asset_id = upload_animation(anim)
        if not asset_id:
            print(f"FAILED: {anim['key']} — upload returned no ID")
            return 1
        update_registry(reg, anim["key"], asset_id)
        dirty = True
        print(f"Registry updated: {anim['key']} = {asset_id}")

    if dirty:
        save_registry(reg)
        print("Registry file written.")
    else:
        print("No registry changes needed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

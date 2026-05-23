=======================================================================
PASRAHPHOBIA — AGENT_07: IMPORTER_AGENT
ROLE: AUTOMATED ASSET IMPORTER — ROBLOX OPEN CLOUD API
VERSION: 1.0
GAME: PASRAHPHOBIA (Universe ID: [ISI_UNIVERSE_ID])
AUTHORITY: Mengotomasi upload & import semua asset ke Roblox tanpa
           manual drag-drop — via Roblox Open Cloud REST API
DEPENDS ON: AGENT_06 output + ASSET_MANIFEST.json dari ORCHESTRATOR
=======================================================================

## WORKFLOW OVERRIDE (2026-05-22)

- Importer menerima PNG/JSON dari Google Nano Banana `scripts/generate_visual.py` untuk image/UI/billboard/reference assets.
- Importer menerima mesh/model dari prioritas Roblox Studio MCP, Cube3D local, Tripo3D jika diminta, lalu Blender fallback.
- Paket Python literal `open-cloud-roblox-api-wrapper` tidak tersedia di PyPI saat setup; gunakan `rblx-open-cloud` atau request resmi Roblox Open Cloud via `requests`.
- Sebelum upload/import/publish, wajib cek branch/worktree, active Rojo `default.project.json`, Creator/Universe/Place target, dan jangan memakai worktree lain.

## IDENTITAS
Kamu adalah IMPORTER_AGENT — agen yang menghilangkan bottleneck manual
upload ke Roblox. Kamu menggunakan Roblox Open Cloud API untuk:
1. Upload image/audio/model asset secara programatik
2. Update DataStore dengan config terbaru (jika diperlukan)
3. Publish place update ke Roblox setelah integrasi selesai
4. Sync ASSET_MANIFEST.json dengan AssetId hasil upload otomatis

**Kamu menerima dari:**
- AGENT_01: assets/icons/ dan assets/concept/ (PNG files)
- AGENT_02: assets/models/ (FBX / rbxm files)
- AGENT_05: assets/audio/ (OGG files)
- AGENT_04: assets/ui/ (PNG files)
- ORCHESTRATOR: ASSET_MANIFEST.json (sebagai checklist upload)

**Kamu memberi ke:**
- AGENT_06: AssetId manifest (semua upload sudah ada ID-nya)
- ASSET_ID_MANAGER (AGENT_09): Raw AssetId baru untuk dicatat
- ORCHESTRATOR: Import report + updated ASSET_MANIFEST.json

=======================================================================
## SETUP & AUTENTIKASI
=======================================================================

### API Key Setup
```bash
# API Key dibuat di: https://create.roblox.com/credentials
# Permissions yang WAJIB aktif:
#   - Assets: Read + Write (untuk upload mesh, image, audio)
#   - Place Publishing: Write (untuk publish update)
#   - DataStore: Read + Write (untuk update config live)
#   - Universe: Read

# Simpan API key di environment variable — JANGAN hardcode!
export ROBLOX_API_KEY="[API_KEY_DARI_CREATOR_HUB]"
export ROBLOX_UNIVERSE_ID="[UNIVERSE_ID_PASRAHPHOBIA]"
export ROBLOX_PLACE_ID="[PLACE_ID_PASRAHPHOBIA]"
export ROBLOX_CREATOR_ID="[USER_ID_ATAU_GROUP_ID]"
export ROBLOX_CREATOR_TYPE="User"  # atau "Group"

# Verifikasi koneksi:
curl -s -X GET \
  "https://apis.roblox.com/cloud/v2/universes/${ROBLOX_UNIVERSE_ID}" \
  -H "x-api-key: ${ROBLOX_API_KEY}" | python3 -m json.tool
```

### Python Environment
```bash
pip install requests python-dotenv pillow tqdm colorama

# Buat file .env di root project (jangan commit ke git!):
cat > .env << 'EOF'
ROBLOX_API_KEY=your_key_here
ROBLOX_UNIVERSE_ID=your_universe_id
ROBLOX_PLACE_ID=your_place_id
ROBLOX_CREATOR_ID=your_creator_id
ROBLOX_CREATOR_TYPE=User
EOF

# Tambahkan .env ke .gitignore
echo ".env" >> .gitignore
echo "*.key" >> .gitignore
```

=======================================================================
## CORE IMPORTER SCRIPT
=======================================================================

### Main Importer: `tools/importer/roblox_importer.py`

```python
#!/usr/bin/env python3
"""
PASRAHPHOBIA — Roblox Open Cloud Asset Importer
AGENT_07: IMPORTER_AGENT
"""

import os
import json
import time
import hashlib
import requests
from pathlib import Path
from datetime import datetime, timezone
from dotenv import load_dotenv

load_dotenv()

# ─── CONFIG ───────────────────────────────────────────────────────────
API_KEY        = os.getenv("ROBLOX_API_KEY")
UNIVERSE_ID    = os.getenv("ROBLOX_UNIVERSE_ID")
PLACE_ID       = os.getenv("ROBLOX_PLACE_ID")
CREATOR_ID     = os.getenv("ROBLOX_CREATOR_ID")
CREATOR_TYPE   = os.getenv("ROBLOX_CREATOR_TYPE", "User")

BASE_URL       = "https://apis.roblox.com"
ASSETS_URL     = f"{BASE_URL}/assets/v1/assets"
CLOUD_V2_URL   = f"{BASE_URL}/cloud/v2"

MANIFEST_PATH  = Path("assets/manifest/ASSET_MANIFEST.json")
UPLOAD_LOG     = Path("assets/manifest/UPLOAD_LOG.json")

HEADERS = {
    "x-api-key": API_KEY,
}

# ─── ASSET TYPE MAP ────────────────────────────────────────────────────
ASSET_TYPE_MAP = {
    ".png":  "Image",
    ".jpg":  "Image",
    ".jpeg": "Image",
    ".ogg":  "Audio",
    ".mp3":  "Audio",
    ".fbx":  "Model",
    ".rbxm": "Model",
}

# ─── HELPERS ──────────────────────────────────────────────────────────
def load_manifest():
    with open(MANIFEST_PATH, "r") as f:
        return json.load(f)

def save_manifest(manifest):
    manifest["last_updated"] = datetime.now(timezone.utc).isoformat()
    with open(MANIFEST_PATH, "w") as f:
        json.dump(manifest, f, indent=2)
    print(f"✓ Manifest disimpan: {MANIFEST_PATH}")

def load_upload_log():
    if UPLOAD_LOG.exists():
        with open(UPLOAD_LOG, "r") as f:
            return json.load(f)
    return {}

def save_upload_log(log):
    with open(UPLOAD_LOG, "w") as f:
        json.dump(log, f, indent=2)

def file_hash(filepath):
    """MD5 hash file untuk deteksi perubahan (skip re-upload jika sama)."""
    h = hashlib.md5()
    with open(filepath, "rb") as f:
        h.update(f.read())
    return h.hexdigest()

# ─── UPLOAD FUNCTIONS ─────────────────────────────────────────────────
def upload_asset(filepath: Path, display_name: str, description: str = "") -> dict:
    """
    Upload satu asset ke Roblox via Open Cloud Assets API.
    Returns: { "assetId": "...", "operationId": "..." }
    """
    suffix = filepath.suffix.lower()
    asset_type = ASSET_TYPE_MAP.get(suffix)
    if not asset_type:
        raise ValueError(f"Tipe file tidak didukung: {suffix}")

    # Build request
    request_body = {
        "assetType": asset_type,
        "displayName": display_name,
        "description": description,
        "creationContext": {
            "creator": {
                "userId" if CREATOR_TYPE == "User" else "groupId": CREATOR_ID
            }
        }
    }

    with open(filepath, "rb") as f:
        files = {
            "request": (None, json.dumps(request_body), "application/json"),
            "fileContent": (filepath.name, f, _get_mime(suffix)),
        }
        resp = requests.post(ASSETS_URL, headers=HEADERS, files=files)

    if resp.status_code not in (200, 201):
        raise RuntimeError(f"Upload gagal [{resp.status_code}]: {resp.text}")

    data = resp.json()
    return data  # Berisi operationId — perlu poll untuk AssetId

def poll_operation(operation_id: str, max_wait: int = 60) -> str:
    """
    Poll operation status sampai selesai, return AssetId.
    Roblox upload bersifat async — perlu polling.
    """
    op_url = f"{BASE_URL}/assets/v1/{operation_id}"
    waited = 0
    while waited < max_wait:
        resp = requests.get(op_url, headers=HEADERS)
        data = resp.json()

        status = data.get("done", False)
        if status:
            # Extract assetId dari response
            response_data = data.get("response", {})
            asset_id = response_data.get("assetId") or \
                       data.get("assetId") or \
                       data.get("resourceId", "").split("/")[-1]
            if asset_id:
                return str(asset_id)
            raise RuntimeError(f"Operation done tapi assetId tidak ditemukan: {data}")

        error = data.get("error")
        if error:
            raise RuntimeError(f"Operation gagal: {error}")

        time.sleep(3)
        waited += 3
        print(f"  ⏳ Menunggu upload selesai... ({waited}s)")

    raise TimeoutError(f"Upload timeout setelah {max_wait}s: {operation_id}")

def upload_with_retry(filepath: Path, display_name: str,
                      description: str = "", retries: int = 3) -> str:
    """Upload dengan retry otomatis. Return AssetId string."""
    for attempt in range(1, retries + 1):
        try:
            print(f"  ↑ Uploading {filepath.name} (attempt {attempt})...")
            result = upload_asset(filepath, display_name, description)

            # Cek apakah langsung dapat assetId atau perlu poll
            if "assetId" in result:
                return str(result["assetId"])
            elif "path" in result:
                # Open Cloud v2 style — path = "assets/{operationId}"
                op_id = result["path"]
                return poll_operation(op_id)
            else:
                raise RuntimeError(f"Unexpected response: {result}")

        except Exception as e:
            print(f"  ✗ Attempt {attempt} gagal: {e}")
            if attempt == retries:
                raise
            time.sleep(5 * attempt)  # backoff

def _get_mime(suffix: str) -> str:
    return {
        ".png": "image/png",
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".ogg": "audio/ogg",
        ".mp3": "audio/mpeg",
        ".fbx": "model/fbx",
        ".rbxm": "application/xml",
    }.get(suffix, "application/octet-stream")

# ─── BATCH IMPORTERS ─────────────────────────────────────────────────
def import_icons(manifest: dict, upload_log: dict) -> dict:
    """Upload semua icon dari assets/icons/ yang belum ada AssetId-nya."""
    print("\n═══ IMPORT ICONS (AGENT_01 output) ═══")
    icons_dir = Path("assets/icons")
    updated = 0

    for png in sorted(icons_dir.glob("*_icon.png")):
        reward_id = png.stem.replace("_icon", "")
        file_hash_val = file_hash(png)

        # Skip jika sudah di-upload (hash sama)
        if upload_log.get(str(png)) == file_hash_val:
            print(f"  ⊙ {reward_id}_icon.png — sudah di-upload, skip")
            continue

        try:
            asset_id = upload_with_retry(
                png,
                display_name=f"[PASRAHPHOBIA] {reward_id} Icon",
                description=f"Royal Pass icon untuk reward: {reward_id}"
            )
            print(f"  ✓ {reward_id}_icon.png → rbxassetid://{asset_id}")

            # Update manifest — cari entry reward_id di semua section
            _update_manifest_asset_id(manifest, reward_id, "icon_asset_id", asset_id)

            upload_log[str(png)] = file_hash_val
            updated += 1
            time.sleep(1)  # Rate limit courtesy

        except Exception as e:
            print(f"  ✗ GAGAL upload {png.name}: {e}")

    print(f"  Icons selesai: {updated} uploaded")
    return manifest

def import_audio(manifest: dict, upload_log: dict) -> dict:
    """Upload semua SFX dari assets/audio/."""
    print("\n═══ IMPORT AUDIO (AGENT_05 output) ═══")
    audio_dir = Path("assets/audio")
    audio_manifest = manifest.setdefault("audio_manifest", {})
    updated = 0

    for ogg in sorted(audio_dir.glob("sfx_*.ogg")):
        sfx_id = ogg.stem  # e.g. "sfx_tier_claim"
        file_hash_val = file_hash(ogg)

        if upload_log.get(str(ogg)) == file_hash_val:
            print(f"  ⊙ {sfx_id}.ogg — sudah di-upload, skip")
            continue

        try:
            asset_id = upload_with_retry(
                ogg,
                display_name=f"[PASRAHPHOBIA] {sfx_id}",
                description=f"SFX untuk event: {sfx_id}"
            )
            print(f"  ✓ {sfx_id}.ogg → rbxassetid://{asset_id}")

            # Update audio_manifest berdasarkan sfx_id
            _update_audio_manifest(audio_manifest, sfx_id, asset_id)

            upload_log[str(ogg)] = file_hash_val
            updated += 1
            time.sleep(1)

        except Exception as e:
            print(f"  ✗ GAGAL upload {ogg.name}: {e}")

    manifest["audio_manifest"] = audio_manifest
    print(f"  Audio selesai: {updated} uploaded")
    return manifest

def import_ui_assets(manifest: dict, upload_log: dict) -> dict:
    """Upload UI PNG dari assets/ui/."""
    print("\n═══ IMPORT UI ASSETS (AGENT_04 output) ═══")
    ui_dir = Path("assets/ui")
    updated = 0

    for png in sorted(ui_dir.glob("*.png")):
        reward_id = png.stem.replace("_border", "").replace("_title", "").replace("_effect_ref", "")
        file_hash_val = file_hash(png)

        if upload_log.get(str(png)) == file_hash_val:
            print(f"  ⊙ {png.name} — sudah di-upload, skip")
            continue

        try:
            asset_id = upload_with_retry(
                png,
                display_name=f"[PASRAHPHOBIA] UI {png.stem}",
                description=f"UI asset untuk: {png.stem}"
            )
            print(f"  ✓ {png.name} → rbxassetid://{asset_id}")

            _update_manifest_asset_id(manifest, reward_id, "roblox_asset_id", asset_id)

            upload_log[str(png)] = file_hash_val
            updated += 1
            time.sleep(1)

        except Exception as e:
            print(f"  ✗ GAGAL upload {png.name}: {e}")

    print(f"  UI assets selesai: {updated} uploaded")
    return manifest

# ─── PLACE PUBLISHING ─────────────────────────────────────────────────
def publish_place(place_rbxl_path: Path, version_type: str = "Saved") -> dict:
    """
    Publish .rbxl file ke Roblox (update place).
    version_type: "Saved" (tidak langsung live) atau "Published" (langsung live)
    """
    print(f"\n═══ PUBLISH PLACE ═══")
    print(f"  File: {place_rbxl_path}")
    print(f"  VersionType: {version_type}")

    url = (f"{CLOUD_V2_URL}/universes/{UNIVERSE_ID}/places/{PLACE_ID}/versions"
           f"?versionType={version_type}")

    with open(place_rbxl_path, "rb") as f:
        resp = requests.post(
            url,
            headers={**HEADERS, "Content-Type": "application/octet-stream"},
            data=f.read()
        )

    if resp.status_code not in (200, 201):
        raise RuntimeError(f"Publish gagal [{resp.status_code}]: {resp.text}")

    data = resp.json()
    print(f"  ✓ Place published! Version: {data.get('versionNumber', '?')}")
    return data

# ─── MANIFEST HELPERS ─────────────────────────────────────────────────
def _update_manifest_asset_id(manifest: dict, reward_id: str,
                               field: str, asset_id: str):
    """Cari reward_id di seluruh manifest dan update field-nya."""
    # Cek checkin_rewards
    for section_key in ["checkin_rewards", "royal_pass_rewards"]:
        section = manifest.get(section_key, {})
        for tier_key, tier_data in section.items():
            if tier_data.get("reward_id") == reward_id or tier_key == reward_id:
                files = tier_data.setdefault("files", {})
                files[field] = f"rbxassetid://{asset_id}"
                return

def _update_audio_manifest(audio_manifest: dict, sfx_id: str, asset_id: str):
    """Update audio_manifest nested structure."""
    # sfx_id format: "sfx_tier_claim", "sfx_gacha_open", dll
    mapping = {
        # Royal Pass
        "sfx_tier_claim":         ("royal_pass", "tier_claim"),
        "sfx_tier_up_free":       ("royal_pass", "tier_up_free"),
        "sfx_tier_up_premium":    ("royal_pass", "tier_up_premium"),
        "sfx_pass_purchased":     ("royal_pass", "pass_purchased"),
        "sfx_royalpass_open":     ("royal_pass", "royalpass_open"),
        "sfx_royalpass_close":    ("royal_pass", "royalpass_close"),
        "sfx_tier_scroll":        ("royal_pass", "tier_scroll"),
        # Gacha
        "sfx_gacha_open":         ("gacha", "gacha_open"),
        "sfx_gacha_pull_start":   ("gacha", "pull_start"),
        "sfx_gacha_reveal_common":("gacha", "reveal_common"),
        "sfx_gacha_reveal_rare":  ("gacha", "reveal_rare"),
        "sfx_gacha_reveal_epic":  ("gacha", "reveal_epic"),
        "sfx_gacha_reveal_legend":("gacha", "reveal_legend"),
        "sfx_gacha_pity_warning": ("gacha", "pity_warning"),
        # Checkin
        "sfx_checkin_daily":      ("checkin", "daily"),
        "sfx_checkin_streak":     ("checkin", "streak_add"),
        "sfx_checkin_streak7":    ("checkin", "streak_7"),
        "sfx_milestone_5":        ("checkin", "milestone_5"),
        "sfx_milestone_30":       ("checkin", "milestone_30"),
        # Missions
        "sfx_mission_progress":   ("missions", "progress"),
        "sfx_mission_complete":   ("missions", "complete"),
        "sfx_mission_claim":      ("missions", "claim"),
        "sfx_challenge_complete": ("missions", "challenge_complete"),
        "sfx_mission_reset":      ("missions", "reset"),
    }
    if sfx_id in mapping:
        section, key = mapping[sfx_id]
        audio_manifest.setdefault(section, {})[key] = f"rbxassetid://{asset_id}"
    else:
        # Emote SFX
        audio_manifest.setdefault("emotes", {})[sfx_id] = f"rbxassetid://{asset_id}"

# ─── MAIN ENTRY POINT ─────────────────────────────────────────────────
def main():
    import argparse
    parser = argparse.ArgumentParser(description="PASRAHPHOBIA Asset Importer")
    parser.add_argument("--icons",     action="store_true", help="Import icons saja")
    parser.add_argument("--audio",     action="store_true", help="Import audio saja")
    parser.add_argument("--ui",        action="store_true", help="Import UI assets saja")
    parser.add_argument("--publish",   type=str,            help="Path ke .rbxl untuk publish")
    parser.add_argument("--all",       action="store_true", help="Import semua asset")
    parser.add_argument("--dry-run",   action="store_true", help="Simulasi tanpa upload")
    args = parser.parse_args()

    if not API_KEY:
        print("✗ ERROR: ROBLOX_API_KEY tidak ada di environment!")
        return

    print("═══════════════════════════════════════════")
    print("  PASRAHPHOBIA — AGENT_07: IMPORTER_AGENT  ")
    print("═══════════════════════════════════════════")
    print(f"  Universe ID : {UNIVERSE_ID}")
    print(f"  Dry Run     : {args.dry_run}")
    print()

    if args.dry_run:
        print("⚠️  DRY RUN MODE — tidak ada upload terjadi")

    manifest    = load_manifest()
    upload_log  = load_upload_log()

    try:
        if args.all or args.icons:
            manifest = import_icons(manifest, upload_log)
        if args.all or args.audio:
            manifest = import_audio(manifest, upload_log)
        if args.all or args.ui:
            manifest = import_ui_assets(manifest, upload_log)
        if args.publish:
            publish_place(Path(args.publish), version_type="Saved")

    finally:
        # Selalu save manifest & log, bahkan jika ada error di tengah
        save_manifest(manifest)
        save_upload_log(upload_log)

    print("\n✓ Import selesai! Manifest & upload log sudah diperbarui.")
    print("→ Kirim ASSET_MANIFEST.json yang sudah diperbarui ke AGENT_06 & AGENT_09")

if __name__ == "__main__":
    main()
```

=======================================================================
## USAGE COMMANDS
=======================================================================

```bash
# Import hanya icons:
python3 tools/importer/roblox_importer.py --icons

# Import hanya audio:
python3 tools/importer/roblox_importer.py --audio

# Import semua asset (icons + audio + UI):
python3 tools/importer/roblox_importer.py --all

# Simulasi dulu tanpa upload:
python3 tools/importer/roblox_importer.py --all --dry-run

# Publish place setelah integrasi:
python3 tools/importer/roblox_importer.py --publish game/PASRAHPHOBIA.rbxl

# Semua sekaligus:
python3 tools/importer/roblox_importer.py --all --publish game/PASRAHPHOBIA.rbxl
```

=======================================================================
## RATE LIMIT & QUOTA AWARENESS
=======================================================================

```
Roblox Open Cloud Rate Limits (per API key):
  Asset Upload   : 60 requests/minute
  Place Publish  : 10 requests/minute
  DataStore Read : 60 requests/minute
  DataStore Write: 60 requests/minute

AGENT_07 built-in safeguards:
  - time.sleep(1) antara setiap upload
  - Retry dengan exponential backoff (3x max)
  - MD5 hash check — skip file yang sudah di-upload
  - Upload log persisten — resume setelah interrupt
```

=======================================================================
## CHECKLIST SEBELUM REPORT KE ORCHESTRATOR
=======================================================================

```
□ API Key valid (test curl berhasil)
□ Universe ID dan Place ID benar (cek di Creator Dashboard)
□ Semua icon (assets/icons/*.png) berhasil di-upload
□ Semua audio (assets/audio/*.ogg) berhasil di-upload
□ Semua UI asset (assets/ui/*.png) berhasil di-upload
□ ASSET_MANIFEST.json sudah punya semua AssetId terisi
□ UPLOAD_LOG.json tersimpan (untuk resume jika perlu)
□ Tidak ada "GAGAL" di log output
□ Kirim manifest terbaru ke AGENT_06 dan AGENT_09
```

=======================================================================
## LAPORAN KE ORCHESTRATOR
=======================================================================

```
=== IMPORT REPORT — AGENT_07 ===
Date       : [tanggal]
Universe ID: [id]

UPLOAD SUMMARY:
  Icons    uploaded : [X] files
  Audio    uploaded : [X] files
  UI assets uploaded: [X] files
  3D Models uploaded: [X] files

FAILED (jika ada):
  [nama file] — [alasan gagal]

MANIFEST updated: assets/manifest/ASSET_MANIFEST.json
Upload log saved: assets/manifest/UPLOAD_LOG.json

NEXT STEP: Kirim manifest ke AGENT_06 (integrasi) & AGENT_09 (asset ID registry)
=== END REPORT ===
```

=======================================================================
AGENT_07 RULES:
- JANGAN simpan API Key di dalam script — selalu dari .env
- JANGAN upload ulang file yang hash-nya sama (cek UPLOAD_LOG dulu)
- JANGAN publish place jika masih ada upload yang GAGAL
- Selalu save manifest setelah setiap batch, bukan hanya di akhir
- Jika upload di-reject Roblox (moderation) → lapor ke ORCHESTRATOR SEGERA
- Verifikasi Universe ID + Place ID sebelum setiap run baru
- JANGAN jalankan --publish di jam peak player (gunakan maintenance window)
=======================================================================

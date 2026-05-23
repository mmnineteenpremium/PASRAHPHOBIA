=======================================================================
PASRAHPHOBIA — AGENT_09: ASSET_ID_MANAGER
ROLE: CENTRAL ASSET ID REGISTRY — SINGLE SOURCE OF TRUTH
VERSION: 1.0
GAME: PASRAHPHOBIA (Roblox Horror/Investigation)
AUTHORITY: Menjadi satu-satunya sumber kebenaran untuk SEMUA Roblox AssetId,
           MeshId, TextureId, AnimationId, AudioId, PassId, ProductId,
           SubscriptionId, dan AssetId UGC di seluruh pipeline
CONNECTS TO: Semua agent (01–08) + ORCHESTRATOR
=======================================================================

## WORKFLOW OVERRIDE (2026-05-22)

- Registry image/UI/billboard/reference harus mencatat file PNG dan metadata JSON dari `scripts/generate_visual.py`.
- Registry model harus mencatat source pipeline: Roblox Studio MCP, Cube3D local, Tripo3D, atau Blender, plus apakah komponen siap rig/animasi.
- Registry animasi harus membedakan output Studio Animation Editor dan Blender fallback.
- Sebelum generate config atau sync AssetId, wajib cek branch/worktree dan Rojo `default.project.json` agar ID tidak masuk ke branch/project yang salah.

## IDENTITAS
Kamu adalah ASSET_ID_MANAGER — registry terpusat yang memastikan tidak ada
AssetId yang tercecer, duplikat, atau salah referensi di seluruh codebase
PASRAHPHOBIA.

**Masalah yang kamu selesaikan:**
- Agent berbeda menyimpan AssetId di tempat berbeda → tidak konsisten
- Hardcode AssetId di banyak file → susah di-update saat aset diganti
- Tidak ada audit trail siapa upload apa dan kapan
- Production vs staging ID tertukar
- Season baru butuh replace ID lama tapi tidak tahu file mana yang pakai

**Kamu menerima dari:**
- AGENT_07 (IMPORTER): AssetId baru setelah upload
- AGENT_08 (MONETIZATION): PassId, ProductId, SubscriptionId
- AGENT_03 (ANIMATION): AnimationId setelah upload ke Roblox
- AGENT_06 (INTEGRATION): MeshId, TextureId setelah import

**Kamu memberi ke:**
- Semua agent yang butuh AssetId
- ORCHESTRATOR: Full registry untuk audit
- AGENT_06: Generated Lua config files dari registry

=======================================================================
## REGISTRY DATABASE STRUCTURE
=======================================================================

### Master Registry File: `assets/manifest/ASSET_ID_REGISTRY.json`

```json
{
  "_meta": {
    "version": "1.0",
    "game": "PASRAHPHOBIA",
    "universe_id": "[UNIVERSE_ID]",
    "place_id": "[PLACE_ID]",
    "last_updated": "2026-05-20T00:00:00Z",
    "maintained_by": "AGENT_09"
  },

  "images": {
    "hat_ghosthunter_cap_icon": {
      "asset_id": null,
      "rbx_asset_id": null,
      "filename": "hat_ghosthunter_cap_icon.png",
      "uploaded_by": "AGENT_07",
      "uploaded_at": null,
      "season": 1,
      "tags": ["icon", "cosmetic", "hat", "tier_05", "free"]
    },
    "border_haunted_frame_border": {
      "asset_id": null,
      "rbx_asset_id": null,
      "filename": "border_haunted_frame_border.png",
      "uploaded_by": "AGENT_07",
      "uploaded_at": null,
      "season": 1,
      "tags": ["ui", "border", "tier_10", "free"]
    }
  },

  "meshes": {
    "hat_ghosthunter_cap_mesh": {
      "mesh_id": null,
      "rbx_mesh_id": null,
      "filename": "hat_ghosthunter_cap_model.fbx",
      "uploaded_by": "AGENT_06",
      "uploaded_at": null,
      "season": 1,
      "tags": ["3d", "cosmetic", "hat"]
    }
  },

  "textures": {
    "hat_ghosthunter_cap_diffuse": {
      "texture_id": null,
      "rbx_texture_id": null,
      "filename": "hat_ghosthunter_cap_diffuse.png",
      "uploaded_by": "AGENT_06",
      "uploaded_at": null,
      "season": 1,
      "tags": ["texture", "cosmetic", "hat"]
    }
  },

  "animations": {
    "emote_pasrah_bow": {
      "animation_id": null,
      "rbx_animation_id": null,
      "filename": "emote_pasrah_bow_emote.rbxanim",
      "uploaded_by": "AGENT_03",
      "uploaded_at": null,
      "type": "emote",
      "season": 1,
      "tags": ["animation", "emote", "tier_20", "free"]
    },
    "pet_orb_ghost_idle": {
      "animation_id": null,
      "rbx_animation_id": null,
      "filename": "pet_orb_ghost_idle.rbxanim",
      "uploaded_by": "AGENT_03",
      "uploaded_at": null,
      "type": "pet_idle",
      "season": 1,
      "tags": ["animation", "pet", "tier_15", "premium"]
    },
    "pet_orb_ghost_follow": {
      "animation_id": null,
      "rbx_animation_id": null,
      "filename": "pet_orb_ghost_follow.rbxanim",
      "uploaded_by": "AGENT_03",
      "uploaded_at": null,
      "type": "pet_follow",
      "season": 1,
      "tags": ["animation", "pet", "tier_15", "premium"]
    }
  },

  "audio": {
    "sfx_tier_claim": {
      "asset_id": null,
      "rbx_asset_id": null,
      "filename": "sfx_tier_claim.ogg",
      "uploaded_by": "AGENT_07",
      "uploaded_at": null,
      "tags": ["sfx", "royal_pass", "ui"]
    },
    "sfx_gacha_reveal_legend": {
      "asset_id": null,
      "rbx_asset_id": null,
      "filename": "sfx_gacha_reveal_legend.ogg",
      "uploaded_by": "AGENT_07",
      "uploaded_at": null,
      "tags": ["sfx", "gacha", "legendary"]
    }
  },

  "monetization": {
    "passes": {
      "pass_royal_premium": {
        "pass_id": null,
        "price_robux": 499,
        "created_by": "AGENT_08",
        "created_at": null,
        "season": 1,
        "status": "PENDING"
      },
      "pass_vip_investigator": {
        "pass_id": null,
        "price_robux": 999,
        "created_by": "AGENT_08",
        "created_at": null,
        "season": 1,
        "status": "PENDING"
      },
      "pass_ghost_whisperer": {
        "pass_id": null,
        "price_robux": 299,
        "created_by": "AGENT_08",
        "created_at": null,
        "season": 1,
        "status": "PENDING"
      }
    },

    "developer_products": {
      "dp_mm_1000": {
        "product_id": null,
        "price_robux": 25,
        "created_by": "AGENT_08",
        "created_at": null,
        "status": "PENDING"
      },
      "dp_mm_5000": {
        "product_id": null,
        "price_robux": 99,
        "created_by": "AGENT_08",
        "created_at": null,
        "status": "PENDING"
      },
      "dp_pp_100": {
        "product_id": null,
        "price_robux": 49,
        "created_by": "AGENT_08",
        "created_at": null,
        "status": "PENDING"
      },
      "dp_tickets_10": {
        "product_id": null,
        "price_robux": 79,
        "created_by": "AGENT_08",
        "created_at": null,
        "status": "PENDING"
      },
      "dp_season_skip_5": {
        "product_id": null,
        "price_robux": 99,
        "created_by": "AGENT_08",
        "created_at": null,
        "status": "PENDING"
      }
    },

    "subscriptions": {
      "sub_investigator_club": {
        "subscription_id": null,
        "price_robux_monthly": 199,
        "created_by": "AGENT_08",
        "created_at": null,
        "status": "PENDING"
      }
    },

    "ugc_items": {
      "ugc_hat_pocong_hood": {
        "asset_id": null,
        "marketplace_price": 100,
        "created_by": "AGENT_08",
        "uploaded_at": null,
        "status": "PENDING_MODERATION"
      }
    }
  }
}
```

=======================================================================
## CORE REGISTRY MANAGER SCRIPT
=======================================================================

### `tools/asset_id_manager/registry_manager.py`

```python
#!/usr/bin/env python3
"""
PASRAHPHOBIA — AGENT_09: Asset ID Registry Manager
Single source of truth untuk semua Roblox AssetId.
"""

import os
import json
import requests
from pathlib import Path
from datetime import datetime, timezone
from dotenv import load_dotenv

load_dotenv()

API_KEY     = os.getenv("ROBLOX_API_KEY")
UNIVERSE_ID = os.getenv("ROBLOX_UNIVERSE_ID")
BASE_URL    = "https://apis.roblox.com"
HEADERS     = {"x-api-key": API_KEY}

REGISTRY_PATH = Path("assets/manifest/ASSET_ID_REGISTRY.json")
MANIFEST_PATH = Path("assets/manifest/ASSET_MANIFEST.json")

# ─── REGISTRY CORE ────────────────────────────────────────────────────

def load_registry() -> dict:
    with open(REGISTRY_PATH, "r") as f:
        return json.load(f)

def save_registry(registry: dict):
    registry["_meta"]["last_updated"] = datetime.now(timezone.utc).isoformat()
    with open(REGISTRY_PATH, "w") as f:
        json.dump(registry, f, indent=2)
    print(f"✓ Registry disimpan: {REGISTRY_PATH}")

# ─── REGISTER FUNCTIONS (dipanggil oleh agent lain) ───────────────────

def register_asset_id(asset_key: str, asset_id: str, asset_type: str,
                      uploaded_by: str = "UNKNOWN"):
    """
    Daftarkan AssetId baru ke registry.
    Dipanggil oleh AGENT_07 setelah upload, atau AGENT_03/06 setelah animasi.

    asset_type: "images" | "meshes" | "textures" | "animations" | "audio"
    """
    registry = load_registry()

    section = registry.get(asset_type, {})
    if asset_key not in section:
        print(f"⚠️  Key '{asset_key}' tidak ditemukan di section '{asset_type}'")
        print(f"   Membuat entry baru...")
        section[asset_key] = {
            "asset_id": None,
            "rbx_asset_id": None,
            "uploaded_by": uploaded_by,
            "uploaded_at": None,
            "season": 1,
            "tags": [],
        }

    section[asset_key]["asset_id"] = asset_id
    section[asset_key]["rbx_asset_id"] = f"rbxassetid://{asset_id}"
    section[asset_key]["uploaded_by"] = uploaded_by
    section[asset_key]["uploaded_at"] = datetime.now(timezone.utc).isoformat()

    registry[asset_type] = section
    save_registry(registry)
    print(f"✓ Registered: {asset_key} → rbxassetid://{asset_id}")

def register_pass_id(internal_id: str, pass_id: str):
    """Daftarkan Game Pass ID dari AGENT_08."""
    registry = load_registry()
    passes = registry["monetization"]["passes"]
    if internal_id in passes:
        passes[internal_id]["pass_id"] = pass_id
        passes[internal_id]["status"] = "ACTIVE"
        passes[internal_id]["created_at"] = datetime.now(timezone.utc).isoformat()
        save_registry(registry)
        print(f"✓ Pass registered: {internal_id} → passId: {pass_id}")
    else:
        print(f"⚠️  Pass '{internal_id}' tidak ada di registry")

def register_product_id(internal_id: str, product_id: str):
    """Daftarkan Developer Product ID dari AGENT_08."""
    registry = load_registry()
    products = registry["monetization"]["developer_products"]
    if internal_id in products:
        products[internal_id]["product_id"] = product_id
        products[internal_id]["status"] = "ACTIVE"
        products[internal_id]["created_at"] = datetime.now(timezone.utc).isoformat()
        save_registry(registry)
        print(f"✓ Product registered: {internal_id} → productId: {product_id}")
    else:
        print(f"⚠️  Product '{internal_id}' tidak ada di registry")

def register_animation_id(animation_key: str, animation_id: str, uploaded_by: str = "AGENT_03"):
    """Daftarkan AnimationId dari AGENT_03."""
    register_asset_id(animation_key, animation_id, "animations", uploaded_by)

# ─── QUERY FUNCTIONS ──────────────────────────────────────────────────

def get_asset_id(asset_key: str, asset_type: str = None) -> str | None:
    """
    Ambil rbx_asset_id berdasarkan key.
    Jika asset_type tidak disebutkan, cari di semua section.
    """
    registry = load_registry()

    if asset_type:
        section = registry.get(asset_type, {})
        entry = section.get(asset_key)
        return entry.get("rbx_asset_id") if entry else None

    # Search semua section
    for section_name, section in registry.items():
        if not isinstance(section, dict) or section_name.startswith("_"):
            continue
        if asset_key in section:
            return section[asset_key].get("rbx_asset_id")

    return None

def get_pass_id(internal_id: str) -> str | None:
    """Ambil passId berdasarkan internal_id."""
    registry = load_registry()
    entry = registry["monetization"]["passes"].get(internal_id)
    return entry.get("pass_id") if entry else None

def get_product_id(internal_id: str) -> str | None:
    """Ambil productId berdasarkan internal_id."""
    registry = load_registry()
    entry = registry["monetization"]["developer_products"].get(internal_id)
    return entry.get("product_id") if entry else None

def search_by_tag(tag: str) -> list:
    """Cari semua asset yang punya tag tertentu."""
    registry = load_registry()
    results = []

    for section_name, section in registry.items():
        if not isinstance(section, dict) or section_name.startswith("_"):
            continue
        for key, entry in section.items():
            if isinstance(entry, dict) and tag in entry.get("tags", []):
                results.append({
                    "key": key,
                    "section": section_name,
                    "rbx_asset_id": entry.get("rbx_asset_id"),
                    "tags": entry.get("tags", []),
                })

    return results

# ─── AUDIT FUNCTIONS ──────────────────────────────────────────────────

def audit_missing_ids() -> dict:
    """
    Cek semua entry yang masih null / belum punya AssetId.
    Return dict berisi daftar yang missing.
    """
    registry = load_registry()
    missing = {}

    def check_section(section_name: str, section: dict):
        for key, entry in section.items():
            if not isinstance(entry, dict):
                continue
            # Cek field id utama
            id_fields = ["asset_id", "mesh_id", "texture_id",
                        "animation_id", "pass_id", "product_id", "subscription_id"]
            for field in id_fields:
                if field in entry and entry[field] is None:
                    missing.setdefault(section_name, []).append({
                        "key": key,
                        "missing_field": field,
                    })
                    break

    for section_name, section in registry.items():
        if isinstance(section, dict) and not section_name.startswith("_"):
            if section_name == "monetization":
                for sub_name, sub_section in section.items():
                    check_section(f"monetization.{sub_name}", sub_section)
            else:
                check_section(section_name, section)

    return missing

def generate_audit_report() -> str:
    """Generate laporan audit ke terminal."""
    missing = audit_missing_ids()
    lines = [
        "═══════════════════════════════════════════",
        "  PASRAHPHOBIA — ASSET ID AUDIT REPORT     ",
        f"  {datetime.now().strftime('%Y-%m-%d %H:%M')}",
        "═══════════════════════════════════════════",
    ]

    if not missing:
        lines.append("✓ Semua AssetId sudah terisi!")
    else:
        total_missing = sum(len(v) for v in missing.values())
        lines.append(f"⚠️  {total_missing} ID masih kosong:\n")
        for section, entries in missing.items():
            lines.append(f"  [{section.upper()}]")
            for entry in entries:
                lines.append(f"    - {entry['key']} (field: {entry['missing_field']})")

    lines.append("═══════════════════════════════════════════")
    report = "\n".join(lines)
    print(report)
    return report

# ─── LUA CONFIG GENERATOR ─────────────────────────────────────────────

def generate_lua_configs():
    """
    Generate semua Lua config file dari registry.
    Dipanggil setelah semua ID terdaftar — hasilnya langsung dipakai di game.
    """
    registry = load_registry()
    output_dir = Path("src/ReplicatedStorage/Shared/Config/Generated")
    output_dir.mkdir(parents=True, exist_ok=True)

    # 1. AudioConfig.lua
    _generate_audio_config(registry, output_dir)

    # 2. AnimationConfig.lua
    _generate_animation_config(registry, output_dir)

    # 3. MonetizationConfig.lua
    _generate_monetization_config(registry, output_dir)

    # 4. AssetIdConfig.lua (semua image/UI asset)
    _generate_asset_config(registry, output_dir)

    print(f"\n✓ Semua Lua config sudah di-generate ke: {output_dir}")

def _generate_audio_config(registry: dict, output_dir: Path):
    audio = registry.get("audio", {})
    lines = [
        "-- GENERATED BY AGENT_09 — JANGAN EDIT MANUAL",
        "-- Source: ASSET_ID_REGISTRY.json",
        "-- Run: python3 tools/asset_id_manager/registry_manager.py --generate-lua",
        "",
        "local AudioConfig = {}",
        "",
        "AudioConfig.SFX = {",
    ]
    for key, entry in audio.items():
        rbx_id = entry.get("rbx_asset_id") or '"[MISSING]"'
        lines.append(f'    ["{key}"] = "{rbx_id}",')

    lines += ["}", "", "return AudioConfig"]

    out = output_dir / "AudioConfig.lua"
    out.write_text("\n".join(lines))
    print(f"  ✓ Generated: {out}")

def _generate_animation_config(registry: dict, output_dir: Path):
    anims = registry.get("animations", {})
    lines = [
        "-- GENERATED BY AGENT_09 — JANGAN EDIT MANUAL",
        "",
        "local AnimationConfig = {}",
        "",
        "AnimationConfig.EMOTES = {}",
        "AnimationConfig.PET_ANIMS = {}",
        "",
    ]

    for key, entry in anims.items():
        rbx_id = entry.get("rbx_asset_id") or '"[MISSING]"'
        anim_type = entry.get("type", "")

        if anim_type == "emote":
            # key = "emote_pasrah_bow"
            emote_id = key
            lines.append(f'AnimationConfig.EMOTES["{emote_id}"] = "{rbx_id}"')
        elif anim_type.startswith("pet_"):
            # key = "pet_orb_ghost_idle" → petId = "pet_orb_ghost", animType = "idle"
            parts = key.rsplit("_", 1)
            if len(parts) == 2:
                pet_id, anim_subtype = parts
                lines.append(
                    f'AnimationConfig.PET_ANIMS["{pet_id}"] = '
                    f'AnimationConfig.PET_ANIMS["{pet_id}"] or {{}}'
                )
                lines.append(
                    f'AnimationConfig.PET_ANIMS["{pet_id}"]["{anim_subtype}"] = "{rbx_id}"'
                )

    lines += ["", "return AnimationConfig"]

    out = output_dir / "AnimationConfig.lua"
    out.write_text("\n".join(lines))
    print(f"  ✓ Generated: {out}")

def _generate_monetization_config(registry: dict, output_dir: Path):
    mono = registry.get("monetization", {})
    passes   = mono.get("passes", {})
    products = mono.get("developer_products", {})
    subs     = mono.get("subscriptions", {})

    lines = [
        "-- GENERATED BY AGENT_09 — JANGAN EDIT MANUAL",
        "",
        "local MonetizationConfig = {}",
        "",
        "MonetizationConfig.PASSES = {",
    ]
    for key, entry in passes.items():
        pass_id = entry.get("pass_id") or "nil"
        price   = entry.get("price_robux", 0)
        lines.append(f'    ["{key}"] = {{ passId = {pass_id}, price = {price} }},')

    lines += ["}", "", "MonetizationConfig.PRODUCTS = {"]
    for key, entry in products.items():
        prod_id = entry.get("product_id") or "nil"
        price   = entry.get("price_robux", 0)
        lines.append(f'    ["{key}"] = {{ productId = {prod_id}, price = {price} }},')

    lines += ["}", "", "MonetizationConfig.SUBSCRIPTIONS = {"]
    for key, entry in subs.items():
        sub_id = entry.get("subscription_id") or "nil"
        price  = entry.get("price_robux_monthly", 0)
        lines.append(f'    ["{key}"] = {{ subscriptionId = "{sub_id}", priceMonthly = {price} }},')

    lines += ["}", "", "return MonetizationConfig"]

    out = output_dir / "MonetizationConfig.lua"
    out.write_text("\n".join(lines))
    print(f"  ✓ Generated: {out}")

def _generate_asset_config(registry: dict, output_dir: Path):
    images   = registry.get("images", {})
    lines = [
        "-- GENERATED BY AGENT_09 — JANGAN EDIT MANUAL",
        "",
        "local AssetIdConfig = {}",
        "",
        "AssetIdConfig.ICONS = {}",
        "AssetIdConfig.UI = {}",
        "",
    ]
    for key, entry in images.items():
        rbx_id = entry.get("rbx_asset_id") or '"[MISSING]"'
        tags   = entry.get("tags", [])
        if "icon" in tags:
            lines.append(f'AssetIdConfig.ICONS["{key}"] = "{rbx_id}"')
        elif "ui" in tags or "border" in tags:
            lines.append(f'AssetIdConfig.UI["{key}"] = "{rbx_id}"')

    lines += ["", "return AssetIdConfig"]

    out = output_dir / "AssetIdConfig.lua"
    out.write_text("\n".join(lines))
    print(f"  ✓ Generated: {out}")

# ─── SYNC FROM MANIFEST ───────────────────────────────────────────────

def sync_from_manifest():
    """
    Sync AssetId dari ASSET_MANIFEST.json ke ASSET_ID_REGISTRY.json.
    Jalankan ini setelah AGENT_07 selesai import.
    """
    print("\n═══ SYNC FROM ASSET_MANIFEST ═══")
    manifest = json.loads(MANIFEST_PATH.read_text())
    registry = load_registry()
    updated = 0

    def extract_ids_from_files(reward_id: str, files: dict):
        nonlocal updated
        id_field_map = {
            "icon_asset_id":     ("images", f"{reward_id}_icon"),
            "roblox_asset_id":   ("images", f"{reward_id}_border"),
            "roblox_mesh_id":    ("meshes", f"{reward_id}_mesh"),
            "roblox_texture_id": ("textures", f"{reward_id}_diffuse"),
            "roblox_animation_id": ("animations", reward_id),
            "roblox_animation_id_idle":   ("animations", f"{reward_id}_idle"),
            "roblox_animation_id_follow": ("animations", f"{reward_id}_follow"),
            "roblox_animation_id_react":  ("animations", f"{reward_id}_react"),
        }
        for file_field, (section, asset_key) in id_field_map.items():
            val = files.get(file_field)
            if val and val.startswith("rbxassetid://"):
                asset_id = val.replace("rbxassetid://", "")
                if asset_key in registry.get(section, {}):
                    entry = registry[section][asset_key]
                    if entry.get("rbx_asset_id") != val:
                        entry["rbx_asset_id"] = val
                        entry["asset_id"] = asset_id
                        updated += 1

    # Proses checkin_rewards
    for reward_id, reward_data in manifest.get("checkin_rewards", {}).items():
        extract_ids_from_files(reward_id, reward_data.get("files", {}))

    # Proses royal_pass_rewards
    for tier_key, tier_data in manifest.get("royal_pass_rewards", {}).items():
        reward_id = tier_data.get("reward_id", tier_key)
        extract_ids_from_files(reward_id, tier_data.get("files", {}))

    # Proses audio_manifest
    for section_name, section in manifest.get("audio_manifest", {}).items():
        for sfx_key, rbx_id in section.items():
            if rbx_id and rbx_id.startswith("rbxassetid://"):
                full_key = f"sfx_{sfx_key}" if not sfx_key.startswith("sfx_") else sfx_key
                if full_key in registry.get("audio", {}):
                    registry["audio"][full_key]["rbx_asset_id"] = rbx_id
                    registry["audio"][full_key]["asset_id"] = rbx_id.replace("rbxassetid://", "")
                    updated += 1

    save_registry(registry)
    print(f"✓ Sync selesai: {updated} entry diperbarui dari manifest")

# ─── CLI ──────────────────────────────────────────────────────────────

def main():
    import argparse
    parser = argparse.ArgumentParser(description="PASRAHPHOBIA Asset ID Manager")
    parser.add_argument("--audit",        action="store_true",  help="Audit missing IDs")
    parser.add_argument("--generate-lua", action="store_true",  help="Generate Lua config files")
    parser.add_argument("--sync",         action="store_true",  help="Sync dari ASSET_MANIFEST.json")
    parser.add_argument("--register",     nargs=4,
                        metavar=("SECTION", "KEY", "ASSET_ID", "AGENT"),
                        help="Daftarkan 1 ID: --register images hat_icon 12345678 AGENT_07")
    parser.add_argument("--get",          nargs="+",
                        metavar="KEY",
                        help="Ambil AssetId: --get hat_ghosthunter_cap_icon")
    parser.add_argument("--search-tag",   type=str,
                        help="Search by tag: --search-tag tier_05")
    args = parser.parse_args()

    print("═══════════════════════════════════════════════")
    print("  PASRAHPHOBIA — AGENT_09: ASSET ID MANAGER    ")
    print("═══════════════════════════════════════════════\n")

    if args.audit:
        generate_audit_report()

    if args.generate_lua:
        generate_lua_configs()

    if args.sync:
        sync_from_manifest()

    if args.register:
        section, key, asset_id, agent = args.register
        register_asset_id(key, asset_id, section, agent)

    if args.get:
        for key in args.get:
            result = get_asset_id(key)
            print(f"  {key}: {result or '[NOT FOUND]'}")

    if args.search_tag:
        results = search_by_tag(args.search_tag)
        print(f"  Assets dengan tag '{args.search_tag}':")
        for r in results:
            print(f"    [{r['section']}] {r['key']} → {r['rbx_asset_id'] or '[MISSING]'}")

if __name__ == "__main__":
    main()
```

=======================================================================
## USAGE COMMANDS
=======================================================================

```bash
# Audit semua ID yang masih kosong:
python3 tools/asset_id_manager/registry_manager.py --audit

# Sync dari ASSET_MANIFEST.json (setelah AGENT_07 selesai import):
python3 tools/asset_id_manager/registry_manager.py --sync

# Generate semua Lua config (setelah semua ID terisi):
python3 tools/asset_id_manager/registry_manager.py --generate-lua

# Daftarkan 1 ID secara manual:
python3 tools/asset_id_manager/registry_manager.py \
  --register images hat_ghosthunter_cap_icon 12345678 AGENT_07

# Ambil AssetId untuk key tertentu:
python3 tools/asset_id_manager/registry_manager.py \
  --get hat_ghosthunter_cap_icon

# Search semua asset tier 5:
python3 tools/asset_id_manager/registry_manager.py --search-tag tier_05

# PIPELINE LENGKAP (setelah AGENT_07 selesai):
python3 tools/asset_id_manager/registry_manager.py --sync
python3 tools/asset_id_manager/registry_manager.py --audit
python3 tools/asset_id_manager/registry_manager.py --generate-lua
```

=======================================================================
## INTEGRASI ANTAR AGENT (FLOW)
=======================================================================

```
[AGENT_03] selesai upload rbxanim ke Roblox
    → Kirim: "AnimationId emote_pasrah_bow = 9876543210"
    → AGENT_09 terima: python3 ... --register animations emote_pasrah_bow 9876543210 AGENT_03

[AGENT_07] selesai batch upload icons & audio
    → Kirim: updated ASSET_MANIFEST.json
    → AGENT_09 terima: python3 ... --sync

[AGENT_08] selesai buat Game Pass
    → Kirim: "pass_royal_premium passId = 11223344"
    → AGENT_09 terima → register_pass_id("pass_royal_premium", "11223344")

[AGENT_09] setelah semua terdaftar:
    → python3 ... --generate-lua
    → Kirim Generated/AudioConfig.lua, AnimationConfig.lua, MonetizationConfig.lua ke AGENT_06
    → AGENT_06 tidak perlu hardcode apa pun — semua dari Generated/ folder

[AGENT_06] integrate:
    → require(game.ReplicatedStorage.Shared.Config.Generated.AudioConfig)
    → require(game.ReplicatedStorage.Shared.Config.Generated.MonetizationConfig)
    → Semua ID sudah ada, tinggal pakai
```

=======================================================================
## CHECKLIST SEBELUM REPORT KE ORCHESTRATOR
=======================================================================

```
□ ASSET_ID_REGISTRY.json ada di assets/manifest/
□ --sync sudah dijalankan setelah AGENT_07 selesai
□ --audit menghasilkan 0 missing (semua terisi)
□ --generate-lua menghasilkan 4 file di Config/Generated/
□ Semua passId dari AGENT_08 terdaftar
□ Semua productId dari AGENT_08 terdaftar
□ Semua animationId dari AGENT_03 terdaftar
□ Lua config Generated/ sudah dikirim ke AGENT_06
□ Registry di-commit ke version control (tanpa .env!)
```

=======================================================================
## LAPORAN KE ORCHESTRATOR
=======================================================================

```
=== ASSET ID REGISTRY REPORT — AGENT_09 ===
Date    : [tanggal]
Registry: assets/manifest/ASSET_ID_REGISTRY.json

REGISTRY SUMMARY:
  Images     : [X] entries, [Y] terisi, [Z] kosong
  Meshes     : [X] entries, [Y] terisi, [Z] kosong
  Textures   : [X] entries, [Y] terisi, [Z] kosong
  Animations : [X] entries, [Y] terisi, [Z] kosong
  Audio      : [X] entries, [Y] terisi, [Z] kosong
  Passes     : [X] entries, [Y] aktif, [Z] pending
  Products   : [X] entries, [Y] aktif, [Z] pending

LUA CONFIGS GENERATED:
  ✓ AudioConfig.lua      ([N] entries)
  ✓ AnimationConfig.lua  ([N] entries)
  ✓ MonetizationConfig.lua ([N] passes, [M] products)
  ✓ AssetIdConfig.lua    ([N] entries)

STATUS: READY FOR AGENT_06 INTEGRATION / [masalah jika ada]
=== END REPORT ===
```

=======================================================================
AGENT_09 RULES:
- JANGAN hardcode AssetId di file manapun — semua lewat registry
- Registry adalah SINGLE SOURCE OF TRUTH — jika konflik, registry yang benar
- JANGAN hapus entry lama saat season baru — arsip dengan season tag
- Generated/ folder: JANGAN edit manual — selalu re-generate dari registry
- Selalu jalankan --audit sebelum --generate-lua
- Jika ada AssetId yang diganti (asset diupload ulang) → update registry DAN
  notifikasi AGENT_06 untuk re-deploy Lua config
- .env dan API key tidak boleh masuk ke ASSET_ID_REGISTRY.json
- ASSET_ID_REGISTRY.json BOLEH di-commit ke git (berisi ID publik, bukan secret)
=======================================================================

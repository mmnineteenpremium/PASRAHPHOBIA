#!/usr/bin/env python3
"""
PASRAHPHOBIA Asset ID Registry Manager.

Lane 09 source-of-truth helper for asset IDs, registry sync, audits, and Lua
config generation.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable


ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT / "assets" / "manifest" / "ASSET_MANIFEST.json"
REGISTRY_PATH = ROOT / "assets" / "manifest" / "ASSET_ID_REGISTRY.json"
COSMETIC_REGISTRY_PATH = ROOT / "src" / "shared" / "Config" / "CosmeticRegistry.lua"
SHOP_CONFIG_PATH = ROOT / "src" / "shared" / "DataTypes" / "ShopMarketplaceConfig.lua"
ASSET_ID_DOC_PATH = ROOT / "PASRAHPHOBIA_ASSETID.md"
GENERATED_DIR = ROOT / "src" / "shared" / "Config" / "Generated"
GENERATED_LUA_PATH = GENERATED_DIR / "AssetIdConfig.lua"

MANIFEST_IMAGE_FIELDS = {
    "concept_art",
    "icon_png",
    "title_png",
    "border_png",
    "badge_png",
    "storyboard_png",
}
MANIFEST_MESH_FIELDS = {"model_fbx", "model_rbxm"}
MANIFEST_TEXTURE_FIELDS = {"diffuse_texture"}
MANIFEST_ANIMATION_FIELDS = {"rbxanim"}


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def lua_quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def lua_key(key: str) -> str:
    if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key):
        return key
    return f"[{lua_quote(key)}]"


def build_empty_registry() -> dict[str, Any]:
    return {
        "_meta": {
            "version": "1.0",
            "game": "PASRAHPHOBIA",
            "universe_id": None,
            "place_id": None,
            "last_updated": now_iso(),
            "maintained_by": "AGENT_09",
        },
        "images": {},
        "meshes": {},
        "textures": {},
        "animations": {},
        "audio": {},
        "monetization": {
            "passes": {},
            "developer_products": {},
            "subscriptions": {},
            "ugc_items": {},
        },
    }


def clone_section_map(raw: Any) -> dict[str, Any]:
    if not isinstance(raw, dict):
        return {}
    return json.loads(json.dumps(raw))


def normalize_status(status: str | None, default: str = "PENDING") -> str:
    if not status:
        return default
    return str(status).upper()


def infer_section_for_field(field_name: str) -> str | None:
    if field_name in MANIFEST_IMAGE_FIELDS:
        return "images"
    if field_name in MANIFEST_MESH_FIELDS:
        return "meshes"
    if field_name in MANIFEST_TEXTURE_FIELDS:
        return "textures"
    if field_name in MANIFEST_ANIMATION_FIELDS:
        return "animations"
    return None


def primary_filename(files: dict[str, Any], section: str) -> str | None:
    preferred_by_section = {
        "images": ["icon_png", "badge_png", "title_png", "border_png", "storyboard_png", "concept_art"],
        "meshes": ["model_fbx", "model_rbxm"],
        "textures": ["diffuse_texture"],
        "animations": ["rbxanim"],
    }
    for key in preferred_by_section.get(section, []):
        value = files.get(key)
        if isinstance(value, str) and value:
            return value
    for value in files.values():
        if isinstance(value, str) and value:
            return value
    return None


def make_entry(
    *,
    asset_id: int | None,
    filename: str | None,
    uploaded_by: str,
    status: str,
    tags: list[str] | None = None,
    **extra: Any,
) -> dict[str, Any]:
    entry = {
        "asset_id": asset_id,
        "rbx_asset_id": f"rbxassetid://{asset_id}" if asset_id is not None else None,
        "filename": filename,
        "uploaded_by": uploaded_by,
        "uploaded_at": extra.pop("uploaded_at", None),
        "season": extra.pop("season", 1),
        "status": status,
        "tags": tags or [],
    }
    entry.update(extra)
    return entry


def parse_manifest_rewards(manifest: dict[str, Any]) -> list[dict[str, Any]]:
    rewards: list[dict[str, Any]] = []

    for bucket_name, reward_list in manifest.get("checkin_rewards", {}).items():
        for reward in reward_list:
            reward_id = reward.get("reward_id") or reward.get("rewardId") or bucket_name
            rewards.append(
                {
                    "reward_id": reward_id,
                    "manifest_group": "checkin_rewards",
                    "bucket": bucket_name,
                    "track": reward.get("track"),
                    "tier": None,
                    "type": reward.get("type"),
                    "source_key": reward.get("source_key"),
                    "asset_status": reward.get("asset_status", "PENDING"),
                    "files": reward.get("files", {}),
                    "assigned_to": reward.get("assigned_to", []),
                    "blocking": reward.get("blocking", []),
                }
            )

    for tier_key, tier_data in manifest.get("tiers", {}).items():
        for bucket_name in ("free", "premium"):
            for reward in tier_data.get(bucket_name, []):
                reward_id = reward.get("reward_id") or tier_key
                rewards.append(
                    {
                        "reward_id": reward_id,
                        "manifest_group": "tiers",
                        "bucket": bucket_name,
                        "track": reward.get("track", bucket_name.upper()),
                        "tier": int(tier_key),
                        "type": reward.get("type"),
                        "source_key": reward.get("source_key"),
                        "asset_status": reward.get("asset_status", "PENDING"),
                        "files": reward.get("files", {}),
                        "assigned_to": reward.get("assigned_to", []),
                        "blocking": reward.get("blocking", []),
                    }
                )

    return rewards


def parse_cosmetic_registry_reward_ids(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8")
    reward_ids = re.findall(r'rewardId\s*=\s*"([^"]+)"', text)
    seen: set[str] = set()
    ordered: list[str] = []
    for reward_id in reward_ids:
        if reward_id not in seen:
            ordered.append(reward_id)
            seen.add(reward_id)
    return ordered


def parse_shop_marketplace_ids(path: Path) -> tuple[dict[str, int], dict[str, int]]:
    text = path.read_text(encoding="utf-8")
    developer_products: dict[str, int] = {}
    game_passes: dict[str, int] = {}

    item_pattern = re.compile(
        r"([A-Za-z0-9_]+)\s*=\s*\{\s*marketplaceId\s*=\s*(\d+)\s*,\s*enabled\s*=\s*(true|false)",
        re.MULTILINE,
    )

    for key, marketplace_id, enabled in item_pattern.findall(text):
        value = int(marketplace_id)
        if key.startswith(("pp_", "mm_")):
            developer_products[key] = value
        else:
            game_passes[key] = value

    return developer_products, game_passes


def parse_assetid_markdown(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    line_pattern = re.compile(
        r"^\|\s*(?P<key>[^|]+?)\s*\|\s*(?P<type>[^|]+?)\s*\|\s*(?P<asset_id>\d+)\s*\|\s*(?P<owner>[^|]+?)\s*\|.*?\|\s*(?P<refs>[^|]+?)\s*\|$"
    )
    for line in path.read_text(encoding="utf-8").splitlines():
        match = line_pattern.match(line)
        if not match:
            continue
        asset_type = match.group("type").strip()
        if asset_type.startswith("Image") or asset_type.startswith("IMAGE"):
            section = "images"
        elif asset_type.startswith("Mesh") or asset_type.startswith("MESH"):
            section = "meshes"
        elif asset_type.startswith("Texture") or asset_type.startswith("TEXTURE"):
            section = "textures"
        elif asset_type.startswith("Animation") or asset_type.startswith("ANIMATION"):
            section = "animations"
        elif asset_type.startswith("Audio") or asset_type.startswith("AUDIO"):
            section = "audio"
        else:
            continue
        rows.append(
            {
                "key": match.group("key").strip(),
                "section": section,
                "asset_type": asset_type,
                "asset_id": int(match.group("asset_id")),
                "owner": match.group("owner").strip(),
                "refs": match.group("refs").strip(),
            }
        )
    return rows


def add_or_update_entry(section: dict[str, Any], key: str, entry: dict[str, Any]) -> None:
    existing = section.get(key)
    if existing:
        if existing.get("asset_id") is None and entry.get("asset_id") is not None:
            existing["asset_id"] = entry["asset_id"]
            existing["rbx_asset_id"] = entry["rbx_asset_id"]
        if not existing.get("filename") and entry.get("filename"):
            existing["filename"] = entry["filename"]
        if not existing.get("uploaded_by") and entry.get("uploaded_by"):
            existing["uploaded_by"] = entry["uploaded_by"]
        if not existing.get("uploaded_at") and entry.get("uploaded_at"):
            existing["uploaded_at"] = entry["uploaded_at"]
        if not existing.get("status") and entry.get("status"):
            existing["status"] = entry["status"]
        existing_tags = list(existing.get("tags", []))
        for tag in entry.get("tags", []):
            if tag not in existing_tags:
                existing_tags.append(tag)
        existing["tags"] = existing_tags
        for extra_key, extra_value in entry.items():
            if extra_key in {"asset_id", "rbx_asset_id", "filename", "uploaded_by", "uploaded_at", "status", "tags"}:
                continue
            if extra_key not in existing or existing[extra_key] in (None, [], {}):
                existing[extra_key] = extra_value
        return
    section[key] = entry


def build_registry() -> dict[str, Any]:
    if not MANIFEST_PATH.exists():
        raise FileNotFoundError(f"Missing manifest: {MANIFEST_PATH}")

    manifest = load_json(MANIFEST_PATH)
    registry = build_empty_registry()
    existing_registry = load_json(REGISTRY_PATH) if REGISTRY_PATH.exists() else {}

    for section_name in ("images", "meshes", "textures", "animations", "audio"):
        registry[section_name] = clone_section_map(existing_registry.get(section_name, {}))

    existing_mono = existing_registry.get("monetization", {})
    registry["monetization"]["passes"] = clone_section_map(existing_mono.get("passes", {}))
    registry["monetization"]["developer_products"] = clone_section_map(existing_mono.get("developer_products", {}))
    registry["monetization"]["subscriptions"] = clone_section_map(existing_mono.get("subscriptions", {}))
    registry["monetization"]["ugc_items"] = clone_section_map(existing_mono.get("ugc_items", {}))

    # Reward entries from manifest become the source truth for pending Royal Pass assets.
    for reward in parse_manifest_rewards(manifest):
        reward_id = reward["reward_id"]
        files = reward.get("files", {})
        tags = ["season_1", reward.get("manifest_group", "manifest")]
        if reward.get("bucket"):
            tags.append(f"track_{reward['bucket']}")
        if reward.get("tier") is not None:
            tags.append(f"tier_{int(reward['tier']):02d}")
        if reward.get("source_key"):
            tags.append(str(reward["source_key"]))
        if reward.get("track"):
            tags.append(str(reward["track"]).lower())

        for field_name, file_path in files.items():
            section_name = infer_section_for_field(field_name)
            if not section_name:
                continue
            section = registry[section_name]
            entry_tags = tags + [field_name, reward.get("type", "reward")]
            entry = make_entry(
                asset_id=None,
                filename=file_path if isinstance(file_path, str) else None,
                uploaded_by="AGENT_09",
                status=normalize_status(reward.get("asset_status"), "PENDING"),
                tags=entry_tags,
                reward_id=reward_id,
                reward_type=reward.get("type"),
                track=reward.get("track"),
                tier=reward.get("tier"),
                source_key=reward.get("source_key"),
                manifest_group=reward.get("manifest_group"),
                manifest_bucket=reward.get("bucket"),
                source_files=files,
            )
            add_or_update_entry(section, reward_id, entry)

    cosmetic_reward_ids = parse_cosmetic_registry_reward_ids(COSMETIC_REGISTRY_PATH)
    missing_from_manifest = [reward_id for reward_id in cosmetic_reward_ids if reward_id not in registry["images"] and reward_id not in registry["animations"]]
    for reward_id in missing_from_manifest:
        entry = make_entry(
            asset_id=None,
            filename=f"{reward_id}.png",
            uploaded_by="AGENT_09",
            status="PENDING",
            tags=["season_1", "royal_pass", "pending", "cosmetic_registry"],
            reward_id=reward_id,
            source_files={},
        )
        add_or_update_entry(registry["images"], reward_id, entry)

    # Confirmed UI / image / animation / audio registry rows from PASRAHPHOBIA_ASSETID.md.
    if ASSET_ID_DOC_PATH.exists():
        for row in parse_assetid_markdown(ASSET_ID_DOC_PATH):
            key = row["key"]
            section_name = row["section"]
            tags = [section_name[:-1] if section_name.endswith("s") else section_name, "confirmed"]
            asset_type = row["asset_type"].lower()
            if "ui" in key.lower() or "royalpass" in key.lower() or "icon" in key.lower() or "tab" in key.lower() or "overlay" in key.lower():
                tags.append("ui")
            if "image" in asset_type:
                tags.append("image")
            if "audio" in asset_type:
                tags.append("audio")
            entry = make_entry(
                asset_id=row["asset_id"],
                filename=f"{key}.png" if section_name == "images" else f"{key}.asset",
                uploaded_by=row["owner"],
                status="CONFIRMED",
                tags=tags,
                source_ref=row["refs"],
                asset_type=row["asset_type"],
            )
            add_or_update_entry(registry[section_name], key, entry)

    # Royal Pass monetization IDs from ShopMarketplaceConfig.lua.
    developer_products, game_passes = parse_shop_marketplace_ids(SHOP_CONFIG_PATH)
    mono = registry["monetization"]
    for key, product_id in developer_products.items():
        mono["developer_products"][key] = {
            "product_id": product_id,
            "price_robux": None,
            "created_by": "AGENT_08",
            "created_at": None,
            "status": "ACTIVE",
        }
    for key, pass_id in game_passes.items():
        mono["passes"][key] = {
            "pass_id": pass_id,
            "price_robux": None,
            "created_by": "AGENT_08",
            "created_at": None,
            "status": "HOLD",
        }

    # Keep subscriptions and UGC placeholders present for schema compatibility.
    mono["subscriptions"] = mono.get("subscriptions", {})
    mono["ugc_items"] = mono.get("ugc_items", {})

    registry["_meta"]["last_updated"] = now_iso()
    return registry


def sync_registry() -> dict[str, Any]:
    registry = build_registry()
    save_json(REGISTRY_PATH, registry)
    return registry


def load_registry() -> dict[str, Any]:
    if not REGISTRY_PATH.exists():
        return build_registry()
    return load_json(REGISTRY_PATH)


def audit_registry(registry: dict[str, Any]) -> dict[str, list[dict[str, Any]]]:
    missing: dict[str, list[dict[str, Any]]] = {}

    for section_name in ("images", "meshes", "textures", "animations", "audio"):
        section = registry.get(section_name, {})
        for key, entry in section.items():
            asset_id = entry.get("asset_id")
            if asset_id is None:
                missing.setdefault(section_name, []).append(
                    {
                        "key": key,
                        "status": entry.get("status"),
                        "filename": entry.get("filename"),
                    }
                )

    mono = registry.get("monetization", {})
    for sub_name, id_field in (("passes", "pass_id"), ("developer_products", "product_id"), ("subscriptions", "subscription_id")):
        section = mono.get(sub_name, {})
        for key, entry in section.items():
            if entry.get(id_field) is None:
                missing.setdefault(f"monetization.{sub_name}", []).append(
                    {
                        "key": key,
                        "status": entry.get("status"),
                        "filename": None,
                    }
                )

    return missing


def print_audit_report(registry: dict[str, Any]) -> None:
    missing = audit_registry(registry)
    sections = ["images", "meshes", "textures", "animations", "audio", "monetization.passes", "monetization.developer_products", "monetization.subscriptions"]
    print("===============================================")
    print("  PASRAHPHOBIA - AGENT_09 AUDIT")
    print("===============================================")
    for section in sections:
        items = missing.get(section, [])
        print(f"[{section}] missing: {len(items)}")
        for item in items[:20]:
            status = item.get("status") or "-"
            filename = item.get("filename") or "-"
            print(f"  - {item['key']} (status={status}, file={filename})")
        if len(items) > 20:
            print(f"  ... {len(items) - 20} more")
    print("===============================================")


def generate_lua(registry: dict[str, Any]) -> None:
    GENERATED_DIR.mkdir(parents=True, exist_ok=True)

    mono = registry.get("monetization", {})
    developer_products = mono.get("developer_products", {})
    game_passes = mono.get("passes", {})
    images = registry.get("images", {})
    animations = registry.get("animations", {})
    audio = registry.get("audio", {})

    royal_pass_ids: list[str] = []
    if COSMETIC_REGISTRY_PATH.exists():
        for reward_id in parse_cosmetic_registry_reward_ids(COSMETIC_REGISTRY_PATH):
            if reward_id not in royal_pass_ids:
                royal_pass_ids.append(reward_id)
    for reward_id in images.keys():
        if reward_id not in royal_pass_ids and reward_id.startswith(("royal_", "title_", "badge_", "emote_")):
            royal_pass_ids.append(reward_id)

    lines: list[str] = [
        "-- GENERATED BY AGENT_09 - JANGAN EDIT MANUAL",
        "-- Source: assets/manifest/ASSET_ID_REGISTRY.json",
        "",
        "local AssetIdConfig = {}",
        "",
        "AssetIdConfig.Monetization = {",
        "    DeveloperProducts = {",
    ]

    for key in sorted(developer_products):
        product_id = developer_products[key].get("product_id")
        if product_id is None:
            lines.append(f"        {lua_key(key)} = nil,")
        else:
            lines.append(f"        {lua_key(key)} = {int(product_id)},")

    lines += [
        "    },",
        "    GamePasses = {",
    ]

    for key in sorted(game_passes):
        pass_id = game_passes[key].get("pass_id")
        if pass_id is None:
            lines.append(f"        {lua_key(key)} = nil,")
        else:
            status = game_passes[key].get("status", "HOLD")
            suffix = " -- hold" if status != "ACTIVE" else ""
            lines.append(f"        {lua_key(key)} = {int(pass_id)},{suffix}")

    lines += [
        "    },",
        "}",
        "",
        "AssetIdConfig.RoyalPassCosmetics = {",
    ]

    for reward_id in royal_pass_ids:
        value = None
        for section_name in ("meshes", "animations", "images"):
            entry = registry.get(section_name, {}).get(reward_id)
            if entry and entry.get("asset_id") is not None:
                value = int(entry["asset_id"])
                break
        if value is None:
            status = "PENDING"
            for section_name in ("meshes", "animations", "images"):
                entry = registry.get(section_name, {}).get(reward_id)
                if entry and entry.get("status"):
                    status = str(entry["status"]).upper()
                    break
            lines.append(f"    {lua_key(reward_id)} = nil, -- {status}")
        else:
            lines.append(f"    {lua_key(reward_id)} = {value},")

    lines += [
        "}",
        "",
        "AssetIdConfig.Animations = {",
    ]

    animation_rows: list[tuple[str, int]] = []
    for key, entry in animations.items():
        if entry.get("status") == "CONFIRMED" and entry.get("asset_id") is not None:
            animation_rows.append((key, int(entry["asset_id"])))
    animation_rows.sort(key=lambda item: item[0].lower())

    for key, asset_id in animation_rows:
        lines.append(f"    {lua_key(key)} = {asset_id},")

    lines += [
        "}",
        "",
        "AssetIdConfig.UIImages = {",
    ]

    ui_rows: list[tuple[str, int]] = []
    for key, entry in images.items():
        if entry.get("status") == "CONFIRMED" and entry.get("asset_id") is not None and re.fullmatch(r"[A-Za-z0-9_ ]+", key):
            ui_rows.append((key, int(entry["asset_id"])))
    ui_rows.sort(key=lambda item: item[0].lower())

    for key, asset_id in ui_rows:
        lines.append(f"    {lua_key(key)} = {asset_id},")

    lines += [
        "}",
        "",
        "AssetIdConfig.Audio = {",
    ]

    audio_rows: list[tuple[str, int]] = []
    for key, entry in audio.items():
        if entry.get("asset_id") is not None:
            status = str(entry.get("status", "")).upper()
            confirmed_flag = entry.get("confirmed") is True
            if status == "CONFIRMED" or confirmed_flag:
                audio_rows.append((key, int(entry["asset_id"])))
    audio_rows.sort(key=lambda item: item[0].lower())

    for key, asset_id in audio_rows:
        lines.append(f"    {lua_key(key)} = {asset_id},")

    lines += [
        "}",
        "",
        "return AssetIdConfig",
        "",
    ]

    GENERATED_LUA_PATH.write_text("\n".join(lines), encoding="utf-8")


def cmd_sync(_: argparse.Namespace) -> int:
    registry = sync_registry()
    print(f"synced: {REGISTRY_PATH.relative_to(ROOT)}")
    print(f"entries: images={len(registry['images'])}, meshes={len(registry['meshes'])}, textures={len(registry['textures'])}, animations={len(registry['animations'])}, audio={len(registry['audio'])}")
    return 0


def cmd_audit(_: argparse.Namespace) -> int:
    registry = load_registry()
    print_audit_report(registry)
    return 0


def cmd_generate_lua(_: argparse.Namespace) -> int:
    registry = load_registry()
    generate_lua(registry)
    print(f"generated: {GENERATED_LUA_PATH.relative_to(ROOT)}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="PASRAHPHOBIA Asset ID Registry Manager")
    parser.add_argument("--sync", action="store_true", help="Sync ASSET_MANIFEST.json and CosmeticRegistry.lua into ASSET_ID_REGISTRY.json")
    parser.add_argument("--audit", action="store_true", help="Print missing/null asset ID summary")
    parser.add_argument("--generate-lua", action="store_true", help="Generate src/shared/Config/Generated/AssetIdConfig.lua")
    args = parser.parse_args(argv)

    actions = [args.sync, args.audit, args.generate_lua]
    if not any(actions):
        parser.error("choose at least one action: --sync, --audit, or --generate-lua")

    try:
        if args.sync:
            cmd_sync(args)
        if args.audit:
            cmd_audit(args)
        if args.generate_lua:
            cmd_generate_lua(args)
    except FileNotFoundError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    except json.JSONDecodeError as exc:
        print(f"JSON parse error in {exc.doc}: line {exc.lineno}, column {exc.colno}: {exc.msg}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

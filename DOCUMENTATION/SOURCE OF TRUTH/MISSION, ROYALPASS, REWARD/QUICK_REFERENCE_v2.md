=======================================================================
PASRAHPHOBIA — MULTI-AGENT QUICK REFERENCE (v2.0)
ROYAL PASS ASSET PIPELINE — SEASON 1
DIPERBARUI: Menambahkan AGENT_07, AGENT_08, AGENT_09
=======================================================================

## WORKFLOW OVERRIDE (2026-05-22)

- Visual raster: gunakan `python scripts/generate_visual.py --prompt "<brief>" --type <icon|billboard|ui|reference>` untuk icon, billboard, UI, border, HUD/static overlay, concept, storyboard, dan 3D reference.
- 3D: generate `--type reference` dulu, lalu pakai prioritas Roblox Studio MCP -> `python scripts/generate_cube3d.py --prompt "<brief>"` -> Tripo3D jika tersedia/diminta -> Blender.
- Animasi: Roblox Studio tooling/Animation Editor -> Blender fallback.
- Rojo/upload/import: cek `git status --short --branch`, worktree `brian-second-final`, dan `default.project.json` dulu.

## DAFTAR FILE PROMPT (LENGKAP)

| File                         | Agent               | Peran                                         |
|------------------------------|---------------------|-----------------------------------------------|
| 00_ORCHESTRATOR_AGENT.md     | ORCHESTRATOR        | Koordinator master, manifest keeper           |
| 01_IMAGEGEN_AGENT.md         | AGENT_01            | Concept art, icon, thumbnail, storyboard      |
| 02_3DMODEL_AGENT.md          | AGENT_02            | 3D model Roblox (accessories, pets)           |
| 03_ANIMATION_AGENT.md        | AGENT_03            | Animasi Roblox Studio → Blender fallback      |
| 04_VISUAL_UI_AGENT.md        | AGENT_04            | UI design (screen, border, title, effect)     |
| 05_AUDIO_AGENT.md            | AGENT_05            | SFX & music stinger                           |
| 06_INTEGRATION_AGENT.md      | AGENT_06            | Integrasi semua asset ke Roblox Studio        |
| 07_IMPORTER_AGENT.md         | AGENT_07 ★ BARU    | Upload otomatis ke Roblox via Open Cloud API  |
| 08_MONETIZATION_MANAGER.md   | AGENT_08 ★ BARU    | Passes, Products, Subs, UGC, Ads, Analytics   |
| 09_ASSET_ID_MANAGER.md       | AGENT_09 ★ BARU    | Registry terpusat semua AssetId + Lua codegen |

=======================================================================
## PIPELINE ALUR LENGKAP (v2.0)
=======================================================================

```
[Developer/Director]
        ↓ brief
[ORCHESTRATOR]
        ↓ assign task
        ├─────────────────────────────────────────────────────────┐
        │                                                         │
[AGENT_01: NANO BANANA]                             [AGENT_08: MONETIZATION]
   ↓ concept/reference/icon                          ↓ buat passes & products
[AGENT_02: 3DMODEL]   [AGENT_04: VISUAL_UI]         ↓
   ↓ fbx + rbxm         ↓ UI PNG + spec             ↓
[AGENT_03: ANIMATION] [AGENT_05: AUDIO]             ↓
   ↓ rbxanim             ↓ ogg files                ↓
        │                     │                     │
        └──────────┬──────────┘                     │
                   ↓                                │
        [AGENT_07: IMPORTER] ←──────────────────────┘
        (upload semua asset via Open Cloud API)
                   ↓ AssetId hasil upload
        [AGENT_09: ASSET_ID_MANAGER]
        (registry + generate Lua configs)
                   ↓ Generated Lua configs
        [AGENT_06: INTEGRATION]
        (integrate ke Roblox Studio)
                   ↓
        [ORCHESTRATOR: Final Check]
                   ↓
               GAME LIVE ✓
```

=======================================================================
## REWARD TYPES vs AGENT YANG MENANGANI
=======================================================================

| Reward Type    | 01 | 02 | 03 | 04 | 05 | 06 | 07 | 08 | 09 |
|----------------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| hat / headgear | ✓  | ✓  | —  | —  | —  | ✓  | ✓  | —  | ✓  |
| face accessory | ✓  | ✓  | —  | —  | —  | ✓  | ✓  | —  | ✓  |
| back item      | ✓  | ✓  | —  | —  | —  | ✓  | ✓  | —  | ✓  |
| emote          | ✓* | —  | ✓  | —  | ✓* | ✓  | ✓  | —  | ✓  |
| pet            | ✓  | ✓  | ✓  | —  | —  | ✓  | ✓  | —  | ✓  |
| border         | —  | —  | —  | ✓  | —  | ✓  | ✓  | —  | ✓  |
| title card     | —  | —  | —  | ✓  | —  | ✓  | ✓  | —  | ✓  |
| effect overlay | —  | —  | —  | ✓  | —  | ✓  | —  | —  | ✓  |
| game pass      | —  | —  | —  | —  | —  | ✓  | —  | ✓  | ✓  |
| dev product    | —  | —  | —  | —  | —  | ✓  | —  | ✓  | ✓  |
| subscription   | —  | —  | —  | —  | —  | ✓  | —  | ✓  | ✓  |
| ugc item       | ✓  | ✓  | —  | —  | —  | —  | ✓  | ✓  | ✓  |
| mm/xp/pp       | —  | —  | —  | —  | —  | —  | —  | —  | —  |

✓* = fungsi khusus (storyboard / emote SFX)

=======================================================================
## API KEY & ENVIRONMENT SETUP
=======================================================================

```bash
# File: .env (di root project — JANGAN commit ke git!)
ROBLOX_API_KEY=your_key_here
ROBLOX_UNIVERSE_ID=your_universe_id
ROBLOX_PLACE_ID=your_place_id
ROBLOX_CREATOR_ID=your_user_or_group_id
ROBLOX_CREATOR_TYPE=User

# .gitignore WAJIB ada:
echo ".env" >> .gitignore

# Cara buat API Key:
# 1. Buka: https://create.roblox.com/credentials
# 2. Create API Key
# 3. Permissions: Assets R+W, Place Publishing W, DataStore R+W
# 4. Restrict ke IP (opsional tapi direkomendasikan untuk keamanan)
```

=======================================================================
## TOOLS FOLDER STRUCTURE
=======================================================================

```
tools/
├── importer/
│   └── roblox_importer.py       ← AGENT_07 script
├── monetization/
│   ├── create_gamepass.py        ← AGENT_08 script
│   └── create_dev_products.py   ← AGENT_08 script
└── asset_id_manager/
    └── registry_manager.py      ← AGENT_09 script

assets/
├── concept/                     ← AGENT_01 output
├── icons/                       ← AGENT_01 output
├── models/fbx/                  ← AGENT_02 output
├── models/rbxm/                 ← AGENT_02 output
├── animations/bvh/              ← AGENT_03 output
├── animations/rbxanim/          ← AGENT_03 output
├── ui/                          ← AGENT_04 output
├── audio/                       ← AGENT_05 output
└── manifest/
    ├── ASSET_MANIFEST.json       ← ORCHESTRATOR maintain
    ├── ASSET_ID_REGISTRY.json    ← AGENT_09 maintain ★ BARU
    └── UPLOAD_LOG.json           ← AGENT_07 maintain ★ BARU

src/shared/Config/
├── RoyalPassConfig.lua           ← Manual (game director)
├── CosmeticRegistry.lua          ← AGENT_06
├── ShopConfig.lua                ← AGENT_08 ★ BARU
└── Generated/                    ← AGENT_09 auto-generate ★ BARU
    ├── AudioConfig.lua
    ├── AnimationConfig.lua
    ├── MonetizationConfig.lua
    └── AssetIdConfig.lua
```

=======================================================================
## NAMING CONVENTION GLOBAL (RINGKASAN LENGKAP)
=======================================================================

```
ASSET FILES (output agent):
[reward_id]_concept.png        ← AGENT_01
[reward_id]_icon.png           ← AGENT_01
[reward_id]_preview.png        ← AGENT_01
[reward_id]_emote_board.png    ← AGENT_01 (emote only)
[reward_id]_model.fbx          ← AGENT_02
[reward_id]_model.rbxm         ← AGENT_02
[reward_id]_diffuse.png        ← AGENT_02
[reward_id]_idle.rbxanim       ← AGENT_03
[reward_id]_follow.rbxanim     ← AGENT_03
[reward_id]_react.rbxanim      ← AGENT_03
[reward_id]_emote.rbxanim      ← AGENT_03
[reward_id]_border.png         ← AGENT_04
[reward_id]_title.png          ← AGENT_04
sfx_[event_name].ogg           ← AGENT_05

REGISTRY KEYS (AGENT_09):
[reward_id]_icon               ← images section
[reward_id]_mesh               ← meshes section
[reward_id]_diffuse            ← textures section
[reward_id] / [reward_id]_idle ← animations section
sfx_[event_name]               ← audio section
pass_[name]                    ← monetization.passes
dp_[name]                      ← monetization.developer_products
sub_[name]                     ← monetization.subscriptions
ugc_[name]                     ← monetization.ugc_items
```

=======================================================================
## SEASON 1 MONETIZATION SUMMARY
=======================================================================

```
GAME PASSES:
  pass_royal_premium       499 R$  — Royal Pass Premium S1
  pass_royal_premium_plus  799 R$  — Premium + bonus PP + XP
  pass_vip_investigator    999 R$  — XP 2x permanen
  pass_ghost_whisperer     299 R$  — MM bonus 1.5x daily

DEVELOPER PRODUCTS:
  dp_mm_1000               25 R$   — +1,000 MM
  dp_mm_5000               99 R$   — +5,000 MM
  dp_mm_15000             249 R$   — +15,000 MM
  dp_pp_100                49 R$   — +100 PP
  dp_pp_300               129 R$   — +300 PP + bonus
  dp_tickets_10            79 R$   — +10 Gacha Tickets
  dp_tickets_50           349 R$   — +50 Tickets + pity reset
  dp_xp_boost_24h          49 R$   — XP 2x 24 jam
  dp_xp_boost_7d          199 R$   — XP 2x 7 hari
  dp_season_skip_5         99 R$   — +5 tier Royal Pass
  dp_season_skip_20       349 R$   — +20 tier Royal Pass

SUBSCRIPTIONS:
  sub_investigator_club   199 R$/bln — XP 1.5x + 500 MM/hari
```

=======================================================================
## CARA PAKAI (WORKFLOW RINGKAS)
=======================================================================

### Untuk 1 Item Baru:
```
1. ORCHESTRATOR → AGENT_01 (concept art)
2. AGENT_01 approve → AGENT_02 (3D) atau AGENT_04 (UI)
3. AGENT_02 → AGENT_03 (animasi, jika pet/emote)
4. AGENT_04 → AGENT_05 (timing SFX)
5. Semua file siap → AGENT_07: python3 roblox_importer.py --all
6. AGENT_07 selesai → AGENT_09: python3 registry_manager.py --sync --audit
7. AGENT_09: python3 registry_manager.py --generate-lua
8. AGENT_06: integrate Generated/ config ke Roblox Studio
9. ORCHESTRATOR: Final verify → DONE ✓
```

### Untuk Launch Monetisasi:
```
1. AGENT_08: buat semua Game Pass di Creator Dashboard
2. AGENT_08: buat semua Developer Products
3. AGENT_08 → AGENT_09: register semua passId dan productId
4. AGENT_09: --generate-lua → MonetizationConfig.lua terisi
5. AGENT_06: require MonetizationConfig.lua, setup ReceiptHandler
6. Test di Studio → publish → monitor di Analytics Dashboard
```

### Untuk Season Baru:
```
1. ORCHESTRATOR: Buat task batch untuk semua 60 tier baru
2. AGENT_09: Arsip registry season lama (tag season = N)
3. Pipeline berjalan normal dari AGENT_01
4. AGENT_08: Update harga jika perlu, buat pass season baru
5. AGENT_07: Batch import semua asset baru
6. AGENT_09: Sync + Generate → AGENT_06 integrate
```

=======================================================================
HUBUNGI ORCHESTRATOR JIKA:
- Ada reward_id baru yang tidak ada di RoyalPassConfig.lua
- Ada konflik AssetId di registry (AGENT_09 lapor)
- Asset di-reject Roblox moderation (AGENT_07 lapor)
- Ada perubahan harga yang perlu approval (AGENT_08 lapor)
- API Key expired atau revoked (semua agent terdampak)
- AGENT_09 --audit menunjukkan banyak ID kosong menjelang deadline
=======================================================================

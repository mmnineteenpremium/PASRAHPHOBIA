# ASSETS AUDIT - 2026-06-14

**Scope:** `assets/` directory
**Auditor:** Claude Sonnet 4.6
**Branch:** `brian-second-final`
**Total Files:** 369 assets

---

## OWNERSHIP CHAIN

| Dimension | Value |
|-----------|-------|
| Default Owner UserId | **8603977492** (`OwnerCheatConfig.DEFAULT_OWNER_USER_ID`) |
| Group Owner | **407883270** — "PASRAHPHOBIA DEVELOPER & TEAM" |
| Active Account | **briankotak** — owns UniverseId `10138560838`, PlaceId `89787959603872` |
| All assets wired | Same group ownership across all 14-digit Creator Hub assets |
| Shop marketplace | 10 GamePass/DeveloperProduct IDs (3573xxx range) — valid Creator Hub items |

---

## FILE INVENTORY

| Subfolder | File Count | Notes |
|----------|-----------|-------|
| `assets/3d model, vfx, animation/` | 155 | 46 .fbx + 109 .fbm texture dirs + 2 roblox_vfx Lua |
| `assets/animations/rbxanim/` | 2 | `.rbxanim` emote animation files |
| `assets/concept/` | 26 | 25 .png concept art + .gitignore |
| `assets/generated/images/manual_inbox/` | 69 | **ORPHAN** — staging PNGs, belum diupload |
| `assets/generated/images/manual_inbox_done/` | 32 | **WIRED** — uploaded ke Roblox, dirujuk via rbxassetid:// |
| `assets/generated/meshes/` | 0 | Empty |
| `assets/generated/test/` | 0 | Empty |
| `assets/icons/` | 31 | 31 .png icon files |
| `assets/manifest/` | 2 | `ASSET_MANIFEST.json` + `ASSET_ID_REGISTRY.json` |
| `assets/models/fbx/` | 23 | Diffuse texture PNGs (bukan .fbx!) |
| `assets/models/rbxm/` | 23 | `.rbxm` model files (royal pass tiers) |
| `assets/ui/` | 6 | Badge/border/title PNG files |
| **TOTAL** | **369** | |

---

## WIRED vs ORPHAN ASSETS

### WIRED (Indirect — via rbxassetid:// numeric IDs)

All 32 PNGs in `manual_inbox_done/` dirujuk via `AssetIdConfig.lua` menggunakan numeric asset ID, BUKAN local file path. Contoh:
- `title_investigator_setia = 98107737947948` → `title_investigator_setia_title.png`
- `badge_season_complete_free = 132587431755176` → `badge_season_complete_free_badge.png`

Asset wiring files:
- `src/shared/Config/Generated/AssetIdConfig.lua` — reward ID → numeric Roblox asset ID
- `src/shared/Config/CosmeticRegistry.lua` — reward ID → local asset file path
- `src/shared/Config/RoyalPassConfig.lua` — runtime cosmetic assembly

### ORPHAN (Belum di-wired)

| Category | Count | Keterangan |
|----------|-------|-----------|
| `manual_inbox/` PNGs | 69 | Staging artifacts — AI-generated variants (suffix `_2/_3/_4`), belum diupload ke Roblox |
| `generated/meshes/` | 0 | Empty |
| `generated/test/` | 0 | Empty |

### Workflow: `_2/_3/_4` Suffix Pattern
Suffix `_2`, `_3`, `_4` = iteration variants (generated sampai kualitas满意). Variant yang dipilih dipindah ke `manual_inbox_done/` sebelum upload ke Roblox.

---

## GHOST ASSETS STATUS

### DONE — All 12 Ghost Base Rigs (Validated Runtime 2026-05-17)

| Ghost | Asset ID | Bones | Status |
|-------|----------|-------|--------|
| Banaspati | `125985418520274` | 10 | DONE — HasSkinnedMesh=true |
| Genderuwo | `116514308503184` | 54 | DONE — HasSkinnedMesh=true |
| HantuTanah | `97068595212213` | 54 | DONE — HasSkinnedMesh=true |
| Jerangkong | `115554451751983` | 10 | DONE — HasSkinnedMesh=true |
| Kuntilanak | `111714179492317` | 54 | DONE — HasSkinnedMesh=true |
| Leak | `98855032697085` | 54 | DONE — HasSkinnedMesh=true |
| Palasik | `78260225419720` | 11 | DONE — HasSkinnedMesh=true |
| Pocong | `135270375666027` | 16 | DONE — HasSkinnedMesh=true |
| SilumanUlar | `87361945667344` | 119 | DONE — HasSkinnedMesh=true |
| SundelBolong | `89326336764042` | 48 | DONE — HasSkinnedMesh=true |
| Tuyul | `128588579954533` | 54 | DONE — HasSkinnedMesh=true |
| WeweGombel | `101666948803556` | 54 | DONE — HasSkinnedMesh=true |

Runtime load: `InsertService:LoadAsset()` → `GhostSystem.Service` → `ReplicatedStorage.Assets.Models.Ghosts`

### DONE — 84/84 Ghost Animations (Uploaded via Open Cloud)

7 animasi per ghost × 12 ghosts = 84 clips. Semua uploaded sebagai team Animation assets, dirakit dalam `.rbxmx`, dan ditulis ke `src/ReplicatedStorage/Assets/Animations/Ghosts/<Ghost>/<RuntimeKey>.model.json`.

Loop flags: `GhostIdle`, `GhostRoam`, `GhostHunt` = looping; `GhostManifest`, `GhostAttack`, `GhostJumpscare`, `GhostCooldown` = non-looping.

### PENDING — Texture Polish

Beberapa ghost masih menampilkan grey/white karena `SurfaceAppearance.ColorMap` kosong. Texture donor lane sudah ditambahkan di `GhostSystem.Service` tapi final texture quality perlu team-owned uploads.

---

## TOOL ASSETS STATUS

### DONE — 8/8 Tool .rbxm Files (Verified on Disk)

| Tool | .rbxm File |
|------|-----------|
| JejakEnergi | EXISTS |
| KotakArwah | EXISTS |
| SuhuMembeku | EXISTS |
| BukuTerkutuk | EXISTS |
| BolaArwah | EXISTS |
| GerakanGaib | EXISTS |
| Flashlight | EXISTS |
| PilSanity | EXISTS |

Runtime refresh: `ToolVisualAssetSystem` → `InsertService:LoadAsset()` → `ToolVisualConfig.inventoryModelAssetId`

---

## ROYAL PASS ASSETS STATUS

### DONE — 23 Royal Pass Tier Models (.rbxm)

11 free tier + 11 premium tier + 1 season exclusive outfit. Semua registered di `ASSET_MANIFEST.json` dan `ASSET_ID_REGISTRY.json`.

### DONE — 32 PNGs Uploaded (manual_inbox_done/)

Badge, title, emote, border PNGs — uploaded ke Roblox, dirujuk via `AssetIdConfig.lua`.

### PENDING — 69 PNGs di manual_inbox/ (Orphan)

AI-generated staging artifacts yang perlu diupload ke Roblox dan dirujuk di `AssetIdConfig.lua`.

---

## AUDIO ASSETS STATUS

### KONOW INVALID — `rbxassetid://10576163165`

HTTP 403 confirmed. Teridentifikasi sebagai UserId-like ID yang salah dipakai sebagai audio asset. Tidak ada live reference di `src/` — hanya di-comment.

### PENDING — Map Ambient Audio

Beberapa washer/TV map sounds return HTTP 403. Butuh owner-approved audio upload path.

---

## CANONICAL SPEC vs BRANCH OWNERSHIP NOTE

`CANONICAL_SPECIFICATIONS_v2.md` lines 171-198 (2026-04-18 addendum) menunjuk **first-account IDs** dari `asset mentah/[ASSETID]/Models & Packages.csv`. Branch `brian-second-final` menggunakan **second-account IDs** (briankotak) yang benar untuk akun ini.

Spec stale untuk branch ini — bukan kode yang salah. Kedua set ID disjoint (tidak ada satupun yang match).

---

## SUMMARY

| Category | Status |
|----------|--------|
| Ghost base rigs (12) | DONE — validated runtime |
| Ghost animations (84) | DONE — uploaded |
| Tool models (8) | DONE — verified on disk |
| Royal pass tier models (23) | DONE — wired |
| Uploaded PNGs (32) | DONE — via rbxassetid:// |
| Orphan PNGs (69) | PENDING — need upload |
| Ghost texture polish | PENDING — need team texture uploads |
| Map ambient audio 403 | PENDING — need owner audio upload |
| Ownership chain | CONSISTENT — groupId 407883270, UserId 8603977492 |

---

*Assets audit generated: 2026-06-14*
*Branch: brian-second-final (briankotak account)*
*Total assets: 369 files*

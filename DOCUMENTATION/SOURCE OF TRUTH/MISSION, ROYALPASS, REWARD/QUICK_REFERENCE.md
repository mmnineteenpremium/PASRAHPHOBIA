=======================================================================
PASRAHPHOBIA — MULTI-AGENT QUICK REFERENCE
ROYAL PASS ASSET PIPELINE — SEASON 1
=======================================================================

## WORKFLOW OVERRIDE (2026-05-22)

- Visual raster: gunakan `python scripts/generate_visual.py --prompt "<brief>" --type <icon|billboard|ui|reference>` untuk icon, billboard, UI, border, HUD/static overlay, concept, storyboard, dan 3D reference.
- 3D: generate `--type reference` dulu, lalu pakai prioritas Roblox Studio MCP -> `python scripts/generate_cube3d.py --prompt "<brief>"` -> Tripo3D jika tersedia/diminta -> Blender.
- Animasi: Roblox Studio tooling/Animation Editor -> Blender fallback.
- Rojo/upload/import: cek `git status --short --branch`, worktree `brian-second-final`, dan `default.project.json` dulu.

## DAFTAR FILE PROMPT

| File                        | Agent        | Peran                                    |
|-----------------------------|--------------|------------------------------------------|
| 00_ORCHESTRATOR_AGENT.md    | ORCHESTRATOR | Koordinator master, manifest keeper      |
| 01_IMAGEGEN_AGENT.md        | AGENT_01     | Concept art, icon, thumbnail, storyboard |
| 02_3DMODEL_AGENT.md         | AGENT_02     | 3D model Roblox (accessories, pets)      |
| 03_ANIMATION_AGENT.md       | AGENT_03     | Animasi Roblox Studio → Blender fallback |
| 04_VISUAL_UI_AGENT.md       | AGENT_04     | UI design (screen, border, title, effect)|
| 05_AUDIO_AGENT.md           | AGENT_05     | SFX & music stinger                      |
| 06_INTEGRATION_AGENT.md     | AGENT_06     | Integrasi semua asset ke Roblox Studio   |

=======================================================================
## PIPELINE ALUR (URUTAN WAJIB)
=======================================================================

```
[Developer/Director]
        ↓ brief
[ORCHESTRATOR]
        ↓ assign task
[AGENT_01: NANO BANANA]        ← WAJIB PERTAMA untuk semua item visual
   ↓ concept/reference/icon         ↓ timing ref (untuk UI)
[AGENT_02: 3DMODEL]         [AGENT_04: VISUAL_UI]
   ↓ fbx + rig                      ↓ UI spec
[AGENT_03: ANIMATION]       [AGENT_05: AUDIO]
   ↓ rbxanim                        ↓ audio manifest
        ↓──────────────────────────↓
              [AGENT_06: INTEGRATION]
                        ↓
              [ORCHESTRATOR: Final Check]
                        ↓
                   GAME LIVE ✓
```

=======================================================================
## REWARD TYPES vs AGENT YANG MENANGANI
=======================================================================

| Reward Type    | AGENT_01 | AGENT_02 | AGENT_03 | AGENT_04 | AGENT_05 | AGENT_06 |
|----------------|:--------:|:--------:|:--------:|:--------:|:--------:|:--------:|
| hat / headgear |    ✓     |    ✓     |    —     |    —     |    —     |    ✓     |
| face accessory |    ✓     |    ✓     |    —     |    —     |    —     |    ✓     |
| back item      |    ✓     |    ✓     |    —     |    —     |    —     |    ✓     |
| emote          |    ✓ *   |    —     |    ✓     |    —     |    ✓ *  |    ✓     |
| pet            |    ✓     |    ✓     |    ✓     |    —     |    —     |    ✓     |
| border         |    —     |    —     |    —     |    ✓     |    —     |    ✓     |
| title card     |    —     |    —     |    —     |    ✓     |    —     |    ✓     |
| effect overlay |    —     |    —     |    —     |    ✓     |    —     |    ✓     |
| mm / xp / pp   |    —     |    —     |    —     |    —     |    —     |    —     |
| gachaTickets   |    —     |    —     |    —     |    —     |    —     |    —     |

✓ * = AGENT_01 buat storyboard (bukan concept sheet biasa)
✓ * = AGENT_05 buat emote SFX (opsional tergantung emote)

=======================================================================
## ASSET YANG PERLU DIBUAT SEASON 1 (CONTOH PRIORITAS)
=======================================================================

Berdasarkan CheckinRewardConfig.lua dan RoyalPassConfig.lua:

**Checkin Milestone Rewards (dari CheckinRewardConfig):**
```
border_haunted_frame      → AGENT_04 + AGENT_06
emote_pasrah_bow          → AGENT_01 (storyboard) + AGENT_03 + AGENT_06
title_investigator_setia  → AGENT_04 + AGENT_06
title_penyintas_sejati    → AGENT_04 + AGENT_06
```

**Royal Pass Tier Rewards (perlu diisi di RoyalPassConfig.lua tier per tier):**
```
Tier 5  FREE  → hat_ghosthunter_cap     (AGENT_01 → AGENT_02 → AGENT_06)
Tier 10 FREE  → border_haunted_frame    (AGENT_04 → AGENT_06)
Tier 15 PREM  → pet_orb_ghost           (AGENT_01 → AGENT_02 → AGENT_03 → AGENT_06)
Tier 20 FREE  → emote_pasrah_bow        (AGENT_01 → AGENT_03 → AGENT_06)
Tier 25 PREM  → acc_spirit_lantern      (AGENT_01 → AGENT_02 → AGENT_06)
Tier 30 FREE  → title_investigator_setia(AGENT_04 → AGENT_06)
... dst hingga tier 60
```

=======================================================================
## NAMING CONVENTION GLOBAL (RINGKASAN)
=======================================================================

```
[reward_id]_concept.png      ← AGENT_01 concept sheet
[reward_id]_icon.png         ← AGENT_01 icon 512x512
[reward_id]_preview.png      ← AGENT_01 thumbnail 400x400
[reward_id]_emote_board.png  ← AGENT_01 storyboard (emote only)
[reward_id]_model.fbx        ← AGENT_02 3D model
[reward_id]_model.rbxm       ← AGENT_02 Roblox model
[reward_id]_diffuse.png      ← AGENT_02 texture
[reward_id]_idle.rbxanim     ← AGENT_03 pet idle
[reward_id]_follow.rbxanim   ← AGENT_03 pet follow
[reward_id]_react.rbxanim    ← AGENT_03 pet react
[reward_id]_emote.rbxanim    ← AGENT_03 emote animation
[reward_id]_border.png       ← AGENT_04 border frame
[reward_id]_title.png        ← AGENT_04 title card
sfx_[event_name].ogg         ← AGENT_05 audio
```

=======================================================================
## SEASON 1 ART DIRECTION (RINGKASAN)
=======================================================================

```
Theme    : Horror Indonesia — rumah tua, hantu lokal, investigasi malam
Palette  : Dark purple (#1A0A2E) + Lantern Gold (#C8A96E) + Spirit Cyan (#4ECDC4)
Style    : Roblox low-poly stylized, bukan hyperrealistic
Must-have: Elemen Indonesia (batik, wayang, gamelan, jimat) di setiap item
Audio    : Indonesian gamelan + modern SFX hybrid
```

=======================================================================
## CARA PAKAI SISTEM MULTI-AGENT INI
=======================================================================

### Untuk 1 Item Baru:

1. **Buat Task di ORCHESTRATOR** dengan format yang sudah ada
2. **Kirim ke AGENT_01** → generate Nano Banana concept/icon/reference via `scripts/generate_visual.py`
3. **Kirim ke AGENT_02** (jika 3D item) dengan reference sheet dan prioritas Studio MCP/Cube3D
4. **Kirim ke AGENT_03** (jika emote/pet) dengan FBX dari AGENT_02
5. **Kirim ke AGENT_04** (jika UI element) dengan concept dari AGENT_01
6. **Kirim ke AGENT_05** untuk SFX terkait
7. **AGENT_06** collect semua → integrate → report ke ORCHESTRATOR

### Untuk Full Season Batch:

1. ORCHESTRATOR buat task untuk semua 60 tier sekaligus
2. AGENT_01 kerjakan semua concept dulu (batch)
3. AGENT_02, AGENT_03, AGENT_04 kerjakan paralel setelah concept approve
4. AGENT_05 kerjakan paralel dengan AGENT_02/03/04
5. AGENT_06 batch integrate setelah semua agent selesai

=======================================================================
HUBUNGI ORCHESTRATOR JIKA:
- Ada reward_id baru yang tidak ada di RoyalPassConfig.lua
- Ada konflik antara konsep dari AGENT_01 dengan spec teknis AGENT_02
- Asset di-reject oleh Roblox moderation
- Ada perubahan art direction di tengah season
- Budget poly/texture perlu di-adjust
=======================================================================

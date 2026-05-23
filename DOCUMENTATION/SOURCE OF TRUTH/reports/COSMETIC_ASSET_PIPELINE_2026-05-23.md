# Cosmetic Asset Pipeline - 2026-05-23

## Summary

- Pipeline result: PARTIAL / MANUAL_REQUIRED.
- Images generated + uploaded: 0/31.
- Meshes generated + uploaded: 0/23.
- Textures generated + uploaded: 0/23.
- Animations: 0/2 confirmed; 2/2 MANUAL_REQUIRED.
- Cosmetic asset confirmation: 0/79 CONFIRMED (0.0%), 79/79 MANUAL_REQUIRED.
- Upload result: 0 assets uploaded. Open Cloud credential was present, but no generated files existed to upload.

## Tool Capability Read

`python scripts\generate_visual.py --help` passed after updating the project launcher to the moved C: tool path.

- Accepted args: `--prompt`, `--type {billboard,icon,reference,ui}`, `--out-dir`, `--model`, `--crop-margin`, `--name`, `--save-raw`.
- Output behavior: writes image output to `--out-dir`; no `--batch` mode.

`python scripts\generate_cube3d.py --help` passed after updating the project launcher/global wrapper to the moved C: Cube path.

- Accepted args include `--prompt`, `--output-dir`, `--gpt-ckpt-path`, `--shape-ckpt-path`, `--fast-inference`, `--top-p`, `--bounding-box-xyz`, `--render-gif`, `--disable-postprocessing`, `--resolution-base`.
- Output behavior: writes `.obj`/optional `.gif` to output dir through Cube; no `--batch` mode.

## Generation And Upload Results

- Image generation: 0/31. Blocker: missing `GEMINI_API_KEY` or `GOOGLE_API_KEY` or `GOOGLE_APPLICATION_CREDENTIALS`.
- Mesh generation: 0/23. Blocker: missing Cube weights `shape_gpt.safetensors` and `shape_tokenizer.safetensors` under `C:\Users\User\.codex\tools\cube\model_weights`.
- Texture generation: 0/23. Blocker: paired mesh generation could not run without Cube weights.
- Open Cloud upload: 0 uploaded because no generated image/mesh/texture files existed after generation blockers.
- Animations: `emote_pasrah_bow` and `emote_pasrah_ascend` marked `MANUAL_REQUIRED`; no uploadable `.rbxanim` files were generated in this source-only run.

## Registry And Source Updates

- `assets/manifest/ASSET_ID_REGISTRY.json`: updated all 79 current cosmetic asset gaps to `MANUAL_REQUIRED` with blocker notes.
- `src/shared/Config/CosmeticRegistry.lua`: 0 entries updated to `CONFIRMED` because no new Roblox asset IDs were produced.
- `tools/asset_id_manager/registry_manager.py`: generated Lua now preserves nil cosmetic status comments such as `-- MANUAL_REQUIRED`.
- `src/shared/Config/Generated/AssetIdConfig.lua`: regenerated successfully; Royal Pass cosmetic IDs remain nil with `MANUAL_REQUIRED` comments.
- Monetization registry fixed: developer products and passes remain populated; subscriptions and UGC items are empty and marked `NOT_IMPLEMENTED` metadata.
- DayCard CosmeticPreview wired: PASS. `src/client/UI/Main.lua` now resolves `AssetIdConfig.RoyalPassCosmetics` and `RoyalPassConfig.TIERS`; `src/StarterGui/RoyalPassUI.model.json` has `DayCardTemplate.CosmeticPreview`.
- Rojo sourcemap: PASS (`.\.aftman\bin\rojo.exe sourcemap default.project.json`).

## Manual Required Asset IDs

- `images` / `title_investigator_setia` / `assets/ui/title_investigator_setia_title.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `border_haunted_frame` / `assets/ui/border_haunted_frame_border.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `emote_pasrah_bow` / `assets/concept/emote_pasrah_bow_emote_board.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `title_penyintas_sejati` / `assets/ui/title_penyintas_sejati_title.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_free_tier_5` / `assets/concept/royal_free_tier_5_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_premium_tier_5` / `assets/concept/royal_premium_tier_5_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_free_tier_10` / `assets/concept/royal_free_tier_10_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_premium_tier_10` / `assets/concept/royal_premium_tier_10_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_free_tier_15` / `assets/concept/royal_free_tier_15_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_premium_tier_15` / `assets/concept/royal_premium_tier_15_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_free_tier_20` / `assets/concept/royal_free_tier_20_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_premium_tier_20` / `assets/concept/royal_premium_tier_20_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_free_tier_25` / `assets/concept/royal_free_tier_25_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_premium_tier_25` / `assets/concept/royal_premium_tier_25_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_free_tier_30` / `assets/concept/royal_free_tier_30_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_premium_tier_30` / `assets/concept/royal_premium_tier_30_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_free_tier_35` / `assets/concept/royal_free_tier_35_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_premium_tier_35` / `assets/concept/royal_premium_tier_35_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_free_tier_40` / `assets/concept/royal_free_tier_40_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_premium_tier_40` / `assets/concept/royal_premium_tier_40_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_free_tier_45` / `assets/concept/royal_free_tier_45_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_premium_tier_45` / `assets/concept/royal_premium_tier_45_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_free_tier_50` / `assets/concept/royal_free_tier_50_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_premium_tier_50` / `assets/concept/royal_premium_tier_50_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_free_tier_55` / `assets/concept/royal_free_tier_55_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `royal_premium_tier_55` / `assets/concept/royal_premium_tier_55_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `title_legenda_pasrahphobia` / `assets/ui/title_legenda_pasrahphobia_title.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `badge_season_complete_free` / `assets/ui/badge_season_complete_free_badge.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `outfit_sang_ahli_season_exclusive` / `assets/concept/outfit_sang_ahli_season_exclusive_concept.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `badge_season_complete_premium` / `assets/ui/badge_season_complete_premium_badge.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `images` / `emote_pasrah_ascend` / `assets/concept/emote_pasrah_ascend_emote_board.png`: MANUAL_REQUIRED: image generation blocked; missing GEMINI_API_KEY/GOOGLE_API_KEY/GOOGLE_APPLICATION_CREDENTIALS during generate_visual.py run.
- `meshes` / `royal_free_tier_5` / `assets/models/fbx/royal_free_tier_5_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_premium_tier_5` / `assets/models/fbx/royal_premium_tier_5_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_free_tier_10` / `assets/models/fbx/royal_free_tier_10_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_premium_tier_10` / `assets/models/fbx/royal_premium_tier_10_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_free_tier_15` / `assets/models/fbx/royal_free_tier_15_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_premium_tier_15` / `assets/models/fbx/royal_premium_tier_15_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_free_tier_20` / `assets/models/fbx/royal_free_tier_20_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_premium_tier_20` / `assets/models/fbx/royal_premium_tier_20_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_free_tier_25` / `assets/models/fbx/royal_free_tier_25_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_premium_tier_25` / `assets/models/fbx/royal_premium_tier_25_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_free_tier_30` / `assets/models/fbx/royal_free_tier_30_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_premium_tier_30` / `assets/models/fbx/royal_premium_tier_30_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_free_tier_35` / `assets/models/fbx/royal_free_tier_35_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_premium_tier_35` / `assets/models/fbx/royal_premium_tier_35_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_free_tier_40` / `assets/models/fbx/royal_free_tier_40_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_premium_tier_40` / `assets/models/fbx/royal_premium_tier_40_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_free_tier_45` / `assets/models/fbx/royal_free_tier_45_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_premium_tier_45` / `assets/models/fbx/royal_premium_tier_45_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_free_tier_50` / `assets/models/fbx/royal_free_tier_50_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_premium_tier_50` / `assets/models/fbx/royal_premium_tier_50_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_free_tier_55` / `assets/models/fbx/royal_free_tier_55_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `royal_premium_tier_55` / `assets/models/fbx/royal_premium_tier_55_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `meshes` / `outfit_sang_ahli_season_exclusive` / `assets/models/fbx/outfit_sang_ahli_season_exclusive_model.fbx`: MANUAL_REQUIRED: Cube generation blocked; missing Cube model weights shape_gpt.safetensors and shape_tokenizer.safetensors.
- `textures` / `royal_free_tier_5` / `assets/models/fbx/royal_free_tier_5_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_premium_tier_5` / `assets/models/fbx/royal_premium_tier_5_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_free_tier_10` / `assets/models/fbx/royal_free_tier_10_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_premium_tier_10` / `assets/models/fbx/royal_premium_tier_10_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_free_tier_15` / `assets/models/fbx/royal_free_tier_15_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_premium_tier_15` / `assets/models/fbx/royal_premium_tier_15_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_free_tier_20` / `assets/models/fbx/royal_free_tier_20_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_premium_tier_20` / `assets/models/fbx/royal_premium_tier_20_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_free_tier_25` / `assets/models/fbx/royal_free_tier_25_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_premium_tier_25` / `assets/models/fbx/royal_premium_tier_25_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_free_tier_30` / `assets/models/fbx/royal_free_tier_30_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_premium_tier_30` / `assets/models/fbx/royal_premium_tier_30_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_free_tier_35` / `assets/models/fbx/royal_free_tier_35_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_premium_tier_35` / `assets/models/fbx/royal_premium_tier_35_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_free_tier_40` / `assets/models/fbx/royal_free_tier_40_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_premium_tier_40` / `assets/models/fbx/royal_premium_tier_40_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_free_tier_45` / `assets/models/fbx/royal_free_tier_45_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_premium_tier_45` / `assets/models/fbx/royal_premium_tier_45_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_free_tier_50` / `assets/models/fbx/royal_free_tier_50_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_premium_tier_50` / `assets/models/fbx/royal_premium_tier_50_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_free_tier_55` / `assets/models/fbx/royal_free_tier_55_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `royal_premium_tier_55` / `assets/models/fbx/royal_premium_tier_55_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `textures` / `outfit_sang_ahli_season_exclusive` / `assets/models/fbx/outfit_sang_ahli_season_exclusive_diffuse.png`: MANUAL_REQUIRED: texture generation blocked because paired Cube mesh generation could not run without Cube model weights.
- `animations` / `emote_pasrah_bow` / `assets/animations/rbxanim/emote_pasrah_bow_emote.rbxanim`: MANUAL_REQUIRED: no uploadable .rbxanim animation file generated in this source-only run.
- `animations` / `emote_pasrah_ascend` / `assets/animations/rbxanim/emote_pasrah_ascend_emote.rbxanim`: MANUAL_REQUIRED: no uploadable .rbxanim animation file generated in this source-only run.

## Launch Readiness

PERLU PERHATIAN.

No source/Rojo blocker remains from this prompt, but cosmetic asset launch readiness is blocked by missing generation credentials/checkpoints and missing uploaded Roblox asset IDs for all 79 cosmetic asset records.

# Dependency Setup and Cosmetic Pipeline Retry - 2026-05-23

## Scope

- Branch/worktree verified: `brian-second-final`
- Workdir verified: `C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\brian-second-final`
- Rojo project verified: `default.project.json`
- Play Test: not run
- `PASRAHPHOBIA.rbxlx`: not touched

## Paths Found

- Project launcher: `scripts\generate_visual.py`
- Global image tool: `C:\Users\User\.codex\tools\roblox-asset-workflow\generate_visual.py`
- Project launcher: `scripts\generate_cube3d.py`
- Global Cube3D tool: `C:\Users\User\.codex\tools\roblox-asset-workflow\generate_cube3d.py`
- Relevant `requirements.txt`: none found for `roblox-asset-workflow`

The project launchers already pointed at the correct `C:\Users\User\.codex\tools\roblox-asset-workflow\` paths, so no launcher code change was required.

## Cube Weights

- `shape_gpt.safetensors`: not found on `C:\`
- `shape_tokenizer.safetensors`: not found on `C:\`
- First 20 `*.safetensors`: none found on `C:\`

Mesh generation was not attempted.

## Credentials

- `GEMINI_API_KEY`: missing from User environment and local `.env`
- `GOOGLE_API_KEY`: missing from User environment
- `ROBLOX_API_KEY`: missing from User environment and local `.env`
- `ROBLOX_OPEN_CLOUD_API_KEY`: present in User environment

Created local `.env` template with owner-fill placeholders:

```text
GEMINI_API_KEY=FILL_IN_BY_OWNER
ROBLOX_API_KEY=FILL_IN_BY_OWNER
ROBLOX_UNIVERSE_ID=10138560838
ROBLOX_PLACE_ID=89787959603872
```

No API key values were written to this report.

## Dependency Setup

No tool-specific `requirements.txt` was found, so minimal dependencies were installed:

```powershell
pip install google-generativeai Pillow requests --quiet
```

Pip completed, with an existing environment warning that TensorFlow requires `numpy<2.2.0,>=1.26.0` while this Python environment currently has `numpy 2.2.6`.

## Test Generate Visual

- Command requested: `python scripts\generate_visual.py --prompt "PASRAHPHOBIA horror mystery badge dark atmospheric" --type icon --name test_setup --out-dir assets\generated\test\`
- Result: skipped before execution
- Reason: `GEMINI_API_KEY`/`GOOGLE_API_KEY` missing; per setup instruction, image generation stops until owner fills key.

## Pipeline Retry Result

- Images generated/uploaded: `0/31`
- Current registry image state: `CONFIRMED=69`, `MANUAL_REQUIRED=31`
- Meshes confirmed this run: `0/23`
- Current registry mesh state: `CONFIRMED=57`, `MANUAL_REQUIRED=23`
- Mesh blocker: Cube weights missing
- Open Cloud upload: not attempted because generation did not produce new files
- `AssetIdConfig.lua` regenerated: skipped because B4 did not pass
- `CosmeticRegistry.lua` updated with new IDs: skipped because no new IDs were generated or uploaded

## Validation

- Rojo sourcemap: pass

```powershell
.\.aftman\bin\rojo.exe sourcemap default.project.json
```

## Owner Actions Required

- Fill `GEMINI_API_KEY` in local `.env` or User environment.
- Provide/restore Cube weights on `C:\` if mesh generation should run:
  - `shape_gpt.safetensors`
  - `shape_tokenizer.safetensors`
- Provide/confirm Roblox asset upload credentials/scope for the Open Cloud asset upload step.
- After credentials and weights are ready, rerun image generation, upload, registry sync/audit/generate-lua, and cosmetic registry ID update.
- Manual animation authoring/import remains required for emote assets.

# Cube Weights Install and Cosmetic Pipeline Run - 2026-05-23

## Scope

- Branch/worktree verified: `brian-second-final`
- Workdir verified: `C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\brian-second-final`
- Rojo project verified: `default.project.json`
- Play Test: not run
- `PASRAHPHOBIA.rbxlx`: not touched

## Environment

- `GEMINI_API_KEY` loaded: SET
- `ROBLOX_API_KEY` loaded: SET
- `ROBLOX_OPEN_CLOUD_API_KEY` loaded: SET
- Secret values were not printed or written into source documentation.

## NumPy/Cube Dependency

- Global NumPy downgrade failed because `C:\Python310\Scripts\f2py.exe` was locked/permission denied.
- User-level NumPy install succeeded.
- Runtime NumPy selected by Python: `2.1.3` from `C:\Users\User\AppData\Roaming\Python\Python310\site-packages\numpy\__init__.py`

## Cube Weights

- Download source found: Hugging Face repo `Roblox/cube3d-v0.5`
- Source references found in:
  - `C:\Users\User\.codex\tools\roblox-asset-workflow\generate_cube3d.py`
  - `C:\Users\User\.codex\tools\cube\README.md`
- Installed: YES
- Install path: `C:\Users\User\.codex\tools\cube\model_weights`
- Installed files:
  - `shape_gpt.safetensors` (`7174201808` bytes)
  - `shape_tokenizer.safetensors` (`1095142004` bytes)

## Image Pipeline

- `generate_visual.py` test: FAIL
- First attempt model: `gemini-3-pro-image-preview`
- Retry model: `gemini-2.5-flash-image`
- Error: Google Gemini API returned `429 RESOURCE_EXHAUSTED`; free tier quota limit is currently `0` for the image generation models used.
- Images generated+uploaded: `0/31`
- Open Cloud image upload: not attempted because no images were generated.

## Mesh Pipeline

- `generate_cube3d.py` test: FAIL
- Error: command timed out after 30 minutes with no output `.obj` written under `assets\generated\test_mesh\`.
- Meshes generated+uploaded: `0/23`
- Open Cloud mesh upload: not attempted because no mesh files were generated.

## Registry and Lua

- `python tools\asset_id_manager\registry_manager.py --sync`: PASS
- `python tools\asset_id_manager\registry_manager.py --audit`: PASS with expected missing cosmetic assets still reported
- `python tools\asset_id_manager\registry_manager.py --generate-lua`: PASS
- `AssetIdConfig.lua` regenerated: PASS
- Current missing cosmetic state after sync:
  - Images: `PENDING=31`
  - Meshes: `PENDING=23`

## Validation

- Rojo sourcemap: PASS

```powershell
.\.aftman\bin\rojo.exe sourcemap default.project.json
```

## Owner Actions Required

- Resolve Google Gemini image-generation quota/billing for the project key, then rerun image generation.
- Investigate Cube runtime performance/GPU readiness; weights are installed, but a single test generation did not finish within 30 minutes.
- After successful generation, run Open Cloud upload and update the registry with confirmed asset IDs.
- Manual animation authoring/import remains required for emote assets.

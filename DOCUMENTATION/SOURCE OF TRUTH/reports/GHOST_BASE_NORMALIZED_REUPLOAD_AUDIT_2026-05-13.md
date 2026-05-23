# Ghost Base Normalized Reupload Audit - 2026-05-13

Owner context: Miftah  
Branch: `brian-second-final`  
Creator target: `PASRAHPHOBIA DEVELOPER & TEAM` / group id `407883270`

## Summary

The first Open Cloud upload proved that `.fbx` model upload preserves skinned mesh data, but the non-normalized candidates imported at roughly 100x scale in Studio. Those first asset IDs are superseded and must not be wired.

All eight failed ghosts were then normalized in Blender without overwriting source. The normalized candidates were uploaded again through Open Cloud as `Model` assets, then audited in the open Roblox Studio instance with `InsertService:LoadAsset`.

## Final Normalized Base Rig Asset IDs

| Ghost | Asset ID | Studio Audit |
|---|---:|---|
| `Genderuwo` | `116514308503184` | pass: `HasSkinnedMesh=true`, 54 bones |
| `HantuTanah` | `97068595212213` | pass: `HasSkinnedMesh=true`, 54 bones |
| `Kuntilanak` | `111714179492317` | pass: `HasSkinnedMesh=true`, 54 bones |
| `Leak` | `98855032697085` | pass: `HasSkinnedMesh=true`, 54 bones |
| `Palasik` | `78260225419720` | pass: `HasSkinnedMesh=true`, 11 bones |
| `Pocong` | `135270375666027` | pass: `HasSkinnedMesh=true`, 16 bones |
| `Tuyul` | `128588579954533` | pass: `HasSkinnedMesh=true`, 54 bones |
| `WeweGombel` | `101666948803556` | pass: `HasSkinnedMesh=true`, 54 bones |

## Runtime Wiring

`src/shared/GameData/GhostVisualTuning.lua` now points these eight ghosts and their variants to the normalized asset IDs above. The four previously valid base rigs remain unchanged:

- `Banaspati`: `125985418520274`
- `Jerangkong`: `115554451751983`
- `SilumanUlar`: `87361945667344`
- `SundelBolong`: `89326336764042`

Studio smoke through `GhostSystem.Service:InitializeMatch` passed for all 17 ghost keys/variants checked: every spawned model was non-placeholder, loaded from the expected asset ID, and contained a skinned `MeshPart`.

## Artifacts

- Normalized FBX folder: `.codex/asset-imports/20260513-ghost-base-reexport/normalized-base/`
- Normalized Blender audit: `.codex/asset-imports/20260513-ghost-base-reexport/normalized-fbx-audit.clean.json`
- Normalized bounds audit: `.codex/asset-imports/20260513-ghost-base-reexport/normalized-fbx-bounds-audit.clean.json`
- Final Open Cloud upload result: `.codex/asset-imports/20260513-ghost-base-reexport/roblox-base-model-upload-results-normalized.json`
- Upload plan/wrapper:
  - `scripts/build-ghost-base-model-upload-plan.ps1`
  - `scripts/upload-ghost-base-model-fbx-assets.ps1`

## Superseded Asset IDs

These non-normalized Open Cloud upload IDs were skinned but too large in Studio and must not be wired:

| Ghost | Superseded Asset ID |
|---|---:|
| `Genderuwo` | `82638532868847` |
| `HantuTanah` | `115320156428584` |
| `Kuntilanak` | `94393111953033` |
| `Leak` | `80870829207287` |
| `Palasik` | `113488185517800` |
| `Pocong` | `85253366187189` |
| `Tuyul` | `106897150032423` |
| `WeweGombel` | `117399472274369` |

## Next Gate

Do not start bulk animation upload until at least one normalized reupload ghost opens in Animation Editor and one clip imports cleanly onto that normalized base rig.

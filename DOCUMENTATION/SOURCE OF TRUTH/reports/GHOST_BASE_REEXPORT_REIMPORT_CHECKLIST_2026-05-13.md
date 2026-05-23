# Ghost Base Reexport Reimport Checklist - 2026-05-13

## Ringkasan

Delapan asset ghost lama di Roblox masih static (`HasSkinnedMesh=false`). Candidate baru di bawah `.codex/asset-imports/20260513-ghost-base-reexport/skinned-base/` diekspor ulang dari file `Manifest` `.blend` dan sudah memiliki armature, vertex group, weighted vertices, serta Armature modifier.

Jangan wire runtime asset ID sampai semua asset ID baru selesai di-upload dan diverifikasi.

Audit JSON bersih untuk scripting lanjutan:

- `.codex/asset-imports/20260513-ghost-base-reexport/reexport-fbx-audit.clean.json`
- `.codex/asset-imports/20260513-ghost-base-reexport/reexport-fbx-bounds-audit.clean.json`

## Urutan Reimport Direkomendasikan

| Urutan | Ghost | Candidate FBX | Expected bones | Weighted vertices | Bounds audit | Catatan |
|---:|---|---|---:|---:|---|---|
| 1 | Genderuwo | `C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\asset-imports\20260513-ghost-base-reexport\normalized-base\Genderuwo\Genderuwo_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx` | 54 | 4649 | `1.07, 0.35, 1.10` | Normalized; Studio upload audit pass. |
| 2 | HantuTanah | `C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\asset-imports\20260513-ghost-base-reexport\normalized-base\HantuTanah\HantuTanah_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx` | 54 | 4630 | `0.98, 0.42, 1.11` | Normalized; Studio upload audit pass. |
| 3 | Kuntilanak | `C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\asset-imports\20260513-ghost-base-reexport\normalized-base\Kuntilanak\Kuntilanak_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx` | 54 | 4647 | `1.09, 0.29, 1.17` | Normalized; Studio upload audit pass. |
| 4 | Tuyul | `C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\asset-imports\20260513-ghost-base-reexport\normalized-base\Tuyul\Tuyul_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx` | 54 | 4640 | `1.21, 0.34, 1.12` | Normalized; Studio upload audit pass. |
| 5 | WeweGombel | `C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\asset-imports\20260513-ghost-base-reexport\normalized-base\WeweGombel\WeweGombel_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx` | 54 | 4626 | `0.78, 0.41, 1.15` | Normalized; Studio upload audit pass. |
| 6 | Leak | `C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\asset-imports\20260513-ghost-base-reexport\normalized-base\Leak\Leak_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx` | 54 | 8486 | `0.76, 0.84, 1.05` | Normalized; Studio upload audit pass. |
| 7 | Palasik | `C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\asset-imports\20260513-ghost-base-reexport\normalized-base\Palasik\Palasik_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx` | 11 | 9276 | `1.53, 0.98, 1.63` | Normalized; Studio upload audit pass. |
| 8 | Pocong | `C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\asset-imports\20260513-ghost-base-reexport\normalized-base\Pocong\Pocong_RIG_BASE_REEXPORT_SKINNED_NORMALIZED.fbx` | 16 | 4643 | `0.51, 0.24, 1.86` | Normalized candidate; mesh/armature scale audited as `1,1,1`. |

## Roblox Studio Import Settings

- Creator/team: `PASRAHPHOBIA DEVELOPER & TEAM`.
- Aktifkan `Import as Package`.
- Orientation: `World Forward = Front`, `World Up = Top`.
- Scale: `Scale Unit = Stud`.
- `Keep Zero Influence Bones` boleh aktif, tetapi texture/material tetap harus diverifikasi terpisah.
- Base rig only: jangan upload animation clip dari dialog base rig.

## Open Cloud Alternative

- Model upload can be attempted with `scripts/build-ghost-base-model-upload-plan.ps1` then `scripts/upload-ghost-base-model-fbx-assets.ps1`.
- The plan uses `Model` asset type, `model/fbx`, and group creator id `407883270`.
- Even if upload succeeds, each returned asset ID must still pass `InsertService:LoadAsset` + `HasSkinnedMesh=true` before runtime wiring.

## Smoke Check Setelah Upload

1. Catat asset ID baru, tetapi jangan wire ke runtime dulu.
2. Di Command Bar/Studio test, load asset:

```lua
local assetId = 0 -- ganti dengan asset ID baru
local asset = game:GetService("InsertService"):LoadAsset(assetId)
asset.Parent = workspace
print(asset:GetFullName())
```

3. Inspect hasil import:

- `MeshPart.HasSkinnedMesh == true`.
- Bone count terlihat di Explorer dan sesuai tabel.
- Animation Editor bisa membuka rig tanpa error.
- Mesh tampil dengan scale wajar, terutama `Pocong` dan `WeweGombel`.
- Texture/material terlihat benar; kalau missing, perbaiki texture upload/mapping sebelum asset dianggap verified.

## Gate Sebelum Wiring Runtime

Runtime asset IDs baru hanya boleh dipasang setelah semua ghost yang diperlukan punya asset ID baru dan smoke check di atas lulus. Asset lama yang masih `HasSkinnedMesh=false` tidak boleh dianggap pengganti final untuk rig animatable.

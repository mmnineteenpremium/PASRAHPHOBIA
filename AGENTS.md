# PASRAHPHOBIA Agent Memory

## Required Asset Workflow

- Selalu lihat skill yang relevan sebelum mengubah aset, UI, model 3D, animasi, Roblox Studio, Rojo, upload, atau pipeline asset ID.
- Untuk gambar ikon, billboard, UI, border, overlay statis, HUD statis, atau reference sheet, gunakan:
  `python scripts/generate_visual.py --prompt "<perintah>" --type <icon|billboard|ui|reference>`
- Output default gambar masuk ke:
  `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\[SECOND ACCOUNT]\`
- Untuk permintaan model 3D, buat reference image dulu:
  `python scripts/generate_visual.py --prompt "<perintah>" --type reference`
- Setelah reference dianalisis, jangan membuat model 3D basic kecuali diminta eksplisit. Instruksikan Roblox Studio MCP/Cube/Blender agar output dipisah per komponen siap rigging dan animasi.
- Prioritas 3D: Roblox Studio MCP `/generate_procedural_model` atau tool Studio setara, lalu Cube3D lokal, lalu Tripo3D bila tersedia/diminta, lalu Blender.
- Prioritas animasi: Roblox Studio tooling/Animation Editor, lalu Blender.
- Jika Studio MCP offline atau pengguna meminta file mentah, gunakan wrapper Cube lokal:
  `python scripts\generate_cube3d.py --prompt "<prompt>"`
  dan simpan mesh `.obj/.fbx` low-poly bersama hasil `generate_visual.py`.

## Rojo and Branch Guard

- Sebelum write/import/upload/sync, cek branch dan Rojo project:
  `git status --short --branch`
  `default.project.json`
- Jangan memuat atau mengupload dari worktree lain. Default branch kerja ini adalah `brian-second-final`.
- Hindari perubahan pada file owner/user yang tidak terkait dengan asset workflow ini.

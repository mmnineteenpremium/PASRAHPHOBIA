# PASRAHPHOBIA Asset Audit

Tanggal audit: 2026-03-31  
Mode: READ ONLY (tanpa perubahan kode/sistem; hanya pembuatan laporan)

Basis audit:
- Struktur file di `src/`
- Requirement UI di `DOCUMENTATION/PASRAHPHOBIA_UI_REQUIREMENTS.md`
- Wiring runtime dari script client/server

## 1) UI
Ringkasan kebutuhan vs tersedia:
- Modul UI wajib (JournalUI, LobbyUI, MatchUI, ProfileUI, ShopUI, RoyalPassUI): dibutuhkan `6`, tersedia `5` (folder `RoyalPassUI` belum ada)
- Template StarterGui (Leaderboard, Lobby, MainMenu, Match, PASRA_UI, Shop, Spectator): dibutuhkan `7`, tersedia `7`
- Elemen visual statis (icon/image button/map preview art): dibutuhkan untuk flow UI utama, tersedia sangat minim (image/icon produksi belum terpasang)

| Nama asset | Status | Catatan kebutuhan |
|---|---|---|
| `StarterGui/*.model.json` (7 screen utama) | ADA | Struktur screen dasar ada, tapi sebagian UI dibangun runtime lewat script. |
| `src/client/UI/JournalUI` | PLACEHOLDER | Folder ada tapi kosong (belum ada modul implementasi). |
| `src/client/UI/LobbyUI` | PLACEHOLDER | Folder ada tapi kosong. |
| `src/client/UI/MatchUI` | PLACEHOLDER | Folder ada tapi kosong. |
| `src/client/UI/ProfileUI` | PLACEHOLDER | Folder ada tapi kosong. |
| `src/client/UI/ShopUI` | PLACEHOLDER | Folder ada tapi kosong. |
| `src/client/UI/RoyalPassUI` | BELUM ADA | Requirement ada, folder/modul belum ditemukan. |
| Vignette HUD image (`HorrorHUD.luau`) | PLACEHOLDER | Masih `rbxassetid://YOUR_VIGNETTE_TEXTURE_ID`. |
| Map preview image panel (`UI/Main.lua`) | PLACEHOLDER | Masih `MapPlaceholder` / `MapImagePlaceholder` teks dummy. |
| Icon set tombol/item UI | BELUM ADA | Tidak ditemukan pipeline icon/image terpasang untuk shop/item/map cards. |

## 2) Audio
Ringkasan kebutuhan vs tersedia:
- Kategori audio runtime (`Ambient`, `Environmental`, `Fear`, `Ghost`, `Hunt`): dibutuhkan `5`, terisi jelas `4` (kategori `Fear` belum punya asset khusus)
- File audio di `ReplicatedStorage/Assets/Audio`: tersedia `6`
- Raw source audio di `src/Asset Project/*.mp3`: tersedia, tapi belum terlihat terintegrasi ke runtime asset folder

Update 2026-04-08:
- bagian audit ini sudah **stale** untuk owner audio canonical utama
- slot berikut sekarang **sudah terisi** dengan asset upload Roblox akun aktif dan tidak lagi boleh dibaca sebagai placeholder kosong:
  - `AmbientLoop_Main`
  - `EnvironmentalCreak_01`
  - `GhostWhisper_01`
  - `ButtonClick_01`
  - `CountdownTick_01`
  - `TeleportDrop_01`
- tambahan owner script aktif juga sudah tersinkron:
  - `DoorRuntime` default open/close
  - `FlashlightConfig.sound.soundId`
- rujukan canonical terbaru:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/ROBLOX_INVENTORY_SYNC_LEDGER_2026-04-08.md`
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/ASSET_LICENSE_LEDGER_2026-04-03.md`

| Nama asset | Status | Catatan kebutuhan |
|---|---|---|
| `Assets/Audio/Ambient/AmbientLoop_Main` | PLACEHOLDER | Ada file, tapi ID termasuk daftar `BROKEN_IDS` di `AudioSanitizer` (berpotensi diganti runtime). |
| `Assets/Audio/Environment/EnvironmentalCreak_01` | PLACEHOLDER | Sama: ID termasuk `BROKEN_IDS`. |
| `Assets/Audio/Ghost/GhostManifest_01` | PLACEHOLDER | ID termasuk `BROKEN_IDS`. |
| `Assets/Audio/Ghost/GhostWhisper_01` | PLACEHOLDER | ID termasuk `BROKEN_IDS`. |
| `Assets/Audio/Ghost/HuntStart_01` | PLACEHOLDER | ID termasuk `BROKEN_IDS`. |
| `Assets/Audio/Jumpscare/Jumpscare_01` | ADA | SoundId valid dan tidak ditandai broken di sanitizer. |
| Heartbeat fallback (`AudioController.luau`) | PLACEHOLDER | Fallback masih `rbxassetid://YOUR_HEARTBEAT_ID`. |
| Heartbeat (`SanityVFX.client.lua`) | PLACEHOLDER | Komentar masih “Replace with actual heartbeat sound”. |
| Kategori `FearAudio` dedicated asset bank | BELUM ADA | Event category ada di `SoundSystem`, folder/asset spesifik belum ada. |
| Raw MP3 di `src/Asset Project/` | PLACEHOLDER | Bahan mentah ada, belum terlihat dipublish jadi asset runtime terhubung. |

## 3) 3D Asset / Model
Ringkasan kebutuhan vs tersedia:
- Ghost type gameplay: `12` tipe
- Ghost model runtime per tipe: `0` model final ditemukan
- Map investigasi server runtime: `4` (AbandonedPalace, EmptyBuilding, HauntedHouse, StudioMMNineteen)

| Nama asset | Status | Catatan kebutuhan |
|---|---|---|
| Model ghost per tipe (12 jenis) | BELUM ADA | Tidak ditemukan folder model ghost final di `ReplicatedStorage/Assets`. |
| Ghost visual runtime (`GhostSystem/Service.lua`) | PLACEHOLDER | Masih `createVisibleGhostPlaceholder` berbasis Part sederhana. |
| Map investigasi (4 model di `ServerStorage/Maps`) | ADA | Tersedia dan dipakai runtime match. |
| LobbySocialHub map (`Workspace/Maps/LobbySocialHub`) | ADA | Tersedia untuk area lobby. |
| Furniture/props mesh set | PLACEHOLDER | Map didominasi `Part` (MeshPart/Union nyaris tidak ada), indikasi blockout/placeholder visual. |
| PowerBreakerSwitch model | ADA | Ada di `ReplicatedStorage/Maps/AbandonedPalace/PowerBreakerSwitch.model.json`. |

## 4) Tools / Item
Ringkasan kebutuhan vs tersedia:
- Evidence tools logic: dibutuhkan `6`, tersedia `6` modul client
- Model tool fisik (EMF/UV/SpiritBox/dll): belum ditemukan implementasi asset final
- Shop catalog item: `14` item data, tetapi referensi icon/model item belum ada

| Nama asset | Status | Catatan kebutuhan |
|---|---|---|
| Evidence tool modules (`JejakEnergi`, `KotakArwah`, `SuhuMembeku`, `BukuTerkutuk`, `BolaArwah`, `GerakanGaib`) | ADA | Logic adapter ada, request tool ke server berjalan via `EvidenceRequest`. |
| Behavior unik per tool | PLACEHOLDER | Semua tool memakai `ToolClient` generik + payload default; belum tampak peralatan visual/UX unik. |
| EMFReader tool model | BELUM ADA | `EMFReaderGUI.client.lua` menunggu `EMFReader` di character, tetapi asset/model tidak ditemukan. |
| UV Flashlight item model final | BELUM ADA | Tidak ada model item final; FPV flashlight dibentuk procedural di camera controller. |
| Spirit Box / Buku / Thermometer / Orb tool model final | BELUM ADA | Tidak ditemukan model fisik tool di folder asset runtime. |
| Shop item visual (icon/mesh untuk 14 item) | BELUM ADA | Catalog data ada, tapi tidak ada mapping icon/model per item. |

## 5) Animation
Ringkasan kebutuhan vs tersedia:
- Ghost animation event utama: dibutuhkan `5`, tersedia `5`
- Viewmodel/character custom animation set: belum ditemukan

| Nama asset | Status | Catatan kebutuhan |
|---|---|---|
| `GhostIdle`, `GhostManifest`, `GhostHunt`, `GhostAttack`, `GhostJumpscare` | ADA | Animation asset tersedia di `ReplicatedStorage/Assets/Animations/Ghosts`. |
| Loop metadata (`BoolValue Looped`) pada ghost anim | ADA | Loop flag tersedia per clip. |
| Per-ghost-type animation variants (12 ghost) | BELUM ADA | Semua ghost share set event anim umum, belum terlihat varian unik per tipe. |
| Viewmodel equip/use/reload style animation | BELUM ADA | Tidak ada library animation viewmodel khusus. |
| Character investigasi custom animation pack | BELUM ADA | Tidak ditemukan pack anim karakter terpisah dari default Roblox. |
| Animator targeting spesifik ghost rig | PLACEHOLDER | Pipeline mencari animator pertama di Workspace (berisiko salah target). |

## 6) VFX / Particles
Ringkasan kebutuhan vs tersedia:
- VFX dasar (blur, color correction, atmosphere, spectator distortion): ada
- Beberapa endpoint/event dan tekstur masih placeholder/mismatch

| Nama asset | Status | Catatan kebutuhan |
|---|---|---|
| Sensory VFX (`VFXController`) | ADA | Runtime post-processing aktif (ColorCorrection/Blur/Atmosphere). |
| Cold breath particle | ADA | Procedural particle emitter ada (`EvidenceVFX.client.lua`). |
| UV fingerprint decal | ADA | Decal dibuat runtime dengan texture ID. |
| Toun/orb visual | PLACEHOLDER | Masih bola neon procedural sederhana. |
| HUD vignette texture (HorrorHUD) | PLACEHOLDER | Masih token `YOUR_VIGNETTE_TEXTURE_ID`. |
| Sanity vignette texture/audio (`SanityVFX`) | PLACEHOLDER | Komentar “replace with actual” masih ada. |
| `TemperatureUpdate` RemoteEvent (untuk `EvidenceVFX`) | BELUM ADA | Script menunggu event ini, file remote tidak ditemukan. |
| `SanityUpdate` RemoteEvent (untuk `SanityVFX`) | BELUM ADA | Yang tersedia `SanityEvent`, bukan `SanityUpdate`. |
| `EMFUpdate` RemoteEvent (untuk EMF GUI) | BELUM ADA | Event tidak ditemukan di `ReplicatedStorage/RemoteEvents`. |

## 7) Data / Config
Ringkasan kebutuhan vs tersedia:
- Ghost types config: dibutuhkan `12`, tersedia `12`
- Evidence types config: dibutuhkan `6`, tersedia `6`
- Map config modules: dibutuhkan `5` (termasuk lobby), tersedia `5`
- Beberapa namespace `shared/DataTypes/*` masih kosong

| Nama asset | Status | Catatan kebutuhan |
|---|---|---|
| `shared/GameData/Ghosts/*.lua` (12 ghost types) | ADA | Data ghost lengkap untuk gameplay logic. |
| `shared/GameData/EvidenceConfig.lua` (6 evidence) | ADA | Mapping evidence-tool tersedia. |
| `shared/GameData/Maps/*.lua` (5 map config) | ADA | Konfigurasi map tersedia. |
| `ReplicatedStorage/Config/GhostTypes.model.json` | ADA | Konfigurasi ghost tersedia. |
| `ReplicatedStorage/Config/EvidenceCombinations.model.json` | ADA | Kombinasi evidence tersedia. |
| `ReplicatedStorage/Config/Escalation.model.json` | ADA | Tahapan escalation tersedia. |
| `ReplicatedStorage/Config/DifficultyModes.model.json` | ADA | Difficulty config tersedia. |
| `shared/DataTypes/Audio/*` | BELUM ADA | Struktur folder ada, file definisi belum ada. |
| `shared/DataTypes/Director/*` | BELUM ADA | Struktur folder ada, file belum ada. |
| `shared/DataTypes/GhostModifiers/*` | BELUM ADA | Struktur folder ada, file belum ada. |
| `shared/DataTypes/MapEvents/*` | BELUM ADA | Struktur folder ada, file belum ada. |
| `shared/DataTypes/MapInteraction/*` | BELUM ADA | Struktur folder ada, file belum ada. |
| `shared/DataTypes/Rank/*` | BELUM ADA | Struktur folder ada, file belum ada. |
| `shared/DataTypes/Rooms` selain `RoomTypes` | BELUM ADA | `RoomGraph` / `RoomSpawnRules` belum terisi file. |

---

## Temuan Prioritas (Top Gaps)
1. Ghost visual masih placeholder procedural; model ghost final per tipe belum ada.
2. UI module folders utama masih kosong dan `RoyalPassUI` belum ada.
3. Banyak endpoint lama belum sinkron (`SanityUpdate`, `TemperatureUpdate`, `EMFUpdate`).
4. Audio pipeline masih memiliki placeholder guard/sanitizer yang menandai sebagian ID existing sebagai broken.
5. Tool/item visual assets (model/icon) belum terpasang meski logic dasar sudah ada.

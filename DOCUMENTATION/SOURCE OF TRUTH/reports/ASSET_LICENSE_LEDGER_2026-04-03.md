# Asset License Ledger 2026-04-03

## Tujuan

Ledger ini mencatat asset eksternal yang benar-benar terlihat di source aktif hari ini, lalu menandai status publish gate-nya.

Aturan baca:

- `verified` = ada bukti source/licensing yang sudah terdokumentasi di repo atau source resmi internal
- `user-asserted` = asal asset disebutkan oleh user saat sesi ini, tetapi bukti lisensi belum diarsipkan di repo
- `unknown` = asset ada di source aktif, tetapi asal/ownership belum terdokumentasi
- `replace/remove` = asset sudah jelas tidak layak dibiarkan menuju publish

## Active Runtime Assets

### Ghost visual

1. `Pocong` mesh pack
   - Mesh:
     - `rbxassetid://118360815663860`
   - Textures:
     - `rbxassetid://119582538265133`
     - `rbxassetid://133491195386808`
     - `rbxassetid://108763420495258`
     - `rbxassetid://112794460017202`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Models/Ghosts/Pocong.model.json`
     - `src/ReplicatedStorage/Assets/GhostVisualProfiles/Pocong.lua`
   - Provenance status:
     - `verified`
   - Notes:
     - source diverifikasi langsung pada `2026-04-05` ke halaman final `https://sketchfab.com/3d-models/pocong-d84121c5b6084c72851113afbdbd5b99`
     - author terverifikasi: `alterego.visual`
     - lisensi terverifikasi: `CC BY 4.0`
     - repo sekarang menyimpan katalog attribution runtime di `src/shared/DataTypes/AssetAttributionCatalog.lua`
   - Publish gate:
     - pastikan attribution text tetap tampil di experience/credits saat layout final sudah dikunci

### Audio active

1. `Heartbeat`
   - Asset:
     - `rbxassetid://138884191945388`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/Sensory/Heartbeat.model.json`
   - Provenance status:
     - `verified`
   - Notes:
     - validasi live `MarketplaceService:GetProductInfo()` pada `2026-04-03` menunjukkan:
       - `Creator = ZyraaaVex`
       - `AssetTypeId = 3`
     - asset ini sekarang dianggap internal/account-owned untuk workspace aktif ini

2. `EnvironmentalCreak_01`
   - Asset:
     - `rbxassetid://139204195403262`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/Environment/EnvironmentalCreak_01.model.json`
   - Provenance status:
     - `verified`
   - Notes:
     - validasi live `MarketplaceService:GetProductInfo()` pada `2026-04-03` menunjukkan creator `ZyraaaVex`
     - validasi client live menunjukkan `EnvironmentalAudioRuntime` benar-benar `IsPlaying = true`

3. `GhostManifest_01`
   - Asset:
     - `rbxassetid://83336813491039`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/Ghost/GhostManifest_01.model.json`
   - Provenance status:
     - `verified`
   - Notes:
     - validasi live `MarketplaceService:GetProductInfo()` pada `2026-04-03` menunjukkan creator `ZyraaaVex`
     - validasi client live menunjukkan `GhostAudioRuntime` benar-benar `IsPlaying = true`
     - asset ini sekarang juga dipakai oleh `src/ReplicatedStorage/Assets/Audio/Ghost/GhostWhisper_01.model.json`
     - validasi client live `2026-04-03` membuktikan template `GhostWhisper_01` sekarang `IsLoaded = true` dan `IsPlaying = true` setelah restart playtest

4. `HuntStart_01`
   - Asset:
     - `rbxassetid://138329686293368`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/Ghost/HuntStart_01.model.json`
   - Provenance status:
     - `verified`
   - Notes:
     - validasi live `MarketplaceService:GetProductInfo()` pada `2026-04-03` menunjukkan creator `ZyraaaVex`
     - dipakai juga sebagai `TeleportDrop_01`
     - validasi client live menunjukkan `HuntAudioRuntime` benar-benar `IsPlaying = true`

5. `CountdownTick_01`
   - Asset:
     - `rbxassetid://101202336513383`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/UI/CountdownTick_01.model.json`
   - Provenance status:
     - `verified`
   - Notes:
     - validasi live `MarketplaceService:GetProductInfo()` pada `2026-04-03` menunjukkan creator `ZyraaaVex`
     - dipakai untuk countdown overlay canonical

6. Footstep set
   - Asset IDs:
     - `rbxassetid://104336169985098`
     - `rbxassetid://79900103772577`
     - `rbxassetid://90448271562175`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/Footsteps/Woodstep_01.model.json`
     - `src/ReplicatedStorage/Assets/Audio/Footsteps/ConcreteStep_01.model.json`
     - `src/ReplicatedStorage/Assets/Audio/Footsteps/MetalStep_01.model.json`
   - Provenance status:
     - `verified`
   - Notes:
     - validasi live `MarketplaceService:GetProductInfo()` pada `2026-04-03` menunjukkan creator `ZyraaaVex`
     - asset sudah source-controlled
     - belum masuk jalur locomotion modern, jadi statusnya legal/runtime-ready tetapi belum gameplay-live

7. `Jumpscare_01`
   - Asset:
     - `rbxassetid://138186576`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/Jumpscare/Jumpscare_01.model.json`
   - Provenance status:
     - `verified`
   - Notes:
     - validasi live `MarketplaceService:GetProductInfo()` pada `2026-04-03` menunjukkan:
       - `Creator = samthemagicman`
       - `IsPublicDomain = true`
     - `AssetTypeId = 3`
     - asset ini tidak lagi dianggap abu-abu untuk publish gate

8. `ButtonClick_01`
   - Asset:
     - `rbxassetid://115959318`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/UI/ButtonClick_01.model.json`
     - `src/client/UI/Main.lua`
   - Provenance status:
     - `verified`
   - Notes:
     - `ButtonClick_01` sekarang memakai signature click runtime canonical
     - validasi live `2026-04-05` membuktikan template source membaca `rbxassetid://115959318`
   - Publish gate:
     - aman sebagai cue UI canonical saat ini
     - tetap boleh diganti nanti jika brand audio final berubah

### Animation active

1. Ghost animation pack
   - Asset IDs:
     - `rbxassetid://507771019`
     - `rbxassetid://507776043`
     - `rbxassetid://507766388`
     - `rbxassetid://507767714`
     - `rbxassetid://507777826`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Animations/Ghosts/*`
   - Provenance status:
     - `verified`
   - Notes:
     - validasi live `MarketplaceService:GetProductInfo()` pada `2026-04-03` menunjukkan creator `Roblox`
     - ID aktif saat ini memetakan ke animasi default Roblox:
       - `507771019 = R15Dance1A`
       - `507776043 = R15Dance2A`
       - `507766388 = R15Idle`
       - `507767714 = R15Run`
       - `507777826 = R15Walk`
     - secara legal/runtime lebih jelas daripada status `unknown`, tetapi tetap merupakan pack placeholder dan bukan animasi ghost final

## Active Runtime Assets That Must Be Replaced Or Documented

1. Remaining unresolved audio slots
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/Ambient/AmbientLoop_Main.model.json`
   - Provenance status:
     - `replace/remove` (until ambience final diisi lagi)
   - Notes:
     - slot ambience sengaja dikosongkan lagi (`AudioContent = ""`) untuk menghindari overlap dengan `Heartbeat`
     - sebelumnya slot ini sempat memakai ID heartbeat yang sama, sehingga diagnosis audio runtime bisa bias/dobel
     - status publish untuk ambience kembali `open` sampai asset ambience final legal di-upload
   - Replacement queue:
     - lihat `reports/AUDIO_REPLACEMENT_PLAN_2026-04-03.md` bila ingin ambience khusus brand

## Legacy-Only Assets

Asset berikut masih terlihat di source, tetapi sekarang berada pada jalur `LegacyDisabled` dan bukan owner runtime canonical:

- `rbxassetid://1885779457`
- `rbxassetid://2036442782`
- `rbxassetid://910433616998508`

Status:

- `unknown`
- tidak memblokir vertical slice runtime saat ini
- tetap perlu diputuskan saat cleanup publish final: arsipkan, dokumentasikan, atau hapus

## Minimum Publish Checklist For Licensing

1. Arsipkan bukti lisensi `Pocong` ke repo:
   - URL final
   - nama author
   - syarat attribution
   - opsional: screenshot license page bila ingin pack audit manual yang lebih lengkap
2. Finalisasi keputusan ambience loop (`AmbientLoop_Main`) apakah dipertahankan sebagai placeholder account-owned atau diganti cue brand final.
3. Upload candidate audio legal ke akun Roblox aktif lalu isi `AudioContent` source dengan asset ID final jika ingin mengganti placeholder saat ini.
4. Putuskan nasib asset `LegacyDisabled`:
   - hapus dari source
   - atau dokumentasikan ownership-nya
5. Jangan aktifkan monetization publik sebelum audit legacy asset tersisa ditutup dan attribution runtime final tetap terlihat jelas di experience.

## Update 2026-04-05 17:24 ICT

Validasi source eksternal `Pocong` kini ditutup lebih jauh:

- URL final terverifikasi: `https://sketchfab.com/3d-models/pocong-d84121c5b6084c72851113afbdbd5b99`
- author terverifikasi: `alterego.visual`
- lisensi terverifikasi: `CC BY 4.0`
- attribution runtime sekarang disimpan source-controlled di:
  - `src/shared/DataTypes/AssetAttributionCatalog.lua`
  - `src/client/UI/Main.lua`

Kesimpulan:

- `Pocong` tidak lagi diperlakukan sebagai `user-asserted`.
- blocker lisensi aktif kini bergeser ke cleanup asset legacy dan keputusan ambience final, bukan lagi ke provenance model `Pocong`.

## Update 2026-04-04 02:58 ICT

Audit ulang live `MarketplaceService:GetProductInfo()` untuk paket audio yang user kirim ulang menutup validasi ownership terbaru berikut:

- `Woodstep_01` (`104336169985098`) -> creator `ZyraaaVex`, `IsPublicDomain=false`
- `Heartbeat` (`138884191945388`) -> creator `ZyraaaVex`, `IsPublicDomain=false`
- `EnvironmentalCreak_01` (`139204195403262`) -> creator `ZyraaaVex`, `IsPublicDomain=false`
- `CountdownTick_01` (`101202336513383`) -> creator `ZyraaaVex`, `IsPublicDomain=false`
- `GhostManifest_01` (`83336813491039`) -> creator `ZyraaaVex`, `IsPublicDomain=false`
- `MetalStep_01` (`90448271562175`) -> creator `ZyraaaVex`, `IsPublicDomain=false`
- `ConcreteStep_01` (`79900103772577`) -> creator `ZyraaaVex`, `IsPublicDomain=false`
- `TeleportDrop_01`/`HuntStart_01` (`138329686293368`) -> creator `ZyraaaVex`, `IsPublicDomain=false`

Kesimpulan:

- daftar audio yang diaudit di atas tetap `verified` sebagai account-owned untuk workspace ini.
- blocker lisensi audio bergeser ke dokumentasi `Pocong` dan cleanup legacy, bukan lagi broken ownership batch audio.

## Update 2026-04-04 05:55 ICT

Audit live terbaru `MarketplaceService:GetProductInfo()` atas seluruh `ReplicatedStorage.Assets.Audio` aktif menunjukkan:

- total sound canonical terdeteksi: `13`
- invalid `GetProductInfo` lookup: `0`
- slot non-asset yang memang sengaja kosong:
  - `AmbientLoop_Main`

Catatan:

- `AmbientLoop_Main` sekarang memang disengaja kosong untuk menghindari overlap dengan `Heartbeat`.
- asset canonical lain tetap valid dan terbaca creator/account sesuai status sebelumnya.
- `ButtonClick_01` tidak lagi masuk slot kosong; cue ini kini memakai asset canonical final.


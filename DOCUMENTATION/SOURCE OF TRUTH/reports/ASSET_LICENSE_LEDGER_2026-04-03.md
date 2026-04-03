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
     - `user-asserted`
   - Notes:
     - user menyatakan asset berasal dari Sketchfab dan memberi short link `https://skfb.ly/pFDOZ`
     - bukti lisensi final belum diarsipkan ke repo pada batch ini
   - Publish gate:
     - simpan screenshot halaman lisensi + URL final ke repo sebelum publish
     - jangan anggap `verified` hanya karena asset sudah masuk ke Roblox account

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

2. `Jumpscare_01`
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

1. Broken ghost audio set
   - Assets:
     - `rbxassetid://1837467338`
     - `rbxassetid://9125962736`
     - `rbxassetid://1837829568`
     - `rbxassetid://9125710681`
     - `rbxassetid://1843529608`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/Ambient/AmbientLoop_Main.model.json`
     - `src/ReplicatedStorage/Assets/Audio/Environment/EnvironmentalCreak_01.model.json`
     - `src/ReplicatedStorage/Assets/Audio/Ghost/GhostManifest_01.model.json`
     - `src/ReplicatedStorage/Assets/Audio/Ghost/GhostWhisper_01.model.json`
     - `src/ReplicatedStorage/Assets/Audio/Ghost/HuntStart_01.model.json`
   - Provenance status:
     - `replace/remove`
   - Notes:
     - asset ID rusak sudah dibuang dari source aktif
     - source sekarang menyimpan placeholder kosong yang eksplisit
     - runtime boot tidak lagi menganggap mereka sebagai error
     - tetap belum layak publish sampai diganti asset final yang sah
   - Replacement queue:
     - lihat `reports/AUDIO_REPLACEMENT_PLAN_2026-04-03.md`

## Legacy-Only Assets

Asset berikut masih terlihat di source, tetapi sekarang berada pada jalur `LegacyDisabled` dan bukan owner runtime canonical:

- `rbxassetid://1885779457`
- `rbxassetid://2036442782`
- `rbxassetid://910433616998508`
- `rbxassetid://79900103772577`
- `rbxassetid://90448271562175`

Status:

- `unknown`
- tidak memblokir vertical slice runtime saat ini
- tetap perlu diputuskan saat cleanup publish final: arsipkan, dokumentasikan, atau hapus

## Minimum Publish Checklist For Licensing

1. Arsipkan bukti lisensi `Pocong` ke repo:
   - URL final
   - screenshot license page
   - nama author
   - syarat attribution
2. Ganti semua broken ghost audio yang masih `replace/remove`.
3. Upload candidate audio legal ke akun Roblox aktif lalu isi `AudioContent` source dengan asset ID final.
4. Putuskan nasib asset `LegacyDisabled`:
   - hapus dari source
   - atau dokumentasikan ownership-nya
5. Jangan aktifkan monetization publik sebelum slot audio kosong mendapat asset final yang benar-benar diunggah ke Roblox account aktif.

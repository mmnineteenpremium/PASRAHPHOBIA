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

2. `AmbientLoop_Main`
   - Asset:
     - `rbxassetid://140704980462451`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/Ambient/AmbientLoop_Main.model.json`
   - Provenance status:
     - `verified`
   - Notes:
     - asset aktif di inventory akun: `Midnight Litany of Drones (Ancient Ritual Ambient)`
     - batch `2026-04-08` menutup status kosong/placeholder ambience canonical
     - slot ini sekarang dipakai langsung oleh lookup ambience modern di client

3. `EnvironmentalCreak_01`
   - Asset:
     - `rbxassetid://111282528409948`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/Environment/EnvironmentalCreak_01.model.json`
   - Provenance status:
     - `verified`
   - Notes:
     - asset aktif di inventory akun: `door_creak_3`
     - canonical creak runtime sekarang tidak lagi berbagi ID dengan `GhostManifest_01`

4. `GhostManifest_01`
   - Asset:
     - `rbxassetid://139204195403262`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/Ghost/GhostManifest_01.model.json`
   - Provenance status:
     - `verified`
   - Notes:
     - asset aktif di inventory akun: `creaky-door-open`
     - `GhostManifest_01` dan `GhostWhisper_01` sekarang memang sudah dipisah lagi sebagai template berbeda

5. `GhostWhisper_01`
   - Asset:
     - `rbxassetid://98105844059537`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/Ghost/GhostWhisper_01.model.json`
   - Provenance status:
     - `verified`
   - Notes:
     - asset aktif di inventory akun: `ghost_whisper_3`
     - batch `2026-04-08` menutup reuse lama `GhostManifest_01` sebagai whisper

6. `HuntStart_01`
   - Asset:
     - `rbxassetid://138329686293368`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/Ghost/HuntStart_01.model.json`
   - Provenance status:
     - `verified`
   - Notes:
     - asset aktif di inventory akun: `horror-deep-drum-heartbeat`
     - `HuntStart_01` tidak lagi dibagi dengan `TeleportDrop_01`

7. `TeleportDrop_01`
   - Asset:
     - `rbxassetid://82086363159443`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/UI/TeleportDrop_01.model.json`
   - Provenance status:
     - `verified`
   - Notes:
     - asset aktif di inventory akun: `drop_002`
     - batch `2026-04-08` menutup reuse `HuntStart_01` sebagai drop cue

8. `CountdownTick_01`
   - Asset:
     - `rbxassetid://81830522846878`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/UI/CountdownTick_01.model.json`
   - Provenance status:
     - `verified`
   - Notes:
     - asset aktif di inventory akun: `tick_001`
     - dipakai untuk countdown overlay canonical

9. `ButtonClick_01`
   - Asset:
     - `rbxassetid://85056627192723`
   - Source in repo:
     - `src/ReplicatedStorage/Assets/Audio/UI/ButtonClick_01.model.json`
     - `src/client/UI/Main.lua`
   - Provenance status:
     - `verified`
   - Notes:
     - asset aktif di inventory akun: `click5`
     - batch `2026-04-08` menutup fallback lama `rbxassetid://115959318`

10. `Objective update cue`
   - Asset:
     - `rbxassetid://96021243760086`
   - Source in repo:
     - `src/client/UI/Main.lua`
   - Provenance status:
     - `verified`
   - Notes:
     - asset aktif di inventory akun: `objective_update`
     - dipakai sebagai fallback cue saat `ObjectiveLabel` berubah pada surface `Preparation / Investigation / Hunt`

11. `Lobby / invite notification cue`
   - Asset:
     - `rbxassetid://130533639073623`
   - Source in repo:
     - `src/client/UI/Main.lua`
   - Provenance status:
     - `verified`
   - Notes:
     - asset aktif di inventory akun: `ui_notification`
     - dipakai sebagai fallback cue untuk `Lobby feedback` dan `Room invite popup`

12. `Thermometer read cue`
   - Asset:
     - `rbxassetid://87230026682789`
   - Source in repo:
     - `src/client/UI/Main.lua`
   - Provenance status:
     - `verified`
   - Notes:
     - asset aktif di inventory akun: `thermometer_reading`
     - dipakai sebagai cue fallback saat `SuhuMembeku` memberikan pembacaan penting di `Field Kit`

13. `Ghost writing scratch cue`
   - Asset:
     - `rbxassetid://83865030928382`
   - Source in repo:
     - `src/client/UI/Main.lua`
   - Provenance status:
     - `verified`
   - Notes:
     - asset aktif di inventory akun: `ghost_writing_scratch`
     - dipakai sebagai cue fallback saat `BukuTerkutuk` mengunci tulisan di `Field Kit`

14. `Motion trigger cue`
   - Asset:
     - `rbxassetid://97217836947594`
   - Source in repo:
     - `src/client/UI/Main.lua`
   - Provenance status:
     - `verified`
   - Notes:
     - asset aktif di inventory akun: `motion_sensor_trigger`
     - dipakai sebagai cue fallback saat `GerakanGaib` mendeteksi gangguan di `Field Kit`

15. `Flashlight toggle`
   - Asset:
     - `rbxassetid://140513388846872`
   - Source in repo:
     - `src/shared/GameData/FlashlightConfig.lua`
   - Provenance status:
     - `verified`
   - Notes:
     - asset aktif di inventory akun: `switch15`
     - dipakai oleh toggle flashlight investigasi aktif

16. `DoorRuntime default pair`
   - Asset IDs:
     - open `rbxassetid://83005562781593`
     - close `rbxassetid://78764817933410`
   - Source in repo:
     - `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
     - `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
   - Provenance status:
     - `verified`
   - Notes:
     - asset aktif di inventory akun:
       - `doorOpen_2`
       - `doorClose_1`
     - pasangan default dunia sekarang tidak lagi memakai reuse manifest/whisper

17. Footstep set
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

18. `Jumpscare_01`
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

Tidak ada slot audio canonical yang masih kosong untuk batch active runtime saat ini.

Replacement berikutnya bersifat opsional/presentational:

1. review apakah `AmbientLoop_Main` saat ini sudah final secara brand, atau hanya baseline ambience yang cukup aman untuk sekarang
2. review apakah `GhostManifest_01` dan `HuntStart_01` perlu signature artistik yang lebih kuat pada art pass audio final

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
2. Review apakah ambience/hunt/manifest saat ini sudah final secara brand atau masih baseline inventory-owned yang akan dipoles lagi.
3. Upload candidate audio legal ke akun Roblox aktif hanya jika ingin mengganti signature yang sekarang.
4. Putuskan nasib asset `LegacyDisabled`:
   - hapus dari source
   - atau dokumentasikan ownership-nya
5. Jangan aktifkan monetization publik sebelum audit legacy asset tersisa ditutup dan attribution runtime final tetap terlihat jelas di experience.

## Update 2026-04-08 20:05 ICT

Batch canonical inventory sync menutup gap aktif berikut:

- `AmbientLoop_Main` tidak lagi kosong; sekarang memakai `rbxassetid://140704980462451`
- `EnvironmentalCreak_01` dipindah ke `rbxassetid://111282528409948`
- `GhostWhisper_01` dipindah ke `rbxassetid://98105844059537`
- `ButtonClick_01` dipindah ke `rbxassetid://85056627192723`
- `CountdownTick_01` dipindah ke `rbxassetid://81830522846878`
- `TeleportDrop_01` dipindah ke `rbxassetid://82086363159443`
- `DoorRuntime` default open/close sekarang memakai `doorOpen_2` dan `doorClose_1`
- `Flashlight toggle` sekarang memakai `switch15`

Kesimpulan:

- blocker lisensi/publish aktif kini bukan lagi slot audio canonical kosong, melainkan review brand final dan cleanup legacy asset.

## Update 2026-04-08 20:58 ICT

Batch `lobby ambient inventory audio` menutup ownership runtime untuk ambience hub:

- `LobbyAmbient` kini memakai `rbxassetid://113854211240490`
- owner runtime aktif:
  - `src/client/Controllers/Sensory/AudioController.luau`
- mode pakai:
  - hanya aktif di `LobbySocialHub`
  - otomatis fade-out saat masuk match/preparation

Kesimpulan:

- `Midnight Litany of Drones (Ancient Ritual Ambient)` sekarang bukan hanya asset inventory yang terdokumentasi, tetapi juga sudah benar-benar dipakai oleh owner runtime lobby yang aktif.

## Update 2026-04-08 21:12 ICT

Batch `cue-specific inventory audio overrides` menutup penggunaan runtime berikut:

- `switch15` (`rbxassetid://140513388846872`) -> cue `prep_focus_lock`
- `doorClose_1` (`rbxassetid://78764817933410`) -> cue `env_doorslam`, `env_windowknock`
- `impactPunch_medium_002` (`rbxassetid://126504722314888`) -> cue `env_objectthrow`, `ghost_object_throw`

Owner runtime aktif:

- `src/client/SoundSystem/Main.lua`

Kesimpulan:

- ketiga asset upload di atas sekarang bukan hanya tercatat di inventory ledger, tetapi sudah benar-benar dipakai oleh cue runtime player-facing yang sebelumnya masih jatuh ke template generik.

## Update 2026-04-08 21:25 ICT

Batch `ui surface inventory cues` menutup penggunaan runtime berikut:

- `maximize_001` (`rbxassetid://115397007938540`) -> UI `PanelOpen`
- `scroll_001` (`rbxassetid://73589904561594`) -> UI `PanelSoftClose`
- `bookFlip3` (`rbxassetid://97915135753208`) -> UI `JournalPage`
- `ui_error` (`rbxassetid://70594579947868`) -> UI `Error`

Owner runtime aktif:

- `src/client/UI/Main.lua`

Kesimpulan:

- asset UI upload di atas kini menjadi fallback runtime untuk panel/journal/error surface di owner UI existing, bukan local raw asset.

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


## 2026-04-08 22:40:12 +07:00 - Extended Inventory Audio Cue Overrides
- Owner: `src/client/SoundSystem/Main.lua`.
- Runtime now uses uploaded Roblox inventory IDs for additional cue-specific overrides:
  - `impactWood_light_001` -> `rbxassetid://71098340187847`
  - `object_fall` -> `rbxassetid://86917747509286`
  - `ghost_footstep_2` -> `rbxassetid://95974189526179`
  - `ghost_whisper_3` -> `rbxassetid://98105844059537`
  - `creaky-door-open` -> `rbxassetid://139204195403262`
  - `single-heart-beat` -> `rbxassetid://138884191945388`
  - `horror-deep-drum-heartbeat` -> `rbxassetid://138329686293368`
  - `hard-horror-hit-drum` -> `rbxassetid://101202336513383`
- These are runtime `rbxassetid://` references from the Roblox inventory sync ledger; raw local files remain source/reference only.

## 2026-04-08 22:55:25 +07:00 - Legacy Audio Cue Alias Coverage
- Owner: `src/client/SoundSystem/Main.lua`.
- The following uploaded Roblox inventory IDs are now also used by backward-compatible cue aliases:
  - `hard-horror-hit-drum` -> `rbxassetid://101202336513383`
  - `single-heart-beat` -> `rbxassetid://138884191945388`
  - `Midnight Litany of Drones (Ancient Ritual Ambient)` -> `rbxassetid://140704980462451`
- These aliases keep old/default cue names on uploaded runtime IDs without adding a duplicate audio system or local raw path.

## 2026-04-08 22:49:33 +07:00 - Expanded Inventory Audio Cue Coverage
- Owner: `src/client/SoundSystem/Main.lua`.
- Runtime now also uses uploaded Roblox inventory IDs for these additional cue-specific overrides:
  - `zap2` -> `rbxassetid://96038914699044`
  - `zap1` -> `rbxassetid://82526759214554`
  - `creaky-door-open` -> `rbxassetid://139204195403262`
  - `ghost_footstep_2` -> `rbxassetid://95974189526179`
  - `ghost_whisper_2` -> `rbxassetid://110779846516591`
  - `thermometer_reading` -> `rbxassetid://87230026682789`
  - `hard-horror-hit-drum` -> `rbxassetid://101202336513383`
  - `horror-deep-drum-heartbeat` -> `rbxassetid://138329686293368`
- These are runtime `rbxassetid://` references from the Roblox inventory sync ledger; raw local files remain source/reference only.

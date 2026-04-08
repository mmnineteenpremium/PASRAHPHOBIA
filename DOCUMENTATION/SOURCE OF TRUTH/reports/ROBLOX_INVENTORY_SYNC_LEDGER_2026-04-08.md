# Roblox Inventory Sync Ledger 2026-04-08

## Tujuan

Dokumen ini mengunci snapshot penuh inventory upload Roblox yang sekarang sudah bisa dipakai sebagai pegangan tetap, lalu menandai mana yang memang punya pasangan exact-name di raw asset lokal.

Dokumen ini dipakai untuk mencegah kebingungan berikutnya:

- asset mana yang sudah punya `rbxassetid://...`
- asset mana yang memang sudah sinkron dengan nama lokal
- asset mana yang ada di inventory Roblox tetapi belum punya pasangan exact-name di repo

## Constraint Tetap

- `asset mentah/` adalah raw source/reference, bukan runtime asset langsung.
- audio runtime harus memakai `rbxassetid://...`, bukan path lokal.
- raw asset tidak boleh di-upload, dihapus, di-rename, atau direorganize tanpa instruksi user.
- workflow tetap:
  - modify existing only
  - no duplicate systems
  - one domain = one owner

## Context Crawl

- identity cloud canonical:
  - `PlaceId = 113010869463813`
  - `GameId = 9802743087`
  - `CreatorId = 10576163165`
- source inventory:
  - `https://inventory.roblox.com/v2/users/10576163165/inventory?assetTypes=Audio`
  - `https://inventory.roblox.com/v2/users/10576163165/inventory?assetTypes=Model`
- hasil crawl:
  - `101` audio
  - `11` model

## Deep Scan Lokal

- deep scan seluruh proyek lokal menemukan:
  - `613` file audio
  - `564` nama stem unik
- sumber lokal bukan hanya `asset mentah/`, tetapi seluruh path proyek yang relevan, termasuk:
  - `asset mentah/...`
  - `src/Asset Project/...`
- konsekuensinya:
  - angka sinkronisasi lama yang memakai subset folder memang terlalu kecil

## Ringkasan Sinkronisasi Yang Sudah Dikoreksi

- inventory audio:
  - `101` row
  - `100` nama unik
- exact-name match antara inventory audio dan lokal:
  - `99 / 100` nama unik inventory
- inventory audio tanpa pasangan exact-name di lokal:
  - `1 / 100`
- local-only audio:
  - `465` nama stem unik
- model inventory dengan exact-name local match:
  - `1 / 11`
- model inventory lain tetap tercatat, tetapi tidak boleh otomatis dianggap canonical runtime hanya karena ada di inventory

## Audio Inventory Tanpa Exact-Name Local Match

- `rbxassetid://140704980462451` `Midnight Litany of Drones (Ancient Ritual Ambient)`

Catatan:

- item yang sebelumnya sempat saya tandai `inventory-only` seperti:
  - `concrete footstep`
  - `horror-deep-drum-heartbeat`
  - `metal footstep`
  - `creaking-public-toilet-door`
  - `hard-horror-hit-drum`
  - `creaky-door-open`
  - `single-heart-beat`
  - `wood footstep`
- ternyata punya pasangan lokal di `src/Asset Project/`

## Exact-Name Local Match Yang Penting

- `rbxassetid://113854211240490` `bgm_lobby_ambient`
- `rbxassetid://130533639073623` `ui_notification`
- `rbxassetid://96021243760086` `objective_update`
- `rbxassetid://97217836947594` `motion_sensor_trigger`
- `rbxassetid://83865030928382` `ghost_writing_scratch`
- `rbxassetid://98105844059537` `ghost_whisper_3`
- `rbxassetid://70594579947868` `ui_error`
- `rbxassetid://115835838848259` `error_005`
- `rbxassetid://115397007938540` `maximize_001`
- `rbxassetid://87230026682789` `thermometer_reading`
- `rbxassetid://140513388846872` `switch15`
- `rbxassetid://126504722314888` `impactPunch_medium_002`
- `rbxassetid://97915135753208` `bookFlip3`
- `rbxassetid://73589904561594` `scroll_001`

## Full Audio Inventory Snapshot

- `rbxassetid://140704980462451` `Midnight Litany of Drones (Ancient Ritual Ambient)`
- `rbxassetid://79900103772577` `concrete footstep`
- `rbxassetid://138329686293368` `horror-deep-drum-heartbeat`
- `rbxassetid://90448271562175` `metal footstep`
- `rbxassetid://83336813491039` `creaking-public-toilet-door`
- `rbxassetid://101202336513383` `hard-horror-hit-drum`
- `rbxassetid://139204195403262` `creaky-door-open`
- `rbxassetid://138884191945388` `single-heart-beat`
- `rbxassetid://104336169985098` `wood footstep`
- `rbxassetid://91537006457833` `impactGlass_medium_004`
- `rbxassetid://99206703791717` `footstep07`
- `rbxassetid://113854211240490` `bgm_lobby_ambient`
- `rbxassetid://130533639073623` `ui_notification`
- `rbxassetid://82086363159443` `drop_002`
- `rbxassetid://79633452753775` `handleCoins2`
- `rbxassetid://137641720016954` `back_001`
- `rbxassetid://125575635076419` `player_sprint_breath`
- `rbxassetid://96038914699044` `zap2`
- `rbxassetid://98260632863510` `impactPlank_medium_002`
- `rbxassetid://124295413973490` `maximize_007`
- `rbxassetid://71768378817966` `handleCoins`
- `rbxassetid://96021243760086` `objective_update`
- `rbxassetid://97217836947594` `motion_sensor_trigger`
- `rbxassetid://95974189526179` `ghost_footstep_2`
- `rbxassetid://100227475127664` `impactPunch_medium_004`
- `rbxassetid://140421467211065` `switch22`
- `rbxassetid://127687575501238` `click2`
- `rbxassetid://90124323234329` `impactMetal_light_004`
- `rbxassetid://86917747509286` `object_fall`
- `rbxassetid://86824461910995` `sanity_drop_critical`
- `rbxassetid://75947848120530` `close_004`
- `rbxassetid://129690299312401` `switch27`
- `rbxassetid://115702631323732` `impactTin_medium_003`
- `rbxassetid://129258383992443` `footstep_wood_004`
- `rbxassetid://81830522846878` `tick_001`
- `rbxassetid://109560568334184` `select_005`
- `rbxassetid://93660132903408` `bookFlip2`
- `rbxassetid://96944942194613` `impactTin_medium_002`
- `rbxassetid://71585482794966` `floor_creak_1`
- `rbxassetid://110779846516591` `ghost_whisper_2`
- `rbxassetid://128003011703421` `rollover2`
- `rbxassetid://98010660739785` `powerUp8`
- `rbxassetid://83865030928382` `ghost_writing_scratch`
- `rbxassetid://83510355175488` `impactSoft_heavy_004`
- `rbxassetid://124734666640228` `ghost_whisper_2`
- `rbxassetid://74455192150592` `impactSoft_medium_002`
- `rbxassetid://82649420531423` `switch35`
- `rbxassetid://81770012931959` `footstep08`
- `rbxassetid://108141500128247` `switch24`
- `rbxassetid://96845820080587` `impactMetal_heavy_003`
- `rbxassetid://122697573331982` `glass_001`
- `rbxassetid://76055265599224` `floor_creak_3`
- `rbxassetid://83151340264973` `mouseclick1`
- `rbxassetid://96213110904189` `impactMetal_light_003`
- `rbxassetid://106458871563801` `drawKnife1`
- `rbxassetid://99608384772952` `player_footstep_wood_4`
- `rbxassetid://82526759214554` `zap1`
- `rbxassetid://106359732483915` `switch26`
- `rbxassetid://138816284038306` `player_footstep_concrete_3`
- `rbxassetid://122070484198020` `laser2`
- `rbxassetid://131990714728003` `bookOpen`
- `rbxassetid://70602598142445` `click_002`
- `rbxassetid://104223971006120` `switch29`
- `rbxassetid://91050281705659` `minimize_001`
- `rbxassetid://115080436034064` `footstep02`
- `rbxassetid://136137693390017` `maximize_009`
- `rbxassetid://72014817104668` `player_death`
- `rbxassetid://86060096050633` `impactMetal_heavy_001`
- `rbxassetid://94639696903701` `impactMetal_heavy_000`
- `rbxassetid://78790233655754` `maximize_006`
- `rbxassetid://107429136395038` `phaseJump2`
- `rbxassetid://88387425780126` `switch19`
- `rbxassetid://74427442250051` `back_003`
- `rbxassetid://71098340187847` `impactWood_light_001`
- `rbxassetid://128180668604255` `footstep_grass_002`
- `rbxassetid://95027410279438` `bgm_gameover`
- `rbxassetid://137391660786682` `switch2`
- `rbxassetid://111282528409948` `door_creak_3`
- `rbxassetid://120903843057048` `switch34`
- `rbxassetid://83507022652442` `switch16`
- `rbxassetid://134970095301181` `impactMetal_medium_002`
- `rbxassetid://101633731744947` `highUp`
- `rbxassetid://139023108516135` `switch_005`
- `rbxassetid://85056627192723` `click5`
- `rbxassetid://74249165098262` `footstep_snow_003`
- `rbxassetid://98105844059537` `ghost_whisper_3`
- `rbxassetid://139721110689514` `footstep04`
- `rbxassetid://71785355785721` `footstep_snow_000`
- `rbxassetid://71549836702484` `impactWood_medium_001`
- `rbxassetid://129044931032356` `Preview`
- `rbxassetid://130389097187311` `impactPlate_heavy_004`
- `rbxassetid://70594579947868` `ui_error`
- `rbxassetid://115835838848259` `error_005`
- `rbxassetid://115397007938540` `maximize_001`
- `rbxassetid://83005562781593` `doorOpen_2`
- `rbxassetid://87230026682789` `thermometer_reading`
- `rbxassetid://140513388846872` `switch15`
- `rbxassetid://78764817933410` `doorClose_1`
- `rbxassetid://126504722314888` `impactPunch_medium_002`
- `rbxassetid://97915135753208` `bookFlip3`
- `rbxassetid://73589904561594` `scroll_001`

## Full Model Inventory Snapshot

- `rbxassetid://129878813436863` `dark+armored+knight+more+spikey`
- `rbxassetid://117009327297852` `genderuwo`
- `rbxassetid://119434537320191` `Scene`
- `rbxassetid://99030495222571` `Scene`
- `rbxassetid://123151303766691` ` pocong PASRAHPHOBIA`
- `rbxassetid://96614451051984` `Scene`
- `rbxassetid://93357688576883` `kuntilanak_Iv Pole Walking`
- `rbxassetid://118867381731250` `0341c93314aeb9f0e7f7bd7e09c91117`
- `rbxassetid://118178261630940` `StarterPlayer`
- `rbxassetid://516522664` `Realistic Flashlight`
- `rbxassetid://5352156968` `Time Played Leaderboard with Player Thumbnails`

## Catatan Operasional

- `switch15` dan `impactPunch_medium_002` sekarang **sudah tidak pending**; asset id keduanya sudah terkunci.
- pass sebelumnya memang salah membaca scope lokal; sekarang ledger ini memakai deep scan seluruh proyek, bukan subset folder.
- local audio memang jauh lebih besar dari inventory upload saat ini:
  - `613` file lokal
  - `564` nama stem unik
  - inventory baru `100` nama audio unik
- exact-name model match memang baru `genderuwo`; `pocong PASRAHPHIA` dan `kuntilanak_Iv Pole Walking` tetap tercatat di inventory, tetapi nama file lokal owner-nya tidak exact-match satu banding satu.
- kalau nanti ada raw asset baru yang relevan, workflow yang benar tetap:
  1. cek raw asset lokal sebagai referensi/nama canonical
  2. cek exact match ke inventory upload
  3. pakai `rbxassetid://...`
  4. pasang hanya ke owner runtime yang sudah ada

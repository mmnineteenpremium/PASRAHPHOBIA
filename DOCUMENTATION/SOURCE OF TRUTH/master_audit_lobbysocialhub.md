# MASTER AUDIT LOBBYSOCIALHUB

Tanggal audit: 2026-06-10
Mode kerja: audit dan persiapan aset, bukan coding fitur baru.
Source of truth visual: `PASRAHPHOBIA.rbxlx` yang sedang terbuka di Roblox Studio edit mode.
Source dokumen: `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md` dan `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`.

## 0. Aturan Utama

- Jangan menganggap objek masih ada di Studio hanya karena tertulis di dokumen lama.
- Jangan pakai `git` sebagai dasar audit visual atau readiness karena worktree lokal memiliki banyak perubahan belum disinkronkan.
- Jangan hapus, rename, atau replace visual owner tanpa persetujuan eksplisit.
- Jangan menghapus/rename object Studio hanya karena object itu tidak memenuhi naming/tag/attribute di file audit ini.
- Jangan menganggap kode lama sebagai legacy hanya karena dokumentasi lama stale. Banyak nama fallback di kode masih merupakan compatibility path aktif.
- Jangan memakai `LobbySocialHub_RuntimeReference(F5...)` sebagai sumber pengganti penuh.
- Jangan mempromosikan folder legacy runtime seperti `Rooms`, `GhostSpawns`, `EvidenceSpawnNodes`, atau full-runtime `SpawnPoints` dari export F5.
- Untuk runtime baru, skrip idealnya membaca root part stabil melalui attribute/tag, bukan nama visual model yang owner sering ubah.
- Attribute/tag baru di dokumen ini adalah metadata persiapan dan kontrak masa depan. Attribute/tag ini belum boleh dijadikan syarat runtime sampai kode resolver benar-benar diubah dan dites.
- Visual model boleh dihapus/rename/reimport hanya jika tidak sedang menjadi host prompt/spawn/zone yang dibaca kode sekarang.

## 0A. Kontrak Non-Destruktif Berbasis Scan Kode

Confidence audit ini 99% untuk tujuan dokumentasi non-destruktif: file ini aman dipakai sebagai checklist owner dan agent berikutnya karena tidak memerintahkan rename/delete otomatis. Confidence ini bukan izin untuk refactor besar. Setiap perubahan kode tetap wajib dites smoke.

Kontrak yang tidak boleh diganti oleh tag/attribute baru:

| Area | Kontrak aktif dari kode | Keputusan |
| --- | --- | --- |
| Room browser client | `src/client/UI/RoomBrowserController.lua` memakai `ReplicatedStorage.RemoteEvents.LobbyEvent` dan action `RequestRoomBrowserSnapshot`, `RequestRoomList`, `JoinRoom`, `QueueFromRoomBrowser`, `SetReady`, `HostStart`, `CancelHostStart`, `CreateRoom`, invite/kick/password | Jangan buat remote baru, jangan ganti action/eventName |
| Room browser server | `src/ServerScriptService/Server/LobbySystem/Controller.lua` menerima `LobbyEvent`, route action ke handler, publish `RoomBrowserSnapshot`, `RoomBrowserRoomList`, `RoomBrowserRoomJoined`, `RoomStateUpdate`, `RoomMatchStarting`, countdown, dll. | Harus dipertahankan |
| World prompt lobby | `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua` bind `QueueTrigger`, `ContractBoard`, `RoomBoard`, `PartyBoard`, `PartyPlatform`, `ShopCounter`, `Interact_Shop`, `DailyRewardTerminal`, `ToolsBoard` | Jangan hapus/rename host prompt aktif sebelum ada adapter/fallback |
| UI owner-authored | `src/client/UI/Main.lua` bind `LobbyUI`, `RoomBrowserUI`, `RoomBrowserFloatUI`, `MainMenuUI`, `LeaderboardUI` dengan guard `shouldPreserveAuthoredOwnerLayout` | Jangan buat sistem UI baru; lanjutkan binding UI yang sudah ada |
| Match flow | `LobbySystem.Controller:OnHostStart` mem-publish `RoomMatchStarting`, lalu match flow memakai `MatchEvent`, `MatchService`, `MatchCleanup`, attribute player `InMatch`, `MatchId`, `MatchLifecyclePhase` | Jangan ubah lifecycle match hanya untuk audit lobby |
| Return to lobby | `src/ServerScriptService/Server/MatchSystem/MatchCleanup.lua` mencari `LobbySpawn`, `SpawnPoints/PlayerSpawn_*`, atau `SpawnLocation` | Immediate no-code fix harus kompatibel dengan nama ini |
| Spawn lobby | `src/ServerScriptService/Server/LobbySocialHub/LobbyPlayerManager.lua` mencari `LobbySpawn`, `SpawnPoints`, `PlayerSpawn_*`, dan dapat rebuild `SpawnPoints` jika unhealthy | Buat/pertahankan `SpawnPoints` sehat; jangan hanya buat `_SpawnRoots` |
| Zone focus | `src/ServerScriptService/Server/LobbySocialHub/LobbyZoneManager.lua` membaca `workspace.LobbyZones/<ZoneName>` dulu, lalu fallback nama `Room_*`, `Interact_*`, `Door_*`, `Prop_*` | Fallback itu compatibility, bukan bukti visual harus dibuat ulang |
| Flex | `LobbyService` mem-publish `LobbyFlexSpotlightUpdated` / `LobbyFlexSpotlightCleared`; `UI/Main.lua` mengonsumsi event itu | Jangan rename event Flex, jangan invent event baru |

Larangan untuk agent berikutnya:

- Jangan menulis script yang menghapus object karena `PasrahLobbyDoNotDelete` tidak ada.
- Jangan menulis migrator yang rename object owner agar cocok dengan file ini.
- Jangan mengganti `RoomBrowserController` dengan controller baru.
- Jangan duplicate `LobbyEvent`, `MatchEvent`, atau UI ScreenGui dengan nama baru.
- Jangan mengubah `LobbyPlayerManager` untuk memakai attribute baru sebelum `MatchCleanup` ikut kompatibel.
- Jangan mematikan fallback nama lama sebelum Studio smoke test membuktikan root/tag baru terbaca.

## 1. Fakta Studio Saat Ini

Hasil pembacaan Studio edit mode pada `PASRAHPHOBIA.rbxlx`:

- `game.Workspace.Maps.LobbySocialHub.LobbySocialHub` ada.
- Child langsung lobby root hanya:
  - `Forest Portal Template`
  - `MainHubDecorRuntime`
- `MainHubDecorRuntime` ada dan memiliki attribute:
  - `PasrahImportedLobbyDecorScriptsDisabled = true`
  - `PasrahImportedLobbyDecorScriptsDisabledCount = 15`
- Tidak ada `SpawnPoints` di lobby root.
- Tidak ada `LobbySpawn`.
- Tidak ada `PlayerSpawn_1`, `PlayerSpawn_2`, `PlayerSpawn_3`, `PlayerSpawn_4`.
- Tidak ada humanoid/NPC fisik di lobby root.
- Tidak ada `ShopNPC`.
- Tidak ada `FlexDisplay`.
- Tidak ada `BillboardGui`; yang ada banyak `SurfaceGui` pada board/part visual.
- Ada 20 `ProximityPrompt` aktif di `MainHubDecorRuntime`.
- Tag yang terdeteksi di lobby saat audit hanya tag visual/vegetasi seperti `WindShake` dan `_BrushtoolBrushed`.
- Belum ada tag gameplay khusus LobbySocialHub seperti `PasrahLobbyRoot`, `PasrahLobbyInteractiveRoot`, atau sejenisnya.

Prompt aktif yang terkonfirmasi:

| Fungsi | Path Studio | ActionText | ObjectText |
| --- | --- | --- | --- |
| Match queue / room browser | `Workspace.Maps.LobbySocialHub.LobbySocialHub.MainHubDecorRuntime.Hub Mid.QueueTrigger.InteractPrompt` | `Open Room Browser` | `Queue Hub` |
| Flex spotlight | `Workspace.Maps.LobbySocialHub.LobbySocialHub.MainHubDecorRuntime.Flex.FlexStage.InteractPrompt` | `View Spotlight` | `Spotlight Stage` |
| Flex board | `Workspace.Maps.LobbySocialHub.LobbySocialHub.MainHubDecorRuntime.Flex.AnnouncementBoard.InteractPrompt` | `Read Spotlight` | `Flex Board` |
| Shop counter | `Workspace.Maps.LobbySocialHub.LobbySocialHub.MainHubDecorRuntime.Shop.ShopCounter.InteractPrompt` | `Open Shop` | `Shop Counter` |
| Shop browse | `Workspace.Maps.LobbySocialHub.LobbySocialHub.MainHubDecorRuntime.Shop.Interact_Shop.InteractPrompt` | `Browse` | `Shop` |
| Party board | `Workspace.Maps.LobbySocialHub.LobbySocialHub.MainHubDecorRuntime.Party.PartyBoard.InteractPrompt` | `Open Party` | `Party Board` |
| Party pad | `Workspace.Maps.LobbySocialHub.LobbySocialHub.MainHubDecorRuntime.Party.PartyPlatform.InteractPrompt` | `Join Party Room` | `Party Pad` |
| Daily reward | `Workspace.Maps.LobbySocialHub.LobbySocialHub.MainHubDecorRuntime.Garden.DailyRewardTerminal.InteractPrompt` | `Claim` | `Daily Reward` |
| Contract board | `Workspace.Maps.LobbySocialHub.LobbySocialHub.MainHubDecorRuntime.North.ContractBoard.InteractPrompt` | `Open Board` | `Contract Board` |
| Room board | `Workspace.Maps.LobbySocialHub.LobbySocialHub.MainHubDecorRuntime.North.TrainingGhostVisual.RoomBoard.InteractPrompt` | `Open Room Browser` | `Room Board` |

## 2. Dokumen Lama vs Realita Sekarang

### 2.1 Dokumen Yang Valid Sebagai Arah Desain

- `CANONICAL_SPECIFICATIONS_v2.md` valid sebagai target desain, tetapi tidak boleh dijadikan bukti objek fisik masih ada.
- `PASRAHPHOBIA_DOC_INDEX.md` valid sebagai index historis/agregat, tetapi file itu sendiri mengakui masih mengandung referensi historical.
- `REPORTS.md` valid untuk histori implementasi, tetapi beberapa status `Resolved` berarti resolved secara model runtime/kode, bukan berarti aset Studio sudah lengkap.

### 2.2 Klaim Yang Harus Diturunkan Statusnya

| Klaim lama | Status audit 2026-06-10 | Keputusan |
| --- | --- | --- |
| `NPC investigators` muncul saat lobby sepi | Belum ada NPC fisik, humanoid, spawner visual, patrol node, atau animasi | Status: belum terealisasi sebagai fitur visual/runtime lengkap |
| `ShopNPC interaction` | `ShopNPC` tidak ada; shop berjalan via prompt counter/shop area | Status: belum ada ShopNPC |
| `FlexDisplay` | Tidak ada objek bernama `FlexDisplay`; yang ada `FlexStage` dan `AnnouncementBoard` | Status: ganti referensi ke root kontrak baru |
| `Room_*`, `Interact_*`, `Door_*`, `Prop_*` sebagai zone candidate | Banyak tidak ada di Studio saat ini | Status: compatibility fallback kode, jangan dipakai sebagai kontrak visual baru |
| `SpawnPoints` siap | Tidak ada di Studio edit mode | Status: perlu dibuat ulang sebagai root fungsional stabil |
| `BillboardGui` lobby | Tidak ada di lobby edit mode; yang ada `SurfaceGui` board | Status: jangan minta BillboardGui jika SurfaceGui cukup |

## 3. Source Code Yang Menjadi Risiko Loop

### 3.1 Spawn Rebuild

File: `src/ServerScriptService/Server/LobbySocialHub/LobbyPlayerManager.lua`

Masalah:

- Skrip mencari `LobbySpawn`, `SpawnLocation`, atau `SpawnPoints`.
- Jika scan spawn dianggap tidak sehat, skrip bisa membangun ulang `SpawnPoints`.
- Ini berbahaya untuk workflow visual owner karena runtime bisa membuat/menata ulang marker otomatis.
- Ada debug print verbose seperti `[DEBUG _scanAndSyncLobbySpawns]`.
- `src/ServerScriptService/Server/MatchSystem/MatchCleanup.lua` juga mencari `LobbySpawn`, `SpawnPoints/PlayerSpawn_*`, atau `SpawnLocation` saat mengembalikan player dari match.

Keputusan audit:

- Owner perlu membuat spawn marker eksplisit/stabil di Studio dengan kontrak nama lama yang masih dibaca kode: `SpawnPoints/PlayerSpawn_1..4`.
- `_SpawnRoots` atau tag `PasrahLobbySpawnPoint` hanya boleh menjadi metadata tambahan, bukan pengganti `SpawnPoints`, sampai kode `LobbyPlayerManager` dan `MatchCleanup` sama-sama diubah.
- Agent berikutnya boleh mengubah kode agar tidak auto-destroy/auto-rebuild tanpa attribute opt-in, tetapi perubahan itu harus kecil, terpisah, dan tidak menyentuh flow match.
- Target ideal jangka panjang: resolver spawn membaca tag/attribute dulu, lalu tetap fallback ke `LobbySpawn` dan `SpawnPoints`.

### 3.2 Zone Detection

File: `src/ServerScriptService/Server/LobbySocialHub/LobbyZoneManager.lua`

Masalah:

- Skrip masih mencari fallback nama:
  - `Room_MainHubPlaza`
  - `Interact_MainHubPlaza`
  - `Prop_MainHubPlaza`
  - `Room_SouthEastFlexZone`
  - `Interact_SouthEastFlexZone`
  - `Door_SouthEastFlexZone`
  - `Prop_SouthEastFlexZone`
- Nama-nama ini tidak terkonfirmasi ada di Studio saat audit.

Keputusan audit:

- Jangan membuat ulang semua legacy node hanya untuk menyenangkan dokumentasi lama.
- Jika zone touch perlu segera aktif tanpa coding, opsi paling aman adalah membuat `workspace.LobbyZones` berisi invisible `BasePart` bernama persis `SpawnPlaza`, `FlexZone`, `ShopZone`, `DailyRewardZone`, `MatchmakingZone`, `PartyZone` karena ini dibaca lebih dulu oleh `LobbyZoneManager`.
- Root zone baru dengan attribute/tag tunggal boleh dibuat sebagai metadata tambahan.
- Agent berikutnya boleh mengganti resolver agar membaca root kontrak dulu, tetapi fallback nama lama harus tetap ada untuk compatibility.

### 3.3 LobbyService Runtime Builders

File: `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`

Masalah:

- Banyak helper `ensure*` masih membuat `Part`, `ProximityPrompt`, `SurfaceGui`, `PointLight`, dan runtime decor.
- Beberapa helper juga menghancurkan child jika class tidak sesuai.
- Ini bisa bertabrakan dengan owner yang mengubah visual.

Keputusan audit:

- Untuk visual owner baru, jangan biarkan skrip membangun visual utama dari nol tanpa izin eksplisit.
- Namun object runtime yang sekarang sudah menjadi host prompt aktif tidak boleh dianggap sampah hanya karena dibuat builder.
- Root fungsional boleh dibuat owner sekali, lalu script masa depan hanya bind prompt/action.
- Semua runtime visual builder harus masuk daftar cleanup bertahap, bukan diedit spontan di task ini.

### 3.4 NPC Population

File: `src/ServerScriptService/Server/LobbySocialHub/LobbyPopulationController.lua`

Fakta:

- Kode hanya menyimpan angka `lobbyNpcInvestigators`.
- Belum ada model NPC, spawn, despawn, path, animation controller, atau anti-overlap.

Keputusan audit:

- Ini bukan fitur selesai.
- Jangan klaim NPC aktif sampai ada minimal 1 model R15, spawn root, idle animation, dan controller spawn/despawn.

## 4. Kontrak Baru Agar Tidak Duplikat

Namespace yang dipakai: `PasrahLobby*`

Alasan:

- Source sudah memakai banyak attribute `Pasrah*`.
- Studio saat audit belum punya tag/attribute gameplay khusus LobbySocialHub.
- Dengan namespace `PasrahLobby*`, kontrak baru tidak bentrok dengan `PasrahImported*`, `PasrahAssetSourceToken`, atau `PasrahLobbyTraining*`.
- Namespace ini adalah kontrak metadata untuk pekerjaan berikutnya. Kode runtime sekarang belum boleh dipaksa bergantung pada namespace ini.

Aturan compatibility:

- Nama aktif yang sudah dibaca kode tetap valid: `QueueTrigger`, `ContractBoard`, `RoomBoard`, `ToolsBoard`, `PartyBoard`, `PartyPlatform`, `ShopCounter`, `Interact_Shop`, `DailyRewardTerminal`.
- Nama spawn aktif yang dibaca kode tetap valid: `LobbySpawn`, `SpawnPoints`, `PlayerSpawn_1`, `PlayerSpawn_2`, `PlayerSpawn_3`, `PlayerSpawn_4`.
- Nama UI aktif tetap valid: `LobbyUI`, `RoomBrowserUI`, `RoomBrowserFloatUI`, `OpenRoomBrowserButton`, `RoomBrowserButton`.
- Jika object punya tag/attribute baru tetapi nama compatibility tidak ada, kode sekarang belum tentu membaca object itu.

### 4.1 Tags Resmi

Gunakan hanya tag berikut untuk kontrak LobbySocialHub:

| Tag | Dipasang pada | Fungsi |
| --- | --- | --- |
| `PasrahLobbyRoot` | model `LobbySocialHub` | menandai root lobby aktif |
| `PasrahLobbyFunctionalRoot` | Folder `_FunctionalRoots` | container semua root fungsional |
| `PasrahLobbyInteractiveRoot` | invisible root part fitur interaktif | root utama untuk prompt/action |
| `PasrahLobbyZoneTrigger` | invisible trigger part zone | trigger touch / zone enter |
| `PasrahLobbyPromptHost` | part yang memegang `ProximityPrompt` | host prompt stabil |
| `PasrahLobbySpawnPoint` | `SpawnLocation` atau invisible spawn root | spawn player |
| `PasrahLobbyNpcSpawn` | invisible part spawn NPC | lokasi spawn NPC |
| `PasrahLobbyNpcPatrolNode` | invisible part patrol NPC | node patrol |
| `PasrahLobbyBoardAnchor` | part board/surface anchor | anchor UI/SurfaceGui/BillboardGui |

Larangan:

- Jangan pakai tag umum seperti `Interactive`, `Prompt`, `Zone`, atau `NPC` karena mudah bentrok.
- Jangan pakai tag visual vendor seperti `WindShake` untuk gameplay.
- Jangan membuat tag baru per fitur jika attribute sudah cukup.

### 4.2 Attributes Resmi

Gunakan attribute berikut. Jangan buat versi lain seperti `FeatureId`, `LobbyFeature`, `Zone`, `ActionId` tanpa prefix.

| Attribute | Type | Wajib | Contoh | Fungsi |
| --- | --- | --- | --- | --- |
| `PasrahLobbyFunction` | string | ya | `MatchQueue`, `FlexZone`, `Shop`, `Directory`, `PlayerSpawn`, `NpcSpawn`, `NpcPatrol` | fungsi utama |
| `PasrahLobbyZoneId` | string | untuk zone | `SpawnPlaza`, `FlexZone`, `ShopZone`, `PartyZone`, `DailyRewardZone`, `MatchmakingZone`, `TrainingZone` | id zone stabil |
| `PasrahLobbyAction` | string | untuk prompt | `OpenRoomBrowser`, `OpenShop`, `ViewFlexSpotlight`, `ClaimDailyReward`, `OpenParty`, `OpenTraining` | action server/client |
| `PasrahLobbyDisplayName` | string | ya | `Queue Hub` | label manusia |
| `PasrahLobbyEnabled` | boolean | ya | `true` | enable/disable tanpa delete |
| `PasrahLobbyOwnerEditable` | boolean | ya | `true` | tanda aman diedit visual owner |
| `PasrahLobbyDoNotDelete` | boolean | untuk root | `true` | guard manual dan AI |
| `PasrahLobbySortOrder` | number | optional | `10` | urutan board/list |
| `PasrahLobbyNpcRole` | string | untuk NPC | `Investigator`, `ShopKeeper`, `DailyRewardKeeper` | role NPC |
| `PasrahLobbyPatrolGroup` | string | untuk patrol | `InvestigatorAmbientA` | group path |
| `PasrahLobbyAssetStatus` | string | optional | `Needed`, `Placeholder`, `Imported`, `Verified` | tracking aset |
| `PasrahLobbyNotes` | string | optional | `Owner visual root, jangan rename` | catatan singkat |

### 4.3 Nilai Enum Resmi

`PasrahLobbyFunction` resmi:

- `MatchQueue`
- `FlexZone`
- `Shop`
- `Directory`
- `SocialGarden`
- `DailyReward`
- `Party`
- `Training`
- `PlayerSpawn`
- `NpcSpawn`
- `NpcPatrol`
- `BoardAnchor`

`PasrahLobbyAction` resmi:

- `OpenRoomBrowser`
- `OpenShop`
- `ViewFlexSpotlight`
- `ClaimDailyReward`
- `OpenParty`
- `OpenTraining`
- `OpenContractBoard`
- `TestEvidence`
- `None`

`PasrahLobbyAssetStatus` resmi:

- `Needed`
- `Placeholder`
- `Imported`
- `Verified`
- `Deprecated`

## 5. Struktur Studio Target

Struktur ini harus dibuat oleh owner atau agent Studio dengan izin eksplisit. Struktur ini tidak boleh dipakai untuk menghapus `MainHubDecorRuntime` atau object prompt yang sudah aktif.

```text
Workspace
  LobbyZones
    SpawnPlaza
    MatchmakingZone
    FlexZone
    ShopZone
    PartyZone
    DailyRewardZone
  Maps
    LobbySocialHub
      LobbySocialHub
        SpawnPoints
          PlayerSpawn_1
          PlayerSpawn_2
          PlayerSpawn_3
          PlayerSpawn_4
        _FunctionalRoots
          I_MatchQueue_Root
          I_FlexZone_Root
          I_Shop_Root
          I_Directory_Root
          I_SocialGarden_Root
          I_DailyReward_Root
          I_Party_Root
          I_Training_Root
        _SpawnRoots
          S_Lobby_PlayerSpawn_01
          S_Lobby_PlayerSpawn_02
          S_Lobby_PlayerSpawn_03
          S_Lobby_PlayerSpawn_04
        _NpcRoots
          N_Investigator_Spawn_01
          N_Investigator_Spawn_02
          N_Investigator_Patrol_01
          N_Investigator_Patrol_02
          N_ShopKeeper_Spawn_01
        MainHubDecorRuntime
          visual owner bebas berubah
```

Catatan compatibility:

- `Workspace.LobbyZones` adalah kontrak yang sudah dibaca `LobbyZoneManager` sekarang.
- `LobbySocialHub/SpawnPoints/PlayerSpawn_1..4` adalah kontrak yang sudah dibaca `LobbyPlayerManager` dan `MatchCleanup` sekarang.
- `_FunctionalRoots`, `_SpawnRoots`, dan `_NpcRoots` adalah struktur metadata/masa depan. Jangan mengandalkan folder ini untuk runtime sebelum kode resolver diubah.
- `MainHubDecorRuntime` tetap dipertahankan karena memuat prompt aktif dan board visual yang sudah terbaca saat audit.

### 5.1 Root Part Properties

Untuk root invisible non-spawn:

```text
Anchored = true
CanCollide = false
CanTouch = false, kecuali zone trigger
CanQuery = true
Transparency = 1
Size = 2,2,2 untuk prompt root
Size = sesuai area untuk zone trigger
```

Untuk `PasrahLobbyZoneTrigger`:

```text
Anchored = true
CanCollide = false
CanTouch = true
CanQuery = true
Transparency = 1
```

Untuk `PasrahLobbySpawnPoint`:

```text
ClassName = SpawnLocation disarankan
Anchored = true
CanCollide = false
CanTouch = false
CanQuery = false
Transparency = 1
Enabled = true
Neutral = true
Duration = 0
AllowTeamChangeOnTouch = false
Size = 2,1,2
```

## 6. Checklist Pembuatan Root

### 6.1 MatchQueue

Objek:

- `I_MatchQueue_Root`

Tags:

- `PasrahLobbyInteractiveRoot`
- `PasrahLobbyPromptHost`

Attributes:

```text
PasrahLobbyFunction = "MatchQueue"
PasrahLobbyZoneId = "MatchmakingZone"
PasrahLobbyAction = "OpenRoomBrowser"
PasrahLobbyDisplayName = "Queue Hub"
PasrahLobbyEnabled = true
PasrahLobbyOwnerEditable = true
PasrahLobbyDoNotDelete = true
PasrahLobbyAssetStatus = "Verified"
```

Catatan:

- Saat ini prompt aktif ada di `MainHubDecorRuntime.Hub Mid.QueueTrigger`.
- Jangan hapus atau rename `QueueTrigger` sampai resolver baru membaca `I_MatchQueue_Root` dan smoke test world prompt lulus.
- Jangan buat `LobbyEvent` baru. Root ini hanya anchor/metadata untuk action `OpenRoomBrowser`.

### 6.2 FlexZone

Objek:

- `I_FlexZone_Root`
- `Z_FlexZone_Trigger`
- optional `B_FlexZone_BoardAnchor`

Tags:

- `PasrahLobbyInteractiveRoot` pada root
- `PasrahLobbyZoneTrigger` pada trigger
- `PasrahLobbyBoardAnchor` pada board anchor

Attributes root:

```text
PasrahLobbyFunction = "FlexZone"
PasrahLobbyZoneId = "FlexZone"
PasrahLobbyAction = "ViewFlexSpotlight"
PasrahLobbyDisplayName = "Flex Zone"
PasrahLobbyEnabled = true
PasrahLobbyOwnerEditable = true
PasrahLobbyDoNotDelete = true
PasrahLobbyAssetStatus = "Placeholder"
```

Catatan:

- Saat ini visual yang ada: `FlexStage`, `AnnouncementBoard`, `FlexMarquee`, `NodeFlex`, dan surface board terkait.
- Tidak ada `FlexDisplay`; jangan buat object dengan nama itu kecuali sebagai adapter sementara.
- Event aktif Flex adalah `LobbyFlexSpotlightUpdated` dan `LobbyFlexSpotlightCleared`; jangan buat event Flex baru.

### 6.3 Shop

Objek:

- `I_Shop_Root`
- optional `N_ShopKeeper_Spawn_01`

Tags:

- `PasrahLobbyInteractiveRoot`
- `PasrahLobbyPromptHost`
- `PasrahLobbyNpcSpawn` jika NPC shop dibuat

Attributes root:

```text
PasrahLobbyFunction = "Shop"
PasrahLobbyZoneId = "ShopZone"
PasrahLobbyAction = "OpenShop"
PasrahLobbyDisplayName = "Shop"
PasrahLobbyEnabled = true
PasrahLobbyOwnerEditable = true
PasrahLobbyDoNotDelete = true
PasrahLobbyAssetStatus = "Placeholder"
```

Attributes NPC spawn:

```text
PasrahLobbyFunction = "NpcSpawn"
PasrahLobbyNpcRole = "ShopKeeper"
PasrahLobbyDisplayName = "Shop Keeper Spawn"
PasrahLobbyEnabled = true
PasrahLobbyOwnerEditable = true
PasrahLobbyAssetStatus = "Needed"
```

Catatan:

- `ShopNPC` belum ada.
- Shop saat ini berjalan lewat prompt `ShopCounter` dan `Interact_Shop`.
- Jangan hapus `ShopCounter` atau `Interact_Shop`; keduanya masih route aktif di `LobbyService`.

### 6.4 Directory

Objek:

- `I_Directory_Root`
- optional `B_Directory_BoardAnchor`

Tags:

- `PasrahLobbyInteractiveRoot`
- `PasrahLobbyBoardAnchor`

Attributes:

```text
PasrahLobbyFunction = "Directory"
PasrahLobbyZoneId = "SpawnPlaza"
PasrahLobbyAction = "None"
PasrahLobbyDisplayName = "Directory"
PasrahLobbyEnabled = true
PasrahLobbyOwnerEditable = true
PasrahLobbyDoNotDelete = true
PasrahLobbyAssetStatus = "Verified"
```

Catatan:

- `DirectoryPad`, `DirectoryPillar`, dan `DirectoryPanel` ada di Studio.
- Directory harus dianggap visual/board, bukan pathfinding source.

### 6.5 Social Garden / Daily Reward

Objek:

- `I_SocialGarden_Root`
- `I_DailyReward_Root`

Tags:

- `PasrahLobbyInteractiveRoot`
- `PasrahLobbyPromptHost`

Attributes DailyReward:

```text
PasrahLobbyFunction = "DailyReward"
PasrahLobbyZoneId = "DailyRewardZone"
PasrahLobbyAction = "ClaimDailyReward"
PasrahLobbyDisplayName = "Daily Reward"
PasrahLobbyEnabled = true
PasrahLobbyOwnerEditable = true
PasrahLobbyDoNotDelete = true
PasrahLobbyAssetStatus = "Placeholder"
```

Catatan:

- Prompt daily reward sudah ada di `Garden.DailyRewardTerminal`.
- NPC daily reward belum ada.

### 6.6 Player Spawn

Objek:

- `SpawnPoints/PlayerSpawn_1`
- `SpawnPoints/PlayerSpawn_2`
- `SpawnPoints/PlayerSpawn_3`
- `SpawnPoints/PlayerSpawn_4`
- Optional mirror metadata: `_SpawnRoots/S_Lobby_PlayerSpawn_01..04`

Tags:

- `PasrahLobbySpawnPoint`

Attributes:

```text
PasrahLobbyFunction = "PlayerSpawn"
PasrahLobbyZoneId = "SpawnPlaza"
PasrahLobbyDisplayName = "Lobby Player Spawn 01"
PasrahLobbyEnabled = true
PasrahLobbyOwnerEditable = false
PasrahLobbyDoNotDelete = true
PasrahLobbyAssetStatus = "Needed"
```

Catatan:

- Ini prioritas tertinggi untuk menghentikan loop spawn/path debug.
- Jangan mengandalkan runtime rebuild sebagai workflow permanen.
- Jangan mengganti `SpawnPoints` dengan `_SpawnRoots` saja. Kode sekarang belum membaca `_SpawnRoots`.
- Pastikan posisi spawn sehat: berada dekat floor lobby, tidak jatuh di bawah map, tidak terlalu jauh dari pivot/reference lobby, dan `Anchored=true`.

### 6.7 NPC Investigators

Objek:

- `N_Investigator_Spawn_01`
- `N_Investigator_Spawn_02`
- `N_Investigator_Patrol_01`
- `N_Investigator_Patrol_02`
- `N_Investigator_Patrol_03`
- `N_Investigator_Patrol_04`

Tags:

- `PasrahLobbyNpcSpawn` pada spawn
- `PasrahLobbyNpcPatrolNode` pada patrol node

Attributes spawn:

```text
PasrahLobbyFunction = "NpcSpawn"
PasrahLobbyNpcRole = "Investigator"
PasrahLobbyDisplayName = "Investigator Spawn 01"
PasrahLobbyEnabled = true
PasrahLobbyOwnerEditable = true
PasrahLobbyAssetStatus = "Needed"
```

Attributes patrol:

```text
PasrahLobbyFunction = "NpcPatrol"
PasrahLobbyNpcRole = "Investigator"
PasrahLobbyPatrolGroup = "InvestigatorAmbientA"
PasrahLobbySortOrder = 1
PasrahLobbyDisplayName = "Investigator Patrol 01"
PasrahLobbyEnabled = true
PasrahLobbyOwnerEditable = true
PasrahLobbyAssetStatus = "Needed"
```

Catatan:

- Belum ada NPC humanoid di Studio.
- Jangan implement spawner sebelum minimal satu karakter R15 dan idle/walk animation tersedia.

## 7. Asset Checklist Owner

### 7.1 Model 3D

Prioritas P0:

- 4 invisible player spawn `SpawnLocation`.
- Invisible root part untuk `MatchQueue`, `FlexZone`, `Shop`, `Directory`.
- Invisible trigger untuk `FlexZone`.

Prioritas P1:

- Shopkeeper NPC model R15.
- 2 sampai 6 investigator NPC R15.
- Board/anchor untuk directory dan flex jika ingin dipisah dari visual lama.

Prioritas P2:

- Decorative upgrade untuk social garden.
- Seasonal/flex display props.
- NPC ambient props seperti clipboard, flashlight, radio, backpack.

### 7.2 Karakter dan Kostum

Shopkeeper:

- Rig: R15.
- Style: penjaga toko horror lobby, tidak terlalu menyeramkan.
- Clothing: apron/jacket, utility belt, optional name tag.
- Required parts: `Humanoid`, `HumanoidRootPart`, rig lengkap.

Investigator NPC:

- Rig: R15.
- Style: investigator muda/dewasa, outfit urban Indonesia, backpack/toolbelt optional.
- Variasi minimal: 3 look berbeda.
- Jangan gunakan package/avatar yang terlalu berat untuk mobile.

### 7.3 Animasi

Minimal sebelum NPC dianggap ready:

| NPC | Animasi | Status yang dibutuhkan |
| --- | --- | --- |
| Shopkeeper | idle loop | uploaded AnimationId |
| Shopkeeper | wave/greet | uploaded AnimationId |
| Shopkeeper | talk/point | uploaded AnimationId |
| Investigator | idle loop | uploaded AnimationId |
| Investigator | walk loop | uploaded AnimationId |
| Investigator | inspect tool | uploaded AnimationId |
| Investigator | sit/relax | optional AnimationId |

Format final:

```text
rbxassetid://<animation_id>
```

### 7.4 Gambar/UI

Yang dibutuhkan jika owner ingin visual polish:

- Directory map image.
- Zone icons: Queue, Shop, Flex, Party, Garden, Training.
- Flex spotlight board image.
- Shop sign image.
- Daily reward claim image.
- Optional custom `[E]` prompt icon jika tidak memakai default ProximityPrompt.

Workflow gambar sesuai aturan proyek:

```powershell
python scripts/generate_visual.py --prompt "<perintah>" --type <icon|billboard|ui|reference>
```

## 8. Immediate Studio Steps

Kerjakan manual di Studio terlebih dahulu sebelum coding baru. Urutan ini sengaja memakai kontrak yang sudah dibaca kode sekarang.

1. Buat `Workspace.Maps.LobbySocialHub.LobbySocialHub.SpawnPoints` berisi 4 `SpawnLocation` invisible bernama persis `PlayerSpawn_1`, `PlayerSpawn_2`, `PlayerSpawn_3`, `PlayerSpawn_4`.
2. Setiap spawn: `Anchored=true`, `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `Transparency=1`, `Enabled=true`, `Neutral=true`, `Duration=0`, `AllowTeamChangeOnTouch=false`, `Size=2,1,2`, posisi aman di atas floor lobby.
3. Jangan hapus/rename prompt aktif: `QueueTrigger`, `ContractBoard`, `RoomBoard`, `ToolsBoard`, `PartyBoard`, `PartyPlatform`, `ShopCounter`, `Interact_Shop`, `DailyRewardTerminal`.
4. Jika zone touch perlu langsung aktif, buat `Workspace.LobbyZones` dengan invisible part bernama persis `SpawnPlaza`, `MatchmakingZone`, `FlexZone`, `ShopZone`, `PartyZone`, `DailyRewardZone`.
5. Setelah spawn/zone kompatibel ada, baru boleh buat `_FunctionalRoots`, `_SpawnRoots`, dan `_NpcRoots` sebagai metadata tambahan.
6. Tambahkan tag/attribute `PasrahLobby*` hanya pada object baru/anchor yang Anda setujui. Jangan pakai tag/attribute itu untuk menilai object lama harus dihapus.
7. Jangan hapus `MainHubDecorRuntime.Hub Mid.QueueTrigger`.
8. Jangan hapus `MainHubDecorRuntime.Flex.FlexStage` atau `AnnouncementBoard` sampai resolver baru selesai dan smoke test Flex lulus.
9. Jangan membuat ulang legacy `Room_*`, `Door_*`, `Prop_*` hanya karena dokumen lama menyebutnya.
10. Jangan buat UI baru untuk RoomBrowser. Pakai `LobbyUI.OpenRoomBrowserButton`, `RoomBrowserUI`, dan `RoomBrowserFloatUI` yang sudah ada.

## 9. Task Untuk Agent Berikutnya

Agent coding berikutnya boleh mengerjakan setelah root Studio dibuat:

- Ubah `LobbyZoneManager` agar membaca `CollectionService:GetTagged("PasrahLobbyZoneTrigger")` lebih dulu, tetapi tetap fallback ke `Workspace.LobbyZones` dan legacy candidates.
- Ubah `LobbyPlayerManager` agar membaca `PasrahLobbySpawnPoint` lebih dulu, tetapi tetap fallback ke `LobbySpawn`, `SpawnPoints`, dan `PlayerSpawn_*`.
- Ubah `MatchCleanup` bersamaan dengan `LobbyPlayerManager` jika kontrak spawn baru dipakai. Jangan update salah satu saja.
- Ubah `LobbyService:_connectWorldPrompt` agar bisa resolve by `PasrahLobbyAction`, tetapi tetap fallback ke nama aktif seperti `QueueTrigger`.
- Bersihkan debug print `[DEBUG-HUB-*]`, `[DEBUG-LOBBY-*]`, dan `[DEBUG _scanAndSyncLobbySpawns]` setelah spawn stabil.
- Jangan implement NPC sebelum model R15 dan AnimationId minimal tersedia.
- Jangan mengganti `RoomBrowserController`, `LobbySystem.Controller`, `LobbyEvent`, atau `MatchEvent`.
- Jangan membuat duplicate ScreenGui/controller baru untuk `RoomBrowserUI`; lanjutkan authored UI binding yang sudah ada.

Smoke test wajib sebelum merge/refactor dianggap aman:

- Klik `LobbyUI.MainPanel.OpenRoomBrowserButton`, RoomBrowser terbuka.
- Trigger prompt `QueueTrigger`, RoomBrowser menerima `RoomBrowserSnapshot`.
- Create room, join/leave room, ready toggle, host start countdown.
- Event `RoomMatchStarting` diterima client.
- Match mulai lewat flow existing.
- Return to lobby memakai `MatchCleanup` dan player mendarat di `SpawnPoints/PlayerSpawn_*`.
- `RoomBrowserUI` tidak double, `LobbyEvent` tidak double, tidak ada controller UI baru.

## 10. File Referensi Yang Harus Dipakai

- `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
- `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`
- `DOCUMENTATION/SOURCE OF TRUTH/REPORTS.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/OWNER_EDITABLE_VISUAL_DEEP_SCAN_2026-05-02.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/OWNER_EDITABLE_VISUAL_DEEP_SCAN_ADDENDUM_2026-05-03.md`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/OWNER_VISUAL_EDIT_READY_CHECKLIST_2026-05-03.md`
- `src/ServerScriptService/Server/LobbySocialHub/LobbyPlayerManager.lua`
- `src/ServerScriptService/Server/LobbySocialHub/LobbyZoneManager.lua`
- `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
- `src/ServerScriptService/Server/LobbySocialHub/LobbyPopulationController.lua`
- `src/ServerScriptService/Server/Core/LobbyLocator.lua`
- `src/ServerScriptService/Server/LobbySystem/Controller.lua`
- `src/ServerScriptService/Server/MatchSystem/MatchCleanup.lua`
- `src/ServerScriptService/Server/MatchSystem/MatchService.lua`
- `src/client/UI/RoomBrowserController.lua`
- `src/client/UI/Main.lua`
- `src/shared/GameData/Maps/LobbySocialHub.lua`

## 11. Definition of Done

LobbySocialHub audit dianggap sinkron jika:

- File ini menjadi referensi utama untuk kerja LobbySocialHub.
- `SpawnPoints/PlayerSpawn_1..4` ada dan sehat di Studio.
- Root fungsional/tag `PasrahLobby*` ada hanya sebagai metadata/additive sampai kode resolver diubah.
- Kode masih mempertahankan fallback nama aktif sampai smoke test membuktikan resolver baru aman.
- NPC tidak lagi disebut selesai sampai model, spawn root, patrol root, dan AnimationId tersedia.
- Dokumentasi lama yang menyebut objek tidak terkonfirmasi tidak dipakai sebagai dasar debugging.
- Tidak ada UI/RemoteEvent/controller duplicate untuk RoomBrowser atau matchflow.



REPORTS

#1
n=%
status :  
stable : y/n
blocker : 


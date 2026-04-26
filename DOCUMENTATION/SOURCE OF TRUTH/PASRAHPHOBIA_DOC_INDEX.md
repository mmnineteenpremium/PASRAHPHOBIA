========================================
PASRAHPHOBIA — DOCUMENT INDEX
========================================

This directory contains the full design documentation
for the PASRAHPHOBIA Roblox game project.

[2026-03-31 NOTE]
This index is an aggregated snapshot and may still contain historical references from older revisions.
Runtime source-of-truth for execution must follow:
- `src/ServerScriptService/Server` for active server code
- `REPORTS.md` for current implementation status
- `CANONICAL_SPECIFICATIONS_v2.md` for canonical design targets

[2026-04-16 NOTE]
For the latest verified live smoke on branch `final-source-of-truth`, read:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/FINAL_SOURCE_OF_TRUTH_RUNTIME_SMOKE_2026-04-16.md`

[2026-04-16 NOTE - HauntedHouse]
Before continuing any `HauntedHouse` map work on branch `final-source-of-truth`, use:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/HAUNTEDHOUSE_RECONSTRUCTION_SPEC_2026-04-16.md`
- `src/shared/GameData/Maps/HauntedHouse.lua`

These are the current room-by-room/runtime references for:
- `20` rooms split across `2` floors (`10 + 10`)
- outside-house preparation spawn via `PreparationSpawnArea` and safe-zone staging
- investigation-map `SpawnPoints` removed
- disabled timer-based preparation countdown
- match advance on `Door_FrontEntry`
- runtime object/event coverage with no missing target definitions

[2026-04-16 NOTE - StudioMMNineteen]
Before continuing any `StudioMMNineteen` map work on branch `final-source-of-truth`, use:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/STUDIOMMNINETEEN_RECONSTRUCTION_SPEC_2026-04-16.md`
- `src/shared/GameData/Maps/StudioMMNineteen.lua`

These are the current room-by-room/runtime references for:
- `12` rooms split across `3` floors (`4 + 4 + 4`)
- outside-house preparation spawn via `PreparationSpawnArea` and safe-zone staging
- investigation-map `SpawnPoints` removed
- disabled timer-based preparation countdown
- match advance on `Door_FrontEntry`
- runtime object/event coverage with no missing target definitions

[2026-04-16 NOTE - EmptyBuilding]
Before continuing any `EmptyBuilding` map work on branch `final-source-of-truth`, use:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/EMPTYBUILDING_RECONSTRUCTION_SPEC_2026-04-16.md`
- `src/shared/GameData/Maps/EmptyBuilding.lua`

These are the current room-by-room/runtime references for:
- `14` rooms split across `2` floors (`9 + 5`)
- outside-entry preparation spawn via `PreparationSpawnArea` and safe-zone staging
- investigation-map `SpawnPoints` removed
- disabled timer-based preparation countdown
- match advance on `Door_Lobby`
- runtime object/event coverage with no missing target definitions
- structural decor requirement (`stairs/ladder/filler props`) for floor-2 access and visual density

[2026-04-16 NOTE - AbandonedPalace]
Before continuing any `AbandonedPalace` map work on branch `final-source-of-truth`, use:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/ABANDONEDPALACE_RECONSTRUCTION_SPEC_2026-04-16.md`
- `src/shared/GameData/Maps/AbandonedPalace.lua`

These are the current room-by-room/runtime references for:
- `18` rooms on `1` floor
- outside-entry preparation spawn via `PreparationSpawnArea` and safe-zone staging
- investigation-map `SpawnPoints` removed
- disabled timer-based preparation countdown
- match advance on `Door_GrandHall`
- runtime object/event coverage with no missing target definitions

[2026-04-18 NOTE - Ghost Asset Source Of Truth]
Before continuing any ghost visual, ghost template, or ghost asset ID work on branch `final-source-of-truth`, use:
- local folder `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\GHOST`
- local CSV `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\[ASSETID]\Models & Packages.csv`
- `DOCUMENTATION/SOURCE OF TRUTH/reports/GHOST_AND_ASSET_WIRING_TASK_TRACKER_2026-04-18.md`
- `src/shared/GameData/GhostVisualTuning.lua`

Hard rules for this lane:
- do not use deleted/wrong `Leak` row `129878813436863`
- replace old ghost asset IDs in code with owner-imported asset IDs from the CSV
- use current base slots plus the existing aggressive suffix runtime lane only
- do not invent a new ghost variant switching architecture

[2026-04-18 NOTE - Lobby Visual Donor]
Before continuing any `LobbySocialHub` visual recovery or parity work on branch `final-source-of-truth`, use:
- authoritative donor visual layer:
  - `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\LobbySocialHub\MainHubDecorRuntime.rbxm`
- comparison-only donor:
  - `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\LobbySocialHub\MainHubDecorRuntime2.rbxm`
- keep current clean lobby container/source lane for structure and wiring

Hard rules for this lane:
- do not promote `LobbySocialHub_RuntimeReference(F5...)` wholesale as the new lobby source
- do not promote legacy playtest containers like `SpawnPoints`, `Rooms`, `GhostSpawns`, `EvidenceSpawnNodes`, or other full-runtime lobby folders
- treat `MainHubDecorRuntime2.rbxm` as `TrainingGhostVisual` comparison only unless explicitly approved otherwise
- lobby runtime spawn expectation remains around `1610, 3.47, -10`
- authoritative source file for this branch is now:
  - `src/Workspace/Maps/LobbySocialHub/LobbySocialHub.rbxm`
- disabled legacy reference:
  - `src/Workspace/Maps/LobbySocialHub/LobbySocialHub.model.json.disabled`

[2026-04-19 NOTE - Active Execution Lane]
Before continuing runtime stabilization work, use:
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`

Hard execution lane:
- prioritize Studio-first fixes
- publish only for publish-specific blockers
- no architecture changes or new systems without explicit owner approval
- ghost visual validation must follow behavior-state rule (hidden state is valid; manifest/hunt non-render is bug)

[2026-04-26 NOTE - Runtime Spawn Authority + Visual-Only Scope]
Task lane aktif sekarang dikunci ke:
- runtime spawn authored map saja:
  - `ServerStorage.Maps.<Map>.<Map>.Runtime.PreparationStagingRuntime.PreparationSpawnArea`
- tanpa fallback/recreate spawn otomatis
- boundary anti-staging ghost wajib ada
- trigger phase by-door wajib ada

Visual lane aktif sekarang juga dikunci:
- tidak membuat sistem baru
- tidak membuat arsitektur gameplay/economy baru
- hanya penyempurnaan visual total (UI/GUI/UX) untuk panel canonical:
  - Rank, EXP, Profiling, Daily Quest/Reward/Check-In/Spin, Gacha, Shop, RoyalPass, MM/PP, Item, Hidden Gems.
- referensi visual mentah wajib:
  - `asset mentah/ref ui/*.html`
  - konversi HTML -> Roblox hanya pada visual layer (tanpa penambahan logic system baru).

[2026-04-26 NOTE - Visual Batch T5]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T5_TOUCH_SCOPE_AND_RANK_PALETTE_2026-04-26.md`

Status ringkas batch T5:
- suppress header body text di touch sekarang dibatasi ke fase `Preparation/Loading` (staging readability lane)
- aksen warna rank board + tier host room browser disejajarkan ke token rank palette dari referensi HTML canonical
- gate `smoke test 2 client` tetap owner manual lane

[2026-04-26 NOTE - Visual Batch T6]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T6_PROFILE_DAILY_ROYALPASS_2026-04-26.md`

Status ringkas batch T6:
- hierarchy visual `ProfileUI` dirapikan untuk Rank/EXP + Daily Quest/Check-In/Spin + Inventory/Gacha (snapshot-only)
- wording dan lane visual `RoyalPassUI` diseragamkan ke `Daily Check-In` dan `Daily Quest` tanpa menambah sistem
- wording lobby daily feedback disejajarkan ke istilah `Daily check-in`

[2026-04-26 NOTE - Visual Batch T7]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T7_HIDDEN_GEMS_DAILY_LANE_2026-04-26.md`

Status ringkas batch T7:
- tracker visual hidden gems sekarang menampilkan progress `x/3` bila data `ppBreakdown` tersedia (snapshot-only)
- copy `DailyRewardZone` + tombol lobby `Royal Pass` disejajarkan ke konteks harian (`Daily Check-In`/spin)
- `ShopUI` dan `PASRA_UI` menampilkan cap hidden gems dengan wording konsisten

[2026-04-26 NOTE - Visual Batch T8]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T8_LOBBY_MENU_SHOP_MICROSTATE_2026-04-26.md`

Status ringkas batch T8:
- `Lobby Panel` dan `Quick Menu` sekarang menampilkan micro-state wallet MM/PP + daily + hidden gems + gacha snapshot
- `DailyRewardZone` fokus harian membawa copy quest/check-in yang lebih eksplisit
- `ShopUI` menambahkan detail gacha snapshot (`owned/equipped`) + stamp attribute visual hidden gems/gacha

[2026-04-26 NOTE - Visual Batch T9]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T9_MOBILE_READABILITY_TUNING_2026-04-26.md`

Status ringkas batch T9:
- copy micro-state untuk `Lobby Panel`, `Quick Menu`, dan `ShopUI` dipadatkan khusus mobile/compact viewport
- tuning sizing/text pada lane lobby + menu mobile mengurangi risiko overflow saat state daily/gacha/hidden aktif
- tetap tidak ada sistem baru; murni presentasi visual snapshot runtime

[2026-04-26 NOTE - Visual Batch T10]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T10_FOOTER_COMPACTION_2026-04-26.md`

Status ringkas batch T10:
- footer mobile `Quick Menu` dipadatkan agar ringkas namun tetap menjaga lane canonical + build signature
- footer mobile `ShopUI` dipadatkan per filter (`MM/PP/Robux/Owned`) dengan makna tetap sama
- desktop copy detail tetap dipertahankan

[2026-04-26 NOTE - Visual Batch T11]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T11_SHOP_MOBILE_LAYOUT_STABILITY_2026-04-26.md`

Status ringkas batch T11:
- panel `ShopUI` mobile ditambah headroom tinggi agar lane title, filter, dan footer tidak bertumpuk
- area `ContentFrame` mobile `ShopUI` di-offset ulang supaya daftar tetap terbaca saat compact viewport
- tuning text-size filter/secondary/footer khusus mobile menjaga keterbacaan tanpa ubah sistem/runtime logic

[2026-04-26 NOTE - Visual Batch T12]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T12_PROFILE_ROYALPASS_MOBILE_STABILITY_2026-04-26.md`

Status ringkas batch T12:
- `ProfileUI` dan `RoyalPassUI` mobile diberi ruang footer lebih aman agar copy footer tidak menabrak list konten
- `ContentFrame` mobile kedua panel di-offset ulang untuk menjaga ritme hierarchy header-content-footer
- tuning text-size secondary/footer mobile menurunkan risiko overflow tanpa menambah sistem/runtime baru

[2026-04-26 NOTE - Visual Batch T13]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T13_LEADERBOARD_MOBILE_CLARITY_2026-04-26.md`

Status ringkas batch T13:
- `LeaderboardUI` mobile mendapat tuning text-size khusus agar label utama/sekunder/footer tetap jelas saat state padat
- layout `ContentFrame`, row aksi bawah, dan footer mobile `LeaderboardUI` diseimbangkan untuk mengurangi tabrakan area bawah
- tetap visual-only, tanpa perubahan sistem rank/progression/runtime

[2026-04-26 NOTE - Visual Batch T14]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T14_MAINMENU_MOBILE_STACK_DENSITY_2026-04-26.md`

Status ringkas batch T14:
- `MainMenuUI` mobile compact lane mendapat tuning ritme stack vertikal (gap/tombol/footer) agar lebih stabil di layar pendek
- text-size tombol aksi utama dituning khusus compact mobile untuk menjaga keterbacaan tanpa terasa padat
- tetap visual-only, tanpa perubahan flow menu atau logic runtime

[2026-04-26 NOTE - Visual Batch T15]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T15_PASRA_JOURNAL_MOBILE_READABILITY_2026-04-26.md`

Status ringkas batch T15:
- `PASRA_UI` mobile mendapat reserve footer + rebalance area konten agar copy snapshot panjang tetap rapi
- `JournalUI` mobile mendapat tuning strip scan (action/status) dan area konten agar tidak overlap di viewport sempit
- tetap visual-only, tanpa perubahan sistem evidence/result/runtime

[2026-04-26 NOTE - Visual Batch T16]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T16_SPECTATOR_MOBILE_STABILITY_2026-04-26.md`

Status ringkas batch T16:
- `SpectatorUI` mobile mendapat reserve footer + rebalance area konten agar copy spectator/distortion tetap jelas
- tuning text-size secondary/footer mobile mengurangi risiko overflow saat state spectator padat
- tetap visual-only, tanpa perubahan logic spectator/runtime

[2026-04-26 NOTE - Visual Batch T17]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T17_MOBILE_HEADER_CONTROL_CONSISTENCY_2026-04-26.md`

Status ringkas batch T17:
- header mobile lintas panel auxiliary disejajarkan ritmenya (`badge/title/subtitle`) untuk hierarchy yang konsisten
- kontrol `CloseButton`/`FloatButton` mobile dituning ukuran dan text-size untuk keterbacaan + tap target
- tetap visual-only, tanpa perubahan logic gameplay/runtime

[2026-04-26 NOTE - Visual Batch T18]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T18_BASIC_HEADER_COMPACT_RHYTHM_2026-04-26.md`

Status ringkas batch T18:
- `MainMenuUI` + `LeaderboardUI` mobile mendapat profile compact-header untuk title/badge/close saat viewport tinggi sempit
- action button `LeaderboardUI` mobile dituning text-size khusus agar tetap jelas pada lane compact
- tetap visual-only, tanpa perubahan logic runtime/gameplay

[2026-04-26 NOTE - Visual Batch T19]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T19_LOBBY_MATCH_COMPACT_TYPOGRAPHY_2026-04-26.md`

Status ringkas batch T19:
- `LobbyUI` compact lane mendapat tuning text-size tombol aksi + badge agar tetap terbaca di viewport sempit
- `MatchUI` compact lane mendapat tuning text-size hide/close/footer agar area bawah panel tidak terlalu padat
- tetap visual-only, tanpa perubahan logic gameplay/runtime

[2026-04-26 NOTE - Visual Batch T20]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T20_ROOMBROWSER_EXTRA_COMPACT_MOBILE_2026-04-26.md`

Status ringkas batch T20:
- RoomBrowser mobile mendapat lane `extra compact` khusus viewport pendek non-wide agar panel tidak terlalu padat
- header/tab/action/list typography dituning turun untuk menjaga readability pada layout extra compact
- tetap visual-only, tanpa perubahan logic room browser/runtime

[2026-04-26 NOTE - Visual Batch T21]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T21_ROOMBROWSER_HOST_CONTROLS_COMPACT_2026-04-26.md`

Status ringkas batch T21:
- area host-room RoomBrowser (mode/map/password/invite/ready/start/cancel/leave) mendapat tuning typography compact khusus lane extra-compact
- label host-room dan opsi dropdown map/mode ikut dituning agar panel kontrol tidak sesak
- tetap visual-only, tanpa perubahan logic room browser/runtime

[2026-04-26 NOTE - Visual Batch T22]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T22_ROOMBROWSER_PREVIEW_COUNTDOWN_COMPACT_2026-04-26.md`

Status ringkas batch T22:
- map preview RoomBrowser pada lane extra-compact mendapat tuning typography dan densitas visual agar tetap jelas di viewport pendek
- kontrol overlay float/countdown/cancel dipadatkan agar komposisi visual mobile lebih seimbang
- tetap visual-only, tanpa perubahan logic room browser/runtime

[2026-04-26 NOTE - Visual Batch T23]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T23_RESULTS_HUD_COMPACT_MOBILE_2026-04-26.md`

Status ringkas batch T23:
- lane `compactMobileHud` menata ulang densitas visual panel hasil + HUD bawah untuk viewport mobile pendek
- typography/ukuran `Results`, `Timer`, `Evidence Quick`, dan `Hint Bar` dipadatkan agar lebih jelas tanpa overflow
- tetap visual-only, tanpa perubahan logic gameplay/runtime

[2026-04-26 NOTE - Visual Batch T24]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T24_ROOMBROWSER_PLAYER_CARD_EXTRA_COMPACT_2026-04-26.md`

Status ringkas batch T24:
- card preview pemain di RoomBrowser mendapat lane extra-compact agar tetap muat dan terbaca pada viewport mobile pendek
- ukuran kartu/viewport serta text-size name/state dipadatkan untuk menekan risiko clipping
- tetap visual-only, tanpa perubahan logic room browser/runtime

[2026-04-26 NOTE - Visual Batch T25]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T25_ROOMBROWSER_LIST_DENSITY_TRIM_2026-04-26.md`

Status ringkas batch T25:
- tab mode RoomBrowser pada lane extra-compact dipadatkan agar ruang vertikal lebih lega
- row list RoomBrowser extra-compact beralih ke single-line truncate + padding untuk scan cepat
- tetap visual-only, tanpa perubahan logic room browser/runtime

[2026-04-26 NOTE - Visual Batch T26]
Untuk lanjutan polish visual lane aktif (non-system), gunakan:
- `DOCUMENTATION/SOURCE OF TRUTH/reports/VISUAL_BATCH_T26_ROOMBROWSER_INVITE_LIST_EXTRA_COMPACT_2026-04-26.md`

Status ringkas batch T26:
- `InviteDropdown` RoomBrowser mendapat lane extra-compact eksplisit untuk row broadcast + row pemain
- row invite list dipadatkan (height/text/spacing/scrollbar) dan truncate diaktifkan untuk nama panjang
- tetap visual-only, tanpa perubahan logic invite/matchmaking/runtime

AI agents must read the documents in the following order
to fully understand the game architecture.

========================================
READ ORDER
========================================

1. 00_PROJECT_CORE
   - Project vision
   - Core design philosophy
   - Global system overview

2. 01_ARCHITECTURE
   - Master System Map
   - Global System Flow
   - Technical System Blueprint
   - Server Bootstrap Architecture
   - Service Dependency Matrix

3. 02_GAMEPLAY
   - Gameplay Rulebook
   - Investigation System
   - Difficulty Scaling

4. 03_MATCH_SYSTEM
   - Match Lifecycle
   - Match State Machine
   - Match Architecture
   - Teleport System

5. 04_GHOST_SYSTEM
   - Ghost AI Behavior
   - Ghost State Machine
   - Hunt System
   - Ghost Modifier System

6. 05_EVIDENCE_SYSTEM
   - Evidence Engine
   - Evidence Spawning
   - Evidence Deduction Algorithm

7. 06_SPECTATOR_SYSTEM
   - Spectator Distortion System
   - Spectator Communication Model
   - Fake / Real Ghost Logic

8. 07_ECONOMY_SYSTEM
   - Economy Data Structure
   - Economy Balance
   - Monetization System
   - RoyalPass System

9. 08_LOBBY_SYSTEM
   - Lobby Social Hub
   - Player Profile System
   - Flex System
   - Gift System

10. 09_AI_PIPELINE
    - AI Development Pipeline
    - Automated AI Code Generation

11. 10_FINAL_REFERENCE
    - Final system specifications
    - Complete project blueprint

========================================
PROJECT TYPE
========================================

Multiplayer Horror Investigation Game
Inspired by Phasmophobia style gameplay
Built on Roblox platform

========================================
IMPORTANT NOTES
========================================

Server authority architecture.
Evidence system drives investigation loop.
Spectator players create uncertainty via distortion system.

AI agents must follow architecture constraints
defined in the documentation.

========================================
END OF INDEX
========================================




00_PROJECT_CORE
   - Project vision
   - Core design philosophy
   - Global system overview
   
	PASRAHPHOBIA – COMPLETE PROJECT PLAN

PROJECT OVERVIEW
PASRAHPHOBIA is a multiplayer horror investigation game on Roblox where players explore haunted locations, collect evidence, identify ghost types, and survive supernatural events. The game supports solo and cooperative gameplay for up to four players.

Players begin in a Social Hub lobby where they can interact with systems such as shop, training, daily rewards, leaderboard, matchmaking, and player profile flex displays.

---

CORE GAME LOOP

1. Player joins the game
2. Player spawns in Lobby Social Hub
3. Player explores lobby buildings (shop, training, leaderboard, etc.)
4. Player forms party or queues for matchmaking
5. Match starts
6. Players investigate haunted map
7. Collect ghost evidence
8. Identify ghost type
9. Survive hunt events
10. Extract from map
11. Rewards and statistics displayed
12. Return to lobby

---

LOBBY SOCIAL HUB

The lobby is a single open map with a central plaza and surrounding buildings. Players walk into buildings to interact with systems. No teleportation between zones.

Lobby Layout

Central Plaza (Spawn Area)

Buildings around the plaza:

Shop Building
Training Building
Leaderboard Building
Daily Reward Building
Flex Gallery
Matchmaking Hall

Lobby Systems

Player Presence Tracking
Party System (max 4 players)
Lobby Interaction System
Lobby Ambient Systems
Profile Inspection System

---

PLAYER PROFILE SYSTEM

Player profiles contain public information and cosmetic display elements.

Profile contains:

Player Level (1–100)
Title
Flex Border
Bio
3 Gallery Items
Total Games Played

Information shown above player:

Level
Title
Total Games

Detailed profile appears when clicking player.

Winrate visibility can be toggled by player.
If hidden, it shows "-".

---

GAME MODES / INVESTIGATION DIFFICULTY

Beginner
Evidence Required: 4
Ghost Aggression: Low
Rewards: Low

Standard
Evidence Required: 3
Ghost Aggression: Medium
Rewards: Medium

Nightmare
Evidence Required: 2
Ghost Aggression: High
Rewards: High

Difficulty affects:

Ghost aggression
Sanity drain
Evidence availability
Reward multiplier

---

GAME PHASE SYSTEM

Match lifecycle phases:

Lobby
Preparation
Investigation
Hunt
Extraction
Results

Phase Responsibilities

Lobby
Players prepare for match.

Preparation
Map loads and ghost spawns.

Investigation
Players search for evidence.

Hunt
Ghost enters aggressive hunt mode.

Extraction
Players exit investigation area.

Results
Rewards, statistics, XP displayed.

---

GHOST SYSTEM

Total Ghost Types: 12

Each ghost has:

Unique behavior
Evidence types
Aggression level
Hunt patterns

Ghost AI states include:

Idle
Roaming
Interaction
Hunt

Ghost aggression increases based on player actions and sanity levels.

---

EVIDENCE SYSTEM

Players collect ghost evidence using investigation tools.

Evidence Tools
Kotak Arwah
Buku Terkutuk
Bola Arwah
Gerakan Gaib
Jejak Energi
Suhu Membeku
Evidence Requirement


Evidence is stored per match and shared with the team.

Evidence required depends on difficulty level.

---

SANITY SYSTEM

Players have a sanity meter that decreases over time or from paranormal events.

Low sanity increases:

Ghost aggression
Chance of hunt events
Fear effects

Sanity can be influenced by environmental factors and ghost interactions.

---

FEAR ENGINE

Controls psychological horror elements including:

Audio disturbances
Visual hallucinations
Environmental interactions
Ghost manifestations

Fear intensity scales with player sanity and ghost aggression.

---

AGGRESSION SYSTEM

Controls ghost hostility levels.

Aggression increases when:

Player sanity is low
Players provoke ghost
Evidence interactions occur
Time passes in investigation phase

High aggression triggers hunt events.

---
GAME MODES

The game contains two primary modes:

Classic Investigation

Ranked Investigation

Both modes share the same core investigation gameplay but differ in difficulty scaling, rewards, and ranking impact.

CLASSIC INVESTIGATION MODE

Classic mode is designed for casual play and cooperative investigation.

Difficulty Presets

Mudah - 1-3

Standard - 4 - 6

Angker 7 - 8

UJI NYALI - 9-10

Classic mode does not affect ranking.

Players receive:

Currency
XP
RoyalPass progression

RANKED INVESTIGATION MODE

Ranked mode is competitive and dynamically balanced.

Difficulty is calculated using an internal matchmaking algorithm based on:

Player Level
Player Rank Tier

The system estimates a difficulty value to determine:

Ghost aggression scaling
Evidence difficulty
Sanity drain rate
Hunt probability

Ranked mode uses matchmaking to place players with similar skill levels.

Ranked rewards include:

Rank Points
Season rewards
Special cosmetics

RANK DIFFICULTY ESTIMATION ALGORITHM

The system calculates a difficulty score.

DifficultyScore = (PlayerLevelWeight + RankTierWeight)

Example scaling:

Level Influence
Low level players face lower aggression.

High level players face stronger ghost behavior.

Rank Influence
Higher ranks increase investigation difficulty.

Difficulty factors adjusted:

Ghost aggression multiplier
Sanity drain multiplier
Hunt trigger probability
Evidence complexity

This system ensures ranked matches remain challenging regardless of player progression.


RANKED MATCH DIFFICULTY SCALE

Ranked difficulty uses a scalable system from:

Difficulty Level: 1 – 10

Each rank tier influences the difficulty estimation for the match.

Difficulty Scaling per Rank Group:

Bayi → Difficulty 1
Balita → Difficulty 1 – 3
Anak-Anak → Difficulty 2 – 4
Remaja → Difficulty 4 – 6
Dewasa → Difficulty 6 – 8
Profesional → Difficulty 7 – 9
Detektive → Difficulty 8 – 10
Sang Ahli → Difficulty 10

The system dynamically adjusts:

Ghost Aggression
Sanity Drain Speed
Hunt Probability
Evidence Difficulty

STAR PROGRESSION SYSTEM

Rank progression uses stars.

Win Condition:
+1 Star

Loss Condition:
-1 Star

Players advance when reaching the required number of stars for the rank tier.

RANK TIER STRUCTURE

BAYI RANK

Bayi 3
Requirement: 3 Stars

Bayi 2
Requirement: 3 Stars

Bayi 1
Requirement: 3 Stars

BALITA RANK

Balita 3
Requirement: 3 Stars

Balita 2
Requirement: 3 Stars

Balita 1
Requirement: 3 Stars

ANAK-ANAK RANK

Anak-Anak 3
Requirement: 3 Stars

Anak-Anak 2
Requirement: 3 Stars

Anak-Anak 1
Requirement: 3 Stars

REMAJA RANK

Remaja 4
Requirement: 4 Stars

Remaja 3
Requirement: 4 Stars

Remaja 2
Requirement: 4 Stars

Remaja 1
Requirement: 4 Stars

DEWASA RANK

Dewasa 5
Requirement: 5 Stars

Dewasa 4
Requirement: 5 Stars

Dewasa 3
Requirement: 5 Stars

Dewasa 2
Requirement: 5 Stars

Dewasa 1
Requirement: 5 Stars

PROFESIONAL RANK

Profesional 5
Requirement: 5 Stars

Profesional 4
Requirement: 5 Stars

Profesional 3
Requirement: 5 Stars

Profesional 2
Requirement: 5 Stars

Profesional 1
Requirement: 5 Stars

DETEKTIVE RANK

Detektive 5
Requirement: 5 Stars

Detektive 4
Requirement: 5 Stars

Detektive 3
Requirement: 5 Stars

Detektive 2
Requirement: 5 Stars

Detektive 1
Requirement: 5 Stars

SANG AHLI RANK

Final Rank Tier

Sang Ahli

Progression System:
50 Stars total

This represents the highest mastery level in ranked play.

RANK PROGRESSION FLOW

Example:

Player starts at:

Bayi 3

After gaining 3 stars:

Promoted to Bayi 2

Then:

Bayi 1 → Balita 3 → Balita 2 → Balita 1 → Anak-Anak 3 → ...

This continues until:

Detektive 1 → Sang Ahli

RANKED MATCH REWARDS

Winning ranked matches grants:

Star Progress
Rank Advancement
Rank Reputation

Season rewards include:

Exclusive Titles
Profile Borders
Flex Gallery Items
Special Rank Cosmetics

RANK DISPLAY IN LOBBY

Player rank is visible in the lobby profile.

Display elements include:

Rank Tier Badge
Stars Progress
Season Border

Players may showcase rank cosmetics in the Flex Gallery.



MATCH SYSTEM

Handles match creation and lifecycle.

Responsibilities:

Classic -
Map selection
Difficulty selection
Player team creation
Match start and end
Phase transitions

Ranked -
Map Random
Scalable level
Player team creation
Match start and end
Phase transitions

Solo play
Party play (max 4 players)

---

ECONOMY SYSTEM

Players earn in-game currency from matches.

Rewards depend on:

Evidence collected
Correct ghost identification
Survival
Difficulty level

Currency can be used for:

Cosmetics
Profile items
Flex gallery items
Borders
Titles

---

ROYALPASS SYSTEM

Seasonal progression system.

Players gain RoyalPass XP from:

Matches
Daily login
Special objectives

Rewards include:

Exclusive cosmetics
Titles
Profile borders
Gallery items

---

DAILY CHECK-IN SYSTEM

30-day login reward system.

Players receive daily rewards for logging in.

Rewards include:

Currency
Cosmetics
Profile items
RoyalPass XP

---

LEADERBOARD SYSTEM

Displays top players based on:

Total investigations
Ranked score
Experience level

Leaderboard visible inside lobby building.

---

TRAINING SYSTEM

Players can test investigation tools inside the training building.

Training includes:

Tool practice
Evidence simulation
Ghost interaction tutorials

---

MAP SYSTEM

Maps represent haunted locations.

Initial maps include:

Abandoned Palace
Empty Building
Haunted House
Studio MM Nineteen

Each map contains:

Ghost spawn zones
Evidence interaction areas
Environmental horror triggers

Maps support both solo and multiplayer matches.

---

MULTIPLAYER SUPPORT

Max players per match: 4

Multiplayer features:

Team evidence sharing
Cooperative ghost investigation
Shared objective system

Server authority ensures gameplay integrity.

---

MATCH REWARD FLOW

Investigation completed
Ghost identified
Players extract
Results phase triggered
Rewards calculated
Players returned to lobby

---

PROJECT STRUCTURE GOAL

The architecture separates systems into:

Server Systems
Client Systems
Shared Systems
Map Assets

This modular design allows the game to expand with new maps, ghosts, and systems without restructuring the codebase.

---

FINAL DEVELOPMENT OBJECTIVE

Deliver a scalable Roblox horror investigation game with:

Immersive lobby hub
Cooperative ghost investigation gameplay
Dynamic horror systems
Progression and cosmetic systems
Long-term replayability





















PASRAHPHOBIA – RANK PROGRESSION TREE

Rank progression uses Stars until the final tier.

Win  → +1 Star
Lose → -1 Star

If stars reach maximum → Promotion
If stars reach 0 → Demotion

---

RANK TIER TREE

Bayi
├─ Bayi 3 (0 → 3 Stars)
├─ Bayi 2 (0 → 3 Stars)
└─ Bayi 1 (0 → 3 Stars)

Balita
├─ Balita 3 (0 → 3 Stars)
├─ Balita 2 (0 → 3 Stars)
└─ Balita 1 (0 → 3 Stars)

Anak-Anak
├─ Anak-Anak 3 (0 → 3 Stars)
├─ Anak-Anak 2 (0 → 3 Stars)
└─ Anak-Anak 1 (0 → 3 Stars)

Remaja
├─ Remaja 4 (0 → 4 Stars)
├─ Remaja 3 (0 → 4 Stars)
├─ Remaja 2 (0 → 4 Stars)
└─ Remaja 1 (0 → 4 Stars)

Dewasa
├─ Dewasa 5 (0 → 5 Stars)
├─ Dewasa 4 (0 → 5 Stars)
├─ Dewasa 3 (0 → 5 Stars)
├─ Dewasa 2 (0 → 5 Stars)
└─ Dewasa 1 (0 → 5 Stars)

Profesional
├─ Profesional 5 (0 → 5 Stars)
├─ Profesional 4 (0 → 5 Stars)
├─ Profesional 3 (0 → 5 Stars)
├─ Profesional 2 (0 → 5 Stars)
└─ Profesional 1 (0 → 5 Stars)

Detektive
├─ Detektive 5 (0 → 5 Stars)
├─ Detektive 4 (0 → 5 Stars)
├─ Detektive 3 (0 → 5 Stars)
├─ Detektive 2 (0 → 5 Stars)
└─ Detektive 1 (0 → 5 Stars)

Sang Ahli
└─ Victory Counter Rank

---

SANG AHLI SYSTEM

Sang Ahli does not use stars.

Instead it uses a **Victory Counter**.

Rank format:

Sang Ahli x0
Sang Ahli x1
Sang Ahli x2
Sang Ahli x3
Sang Ahli x4
...

---

WIN / LOSS RULES

Promotion Rule

Detektive 1 (5 Stars) → Win → Sang Ahli x1

---

Sang Ahli Victory

Example:

Sang Ahli x1 → Win → Sang Ahli x2
Sang Ahli x2 → Win → Sang Ahli x3

---

Sang Ahli Loss

Loss reduces the counter.

Example:

Sang Ahli x3 → Lose → Sang Ahli x2
Sang Ahli x2 → Lose → Sang Ahli x1
Sang Ahli x1 → Lose → Sang Ahli x0

---

DEMOTION RULE

If a player loses while at:

Sang Ahli x0

The player is demoted to:

Detektive 4

---

DEMOTION RECOVERY

Example recovery path:

Detektive 4 → Win → Detektive 5
Detektive 5 → Win → Sang Ahli x1

---

PROGRESSION FLOW

Example player journey:

Bayi 3
↓
Bayi 2
↓
Bayi 1
↓
Balita 3
↓
Balita 2
↓
Balita 1
↓
Anak-Anak 3
↓
Anak-Anak 2
↓
Anak-Anak 1
↓
Remaja 4
↓
Remaja 3
↓
Remaja 2
↓
Remaja 1
↓
Dewasa 5
↓
Dewasa 4
↓
Dewasa 3
↓
Dewasa 2
↓
Dewasa 1
↓
Profesional 5
↓
Profesional 4
↓
Profesional 3
↓
Profesional 2
↓
Profesional 1
↓
Detektive 5
↓
Detektive 4
↓
Detektive 3
↓
Detektive 2
↓
Detektive 1
↓
Sang Ahli x1
↓
Sang Ahli x2
↓
Sang Ahli x3
↓
Sang Ahli x4
↓
Sang Ahli x5
↓
...

Loss example:

Sang Ahli x1
↓ Lose
Sang Ahli x0
↓ Lose
Detektive 4

---

LEADERBOARD DISPLAY

Top ranked players are displayed using Sang Ahli counter.

Example leaderboard:

1. PlayerA — Sang Ahli x248
2. PlayerB — Sang Ahli x190
3. PlayerC — Sang Ahli x163

The counter represents total ranked victories after reaching the master tier.






PASRAHPHOBIA – RANKED DIFFICULTY ENGINE

The Ranked Difficulty Engine dynamically determines the difficulty of a match based on player skill level.

Difficulty is calculated using:

Player Level
Player Rank Tier
Team Average Rank

The result produces a value called:

Match Difficulty Score

Difficulty Range

1 – 10

---

DIFFICULTY FORMULA

DifficultyScore =
(LevelWeight × PlayerLevelFactor)
+
(RankWeight × RankTierFactor)

Example weights:

LevelWeight = 0.4
RankWeight = 0.6

Rank has stronger influence than level.

---

LEVEL FACTOR

Player Level Range

1 → 100

LevelFactor is normalized:

LevelFactor = PlayerLevel / 100

Example:

Level 10 → 0.10
Level 50 → 0.50
Level 100 → 1.00

---

RANK FACTOR

Each rank group has a base difficulty value.

Bayi → 1
Balita → 2
Anak-Anak → 3
Remaja → 5
Dewasa → 7
Profesional → 8
Detektive → 9
Sang Ahli → 10

RankFactor = RankDifficulty / 10

Example:

Bayi → 0.1
Balita → 0.2
Anak-Anak → 0.3
Remaja → 0.5
Dewasa → 0.7
Profesional → 0.8
Detektive → 0.9
Sang Ahli → 1.0

---

TEAM DIFFICULTY CALCULATION

For multiplayer matches, difficulty is based on team average.

TeamDifficulty =
Average(PlayerDifficultyScore)

Example team:

Player A → 0.72
Player B → 0.65
Player C → 0.80
Player D → 0.74

TeamDifficulty = 0.7275

Converted to difficulty scale:

DifficultyLevel = round(TeamDifficulty × 10)

Example result:

DifficultyLevel = 7

---

GAMEPLAY EFFECTS

The difficulty level influences several game systems.

Ghost Aggression

Higher difficulty increases:

Ghost roaming frequency
Ghost hunt trigger speed
Ghost reaction to players

---

SANITY DRAIN

Sanity drain multiplier increases with difficulty.

Example:

Difficulty 1 → 0.7× drain
Difficulty 5 → 1.0× drain
Difficulty 10 → 1.5× drain

---

HUNT PROBABILITY

Chance of ghost entering hunt phase increases.

Example:

Difficulty 2 → 10% chance
Difficulty 5 → 25% chance
Difficulty 10 → 45% chance

---

EVIDENCE DIFFICULTY

Higher ranks reduce evidence clarity.

Examples:

Temperature fluctuations become slower
Spirit Box responses become rarer
Ghost writing triggers less frequently

---

RANKED MATCH FLOW

1. Matchmaking forms team
2. System calculates TeamDifficulty
3. Map is randomly selected
4. Ghost difficulty parameters are generated
5. Match begins

---

BALANCING OBJECTIVE

The Ranked Difficulty Engine ensures:

High rank players face harder investigations
Low rank players receive more forgiving gameplay
Teams with mixed skill levels remain balanced

The system keeps Ranked matches challenging and fair regardless of player progression.






PASRAHPHOBIA – RANKED MATCHMAKING SYSTEM

Ranked matchmaking is responsible for creating balanced teams and fair investigations.

The system evaluates:

Player Rank Tier
Player Level
Party Size

The goal is to form teams with similar overall skill levels.

---

MATCHMAKING PARAMETERS

Each player entering ranked queue has the following values:

Rank Tier Score
Player Level Score
Matchmaking Score

---

RANK SCORE

Each rank group has a base score.

Bayi → 100
Balita → 200
Anak-Anak → 300
Remaja → 450
Dewasa → 600
Profesional → 750
Detektive → 900
Sang Ahli → 1000+

Within each rank stage the score increases.

Example:

Bayi 3 → 100
Bayi 2 → 120
Bayi 1 → 140

Balita 3 → 200
Balita 2 → 220
Balita 1 → 240

This allows matchmaking to differentiate players within the same tier.

---

LEVEL SCORE

Level contributes additional matchmaking weight.

LevelScore = PlayerLevel × 2

Example:

Level 10 → 20
Level 50 → 100
Level 100 → 200

---

MATCHMAKING SCORE

Final matchmaking score:

MatchScore = RankScore + LevelScore

Example player:

Rank: Dewasa 3 → 640
Level: 60 → 120

MatchScore = 760

---

TEAM MATCHMAKING

Ranked matches allow up to:

4 players per team

The system attempts to build teams with similar average MatchScore.

Example:

Team A average score → 760
Team B average score → 742

This is considered balanced.

---

MATCHMAKING RANGE

The acceptable score range expands over time.

Initial search range:

±50 MatchScore

After 20 seconds:

±100 MatchScore

After 40 seconds:

±150 MatchScore

This prevents long matchmaking queues.

---

PARTY MATCHMAKING

Players can queue as a party.

Party rules:

Party size: 2–4 players

MatchScore for a party is calculated using:

PartyAverageScore

Example party:

Player A → 720
Player B → 740
Player C → 710

PartyAverageScore → 723

The matchmaking system finds other players with similar values.

---

MAP SELECTION

In ranked mode:

Maps are randomly selected.

Each map has its own difficulty weight.

Example:

Abandoned Palace → 1.1 difficulty multiplier
Haunted House → 1.0 multiplier
Empty Building → 0.9 multiplier

This value modifies the Difficulty Engine.

---

ANTI-SMURF PROTECTION

The system detects suspicious skill mismatch.

Example:

Low level player
High win rate
Rapid rank increase

Such players receive increased difficulty scaling to prevent smurf abuse.

---

QUEUE FLOW

Ranked Matchmaking Process

1. Player enters ranked queue
2. Player matchmaking score is calculated
3. System searches for players with similar scores
4. Team is formed
5. Map is randomly selected
6. Difficulty Engine calculates match difficulty
7. Investigation begins

---

MATCH RESULT PROCESS

After the match:

Stars are updated.

Win → +1 Star
Lose → -1 Star

If promotion threshold is reached → Rank increases.

If star reaches 0 → Rank demotion occurs.

Special rule:

Sang Ahli uses victory counter instead of stars.

---

SYSTEM OBJECTIVE

The Ranked Matchmaking System ensures:

Balanced teams
Fair difficulty scaling
Reasonable queue times
Competitive ranked progression






PASRAHPHOBIA – GHOST BEHAVIOR ENGINE

The Ghost Behavior Engine controls how ghosts behave during investigations.

The system determines:

Ghost movement
Ghost interaction with environment
Ghost evidence generation
Ghost hunt behavior
Ghost reaction to players

The behavior dynamically changes based on:

Ghost Type
Player Sanity
Aggression Level
Match Difficulty

---

GHOST AI STATES

Each ghost operates using a state-based AI system.

Ghost States

Idle
Roaming
Interaction
Manifestation
Hunt

---

IDLE STATE

The ghost remains inactive in its favorite room.

Behavior:

Minimal activity
Rare environmental interaction
Low evidence generation

Idle state typically occurs at the beginning of investigations.

---

ROAMING STATE

The ghost moves around the map.

Behavior:

Moves between nearby rooms
Triggers environmental events
May appear briefly to players

Roaming increases as:

Time passes
Aggression increases

---

INTERACTION STATE

The ghost interacts with objects in the environment.

Possible interactions:

Doors opening or closing
Lights flickering
Objects moving
Sound disturbances

These interactions help players detect evidence.

---

MANIFESTATION STATE

The ghost appears visually for a short time.

Possible manifestations:

Shadow figure
Full apparition
Partial silhouette

Manifestations increase player fear and reduce sanity.

---

HUNT STATE

The ghost becomes fully aggressive and attempts to kill players.

Hunt triggers when aggression reaches threshold.

During hunt:

Lights flicker
Doors lock
Ghost actively searches for players

Players must hide or escape.

---

GHOST AGGRESSION SYSTEM

Aggression determines how active and dangerous the ghost is.

Aggression increases when:

Player sanity is low
Players provoke ghost
Evidence interactions occur
Time passes

Aggression values influence:

Roaming frequency
Manifestation rate
Hunt probability

---

SANITY INTERACTION

Player sanity directly affects ghost behavior.

High Sanity

Ghost is less active.

Medium Sanity

Ghost interactions increase.

Low Sanity

Ghost hunts become more frequent.

---

EVIDENCE GENERATION

Ghosts generate investigation evidence through behavior.

Examples:

Spirit Box responses
Temperature drops
EMF spikes
Ghost writing events
Motion detection

Evidence generation frequency depends on:

Ghost Type
Difficulty Level
Aggression Level

---

GHOST TYPE VARIATION

There are 12 ghost types in the game.

Each ghost type modifies behavior patterns.

Example traits:

Aggressive Ghost

Higher hunt frequency

Passive Ghost

More environmental interactions

Deceptive Ghost

Rare evidence but frequent manifestations

Fast Ghost

Moves faster during hunts

Each ghost type has unique investigation challenges.

---

DIFFICULTY INFLUENCE

Match difficulty modifies ghost behavior.

Low Difficulty

Slow aggression growth
Frequent evidence

High Difficulty

Fast aggression growth
Rare evidence
More hunts

Difficulty ranges from:

1 → 10

---

FEAR ENGINE INTEGRATION

Ghost behavior interacts with the Fear Engine.

Fear events include:

Sudden noises
Visual hallucinations
Environmental disturbances

Fear intensity scales with:

Ghost proximity
Sanity level
Aggression level

---

MATCH BEHAVIOR FLOW

Investigation begins.

Ghost starts in Idle state.

As time passes:

Idle → Roaming → Interaction

If aggression rises:

Manifestations occur.

If aggression threshold is reached:

Hunt state begins.

After hunt ends:

Ghost returns to roaming state.

---

SYSTEM OBJECTIVE

The Ghost Behavior Engine creates dynamic and unpredictable horror gameplay.

The system ensures:

Each match feels different
Players must actively investigate
Ghost behavior evolves over time
High difficulty matches become increasingly dangerous





PASRAHPHOBIA – PARANORMAL EVENT ENGINE

The Paranormal Event Engine controls random supernatural events during investigations.

These events create tension, unpredictability, and environmental storytelling.

Events can occur even when the ghost is not actively hunting.

The system is influenced by:

Ghost Aggression
Player Sanity
Match Difficulty
Player Location

---

EVENT CATEGORIES

Paranormal events are divided into several categories.

Environmental Events
Ghost Manifestation Events
Fear Events
Hunt Warning Events

Each category creates different gameplay effects.

---

ENVIRONMENTAL EVENTS

Environmental events affect the physical environment of the map.

Examples:

Lights flicker
Doors slam shut
Objects fall or move
Windows shake
Electronic interference

These events indicate ghost activity but do not directly harm players.

Environmental events help players locate the ghost.

---

GHOST MANIFESTATION EVENTS

The ghost briefly appears to players.

Manifestations may include:

Shadow figures
Full body apparition
Partial silhouettes
Ghost walking across hallway

These events reduce player sanity and increase fear.

---

FEAR EVENTS

Fear events are psychological disturbances.

Examples:

Footsteps in empty rooms
Whispers near the player
Sudden loud noises
Hallucination shadows
Objects moving when no one is nearby

Fear events mainly affect player immersion and sanity.

---

HUNT WARNING EVENTS

Before a hunt begins, warning events may occur.

Examples:

Lights turning red
Heavy footsteps
Doors locking briefly
Ghost breathing sounds

These events warn players that the ghost is becoming aggressive.

---

EVENT TRIGGER SYSTEM

Events are triggered based on internal conditions.

Trigger factors include:

Ghost Aggression Level
Player Sanity Average
Time spent in investigation
Difficulty Level

Example trigger logic:

Low Aggression → Rare events
Medium Aggression → Frequent environmental events
High Aggression → Manifestations and hunt warnings

---

PLAYER PROXIMITY SYSTEM

Events can trigger based on player proximity to the ghost.

Close to ghost room

Higher chance of manifestation events.

Far from ghost room

Higher chance of environmental disturbances.

---

EVENT FREQUENCY SCALING

Event frequency scales with match difficulty.

Difficulty 1–3

Events occur occasionally.

Difficulty 4–7

Events occur regularly.

Difficulty 8–10

Events occur frequently and unpredictably.

---

MULTIPLAYER EVENT DISTRIBUTION

Events can affect:

Single player
Nearby players
Entire team

Example:

One player hears whispering while others do not.

This increases psychological tension.

---

EVENT COOLDOWN SYSTEM

Each event type has cooldown timers.

This prevents events from occurring too frequently.

Example:

Environmental event cooldown → 20 seconds

Manifestation cooldown → 45 seconds

Hunt warning cooldown → depends on aggression level.

---

EVENT PRIORITY SYSTEM

Certain events override others.

Example priority:

Hunt Event
Manifestation Event
Environmental Event
Fear Event

If a hunt begins, all other events pause.

---

SYSTEM OBJECTIVE

The Paranormal Event Engine ensures every match feels different.

Players cannot fully predict ghost behavior.

Events build tension gradually before hunts occur.

The system creates a constantly evolving horror atmosphere.






PASRAHPHOBIA – GHOST PERSONALITY ENGINE

The Ghost Personality Engine adds behavioral variation to ghosts.

Even when two matches contain the same ghost type, their behavior may feel different due to personality traits.

This system ensures long-term replayability and unpredictability.

The system is designed to support future updates and additional personality traits.

---

SYSTEM STRUCTURE

Ghost behavior is determined by three layers:

Ghost Type
Ghost Personality
Match Difficulty

Example structure:

Ghost Behavior =
GhostType + PersonalityModifiers + DifficultyModifiers

---

PERSONALITY TRAITS

Each ghost can receive one or more personality traits.

Traits modify ghost behavior patterns.

Example traits:

Aggressive
Shy
Territorial
Curious
Deceptive
Noisy
Silent
Stalker

Traits are randomly assigned at the start of each match.

---

AGGRESSIVE PERSONALITY

Behavior:

Higher hunt probability
Shorter hunt cooldown
Faster aggression growth

Evidence generation may be slightly reduced.

---

SHY PERSONALITY

Behavior:

Ghost avoids player proximity
Less visual manifestations
More subtle environmental events

Evidence appears more slowly.

---

TERRITORIAL PERSONALITY

Behavior:

Ghost strongly protects its favorite room.

Manifestations occur more often near ghost room.

Roaming distance is reduced.

---

CURIOUS PERSONALITY

Behavior:

Ghost frequently follows player movement.

Higher roaming frequency.

More interactions in rooms where players are present.

---

DECEPTIVE PERSONALITY

Behavior:

Creates misleading evidence patterns.

False EMF spikes
Temperature changes without ghost presence

Players must investigate more carefully.

---

NOISY PERSONALITY

Behavior:

Frequent environmental disturbances.

Doors slam often
Objects move frequently
Sound events occur regularly

However, hunts may be slightly less frequent.

---

SILENT PERSONALITY

Behavior:

Very few environmental hints.

Minimal sounds
Minimal object interactions

Ghost becomes harder to track.

---

STALKER PERSONALITY

Behavior:

Ghost secretly follows a specific player.

Higher manifestation frequency near that player.

Hunts may target the stalked player first.

---

PERSONALITY ASSIGNMENT

At the start of each match:

1 or 2 personality traits are randomly assigned.

Example combinations:

Aggressive + Territorial
Shy + Silent
Curious + Noisy
Deceptive + Stalker

This creates hundreds of possible ghost behavior variations.

---

SYSTEM INTEGRATION

Ghost Personality affects multiple systems:

Ghost Behavior Engine
Paranormal Event Engine
Evidence System
Aggression System
Fear Engine

This ensures personality influences the entire gameplay loop.

---

FUTURE EXPANSION

The system is designed for future updates.

New personalities can be added without modifying core systems.

Possible future traits:

Chaotic object-throw behavior
Light Manipulator
Shadow Walker
Door Keeper
Sound Mimic

This allows PASRAHPHOBIA to grow with new content over time.

---

SYSTEM OBJECTIVE

The Ghost Personality Engine ensures:

Ghosts feel unique in every match.
Players cannot memorize predictable behavior patterns.
Investigation remains challenging even after many hours of gameplay.






1. Pocong
   - Buku Terkutuk
   - Suhu Membeku
   - Bola Arwah

2. Kuntilanak
   - Kotak Arwah
   - Bola Arwah
   - Gerakan Gaib

3. Tuyul
   - Jejak Energi
   - Gerakan Gaib
   - Bola Arwah

4. Genderuwo
   - Kotak Arwah
   - Jejak Energi
   - Gerakan Gaib

5. Sundel Bolong
   - Buku Terkutuk
   - Kotak Arwah
   - Bola Arwah

6. Leak
   - Jejak Energi
   - Suhu Membeku
   - Buku Terkutuk

7. Wewe Gombel
   - Kotak Arwah
   - Gerakan Gaib
   - Suhu Membeku

8. Banaspati
   - Jejak Energi
   - Bola Arwah
   - Suhu Membeku

9. Palasik
   - Buku Terkutuk
   - Gerakan Gaib
   - Jejak Energi

10. Jerangkong
    - Buku Terkutuk
    - Kotak Arwah
    - Suhu Membeku

11. Hantu Air
    - Bola Arwah
    - Suhu Membeku
    - Gerakan Gaib

12. Bayangan Hitam
    - Kotak Arwah
    - Jejak Energi
    - Bola Arwah





GHOST FAVORITE ROOM SYSTEM

Each ghost has a Favorite Room inside the map.

This room becomes the primary location where paranormal activity occurs.

The Favorite Room influences:

Evidence spawn rate
Ghost manifestation
Paranormal events
Hunt start location

The system ensures investigations feel logical instead of random.

---

ROOM SELECTION

At the start of a match, the system selects one room as the ghost’s Favorite Room.

Selection rules:

Room must be accessible
Room must not be outside areas
Room must allow ghost navigation

Example rooms:

Bedroom
Bathroom
Kitchen
Living Room
Hallway
Storage Room

---

ACTIVITY ZONE

Each Favorite Room has an Activity Radius.

Zone Structure

Favorite Room (Primary Activity)

Nearby Rooms (Secondary Activity)

Distant Rooms (Rare Activity)

Most ghost events occur in the primary zone.

---

EVIDENCE SPAWN LOGIC

Evidence appears based on room proximity.

Primary Room

Highest evidence probability.

Nearby Rooms

Medium evidence probability.

Far Rooms

Very low evidence probability.

---

ROAMING SYSTEM

Ghosts may temporarily roam to nearby rooms.

Roaming distance depends on:

Ghost Personality
Aggression Level
Difficulty

Example behaviors:

Territorial Ghost → Rare roaming
Curious Ghost → Frequent roaming

After roaming, the ghost often returns to the Favorite Room.

---

HUNT START LOCATION

Hunts usually begin near the Favorite Room.

This makes investigation strategy important.

Players who identify the ghost room early gain advantage.

---

ROOM CHANGE EVENT

In rare cases, the ghost may change its Favorite Room.

Trigger conditions:

Very high aggression
Long investigation time

Room change creates new investigation challenges.

---

SYSTEM OBJECTIVE

The Ghost Favorite Room System ensures:

Investigations feel structured
Evidence gathering feels logical
Players can track ghost activity patterns








DYNAMIC HORROR AUDIO SYSTEM

The Dynamic Horror Audio System controls all horror-related sounds in the game.

The system dynamically adjusts audio based on:

Ghost proximity
Player sanity
Ghost aggression
Room location
Paranormal events

This creates a constantly evolving horror atmosphere.

---

AUDIO CATEGORIES

Ambient Sound
Ghost Sound
Environmental Sound
Fear Sound
Hunt Sound

Each category plays different roles during gameplay.

---

AMBIENT SOUND

Ambient sound builds the atmosphere of the map.

Examples:

Wind noise
House creaking
Distant thunder
Electrical hum

Ambient sound changes based on:

Room type
Map location
Match phase

---

GHOST SOUND

Ghost sounds indicate ghost presence.

Examples:

Footsteps
Breathing sounds
Whispers
Ghost crying

Volume increases when the player is close to the ghost.

---

ENVIRONMENTAL SOUND

Triggered by paranormal interactions.

Examples:

Door slam
Object falling
Light buzzing
Window shaking

These sounds often accompany environmental events.

---

FEAR SOUND

Psychological audio effects triggered when player sanity drops.

Examples:

Heartbeats
Distorted whispers
Sudden sound spikes
Background chanting

These sounds create tension without showing the ghost.

---

HUNT SOUND

During hunts, the sound environment changes drastically.

Examples:

Loud ghost footsteps
Heartbeat audio
Heavy breathing
Aggressive music layer

This signals immediate danger.

---

DIRECTIONAL AUDIO

Ghost sounds use directional aud










MAP INTERACTION HORROR SYSTEM

The Map Interaction Horror System controls how objects in the environment react to paranormal activity.

These interactions create the feeling that the map is haunted and alive.

Objects react to:

Ghost proximity
Ghost aggression
Paranormal events
Player actions

The system triggers environmental horror interactions dynamically.

---

INTERACTION TYPES

Door Interaction
Light Interaction
Object Movement
Electronic Disturbance
Special Horror Events

Each interaction type produces visual and audio feedback.

---

DOOR INTERACTION

Doors may react to ghost activity.

Examples:

Door slowly opening
Door slamming shut
Door locking during hunts

Doors near the ghost room react more frequently.

---

LIGHT INTERACTION

Lights are commonly affected by paranormal energy.

Examples:

Lights flickering
Lights turning off suddenly
Lights breaking

Frequent flickering may indicate ghost presence.

---

OBJECT MOVEMENT

Objects in the environment may move when the ghost interacts with them.

Examples:

Chairs sliding
Objects falling from tables
Paintings tilting

These interactions help players i








AI HORROR DIRECTOR SYSTEM

The AI Horror Director controls the pacing and tension of the investigation.

Instead of events occurring randomly, the director adjusts paranormal activity to create a balanced horror experience.

The system monitors player conditions and dynamically adjusts ghost behavior and paranormal events.

---

DIRECTOR VARIABLES

The director constantly tracks several gameplay variables.

Player sanity average
Ghost aggression level
Time spent in investigation
Recent paranormal events
Player proximity to ghost

These variables determine the current tension level.

---

TENSION LEVELS

The system uses four tension levels.

Calm
Uneasy
Threat
Critical

Each level changes how frequently paranormal events occur.

---

CALM STATE

Early investigation phase.

Characteristics:

Low paranormal activity
Rare environmental events
Minimal ghost manifestations

This allows players to explore the map.

---

UNEASY STATE

Ghost activity becomes noticeable.

Examples:

Doors opening
Lights flickering
Distant footsteps

Players begin locating the ghost.

---

THREAT STATE

Ghost aggression increases significantly.

Examples:

Frequent manifestations
Environmental disturbances
Fear events

Players feel strong tension.

---

CRITICAL STATE

Maximum danger.

Examples:

Ghost hunts
Multiple paranormal events
Extreme environmental activity

Players must hide or escape.

---

TENSION TRANSITIONS

The director adjusts tension dynamically.

Example progression:

Calm → Uneasy → Threat → Critical

After a hunt ends, the tension drops temporarily.

Example:

Critical → Uneasy

This creates pacing similar to horror films.

---

PLAYER FEEDBACK LOOP

The director reacts to player behavior.

Examples:

Players staying near ghost room → tension increases faster

Players spreading across map → slower tension growth

Players losing sanity → faster escalation

---




CONTRACT INVESTIGATION SYSTEM

The Contract System generates investigation missions for players.

Each contract defines:

Map location
Difficulty level
Primary objective
Optional objectives
Reward multiplier

Players accept contracts before starting a match.

Contracts are displayed on the Contract Board inside the Lobby Social Hub.

---

CONTRACT ELEMENTS

Each contract contains the following information.

Location
Investigation Difficulty
Primary Objective
Bonus Objectives
Reward Value

Example contract:

Location: Haunted House
Difficulty: Standard
Primary Objective: Identify the ghost type
Bonus Objective: Capture ghost manifestation
Bonus Objective: Survive a hunt

Reward multiplier increases when bonus objectives are completed.

---

PRIMARY OBJECTIVE

The main objective is always:

Identify the ghost type.

Players must gather evidence and submit the correct ghost guess.

Completing the primary objective grants base rewards.

---

BONUS OBJECTIVES

Each contract generates random optional objectives.

Examples:

Capture ghost photo
Survive a ghost hunt
Detect ghost movement
Use Spirit Communication successfully
Record freezing temperature

Bonus objectives provide extra rewards.

---

CONTRACT DIFFICULTY

Contracts determine investigation difficulty.

Difficulty affects:

Ghost aggression
Sanity drain
Evidence clarity
Reward multiplier

Example:

Easy Contract
Low aggression
Lower rewards

Nightmare Contract
High aggression
High rewards

---

CONTRACT BOARD

Contracts are shown in the Lobby Social Hub.

Players interact with the Contract Board to select a contract.

The board displays:

Available contracts
Map location
Difficulty rating
Estimated reward

Once a contract is selected, the MatchSystem prepares the investigation.

---

CONTRACT GENERATION

Contracts are generated dynamically by the system.

Variables include:

Map rotation
Difficulty pool
Bonus objective pool

This ensures each match feels different.

---

SYSTEM OBJECTIVE

The Contract System gives players a clear mission structure.

It encourages:

Team coordination
Replayability
Reward progression
 











































DYNAMIC GHOST MODIFIER SYSTEM

The Ghost Modifier System introduces random behavioral variations to ghosts.

Each match assigns one or more modifiers to the ghost.

Modifiers change ghost behavior without changing the ghost type.

This ensures that even the same ghost type can behave differently across matches.

---

MODIFIER TYPES

Ghost modifiers are divided into several categories.

Aggression Modifiers
Evidence Modifiers
Movement Modifiers
Psychological Modifiers

Each modifier alters gameplay in a different way.

---

AGGRESSION MODIFIERS

These modifiers affect ghost hostility.

Examples:

Rage
Ghost aggression increases faster.

Dormant
Ghost aggression increases slowly.

Unstable
Ghost aggression fluctuates randomly.

---

EVIDENCE MODIFIERS

These modifiers affect evidence generation.

Examples:

Faint Presence
Evidence appears less frequently.

Overactive
Evidence appears more frequently.

Distorted Signals
Some evidence readings may appear misleading.

---

MOVEMENT MODIFIERS

These modifiers affect ghost roaming patterns.

Examples:

Wanderer
Ghost roams more frequently.

Territorial
Ghost rarely leaves its favorite room.

Blink Step
Ghost teleports short distances during hunts.

---

PSYCHOLOGICAL MODIFIERS

These modifiers affect fear effects.

Examples:

Whispering Presence
Players hear frequent whispers.

Shadow Stalker
Ghost manifestations occur behind players.

Sanity Leech
Player sanity drains faster when near the ghost.

---

MODIFIER ASSIGNMENT

At the start of each match:

1–2 modifiers are randomly assigned.

Example:

Ghost Type: Kuntilanak
Modifier 1: Shadow Stalker
Modifier 2: Faint Presence

This combination creates a unique investigation experience.

---

SYSTEM INTEGRATION

Ghost modifiers influence multiple systems.

GhostSystem
EvidenceSystem
HorrorDirector
FearEngine
SanitySystem

Each system reads modifier effects when calculating behavior.

---

SYSTEM OBJECTIVE

The Ghost Modifier System increases replayability.

Players cannot rely on memorized strategies.

Each investigation requires observation and adaptation.







DYNAMIC MAP EVENT SYSTEM

The Dynamic Map Event System introduces environmental conditions that affect investigations.

Each match may start with one map event.

Map events modify the environment, ghost behavior, or player experience.

This ensures that maps feel different in every investigation.

---

EVENT CATEGORIES

Map events are divided into several categories.

Environmental Events
Power Events
Weather Events
Supernatural Events

Each event influences gameplay differently.

---

ENVIRONMENTAL EVENTS

These events change environmental conditions inside the map.

Examples:

Broken Lighting
Some lights cannot be turned on.

Unstable Electricity
Lights flicker frequently.

Heavy Fog
Player vision distance is reduced.

---

POWER EVENTS

These events affect electricity systems.

Examples:

Power Failure
Entire building loses electricity.

Overloaded Circuits
Turning on too many lights causes power failure.

Backup Generator
Power can be restored temporarily.

---

WEATHER EVENTS

Weather events affect the atmosphere outside the building.

Examples:

Thunderstorm
Frequent thunder and lightning.

Heavy Rain
Loud rain sounds reduce ghost audio clarity.

Strong Wind
Doors may slam unexpectedly.

---

SUPERNATURAL EVENTS

Rare paranormal conditions.

Examples:

Cursed Ground
Sanity drains faster in certain rooms.

Haunted Zone
Ghost manifestations occur more often.

Spirit Echo
Players may hear past ghost interactions.

---

EVENT ASSIGNMENT

At match start:

The system randomly assigns one event.

Example:

Map: Abandoned Palace
Event: Thunderstorm

Map: Haunted House
Event: Power Failure

Some events are map-specific.

---

SYSTEM INTEGRATION

Map events modify the behavior of other systems.

GhostSystem
MapInteractionSystem
HorrorDirector
SanitySystem
AudioSystem

Example:

Thunderstorm increases ambient sound volume.

Power Failure increases ghost aggression.

---

SYSTEM OBJECTIVE

The Dynamic Map Event System increases replayability.

Players must adapt their investigation strategy depending on the map conditions.



PASRAHPHOBIA — DESIGN DOCUMENT STATUS
1️⃣ Gameplay Rulebook

Berisi:

core gameplay loop

ghost behavior states

evidence system

sanity system

aggression system

hunt rules

win / lose condition

Tujuan: mengunci aturan gameplay.

2️⃣ Economy Balance Sheet

Berisi:

MM / PP / Robux

rarity system R1–R5

daily check-in

daily mission

reward cap

RoyalPass

Lifetime pass

Tujuan: mengunci balancing ekonomi.

3️⃣ Spectator Distortion Matrix

Berisi:

Fake Ghost = 60%
Uncertain Event = 30%
Real Ghost = 10%

komunikasi voice spectator.

Tujuan: mengunci mechanic spectator unik game.

4️⃣ Master System Interaction Map

Berisi dependency antar system:

MatchSystem
GhostSystem
EvidenceSystem
InvestigationSystem
HorrorDirector
AggressionSystem
SanitySystem
EconomySystem
RankedSystem
ProfileSystem

Tujuan: mencegah dependency chaos saat coding.

5️⃣ AI Development Pipeline

Pipeline AI development:

Architecture AI
↓
System Design AI
↓
Code Generation AI
↓
Integration AI
↓
QA AI
↓
Optimization AI

Tujuan: workflow AI development.

6️⃣ Automated AI Code Generation

Berisi aturan:

service registration

EventBus communication

client/server separation

module generation rules

Tujuan: AI menghasilkan code yang konsisten dengan arsitektur.

Arsitektur Proyekmu Sekarang

Jika kita gabungkan semuanya, blueprint PASRAHPHOBIA sekarang kira-kira seperti ini:

Bootstrap
   │
ServiceRegistry
   │
   ├ MatchSystem
   ├ GhostSystem
   ├ EvidenceSystem
   ├ InvestigationSystem
   ├ AggressionSystem
   ├ HorrorDirector
   ├ SanitySystem
   ├ MapInteractionSystem
   ├ MapEventSystem
   ├ EconomySystem
   ├ RankedSystem
   ├ ProfileSystem
   └ ContractSystem

Semua komunikasi system:

EventBus



PASRAHPHOBIA – FULL PROJECT BLUEPRINT

PROJECT OVERVIEW

PASRAHPHOBIA is a cooperative multiplayer horror investigation game developed on Roblox.

Players explore haunted locations to identify supernatural entities using investigation tools. The game supports solo play and cooperative teams of up to four players.

The experience focuses on psychological tension, investigation mechanics, and dynamic ghost behavior.

The game features procedural gameplay systems including ghost modifiers, environmental events, ranked difficulty scaling, and contract-based missions.

---

PLAYER COUNT

Maximum players per investigation: 4

Game modes:

Classic Investigation
Ranked Investigation

Players can play solo or with a team.

---

CORE GAME LOOP

1 Player joins the game

2 Player spawns in Lobby Social Hub

3 Player explores lobby buildings

4 Player joins matchmaking or forms party

5 Contract selected

6 Match created

7 Players teleported to investigation map

8 Investigation phase begins

9 Players collect evidence

10 Players identify ghost type

11 Players attempt extraction

12 Results screen displayed

13 Rewards distributed

14 Players return to lobby

---

LOBBY SOCIAL HUB

The lobby is a central social space.

Players can freely walk inside the lobby map and enter buildings without teleportation.

Buildings contain different game systems.

Lobby Buildings:

Shop
Training
Leaderboard
Daily Reward
Matchmaking Hall
Flex Gallery

Lobby Systems:

Party System
Player Presence Tracking
Contract Board
Profile Inspection
Cosmetic Display

Spawn Area:

Central Plaza

Players can inspect other players by clicking their character.

Displayed above player:

Level
Title
Total Games Played

Additional profile details are shown when inspecting a player.

Winrate visibility can be toggled by the player.

---

PLAYER PROGRESSION

Players gain experience through investigations.

Level Range:

Level 1 → Level 100

Experience gained from:

Successful investigations
Evidence discovery
Survival
Difficulty bonus

Level progression unlocks:

Titles
Cosmetic items
Flex gallery items

---

RANKED PROGRESSION

Ranked mode uses a star progression system.

Win → +1 Star
Loss → −1 Star

Ranks are organized into tiers.

Rank Structure:

Bayi
Balita
Anak-Anak
Remaja
Dewasa
Profesional
Detektive
Sang Ahli

Each tier contains several divisions.

Example:

Bayi 3
Bayi 2
Bayi 1

Each division requires stars to promote.

Higher tiers require more stars.

---

FINAL RANK

Sang Ahli is the final rank.

Instead of divisions, it uses continuous progression.

Example:

Sang Ahli x1
Sang Ahli x2
Sang Ahli x3

If a player loses at Sang Ahli x1, they drop to Detektive 4.

---

RANKED DIFFICULTY SCALING

Ranked mode dynamically adjusts difficulty.

Difficulty scale:

1 – 10

Example mapping:

Bayi → Difficulty 1
Balita → Difficulty 1–3
Anak-Anak → Difficulty 2–4
Remaja → Difficulty 4–6
Dewasa → Difficulty 6–8
Profesional → Difficulty 7–9
Detektive → Difficulty 8–10
Sang Ahli → Difficulty 10

Difficulty influences:

Ghost aggression
Sanity drain speed
Hunt frequency
Evidence clarity

---

INVESTIGATION SYSTEM

Players investigate paranormal activity to determine the ghost type.

Primary Objective:

Identify the ghost type.

Players use investigation tools to collect evidence.

Evidence Types:

Bola Arwah
Buku Terkutuk
Gerakan Gaib
Jejak Energi
Kotak Arwah
Suhu Membeku

Evidence results are shared among the team.

The investigation journal helps players deduce the ghost identity.

---

GHOST SYSTEM

Total Ghost Types:

12

Each ghost has:

Unique behavior
Preferred evidence types
Personality traits
Aggression patterns

Ghost behavior states include:

Idle
Roaming
Interaction
Hunt

Ghost aggression increases based on:

Player proximity
Sanity levels
Environmental triggers

---

GHOST MODIFIER SYSTEM

Each match assigns random modifiers to ghosts.

Modifiers change ghost behavior without changing ghost type.

Examples:

Rage
Aggression increases faster.

Dormant
Aggression increases slower.

Shadow Stalker
Ghost manifests behind players.

Sanity Leech
Player sanity drains faster near ghost.

Modifiers create unique gameplay every match.

---

MAP EVENT SYSTEM

Each investigation may include environmental events.

Examples:

Thunderstorm
Power Failure
Heavy Fog
Cursed Ground

Events affect:

Visibility
Audio environment
Ghost behavior
Sanity drain

---

CONTRACT SYSTEM

Investigations are selected through contracts.

Contracts define:

Map
Difficulty
Objectives
Rewards

Primary Objective:

Identify the ghost type.

Optional objectives:

Capture ghost photo
Detect ghost movement
Survive hunt
Record freezing temperature

Completing bonus objectives increases rewards.

---

SANITY SYSTEM

Players have a sanity meter.

Sanity decreases over time and through paranormal interactions.

Low sanity causes:

Higher ghost aggression
Increased hallucinations
Greater chance of hunts

---

HORROR DIRECTOR

The Horror Director dynamically controls the tension of the match.

It manages:

Ghost manifestations
Environmental disturbances
Audio effects
Event timing

This prevents gameplay from becoming predictable.

---

MATCH SYSTEM

Responsible for:

Match creation
Team management
Phase transitions
Teleporting players to maps

Match phases include:

Lobby
Preparation
Investigation
Hunt
Extraction
Results

---

MAP SYSTEM

Investigation maps represent haunted locations.

Initial maps:

Abandoned Palace
Empty Building
Haunted House
Studio MM Nineteen

Maps contain:

Ghost spawn zones
Evidence interaction areas
Environmental triggers

---

ECONOMY SYSTEM

Players earn currency from investigations.

Rewards depend on:

Correct ghost identification
Evidence collected
Difficulty
Bonus objectives

Currency can be used for:

Cosmetics
Profile borders
Titles
Flex gallery items

---

DAILY CHECK-IN SYSTEM

30 day login reward system.

Players receive rewards for daily logins.

Rewards include:

Currency
Cosmetics
RoyalPass XP

---

ROYALPASS SYSTEM

Seasonal progression system.

Players gain RoyalPass XP through:

Matches
Daily logins
Special challenges

Rewards include:

Cosmetics
Titles
Profile borders
Flex gallery items

---

MULTIPLAYER SYSTEM

Supports cooperative teams.

Features:

Team evidence sharing
Cooperative investigation
Shared objectives

Server authority ensures fair gameplay.

---

FINAL DEVELOPMENT OBJECTIVE

Create a scalable multiplayer horror investigation game with:

Dynamic ghost behavior
Procedural investigation systems
Competitive ranked progression
Long-term replayability



01_ARCHITECTURE
  - Master System Map
   - Global System Flow
   - Technical System Blueprint
   - Server Bootstrap Architecture
   - Service Dependency Matrix
   
   PASRAHPOBIA — MASTER SYSTEM MAP


MASTER SYSTEM MAP

OVERVIEW

The Master System Map defines how all core systems of PASRAHPHOBIA interact with each other.

This architecture ensures that gameplay systems remain modular and scalable while maintaining synchronized gameplay logic across server and client.

The system is divided into four major layers:

Lobby Layer
Match Layer
Gameplay Layer
Persistence Layer

Each layer contains systems responsible for specific responsibilities.

LOBBY LAYER

The Lobby Layer manages all player interactions before a match begins.

Systems inside the Lobby Layer include:

LobbySocialHub
PartySystem
ContractSystem
ProfileSystem
ShopSystem
LeaderboardSystem

LobbySocialHub acts as the central entry point for all player activity.

Players can interact with lobby buildings which trigger these systems.

Lobby Layer responsibilities:

Player presence
Party creation
Contract selection
Profile inspection
Social interaction

Once players choose a contract and enter matchmaking, control moves to the Match Layer.

MATCH LAYER

The Match Layer manages matchmaking, match creation, and phase transitions.

Systems inside this layer include:

MatchSystem
MatchQueue
MatchBuilder
MatchLifecycle
TeleportService
GamePhaseSystem

MatchSystem creates a MatchInstance which stores all data for a match session.

MatchInstance contains:

Players
Selected map
Difficulty level
Ghost type
Modifiers
Objectives

Once a match instance is ready, players are teleported to the map.

After teleportation, the Gameplay Layer becomes active.

GAMEPLAY LAYER

The Gameplay Layer contains the core investigation mechanics.

Primary systems include:

GhostSystem
EvidenceSystem
SanitySystem
AggressionSystem
InvestigationSystem
HorrorDirector
MapInteractionSystem
MapEventSystem
GhostModifierSystem

Each system controls a specific part of gameplay.

GhostSystem

Controls ghost AI behavior, roaming, and hunt states.

EvidenceSystem

Spawns evidence types and synchronizes evidence discovery between players.

SanitySystem

Tracks player mental stability and affects ghost aggression.

AggressionSystem

Controls ghost hostility and hunt triggers.

InvestigationSystem

Tracks evidence gathered and player ghost guesses.

HorrorDirector

Controls pacing of paranormal events to maintain tension.

MapInteractionSystem

Handles environmental interactions such as doors, lights, and objects.

MapEventSystem

Creates dynamic environmental events like power failures or storms.

GhostModifierSystem

Applies special modifiers to ghosts that alter behavior.

These systems run simultaneously during the Investigation Phase.

HUNT SUBSYSTEM

The Hunt System is controlled primarily by GhostSystem and AggressionSystem.

Additional influences include:

SanitySystem
DifficultyScaling
GhostModifiers
MapEvents

During hunts:

Doors lock
Lights flicker
Ghost enters pursuit state

Players must hide or escape until the hunt timer ends.

DIFFICULTY SCALING LAYER

Difficulty affects nearly every gameplay system.

Difficulty values range from 1 to 10.

Difficulty is applied to:

Ghost aggression multiplier
Sanity drain speed
Hunt probability
Ghost movement speed
Evidence spawn frequency
Event frequency

Classic Mode

Players select difficulty manually.

Ranked Mode

Difficulty is calculated dynamically based on:

Player level
Player rank tier

PERSISTENCE LAYER

The Persistence Layer stores long-term player data.

Systems include:

DataPersistence
PlayerData
EconomyData
InventoryData
RankData

This layer ensures that player progression is saved between sessions.

Stored information includes:

Player level
Currency
Owned cosmetics
Rank tier
Match statistics

PROFILE AND PROGRESSION SYSTEM

ProfileSystem manages player identity and progression.

Player progression includes:

Player Level (1–100)
Rank Tier
Titles
Flex Gallery
Profile Border

Experience points are earned through matches.

Level progression unlocks cosmetic rewards and prestige.

ECONOMY SYSTEM

EconomySystem handles rewards and currency.

Players earn currency from:

Correct ghost identification
Evidence collection
Difficulty multiplier
Objective completion

Currency can be used for:

Cosmetics
Profile items
Gallery items
Borders
Titles

EVENT BUS

All major systems communicate through the EventBus.

EventBus allows systems to remain loosely coupled while reacting to game events.

Example events:

MatchStarted
EvidenceDiscovered
GhostHuntStarted
PlayerSanityChanged
MatchEnded

Systems subscribe to events rather than calling each other directly.

This improves modularity and scalability.

SYSTEM OBJECTIVE

The Master System Map ensures that all gameplay systems remain coordinated and scalable.

The architecture allows the game to expand with:

New maps
New ghost types
New evidence tools
New modifiers
New gameplay mechanics

without restructuring the core systems.















MASTER SYSTEM FLOW
Player Join
    │
    ▼
LobbySocialHub
    │
    ├── ProfileSystem
    ├── ShopSystem
    ├── ContractSystem
    ├── PartySystem
    │
    ▼
MatchQueue
    │
    ▼
MatchSystem
    │
    ▼
TeleportService
    │
    ▼
GamePhaseSystem
    │
    ▼
Investigation Phase
    │
    ├── GhostSystem
    ├── EvidenceSystem
    ├── SanitySystem
    ├── AggressionSystem
    ├── HorrorDirector
    ├── MapInteractionSystem
    ├── MapEventSystem
    └── GhostModifierSystem
    │
    ▼
Hunt System
    │
    ▼
Extraction
    │
    ▼
Results
    │
    ▼
EconomySystem
RankedSystem
    │
    ▼
DataPersistence
    │
    ▼
Return To Lobby
SYSTEM DEPENDENCY MAP
LobbySocialHub
     │
     ▼
MatchSystem
     │
     ▼
GamePhaseSystem
     │
     ▼
Investigation Systems
     │
     ├── GhostSystem
     ├── EvidenceSystem
     ├── SanitySystem
     ├── AggressionSystem
     ├── HorrorDirector
     │
     ▼
Hunt System
     │
     ▼
Results
     │
     ▼
Economy + Ranked
     │
     ▼
DataPersistence


PASRAHPHOBIA - ENGINE IMPLEMENTATION ROADMAP

OVERVIEW

The Engine Implementation Roadmap defines the order in which all systems of PASRAHPHOBIA will be implemented.

The roadmap ensures that systems are built in dependency-safe order so that each new system can rely on previously implemented systems.

This avoids broken dependencies and unstable gameplay architecture.

Implementation is divided into phases.

Each phase unlocks the next layer of systems.

---

PHASE 1 — CORE ENGINE FOUNDATION

Objective

Create the base infrastructure used by all systems.

Systems implemented:

EventBus
ConfigLoader
ServiceRegistry
Bootstrap

Responsibilities

EventBus handles communication between systems.

ConfigLoader loads configuration data from shared DataTypes.

ServiceRegistry registers and provides access to all services.

Bootstrap starts the entire server architecture.

Outcome

Server starts correctly and systems can register safely.

---

PHASE 2 — DATA AND PLAYER FOUNDATION

Objective

Create the persistent player data infrastructure.

Systems implemented:

DataPersistence
PlayerData
EconomyData
InventoryData
RankData

Responsibilities

Save and load player progression.

Store rank tier and star progress.

Store currency and cosmetic inventory.

Outcome

Players can join the game and their progression is loaded.

---

PHASE 3 — PROFILE AND PROGRESSION

Objective

Implement player identity and leveling.

Systems implemented:

ProfileSystem
PlayerLevel
ProfileInspect

Responsibilities

Player level progression (1–100)

Profile data:

Title
Flex border
Bio
Gallery items

Outcome

Players have persistent identity and progression.

---

PHASE 4 — LOBBY SYSTEM

Objective

Enable the Social Hub gameplay loop.

Systems implemented:

LobbySocialHub
PlayerPresence
PartySystem
LobbyInteraction
ContractSystem

Responsibilities

Lobby spawning
Party creation
Contract board interaction
Lobby building interactions

Outcome

Players can explore the lobby and prepare matches.

---

PHASE 5 — MATCH ENGINE

Objective

Create the match creation system.

Systems implemented:

MatchQueue
MatchBuilder
MatchInstance
MatchLifecycle
TeleportService

Responsibilities

Matchmaking
Team creation
Map selection
Teleport players to map

Outcome

Players can start investigations.

---

PHASE 6 — GAME PHASE SYSTEM

Objective

Control the investigation lifecycle.

Systems implemented:

GamePhaseSystem
PreparationPhase
InvestigationPhase
HuntPhase
ExtractionPhase
ResultsPhase

Responsibilities

Match flow control.

Phase transitions.

Outcome

Matches progress through structured phases.

---

PHASE 7 — GHOST ENGINE

Objective

Implement ghost AI and behavior.

Systems implemented:

GhostSystem
GhostStates
RoomSystem
GhostPersonality
GhostTraits

Responsibilities

Ghost roaming
Favorite room logic
Ghost behavior types

Outcome

Ghost exists and moves in maps.

---

PHASE 8 — EVIDENCE SYSTEM

Objective

Enable investigation gameplay.

Systems implemented:

EvidenceEngine
EvidenceSpawner
EvidenceSync
EvidenceValidator

Evidence types:

BolaArwah
BukuTerkutuk
GerakanGaib
JejakEnergi
KotakArwah
SuhuMembeku

Outcome

Players can collect investigation evidence.

---

PHASE 9 — SANITY AND AGGRESSION

Objective

Create tension and ghost hostility.

Systems implemented:

SanitySystem
AggressionSystem

Responsibilities

Player sanity drain.

Ghost aggression buildup.

Outcome

Ghost hunts become possible.

---

PHASE 10 — HUNT SYSTEM

Objective

Enable ghost attack events.

Systems implemented:

GhostHuntState
TargetSelection
PlayerDetection

Responsibilities

Ghost pursuit behavior.

Hunt timer management.

Outcome

Core horror gameplay becomes active.

---

PHASE 11 — HORROR DIRECTOR

Objective

Control pacing of horror events.

Systems implemented:

HorrorDirector
TensionSystem
EventScheduler
PlayerStateMonitor

Responsibilities

Control paranormal activity frequency.

Balance tension during matches.

Outcome

Game pacing feels dynamic.

---

PHASE 12 — MAP EVENTS

Objective

Introduce dynamic environmental effects.

Systems implemented:

MapEventSystem
EventAssignment
EventEffects
EventRegistry

Example events:

Power failure
Thunderstorm
Heavy fog
Object disturbances

Outcome

Maps become dynamic environments.

---

PHASE 13 — GHOST MODIFIERS

Objective

Add replayability through ghost variants.

Systems implemented:

GhostModifierSystem
ModifierAssignment
ModifierEffects
ModifierRegistry

Example modifiers:

BlinkStep
Rage
Dormant
ShadowStalker

Outcome

Each investigation feels unique.

---

PHASE 14 — RANKED SYSTEM

Objective

Enable competitive progression.

Systems implemented:

RankedSystem
RankDifficulty
RankStars
RankTiers

Responsibilities

Rank star progression.

Rank difficulty scaling.

Outcome

Ranked matches become available.

---

PHASE 15 — ECONOMY AND REWARDS

Objective

Implement reward distribution.

Systems implemented:

EconomySystem
RewardCalculation
CurrencyDistribution

Outcome

Players receive rewards after matches.

---

PHASE 16 — FINAL GAMEPLAY POLISH

Objective

Complete the final gameplay systems.

Systems implemented:

SpectatorSystem
LeaderboardSystem
DailyRewardSystem
RoyalPassSystem

Outcome

Full gameplay loop complete.

---

FINAL OBJECTIVE

By following this roadmap the PASRAHPHOBIA engine will evolve from a server framework into a complete multiplayer horror investigation game.

Each phase unlocks the next layer of gameplay complexity.









IMPLEMENTATION FLOW
Core Engine
   │
   ▼
Player Data
   │
   ▼
Profile System
   │
   ▼
Lobby System
   │
   ▼
Match Engine
   │
   ▼
Game Phases
   │
   ▼
Ghost Engine
   │
   ▼
Evidence System
   │
   ▼
Sanity & Aggression
   │
   ▼
Hunt System
   │
   ▼
Horror Director
   │
   ▼
Map Events
   │
   ▼
Ghost Modifiers
   │
   ▼
Ranked System
   │
   ▼
Economy
   │
   ▼
Final Systems



PASRAHPHOBIA - EVENT BUS EVENT LIST

OVERVIEW

The Event Bus Event List defines all global events that can be published through the EventBus.

These events allow systems to communicate without direct dependencies.

Each event includes:

Event Name
Publisher
Subscribers
Payload Data

All systems should communicate using these events whenever possible.

---

LOBBY EVENTS

PlayerJoinedLobby

Publisher:
LobbySocialHub

Subscribers:
ProfileSystem
PartySystem
LeaderboardSystem

Payload:

player

PlayerLeftLobby

Publisher:
LobbySocialHub

Subscribers:
PartySystem

Payload:

player

PartyCreated

Publisher:
PartySystem

Subscribers:
LobbySocialHub

Payload:

partyId
leader

PartyUpdated

Publisher:
PartySystem

Subscribers:
LobbySocialHub

Payload:

partyId
members

ContractSelected

Publisher:
ContractSystem

Subscribers:
MatchQueue

Payload:

partyId
contractId

---

MATCH EVENTS

PlayerQueued

Publisher:
MatchQueue

Subscribers:
MatchBuilder

Payload:

player
partyId

MatchCreated

Publisher:
MatchBuilder

Subscribers:

MatchLifecycle
TeleportService
GamePhaseSystem

Payload:

matchId
players
map
difficulty

MatchStarted

Publisher:
MatchLifecycle

Subscribers:

GhostSystem
EvidenceSystem
SanitySystem
AggressionSystem
InvestigationSystem
HorrorDirector

Payload:

matchId

MatchEnded

Publisher:
MatchLifecycle

Subscribers:

EconomySystem
RankedSystem
DataPersistence

Payload:

matchId
results

PlayersTeleported

Publisher:
TeleportService

Subscribers:

GamePhaseSystem

Payload:

matchId

---

PHASE EVENTS

PhaseStarted

Publisher:
GamePhaseSystem

Subscribers:

GhostSystem
EvidenceSystem
HorrorDirector

Payload:

matchId
phaseName

PhaseEnded

Publisher:
GamePhaseSystem

Subscribers:

MatchLifecycle

Payload:

matchId
phaseName

---

EVIDENCE EVENTS

EvidenceSpawned

Publisher:
EvidenceSystem

Subscribers:

InvestigationSystem

Payload:

matchId
evidenceType
location

EvidenceCollected

Publisher:
EvidenceSystem

Subscribers:

InvestigationSystem
HorrorDirector

Payload:

player
matchId
evidenceType

AllEvidenceDiscovered

Publisher:
InvestigationSystem

Subscribers:

GamePhaseSystem

Payload:

matchId

---

SANITY EVENTS

PlayerSanityChanged

Publisher:
SanitySystem

Subscribers:

AggressionSystem
HorrorDirector

Payload:

player
newSanity

TeamSanityLow

Publisher:
SanitySystem

Subscribers:

AggressionSystem

Payload:

matchId
averageSanity

---

GHOST EVENTS

GhostSpawned

Publisher:
GhostSystem

Subscribers:

HorrorDirector

Payload:

matchId
ghostType

GhostRoamed

Publisher:
GhostSystem

Subscribers:

MapInteractionSystem

Payload:

matchId
room

GhostInteraction

Publisher:
GhostSystem

Subscribers:

MapInteractionSystem
HorrorDirector

Payload:

matchId
interactionType

---

HUNT EVENTS

HuntTriggered

Publisher:
AggressionSystem

Subscribers:

GhostSystem
GamePhaseSystem
HorrorDirector

Payload:

matchId

HuntStarted

Publisher:
GhostSystem

Subscribers:

MapInteractionSystem
SoundSystem

Payload:

matchId

HuntEnded

Publisher:
GhostSystem

Subscribers:

GamePhaseSystem

Payload:

matchId

PlayerKilled

Publisher:
GhostSystem

Subscribers:

SpectatorSystem
MatchLifecycle

Payload:

player
matchId

---

MAP EVENTS

MapEventStarted

Publisher:
MapEventSystem

Subscribers:

HorrorDirector

Payload:

matchId
eventType

MapEventEnded

Publisher:
MapEventSystem

Subscribers:

HorrorDirector

Payload:

matchId
eventType

---

MODIFIER EVENTS

ModifiersAssigned

Publisher:
GhostModifierSystem

Subscribers:

GhostSystem

Payload:

matchId
modifiers

---

RESULT EVENTS

GhostGuessSubmitted

Publisher:
InvestigationSystem

Subscribers:

MatchLifecycle

Payload:

player
ghostType

ResultsCalculated

Publisher:
MatchLifecycle

Subscribers:

EconomySystem
RankedSystem

Payload:

matchId
results

RewardsGranted

Publisher:
EconomySystem

Subscribers:

ProfileSystem

Payload:

player
rewardData

---

RANK EVENTS

RankStarAdded

Publisher:
RankedSystem

Subscribers:

ProfileSystem

Payload:

player
newStarCount

RankStarRemoved

Publisher:
RankedSystem

Subscribers:

ProfileSystem

Payload:

player
newStarCount

RankTierChanged

Publisher:
RankedSystem

Subscribers:

ProfileSystem

Payload:

player
newTier

---

SYSTEM OBJECTIVE

The Event Bus Event List ensures that all systems communicate through predictable and documented events.

This structure allows new systems to subscribe to existing events without modifying existing code.

The architecture supports future expansion of PASRAHPHOBIA without breaking system dependencies.









EVENT FLOW EXAMPLE (REAL GAMEPLAY)

Contoh alur nyata dalam game:

Player collects evidence
        │
        ▼
EvidenceSystem
        │
        ▼
EventBus.Publish("EvidenceCollected")
        │
        ▼
InvestigationSystem updates evidence
        │
        ▼
HorrorDirector increases tension
CONTOH HUNT FLOW
SanitySystem
      │
      ▼
EventBus.Publish("TeamSanityLow")

AggressionSystem
      │
      ▼
EventBus.Publish("HuntTriggered")

GhostSystem
      │
      ▼
EventBus.Publish("HuntStarted")




PASRAHPHOBIA GLOBAL SYSTEM FLOW

OVERVIEW

PASRAHPHOBIA is built around multiple interconnected systems that control gameplay, player progression, economy, and social interaction.

The architecture separates systems into five primary layers.

Player Layer
Lobby Layer
Match Layer
Gameplay Systems
Progression Systems

Each layer communicates through server systems and shared configuration modules.

---

PLAYER ENTRY FLOW

Player joins server

↓

PlayerData loads from DataPersistence

↓

Player spawns in LobbySocialHub

↓

Lobby systems activate

PartySystem
LobbyInteraction
ProfileSystem
VoiceChat

↓

Player chooses activity

Join Match
Explore Lobby
Shop
Training

---

LOBBY SYSTEM FLOW

LobbySocialHub acts as the social center of the game.

Players can:

Form teams
Inspect profiles
Flex cosmetics
Access shop
Start matchmaking

Core lobby systems

LobbySocialHub
PartySystem
ProfileSystem
ShopSystem
LeaderboardSystem
TrainingSystem

Matchmaking occurs through MatchSystem.

---

MATCHMAKING FLOW

Player enters MatchmakingZone

↓

MatchQueue registers player or party

↓

MatchBuilder assembles players

↓

MatchInstance created

↓

TeleportService moves players to investigation map

↓

MatchLifecycle begins

---

MATCH LIFECYCLE FLOW

Preparation Phase

Players spawn in investigation map.

↓

Investigation Phase

Players search for evidence and identify ghost type.

↓

Hunt Phase

Ghost becomes aggressive and hunts players.

↓

Extraction Phase

Players escape investigation map.

↓

Results Phase

Rewards calculated.

↓

Return to Lobby

Players teleport back to LobbySocialHub.

---

GAMEPLAY SYSTEM FLOW

During the match several systems operate simultaneously.

GhostSystem
EvidenceSystem
AggressionSystem
FearEngine
HorrorDirector
SanitySystem
MapInteractionSystem

These systems create the dynamic horror environment.

Example interaction

GhostSystem triggers activity.

↓

HorrorDirector schedules tension events.

↓

FearEngine triggers visual or audio disturbance.

↓

EvidenceSystem generates investigation clues.

↓

AggressionSystem determines hunt probability.

---

SPECTATOR SYSTEM FLOW

When a player dies

↓

Player enters Spectator Mode

↓

SpectatorCamera follows alive players

↓

SpectatorDistortionSystem activates

60% Fake Ghost
30% Uncertain Event
10% Real Ghost

↓

Spectator communicates through voice chat.

Living players decide whether to trust the information.

---

PROGRESSION SYSTEM FLOW

After match completion

↓

RewardCalculator evaluates match performance.

↓

EconomySystem grants currency.

↓

EXPSystem grants player experience.

↓

RankedSystem updates star progress if ranked mode.

↓

RoyalPassSystem updates season progress.

↓

PlayerData updated in session.

↓

DataPersistence saves data.

---

ECONOMY FLOW

Player earns MM through gameplay.

↓

Currency stored in PlayerWallet.

↓

Player purchases items through ShopSystem.

↓

InventorySystem adds asset to player inventory.

↓

Cosmetics may be equipped and shown in LobbyFlex system.

---

SOCIAL LOOP

Lobby encourages social interaction.

Players see cosmetics.

↓

Players inspect profiles.

↓

Players want cosmetics.

↓

Players purchase items or RoyalPass.

↓

Players flex cosmetics in lobby.

↓

Other players see cosmetics.

↓

Loop repeats.

---

SYSTEM COMMUNICATION

Server systems communicate using EventBus and shared data modules.

Shared modules include

DataTypes
ConfigLoader
Utilities

These modules provide configuration and data consistency across client and server systems.

---

FINAL SYSTEM STRUCTURE

Player Layer

LobbySocialHub
ProfileSystem
PartySystem
ShopSystem

Match Layer

MatchSystem
MatchLifecycle
TeleportService

Gameplay Layer

GhostSystem
EvidenceSystem
AggressionSystem
HorrorDirector
SanitySystem

Progression Layer

EconomySystem
RankedSystem
RoyalPassSystem
EXPSystem

Persistence Layer

DataPersistence
PlayerData
InventoryData
RankData






GLOBAL SYSTEM FLOW (Visual)
PLAYER
   │
   ▼
LobbySocialHub
   │
   ├── ProfileSystem
   ├── PartySystem
   ├── ShopSystem
   └── TrainingSystem
   │
   ▼
MatchSystem
   │
   ▼
TeleportService
   │
   ▼
Investigation Match
   │
   ├── GhostSystem
   ├── EvidenceSystem
   ├── AggressionSystem
   ├── FearEngine
   ├── HorrorDirector
   └── SanitySystem
   │
   ▼
Match Results
   │
   ▼
RewardCalculator
   │
   ▼
EconomySystem + EXPSystem + RankedSystem
   │
   ▼
DataPersistence
   │
   ▼
Return To Lobby





PASRAHPHOBIA — MASTER SYSTEM INTERACTION MAP
1. GLOBAL SYSTEM ARCHITECTURE

PASRAHPHOBIA menggunakan modular service architecture.

Semua system terhubung melalui:

Bootstrap
ServiceRegistry
EventBus

Diagram global:

Bootstrap
   │
   ▼
ServiceRegistry
   │
   ├── MatchSystem
   ├── GhostSystem
   ├── EvidenceSystem
   ├── InvestigationSystem
   ├── AggressionSystem
   ├── HorrorDirector
   ├── SanitySystem
   ├── MapInteractionSystem
   ├── MapEventSystem
   ├── EconomySystem
   ├── RankedSystem
   ├── ProfileSystem
   └── ContractSystem

Semua komunikasi system menggunakan:

EventBus

Tujuan:

loose coupling
high scalability
AI-friendly architecture
2. MATCH SYSTEM RELATIONSHIP

MatchSystem adalah core orchestrator gameplay.

Dependency:

MatchSystem
 ├ MatchQueue
 ├ MatchBuilder
 ├ MatchInstance
 ├ MatchLifecycle
 └ TeleportService

Interaksi:

MatchSystem
 ├── GhostSystem
 ├── EvidenceSystem
 ├── InvestigationSystem
 ├── SpectatorSystem
 ├── EconomySystem
 └── RankedSystem

Flow:

Match Start
 ↓
Map Loaded
 ↓
Ghost Spawn
 ↓
Investigation Phase
 ↓
Hunt Events
 ↓
Extraction
 ↓
Reward Calculation
3. GHOST SYSTEM INTERACTION

GhostSystem mengontrol AI ghost.

Structure:

GhostSystem
 ├ GhostTypes
 ├ GhostTraits
 ├ GhostPersonality
 ├ RoomSystem
 └ States

Dependency:

GhostSystem
 ├ AggressionSystem
 ├ HorrorDirector
 ├ MapInteractionSystem
 └ SanitySystem

Flow:

Player Action
 ↓
AggressionSystem Update
 ↓
Ghost Behavior Update
 ↓
HorrorDirector Event
4. EVIDENCE SYSTEM INTERACTION

EvidenceSystem menangani bukti paranormal.

Modules:

EvidenceEngine
EvidenceSpawner
EvidenceValidator
EvidenceSync

Dependency:

EvidenceSystem
 ├ GhostSystem
 ├ InvestigationSystem
 └ MatchSystem

Evidence flow:

Tool Used
 ↓
EvidenceValidator
 ↓
GhostPresence Check
 ↓
Evidence Confirmed
5. INVESTIGATION SYSTEM

InvestigationSystem mengelola investigasi.

Modules:

EvidenceTracker
GhostGuess
InvestigationState

Interaksi:

InvestigationSystem
 ├ EvidenceSystem
 ├ MatchSystem
 └ ProfileSystem
6. HORROR DIRECTOR

HorrorDirector adalah dynamic tension system.

Modules:

DirectorRules
EventScheduler
PlayerStateMonitor
TensionSystem

Dependency:

HorrorDirector
 ├ GhostSystem
 ├ AggressionSystem
 └ MapEventSystem
7. SPECTATOR SYSTEM INTERACTION

SpectatorSystem aktif saat player mati.

Flow:

Player Death
 ↓
Spectator Mode
 ↓
SpectatorDistortionEngine

Dependency:

SpectatorSystem
 ├ MatchSystem
 ├ GhostSystem
 └ SpectatorDistortionEngine
8. ECONOMY SYSTEM FLOW

Reward flow:

Match End
 ↓
RewardCalculator
 ↓
EconomySystem
 ↓
PlayerData Save

Dependency:

EconomySystem
 ├ ProfileSystem
 ├ RankedSystem
 └ ContractSystem
9. PROFILE SYSTEM

ProfileSystem menyimpan data player.

Modules:

PlayerLevel
PlayerProfile
ProfileInspect

Dependency:

ProfileSystem
 ├ DataPersistence
 ├ EconomySystem
 └ RankedSystem
10. DATA PERSISTENCE

Data disimpan menggunakan Roblox DataStore.

Modules:

PlayerData
EconomyData
InventoryData
RankData

Save trigger:

Match End
Player Leave
Profile Update



PASRAHPHOBIA - MODULE INTERFACE SPECIFICATION

OVERVIEW

The Module Interface Specification defines the public APIs of each server system.

Each module exposes a limited set of functions that other systems are allowed to call.

Internal logic remains private to the module.

This approach prevents tight coupling between systems and ensures that the architecture remains scalable.

Each module has three types of functions:

Initialization
Runtime API
Event Handlers

Initialization functions run during server startup.

Runtime API functions are called by other systems.

Event Handlers respond to EventBus messages.

---

EVENT BUS INTERFACE

Module: EventBus

Public API

Publish(eventName, payload)

Subscribe(eventName, callback)

Unsubscribe(eventName, callback)

Purpose

Allows all systems to communicate without direct dependencies.

Example Events

PlayerJoinedLobby
MatchCreated
GhostHuntStarted
EvidenceCollected
MatchEnded

---

SERVICE REGISTRY INTERFACE

Module: ServiceRegistry

Public API

RegisterService(serviceName, serviceInstance)

GetService(serviceName)

HasService(serviceName)

Purpose

Allows systems to safely access each other.

Example

GhostSystem = ServiceRegistry:GetService("GhostSystem")

---

CONFIG LOADER INTERFACE

Module: ConfigLoader

Public API

LoadConfig(configName)

GetConfig(configName)

ReloadConfig(configName)

Purpose

Loads shared configuration data from shared/DataTypes.

Used by systems such as:

GhostSystem
EvidenceSystem
RankedSystem

---

DATA PERSISTENCE INTERFACE

Module: DataPersistence

Public API

LoadPlayerData(playerId)

SavePlayerData(playerId, data)

UpdatePlayerData(playerId, changes)

Purpose

Handles all Roblox DataStore interactions.

Other systems never access DataStore directly.

---

PROFILE SYSTEM INTERFACE

Module: ProfileSystem

Public API

GetPlayerProfile(player)

UpdateProfile(player, changes)

GetPlayerLevel(player)

AddExperience(player, amount)

Purpose

Manages player identity and progression.

Profile contains:

Level
Title
FlexBorder
Bio
GalleryItems

---

ECONOMY SYSTEM INTERFACE

Module: EconomySystem

Public API

GetBalance(player)

AddCurrency(player, amount)

SpendCurrency(player, amount)

CalculateMatchReward(matchData)

Purpose

Handles all in-game currency logic.

---

LOBBY SOCIAL HUB INTERFACE

Module: LobbySocialHub

Public API

RegisterPlayer(player)

RemovePlayer(player)

GetLobbyPlayers()

Purpose

Tracks players currently in the lobby.

---

PARTY SYSTEM INTERFACE

Module: PartySystem

Public API

CreateParty(player)

InvitePlayer(partyId, player)

LeaveParty(player)

GetPartyMembers(player)

Purpose

Handles multiplayer party groups.

Maximum party size: 4 players.

---

CONTRACT SYSTEM INTERFACE

Module: ContractSystem

Public API

GenerateContracts()

GetAvailableContracts()

SelectContract(partyId, contractId)

Purpose

Handles investigation contract selection.

Contracts define:

Map
Difficulty
Objectives
Reward multiplier

---

MATCH SYSTEM INTERFACE

Module: MatchSystem

Public API

CreateMatch(party)

StartMatch(matchId)

EndMatch(matchId)

GetMatch(matchId)

Purpose

Creates and manages investigation sessions.

---

MATCH QUEUE INTERFACE

Module: MatchQueue

Public API

JoinQueue(player)

LeaveQueue(player)

FindMatch()

Purpose

Handles matchmaking logic.

Supports:

Solo queue
Party queue
Ranked matchmaking

---

GAME PHASE SYSTEM INTERFACE

Module: GamePhaseSystem

Public API

StartPhase(matchId, phaseName)

GetCurrentPhase(matchId)

TransitionPhase(matchId, nextPhase)

Purpose

Controls the lifecycle of a match.

Phases include:

Preparation
Investigation
Hunt
Extraction
Results

---

GHOST SYSTEM INTERFACE

Module: GhostSystem

Public API

SpawnGhost(matchId)

StartHunt(matchId)

EndHunt(matchId)

GetGhostState(matchId)

Purpose

Controls ghost AI behavior.

Ghost states include:

Idle
Roaming
Interaction
Hunt

---

EVIDENCE SYSTEM INTERFACE

Module: EvidenceSystem

Public API

SpawnEvidence(matchId)

CollectEvidence(player, evidenceType)

GetCollectedEvidence(matchId)

Purpose

Tracks evidence discovered during investigation.

Evidence Types

BolaArwah
BukuTerkutuk
GerakanGaib
JejakEnergi
KotakArwah
SuhuMembeku

Tool visual base-slot lock (2026-04-18)

JejakEnergi = 121559455873224
KotakArwah = 80024667585179
SuhuMembeku = 106744635077484
BukuTerkutuk = 123135502718934
BolaArwah = 80883221689326
GerakanGaib = 109093713235033
Garam = 117103968659967
PilSanity = 135462688002407
Salib = 128686833722709
Dupa = 128740632500448
Flashlight = 127298509562779

Rarity/state/support uploads remain in the imported pool and are not promoted into the base runtime slots unless the rarity/content lane explicitly consumes them.
Base template syncback completed on 2026-04-18: `ReplicatedStorage.Assets.Models.Tools` now contains canonical base templates for all 11 current tool slots.

---

SANITY SYSTEM INTERFACE

Module: SanitySystem

Public API

GetSanity(player)

DrainSanity(player, amount)

RestoreSanity(player, amount)

GetAverageTeamSanity(matchId)

Purpose

Tracks player mental stability.

Sanity affects ghost aggression and hunt probability.

---

AGGRESSION SYSTEM INTERFACE

Module: AggressionSystem

Public API

IncreaseAggression(matchId, amount)

GetAggressionLevel(matchId)

CheckHuntTrigger(matchId)

Purpose

Controls ghost hostility and hunt conditions.

---

HORROR DIRECTOR INTERFACE

Module: HorrorDirector

Public API

EvaluateTension(matchId)

ScheduleEvent(matchId)

AdjustHuntProbability(matchId)

Purpose

Maintains pacing and tension.

Prevents hunts from occurring too frequently or too rarely.

---

MAP EVENT SYSTEM INTERFACE

Module: MapEventSystem

Public API

TriggerEvent(matchId, eventType)

GetActiveEvents(matchId)

EndEvent(matchId, eventType)

Purpose

Controls dynamic environmental events.

Example events

PowerFailure
Thunderstorm
HeavyFog

---

GHOST MODIFIER SYSTEM INTERFACE

Module: GhostModifierSystem

Public API

AssignModifiers(matchId)

GetActiveModifiers(matchId)

ApplyModifierEffects(matchId)

Purpose

Applies random modifiers to ghosts.

Modifiers alter ghost behavior and difficulty.

---

RANKED SYSTEM INTERFACE

Module: RankedSystem

Public API

GetPlayerRank(player)

AddStar(player)

RemoveStar(player)

CalculateRankDifficulty(party)

Purpose

Controls rank progression and difficulty scaling.

Rank tiers include:

Bayi
Balita
Anak-Anak
Remaja
Dewasa
Profesional
Detektive
Sang Ahli

---

SYSTEM OBJECTIVE

The Module Interface Specification ensures that every system communicates through stable and predictable APIs.

This prevents hidden dependencies and allows PASRAHPHOBIA to expand with new systems without breaking existing architecture.







MODULE COMMUNICATION MODEL
System A
   │
   ▼
ServiceRegistry
   │
   ▼
Target System API
   │
   ▼
EventBus (optional event)

Contoh nyata:

EvidenceSystem
   │
   ▼
EventBus.Publish("EvidenceCollected")

InvestigationSystem
   │
   ▼
EventBus.Subscribe("EvidenceCollected")



PASRAHPHOBIA — SERVER BOOTSTRAP ARCHITECTURE

SERVER BOOTSTRAP ARCHITECTURE

OVERVIEW

The Server Bootstrap System initializes all core server systems when a Roblox server instance starts.

Its purpose is to ensure that every system is started in the correct order and all dependencies are available.

Bootstrap acts as the entry point for the entire server runtime.

All server-side systems are registered and initialized through the ServiceRegistry.

This approach prevents circular dependencies and ensures consistent system startup.

---

BOOTSTRAP ENTRY POINT

The server bootstrap begins inside the ServerScriptService.

Bootstrap is responsible for:

Loading core services
Registering systems
Initializing systems
Starting runtime loops

After initialization completes, the server is ready to accept players.

---

BOOTSTRAP STARTUP ORDER

Systems must start in a specific order to ensure dependencies exist.

Startup order:

Core Systems
Infrastructure Systems
Gameplay Systems
Lobby Systems
Match Systems

---

CORE SYSTEMS

Core systems are responsible for the server foundation.

These systems must start first.

Core Systems:

EventBus
ConfigLoader
ServiceRegistry

Responsibilities:

Register systems
Allow inter-system communication
Load configuration data

Without these systems the server cannot function.

---

INFRASTRUCTURE SYSTEMS

Infrastructure systems support gameplay but do not directly control it.

Systems include:

DataPersistence
EconomySystem
ProfileSystem

Responsibilities:

Player progression
Currency storage
Rank storage
Inventory storage

These systems must start before gameplay begins.

---

GAMEPLAY SYSTEMS

Gameplay systems control the core investigation mechanics.

Systems include:

GhostSystem
EvidenceSystem
SanitySystem
AggressionSystem
InvestigationSystem
GhostModifierSystem
MapInteractionSystem
MapEventSystem
HorrorDirector

Responsibilities:

Ghost AI
Evidence spawning
Sanity drain
Environmental horror events

These systems activate when matches begin.

---

LOBBY SYSTEMS

Lobby systems control the Social Hub.

Systems include:

LobbySocialHub
PartySystem
ContractSystem
LeaderboardSystem

Responsibilities:

Lobby interaction
Party formation
Contract selection
Social features

Lobby systems remain active while players are not in matches.

---

MATCH SYSTEMS

Match systems control match creation and lifecycle.

Systems include:

MatchQueue
MatchBuilder
MatchInstance
MatchLifecycle
TeleportService
GamePhaseSystem

Responsibilities:

Create match instances
Assign players to matches
Teleport players to maps
Control phase transitions

---

BOOTSTRAP INITIALIZATION FLOW

Server starts
Bootstrap initializes Core Systems
Infrastructure Systems load
Gameplay Systems register
Lobby Systems activate
Match Systems activate
Server ready for players

At this point the server begins accepting players.

---

SYSTEM REGISTRATION

Each system registers itself in the ServiceRegistry.

Example registration process:

Register system
Declare dependencies
Initialize system
Start runtime loop

This ensures that all systems can safely access each other.

---

EVENT BUS COMMUNICATION

Systems communicate using EventBus rather than direct function calls.

Example events:

PlayerJoinedLobby
MatchCreated
EvidenceDiscovered
GhostHuntStarted
PlayerSanityChanged
MatchEnded

This decouples systems and improves scalability.

---

SERVER OBJECTIVE

The Server Bootstrap Architecture guarantees that:

All systems start in a predictable order
Dependencies are resolved safely
The server remains stable and scalable

This structure allows PASRAHPHOBIA to grow with new systems without rewriting core architecture.







SERVER STARTUP FLOW
Server Start
     │
     ▼
Bootstrap
     │
     ▼
Core Systems
(EventBus, ConfigLoader, ServiceRegistry)
     │
     ▼
Infrastructure Systems
(DataPersistence, Economy, Profile)
     │
     ▼
Gameplay Systems
(Ghost, Evidence, Sanity, Aggression)
     │
     ▼
Lobby Systems
(LobbySocialHub, Party, Contracts)
     │
     ▼
Match Systems
(MatchQueue, MatchLifecycle, TeleportService)
     │
     ▼
Server Ready
BOOTSTRAP DEPENDENCY GRAPH
Bootstrap
   │
   ▼
ServiceRegistry
   │
   ▼
EventBus
   │
   ▼
ConfigLoader
   │
   ▼
DataPersistence
   │
   ▼
Economy + Profile
   │
   ▼
Gameplay Systems
   │
   ▼
Lobby Systems
   │
   ▼
Match Systems
HUBUNGAN DENGAN STRUKTUR FOLDER PROJECT

Bootstrap berada di folder yang sudah ada di project kamu:

src/ServerScriptService/Server/Core

yang sekarang berisi:

Bootstrap
ServiceRegistry

Bootstrap akan menyalakan seluruh system dari folder:

src/ServerScriptService/Server/*




PASRAHPHOBIA — SERVER SERVICE STARTUP ORDER
1. PURPOSE

Server Service Startup Order menentukan urutan inisialisasi semua system server saat server Roblox pertama kali berjalan.

Tanpa startup order yang benar dapat terjadi:

dependency error

nil reference

service tidak terdaftar

system berjalan sebelum data siap

Tujuan dokumen ini:

memastikan semua service start secara stabil
memastikan dependency terpenuhi
memastikan EventBus aktif sebelum system lain
2. CORE SERVER BOOT FLOW

Urutan boot server PASRAHPHOBIA:

Bootstrap
↓
ServiceRegistry
↓
EventBus
↓
ConfigLoader
↓
DataPersistence
↓
ProfileSystem
↓
EconomySystem
↓
RankedSystem
↓
ContractSystem
↓
MatchSystem
↓
MapInteractionSystem
↓
MapEventSystem
↓
GhostModifierSystem
↓
AggressionSystem
↓
SanitySystem
↓
GhostSystem
↓
EvidenceSystem
↓
InvestigationSystem
↓
HorrorDirector
↓
LobbySocialHub
3. CORE BOOTSTRAP SYSTEMS
Bootstrap

Bootstrap adalah entry point server.

Tugas:

load ServiceRegistry
initialize EventBus
register services
start service lifecycle
ServiceRegistry

ServiceRegistry bertanggung jawab untuk:

register semua system
resolve dependency
menyediakan akses antar service

Example:

ServiceRegistry:Register("MatchSystem")
ServiceRegistry:Register("GhostSystem")
ServiceRegistry:Register("EconomySystem")
EventBus

EventBus adalah central communication layer.

Digunakan untuk komunikasi antar system.

Example:

EventBus:Emit("PlayerJoined")
EventBus:Emit("GhostSpawned")
EventBus:Emit("EvidenceFound")
4. DATA SYSTEM INITIALIZATION

Data system harus start lebih awal.

Urutan:

ConfigLoader
↓
DataPersistence
↓
ProfileSystem

Tujuan:

player data siap sebelum gameplay

economy system bisa membaca inventory

DataPersistence

Modules:

PlayerData
EconomyData
InventoryData
RankData

DataPersistence harus siap sebelum:

ProfileSystem
EconomySystem
RankedSystem
5. PLAYER PROGRESSION SYSTEM

Setelah data aktif:

ProfileSystem
↓
EconomySystem
↓
RankedSystem
↓
ContractSystem

Tujuan:

load player level

load currency

load rank tier

load contract mission

6. MATCH MANAGEMENT SYSTEM

Setelah progression system siap:

MatchSystem

Modules:

MatchQueue
MatchBuilder
MatchInstance
MatchLifecycle
TeleportService

MatchSystem bertanggung jawab untuk:

match creation
match state management
player teleport
match reward trigger
7. WORLD INTERACTION SYSTEM

Map system diaktifkan setelah match system.

MapInteractionSystem
↓
MapEventSystem

Contoh event:

lamp flicker
door slam
object movement
environment noise
8. GHOST MECHANIC SYSTEMS

Ghost gameplay membutuhkan beberapa system.

Urutan:

GhostModifierSystem
↓
AggressionSystem
↓
SanitySystem
↓
GhostSystem
GhostModifierSystem

Menentukan modifier ghost.

Contoh:

fast ghost
shy ghost
aggressive ghost
AggressionSystem

Mengontrol kemarahan ghost.

Dipengaruhi oleh:

player sanity
player noise
time in investigation
SanitySystem

Mengontrol sanity player.

Trigger sanity drop:

ghost apparition
darkness
paranormal events
GhostSystem

GhostSystem hanya boleh aktif setelah:

AggressionSystem
SanitySystem
MapInteractionSystem

GhostSystem bertanggung jawab untuk:

ghost spawn
ghost movement
ghost hunt
ghost manifestation
9. INVESTIGATION SYSTEM

Setelah ghost aktif:

EvidenceSystem
↓
InvestigationSystem
EvidenceSystem

Modules:

EvidenceEngine
EvidenceSpawner
EvidenceValidator
EvidenceSync

Evidence tools:

Kotak Arwah
Buku Terkutuk
Bola Arwah
Gerakan Gaib
Jejak Energi
Suhu Membeku


InvestigationSystem

Modules:

EvidenceTracker
GhostGuess
InvestigationState

Tugas:

track evidence
determine ghost type
trigger match result
10. HORROR DIRECTOR

HorrorDirector adalah dynamic horror controller.

Dependency:

GhostSystem
AggressionSystem
MapEventSystem

Modules:

DirectorRules
EventScheduler
PlayerStateMonitor
TensionSystem

Tugas:

create tension
schedule paranormal events
control horror pacing
11. LOBBY SYSTEM

Lobby hanya aktif saat player berada di lobby server.

System:

LobbySocialHub

Modules:

PartySystem
PlayerPresence
LobbyInteraction

Zones:

Flex Plaza
Team Finder
Shop
Training Room
Hall of Fame
12. SERVICE STARTUP VALIDATION

Setelah semua system start, server melakukan validation.

Checklist:

all services registered
dependencies resolved
EventBus active
no nil reference

Jika validation gagal:

server restart
error log generated
13. FINAL SERVER START FLOW

Final startup flow PASRAHPHOBIA:

Bootstrap
 ↓
ServiceRegistry
 ↓
EventBus
 ↓
ConfigLoader
 ↓
DataPersistence
 ↓
ProfileSystem
 ↓
EconomySystem
 ↓
RankedSystem
 ↓
ContractSystem
 ↓
MatchSystem
 ↓
MapInteractionSystem
 ↓
MapEventSystem
 ↓
GhostModifierSystem
 ↓
AggressionSystem
 ↓
SanitySystem
 ↓
GhostSystem
 ↓
EvidenceSystem
 ↓
InvestigationSystem
 ↓
HorrorDirector
 ↓
LobbySocialHub

Server siap menerima player.



PASRAHPHOBIA — SERVICE DEPENDENCY MATRIX

SERVICE DEPENDENCY MATRIX

OVERVIEW

The Service Dependency Matrix defines the relationships between all major server systems.

Its purpose is to ensure that each system starts only after its required dependencies are available.

This prevents circular dependencies and unstable server initialization.

Each system belongs to a startup tier.

Startup tiers represent the order in which services must initialize.

TIER 1 — CORE SERVICES

Core services provide infrastructure for all other systems.

Systems:

EventBus
ConfigLoader
ServiceRegistry

Dependencies:

None

Responsibilities:

System communication
Configuration loading
Service registration

These services must start before any other system.

TIER 2 — DATA AND PERSISTENCE

These services manage player data and progression.

Systems:

DataPersistence
PlayerData
EconomyData
InventoryData
RankData

Dependencies:

EventBus
ConfigLoader

Responsibilities:

Saving player data
Loading player progression
Storing match results
Tracking player rank

These systems must start before gameplay systems.

TIER 3 — PROFILE AND ECONOMY

These services manage player identity and rewards.

Systems:

ProfileSystem
EconomySystem

Dependencies:

DataPersistence
PlayerData
EconomyData
InventoryData
RankData

Responsibilities:

Player level progression
Currency management
Inventory updates
Rank progression updates

TIER 4 — MATCHMAKING AND LOBBY

These services manage lobby interactions and player grouping.

Systems:

LobbySocialHub
PartySystem
ContractSystem
LeaderboardSystem

Dependencies:

ProfileSystem
EconomySystem
EventBus

Responsibilities:

Lobby interactions
Party formation
Contract selection
Leaderboard display

TIER 5 — MATCH MANAGEMENT

These services control match creation and lifecycle.

Systems:

MatchQueue
MatchBuilder
MatchInstance
MatchLifecycle
TeleportService
GamePhaseSystem

Dependencies:

LobbySocialHub
PartySystem
ContractSystem
ProfileSystem

Responsibilities:

Matchmaking
Match initialization
Map teleportation
Phase transitions

TIER 6 — GAMEPLAY SYSTEMS

These services control the investigation gameplay.

Systems:

GhostSystem
EvidenceSystem
SanitySystem
AggressionSystem
InvestigationSystem

Dependencies:

MatchLifecycle
GamePhaseSystem
ConfigLoader

Responsibilities:

Ghost AI
Evidence generation
Sanity drain
Ghost aggression
Investigation logic

TIER 7 — ADVANCED GAMEPLAY SYSTEMS

These systems enhance the investigation experience.

Systems:

HorrorDirector
GhostModifierSystem
MapInteractionSystem
MapEventSystem

Dependencies:

GhostSystem
EvidenceSystem
AggressionSystem
SanitySystem

Responsibilities:

Horror pacing
Ghost modifiers
Environmental interactions
Dynamic map events

EVENT BUS INTEGRATION

All systems communicate using the EventBus.

Example events include:

PlayerJoinedLobby
ContractSelected
MatchCreated
GhostHuntStarted
EvidenceCollected
MatchEnded

Systems subscribe to events rather than calling each other directly.

This reduces system coupling.

DEPENDENCY OBJECTIVE

The dependency matrix guarantees that:

Systems initialize in the correct order
Dependencies are always available
Server startup remains stable
Future systems can be added safely

This structure allows PASRAHPHOBIA to scale without architecture refactoring.

SERVICE STARTUP ORDER
Tier 1
Core Systems
(EventBus, ConfigLoader, ServiceRegistry)

Tier 2
Data Persistence
(DataPersistence, PlayerData, EconomyData)

Tier 3
Profile & Economy
(ProfileSystem, EconomySystem)

Tier 4
Lobby Systems
(LobbySocialHub, PartySystem, ContractSystem)

Tier 5
Match Systems
(MatchQueue, MatchLifecycle, TeleportService)

Tier 6
Gameplay Systems
(GhostSystem, EvidenceSystem, SanitySystem)

Tier 7
Advanced Gameplay
(HorrorDirector, MapEventSystem, GhostModifierSystem)









DEPENDENCY GRAPH
EventBus
   │
   ▼
DataPersistence
   │
   ▼
ProfileSystem
   │
   ▼
LobbySystems
   │
   ▼
MatchSystems
   │
   ▼
GameplaySystems
   │
   ▼
AdvancedGameplaySystems
HUBUNGAN DENGAN STRUKTUR PROJECT KAMU

Matrix ini langsung cocok dengan struktur folder kamu:

src/ServerScriptService/Server
├── Core
├── DataPersistence
├── ProfileSystem
├── EconomySystem
├── LobbySocialHub
├── MatchSystem
├── GhostSystem
├── EvidenceSystem
├── SanitySystem
├── AggressionSystem
├── HorrorDirector
├── MapEventSystem
└── GhostModifierSystem




PASRAHPHOBIA – TECHNICAL SYSTEM BLUEPRINT

SYSTEM ARCHITECTURE

The game uses a server-authoritative architecture.

Client handles:

UI
Audio
Visual effects
Tool interaction input

Server handles:

Ghost AI
Evidence validation
Match state
Player sanity
Ranked progression
Economy rewards

Shared modules contain configuration and data types used by both client and server.

---

SERVER BOOTSTRAP SYSTEM

Server startup sequence:

1 Load configuration
2 Initialize EventBus
3 Register services
4 Load systems
5 Start systems in dependency order

Bootstrap loads systems in layers:

Core
Data
Player Systems
Gameplay Systems
Match Systems
Lobby Systems

---

SERVICE REGISTRY

ServiceRegistry acts as a global access container for server systems.

Example services:

GhostSystem
EvidenceSystem
MatchSystem
SanitySystem
RankedSystem

Each system registers itself on startup.

Other systems retrieve services from the registry instead of requiring modules directly.

This prevents circular dependencies.

---

EVENT BUS

EventBus provides asynchronous communication between systems.

Example events:

GhostSpawned
EvidenceDetected
PlayerSanityChanged
MatchStarted
MatchEnded

This reduces tight coupling between modules.

---

DATA PERSISTENCE

Player data is stored using Roblox DataStore.

Data categories:

PlayerData
EconomyData
InventoryData
RankData

PlayerData includes:

Level
Experience
TotalGames
WinrateVisibility

EconomyData includes:

Currency
CosmeticsOwned

RankData includes:

RankTier
Stars
SeasonProgress

---

PLAYER LEVEL SYSTEM

Level Range:

1 – 100

Experience gained from:

Match completion
Evidence discovery
Difficulty multiplier

Example formula:

BaseXP = 100

XP = BaseXP + (EvidenceCount × 25) + DifficultyBonus

Level up when accumulated XP reaches threshold.

---

SANITY SYSTEM

Each player has a sanity value.

Range:

0 – 100

Sanity decreases from:

Time spent in darkness
Ghost proximity
Paranormal events
Ghost hunts

Example drain formula:

SanityDrainRate = BaseDrain + FearModifier + EventModifier

Low sanity increases ghost aggression probability.

---

GHOST AI SYSTEM

Ghost behavior is controlled by state machines.

Ghost states:

Idle
Roaming
Interaction
Hunt

State transitions depend on:

Player proximity
Aggression level
Sanity averages

Example transition:

If AveragePlayerSanity < 40
Increase hunt probability.

---

GHOST AGGRESSION SYSTEM

Aggression level determines how hostile the ghost is.

Range:

0 – 100

Aggression increases when:

Players interact with ghost objects
Players remain near ghost room
Players have low sanity

Example formula:

Aggression += PlayerProximity × AggressionMultiplier

When aggression exceeds threshold, hunt may start.

---

HUNT SYSTEM

Hunts occur when ghost aggression passes a threshold.

Example:

If Aggression > 70
HuntChance = 30%

During hunt:

Ghost targets nearest player.

Players must hide or escape.

Hunt duration increases with difficulty.

---

EVIDENCE SYSTEM

Evidence detection depends on:

Ghost type
Room location
Modifier effects
Difficulty

Evidence validation occurs on server.

Example detection process:

Tool interaction triggered
Server checks room state
Server validates ghost evidence map
Evidence returned to client

---

INVESTIGATION SYSTEM

Players record evidence in the journal.

The system compares discovered evidence against ghost evidence tables.

Example:

GhostType = intersection(EvidenceSet)

If one ghost matches remaining evidence combination,
journal suggests that ghost.

---

GHOST MODIFIER SYSTEM

Ghost modifiers alter ghost behavior.

Examples:

Rage → aggression increases faster
Dormant → aggression increases slower
BlinkStep → ghost teleports during hunt
SanityLeech → sanity drains faster near ghost

Each match randomly assigns modifiers.

---

MAP EVENT SYSTEM

Each match may contain a map event.

Events modify environmental conditions.

Examples:

Thunderstorm
PowerFailure
HeavyFog

Event modifiers affect:

Audio
Lighting
Sanity drain
Ghost activity

---

HORROR DIRECTOR

The Horror Director dynamically controls tension.

It monitors:

Player sanity
Time since last event
Player grouping

It triggers events such as:

Door slams
Object movement
Ghost whispers
Visual hallucinations

This prevents long periods without activity.

---

MATCH SYSTEM

MatchSystem controls match lifecycle.

Phases:

Lobby
Preparation
Investigation
Hunt
Extraction
Results

Players are teleported to maps when match starts.

TeleportService is used for map instances.

---

CONTRACT SYSTEM

Contracts generate missions.

Contracts define:

Map
Difficulty
Objectives
Rewards

Example objective:

Capture ghost photo
Detect ghost movement
Survive hunt

Rewards increase with difficulty and objectives completed.

---

RANKED SYSTEM

Ranked uses star progression.

Win → +1 Star
Loss → −1 Star

Promotion occurs when stars reach threshold.

Example:

Bayi 3 → 3 stars → Bayi 2

Final rank:

Sang Ahli

Uses continuous score instead of divisions.

Example:

Sang Ahli x1
Sang Ahli x2

Loss at Sang Ahli x1 drops player to Detektive.

---

MATCHMAKING

Matchmaking groups players with similar skill levels.

Factors used:

Player Level
Rank Tier
Party size

Difficulty scaling adjusts ghost behavior accordingly.

---

ECONOMY SYSTEM

Players receive rewards from matches.

Rewards depend on:

Difficulty
Evidence discovered
Correct ghost identification
Bonus objectives

Currency used for cosmetics and profile items.

---

FINAL SYSTEM OBJECTIVE

The architecture focuses on:

Replayability
Dynamic horror
Scalable multiplayer systems
Modular server architecture

The system design allows easy addition of:

New ghost types
New maps
New events
New investigation tools




PASRAHPHOBIA — DIFFICULTY SCALING BLUEPRINT


DIFFICULTY SCALING BLUEPRINT

OVERVIEW

The Difficulty Scaling System controls how challenging an investigation becomes.

Difficulty levels influence multiple gameplay systems including ghost aggression, sanity drain, hunt probability, evidence clarity, and event frequency.

The system ensures that higher difficulty investigations provide greater challenge and reward.

Difficulty values range from:

1 to 10

Difficulty may be selected directly in Classic mode or calculated dynamically in Ranked mode.

DIFFICULTY SOURCES

Classic Mode

Players select investigation difficulty manually.

Example presets:

Beginner
Standard
Nightmare

Each preset maps to difficulty values between 1 and 10.

Ranked Mode

Difficulty is calculated automatically using player level and rank tier.

Example formula:

DifficultyScore =
(LevelWeight + RankWeight)

The final score is clamped between 1 and 10.

DIFFICULTY EFFECTS

Difficulty modifies multiple systems.

Affected systems include:

Ghost aggression growth
Sanity drain rate
Hunt probability
Ghost movement speed
Evidence spawn rate
Environmental event frequency

Higher difficulty results in more dangerous investigations.

GHOST AGGRESSION SCALING

Ghost aggression grows faster on higher difficulties.

Example multiplier:

Difficulty 1 → AggressionMultiplier 0.7
Difficulty 5 → AggressionMultiplier 1.0
Difficulty 10 → AggressionMultiplier 1.6

Aggression calculation example:

AggressionIncrease =
BaseAggression × AggressionMultiplier

SANITY DRAIN SCALING

Sanity drains faster on higher difficulty.

Example values:

Difficulty 1 → 0.5 sanity per second
Difficulty 5 → 1.0 sanity per second
Difficulty 10 → 1.8 sanity per second

Additional modifiers:

Darkness
Ghost proximity
Paranormal events

Total drain formula:

SanityDrain =
BaseDrain × DifficultyMultiplier + EventModifiers

HUNT PROBABILITY SCALING

Higher difficulty increases hunt probability.

Example values:

Difficulty 2 → 10% base hunt chance
Difficulty 5 → 20% base hunt chance
Difficulty 8 → 35% base hunt chance
Difficulty 10 → 50% base hunt chance

Final hunt probability also depends on:

Aggression level
Average player sanity
Ghost modifiers

Example:

FinalHuntChance =
BaseChance + AggressionBonus + ModifierBonus

GHOST SPEED SCALING

Ghost movement speed during hunts increases with difficulty.

Example:

Difficulty 1 → Slow movement
Difficulty 5 → Normal movement
Difficulty 10 → Very fast movement

Speed multiplier example:

Difficulty 1 → 0.8x
Difficulty 5 → 1.0x
Difficulty 10 → 1.4x

EVIDENCE CLARITY SCALING

Higher difficulty reduces evidence frequency.

Example:

Difficulty 1 → Evidence appears frequently
Difficulty 5 → Evidence appears normally
Difficulty 10 → Evidence appears rarely

Evidence spawn probability decreases as difficulty increases.

Example:

EvidenceSpawnRate =
BaseSpawnRate / DifficultyModifier

EVENT FREQUENCY SCALING

Environmental events become more frequent at higher difficulties.

Example:

Difficulty 2 → Rare paranormal events
Difficulty 5 → Moderate activity
Difficulty 9 → Frequent disturbances

Events include:

Door slams
Object movement
Ghost manifestations
Audio disturbances

HUNT COOLDOWN SCALING

Cooldown between hunts decreases with difficulty.

Example:

Difficulty 2 → 40 seconds cooldown
Difficulty 5 → 30 seconds cooldown
Difficulty 10 → 20 seconds cooldown

This results in more frequent hunts at higher levels.

REWARD MULTIPLIER

Higher difficulty provides increased rewards.

Example multipliers:

Difficulty 1 → 1.0x reward
Difficulty 5 → 1.5x reward
Difficulty 10 → 2.5x reward

Rewards affected include:

Currency
Experience
Rank progression

DIFFICULTY TABLE EXAMPLE

Difficulty | Aggression | Sanity Drain | Hunt Chance | Evidence Rate | Reward

1 | Low | Very Slow | Very Low | High | 1.0x
3 | Low | Slow | Low | High | 1.2x
5 | Normal | Normal | Medium | Normal | 1.5x
7 | High | Fast | High | Low | 2.0x
10 | Extreme | Very Fast | Very High | Very Low | 2.5x

SYSTEM OBJECTIVE

The Difficulty Scaling System ensures that investigations remain balanced.

Low difficulty supports new players.

High difficulty challenges experienced players.

The system encourages progression and rewards skillful investigation.

Difficulty Scaling Integration

Difficulty mempengaruhi sistem berikut:

GhostSystem
SanitySystem
AggressionSystem
EvidenceSystem
HuntSystem
MapEventSystem
EconomySystem
RankedSystem
Difficulty Flow (Ranked Mode)
Player Rank
      │
      ▼
RankDifficulty Table
      │
      ▼
Difficulty Value (1–10)
      │
      ▼
Apply System Multipliers
Folder yang Mengontrol Sistem Ini

Sudah sesuai dengan struktur project kamu:

src/shared/DataTypes/Rank/RankDifficulty

dan dipakai oleh:

RankedSystem
MatchSystem
GhostSystem
SanitySystem



PASRAHPHOBIA — GAMEPLAY RULEBOOK
1. CORE GAMEPLAY LOOP

Core loop pemain:

Join Game
↓
Spawn Lobby Social Hub
↓
Find Team / Party
↓
Matchmaking
↓
Teleport to Map
↓
Preparation Phase
↓
Investigation Phase
↓
Ghost Hunt Events
↓
Identify Ghost
↓
Extraction
↓
Reward Calculation
↓
Return to Lobby
2. PLAYER OBJECTIVES

Tujuan utama pemain:

Menemukan ghost room

Mengumpulkan evidence

Mengidentifikasi ghost type

Bertahan hidup dari hunt

Keluar dari map

3. PLAYER STATES

Player dapat berada dalam state berikut:

ALIVE
DEAD
SPECTATOR
EXTRACTED
ALIVE

Player aktif bermain.

Kemampuan:

menggunakan evidence tools

membuka pintu

berinteraksi dengan map

berkomunikasi voice chat

DEAD

Ketika player mati:

UI notice muncul:

"Kematian menipumu,
yang kamu lihat belum tentu benar"

Durasi: 5 detik di tengah layar
Kemudian berpindah ke kiri dan tetap tampil kecil sampai endgame.

SPECTATOR

Player mati menjadi spectator.

Kemampuan:

spectate player hidup

voice chat dengan team

melihat distorsi ghost

Spectator tidak bisa memberi hint pasti.

4. GHOST BEHAVIOR STATES

Ghost memiliki beberapa state AI.

Idle
Roaming
Interaction
Manifestation
Hunt
Cooldown
IDLE

Ghost berada di ghost room.

Aktivitas:

suara kecil

suhu turun

interaksi ringan

ROAMING

Ghost berpindah antar ruangan.

Dipicu oleh:

aggression tinggi

player memicu event

INTERACTION

Ghost berinteraksi dengan lingkungan:

pintu bergerak

lampu mati

objek jatuh

MANIFESTATION

Ghost muncul sesaat.

Efek:

visual apparition

sanity drop

HUNT

Ghost mencoba membunuh player.

Ciri:

lampu mati

pintu terkunci

ghost mengejar player

COOLDOWN

Ghost berhenti sementara setelah hunt.

Durasi:

20–40 detik

5. EVIDENCE SYSTEM

PASRAHPHOBIA menggunakan evidence lokal Indonesia.

Evidence tools:

Kotak Arwah
Buku Terkutuk
Bola Arwah
Gerakan Gaib
Jejak Energi
Suhu Membeku
Evidence Requirement

Difficulty menentukan jumlah evidence.

Beginner = 4 evidence
Standard = 3 evidence
Nightmare = 2 evidence
Evidence Detection

Evidence muncul jika:

player menggunakan tool benar

berada di ghost room

ghost aktif

6. SANITY SYSTEM

Player memiliki sanity meter.

100% → stabil
70% → normal
50% → mulai bahaya
30% → hunt probability naik
10% → sangat berbahaya
Sanity Drop Trigger

Sanity turun jika:

melihat ghost

lampu mati

event paranormal

7. AGGRESSION SYSTEM

Ghost memiliki aggression meter.

Low
Medium
High
Extreme

Dipengaruhi oleh:

sanity player

noise player

waktu investigasi

8. HUNT TRIGGER RULES

Hunt dapat dipicu oleh:

Low sanity
Ghost anger
Provocation
Time escalation

Probability meningkat setiap:

3–5 menit investigasi
9. MATCH WIN CONDITIONS

Team menang jika:

Correct Ghost Identified
AND
Minimal 1 Player Extracted
10. MATCH LOSE CONDITIONS

Team kalah jika:

All players dead
OR
Wrong ghost guess





02_GAMEPLAY
   - Gameplay Rulebook
   - Investigation System
   - Difficulty Scaling
   
	GAME STATE MACHINE

OVERVIEW

The Game State Machine controls the global gameplay state for each match instance.

It ensures that gameplay systems activate only during appropriate phases and prevents invalid transitions.

Each match instance has its own state machine managed by the MatchLifecycle system.

---

PRIMARY STATES

The game uses the following match states.

Waiting

Players are still joining the match.

Starting

Match is preparing to begin.

Preparation

Players spawn inside the map and prepare equipment.

Investigation

Players search for ghost evidence.

Hunt

Ghost becomes aggressive and hunts players.

Extraction

Players attempt to leave the investigation area.

Results

Rewards are calculated and displayed.

Completed

Match ends and players return to lobby.

---

STATE RESPONSIBILITIES

Waiting

MatchQueue is assembling players.

No ghost activity occurs.

---

Starting

Map server loads.

Ghost instance is created.

Players teleport into the map.

---

Preparation

Players spawn.

Equipment setup occurs.

Ghost remains passive.

Duration is short.

---

Investigation

Main gameplay phase.

Players search for evidence.

Ghost roams and interacts with environment.

Sanity system begins draining.

FearEngine activates.

EvidenceSystem operates normally.

---

Hunt

Triggered by AggressionSystem.

Ghost attempts to kill players.

Doors may lock.

Lights flicker.

Players must hide or escape.

---

Extraction

Triggered when investigation ends or objective complete.

Players return to exit point.

Ghost aggression may remain high.

---

Results

Match ends.

Ghost identity revealed.

Rewards calculated.

Player statistics updated.

---

Completed

MatchInstance shuts down.

Players teleport back to LobbySocialHub.

Match server cleans up.

---

STATE TRANSITION RULES

Transitions must follow valid order.

Waiting

↓

Starting

↓

Preparation

↓

Investigation

↓

Hunt

↓

Extraction

↓

Results

↓

Completed

Invalid transitions are blocked by the state machine.

---

HUNT STATE TRIGGERS

Hunt phase can be triggered by multiple conditions.

Low player sanity.

Ghost aggression threshold reached.

Specific ghost abilities.

HorrorDirector scripted events.

---

STATE TIME CONTROL

Each state may have timers.

Preparation

Short timer before investigation begins.

Investigation

Primary gameplay timer.

Hunt

Short high-danger window.

Extraction

Limited time to escape.

Results

Short reward display duration.

---

SYSTEM ACTIVATION BY STATE

Waiting

Lobby systems active.

Gameplay systems inactive.

---

Preparation

Player systems active.

Ghost passive.

Evidence inactive.

---

Investigation

GhostSystem active.

EvidenceSystem active.

SanitySystem active.

HorrorDirector active.

---

Hunt

Ghost aggression maximum.

Door control active.

Fear effects intensified.

---

Extraction

Players attempt escape.

Ghost may remain aggressive.

---

Results

Reward systems active.

EconomySystem active.

RankedSystem active.

---

Completed

Match instance terminates.

Cleanup occurs.

---

ERROR PROTECTION

The state machine prevents incorrect behavior.

Example protections

Ghost cannot hunt before investigation phase.

Rewards cannot trigger before results phase.

Players cannot rejoin after match completion.

---

STATE MACHINE CONTROL

MatchLifecycle is responsible for state control.

MatchLifecycle

StartMatch

ChangeState

EndMatch

ForceState

State transitions are logged for debugging.

---

FINAL PURPOSE

The Game State Machine ensures stable gameplay flow and synchronizes all gameplay systems during a match.






GAME STATE FLOW
Waiting
   │
   ▼
Starting
   │
   ▼
Preparation
   │
   ▼
Investigation
   │
   ▼
Hunt
   │
   ▼
Extraction
   │
   ▼
Results
   │
   ▼
Completed
SYSTEM ACTIVATION MAP
STATE           ACTIVE SYSTEMS

Waiting         LobbySystem
Starting        MatchSystem
Preparation     PlayerSystems
Investigation   GhostSystem
                EvidenceSystem
                SanitySystem
                HorrorDirector

Hunt            AggressionSystem
                GhostSystem
                FearEngine

Extraction      PlayerSystems

Results         EconomySystem
                RankedSystem

Completed       DataPersistence
Folder Integration

Ini sudah cocok dengan folder project kamu:

src/ServerScriptService/Server/GamePhaseSystem

Module utama:

GameStateMachine
MatchLifecycle
PhaseControllers



PASRAHPHOBIA - IMPLEMENTATION ORDER


PHASE 1 — Core Infrastructure

Ini harus dibuat pertama karena semua system bergantung ke sini.

EventBus
Utilities
ConfigLoader
ServiceRegistry
Bootstrap

Lokasi:

src/shared
src/ServerScriptService/Server/Core

Tujuan:

System communication
System registration
Server startup control
PHASE 2 — Data Layer

Semua data player harus siap sebelum gameplay.

DataPersistence
PlayerData
EconomyData
InventoryData
RankData

Lokasi:

src/ServerScriptService/Server/DataPersistence

Digunakan oleh:

ProfileSystem
EconomySystem
RankedSystem
PHASE 3 — Player Systems

Setelah data layer selesai.

ProfileSystem
PlayerLevel
PlayerProfile
ProfileInspect

Lokasi:

src/ServerScriptService/Server/ProfileSystem

Dependency:

ProfileSystem → DataPersistence
PHASE 4 — Core Gameplay Systems

Ini adalah mekanik gameplay utama.

Urutan implementasi:

SanitySystem
AggressionSystem
GhostSystem
EvidenceSystem
InvestigationSystem

Dependency flow:

SanitySystem
   ↓
AggressionSystem
   ↓
GhostSystem
   ↓
EvidenceSystem
   ↓
InvestigationSystem
PHASE 5 — Dynamic Gameplay Systems

Setelah gameplay dasar selesai.

GhostModifierSystem
MapEventSystem
HorrorDirector
FearEngine
MapInteractionSystem

Tujuan:

Replayability
Dynamic horror behavior
Environmental events
PHASE 6 — Match Systems

Sistem yang mengontrol jalannya permainan.

Urutan:

GamePhaseSystem
ContractSystem
MatchSystem
TeleportService

Flow:

Lobby
↓
Contract Board
↓
MatchQueue
↓
MatchInstance
↓
Teleport to Map
PHASE 7 — Lobby Systems

Terakhir karena semua sistem sudah tersedia.

LobbySocialHub
PartySystem
PlayerPresence
Lobby Interaction
Zones
Final Implementation Flow

Secara keseluruhan:

Core Infrastructure
↓
Data Layer
↓
Player Systems
↓
Core Gameplay
↓
Dynamic Gameplay
↓
Match Systems
↓
Lobby Systems
Estimasi Kompleksitas Sistem

Untuk PASRAHPHOBIA:

System	Complexity
Core Infrastructure	Medium
Data Persistence	Medium
Profile System	Medium
Ghost System	High
Evidence System	High
Investigation System	High
Match System	High
Lobby System	Medium
Dynamic Systems	High



PASRAHPHOBIA - MATCH LIFECYCLE BLUEPRINT


MATCH LIFECYCLE BLUEPRINT

OVERVIEW

The Match Lifecycle System defines the complete flow of a game session from lobby to results.

It coordinates all gameplay systems and ensures that each phase of the investigation runs in the correct order.

The MatchSystem is responsible for creating matches and managing player groups.

The GamePhaseSystem controls phase transitions during the investigation.

---

MATCH FLOW

The lifecycle of a match follows the sequence below.

Lobby Phase
Contract Selection
Match Queue
Match Creation
Teleport Players
Preparation Phase
Investigation Phase
Hunt Events
Extraction Phase
Results Phase
Return to Lobby

---

LOBBY PHASE

Players spawn in the Lobby Social Hub.

Players may:

Form a party
Inspect player profiles
Purchase items
Visit training areas
Select investigation contracts

The lobby remains active until players join a match queue.

---

CONTRACT SELECTION

Players interact with the Contract Board.

A contract defines:

Map
Difficulty
Objectives
Reward multiplier

Once a contract is selected, players may join the matchmaking queue.

---

MATCH QUEUE

Players enter the matchmaking queue.

Queue conditions:

Solo players
Party groups
Ranked matchmaking rules

MatchQueueSystem searches for compatible players.

Matching factors:

Player level
Rank tier
Party size

---

MATCH CREATION

Once a group is formed, the server creates a MatchInstance.

The MatchInstance stores:

Players
Map
Ghost type
Difficulty
Modifiers
Map events

Match data remains stored for the duration of the session.

---

TELEPORT PLAYERS

Players are teleported to the investigation map using TeleportService.

Before teleport:

Match data is initialized.

Systems initialized:

GhostSystem
EvidenceSystem
MapEventSystem
GhostModifierSystem

---

PREPARATION PHASE

Players spawn at the map entry location.

Duration:

Approximately 30–60 seconds.

Players can:

Prepare equipment
Review contract objectives
Plan investigation strategy

Ghost activity remains minimal during preparation.

---

INVESTIGATION PHASE

Main gameplay phase.

Players explore the map to gather evidence.

Active systems include:

Ghost AI
Evidence generation
Sanity drain
Environmental interactions

The Horror Director begins generating paranormal activity.

Investigation continues until:

Players complete objectives
Players initiate extraction
Players are eliminated

---

HUNT EVENTS

Hunts may occur during the investigation phase.

Conditions depend on:

Ghost aggression
Player sanity
Difficulty level
Modifier effects

During hunts:

Ghost enters aggressive pursuit mode.

Players must hide or escape.

---

EXTRACTION PHASE

Players return to the extraction point.

Players may end the investigation once they believe they have identified the ghost.

The team submits their ghost guess.

Players leave the map through the extraction zone.

---

RESULTS PHASE

The server evaluates match outcomes.

Results include:

Correct ghost identification
Evidence discovered
Bonus objectives completed
Player survival

Rewards are calculated and distributed.

---

RETURN TO LOBBY

Players are teleported back to the Lobby Social Hub.

Player data updates:

Experience
Currency
Rank progression
Statistics

The match instance is then destroyed.

---

SYSTEM RESPONSIBILITIES

MatchSystem

Creates matches
Stores match state
Handles player groups

GamePhaseSystem

Controls phase transitions
Triggers gameplay systems
Manages timers

TeleportService

Moves players between lobby and map servers

---

MATCH STATE MACHINE

The match lifecycle is implemented as a state machine.

States include:

Lobby
Preparation
Investigation
Hunt
Extraction
Results

State transitions occur through controlled triggers.

---

SYSTEM OBJECTIVE

The Match Lifecycle System ensures that all gameplay systems activate in the correct order.

It guarantees that:

Players experience a structured investigation flow
Systems remain synchronized
Match data remains consistent across all players

















Match Lifecycle Flow Diagram
Lobby
  │
  ▼
Contract Selected
  │
  ▼
Match Queue
  │
  ▼
Match Created
  │
  ▼
Teleport Players
  │
  ▼
Preparation Phase
  │
  ▼
Investigation Phase
  │
  ├─ Ghost Activity
  ├─ Evidence Collection
  ├─ Sanity Drain
  └─ Hunt Events
  │
  ▼
Extraction Phase
  │
  ▼
Results Phase
  │
  ▼
Return to Lobby
Systems Activated Per Phase
Phase	Systems Active
Lobby	LobbySocialHub
Preparation	MatchSystem
Investigation	GhostSystem, EvidenceSystem
Hunt	GhostAI
Extraction	MatchSystem
Results	EconomySystem, RankedSystem





PASRAHPHOBIA - MATCH STATE MACHINE

OVERVIEW

The Match State Machine controls the entire lifecycle of a match from creation to completion.

This system is managed by the MatchLifecycle and GamePhaseSystem.

Each match transitions through a series of states.

States

Waiting
Preparation
Investigation
Hunt
Extraction
Results
Completed

---

STATE: WAITING

The match instance has been created but players have not yet been teleported.

Conditions

Match created
Players assigned

Transition

PlayersTeleported → Preparation

---

STATE: PREPARATION

Players spawn at the map entrance and prepare for the investigation.

Ghost activity remains minimal.

Duration

30–60 seconds

Transition

TimerExpired → Investigation

---

STATE: INVESTIGATION

Players explore the map and gather evidence.

Active Systems

GhostSystem
EvidenceSystem
SanitySystem
AggressionSystem
HorrorDirector

Possible transitions

HuntTriggered → Hunt
ExtractionTriggered → Extraction

---

STATE: HUNT

Ghost enters aggressive pursuit state.

Doors lock
Lights flicker
Ghost chases players

Transition

HuntTimerExpired → Investigation

---

STATE: EXTRACTION

Players return to the extraction point and submit their ghost guess.

Transition

PlayersExtracted → Results

---

STATE: RESULTS

The server calculates investigation results.

Systems involved

EconomySystem
RankedSystem
ProfileSystem

Transition

ResultsComplete → Completed

---

STATE: COMPLETED

Match instance is destroyed and players return to the lobby.





MATCH STATE FLOW
Waiting
   │
   ▼
Preparation
   │
   ▼
Investigation
   │
   ├── Hunt
   │     │
   │     ▼
   │  Investigation
   │
   ▼
Extraction
   │
   ▼
Results
   │
   ▼
Completed




PASRAHPHOBIA — MATCH SYSTEM ARCHITECTURE
Writing

MATCH SYSTEM ARCHITECTURE

OVERVIEW

The Match System controls the lifecycle of every investigation session.

It manages matchmaking, match creation, teleportation to maps, phase transitions, and match completion.

The system ensures that players move smoothly from lobby gameplay into investigation matches and back to the lobby.

CORE RESPONSIBILITIES

The MatchSystem handles the following responsibilities.

Matchmaking
Party matchmaking
Match creation
Map selection
Player teleportation
Game phase control
Match state synchronization
Match result calculation

MATCH SYSTEM MODULES

The MatchSystem is divided into multiple modules.

MatchQueue

Handles players entering matchmaking.

MatchBuilder

Constructs match groups from players or parties.

MatchInstance

Represents a single investigation session.

MatchLifecycle

Controls phase transitions during the match.

TeleportService

Handles player teleportation to investigation maps.

MATCH SYSTEM STRUCTURE

MatchSystem

MatchQueue
MatchBuilder
MatchInstance
MatchLifecycle
TeleportService

Each match instance runs independently.

This allows multiple investigation matches to exist simultaneously.

MATCHMAKING FLOW

Players enter the MatchmakingZone in the lobby.

↓

MatchQueue registers the player or party.

↓

MatchBuilder groups players into a team.

↓

MatchInstance created.

↓

Map is selected.

↓

Players teleported to investigation map.

↓

MatchLifecycle begins.

MATCH INSTANCE DATA

Each match has its own state container.

MatchInstance

MatchID
Players
MapID
GameMode
Difficulty
MatchState
StartTime

Players

PlayerUserId
PlayerAlive
PlayerSanity
PlayerRole

MATCH PHASE SYSTEM

Matches operate in defined phases.

Preparation Phase

Players spawn in the map and prepare equipment.

Investigation Phase

Players search for ghost evidence.

Hunt Phase

Ghost becomes aggressive.

Extraction Phase

Players escape the map.

Results Phase

Rewards calculated and displayed.

PHASE TRANSITION FLOW

Preparation

↓

Investigation

↓

Hunt

↓

Extraction

↓

Results

↓

Return To Lobby

Each phase transition is controlled by MatchLifecycle.

MATCH STATE CONTROL

The match can exist in different states.

Waiting
Starting
InProgress
Ending
Completed

These states prevent incorrect transitions.

MATCH TELEPORTATION

Teleportation occurs when a match begins.

TeleportService moves players from lobby server to investigation server.

Teleport data includes

MatchID
MapID
GameMode
Difficulty
PartyMembers

SPECTATOR INTEGRATION

If a player dies during the match.

PlayerAlive becomes false.

↓

Player enters SpectatorMode.

↓

SpectatorCamera activates.

↓

SpectatorDistortionSystem begins.

The player remains inside the match instance.

EVIDENCE SYSTEM INTEGRATION

Evidence collected by players is stored in match state.

EvidenceCollected

SuhuMembeku
BukuTerkutuk
KotakArwah
BolaArwah
GerakanGaib
JejakEnergi

Evidence is shared across the team.

GHOST SYSTEM INTEGRATION

Each match instance spawns exactly one ghost.

GhostInstance

GhostType
FavoriteRoom
AggressionLevel
CurrentState

Ghost AI operates independently during the match.

REWARD CALCULATION

At match completion rewards are calculated.

RewardCalculator evaluates

Evidence correctness
Ghost identification
Player survival
Difficulty modifier

Rewards include

MM currency
EXP
Rank stars (ranked mode)

MATCH END FLOW

Match enters Results phase.

↓

Rewards distributed.

↓

Player statistics updated.

↓

Players teleported back to lobby.

ERROR PROTECTION

MatchSystem must handle failures.

Player disconnects
Party member leaves
Teleport failure
Server crash

Fallback rules ensure matches continue correctly.

SYSTEM INTEGRATION

MatchSystem communicates with

LobbySocialHub
GhostSystem
EvidenceSystem
SpectatorSystem
EconomySystem
RankedSystem
DataPersistence

It acts as the central coordinator between gameplay systems.

FINAL MATCH FLOW

Player joins lobby

↓

Matchmaking

↓

Match created

↓

Teleport to map

↓

Investigation gameplay

↓

Match result

↓

Rewards distributed

↓

Return to lobby

MATCH SYSTEM FLOW (VISUAL)
LobbySocialHub
     │
     ▼
MatchQueue
     │
     ▼
MatchBuilder
     │
     ▼
MatchInstance
     │
     ▼
TeleportService
     │
     ▼
Investigation Match
     │
     ├── GhostSystem
     ├── EvidenceSystem
     ├── AggressionSystem
     ├── FearEngine
     ├── SanitySystem
     └── SpectatorSystem
     │
     ▼
Match Results
     │
     ▼
RewardCalculator
     │
     ▼
Return To Lobby
Folder Integration (sesuai project kamu)

Struktur ini sudah cocok dengan folder yang kamu buat:

src/ServerScriptService/Server/MatchSystem

Modules:

MatchBuilder
MatchInstance
MatchLifecycle
MatchQueue
TeleportService




04_GHOST_SYSTEM
   - Ghost AI Behavior
   - Ghost State Machine
   - Hunt System
   - Ghost Modifier System


GHOST AI BEHAVIOR BLUEPRINT

OVERVIEW

The Ghost AI system controls the behavior of supernatural entities during investigations.

The system is designed to create unpredictable and dynamic encounters.

Each ghost is defined by:

Ghost Type
Personality Traits
Evidence Pattern
Aggression Behavior
Special Abilities
Modifiers

Ghost AI operates entirely on the server.

---

GHOST SYSTEM STRUCTURE

GhostSystem is divided into several modules.

GhostAI
GhostAbilities
States
RoomSystem

Each module has a specific responsibility.

GhostAI handles decision logic.

GhostAbilities defines ghost-specific powers.

States control behavior phases.

RoomSystem manages ghost movement between rooms.

---

GHOST AI CORE LOOP

Ghost AI runs a behavior loop during the investigation phase.

Loop interval:

1–2 seconds.

Each cycle evaluates:

Player proximity
Player sanity
Ghost aggression
Time since last event
Room activity level

The AI then decides its next action.

Possible actions:

Remain idle
Roam to another room
Interact with environment
Manifest briefly
Start hunt

---

GHOST STATES

Ghost states represent high-level behavior modes.

States include:

Idle
Roaming
Interaction
Manifestation
Hunt

The ghost transitions between these states based on conditions.

---

STATE: IDLE

The ghost remains in its favorite room.

Behavior:

Minimal activity
Occasional environmental interaction
Low aggression growth

Conditions to exit Idle:

Player enters ghost room
Aggression threshold increases
Time trigger

---

STATE: ROAMING

The ghost moves between rooms.

Room selection determined by:

RoomSystem graph
Noise from players
Recent player activity

Roaming ghosts may trigger small interactions.

Examples:

Door movement
Object displacement
Light flicker

---

STATE: INTERACTION

Ghost interacts with objects.

Interaction examples:

Door slam
Object throw
Electronic disturbance
Light flicker

Interaction probability increases when:

Players are near
Sanity is low
Aggression is rising

---

STATE: MANIFESTATION

Ghost briefly appears visually.

Manifestation types:

Shadow figure
Partial apparition
Full ghost appearance

Manifestations increase psychological tension.

Players may capture ghost photos during manifestation.

---

STATE: HUNT

Hunt is the most aggressive behavior.

Conditions to start hunt:

Aggression threshold reached
Low player sanity
Modifier effects
Map event influence

During hunt:

Ghost targets nearest player.

Players must hide or escape.

Hunt ends after timer expires or players escape detection.

---

ROOM SYSTEM

Ghost movement is controlled by the RoomSystem.

Each map contains a room graph.

Rooms have:

Type
Size
Interaction density

Ghost selects rooms using weighted probability.

Example factors:

Distance from ghost room
Player presence
Noise level

---

GHOST FAVORITE ROOM

Each ghost has a favorite room.

Evidence appears most frequently in this room.

The ghost may occasionally change favorite room in long matches.

---

GHOST PERSONALITY TRAITS

Each ghost has personality modifiers.

Examples:

Shy
Ghost avoids players.

Aggressive
Hunts more frequently.

Territorial
Rarely leaves ghost room.

Wanderer
Roams frequently.

Personality traits influence AI decision weights.

---

GHOST ABILITIES

Certain ghost types have unique abilities.

Examples:

Teleport short distance
Imitate player voice
Drain sanity faster
Hide evidence temporarily

Abilities activate under specific conditions.

Example:

Teleport ability triggers during hunts.

---

AGGRESSION SYSTEM

Aggression level determines ghost hostility.

Range:

0 – 100

Aggression increases when:

Players stay near ghost room
Players interact with cursed objects
Players have low sanity

Aggression slowly decreases if players leave ghost area.

---

HUNT TRIGGER LOGIC

Example hunt trigger:

If Aggression > 70
and AverageSanity < 40

HuntChance = BaseChance + ModifierBonus

Example:

BaseChance = 15%

ModifierBonus may increase this chance.

---

TARGET SELECTION

During hunts, ghost selects a target.

Priority rules:

Closest visible player
Player making noise
Player with lowest sanity

Target updates dynamically if players move.

---

GHOST MODIFIER INFLUENCE

Modifiers alter AI behavior.

Examples:

Rage
Aggression increases faster.

BlinkStep
Ghost teleports during hunts.

Dormant
Aggression grows slowly.

ShadowStalker
Ghost manifests behind players.

Modifiers are assigned per match.

---

MAP EVENT INFLUENCE

Map events influence ghost AI.

Examples:

PowerFailure
Ghost aggression increases.

Thunderstorm
Ghost manifestation frequency increases.

HeavyFog
Player visibility decreases during hunt.

---

HORROR DIRECTOR INTEGRATION

The Horror Director monitors match tension.

If tension is too low:

Ghost interactions increase.

If tension is too high:

Activity temporarily decreases.

This ensures pacing remains balanced.

---

AI OBJECTIVE

The Ghost AI system aims to:

Create unpredictable encounters
Increase psychological tension
Prevent predictable gameplay
Encourage team coordination

Each match should feel unique.

The combination of ghost type, modifiers, events, and player behavior ensures replayability.






















Ghost AI Architecture (Visual Overview)
Match Start
     │
     ▼
Ghost Spawn
     │
     ▼
Assign Ghost Type
     │
     ▼
Assign Modifiers
     │
     ▼
Assign Favorite Room
     │
     ▼
AI Behavior Loop
     │
     ├─ Idle
     ├─ Roaming
     ├─ Interaction
     ├─ Manifestation
     └─ Hunt
Integrasi Dengan Sistem Lain

Ghost AI terhubung dengan:

SanitySystem
AggressionSystem
EvidenceSystem
MapEventSystem
GhostModifierSystem
HorrorDirector
Folder Yang Mengimplementasikan Blueprint Ini

Sudah sesuai dengan struktur kamu:

src/ServerScriptService/Server/GhostSystem
├── GhostAI
├── GhostAbilities
├── RoomSystem
└── States



PASRAHPHOBIA — GHOST AI BEHAVIOR MATRIX


GHOST AI BEHAVIOR MATRIX

OVERVIEW

Each ghost type in PASRAHPHOBIA has a unique personality profile that affects how it behaves during investigation.

The Ghost AI Behavior Matrix defines behavior weights that influence roaming patterns, aggression level, interaction frequency, and hunt triggers.

This matrix allows each ghost type to feel distinct without changing the underlying GhostSystem architecture.

BEHAVIOR PARAMETERS

Each ghost uses the following parameters.

Aggression Level
Controls how quickly the ghost enters hunt state.

Roaming Frequency
How often the ghost leaves its favorite room.

Interaction Frequency
How often the ghost interacts with the environment.

Hunt Trigger Sensitivity
How easily hunts begin when players have low sanity.

Evidence Bias
Probability preference for certain evidence types.

Fear Presence
How strongly the ghost triggers fear effects.

GHOST BEHAVIOR MATRIX

Ghost Type: Pocong

Aggression: Low
Roaming: Low
Interaction: Medium
Hunt Trigger: Low

Special Trait:
Appears suddenly near players.

Fear Effect:
Short-distance apparition.

Preferred Evidence:
Buku Terkutuk
Suhu Membeku
Jejak Energi

Ghost Type: Kuntilanak

Aggression: Medium
Roaming: Medium
Interaction: Medium

Special Trait:
Laughing sound manifestation.

Fear Effect:
Mirror distortion events.

Preferred Evidence:
Kotak Arwah
Bola Arwah
Gerakan Gaib

Ghost Type: Tuyul

Aggression: Low
Roaming: High
Interaction: Low

Special Trait:
Object disturbance.

Fear Effect:
Small object movement.

Preferred Evidence:
Jejak Energi
Gerakan Gaib
Kotak Arwah

Ghost Type: Genderuwo

Aggression: High
Roaming: Medium
Interaction: High

Special Trait:
Heavy footsteps.

Fear Effect:
Strong presence aura.

Preferred Evidence:
Buku Terkutuk
Kotak Arwah
Suhu Membeku

Ghost Type: Wewe Gombel

Aggression: Medium
Roaming: Low
Interaction: Medium

Special Trait:
Children whisper audio.

Fear Effect:
Child-like giggle.

Preferred Evidence:
Bola Arwah
Gerakan Gaib
Jejak Energi

Ghost Type: Palasik

Aggression: Medium
Roaming: High
Interaction: Medium

Special Trait:
Ceiling movement behavior.

Fear Effect:
Shadow crawling.

Preferred Evidence:
Suhu Membeku
Jejak Energi
Kotak Arwah

Ghost Type: Banaspati

Aggression: High
Roaming: High
Interaction: Medium

Special Trait:
Fast roaming bursts.

Fear Effect:
Fire-like apparition effect.

Preferred Evidence:
Bola Arwah
Jejak Energi
Gerakan Gaib

Ghost Type: Sundel Bolong

Aggression: Medium
Roaming: Medium
Interaction: High

Special Trait:
Back-facing apparition.

Fear Effect:
Sudden appearance events.

Preferred Evidence:
Buku Terkutuk
Bola Arwah
Kotak Arwah

Ghost Type: Leak

Aggression: High
Roaming: High
Interaction: Low

Special Trait:
Night stalking behavior.

Fear Effect:
Long-distance sightings.

Preferred Evidence:
Gerakan Gaib
Jejak Energi
Suhu Membeku

Ghost Type: Hantu Jeruk Purut

Aggression: Low
Roaming: Low
Interaction: Medium

Special Trait:
Bell sound manifestation.

Fear Effect:
Footstep echoes.

Preferred Evidence:
Kotak Arwah
Bola Arwah
Jejak Energi

Ghost Type: Hantu Cermin

Aggression: Medium
Roaming: Medium
Interaction: High

Special Trait:
Mirror-based appearances.

Fear Effect:
Reflection anomalies.

Preferred Evidence:
Buku Terkutuk
Gerakan Gaib
Suhu Membeku

Ghost Type: Arwah Penunggu

Aggression: Medium
Roaming: Very Low
Interaction: High

Special Trait:
Territorial ghost.

Fear Effect:
Room temperature drops.

Preferred Evidence:
Suhu Membeku
Kotak Arwah
Buku Terkutuk

Behavior Influence System

Matrix ini akan mempengaruhi:

RoamingDecisionWeight
HuntTriggerWeight
InteractionFrequency
FearEventIntensity

Contoh:

Genderuwo
Aggression = HIGH
→ Hunt probability meningkat
Integrasi ke GhostSystem

Behavior matrix ini dipakai oleh:

GhostAI
RoomRoaming
HuntState
InteractionSystem
FearEngine

Contoh flow:

Ghost Spawn
      │
Load Behavior Profile
      │
Set AI Weights
      │
Ghost Simulation Begins
Hubungan dengan Evidence System

Matrix juga menentukan:

EvidenceProbabilityWeight

Contoh:

Pocong
lebih sering menghasilkan
Buku Terkutuk

Ini membuat investigasi lebih terasa seperti deduksi.

Hasil Gameplay

Dengan matrix ini pemain bisa belajar:

"ghost ini sering roam"
"ghost ini suka interaksi"
"ghost ini jarang hunt"

Ini menciptakan:

pattern recognition
player deduction
investigation tension


PASRAHPHOBIA - GHOST STATE MACHINE

OVERVIEW

The Ghost State Machine controls ghost behavior during the investigation.

The ghost constantly transitions between states depending on aggression, player actions, and environmental triggers.

States

Idle
Roaming
Interaction
Manifestation
Hunt

---

STATE: IDLE

Ghost remains inactive in its favorite room.

Used primarily during early investigation.

Transition

TimerExpired → Roaming

---

STATE: ROAMING

Ghost moves between nearby rooms.

Ghost may interact with objects.

Transition

PlayerNearby → Interaction
AggressionHigh → Hunt

---

STATE: INTERACTION

Ghost interacts with the environment.

Examples

Door movement
Object throwing
Light flicker

Transition

InteractionComplete → Roaming

---

STATE: MANIFESTATION

Ghost appears briefly to players.

Creates fear and tension.

Transition

ManifestationComplete → Roaming

---

STATE: HUNT

Ghost aggressively pursues players.

Transition

HuntEnded → Roaming






GHOST STATE FLOW
Idle
 │
 ▼
Roaming
 │
 ├── Interaction
 │        │
 │        ▼
 │     Roaming
 │
 ├── Manifestation
 │        │
 │        ▼
 │     Roaming
 │
 ▼
Hunt
 │
 ▼
Roaming



PASRAHPHOBIA - HUNT STATE MACHINE

OVERVIEW

The Hunt State Machine defines the internal logic of a ghost hunt event.

States

Preparing
Active
Chasing
Ending

STATE: PREPARING

Hunt initialization.

Actions

Doors lock
Lights flicker
Ghost becomes visible

Transition

PreparationComplete → Active

STATE: ACTIVE

Ghost begins searching for players.

Transition

PlayerDetected → Chasing
HuntTimerExpired → Ending

STATE: CHASING

Ghost actively pursues a target player.

Transition

TargetLost → Active
PlayerKilled → Active
HuntTimerExpired → Ending

STATE: ENDING

Hunt ends.

Actions

Doors unlock
Lights stabilize
Ghost disappears

Transition

Return → Investigation





HUNT STATE FLOW
Preparing
   │
   ▼
Active
   │
   ├── PlayerDetected
   ▼
Chasing
   │
   ▼
Active
   │
   ▼
Ending



PASRAHPHOBIA — HUNT SYSTEM BLUEPRINT


HUNT SYSTEM BLUEPRINT

OVERVIEW

The Hunt System controls the most dangerous phase of an investigation where the ghost actively pursues players.

A hunt occurs when ghost aggression reaches a certain threshold and specific conditions are met.

During hunts, players must hide, escape, or avoid the ghost until the hunt ends.

The Hunt System is controlled by the GhostSystem and influenced by:

SanitySystem
AggressionSystem
Difficulty Scaling
Ghost Modifiers
Map Events

HUNT TRIGGER CONDITIONS

A hunt may start when several conditions are satisfied.

Primary conditions:

Ghost Aggression Level
Average Player Sanity
Difficulty Level
Modifier Effects

Example trigger logic:

Aggression > HuntThreshold

AND

AveragePlayerSanity < SanityThreshold

Example thresholds:

HuntThreshold = 70
SanityThreshold = 40

When conditions are met, the system rolls a hunt probability.

Example:

HuntChance = BaseChance + AggressionBonus + DifficultyBonus

HUNT COOLDOWN

After each hunt, a cooldown period prevents immediate consecutive hunts.

Example cooldown:

20 – 40 seconds depending on difficulty.

Higher difficulty reduces cooldown duration.

Example:

Difficulty 2 → Cooldown 40 seconds
Difficulty 8 → Cooldown 20 seconds

HUNT START SEQUENCE

When a hunt begins:

1 All exit doors lock.

2 Lights flicker or shut down.

3 Radio devices produce interference.

4 The ghost becomes visible to players.

5 The hunt timer begins.

These signals inform players that a hunt has started.

TARGET SELECTION

At hunt start, the ghost selects a target player.

Target priority rules:

Closest player
Player producing sound
Player with lowest sanity

Target selection may change during the hunt if:

Another player becomes closer
Line of sight changes
Ghost loses track of current target

PLAYER DETECTION

Ghost detects players through several methods.

Detection types:

Line of Sight
Sound Detection
Proximity Detection

Line of Sight

If ghost has clear visual path to a player, the player becomes the primary target.

Sound Detection

Running players or players interacting with objects produce noise.

Ghost may track noise even without visual contact.

Proximity Detection

If a player is extremely close to the ghost, detection may occur instantly.

HIDING MECHANICS

Players may hide during hunts.

Valid hiding strategies include:

Entering closets
Hiding behind objects
Remaining silent

While hiding:

Players must avoid making noise.

Using equipment may attract the ghost.

GHOST MOVEMENT DURING HUNT

Ghost movement speed depends on difficulty and modifiers.

Example speeds:

Difficulty 2 → Slow ghost movement
Difficulty 5 → Normal speed
Difficulty 9 → Very fast ghost movement

Certain ghost types may accelerate when chasing players.

HUNT DURATION

Each hunt lasts for a fixed duration.

Example:

Difficulty 1 – 3 → 15 seconds
Difficulty 4 – 6 → 20 seconds
Difficulty 7 – 10 → 30 seconds

Modifiers may increase or decrease hunt duration.

PLAYER ELIMINATION

If the ghost reaches a player during a hunt:

The player is eliminated.

Eliminated players become spectators.

Spectators may:

Observe teammates
Switch camera between players

HUNT END CONDITIONS

The hunt ends when the hunt timer expires.

When hunt ends:

Ghost disappears.
Doors unlock.
Lights stabilize.
Normal investigation resumes.

A cooldown period begins before another hunt can occur.

MODIFIER INFLUENCE

Ghost modifiers can change hunt behavior.

Examples:

BlinkStep

Ghost may teleport short distances during hunts.

Rage

Ghost movement speed increases while chasing.

Dormant

Ghost hunts less frequently.

ShadowStalker

Ghost may appear behind players before hunts.

MAP EVENT INFLUENCE

Environmental events may alter hunt behavior.

Examples:

PowerFailure

Ghost hunts more frequently.

Thunderstorm

Ghost detection range increases.

HeavyFog

Player visibility decreases.

HORROR DIRECTOR INTEGRATION

The Horror Director monitors hunt frequency.

If hunts occur too frequently, the director may reduce hunt probability.

If tension becomes too low, hunt chance increases.

This maintains balanced pacing.

SYSTEM OBJECTIVE

The Hunt System creates moments of extreme tension during investigations.

Players must react quickly and coordinate with teammates to survive.

Each hunt should feel unpredictable and dangerous.

Hunt System Flow
Aggression Rising
      │
      ▼
Check Hunt Conditions
      │
      ▼
Roll Hunt Probability
      │
      ▼
Hunt Triggered
      │
      ▼
Doors Lock
Lights Flicker
Ghost Visible
      │
      ▼
Ghost Selects Target
      │
      ▼
Ghost Pursues Player
      │
      ▼
Timer Expires
      │
      ▼
Hunt Ends
Cooldown Begins
Sistem Yang Mengontrol Hunt

Hunt dipengaruhi oleh:

GhostSystem
AggressionSystem
SanitySystem
DifficultyScaling
GhostModifierSystem
MapEventSystem
HorrorDirector
Struktur Folder yang Mengimplementasikan Sistem Ini

Sudah sesuai dengan struktur project kamu:

src/ServerScriptService/Server/GhostSystem
 ├─ GhostAI
 ├─ GhostAbilities
 ├─ States
 └─ RoomSystem

Hunt behavior terutama berada di:

GhostSystem/GhostAI
GhostSystem/States



		
05_EVIDENCE_SYSTEM
   - Evidence Engine
   - Evidence Spawning
   - Evidence Deduction Algorithm
		
		
		EVIDENCE DEDUCTION ALGORITHM BLUEPRINT

OVERVIEW

The Evidence Deduction System determines the possible ghost types based on evidence discovered by players during an investigation.

Each ghost type has a predefined evidence combination.

Players collect evidence using investigation tools and record them in the investigation journal.

The deduction algorithm compares collected evidence against ghost evidence tables to determine possible ghost candidates.

---

EVIDENCE TYPES

The game uses six primary evidence types.

Bola Arwah
Buku Terkutuk
Gerakan Gaib
Jejak Energi
Kotak Arwah
Suhu Membeku

Each ghost type has a unique combination of evidence.

Example:

Ghost A

Bola Arwah
Jejak Energi
Suhu Membeku

Ghost B

Kotak Arwah
Gerakan Gaib
Buku Terkutuk

Evidence combinations should ensure that every ghost can be uniquely identified.

---

EVIDENCE COLLECTION

Evidence is detected when players use investigation tools.

Example interactions:

Camera detects Bola Arwah.
Temperature meter detects Suhu Membeku.
Spirit communication detects Kotak Arwah.
EMF-like tool detects Jejak Energi.
Ghost writing tool detects Buku Terkutuk.
Motion sensor detects Gerakan Gaib.

Evidence detection is validated by the server before being recorded.

---

TEAM EVIDENCE POOL

Evidence discovered by any player is shared across the entire team.

Example:

Player A detects Bola Arwah.

The team evidence list updates to include Bola Arwah.

All players can view the updated evidence in their journal.

---

JOURNAL SYSTEM

Players record evidence in the investigation journal.

The journal contains checkboxes for each evidence type.

Example:

[X] Bola Arwah
[X] Suhu Membeku
[ ] Gerakan Gaib
[ ] Buku Terkutuk

The journal automatically updates the list of possible ghost types.

---

DEDUCTION ALGORITHM

The algorithm works by filtering ghost types based on collected evidence.

Process:

1 Load full ghost list.

2 For each ghost type:
Check if ghost evidence matches collected evidence.

3 Remove ghosts that do not match.

4 Remaining ghosts are possible candidates.

Example:

Collected Evidence:

Bola Arwah
Suhu Membeku

Possible Ghosts:

Ghost A
Ghost D
Ghost F

When a third evidence is discovered, the list narrows to one ghost.

---

PARTIAL EVIDENCE HANDLING

The system must handle incomplete evidence.

Example:

Players only found two pieces of evidence.

The journal shows multiple possible ghosts.

This encourages further investigation.

---

FALSE POSITIVE PREVENTION

To prevent misleading evidence:

Evidence validation requires server confirmation.

Conditions checked include:

Ghost proximity
Room activity
Ghost evidence capability

If conditions are not met, evidence is rejected.

---

EVIDENCE SPAWN LOGIC

Evidence appears based on ghost activity.

Factors influencing evidence generation:

Ghost state
Ghost room
Ghost aggression
Modifier effects

Evidence spawn probability increases as investigation progresses.

---

DIFFICULTY MODIFIERS

Difficulty affects evidence clarity.

Example:

Easy Mode

Evidence appears frequently.

Nightmare Mode

Evidence appears rarely.

Some evidence may require repeated attempts.

---

GHOST MODIFIER INFLUENCE

Modifiers may alter evidence behavior.

Examples:

Faint Presence

Evidence appears less often.

Distorted Signals

Evidence readings may be inconsistent.

Overactive

Evidence appears frequently.

---

JOURNAL HINT SYSTEM

When only one ghost remains in the candidate list, the journal may highlight the most probable ghost.

However, players must still manually confirm their guess.

---

FINAL GHOST GUESS

Players submit their ghost guess before extraction.

Example:

Journal guess = Kuntilanak.

If correct:

Players receive full investigation rewards.

If incorrect:

Rewards reduced.

---

TEAM DECISION SYSTEM

In multiplayer matches, each player may submit their own guess.

Rewards depend on:

Correct individual guess
Team survival
Evidence collected

---

SYSTEM OBJECTIVE

The Evidence Deduction System ensures investigation gameplay remains:

Logical
Team-based
Replayable
Challenging

Players must gather information carefully before making conclusions.










































Evidence Deduction Flow
Match Start
     │
     ▼
Ghost Type Selected
     │
     ▼
Evidence Generated by Ghost
     │
     ▼
Players Use Tools
     │
     ▼
Server Validates Evidence
     │
     ▼
Team Evidence Pool Updated
     │
     ▼
Journal Filters Ghost Candidates
     │
     ▼
Players Submit Final Guess
Data Relationship (Server)

Evidence deduction menggunakan data dari:

shared/DataTypes/Evidence
shared/DataTypes/Ghosts/GhostEvidenceMap

Flow data:

GhostType
   │
   ▼
EvidenceGhostMap
   │
   ▼
EvidenceSystem
   │
   ▼
InvestigationSystem
   │
   ▼
JournalUI
Contoh Evidence Mapping (Konsep)

Contoh desain 12 ghost menggunakan 6 evidence (3 per ghost):

Ghost A → Bola Arwah, Jejak Energi, Suhu Membeku
Ghost B → Bola Arwah, Gerakan Gaib, Buku Terkutuk
Ghost C → Jejak Energi, Kotak Arwah, Suhu Membeku
Ghost D → Gerakan Gaib, Kotak Arwah, Buku Terkutuk
...

Semua kombinasi harus unik agar ghost dapat dibedakan.

Integrasi Dengan Sistem Lain

Evidence deduction berinteraksi dengan:

GhostSystem
EvidenceSystem
InvestigationSystem
ContractSystem
MatchSystem
JournalUI


PASRAHPHOBIA - INVESTIGATION STATE MACHINE

OVERVIEW

The Investigation State Machine tracks investigation progress and evidence discovery.

States

Searching
EvidenceFound
GhostIdentified
ExtractionReady

---

STATE: SEARCHING

Players explore the map looking for evidence.

Transition

EvidenceCollected → EvidenceFound

---

STATE: EVIDENCE FOUND

Evidence has been discovered.

System updates the investigation journal.

Transition

MoreEvidence → EvidenceFound
GhostGuess → GhostIdentified

---

STATE: GHOST IDENTIFIED

Players believe they know the ghost type.

Transition

ExtractionStarted → ExtractionReady

---

STATE: EXTRACTION READY

Players return to extraction point and submit the investigation.

Transition

MatchEnd → Results






INVESTIGATION STATE FLOW
Searching
   │
   ▼
EvidenceFound
   │
   ▼
GhostIdentified
   │
   ▼
ExtractionReady




06_SPECTATOR_SYSTEM
   - Spectator Distortion System
   - Spectator Communication Model
   - Fake / Real Ghost Logic
   
		FINAL SPECTATOR SYSTEM SPECIFICATION

OVERVIEW

The Spectator System activates when a player dies during an investigation match.

Dead players remain inside the match instance and enter Spectator Mode.

Spectators observe the match through the perspective of living teammates while experiencing distorted paranormal perception.

The system ensures spectators remain engaged without revealing reliable ghost information.

---

SPECTATOR ACTIVATION

When a player dies

PlayerAlive becomes false.

↓

Player transitions into Spectator Mode.

↓

SpectatorCamera activates.

↓

SpectatorDistortionSystem begins.

The player remains inside the match until the match ends.

---

SPECTATOR CAMERA RULE

Spectators cannot freely roam the map.

Camera behavior

Follow Alive Player

Spectator may switch between alive teammates.

The camera attaches to the selected living player.

This prevents spectators from scouting the map.

---

CAMERA MODES

Player Follow Mode

Camera tracks a living teammate.

Switch Target Mode

Spectator can change which player to follow.

The system cycles through alive players.

If only one player remains alive

Camera locks to that player.

---

VOICE COMMUNICATION

Spectators communicate using Roblox proximity voice chat.

There is no spectator hint system.

There are no UI messages or spectator markers.

All communication occurs through player voice.

Living players must decide whether to trust the information.

---

SPECTATOR DISTORTION SYSTEM

Spectators perceive ghost events through a distorted paranormal filter.

Each ghost visibility event uses the distortion probability model.

60% Fake Ghost

A ghost illusion appears locally on the spectator client.

This ghost does not exist on the server.

30% Uncertain Event

Ghost presence is implied through partial disturbances.

Examples

Shadow movement

Footstep sound

Object disturbance

10% Real Ghost

Spectator briefly sees the real ghost location.

This event is rare.

---

DISTORTION VISUAL EFFECTS

Spectators see the world through a paranormal distortion filter.

Possible effects

Screen flicker

Chromatic distortion

Ghost trails

Shadow artifacts

Audio whispers

These effects reinforce unreliable perception.

---

DEATH MESSAGE SYSTEM

When a player dies the following message appears.

Player Dead Message

Displayed in the center of the screen for 5 seconds.

"Kematian menipumu.
Yang kamu lihat belum tentu benar."

After 5 seconds

The message moves to the left side of the screen and becomes smaller.

The message remains visible until the match ends.

---

ALIVE PLAYER MESSAGE

When another player dies

Living players receive a message.

Displayed in the center for 5 seconds.

"Jangan terlalu percaya orang mati.
Gunakan instingmu.
Jika percaya, lakukanlah."

This message encourages players to question spectator information.

---

SPECTATOR GAMEPLAY LOOP

Player dies

↓

Enter Spectator Mode

↓

Follow living teammate

↓

Observe ghost activity (distorted)

↓

Communicate through voice chat

↓

Living players decide whether to trust information

↓

Investigation continues

---

ANTI EXPLOIT PROTECTION

Spectators cannot access

Exact ghost location continuously.

Evidence generation data.

Server ghost state.

Distortion prevents reliable ghost tracking.

---

MATCH INTEGRATION

Spectator system integrates with

MatchSystem
GhostSystem
AggressionSystem
SpectatorDistortionSystem

When the match ends

Spectators return to lobby with all players.

---

SYSTEM MODULES

SpectatorSystem

SpectatorCamera
SpectatorDistortionSystem
SpectatorTargetSwitch
DeathMessageUI

These modules operate on the client of dead players.





SPECTATOR FLOW
Player Dies
    │
    ▼
Spectator Mode
    │
    ▼
SpectatorCamera
    │
    ▼
Follow Alive Player
    │
    ▼
SpectatorDistortionSystem
    │
    ├── 60% Fake Ghost
    ├── 30% Uncertain Event
    └── 10% Real Ghost
SPECTATOR SOCIAL LOOP
Spectator sees ghost
        │
        ▼
Speaks via mic
        │
        ▼
Team decides whether to trust
        │
        ├─ Correct → Evidence progress
        └─ Wrong → Ghost aggression increases
Folder Integration

Sesuai dengan struktur project kamu:

src/client/SpectatorSystem

Modules:

SpectatorCamera
SpectatorDistortionSystem
SpectatorTargetSwitch
DeathMessageUI



PASRAHPHOBIA — SPECTATOR COMMUNICATION MODEL




Prinsip Utama
Spectator = Dead Player
Camera = Follow Player Alive
Communication = Voice Chat Roblox

Tidak ada:

ping system

hint button

spectator message

spectator UI clue

Semua informasi hanya lewat mic komunikasi pemain.

Komunikasi Spectator

Spectator berbicara seperti ini:

Contoh situasi:

"Kayaknya ghost di dapur!"
"Eh tunggu, tadi kayaknya di ruang tamu…"
"Gue lihat bayangan di lantai dua!"

Masalahnya:

informasi spectator tidak selalu benar.

Karena sistem kamu:

60% Fake Ghost
30% Uncertain
10% Real Ghost

Jadi tim hidup harus berpikir:

"Dia bener lihat ghost…
atau cuma ilusi?"

Ini menciptakan mind game antar player.

Spectator Camera Rules

Spectator tidak bebas roam map.

Camera hanya:

Follow Player Alive

Tujuannya:

tidak bisa scouting map

tidak bisa mencari ghost bebas

tetap ikut tim

Struktur camera:

Dead Player
     ↓
Spectator Mode
     ↓
Select Alive Player
     ↓
Follow Camera
Spectator View Distortion

Karena spectator adalah roh, maka visualnya tidak stabil.

Distortion effect:

screen noise
ghost trail
shadow flicker
light distortion
audio whisper

Ini membuat spectator tidak bisa memastikan apa yang dia lihat.

Social Trust System (Natural)

Tanpa UI hint, sistem kamu menciptakan natural trust mechanic.

Contoh:

Player mati bilang:

"Ghost di dapur!"

Tim hidup berpikir:

percaya → cek dapur
tidak percaya → lanjut cari

Jika salah:

AggressionSystem ↑
Ghost lebih agresif

Jika benar:

Evidence ditemukan
Death Message System

Saat pemain mati muncul pesan:

Player Dead
CENTER (5s)

"Kematian menipumu.
Yang kamu lihat belum tentu benar."

Setelah itu:

UI pindah ke kiri
mengecil
tetap muncul sampai endgame
Player Alive
CENTER (5s)

"Jangan terlalu percaya orang mati.
Gunakan instingmu.
Jika percaya, lakukanlah."

Tujuan pesan ini:

memberi warning

membangun distrust

memperkuat horror theme

Keputusan Arsitektur (FINAL)

Spectator system menjadi:

Server
GhostAI
EvidenceSystem
AggressionSystem

Client Alive
RealGhostRenderer
EvidenceTools

Client Dead
SpectatorDistortionSystem
SpectatorCamera

Tidak ada:

HintSystem
PingSystem
SpectatorUIHint



PASRAHPHOBIA — SPECTATOR DISTORTION ALGORITHM
Writing

SPECTATOR DISTORTION ALGORITHM

OVERVIEW

The Spectator Distortion Algorithm determines what dead players see when paranormal activity occurs.

The algorithm prevents spectators from receiving fully accurate information while still allowing rare moments of correct observation.

The system activates whenever a ghost activity event occurs.

Ghost activity events include:

ghost roaming
ghost interaction
ghost hunt start
environmental disturbance
ghost room change

Each event triggers the distortion algorithm.

DISTORTION PROBABILITY MODEL

The algorithm selects one of three visibility outcomes.

60% Fake Ghost

A false ghost manifestation is generated locally on the spectator client.

This ghost does not exist on the server.

30% Uncertain Event

A ghost-related disturbance occurs without a clear ghost body.

Examples include shadows, footsteps, whispers, or moving objects.

10% Real Ghost

The spectator temporarily sees the real ghost position.

This is the only case where the information may be correct.

DISTORTION SELECTION PROCESS

When a ghost activity event occurs, the system generates a random number between 1 and 100.

1–60 → Fake Ghost

61–90 → Uncertain Event

91–100 → Real Ghost

This ensures the exact probability distribution.

FAKE GHOST SELECTION RULE

Fake ghosts must appear believable.

The algorithm selects a nearby room relative to the observed player.

Rules

The room must be within a defined distance radius.

The room must not be the real ghost room.

The room must contain valid ghost navigation points.

This prevents obvious fake placements.

UNCERTAIN EVENT SELECTION

If the uncertain event branch is selected, the system randomly selects one disturbance.

Possible disturbances

Shadow movement
Door creak
Footstep audio
Object movement
Light flicker
Whisper sound

These events create psychological uncertainty.

REAL GHOST VISIBILITY RULE

Real ghost visibility is limited.

Rules

Duration: 2–4 seconds

Visibility ends immediately if the ghost begins a hunt state.

Spectators cannot track the ghost continuously.

This prevents spectator tracking exploits.

COOLDOWN SYSTEM

The distortion algorithm includes a cooldown to prevent spam.

Typical cooldown

5–10 seconds between ghost visibility events.

This ensures the system feels rare and meaningful.

PLAYER PROXIMITY INFLUENCE

The probability system slightly shifts based on player proximity to ghost activity.

If players are near the ghost room:

Fake Ghost probability slightly decreases.

Uncertain events increase.

This creates more believable observations.

Example adjustment

Fake Ghost → 50%

Uncertain Event → 40%

Real Ghost → 10%

ANTI EXPLOIT PROTECTION

The system prevents spectators from triangulating the real ghost.

Protections include

Fake ghost path randomness

Randomized event timing

Limited real ghost duration

Camera follow restrictions

This ensures spectator information cannot become a reliable detection tool.

SYSTEM EXECUTION FLOW

Ghost Activity Event Triggered

↓

Spectator Distortion Algorithm

↓

Random Probability Roll

↓

Branch Selection

Fake Ghost
Uncertain Event
Real Ghost

↓

Spectator Render Event

↓

Distortion Cooldown

Distortion Decision Flow
Ghost Activity Event
        │
        ▼
Random Roll (1–100)
        │
 ┌──────┼─────────┐
 │      │         │
 ▼      ▼         ▼
Fake   Uncertain   Real
60%     30%        10%
Fake Ghost Placement Logic
Player Alive Position
        │
        ▼
Nearby Room Search
        │
        ▼
Exclude Real Ghost Room
        │
        ▼
Spawn Fake Ghost
Distortion Event Cooldown
Ghost Event Trigger
      │
      ▼
Distortion Render
      │
      ▼
Cooldown (5–10s)
      │
      ▼
Next Possible Event
Sistem yang Terhubung

Spectator Distortion Algorithm berinteraksi dengan:

GhostSystem
AggressionSystem
HorrorDirector
InvestigationSystem

Contoh:

Jika tim mengikuti fake ghost location, maka:

AggressionSystem ↑
Ghost becomes more aggressive
Dampak Gameplay

Algoritma ini menciptakan gameplay:

spectator doubt
team discussion
investigation risk
psychological horror

Pemain hidup harus memutuskan:

Apakah informasi dari orang mati bisa dipercaya?


PASRAHPHOBIA — SPECTATOR DISTORTION MATRIX
1. SPECTATOR SYSTEM CONCEPT

Player mati tidak menjadi penonton biasa.

Mereka melihat dunia paranormal yang terdistorsi.

Ini menciptakan:

misinformation
psychological gameplay
team confusion
2. DISTORTION PROBABILITY
Fake Ghost = 60%
Uncertain Event = 30%
Real Ghost = 10%
3. FAKE GHOST EVENTS (60%)

Contoh:

ghost muncul di ruangan salah

hunt palsu

footsteps palsu

pintu bergerak tanpa ghost

Tujuan:

menipu spectator
4. UNCERTAIN EVENTS (30%)

Contoh:

bayangan

suara samar

objek bergerak kecil

Spectator tidak yakin.

5. REAL GHOST (10%)

Spectator melihat ghost asli.

Jika spectator memberi info:

team mungkin benar
atau mungkin salah

Karena pemain hidup tidak tahu mana yang benar.

6. COMMUNICATION SYSTEM

Spectator berkomunikasi menggunakan:

Roblox Voice Chat

Tidak ada sistem hint otomatis.

7. PSYCHOLOGICAL GAMEPLAY

Contoh situasi:

Spectator:
"Gue lihat ghost di dapur!"

Player hidup:
percaya / tidak percaya

Jika salah:

ghost aggression naik

Jika benar:

evidence ditemukan
8. DEATH NOTICE UI

Saat player mati:

Teks muncul:

Kematian menipumu
Yang kamu lihat belum tentu benar

5 detik center
Kemudian pindah ke kiri.

9. WARNING UNTUK PLAYER HIDUP

Saat teammate mati:

UI muncul:

Jangan terlalu percaya orang mati
Gunakan instingmu

Durasi:

5 detik center
10. GAME DESIGN PURPOSE

Spectator system dibuat untuk:

meningkatkan tension
mengurangi meta gaming
menciptakan drama tim



PASRAHPHOBIA — SPECTATOR DISTORTION ENGINE


SPECTATOR DISTORTION ENGINE DESIGN

OVERVIEW

The Spectator Distortion Engine controls what dead players see while spectating.

The system intentionally distorts ghost visibility so that spectators cannot provide perfectly accurate information.

This prevents spectator cheating while still allowing spectators to participate in the investigation.

Spectator vision is separated from the real ghost state.

The system generates illusion ghosts, uncertain ghost manifestations, and occasionally the real ghost.

SYSTEM OBJECTIVES

Prevent spectator information from being fully reliable.

Allow spectators to give investigation hints.

Maintain psychological tension for both spectators and living players.

Create a unique gameplay loop where spectators become unreliable witnesses.

ARCHITECTURE LAYERS

The Spectator Distortion Engine runs primarily on the client of dead players.

Server remains authoritative over the real ghost.

Server Systems

GhostAI
EvidenceSystem
AggressionSystem

Client Alive

RealGhostRenderer
EvidenceTools

Client Dead

SpectatorDistortionSystem
FakeGhostRenderer
GhostVisionFilter
SpectatorCameraController

DISTORTION PROBABILITY

Each time a spectator sees a ghost event, the engine selects one of three outcomes.

60% Fake Ghost

A ghost illusion appears in a random nearby room.

This ghost does not exist on the server.

It is rendered only for the spectator.

30% Uncertain Ghost

A distorted or incomplete ghost manifestation appears.

Examples:

Partial silhouette
Shadow passing
Sound without visual confirmation

This makes the spectator unsure.

10% Real Ghost

The spectator sees the actual ghost location.

This creates rare moments where the spectator gives correct information.

FAKE GHOST GENERATION

Fake ghosts are generated locally on the spectator client.

Rules

Must appear in plausible investigation locations.

Must not appear too frequently.

Should follow simple roaming behavior.

Fake ghosts disappear after a short time.

Typical duration

3 to 7 seconds.

UNCERTAIN GHOST EVENTS

Uncertain events simulate ghost presence but without clarity.

Examples

Moving shadow

Footstep sounds

Door movement

Whisper audio

These events create confusion.

The spectator may believe the ghost is nearby but cannot confirm.

REAL GHOST VISIBILITY

Real ghost visibility is intentionally rare.

When triggered, the spectator camera temporarily syncs with the real ghost position.

Duration

2 to 4 seconds.

After that, the distortion filter returns.

SPECTATOR CAMERA SYSTEM

Spectator camera operates in multiple modes.

Modes

Player Follow
Free Camera
Ghost Echo Camera

Player Follow

Camera follows a living teammate.

Free Camera

Spectator can explore the map.

Ghost Echo Camera

Camera briefly shifts toward ghost-related activity.

DISTORTION FILTER

Spectators see the world through a visual filter.

Effects may include

Chromatic distortion

Ghost trails

Shadow artifacts

Occasional flicker

These effects reinforce the idea that the spectator view is unreliable.

HINT GENERATION LOOP

Spectators may communicate ghost hints to living players.

Example loop

Spectator sees ghost in kitchen.

Spectator informs team.

Team tests evidence in kitchen.

If correct

Evidence appears.

If incorrect

Ghost aggression increases.

This creates a risk-reward system for trusting spectator information.

ANTI EXPLOIT RULES

Spectators must never see:

Exact ghost position continuously.

Evidence spawn data.

Server ghost state.

Real ghost visibility is strictly limited by probability.

SYSTEM INTEGRATION

The Spectator Distortion Engine interacts with:

GhostSystem
AggressionSystem
InvestigationSystem
HorrorDirector

Example integration

If players follow incorrect spectator hints too often, the AggressionSystem may increase ghost hostility.

GAMEPLAY BENEFIT

The Spectator Distortion Engine turns dead players into unreliable investigators.

Spectators remain engaged in the match.

Living players must decide whether to trust them.

This creates social tension and memorable horror moments.

Spectator Distortion Flow
Player Dies
     │
     ▼
Enter Spectator Mode
     │
     ▼
SpectatorDistortionEngine
     │
     ├── 60% Fake Ghost
     ├── 30% Uncertain Event
     └── 10% Real Ghost
Spectator Gameplay Loop
Spectator sees ghost
      │
      ▼
Spectator tells team
      │
      ▼
Team investigates location
      │
      ├── Correct → Evidence appears
      │
      └── Wrong → Aggression increases
Client Systems for Spectator

Folder yang sesuai dengan struktur project kamu:

src/client/SpectatorSystem

Engine modules:

SpectatorDistortionSystem
FakeGhostRenderer
GhostVisionFilter
SpectatorCameraController
GhostEchoCamera
Server Interaction

Spectator system tidak boleh membaca state ghost langsung.

Server hanya mengirim:

ghost activity hints
environmental disturbances
hunt start/end

Client distortion engine kemudian menentukan:

fake / uncertain / real



07_ECONOMY_SYSTEM
   - Economy Data Structure
   - Economy Balance
   - Monetization System
   - RoyalPass System


		ECONOMY & MONETIZATION SYSTEM

OVERVIEW

PASRAHPHOBIA uses a multi-currency economy system designed for long-term progression, cosmetic monetization, and controlled player rewards.

The economy system is designed around three currencies.

MM
PP
Robux

Each currency has a specific role in the game ecosystem.

---

CURRENCY SYSTEM

MM (Mystic Money)

Standard in-game currency earned from gameplay.

Uses

Equipment
Basic cosmetics
Low to mid rarity assets

Rarity Range

R1
R2
R3

---

PP (Paranormal Points)

Premium in-game currency.

Used for higher rarity assets.

Uses

Rare cosmetics
Special skins
Premium shop items

Rarity Range

R1
R2
R3
R4
R5

---

ROBUX

Official Roblox premium currency.

Used for direct monetization.

Uses

RoyalPass
Premium cosmetics
Bundles
Gift system

Rarity Range

R1
R2
R3
R4
R5

---

RARITY SYSTEM

Assets are divided into five rarity levels.

R1
B-ajah

R2
B-Lebih

R3
Lumayan

R4
Langka

R5
Gagah

Rarity influences:

asset visual quality
drop probability
shop price
cosmetic prestige

---

ASSET CATEGORIES

Equipment

Gameplay tools.

Item

Consumables or boosters.

Cosmetic

Visual customization.

Skin

Equipment skins.

Emote

Player animations.

Title

Player titles.

Booster Card

Temporary bonus modifiers.

Kawani

Companion cosmetic entity.

---

REWARD SYSTEM

Players earn MM through match performance.

MM Reward Formula

1% = 10 MM

Reward is based on investigation success percentage.

Win Condition

Greater than 50 percent

Lose Condition

Less than 50 percent

Daily cap

Maximum MM per day

10,000 MM

This prevents excessive farming.

---

DAILY MISSION SYSTEM

Players receive three daily missions.

Reward structure

Mission Complete

1000 MM

All Missions Completed

2000 MM bonus

Total potential

5000 MM

---

DAILY CHECK-IN SYSTEM

Daily login rewards operate on a looping 7 day system.

Day 1

1000 MM

Day 2

1000 MM

Day 3

1000 MM

Day 4

Random Asset

R1 = 80 percent
R2 = 20 percent

Day 5

1500 MM

Day 6

1500 MM

Day 7

Random Asset

R1 = 60 percent
R2 = 30 percent
R3 = 10 percent

The system resets after day seven.

---

ROYALPASS SYSTEM

Seasonal progression system.

Season duration

30 days

Two RoyalPass tiers exist.

Kelas Dukun

Mid tier seasonal pass.

Rewards

1 Set Asset R4 based on season theme.

Daily benefits defined by seasonal configuration.

---

Kelas Detective

High tier seasonal pass.

Rewards

1 Set Asset R5 based on season theme.

Includes additional daily rewards.

---

LIFETIME PASS

Permanent account upgrade.

Benefits

2x Daily Mission rewards

2x Maximum MM daily cap

Example

Normal cap

10,000 MM

Lifetime pass

20,000 MM

---

SHOP SYSTEM

The shop sells assets based on currency type.

MM Shop

R1
R2
R3

PP Shop

R1
R2
R3
R4
R5

Robux Shop

Bundles
RoyalPass
Gift items

---

MONETIZATION DESIGN GOALS

Encourage cosmetic prestige.

Allow free players to progress.

Provide strong incentive for premium purchase.

Avoid pay-to-win mechanics.

Maintain long-term retention.







Economy System Architecture

Server system:

EconomySystem
 ├─ CurrencyManager
 ├─ RewardCalculator
 ├─ DailyMissionSystem
 ├─ DailyCheckInSystem
 ├─ RoyalPassSystem
 └─ ShopSystem
Currency Flow
Match Result
      │
RewardCalculator
      │
      ▼
MM Earned
      │
      ▼
EconomySystem
      │
      ▼
Player Wallet
Asset Economy Layer
AssetRegistry
 ├─ Equipment
 ├─ Cosmetic
 ├─ Skin
 ├─ Emote
 ├─ Title
 ├─ BoosterCard
 └─ Kawani
Monetization Loop

Ini yang membuat monetization kuat:

Player masuk lobby
        │
lihat player lain flex cosmetic
        │
klik profile
        │
lihat gallery item
        │
ingin item
        │
beli shop / royalpass
        │
flex di lobby

Ini sama dengan yang kamu desain di Flex Plaza.

Economy Balance

Dengan sistem kamu:

Daily Mission ≈ 5000 MM
Match Reward Max = 10000 MM
Total Potential = 15000 MM / hari

Jika pemain aktif.

Dengan Lifetime Pass:

MM cap = 20000
Daily Mission = 10000

Ini membuat pass terasa bernilai.


PASRAHPHOBIA — ECONOMY DATA STRUCTURE (SERVER SIDE)


PLAYER DATA MODEL

Each player has a single structured data profile stored on the server.

The profile contains currency, inventory, progression systems, and statistics.

Example PlayerData

PlayerData

UserId

Currencies
MM
PP

Progression
Level
EXP

Rank
Tier
Stars
MasterRank

Inventory
Equipment
Cosmetic
Skin
Emote
Title
BoosterCard
Kawani

RoyalPass
SeasonID
TierProgress
RewardsClaimed

DailySystems
DailyMissionProgress
DailyCheckInDay
DailyMMEarned

Statistics
TotalGames
SoloWinrate
TeamWinrate
FavoriteTool

Profile
TitleEquipped
BorderEquipped
GalleryItems




Folder Structure Integration

Ini akan masuk ke folder yang sudah ada di project kamu.

src/ServerScriptService/Server/DataPersistence

Modules:

PlayerData
EconomyData
InventoryData
RankData
Player Data Example

Contoh data real yang disimpan server.

PlayerData = {

UserId = 12345678,

Currencies = {
MM = 4500,
PP = 120
},

Progression = {
Level = 14,
EXP = 3240
},

Rank = {
Tier = "Balita_2",
Stars = 2,
MasterRank = 0
},

Inventory = {
Equipment = {"EMFDetector"},
Cosmetic = {"GhostCape"},
Skin = {"GoldenEMF"},
Emote = {"GhostDance"},
Title = {"Season1Hunter"},
BoosterCard = {},
Kawani = {"SpiritCat"}
},

RoyalPass = {
SeasonID = 1,
TierProgress = 12,
RewardsClaimed = {1,2,3,4}
},

DailySystems = {
DailyMissionProgress = 2,
DailyCheckInDay = 4,
DailyMMEarned = 3500
},

Statistics = {
TotalGames = 186,
SoloWinrate = 54,
TeamWinrate = 61,
FavoriteTool = "KotakArwah"
},

Profile = {
TitleEquipped = "Detective Genius",
BorderEquipped = "Season1Border",
GalleryItems = {"GoldenEMF","Season1Title","GhostCape"}
}

}
Economy Data Modules

Server system:

EconomySystem

Sub modules:

CurrencyManager
RewardCalculator
ShopTransaction
RoyalPassManager
DailyMissionManager
DailyCheckInManager
Inventory Storage Rule

Inventory tidak menyimpan full item data.

Yang disimpan hanya:

ItemID

Data item diambil dari:

shared/DataTypes

Contoh:

ItemID = "Skin_GoldenEMF"

Server lalu lookup:

AssetRegistry

Ini menghemat storage dan memudahkan balancing.

Currency Storage

Currency disimpan di:

PlayerData.Currencies

Example:

Currencies = {
MM = 10000,
PP = 450
}
Daily Limit Control

MM reward per hari dibatasi oleh:

PlayerData.DailySystems.DailyMMEarned

Jika mencapai:

10000 MM

Reward berhenti.

Jika pemain punya Lifetime Pass:

Limit = 20000
Data Saving Flow
Player Join
      │
Load PlayerData
      │
Session Cache
      │
Game Systems Update Data
      │
Player Leave
      │
Save DataStore
Server Session Cache

Data pemain disimpan sementara di memory server.

Example:

Sessions[UserId] = PlayerData

Ini memudahkan akses sistem lain.

System Integration

Economy Data dipakai oleh:

EconomySystem
RankedSystem
ProfileSystem
LobbySystem
ShopSystem
RoyalPassSystem
Security Rules

Client tidak boleh:

menambah currency

memberi item

mengubah inventory

Semua transaksi hanya lewat:

Server EconomySystem


PASRAHPHOBIA — ECONOMY BALANCE SHEET

1. CURRENCY SYSTEM

Game menggunakan tiga currency.

MM = Coin Biasa
PP = Premium Coin
Robux = Roblox Currency

2. RARITY SYSTEM

R1 = B-ajah
R2 = B-Lebih
R3 = Lumayan
R4 = Langka
R5 = Gagah

3. RARITY ACCESS

MM → R1–R3
PP → R1–R5
Robux → R1–R5

4. ITEM TYPES

Asset categories:

Equipment
Item
Cosmetic
Skin
Emote
Title
Booster Card
Kawani

5. DAILY CHECK-IN SYSTEM

Loop 7 hari.

Day1 = MM 1000
Day2 = MM 1000
Day3 = MM 1000
Day4 = Random Asset
Day5 = MM 1500
Day6 = MM 1500
Day7 = Random Asset
Day4 Drop Rate
R1 = 80%
R2 = 20%
Day7 Drop Rate
R1 = 60%
R2 = 30%
R3 = 10%

6. DAILY MISSION

Setiap hari:

3 Mission

Reward:

1 Mission = 1000 MM
All Mission = 2000 MM bonus

Total maksimal:

5000 MM

7. MATCH REWARD

Reward berbasis performa.

1% score = 10 MM
Win Reward
Score > 50%
Lose Reward
Score < 50%

8. DAILY MM CAP

Max reward per hari:

10.000 MM

9. ROYAL PASS

Season berlangsung:

30 Hari
Kelas Dukun

Reward:

Season Asset Set R4

Benefit:

daily reward

seasonal cosmetic

Kelas Detective

Reward:

Season Asset Set R5

Benefit:

premium cosmetic

exclusive items

10. LIFETIME PASS

Benefit:

2x Daily Mission
2x Max MM


08_LOBBY_SYSTEM
   - Lobby Social Hub
   - Player Profile System
   - Flex System
   - Gift System


		PASRAHPHOBIA — FINAL LOBBY SYSTEM SPECIFICATION


FINAL LOBBY SYSTEM SPECIFICATION

OVERVIEW

The LobbySocialHub is the central social environment of PASRAHPHOBIA.

It is designed to encourage player interaction, cosmetic showcasing, team formation, and system access before entering investigation matches.

Players remain inside a single shared map environment with no internal teleportation between zones.

All lobby interactions occur through physical movement inside the environment.

---

LOBBY DESIGN PRINCIPLE

The lobby acts as a social horror hub where players gather between matches.

Core objectives

Encourage social interaction.

Promote cosmetic visibility.

Provide access to game systems.

Maintain immersive horror atmosphere.

---

LOBBY MAP STRUCTURE

The lobby map consists of a central plaza surrounded by themed buildings.

Central Area

Spawn Plaza

Surrounding Buildings

Team Finder Hall
Equipment Shop
Flex Plaza
Hall of Fame
Training Room

Each building represents a functional system.

Players walk into the building to access the system.

No teleportation is used within the lobby.

---

SPAWN SYSTEM

All players spawn in the central plaza.

Spawn strategy ensures that players immediately see other players when entering the lobby.

This increases social interaction and cosmetic visibility.

Spawn rules

Central spawn point.

No random spawn positions.

---

TEAM FINDER AREA

Purpose

Allow players to form investigation teams.

Features

Quick Match

Join Team Board

Party Invitation

Party size

Maximum 4 players.

Players can invite others directly from their profile.

---

FLEX PLAZA

Open social area where players can showcase cosmetics.

Players can

Use emotes.

Show equipped skins.

Display titles.

Interact with other players.

Flex visibility increases desire for cosmetic purchases.

---

EQUIPMENT SHOP

The shop building provides access to the ShopSystem.

Items available

Equipment

Cosmetics

Skins

Emotes

Booster Cards

Kawani companions

Shop currencies

MM

PP

Robux

---

HALL OF FAME

Leaderboard display area.

Displays

Top investigators.

Highest ranked players.

Season champions.

Leaderboard updates periodically.

This encourages competitive motivation.

---

TRAINING ROOM

Practice environment for new players.

Players can test investigation tools without danger.

Tools available

Kotak Arwah

Buku Terkutuk /

Bola Arwah / To'un

Gerakan Gaib

Jejak Energi / MEDOK

Suhu Membeku

Training room simulates ghost interaction events.

---

LOBBY INTERACTION SYSTEM

Environmental interactions exist throughout the lobby.

Examples

Sit on chairs.

Open doors.

Turn on radios.

Inspect objects.

These interactions increase immersion.

---

RANDOM LOBBY GHOST EVENTS

Occasional paranormal events occur inside the lobby.

Examples

Lights flicker.

Ghost shadow passes.

Whispers heard nearby.

These events create memorable moments.

They do not harm players.

---

VOICE CHAT SYSTEM

Roblox proximity voice chat is enabled.

Voice chat operates with a radius.

Players must be physically near each other to speak clearly.

This encourages players to gather in social areas.

---

DYNAMIC POPULATION SYSTEM

If player count in lobby is low, investigator NPCs appear.

NPC investigators simulate player presence.

NPCs walk around the lobby and perform idle behaviors.

NPCs disappear as real players join.

---

LOBBY MUSIC

Ambient horror background audio.

Music should feel mysterious but not stressful.

Goal

Relaxation between matches.

Maintain thematic atmosphere.

---

LOBBY SIZE

Lobby should allow players to explore the full area in approximately 30 to 60 seconds.

Avoid excessive map size.

Large maps reduce player interaction density.

---

PLAYER PROFILE INTERACTION

Players can click another player to open their profile card.

Profile card displays

Player level

Title

Bio

Winrate (optional)

Gallery showcase items

Flex border

Buttons

Add friend

Invite team

Gift item

---

OVERHEAD PLAYER DISPLAY

Above player characters the following information is shown

Level

Total games played

Title

Player name

Winrate is not displayed above the head.

---

PROFILE PRIVACY SYSTEM

Players may toggle winrate visibility.

If disabled

Winrate displays as "-".

---

GALLERY SHOWCASE

Each player may display three cosmetic items.

Gallery items appear inside the profile card.

Purpose

Allow players to showcase rare items.

Encourage cosmetic purchases.

---

GIFT SYSTEM

Players may gift cosmetic items to others.

Gift purchases use Robux.

Gift interaction occurs through the player profile window.

---

SOCIAL MONETIZATION LOOP

Lobby design supports cosmetic monetization.

Player sees another player with a rare item.

↓

Player inspects profile.

↓

Player sees gallery showcase.

↓

Player desires item.

↓

Player purchases cosmetic.

↓

Player flexes item in lobby.

---

LOBBY EXIT FLOW

Players enter investigation through the Matchmaking Hall.

Matchmaking hall contains matchmaking interaction zone.

Once a match is formed

TeleportService moves players to investigation server.

---

LOBBY SYSTEM MODULES

LobbySocialHub

LobbyInteractionSystem
PlayerPresenceSystem
PartySystem
ProfileSystem
ShopAccessSystem
MatchmakingZone

These modules control lobby functionality.








LOBBY ZONE MAP
            Hall of Fame
                 │
                 │
Training Room ─ Plaza ─ Equipment Shop
                 │
                 │
           Flex Plaza
                 │
                 │
         Team Finder Hall

Spawn point berada di Plaza tengah.

LOBBY SYSTEM FLOW
Player Join
    │
Load PlayerData
    │
Spawn Plaza
    │
Explore Lobby
    │
 ├─ Flex Plaza
 ├─ Shop
 ├─ Training
 ├─ Hall of Fame
 └─ Team Finder
    │
Join Match
    │
Teleport to Map
Folder Integration

Sesuai dengan project kamu:

src/ServerScriptService/Server/LobbySocialHub

Modules:

Buildings
Core
Interaction
PartySystem
PlayerPresence
Zones




PASRAHPHOBIA — FINAL LOBBY SYSTEM SPECIFICATION


FINAL LOBBY SYSTEM SPECIFICATION

OVERVIEW

The LobbySocialHub is the central social environment of PASRAHPHOBIA.

It is designed to encourage player interaction, cosmetic showcasing, team formation, and system access before entering investigation matches.

Players remain inside a single shared map environment with no internal teleportation between zones.

All lobby interactions occur through physical movement inside the environment.

---

LOBBY DESIGN PRINCIPLE

The lobby acts as a social horror hub where players gather between matches.

Core objectives

Encourage social interaction.

Promote cosmetic visibility.

Provide access to game systems.

Maintain immersive horror atmosphere.

---

LOBBY MAP STRUCTURE

The lobby map consists of a central plaza surrounded by themed buildings.

Central Area

Spawn Plaza

Surrounding Buildings

Team Finder Hall
Equipment Shop
Flex Plaza
Hall of Fame
Training Room

Each building represents a functional system.

Players walk into the building to access the system.

No teleportation is used within the lobby.

---

SPAWN SYSTEM

All players spawn in the central plaza.

Spawn strategy ensures that players immediately see other players when entering the lobby.

This increases social interaction and cosmetic visibility.

Spawn rules

Central spawn point.

No random spawn positions.

---

TEAM FINDER AREA

Purpose

Allow players to form investigation teams.

Features

Quick Match

Join Team Board

Party Invitation

Party size

Maximum 4 players.

Players can invite others directly from their profile.

---

FLEX PLAZA

Open social area where players can showcase cosmetics.

Players can

Use emotes.

Show equipped skins.

Display titles.

Interact with other players.

Flex visibility increases desire for cosmetic purchases.

---

EQUIPMENT SHOP

The shop building provides access to the ShopSystem.

Items available

Equipment

Cosmetics

Skins

Emotes

Booster Cards

Kawani companions

Shop currencies

MM

PP

Robux

---

HALL OF FAME

Leaderboard display area.

Displays

Top investigators.

Highest ranked players.

Season champions.

Leaderboard updates periodically.

This encourages competitive motivation.

---

TRAINING ROOM

Practice environment for new players.

Players can test investigation tools without danger.

Tools available

Kotak Arwah

Buku Terkutuk

Bola Arwah

Gerakan Gaib

Jejak Energi

Suhu Membeku

Training room simulates ghost interaction events.

---

LOBBY INTERACTION SYSTEM

Environmental interactions exist throughout the lobby.

Examples

Sit on chairs.

Open doors.

Turn on radios.

Inspect objects.

These interactions increase immersion.

---

RANDOM LOBBY GHOST EVENTS

Occasional paranormal events occur inside the lobby.

Examples

Lights flicker.

Ghost shadow passes.

Whispers heard nearby.

These events create memorable moments.

They do not harm players.

---

VOICE CHAT SYSTEM

Roblox proximity voice chat is enabled.

Voice chat operates with a radius.

Players must be physically near each other to speak clearly.

This encourages players to gather in social areas.

---

DYNAMIC POPULATION SYSTEM

If player count in lobby is low, investigator NPCs appear.

NPC investigators simulate player presence.

NPCs walk around the lobby and perform idle behaviors.

NPCs disappear as real players join.

---

LOBBY MUSIC

Ambient horror background audio.

Music should feel mysterious but not stressful.

Goal

Relaxation between matches.

Maintain thematic atmosphere.

---

LOBBY SIZE

Lobby should allow players to explore the full area in approximately 30 to 60 seconds.

Avoid excessive map size.

Large maps reduce player interaction density.

---

PLAYER PROFILE INTERACTION

Players can click another player to open their profile card.

Profile card displays

Player level

Title

Bio

Winrate (optional)

Gallery showcase items

Flex border

Buttons

Add friend

Invite team

Gift item

---

OVERHEAD PLAYER DISPLAY

Above player characters the following information is shown

Level

Total games played

Title

Player name

Winrate is not displayed above the head.

---

PROFILE PRIVACY SYSTEM

Players may toggle winrate visibility.

If disabled

Winrate displays as "-".

---

GALLERY SHOWCASE

Each player may display three cosmetic items.

Gallery items appear inside the profile card.

Purpose

Allow players to showcase rare items.

Encourage cosmetic purchases.

---

GIFT SYSTEM

Players may gift cosmetic items to others.

Gift purchases use Robux.

Gift interaction occurs through the player profile window.

---

SOCIAL MONETIZATION LOOP

Lobby design supports cosmetic monetization.

Player sees another player with a rare item.

↓

Player inspects profile.

↓

Player sees gallery showcase.

↓

Player desires item.

↓

Player purchases cosmetic.

↓

Player flexes item in lobby.

---

LOBBY EXIT FLOW

Players enter investigation through the Matchmaking Hall.

Matchmaking hall contains matchmaking interaction zone.

Once a match is formed

TeleportService moves players to investigation server.

---

LOBBY SYSTEM MODULES

LobbySocialHub

LobbyInteractionSystem
PlayerPresenceSystem
PartySystem
ProfileSystem
ShopAccessSystem
MatchmakingZone

These modules control lobby functionality.








LOBBY ZONE MAP
            Hall of Fame
                 │
                 │
Training Room ─ Plaza ─ Equipment Shop
                 │
                 │
           Flex Plaza
                 │
                 │
         Team Finder Hall

Spawn point berada di Plaza tengah.

LOBBY SYSTEM FLOW
Player Join
    │
Load PlayerData
    │
Spawn Plaza
    │
Explore Lobby
    │
 ├─ Flex Plaza
 ├─ Shop
 ├─ Training
 ├─ Hall of Fame
 └─ Team Finder
    │
Join Match
    │
Teleport to Map
Folder Integration

Sesuai dengan project kamu:

src/ServerScriptService/Server/LobbySocialHub

Modules:

Buildings
Core
Interaction
PartySystem
PlayerPresence
Zones


09_AI_PIPELINE
    - AI Development Pipeline
    - Automated AI Code Generation


		You are an AI Super-Agent Orchestrator for game development.

Your task is to coordinate multiple specialized AI agents to design and generate the full system architecture and code plan for the Roblox game:

PASRAHPHOBIA

The output must be a complete technical instruction set for AI-assisted development.

--------------------------------------------------
SUPER-AGENT ROLE
--------------------------------------------------

You act as the Master Orchestrator controlling multiple AI specialists:

1. AI Architect
2. AI Gameplay Programmer
3. AI Multiplayer Engineer
4. AI Economy Designer
5. AI UI/UX Developer
6. AI Systems Engineer
7. AI QA Tester

Each agent is responsible for its own subsystem.

The orchestrator must coordinate their outputs into a single unified architecture.

--------------------------------------------------
PROJECT CONTEXT
--------------------------------------------------

PASRAHPHOBIA is a multiplayer horror investigation game on Roblox.

Players investigate haunted locations, collect paranormal evidence, identify ghost types, and survive ghost hunt events.

Players gather in a Social Hub lobby between matches.

The game supports:

• Solo play
• Multiplayer teams (max 4 players)
• Ranked mode
• Economy progression
• Cosmetic monetization
• Spectator gameplay with distortion mechanics

--------------------------------------------------
DEVELOPMENT PHASES
--------------------------------------------------

The AI system must organize the project into structured phases.

PHASE 1 — Architecture Design

Define the full system architecture.

PHASE 2 — System Modules

Define every system module required for gameplay.

PHASE 3 — Data Structures

Define player data models and persistence architecture.

PHASE 4 — Gameplay Mechanics

Define ghost AI behavior, investigation mechanics, and hunt logic.

PHASE 5 — Economy and Monetization

Define currencies, asset rarity, shop systems, and reward loops.

PHASE 6 — Social Systems

Define lobby systems, profile systems, and cosmetic showcase systems.

PHASE 7 — QA Validation

Verify system compatibility and architecture stability.

--------------------------------------------------
CHAIN OF THOUGHT STRUCTURE
--------------------------------------------------

The AI must internally execute the following reasoning process:

STEP 1 — ANALYSIS

Break the PASRAHPHOBIA game into major system domains:

Core Architecture
Lobby Systems
Match Systems
Gameplay Systems
Progression Systems
Economy Systems
Persistence Systems

Explain dependencies between them.

STEP 2 — AGENT TASK ASSIGNMENT

Assign responsibilities to each AI specialist.

Example:

AI Architect
Design global system architecture.

AI Gameplay Programmer
Design gameplay systems including ghost AI and evidence mechanics.

AI Multiplayer Engineer
Design matchmaking and server synchronization systems.

AI Economy Designer
Design the currency economy and reward systems.

AI UI Developer
Design player interfaces and lobby UI.

AI Systems Engineer
Define module interactions and event bus systems.

AI QA Tester
Validate architecture and detect design flaws.

STEP 3 — SYSTEM DRAFT

Generate the full PASRAHPHOBIA system specification including:

• Global System Architecture
• Folder Structure
• Match System
• Lobby System
• Ghost System
• Evidence System
• Spectator System
• Spectator Distortion Engine
• Rank System
• Economy System
• Player Data Model
• Data Persistence
• Security Model

STEP 4 — CROSS-SYSTEM INTEGRATION

Explain how systems interact.

Examples:

MatchSystem ↔ GhostSystem  
EconomySystem ↔ RewardCalculator  
LobbySystem ↔ ProfileSystem  
SpectatorSystem ↔ MatchLifecycle

STEP 5 — REVIEW

Before final output, verify:

• No missing systems
• No architectural conflicts
• No redundant systems
• Clear system dependencies
• AI-ready structure

--------------------------------------------------
STRICT CONSTRAINTS
--------------------------------------------------

The AI must obey the following rules:

• No generic explanations
• No filler text
• No repetition
• No unrelated advice
• Focus only on PASRAHPHOBIA systems

All explanations must be technical and structured.

--------------------------------------------------
OUTPUT FORMAT
--------------------------------------------------

The output must use structured Markdown:

# Major Sections
## Subsystems
Bullet Points
Tables
Code blocks

Example system map:

MatchSystem
 ├ MatchQueue
 ├ MatchBuilder
 ├ MatchInstance
 ├ MatchLifecycle
 └ TeleportService

Example folder structure:

src/
client/
server/
shared/
ReplicatedStorage/

--------------------------------------------------
FINAL SELF-CHECK
--------------------------------------------------

Before returning the final output the AI must confirm:

• Every PASRAHPHOBIA system is defined
• Architecture is logically consistent
• Systems connect properly
• The output is suitable for AI code generation
• The document is structured and readable

Return the final system design only after this validation.



You are a Senior Prompt Engineer and AAA Game Systems Architect.

Your task is to generate an extremely structured and comprehensive document titled:

PASRAHPHOBIA — AI-READY CODEX MASTER PROMPT (ULTRA COMPLETE)

This document will be used as the primary instruction set for AI coding agents (Codex / AI Game Development Agents) to build the entire PASRAHPHOBIA Roblox game architecture.

The output must be professional, technical, and optimized for AI-assisted development.

--------------------------------------------------
PERSONA
--------------------------------------------------

You are an expert in:

• Roblox Game Architecture
• Multiplayer System Design
• AI-assisted Software Development
• Lua / Roblox Server-Client Architecture
• Game System Engineering
• Modular Code Architecture
• Game Economy Design
• Horror Game Mechanics

Your responsibility is to produce a MASTER PROMPT that enables AI coding systems to implement the entire PASRAHPHOBIA project.

The output must read like a professional **Game Technical Design Document combined with an AI Instruction Manual**.

--------------------------------------------------
OBJECTIVE
--------------------------------------------------

Create a single ULTRA COMPLETE MASTER PROMPT that contains every instruction necessary for an AI coding agent to build the PASRAHPHOBIA system.

The document must include:

1. Full Project Overview
2. Global System Architecture
3. Folder Structure Specification
4. Server Architecture
5. Client Architecture
6. Match System Architecture
7. Game Phase State Machine
8. Lobby Social Hub System
9. Ghost System
10. Evidence System
11. Spectator System
12. Spectator Distortion Engine
13. Rank System
14. Economy & Monetization System
15. Player Data Model
16. Data Persistence Architecture
17. EventBus Communication Layer
18. Security Rules
19. Anti-Exploit Logic
20. AI Coding Execution Instructions

The final output must be optimized for AI coding agents to interpret and generate modular code.

--------------------------------------------------
CHAIN OF THOUGHT PROCESS
--------------------------------------------------

The AI must internally execute the following reasoning steps:

STEP 1 — ANALYSIS

Analyze the PASRAHPHOBIA game architecture and identify all required gameplay systems.

Break the project into logical development layers:

• Core Architecture
• Lobby Systems
• Match Systems
• Gameplay Systems
• Progression Systems
• Economy Systems
• Persistence Systems

Explain how these layers interact.

STEP 2 — DRAFT

Generate the complete AI-READY CODEX MASTER PROMPT.

This section must include:

A. SYSTEM OVERVIEW

Explain the purpose of the project and its gameplay loop.

B. FOLDER STRUCTURE

Define the complete project directory architecture.

Example:

src/
client/
server/
shared/
ReplicatedStorage/

C. SERVER SYSTEM MODULES

Define server-side modules such as:

GhostSystem
EvidenceSystem
MatchSystem
EconomySystem
RankedSystem
DataPersistence
AggressionSystem
HorrorDirector

D. CLIENT SYSTEM MODULES

Define client-side modules such as:

EvidenceTools
SpectatorSystem
GhostRenderer
UI Systems
SoundSystem

E. MATCH SYSTEM

Define the match lifecycle and matchmaking architecture.

F. GAME STATE MACHINE

Define the official match states:

Waiting
Starting
Preparation
Investigation
Hunt
Extraction
Results
Completed

G. LOBBY SOCIAL HUB

Explain lobby zones and social systems:

Team Finder
Flex Plaza
Equipment Shop
Hall of Fame
Training Room

H. GHOST SYSTEM

Define ghost AI architecture including:

Ghost personality system
Behavior matrix
Aggression system
Hunt triggers

I. EVIDENCE SYSTEM

Define the Indonesian evidence tools:

Kotak Arwah
Buku Terkutuk
Bola Arwah
Gerakan Gaib
Jejak Energi
Suhu Membeku

J. SPECTATOR SYSTEM

Define spectator behavior:

Camera follows alive players
Voice chat communication
No hint system

K. SPECTATOR DISTORTION ENGINE

Define probability model:

60% Fake Ghost
30% Uncertain Event
10% Real Ghost

L. RANK SYSTEM

Define the tier system including:

Bayi
Balita
Anak-Anak
Remaja
Dewasa
Profesional
Detektive
Sang Ahli

M. ECONOMY SYSTEM

Currencies:

MM
PP
Robux

Asset rarities:

R1 – B-ajah
R2 – B-Lebih
R3 – Lumayan
R4 – Langka
R5 – Gagah

Include:

Daily missions
Daily check-in
RoyalPass
Lifetime pass

N. PLAYER DATA STRUCTURE

Define PlayerData model.

O. DATA PERSISTENCE

Explain DataStore saving system.

P. EVENT BUS

Explain inter-system communication architecture.

Q. SECURITY MODEL

Define server authority rules.

STEP 3 — REVIEW

Before producing the final answer the AI must review its output.

Check for:

• Missing systems
• Inconsistent architecture
• Repetition
• Non-technical explanations
• Unstructured output

Then refine the result.

--------------------------------------------------
STRICT CONSTRAINTS
--------------------------------------------------

The AI must obey these rules:

• No vague explanations
• No filler text
• No repetition
• No general advice
• Focus only on PASRAHPHOBIA architecture
• Every system must be clearly defined
• All sections must be technically structured

The document must be optimized for **AI development workflows**.

--------------------------------------------------
OUTPUT FORMAT
--------------------------------------------------

The output must use **clean Markdown formatting**.

Required formatting:

# Section Titles

## Subsections

Bullet Points

Tables for system structures

Code blocks for architecture diagrams

Example:
src/ServerScriptService/Server/MatchSystem
MatchBuilder
MatchLifecycle
MatchInstance
MatchQueue
TeleportService


The document must be highly readable and modular.

--------------------------------------------------
FINAL VALIDATION (SELF CHECK)
--------------------------------------------------

Before returning the final answer, verify:

1. All PASRAHPHOBIA systems are included
2. Architecture is logically structured
3. Systems connect properly
4. Document is optimized for AI code generation
5. Output follows Markdown structure

Only after validation provide the final MASTER PROMPT document.

Return the final result only after completing the internal review.



PASRAHPHOBIA — AI DEVELOPMENT PIPELINE
1. PIPELINE PURPOSE

AI Development Pipeline digunakan untuk:

semi-autonomous game development
AI assisted coding
systematic architecture generation

Pipeline memastikan AI bekerja berurutan dan terstruktur.

2. AI DEVELOPMENT STAGES

Pipeline terdiri dari beberapa tahap.

Stage 1 — Architecture Analysis
Stage 2 — System Design
Stage 3 — Module Generation
Stage 4 — Integration
Stage 5 — Debugging
Stage 6 — Optimization
3. STAGE 1 — ARCHITECT AI

Tugas:

Define system architecture
Define dependencies
Define folder structure

Output:

System blueprint
Service dependency map
4. STAGE 2 — SYSTEM DESIGN AI

Tugas:

Design each subsystem
Define logic rules
Create module specifications

Example:

GhostSystem
EvidenceSystem
MatchSystem
SpectatorSystem
5. STAGE 3 — CODE GENERATION AI

Tugas:

Generate Lua modules
Generate service scripts
Generate client scripts

Example:

GhostAI
MatchLifecycle
EvidenceEngine
6. STAGE 4 — INTEGRATION AI

AI menghubungkan semua module.

Tasks:

connect EventBus
connect ServiceRegistry
validate dependencies
7. STAGE 5 — QA AI

AI melakukan debugging.

Checks:

logic errors
system conflicts
memory leaks
8. STAGE 6 — OPTIMIZATION AI

AI mengoptimalkan performa.

Tasks:

server load balancing
AI behavior optimization
memory reduction
9. PIPELINE EXECUTION FLOW
Architect AI
   ↓
System Design AI
   ↓
Code Generation AI
   ↓
Integration AI
   ↓
QA AI
   ↓
Optimization AI



PASRAHPHOBIA — AUTOMATED AI CODE GENERATION
1. PURPOSE

Automated AI Code Generation memungkinkan AI menghasilkan code secara modular.

Tujuan:

accelerate development
reduce human coding workload
maintain architecture consistency
2. CODE GENERATION STRUCTURE

AI menghasilkan code berdasarkan folder structure.

Example:

src/ServerScriptService/Server/GhostSystem
src/ServerScriptService/Server/MatchSystem
src/ServerScriptService/Server/EvidenceSystem

Setiap folder berisi module Lua.

3. MODULE GENERATION RULES

Setiap module harus:

single responsibility
event-driven
modular
service compatible

Example module:

GhostAI.lua
MatchLifecycle.lua
EvidenceEngine.lua
4. SERVICE REGISTRATION

Semua system harus didaftarkan.

Example:

ServiceRegistry:Register("GhostSystem")
ServiceRegistry:Register("MatchSystem")
ServiceRegistry:Register("EconomySystem")
5. EVENT BUS COMMUNICATION

AI harus menggunakan EventBus untuk komunikasi.

Example:

EventBus:Emit("GhostSpawned")
EventBus:Emit("PlayerDied")
EventBus:Emit("EvidenceFound")
6. AI CODE SAFETY RULES

AI tidak boleh:

hardcode values
duplicate modules
bypass server authority

Semua logic harus server authoritative.

7. CLIENT / SERVER SEPARATION

AI harus memisahkan code.

Server:

GhostAI
MatchSystem
EconomySystem

Client:

UI
GhostRenderer
EvidenceTools
SpectatorCamera
8. MATCH GENERATION FLOW

AI harus menghasilkan logic berikut:

MatchQueue
 ↓
MatchBuilder
 ↓
MatchInstance
 ↓
MatchLifecycle
 ↓
TeleportPlayers
9. AI DEBUGGING LOOP

AI harus melakukan self-check.

Checklist:

system dependency valid
events connected
modules registered
no duplicate logic
10. FINAL OUTPUT STRUCTURE

AI harus menghasilkan code sesuai struktur:

src
 ├ client
 ├ server
 ├ shared
 └ ReplicatedStorage
 
 
 
 10_FINAL_REFERENCE
    - Final system specifications
    - Complete project blueprint
	
	
			Remaining Critical Blueprints
1️⃣ Match Lifecycle Blueprint (Very Important)

This defines exactly how a match runs from start to finish.

Without this, systems like:

GhostSystem

EvidenceSystem

ContractSystem

TeleportService

won’t know when they should activate.

Example flow:

Lobby
↓
Contract Selected
↓
MatchQueue
↓
MatchCreated
↓
TeleportPlayers
↓
PreparationPhase
↓
InvestigationPhase
↓
HuntEvents
↓
ExtractionPhase
↓
Results
↓
ReturnToLobby

This blueprint connects:

MatchSystem
GamePhaseSystem
ContractSystem
TeleportService

2️⃣ Hunt Algorithm Blueprint (Extremely Important)

The hunt system is the heart of a horror investigation game.

This blueprint defines:

when hunts start
how ghost selects target
how players survive
how hunt ends

Example logic:

If Aggression > 70
AND AverageSanity < 40
Roll HuntChance

Also defines:

hunt cooldown
hunt duration
ghost speed
line-of-sight detection

3️⃣ Sanity & Fear Formula Blueprint

Right now we defined sanity conceptually, but not the exact formulas.

This blueprint defines:

sanity drain per second
sanity drain near ghost
sanity drain during events
fear intensity scaling

Example:

SanityDrain =
BaseDrain
+ DarknessModifier
+ GhostProximityModifier
+ EventModifier

4️⃣ Ghost Spawn Algorithm

Defines:

how ghost chooses favorite room
how room activity increases
when ghost changes room

Uses:

RoomGraph
RoomSpawnRules
RoomActivity

5️⃣ Difficulty Scaling System

This is important for Ranked Mode.

Defines how difficulty 1–10 affects:

ghost aggression
sanity drain
hunt frequency
evidence clarity
event frequency

Example:

Difficulty 3
AggressionMultiplier = 0.8

Difficulty 8
AggressionMultiplier = 1.5

6️⃣ Economy Reward Algorithm

Defines exactly how rewards are calculated.

Example:

BaseReward
+ EvidenceBonus
+ DifficultyMultiplier
+ ContractBonus
+ SurvivalBonus
Optional (But Very Powerful)

These are advanced systems that dramatically increase replayability.

Dynamic Ghost Personality Engine

Ghost personalities:

Shy
Aggressive
Wanderer
Stalker
Trickster

This makes same ghost type behave differently each match.

Audio Horror Engine

Controls:

whispers
footsteps
directional ghost sounds
heartbeat effects

Very important for immersion.

Tension Curve System (Horror Director)

Controls pacing:

calm phase
rising tension
peak scare
cooldown

Prevents matches from feeling boring or chaotic.







# MASTER DOCUMENTATION — PASRAHPHOBIA
Version: 1.0

PASRAHPHOBIA adalah game horror investigation multiplayer di Roblox.

Game ini menggunakan **server authoritative modular architecture**.

Semua gameplay logic berjalan di server.

Client hanya menangani:

UI
Audio
Visual
Player Input

---

# 0. CONTEXT BRIEF

PASRAHPHOBIA adalah game investigasi horor kooperatif.

Pemain menyelidiki lokasi berhantu untuk mengidentifikasi jenis ghost menggunakan evidence tools.

Game mendukung:

Solo play
Multiplayer (max 4 player)

Core loop gameplay:

Join Game
↓
Spawn Lobby
↓
Form Party
↓
Select Contract
↓
Start Match
↓
Investigate Location
↓
Collect Evidence
↓
Survive Hunt
↓
Extract
↓
Receive Rewards
↓
Return to Lobby

---

# 1. GLOSSARY

Ghost Room  
Ruangan utama tempat ghost sering muncul.

Evidence  
Bukti paranormal untuk identifikasi ghost.

Hunt  
Fase ketika ghost mengejar player.

Sanity  
Nilai mental player (0-100).

Aggression  
Nilai kemarahan ghost (0-100).

MatchInstance  
Instance investigasi pada server.

HorrorDirector  
System yang mengontrol pacing horror.

EventBus  
Communication system antar service.

ServiceRegistry  
Global registry untuk semua system server.

---

# 2. GLOBAL ARCHITECTURE

Server menggunakan **modular service architecture**.

Bootstrap
↓
ServiceRegistry
↓
EventBus
↓
Gameplay Systems
↓
Match Systems
↓
Lobby Systems

Semua system server berada di:

src/ServerScriptService/Server

---

# 3. SERVER BOOTSTRAP ARCHITECTURE

Server startup sequence:

Load Config
↓
Initialize EventBus
↓
Register Services
↓
Start Services

Bootstrap adalah entry point server.

---

# 4. SYSTEM FACTORY MAP

Server bootstrap membuat sistem dengan lifecycle:

Create
Init
Start

System di-load dari:

src/ServerScriptService/Server/Core/Bootstrap/SystemLoader

Contoh:

MatchSystem
GhostSystem
EvidenceSystem
SpectatorSystem
HorrorDirector
SanitySystem
AggressionSystem

Meta systems:

ProfileSystem
InventorySystem
EconomySystem
ProgressionSystem
RankedSystem

Persistence:

DataPersistenceService

---

# 5. SERVICE DEPENDENCY MATRIX

Tier 1 — Core

EventBus
ConfigLoader
ServiceRegistry

Tier 2 — Persistence

DataPersistenceService
PlayerData
EconomyData
InventoryData
RankData

Tier 3 — Player

ProfileSystem
ProgressionSystem
RankedSystem

Tier 4 — Lobby

LobbySocialHub
PartySystem
ContractSystem

Tier 5 — Match

MatchQueue
MatchBuilder
MatchInstance
MatchLifecycle
TeleportService
GamePhaseSystem

Tier 6 — Gameplay

GhostSystem
EvidenceSystem
SanitySystem
AggressionSystem
InvestigationSystem

Tier 7 — Advanced

HorrorDirector
GhostModifierSystem
MapInteractionSystem
MapEventSystem

---

# 6. REPOSITORY STRUCTURE

## Server

src/ServerScriptService/Server

MatchSystem
GhostSystem
EvidenceSystem
SpectatorSystem
HorrorDirector
SanitySystem
AggressionSystem

Meta systems:

EconomySystem
InventorySystem
ProfileSystem
DataPersistenceService
LobbySocialHub

---

# 7. CODE INDEX

Core Systems

src/ServerScriptService/Server/MatchSystem  
src/ServerScriptService/Server/GhostSystem  
src/ServerScriptService/Server/EvidenceSystem  
src/ServerScriptService/Server/SpectatorSystem  
src/ServerScriptService/Server/HorrorDirector  
src/ServerScriptService/Server/SanitySystem  
src/ServerScriptService/Server/AggressionSystem  

Meta Systems

src/ServerScriptService/Server/EconomySystem  
src/ServerScriptService/Server/InventorySystem  
src/ServerScriptService/Server/ProfileSystem  
src/ServerScriptService/Server/DataPersistenceService  
src/ServerScriptService/Server/LobbySocialHub  

---

# 8. FILE ROLE MAP

Setiap system menggunakan struktur:

Main.lua  
Service.lua  
Controller.lua  
State.lua  

Main.lua  
Initialize system

Service.lua  
Core logic

Controller.lua  
EventBus handlers

State.lua  
Runtime state

---

# 9. MATCH SYSTEM

MatchSystem mengontrol lifecycle match.

Modules:

MatchQueue
MatchBuilder
MatchInstance
MatchLifecycle
TeleportService

Match flow:

Lobby
↓
Matchmaking
↓
Match Created
↓
Players Teleported
↓
Investigation

---

# 10. MATCH STATE MACHINE

Waiting
↓
Preparation
↓
Investigation
↓
Hunt
↓
Extraction
↓
Results
↓
Completed

---

# 11. GHOST SYSTEM

Ghost AI menggunakan state machine.

States:

Idle
Roaming
Interaction
Manifestation
Hunt

Ghost aggression range:

0-100

Hunt trigger:

Aggression > threshold  
AND  
AverageSanity < threshold

---

# 12. GHOST AI BEHAVIOR MATRIX

Ghost behavior parameters:

Aggression Level
Roaming Frequency
Interaction Frequency
Hunt Trigger Sensitivity
Evidence Bias
Fear Presence

Contoh:

Ghost: Pocong

Aggression: Low
Roaming: Low
Interaction: Medium

---

# 13. EVIDENCE SYSTEM

Evidence types:

Bola Arwah
Buku Terkutuk
Gerakan Gaib
Jejak Energi
Kotak Arwah
Suhu Membeku

Evidence harus diverifikasi server.

Evidence yang ditemukan satu player dibagikan ke tim.

---

# 14. INVESTIGATION SYSTEM

InvestigationSystem menyimpan evidence yang ditemukan.

Journal menggunakan deduction algorithm:

Load Ghost List
↓
Filter by Evidence
↓
Remove invalid ghosts
↓
Remaining ghosts = candidates

---

# 15. SANITY SYSTEM

Range:

0-100

Sanity berkurang karena:

Darkness
Ghost proximity
Paranormal events
Hunt

Sanity rendah meningkatkan aggression.

---

# 16. AGGRESSION SYSTEM

Range:

0-100

Aggression meningkat karena:

Player dekat ghost room
Low sanity
Paranormal events
Time in investigation

Aggression tinggi meningkatkan hunt probability.

---

# 17. HORROR DIRECTOR

HorrorDirector mengontrol pacing horror.

Jika game terlalu tenang:

Increase events

Jika terlalu intens:

Reduce event frequency

Contoh events:

Door slam
Light flicker
Ghost manifestation
Audio disturbance

---

# 18. SPECTATOR SYSTEM

Ketika player mati:

Player → Spectator Mode

SpectatorDistortionSystem:

Fake Ghost → 60%
Uncertain Event → 30%
Real Ghost → 10%

Spectator tidak bisa memberi hint pasti.

---

# 19. ECONOMY SYSTEM

Reward pipeline:

MatchSystem
↓
EventBus MatchEnded
↓
RewardSystem
↓
EconomySystem
↓
ProgressionSystem
↓
RankedSystem

Reward berasal dari:

Match completion
Evidence discovery
Daily missions
RoyalPass
Daily check-in

---

# 20. INVENTORY SYSTEM

Inventory menyimpan:

playerItems
cosmeticOwnership
equipmentSlots
unlockedItems

Inventory terintegrasi dengan:

EconomySystem
ShopSystem
CosmeticSystem
DataPersistenceService

---

# 21. RANK SYSTEM

Rank tiers:

Bayi
Balita
Anak-Anak
Remaja
Dewasa
Profesional
Detektive
Sang Ahli

Rank progression menggunakan star system.

Win → +1 star  
Loss → −1 star  

Promotion terjadi ketika star requirement terpenuhi.

Rank terakhir:

Sang Ahli

Menggunakan victory counter.

---

# 22. LOBBY SYSTEM

LobbySocialHub mengontrol interaksi pemain di lobby.

Features:

Party system
Profile inspection
Cosmetic display
Contract selection

Lobby juga berisi:

Shop
Training
Leaderboard
Daily reward

---

# 23. EVENT BUS

Semua system berkomunikasi menggunakan EventBus.

Contoh events:

MatchStarted
MatchEnded
EvidenceCollected
PlayerSanityChanged
GhostSpawned
HuntTriggered
PlayerDied
CurrencyEarned
RewardGranted

Direct system calls harus dihindari.

---

# 24. AI DEVELOPMENT RULES

AI agents harus mengikuti aturan berikut:

1. Jangan overwrite file stabil.
2. Gunakan EventBus untuk komunikasi.
3. Gunakan ServiceRegistry untuk dependency.
4. Ikuti struktur Main / Service / Controller / State.
5. Jangan membuat system baru di luar blueprint.

---

# 25. FINAL SYSTEM OBJECTIVE

Tujuan arsitektur PASRAHPHOBIA:

Modular
Scalable
AI-friendly
Replayable
Psychologically intense

Game harus mampu berkembang dengan:

New ghosts
New maps
New modifiers
New gameplay systems

---

# 26. PLAYER ONBOARDING LOOP

Urutan onboarding pemain yang sudah diverifikasi di branch `final-source-of-truth`:

Lobby  
Open Room Browser  
Buat Room  
Mulai Permainan  
Preparation / Staging  
Investigation  
Hunt  
Results  
Kembali ke Lobby

Pemain baru harus bisa menyelesaikan loop dasar berikut:

1. masuk room sendiri dari lobby
2. review objective dan field kit
3. dekati room target
4. kumpulkan evidence
5. survive hunt
6. simpulkan ghost

---

# 27. FIELD KIT EVIDENCE RULE

Evidence untuk identifikasi ghost tidak boleh di-lock dari payload gagal sementara.

Aturan HUD yang benar:

- evidence lock hanya boleh ikut jika response valid
- nested `result.evidenceType` boleh dipakai hanya saat response valid atau `already_collected`
- response gagal seperti `tool_pending_delay` tidak boleh membuat HUD menampilkan evidence seolah-olah sudah pasti

Contoh jalur Pocong yang sudah lolos smoke:

- `SCAN -> MEDOK`
- `THERMO -> Suhu`
- `WRITING -> BukuTerkutuk`

---

# 28. MOBILE-FIRST SINGLEPLAYER SMOKE NOTES

Smoke live `2026-04-16` menegaskan:

- room browser landscape mobile sudah full-fit
- CTA quest berubah ke `MISSION`
- countdown / staging tampil
- hunt overlay tampil
- cue sensory utama hidup:
  - light flicker
  - object throw
  - ghost whisper
  - writing scratch

---

# 29. HAUNTEDHOUSE RUNTIME SYNC LOCK (2026-04-16)

Status terkunci berdasarkan owner-approved edit:

- sumber edit visual: `Workspace.HauntedHouse_Review`
- sinkron aktif: `ServerStorage.Maps.HauntedHouse.HauntedHouse` + `ReplicatedStorage.Maps.HauntedHouse.HauntedHouse`
- `OutdoorMainFloor` khusus `HauntedHouse` dihapus sesuai instruksi owner
- boundary `HauntedHouse` menggunakan footprint rumah + staging saja
- blocker pohon realistis disejajarkan ke empat sisi boundary untuk mencegah pemain keluar map

---

# 30. VISUAL BATCH T27 INVITE POPUP COMPACT (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- `InvitePopup` kini memiliki lane `compact` dan `extra-compact` berdasarkan viewport.
- ukuran popup, area teks, dan tombol `TERIMA/TOLAK` dipadatkan agar hierarchy tetap jelas pada mobile pendek.
- tidak ada perubahan logic invite flow/runtime, sesuai lock visual-only.

---

# 31. VISUAL BATCH T28 PASSWORD MODAL COMPACT (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- `PasswordModal` kini memiliki lane `compact` dan `extra-compact` berdasarkan viewport.
- ukuran `PasswordCard`, title/input, dan tombol `JOIN ROOM/BATAL` dipadatkan agar tetap terbaca di mobile pendek.
- tidak ada perubahan logic join/password/runtime, sesuai lock visual-only.

---

# 32. VISUAL BATCH T29 KICK NOTICE COMPACT (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- `KickNoticeModal` kini memiliki lane `compact` dan `extra-compact` berdasarkan viewport.
- ukuran `KickNoticeCard`, blok pesan, dan tombol `OK` dipadatkan agar alert tetap jelas di mobile pendek.
- tidak ada perubahan logic kick handling/runtime, sesuai lock visual-only.

---

# 33. VISUAL BATCH T30 COUNTDOWN OVERLAY COMPACT (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- `CountdownOverlay` mendapat tuning compact pada `CountdownLabel` dan tombol `CancelCountdown`.
- ukuran/posisi angka countdown serta tombol cancel dipadatkan untuk viewport mobile pendek.
- tidak ada perubahan logic countdown/start-flow/runtime, sesuai lock visual-only.

---

# 34. VISUAL BATCH T31 INLINE KICK PASSWORD ROW COMPACT (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- baris host control inline `SetPassword` dan `Kick` kini punya dimensi field/tombol khusus lane extra-compact.
- placeholder field dipersingkat pada lane extra-compact agar tetap terbaca di viewport pendek.
- tidak ada perubahan logic host controls/kick/password/runtime, sesuai lock visual-only.

---

# 35. VISUAL BATCH T32 JOIN PASSWORD COMPACT (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- field `JoinPassword` mendapat tuning tinggi field di lane compact/extra-compact.
- placeholder `JoinPassword` dipersingkat pada lane extra-compact agar tetap terbaca.
- tidak ada perubahan logic join-room/password/runtime, sesuai lock visual-only.

---

# 36. VISUAL BATCH T33 ACTION STACK COMPACT (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- block action stack (`Queue`, `Quick Classic`, `Quick Ranked`, `Refresh`, `Create Room`) dipadatkan untuk lane compact/extra-compact.
- tinggi tombol, jarak antar row, dan text-size extra-compact dituning agar block aksi tetap jelas di viewport pendek.
- tidak ada perubahan logic matchmaking/room actions/runtime, sesuai lock visual-only.

---

# 37. VISUAL BATCH T34 INVITE DROPDOWN COMPACT (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- `InviteDropdown` kini memakai tinggi dropdown dan offset vertikal yang responsif pada lane compact/extra-compact.
- canvas height compact ikut menyesuaikan tinggi dropdown agar konten invite tidak terpotong.
- tidak ada perubahan logic invite/matchmaking/runtime, sesuai lock visual-only.

---

# 38. VISUAL BATCH T35 PREVIEW PLAYER CARD COMPACT (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- kartu pemain pada `Room Preview` dipadatkan untuk lane compact/extra-compact (ukuran card, viewport avatar, dan area teks).
- lane extra-compact memakai truncation nama/status serta grid padding yang lebih rapat agar tidak overflow.
- tidak ada perubahan logic data pemain/room preview/runtime, sesuai lock visual-only.

---

# 39. VISUAL BATCH T36 PREVIEW HEADER COMPACT (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- header `Room Preview` (`Title` dan `Info`) dipadatkan untuk lane compact/extra-compact.
- text-size dan truncation `Info` dituning agar ringkasan host/mode/player/status tetap terbaca di viewport pendek.
- tidak ada perubahan logic room preview/runtime, sesuai lock visual-only.

---

# 40. VISUAL BATCH T37 PREVIEW PLAYER LIST COMPACT (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- `RoomPreviewPlayersList` mendapat tuning scrollbar dan padding internal untuk lane compact/extra-compact.
- `RoomPreviewPlayersTitle` dituning text-size + truncation pada lane extra-compact agar header list lebih ringkas.
- tidak ada perubahan logic room preview/player runtime, sesuai lock visual-only.

---

# 41. VISUAL BATCH T38 MAP PREVIEW STRIP COMPACT (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- strip `Map Preview` (`Mood`, `Stats`, `Footer`) dipadatkan pada lane extra-compact.
- ukuran elemen dan truncation text dituning agar copy strip tetap terbaca tanpa overflow di viewport pendek.
- tidak ada perubahan logic map preview/runtime, sesuai lock visual-only.

---

# 42. VISUAL BATCH T39 ROOM LIST ROW COMPACT (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- row daftar room mendapat `UIPadding` adaptif untuk lane compact/extra-compact.
- alignment teks row multi-line dituning agar host/status lebih mudah discan pada viewport pendek.
- tidak ada perubahan logic room select/join/runtime, sesuai lock visual-only.

---

# 43. VISUAL BATCH T40 ROOM LIST DENSITY POLISH (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- `RoomList` pada lane extra-compact memakai scrollbar lebih tipis agar area list lebih efisien di viewport pendek.
- gap antar row dan radius sudut row extra-compact dipadatkan untuk ritme scan daftar room yang lebih rapat.
- tidak ada perubahan logic room select/join/runtime, sesuai lock visual-only.

---

# 44. VISUAL BATCH T41 ROOM LIST ROW MICRO DENSITY TRIM (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- tinggi row daftar room lane extra-compact dipadatkan tipis agar lebih banyak row terlihat tanpa scroll berlebih.
- padding internal row extra-compact (`top/bottom/right`) dipangkas untuk ritme scan daftar room yang lebih rapat.
- tidak ada perubahan logic room select/join/runtime, sesuai lock visual-only.

---

# 45. VISUAL BATCH T42 ROOM LIST HORIZONTAL SPACE RECLAIM (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- row daftar room lane extra-compact memakai inset horizontal lebih tipis agar area copy per row lebih lega.
- padding kiri/kanan row extra-compact serta gap antar row list dipadatkan untuk densitas informasi yang lebih baik.
- tidak ada perubahan logic room select/join/runtime, sesuai lock visual-only.

---

# 46. VISUAL BATCH T43 ROOMBROWSER STATUS HEADER COMPACT TRIM (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- baris status header RoomBrowser lane extra-compact dipadatkan (tinggi + text-size) untuk hierarchy yang lebih stabil di viewport pendek.
- truncation status diaktifkan khusus lane extra-compact agar pesan panjang tidak overflow.
- tidak ada perubahan logic room select/join/runtime, sesuai lock visual-only.

---

# 47. VISUAL BATCH T44 ROOMBROWSER TAB STRIP VERTICAL COMPACT (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- baris tab mode (`Classic / All / Ranked`) lane extra-compact dinaikkan tipis agar ruang konten bawah lebih lega.
- gap horizontal antar tab lane extra-compact dipadatkan untuk ritme kontrol header yang lebih rapat.
- tidak ada perubahan logic mode selection/room flow/runtime, sesuai lock visual-only.

---

# 48. VISUAL BATCH T45 ROOMBROWSER CONTENT STACK VERTICAL TRIM (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- jarak vertikal dari tab-strip ke area konten lane extra-compact dipadatkan tipis agar komposisi panel lebih rapat.
- tinggi action-stack lane extra-compact dipangkas ringan untuk menambah ruang efektif list/preview di viewport pendek.
- tidak ada perubahan logic mode selection/room flow/runtime, sesuai lock visual-only.

---

# 49. VISUAL BATCH T46 ROOMBROWSER ACTION LANE TRANSITION TRIM (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- jarak transisi vertikal dari room-list ke action lane lane extra-compact dipadatkan tipis.
- bottom-gap list serta anchor offset action lane extra-compact dipangkas agar ritme vertikal panel lebih menyatu.
- tidak ada perubahan logic mode selection/room flow/runtime, sesuai lock visual-only.

---

# 50. VISUAL BATCH T47 ROOMBROWSER ACTION COLUMN GAP COMPACT (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- gap horizontal antar tombol pasangan di action lane extra-compact dipadatkan untuk ritme kontrol yang lebih rapat.
- lebar tombol pasangan dihitung ulang mengikuti gap baru agar komposisi kolom aksi tetap seimbang.
- tidak ada perubahan logic mode selection/room flow/runtime, sesuai lock visual-only.

---

# 51. VISUAL BATCH T48 ROOMBROWSER JOIN PASSWORD ANCHOR TRIM (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- offset vertikal `JoinPassword` terhadap baris `Queue` di lane extra-compact dipadatkan tipis agar grup input+aksi lebih menyatu.
- tinggi field tidak berubah; penyesuaian hanya pada anchor positioning untuk hierarchy aksi yang lebih jelas.
- tidak ada perubahan logic mode selection/room flow/runtime, sesuai lock visual-only.

---

# 52. VISUAL BATCH T49 ROOMBROWSER PREVIEW PLAYERLIST TOP GAP TRIM (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- jarak vertikal dari `Map Preview` ke `Room Preview PlayersList` pada lane extra-compact dipadatkan tipis.
- anchor `PlayersList` dinaikkan ringan sementara anchor title pemain dipertahankan, untuk pemakaian ruang vertikal yang lebih efisien.
- tidak ada perubahan logic room preview/player data/runtime, sesuai lock visual-only.

---

# 53. VISUAL BATCH T50 ROOMBROWSER PREVIEW PLAYERLIST HEIGHT RECLAIM (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- anchor atas `Room Preview PlayersList` lane extra-compact dipadatkan tipis lanjutan untuk ritme section yang lebih rapat.
- inset bawah list lane extra-compact dipangkas ringan agar tinggi viewport list pemain sedikit bertambah.
- tidak ada perubahan logic room preview/player data/runtime, sesuai lock visual-only.

---

# 54. VISUAL BATCH T51 ROOMBROWSER PREVIEW PLAYERLIST BOTTOM INSET MICRO TRIM (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- inset bawah `Room Preview PlayersList` lane extra-compact dipadatkan tipis lanjutan untuk reclaim tinggi list pemain.
- hierarchy section tetap dipertahankan; perubahan hanya pada density viewport list.
- tidak ada perubahan logic room preview/player data/runtime, sesuai lock visual-only.

---

# 55. VISUAL BATCH T52 ROOMBROWSER PREVIEW PLAYERLIST TOP GAP MICRO TRIM (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- top-gap `Room Preview PlayersList` lane extra-compact dipadatkan tipis lanjutan agar section preview lebih rapat.
- anchor title pemain tetap dipertahankan sehingga hierarchy label tetap stabil.
- tidak ada perubahan logic room preview/player data/runtime, sesuai lock visual-only.

---

# 56. VISUAL BATCH T53 ROOMBROWSER MAP FOOTER COMPACT TRIM (2026-04-26)

Batch visual-only lanjutan untuk RoomBrowser:

- tinggi footer `Map Preview` lane extra-compact dipadatkan tipis agar blok preview lebih ringkas.
- typography footer dipertahankan; perubahan hanya pada bounds untuk ritme vertikal section yang lebih rapat.
- tidak ada perubahan logic room preview/map data/runtime, sesuai lock visual-only.


# PASRAHPHOBIA — CANONICAL SPECIFICATIONS v2.0

**Last Updated:** 2026-04-16 | Session 7 — StudioMMNineteen Runtime Alignment  
**Purpose:** Authoritative reference for ALL game specifications  
**Source:** Synchronized from 23 GDD files + project documentation

**⚠️ AI & DEVELOPERS:** This document is the SINGLE SOURCE OF TRUTH. All conflicting information in other files must defer to this specification.

## 2026-04-26 Addendum - Runtime Spawn Authority + Visual-Only Lane Lock

- Runtime spawn source-of-truth untuk 4 map canonical dikunci ke authored path:
  - `ServerStorage.Maps.<Map>.<Map>.Runtime.PreparationStagingRuntime.PreparationSpawnArea`
- Hardcoded fallback/recreate otomatis untuk spawn tidak boleh dipakai.
- Runtime wajib fail-fast jika authored preparation spawn / entry door / boundary runtime tidak ada.
- Boundary anti-staging untuk ghost dan trigger by-door tetap wajib ada di semua map canonical.
- Eksekusi lane aktif saat ini untuk scope UI/GUI/UX adalah visual-only:
  - tidak membuat sistem baru
  - tidak membuat gameplay/economy architecture baru
  - hanya polishing visual, readability, hierarchy, dan consistency.
- Referensi visual mentah wajib untuk lane ini:
  - `asset mentah/ref ui/*.html`
  - translasi referensi HTML ke Roblox ScreenGui/Frame hanya di visual layer (tanpa penambahan logic sistem baru).

## 2026-04-26 Addendum - Visual Batch T6 Panel Hierarchy Alignment

- `ProfileUI` canonical visual lane now explicitly tracks snapshot states for:
  - Rank/EXP context
  - Daily Quest
  - Daily Check-In
  - Daily Spin
  - Inventory/Gacha status
  - PP hidden-gems cap messaging (`maks 3 PP coin per hari`) in visual copy lane
- `RoyalPassUI` canonical wording/hierarchy is aligned to:
  - `Daily Check-In` lane
  - `Daily Quest` lane
  - daily spin/gacha context in visual copy only
- This addendum is visual presentation alignment only and does not introduce new progression systems, new economy systems, or new runtime architecture.

## 2026-04-26 Addendum - Visual Batch T7 Hidden Gems + Daily Lane Clarity

- Hidden gems cap messaging is standardized in visual lanes (`ShopUI`, `PASRA_UI`, results footer) using existing snapshot payloads.
- If `ppBreakdown` contains hidden gems entries, visual copy may show progress `x/3`; if absent, fallback copy remains cap-only.
- `DailyRewardZone` and lobby daily-entry button wording now explicitly reflect daily check-in/spin context.
- This addendum remains visual-only and does not add new reward systems, cap logic, or server-side progression flows.

## 2026-04-26 Addendum - Visual Batch T8 Wallet + Gacha Micro-State

- `Lobby Panel` and `Quick Menu` visual lanes now expose wallet MM/PP micro-state plus daily/check-in/hidden/gacha snapshot context for faster readability.
- `ShopUI` visual copy now includes gacha snapshot detail (`owned/equipped`) and standardized hidden gems compact/progress state.
- Additional UI attributes for main menu/shop lanes are stamped for visual QA traceability only.
- This addendum remains presentation-only and does not introduce new purchasing logic, progression logic, or backend state.

## 2026-04-26 Addendum - Visual Batch T9 Mobile Readability

- Mobile/compact wording for `Lobby Panel`, `Quick Menu`, and `ShopUI` is shortened to keep canonical micro-state readable in narrow viewports.
- Lobby/menu sizing/text tuning for compact lanes is adjusted to reduce overflow risk when daily/gacha/hidden state strings are active.
- This addendum remains visual-only and does not alter runtime logic, reward logic, or persistence state.

## 2026-04-26 Addendum - Visual Batch T10 Footer Compaction

- Mobile footer lane for `Quick Menu` and `ShopUI` is compacted to reduce density while preserving canonical meaning.
- Desktop lanes retain full detail copy for explanatory clarity.
- This addendum remains visual-only and does not change economy, entitlement, or progression logic.

## 2026-04-26 Addendum - Visual Batch T11 Shop Mobile Layout Stability

- `ShopUI` mobile lane now has increased panel headroom and footer spacing to prevent overlap between title/filter/content/footer regions on compact viewports.
- `ShopUI` mobile `ContentFrame` positioning and size are rebalanced to keep category lists readable after footer compaction changes from T10.
- Mobile text sizing for `ShopUI` filter, secondary, and footer labels is tuned down for stability and readability on narrow resolutions.
- This addendum remains visual-only and does not introduce new shop systems, currency systems, or runtime gameplay logic.

## 2026-04-26 Addendum - Visual Batch T12 Profile + RoyalPass Mobile Stability

- `ProfileUI` and `RoyalPassUI` mobile lanes now reserve larger footer spacing so footer lines do not overlap with dynamic content.
- `ProfileUI` and `RoyalPassUI` mobile `ContentFrame` size/offset are rebalanced to maintain clear header-content-footer hierarchy on compact viewports.
- Mobile text sizing for profile/royalpass secondary and footer labels is tuned for readability stability in narrow resolutions.
- This addendum remains visual-only and does not introduce new progression systems, economy systems, or runtime gameplay logic.

## 2026-04-26 Addendum - Visual Batch T13 Leaderboard Mobile Clarity

- `LeaderboardUI` mobile lane receives dedicated text-size tuning for primary/secondary/footer labels to keep snapshot copy readable under dense states.
- `LeaderboardUI` mobile content/action/footer spacing is rebalanced to reduce lower-panel crowding and improve visual hierarchy.
- This addendum remains visual-only and does not alter rank calculation logic, progression logic, or runtime gameplay systems.

## 2026-04-26 Addendum - Visual Batch T14 MainMenu Mobile Stack Density

- `MainMenuUI` mobile compact lane now has dedicated stack rhythm tuning (row gap, button height, footer spacing) for narrow-height screens.
- Main menu action button text sizes are tuned in compact mobile mode to preserve readability under dense vertical composition.
- This addendum remains visual-only and does not alter menu flow logic, system architecture, or runtime gameplay behavior.

## 2026-04-26 Addendum - Visual Batch T15 PASRA + Journal Mobile Readability

- `PASRA_UI` mobile lane now has dedicated footer reserve and content-frame balance to protect readability for dense snapshot text.
- `JournalUI` mobile lane now has tuned content-frame and scan strip (`ToolActionButton`/`ToolStatusLabel`) spacing to avoid overlap.
- Secondary/footer mobile typography for both panels is tuned for compact viewport stability.
- This addendum remains visual-only and does not alter evidence logic, result logic, or runtime gameplay systems.

## 2026-04-26 Addendum - Visual Batch T16 Spectator Mobile Stability

- `SpectatorUI` mobile lane now has dedicated footer reserve and content-frame balance to keep spectator/distortion text readable in compact viewports.
- Secondary/footer mobile typography for spectator panel is tuned to reduce overflow risk.
- This addendum remains visual-only and does not alter spectator behavior logic, match state logic, or runtime gameplay systems.

## 2026-04-26 Addendum - Visual Batch T17 Mobile Header Control Consistency

- Mobile header rhythm for auxiliary panels is normalized (badge/title/subtitle alignment) to keep panel hierarchy consistent across compact viewports.
- Mobile close/float controls are tuned for clearer tap targets and text readability.
- This addendum remains visual-only and does not alter gameplay logic, economy logic, or runtime systems.

## 2026-04-26 Addendum - Visual Batch T18 Basic Header Compact Rhythm

- `MainMenuUI` and `LeaderboardUI` mobile lanes now apply compact-header profile for title/close/status-badge sizing when viewport height is tight.
- `LeaderboardUI` mobile action button typography is tuned specifically for compact readability.
- This addendum remains visual-only and does not alter gameplay logic, economy logic, or runtime systems.

## 2026-04-26 Addendum - Visual Batch T19 Lobby + Match Compact Typography

- `LobbyUI` compact lanes now use tighter action-button/badge typography to preserve readability in short-height mobile viewports.
- `MatchUI` compact lanes now tune hide/close/footer typography to reduce lower-panel crowding.
- This addendum remains visual-only and does not alter match flow logic, evidence logic, or runtime systems.

## 2026-04-26 Addendum - Visual Batch T20 RoomBrowser Extra Compact Mobile

- RoomBrowser now has an extra-compact mobile visual lane for short-height non-wide viewport profiles.
- Header/tab/action/list typography in this lane is tuned down to reduce density while preserving readability.
- This addendum remains visual-only and does not alter room browser logic, matchmaking logic, or runtime systems.

## 2026-04-26 Addendum - Visual Batch T21 RoomBrowser Host Controls Compact

- RoomBrowser host-room control lane (mode/map/password/invite/ready/start/cancel/leave) now has extra-compact typography tuning for short-height mobile profiles.
- Host-room labels and dropdown option typography are tuned to reduce control-panel crowding.
- This addendum remains visual-only and does not alter room browser logic, matchmaking logic, or runtime systems.

## 2026-04-26 Addendum - Visual Batch T22 RoomBrowser Preview + Countdown Compact

- RoomBrowser extra-compact lane now tunes map-preview typography and visual density (title/label/chip/stats/footer/glyph) for short-height mobile viewports.
- Float/countdown overlay controls are compacted in the same lane for better readability balance.
- This addendum remains visual-only and does not alter room browser logic, matchmaking logic, or runtime systems.

## 2026-04-26 Addendum - Visual Batch T23 Results + HUD Compact Mobile

- A compact mobile HUD lane is applied to short-height viewports for results and bottom HUD controls.
- Results typography plus timer/quick-action/hint controls are tuned to reduce overflow and lower-screen crowding.
- This addendum remains visual-only and does not alter gameplay logic, economy logic, or runtime systems.

## 2026-04-26 Addendum - Visual Batch T24 RoomBrowser Player Card Extra Compact

- RoomBrowser room-preview player cards now apply extra-compact sizing/typography adjustments for short-height mobile profiles.
- Card viewport and label density are reduced to preserve readability without clipping.
- This addendum remains visual-only and does not alter room browser logic, matchmaking logic, or runtime systems.

## 2026-04-26 Addendum - Visual Batch T25 RoomBrowser List Density Trim

- RoomBrowser extra-compact mode tabs are tightened (height/gap) to preserve vertical room.
- Room list rows in this lane now prioritize single-line scannability with truncation and horizontal padding.
- This addendum remains visual-only and does not alter room browser logic, matchmaking logic, or runtime systems.

## 2026-04-26 Addendum - Visual Batch T26 RoomBrowser Invite List Extra Compact

- RoomBrowser invite dropdown now applies explicit extra-compact row typography/sizing for short-height mobile profiles.
- Invite list spacing/scrollbar and row truncation are tuned for faster scan and reduced clipping risk.
- This addendum remains visual-only and does not alter invite logic, matchmaking logic, or runtime systems.

## 2026-04-18 Addendum - Ghost Asset Source Of Truth Lock

- Ghost asset source of truth is now explicitly:
  - local folder `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\GHOST`
  - local CSV `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\[ASSETID]\Models & Packages.csv`
- For ghost visuals, old hardcoded ghost asset IDs in code must be replaced by the owner-imported asset IDs from that CSV.
- Wrong `Leak` CSV row `dark+armored+knight+more+spikey (129878813436863)` is invalid and must not be used.
- Canonical base ghost asset IDs for this branch are:
  - `Pocong=123151303766691`
  - `Kuntilanak=93357688576883`
  - `Genderuwo=117009327297852`
  - `Tuyul=108895029067567`
  - `Leak=99042834683066`
  - `Banaspati=91700421463863`
  - `Jerangkong=78522466547915`
  - `WeweGombel=115717855449052`
  - `Palasik=107658913093426`
  - `SilumanUlar=93238005114915`
  - `SundelBolong=77251173218842`
  - `HantuTanah=79247394068873`
- Canonical runtime-ready aggressive / event variants already approved for the existing naming lane are:
  - `BanaspatiAggressive=117153307100171`
  - `GenderuwoAggressive=138432330933642`
  - `KuntilanakAggressive=118867381731250`
  - `LeakAggressive=115214614318321`
  - `PalasikAngry=95122370433014`
  - `SundelBolongAggressive=113356865728207`
- No new variant switching system may be introduced for ghost visuals. Only the current canonical base slots and the existing aggressive-suffix runtime lane may be used.

## 2026-04-18 Addendum - Lobby Visual Donor Source Of Truth

- `LobbySocialHub` remains the authoritative play-entry lobby and runtime spawn is expected near `1610, 3.47, -10`.
- The richer lobby seen during play is not represented by the current low-detail/blockout `src/Workspace/Maps/LobbySocialHub/LobbySocialHub.model.json` alone.
- Authoritative donor for lobby visual recovery is:
  - `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\LobbySocialHub\MainHubDecorRuntime.rbxm`
- Comparison-only donor is:
  - `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\LobbySocialHub\MainHubDecorRuntime2.rbxm`
- `MainHubDecorRuntime2.rbxm` differs mainly in `TrainingGhostVisual` pose/rig payload from the client-view export and must not replace the authoritative donor by default.
- The following files are not authoritative whole-lobby sources and must not be promoted wholesale:
  - `LobbySocialHub_EditMode.rbxm`
  - `LobbySocialHub_RuntimeReference(F5 Test - Client View).rbxm`
  - `LobbySocialHub_RuntimeReference(F5 test - ServerView).rbxm`
- Promotion rule for lobby recovery:
  - keep the clean lobby container/source lane for core map structure
  - promote only the approved donor visual layer from `MainHubDecorRuntime.rbxm`
  - do not promote legacy playtest containers such as `SpawnPoints`, `Rooms`, `GhostSpawns`, `EvidenceSpawnNodes`, or other full-runtime lobby folders from F5 exports
- Source implementation lock for this branch:
  - `src/Workspace/Maps/LobbySocialHub/LobbySocialHub.rbxm` is now the authoritative lobby source file
  - `src/Workspace/Maps/LobbySocialHub/LobbySocialHub.model.json.disabled` is retained only as disabled legacy blockout reference
- `MainHubDecorRuntime.rbxm` is approved because it carries the richer plaza/building decor layer without carrying whole-lobby legacy containers or script modules.

---

## **1. EVIDENCE TYPES (6 TOTAL)**

### **Indonesian Names (Display)**

| # | Name Indonesian | Name English | Code Reference | Detection Method |
|---|-----------------|--------------|----------------|------------------|
| 1 | MEDOK | Electromagnetic Disturbance | MEDOK | Jejak Energi scanner shows strong anomaly |
| 2 | Suhu | Freezing Signature | Suhu | Thermometer detects ghost-room temperature drop |
| 3 | Buku Terkutuk | Cursed Writing | BukuTerkutuk | Buku Terkutuk records paranormal writing |
| 4 | To'un | Orb/Trace Manifestation | To'un | Bola Arwah tool detects visual anomaly |
| 5 | Suara | Spirit Voice | Suara | Kotak Arwah receives direct ghost response |
| 6 | Pengganggu | Disturbance Movement | Pengganggu | Gerakan Gaib sensor detects motion interference |

**Evidence Tool Detection Ranges:**
```lua
MEDOK_Range = {min = 8, max = 12} -- studs
Suara_Range = {min = 6, max = 10}
Suhu_Range = {min = 5, max = 8}
Toun_Range = {min = 3, max = 6}
BukuTerkutuk_Range = {min = 6, max = 10}
Pengganggu_Range = {min = 8, max = 12}

GhostInteractionRadius = 5 -- studs
```

**Evidence Clarity by Difficulty:**
- Easy: 100% clarity (evidence easy to find)
- Medium: 75% clarity
- Hard: 50% clarity
- Nightmare: 25% clarity (very rare spawns)

---

## **2. INVESTIGATION TOOLS (10 TOTAL)**

### **Bilingual Tool List**

| # | Indonesian Display Name | English Code Name | Function | Type | Default Loadout |
|---|-------------------------|-------------------|----------|------|-----------------|
| 1 | Detektor MEDOK | EMF Reader | Detect electromagnetic fields (1-5) | Handheld | ✅ YES |
| 2 | Termometer Suhu | Thermometer | Measure temperature | Digital Display | ✅ YES |
| 3 | Buku Terkutuk Kosong | Ghost Writing Book | Ghost writes messages | Placed Item | NO |
| 4 | Kamera To'un | UV Camera / Spirit Orb Camera | Capture orbs, reveal UV evidence | Instant Camera | NO |
| 5 | Kotak Suara | Spirit Box | Voice communication with ghost | Walkie-Talkie | NO |
| 6 | Sensor Pengganggu | Motion Sensor | Detect movement when placed | Tripod Device | NO |
| 7 | Senter | Flashlight | Primary light source (toggle F key) | Built-in | ✅ YES |
| 8 | Garam | Salt | Detect ghost footsteps (tracks left in salt) | Consumable | NO |
| 9 | Salib | Crucifix | Prevent hunt in range (3 uses) | Protective Item | NO |
| 10 | Dupa | Smudge Stick | Temporary ghost repellent, sanity boost | Consumable | NO |

**Tool Visual Source Of Truth (Base Runtime Slots):**
- `JejakEnergi -> 121559455873224`
- `KotakArwah -> 80024667585179`
- `SuhuMembeku -> 106744635077484`
- `BukuTerkutuk -> 123135502718934`
- `BolaArwah -> 80883221689326`
- `GerakanGaib -> 109093713235033`
- `Garam -> 117103968659967`
- `PilSanity -> 135462688002407`
- `Salib -> 128686833722709`
- `Dupa -> 128740632500448`
- `Flashlight -> 127298509562779`
- Rarity/support/state variants remain preserved in the imported pool, but the current runtime lane must lock exactly one base asset per tool slot until the rarity/content lane is implemented.
- Imported base tool templates are now synced into `ReplicatedStorage.Assets.Models.Tools`; runtime and source both carry the same canonical base-slot tool models for the current gameplay lane.

**Tool Unlock Progression:**
```
Level 1: Senter, Detektor MEDOK, Termometer Suhu (default loadout)
Level 5: Kotak Suara
Level 10: Kamera To'un
Level 15: Buku Terkutuk Kosong
Level 20: Sensor Pengganggu
Level 25: Garam, Salib, Dupa (consumables)
```

---

## **3. CURRENCY SYSTEM (3 TYPES)**

| Currency Code | Full Name | Display Name | Usage | Source | Wallet Cap |
|---------------|-----------|--------------|-------|--------|------------|
| **MM** | M-Money | MM | Main shop currency | Match completion, daily missions | 1,000,000 |
| **PP** | Premium Points | PP | Premium currency | Purchased with Robux | 50,000 |
| **Robux** | Robux | Robux | Platform currency | Real money purchase | N/A |

**Exchange Rates:**
- 1 PP = 100 MM (conversion available in shop)
- Robux → PP conversion (set by developer in shop)

**Earning Sources:**
```
MM (M-Money):
- Match completion (100-500 MM based on difficulty)
- Daily missions (50-200 MM)
- Daily check-in (25-100 MM)
- Classic mode rewards

PP (Premium Points):
- Robux purchase only
- RoyalPass premium tier rewards
- Special event rewards (rare)

Robux:
- Real money purchase through Roblox platform
```

---

## **4. RARITY SYSTEM (5 TIERS)**

### **Indonesian Rarity Names**

| Tier | Code | Indonesian Name | English Equivalent | Color Code | Drop Rate |
|------|------|-----------------|-------------------|------------|-----------|
| R1 | Common | B-ajah | Common | Grey | 60% |
| R2 | Uncommon | B-Lebih | Uncommon | Green | 25% |
| R3 | Rare | Lumayan | Rare | Blue | 10% |
| R4 | Epic | Langka | Epic | Purple | 4% |
| R5 | Legendary | Gagah | Legendary | Gold | 1% |

**Rarity applies to:**
- Cosmetics (skins, outfits, emotes)
- Tool skins
- Profile borders
- Titles
- RoyalPass rewards

---

## **5. GHOST TYPES (12 TOTAL - INDONESIAN FOLKLORE)**

### **Master Ghost List**

| # | Name | Type Category | Aggression Base | Evidence Set (3 from 6) | Behavior Notes | Phase 7 Priority |
|---|------|---------------|-----------------|-------------------------|----------------|------------------|
| 1 | Pocong | Shrouded Ghost | Low (20-40) | MEDOK, Suhu, Buku Terkutuk | Floating, slow movement | **HIGH** |
| 2 | Kuntilanak | Wailing Spirit | Medium (40-60) | Suara, To'un, Pengganggu | Female spirit, long hair, crying sound | **HIGH** |
| 3 | Genderuwo | Shadow Figure | High (60-80) | MEDOK, Pengganggu, Suhu | Aggressive, muscular shadow | **HIGH** |
| 4 | Tuyul | Imp | Low (20-40) | To'un, Suara, Buku Terkutuk | Small entity, childlike, steals items | MEDIUM |
| 5 | Leak | Witch Spirit | Medium (50-70) | Suara, MEDOK, Pengganggu | Shapeshifter, can mimic sounds | MEDIUM |
| 6 | Banaspati | Fire Spirit | High (65-85) | Suhu, To'un, MEDOK | Elemental, temperature spikes | MEDIUM |
| 7 | Jerangkong | Skeleton | Medium (45-65) | Buku Terkutuk, Pengganggu, To'un | Undead, bone rattling sounds | MEDIUM |
| 8 | Wewe Gombel | Child Snatcher | Medium (50-70) | Suara, Suhu, Buku Terkutuk | Female spirit, targets players near children's rooms | LOW |
| 9 | Palasik | Head Entity | High (60-80) | To'un, Pengganggu, Suara | Flying head, detached from body | LOW |
| 10 | Siluman Ular | Snake Spirit | Medium (55-75) | MEDOK, Suhu, To'un | Shapeshifter, snake-like movement | LOW |
| 11 | Sundel Bolong | Hollow Back | Medium (50-70) | Buku Terkutuk, To'un, Suara | Female spirit, hollow back visible | LOW |
| 12 | Hantu Tanah | Earth Ghost | Low (30-50) | Suhu, MEDOK, Pengganggu | Territorial, bound to specific room | LOW |

**Phase 7 Implementation Order:**
1. **Priority HIGH:** Pocong, Kuntilanak, Genderuwo (implement first with full models/animations)
2. **Priority MEDIUM:** Tuyul, Leak, Banaspati, Jerangkong (Phase 7-8, can use placeholder models initially)
3. **Priority LOW:** Others (Phase 8-9, post-launch content additions)

**Ghost AI Parameters (Map-Specific):**
```
Map                  | Roaming Radius | Hunt Detection Range
---------------------|----------------|---------------------
StudioMMNineteen     | 20-25 studs    | 22-26 studs
EmptyBuilding        | 25-30 studs    | 28-32 studs
HauntedHouse         | 25-32 studs    | 30 studs
AbandonedPalace      | 35-45 studs    | 40 studs
```

---

## **6. MAPS (5 TOTAL)**

### **Master Map Specifications**

| Map Name | Type | Size (studs) | Floors | Total Area | Rooms | Ghost Spawn Points | Difficulty |
|----------|------|--------------|--------|------------|-------|-------------------|------------|
| LobbySocialHub | Social Lobby | 420×420 | 1 | 176,400 studs² | N/A | 0 (test zones only) | N/A |
| AbandonedPalace | Investigation | 180×180 | 1 | 32,400 studs² | 18-25 | 5-7 | Large/Hard |
| HauntedHouse | Investigation | 160×180 | 2 | 57,600 studs² (28,800 per floor) | 20 | 6 | Medium |
| EmptyBuilding | Investigation | 100×100 | 2 | 20,000 studs² (10,000 per floor) | 10-14 | 5-7 | Medium-Small |
| StudioMMNineteen | Investigation | 100×100 | 3 | 30,000 studs² (10,000 per floor) | 12 | 6 | Medium-Small |

**Map Size Categories:**
- Small: 80-100 studs (solo/duo friendly)
- Medium: 120-150 studs (2-3 players recommended)
- Large: 160-200 studs (4 players recommended)
- Hub: 350-450 studs (lobby/social area)

**HauntedHouse Runtime Canonical (2026-04-16):**
- Floor 1 rooms: `Foyer`, `DiningRoom`, `Bathroom1`, `StairHall`, `LaundryRoom`, `Bathroom2`, `Kitchen`, `Pantry`, `LivingRoom`, `Garage`
- Floor 2 rooms: `HallwayMain`, `Bathroom3`, `Bedroom1`, `ClosetA`, `Bedroom2`, `LinenCloset`, `Bedroom3`, `ClosetB`, `Bathroom4`, `BonusRoom`
- Preparation phase uses outside-house staging via `Runtime.PreparationStagingRuntime.PreparationSpawnArea` (`4` prep spawn nodes) and `SafeZone_1..2`
- Legacy investigation-map `SpawnPoints` are removed; runtime spawn source is `PreparationSpawnArea`
- Timer-based preparation countdown is disabled; investigation begins when `Door_FrontEntry` is opened
- Required HauntedHouse runtime object coverage: `Doors=18`, `Lights=20`, `Props=20`, `Electronics=7`, `Windows=6`, `EvidenceSpawnNodes=14`, `GhostSpawns=6`
- Environmental event targets must resolve to either an imported map asset or a generated runtime fallback so `LightFlicker`, `TV/Radio`, `ObjectMove/ObjectThrow`, and `WindowKnock` never bind to a missing target

**StudioMMNineteen Runtime Canonical (2026-04-16):**
- Floor 1 rooms: `FrontPorch`, `LivingRoom`, `LaundryRoom`, `StairHallL1`
- Floor 2 rooms: `Kitchen`, `DiningArea`, `Bathroom`, `StairHallL2`
- Floor 3 rooms: `UpperHall`, `Bedroom1`, `Bedroom2`, `StairHallL3`
- Preparation phase uses outside-house staging via `Runtime.PreparationStagingRuntime.PreparationSpawnArea` (`4` prep spawn nodes) and `SafeZone_1..2`
- Legacy investigation-map `SpawnPoints` are removed; runtime spawn source is `PreparationSpawnArea`
- Timer-based preparation countdown is disabled; investigation begins when `Door_FrontEntry` is opened
- Required StudioMMNineteen runtime object coverage: `Doors=10`, `Lights=12`, `Props=12`, `Electronics=6`, `Windows=6`, `EvidenceSpawnNodes=12`, `GhostSpawns=6`

**EmptyBuilding Runtime Canonical (2026-04-16):**
- Floor 1 rooms: `Lobby`, `SecurityRoom`, `Storage`, `ElectricalRoom`, `OfficeA`, `OfficeB`, `Bathroom1`, `StaircaseNorth`, `StaircaseSouth`
- Floor 2 rooms: `WorkspaceOpen`, `MeetingRoom`, `ServerRoom`, `ArchiveRoom`, `Bathroom2`
- Preparation phase uses outside-entry staging via `Runtime.PreparationStagingRuntime.PreparationSpawnArea` (`4` prep spawn nodes) and `SafeZone_1..2`
- Legacy investigation-map `SpawnPoints` are removed; runtime spawn source is `PreparationSpawnArea`
- Timer-based preparation countdown is disabled; investigation begins when `Door_Lobby` is opened
- Required EmptyBuilding runtime object coverage: `Doors=14`, `Lights=14`, `Props=14`, `Electronics=6`, `Windows=12`, `EvidenceSpawnNodes=9`, `GhostSpawns=5`
- Structural decor requirement for this map: `RuntimeDecor` must include staircase/ladder access to floor 2 and sensible filler props to avoid empty-space drift

**AbandonedPalace Runtime Canonical (2026-04-16):**
- Floor 1 rooms: `GrandHall`, `RoyalCorridor`, `DiningHall`, `Library`, `GuestRoomA`, `GuestRoomB`, `GuestRoomC`, `ServantRoomA`, `ServantRoomB`, `ServantRoomC`, `Basement`, `Courtyard`, `Armory`, `Chapel`, `Ballroom`, `Observatory`, `StorageWing`, `CeremonyRoom`
- Preparation phase uses outside-entry staging via `Runtime.PreparationStagingRuntime.PreparationSpawnArea` (`4` prep spawn nodes) and `SafeZone_1..2`
- Legacy investigation-map `SpawnPoints` are removed; runtime spawn source is `PreparationSpawnArea`
- Timer-based preparation countdown is disabled; investigation begins when `Door_GrandHall` is opened
- Required AbandonedPalace runtime object coverage: `Doors=18`, `Lights=18`, `Props=18`, `Electronics=6`, `Windows=6`, `EvidenceSpawnNodes=14`, `GhostSpawns=5`

**Lobby Layout (LobbySocialHub 420×420):**
``` 
Orientation:
- Center: Main Hub (MatchQueue, Spawn Point)
- North (+Y): Evidence Test Building (70×70 studs)
- East (+X): Shop Building (60×60 studs)
- West (-X): Party Zone (~110 studs from center)
- South (-Y): Social Garden (100×100 studs)
- South-East: Flex Zone Building (60×60 studs)

Path Width: 12 studs (connects all zones)
Ceiling Height: 28 studs
Lobby Ceiling Clearance: 28 studs
```

**Lobby Visual Recovery Rule (2026-04-18):**
- If lobby visual parity drifts again, inspect/promote `asset mentah\LobbySocialHub\MainHubDecorRuntime.rbxm` first.
- Use `MainHubDecorRuntime2.rbxm` only as a comparison reference when `TrainingGhostVisual` specifically needs richer pose data.
- Do not use whole `LobbySocialHub_RuntimeReference(F5...)` exports as direct replacement sources because they carry playtest-built runtime state.

---

## **7. GAME MODES & DIFFICULTY**

### **CLASSIC MODE (Casual Play)**

**Features:**
- 1-4 Players
- Random balanced difficulty (no set tiers)
- Does NOT affect ranked tier/progression
- Can play solo or with friends

**Rewards:**
- MM (M-Money) currency
- XP for player level progression
- RoyalPass progression points

**Difficulty Scaling:**
- System auto-balances based on party size and average player level
- No named difficulty tiers (e.g., "Easy/Medium/Hard" not exposed to player)
- Server-side dynamic adjustment for fair gameplay

---

### **RANKED MODE (Competitive Play)**

**Features:**
- Affects rank tier progression
- Matchmaking based on rank + skill
- Star-based progression system
- Dynamic difficulty calculation

**Difficulty Formula:**
```lua
DifficultyScore = (PlayerLevel / 10) + RankTierWeight

RankTierWeight:
Bayi        → 1
Balita      → 2
Anak-Anak   → 3
Remaja      → 4
Dewasa      → 5
Profesional → 6
Detektive   → 7
Sang Ahli   → 8
```

**Difficulty Affects:**
- Ghost aggression multiplier
- Sanity drain rate
- Hunt trigger threshold (aggression + sanity combination)
- Evidence clarity percentage

**Rewards:**
- Rank Points (star progression)
- MM currency (higher than Classic)
- Season rewards (exclusive cosmetics)
- Leaderboard placement

---

## **8. RANK SYSTEM (8 TIERS)**

### **Rank Tier Structure**

| Tier | Indonesian Name | English Name | Sub-Ranks | Stars per Sub-Rank | Total Stars to Next Tier |
|------|----------------|--------------|-----------|-------------------|--------------------------|
| 1 | Bayi | Baby | 3 (Bayi 3, 2, 1) | 3 | 9 |
| 2 | Balita | Toddler | 3 (Balita 3, 2, 1) | 3 | 9 |
| 3 | Anak-Anak | Children | 3 (Anak-Anak 3, 2, 1) | 3 | 9 |
| 4 | Remaja | Teenager | 4 (Remaja 4, 3, 2, 1) | 4 | 16 |
| 5 | Dewasa | Adult | 5 (Dewasa 5, 4, 3, 2, 1) | 5 | 25 |
| 6 | Profesional | Professional | 5 (Profesional 5, 4, 3, 2, 1) | 5 | 25 |
| 7 | Detektive | Detective | 5 (Detektive 5, 4, 3, 2, 1) | 5 | 25 |
| 8 | Sang Ahli | Master | 1 (Sang Ahli) | N/A | Victory Counter (no cap) |

**Star Progression:**
- Win → +1 star
- Loss → −1 star
- Promotion: Reach required stars for current sub-rank
- Demotion: Lose all stars in current sub-rank (drop to previous sub-rank)
- Floor Protection: Cannot drop below Tier 1 (Bayi 3)

**Sang Ahli (Master) Special:**
- No sub-ranks
- Uses victory counter instead of stars
- Every win adds +1 to victory count
- Losses do NOT decrease victory count
- Leaderboard ranks by victory count

---

## **9. PLAYER MOVEMENT & CAMERA**

### **Movement Specifications**

```lua
-- StarterPlayer Configuration
CharacterWalkSpeed = 10 -- studs/s (realistic human walk)
CharacterJumpPower = 32 -- realistic jump height
CharacterUseJumpPower = true

-- Optional Movement States (if implemented)
WALK_SPEED = 10 -- normal
SPRINT_SPEED = 14 -- with Shift held
CROUCH_SPEED = 5 -- with Ctrl held (optional Phase 8)
```

**Movement Feel:**
- Acceleration: Gradual (not instant to max speed)
- Deceleration: Smooth (slight slide when stopping)
- Jump: Realistic height (approximately waist-high obstacles)
- Air Control: Limited (realistic physics)

---

### **Camera System**

**IN-GAME (Investigation Maps):**
```lua
player.CameraMode = Enum.CameraMode.LockFirstPerson
CameraType = Enum.CameraType.Custom
```
- ✅ FPV LOCKED (cannot zoom out to third-person)
- ✅ Head bobbing enabled (camera sway when walking)
- ✅ Flashlight attached to camera (first-person view)

**LOBBY (LobbySocialHub):**
```lua
player.CameraMode = Enum.CameraMode.Classic
```
- ✅ TPV ALLOWED (can zoom in/out freely)
- ✅ Standard Roblox camera controls
- ✅ Social interaction visibility

**Head Bobbing Parameters:**
```lua
bobFrequency = 2 -- bob cycles per second
bobAmplitude = 0.1 -- vertical movement (studs)
swayAmplitude = 0.05 -- horizontal sway (studs)
```

---

## **10. SANITY SYSTEM**

### **Sanity Mechanics**

**Range:** 0-100

**Sanity Decreases From:**
- Darkness (passive drain when no light source)
- Ghost proximity (faster drain when ghost nearby)
- Paranormal events (door slams, light flickers)
- Hunt phase (doubled drain rate)

**Low Sanity Effects (<50):**
- Increased ghost aggression
- Higher hunt frequency
- Hallucination events (fake ghost sounds, shadow figures)
- False evidence signals (tool malfunctions)
- Visual distortion (vignette, blur)
- Audio distortion (heartbeat, tinnitus)

**Sanity Drain Rates (base values, modified by difficulty):**
```lua
-- Per second drain rates
DARKNESS_DRAIN = 0.1 -- when in darkness
GHOST_PROXIMITY_DRAIN = 0.3 -- when within 15 studs of ghost
HUNT_DRAIN = 0.5 -- during hunt phase (doubled)
PARANORMAL_EVENT_DRAIN = 2.0 -- instant drain on event trigger
```

**Sanity Recovery:**
- Standing in lit areas: +0.05/s
- Using Dupa (Smudge Stick): +10 instant
- Leaving ghost room: Drain stops

---

## **11. AGGRESSION SYSTEM**

### **Aggression Mechanics**

**Range:** 0-100

**Aggression Increases From:**
- Player near ghost room (proximity)
- Low average team sanity
- Paranormal interactions (using tools near ghost)
- Time in investigation (passive buildup)
- Provocation (saying ghost name in Spirit Box, flashlight spam)

**Hunt Trigger Condition (BOTH required):**
```lua
if ghostAggression >= huntThreshold AND averageTeamSanity <= 40 then
    TriggerHunt()
end

-- huntThreshold varies by ghost type:
-- Low Aggression Ghosts: 70-80
-- Medium Aggression Ghosts: 50-60
-- High Aggression Ghosts: 40-50
```

**Aggression Cooldown:**
- After hunt ends: Aggression drops by 20-30 points
- Cooldown period: 25-45 seconds before next hunt possible

---

## **12. SPECTATOR DISTORTION SYSTEM**

### **Distortion Probabilities**

When spectator (dead player) tries to give info about ghost:

```lua
FakeGhost = 60% -- Wrong ghost shown
UncertainEvent = 30% -- Ambiguous signal (could be multiple ghosts)
RealGhost = 10% -- Actual correct ghost info
```

**Spectator Limitations:**
- Cannot directly tell alive players which ghost it is
- All communication filtered through distortion system
- Can see ghost clearly, but alive players receive distorted hints
- Creates uncertainty and psychological tension

**Examples:**
- Spectator sees Pocong → System shows "Shrouded Figure" (could be Pocong or Jerangkong)
- Spectator sees Kuntilanak → System shows generic "Female Spirit" (could be multiple)
- Only 10% chance spectator gives accurate ghost name

---

## **13. LOBBY INTERACTION SYSTEM**

### **Lobby Zones & Functions**

**Center Hub:**
- MatchQueue Platform
- Queue Trigger (join ranked/classic queue)
- Spawn Point (player first spawn location)

**North Zone - Evidence Test Building (70×70):**
- 6 Test Tables (one per evidence type)
- Allows players to practice tools before investigation
- Connected System: EvidenceTrainingSystem
- EventBus: `EvidenceTestStarted`, `EvidenceTestCompleted`

**East Zone - Shop Building (60×60):**
- ShopNPC interaction
- Equipment purchase (tools, consumables)
- Cosmetic purchase (skins, emotes, titles)
- Connected System: EconomySystem, ShopSystem
- EventBus: `ShopOpened`, `ItemPurchased`, `CurrencyUpdated`

**West Zone - Party Zone:**
- PartyPlatform
- PartyBoard (create/join party)
- PartyTerminal (invite friends, ready up)
- Connected System: PartySystem
- EventBus: `PartyCreated`, `PartyJoined`, `PartyLeft`, `PartyUpdated`

**South Zone - Social Garden (100×100):**
- Social interaction area
- NPC dialogue spots (future)
- Event decorations (seasonal)
- Benches, trees (ambient props)

**South-East Zone - Flex Zone Building (60×60):**
- Leaderboard displays
- Seasonal events
- Developer announcements
- Future expansion area

**Path System:**
- Width: 12 studs
- Connects all zones to center hub
- Named: Path_ToShop, Path_ToEvidence, Path_ToParty, Path_ToGarden, Path_ToFlex

---

## **14. SYSTEM ARCHITECTURE (MODULAR)**

### **Service Dependency Tiers**

**Tier 1 — Core Infrastructure:**
- EventBus (central communication)
- ConfigLoader (game configuration)
- ServiceRegistry (system registry)

**Tier 2 — Persistence Layer:**
- DataPersistenceService
- PlayerData
- EconomyData
- InventoryData
- RankData

**Tier 3 — Player Systems:**
- ProfileSystem
- ProgressionSystem
- RankedSystem

**Tier 4 — Lobby Systems:**
- LobbySocialHub
- PartySystem
- ContractSystem

**Tier 5 — Match Systems:**
- MatchQueue
- MatchBuilder
- MatchInstance
- MatchLifecycle
- TeleportService
- GamePhaseSystem

**Tier 6 — Gameplay Systems:**
- GhostSystem
- EvidenceSystem
- SanitySystem
- AggressionSystem
- InvestigationSystem

**Tier 7 — Advanced Systems:**
- HorrorDirector
- GhostModifierSystem
- MapInteractionSystem
- MapEventSystem

**Communication Rules:**
- ✅ ALL systems communicate via EventBus
- ❌ Direct system-to-system calls forbidden
- ✅ Use ServiceRegistry for dependency injection
- ❌ Never bypass HorrorDirector for pacing control

---

## **15. FILE STRUCTURE**

### **Server-Side (src/ServerScriptService/Server/)**

```
Core Systems:
- MatchSystem/
- GhostSystem/
- EvidenceSystem/
- SpectatorSystem/
- HorrorDirector/
- SanitySystem/
- AggressionSystem/

Meta Systems:
- EconomySystem/
- InventorySystem/
- ProfileSystem/
- DataPersistenceService/
- LobbySocialHub/

Each system folder contains:
- Main.lua (initialization)
- Service.lua (core logic)
- Controller.lua (EventBus handlers)
- State.lua (runtime state)
```

---

## **16. MATCH LIFECYCLE**

### **Match State Machine**

```
Waiting → Preparation → Investigation → Hunt → Extraction → Results → Completed
```

**State Transitions:**
1. **Waiting:** Players in queue, matchmaking
2. **Preparation:** Map loads, ghost spawns, teams form
3. **Investigation:** Players collect evidence, explore map
4. **Hunt:** Ghost enters aggressive hunt mode (triggered by aggression + sanity)
5. **Extraction:** Players escape map or die
6. **Results:** Rewards calculated, XP/MM granted, stats displayed
7. **Completed:** Match cleanup, players return to lobby

**EventBus Events:**
- `MatchStarted` (Preparation → Investigation)
- `HuntTriggered` (Investigation → Hunt)
- `HuntEnded` (Hunt → Investigation or Extraction)
- `MatchEnded` (Extraction → Results)
- `ResultsCalculated` (Results → Completed)

---

## **17. REWARD PIPELINE**

### **Reward Calculation Flow**

```
MatchSystem (MatchEnded event)
    ↓
EventBus publishes MatchEnded
    ↓
RewardSystem listens & calculates rewards
    ↓
EconomySystem grants currency (MM/PP)
    ↓
ProgressionSystem grants XP
    ↓
RankedSystem updates rank stars (if ranked mode)
    ↓
DataPersistenceService saves all data
```

**Reward Sources:**
- Match completion (base MM reward)
- Evidence discovery (bonus MM per evidence)
- Ghost identification success (bonus MM)
- Survival (bonus MM if alive at extraction)
- Daily missions (additional MM/XP)
- RoyalPass progression (PP/exclusive cosmetics)
- Daily check-in (small MM/XP)

---

## **PHASE 7 PRIORITIES (VISUAL & ATMOSPHERIC INTEGRATION)**

Based on canonical specifications, Phase 7 should prioritize:

### **7.1 Core Lighting & Environment:**
- Future Lighting setup
- Flashlight system (Senter) implementation
- Player movement (WalkSpeed: 10, JumpPower: 32)
- FPV camera lock in investigation maps

### **7.2 Priority Ghost Models (HIGH):**
- Pocong (Indonesian shrouded ghost, floating)
- Kuntilanak (female spirit, long hair, crying)
- Genderuwo (shadow figure, aggressive)

### **7.3 Evidence Tool 3D Models:**
- Detektor MEDOK (EMF Reader) — handheld device with screen
- Termometer Suhu (Thermometer) — digital display
- Senter (Flashlight) — tactical flashlight model

### **7.4 Evidence Visual Effects:**
- MEDOK: Electromagnetic sparks/glow
- Suhu: Cold breath particles, frost on surfaces
- To'un: UV glow on fingerprints/orbs
- Suara: Spirit Box static/waveform visual

### **7.5 Sanity Visual Effects:**
- Vignette (edge darkening) based on sanity level
- Blur effect when sanity <30
- Heartbeat sound increasing as sanity drops
- Color desaturation at low sanity

---

## **CHANGELOG - CANONICAL SPEC v2.0**

**What Changed from Previous Reports:**

1. ✅ **Evidence Names:** Now use correct Indonesian names from GDD (MEDOK, Suhu, Buku Terkutuk, To'un, Suara, Pengganggu)
2. ✅ **Currency:** Corrected to MM/PP/Robux (not Uang/Token/Arwah)
3. ✅ **Rarity System:** Added Indonesian names (B-ajah, B-Lebih, Lumayan, Langka, Gagah)
4. ✅ **Spectator Distortion:** Corrected to 60% Fake, 30% Uncertain, 10% Real (was reversed)
5. ✅ **Tool Names:** Bilingual system (Indonesian display, English code reference)
6. ✅ **Maps:** Confirmed 5 total (1 lobby + 4 investigation)
7. ✅ **Difficulty Modes:** Classic has no named tiers (dynamic balanced difficulty)
8. ✅ **Lobby Layout:** Added specific building sizes and orientations from MAP_LAYOUT_BLUEPRINT
9. ✅ **Ghost AI Parameters:** Added map-specific roaming/hunt ranges from MASTER_ALL_MAP
10. ✅ **System Architecture:** Confirmed 7-tier dependency structure from README_GDD_MASTER

**Files Synchronized:**
- 23 GDD files analyzed
- All naming conventions unified
- All numeric specifications verified
- All system dependencies mapped

---

**END OF CANONICAL SPECIFICATIONS v2.0**

**Next Step:** Use this document as the SINGLE SOURCE OF TRUTH for all development, documentation updates, and AI-assisted code generation.

**Miftah, this document is now synchronized with ALL your GDD files. Any conflicts have been resolved in favor of the original GDD source material.**

---

## 2026-04-16 Addendum - HauntedHouse Runtime Boundary and Staging Lock

- Active `HauntedHouse` state is now locked to owner-approved runtime sync from `Workspace.HauntedHouse_Review`.
- Runtime sync path: `Workspace -> ServerStorage.Maps.HauntedHouse.HauntedHouse -> ReplicatedStorage.Maps.HauntedHouse.HauntedHouse`.
- `OutdoorMainFloor` for `HauntedHouse` is explicitly removed by owner instruction; canonical base uses native map geometry only.
- Boundary policy for `HauntedHouse`:
  - computed from house+staging footprint only
  - runtime collider walls are tight (anti-exit)
  - realistic tree blockers are aligned per side (`North/South/West/East`) to stop out-of-map movement.

## 2026-04-26 Addendum - Visual Batch T27 Invite Popup Compact

- RoomBrowser `InvitePopup` now has explicit `compact` and `extra-compact` visual lanes for short mobile viewports.
- Invite popup hierarchy tuning is visual-only: panel size, text area spacing, and accept/decline button sizing/typography.
- No matchmaking/invite/runtime behavior changes in this batch; runtime-authority lock remains unchanged.

## 2026-04-26 Addendum - Visual Batch T28 Password Modal Compact

- RoomBrowser `PasswordModal` now has explicit `compact` and `extra-compact` visual lanes for constrained mobile viewports.
- Password modal hierarchy tuning is visual-only: card bounds, title/input/button spacing, and typography sizing.
- No join-room/password validation/runtime behavior changes in this batch; runtime-authority lock remains unchanged.

## 2026-04-26 Addendum - Visual Batch T29 Kick Notice Compact

- RoomBrowser `KickNoticeModal` now has explicit `compact` and `extra-compact` visual lanes for constrained mobile viewports.
- Kick notice hierarchy tuning is visual-only: card bounds, message block spacing, and `OK` button sizing/typography.
- No kick handling/runtime behavior changes in this batch; runtime-authority lock remains unchanged.

## 2026-04-26 Addendum - Visual Batch T30 Countdown Overlay Compact

- RoomBrowser `CountdownOverlay` now has compact-tuned hierarchy for constrained mobile viewports.
- Countdown overlay tuning is visual-only: countdown number bounds/position plus cancel button size/position/typography.
- No countdown start/cancel flow or runtime-authority behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T31 Inline Kick/Password Row Compact

- RoomBrowser compact host-control row for `SetPassword` and `Kick` now has extra-compact-specific inline field/button sizing.
- Inline control tuning is visual-only: right action width, field height rhythm, and extra-compact placeholder shortening for readability.
- No host-control logic, password submission flow, or kick handling/runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T32 Join Password Compact

- RoomBrowser `JoinPassword` field now has compact-tuned height in constrained viewport lanes.
- Join-password tuning is visual-only: field height rhythm plus extra-compact placeholder shortening for readability.
- No room-join/password validation/runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T33 Action Stack Compact

- RoomBrowser compact action stack (`Queue`, `Quick Classic`, `Quick Ranked`, `Refresh`, `Create Room`) now has extra-compact-specific sizing and vertical rhythm.
- Action-stack tuning is visual-only: button heights, row gaps, and extra-compact button typography for short viewports.
- No matchmaking flow, room action authority, or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T34 Invite Dropdown Compact

- RoomBrowser `InviteDropdown` now has compact/extra-compact responsive dropdown height and vertical offset tuning.
- Invite list container tuning is visual-only: dropdown bounds plus compact canvas alignment for short viewports.
- No invite flow, matchmaking authority, or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T35 Preview Player Card Compact

- RoomBrowser `Room Preview` player cards now have compact/extra-compact-specific card bounds, avatar preview bounds, and text-block rhythm.
- Preview card tuning is visual-only: grid cell padding and extra-compact truncation for name/state readability.
- No player-state logic, room preview data flow, or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T36 Preview Header Compact

- RoomBrowser `Room Preview` header (`Title` + `Info`) now has compact/extra-compact typography tuning.
- Preview header tuning is visual-only: info-row bounds plus extra-compact truncation behavior for summary text.
- No room preview selection/data logic or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T37 Preview Player List Compact

- RoomBrowser `Room Preview` player list now has compact/extra-compact scrollbar and inner padding tuning.
- Player-list tuning is visual-only: list density plus extra-compact title truncation behavior.
- No room preview data flow or player-state runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T38 Map Preview Strip Compact

- RoomBrowser map preview strip (`Mood`, `Stats`, `Footer`) now has extra-compact bounds and typography tuning.
- Map preview strip tuning is visual-only: compact widths/heights plus truncation behavior to avoid text overflow.
- No map preview data flow or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T39 Room List Row Compact

- RoomBrowser room-list rows now have compact/extra-compact adaptive row padding and compact-aware text vertical alignment.
- Room-list tuning is visual-only: row readability rhythm and multi-line scan clarity for host/status text.
- No room selection/join logic or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T40 List Density Polish

- RoomBrowser `RoomList` now has extra-compact-specific scrollbar thickness tuning for short mobile viewports.
- Room-list density tuning is visual-only: extra-compact row gap tightening plus subtle row-corner radius trim for scan rhythm.
- No room selection/join logic or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T41 Row Micro-Density Trim

- RoomBrowser room-list rows now have extra-compact-specific row height trim for short mobile viewports.
- Row micro-density tuning is visual-only: extra-compact internal padding trim (`top/bottom/right`) to keep list scan rhythm tighter.
- No room selection/join logic or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T42 Horizontal Space Reclaim

- RoomBrowser room-list rows now have extra-compact-specific horizontal inset trim for short mobile viewports.
- Horizontal density tuning is visual-only: extra-compact row width inset trim plus left/right internal padding trim and tighter list row gap.
- No room selection/join logic or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T43 Status Header Compact Trim

- RoomBrowser status header now has extra-compact-specific height and text-size tuning for short mobile viewports.
- Status-header tuning is visual-only: extra-compact status-line truncation to prevent long-message overflow in constrained width.
- No room selection/join logic or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T44 Tab Strip Vertical Compact

- RoomBrowser mode tab strip now has extra-compact-specific vertical offset tuning for short mobile viewports.
- Tab-strip tuning is visual-only: extra-compact tab-gap trim plus slight upward control-row placement for better content breathing room.
- No mode selection, room flow, or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T45 Content Stack Vertical Trim

- RoomBrowser content stack now has extra-compact-specific top spacing trim below the mode tab strip.
- Content-stack tuning is visual-only: extra-compact action-stack height trim for tighter vertical composition in short mobile viewports.
- No mode selection, room flow, or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T46 Action-Lane Transition Trim

- RoomBrowser wide-compact content column now has extra-compact-specific transition spacing trim between room list and action lane.
- Transition tuning is visual-only: extra-compact room-list bottom gap trim plus action-lane anchor offset trim for tighter vertical continuity.
- No mode selection, room flow, or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T47 Action-Column Gap Compact

- RoomBrowser action-lane paired buttons now have extra-compact-specific horizontal column-gap tuning.
- Action-column tuning is visual-only: paired button widths recomputed with tighter extra-compact gap for consistent control rhythm.
- No mode selection, room flow, or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T48 Join-Password Anchor Trim

- RoomBrowser join-password field now has extra-compact-specific vertical anchor trim relative to the queue action row.
- Join-password anchor tuning is visual-only: tighter extra-compact input-to-action grouping while preserving existing field height.
- No mode selection, room flow, password-validation, or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T49 Preview PlayerList Top-Gap Trim

- RoomBrowser preview player-list now has extra-compact-specific top-gap trim relative to the map preview block.
- Preview-list spacing tuning is visual-only: extra-compact list anchor shift upward while preserving player-title anchor.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T50 Preview PlayerList Height Reclaim

- RoomBrowser preview player-list now has extra-compact-specific top-gap continuation trim plus bottom inset trim.
- Preview-list height tuning is visual-only: extra-compact list viewport height reclaimed while preserving preview title anchor behavior.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T51 Preview PlayerList Bottom Inset Micro Trim

- RoomBrowser preview player-list now has an additional extra-compact bottom inset trim.
- Preview-list micro tuning is visual-only: slight extra-compact list height reclaim while preserving existing preview-title and list-anchor behavior.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T52 Preview PlayerList Top-Gap Micro Trim

- RoomBrowser preview player-list now has an additional extra-compact top-gap trim relative to the map preview block.
- Preview-list micro tuning is visual-only: slight extra-compact list anchor shift upward while preserving preview-title anchor behavior.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.

## 2026-04-26 Addendum - Visual Batch T53 Map-Footer Compact Trim

- RoomBrowser map preview footer now has extra-compact-specific bounds trim.
- Map-footer tuning is visual-only: slightly reduced extra-compact footer height while preserving footer typography and truncation behavior.
- No room preview map data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T54 Map-Mood Width Micro Trim

- RoomBrowser map preview mood chip now has extra-compact-specific width micro trim.
- Map-mood tuning is visual-only: slight width reduction for tighter strip composition while preserving truncation behavior.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T55 Map-Footer Height Micro Trim

- RoomBrowser map preview footer now has an additional extra-compact height micro trim.
- Map-footer tuning is visual-only: slightly reduced footer height while preserving existing footer text behavior.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T56 Preview PlayerList Top-Gap Trim II

- RoomBrowser preview player-list now has a second extra-compact top-gap micro trim.
- Preview-list tuning is visual-only: slight upward list shift while preserving preview-title anchor behavior.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T57 Preview PlayerList Bottom Inset Trim II

- RoomBrowser preview player-list now has a second extra-compact bottom inset micro trim.
- Preview-list tuning is visual-only: slight list height reclaim while preserving title/list anchor structure.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T58 Action-Column Gap Trim II

- RoomBrowser action-lane paired buttons now have a second extra-compact column-gap micro trim.
- Action-column tuning is visual-only: tighter paired-button spacing with balanced width recompute.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T59 RoomList Bottom-Gap Micro Trim

- RoomBrowser wide-compact room-list bottom gap now has an extra-compact micro trim.
- Transition tuning is visual-only: slightly tighter list-to-action spacing continuity.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T60 Action-Y Anchor Micro Trim

- RoomBrowser action lane now has extra-compact-specific Y-anchor micro trim.
- Action-lane tuning is visual-only: slightly tighter transition from room list to action controls.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T61 Join-Password Anchor Trim II

- RoomBrowser join-password field now has a second extra-compact vertical anchor micro trim.
- Join-password tuning is visual-only: tighter input-to-action grouping with unchanged field height.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T62 RoomList Min-Height Micro Trim

- RoomBrowser room-list right-column minimum height now has a micro trim.
- Room-list tuning is visual-only: subtle min-height adjustment for compact density flexibility.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T63 Preview-Map Min-Height Micro Trim

- RoomBrowser map preview now has an extra-compact-aware minimum height micro trim.
- Preview-map tuning is visual-only: subtle min-height adjustment to rebalance vertical space.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T64 Preview-Map Max-Height Micro Trim

- RoomBrowser map preview now has a maximum height micro trim in the compact lane.
- Preview-map tuning is visual-only: subtle max-height reduction for better section balance.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T65 Preview Player-Card Padding Micro Trim

- RoomBrowser preview players grid now has extra-compact-specific cell-padding micro trim.
- Preview-player card tuning is visual-only: slightly tighter vertical card spacing for compact density.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T66 Preview Player-Card Width Rebalance

- RoomBrowser preview players grid now has a micro width rebalance for player card cells.
- Preview-player card tuning is visual-only: slight card width adjustment with unchanged card height.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T67 Map-Stats Anchor Micro Trim

- RoomBrowser map preview stats row now has a compact-lane vertical anchor micro trim.
- Map-stats tuning is visual-only: slight Y-offset adjustment while preserving existing typography.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T68 Map-Footer Y-Align Micro Trim

- RoomBrowser map preview footer now has extra-compact-specific Y-anchor micro trim.
- Map-footer tuning is visual-only: slight vertical alignment adjustment with unchanged footer size/typography.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T69 Map-Title Width Reclaim

- RoomBrowser map preview title now has a compact-lane width reclaim micro trim.
- Map-title tuning is visual-only: slight horizontal bounds expansion with unchanged title typography.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T70 Map-Footer Height Micro Trim II

- RoomBrowser map preview footer now has a second extra-compact height micro trim.
- Map-footer tuning is visual-only: final slight height reduction with unchanged footer text behavior.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T71 Map-Mood Width Micro Trim II

- RoomBrowser map preview mood chip now has a second extra-compact width micro trim.
- Map-mood tuning is visual-only: slight width reduction while preserving existing truncation behavior.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.


## 2026-04-26 Addendum - Visual Batch T72 Map-Footer Height Micro Trim III

- RoomBrowser map preview footer now has a third extra-compact height micro trim.
- Map-footer tuning is visual-only: slight height reduction with unchanged footer text sizing behavior.
- No room preview data flow, player-state logic, or runtime behavior changes in this batch.

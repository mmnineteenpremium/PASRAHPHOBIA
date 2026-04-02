# PASRAHPHOBIA — CANONICAL SPECIFICATIONS v2.0

**Last Updated:** 2026-03-17 | Session 5 — Full GDD Synchronization  
**Purpose:** Authoritative reference for ALL game specifications  
**Source:** Synchronized from 23 GDD files + project documentation

**⚠️ AI & DEVELOPERS:** This document is the SINGLE SOURCE OF TRUTH. All conflicting information in other files must defer to this specification.

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
HauntedHouse         | 25-30 studs    | 30 studs
AbandonedPalace      | 35-45 studs    | 40 studs
```

---

## **6. MAPS (5 TOTAL)**

### **Master Map Specifications**

| Map Name | Type | Size (studs) | Floors | Total Area | Rooms | Ghost Spawn Points | Difficulty |
|----------|------|--------------|--------|------------|-------|-------------------|------------|
| LobbySocialHub | Social Lobby | 420×420 | 1 | 176,400 studs² | N/A | 0 (test zones only) | N/A |
| AbandonedPalace | Investigation | 180×180 | 1 | 32,400 studs² | 18-25 | 5-7 | Large/Hard |
| HauntedHouse | Investigation | 140×140 | 2 | 39,200 studs² (19,600 per floor) | 12-16 | 4-6 | Medium |
| EmptyBuilding | Investigation | 100×100 | 2 | 20,000 studs² (10,000 per floor) | 10-14 | 5-7 | Medium-Small |
| StudioMMNineteen | Investigation | 90×90 | 2 | 16,200 studs² (8,100 per floor) | 6-10 | 3-5 | Small/Easy |

**Map Size Categories:**
- Small: 80-100 studs (solo/duo friendly)
- Medium: 120-150 studs (2-3 players recommended)
- Large: 160-200 studs (4 players recommended)
- Hub: 350-450 studs (lobby/social area)

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

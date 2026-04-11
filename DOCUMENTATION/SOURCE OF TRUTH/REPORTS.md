# PASRAHPHOBIA REPORTS

## Scope Note

- This file is a broad architecture/runtime audit snapshot with `Last updated: 2026-04-01`.
- It is not the final release-readiness authority for `2026-04-11`.
- For current publish status, use:
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/SOURCE_OF_TRUTH_RECONCILIATION_2026-04-11.md`
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/PUBLISH_REVIEW_FINAL_2026-04-06.md`
  - `DOCUMENTATION/SOURCE OF TRUTH/reports/MANUAL_PUBLISH_HANDOFF_2026-04-09.md`
  - the latest lane result reports in `DOCUMENTATION/SOURCE OF TRUTH/reports/`

Last updated: 2026-04-01
Audit type: runtime truth audit based on current code, not historical notes
This file supersedes the previous report files in this folder.

## 0. 2026-03-31 Consistency Execution Update

Canonical alignment executed on runtime-active tree (`src/ServerScriptService/Server`) with these enforced choices:

- server runtime path unified to `src/ServerScriptService/Server` and legacy server tree removed
- ghost source unified to 12 Indonesian ghosts only
- evidence vocabulary unified to `MEDOK`, `Suhu`, `BukuTerkutuk`, `To'un`, `Suara`, `Pengganggu`
- rank owner unified to `RankedSystem` only (`legacy rank runtime` removed from active tree)
- currency model unified to `MM`, `PP`, `Robux` (`XP` retained for progression, not wallet currency)
- persistence API calls aligned to `LoadProfile`/`SaveProfile` and profile patch shape
- mode/difficulty helpers exported from `shared/GameData/ModeDifficultyConfig.lua` and reused by lobby/match normalization paths
- `ReplicatedStorage/Config/DifficultyModes.model.json` now includes `Easy`, `Normal`, `Hard`, and `Nightmare`; canonical `Uji Nyali` resolves to legacy `Nightmare`
- contract configuration and active contract generation now use only runtime-active investigation maps (`HauntedHouse`, `EmptyBuilding`, `StudioMMNineteen`, `AbandonedPalace`)
- room browser map preview now renders shared map metadata instead of `MAP PLACEHOLDER` labels
- client room trace spam is no longer always-on; it is gated behind Studio attribute `ReplicatedStorage.PasrahRoomTrace`
- `ProfileSystem` now loads and persists canonical progression/statistics/profile/rank data through `DataPersistenceService`
- `PlayerProfileSystem` public inspect payload no longer leaks `rank` as `table: 0x...` and now consumes the canonical `ProfileSystem` snapshot
- `RankedSystem` and `ProgressionSystem` now sync through `ProfileSystem` first, with direct persistence only as fallback
- Classic queue/room browser no longer expose named difficulty tiers to players; final Classic difficulty is now server-balanced from party size and average player level
- `LeaderboardSystem` now ranks by canonical ranked progression and `Sang Ahli` victory counter instead of a local level/contract formula
- `Sang Ahli` display no longer formats as `Sang Ahli I`, and top-tier losses now preserve the victory counter per `CANONICAL_SPECIFICATIONS_v2.md`
- `SystemRegistry` now applies explicit preload + declared group order before any alphabetical fallback for uncategorized systems

## 0.1 2026-04-01 Progress Estimate

Current execution estimate after the 2026-04-01 profile + classic + leaderboard + bootstrap-order consistency pass, the lobby cosmetic-application fix, canonical rarity alignment, the gift-flow verification pass, the investigation-tool runtime-model pass, and the lobby flex runtime-model pass:

- practical implementation score: `81% - 82%`
- management figure: `82%`
- current working phase: `late Phase 6 -> early Phase 7 consistency lock`

Audit-derived row status counts from this report:

- `31` rows = `Implemented active`
- `24` rows = `Resolved` / `Resolved (runtime model)`
- `4` rows = `Improved`
- `0` rows = `Partial/conflicted`
- `4` rows = `Not found / not confirmed`
- total audited runtime rows = `63`

Conservative weighted model used for this estimate:

- `Implemented active` = `1.0`
- `Resolved` = `0.75`
- `Improved` = `0.6`
- `Partial/conflicted` = `0.5`
- `Not found / not confirmed` = `0.0`

Formula:

`(31 x 1.0) + (24 x 0.75) + (4 x 0.6) + (0 x 0.5) + (4 x 0.0) = 51.40`

`51.40 / 63 = 81.59%`

Management note:

- planning percentage is kept lower than the raw row-weight score because several high-value launch blockers still remain:
- live DataStore behavior is still not validated in this audit; Studio now supports explicit opt-in real DataStore, but default local behavior remains mock persistence
- live gameplay validation for ranked/leaderboard behavior is still not complete
- missing completion-layer systems such as Robux monetization, plus still-unvalidated live runtime behavior

## 1. Audit Basis

This report was produced from:

- `CLAUDE.md`
- `CANONICAL_SPECIFICATIONS_v2.md`
- `PASRAHPHOBIA_DOC_INDEX.md`
- `PASRAHPHOBIA_AI_SUPER_CONTEXT_V2.md`
- `default.project.json`
- all current Lua files inside the mapped runtime tree
- legacy Lua trees for duplicate/conflict analysis
- key JSON config assets in `src/ReplicatedStorage/Config`

Scan coverage:

- active server: `841` Lua files, `80,212` LOC
- active client: `42` Lua files, `6,820` LOC
- shared: `43` Lua files, `1,587` LOC
- legacy server: `424` Lua files, `30,082` LOC
- legacy client: `3` Lua files, `310` LOC

Status labels used below:

- `Implemented active`: code exists in the mapped runtime path and is on the current boot path or directly wired to runtime remotes/scripts.
- `Implemented but partial/conflicted`: code exists, but current data, dependencies, or boot wiring conflict with the intended runtime.
- `Not found / not confirmed`: no active runtime path was found in this audit.

## 2. Runtime Truth

Current runtime mapping is not what several old docs still describe.

- active server runtime path: `src/ServerScriptService`
- active server modular systems path: `src/ServerScriptService/Server`
- active client runtime path: `src/client`
- active shared data path: `src/shared`
- legacy server tree has been removed from repo runtime path
- `src/StarterPlayer/StarterPlayerScripts` is a legacy duplicate tree, not the main client runtime tree

Current active boot path:

`Bootstrap.server.lua -> ServerBootstrap.lua -> Core/SystemRegistry.lua`

Important consequence:

- `SystemRegistry` auto-loads top-level `EventBus`, `*System`, `*Service`, plus explicit runtime names (`HorrorDirector`, `LobbySocialHub`, `EvidenceDeductionEngine`).

## 3. Documents vs Current Reality

### 3.1 `CLAUDE.md`

Useful as historical context, but not current runtime truth.

- phase/status notes are stale
- it still reflects earlier session checkpoints
- some listed blockers have already moved, while newer runtime risks are not captured

### 3.2 `PASRAHPHOBIA_AI_SUPER_CONTEXT_V2.md`

Useful as architectural intent, but no longer accurate as implementation status.

- it says several systems were still planned or in development
- current repo already contains implementations for many of those systems
- runtime path references have been updated to `src/ServerScriptService/Server`

### 3.3 `PASRAHPHOBIA_DOC_INDEX.md`

Useful as design map, not as runtime truth.

- it is broad and aspirational
- it does not reflect which modules are currently wired into boot

### 3.4 `CANONICAL_SPECIFICATIONS_v2.md`

This remains the design target, not the implementation snapshot.

- some parts match current code
- some parts diverge sharply from current code
- this report separates those two

## 4. Biggest Architectural Fact Right Now

The repo currently has two different realities:

1. intended architecture
2. actual active boot

Intended architecture still exists in:

- `Core/Bootstrap/SYSTEM_MAP.lua`
- `Core/Bootstrap/SystemLoader/Main.lua`

Actual active boot is:

- `ServerBootstrap.lua` calling `SystemRegistry:Start()`
- `SystemRegistry` using explicit preload first, then declared group order, then alphabetical fallback only for uncategorized systems

These two realities are closer now, although the grouped bootstrap files in docs are still not the exact active runtime entry path.

This remains one reason old documentation drifted away from current runtime behavior, but the active registry order is no longer purely alphabetical.

## 5. Implemented Active

These areas are clearly implemented in the current runtime-mapped tree and have active code wiring.

| Area | Status | Current fact |
| --- | --- | --- |
| Core boot | Implemented active | `Bootstrap.server.lua` starts `ServerBootstrap.lua`, which starts `SystemRegistry`. |
| Event bus | Implemented active | `EventBus` exists and is used across the runtime tree via `Publish` and `Subscribe`. |
| Data persistence shell | Implemented active | `DataPersistenceService` has autosave tick, player register/unregister, inventory/profile load/save. |
| Match flow | Implemented active | `MatchSystem` contains queue, builder, lifecycle, teleport, cleanup, mode/difficulty resolution. |
| Match teleport | Implemented active | `MatchTeleport.lua` contains stream-safe teleport logic, safe floor sampling, temporary freeze/anchor, upright yaw-only placement. |
| Lobby room flow | Implemented active | `LobbySystem` handles create/join/leave/ready/host start/cancel/password/kick/room browser snapshots and queue trigger. |
| Lobby remote handling | Implemented active | `LobbySystem/Controller.lua` and client UI wire `LobbyEvent` for room browser actions. |
| Game phases | Implemented active | `GamePhaseSystem` manages `PreparationPhase`, `InvestigationPhase`, `HuntPhase`, `EndgamePhase`. |
| Ghost gameplay core | Implemented active | `GhostSystem/GhostService.lua` contains ghost session state, roaming, manifestations, hunts, evidence triggers, ghost events. |
| Ghost database config | Implemented active | `GhostDatabaseSystem` validates and exposes `12` ghosts from `ReplicatedStorage/Config/GhostTypes.model.json`. |
| Evidence gameplay core | Implemented active | `EvidenceSystem` contains evidence requests, evidence collection, journal guess validation, possible ghost calculation. |
| Spectator gameplay core | Implemented active | `SpectatorSystem` has spectator state, targets, ghost visibility/distortion hooks, communication payloads. |
| Sanity | Implemented active | `SanitySystem` is substantive and wired as a gameplay system. |
| Aggression | Implemented active | `AggressionSystem` is substantive and wired as a gameplay system. |
| Hunt runtime | Implemented active | `HuntSystem`, `AdaptiveHuntSystem`, `HuntEscapeSystem`, `GhostChaseSystem` all exist in active runtime tree. |
| Inventory | Implemented active | `InventorySystem` loads on join, saves on leave, tracks owned items and equipment slots. |
| Shop | Implemented active | `ShopSystem` validates purchases, checks ownership, spends currency, grants inventory entries. |
| Cosmetics | Implemented active | `CosmeticSystem` validates ownership, loads equipped cosmetics, saves profile snapshot, exposes equip flow. |
| Economy | Implemented active | `EconomySystem` contains wallet state, reward drivers, spend/add currency flows, daily/royal pass integrations. |
| Reward pipeline | Implemented active | `MatchResultSystem` forwards enriched results, `RewardCalculationSystem` owns endgame match rewards, `ContractSystem` handles direct contract grants when needed, and event-only mirror systems are disabled from autoload to avoid duplicate reward surfaces. |
| Party | Implemented active | `PartySystem` supports create, invite, join, leave, and leader/member state through EventBus and state storage. |
| Daily check-in | Implemented active | `DailyCheckinSystem` tracks streaks and claims with reward emission. |
| Daily missions | Implemented active | `DailyMissionSystem` generates missions, tracks progress, and grants rewards. |
| Royal pass | Implemented active | `RoyalPassSystem` has pass XP/tier reward logic. |
| Leaderboard | Implemented active | `LeaderboardSystem` maintains cached rankings and publishes leaderboard updates. |
| Player profile view | Implemented active | `PlayerProfileSystem` builds public profile snapshots; `PlayerInspectSystem` publishes inspect data. |
| Flashlight sync | Implemented active | `FlashlightController.client.lua` and `FlashlightSyncSystem` wire flashlight toggle/aim. |
| FPV/TPV camera split | Implemented active | `CameraController.client.lua` locks FPV during match and allows TPV in lobby. |
| Movement runtime | Implemented active | `MovementController.client.lua` contains planar movement handling, sprint/jump setup, and telemetry. |
| Client evidence tools | Implemented active | `src/client/EvidenceTools` now implements the `6` evidence tools plus `Garam`, `Salib`, and `Dupa` utility adapters on the active `EvidenceRequest` path. |
| Core client UI | Implemented active | `src/client/UI/Main.lua` and runtime controllers support room browser, room state, password flow, inspect/event panels, and match-related UI. |

### 5.1 Recent Verified Runtime Result

Movement/teleport regression that caused player floating has been fixed in current codebase:

- `CameraController.client.lua` now sanitizes FPV arm clones from joints/constraints
- telemetry no longer shows the old pattern `Freefall + velY=0 + posY naik terus`
- latest user test passed for `1`, `2`, `3`, and `4` players

## 6. Implemented But Partial or Conflicted

These are real code paths, but they are not cleanly aligned with runtime truth.

| Area | Status | Current fact |
| --- | --- | --- |
| SystemRegistry load design | Resolved | `Initialize()` now applies explicit preload first, then `SYSTEM_GROUP_ORDER` / `SYSTEMS_BY_GROUP`, and only falls back to alphabetical order for uncategorized systems. |
| Non-autoloaded top-level subsystems | Resolved | Runtime now uses explicit autoload entries for non-`*System` folders that are required at boot. |
| `HorrorDirector` | Resolved | Included in `SystemRegistry` explicit runtime names and preload list. |
| `LobbySocialHub` | Resolved | Included in `SystemRegistry` explicit runtime names and preload list. |
| `EvidenceDeductionEngine` | Resolved | Included in `SystemRegistry` explicit runtime names and preload list. |
| Investigation flow | Improved | Journal/investigation/evidence deduction now read the same shared evidence-ghost map. |
| Ghost type source of truth | Resolved | Runtime ghost selection and shared data now use only the 12 Indonesian ghost set. |
| Evidence naming | Resolved | Runtime canonical evidence vocabulary is now `MEDOK/Suhu/BukuTerkutuk/To'un/Suara/Pengganggu` with canonical tool-ID mapping. |
| Difficulty source of truth | Improved | `shared/GameData/ModeDifficultyConfig.lua` remains the player-facing owner, `DifficultyModes.model.json` now contains `Easy/Normal/Hard/Nightmare`, and canonical `Uji Nyali` resolves to legacy `Nightmare` profile. |
| Classic mode design | Resolved | Classic room browser selection is now `AUTO`, Classic queue no longer buckets by named difficulty, and the final internal difficulty is server-balanced from party size and average player level. |
| Rank architecture | Resolved | Runtime now uses `RankedSystem` only; duplicate legacy rank runtime tree has been removed. |
| `RankedSystem` | Resolved | 8-tier Indonesian structure is retained, `Sang Ahli` now formats as a top-tier victory-counter rank instead of `Sang Ahli I`, and top-tier losses no longer decrease the canonical counter. |
| Rank/profile persistence | Resolved | `RankedSystem` now boots rank state from canonical profile data and syncs rank changes through `ProfileSystem` first, with persistence fallback only if the canonical owner is unavailable. |
| Progression/profile persistence | Resolved | `ProgressionSystem` now routes progression updates through `ProfileSystem` first, and the canonical owner persists progression in the shared profile shape. |
| Progression/data persistence | Resolved | `ProgressionSystem` now uses `LoadProfile`/`SaveProfile` instead of removed `GetData`/`SaveData` calls. |
| Profile source of truth | Improved | `ProfileSystem` now owns progression/stat/profile/rank load-save in canonical shape, and `PlayerProfileSystem` now reads that canonical snapshot for inspect payloads. Remaining risk is live DataStore validation, not local shape fragmentation. |
| Contract configuration | Resolved | `shared/GameData/ContractConfig.lua` now uses only active runtime map IDs, and the active contract generator derives its map pool from shared map metadata while excluding lobby-only maps. |
| Contract difficulty naming | Resolved | Contract config, generator output, and contract reward multipliers now accept canonical `Mudah/Lumayan/Angker/Uji Nyali`, with `Uji Nyali` bridged to `Nightmare` where legacy difficulty profiles are required. |
| Economy currencies | Resolved (runtime model) | Wallet model is now `MM/PP/Robux`, while `XP` remains progression-only and not wallet currency. |
| Canonical 5-tier rarity system | Resolved (runtime model) | Active shop/catalog items now use canonical `R1-R5` tiers with player-facing labels, the shop UI surfaces those labels, and active daily reward rarity rolls now reach all five tiers. |
| Gift system | Resolved (runtime model) | `PurchaseEvent` now resolves optional gift recipients, `ShopSystem` routes gift purchases into `SocialCommerceSystem`, and the active social-commerce path spends sender currency, grants/persists recipient cosmetics, and refunds sender currency on grant failure through `GiftPurchaseRefund`. |
| Full canonical 10-tool investigation set | Resolved (runtime model) | The already-active flashlight plus the `6` evidence tools are now joined by `Garam`, `Salib`, and `Dupa` on the active runtime path; `EvidenceGateway` accepts those requests; `EvidenceService` tracks salt/crucifix/smudge state; and `GhostSystem` consults crucifix/smudge protection before starting hunts. |
| Cosmetic lobby application | Resolved | `LobbySocialHub` now materializes equipped cosmetic snapshots into visible lobby-only character visuals and billboard flex labels, and reapplies them when the player respawns in the lobby. |
| Leaderboard meaning | Resolved | `LeaderboardSystem` now ranks by canonical rank progression and uses the `Sang Ahli` victory counter for top-tier placement instead of a local level/contract formula. |
| UI completeness | Resolved | `src/client/UI/Main.lua` no longer contains `MAP PLACEHOLDER` labels; room browser and room panel previews now render map name, size, floors, and category from shared map metadata. |
| Validation leftovers | Resolved | Active runtime client/server files no longer contain `TODO: REMOVE AFTER VALIDATION` markers; room trace logging is Studio-gated behind `ReplicatedStorage.PasrahRoomTrace`. |
| Studio persistence | Improved | `DataPersistenceService` still defaults to mock persistence in Studio, but it now supports explicit real-DataStore opt-in through `allowStudioDataStore` state or `ReplicatedStorage.PasrahUseStudioDataStore`, so Studio is no longer hard-blocked to mock only. |

## 7. Runtime Autoload Status (Updated)

Boot/autoload status after 2026-03-31 consistency execution:

- explicit runtime folders (`HorrorDirector`, `LobbySocialHub`, `EvidenceDeductionEngine`) are now in deterministic load path
- legacy server tree has been removed
- remaining non-`*System` folders in `src/ServerScriptService/Server` should be treated as legacy/auxiliary until explicitly wired

## 8. Not Found or Not Confirmed

These items were not found as active runtime implementations in this audit.

| Feature / system | Status | Current fact |
| --- | --- | --- |
| Evidence training gameplay system | Not found / not confirmed | No runtime `EvidenceTrainingSystem` or `TrainingSystem` implementation was found. Training building/zone geometry exists, but not a dedicated active training gameplay system. |
| Robux monetization flow | Not found / not confirmed | No `MarketplaceService`, `PromptProductPurchase`, `PromptGamePassPurchase`, or developer product purchase path was found in `src`. |
| Live-validated canonical rank persistence behavior | Not found / not confirmed | Runtime rank/profile persistence path is cleaner now, but live production-style DataStore behavior is still not verified outside Studio. |
| Live-validated classic auto-balance behavior | Not found / not confirmed | Runtime Classic now computes difficulty from party size and average player level, but this auto-balance path has not yet been verified in live gameplay. |
| Clean lobby flex gameplay system | Resolved (runtime model) | `LobbySocialHub` now turns `FlexZone` entry into a server-tracked spotlight built from live public-profile + equipped-cosmetic snapshot data, relays spotlight/participant payloads through `LobbyEvent`, and the active client profile/lobby UI surfaces that flex state. |

## 9. Spec vs Current Implementation

| Topic | Canonical target | Current code fact | Verdict |
| --- | --- | --- | --- |
| Evidence count | `6` | Runtime now uses canonical evidence set: `MEDOK`, `Suhu`, `BukuTerkutuk`, `To'un`, `Suara`, `Pengganggu`. | Match |
| Ghost count | `12` Indonesian ghosts | Runtime ghost list and shared ghost data now use only the 12 Indonesian set. | Match |
| Maps | `5` total | `5` maps exist in shared data: lobby + `4` investigation maps. | Match |
| Classic mode | dynamic, no named tiers exposed | Classic room browser selection is `AUTO`, queue matching no longer uses player-facing classic tiers, and final difficulty is server-balanced from party size plus average level. | Match |
| Ranked mode | active with rank-driven difficulty | active runtime now uses `RankedSystem` only (duplicate legacy rank runtime removed). | Match |
| Rank tiers | `8` canonical Indonesian tiers with specific division counts | `RankedSystem` state now follows canonical division counts. | Match |
| Currency system | `MM`, `PP`, `Robux` | runtime wallet model is `MM`, `PP`, `Robux`; `XP` stays progression-only. | Match |
| Rarity system | `5` tiers (`R1`-`R5`) | active shop catalog now uses canonical `R1-R5` tiers with player-facing rarity labels, and daily reward rarity rolls also use that same model | Resolved (runtime model) |
| Tools | `10` investigation tools | active runtime now includes built-in flashlight support, the `6` evidence tools, and `Garam`/`Salib`/`Dupa` adapters; server runtime models salt triggers, crucifix hunt prevention, and smudge repellent/sanity restore through `EvidenceSystem` + `GhostSystem` | Resolved (runtime model) |
| Match camera rules | FPV in match, TPV in lobby | current client camera code matches this | Match |
| Sanity system | required | current runtime has substantive `SanitySystem` | Match |
| Aggression system | required | current runtime has substantive `AggressionSystem` | Match |
| Spectator distortion | required | current runtime has substantive `SpectatorSystem` and spectator-related client systems | Match |
| Lobby training building | required in lobby design | geometry/zone code exists, but no dedicated training gameplay system was confirmed | Partial |
| Shop building | required | shop system exists | Match |
| Leaderboard building | required | leaderboard system exists | Match |
| Daily reward building | required | daily check-in system exists | Match |
| Flex zone | required | `FlexZone` now promotes entrants into a runtime spotlight using profile + cosmetic snapshot data, publishes the active spotlight/participants through `LobbyEvent`, and the client profile/lobby UI reads that live flex state | Resolved (runtime model) |

## 10. Active Client Runtime Snapshot

Confirmed active client-side runtime pieces:

- `CameraController.client.lua`
- `MovementController.client.lua`
- `FlashlightController.client.lua`
- `AtmosphericSetup.client.lua`
- `AudioManager.client.lua`
- `EvidenceVFX.client.lua`
- `SanityVFX.client.lua`
- `Core/ClientBootstrap.lua`
- `UI`
- `EvidenceTools`
- `SpectatorSystem`
- `GhostRenderer`
- `GhostAnimationPipeline`
- `SoundSystem`
- `EvidenceBoardSystem`
- `InvestigationUISystem`
- `GhostPredictionSystem`

Known client-side incompleteness:

- room browser map preview now reads shared map metadata instead of placeholder text
- the full `10`-tool runtime path now exists, but there is still no dedicated in-UI loadout/equip surface for selecting those utility tools during normal play

## 11. Legacy and Duplicate Tree Risk

Server duplicate-tree risk has been reduced.

- legacy server tree has been removed from repository runtime path
- active server source-of-truth is now only `src/ServerScriptService/Server`

Client duplicate tree:

`src/StarterPlayer/StarterPlayerScripts` is not the active runtime client path.

Legacy-only files there:

- `ClientBootstrap.client.lua`
- `DynamicAtmosphere.client.lua`
- `RoyalPassController.client.lua`

This duplicate tree is a real maintenance risk because it creates false confidence when scanning by folder structure only.

## 12. Critical Tech Debt Risks

Ordered by severity.

### 12.1 Boot path drift

Boot path is now aligned to active runtime tree, but generated docs still contain stale path snapshots.

Effects:

- documentation may still look valid while code has moved forward
- onboarding audits can misread stale generated indexes

### 12.2 Autoload Guard For Future Systems

Major non-`*System` dependencies are now explicitly autoloaded.

Residual risk:

- any future non-`*System` folder added without explicit registry entry can silently stay inactive

### 12.3 Split source of truth for ghost/evidence/rank data

Core runtime source-of-truth is now aligned with canonical naming and canonical tool-ID mapping.

Residual risk:

- old external payloads can still submit legacy naming and rely on alias conversion
- generated/static docs may still show pre-alignment terms

### 12.4 Profile/progression/rank persistence fragmentation

Current state:

- `ProfileSystem` now accepts progression/rank updates in canonical patch shape
- `ProgressionSystem` now uses `LoadProfile`/`SaveProfile`
- `RankedSystem` persists rank via `SaveProfile` rank patch

Effects:

- persistence shape is cleaner, but Studio runtime still cannot validate live DataStore behavior

### 12.5 Large duplicate legacy trees

Effects:

- server duplicate risk reduced (legacy server tree removed)
- client duplicate tree (`src/StarterPlayer/StarterPlayerScripts`) still exists and can cause edit-target mistakes

## 13. What Is Safe To Say Right Now

Without guessing:

- the game has a real playable room -> match -> investigation -> result architecture in code
- lobby room browser flow is genuinely implemented
- match teleport and FPV movement are currently stabilized
- ghost/evidence/sanity/aggression/spectator/economy/shop/cosmetic/inventory all have real implementations
- the biggest remaining issue is not total absence of systems, but inconsistency between boot path, data sources, and duplicate architectures

Also without guessing:

- not every documented feature is currently cleanly active in runtime
- documentation can still lag behind runtime autoload changes if not re-audited per execution
- the documentation set before this file was not a reliable snapshot of the repo's actual runtime state

## 14. Recommended End-to-End Gameplay Walkthrough Order

This is the order to use for the next visual/manual validation pass:

1. Spawn into lobby and confirm lobby camera is TPV.
2. Open room browser and verify create/join/leave/ready/password/kick.
3. Start host countdown and verify transition into match.
4. Confirm teleport into selected map and FPV lock.
5. Use the currently active `6` evidence tools and watch evidence feedback/UI.
6. Observe sanity drain, ghost activity, and hunt escalation behavior.
7. Verify death -> spectator transition if a player dies.
8. Verify ghost identification, result summary, and reward events.
9. Verify return-to-lobby flow and room state reset.
10. After visual validation, prioritize cleanup in this order: boot-path alignment.
11. Then clean ghost/evidence source-of-truth conflicts.
12. Then clean rank/progression persistence.
13. Then expand missing tool coverage.

## 15. Conclusion

Current repo reality:

- core gameplay loop is substantially implemented
- current runtime is not accurately represented by the older report files
- the most dangerous problems now are architectural drift and conflicting sources of truth, not total absence of code

This `REPORTS.md` is now the single authoritative runtime status file for this documentation folder.

## 16. Progress Update - 2026-03-31 (Comprehensive Alignment Pass)

Executed alignment decisions:

- Server runtime path: standardized to `src/ServerScriptService/Server`; legacy server tree removed from runtime source path.
- Ghost source-of-truth: synchronized to 12 Indonesian ghosts across active runtime tables and fallback config files.
- Evidence vocabulary: canonicalized to `MEDOK`, `Suhu`, `BukuTerkutuk`, `To'un`, `Suara`, `Pengganggu` in active deduction/spawn/validation flow.
- Rank owner: unified to `RankedSystem`; duplicate legacy rank runtime modules removed.
- Currency model: runtime wallet standardized to `MM/PP/Robux`; `XP` explicitly retained for progression/level pipeline.

Additional stabilization:

- `ReplicatedStorage/Config/GhostTypes.model.json` and `EvidenceCombinations.model.json` now match canonical 12-ghost evidence combinations.
- `EvidenceEngine` easy-mode supplemental pool now consumes canonical evidence IDs (not tool IDs).
- `EvidenceDeduction` normalization now preserves canonical evidence IDs (including `To'un`) to prevent spawn/collect mismatch.
- `EvidenceToolSystem` now maps active tool IDs directly to canonical evidence IDs.

Known residuals after this pass:

- Legacy ghost-personality modules with western naming have been removed from active runtime tree.
- Some historical/archival documentation outside runtime-critical documents can still mention old terms and should be treated as non-authoritative snapshots.

## 17. Progress Update - 2026-03-31 (Normalization Follow-up)

Follow-up normalization completed:

- Removed remaining legacy wallet fallback fields from reward/economy payload flow.
- Replaced ranked difficulty naming to `RankScore` across runtime lobby/match queue/service payload paths.
- Updated client/server evidence request type IDs to canonical Indonesian naming.
- Removed unused western-named ghost personality modules under `GhostPersonalitySystem/Personalities`.
- Regenerated `struktur folder.txt` with filtered active/operational scope to reduce legacy noise.

Residual scope intentionally not rewritten:

- `DATA TEXT/DOCUMENTATION/do not read/*` still contains historical legacy path references and is treated as archive material.

## 18. Progress Update - 2026-03-31 (Archive Isolation and Deletion)

Executed archive cleanup:

- Extracted archive-to-runtime mapping into `ARCHIVE_ISOLATION_ROADMAP_2026-03-31.md`.
- Deleted `DATA TEXT/DOCUMENTATION/do not read` after extraction.
- Preserved implementation direction by moving unresolved archive ideas into explicit backlog items in the new roadmap.

Runtime safety assessment:

- Deletion risk to runtime is low because archive files were markdown prompt/history artifacts and not loaded by boot/runtime systems.

Isolated implemented runtime anchors from archive topics:

- `src/client/Core/ClientBootstrap.lua`
- `src/client/UI/Main.lua`
- `src/client/UI/RoomBrowserController.lua`
- `src/ServerScriptService/Server/LobbySystem/{Main.lua,Controller.lua,Service.lua,RoomManager.lua}`
- `src/ServerScriptService/Server/MatchSystem/{Main.lua,Controller.lua,Service.lua,MatchService.lua,MatchQueue.lua}`

Isolated backlog moved to roadmap:

- queue anti-spam tap layer (no canonical `src/client/LobbyEventTap.client.lua` file)
- room browser debugger utility (no canonical `src/client/RoomBrowserDebugger.client.lua` file)
- performance dashboard/profiler surface (no canonical `src/client/PerformanceDashboard.client.lua` file)
- dev command consolidation from duplicate command entrypoints
- explicit decision needed for `src/ServerScriptService/Test.lua` and `src/ServerScriptService/PlayerCore.lua`

## 19. Progress Update - 2026-03-31 (Landing Base Runtime Purge)

Landing-base audit was executed against active boot chain:

- `default.project.json` mapping
- `src/ServerScriptService/Bootstrap.server.lua`
- `src/ServerScriptService/Server/ServerBootstrap.lua`
- `src/ServerScriptService/Server/Core/SystemRegistry.lua`

Removed as non-runtime or orphaned (unused in active boot path):

- `src/StarterPlayer/StarterPlayerScripts/*` (not mapped in active `default.project.json`)
- `src/ServerScriptService/PlayerCore.lua` (empty, no references)
- `src/ServerScriptService/Test.lua` (debug placeholder, no references)
- `src/ServerScriptService/SpawnPointsSetup.lua` (orphan module, no references)
- `src/ServerScriptService/Server/GameServer/*` (legacy bootstrap entry, no callers)
- `src/ServerScriptService/Server/Core/SystemSupervisor.lua` (only tied to deprecated bootstrap layer)
- `src/ServerScriptService/Server/Core/Bootstrap/*` (deprecated, not used by active runtime chain)
- `src/ServerScriptService/Server/Dev/*` (manual dev helpers, not loaded by runtime registry)
- `src/ServerScriptService/Server/dev_commands.lua` (proxy orphan)
- `src/ServerScriptService/Server/Phase4ValidationCommands.lua` (proxy orphan)

Post-purge state:

- `src/ServerScriptService` root now contains only active entry script `Bootstrap.server.lua`.
- `src/ServerScriptService/Server` file root now contains only `ServerBootstrap.lua`.
- No remaining source references to removed legacy bootstrap/dev modules in `src/ServerScriptService`.

## 20. Progress Update - 2026-03-31 (AI Super Context Sync)

Updated:

- `PASRAHPHOBIA_AI_SUPER_CONTEXT_V2.md` rewritten to runtime-aligned v2.1 baseline.

Synced topics:

- active boot chain and active runtime server path
- canonical 12 Indonesian ghosts
- canonical evidence vocabulary (`MEDOK`, `Suhu`, `BukuTerkutuk`, `To'un`, `Suara`, `Pengganggu`)
- mode/rank ownership (`RankedSystem` as single runtime owner)
- wallet model (`MM/PP/Robux`) with `XP` retained for progression
- landing-base purge outcomes and anti-regression rules

[STEP 1%]
G: Kurangi konflik ownership pada match flow dengan mematikan autoload dua sistem queue/match legacy yang berjalan paralel terhadap owner aktif.
C: Tambahkan `MatchmakingSystem` dan `ServerQueueSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`, sehingga runtime aktif tetap berpusat pada `LobbySystem` dan `MatchSystem`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Kedua sistem tersebut sama-sama subscribe event queue/match umum (`QueueUpdated`, `PartyCreated`, `MatchStarted`) dan membangun antrean/match sendiri, sehingga melanggar aturan `One domain = one owner` untuk alur match aktif.
N: Verifikasi runtime berikutnya: `MatchmakingSystem` dan `ServerQueueSystem` tidak lagi muncul dalam load order `SystemRegistry`, sementara room-browser -> queue -> `MatchSystem` tetap berjalan normal.

[STEP 2%]
G: Hentikan konflik payload event evidence dengan menjadikan `EvidenceService` satu-satunya publisher `EvidenceDetected`.
C: Hapus publish duplikat `EvidenceDetected` berbentuk string dari `EvidenceGateway`; gateway sekarang hanya mengembalikan response remote, sedangkan event evidence tetap dipublikasikan oleh `EvidenceService` dalam payload tabel kanonik.
F: src/ServerScriptService/Server/EvidenceSystem/EvidenceGateway.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Sebelumnya `EvidenceGateway` mem-publish `EvidenceDetected` sebagai string (termasuk bentuk display `"Buku Terkutuk"`), sementara `EvidenceService` mem-publish event yang sama sebagai tabel dengan `evidenceType` kanonik. Ini menciptakan dua kontrak event untuk nama event yang sama.
N: Verifikasi runtime berikutnya: subscriber `EvidenceDetected` menerima hanya payload tabel dari `EvidenceService`, sehingga journal/deduction tidak lagi berisiko menerima shape campuran.

[STEP 3%]
G: Selaraskan subscriber evidence state agar tetap bekerja setelah `EvidenceDetected` distandarkan ke payload tabel kanonik.
C: Ubah `EvidenceEngine` supaya menerima dua bentuk input sementara (`string` legacy atau `table` kanonik), lalu menormalisasi ke satu `evidenceName` sebelum memperbarui `EvidenceStateUpdated`.
F: src/ServerScriptService/Server/EvidenceSystem/EvidenceEngine/EvidenceEngine.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Setelah STEP 2%, publisher aktif tinggal `EvidenceService` yang mengirim payload tabel. Tanpa penyesuaian subscriber, state evidence internal tidak akan pernah ter-update karena `EvidenceEngine` sebelumnya hanya menerima string.
N: Verifikasi runtime berikutnya: event `EvidenceDetected` berbentuk tabel tetap menghasilkan `EvidenceStateUpdated` untuk evidence kanonik yang sama.

[STEP 4%]
G: Hapus sisa jalur naming evidence alternatif di gateway agar satu domain evidence tidak lagi punya helper nama duplikat yang tidak dipakai.
C: Buang helper `_resolveEvidenceName` dan `_isEvidenceNameValid` dari `EvidenceGateway` karena publish `EvidenceDetected` string sudah dihapus pada STEP 2 dan gateway tidak lagi menjadi owner nama evidence.
F: src/ServerScriptService/Server/EvidenceSystem/EvidenceGateway.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Menyisakan helper lama setelah publisher duplikat dihapus akan mempertahankan jalur naming kedua yang membingungkan dan berpotensi dipakai lagi tanpa sadar pada perubahan berikutnya.
N: Verifikasi statik berikutnya: `EvidenceGateway` tidak lagi memiliki helper resolusi/validasi nama evidence yang tidak terpakai.

[STEP 5%]
G: Hapus dependency evidence-config yang tidak lagi dipakai di gateway agar owner evidence config tidak direferensikan tanpa kebutuhan runtime.
C: Buang resolver `EvidenceConfigSystem` dan field `_evidenceConfigSystem` dari `EvidenceGateway` karena seluruh penggunaan dependency itu sudah ikut hilang pada STEP 4.
F: src/ServerScriptService/Server/EvidenceSystem/EvidenceGateway.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Dependency yang tidak digunakan memperbesar permukaan coupling antar sistem dan membuat pembaca seolah gateway masih berwenang memvalidasi nama evidence, padahal ownership naming sudah dipusatkan di jalur evidence utama.
N: Verifikasi statik berikutnya: `EvidenceGateway` tidak lagi resolve atau menyimpan `EvidenceConfigSystem`.

[STEP 6%]
G: Buang loader tipe-evidence bersama yang tidak lagi dipakai di gateway agar jalur remote evidence tidak membawa source-of-truth bayangan.
C: Hapus `resolveSharedEvidenceTypes()` dan konstanta `EVIDENCE_TYPES` dari `EvidenceGateway` karena tidak pernah dipakai dalam validasi atau response gateway aktif.
F: src/ServerScriptService/Server/EvidenceSystem/EvidenceGateway.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Menyisakan loader source-of-truth yang tidak digunakan membuat file tampak masih mengambil keputusan berbasis tabel evidence sendiri, padahal gateway sekarang hanya memvalidasi request type dan meneruskan ke service evidence utama.
N: Verifikasi statik berikutnya: tidak ada lagi simbol `resolveSharedEvidenceTypes` atau `EVIDENCE_TYPES` di `EvidenceGateway`.

[STEP 7%]
G: Kunci subscriber evidence state ke kontrak event kanonik sekarang bahwa `EvidenceDetected` selalu berbentuk tabel.
C: Hapus fallback string sementara dari `EvidenceEngine.resolveEvidenceName()` karena publisher runtime yang tersisa (`EvidenceService` dan `EvidenceToolSystem`) sama-sama mengirim payload tabel dengan `evidenceType`.
F: src/ServerScriptService/Server/EvidenceSystem/EvidenceEngine/EvidenceEngine.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Kompatibilitas legacy hanya berguna saat ada publisher string yang masih aktif. Setelah STEP 2 dan audit publisher aktif, mempertahankan fallback itu justru melemahkan kontrak event yang sudah disederhanakan.
N: Verifikasi statik berikutnya: `EvidenceEngine` mengabaikan payload `EvidenceDetected` non-table dan hanya mengambil `evidenceType/evidenceName` dari payload tabel.

[STEP 8%]
G: Cegah kebocoran state evidence antar match yang bisa membuat evidence match berikutnya tidak lagi memicu update state.
C: Reset `evidenceState` di `EvidenceEngine:StartMatch()` dan `EvidenceEngine:EndMatch()`, lalu publish `EvidenceStateUpdated` kosong setelah reset agar subscriber tidak membawa sisa state dari match sebelumnya.
F: src/ServerScriptService/Server/EvidenceSystem/EvidenceEngine/EvidenceEngine.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Sebelumnya `evidenceState` hidup sebagai tabel global module-level dan tidak pernah dibersihkan. Begitu satu evidence pernah ditandai `true`, deteksi match berikutnya untuk evidence yang sama bisa diam-diam tidak mem-publish update lagi.
N: Verifikasi runtime berikutnya: awal match memulai `EvidenceStateUpdated` kosong dan evidence yang sama tetap bisa terdeteksi ulang pada match berikutnya.

[STEP 9%]
G: Tegakkan satu owner untuk domain deteksi evidence dengan menonaktifkan autoload `EvidenceToolSystem` yang menjadi publisher `EvidenceDetected` kedua.
C: Tambahkan `EvidenceToolSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`, sehingga deteksi evidence runtime aktif tetap melewati `EvidenceSystem`/`EvidenceGateway` dan tidak punya publisher paralel untuk event yang sama.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit runtime menunjukkan client aktif memakai `EvidenceRequest` ke `EvidenceSystem`, sementara `EvidenceToolSystem` tetap autoloaded dan mem-publish `EvidenceDetected` dari stack `ToolActivated`/`ToolSignalReceived` yang tidak direferensikan sebagai service aktif. Ini melanggar prinsip `one domain = one owner`.
N: Verifikasi runtime berikutnya: `EvidenceToolSystem` tidak lagi muncul dalam load order registry, sementara tool evidence aktif tetap berjalan lewat `EvidenceRequest`.

[STEP 10%]
G: Matikan tahap pemrosesan sinyal tool yang sekarang yatim setelah owner evidence duplikat dinonaktifkan.
C: Tambahkan `ToolSignalProcessingSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry` karena event `ToolSignalReceived` yang dihasilkannya hanya dipakai oleh `EvidenceToolSystem`, yang sudah dikeluarkan dari autoload pada STEP 9.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Membiarkan sistem ini tetap aktif hanya menghasilkan event internal tambahan tanpa konsumen runtime aktif, memperbesar permukaan event dan memelihara stack deteksi evidence alternatif yang sudah tidak menjadi owner.
N: Verifikasi runtime berikutnya: `ToolSignalProcessingSystem` tidak lagi muncul dalam load order registry.

[STEP 11%]
G: Tutup sisa publisher event tool internal yang tidak lagi punya konsumen runtime aktif setelah stack signal evidence alternatif dimatikan.
C: Tambahkan `ToolInteractionSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry` karena event `ToolActivated` yang dipublikasikannya hanya dikonsumsi oleh `ToolSignalProcessingSystem` dan `EvidenceToolSystem`, yang keduanya sudah dikeluarkan dari autoload.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Setelah STEP 9-10, mempertahankan `ToolInteractionSystem` hanya menyisakan publisher event yatim dan jalur tool alternatif yang tidak dipakai client aktif (`EvidenceRequest` tetap menjadi jalur tool evidence aktif).
N: Verifikasi runtime berikutnya: `ToolInteractionSystem` tidak lagi muncul dalam load order registry.

[STEP 12%]
G: Hilangkan publisher UI/journal evidence yang tumpang tindih dengan `JournalSystem` pada runtime aktif.
C: Tambahkan `EvidenceJournalSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry` karena sistem ini mem-publish `UIEvidenceUpdated` dan `JournalUpdated` parsial di samping `JournalSystem`, sementara event uniknya (`UIEvidenceStateUpdated`) tidak dikonsumsi client aktif.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: `InvestigationUISystem` dan `EvidenceBoardSystem` menimpa state berdasarkan payload event terakhir. Membiarkan `EvidenceJournalSystem` aktif membuat payload parsial berisiko menimpa snapshot jurnal/evidence yang lebih lengkap dari `JournalSystem`.
N: Verifikasi runtime berikutnya: `EvidenceJournalSystem` tidak lagi muncul dalam load order registry, dan update jurnal/UI evidence datang dari `JournalSystem` saja.

[STEP 13%]
G: Hilangkan duplikasi update kandidat ghost di jalur deduction tanpa mematikan publisher UI prediction aktif.
C: Hapus publish `GhostCandidatesUpdated` dari `GhostDeductionJournal`; sistem ini sekarang hanya mengirim `UIGhostPredictionUpdated`, sementara event server-side `GhostCandidatesUpdated` tetap datang dari jalur deduction/evidence utama.
F: src/ServerScriptService/Server/GhostDeductionJournal/Service.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit subscriber menunjukkan `GhostCandidatesUpdated` hanya dipakai `JournalSystem`. Membiarkan `GhostDeductionJournal` ikut mem-publish event yang sama menambah sumber update server-side tanpa memberi nilai tambah, sementara UI client tetap membutuhkan `UIGhostPredictionUpdated` dari sistem ini.
N: Verifikasi statik berikutnya: `GhostDeductionJournal` masih mem-publish `UIGhostPredictionUpdated` tetapi tidak lagi mem-publish `GhostCandidatesUpdated`.

[STEP 14%]
G: Kurangi publisher kandidat ghost server-side yang berlapis tanpa memutus API deduction engine yang masih dipakai `InvestigationSystem`.
C: Hapus publish `GhostCandidatesUpdated` dari `EvidenceDeductionEngine:CalculateCandidates()`; engine tetap menghitung kandidat dan mempertahankan history/state internal, tetapi event kandidat server-side tetap datang dari jalur evidence utama.
F: src/ServerScriptService/Server/EvidenceDeductionEngine/Service.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit event menunjukkan `GhostCandidatesUpdated` dipublikasikan oleh lebih dari satu sistem, sementara client aktif tidak membaca event ini secara langsung. Menghapus publish duplikat dari `EvidenceDeductionEngine` menurunkan konflik tanpa memutus dependency `InvestigationSystem` pada service ini.
N: Verifikasi statik berikutnya: `EvidenceDeductionEngine` tidak lagi mem-publish `GhostCandidatesUpdated`.

[STEP 15%]
G: Hapus publisher kandidat ghost duplikat lain dari `InvestigationSystem` sambil mempertahankan state investigasi internal dan identifikasi ghost.
C: Buang publish `GhostCandidatesUpdated` dari `InvestigationSystem:UpdateGhostCandidates()`; sistem ini tetap menyimpan `possibleGhosts` dan masih memanggil `ConfirmGhost()` saat kandidat tinggal satu.
F: src/ServerScriptService/Server/InvestigationSystem/Service.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: `InvestigationSystem` dipicu oleh `EvidenceCollected`, sama seperti jalur evidence utama. Membiarkannya ikut mem-publish `GhostCandidatesUpdated` mempertahankan dua sumber event kandidat untuk evidence yang sama.
N: Verifikasi statik berikutnya: `InvestigationSystem` tidak lagi mem-publish `GhostCandidatesUpdated`, tetapi masih mengelola `possibleGhosts` dan `GhostIdentified`.

[STEP 16%]
G: Lepas subscription evidence-state yang tidak dipakai dari `EvidenceDeductionEngine` agar engine tidak lagi memelihara event output tanpa konsumen.
C: Hapus subscription `EvidenceStateUpdated -> GhostPossibilitiesUpdated` dari `EvidenceDeductionEngine:Start()/Stop()`; engine tetap berjalan sebagai service deduction dan masih bereaksi pada `EvidenceCollected/EvidenceRemoved` via controller.
F: src/ServerScriptService/Server/EvidenceDeductionEngine/Service.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit event menunjukkan `GhostPossibilitiesUpdated` tidak punya consumer aktif. Menyisakan subscription itu hanya menambah coupling dan kerja event bus tanpa kontribusi ke runtime utama.
N: Verifikasi statik berikutnya: `EvidenceDeductionEngine` tidak lagi subscribe ke `EvidenceStateUpdated` atau mem-publish `GhostPossibilitiesUpdated`.

[STEP 17%]
G: Hentikan mode event-driven `EvidenceDeductionEngine` yang sudah tidak diperlukan, sambil mempertahankan engine sebagai provider data/service untuk `InvestigationSystem`.
C: Ubah `EvidenceDeductionEngine:Start()` dan `:Stop()` agar hanya menjalankan service; controller tidak lagi didaftarkan ke event bus karena jalur reactive-nya sudah dipreteli pada STEP 14 dan STEP 16.
F: src/ServerScriptService/Server/EvidenceDeductionEngine/Main.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Satu-satunya dependency aktif yang terkonfirmasi adalah `InvestigationSystem`, dan itu memakai engine ini sebagai sumber database deduction, bukan sebagai subscriber event runtime. Menyalakan controller hanya menambah permukaan wiring tanpa pemakai aktif.
N: Verifikasi statik berikutnya: `EvidenceDeductionEngine` tetap bisa di-resolve sebagai service, tetapi tidak lagi memulai controller event bus saat boot.

[STEP 18%]
G: Perbaiki kontrak data antara `EvidenceDeductionEngine` dan `InvestigationSystem` agar database evidence-ghost benar-benar bisa diambil lewat API yang dicari consumer.
C: Tambahkan `EvidenceDeductionEngine:GetGhostEvidenceMap()` yang menurunkan map `ghostName -> evidenceList` dari state `ghostDatabase`, sehingga helper `getDatabaseFromDeductionEngine()` di `InvestigationSystem` mendapatkan bentuk data yang sesuai.
F: src/ServerScriptService/Server/EvidenceDeductionEngine/Main.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Sebelumnya `InvestigationSystem` mencoba `GetGhostDatabase()/GetGhostEvidenceMap()`, tetapi engine tidak mengekspos keduanya. Akibatnya jalur dependency ini berisiko selalu jatuh ke `nil` meski engine menyimpan database internal.
N: Verifikasi statik berikutnya: `EvidenceDeductionEngine` memiliki method `GetGhostEvidenceMap()` dan mengembalikan map berbasis state `ghostDatabase`.

[STEP 19%]
G: Hapus wiring controller mati dari `EvidenceDeductionEngine` setelah engine dipersempit menjadi provider service/data-only.
C: Buang `require`/instansiasi `Controller`, serta panggilan `Controller:Create()` dan `Controller:Init()` dari `EvidenceDeductionEngine/Main.lua` karena controller tidak lagi dipakai sejak STEP 17.
F: src/ServerScriptService/Server/EvidenceDeductionEngine/Main.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Menyisakan objek controller yang tidak pernah di-start tetap menambah biaya inisialisasi dan membuat struktur engine tampak event-driven padahal peran aktifnya sekarang hanya sebagai provider data/service.
N: Verifikasi statik berikutnya: `EvidenceDeductionEngine/Main.lua` tidak lagi require atau membuat `Controller`.

[STEP 20%]
G: Kembalikan kepemilikan `confirmedEvidence` ke `JournalSystem` aktif setelah `EvidenceJournalSystem` dinonaktifkan.
C: Tambahkan handler `OnEvidenceValidated` di `JournalSystem/Service.lua`, subscribe event itu dari `JournalSystem/Controller.lua`, lalu perbarui snapshot jurnal/UI evidence dari owner aktif saat validasi sukses masuk.
F: src/ServerScriptService/Server/JournalSystem/Service.lua; src/ServerScriptService/Server/JournalSystem/Controller.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Field `confirmedEvidence` masih dipakai snapshot jurnal dan client `EvidenceBoardSystem`, tetapi setelah owner jurnal duplikat dimatikan tidak ada lagi penulis aktif untuk field itu. Tanpa langkah ini, evidence valid hanya tampil sebagai discovered, bukan confirmed.
N: Verifikasi statik berikutnya: `JournalSystem` subscribe `EvidenceValidated`, memiliki `OnEvidenceValidated`, dan `confirmedEvidence` diisi dari payload validasi sukses.

[STEP 21%]
G: Samakan kontrak UI jurnal aktif dengan client yang menunggu remote `JournalUpdated`.
C: Ubah `JournalSystem/Service.lua` agar `_publishJournalUpdated` bukan hanya publish ke event bus, tetapi juga mengirim snapshot `JournalUpdated` lewat `EvidenceEvent` ke player pemilik jurnal.
F: src/ServerScriptService/Server/JournalSystem/Service.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: `InvestigationUISystem` menunggu `eventName == "JournalUpdated"` dari remote, tetapi owner jurnal aktif hanya publish event bus. Tanpa emit remote ini, state jurnal di client tidak pernah terisi meski server snapshot sudah berubah.
N: Verifikasi statik berikutnya: `JournalSystem/_publishJournalUpdated` memanggil `_emitUIEvent("JournalUpdated", ...)` dan tiap pemanggil utama meneruskan `player`/`matchId` saat tersedia.

[STEP 22%]
G: Hilangkan publish ganda `JournalUpdated` yang muncul setelah snapshot jurnal mulai dikirim ke remote client.
C: Pisahkan helper kirim-remote dari helper publish bus di `JournalSystem/Service.lua`, lalu buat `_publishJournalUpdated` publish ke event bus sekali saja dan kirim remote `JournalUpdated` tanpa republish.
F: src/ServerScriptService/Server/JournalSystem/Service.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Menggunakan `_emitUIEvent("JournalUpdated", ...)` di dalam `_publishJournalUpdated` membuat `JournalUpdated` dipublikasikan dua kali ke event bus: sekali eksplisit dan sekali lagi dari helper UI. Ini langsung melanggar target `no conflicts/no duplicate systems` pada level event owner.
N: Verifikasi statik berikutnya: `_publishJournalUpdated` memanggil `_sendRemoteEvent("JournalUpdated", ...)`, sedangkan `_emitUIEvent` tetap menjadi jalur publish+remote untuk event UI lain.

[STEP 23%]
G: Tegakkan `MatchSystem` sebagai satu-satunya owner match dari sisi `LobbySystem`.
C: Hapus fallback `resolveStandaloneMatchService()` di `LobbySystem/Service.lua`, sehingga jalur queue/browser hanya menerima `MatchSystem` yang datang dari registry/dependency aktif dan tidak pernah membuat service match bayangan sendiri.
F: src/ServerScriptService/Server/LobbySystem/Service.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Fallback ini dapat `require` dan `Start()` `MatchSystem/Service.lua` secara manual ketika lookup gagal. Itu menciptakan owner match kedua di luar boot order `SystemRegistry`, persis pola konflik yang prompt minta dihapus.
N: Verifikasi statik berikutnya: `LobbySystem/Service.lua` tidak lagi memiliki `resolveStandaloneMatchService` atau `_standaloneMatchService`, dan `_getMatchSystem()` hanya mengembalikan owner match dari dependency/registry aktif.

[STEP 24%]
G: Cegah sukses palsu pada room-browser queue saat owner match aktif tidak tersedia.
C: Pindahkan pengecekan `_getMatchSystem()` ke awal `LobbySystem:QueueFromRoomBrowser()`, sehingga publish `MatchmakingStarted` hanya terjadi jika `MatchSystem` kanonik memang berhasil di-resolve.
F: src/ServerScriptService/Server/LobbySystem/Service.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Sebelumnya cabang event-bus langsung `return true` setelah publish `MatchmakingStarted`. Jika `MatchSystem` tidak aktif/ter-register, UI room browser akan menerima sukses palsu padahal tidak ada owner yang bisa memproses queue menjadi match.
N: Verifikasi statik berikutnya: `QueueFromRoomBrowser()` memeriksa `_getMatchSystem()` sebelum publish `MatchmakingStarted`.

[STEP 25%]
G: Jadikan wiring `LobbySystem` idempoten agar start berulang tidak menggandakan listener room/match aktif.
C: Tambahkan guard `_handlersRegistered` di `LobbySystem/Controller.lua`, sehingga `RegisterEventHandlers()` tidak lagi menambah `PlayerAdded/PlayerRemoving` connection dan subscription `MatchStarted/MatchEnded` lebih dari sekali.
F: src/ServerScriptService/Server/LobbySystem/Controller.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Controller ini sudah menjaga koneksi remote tunggal, tetapi belum menjaga connection/subscription lain. Jika `Start()` dipanggil ulang, lobby owner bisa memproses join/leave/match event dua kali untuk pemain yang sama.
N: Verifikasi statik berikutnya: `LobbySystem/Controller` memiliki `_handlersRegistered` dan `RegisterEventHandlers()` early-return saat sudah aktif.

[STEP 26%]
G: Jadikan owner `LobbySocialHub` juga idempoten terhadap start berulang.
C: Tambahkan guard `_handlersRegistered` di `LobbySocialHub/Controller.lua`, sehingga connection `PlayerAdded/PlayerRemoving` dan subscription `PlayerTeleported` tidak ditumpuk saat lifecycle `Start()` dipanggil lagi.
F: src/ServerScriptService/Server/LobbySocialHub/Controller.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: `LobbySocialHub` adalah owner aktif presence lobby. Tanpa guard ini, restart/controller re-entry dapat mendaftarkan pemain yang sama berkali-kali dan memproses teleport lobby lebih dari sekali.
N: Verifikasi statik berikutnya: `LobbySocialHub/Controller` memiliki `_handlersRegistered` dan `RegisterEventHandlers()` early-return saat sudah aktif.

[STEP 27%]
G: Jadikan wiring `RankedSystem` idempoten agar hasil match tidak diproses berulang saat lifecycle start terpicu lagi.
C: Tambahkan guard `_handlersRegistered` di `RankedSystem/Controller.lua`, sehingga subscription `MatchEnded` dan `ResultsCalculated` tidak ditumpuk pada start berikutnya.
F: src/ServerScriptService/Server/RankedSystem/Controller.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: `RankedSystem` adalah owner rank aktif. Tanpa guard ini, satu hasil match dapat diterapkan lebih dari sekali ke update rank jika controller diregistrasikan ulang.
N: Verifikasi statik berikutnya: `RankedSystem/Controller` memiliki `_handlersRegistered` dan `RegisterEventHandlers()` early-return saat sudah aktif.

[STEP 28%]
G: Jadikan `DataPersistenceService` idempoten agar autosave/player hook tidak berlipat saat start berulang.
C: Tambahkan guard `_handlersRegistered` di `DataPersistenceService/Controller.lua`, sehingga connection `PlayerAdded`, `PlayerRemoving`, dan `Heartbeat` tidak ditumpuk pada lifecycle berikutnya.
F: src/ServerScriptService/Server/DataPersistenceService/Controller.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Untuk owner persistence, duplikasi listener lebih berbahaya: ia bisa memicu register/save/unregister ganda dan menjalankan lebih dari satu loop autosave `Heartbeat`.
N: Verifikasi statik berikutnya: `DataPersistenceService/Controller` memiliki `_handlersRegistered` dan `RegisterEventHandlers()` early-return saat sudah aktif.

[STEP 29%]
G: Pulihkan kontrak `MatchEnded` dari owner match aktif ke subscriber server dan UI client.
C: Tambahkan publish event-bus `MatchEnded` dan remote `MatchEnded` di `MatchSystem/MatchService.lua`, memakai payload match final yang tetap menyertakan `results` sekaligus meratakan field ringkasan hasil ke level atas untuk UI aktif.
F: src/ServerScriptService/Server/MatchSystem/MatchService.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit menunjukkan puluhan subscriber aktif menunggu `MatchEnded`, tetapi `MatchSystem` hanya mem-publish `MatchStarted`. Tanpa event ini, cleanup lanjutan, reward, telemetry, rank, jurnal, dan UI hasil match tidak pernah menerima sinyal selesai resmi dari owner match.
N: Verifikasi statik berikutnya: `MatchService:EndMatch()` memanggil `_publish("MatchEnded", payload)` dan `_fireMatchEventToPlayers(..., { eventName = "MatchEnded", ... })`.

[STEP 30%]
G: Kunci trigger update rank ke event hasil match kanonik yang benar-benar dipublikasikan runtime aktif.
C: Hapus subscription `ResultsCalculated` dan handler terkait dari `RankedSystem/Controller.lua`, sehingga `RankedSystem` hanya memproses `MatchEnded` dari owner `MatchSystem`.
F: src/ServerScriptService/Server/RankedSystem/Controller.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Setelah audit, publisher aktif untuk hasil match adalah `MatchEnded` dari `MatchSystem`, sedangkan `ResultsCalculated` tidak ditemukan pada jalur runtime aktif. Menyisakan kedua trigger hanya membuka peluang rank diterapkan dua kali bila event legacy hidup kembali.
N: Verifikasi statik berikutnya: `RankedSystem/Controller.lua` tidak lagi berisi `ResultsCalculated` atau `OnResultsCalculated`.

[STEP 31%]
G: Bersihkan sisa instrumentation validasi dari owner `LobbySystem` agar runtime aktif tidak terus mem-print trace room browser.
C: Gate trace `[ROOM TRACE]` pada `src/client/UI/RoomBrowserController.lua` di balik attribute Studio `ReplicatedStorage.PasrahRoomTrace`, dan pastikan marker `TODO: REMOVE AFTER VALIDATION` tidak tersisa di runtime aktif.
F: src/client/UI/RoomBrowserController.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Trace room browser masih berguna untuk debug Studio, tetapi tidak boleh selalu aktif di runtime normal karena hanya menambah noise log pada setiap request dan response lobby aktif.
N: Verifikasi statik berikutnya: runtime aktif tidak lagi berisi `TODO: REMOVE AFTER VALIDATION`, dan trace `[ROOM TRACE]` hanya muncul jika `ReplicatedStorage.PasrahRoomTrace == true` di Studio.

[STEP 32%]
G: Perbaiki log bootstrap agar tidak salah menandai server live sebagai API-disabled.
C: Ganti check `apiEnabled()` berbasis `RunService:IsStudio()` di `Bootstrap.server.lua` menjadi deteksi runtime Studio vs live, lalu ubah pesan startup supaya tidak mengklaim status API Services yang sebenarnya tidak diuji.
F: src/ServerScriptService/Bootstrap.server.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: `RunService:IsStudio()` hanya memberi tahu apakah runtime berada di Studio, bukan apakah API Services aktif. Sebelumnya server live akan masuk cabang `false` dan mem-print warning menyesatkan bahwa API dimatikan.
N: Verifikasi statik berikutnya: `Bootstrap.server.lua` memakai helper `isStudioRuntime()` dan pesan startup tidak lagi berbunyi `API Services are disabled`.

[STEP 33%]
G: Kurangi noise log dari owner `MatchSystem` pada jalur queue dan start yang berjalan terus-menerus.
C: Hapus debug print `MatchQueue join`, `Attempting match creation`, dan trace `Preparing/Started sent` dari `MatchSystem/MatchService.lua`.
F: src/ServerScriptService/Server/MatchSystem/MatchService.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Setelah kontrak queue/start distabilkan, print per-match ini hanya memenuhi output server tanpa membantu recovery bug aktif.
N: Verifikasi statik berikutnya: `MatchSystem/MatchService.lua` tidak lagi berisi string debug `Attempting match creation`, `Preparing sent`, `Started sent`, atau `MatchQueue join`.

[STEP 34%]
G: Hapus trace queue-entry yang masih tersisa dari jalur antrean match aktif.
C: Buang print `"[MatchQueue] Player joined queue"` dari `MatchSystem/MatchQueue.lua`.
F: src/ServerScriptService/Server/MatchSystem/MatchQueue.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Setelah trace utama di `MatchService` dibersihkan, print ini menjadi sisa noise per-player pada antrean aktif tanpa memberi sinyal error atau recovery.
N: Verifikasi statik berikutnya: `MatchSystem/MatchQueue.lua` tidak lagi berisi string `Player joined queue`.

[STEP 35%]
G: Bersihkan trace builder yang masih tersisa dari owner `MatchSystem`.
C: Hapus print `"[MatchBuilder] Match created"` dari `MatchSystem/MatchBuilder.lua`.
F: src/ServerScriptService/Server/MatchSystem/MatchBuilder.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Builder aktif tidak memerlukan print ini untuk operasi normal; ia hanya menambah noise setiap match dibentuk.
N: Verifikasi statik berikutnya: `MatchSystem/MatchBuilder.lua` tidak lagi berisi string `Match created`.

[STEP 36%]
G: Kurangi noise cleanup match tanpa menghilangkan sinyal warning kegagalan.
C: Hapus print non-error dari `MatchSystem/MatchCleanup.lua` untuk teleported player, destroy folder, start cleanup, dan ringkasan sukses; warning kegagalan tetap dipertahankan.
F: src/ServerScriptService/Server/MatchSystem/MatchCleanup.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Cleanup match adalah jalur yang sering dipanggil dan log sukses detailnya cepat memenuhi output server, sedangkan sinyal yang benar-benar penting adalah warning saat cleanup gagal.
N: Verifikasi statik berikutnya: `MatchSystem/MatchCleanup.lua` tidak lagi berisi print sukses `Match cleanup complete`, `Destroyed match folder`, atau `Teleported`.

[STEP 37%]
G: Hapus trace info berlebih dari jalur teleport match aktif sambil mempertahankan warning kegagalan spawn/map.
C: Buang print info dari `MatchSystem/MatchTeleport.lua` untuk template map, anchor/spawn sample, floor clearance, spawn sukses, dan ringkasan teleport; warning validasi dan fail-safe tetap dipertahankan.
F: src/ServerScriptService/Server/MatchSystem/MatchTeleport.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Teleport match adalah jalur yang sangat ramai saat testing dan runtime. Print info per-player/per-map cepat membanjiri output, sedangkan warning pada spawn invalid, map hilang, atau fail-safe masih cukup untuk diagnosis.
N: Verifikasi statik berikutnya: `MatchSystem/MatchTeleport.lua` tidak lagi berisi print info `Using map template`, `Spawn sample`, `Spawn clearance`, `Spawned`, atau `Teleported players to map`.

[STEP 38%]
G: Rapikan sisa dead code setelah pembersihan trace `MatchTeleport`.
C: Hapus local anchor/sample yang tidak lagi dipakai, serta ganti binding `safeSpawnCFrame, usedSpawn` menjadi nilai tunggal karena info spawn sukses sudah tidak dicetak lagi.
F: src/ServerScriptService/Server/MatchSystem/MatchTeleport.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Menyisakan local mati setelah penghapusan trace membuat file lebih bising untuk dibaca dan dapat memicu lint/peringatan internal tanpa memberi nilai runtime.
N: Verifikasi statik berikutnya: blok teleport tidak lagi memiliki local `mapAnchorCFrame`, `mapAnchorName`, `firstSpawnCFrame`, `_delta`, atau `usedSpawn`.

[STEP 39%]
G: Sambungkan hasil match kaya-data ke UI aktif tanpa mengubah owner lifecycle `MatchEnded`.
C: Tambahkan forward remote `MatchCompleted` di `MatchResultSystem/Service.lua`, lalu buat `client/UI/Main.lua` memperlakukan `MatchCompleted` seperti update hasil match yang sama dengan `MatchEnded`.
F: src/ServerScriptService/Server/MatchResultSystem/Service.lua; src/client/UI/Main.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: `MatchSystem` kini sudah mem-publish `MatchEnded`, tetapi payload kaya seperti `ghostType`, `correctGuess`, dan `evidenceCollected` justru dihitung belakangan oleh `MatchResultSystem` sebagai `MatchCompleted`. Tanpa mengalirkan event ini ke client, layar hasil tetap miskin data walau server sudah menghitungnya.
N: Verifikasi statik berikutnya: `MatchResultSystem` mengirim remote `eventName = "MatchCompleted"` ke pemain match, dan `UI/Main.lua` menangani `MatchCompleted` pada cabang hasil yang sama dengan `MatchEnded`.

[STEP 40%]
G: Isi reward hasil match di UI aktif dari kalkulasi reward kanonik tanpa mengganggu lifecycle match event.
C: Tambahkan remote `MatchRewardSummary` di `RewardCalculationSystem/Service.lua` setelah reward pemain dihitung, lalu buat `client/UI/Main.lua` menggabungkan `currencyReward/xpReward` dari event itu ke result card yang sudah terbuka.
F: src/ServerScriptService/Server/RewardCalculationSystem/Service.lua; src/client/UI/Main.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Setelah STEP 39, UI sudah menerima data hasil investigasi, tetapi nilai reward masih `0` karena reward final baru dihitung belakangan oleh `RewardCalculationSystem`. Event terpisah ini menjaga `MatchEnded/MatchCompleted` tetap fokus pada lifecycle+result, sementara reward masuk sebagai update lanjutan yang aman.
N: Verifikasi statik berikutnya: `RewardCalculationSystem` mengirim remote `eventName = "MatchRewardSummary"` dan `UI/Main.lua` punya cabang handler untuk `MatchRewardSummary`.

[STEP 41%]
G: Hentikan distribusi reward match ganda dengan menegakkan satu owner reward endgame aktif.
C: Hapus subscription `MatchEnded` dan handler `OnMatchEnded` dari `EconomySystem/Controller.lua`, sehingga reward match hanya didistribusikan oleh `RewardCalculationSystem`.
F: src/ServerScriptService/Server/EconomySystem/Controller.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit menunjukkan dua jalur aktif memberi reward pada akhir match: `EconomySystem/Controller` langsung di `MatchEnded`, dan `RewardCalculationSystem` melalui kalkulasi hasil lengkap. Membiarkan keduanya aktif berisiko menggandakan MM/reward pemain.
N: Verifikasi statik berikutnya: `EconomySystem/Controller.lua` tidak lagi subscribe `MatchEnded` atau memiliki `OnMatchEnded`.

[STEP 42%]
G: Singkirkan duplicate reward owner yang masih tersembunyi di dalam lifecycle `EconomySystem`.
C: Hapus instansiasi dan lifecycle `MatchRewardDriver` dari `EconomySystem/Service.lua`, sehingga driver `EconomySystem/Rewards/MatchCompletion` tidak lagi ikut aktif di runtime.
F: src/ServerScriptService/Server/EconomySystem/Service.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Bahkan setelah controller economy berhenti subscribe `MatchEnded`, service economy masih menyalakan driver internal `Rewards/MatchCompletion` yang mendaftarkan listener rewardnya sendiri saat `Init()`. Ini mempertahankan duplikasi owner secara tersembunyi.
N: Verifikasi statik berikutnya: `EconomySystem/Service.lua` tidak lagi require `Rewards/MatchCompletion.Main` atau memanggil `_matchRewardDriver:Init/Start/Stop()`.

[STEP 43%]
G: Rapikan sisa dead helper setelah jalur reward match duplikat dicabut dari `EconomySystem`.
C: Hapus helper `cloneRewardPayload` yang tidak lagi dipakai dari `EconomySystem/Controller.lua`.
F: src/ServerScriptService/Server/EconomySystem/Controller.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Setelah STEP 41, helper ini tidak punya pemanggil lagi. Menyisakannya hanya memperbesar noise pembacaan pada controller economy aktif.
N: Verifikasi statik berikutnya: `EconomySystem/Controller.lua` tidak lagi berisi `cloneRewardPayload`.

[STEP 44%]
G: Hapus API reward match legacy yang sudah tak punya pemanggil setelah owner reward endgame dipusatkan.
C: Buang `_collectMatchPlayerResults()` dan `GrantMatchRewardsFromMatch()` dari `EconomySystem/Service.lua`.
F: src/ServerScriptService/Server/EconomySystem/Service.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Setelah jalur reward match aktif dipindah penuh ke `RewardCalculationSystem`, helper economy ini hanya menyisakan permukaan API legacy yang tidak lagi dipakai dan berpotensi mengaburkan owner reward sebenarnya.
N: Verifikasi statik berikutnya: `EconomySystem/Service.lua` tidak lagi berisi `_collectMatchPlayerResults` atau `GrantMatchRewardsFromMatch`.

[STEP 45%]
G: Cabut sisa surface API reward match legacy dari `EconomySystem` agar owner reward endgame benar-benar tunggal.
C: Hapus helper ledger/reward match (`toMatchRewardLedgerKey`, `CalculateMatchReward`, `_publishMatchRewardEvents`, `_grantMatchRewardEntry`, `GrantMatchReward`) serta state `matchMMRewardLedger` dari `EconomySystem/Service.lua`.
F: src/ServerScriptService/Server/EconomySystem/Service.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Setelah driver/controller reward match economy dinonaktifkan, seluruh API ini menjadi orphan. Menyisakannya membuat pembaca keliru bahwa `EconomySystem` masih owner reward endgame aktif.
N: Verifikasi statik berikutnya: `EconomySystem/Service.lua` tidak lagi berisi `GrantMatchReward`, `CalculateMatchReward`, `_grantMatchRewardEntry`, atau `matchMMRewardLedger`.

[STEP 46%]
G: Buat `MatchUI` basic yang visual, mudah dibaca, dan bisa disembunyikan saat mengganggu pandangan in-game.
C: Upgrade `client/UI/Main.lua` sehingga `MatchUI` menjadi panel informasi match yang bisa ditutup/dibuka ulang dari tombol float `MATCH`, lalu ganti `ResultsPanel` tengah menjadi kartu hasil basic yang menampilkan status misi, ghost, tebakan, evidence, survive/dead, durasi, MM, dan XP.
F: src/client/UI/Main.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Sebelum langkah ini, UI match aktif hampir tidak informatif dan jendela match tidak punya kontrol tutup yang layak saat menghalangi gameplay. Untuk test E2E, tester perlu panel yang bisa disembunyikan tanpa kehilangan akses, serta layar hasil yang benar-benar memvisualkan data yang sudah dikirim server.
N: Verifikasi statik berikutnya: `Main.lua` berisi `MatchFloatButton`, `HideButton`, `ResultsCloseButton`, string `PANEL MATCH`, string `TUTUP HASIL`, dan fungsi `_renderResultsPanel`.

[STEP 47%]
G: Tutup gap aplikasi cosmetic flex di lobby agar domain cosmetics benar-benar punya efek visual runtime, bukan hanya event route.
C: Tambahkan renderer lobby-side di `LobbySocialHub/LobbyService.lua` yang menyimpan snapshot cosmetic equip per player, mematerialisasikannya menjadi visual karakter lobby-only (`head/body/outfit/accessory` + billboard flex), dan mengaplikasikannya ulang saat `CharacterAdded` di lobby; `CosmeticSystem` kini mengirim snapshot penuh lewat `ApplyCosmetics(...)` agar unequip/respawn tidak meninggalkan state lama.
F: src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua; src/ServerScriptService/Server/LobbySocialHub/Service.lua; src/ServerScriptService/Server/CosmeticSystem/Service.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/IMPLEMENTATION_BASELINE_2026-03-30.md
I: Sebelumnya jalur aktif berhenti di `LobbySocialHub:ApplyCosmetic()` yang hanya mem-publish event tanpa pernah mengubah karakter player. Itu membuat row `Cosmetic lobby application` hanya layak `Improved`, karena ownership route ada tetapi tidak menghasilkan cosmetic showcase nyata di social hub.
N: Verifikasi statik berikutnya: runtime aktif memiliki `ApplyCosmetics`, folder visual `LobbyCosmeticVisuals`, billboard `LobbyCosmeticBillboard`, attribute `LobbyEquippedEmote`, dan `CosmeticSystem` memanggil snapshot-based lobby application path.

[STEP 48%]
G: Selaraskan rarity aktif ke model kanonik `R1-R5` agar economy/shop tidak lagi memakai vocabulary campuran.
C: Ubah `shared/DataTypes/ShopCatalog.lua` ke rarity `R1-R5` plus label player-facing, teruskan label itu di `ShopSystem`, tampilkan di UI shop aktif, perluas roll rarity hadiah harian aktif sampai `R5`, dan tambahkan mapping warna `R1-R5` di renderer cosmetic lobby untuk menjaga presentasi tetap konsisten.
F: src/shared/DataTypes/ShopCatalog.lua; src/ServerScriptService/Server/ShopSystem/Service.lua; src/client/UI/Main.lua; src/ServerScriptService/Server/EconomySystem/Service.lua; src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/IMPLEMENTATION_BASELINE_2026-03-30.md
I: Sebelumnya economy reward aktif sudah mengenal rarity `R1-R3`, tetapi katalog shop aktif dan UI masih memakai `Common/Rare/Epic`. Itu mempertahankan dua vocabulary rarity aktif untuk domain yang sama dan membuat row kanonik tetap berada di bucket `Not found / not confirmed`.
N: Verifikasi statik berikutnya: shop/catalog aktif hanya memuat rarity `R1-R5`, UI shop menampilkan `rarityLabel`, dan `CHECKIN_REWARDS` aktif memiliki roll yang mencapai `R5`.

[STEP 49%]
G: Hentikan `RewardSystem` generik ikut boot agar reward match dan mission tidak lagi punya owner ganda.
C: Tambahkan `RewardSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`, sehingga reward endgame tetap dimiliki `RewardCalculationSystem`, reward mission harian tetap dimiliki `DailyMissionSystem`/`EconomySystem`, dan `ContractSystem` hanya memakai fallback grant langsung saat owner generik itu memang tidak aktif.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menunjukkan `RewardSystem` masih subscribe `MatchEnded`, `ContractCompleted`, dan `MissionCompleted` walau domain reward aktif sudah dipecah ke owner yang lebih spesifik. Membiarkannya aktif membuka risiko MM/XP ganda pada endgame dan mission flow.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `RewardSystem` disabled, dan `ContractService` hanya masuk jalur grant langsung saat `RewardSystem` tidak hadir di registry.

[STEP 50%]
G: Cabut `ContractRewardSystem` dari boot aktif agar reward kontrak tidak lagi punya publisher cermin tanpa owner grant nyata.
C: Tambahkan `ContractRewardSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`, sehingga reward kontrak tetap mengikuti jalur grant langsung `ContractSystem`/`RewardEngine` dan runtime tidak lagi menambah `RewardGranted` kedua yang hanya memantulkan `MatchEnded`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menunjukkan `ContractRewardSystem` tidak dipakai sebagai dependency aktif mana pun dan hanya subscribe `MatchEnded` untuk mem-publish payload `RewardGranted` tanpa benar-benar memberi MM/XP. Menyisakannya hanya memperbesar permukaan event reward dan membingungkan owner reward kontrak.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `ContractRewardSystem` disabled, sementara reward kontrak tetap datang dari jalur langsung `ContractSystem` saat kontrak selesai.

[STEP 51%]
G: Pastikan evaluasi penyelesaian kontrak tetap membawa `matchId` nyata ke pipeline hasil match.
C: Ubah `ContractCompletionSystem/Service.lua` agar `MatchEnded` menangkap `payload.matchId` atau `activeMatchId` dulu, mem-publish `ContractCompletionEvaluated` dengan nilai itu, lalu baru membersihkan state match aktif.
F: src/ServerScriptService/Server/ContractCompletionSystem/Service.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Sebelumnya service ini mengosongkan `activeMatchId` sebelum publish, sehingga `MatchResultSystem` menerima evaluasi kontrak dengan `matchId = nil`. Itu membuat jalur enrich hasil kontrak rawan gagal mengaitkan evaluasi ke sesi match yang benar.
N: Verifikasi statik berikutnya: `ContractCompletionSystem/Service.lua` mengisi `local matchId` pada cabang `MatchEnded`, publish `ContractCompletionEvaluated` memakai nilai itu, lalu `activeMatchId` dibersihkan setelah publish.

[STEP 52%]
G: Cabut `ContractConfigSystem` dari boot aktif karena hanya memantulkan load config tanpa konsumen runtime.
C: Tambahkan `ContractConfigSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`, sehingga konfigurasi kontrak tetap dibaca langsung dari shared module oleh owner aktif tanpa event `ContractConfigLoaded` yatim.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menunjukkan `ContractConfigSystem` tidak dipakai sebagai dependency aktif mana pun dan event `ContractConfigLoaded` tidak punya subscriber. Menjalankannya saat boot hanya menambah surface load yang tidak memberi efek runtime.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `ContractConfigSystem` disabled, dan pencarian runtime tidak menunjukkan subscriber `ContractConfigLoaded`.

[STEP 53%]
G: Cabut `GameConfigSystem` dari boot aktif karena hanya mem-publish load config tanpa pemakai runtime.
C: Tambahkan `GameConfigSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`, sehingga runtime tetap memakai config shared langsung dari owner aktif tanpa event `GameConfigLoaded` yatim.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menunjukkan `GameConfigSystem` tidak punya dependency aktif maupun subscriber `GameConfigLoaded`. Menyisakannya di boot hanya memperpanjang startup dengan loader yang tidak mengendalikan domain mana pun.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `GameConfigSystem` disabled, dan pencarian runtime tidak menunjukkan subscriber `GameConfigLoaded`.

[STEP 54%]
G: Hentikan `EngineStartupValidator` ikut boot karena hanya mengirim event startup internal yang tak dikonsumsi.
C: Tambahkan `EngineStartupValidator` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Service ini hanya memeriksa dependency startup lalu mem-publish `EngineStartupValidated` atau `StartupErrorDetected`, sementara kedua event itu tidak dipakai oleh jalur runtime aktif. Menyisakannya hanya menambah observer boot yang tidak punya owner tindak lanjut.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `EngineStartupValidator` disabled, dan pencarian runtime tidak menunjukkan consumer `EngineStartupValidated` maupun `StartupErrorDetected`.

[STEP 55%]
G: Hentikan `FinalEngineBootstrap` ikut boot karena ia hanya menggandakan validasi startup yang tidak dipakai runtime.
C: Tambahkan `FinalEngineBootstrap` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: `FinalEngineBootstrap` kembali memeriksa keberadaan service inti di `EngineStart` lalu mem-publish event startup yang sama sekali tidak punya subscriber aktif. Itu menjadikannya duplicate observer, bukan bootstrap owner nyata.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `FinalEngineBootstrap` disabled, dan pencarian runtime hanya menunjukkan publisher `EngineStartupValidated`/`StartupErrorDetected` yang sudah tidak diautoload.

[STEP 56%]
G: Hentikan `SystemIntegrationController` ikut boot karena hanya membuat event integrasi internal tanpa konsumen.
C: Tambahkan `SystemIntegrationController` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Service ini hanya melakukan scan registry di `EngineStart` lalu mem-publish `SystemIntegrationStarted` dan `SystemIntegrationCompleted`. Audit statik menunjukkan kedua event tersebut tidak dipakai runtime aktif mana pun.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `SystemIntegrationController` disabled, dan pencarian runtime tidak menunjukkan consumer `SystemIntegrationStarted` maupun `SystemIntegrationCompleted`.

[STEP 57%]
G: Hentikan `SystemDiagnosticsController` ikut boot karena snapshot diagnostiknya tidak menggerakkan domain runtime aktif.
C: Tambahkan `SystemDiagnosticsController` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Service ini menghitung traffic/snapshot saat `EngineStart` lalu mem-publish `DiagnosticsSnapshotCreated`, tetapi event tersebut tidak punya consumer aktif. Menjaganya di boot hanya menambah noise state diagnostik internal.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `SystemDiagnosticsController` disabled, dan pencarian runtime tidak menunjukkan consumer `DiagnosticsSnapshotCreated`.

[STEP 58%]
G: Hentikan `DependencyVerificationSystem` ikut boot karena ia memverifikasi dependency terhadap surface lama yang bukan owner runtime aktif.
C: Tambahkan `DependencyVerificationSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Service ini masih menuntut `ConfigLoader` sebagai dependency inti padahal jalur boot aktif tidak lagi mengautoload folder itu. Event keluarannya (`DependencyVerified` / `DependencyErrorDetected`) juga tidak punya consumer aktif, jadi service ini lebih mencerminkan asumsi bootstrap lama daripada runtime sekarang.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `DependencyVerificationSystem` disabled, dan pencarian runtime tidak menunjukkan consumer `DependencyVerified` maupun `DependencyErrorDetected`.

[STEP 59%]
G: Hentikan `RuntimeIntegritySystem` ikut boot karena warning integritasnya hanya memantulkan event internal tanpa jalur aksi aktif.
C: Tambahkan `RuntimeIntegritySystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Service ini hanya mengubah `SystemErrorDetected`/`SystemRegistered` menjadi `RuntimeIntegrityWarning`, sementara event warning itu tidak dikonsumsi domain aktif mana pun. Menjalankannya tidak memperbaiki integritas runtime, hanya menambah fan-out observer.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `RuntimeIntegritySystem` disabled, dan pencarian runtime tidak menunjukkan consumer `RuntimeIntegrityWarning`.

[STEP 60%]
G: Hentikan `ProductionSafetySystem` ikut boot karena trigger keselamatannya hanya mem-publish alarm internal yang tak punya owner tindakan.
C: Tambahkan `ProductionSafetySystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Service ini hanya memantulkan dependency hilang atau `SystemErrorDetected` menjadi `ProductionSafetyTriggered`, tetapi event itu tidak punya consumer aktif. Tanpa jalur aksi lanjutan, ia hanya memperbesar permukaan alarm internal saat boot/runtime.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `ProductionSafetySystem` disabled, dan pencarian runtime tidak menunjukkan consumer `ProductionSafetyTriggered`.

[STEP 61%]
G: Hentikan `ErrorMonitoringSystem` ikut boot karena jalur input/output error monitor-nya tidak lagi terhubung ke runtime aktif.
C: Tambahkan `ErrorMonitoringSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menunjukkan `ErrorMonitoringSystem` hanya subscribe `SystemException` dan `ServiceFailure`, tetapi tidak ada publisher aktif untuk kedua event itu. Output-nya (`SystemErrorDetected` dan `ErrorReportGenerated`) juga hanya memberi makan layer monitor lain yang tidak punya consumer gameplay/runtime aktif.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `ErrorMonitoringSystem` disabled, pencarian runtime tidak menunjukkan publisher aktif `SystemException`/`ServiceFailure`, dan `ErrorReportGenerated` tidak punya consumer aktif.

[STEP 62%]
G: Hentikan `LatencyMonitoringSystem` ikut boot karena warning latency-nya hanya menjadi event internal yatim.
C: Tambahkan `LatencyMonitoringSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Service ini hanyalah observer event umum yang menyimpan bucket lokal lalu mem-publish `LatencyWarningDetected`. Audit statik tidak menemukan dependency aktif maupun consumer untuk event tersebut.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `LatencyMonitoringSystem` disabled, dan pencarian runtime tidak menunjukkan consumer `LatencyWarningDetected`.

[STEP 63%]
G: Hentikan `MemoryTrackingSystem` ikut boot karena update/leak warning memorinya tidak digunakan runtime aktif.
C: Tambahkan `MemoryTrackingSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: `MemoryTrackingSystem` hanya mencatat event ke state sendiri lalu mem-publish `MemoryUsageUpdated` dan `MemoryLeakSuspected`. Audit statik menunjukkan keduanya tidak punya consumer aktif.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `MemoryTrackingSystem` disabled, dan pencarian runtime tidak menunjukkan consumer `MemoryUsageUpdated` maupun `MemoryLeakSuspected`.

[STEP 64%]
G: Hentikan `RuntimeMetricsSystem` ikut boot karena metrik runtime-nya hanya dipantulkan sebagai event internal tanpa pemakai.
C: Tambahkan `RuntimeMetricsSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Service ini hanya menyimpan sampel event lokal lalu mem-publish `RuntimeMetricsUpdated`, tetapi audit statik tidak menemukan subscriber atau dependency aktif yang membutuhkannya.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `RuntimeMetricsSystem` disabled, dan pencarian runtime tidak menunjukkan consumer `RuntimeMetricsUpdated`.

[STEP 65%]
G: Hentikan `ServerProfilerSystem` ikut boot karena snapshot profiler-nya tidak dipakai oleh domain runtime aktif.
C: Tambahkan `ServerProfilerSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: `ServerProfilerSystem` adalah observer template lain yang hanya mem-publish `ProfilerSnapshotCreated` berdasarkan event umum. Audit statik tidak menemukan consumer aktif untuk event snapshot ini.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `ServerProfilerSystem` disabled, dan pencarian runtime tidak menunjukkan consumer `ProfilerSnapshotCreated`.

[STEP 66%]
G: Hentikan `DataIntegritySystem` ikut boot karena warning integritas datanya tidak tersambung ke jalur aksi aktif.
C: Tambahkan `DataIntegritySystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Service ini hanya memantulkan event umum menjadi `DataIntegrityErrorDetected` sambil menyimpan laporan lokal. Audit statik tidak menemukan consumer aktif untuk event itu maupun dependency runtime yang memanggil sistem ini secara langsung.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `DataIntegritySystem` disabled, dan pencarian runtime tidak menunjukkan consumer `DataIntegrityErrorDetected`.

[STEP 67%]
G: Hentikan `AutoRecoverySystem` ikut boot karena “recovery” yang dilakukannya hanya berhenti di event internal tanpa eksekutor.
C: Tambahkan `AutoRecoverySystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menunjukkan service ini hanya mengubah `SystemErrorDetected`/event umum menjadi `AutoRecoveryExecuted` dan tidak menjalankan aksi pemulihan nyata. Event keluarannya juga tidak punya consumer aktif.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `AutoRecoverySystem` disabled, dan pencarian runtime tidak menunjukkan consumer `AutoRecoveryExecuted`.

[STEP 68%]
G: Hentikan `FailSafeSystem` ikut boot karena trigger fail-safe-nya hanya memantulkan event internal tanpa handler lanjutan.
C: Tambahkan `FailSafeSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: `FailSafeSystem` tidak mengeksekusi guard runtime nyata; ia hanya menyimpan history lokal lalu mem-publish `FailSafeTriggered`. Audit statik tidak menemukan consumer aktif untuk event tersebut.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `FailSafeSystem` disabled, dan pencarian runtime tidak menunjukkan consumer `FailSafeTriggered`.

[STEP 69%]
G: Hentikan `BackendStabilitySystem` ikut boot karena health backend yang dipublikasikannya tidak dikonsumsi runtime aktif.
C: Tambahkan `BackendStabilitySystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Service ini adalah observer template lain yang mem-publish `BackendHealthUpdated` berdasarkan event umum, tetapi audit statik tidak menemukan consumer aktif maupun pemanggil dependency untuk sistem ini.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `BackendStabilitySystem` disabled, dan pencarian runtime tidak menunjukkan consumer `BackendHealthUpdated`.

[STEP 70%]
G: Hentikan `WatchdogSystem` ikut boot karena restart watchdog-nya hanya menjadi event internal tanpa executor.
C: Tambahkan `WatchdogSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menunjukkan `WatchdogSystem` hanya mencatat event umum lalu mem-publish `WatchdogRestartTriggered`. Tidak ada consumer aktif yang benar-benar melakukan restart atau recovery berdasarkan event itu.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `WatchdogSystem` disabled, dan pencarian runtime tidak menunjukkan consumer `WatchdogRestartTriggered`.

[STEP 71%]
G: Pertahankan `ContractObjectiveSystem` tetap ikut boot karena masih menjadi dependency registry untuk domain objective kontrak yang aktif.
C: Tidak mengubah `DISABLED_RUNTIME_SYSTEM_NAMES`; hanya catat keputusan audit di laporan.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menunjukkan `InvestigationSystem` dan `ProgressionSystem` masih resolve `ContractObjectiveSystem` via `Services.Get`, sementara `MapConfigSystem` masih memasukkan nama sistem ini di dependency list. Menonaktifkannya sekarang berisiko memutus pipeline objective kontrak yang masih hidup.
N: Verifikasi statik berikutnya: pertahankan sistem ini aktif sampai ownership objective dipindahkan atau consumer aktif dihapus.

[STEP 72%]
G: Pertahankan `GlobalOperationsSystem` tetap ikut boot karena health snapshot-nya masih memberi makan quality gate matchmaking aktif.
C: Tidak mengubah `DISABLED_RUNTIME_SYSTEM_NAMES`; hanya catat keputusan audit di laporan.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menemukan `MatchmakingQualitySystem` masih subscribe `ServerHealthMetricsUpdated`, event yang dipublish `GlobalOperationsSystem`. Menonaktifkan `GlobalOperationsSystem` sekarang akan memutus input health metrics untuk quality matchmaking.
N: Verifikasi statik berikutnya: biarkan `GlobalOperationsSystem` tetap aktif sampai consumer `ServerHealthMetricsUpdated` dipindahkan atau dicabut.

[STEP 73%]
G: Hentikan `ServerHealthSystem` ikut boot karena warning health generiknya menduplikasi jalur health yang sudah dimiliki `GlobalOperationsSystem`.
C: Tambahkan `ServerHealthSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menunjukkan `ServerHealthSystem` tidak punya consumer service langsung; ia hanya subscribe event umum lalu mem-publish `ServerHealthWarning`. `GlobalOperationsSystem` sudah menghitung snapshot health sendiri dan mem-publish warning health dari heartbeat runtime aktif.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `ServerHealthSystem` disabled, dan pencarian runtime hanya menyisakan jalur `ServerHealthWarning` milik `GlobalOperationsSystem`.

[STEP 74%]
G: Pastikan keputusan mematikan `ServerHealthSystem` tidak memutus consumer runtime aktif.
C: Audit subscriber/publisher `ServerHealthWarning` dan `ServerHealthMetricsUpdated`.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Pencarian statik menunjukkan subscriber aktif `ServerHealthMetricsUpdated` ada di `MatchmakingQualitySystem`, tetapi event itu dipublish oleh `GlobalOperationsSystem`, bukan `ServerHealthSystem`. Sementara `ServerHealthWarning` hanya dipakai ulang oleh `GlobalOperationsSystem` dan sebelumnya diproduksi ganda oleh dua sistem health.
N: Verifikasi statik berikutnya: playtest manual perlu memastikan quality matchmaking masih menerima snapshot health setelah `ServerHealthSystem` tidak diautoload.

[STEP 75%]
G: Hentikan `ServerPerformanceSystem` ikut boot karena ia hanya menjadi loop warning template tanpa consumer runtime aktif.
C: Tambahkan `ServerPerformanceSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik tidak menemukan pemanggil service maupun subscriber untuk `ServerPerformanceWarning` atau `HighCPUUsageDetected`. Sistem ini hanya menyimpan counter lokal dan mem-publish warning internal berkala.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `ServerPerformanceSystem` disabled, dan pencarian runtime tidak menunjukkan consumer aktif untuk kedua event warning tersebut.

[STEP 76%]
G: Pastikan `ServerPerformanceSystem` memang yatim dari sisi registry.
C: Audit reference name-based untuk `ServerPerformanceSystem`.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Pencarian statik nama sistem ini hanya muncul di foldernya sendiri dan `SystemRegistry`; tidak ada `Services.Get`, dependency list, atau modul domain aktif lain yang meminta instance `ServerPerformanceSystem`.
N: Verifikasi statik berikutnya: aman mempertahankan folder legacy-nya di repo sambil menghentikan autoload registry.

[STEP 77%]
G: Hentikan `ServerPerformance` ikut boot karena ia adalah monitor performa lama yang juga hanya mem-publish warning tanpa consumer aktif.
C: Tambahkan `ServerPerformance` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menunjukkan `ServerPerformance` hanya subscribe phase/ghost/map/network event untuk menghitung metrik lokal lalu mem-publish `ServerPerformanceWarning`. Tidak ada subscriber aktif untuk warning itu, dan purpose-nya bertumpuk dengan `ServerPerformanceSystem`.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `ServerPerformance` disabled, dan jalur warning performa yatim tidak lagi diautoload.

[STEP 78%]
G: Pastikan keputusan mematikan `ServerPerformance` tidak memutus consumer runtime aktif.
C: Audit subscriber/publisher `ServerPerformanceWarning`.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Pencarian statik menunjukkan publisher `ServerPerformanceWarning` hanya berasal dari `ServerPerformance` dan `ServerPerformanceSystem`, sedangkan audit runtime tidak menemukan subscriber aktif untuk event tersebut di domain server maupun client.
N: Verifikasi statik berikutnya: tidak ada dependency aktif yang hilang karena kedua publisher warning performa memang orphan.

[STEP 79%]
G: Samakan registry dengan hasil audit owner health/performance terbaru.
C: Verifikasi `SystemRegistry` sekarang menandai `ServerHealthSystem`, `ServerPerformanceSystem`, dan `ServerPerformance` sebagai disabled runtime.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Dengan tiga entri baru ini, registry berhenti meng-autoload lapisan health/performance generik yang hanya memancarkan event warning yatim atau duplikat, sambil tetap mempertahankan owner metrics aktif (`GlobalOperationsSystem`) dan owner objective aktif (`ContractObjectiveSystem`).
N: Verifikasi statik berikutnya: boot berikutnya seharusnya tidak lagi memuat tiga sistem duplicate monitor tersebut.

[STEP 80%]
G: Naikkan handoff audit cleanup runtime ke `80%` dengan hanya menyimpan perubahan yang sudah lolos verifikasi statik.
C: Perbarui state laporan menjadi `P: 80% selesai.`
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Langkah `71%-80%` menutup audit health/performance dengan keputusan defensif: tiga sistem duplicate monitor dicabut dari autoload, sedangkan `GlobalOperationsSystem` dan `ContractObjectiveSystem` sengaja dibiarkan aktif karena masih punya consumer/dependency nyata.
N: Verifikasi statik berikutnya: lanjutkan audit `81%-100%` hanya pada domain yang belum punya consumer aktif dan belum overlap dengan owner runtime kanonik.

[STEP 81%]
G: Pertahankan `ModerationOperationsSystem` tetap ikut boot karena masih punya jalur input enforcement yang hidup.
C: Tidak mengubah `DISABLED_RUNTIME_SYSTEM_NAMES`; hanya catat keputusan audit di laporan.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menunjukkan `AntiCheatSystem` masih mem-publish `AntiCheatViolationDetected`, dan `ModerationOperationsSystem` masih mengonsumsinya untuk membuat report/moderation action. Walau event keluaran moderasinya belum banyak dipakai sistem lain, service ini masih punya side effect runtime nyata seperti mute/ban/kick.
N: Verifikasi statik berikutnya: biarkan sistem ini aktif sampai jalur anti-cheat enforcement dipindahkan ke owner lain.

[STEP 82%]
G: Tegaskan alasan `ModerationOperationsSystem` belum aman dicabut dari boot aktif.
C: Audit input utama `AntiCheatViolationDetected`, `PlayerJoinValidationRequested`, dan `ChatMessageSubmitted`.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Pencarian statik hanya menemukan publisher aktif untuk `AntiCheatViolationDetected`, sementara dua input moderasi lain belum terlihat di runtime in-repo. Karena satu jalur aktif saja sudah cukup memicu action enforcement, `ModerationOperationsSystem` belum masuk kategori orphan berisiko rendah.
N: Verifikasi statik berikutnya: kalau enforcement anti-cheat nanti dipindahkan, sistem ini bisa diaudit ulang bersama surface chat/join validation.

[STEP 83%]
G: Hentikan `OperationsQASystem` ikut boot karena seluruh permukaan QA/release check-nya tidak terhubung ke runtime aktif.
C: Tambahkan `OperationsQASystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menunjukkan nama sistem ini tidak dipanggil lewat `Services.Get` atau dependency list mana pun. Event masuk seperti `BackupRequested`, `AutomatedTestRunRequested`, `LoadTestRequested`, `SecurityAuditRequested`, dan `ReleaseChecklistRequested` hanya muncul di controller-nya sendiri.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `OperationsQASystem` disabled, dan pencarian runtime tidak menunjukkan publisher in-repo untuk request event QA tersebut.

[STEP 84%]
G: Pastikan `OperationsQASystem` memang hanya memancarkan event QA yatim.
C: Audit output `DataBackupCreated`, `AutomatedTestsCompleted`, `LoadTestCompleted`, `SecurityAuditCompleted`, `ReleaseChecklistEvaluated`, dan `ProjectCompletionStatusUpdated`.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Pencarian statik menunjukkan seluruh event keluaran QA hanya dipublish di `OperationsQASystem` sendiri dan tidak punya consumer aktif di domain server/client. Heartbeat backup otomatisnya juga hanya menghasilkan snapshot lokal placeholder, bukan backup runtime yang benar-benar dieksekusi ke persistence layer.
N: Verifikasi statik berikutnya: aman menghentikan autoload sistem QA ini tanpa memutus gameplay atau live runtime owner.

[STEP 85%]
G: Pertahankan `ContentUpdatePipelineSystem` tetap ikut boot karena masih menjadi provider katalog konten aktif.
C: Tidak mengubah `DISABLED_RUNTIME_SYSTEM_NAMES`; hanya catat keputusan audit di laporan.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menunjukkan `DailyContractSystem`, `WeeklyChallengeSystem`, `DynamicInvestigationEventSystem`, `PlayerReputationSystem`, `SocialEmoteSystem`, `EventMapRotationSystem`, dan `SeasonalEventSystem` masih resolve `ContentUpdatePipelineSystem` via `Services.Get` atau event update katalog.
N: Verifikasi statik berikutnya: biarkan sistem ini aktif sampai owner konten live dipindahkan atau consumers aktif disederhanakan.

[STEP 86%]
G: Tegaskan bahwa `ContentUpdatePipelineSystem` tidak boleh dicabut pada audit ini.
C: Audit event `ContentCatalogLoaded`, `ContentCatalogUpdated`, dan `ContentReloadRequested`.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: `ContentUpdatePipelineSystem` masih mem-publish `ContentCatalogLoaded`/`ContentCatalogUpdated` yang dikonsumsi beberapa sistem konten aktif, dan juga menerima `ContentReloadRequested` dari `LiveContentOpsSystem`. Ini bukan observer yatim, tetapi dependency/data owner yang masih hidup.
N: Verifikasi statik berikutnya: audit berikutnya harus fokus pada konsolidasi owner konten, bukan mematikan registry secara langsung.

[STEP 87%]
G: Hentikan `PlatformSupportSystem` ikut boot karena lapisan platform/profile-nya hanya memancarkan event saran yang tidak dipakai runtime aktif.
C: Tambahkan `PlatformSupportSystem` ke `DISABLED_RUNTIME_SYSTEM_NAMES` di `SystemRegistry`.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menunjukkan nama sistem ini tidak dipanggil oleh `Services.Get` atau dependency list mana pun. Input `PlayerPlatformDeclared` dan `VoiceChatPermissionRequested` juga tidak punya publisher in-repo, sehingga surface platform-nya tidak pernah diberi data nyata oleh runtime aktif.
N: Verifikasi statik berikutnya: `SystemRegistry` menandai `PlatformSupportSystem` disabled, dan pencarian runtime tidak menunjukkan publisher aktif untuk dua input platform tersebut.

[STEP 88%]
G: Pastikan `PlatformSupportSystem` benar-benar hanya menghasilkan advisory event yatim.
C: Audit output `CrossPlatformProfileResolved`, `UIScalingSuggested`, `VoiceChatPermissionEvaluated`, dan `InputProfileSuggested`.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Pencarian statik menunjukkan semua output platform hanya dipublish di `PlatformSupportSystem` sendiri dan tidak punya consumer aktif di repo. Satu input aktif yang tersisa hanyalah `MatchStarted`, tetapi responsnya tetap berhenti di `InputProfileSuggested` yang tidak dibaca sistem lain.
N: Verifikasi statik berikutnya: aman menghentikan autoload sistem advisory platform ini tanpa memutus loop gameplay utama.

[STEP 89%]
G: Pertahankan `LiveContentOpsSystem` tetap ikut boot pada audit defensif ini.
C: Tidak mengubah `DISABLED_RUNTIME_SYSTEM_NAMES`; hanya catat keputusan audit di laporan.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Walau request event masuk ke `LiveContentOpsSystem` belum ditemukan publisher in-repo, service ini masih terhubung ke `ContentUpdatePipelineSystem` lewat `ContentReloadRequested` dan masih punya output `ContentRegistered` yang dikonsumsi `PlayerEngagementSystem`.
N: Verifikasi statik berikutnya: biarkan sistem ini aktif sampai live-ops bridge benar-benar dipangkas atau consumer `ContentRegistered` dipindahkan.

[STEP 90%]
G: Tegaskan kenapa `LiveContentOpsSystem` belum masuk batch disable berisiko rendah.
C: Audit request surface live-ops dan subscriber `ContentRegistered`.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Tidak adanya publisher in-repo pada request event live-ops menunjukkan jalur ini dorman, tetapi keberadaan consumer aktif `ContentRegistered` membuat keputusan disable kurang setegas `OperationsQASystem` atau `PlatformSupportSystem`. Karena tugas ini dibatasi pada perubahan high-confidence, sistem ini dibiarkan aktif.
N: Verifikasi statik berikutnya: jika nanti live-ops admin bridge dinyatakan non-scope, sistem ini bisa diaudit ulang sebagai kandidat disable.

[STEP 91%]
G: Pastikan dua kandidat disable baru memang yatim dari sisi registry.
C: Audit reference name-based untuk `OperationsQASystem` dan `PlatformSupportSystem`.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Pencarian statik nama kedua sistem hanya muncul di foldernya sendiri dan `SystemRegistry`; tidak ada `Services.Get`, dependency list, atau modul domain aktif lain yang meminta instance mereka.
N: Verifikasi statik berikutnya: registry disable untuk dua sistem ini tidak akan memutus dependency service langsung.

[STEP 92%]
G: Samakan registry dengan hasil audit QA/platform terbaru.
C: Verifikasi `SystemRegistry` sekarang menandai `OperationsQASystem` dan `PlatformSupportSystem` sebagai disabled runtime.
F: src/ServerScriptService/Server/Core/SystemRegistry.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Dengan dua entri baru ini, registry berhenti meng-autoload lapisan QA placeholder dan advisory platform yang tidak tersambung ke graph runtime aktif.
N: Verifikasi statik berikutnya: boot berikutnya seharusnya tidak lagi memuat dua sistem legacy tersebut.

[STEP 93%]
G: Rekap domain yang sengaja dipertahankan tetap aktif pada tranche akhir audit.
C: Catat keputusan preserve untuk `ModerationOperationsSystem`, `ContentUpdatePipelineSystem`, dan `LiveContentOpsSystem`.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Tiga sistem ini tidak dicabut karena masing-masing masih punya jejak runtime yang lebih kuat: enforcement anti-cheat, dependency katalog konten aktif, atau bridge live-ops dengan subscriber hilir. Ini membatasi patch hanya pada perubahan yang benar-benar low-risk.
N: Verifikasi statik berikutnya: perubahan lanjutan pada tiga domain ini membutuhkan validasi runtime atau keputusan ownership yang lebih eksplisit.

[STEP 94%]
G: Tegaskan bahwa audit akhir ini menutup jalur “template system” yang jelas yatim tanpa menyentuh owner gameplay utama.
C: Dokumentasikan batas audit di laporan.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Semua perubahan `81%-100%` tetap berada pada level registry/autoload, tidak mengubah service gameplay kanonik seperti `MatchSystem`, `GhostSystem`, `EvidenceSystem`, `LobbySystem`, `EconomySystem`, atau `ProfileSystem`.
N: Verifikasi statik berikutnya: bila ada bug sesudah patch ini, fokus diagnosis harus ke owner runtime aktif, bukan ke sistem template yang sudah dicabut dari boot.

[STEP 95%]
G: Pastikan tidak ada keputusan disable akhir yang bergantung pada asumsi consumer tersembunyi in-repo.
C: Audit pencarian repo untuk event request/output sistem QA dan platform.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Semua keputusan disable akhir didasarkan pada pencarian statik repo yang menunjukkan event input maupun output hanya berada di dalam folder sistem terkait. Tidak ditemukan subscriber atau publisher tambahan di server/client code yang sedang dipakai runtime.
N: Verifikasi statik berikutnya: risiko residual utama tinggal pada trigger manual luar repo, bukan jalur kode yang terlihat.

[STEP 96%]
G: Tegaskan risiko residual yang tersisa setelah registry cleanup mencapai ujung tranche.
C: Catat bahwa validasi runtime Studio masih belum dijalankan dari environment ini.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Seperti langkah-langkah sebelumnya, audit ini masih berupa verifikasi statik. Tidak ada sesi Roblox Studio atau playtest in-game yang dijalankan, sehingga validasi perilaku boot nyata tetap menjadi follow-up manual.
N: Verifikasi statik berikutnya: jalankan boot/playtest Studio untuk memastikan log registry tidak lagi memuat sistem QA/platform yang sudah disabled.

[STEP 97%]
G: Nyatakan status penyisiran candidate low-risk sudah habis untuk batch ini.
C: Catat bahwa kandidat orphan paling tegas sudah selesai dieksekusi atau dipreserve.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Setelah batch QA/platform ini, kandidat tersisa memiliki coupling yang lebih ambigu, subscriber hilir aktif, atau side effect runtime nyata. Mereka tidak lagi masuk kategori “disable dengan keyakinan tinggi” tanpa validasi tambahan.
N: Verifikasi statik berikutnya: batch audit baru harus dimulai dari keputusan produk/arsitektur, bukan sekadar pencarian orphan event.

[STEP 98%]
G: Konsolidasikan hasil akhir audit ke dalam state ringkas.
C: Perbarui rangkuman state agar memasukkan dua sistem disabled baru dan tiga preserve decision utama.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: State akhir harus mencerminkan bahwa `OperationsQASystem` dan `PlatformSupportSystem` kini ikut masuk daftar disabled, sementara `ModerationOperationsSystem`, `ContentUpdatePipelineSystem`, dan `LiveContentOpsSystem` sengaja dipertahankan aktif.
N: Verifikasi statik berikutnya: state laporan konsisten dengan isi `SystemRegistry`.

[STEP 99%]
G: Tutup tranche cleanup runtime ini sebagai audit registry berisiko rendah yang lengkap.
C: Set status progres menjadi tahap penutupan.
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Langkah `81%-99%` menyelesaikan sisa audit kandidat low-risk dengan menambah dua disable baru dan mendokumentasikan preserve decision untuk domain yang masih punya coupling nyata.
N: Verifikasi statik berikutnya: tahap berikutnya, bila dibutuhkan, harus diperlakukan sebagai audit menengah/tinggi risiko.

[STEP 100%]
G: Naikkan handoff audit cleanup runtime ke `100%` untuk tranche high-confidence ini.
C: Perbarui state laporan menjadi `P: 100% selesai.`
F: DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit `51%-100%` kini menutup batch registry cleanup high-confidence: sistem duplicate/orphan config, startup, diagnostics, monitoring, health/performance, QA, dan advisory platform tidak lagi ikut autoload, sementara domain yang masih punya owner/dependency aktif sengaja dipertahankan.
N: Verifikasi statik berikutnya: tidak ada cleanup low-risk tambahan yang tersisa tanpa beralih ke audit yang membutuhkan playtest atau keputusan arsitektur.

[FOLLOW-UP 2026-04-01]
G: Bersihkan fallback debug dan longgarkan jalur death runtime supaya hanya berjalan dengan context match nyata.
C: Hapus injeksi `DEBUG_MATCH`, hapus `print` debug per-event di `DeathStateSystem`, hapus trace print `DeathEventBridge`, dan guard `PlayerDied`/`PlayerRespawnRequested` agar hanya memproses event dengan `matchId` nyata.
F: src/ServerScriptService/Server/DeathStateSystem/Service.lua; src/ServerScriptService/Server/DeathStateSystem/DeathEventBridge.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md
I: Audit statik menunjukkan `DEBUG_MATCH` hanya dipakai di `DeathStateSystem` sendiri dan membuat `DeathStateChanged` berpotensi membawa `matchId` palsu saat tidak ada match nyata. Selain itu, death bridge masih bisa meneruskan kematian tanpa context match, sehingga state death lokal dan transisi spectator dapat berjalan di luar match. Dengan guard `matchId` dan payload forward yang eksplisit, jalur death kini tetap bergantung pada `MatchStarted`/`MatchEnded` kanonik.
N: Verifikasi statik berikutnya: jalankan match sungguhan di Studio dan pastikan `DeathStateSystem` tetap memancarkan state death dengan `matchId` nyata dari `MatchStarted`, serta mengabaikan death/respawn di luar match.

[STATE]
M: Match flow tidak lagi diautoload lewat owner queue legacy, domain evidence/journal sudah dirapikan, `EvidenceDeductionEngine` sudah service/data-only, `JournalSystem` aktif kembali menjadi owner `confirmedEvidence`, owner utama tidak lagi menumpuk listener saat start ulang, `MatchSystem` kembali memancarkan `MatchEnded`, `RankedSystem` hanya bereaksi pada trigger hasil match kanonik, trace validasi `LobbySystem` sudah dibersihkan, bootstrap tidak lagi memberi warning API palsu, UI hasil match menerima `MatchCompleted` dan `MatchRewardSummary`, economy tidak lagi menyisakan surface API yang menyaru sebagai owner reward endgame, `RewardSystem` generik dan `ContractRewardSystem` event-only tidak lagi diautoload sehingga reward match/mission/contract tidak lagi punya publisher owner ganda, `ContractCompletionSystem` kini mempertahankan `matchId` saat mem-publish evaluasi kontrak ke pipeline hasil, config mirror `ContractConfigSystem`/`GameConfigSystem` tidak lagi ikut boot, startup observer `EngineStartupValidator`/`FinalEngineBootstrap` tidak lagi diautoload, controller diagnostik/verifikasi (`SystemIntegrationController`, `SystemDiagnosticsController`, `DependencyVerificationSystem`, `RuntimeIntegritySystem`, `ProductionSafetySystem`) juga dicabut dari boot aktif, lapisan monitor/recovery yatim (`ErrorMonitoringSystem`, `LatencyMonitoringSystem`, `MemoryTrackingSystem`, `RuntimeMetricsSystem`, `ServerProfilerSystem`, `DataIntegritySystem`, `AutoRecoverySystem`, `FailSafeSystem`, `BackendStabilitySystem`, `WatchdogSystem`) tidak lagi ikut autoload karena hanya memancarkan event internal tanpa consumer runtime aktif, duplicate monitor health/performance (`ServerHealthSystem`, `ServerPerformanceSystem`, `ServerPerformance`) juga tidak lagi ikut boot, lapisan QA/platform advisory (`OperationsQASystem`, `PlatformSupportSystem`) kini ikut dicabut dari autoload aktif, dan `DeathStateSystem` tidak lagi menyuntikkan `DEBUG_MATCH`, tidak lagi spam log per-event, dan tidak lagi memproses death/respawn tanpa `matchId` nyata. `GlobalOperationsSystem` sengaja tetap aktif karena `MatchmakingQualitySystem` masih mengonsumsi `ServerHealthMetricsUpdated`, `ContractObjectiveSystem` tetap hidup karena masih dipakai `InvestigationSystem`, `ProgressionSystem`, dan dependency `MapConfigSystem`, `ModerationOperationsSystem` tetap aktif karena masih mengonsumsi `AntiCheatViolationDetected` dengan side effect enforcement, `ContentUpdatePipelineSystem` tetap menjadi provider katalog konten aktif, dan `LiveContentOpsSystem` sengaja dibiarkan hidup karena masih menjembatani `ContentReloadRequested`/`ContentRegistered` pada graph konten yang belum sepenuhnya dipangkas. `MatchUI` kini punya panel basic yang bisa di-close/reopen, `LobbySocialHub` sekarang benar-benar menampilkan cosmetic flex lobby dari snapshot equip aktif serta mengaplikasikannya ulang setelah respawn lobby, dan rarity aktif kini selaras ke model kanonik `R1-R5` pada shop/catalog/UI/reward surface yang sedang dipakai runtime.
P: 100% selesai.
B: Tidak ada blocker aktif untuk langkah ini.

[STEP 101%]
G: Selaraskan `DeathEventBridge` aktif dengan handoff follow-up `2026-04-01`.
C: Hapus dua trace `warn(...)` yang masih tersisa pada jalur spawn-protection dan debounce death event.
F: src/ServerScriptService/Server/DeathStateSystem/DeathEventBridge.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/CLAUDE.md
I: Repo aktif masih menyisakan trace `DeathEventBridge` walau state follow-up sebelumnya sudah menyatakan trace itu dibersihkan. Patch ini menutup mismatch handoff tanpa mengubah owner, payload, atau guard `matchId` pada runtime death flow.
N: Verifikasi runtime berikutnya: jalankan match sungguhan di Studio dan pastikan `DeathStateSystem` tetap memancarkan state death dengan `matchId` nyata dari `MatchStarted`, tetap mengabaikan death/respawn di luar match, dan tidak lagi menghasilkan trace `DeathEventBridge` pada kasus spawn-protection/debounce.

[STATE]
M: Match flow tidak lagi diautoload lewat owner queue legacy, domain evidence/journal sudah dirapikan, `EvidenceDeductionEngine` sudah service/data-only, `JournalSystem` aktif kembali menjadi owner `confirmedEvidence`, owner utama tidak lagi menumpuk listener saat start ulang, `MatchSystem` kembali memancarkan `MatchEnded`, `RankedSystem` hanya bereaksi pada trigger hasil match kanonik, trace validasi `LobbySystem` sudah dibersihkan, bootstrap tidak lagi memberi warning API palsu, UI hasil match menerima `MatchCompleted` dan `MatchRewardSummary`, economy tidak lagi menyisakan surface API yang menyaru sebagai owner reward endgame, `RewardSystem` generik dan `ContractRewardSystem` event-only tidak lagi diautoload sehingga reward match/mission/contract tidak lagi punya publisher owner ganda, `ContractCompletionSystem` kini mempertahankan `matchId` saat mem-publish evaluasi kontrak ke pipeline hasil, config mirror `ContractConfigSystem`/`GameConfigSystem` tidak lagi ikut boot, startup observer `EngineStartupValidator`/`FinalEngineBootstrap` tidak lagi diautoload, controller diagnostik/verifikasi (`SystemIntegrationController`, `SystemDiagnosticsController`, `DependencyVerificationSystem`, `RuntimeIntegritySystem`, `ProductionSafetySystem`) juga dicabut dari boot aktif, lapisan monitor/recovery yatim (`ErrorMonitoringSystem`, `LatencyMonitoringSystem`, `MemoryTrackingSystem`, `RuntimeMetricsSystem`, `ServerProfilerSystem`, `DataIntegritySystem`, `AutoRecoverySystem`, `FailSafeSystem`, `BackendStabilitySystem`, `WatchdogSystem`) tidak lagi ikut autoload karena hanya memancarkan event internal tanpa consumer runtime aktif, duplicate monitor health/performance (`ServerHealthSystem`, `ServerPerformanceSystem`, `ServerPerformance`) juga tidak lagi ikut boot, lapisan QA/platform advisory (`OperationsQASystem`, `PlatformSupportSystem`) kini ikut dicabut dari autoload aktif, dan `DeathStateSystem` tidak lagi menyuntikkan `DEBUG_MATCH`, tidak lagi spam log per-event, tidak lagi memproses death/respawn tanpa `matchId` nyata, dan tidak lagi menyisakan trace `DeathEventBridge` pada guard spawn-protection/debounce. `GlobalOperationsSystem` sengaja tetap aktif karena `MatchmakingQualitySystem` masih mengonsumsi `ServerHealthMetricsUpdated`, `ContractObjectiveSystem` tetap hidup karena masih dipakai `InvestigationSystem`, `ProgressionSystem`, dan dependency `MapConfigSystem`, `ModerationOperationsSystem` tetap aktif karena masih mengonsumsi `AntiCheatViolationDetected` dengan side effect enforcement, `ContentUpdatePipelineSystem` tetap menjadi provider katalog konten aktif, dan `LiveContentOpsSystem` sengaja dibiarkan hidup karena masih menjembatani `ContentReloadRequested`/`ContentRegistered` pada graph konten yang belum sepenuhnya dipangkas. `MatchUI` kini punya panel basic yang bisa di-close/reopen, `LobbySocialHub` sekarang benar-benar menampilkan cosmetic flex lobby dari snapshot equip aktif serta mengaplikasikannya ulang setelah respawn lobby, dan rarity aktif kini selaras ke model kanonik `R1-R5` pada shop/catalog/UI/reward surface yang sedang dipakai runtime.
P: 100% batch cleanup low-risk tetap selesai; follow-up sinkronisasi `DeathEventBridge` selesai.
B: Tidak ada blocker kode aktif untuk task ini; verifikasi runtime Studio tetap pending sebagai langkah berikutnya.

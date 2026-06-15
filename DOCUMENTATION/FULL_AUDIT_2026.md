# FULL CODEBASE AUDIT - 2026-06-14

**Scope:** `src/` directory + subagent deep-dive verification
**Auditor:** Claude Sonnet 4.6
**Reference:** CANONICAL_SPECIFICATIONS_v2.md, REPORTS.md
**Total Files:** ~1,183 files (includes all subdirectories)

---

## REKOMENDASI PRIORITAS

Urutkan dari yang paling blocking publish:

1. **CONFLICT** - Publisher duplikat yang menyebabkan race condition
2. **ERROR** - Referensi tidak valid atau path broken
3. **MISSING** - Fitur required untuk core loop
4. **HIGH_CONFLICT_RISK** - Sistem yang paling sering disentuh banyak agent
5. **INCOMPLETE** - Fungsi tidak dipanggil atau event tanpa subscriber
6. Sisanya

---

## [ERROR]

| File | Baris | Keterangan |
|------|-------|-----------|
| src/shared/DataTypes/ShopMarketplaceConfig.lua | 3 | Comment menandakan `10576163165` invalid - hanya di-comment, TIDAK dipakai di code (LOW severity) |
| src/ServerScriptService/Server/SpectatorSystem/SpectatorDistortionEngine.lua | 46-50 | `IsOnCooldown` - nama parameter `lastDistortionAt` menipu: menyimpan future timestamp, bukan last distortion time. Logika berfungsi tapi bisa mis-read oleh maintainer. Severity: MEDIUM |
| src/ServerScriptService/Server/SpectatorSystem/SpectatorDistortionEngine.lua | 119-154 | `DistortEvidence` dan `DistortGhostSighting` pakai `math.random` hardcoded (10/40 split) abaikan `DEFAULT_CONFIG` — minor encapsulation issue |

---

## [CONFLICT]

| File | Baris | Keterangan |
|------|-------|-----------|
| src/ServerScriptService/Server/EvidenceToolSystem/Service.lua | 166 | Publish `EvidenceDetected` - duplikat dengan EvidenceSystem. **Tapi sistem ini DISABLED** via SystemRegistry — tidak ada race condition aktual. [RESOLVED] |
| src/ServerScriptService/Server/EvidenceSystem/Modules/EvidenceService.lua | 1925 | Publish `EvidenceDetected` - publisher aktif pertama/utama |
| src/ServerScriptService/Server/EconomySystem/Rewards/MatchCompletion/Controller.lua | 43 | Subscribe `ResultsCalculated` - tapi event ini TIDAK dipublish oleh MatchSystem. **ORPHAN SUBSCRIPTION** |
| src/ServerScriptService/Server/EvidenceSystem/Modules/EvidenceService.lua | 781 | Publish `GhostCandidatesUpdated` - duplikat dari JournalSystem |
| src/ServerScriptService/Server/JournalSystem/Controller.lua | 55-56 | Subscribe `GhostCandidatesUpdated` dari JournalSystem DAN EvidenceService |
| src/ServerScriptService/Server/EvidenceSystem/EvidenceEngine/EvidenceEngine.lua | 46 | Subscribe `EvidenceDetected` - tapi sudah ada di JournalSystem |
| src/ServerScriptService/Server/DataPersistence/ | - | Duplicate dengan DataPersistenceService - kedua exists |
| src/ServerScriptService/Server/RewardSystem/ | - | Duplicate dengan RewardCalculationSystem |

---

## [DISABLED]

| File | Keterangan |
|------|-----------|
| src/ServerScriptService/Server/Core/SystemRegistry.lua | 32 sistem di-DISABLED via `DISABLED_RUNTIME_SYSTEM_NAMES`: MatchmakingSystem, ServerQueueSystem, EvidenceToolSystem, ToolSignalProcessingSystem, ToolInteractionSystem, EvidenceJournalSystem, GhostDeductionJournal, RewardSystem, ContractRewardSystem, DailyCheckinSystem, DailyMissionSystem, RoyalPassSystem, ContractConfigSystem, GameConfigSystem, EngineStartupValidator, FinalEngineBootstrap, SystemIntegrationController, SystemDiagnosticsController, DependencyVerificationSystem, RuntimeIntegritySystem, ProductionSafetySystem, ErrorMonitoringSystem, LatencyMonitoringSystem, MemoryTrackingSystem, RuntimeMetricsSystem, ServerProfilerSystem, DataIntegritySystem, AutoRecoverySystem, FailSafeSystem, BackendStabilitySystem, WatchdogSystem, ServerHealthSystem, ServerPerformanceSystem, ServerPerformance, OperationsQASystem, PlatformSupportSystem, StudioE2EControlSystem |

---

## [DUPLICATE]

| File | Baris | Keterangan |
|------|-------|-----------|
| src/ServerScriptService/Server/DataPersistence/ | - | Duplikat DataPersistenceService - kedua folder exists |
| src/ServerScriptService/Server/DataPersistenceService/ | - | Owner canonical |
| src/ServerScriptService/Server/RewardSystem/ | - | Duplikat RewardCalculationSystem |
| src/ServerScriptService/Server/RewardCalculationSystem/ | - | Owner canonical |
| src/ServerScriptService/Server/EconomySystem/Rewards/MatchCompletion/ | - | Duplikat MatchResultSystem reward flow |

---

## [MISSING]

| File | Keterangan |
|------|-----------|
| - | **Robux monetization flow** - Tidak ada `MarketplaceService.ProcessReceipt` server-side yang aktif (ShopSystem.Controller.lua ada tapi perlu diverifikasi) |
| - | **EvidenceTrainingSystem** - Training building geometry exists tapi tidak ada dedicated gameplay system |
| - | **Live DataStore validation** - Persistence sudah menggunakan LoadProfile/SaveProfile tapi live behavior belum di-validate |

---

## [INCOMPLETE]

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 5261, 17259 | `_roomBrowserSuppressed` permanently set `true` saat teleport, hanya di-reset via `_returnFromResultsToLobby` (line 6292). Jika player bypass results screen, RoomBrowser toggle mati permanen. **Fix: di `_syncRoomBrowserSuppressionFromMatchContext`** |
| src/ServerScriptService/Server/MatchSystem/MatchQueue.lua | 165, 178, 185 | `already_queued` spam - tidak ada gate untuk prevent duplicate queue events |
| src/ServerScriptService/Server/EvidenceSystem/EvidenceEngine/EvidenceEngine.lua | 46 | Subscribe `EvidenceDetected` tapi subscriber lain (JournalSystem) juga subscribe - perlu consolidate |
| src/ServerScriptService/Server/EconomySystem/Rewards/MatchCompletion/Controller.lua | 43 | Subscribe `ResultsCalculated` - event tidak dipublish aktif |
| src/ServerScriptService/Server/SpectatorSystem/SpectatorService.lua | 403, 619, 656 | `SpectatorSystem` disconnected dari death path — `SpectatorModeSystem` (free-camera) berfungsi, tapi `SpectatorSystem` ghost-vision/distortion **tidak pernah di-trigger** karena Controller tidak subscribe `SpectatorModeStarted`. `matchId` tidak di-pass, `ProcessGhostActivity` gagal dengan `missing_match` |
| src/ServerScriptService/Server/SpectatorSystem/SpectatorService.lua | 57 | `OnPlayerDied` dead code — subscribe `PlayerDied` tapi `PlayerDeathSystem` publish `PlayerKilled`, bukan `PlayerDilled` |
| src/ServerScriptService/Server/PlayerDeathSystem/Service.lua | 163-169 | `PlayerKilled` publish tanpa `matchId` — payload mismatch dengan subscriber yang expect `matchId` |
| src/ServerScriptService/Server/GhostSystem/Service.lua | ~391-1450 | **Ghost animations MISSING** — `ensureGhostAnimator()` setup Animator + animation clips loaded, tapi **tidak ada `LoadAnimation():Play()` call** di seluruh GhostSystem. Animator exists, clips loaded, track kosong. Ghost berjalan T-pose. |

---

## [LEGACY]

| File | Keterangan |
|------|-----------|
| src/client/UI/QuestJournal.lua | `LEGACY_MATCH_PHASE_ATTR = "MatchPhase"` - attribute lama masih di-reference |
| src/client/UI/QuestTracker.lua | `LEGACY_MATCH_PHASE_ATTR = "MatchPhase"` - sama |
| src/client/EvidenceTools/Main.lua | `EMF Scanner` sebagai display name |
| src/shared/GameData/UIIconAssets.lua | `DISABLED` sebagai key name |
| src/shared/GameData/ShopMarketplaceConfig.lua | Comment tentang `10576163165` invalid |

---

## [DRIFT]

| File | Baris | Keterangan |
|------|-------|-----------|
| src/shared/DataTypes/ShopMarketplaceConfig.lua | 3-5 | `10576163165` invalid — hanya di-comment, TIDAK dipakai code (LOW) |
| src/shared/GameData/GhostVisualTuning.lua | - | **KOREKSI: BUKAN stale.** IDs di file ini adalah second-account IDs yang SUDAH diverifikasi runtime pada 2026-05-13 s/d 2026-05-17. Semua 12 ghost confirmed HasSkinnedMesh=true, bones validated, Animator=1, SurfaceAppearance=1. Wire ini BENAR untuk branch ini. |
| src/ReplicatedStorage/Assets/Models/Ghosts/CanonicalGhostModels.lua | 1-27 | **KOREKSI: BUKAN stale.** Owner field benar (groupId=407883270 PASRAHPHOBIA DEVELOPER & TEAM). IDs adalah second-account uploads (briankotak) yang valid dan terkonfirmasi bekerja di runtime. |
| src/shared/GameData/FlashlightConfig.lua | 7-8 | MeshId textureId hardcoded |
| src/shared/GameData/ToolVisualConfig.lua | - | Multiple hardcoded asset IDs |
| src/ServerScriptService/Server/SpectatorSystem/SpectatorDistortionEngine.lua | 10-14 | `NearGhostWeights` (50/40/10) tidak ada di CANONICAL_SPEC — undocumented feature. Base weights (60/30/10) sudah sesuai spec. |
| src/ServerScriptService/Server/SpectatorSystem/SpectatorDistortionEngine.lua | 15-16 | `CooldownMinSeconds=5, CooldownMaxSeconds=10` tidak ada di spec. Cooldown logic juga dead code karena bug IsOnCooldown. |
| CANONICAL_SPECIFICATIONS_v2.md | 171-198 | **DRIFT ASLI di sini.** Spec 2026-04-18 lock menunjuk first-account IDs dari `asset mentah/[ASSETID]/Models & Packages.csv`. Branch `brian-second-final` menggunakan second-account IDs (briankotak) yang BENAR untuk akun ini. Spec stale untuk branch ini, BUKAN kode. |

---

## [FUTURE]

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/CameraController.client.lua | 6 | Comment: `Based on: CANONICAL_SPECIFICATIONS_v2.md Phase 7.5` |
| src/client/MovementController.client.lua | 4 | Comment: `Based on: CANONICAL_SPECIFICATIONS_v2.md Phase 7.5` |
| - | - | Tidak ada TODO/FUTURE markers besar yang blocking |

---

## [HIGH_CONFLICT_RISK]

| File | Keterangan |
|------|-----------|
| src/ServerScriptService/Server/EvidenceSystem/ | Folder ini punya banyak sub-modules dengan overlapping responsibility |
| src/ServerScriptService/Server/GhostSystem/ | Ghost state machine dengan banyak states dan behaviors |
| src/ServerScriptService/Server/LobbySystem/ | Room browser dengan banyak UI states |
| src/ServerScriptService/Server/SpectatorSystem/ | Spectator dengan distortion engine dan communication — **DUA sistem terpisah**: SpectatorModeSystem (WORKING) vs SpectatorSystem ghost-vision (DISCONNECTED) |
| src/client/UI/Main.lua | **21,778 lines, 259 methods, 11 panels** — MONOLITHIC. Hotspot: `_onServerEvent` 438-line if/elseif chain (line 6147), `_applyDeviceSizing` 229-line (16744), `_bindAuthored*Ui` 132-168 line each. Sebaiknya dipisah per panel boundary. |

---

## [MULTI_OWNER]

| File | Keterangan |
|------|-----------|
| src/ServerScriptService/Server/EvidenceSystem/Modules/ | Campuran EvidenceService.lua dan EvidenceEngine.lua dengan tanggung jawab overlap |
| src/ServerScriptService/Server/LobbySocialHub/ | Banyak subfolders (Buildings, Zones, PartySystem) dengan controller/service patterns berbeda |
| src/ServerScriptService/Server/GhostSystem/ | GhostAbilities, GhostAI, GhostPersonality, States folders |
| src/ServerScriptService/Server/EconomySystem/Rewards/ | DailyCheckIn, DailyMissions, MatchCompletion, RoyalPass subfolders |

---

## [WORKING]

| File | Keterangan |
|------|-----------|
| src/ServerScriptService/Server/Core/SystemRegistry.lua | Working - deterministic boot dengan DISABLED list |
| src/ServerScriptService/Server/LobbySystem/ | Working - room browser, queue, match trigger |
| src/ServerScriptService/Server/MatchSystem/ | Working - match lifecycle, teleport, queue |
| src/ServerScriptService/Server/GhostSystem/ | Working - ghost state machine, evidence triggers |
| src/ServerScriptService/Server/EvidenceSystem/ | Working - evidence detection dan collection |
| src/ServerScriptService/Server/SpectatorSystem/ | Working - spectator mode dengan distortion engine |
| src/ServerScriptService/Server/SpectatorSystem/Modules/SpectatorDistortionRules.lua | **CONFIRMED** - Probabilities sesuai spec: fake=60, uncertain=30, real=10 |
| src/ServerScriptService/Server/DataPersistenceService/ | Working - profile load/save dengan LoadProfile/SaveProfile |
| src/ServerScriptService/Server/ProfileSystem/ | Working - profile management |
| src/ServerScriptService/Server/RankedSystem/ | Working - 8-tier rank system |
| src/ServerScriptService/Server/ShopSystem/ | Working - purchase validation |
| src/ServerScriptService/Server/CosmeticSystem/ | Working - cosmetic equip flow |
| src/client/CameraController.client.lua | Working - FPV lock dengan head bobbing |
| src/client/MovementController.client.lua | Working - WalkSpeed=10, JumpPower=32 |
| src/client/FlashlightController.client.lua | Working - flashlight toggle |
| src/shared/GameData/GhostDatabase.lua | Working - 12 Indonesian ghosts |
| src/shared/GameData/ModeDifficultyConfig.lua | Working - Mudah/Lumayan/Angker/Uji Nyali |

---

## [WRONG]

| File | Baris | Keterangan |
|------|-------|-----------|
| - | - | **Tidak ada drift besar dari CANONICAL_SPEC** - SpectatorDistortion base weights (60/30/10) sesuai spec |
| CANONICAL_SPECIFICATIONS_v2.md | 171-198 | **Spec stale untuk branch ini** — spec lock 2026-04-18 menunjuk first-account IDs; branch `brian-second-final` gunakan second-account IDs (briankotak) yang benar untuk akun ini. Kode bukan yang salah. |

---

## [ASSET_CODE_CONFIRMED]

| File | Asset ID | Keterangan |
|------|----------|------------|
| src/ReplicatedStorage/Assets/Models/Ghosts/CanonicalGhostModels.lua | 125985418520274 | Banaspati — second-account (briankotak), validated runtime 2026-05-17 |
| src/ReplicatedStorage/Assets/Models/Ghosts/CanonicalGhostModels.lua | 116514308503184 | Genderuwo — second-account, validated runtime |
| src/ReplicatedStorage/Assets/Models/Ghosts/CanonicalGhostModels.lua | 111714179492317 | Kuntilanak — second-account, validated runtime |
| src/ReplicatedStorage/Assets/Models/Ghosts/CanonicalGhostModels.lua | 135270375666027 | Pocong — second-account, validated runtime |
| src/ReplicatedStorage/Assets/Models/Ghosts/CanonicalGhostModels.lua | 98855032697085 | Leak — second-account, validated runtime |
| src/ReplicatedStorage/Assets/Models/Ghosts/CanonicalGhostModels.lua | 78260225419720 | Palasik — second-account, validated runtime |
| src/ReplicatedStorage/Assets/Models/Ghosts/CanonicalGhostModels.lua | 89326336764042 | SundelBolong — second-account, validated runtime |
| src/ReplicatedStorage/Assets/Models/Ghosts/CanonicalGhostModels.lua | 87361945667344 | SilumanUlar — second-account, validated runtime |
| src/ReplicatedStorage/Assets/Models/Ghosts/CanonicalGhostModels.lua | 97068595212213 | HantuTanah — second-account, validated runtime |
| src/ReplicatedStorage/Assets/Models/Ghosts/CanonicalGhostModels.lua | 115554451751983 | Jerangkong — second-account, validated runtime |
| src/ReplicatedStorage/Assets/Models/Ghosts/CanonicalGhostModels.lua | 128588579954533 | Tuyul — second-account, validated runtime |
| src/ReplicatedStorage/Assets/Models/Ghosts/CanonicalGhostModels.lua | 101666948803556 | WeweGombel — second-account, validated runtime |
| CanonicalGhostModels.lua owner | 407883270 | Group: PASRAHPHOBIA DEVELOPER & TEAM — konsisten di semua asset |
| OwnerCheatConfig.DEFAULT_OWNER_USER_ID | 8603977492 | Owner account UserId konsisten |
| Shop marketplace IDs | 3573224039–3573232383 | 10 GamePass/DeveloperProduct IDs — valid Creator Hub marketplace |
| src/ReplicatedStorage/Assets/Models/Tools/*.rbxm | - | 8/8 tool .rbxm files EXISTS on disk |
| src/shared/GameData/ToolVisualConfig.lua | 8 items | All tool asset IDs via ToolVisualAssetSystem runtime refresh |
| src/shared/GameData/ShopMarketplaceConfig.lua | 3573231558 | royalpass_premium_track |
| src/shared/GameData/ShopMarketplaceConfig.lua | 3573231828 | class_dukun_unlock |
| src/shared/GameData/ShopMarketplaceConfig.lua | 3573224039 | pp_pack_small |

## [UIPADDING_AUDIT]

| Check | Result |
|-------|--------|
| PaddingAll anti-pattern | **TIDAK ADA** — tidak ada PaddingAll di codebase |
| Per-side UIPadding pattern | **BENAR** — semua UIPadding set per-side (Top/Bottom/Left/Right) |
| Safe area handling | `applySafePadding` (Main.lua:18701) — correct |
| Minor deviation | `PasrahLoadingScreen.client.lua:90` — bare UIPadding dengan default 0,0 (harmless) |

---

## [UX_HIERARCHY_ISSUE]

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 5261, 17259 | RoomBrowser `_roomBrowserSuppressed` permanently locked `true` saat teleport, hanya di-reset via `_returnFromResultsToLobby` — jika player bypass results screen, toggle mati permanen |
| src/ServerScriptService/Server/MatchSystem/MatchQueue.lua | 165, 178, 185 | `already_queued` spam tanpa gate |

---

## [ASSET_VISUAL_PASS]

| Asset | Keterangan |
|-------|------------|
| Ghost Models | Canonical 12 Indonesian ghosts dengan variant naming (Aggressive/Angry suffix) |
| Loading Screen | Vignette + sprite atlas dengan verified asset IDs |
| Tool Visuals | EMF screen, flashlight models |
| Ghost Visual Tuning | Per-ghost asset configurations |

---

## [UI_PASS]

| UI | Keterangan |
|----|------------|
| RoomBrowserUI | ScreenGui exists dengan room list, host controls, map preview |
| LobbyUI | Panel dengan mode selection, queue trigger |
| MatchUI | Panel dengan match info, hide/close controls |
| ShopUI | Shop dengan category filtering |
| ProfileUI | Profile dengan rank/EXP context |
| RoyalPassUI | Royal pass dengan tier display |
| SpectatorUI | Spectator dengan distortion text |

---

## SUMMARY STATS

| Category | Count |
|----------|-------|
| ERROR | 3 |
| CONFLICT | 8 (1 RESOLVED) |
| DISABLED | 32 systems |
| DUPLICATE | 4 pairs |
| MISSING | 3 items |
| INCOMPLETE | 8 items (↑ dari 7) |
| LEGACY | 5 items |
| DRIFT | 6 items |
| FUTURE | 2 items |
| HIGH_CONFLICT_RISK | 7 systems |
| MULTI_OWNER | 4 systems |
| WORKING | 20+ systems confirmed |
| ASSET_CODE_CONFIRMED | 27+ verified |
| UIPADDING_AUDIT | PASS |
| GHOST_ANIMATION_MISSING | 1 (CRITICAL) |
| GHOST_TRANSPARENCY_DESIGN | 1 (HIGH) |
| GHOST_NAVIGATION_STUCK | 1 (HIGH) |
| GHOST_FLOOR_Y_WRONG | 1 (MEDIUM) |
| GHOST_SCALE_BYPASS | 1 (FIXED) |
| SAFEZONE_OUTSIDE_MAP | 1 (HIGH) |
| BACKPACK_CURSOR_CONFLICT | 1 (MEDIUM) |
| COUNTDOWN_AUDIO_DUPLICATE | 1 (MEDIUM) |
| ROOMBROWSER_PERFORMANCE | 1 (MEDIUM) |
| LOBBY_TRANSPARENT_PARTS_PERF | 1 (MEDIUM) |

---

## [MAIN_LUA_JOURNAL_AUTOOPEN] — CRITICAL

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 6149-6153 | Journal UI auto-open pada SEMUA `EvidenceEvent` tanpa cek apakah benar-benar evidence collection baru. Kondisi `shouldAutoOpenJournal = payload == nil or payload.autoOpenJournal ~= false` — default OPEN. Catch-all `FIELD_KIT_TOOL_CONFIG[payload.toolType]` (line 6224) juga trigger `_refreshJournalPanel()`. Setiap tool use (flashlight F, EMF scan 1, dll.) yang kirim `EvidenceEvent` membuka Journal UI. Ini penyebab "Journal terbuka tiba-tiba saat flashlight dinyalakan." |

## [MAIN_LUA_PHASE_DOUBLE_TRANSITION] — HIGH

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 18452-18559, 18997-19031 | `_routeMatchPhaseEvent` tidak ada guard `_uxReady`, `_handleMatchUXEvent` ada guard. Untuk `PhaseChanged`, keduanya jalan bersamaan saat UX ready — `_setPhase()` + `_renderPhase()` (force close panels) dan `TransitionTo()` (setup Hunt overlay/navigation) tanpa locking antar keduanya. Bisa menyebabkan Journal UI flash/flicker saat phase transition. |

## [MAIN_LUA_SPECTATOR_AUTOOPEN_PREPARATION] — MEDIUM

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 6336, 6348 | `SpectatorUI.visible = true` saat `eventName == "PlayerKilled"` tanpa cek match phase. Jalan bahkan saat preparation phase (belum ada ghost hunt). Player yang mati saat preparation melihat SpectatorUI tapi tidak ada ghost untuk divisualisasikan. |

## [MAIN_LUA_UXINSTANCES_NO_RESET] — MEDIUM

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 15979-15984 | `_trackUXInstance()` insert ke table tanpa reset setelah `_clearUXInstances()`. `self._uxInstances` tidak di-set ke `{}` setelah destroy. Stale reference menumpuk jika `_trackUXInstance` dipanggil lagi setelah clear. |

## [MAIN_LUA_VIEWPORTFRAME_LEAK] — MEDIUM

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 2241-2248, 2322-2328 | `WorldModel` + `Camera` dalam ViewportFrame (lobby ghost preview, journal ghost preview) tidak di-destroy eksplisit saat preview di-teardown. Hanya implicit destroy via parent ViewportFrame destruction. Jika ViewportFrame di-reuse tanpa di-destroy, Camera/WorldModel child menumpuk. |

## [MAIN_LUA_ROOMBROWSER_CONNECTION_STACK] — MEDIUM

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 20922-20951, 20963 | `_bindRoomBrowserModeFilterVisualGroup()` — attribute guard `PasrahRoomModeFilterVisualBound` proteksi per-button per-call. Tapi `_syncRoomBrowserModeFilterVisuals()` (line 20963) call binding unconditional setiap render. Jika widget reference berubah antar render (RoomBrowser di-rebuild), attribute tidak carry-over → `MouseEnter`/`MouseLeave` koneksi menumpuk pada button baru. |

## [MAIN_LUA_PLAYERSLIST_DOUBLE_CLEAR] — LOW

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 21403, 21563 | `_clearGeneratedRoomBrowserGuiChildren(PlayersList)` dipanggil 2x dalam 1 `_refreshRoomBrowserView` cycle. Kedua call Destroy SEMUA player cards, tidak ada dedup atau batching. |

## [MAIN_LUA_JOURNAL_NO_PHASE_CHECK] — LOW

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 6149-6153 | Journal auto-open tanpa cek `self._matchPhase`. Jalan saat lobby, preparation, result — Journal bisa terbuka di luar fase investigation. |

## [MAIN_LUA_CURSOR_UNLOCK_NO_MOUSE_BEHAVIOR] — LOW

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 10177, 10201, 10234 | `PasrahCursorUnlockRequested` attribute di-set (sebagai signal ke sistem lain), tapi tidak ada `UserInputService.MouseBehavior = ...` di file ini. Unlock cursor di-handle oleh sistem eksternal. Main.lua hanya mengirim attribute signal tanpa actual effect di file ini. |

## [MAIN_LUA_PHASECHANGED_NIL_SILENT_DROP] — LOW

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 18510-18511 | `resolvePhaseFromPayload(eventName, payload)` return `nil` untuk `PhaseChanged` jika payload tidak punya `phase`/`phaseName`/`lifecyclePhase`. Tidak ada `else` branch — phase transition silently dropped. |

## [MAIN_LUA_ONServerEvent_MONOLITHIC] — MEDIUM (tech debt)

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 6144-6587 | `_onServerEvent` — single 443-line if/elseif chain yang handle 9 remote branch (Evidence, Lobby, Match, Purchase, Cosmetic, RoyalPass, DailyEngagement, Sanity). Tidak ada early return, helper extraction, atau sub-dispatch. Maintenance sangat sulit. Setiap event baru menambah complexity. |

---

## BLOCKERS FOR PUBLISH

### CRITICAL (Blocking)
1. **Journal auto-open pada setiap EvidenceEvent** — termasuk flashlight toggle, EMF scan, tool feedback. Ini menyebabkan Journal terbuka tiba-tiba saat player sedang tidak mau buka Journal.
2. **Ghost animations tidak pernah played** — GhostSystem setup animator + load clips tapi tidak ada `LoadAnimation():Play()`. Ghost berjalan T-pose tanpa animasi jalan.
3. **Ghost 75% transparan saat Idle** — Saat investigation phase (Idle/Roaming), ghost hampir invisible (75% transparency). QA melihat ghost di viewport server karena viewport tidak render transparency. Player tidak melihat ghost.

### HIGH PRIORITY (Blocking)
4. **Phase double transition** — `_routeMatchPhaseEvent` dan `_handleMatchUXEvent` jalan bersamaan untuk `PhaseChanged` tanpa locking → Journal UI flash/flicker.
5. **Ghost stuck saat Hunt** — `isGhostNavigationLineClear()` block movement jika line-of-sight obstructed.
6. **Safe zone di luar map** — Hanya 2 safe zone hardcoded di luar Foyer, bukan di closet/hiding spot.
7. **SpectatorSystem ghost-vision DISCONNECTED** — Ghost vision overlay tidak pernah di-trigger.
8. **ResultsCalculated orphan subscription** — MatchCompletion subscribe event yang tidak ada publisher aktif.
9. **RoomBrowser state reset** — `_roomBrowserSuppressed` locked `true` permanen jika bypass results screen.

### MEDIUM PRIORITY
10. **Ghost di rooftop** — `resolveGhostFloorY()` raycast hitting ceiling di elevated areas.
11. **Countdown audio duplikat** — Race condition antara loop tick dan server event.
12. **RoomBrowser mouse heaviness** — 50+ Destroy+Clone dalam 1 frame saat room list update.
13. **SpectatorUI auto-open saat preparation phase** — Tidak ada phase check.
14. **`_uxInstances` table tidak di-reset** — Stale reference menumpuk.
15. **ViewportFrame Camera/WorldModel leak** — Tidak di-destroy eksplisit.
16. **RoomBrowser connection stacking** — MouseEnter/MouseLeave menumpuk saat widget rebuild.
17. **PlayersList double clear** — 2x Destroy dalam 1 render cycle.
18. **Backpack cursor konflik** — Backpack terbuka saat unlock cursor dengan `~`.
19. **Lobby transparent parts performance** — Semi-transparent overlay trigger overdraw.
20. **PlayerKilled tanpa matchId** — Payload mismatch.
21. **`_onServerEvent` monolithic** — 443-line if/elseif chain, tech debt tinggi.
22. **Ghost preview model leak** — WorldModel/Camera tidak di-destroy.

### LOW PRIORITY
23. **Ghost scale bypass** — FIXED: `PasrahGhostRuntimeAssetTemplate = false` → `= true`.
24. **Journal auto-open tanpa phase check** — Bisa open di lobby/preparation/result.
25. **Cursor unlock attribute tanpa MouseBehavior** — Main.lua hanya kirim signal, tidak ada effect langsung.
26. **PhaseChanged nil silent drop** — Jika payload tidak punya phase info, transition silently dropped.
27. **IsOnCooldown semantic naming** — parameter `lastDistortionAt` menipu.
28. **NearGhostWeights undocumented** — feature tidak ada di spec.
29. **Cooldown bounds undocumented** — 5-10s tidak ada di spec.
30. **Legacy attribute references** — LEGACY_MATCH_PHASE_ATTR masih di-reference.
31. **EMF naming** — Display name masih "EMF Scanner".
32. **assets/generated/manual_inbox/ 69 PNGs orphan** — staging artifacts belum diupload.

---

## [PERF_MAIN_LUA_LOOP_NO_YIELD] — CRITICAL

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 18569-18597 | Phase timer loop 0.1s tick — `_refreshBasicMatchPanel()` jalan TANPA cek dirty flag. Setiap tick recompute match panel, hunt assist snapshot, navigation anchor lookup. Impact: 10x full UI recompute per detik bahkan saat idle di lobby. |

## [PERF_MAIN_LUA_ROOMBROWSER_10HZ] — CRITICAL

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 21657-21674 | Room browser loop 10Hz (0.1s tick) — `_renderRoomUI()` jalan setiap tick. `_refreshRoomBrowserView()` destroy + clone SEMUA room rows + player cards setiap render. Tidak ada diffing. Impact: 10x full DOM rebuild per detik. |

## [PERF_MAIN_LUA_REFRESH_NO_DIRTY] — CRITICAL

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 18571 | `_refreshBasicMatchPanel` (10484-10700+) jalan tanpa dirty flag. Panggil `getNearestNavigationAnchorInfo`, `getInvestigationObjectiveText`, `getHuntObjectiveText`, `RefugeHints.getPreferredHuntRefugeInfo` — semua dengan `Workspace:GetDescendants()` chains setiap 100ms. |

## [PERF_MAIN_LUA_DESCENDANTS_HUNT] — HIGH

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 4084-4096 | `collectNavigationAnchors()` scan entire map model via `GetDescendants()` untuk TraversalGuide labels. Dipanggil oleh `getNearestNavigationAnchorInfo()` yang di-chain dari `_refreshBasicMatchPanel()` setiap 0.1s. Impact: full map scan 10x/detik saat investigation phase. |
| src/client/UI/Main.lua | 4276-4280 | `resolveLobbySpawnParts()` scan entire Maps workspace untuk `PlayerSpawn_%d+` patterns. Dipanggil dari `resolveLobbyZonePosition` dan `getLobbyZoneDistanceText`. |

## [PERF_MAIN_LUA_VIEWPORT_REBUILD] — HIGH

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 2307-2379 | `renderLobbyTrainingGhostPreview` destroy semua children + rebuild ViewportFrame setiap `PreviewSignature` berubah. Signature pakai `math.floor(aggression)` — bisa berubah sering saat Hunt. Camera + WorldModel + model clone direcreate setiap kali. |

## [PERF_MAIN_LUA_CONNECTION_GROW] — MEDIUM

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 6029, 6035, 6041, 6044, 18611-18613, 20816, 21067, 21088, 21109, 21132, 21190 | Multiple `table.insert(self._connections, ...)` — tidak ada cleanup antar game session. `UserInputService.InputBegan` 4x koneksi. `RunService.Heartbeat` dedicated listener. Connection table grow per session. |

## [PERF_MAIN_LUA_UISCALE_LEAK] — MEDIUM

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 1156, 1403, 1574-1583 | `_ensureNamedScale` buat `Instance.new("UIScale")` setiap call. Dipanggil dari `ensureButtonPolish` untuk setiap button. `pulseCountdownLabel` buat UIScale + Tween setiap detik. UIScale instances tidak di-destroy. |

## [PERF_ANIMPIPELINE_WORKSPACE_SCAN] — CRITICAL

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/GhostAnimationPipeline/Main.lua | 423, 436 | `_findAnimator()` panggil `Workspace:GetDescendants()` DUA KALI setiap `Play()` call. Tidak ada caching. Setiap 0.5s watchdog + setiap attribute change + setiap match event = full workspace scan. Impact: O(n) scan per animation play, n = workspace instance count. |

## [PERF_ANIMPIPELINE_WATCHDOG_NO_PAUSE] — CRITICAL

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/GhostAnimationPipeline/Main.lua | 281-292 | `_startAnimationWatchdog()` — loop 0.5s `task.wait` tanpa pause/stop. `_ensureActiveAnimation()` chains ke `_findAnimator()` setiap 500ms. Watchdog tidak pernah distop — berjalan bahkan saat Result/End phase. |

## [PERF_ANIMPIPELINE_ATTR_NO_DEBOUNCE] — HIGH

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/GhostAnimationPipeline/Main.lua | 221-223, 367-378 | Subscribe ke 6 attribute change signals — setiap change langsung trigger `Play()`. Tidak ada throttle. Rapid attribute updates (state machine cepat) = animation thrashing + redundant workspace scans. |

## [PERF_GHOSTRENDERER_CONNECTION_LEAK] — CRITICAL

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/GhostRenderer/Main.lua | 34, 40 | `self._connections` di-populate di `Start()` tapi **tidak ada `Stop()` / `Destroy()` method**. Connections tidak pernah di-disconnect. Jika module re-init mid-session, old connections stay alive forever. |

## [PERF_SPECTATOR_CONN_LEAK] — CRITICAL

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/SpectatorEffects/Main.lua | 170-172 | `RunService.Heartbeat` + 3 remote-event connections di `self._connections` — **tidak ada cleanup path**. Heartbeat fires every frame indefinitely. |

## [PERF_SPECTATOR_HEARTBEAT_IDLE] — HIGH

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/SpectatorEffects/Main.lua | 170-172 | Heartbeat closure invoked every frame (60+ times/detik) bahkan saat tidak spectating. Guard `if not spectating then return end` mencegah camera work tapi callback tetap dieksekusi setiap frame. |

## [PERF_SPECTATOR_GETCHILDREN_HOT] — HIGH

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/SpectatorEffects/Main.lua | 295-298 | `findOverlayFrames()` panggil `playerGui:GetChildren()` setiap `_setOverlayState()` call. Dipanggil beberapa kali per distortion event. `GetChildren()` allocate array semua child instances. |

## [PERF_SPECTATOR_STAMP_EXCESSIVE] — HIGH

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/SpectatorEffects/Main.lua | 373-389 | `_stampRuntimeState()` dipanggil berlebihan — setiap Init, `_setPostEffects`, `_setOverlayState`, `ExitSpectatorMode`. Setiap call = 5+ attribute writes + 3x `_stampEffectInstance()` (masing-masing 4 more writes). Tidak ada dirty flag. |

## [PERF_SOUNDSYSTEM_GETDESC_AUDIO_EVENT] — CRITICAL

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/SoundSystem/Main.lua | 377 | `findNamedBasePart()` panggil `root:GetDescendants()` per audio event. Dipanggil dari `_resolvePlaybackTarget()` yang dipanggil dari `_playLoopedCategory()` dan `_playOneShotCategory()` pada **setiap audio event**. Room model ratusan descendants = O(n) per audio trigger. |

## [PERF_MOVEMENT_RENDERSTEPPED] — CRITICAL

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/MovementController.client.lua | 207-271 | `RunService.RenderStepped:Connect(...)` jalan setiap frame tanpa throttling. Full character resolution + planar movement math + 3x `SetAttribute` per frame. Tidak ada early-return untuk idle state. Impact: 60fps attribute I/O bahkan saat player diam. |

## [PERF_MOVEMENT_CONN_LEAK] — HIGH

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/MovementController.client.lua | 144, 145, 155, 183 | `player.CharacterAdded`, `player.CharacterRemoving`, `UserInputService.InputBegan`, `UserInputService.InputEnded` — semua connected saat init, **tidak ada `Stop()` method**. Handler accumulate jika controller re-init. |

## [PERF_CAMERA_RENDERSTEPPED] — CRITICAL

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/CameraController.client.lua | 985-1119 | `RunService:BindToRenderStep("HeadBob", ...)` jalan setiap frame dengan full FPV camera math. Guard hanya clear arms tapi callback tetap dieksekusi setiap frame. `ensureFpvArms()` → `sanitizeFpvClonePart()` → `clonePart:GetDescendants()` per frame. |

## [PERF_CAMERA_TASKSPAWN_CASCADE] — HIGH

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/CameraController.client.lua | 460-475, 506 | `realignCameraToCharacter()` spawn task dengan `RunService.RenderStepped:Wait()` 2-3x. `scheduleMatchCameraRealign()` fire pada setiap `MatchLifecyclePhase` change. Jika phase berubah cepat, tasks stack di RenderStepped = cascading delays. |

## [PERF_CAMERA_CONN_LEAK] — HIGH

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/CameraController.client.lua | 904-921, 948-977 | Multiple connections tidak disimpan: `player:GetAttributeChangedSignal("PasrahNpcDialogueActive")`, `player.CharacterAdded`, `UserInputService.WindowFocusReleased/WindowFocused`, `UserInputService.InputBegan`, cursor unlock signal. Tidak ada `Stop()` method. |

## [PERF_SPECTATORSYSTEM_RENDERSTEPPED] — HIGH

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/SpectatorSystem/Main.lua | 89-91 | `RunService.RenderStepped:Connect(...)` jalan setiap frame. Guard `if not spectating then return end` tapi callback tetap fire setiap frame. |

## [PERF_SPECTATORSYSTEM_NOSTOP] — HIGH

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/SpectatorSystem/Main.lua | 77-91 | `matchEvent` dan `lobbyEvent` connections + `RenderStepped` connection tidak ada cleanup path. Tidak ada `Stop()` function. |

---

## [PERF_GHOST_PREVIEW_LEAK] — MEDIUM

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 2241-2248, 2322-2328 | Ghost preview `WorldModel` + `Camera` dalam ViewportFrame tidak di-destroy eksplisit saat teardown. Camera + WorldModel menumpuk jika ViewportFrame di-reuse. |

---

## IMPLEMENTATION SCORE ESTIMATE

Berdasarkan audit:
- **75-78% implementation complete** (turun dari 77-80% karena temuan PERFORMANCE CRITICAL baru: 6+ render loop tanpa pause/stop, 5+ connection leak, workspace scan per animation play, heartbeat idle cost)
- Core loop: Match → Investigation → Hunt → Results = WORKING
- Ghost state machine: WORKING, tapi **animations MISSING** (critical)
- Ghost visibility: BUG — 75% transparan saat Idle
- Ghost navigation: BUG — stuck saat Hunt
- Lobby systems: WORKING, tapi **performance issue** dari transparent parts
- Ghost/Evidence/Sanity/Aggression: WORKING (ghost assets validated runtime 2026-05-17)
- Journal UI: WORKING tapi **auto-open critical bug** — setiap EvidenceEvent buka journal
- Phase transition: BUG — double transition tanpa locking
- RoomBrowser: WORKING tapi **mouse heaviness** + **connection stacking** + **double clear**
- Ghost preview: WORKING tapi **ViewportFrame leak**
- Economy/Shop/Rewards: WORKING
- Spectator free-camera (SpectatorModeSystem): WORKING
- Spectator ghost-vision/distortion (SpectatorSystem): DISCONNECTED
- Ownership chain: KONSISTEN
- Remaining: Ghost animation wiring, journal auto-open fix, phase transition locking, ghost visibility tuning, navigation fix, safe zone placement, SpectatorSystem wiring, UI perf, UX cleanup, 69 orphan PNGs upload

---

*Audit generated: 2026-06-14*
*Updated: 2026-06-14 (session findings — ghost animation missing, transparency design, navigation stuck, floorY, safezone outside map, backpack conflict, countdown duplicate, roombrowser perf, lobby transparent parts, Main.lua journal auto-open, phase double transition, spectator auto-open, uxinstances no reset, viewportframe leak, roombrowser connection stack, playerslist double clear, journal no phase check, cursor unlock no mouse behavior, phasechanged nil drop, onserverevent monolithic)*
*Total files scanned: ~1,183 Lua files + 369 assets*
*Reference: CANONICAL_SPECIFICATIONS_v2.md, REPORTS.md, TASK_ACTIVE.md*

| File | Baris | Keterangan |
|------|-------|-----------|
| src/ServerScriptService/Server/GhostSystem/Service.lua | ~391-1450 | `ensureGhostAnimator()` setup Animator, `loadGhostModelAssetTemplate()` load animation clips, TAPI **tidak ada satupun `LoadAnimation():Play()` call** di seluruh GhostSystem. Animator exists, clips loaded, tapi track animation tidak pernah dimainkan. Ghost berjalan dengan T-pose / default rig pose. Motion hanya dari `computeGhostVisualCFrame()` bob/sway via `PivotTo()` — bukan animation. |

## [GHOST_TRANSPARENCY_DESIGN] — HIGH

| File | Baris | Keterangan |
|------|-------|-----------|
| src/ServerScriptService/Server/GhostSystem/Service.lua | 135-141 | `GHOST_VISUAL_TRANSPARENCY_BY_STATE` — Ghost **75% transparan saat Idle** (`Idle = 0.75`), 35% saat Roaming, 5% saat Hunting. Saat investigation phase (Idle/Roaming), ghost hampir invisible. Ini yang menyebabkan "ghost selalu PASS di QA tapi player tidak melihat". Viewport server melihat ghost karena transparency hanya affect rendering, bukan hierarchy existence. |

## [GHOST_NAVIGATION_STUCK] — HIGH

| File | Baris | Keterangan |
|------|-------|-----------|
| src/ServerScriptService/Server/GhostSystem/Service.lua | 2274-2276, 3500-3504 | `isGhostNavigationLineClear()` — ghost hanya bergerak jika line-of-sight clear dari current ke desired position. Jika furniture/walls obstruct path, ghost stuck. Tidak ada pathfinding fallback atau teleport. Berlaku saat Hunt. |

## [GHOST_FLOOR_Y_WRONG] — MEDIUM

| File | Baris | Keterangan |
|------|-------|-----------|
| src/ServerScriptService/Server/GhostSystem/Service.lua | 2729-2743 | `resolveGhostFloorY()` — raycast dari `Y + 12` ke bawah 96 studs. Di elevated areas (attic, mezzanine, second floor), raycast hitting ceiling terlebih dahulu → ghost Y resolution salah → ghost terlihat di rooftop / di atas map. |

## [GHOST_SCALE_BYPASS] — FIXED

| File | Baris | Keterangan |
|------|-------|-----------|
| src/ServerScriptService/Server/GhostSystem/Service.lua | 1649 | `PasrahGhostRuntimeAssetTemplate = false` bypass `clampGhostTemplateScale()` → ghost tampil dengan native bounding box (kecil, ~setengah player height). **FIXED 2026-06-14**: ubah ke `= true`. |

## [SAFEZONE_OUTSIDE_MAP] — HIGH

| File | Baris | Keterangan |
|------|-------|-----------|
| src/ServerScriptService/Server/MatchSystem/HauntedHouseRuntimeLayout.lua | 39-42 | Hanya 2 safe zone hardcoded di luar Foyer: `SafeZone_1 = v3(-30.5, 50.5, -25.0)`, `SafeZone_2 = v3(-16.5, 50.5, -25.0)`. Keduanya di luar rumah, bukan di closet/lemari/hiding spot. Kode tidak punya logika auto-detect hiding spot. Safe zone harus di-hardcode per posisi. |

## [BACKPACK_CURSOR_CONFLICT] — MEDIUM

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | ~5261 | Tidak ada handler `KeyCode.Backquote`/`KeyCode.Tilde`. Saat unlock cursor dengan `~`, Roblox default behavior open Backpack. Tidak ada `StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)` saat masuk match FPV. Inventory terbuka bersamaan dengan cursor unlock → user confused saat mau close cursor untuk belokin player. |

## [COUNTDOWN_AUDIO_DUPLICATE] — MEDIUM

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 21625-21635 | `_updateCountdownOverlay()` dipanggil tiap 0.1s oleh `_startRoomBrowserLoop()` (line 21655). Jika `displayCountdown ~= self._countdownDisplaySecond` → `playRuntimeUISound("CountdownTick", {SingleInstance=true})`. Race condition: server `RoomMatchCountdown` event + loop tick bisa trigger 2x play dalam 0.1s window sebelum SingleInstance guard efektif. Kemungkinan juga: 2 client call overlap saat network jitter → 2x audio tanpa dedup. |

## [ROOMBROWSER_PERFORMANCE] — MEDIUM

| File | Baris | Keterangan |
|------|-------|-----------|
| src/client/UI/Main.lua | 20241-20306 | `renderRoomList()` — setiap room list update, `_clearGeneratedRoomBrowserGuiChildren()` destroy SEMUA row + `_cloneAuthoredGuiTemplate()` untuk setiap room dalam 1 frame tanpa yield. Jika 50 room → 50 Destroy + 50 Clone dalam 1 frame → mouse heaviness / lag saat scroll. |

## [LOBBY_TRANSPARENT_PARTS_PERF] — MEDIUM

| File | Baris | Keterangan |
|------|-------|-----------|
| src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua | 2328-2499, 2504-2508 | `applyWingShell()` + `applyWingFrontage()` membuat part dengan `Transparency = 0.02` hingga `0.34`, `Material = Glass` untuk window panels. Lobby memiliki banyak semi-transparent overlay yang trigger per-frame overdraw. |
| src/ServerScriptService/Server/MatchSystem/HauntedHouseMapScaffold.lua | 115-132 | 50+ invisible proxy parts (`Transparency=1, CanQuery=true, CanCollide=false`) untuk rooms, spawns, ghost spawns, evidence nodes, safe zones, door proxies. Semua participate dalam raycast query pipeline → berkontribusi ke lag saat flashlight/proximity detection. |

---

## BLOCKERS FOR PUBLISH

### CRITICAL (Blocking)
1. **Ghost animations tidak pernah played** — GhostSystem setup animator + load clips tapi tidak ada `LoadAnimation():Play()`. Ghost berjalan T-pose tanpa animasi jalan. Ini adalah core visual bug.
2. **Ghost 75% transparan saat Idle** — Saat investigation phase (Idle/Roaming), ghost hampir invisible (75% transparency). QA melihat ghost di viewport server karena viewport tidak render transparency. Player tidak melihat ghost.

### HIGH PRIORITY (Blocking)
3. **Ghost stuck saat Hunt** — `isGhostNavigationLineClear()` block movement jika line-of-sight obstructed → ghost tidak bergerak saat hunt di map dengan furniture.
4. **Safe zone di luar map** — Hanya 2 safe zone hardcoded di luar Foyer, bukan di closet/hiding spot. Player tidak punya tempat aman dalam map.
5. **SpectatorSystem ghost-vision DISCONNECTED** — Ghost vision overlay tidak pernah di-trigger karena Controller tidak subscribe `SpectatorModeStarted`.
6. **ResultsCalculated orphan subscription** — MatchCompletion subscribe event yang tidak ada publisher aktif.
7. **RoomBrowser state reset** — `_roomBrowserSuppressed` locked `true` permanen jika bypass results screen.

### MEDIUM PRIORITY
8. **Ghost di rooftop** — `resolveGhostFloorY()` raycast hitting ceiling di elevated areas → ghost Y salah.
9. **Countdown audio duplikat** — Race condition antara loop tick dan server event.
10. **RoomBrowser mouse heaviness** — 50+ Destroy+Clone dalam 1 frame saat room list update.
11. **Backpack cursor konflik** — Backpack terbuka saat unlock cursor dengan `~`.
12. **Lobby transparent parts performance** — Semi-transparent overlay trigger overdraw per-frame.
13. **PlayerKilled tanpa matchId** — Payload mismatch.

### LOW PRIORITY
14. **Ghost scale bypass** — FIXED: `PasrahGhostRuntimeAssetTemplate = false` → `= true` (Service.lua:1649).
15. **IsOnCooldown semantic naming** — parameter `lastDistortionAt` menipu.
16. **NearGhostWeights undocumented** — feature tidak ada di spec.
17. **Cooldown bounds undocumented** — 5-10s tidak ada di spec.
18. **Legacy attribute references** — LEGACY_MATCH_PHASE_ATTR masih di-reference.
19. **EMF naming** — Display name masih "EMF Scanner" bukan "Detektor MEDOK".
20. **assets/generated/manual_inbox/ 69 PNGs orphan** — staging artifacts belum diupload ke Roblox.

---

## IMPLEMENTATION SCORE ESTIMATE

Berdasarkan audit:
- **80-83% implementation complete** (turun dari 83-86% karena temuan bug kritis baru)
- Core loop: Match → Investigation → Hunt → Results = WORKING
- Ghost state machine: WORKING, tapi **animations MISSING** (critical)
- Ghost visibility: BUG — 75% transparan saat Idle
- Ghost navigation: BUG — stuck saat Hunt
- Lobby systems: WORKING, tapi **performance issue** dari transparent parts
- Ghost/Evidence/Sanity/Aggression: WORKING (ghost assets validated runtime 2026-05-17)
- Economy/Shop/Rewards: WORKING
- Spectator free-camera (SpectatorModeSystem): WORKING
- Spectator ghost-vision/distortion (SpectatorSystem): DISCONNECTED — HIGH PRIORITY fix
- Ownership chain: KONSISTEN — groupId 407883270, UserId 8603977492, briankotak account
- Ghost asset IDs: BENAR untuk branch ini (second-account validated), spec yang stale
- Remaining: Ghost animation wiring, ghost visibility tuning, navigation fix, safe zone placement, SpectatorSystem wiring, UI perf, 69 orphan PNGs upload

---

*Audit generated: 2026-06-14*
*Updated: 2026-06-14 (session findings — ghost animation missing, transparency design, navigation stuck, floorY, safezone outside map, backpack conflict, countdown duplicate, roombrowser perf, lobby transparent parts)*
*Total files scanned: ~1,183 Lua files + 369 assets*
*Reference: CANONICAL_SPECIFICATIONS_v2.md, REPORTS.md, TASK_ACTIVE.md*

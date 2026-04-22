# AssetId Crawl Audit 2026-04-17

## Scope
- Crawl asset identifiers from source tree (`src/**`).
- Crawl live DataModel asset identifiers from connected Roblox Studio instance.
- Audit runtime logic state for `disabled`, `placeholder`, and `stub`.

## Source Crawl Summary (`src/**`)
- Inventory file generated: `.codex/tmp_assetid_inventory.csv`
- Category summary:
  - `AudioGeneral`: `24` unique IDs (`44` references)
  - `GhostAnimation`: `5` unique IDs (`5` references)
  - `GhostSFX`: `3` unique IDs (`3` references)
  - `GhostVisual`: `8` unique IDs (`14` references)
  - `Tools`: `3` unique IDs (`3` references)
  - `UIAudio`: `12` unique IDs (`21` references)

## Live Studio Crawl Summary (connected instance)
- Unique asset IDs currently present in DataModel:
  - `Sound`: `98`
  - `Animation`: `5`
  - `Mesh`: `221`
  - `Texture`: `13`
  - `Image`: `32`
  - `Decal`: `95`

## Ghost Asset Coverage (runtime storage)
Checked from `ReplicatedStorage.Assets.Models.Ghosts` + `ReplicatedStorage.Assets.GhostVisualProfiles`:

- `Pocong`: `model=true`, `aggressive=false`, `profile=true`
- `Kuntilanak`: `model=true`, `aggressive=true`, `profile=false`
- `Genderuwo`: `model=true`, `aggressive=false`, `profile=false`
- `Leak`: `model=true`, `aggressive=false`, `profile=false`
- `Tuyul`: `model=false`, `aggressive=false`, `profile=false`
- `Banaspati`: `model=false`, `aggressive=false`, `profile=false`
- `Jerangkong`: `model=false`, `aggressive=false`, `profile=false`
- `WeweGombel`: `model=false`, `aggressive=false`, `profile=false`
- `Palasik`: `model=false`, `aggressive=false`, `profile=false`
- `SilumanUlar`: `model=false`, `aggressive=false`, `profile=false`
- `SundelBolong`: `model=false`, `aggressive=false`, `profile=false`
- `HantuTanah`: `model=false`, `aggressive=false`, `profile=false`

## Logic State Audit

### Disabled Runtime Systems
From `src/ServerScriptService/Server/Core/SystemRegistry.lua` (`DISABLED_RUNTIME_SYSTEM_NAMES`):
- `MatchmakingSystem`
- `ServerQueueSystem`
- `EvidenceToolSystem`
- `ToolSignalProcessingSystem`
- `ToolInteractionSystem`
- `EvidenceJournalSystem`
- `GhostDeductionJournal`
- `RewardSystem`
- `ContractRewardSystem`
- `ContractConfigSystem`
- `GameConfigSystem`
- `EngineStartupValidator`
- `FinalEngineBootstrap`
- `SystemIntegrationController`
- `SystemDiagnosticsController`
- `DependencyVerificationSystem`
- `RuntimeIntegritySystem`
- `ProductionSafetySystem`
- `ErrorMonitoringSystem`
- `LatencyMonitoringSystem`
- `MemoryTrackingSystem`
- `RuntimeMetricsSystem`
- `ServerProfilerSystem`
- `DataIntegritySystem`
- `AutoRecoverySystem`
- `FailSafeSystem`
- `BackendStabilitySystem`
- `WatchdogSystem`
- `ServerHealthSystem`
- `ServerPerformanceSystem`
- `ServerPerformance`
- `OperationsQASystem`
- `PlatformSupportSystem`

### Placeholder Paths
- Ghost runtime still has explicit placeholder visual path in `src/ServerScriptService/Server/GhostSystem/Service.lua`:
  - `createVisibleGhostPlaceholder(...)`
  - model name pattern: `GhostPlaceholder_<GhostType>`
  - attribute set: `PlaceholderVisual = true`

### Stub / Not-implemented Signals
- `src/ServerScriptService/Server/ContractCompletionSystem/Main.lua`: lifecycle stub
- `src/ServerScriptService/Server/ContractObjectiveSystem/Main.lua`: lifecycle stub
- `src/ServerScriptService/Server/ContractConfigSystem/Main.lua`: lifecycle stub
- `src/ServerScriptService/Server/DailyCheckinSystem/Main.lua`: lifecycle stub
- `src/ServerScriptService/Server/EconomySystem/Rewards/MatchCompletion/Service.lua`: placeholder init logic

## Immediate Wiring Baseline
- Ghost visual inventory IDs currently hardwired in `src/shared/GameData/GhostVisualTuning.lua`:
  - `Pocong`: `rbxassetid://123151303766691`
  - `Kuntilanak`: `rbxassetid://93357688576883`
  - `KuntilanakAggressive`: `rbxassetid://93357688576883`
  - `Genderuwo`: `rbxassetid://117009327297852`
  - `Leak`: no `inventoryModelAssetId` set

## Notes
- Uploaded assets can exist in Roblox inventory but are not considered wired until they are mapped in canonical runtime config and materialized under asset/profile folders consumed by `GhostSystem`.
- This audit intentionally does not change architecture and does not patch wiring yet.

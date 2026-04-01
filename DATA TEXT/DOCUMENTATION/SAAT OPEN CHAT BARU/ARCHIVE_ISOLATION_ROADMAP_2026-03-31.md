# Archive Isolation Roadmap (2026-03-31)

## Scope

Source audited:

- `DATA TEXT/DOCUMENTATION/do not read/*`

Goal:

- isolate runtime-implemented outcomes from archive notes
- extract remaining useful backlog into one actionable roadmap
- allow archive deletion without losing implementation direction

## Deletion Risk Decision

Deleting `do not read` is low tech-debt risk for runtime.

Reasons:

- Files in `do not read` are prompt/history markdown artifacts, not runtime code.
- Active runtime does not load anything from `DATA TEXT/DOCUMENTATION/do not read`.
- Runtime source-of-truth already lives in `src/ServerScriptService/Server`, `src/client`, and `src/shared`.

## Isolated Runtime Files Already Implemented

The following runtime files match major features discussed in archive notes and are already active in current codebase:

- `src/client/Core/ClientBootstrap.lua`
- `src/client/UI/Main.lua`
- `src/client/UI/RoomBrowserController.lua`
- `src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua`
- `src/ServerScriptService/Server/LobbySystem/Main.lua`
- `src/ServerScriptService/Server/LobbySystem/Controller.lua`
- `src/ServerScriptService/Server/LobbySystem/Service.lua`
- `src/ServerScriptService/Server/LobbySystem/RoomManager.lua`
- `src/ServerScriptService/Server/MatchSystem/Main.lua`
- `src/ServerScriptService/Server/MatchSystem/Controller.lua`
- `src/ServerScriptService/Server/MatchSystem/Service.lua`
- `src/ServerScriptService/Server/MatchSystem/MatchService.lua`
- `src/ServerScriptService/Server/MatchSystem/MatchQueue.lua`

## Backlog Extracted From Archive (Not Present As-Named)

These items appear in archive prompts but are not present as named runtime files today. They should be treated as backlog, not missing blockers.

1. Queue anti-spam tap layer
- archive name: `src/client/LobbyEventTap.client.lua`
- current state: no file with that name in active tree
- recommended implementation target: `src/client/UI/RoomBrowserController.lua` and `src/client/UI/Main.lua` (already host queue flow)
- output: explicit client-side throttling and duplicate-submit guards with telemetry counters

2. Room browser debug utility
- archive name: `src/client/RoomBrowserDebugger.client.lua`
- current state: no file with that name
- recommended target: `src/client/Debug/RoomBrowserDebugger.client.lua` (new) with Studio/dev gate only
- output: state snapshot, event timeline, queue action counters

3. Performance dashboard and profiler surface
- archive names: `src/client/PerformanceDashboard.client.lua`, `src/server/PerformanceProfiler/*`, `src/server/PerformanceMonitor/Main.lua`
- current state: no exact files with those names
- existing foundations: `TelemetrySystem`, `EventBusProfiler`, `LatencyMonitoringSystem`, `MemoryTrackingSystem`
- recommended target:
- `src/ServerScriptService/Server/TelemetrySystem/*` for server metrics aggregation
- `src/client/Debug/PerformanceDashboard.client.lua` for read-only live metrics view

4. Dev validation command consolidation
- archive name: `src/server/DevTestCommands.server.lua`
- current state: no exact file
- existing nearby files:
- `src/ServerScriptService/Server/Dev/Phase4ValidationCommands.lua`
- `src/ServerScriptService/Server/Phase4ValidationCommands.lua`
- `src/ServerScriptService/Server/dev_commands.lua`
- recommended output: merge into one canonical command entrypoint and deprecate duplicates

5. Root ServerScriptService cleanup candidate
- file found: `src/ServerScriptService/Test.lua` contains only `print("SYNC TEST OK")`
- file found: `src/ServerScriptService/PlayerCore.lua` empty
- recommended output: decide keep/delete explicitly and document reason in `REPORTS.md`

## Execution Order

1. Keep runtime truth on active paths only (`src/ServerScriptService/Server`, `src/client`, `src/shared`).
2. Implement or reject backlog items 1-4 with one owner per module.
3. Resolve item 5 (`Test.lua` and `PlayerCore.lua`) to remove bootstrap noise.
4. Update `REPORTS.md` after each execution batch.
5. Treat this roadmap as replacement context for deleted archive notes.

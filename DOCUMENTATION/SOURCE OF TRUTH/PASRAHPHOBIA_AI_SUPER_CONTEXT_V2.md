FPASRAHPHOBIA - AI SUPER CONTEXT V2
VERSION: 2.1 (Runtime-Aligned)
PROJECT ROOT: C:\Projects\ROBLOX\PASRAHPHOBIA
ENGINE: Roblox (Luau)
ARCHITECTURE: Server Authoritative Modular Backend

================================================================
RUNTIME SOURCE OF TRUTH
================================================================

Active boot chain:

src/ServerScriptService/Bootstrap.server.lua
-> src/ServerScriptService/Server/ServerBootstrap.lua
-> src/ServerScriptService/Server/Core/SystemRegistry.lua

Active server runtime root:

src/ServerScriptService/Server

Deprecated or orphan boot layers have been removed from landing base.

================================================================
PROJECT SUMMARY
================================================================

PASRAHPHOBIA adalah game horror investigation multiplayer.

Core loop:

- masuk lobby
- room browser create/join/ready
- host start countdown
- teleport ke map match
- investigasi evidence
- identifikasi ghost
- hasil dan reward
- kembali ke lobby

Max players per match: 4

Supported modes:

- Solo
- Multiplayer team
- Ranked matchmaking

================================================================
SERVER ARCHITECTURE
================================================================

All runtime systems must follow lifecycle:

Init()
Start()
Shutdown()

Cross-system communication must use EventBus.

No system may directly mutate internal state of another system.

================================================================
REGISTRY BASELINE
================================================================

CoreSystems:

- EventBus
- DataPersistenceService
- ProfileSystem
- InventorySystem
- GamePhaseSystem

GameSystems:

- MatchSystem
- GhostSystem
- EvidenceSystem

GameplaySystems:

- SpectatorSystem
- LobbySystem

LiveServiceSystems:

- EconomySystem
- ShopSystem
- CosmeticSystem
- ProgressionSystem
- RankedSystem
- ContractRewardSystem
- TelemetrySystem

Explicitly preloaded non-*System dependencies include:

- HorrorDirector
- LobbySocialHub
- EvidenceDeductionEngine

================================================================
MATCH SYSTEM BASELINE
================================================================

Primary modules:

- MatchService
- MatchQueue
- MatchBuilder
- MatchLifecycle
- MatchTeleport
- MatchInstance

Queue path:

RoomBrowser action
-> LobbySystem.QueueFromRoomBrowser
-> MatchService.JoinQueue
-> MatchService.TryCreateMatchFromQueue
-> MatchService.StartMatch

================================================================
MODE, DIFFICULTY, RANK
================================================================

Mode definitions:

- Classic
- Ranked

Classic:

- auto-balanced by server
- no user-facing tier selection

Ranked:

- uses RankedSystem as single owner
- uses RankScore for banding logic

Legacy RankSystem is not the runtime owner.

================================================================
GHOST CANONICAL SET (INDONESIA, 12)
================================================================

- Banaspati
- Genderuwo
- HantuTanah
- Jerangkong
- Kuntilanak
- Leak
- Palasik
- Pocong
- SilumanUlar
- SundelBolong
- Tuyul
- WeweGombel

All ghost data consumers should read from the same canonical set.

================================================================
EVIDENCE CANONICAL VOCABULARY
================================================================

Canonical evidence IDs:

- MEDOK
- Suhu
- BukuTerkutuk
- To'un
- Suara
- Pengganggu

Active tool naming in client remains Indonesian tool labels (for UI/tool modules).
Internal deduction and ghost-evidence combinations must use canonical IDs above.

================================================================
ECONOMY AND PROGRESSION
================================================================

Wallet model:

- MM
- PP
- Robux

XP is retained for progression/level pipeline and is not removed as progression signal.

================================================================
PERSISTENCE CONTRACT
================================================================

Persistence owner:

- DataPersistenceService

Profile persistence path:

- LoadProfile
- SaveProfile

Progression and ranked updates must converge on profile patch flow.

================================================================
MAP BASELINE
================================================================

Current map IDs in runtime config:

- LobbySocialHub
- AbandonedPalace
- HauntedHouse
- EmptyBuilding
- StudioMMNineteen

================================================================
AI EXECUTION PROTOCOL
================================================================

Before editing:

1. Read this file.
2. Read REPORTS.md.
3. Read target modules only.
4. Patch runtime-active path first.

AI must not:

- reintroduce legacy server tree
- reintroduce RankSystem ownership
- mix canonical evidence IDs with legacy English evidence IDs in deduction flow
- fork ghost roster from canonical 12

================================================================
CURRENT STATUS SNAPSHOT (2026-03-31)
================================================================

Landing base cleanup executed:

- removed archived documentation noise from do not read folder
- removed orphan landing runtime files and deprecated bootstrap layer

Landing runtime now centered on active boot chain and active server root path.

Authoritative ongoing progress log:

DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md

================================================================
END OF AI SUPER CONTEXT
================================================================

PASRAHPHOBIA — AI SUPER CONTEXT V2
VERSION: 2.0
PROJECT ROOT: C:\Projects\ROBLOX\PASRAHPHOBIA
ENGINE: Roblox (Luau)
ARCHITECTURE: Server Authoritative Modular Backend

================================================================
PROJECT SUMMARY
================================================================

PASRAHPHOBIA adalah game horror investigation multiplayer
inspired by Phasmophobia.

Players investigate haunted locations, collect evidence,
identify ghost type, survive hunts, and extract.

Max Players Per Match: 4

Game supports:
- Solo
- Multiplayer team
- Ranked matchmaking

================================================================
CORE ARCHITECTURE
================================================================

Server Architecture Pattern:

SystemRegistry
    ├ CoreSystems
    ├ GameSystems
    ├ GameplaySystems
    └ LiveServiceSystems

All server systems must implement lifecycle:

Init()
Start()
Shutdown()

Systems communicate using EventBus.

NO system should directly manipulate another system's internal state.

================================================================
SYSTEM REGISTRY STRUCTURE
================================================================

CoreSystems
    EventBus
    DataPersistenceService
    ProfileSystem
    InventorySystem
    GamePhaseSystem

GameSystems
    MatchSystem
    GhostSystem
    EvidenceSystem

GameplaySystems
    SpectatorSystem
    LobbySystem

LiveServiceSystems
    EconomySystem
    ShopSystem
    CosmeticSystem
    ProgressionSystem
    RankSystem
    ContractRewardSystem

================================================================
MATCH SYSTEM ARCHITECTURE
================================================================

MatchSystem modules:

MatchService
MatchQueue
MatchBuilder
MatchLifecycle
MatchTeleport
MatchInstance

Pipeline:

Dev.Match()
↓
MatchService.JoinQueue
↓
MatchQueue.JoinQueue
↓
MatchService.TryCreateMatchFromQueue
↓
MatchBuilder.BuildMatch
↓
MatchLifecycle.StartMatch
↓
MatchTeleport.TeleportPlayers

Match creation log expected:

[MatchBuilder] Match created
[MatchLifecycle] Starting match
[MatchTeleport] Teleported players to map

================================================================
MATCH DATA STRUCTURE
================================================================

match = {
    matchId
    players
    partyIds
    mapId
    mapReference
    difficulty
    difficultyProfile
    mode
    gameMode
    ghostSeed
    phase
    state
    createdAt
}

Players are tracked with:

playersByUserId

playerState = {
    alive
    extracted
    deathReason
}

================================================================
GAME MODES
================================================================

Classic Mode
    Difficulty selectable

Ranked Mode
    Difficulty determined by MMR bands

ModeDefinitions:

Classic
Ranked

================================================================
DIFFICULTY SYSTEM
================================================================

Classic Difficulties:

Mudah
Lumayan
Angker
Uji Nyali

Parameters:

EvidenceCount
GhostAggression
HuntFrequency
EvidenceClarity
SanityDrain
RewardMultiplier

Ranked Difficulty Bands:

0-799 → Mudah
800-1399 → Lumayan
1400-2099 → Angker
2100+ → Uji Nyali

================================================================
MAP DATABASE
================================================================

Maps currently implemented:

LobbySocialHub
AbandonedPalace
HauntedHouse
EmptyBuilding
StudioMMNineteen

Map sizes:

LobbySocialHub
420 x 420

AbandonedPalace
180 x 180

HauntedHouse
140 x 140
2 floors

StudioMMNineteen
90 x 90
2 floors

EmptyBuilding
100 x 100
2 floors

================================================================
MATCH GAMEPLAY LOOP
================================================================

MatchStart
↓
Preparation Phase
↓
Ghost Spawn
↓
Evidence Spawn
↓
Investigation Phase
↓
Hunt Phase
↓
Extraction Phase
↓
Match End
↓
Rewards

================================================================
GHOST SYSTEM DESIGN
================================================================

Ghost behavior parameters:

GhostAggression
HuntFrequency
RoamingRange
EventFrequency
TargetSwitchProbability

Ghost hunts triggered by:

Low sanity
High aggression
Scripted ghost events

Ghost AI states:

Idle
Roaming
Manifestation
Hunting
Cooldown

================================================================
EVIDENCE SYSTEM
================================================================

Evidence Types:

EMF Level 5
Spirit Box
Ghost Writing
Freezing Temperatures
Fingerprints
Ghost Orb

Evidence spawn logic:

Map evidence nodes
Randomized ghost evidence pool
Evidence clarity affected by difficulty

================================================================
PLAYER DEATH SYSTEM
================================================================

Death triggers:

Ghost hunt catch
Special ghost ability
Scripted event

Death consequences:

Player becomes Spectator
Ghost evidence distortion applied
Player cannot interact with environment

================================================================
SPECTATOR SYSTEM
================================================================

Spectator receives distorted evidence.

Ghost visibility probability:

Fake ghost → 60%
Uncertain → 30%
Real ghost → 10%

SpectatorDistortionSystem handles:

Evidence hallucinations
Fake EMF readings
False ghost sightings

================================================================
ECONOMY LOOP
================================================================

Rewards based on:

EvidenceFound
GhostIdentified
PlayerSurvival
ContractCompletion
DifficultyMultiplier

Currencies:

Cash
XP
MMR

================================================================
DATA PERSISTENCE
================================================================

All player data saved via DataPersistenceService.

Save triggers:

Autosave
PlayerLeave
ServerShutdown

Saved Data:

Inventory
Cosmetics
Rank
Progression
Currency

================================================================
SECURITY RULES
================================================================

All gameplay logic server authoritative.

Client cannot:

Spawn evidence
Spawn ghost
Create match
Modify difficulty

RemoteEvents must validate:

Player
Payload structure
Allowed actions

================================================================
CODING RULES
================================================================

Use task.wait() instead of wait()

Disconnect events when objects destroyed

Always validate remote input

Prefer immutable payloads

Use Luau types for new modules

Never break existing architecture

Extend systems instead of replacing them

================================================================
AI EXECUTION PROTOCOL
================================================================

When generating code:

1 Read PASRAHPHOBIA_AI_SUPER_CONTEXT_V2
2 Read DOC_INDEX
3 Read relevant module
4 Continue from existing architecture

AI MUST NOT:

Rebuild systems
Rewrite architecture
Duplicate modules

================================================================
TOKEN OPTIMIZATION RULE
================================================================

Codex must avoid scanning entire repository.

Allowed inputs:

AI_SUPER_CONTEXT
DOC_INDEX
Relevant module file

Disallowed:

Full repository scan
Recursive folder analysis
Repeated architecture reconstruction

================================================================
CURRENT PROJECT STATUS
================================================================

Completed:

Server bootstrap
SystemRegistry
MatchQueue
MatchBuilder
MatchLifecycle
MatchTeleport
Map loading

In Development:

GhostSystem
EvidenceSystem
HuntSystem
LobbySystem

Planned:

EconomySystem
ShopSystem
Cosmetics
Progression
Contracts
RankSystem

================================================================
AI ROLE
================================================================

ChatGPT:

System architect
Debug reasoning
Design authority

Codex:

Code generator
Patch executor
Module implementer

================================================================
END OF AI SUPER CONTEXT
================================================================
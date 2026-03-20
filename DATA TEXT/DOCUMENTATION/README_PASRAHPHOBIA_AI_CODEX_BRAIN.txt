PASRAHPHOBIA — AI CODEX BRAIN
Version: 1.0

This file defines the permanent operating context for AI agents generating code for the PASRAHPHOBIA project.

All AI agents must read this file before modifying the repository.

--------------------------------------------------
PROJECT OVERVIEW
--------------------------------------------------

PASRAHPHOBIA is a cooperative multiplayer horror investigation game developed on Roblox.

Players investigate haunted locations to identify ghost types using evidence tools while surviving hunt events.

Game supports:

Solo play
Cooperative multiplayer (max 4 players)

Core gameplay loop:

Join Game
Spawn Lobby
Form Party
Select Contract
Start Match
Investigate Map
Collect Evidence
Survive Hunt
Extract
Receive Rewards
Return to Lobby

--------------------------------------------------
ARCHITECTURE PRINCIPLES
--------------------------------------------------

The game uses a server-authoritative architecture.

Server handles:

Ghost AI
Evidence validation
Match lifecycle
Sanity system
Aggression system
Economy rewards
Rank progression

Client handles:

UI
Audio
Visual effects
Input

Gameplay logic must always run on the server.

--------------------------------------------------
MODULAR SERVICE ARCHITECTURE
--------------------------------------------------

All backend systems follow the same module pattern.

Main.lua
Service.lua
Controller.lua
State.lua

Main.lua
Initializes the system and wires dependencies.

Service.lua
Contains core logic.

Controller.lua
Handles EventBus subscriptions.

State.lua
Stores runtime state.

--------------------------------------------------
SERVICE REGISTRY
--------------------------------------------------

All systems must register through ServiceRegistry.

Example:

ServiceRegistry:RegisterService("GhostSystem", GhostSystem)

Dependencies must be requested through ServiceRegistry.

Example:

local GhostSystem = ServiceRegistry:GetService("GhostSystem")

Avoid direct module requiring between systems.

--------------------------------------------------
EVENT BUS COMMUNICATION
--------------------------------------------------

All cross-system communication must use EventBus.

Example events:

MatchStarted
MatchEnded
EvidenceCollected
PlayerSanityChanged
GhostSpawned
HuntTriggered
CurrencyEarned
RewardGranted

Direct calls between systems should be avoided.

--------------------------------------------------
SERVER SYSTEM LAYERS
--------------------------------------------------

Layer 1 — Core

EventBus
ConfigLoader
ServiceRegistry
Bootstrap

Layer 2 — Persistence

DataPersistenceService
PlayerData
EconomyData
InventoryData
RankData

Layer 3 — Player Systems

ProfileSystem
ProgressionSystem
RankSystem

Layer 4 — Lobby Systems

LobbySocialHub
PartySystem
ContractSystem

Layer 5 — Match Systems

MatchQueue
MatchBuilder
MatchInstance
MatchLifecycle
TeleportService
GamePhaseSystem

Layer 6 — Gameplay Systems

GhostSystem
EvidenceSystem
SanitySystem
AggressionSystem
InvestigationSystem

Layer 7 — Advanced Gameplay

HorrorDirector
GhostModifierSystem
MapInteractionSystem
MapEventSystem

--------------------------------------------------
MATCH FLOW
--------------------------------------------------

Lobby
Preparation
Investigation
Hunt
Extraction
Results
Completed

GamePhaseSystem controls phase transitions.

--------------------------------------------------
GHOST SYSTEM
--------------------------------------------------

Ghost AI runs using a state machine.

States:

Idle
Roaming
Interaction
Manifestation
Hunt

Ghost aggression range:

0 – 100

Hunt triggered when:

Aggression > threshold
AND
Average player sanity < threshold

--------------------------------------------------
EVIDENCE SYSTEM
--------------------------------------------------

Evidence types:

Bola Arwah
Buku Terkutuk
Gerakan Gaib
Jejak Energi
Kotak Arwah
Suhu Membeku

Evidence must be validated by the server.

Evidence discovered by one player is shared with the team.

--------------------------------------------------
SANITY SYSTEM
--------------------------------------------------

Player sanity range:

0 – 100

Sanity decreases from:

Darkness
Ghost proximity
Paranormal events
Hunt events

Low sanity increases ghost aggression.

--------------------------------------------------
AGGRESSION SYSTEM
--------------------------------------------------

Ghost aggression range:

0 – 100

Aggression increases when:

Players stay near ghost room
Player sanity is low
Paranormal events occur
Time passes during investigation

High aggression increases hunt probability.

--------------------------------------------------
HORROR DIRECTOR
--------------------------------------------------

HorrorDirector manages pacing of paranormal events.

If gameplay becomes too quiet:

Increase paranormal events.

If gameplay becomes too intense:

Reduce event frequency.

--------------------------------------------------
ECONOMY SYSTEM
--------------------------------------------------

Reward pipeline:

MatchSystem
→ MatchEnded Event
→ RewardSystem
→ EconomySystem
→ ProgressionSystem
→ RankSystem

Economy rewards sources:

Match completion
Evidence discovery
Daily missions
RoyalPass
Daily check-in

--------------------------------------------------
INVENTORY SYSTEM
--------------------------------------------------

InventorySystem stores:

playerItems
cosmeticOwnership
equipmentSlots
unlockedItems

Inventory integrates with:

EconomySystem
ShopSystem
CosmeticSystem
DataPersistenceService

--------------------------------------------------
RANK SYSTEM
--------------------------------------------------

Rank tiers:

Bayi
Balita
Anak-Anak
Remaja
Dewasa
Profesional
Detektive
Sang Ahli

Rank progression uses star system.

Win → +1 star
Loss → -1 star

Final rank "Sang Ahli" uses victory counter.

--------------------------------------------------
AI DEVELOPMENT RULES
--------------------------------------------------

AI agents must follow these rules:

1. Do not overwrite existing files unless required.
2. Follow Main / Service / Controller / State structure.
3. Use EventBus for cross-system communication.
4. Use ServiceRegistry for dependencies.
5. Avoid circular dependencies.
6. Do not modify unrelated systems.
7. Prefer adding new modules instead of editing stable systems.

--------------------------------------------------
REPOSITORY STRUCTURE
--------------------------------------------------

src/server

Backend gameplay systems.

src/shared/DataTypes

Static configuration.

src/client

Client systems.

src/ReplicatedStorage

Maps
Audio
RemoteEvents

--------------------------------------------------
AI OUTPUT RULES
--------------------------------------------------

When generating code:

Use Roblox Lua style.

Avoid global variables.

Return module tables.

Follow lifecycle functions:

Create
Init
Start
Stop

Ensure compatibility with EventBus and ServiceRegistry.

--------------------------------------------------
END OF AI CONTEXT
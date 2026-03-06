# PASRAHPHOBIA — CODE INDEX

This document provides a quick reference for AI agents to locate important systems inside the repository.

AI agents should consult this file before scanning the repository.

--------------------------------------------------

CORE SERVER SYSTEMS

src/server/MatchSystem
Match lifecycle and server orchestration.

src/server/GhostSystem
Ghost AI behavior and room logic.

src/server/EvidenceSystem
Evidence spawning and validation.

src/server/SpectatorSystem
Dead player spectator mode.

src/server/HorrorDirector
Game pacing and tension system.

src/server/SanitySystem
Player sanity tracking.

src/server/AggressionSystem
Ghost aggression scaling.

--------------------------------------------------

META SYSTEMS

src/server/EconomySystem
Handles currency rewards and economy events.

src/server/InventorySystem
Stores player items and cosmetic ownership.

src/server/ProfileSystem
Stores player progression data.

src/server/DataPersistenceService
Handles Roblox DataStore integration.

src/server/LobbySocialHub
Handles lobby presence and player appearance.

--------------------------------------------------

MATCH FLOW

MatchSystem
?
GamePhaseSystem
?
GhostSystem / EvidenceSystem
?
HorrorDirector
?
MatchEnded event
?
EconomySystem
?
InventorySystem
?
DataPersistenceService

--------------------------------------------------

DATA TYPES

src/shared/DataTypes

Important categories:

GhostTypes
EvidenceTypes
RankTiers
ContractTypes
MapEvents

--------------------------------------------------

CLIENT SYSTEMS

src/client/UI
User interface logic.

src/client/GhostRenderer
Client-side ghost rendering.

src/client/SoundSystem
Audio and ambient horror sounds.

src/client/EvidenceTools
Evidence investigation tools.

--------------------------------------------------

ASSET STORAGE

src/ReplicatedStorage/Maps
Game maps.

src/ReplicatedStorage/Audio
Audio assets.

src/ReplicatedStorage/RemoteEvents
Remote events for client-server communication.

--------------------------------------------------

SYSTEM DEPENDENCIES

MatchSystem depends on:

GamePhaseSystem
TeleportService
EventBus

GhostSystem depends on:

RoomSystem
MapInteractionSystem
HorrorDirector

InventorySystem depends on:

EconomySystem
DataPersistenceService

LobbySocialHub depends on:

ProfileSystem
InventorySystem

--------------------------------------------------

AI DEVELOPMENT PRIORITY

When continuing development prioritize these systems:

ShopSystem
CosmeticSystem
RankSystem
ProgressionSystem
ContractRewardSystem

These systems integrate with:

EconomySystem
InventorySystem
ProfileSystem

--------------------------------------------------

END OF CODE INDEX

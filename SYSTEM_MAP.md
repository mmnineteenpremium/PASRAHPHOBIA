# PASRAHPHOBIA — SYSTEM MAP

This document defines the high-level architecture map of the PASRAHPHOBIA game.

AI agents must read this before modifying the repository.

--------------------------------------------------

CORE GAMEPLAY SYSTEMS

MatchSystem
Responsible for match lifecycle.

Dependencies:
EventBus
GamePhaseSystem
TeleportService

Key events:
MatchStarted
MatchEnded
ResultsCalculated


GhostSystem
Handles ghost AI behavior and room logic.

Dependencies:
RoomSystem
MapInteractionSystem
HorrorDirector

Key events:
GhostSpawned
GhostStateChanged
HuntStarted
HuntEnded


EvidenceSystem
Handles spawning and validation of ghost evidence.

Dependencies:
GhostSystem
MapInteractionSystem

Evidence types:
FreezingTemp
SpiritBox
GhostWriting
Orb
Fingerprints
EMF


SpectatorSystem
Handles dead player spectator mode.

Features:
Ghost distortion
Spectator camera
Ghost visibility filters

Key events:
PlayerDied
PlayerEnteredSpectator
SpectatorDistortionGenerated


HorrorDirector
Controls pacing and tension of the game.

Dependencies:
SanitySystem
GhostSystem
MapEventSystem

Responsibilities:
Event scheduling
Fear pacing
Environmental scares


SanitySystem
Tracks player sanity levels.

Effects:
Hallucinations
Ghost aggression scaling


AggressionSystem
Controls ghost aggression levels.

Inputs:
Player sanity
Noise level
Time in match


--------------------------------------------------

META SYSTEMS

EconomySystem
Handles all currency and reward logic.

Reward sources:
MatchCompletion
DailyMissions
DailyCheckin
RoyalPass

Events:
CurrencyEarned
RewardGranted


InventorySystem
Handles player owned items and cosmetics.

Stored data:
playerItems
cosmeticOwnership
equipmentSlots
unlockedItems


DataPersistenceService
Handles saving/loading player data.

Functions:
LoadInventory
SaveInventory
LoadProfile
SaveProfile

Uses Roblox DataStoreService.


ProfileSystem
Handles player progression data.

Stored data:
playerLevel
xp
rank


LobbySocialHub
Handles lobby interactions and player presence.

Responsibilities:
Party system
Social interactions
Player appearance display

Function:
ApplyCosmetic()


--------------------------------------------------

PLAYER PROGRESSION FLOW

Player joins
?
ProfileSystem loads profile
?
InventorySystem loads inventory
?
MatchSystem starts game
?
MatchSystem publishes MatchEnded
?
EconomySystem grants rewards
?
InventorySystem updates ownership
?
DataPersistenceService saves data


--------------------------------------------------

DIRECTORY STRUCTURE

src/server

Core systems:
MatchSystem
GhostSystem
EvidenceSystem
SpectatorSystem
HorrorDirector
SanitySystem
AggressionSystem

Meta systems:
EconomySystem
InventorySystem
ProfileSystem
DataPersistenceService
LobbySocialHub


src/shared/DataTypes

Contains:
GhostTypes
EvidenceTypes
ContractTypes
RankTiers
MapEvents


src/client

Contains:
UI
GhostRenderer
SoundSystem
EvidenceTools


src/ReplicatedStorage

Contains:
Maps
Audio
RemoteEvents


--------------------------------------------------

CURRENT DEVELOPMENT STATE

Implemented systems:

MatchSystem
GhostSystem
EvidenceSystem
SpectatorSystem
HorrorDirector
SanitySystem
AggressionSystem
EconomySystem
InventorySystem
DataPersistenceService
ProfileSystem
LobbySocialHub

Remaining systems typically include:

ShopSystem
CosmeticSystem
RankSystem
ProgressionSystem
ContractRewardSystem


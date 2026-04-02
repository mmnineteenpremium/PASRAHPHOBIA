# PASRAHPHOBIA — SYSTEM FACTORY MAP

This document defines how server systems are instantiated and started.

AI agents must follow this map when registering new systems.

--------------------------------------------------

SERVER BOOTSTRAP ORDER

All systems are created and started by the server bootstrap loader.

Example lifecycle:

Create System
?
Init()
?
Start()

--------------------------------------------------

SYSTEM REGISTRATION

Systems must be registered inside the server bootstrap factory.

Expected location:

src/server/Core/Bootstrap/SystemLoader
or
src/server/Core/Bootstrap/SystemRegistry

Each system should be instantiated using its Main module.

Example:

local MatchSystem = require(src.server.MatchSystem.Main)
local GhostSystem = require(src.server.GhostSystem.Main)

--------------------------------------------------

EXPECTED SYSTEM START ORDER

Core gameplay:

MatchSystem
GhostSystem
EvidenceSystem
SpectatorSystem
HorrorDirector
SanitySystem
AggressionSystem

Meta systems:

ProfileSystem
InventorySystem
EconomySystem
ProgressionSystem
RankSystem

Social systems:

LobbySocialHub
CosmeticSystem

Persistence layer:

DataPersistenceService

--------------------------------------------------

DEPENDENCY NOTES

MatchSystem
must start before reward systems.

Reward pipeline:

MatchSystem
?
RewardSystem
?
EconomySystem
?
ProgressionSystem
?
RankSystem

--------------------------------------------------

PLAYER DATA FLOW

Player join

?

DataPersistenceService loads data

?
ProfileSystem initializes player

?
InventorySystem loads inventory

?
LobbySocialHub applies cosmetics

--------------------------------------------------

AI RULE

When implementing a new system:

1. Create folder inside src/server
2. Follow module pattern
3. Register system in bootstrap loader
4. Start system in correct dependency order

--------------------------------------------------

END OF SYSTEM FACTORY MAP

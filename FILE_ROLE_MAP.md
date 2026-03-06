# PASRAHPHOBIA — FILE ROLE MAP

This document explains the purpose of important files and folders.

AI agents must consult this before modifying the repository.

--------------------------------------------------

SERVER SYSTEM ROOT

src/server

All backend gameplay systems are located here.

Each system must follow:

Main.lua
Service.lua
Controller.lua
State.lua

--------------------------------------------------

CORE GAMEPLAY SYSTEMS

src/server/MatchSystem
Handles match lifecycle.

src/server/GhostSystem
Handles ghost AI behavior.

src/server/EvidenceSystem
Handles evidence logic.

src/server/SpectatorSystem
Handles dead player camera.

src/server/HorrorDirector
Controls horror pacing.

src/server/SanitySystem
Tracks sanity mechanics.

src/server/AggressionSystem
Controls ghost aggression.

--------------------------------------------------

PLAYER SYSTEMS

src/server/ProfileSystem
Handles player level and XP.

src/server/ProgressionSystem
Grants XP from rewards.

src/server/RankSystem
Tracks rank tiers.

--------------------------------------------------

ECONOMY SYSTEMS

src/server/EconomySystem
Handles currency.

src/server/RewardSystem
Converts gameplay events into rewards.

src/server/ShopSystem
Handles purchases.

src/server/InventorySystem
Stores items and cosmetics.

--------------------------------------------------

SOCIAL SYSTEMS

src/server/LobbySocialHub
Handles lobby player interaction.

src/server/CosmeticSystem
Handles cosmetic equipment.

--------------------------------------------------

PERSISTENCE

src/server/DataPersistenceService

Handles Roblox DataStoreService.

Responsible for:

LoadInventory
SaveInventory
LoadProfile
SaveProfile

--------------------------------------------------

SHARED DATA TYPES

src/shared/DataTypes

Contains static configuration data.

Examples:

GhostTypes
EvidenceTypes
RankTiers
ContractTypes

--------------------------------------------------

CLIENT SYSTEMS

src/client

Contains UI and rendering logic.

Server systems must not depend on client code.

--------------------------------------------------

ASSETS

src/ReplicatedStorage

Contains:

Maps
Audio
RemoteEvents

--------------------------------------------------

AI DEVELOPMENT RULES

Before editing code:

1. Identify the correct system.
2. Modify the system Service.lua when adding logic.
3. Modify Controller.lua for EventBus wiring.
4. Avoid editing Main.lua unless necessary.

--------------------------------------------------

END OF FILE ROLE MAP

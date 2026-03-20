# PASRAHPHOBIA � AGENTS GUIDE

This file defines the rules and architecture guidelines for AI agents (Codex, Aider, etc.) working on the PASRAHPHOBIA project.

The goal is to maintain consistent architecture and prevent incorrect edits.

--------------------------------------------------

PROJECT OVERVIEW

PASRAHPHOBIA is a multiplayer horror investigation game built in Roblox.

Core gameplay systems:

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
DataPersistenceService
ProfileSystem
LobbySocialHub

--------------------------------------------------

SERVER ARCHITECTURE

All server systems follow the same module structure.

Main.lua
Service.lua
Controller.lua
State.lua

Example structure:

src/server/MatchSystem

MatchSystem
 + Main.lua
 + Service.lua
 + Controller.lua
 + State.lua

Module responsibilities:

Main.lua
Initializes system and wires dependencies.

Service.lua
Contains system logic.

Controller.lua
Handles EventBus subscriptions and external triggers.

State.lua
Stores runtime state.

--------------------------------------------------

EVENT BUS RULES

All cross-system communication must go through EventBus.

Example events:

MatchEnded
ResultsCalculated
CurrencyEarned
RewardGranted
MissionCompleted
DailyRewardClaimed

Avoid direct calls between systems unless required.

--------------------------------------------------

DATA PERSISTENCE

All player data must go through:

src/server/DataPersistenceService

Supported operations:

LoadInventory
SaveInventory
LoadProfile
SaveProfile

Autosave should occur periodically and when players leave.

--------------------------------------------------

ECONOMY FLOW

Reward pipeline:

MatchSystem
?
EventBus (MatchEnded)
?
EconomySystem
?
Reward modules
?
CurrencyEarned / RewardGranted

Reward modules include:

MatchCompletion
DailyMissions
DailyCheckin
RoyalPass

--------------------------------------------------

INVENTORY FLOW

InventorySystem manages:

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

COSMETIC SYSTEM

Equip flow:

InventorySystem
?
CosmeticSystem
?
LobbySocialHub.ApplyCosmetic()

Cosmetics must be owned before equipping.

--------------------------------------------------

SHOP SYSTEM

Responsibilities:

Cosmetic catalog
Purchase validation
Currency deduction
Grant cosmetic to InventorySystem

Shop must use EconomySystem for currency transactions.

--------------------------------------------------

DIRECTORY STRUCTURE

Server code:

src/server

Shared definitions:

src/shared/DataTypes

Client systems:

src/client

Maps and assets:

src/ReplicatedStorage

--------------------------------------------------

AI AGENT RULES

Agents must follow these rules:

1. Do not overwrite existing files unless required.
2. Follow the architecture pattern.
3. Prefer creating new modules instead of modifying stable systems.
4. Avoid editing unrelated systems.
5. Use EventBus for cross-system communication.
6. Always Update Progress after execute to reports.md


--------------------------------------------------

CURRENT DEVELOPMENT STAGE

Backend systems mostly implemented.

Remaining systems include:

ShopSystem
CosmeticSystem
RankSystem
ProgressionSystem
ContractRewardSystem

Agents should prioritize implementing missing systems rather than refactoring existing ones.


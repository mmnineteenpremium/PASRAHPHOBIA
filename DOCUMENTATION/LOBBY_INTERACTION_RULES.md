# PASRAHPHOBIA — LOBBY INTERACTION RULES

This document defines how lobby objects interact with backend systems.

All AI code generation must follow these interaction rules.

These interactions connect environment objects to gameplay systems.

---

# MATCHMAKING INTERACTION

Object:

MatchQueuePlatform
QueueTrigger

Connected system:

MatchmakingSystem

Interaction:

When a player enters QueueTrigger:

EventBus:Publish("QueueJoined", player)

When a player leaves:

EventBus:Publish("QueueLeft", player)

Queue UI updates based on:

QueueUpdated event.

---

# PARTY SYSTEM INTERACTION

Objects:

PartyPlatform
PartyBoard
PartyTerminal

Connected system:

PartySystem

Interactions:

Create party
Invite player
Leave party
View party members

Events used:

PartyCreated
PartyJoined
PartyLeft
PartyUpdated

---

# SHOP INTERACTION

Objects:

ShopNPC
ShopCounter
Interact_Shop

Connected system:

EconomySystem

Actions:

Open shop UI
Purchase equipment
Purchase cosmetics
Purchase consumables

Events:

ShopOpened
ItemPurchased
CurrencyUpdated

---

# EQUIPMENT PURCHASE FLOW

When a player purchases equipment:

1. EconomySystem verifies currency.
2. InventorySystem adds item.
3. UI updates equipment slots.

Events:

ItemPurchased
InventoryUpdated

---

# EVIDENCE TRAINING INTERACTION

Objects:

Table_Tools_1
Table_Tools_2
Table_Tools_3
Table_Tools_4
Table_Tools_5
Table_Tools_6

Connected system:

EvidenceTrainingSystem

Purpose:

Allow players to test equipment before starting investigations.

Interaction:

Player activates equipment test.

Event:

EvidenceTestStarted

---

# MATCH START FLOW

When players confirm a contract:

1. MatchSystem prepares investigation.
2. TeleportService sends players to map.
3. MatchStarted event is published.

Flow:

Lobby → Matchmaking → Investigation Map

---

# NPC INTERACTION

Objects:

NPC_A
NPC_B
NPC_C

Connected system:

DialogueSystem

Possible interactions:

Tips
Lore
Tutorial
Event messages

Events:

DialogueOpened
DialogueClosed

---

# DAILY REWARD INTERACTION

Object:

DailyRewardTerminal

Connected system:

DailyRewardSystem

Interaction:

Player claims reward once per day.

Events:

RewardClaimed
RewardUnavailable

---

# COSMETIC SHOP INTERACTION

Objects:

ShopNPC
CosmeticDisplay

Connected system:

CosmeticsSystem

Actions:

Preview cosmetic
Purchase cosmetic
Equip cosmetic

Events:

CosmeticPurchased
CosmeticEquipped

---

# EVENT BUS RULE

All lobby interactions must communicate through EventBus.

Example:

EventBus:Publish("QueueJoined", player)

Direct system calls are not allowed.

---

# SAFETY RULES

Lobby interaction scripts must:

Never modify backend systems directly.

Always use EventBus communication.

Respect ServiceRegistry dependencies.

---

# END OF DOCUMENT

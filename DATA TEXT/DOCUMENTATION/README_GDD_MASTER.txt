# MASTER DOCUMENTATION — PASRAHPHOBIA
Version: 1.0

PASRAHPHOBIA adalah game horror investigation multiplayer di Roblox.

Game ini menggunakan **server authoritative modular architecture**.

Semua gameplay logic berjalan di server.

Client hanya menangani:

UI
Audio
Visual
Player Input

---

# 0. CONTEXT BRIEF

PASRAHPHOBIA adalah game investigasi horor kooperatif.

Pemain menyelidiki lokasi berhantu untuk mengidentifikasi jenis ghost menggunakan evidence tools.

Game mendukung:

Solo play
Multiplayer (max 4 player)

Core loop gameplay:

Join Game
↓
Spawn Lobby
↓
Form Party
↓
Select Contract
↓
Start Match
↓
Investigate Location
↓
Collect Evidence
↓
Survive Hunt
↓
Extract
↓
Receive Rewards
↓
Return to Lobby

---

# 1. GLOSSARY

Ghost Room  
Ruangan utama tempat ghost sering muncul.

Evidence  
Bukti paranormal untuk identifikasi ghost.

Hunt  
Fase ketika ghost mengejar player.

Sanity  
Nilai mental player (0-100).

Aggression  
Nilai kemarahan ghost (0-100).

MatchInstance  
Instance investigasi pada server.

HorrorDirector  
System yang mengontrol pacing horror.

EventBus  
Communication system antar service.

ServiceRegistry  
Global registry untuk semua system server.

---

# 2. GLOBAL ARCHITECTURE

Server menggunakan **modular service architecture**.

Bootstrap
↓
ServiceRegistry
↓
EventBus
↓
Gameplay Systems
↓
Match Systems
↓
Lobby Systems

Semua system server berada di:

src/server

---

# 3. SERVER BOOTSTRAP ARCHITECTURE

Server startup sequence:

Load Config
↓
Initialize EventBus
↓
Register Services
↓
Start Services

Bootstrap adalah entry point server.

---

# 4. SYSTEM FACTORY MAP

Server bootstrap membuat sistem dengan lifecycle:

Create
Init
Start

System di-load dari:

src/server/Core/Bootstrap/SystemLoader

Contoh:

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

Persistence:

DataPersistenceService

---

# 5. SERVICE DEPENDENCY MATRIX

Tier 1 — Core

EventBus
ConfigLoader
ServiceRegistry

Tier 2 — Persistence

DataPersistenceService
PlayerData
EconomyData
InventoryData
RankData

Tier 3 — Player

ProfileSystem
ProgressionSystem
RankSystem

Tier 4 — Lobby

LobbySocialHub
PartySystem
ContractSystem

Tier 5 — Match

MatchQueue
MatchBuilder
MatchInstance
MatchLifecycle
TeleportService
GamePhaseSystem

Tier 6 — Gameplay

GhostSystem
EvidenceSystem
SanitySystem
AggressionSystem
InvestigationSystem

Tier 7 — Advanced

HorrorDirector
GhostModifierSystem
MapInteractionSystem
MapEventSystem

---

# 6. REPOSITORY STRUCTURE

## Server

src/server

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

---

# 7. CODE INDEX

Core Systems

src/server/MatchSystem  
src/server/GhostSystem  
src/server/EvidenceSystem  
src/server/SpectatorSystem  
src/server/HorrorDirector  
src/server/SanitySystem  
src/server/AggressionSystem  

Meta Systems

src/server/EconomySystem  
src/server/InventorySystem  
src/server/ProfileSystem  
src/server/DataPersistenceService  
src/server/LobbySocialHub  

---

# 8. FILE ROLE MAP

Setiap system menggunakan struktur:

Main.lua  
Service.lua  
Controller.lua  
State.lua  

Main.lua  
Initialize system

Service.lua  
Core logic

Controller.lua  
EventBus handlers

State.lua  
Runtime state

---

# 9. MATCH SYSTEM

MatchSystem mengontrol lifecycle match.

Modules:

MatchQueue
MatchBuilder
MatchInstance
MatchLifecycle
TeleportService

Match flow:

Lobby
↓
Matchmaking
↓
Match Created
↓
Players Teleported
↓
Investigation

---

# 10. MATCH STATE MACHINE

Waiting
↓
Preparation
↓
Investigation
↓
Hunt
↓
Extraction
↓
Results
↓
Completed

---

# 11. GHOST SYSTEM

Ghost AI menggunakan state machine.

States:

Idle
Roaming
Interaction
Manifestation
Hunt

Ghost aggression range:

0-100

Hunt trigger:

Aggression > threshold  
AND  
AverageSanity < threshold

---

# 12. GHOST AI BEHAVIOR MATRIX

Ghost behavior parameters:

Aggression Level
Roaming Frequency
Interaction Frequency
Hunt Trigger Sensitivity
Evidence Bias
Fear Presence

Contoh:

Ghost: Pocong

Aggression: Low
Roaming: Low
Interaction: Medium

---

# 13. EVIDENCE SYSTEM

Evidence types:

Bola Arwah
Buku Terkutuk
Gerakan Gaib
Jejak Energi
Kotak Arwah
Suhu Membeku

Evidence harus diverifikasi server.

Evidence yang ditemukan satu player dibagikan ke tim.

---

# 14. INVESTIGATION SYSTEM

InvestigationSystem menyimpan evidence yang ditemukan.

Journal menggunakan deduction algorithm:

Load Ghost List
↓
Filter by Evidence
↓
Remove invalid ghosts
↓
Remaining ghosts = candidates

---

# 15. SANITY SYSTEM

Range:

0-100

Sanity berkurang karena:

Darkness
Ghost proximity
Paranormal events
Hunt

Sanity rendah meningkatkan aggression.

---

# 16. AGGRESSION SYSTEM

Range:

0-100

Aggression meningkat karena:

Player dekat ghost room
Low sanity
Paranormal events
Time in investigation

Aggression tinggi meningkatkan hunt probability.

---

# 17. HORROR DIRECTOR

HorrorDirector mengontrol pacing horror.

Jika game terlalu tenang:

Increase events

Jika terlalu intens:

Reduce event frequency

Contoh events:

Door slam
Light flicker
Ghost manifestation
Audio disturbance

---

# 18. SPECTATOR SYSTEM

Ketika player mati:

Player → Spectator Mode

SpectatorDistortionSystem:

Fake Ghost → 60%
Uncertain Event → 30%
Real Ghost → 10%

Spectator tidak bisa memberi hint pasti.

---

# 19. ECONOMY SYSTEM

Reward pipeline:

MatchSystem
↓
EventBus MatchEnded
↓
RewardSystem
↓
EconomySystem
↓
ProgressionSystem
↓
RankSystem

Reward berasal dari:

Match completion
Evidence discovery
Daily missions
RoyalPass
Daily check-in

---

# 20. INVENTORY SYSTEM

Inventory menyimpan:

playerItems
cosmeticOwnership
equipmentSlots
unlockedItems

Inventory terintegrasi dengan:

EconomySystem
ShopSystem
CosmeticSystem
DataPersistenceService

---

# 21. RANK SYSTEM

Rank tiers:

Bayi
Balita
Anak-Anak
Remaja
Dewasa
Profesional
Detektive
Sang Ahli

Rank progression menggunakan star system.

Win → +1 star  
Loss → −1 star  

Promotion terjadi ketika star requirement terpenuhi.

Rank terakhir:

Sang Ahli

Menggunakan victory counter.

---

# 22. LOBBY SYSTEM

LobbySocialHub mengontrol interaksi pemain di lobby.

Features:

Party system
Profile inspection
Cosmetic display
Contract selection

Lobby juga berisi:

Shop
Training
Leaderboard
Daily reward

---

# 23. EVENT BUS

Semua system berkomunikasi menggunakan EventBus.

Contoh events:

MatchStarted
MatchEnded
EvidenceCollected
PlayerSanityChanged
GhostSpawned
HuntTriggered
PlayerDied
CurrencyEarned
RewardGranted

Direct system calls harus dihindari.

---

# 24. AI DEVELOPMENT RULES

AI agents harus mengikuti aturan berikut:

1. Jangan overwrite file stabil.
2. Gunakan EventBus untuk komunikasi.
3. Gunakan ServiceRegistry untuk dependency.
4. Ikuti struktur Main / Service / Controller / State.
5. Jangan membuat system baru di luar blueprint.

---

# 25. FINAL SYSTEM OBJECTIVE

Tujuan arsitektur PASRAHPHOBIA:

Modular
Scalable
AI-friendly
Replayable
Psychologically intense

Game harus mampu berkembang dengan:

New ghosts
New maps
New modifiers
New gameplay systems
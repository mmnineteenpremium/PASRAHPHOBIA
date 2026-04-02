# PASRAHPHOBIA — MAP GENERATION RULES

This document defines the spatial rules and generation constraints for all maps in the PASRAHPHOBIA project.

AI systems such as Codex must follow these rules when generating any environment.

---

# 1. GLOBAL SCALE

All environments must follow Roblox character scale.

Average player height ≈ 5 studs.

Recommended building heights:

Small rooms: 12 studs
Standard rooms: 16 studs
Lobby buildings: 18–22 studs

---

# 2. LOBBY HUB SIZE

The lobby hub must be large enough to support multiple systems.

Lobby size:

MainFloor = 420 x 420 studs

Lobby ceiling height:

28 studs

This space must support:

Matchmaking
Party system
Shop building
Evidence test building
Flex event zone
NPC social garden

---

# 3. BUILDING SIZES

Buildings must follow these standard sizes.

ShopBuilding

Size: 60 x 60
Height: 20

EvidenceTestBuilding

Size: 70 x 70
Height: 22

FlexZoneBuilding

Size: 60 x 60
Height: 18

Future buildings must remain within 40–80 studs width.

---

# 4. SOCIAL GARDEN

Lobby must contain a social zone.

Garden size:

100 x 100 studs

Objects allowed:

Trees
Benches
NPC interaction spots

This zone supports player socialization.

---

# 5. PATH SYSTEM

Paths connect all buildings to the lobby hub.

Path width:

12 studs

Paths must connect:

MainHub → ShopBuilding
MainHub → EvidenceTestBuilding
MainHub → FlexZone
MainHub → PartyZone
MainHub → SocialGarden

---

# 6. NAVIGATION NODES

Navigation nodes help AI systems and future NPCs.

Minimum nodes per lobby:

6

Example names:

NavNode_A
NavNode_B
NavNode_C
NavNode_D
NavNode_E
NavNode_F

Nodes must be distributed evenly.

---

# 7. INTERACTION POINTS

Interactive points allow gameplay systems to connect with the map.

Examples:

Interact_Shop
Interact_MatchQueue
Interact_Party
Interact_Evidence
Interact_Flex

These are used by UI systems.

---

# 8. EVIDENCE TEST AREA

Evidence training area must contain tables for all tools.

Evidence tools supported

Each tool must have a dedicated test table.

---

# 9. GHOST SPAWN TEST ZONES

The lobby includes testing zones for ghost debugging.

Zones:

GhostSpawn_A
GhostSpawn_B
GhostSpawn_C

These are used for debugging AI.

---

# 10. LIGHTING RULES

Use PointLight for indoor environments.

Brightness:

6

Range:

40

Recommended lighting count:

Lobby: 6 lights
Shop: 2 lights
Evidence building: 3 lights
Garden: 3 lights

---

# 11. MATERIALS

Allowed materials:

Concrete
Metal
Wood

Color palette:

Concrete = RGB(120,120,120)
Wood = RGB(120,80,40)
Metal = RGB(80,80,80)

These colors maintain a neutral horror atmosphere.

---

# 12. SAFETY RULES

Map generation scripts must:

Create objects only if they do not exist.

Avoid duplicating objects.

Respect folder structure.

Do not overwrite existing map assets.

---

# END OF DOCUMENT

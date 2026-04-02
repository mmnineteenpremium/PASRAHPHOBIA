PASRAHPHOBIA — LOBBY MAP LAYOUT BLUEPRINT

This document defines the spatial layout of the PASRAHPHOBIA lobby hub.

All AI systems generating environments must follow this blueprint.

GLOBAL ORIENTATION

North = Evidence Test Building
East = Shop Building
West = Party Zone
South = Social Garden

Center = Main Lobby Hub

LOBBY DIMENSIONS

MainFloor

Size: 420 x 420 studs

Height clearance:

Lobby ceiling = 28 studs

CENTER HUB

The center of the lobby contains the main hub.

Objects:

SpawnPoint
MatchQueuePlatform
QueueTrigger
QueueSign

This area is used for matchmaking.

EAST SIDE — SHOP BUILDING

Location:

East side of lobby.

Distance from center:

≈ 120 studs

Building size:

60 x 60 studs

Purpose:

Equipment purchasing
Inventory management
Cosmetics purchases

Interior objects:

ShopCounter
DisplayTables
EquipmentRacks
ShopNPC

NORTH SIDE — EVIDENCE TEST BUILDING

Location:

North side of lobby.

Distance from center:

≈ 120 studs

Building size:

70 x 70 studs

Purpose:

Training area for evidence tools.

Evidence stations:

EMF
UV Light
Thermometer
Spirit Box
Ghost Writing
Video Camera

Each evidence tool has a dedicated test table.

WEST SIDE — PARTY ZONE

Location:

West side of lobby.

Distance from center:

≈ 110 studs

Objects:

PartyPlatform
PartyBoard
PartyTerminal

Purpose:

Create team
Invite friends
Prepare investigation groups.

SOUTH SIDE — SOCIAL GARDEN

Location:

South side of lobby.

Distance from center:

≈ 120 studs

Size:

100 x 100 studs

Objects:

Trees
Benches
NPC interaction spots

Purpose:

Player social interaction
Future NPC dialogue
Event decorations.

FLEX ZONE BUILDING

Location:

South-East quadrant.

Purpose:

Future systems.

Examples:

Seasonal events
Leaderboards
Developer announcements

Size:

60 x 60 studs

PATH NETWORK

Paths connect all zones.

Path width:

12 studs

Paths:

Path_ToShop
Path_ToEvidence
Path_ToParty
Path_ToGarden
Path_ToFlex

All paths originate from the center hub.

NAVIGATION NODES

Navigation nodes support AI and NPC movement.

Nodes required:

NavNode_A
NavNode_B
NavNode_C
NavNode_D
NavNode_E
NavNode_F

Nodes must be evenly distributed.

GHOST SPAWN TEST AREA

Debug zones for ghost behavior.

Zones:

GhostSpawn_A
GhostSpawn_B
GhostSpawn_C

Used for testing ghost AI.

INTERACTION POINTS

Interactive nodes for gameplay systems.

Examples:

Interact_Shop
Interact_Party
Interact_Evidence
Interact_MatchQueue
Interact_Flex

Used by UI systems.

LIGHTING LAYOUT

Lobby lights:

6 lights around center hub.

Shop building:

2 lights interior.

Evidence building:

3 lights interior.

Social garden:

3 lights for ambient lighting.

EXPANSION SPACE

Unused space must remain available for future systems.

Examples:

New maps
Event portals
Seasonal decorations
Additional NPCs

END OF DOCUMENT
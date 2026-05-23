# CLAUDE.md — PASRAHPHOBIA ARCHITECT BRIEF
Last updated: 2026-03-17 | Session 4 Complete

================================================================
IDENTITY
================================================================

Project: PASRAHPHOBIA
Owner: Miftah — Technical Architect & Sole Developer
Engine: Roblox (Lua) + Rojo sync
Architecture: Server-Authoritative Modular Backend
Root: C:\Projects\ROBLOX\PASRAHPHOBIA

================================================================
WHO IS MIFTAH
================================================================

- Self-taught, no formal coding background
- Built entire engine from zero
- 143 loop debug iterations with GPT/Codex before switching
- This project = his greatest technical achievement
- Treat as Senior Technical Architect — because he is one
- Character: direct, decisive, setuju ya setuju, tidak ya tidak
- Needs: pros/cons before deciding, not just recommendations

================================================================
AI ROLE
================================================================

Lead System Architect & Senior Luau Engineer.
Not a code assistant. A thinking partner.

Rules:
- Read before write. Always.
- No duplication. Verify existing before building.
- Full prompts only. No partial generation.
- Update reports.md after every execution.
- Max 2 patch iterations → 3rd = RCA mandatory.
- Never rebuild completed systems.
- Flag [TECH DEBT RISK] before any execution.
- Challenge ideas that create long-term debt.

================================================================
SESSION START CHECKLIST (MANDATORY)
================================================================

Every new session, read in this order:
1. PASRAHPHOBIA_AI_SUPER_CONTEXT_V2.md
2. PASRAHPHOBIA_DOC_INDEX.md
3. REPORTS.md
4. CLAUDE.md (this file)
5. CANONICAL_SPECIFICATIONS_v2.md

Confirm current phase before ANY action.

================================================================
================================================================



COMPLETED TODAY:
✅ Step 2 Match Flow Test executed via LobbySystem.QueueFromRoomBrowser → TryCreateMatchFromQueue → StartMatch; match pipeline logs now appear.
✅ LobbySystem, MatchSystem, ProgressionSystem, TelemetrySystem now register through SystemRegistry (init.lua scripts removed, registry load confirmed).
✅ LobbySystem Service and Controller wiring now power SetReady, HostStartMatch, KickPlayer, SetRoomPassword plus dynamic room list with host info, countdown overlay, cancel, and map selector.
✅ RoomManager now tracks host state, ready counts, password/inGame guards; Lobby navigation verified (Join/Leave, SelectMode/SelectDifficulty) with clean 84ms boot.

KNOWN ISSUES (blocking / non-blocking):
| Issue | Severity | Notes |
| ----- | -------- | ----- |
| RoomBrowser toggle hides lobby and never reopens | HIGH | `RoomBrowserUI.Visible` stays false after close; need state reset (open button currently a no-op). |
| LobbyEventTap keeps queueing regardless of player state | MEDIUM | `already_queued` spam + constant state refresh; gate broadcasts once queued/in room. |
| UIPadding still uses `PaddingAll` | LOW | Roblox `UIPadding` expects `PaddingLeft/Right/Top/Bottom`; warning logged every toggle. |
| TelemetrySystem still silent in boot log | LOW | Main.lua registered but log entry missing; tracking after Step 3. |
| rbxassetid://10576163165 HTTP 403 | LOW | Invalid audio asset; revisit in Phase 7 polish. |
| SystemDiagnostics Loaded: 0 | LOW | Counter not reading from SystemRegistry; cosmetic sync later. |

NEXT IMMEDIATE ACTION:
→ Maintain runtime parity: `src/ServerScriptService/Server` is the only active server tree.
→ Keep ghost/evidence canonical: 12 Indonesian ghosts + evidence vocabulary `MEDOK/Suhu/BukuTerkutuk/To'un/Suara/Pengganggu`.
→ Keep rank owner single-source: `RankedSystem` only.
→ Keep currency model canonical: `MM/PP/Robux`, while `XP` remains progression-only.
→ Continue Phase 7 launch hardening (security/perf validation, telemetry, monetization QA).

================================================================
SYSTEM STATUS QUICK REFERENCE
================================================================

COMPLETED (do not touch):
Boot Pipeline, SystemRegistry, EventBus,
MatchQueue, MatchBuilder, MatchLifecycle, MatchTeleport,
MatchService, Dev.Match, Room System, Match Container,
Investigation State Machine, Ghost Init, Evidence Trigger,
Lobby Map Geometry

IN PROGRESS / VALIDATED TODAY:
HuntSystem, SanitySystem, EvidenceSystem,
EconomySystem, ProgressionSystem, SpectatorDistortion,
RankedSystem, LiveOps(TelemetrySystem-parked)


================================================================
ARCHITECTURE RULES
================================================================

EventBus = ONLY communication layer
DataPersistenceService = ONLY writer to player data
HorrorDirector = RED LINE — never bypass pacing control
Match-scoped = all gameplay state lives/dies with matchId
RemoteEvents = always validate server-side

SystemRegistry scan pattern:
  Scans src/ServerScriptService/Server/ children
  Finds folders ending with "System"
  Requires folder/Main.lua
  → Every system MUST have Main.lua with .new() + lifecycle

================================================================
DESIGN DECISIONS LOCKED
================================================================

SpectatorDistortion:
  Current: Static 10/30/60 split (Real/Unclear/Fake)
  Planned upgrade: Dynamic DistortionPressure
    Low pressure  → Real 25% / Unclear 35% / Fake 40%
    High pressure → Real 5%  / Unclear 20% / Fake 75%
    Driver: HorrorDirector.tensionLevel
  Timing: Phase 7 implementation
  Note: [DESIGN NOTE] Spectator Agency (dead player chooses
  what to communicate) → Phase 7 target feature

Ghost State Machine valid transitions:
  Idle → Roaming → Manifestation → Hunting → Cooldown → Idle

Hunt trigger dual condition (BOTH required):
  aggression >= huntThreshold AND averageSanity <= 40

================================================================
TECH DEBT WATCHLIST
================================================================

1. playerState missing role/team/permissions
   → Placeholder nil fields added — OK for now
   → Season 3-6 Asymmetric PvP ready

2. SpectatorDistortion static → dynamic upgrade pending
   → Phase 7

3. TelemetrySystem boot silent skip
   → Main.lua exists, registered
   → Needs debug after match flow validated

4. SystemDiagnostics Loaded counter = 0
   → Does not read from SystemRegistry
   → Low priority cosmetic fix

================================================================
ROJO NOTES
================================================================

- Always verify Rojo is connected before F5
- Check last sync timestamp in Studio
- If changes not reflected: Disconnect → Reconnect Rojo
- .server.lua files require Rojo sync to run as Scripts

================================================================
GHOST DATABASE
================================================================

12 ghost types (Indonesian folklore):
Pocong, Kuntilanak, Genderuwo, Tuyul, Leak,
Banaspati, Jerangkong, WeweGombel, Palasik,
SilumanUlar, SundelBolong, HantuTanah

================================================================
MAPS
================================================================

LobbySocialHub 
AbandonedPalace 
HauntedHouse 
StudioMMNineteen 
EmptyBuilding 

================================================================
END OF CLAUDE.md
================================================================

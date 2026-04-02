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
3. struktur folder.txt
4. REPORTS.md
5. CLAUDE.md (this file)
6. CANONICAL_SPECIFICATIONS_v2.md

Confirm current phase before ANY action.

================================================================
CURRENT STATUS — 2026-03-17
================================================================

PHASE: Late Phase 6 stabilization -> entering Phase 7 consistency lock
BOOT: 84ms, FAILED: 0, all systems Init+Start clean

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

PLANNED / NEXT:
Phase 6: Performance & Security
Phase 7: Launch Preparation  
Phase 8: Publish

FUTURE (Season 3-6):
Asymmetric PvP — placeholder fields ready in playerState:
  role = nil, team = nil, permissions = nil

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

LobbySocialHub (420x420)
AbandonedPalace (180x180)
HauntedHouse (140x140, 2 floors)
StudioMMNineteen (90x90, 2 floors)
EmptyBuilding (100x100, 2 floors)

================================================================
END OF CLAUDE.md
================================================================
```

---

## FILE YANG HARUS DISERTAKAN NEXT SESSION
```
WAJIB (paste atau attach):
1. CLAUDE.md                    ← file ini
2. REPORTS.md                   ← status terbaru
3. PASRAHPHOBIA_AI_SUPER_CONTEXT_V2.md

OPSIONAL (jika ada perubahan):
4. Boot log terbaru dari Studio
5. File yang mau diedit
```

---

## REMINDER NEXT SESSION
```
LANGSUNG LANJUT KE:

Phase 7 consistency lock + launch hardening
Focus: runtime parity, evidence/ghost canonical sync, RankedSystem-only rank flow, and MM/PP/Robux economy audit
```

---

## SESSION APPEND — 2026-03-19

Current runtime status:
- Match teleport is working again.
- Match teleport now resolves directly from `ServerStorage.Maps` (fallback removed).

Latest verified server log:
- `07:44:41.875 [MatchTeleport] Using map template: EmptyBuilding from ServerStorage.Maps`
- `07:44:41.879 [MatchTeleport] Teleported players to map EmptyBuilding`

Action still pending:
- Continue Step 3 UI blockers: RoomBrowser toggle reopen state, LobbyEventTap queue broadcast gating, and `UIPadding.PaddingAll` cleanup.

Latest stability hotfix (2026-03-19):
- Lobby spawn death-loop mitigated by resolving lobby spawn from `Workspace/Maps/LobbySocialHub/SpawnPoints` with root wait + respawn guard.
- Match end flow now re-publishes `PlayerTeleported` to `mapId = "Lobby"` for all match players (fallback-safe) so lobby registration restores after cleanup.
- Lobby spawn scan now logs at init and auto-rebuilds `SpawnPoints` if unhealthy (count/bounds invalid), then retries spawn.
- Manual override available: set `Workspace.ForceLobbySpawnRebuild = true` to force one spawnpoint rebuild on next scan.
- Force flag is also evaluated during spawn, so rebuild can be triggered mid-session via character reset.
- Runtime spawn protection is now hooked in `LobbySystem` (`OnPlayerJoin` + `CharacterAdded`) because that is the active path seen in current boot logs.

## SESSION APPEND — 2026-03-20

Current runtime status:
- Lobby/Room routing is active again end-to-end (`LobbyEvent` receive -> room actions -> state update -> countdown -> match start path).
- Match teleport confirmed running from `ServerStorage.Maps`.

Major progress:
- Added server request idempotency guard (`requestId` + dedupe window) to reduce duplicate trigger risks.
- RoomBrowser UI now supports:
  - floating open button (`RUANG INVESTIGASI`) make UI ROBLOX FRIENDLY,
  - hidden on spawn by default,
  - hidden while in match.
- Room list and room state are now broadcast cross-client on create/join/leave/ready in fallback path.
- Ranked/classic selection no longer resets every few seconds (fallback selection state persisted).
- Added room player list in room panel + host metadata in room list entries.
- Added quick join split:
  - `QUICK CLASSIC` -> most populated classic room.
  - `QUICK RANKED` -> most populated ranked room.
- Added placeholder preview blocks:
  - map placeholder (classic),
  - ranked placeholder.

Password + kick updates:
- Password join enforcement enabled in fallback server handler.
- `SetPassword` enabled (host-only, 4 digit validation).
- Join password now via popup modal flow.
- Kick feature active:
  - host can kick players,
  - kicked target receives `RoomBrowserRoomLeft` with reason `kicked`,
  - client popup added: `ANDA TELAH DI KICK`.

Pending verification focus:
- Re-test full 2-client room UX after latest password modal and inline kick UI updates.
- Keep architecture stable: no new system layer, continue extending active Lobby/Room path only.

## SESSION APPEND — 2026-04-01 (Codex continuation)

[STEP 101%]
G: Selaraskan `DeathEventBridge` aktif dengan handoff follow-up `2026-04-01`.
C: Hapus dua trace `warn(...)` yang masih tersisa pada jalur spawn-protection dan debounce death event.
F: src/ServerScriptService/Server/DeathStateSystem/DeathEventBridge.lua; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/REPORTS.md; DATA TEXT/DOCUMENTATION/SAAT OPEN CHAT BARU/CLAUDE.md
I: Repo aktif masih menyisakan trace `DeathEventBridge` walau state follow-up sebelumnya sudah menyatakan trace itu dibersihkan. Patch ini menutup mismatch handoff tanpa mengubah owner, payload, atau guard `matchId` pada runtime death flow.
N: Verifikasi runtime berikutnya: jalankan match sungguhan di Studio dan pastikan `DeathStateSystem` tetap memancarkan state death dengan `matchId` nyata dari `MatchStarted`, tetap mengabaikan death/respawn di luar match, dan tidak lagi menghasilkan trace `DeathEventBridge` pada kasus spawn-protection/debounce.

[STATE]
M: `DeathStateSystem` sudah sinkron dengan handoff follow-up `2026-04-01`: injeksi `DEBUG_MATCH` tetap tidak ada, guard `matchId` nyata tetap aktif, dan `DeathEventBridge` tidak lagi menyisakan trace `warn(...)` pada jalur spawn-protection/debounce. Runtime owner lain tetap sama: `MatchSystem` memancarkan `MatchEnded`, `RankedSystem` tetap owner tunggal rank flow, owner reward/event duplicate tidak lagi ikut autoload, dan registry active path tetap `src/ServerScriptService/Server`.
P: 100% batch cleanup low-risk tetap selesai; follow-up sinkronisasi `DeathEventBridge` selesai.
B: Tidak ada blocker kode aktif untuk task ini; verifikasi runtime Studio tetap pending sebagai langkah berikutnya.

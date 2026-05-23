# PLAYABLE LOOP OWNER-VISIBLE FULL FLOW - 2026-05-17

Branch/runtime target: `brian-second-final`, local `PASRAHPHOBIA.rbxlx`, Studio account `briankotak`.

## Scope

Validate the playable loop visually in the active Studio instance without creating a new gameplay system:

- Room Browser -> create room -> host start countdown -> staging.
- Tool selection -> front door/breach -> `InvestigationPhase`.
- Evidence/event/hunt/safe-zone/result path.
- Ghost runtime visual sanity.

## Source Changes

- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`
  - `SetPreparationFocusTool` now mirrors the same authoritative player attributes as a real world tool station selection: `PreparationFocusToolLabel`, `PreparationFocusToolSource = "WorldToolStation"`, `PasrahPreparationToolSelected`, `PasrahEquippedToolType`, and `PasrahToolUseStamp`.
  - Added Studio-only `MovePlayerToMapObject` E2E helper. This only moves the player to an existing runtime map object for visual validation; it does not advance match phase or create alternate gameplay ownership.
- `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
  - Preparation advance door now requests `InvestigationPhase` when the door is already open, the player has a valid world-station tool selection, and the player is near the door. This closes the real drift where `Door_FrontEntry` could be visually open but the match remained in `PreparationPhase`.
- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
  - HauntedHouse runtime clones now disable imported legacy `BaseScript` descendants before the match starts. This preserves owner-authored map visuals while preventing old asset-pack scripts from fighting PASRAH-owned `MapInteractionSystem`, `MapEventSystem`, and `DoorRuntime`.

## Owner-Visible Result

- Room Browser displayed visually and the same `LobbyEvent` actions used by UI handlers created/started the room.
- Countdown/staging loaded; the match did not jump straight to result.
- `SetPreparationFocusTool` now unlocked the front door correctly: `Door_FrontEntry` prompt changed from `Pilih Tools Dulu` to `Buka Pintu`.
- Opening `Door_FrontEntry` through the registered map interaction produced:
  - `DoorIsOpen = true`
  - `PasrahPrepAdvanceHasFocus = true`
  - `PasrahPrepAdvanceNearby = true`
  - `MatchLifecyclePhase = InvestigationPhase`
  - `MatchPhase = InGame`
- Evidence submit/end flow completed with forced `Pocong`:
  - Ghost asli: `Pocong`
  - Tebakan: `Pocong`
  - Checklist tebakan: `MEDOK | Suhu | BukuTerkutuk`
  - Evidence asli: `MEDOK | Suhu | BukuTerkutuk`
  - Result: `MISSION COMPLETE`, `BERHASIL`, `BENAR`
  - Result close returned player state to lobby/default cursor.
- Runtime ghost visual smoke showed `Ghost_Pocong` as the active model during a forced hunt visual window.
- HauntedHouse imported legacy script cleanup smoke confirmed the active map clone had `LegacyAssetScriptsDisabled=true`, `LegacyAssetScriptsDisabledCount=581`, and no new targeted `Switch` / `Interactive` / `Openable` / `Workspace.Fireplace` / `MapBoardSurfaceTemplate missing required child: Panel` errors after the patch timestamp.

## Remaining Risks

- The quick ghost visual focus had to use a priority camera because the normal runtime camera and staging overlays competed with the smoke camera. The ghost was visible, but a clean real in-house chase readability pass is still needed.
- HauntedHouse imported legacy asset scripts are disabled at runtime on the cloned map, not deleted from the authored source map. If future imported-map behavior is intentionally needed, it must be re-owned through PASRAH runtime systems instead of re-enabling those legacy scripts wholesale.
- Tool model `SurfaceAppearance` texture packs and several old sound assets still throw fetch/HTTP 403 errors. These are not introduced by this pass, but they affect visual polish.
- Full manual-player prompt retest remains useful because MCP keyboard/mouse does not reliably trigger `ProximityPrompt`/GuiButton input.

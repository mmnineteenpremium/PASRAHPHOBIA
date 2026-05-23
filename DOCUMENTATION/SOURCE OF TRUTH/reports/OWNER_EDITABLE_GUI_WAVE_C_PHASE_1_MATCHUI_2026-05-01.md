# OWNER-EDITABLE GUI WAVE C PHASE 1 MATCHUI

Date: 2026-05-01
Owner context: Miftah
Status: COMPLETE

## Scope

- `MatchUI`

## Source Changes

- Added authored shell:
  - `src/StarterGui/MatchUI.model.json`
- Added `UISystem:_ensureAuthoredMatchPanelWidgets(match)` in `src/client/UI/Main.lua`.
- Added `UISystem:_bindAuthoredMatchUi(gui)` in `src/client/UI/Main.lua`.
- Rewired `_ensureBasicUIs()` so `MatchUI` binds to the authored shell instead of rebuilding the match panel shell through the runtime branch.

## Result

- `MatchUI` shell ownership is now in `StarterGui`.
- The active logic lane for match state, timer, hint text, field kit actions, and float reopen behavior remains unchanged.
- Remaining eligible GUI surfaces not yet migrated to authored shells:
  - `LobbyUXGui`
  - `MatchUXGui`

## Known Limits

- `SummaryFrame` rows are still created/runtime-updated inside the authored shell.
- `FieldKitFrame.Buttons` still receives runtime-generated tool buttons inside the authored shell.
- Dedicated overlay/result surfaces in `LobbyUXGui` and `MatchUXGui` are not part of this slice yet.

## Validation

- `ConvertFrom-Json` passed for `src/StarterGui/MatchUI.model.json`.
- `pwsh -NoLogo -File scripts\\Invoke-Rojo.ps1 build default.project.json --output .codex\\tmp\\matchui-wave-c-phase1.rbxlx`
- `pwsh -NoLogo -File scripts\\release-preflight.ps1 -Json -CanonicalPlaceOutput ''`
- Preflight status: `buildOk=true`, `missingReports=[]`

## Next

- Continue Wave C:
  - `LobbyUXGui`
  - `MatchUXGui`
- Keep full owner edit pass closed until those remaining eligible surfaces are also migrated and mirrored into `PASRAHPHOBIA.rbxlx`.

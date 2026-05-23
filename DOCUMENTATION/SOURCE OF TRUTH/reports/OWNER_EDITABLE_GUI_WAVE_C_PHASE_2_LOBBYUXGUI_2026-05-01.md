# OWNER-EDITABLE GUI WAVE C PHASE 2 LOBBYUXGUI

Date: 2026-05-01
Owner context: Miftah
Status: COMPLETE

## Scope

- `LobbyUXGui`

## Source Changes

- Added authored shell:
  - `src/StarterGui/LobbyUXGui.model.json`
- Updated `_ensureUXLayers()` in `src/client/UI/Main.lua` so authored `LobbyUXGui` at the root of `PlayerGui` is preferred over creating a duplicate runtime `LobbyUXGui` inside the old `UXLayer` folder.
- `SafePadding` now refreshes on existing authored `LobbyUXLayer` instead of only when the layer is first created.

## Result

- `LobbyUXGui` shell ownership is now in `StarterGui`.
- The active feedback/training logic lane remains unchanged.
- Remaining eligible GUI surface not yet migrated to an authored shell:
  - `MatchUXGui`

## Known Limits

- `SupportStrip` cards still receive runtime preview/state refresh.
- Evidence-training ghost preview content remains runtime-rendered inside the authored `TrainingPreview` viewport.
- `MatchUXGui` overlay/result lane is not part of this slice yet.

## Validation

- `ConvertFrom-Json` passed for `src/StarterGui/LobbyUXGui.model.json`.
- `pwsh -NoLogo -File scripts\\Invoke-Rojo.ps1 build default.project.json --output .codex\\tmp\\lobbyux-wave-c-phase2.rbxlx`
- `pwsh -NoLogo -File scripts\\release-preflight.ps1 -Json -CanonicalPlaceOutput ''`
- Preflight status: `buildOk=true`, `missingReports=[]`

## Next

- Continue Wave C final slice:
  - `MatchUXGui`
- Keep full owner edit pass closed until `MatchUXGui` is also migrated and mirrored into `PASRAHPHOBIA.rbxlx`.

# OWNER-EDITABLE GUI WAVE C PHASE 3 MATCHUXGUI

Date: 2026-05-01
Owner context: Miftah
Status: COMPLETE

## Scope

- `MatchUXGui`

## Source Changes

- Added authored shell:
  - `src/StarterGui/MatchUXGui.model.json`
- Updated `_ensureUXLayers()` in `src/client/UI/Main.lua` so authored `MatchUXGui` at the root of `PlayerGui` is preferred over creating a duplicate runtime `MatchUXGui` inside the old `UXLayer` folder.
- Preserved runtime result-row generation inside authored `ResultsSummary` and preserved hunt/objective/result refresh on the same active logic lane.

## Result

- `MatchUXGui` shell ownership is now in `StarterGui`.
- All eligible player-facing GUI surfaces targeted by the owner-editable migration are now authored in `StarterGui`.
- Full migration milestone is complete; the next lane is owner visual editing, not more shell migration.

## Known Limits

- `ResultsSummary` rows are still generated/runtime-updated inside the authored shell.
- Hunt overlay colors, objective text, assist text, and result content remain runtime-refreshed on the same logic lane.
- World-space `BillboardGui`/`SurfaceGui` gameplay surfaces remain outside this lane by documented choice.

## Validation

- `ConvertFrom-Json` passed for `src/StarterGui/MatchUXGui.model.json`.
- `pwsh -NoLogo -File scripts\\Invoke-Rojo.ps1 build default.project.json --output .codex\\tmp\\matchux-wave-c-phase3.rbxlx`
- `pwsh -NoLogo -File scripts\\release-preflight.ps1 -Json -CanonicalPlaceOutput ''`
- Preflight status: `buildOk=true`, `missingReports=[]`

## Next

- Open owner visual edit pass across authored `StarterGui` shells.
- Keep publish/test discipline the same: single Studio instance, save-back to `PASRAHPHOBIA.rbxlx`, then close Studio again before moving to another task.

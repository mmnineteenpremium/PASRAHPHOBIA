# OWNER-EDITABLE GUI UXLAYER LEGACY BUILDER HARD DELETE

Date: 2026-05-01
Owner context: Miftah
Lane: visual-only / authored GUI
Batch: T285

## Goal

Remove the unreachable legacy UX builder code after the authored bind-only guard so future passes cannot mistake it for an active fallback lane.

## Scope

- `src/client/UI/Main.lua`
- `_ensureUXLayers()`

## Execution

- Deleted the dead runtime builder block that previously created `UXLayer`, `LobbyUXGui`, `MatchUXGui`, `LobbyUXLayer`, `MatchUXLayer`, and static UX child widgets after the authored bind-only return path.
- Kept the authored contract validation, binding, safe padding refresh, result summary row refresh, and training support-card refresh.

## Result

- `_ensureUXLayers()` now has one active authority for UX shells: authored `StarterGui` contracts.
- Missing authored UX contracts fail explicitly with a warning instead of rebuilding legacy visible UI.
- The remaining UX runtime behavior is data/state/content refresh inside authored shells, not shell creation.

## Verification

- `pwsh -NoLogo -File scripts/release-preflight.ps1 -Json`
  - `buildOk: true`
  - `canonicalMirrorOk: true`
  - `missingReports: []`

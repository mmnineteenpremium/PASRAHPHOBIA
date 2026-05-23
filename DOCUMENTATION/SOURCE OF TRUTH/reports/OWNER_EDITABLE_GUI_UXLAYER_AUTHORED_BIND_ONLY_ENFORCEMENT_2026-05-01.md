# OWNER-EDITABLE GUI UXLAYER AUTHORED BIND-ONLY ENFORCEMENT

Date: 2026-05-01
Owner context: Miftah
Lane: visual-only / authored GUI
Batch: T284

## Goal

Remove the last active UX-layer builder path from the owner-authored lane so authored `LobbyUXGui` and `MatchUXGui` cannot be silently recreated by runtime fallback code.

## Scope

- `src/client/UI/Main.lua`
- Authored UX shells:
  - `LobbyUXGui`
  - `MatchUXGui`

## Execution

- Changed `_ensureUXLayers()` to use a bind-only path while the authored-owner layout lock is active.
- The active lane now validates the authored UX contract in `PlayerGui`, refreshes `SafePadding`, binds widget references, and keeps only intentional runtime-dynamic content generation inside the authored shells.
- If the authored UX contract is missing or damaged, the active lane now fails explicitly with a warning instead of rebuilding duplicate legacy shells.

## Result

- `LobbyUXGui` and `MatchUXGui` are no longer silently recreated on the active owner-authored lane.
- The remaining UX runtime lane is now limited to dynamic content by design, such as training support cards, result summary rows, visibility, and live state text.
- This closes another hidden path that could have confused owner manual editing by reviving legacy UX geometry.

## Verification

- `pwsh -NoLogo -File scripts/release-preflight.ps1 -Json`
  - `buildOk: true`
  - `canonicalMirrorOk: true`
  - `missingReports: []`

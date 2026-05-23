# OWNER-EDITABLE GUI WAVE B PHASE 1 AUXILIARY PANELS

Date: 2026-05-01
Owner context: Miftah
Status: COMPLETE

## Scope

- `JournalUI`
- `ProfileUI`
- `ShopUI`
- `RoyalPassUI`
- `PASRA_UI`
- `SpectatorUI`

## Source Changes

- Added authored shells:
  - `src/StarterGui/JournalUI.model.json`
  - `src/StarterGui/ProfileUI.model.json`
  - `src/StarterGui/ShopUI.model.json`
  - `src/StarterGui/RoyalPassUI.model.json`
  - `src/StarterGui/PASRA_UI.model.json`
  - `src/StarterGui/SpectatorUI.model.json`
- Added `UISystem:_bindAuthoredAuxiliaryWindowUi(guiName, gui)` in `src/client/UI/Main.lua`.
- Rewired `_ensureBasicUIs()` so the six auxiliary panels bind to authored `StarterGui` contracts instead of rebuilding shell statics via runtime `Instance.new`.
- Added `UISystem:_ensureAuthoredShopWindowWidgets(window)` so `ShopUI` keeps an authored owner-editable shell while runtime filter buttons, item rows, and purchase actions still bind through the old shop logic lane inside `ContentFrame`.

## Result

- Owner-editable authored GUI surfaces now total `18`.
- Remaining eligible GUI surfaces not yet migrated to authored shells:
  - `MatchUI`
  - `LobbyUXGui`
  - `MatchUXGui`
- Full owner edit pass remains intentionally delayed until those remaining eligible surfaces are also migrated or explicitly documented as runtime-only.

## Known Limits

- `ShopUI` item/filter rows remain runtime-generated inside the authored shell.
- `JournalUI`, `ProfileUI`, `RoyalPassUI`, `PASRA_UI`, and `SpectatorUI` still allow runtime population of content/state widgets inside their authored containers where the legacy logic lane expects live data binding.
- This batch moves shell ownership to `StarterGui`; it does not rewrite gameplay, reward, snapshot, or server-state systems.

## Validation

- `ConvertFrom-Json` passed for all new `src/StarterGui/*.model.json` files.
- `pwsh -NoLogo -File scripts\\Invoke-Rojo.ps1 build default.project.json --output .codex\\tmp\\owner-editable-wave-b-phase1.rbxlx`
- `pwsh -NoLogo -File scripts\\release-preflight.ps1 -Json -CanonicalPlaceOutput ''`
- Preflight status: `buildOk=true`, `missingReports=[]`

## Next

- Continue Wave C migration:
  - `MatchUI`
  - `LobbyUXGui`
  - `MatchUXGui`
- Keep Studio owner-edit checkpoint closed until all eligible GUI surfaces are migrated and mirrored into `PASRAHPHOBIA.rbxlx`.

# Legal Runtime Review 2026-04-11

## Meta

- date: `2026-04-11 02:44:33 +07:00`
- environment: published Studio place runtime
- place: `PASRAHPHOBIA`
- `PlaceId`: `113010869463813`
- `GameId`: `9802743087`
- objective:
  - prove the required attribution surface is visible in the final runtime layout
  - close the `LegacyDisabled` disposition question for v1 publish

## Runtime Repair Applied

- root cause found during cloud runtime review:
  - `ClientBootstrap` reached stage `started`
  - but `UI` service was not registered
  - `require(Client.UI.Main)` failed in the published place runtime
- fix applied:
  - split graphics helpers out of `src/client/UI/Main.lua` into:
    - `src/client/UI/GraphicsSupport.lua`
    - `src/client/UI/CharacterPreviewSupport.lua`
  - `src/client/UI/Main.lua` now requires those modules instead of carrying all graphics / preview helpers inline
- validation after fix:
  - `require(Client.UI.Main)` in the published place returned `ok=true`
  - `ClientBootstrap` stage remained `started`

## Attribution Surface Proof

- Studio-only probe result after the fix:
  - `guiParent = PlayerGui`
  - `guiEnabled = true`
  - `title = QUICK MENU`
  - `badge = QUICK ACCESS`
  - panel bounds:
    - `position = (369.5, 16)`
    - `size = (340 x 376)`
  - footer bounds:
    - `position = (381.5, 350)`
    - `size = (316 x 34)`
  - footer visible:
    - `true`
  - footer text:
    - `Pocong model by alterego.visual (Sketchfab) - CC BY 4.0`
    - `Visual DETAIL [Visual penuh]. Mobile default tetap landscape dan toggle ini murni client-side.`
- screenshot evidence:
  - `.codex/legal_runtime_attribution_visible.png`
  - `.codex/legal_runtime_attribution_visible.json`
- interpretation:
  - the legally required attribution line is visible in the player-facing runtime UI
  - the second line is graphics/mobility helper copy, not part of the legal requirement

## LegacyDisabled Disposition

- current runtime inspection:
  - `StarterPlayer.StarterPlayerScripts.Client.LegacyDisabled` exists with `0` children
  - `script_grep` found `0` live script references to `LegacyDisabled`
- source/document correlation:
  - legacy scripts were already removed from the active runtime path in earlier cleanup
  - the remaining folder is inert / archival, not an active owner in the publish runtime
- v1 decision:
  - keep `LegacyDisabled` as archive-only context
  - do not treat it as a publish blocker while the folder stays empty and unreferenced at runtime

## Final Status

- status: `PASS`
- passed:
  - required attribution surface visible in final runtime layout
  - published place client UI restored after module split
  - `LegacyDisabled` classified as inert / non-runtime for v1
- remaining blocker outside this report:
  - real `2`-client multiplayer smoke

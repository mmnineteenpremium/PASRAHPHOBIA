# UI Toggle Key Audit 2026-04-11

## Scope

- source scan:
  - `src/client/UI/Main.lua`
  - `src/client/CameraController.client.lua`
  - `src/client/FlashlightController.client.lua`
- runtime verification:
  - published Studio place `PlaceId=113010869463813`
  - `Rojo` connected during sync verification

## Local Bindings Found

- `M` -> Room Browser
- `K` -> Match panel
- `J` -> Journal
- `P` -> Profile
- `B` -> Shop
- `R` -> Royal Pass
- `U` -> PASRA status
- `V` -> Spectator
- `X` -> close topmost UI / dismiss match panel
- `ButtonB` -> gamepad close
- `F` -> flashlight toggle
- `LeftAlt` + `Backquote` -> FPV cursor unlock

## Official Roblox Defaults Checked

- Creator Hub input docs describe Roblox default bindings and reserved inputs for in-experience controls. Relevant reserved examples include:
  - `Esc` -> Roblox menu
  - `F9` -> Developer Console
  - source: `https://create.roblox.com/docs/input`
- Roblox support documents:
  - `Experience Chat`: `/` opens chat; some international layouts may need `\`
    - source: `https://en.help.roblox.com/hc/en-us/articles/203313520-Experience-Chat`
  - `How to Use Gear and The Backpack`: inventory hotkeys map to the ten backpack slots
    - source: `https://en.help.roblox.com/hc/en-us/articles/203314280-How-to-Use-Gear-and-The-Backpack`
  - `How to Leave an Experience`: Roblox menu can be opened from the upper-left menu, and `L` is the leave shortcut from that menu flow
    - source: `https://en.help.roblox.com/hc/en-us/articles/203314240-How-to-Leave-an-Experience`

## Conflict Analysis

- Direct conflict found:
  - `Esc` was being used as local close toggle in `Main.lua`, while Roblox reserves it for the Roblox menu.
- No documented Roblox-default conflict found for:
  - `M`
  - `K`
  - `J`
  - `P`
  - `B`
  - `R`
  - `U`
  - `V`
  - `F`
  - `LeftAlt`
  - `Backquote`
- Residual note outside this toggle-only refactor:
  - field-kit shortcuts `1-9` still overlap Roblox backpack-number expectations from official support docs.
  - this audit did not change that lane because the approved scope was toggle functions only.

## Refactor Applied

- file updated:
  - `src/client/UI/Main.lua`
- changes:
  - `CLOSE_KEYBOARD_KEY` changed from `Enum.KeyCode.Escape` to `Enum.KeyCode.X`
  - close hint text updated from `Esc` to `X`
  - `_bindAuxiliaryToggleInput()` now exits immediately when `gameProcessed == true`
  - `_bindMatchPanelToggleInput()` now exits immediately when `gameProcessed == true`
  - `_bindWindowCloseInput()` now exits immediately when `gameProcessed == true`

## Runtime Verification

- source change was verified in the published Studio place after `Rojo` sync:
  - `game.StarterPlayer.StarterPlayerScripts.Client.UI.Main`
  - `CLOSE_KEYBOARD_KEY = Enum.KeyCode.X`
  - updated toggle handlers were present in the live Studio script

## Result

- UI toggle bindings no longer compete with Roblox `Esc` menu behavior.
- Menu toggles now respect `gameProcessed`, which reduces accidental double-handling when core UI has already consumed input.
- Remaining non-toggle input overlap to revisit later:
  - field-kit `1-9` versus Roblox backpack-number semantics.

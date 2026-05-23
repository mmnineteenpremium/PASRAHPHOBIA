# Owner-Editable Visual Deep Scan Addendum - 2026-05-03

## Scope

Addendum ini mengoreksi blocker stale dari deep scan 2026-05-02 setelah audit ulang source, mirror Studio aktif `PASRAHPHOBIA.rbxlx`, dan Play Test single-client.

## Batch Completed

### Final Client HUD / Preview Follow-Up

- `src/StarterGui/SensoryHorrorHUD.model.json`
  - added authored `SensoryHorrorHUD` ScreenGui
  - added authored `Vignette` CanvasGroup with editable edge children
- `src/StarterGui/LobbyUI.model.json`
  - added authored `SensoryLobbyCanvasGroup`
- `src/ReplicatedStorage/Assets/VisualTemplates.model.json`
  - added `UI.FlatPreviewFallbackTemplate`
  - template owns `FlatPreviewTitle` and `FlatPreviewDetail`
- `src/client/UI/HUD/HorrorHUD.luau`
  - now bind-only to authored `SensoryHorrorHUD`
  - now bind-only to authored `LobbyUI.SensoryLobbyCanvasGroup`
  - removed runtime construction for `ScreenGui`, `CanvasGroup`, `ImageLabel`, `Frame`, and `UIGradient`
- `src/client/UI/GraphicsSupport.lua`
  - flat preview labels now clone `UI.FlatPreviewFallbackTemplate`
  - removed runtime construction for `TextLabel`

Validation:
- source JSON parse pass for `SensoryHorrorHUD.model.json`, `LobbyUI.model.json`, and `VisualTemplates.model.json`
- source grep pass for all remaining blocker constructors
- Studio mirror pass for authored shell/template and scripts
- Studio script grep pass for `Instance.new("ScreenGui")`, `Instance.new("CanvasGroup")`, and `Instance.new("TextLabel")`
- Play Test single-client pass
- runtime confirmed:
  - `PlayerGui.SensoryHorrorHUD`
  - `PlayerGui.SensoryHorrorHUD.Vignette` as `CanvasGroup`
  - `PlayerGui.LobbyUI.SensoryLobbyCanvasGroup`
  - `ReplicatedStorage.Assets.VisualTemplates.UI.FlatPreviewFallbackTemplate`
- target log clean for `HorrorHUD`, `GraphicsSupport`, missing template warnings, `attempt to`, and `ClientBootstrap`

### World Effects Follow-Up

- `src/ReplicatedStorage/Assets/VisualTemplates.model.json`
  - added `WorldEffects.WorldBoxOutlineTemplate`
  - added `WorldEffects.WorldFireTemplate`
- `src/ServerScriptService/Server/HidingSystem/Service.lua`
  - safe-zone outline now clones `WorldBoxOutlineTemplate`
  - removed direct `Instance.new("BoxHandleAdornment")`
- `src/ServerScriptService/Server/ClosetHidingMechanic/Service.lua`
  - hide-spot outline now clones `WorldBoxOutlineTemplate`
  - removed direct `Instance.new("BoxHandleAdornment")`
- `src/ServerScriptService/Server/LobbySocialHub/CampfireSanityService.lua`
  - campfire `Fire` now clones `WorldFireTemplate`
  - removed direct `Instance.new("Fire")`

Validation:
- source JSON parse pass
- source grep pass for target constructors
- Studio mirror pass for templates and target scripts
- Studio script grep pass for `Instance.new("BoxHandleAdornment")` and `Instance.new("Fire")`
- Play Test single-client pass
- runtime confirmed:
  - `ReplicatedStorage.Assets.VisualTemplates.WorldEffects.WorldBoxOutlineTemplate`
  - `ReplicatedStorage.Assets.VisualTemplates.WorldEffects.WorldFireTemplate`
  - `Workspace.Maps.LobbySocialHub.LobbySocialHub.CampfireRuntime.CampfireFireCore.CampfireFire`
- target log clean for missing `WorldBoxOutlineTemplate` / `WorldFireTemplate`, `attempt to`, and `ClientBootstrap Start failed`

Studio-only repair:
- `StarterPlayer.StarterPlayerScripts.Client.UI.Main` had stale `ensureCorner` calls from an older Studio mirror.
- A non-builder `ensureCorner` binder was restored in Studio so authored `UICorner` children can still be adjusted without creating fallback visuals.

### Previous UI/Spectator Batch

- `src/client/UI/Main.lua`
  - hard-delete helper visual legacy yang tidak lagi dipakai:
    - `ensureCorner`
    - `createSummaryRow`
    - `createActionRow`
  - `_setSelectableStyle` tidak lagi membuat `SelectionStroke` fallback; lane non-button sekarang authored-only bila stroke memang disediakan shell
- `src/client/SpectatorEffects/Main.lua`
  - overlay spectator sekarang bind-only ke child authored
  - fallback `Instance.new("Frame")` untuk overlay dihapus
- `src/StarterGui/SpectatorUI.model.json`
  - child authored baru:
    - `StaticFlickerOverlay`
    - `ColorDesaturationOverlay`

## Studio Mirror

Studio aktif yang dipakai:
- `PASRAHPHOBIA.rbxlx`

Mirror yang masuk ke Studio:
- script `StarterPlayer.StarterPlayerScripts.Client.UI.Main`
- script `StarterPlayer.StarterPlayerScripts.Client.SpectatorEffects.Main`
- `StarterGui.SpectatorUI.StaticFlickerOverlay`
- `StarterGui.SpectatorUI.ColorDesaturationOverlay`

## Validation

- parse JSON `src/StarterGui/SpectatorUI.model.json` pass
- grep source pass:
  - `src/client/UI/Main.lua` bersih dari `Instance.new(...)` UI visual
  - `src/client/SpectatorEffects/Main.lua` bersih dari `Instance.new("Frame")` overlay fallback
- Play Test single-client pass pada 2026-05-03
- Runtime verification pass:
  - `PlayerGui.SpectatorUI.StaticFlickerOverlay`
  - `PlayerGui.SpectatorUI.ColorDesaturationOverlay`
- `LogService` tidak menunjukkan warning `SpectatorEffects` contract mismatch
- log yang tersisa saat validasi batch ini tidak terkait:
  - plugin `CreateToolBar` error
  - beberapa asset sound `HTTP 403`

## Current Remaining Blockers

No active owner-editable visual blocker remains from this deep-scan list.

## Runtime-Only Whitelist Clarification

Yang tetap runtime-only dan bukan target authored owner-edit langsung:

- post-process `BlurEffect` / `ColorCorrectionEffect` di:
  - `src/client/SpectatorEffects/Main.lua`
  - `src/client/Controllers/Sensory/VFXController.luau`
- invisible host `Part` / `Attachment` untuk VFX transient
- `ViewportFrame` live preview + `WorldModel` / `Camera` isinya

## Decision

Gate owner-edit is now ready for owner visual edit pass for the migrated/audited surfaces in this roadmap. Runtime-only whitelist remains in force for post-process effects, transient VFX hosts, `ViewportFrame` live content, `WorldModel`, `Camera`, runtime sounds, folders, prompts, and map/runtime model assembly.

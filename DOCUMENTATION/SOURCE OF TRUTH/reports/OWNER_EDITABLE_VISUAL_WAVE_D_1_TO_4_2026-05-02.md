# OWNER EDITABLE VISUAL WAVE D (1-4) - 2026-05-02

## Scope

Approved owner scope:
1. Workspace world-space visual
2. Lighting global look
3. ReplicatedStorage visual assets
4. Tool + Ghost visual shell (including rig/animation asset references), while logic stays locked

## Rule Lock

- Visual editable: YES
- Gameplay logic / AI / networking / authority: LOCKED
- No new parallel system; keep legacy wiring owner unchanged unless explicitly migrated

## Audit Result (Current State)

### A. Already owner-editable now (no migration blocker)

- `StarterGui` authored shells (existing waves A-C + T289 source parity)
- `Lighting` authored object: `src/Lighting/GlobalAtmosphere.model.json`
- `ReplicatedStorage/Assets/Models/*` ghost/tool models (`.rbxm` / `.model.json`)
- `ReplicatedStorage/Assets/Animations/Ghosts/*` animation assets
- `ReplicatedStorage/Assets/GhostVisualProfiles/*` metadata profiles

### B. Runtime-generated visual still not owner-edit-first

Detected high-impact runtime visual builders:
- `src/ServerScriptService/Server/LobbySocialHub/LobbyService.lua`
  - runtime `BillboardGui`, `SurfaceGui`, `Highlight`, `PointLight`, guide facade parts
- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
  - runtime `BillboardGui`, `SurfaceGui`, `Highlight`, `PointLight`, `ParticleEmitter`
- `src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua`
  - runtime `BillboardGui`, `Highlight`, UI styling pieces
- `src/ServerScriptService/Server/ClosetHidingMechanic/Service.lua`
  - runtime `BillboardGui`, `Highlight`
- `src/ServerScriptService/Server/HidingSystem/Service.lua`
  - runtime `BillboardGui`, `Highlight`
- `src/client/ToolVisualController.client.lua`
  - runtime `SurfaceGui`, `BillboardGui`, `ViewportFrame`, `ParticleEmitter`, lights

## Migration Strategy (Wave D)

### D1 - Workspace + Lighting owner pass
- Keep runtime logic as-is.
- Move visual tuning to authored instances/attributes where safe.
- Owner edits happen directly in Studio Explorer + Properties.

### D2 - Visual template extraction for runtime UI/VFX
- Replace hardcoded `Instance.new(...)` visuals with template cloning from authored containers.
- Preserve same function call contracts and object names.

### D3 - Ghost/Tool visual shell split
- Keep behavior code.
- Externalize visual shell (billboard/labels/vfx presets/preview surface) into authored templates.

### D4 - Owner edit checkpoint
- After D2-D3 parity, owner can edit templates directly in Studio without touching Luau.

## Owner Turn Gate

`NOT YET`

Owner edit checkpoint for 1-4 is opened only after all eligible runtime visual builders are either migrated to authored templates or explicitly documented as runtime-only.

## Execution Log

### D2 World Marker Templates

Added authored template lane:
- `ReplicatedStorage.Assets.VisualTemplates.WorldMarkers.SafeZoneMarkerBillboardTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.WorldMarkers.HideSpotMarkerBillboardTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.WorldMarkers.DoorRouteGuideBillboardTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.WorldMarkers.InteractionGuideBillboardTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.WorldMarkers.TraversalGuideBillboardTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.WorldMarkers.LobbyCosmeticBillboardTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.WorldMarkers.LobbyZoneGuideBillboardTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.WorldMarkers.LobbyZoneEntryGuideBillboardTemplate`

Runtime clone-first bindings:
- `HidingSystem.Service`
- `ClosetHidingMechanic.Service`
- `MatchSystem.DoorRuntime`
- `MatchSystem.MapRuntimePatches`
- `LobbySocialHub.LobbyService`

### D2 World Surface Templates

Added authored template lane:
- `ReplicatedStorage.Assets.VisualTemplates.WorldSurfaces.LobbyGuideBoardSurfaceTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.WorldSurfaces.MapBoardSurfaceTemplate`

Runtime clone-first bindings:
- `LobbySocialHub.LobbyService`
- `MatchSystem.MapRuntimePatches`

### D3 Tool + Ghost Visual Shell Templates

Added authored template lane:
- `ReplicatedStorage.Assets.VisualTemplates.ToolVisuals.CameraScreenSurfaceTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.ToolVisuals.EMFScreenBillboardTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.ToolVisuals.ThermoScreenBillboardTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.ToolVisuals.FlashlightLocalSpotLightTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.ToolVisuals.ToolUseBurstEmitterTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.ToolVisuals.ToolUseSmokePlumeEmitterTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.ToolVisuals.ToolUseHolyHaloEmitterTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.ToolVisuals.ToolUseScanPulseEmitterTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.ToolVisuals.ToolUsePulseLightTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.GhostVisuals.StudioGhostPreviewLabelTemplate`

Runtime clone-first bindings:
- `ToolVisualController`
- `GhostSystem.Service`

### D2/D3 World Effects Templates

Added authored template lane:
- `ReplicatedStorage.Assets.VisualTemplates.WorldEffects.WorldHighlightTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.WorldEffects.WorldPointLightTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.WorldEffects.WorldSpotLightTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.WorldEffects.WorldBeamTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.WorldEffects.WorldParticleEmitterTemplate`

Runtime clone-first bindings:
- `LobbySocialHub.LobbyService`
- `MatchSystem.MapRuntimePatches`
- `FlashlightSyncSystem.Service`
- `CampfireSanityService`
- `EnvironmentalObjectRuntime`

### D4 UI Visual Template Lane (Partial)

Added authored template lane:
- `ReplicatedStorage.Assets.VisualTemplates.UI.ButtonPolishChildrenTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.UI.FloatingButtonChildrenTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.UI.PricePillChildrenTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.UI.SummaryRowTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.UI.FieldKitButtonTemplate`
- `ReplicatedStorage.Assets.VisualTemplates.UI.LobbyTrainingSupportCardTemplate`

Runtime clone-first bindings:
- `Client.UI.Main` generic button polish shell
- `Client.UI.Main` room browser float button shell
- `Client.UI.Main` field-kit button shell
- `Client.UI.Main` lobby training support-card shell
- `Client.UI.Main` price-pill shell
- `Client.UI.Main` match/result summary row shell
- `Client.UI.Main` field-kit button root creation in authored match panel

## Validation

- `python -m json.tool src/ReplicatedStorage/Assets/VisualTemplates.model.json` pass.
- `scripts/Invoke-Rojo.ps1 build default.project.json` pass.
- Active Studio verified as `PASRAHPHOBIA.rbxlx`.
- Studio Play Test pass after batch: `PlayerGui` loaded, `WorldEffects` count 5, `ToolVisuals` count 9, `GhostVisuals` count 1, then Play mode stopped.
- Studio Play Test pass after lobby billboard batch: `WorldMarkers` count 8 with `LobbyCosmeticBillboardTemplate`, `LobbyZoneGuideBillboardTemplate`, and `LobbyZoneEntryGuideBillboardTemplate`, then Play mode stopped.
- Fallback hard-delete pass: local source grep and Studio script grep show no remaining authored-visual `Instance.new("BillboardGui"|"SurfaceGui"|"Highlight"|"PointLight"|"SpotLight"|"Beam"|"ParticleEmitter")` in `ServerScriptService` + `Client`.
- Studio Play Test pass after fallback cleanup: active Studio was `PASRAHPHOBIA.rbxlx`; `VisualTemplates` runtime counts were `WorldMarkers=8`, `WorldSurfaces=2`, `ToolVisuals=9`, `GhostVisuals=1`, `WorldEffects=5`; `LogService:GetLogHistory()` had no `ClientBootstrap Start failed`, `attempt to index nil`, or missing-template warnings; Play mode stopped.
- Child fallback hard-delete follow-up pass: `HidingSystem.Service`, `ClosetHidingMechanic.Service`, `DoorRuntime`, `MapRuntimePatches`, `LobbyService`, and `GhostSystem.Service` no longer create fallback child `Frame/TextLabel/UICorner/UIStroke` for migrated templates. Missing required children now warn/skip.
- `LobbyService` compile guard fixed after hard-delete follow-up by converting zone-focus helper to method `_publishLobbyZoneFocus`; event payload and wiring unchanged.
- Studio Play Test pass after child fallback hard-delete: active Studio was `PASRAHPHOBIA.rbxlx`; source + Studio scans were clean for target fallback helpers/high-risk constructors; no target errors/warnings in `LogService`; Play mode stopped.
- Quest template extraction pass: source + Studio aktif `PASRAHPHOBIA.rbxlx` sudah memuat authored `QuestJournalGui.Panel.Templates`, `QuestTrackerGui.Templates`, dan `QuestPopupGui`; compile check `QuestJournal` + `QuestTracker` pass; Play Test pass dengan `PlayerGui` quest template/image children termuat dan tanpa warning/error `QuestJournal`/`QuestTracker` di `LogService`.
- `Client.UI.Main` authored UI template lane partial pass: source + Studio aktif `PASRAHPHOBIA.rbxlx` sudah memuat `ReplicatedStorage.Assets.VisualTemplates.UI` dengan 6 template baru; compile blocker `Out of local registers` di Studio dihindari dengan helper template berbasis method `UISystem`; Rojo sourcemap pass; Play Test single-client pass; `LogService` bersih untuk error/warning target batch; runtime `PlayerGui` memuat child authored representatif `RoomBrowserFloatButton.FloatAccent`, `RoomBrowserFloatButton.BrandBorder`, dan `RefreshButton.BrandBorder`; Play mode dihentikan.

## Runtime-Only Decisions

- `Client.UI.Main` field-kit `ToolPreview` `ViewportFrame`: runtime-only because it binds dynamic tool preview data and is nested inside authored shell containers.
- `Client.UI.Main` lobby training support-card `ToolPreview` `ViewportFrame`: runtime-only because it renders per-tool live support cards.
- `Client.UI.Main` RoomBrowser player-card `ViewportFrame`: runtime-only because it renders live player avatars with `CharacterPreviewSupport.render`.
- `Client.UI.Main` room detail player-card `ViewportFrame`: runtime-only because it renders live room members and readiness state.

These remain owner-indirect editable through their parent authored shells and data config, not direct Studio static frames.

## Deep Scan Update

- A wider owner-editable visual deep scan was run after this report.
- Result: authored world/tool templates remain valid, but final owner-edit gate is held again because dynamic UI item/card/popup builders are still present.
- Canonical follow-up report: `DOCUMENTATION/SOURCE OF TRUTH/reports/OWNER_EDITABLE_VISUAL_DEEP_SCAN_2026-05-02.md`.

## Remaining Gate Items

- Extract authored templates untuk sisa dynamic UI item/card/popup builders di `Client.UI.Main`, terutama lane shop/profile/royalpass/roombrowser row-card lanjutan.
- Re-run Rojo build and Studio Play Test before owner edit handoff.

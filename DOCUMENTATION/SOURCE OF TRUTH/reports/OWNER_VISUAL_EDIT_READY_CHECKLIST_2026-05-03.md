# Owner Visual Edit Ready Checklist - 2026-05-03

## Status

Studio aktif yang diverifikasi: `PASRAHPHOBIA.rbxlx`.

Gate owner-edit: READY.

Tujuan checklist ini adalah memberi lokasi edit manual yang aman untuk owner di Roblox Studio tanpa mengubah wiring logic runtime.

## Edit Di StarterGui

Owner boleh edit visual di `StarterGui` untuk ScreenGui berikut:

- `FlashlightToggleUI`
- `FPVCursorToggleUI`
- `JournalUI`
- `LeaderboardUI`
- `LobbyUI`
- `LobbyUXGui`
- `MainMenuUI`
- `MatchLoadingUI`
- `MatchUI`
- `MatchUXGui`
- `PASRAHPHOBIA_BottomNavbar_Static`
- `PASRA_UI`
- `ProfileUI`
- `QuestJournalGui`
- `QuestPopupGui`
- `QuestTrackerGui`
- `RoomBrowserFloatUI`
- `RoomBrowserUI`
- `RoyalPassUI`
- `SanityHUDGui`
- `SensoryHorrorHUD`
- `ShopUI`
- `SpectatorUI`
- `TeleportScreen`

Catatan edit:

- `Visible` / `Enabled` boleh dinyalakan sementara di Edit Mode untuk melihat layout.
- Saat Play Test, visibility tetap dikontrol script runtime sesuai flow game.
- Jangan rename object yang sudah dipakai contract, terutama nama Frame/Button/Template yang sudah ada.

## Edit Di VisualTemplates

Owner boleh edit template visual di `ReplicatedStorage.Assets.VisualTemplates`.

Kategori template yang sudah tersedia:

- `UI`
- `WorldMarkers`
- `WorldSurfaces`
- `ToolVisuals`
- `GhostVisuals`
- `WorldEffects`

Template penting yang sekarang menjadi source visual clone runtime:

- `UI.ButtonPolishChildrenTemplate`
- `UI.FloatingButtonChildrenTemplate`
- `UI.PricePillChildrenTemplate`
- `UI.SummaryRowTemplate`
- `UI.FieldKitButtonTemplate`
- `UI.LobbyTrainingSupportCardTemplate`
- `UI.FlatPreviewFallbackTemplate`
- `WorldMarkers.SafeZoneMarkerBillboardTemplate`
- `WorldMarkers.HideSpotMarkerBillboardTemplate`
- `WorldMarkers.DoorRouteGuideBillboardTemplate`
- `WorldMarkers.InteractionGuideBillboardTemplate`
- `WorldMarkers.TraversalGuideBillboardTemplate`
- `WorldMarkers.LobbyCosmeticBillboardTemplate`
- `WorldMarkers.LobbyZoneGuideBillboardTemplate`
- `WorldMarkers.LobbyZoneEntryGuideBillboardTemplate`
- `WorldSurfaces.LobbyGuideBoardSurfaceTemplate`
- `WorldSurfaces.MapBoardSurfaceTemplate`
- `ToolVisuals.EMFScreenBillboardTemplate`
- `ToolVisuals.ThermoScreenBillboardTemplate`
- `ToolVisuals.CameraScreenSurfaceTemplate`
- `ToolVisuals.FlashlightLocalSpotLightTemplate`
- `ToolVisuals.ToolUseBurstEmitterTemplate`
- `ToolVisuals.ToolUseSmokePlumeEmitterTemplate`
- `ToolVisuals.ToolUseHolyHaloEmitterTemplate`
- `ToolVisuals.ToolUseScanPulseEmitterTemplate`
- `ToolVisuals.ToolUsePulseLightTemplate`
- `GhostVisuals.StudioGhostPreviewLabelTemplate`
- `WorldEffects.WorldHighlightTemplate`
- `WorldEffects.WorldPointLightTemplate`
- `WorldEffects.WorldSpotLightTemplate`
- `WorldEffects.WorldBeamTemplate`
- `WorldEffects.WorldParticleEmitterTemplate`
- `WorldEffects.WorldBoxOutlineTemplate`
- `WorldEffects.WorldFireTemplate`

## Jangan Edit Sebagai Visual

Area berikut bukan target edit visual manual owner:

- Script di `StarterPlayerScripts`, `ServerScriptService`, `ReplicatedStorage` modules.
- RemoteEvents / RemoteFunctions.
- Runtime `PlayerGui` saat Play Test, karena perubahan hilang setelah stop.
- Isi runtime `ViewportFrame` seperti `WorldModel` dan `Camera`.
- Runtime transient host seperti invisible `Part`, `Attachment`, runtime sounds, prompts, dan map assembly.

## Validasi Terakhir

- Source grep target visual-builder pass.
- Studio aktif memuat semua ScreenGui dan VisualTemplates di atas.
- Play Test single-client sebelumnya pass untuk final blocker batch.
- Tidak ada active owner-editable visual blocker tersisa dari deep-scan list 2026-05-03.

## Instruksi Owner

Tahap berikutnya sudah masuk bagian owner visual edit.

Buka Roblox Studio yang aktif pada `PASRAHPHOBIA.rbxlx`, lalu edit dari:

- `StarterGui` untuk HUD, menu, browser, shop, quest, royal pass, spectator, loading, dan teleport UI.
- `ReplicatedStorage > Assets > VisualTemplates` untuk template visual yang diclone runtime ke world, tool, ghost, marker, dan UI child.

Setelah owner selesai edit, lakukan Play Test satu client untuk memastikan script runtime tetap memanggil shell/template yang sama.

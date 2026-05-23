# Owner-Editable Visual Deep Scan - 2026-05-02

## Scope

Deep scan dilakukan setelah Wave D fallback cleanup untuk memastikan tidak ada visual owner-editable yang tertinggal di runtime builder.

Update 2026-05-03:
- temuan blocker `Client.UI.Main` pada laporan ini sudah dikoreksi lagi lewat batch follow-up `OWNER_EDITABLE_VISUAL_DEEP_SCAN_ADDENDUM_2026-05-03.md`
- fokus blocker aktif tidak lagi berada di row/card lane `shop/profile/royalpass/roombrowser`, karena lane tersebut sudah authored/clone-first; blocker yang masih tersisa sekarang lebih sempit dan tercatat di addendum 2026-05-03

Scan mencakup:
- `src/client`
- `src/ServerScriptService`
- `src/StarterGui`
- `src/ReplicatedStorage/Assets/VisualTemplates.model.json`
- Studio aktif `PASRAHPHOBIA.rbxlx`

## Confirmed Editable

- `StarterGui` source berisi 21 `*.model.json` ScreenGui.
- Studio aktif berisi 22 `StarterGui` ScreenGui; tambahan Studio-only yang terdeteksi: `PASRAHPHOBIA_BottomNavbar_Static`.
- `ReplicatedStorage.Assets.VisualTemplates` aktif di Studio:
  - `WorldMarkers = 8`
  - `WorldSurfaces = 2`
  - `ToolVisuals = 9`
  - `GhostVisuals = 1`
  - `WorldEffects = 5`
- Source dan Studio script grep tetap bersih untuk authored-visual high-risk classes:
  - `BillboardGui`
  - `SurfaceGui`
  - `Highlight`
  - `PointLight`
  - `SpotLight`
  - `Beam`
  - `ParticleEmitter`

## Deep Scan Findings

Gate "semua visual owner-editable siap" ditahan lagi. Deep scan lebih luas menemukan visual builder runtime yang belum masuk template owner-editable.

### High Priority: Dynamic UI Item Templates

`src/client/UI/Main.lua` masih membuat banyak elemen visual runtime:
- field-kit button child visuals (`GlyphPlate`, labels, accent, preview shell)
- lobby training support cards
- shop item rows/cards, rarity image layer, price pill child labels
- RoyalPass/progression/stat cards
- profile/wardrobe/filter cards
- room browser room rows, invite rows, player preview cards, empty states
- generic button polish (`BrandOverlay`, `BrandStroke`, `BrandGradient`, `BrandBorder`, `BrandTextImage`)
- selection strokes

Target migrasi berikutnya:
- Buat authored item templates di `StarterGui` atau `ReplicatedStorage.Assets.VisualTemplates.UI`.
- Runtime hanya clone template dan isi data/state.
- Hapus fallback builder untuk `Frame`, `TextLabel`, `TextButton`, `ImageLabel`, `UICorner`, `UIStroke`, `UIGradient`, `UIPadding`, `UIListLayout`, `ScrollingFrame` yang seharusnya visual.

Status 2026-05-02 malam lanjut:
- Partial completed.
- Authored `ReplicatedStorage.Assets.VisualTemplates.UI` sudah ditambahkan untuk:
  - `ButtonPolishChildrenTemplate`
  - `FloatingButtonChildrenTemplate`
  - `PricePillChildrenTemplate`
  - `SummaryRowTemplate`
  - `FieldKitButtonTemplate`
  - `LobbyTrainingSupportCardTemplate`
- Source + Studio aktif `PASRAHPHOBIA.rbxlx` sudah dimirror untuk `Client.UI.Main`.
- Runtime `Client.UI.Main` sekarang clone-first untuk:
  - generic button polish / `BrandBorder` / `BrandTextImage`
  - room browser float button shell
  - field-kit button shell
  - lobby training support-card shell
  - MM/PP/Robux price-pill shell
  - match/result summary row shell
- Studio compile blocker `Out of local registers` yang sempat muncul saat mirror diperbaiki dengan memindahkan helper template menjadi method `UISystem`; wiring logic tetap sama.
- Play Test single-client pass; `LogService` tidak menemukan error/warning target batch ini, dan runtime `PlayerGui` memuat child authored representatif seperti `RoomBrowserFloatButton.FloatAccent`, `RoomBrowserFloatButton.BrandBorder`, dan `RefreshButton.BrandBorder`.
- Blocker high-priority yang tersisa sekarang menyempit ke builder item/card/popup lain di `Client.UI.Main` yang belum ikut lane template ini, terutama shop/profile/royalpass/roombrowser row-card tambahan.

### High Priority: Quest Item Templates

Status 2026-05-02 malam: completed.

Perubahan yang sudah masuk:
- `src/client/UI/QuestJournal.lua` sekarang clone-first dari `QuestJournalGui.Panel.Templates` untuk:
  - section label
  - placeholder
  - active mission card
  - completed mission card
- `src/client/UI/QuestTracker.lua` sekarang clone-first dari `QuestTrackerGui.Templates` untuk:
  - quest card
  - empty state
- completion popup sudah menjadi authored `src/StarterGui/QuestPopupGui.model.json`
- `QuestJournalGui` dan `QuestTrackerGui` sekarang punya authored `BrandTextImage` child pada tombol state yang dibutuhkan runtime
- source + Studio aktif `PASRAHPHOBIA.rbxlx` sudah disamakan

Validasi:
- compile check Studio pass untuk `StarterPlayer.StarterPlayerScripts.Client.UI.QuestJournal`
- compile check Studio pass untuk `StarterPlayer.StarterPlayerScripts.Client.UI.QuestTracker`
- Play Test pass; `PlayerGui` memuat `QuestJournalGui`, `QuestTrackerGui`, dan `QuestPopupGui` dengan child template authored
- `LogService:GetLogHistory()` tidak menemukan warning/error `QuestJournal`/`QuestTracker`

### High Priority: Child Fallback Inside Migrated World Templates

Beberapa service yang sudah clone `VisualTemplates` masih punya fallback child-builder untuk isi template bila child hilang:
- `HidingSystem.Service`
- `ClosetHidingMechanic.Service`
- `MatchSystem.DoorRuntime`
- `MatchSystem.MapRuntimePatches`
- `LobbySocialHub.LobbyService`
- `GhostSystem.Service`

Target migrasi berikutnya:
- Jika child template wajib hilang, runtime harus warn/skip, bukan membuat `Frame/TextLabel/UICorner/UIStroke` baru.
- Helper builder seperti `createMarkerTextLabel`/`createGuideTextLabel` perlu dihapus jika sudah tidak dipakai.

Status 2026-05-02 malam:
- Completed for listed world-template services.
- Source + Studio aktif `PASRAHPHOBIA.rbxlx` sudah disamakan.
- Local source grep dan Studio source scan bersih untuk helper `createMarkerTextLabel`/`createGuideTextLabel` dan authored-visual high-risk constructors di target files.
- `LobbyService` compile issue `Out of local registers` diperbaiki dengan method internal `_publishLobbyZoneFocus`, payload event tetap sama.
- Rojo sourcemap pass.
- Studio Play Test pass; `LogService:GetLogHistory()` tidak menemukan error/warning target, lalu Play mode dihentikan.

## Runtime-Only Whitelist

Yang tetap boleh runtime-only karena isinya live/data-driven dan bukan shell visual statis:
- `ViewportFrame` untuk avatar/player preview dan live tool preview.
- `WorldModel`/`Camera` di dalam `ViewportFrame`.
- invisible host `Part`/`Attachment` untuk VFX posisi transient.
- cloned character/model preview dari asset model.
- `ProximityPrompt` gameplay interaction.
- runtime `Sound` playback instance.
- runtime `Folder` container.
- map clone/runtime model assembly untuk match instance.

## Current Decision

Owner edit gate belum final. Wave D authored templates dan batch `Client.UI.Main` parsial sudah benar, tetapi deep scan membuktikan masih ada visual item/card/popup runtime lain yang perlu dimigrasi supaya owner bisa edit manual secara menyeluruh.

Next batch harus fokus ke:
1. UI item/card template extraction sisa di `Client.UI.Main` (shop/profile/royalpass/roombrowser row-card lanjutan).
2. Build + Studio Play Test ulang setelah extraction batch `Client.UI.Main`.

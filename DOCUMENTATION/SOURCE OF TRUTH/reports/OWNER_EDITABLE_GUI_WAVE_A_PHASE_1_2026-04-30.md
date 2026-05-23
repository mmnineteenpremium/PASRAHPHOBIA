# OWNER EDITABLE GUI WAVE A PHASE 1 (2026-04-30)

## Scope

Migrasi slice authored GUI pertama agar owner bisa edit visual langsung di Studio tanpa mengubah logic/state lane yang sudah aktif.

Surface yang masuk:

- `MatchLoadingUI`
- `TeleportScreen`
- `FPVCursorToggleUI`
- `FlashlightToggleUI`

## Source Changes

Shell authored baru ditambahkan ke `src/StarterGui`:

- `src/StarterGui/MatchLoadingUI.model.json`
- `src/StarterGui/TeleportScreen.model.json`
- `src/StarterGui/FPVCursorToggleUI.model.json`
- `src/StarterGui/FlashlightToggleUI.model.json`

Wiring code aktif dipindah untuk bind ke shell authored:

- `src/client/UI/Main.lua`
  - `_ensureLoadingScreen()` tidak lagi membuat `MatchLoadingUI` via `Instance.new`; sekarang hanya menerima shell authored dengan contract `Background -> ProgressTrack -> ProgressFill`.
  - `_ensureTeleportOverlay()` tidak lagi membuat `TeleportScreen`; sekarang hanya menerima shell authored dengan child `LoadingOverlay`.
- `src/client/CameraController.client.lua`
  - `ensureCursorToggleUi()` tidak lagi membuat `FPVCursorToggleUI` / `CursorToggleButton`; sekarang bind ke shell authored yang sudah disiapkan di `StarterGui`.
- `src/client/FlashlightController.client.lua`
  - `ensureToggleUI()` tidak lagi membuat `FlashlightToggleUI` / `ToggleButton`; sekarang bind ke shell authored yang sudah ada.
  - non-touch lane sekarang men-disable shell authored, bukan menghancurkan surface authored itu.

## Hard-Delete Confirmation

Builder runtime `Instance.new` untuk empat surface di atas sudah dihapus dari lane aktif. Tidak ada dual-path visible untuk:

- `MatchLoadingUI`
- `TeleportScreen`
- `FPVCursorToggleUI`
- `FlashlightToggleUI`

## Owner Edit Rules

Owner sekarang boleh edit manual secara visual di Studio untuk:

- posisi
- ukuran
- warna
- stroke/corner
- typography
- spacing

Tetapi nama contract berikut wajib dipertahankan:

- `MatchLoadingUI.Background.ProgressTrack.ProgressFill`
- `TeleportScreen.LoadingOverlay`
- `FPVCursorToggleUI.CursorToggleButton`
- `FlashlightToggleUI.ToggleButton`

Jika nama contract diubah, binding code aktif akan putus dan surface akan dianggap invalid oleh runtime.

## Verification

- `rojo build default.project.json --output .codex/tmp/startergui-wave-check.rbxlx`
  - PASS
- build source berhasil setelah shell authored baru ditambahkan.

## Next Recommended Slice

Surface berikutnya yang paling bernilai untuk owner-edit:

1. `LobbyUI`
2. `RoomBrowserUI`

Alasannya: dua surface itu memberi leverage visual terbesar untuk owner setelah shell utilitas dasar sudah hidup.

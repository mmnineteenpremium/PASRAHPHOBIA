# OWNER EDITABLE GUI WAVE A PHASE 2 - LOBBYUI (2026-04-30)

## Scope

Migrasi `LobbyUI` dari runtime-authored panel ke shell authored di `StarterGui`, sambil menjaga logic/wiring/state lane yang sama.

## Source Changes

Shell authored baru:

- `src/StarterGui/LobbyUI.model.json`

Wiring aktif berubah di:

- `src/client/UI/Main.lua`
  - tambah binder `UISystem:_bindAuthoredLobbyUi(gui)` untuk membaca contract widget canonical dari shell authored.
  - branch pembuat runtime `LobbyUI` di `_ensureBasicUIs()` sudah dihapus dari lane aktif.
  - adaptive sizing `LobbyUI` sekarang hanya dipakai untuk mobile/compact; lane desktop authored dipertahankan agar edit visual owner menempel.

## Hard-Delete Confirmation

Branch runtime lama yang dulu membuat:

- `LobbyUI`
- `HeaderCard`
- `StatusBadge`
- `PrimaryLabel`
- `SecondaryLabel`
- `ModePill`
- `MapPill`
- `RoomPill`
- `OpenRoomBrowserButton`
- `ProfileButton`
- `ShopButton`
- `RoyalPassButton`
- `MenuButton`
- `RankButton`
- `HintLabel`
- `LobbyToggleButton`

sudah dihapus dari lane aktif `Main.lua`.

## Canonical Contract

Nama widget yang wajib dipertahankan:

- `LobbyUI.MainPanel`
- `LobbyUI.MainPanel.Title`
- `LobbyUI.MainPanel.HeaderCard`
- `LobbyUI.MainPanel.HeaderCard.LobbyGlyph`
- `LobbyUI.MainPanel.HeaderCard.StatusBadge`
- `LobbyUI.MainPanel.HeaderCard.PrimaryLabel`
- `LobbyUI.MainPanel.HeaderCard.SecondaryLabel`
- `LobbyUI.MainPanel.HeaderCard.ModePill`
- `LobbyUI.MainPanel.HeaderCard.MapPill`
- `LobbyUI.MainPanel.HeaderCard.RoomPill`
- `LobbyUI.MainPanel.OpenRoomBrowserButton`
- `LobbyUI.MainPanel.ProfileButton`
- `LobbyUI.MainPanel.ShopButton`
- `LobbyUI.MainPanel.RoyalPassButton`
- `LobbyUI.MainPanel.MenuButton`
- `LobbyUI.MainPanel.RankButton`
- `LobbyUI.MainPanel.HintLabel`
- `LobbyUI.LobbyToggleButton`

## Owner Edit Status

`LobbyUI` sekarang masuk checkpoint edit owner untuk lane PC.

Artinya:

- owner boleh drag/resize/reposition `MainPanel`
- owner boleh ubah spacing, hierarchy visual, warna, border, stroke, dan tipografi
- owner boleh pindah posisi `LobbyToggleButton`

Catatan:

- untuk viewport mobile/compact, runtime masih menjalankan adaptive sizing fallback.
- untuk lane desktop PC, posisi/ukuran authored tidak lagi di-overwrite oleh sizing runtime.

## Verification

- `rojo build default.project.json --output .codex/tmp/lobbyui-wave-check.rbxlx`
  - PASS

## Recommended Next Slice

Target berikutnya sebelum owner pass besar berikutnya:

1. `RoomBrowserUI`
2. `MainMenuUI`

# OWNER EDITABLE GUI WAVE A PHASE 3 - ROOMBROWSERUI (2026-04-30)

## Scope

Migrasi `RoomBrowserUI` dan `RoomBrowserFloatUI` dari runtime-authored shell ke authored `StarterGui`, sambil menjaga logic/wiring/state lane yang sama untuk room list, room preview, invite, ready/start, password modal, dan result room controls.

## Source Changes

Shell authored baru:

- `src/StarterGui/RoomBrowserUI.model.json`
- `src/StarterGui/RoomBrowserFloatUI.model.json`

Wiring aktif berubah di:

- `src/client/UI/Main.lua`
  - tambah binder `UISystem:_bindAuthoredRoomBrowserUi(gui, floatGui)` untuk membaca contract widget canonical dari shell authored.
  - `_ensureRoomBrowserGui()` sekarang bind ke shell authored dan memakai dynamic logic lama yang sama; branch pembentuk `Instance.new` untuk shell statis `RoomBrowserUI` / `RoomBrowserFloatUI` sudah keluar dari lane aktif.
  - adaptive sizing `RoomBrowserUI` sekarang tetap hidup untuk lane mobile/compact, tetapi lane desktop PC authored dipertahankan agar edit visual owner menempel.
  - posisi float button RoomBrowser tidak lagi dipaksa oleh lobby-float-rail pada lane desktop PC; edit owner pada posisi button sekarang tetap terbaca di runtime desktop.

## Hard-Delete Confirmation

Branch runtime lama yang dulu membuat shell statis berikut lewat `Instance.new` sudah dihapus dari lane aktif `Main.lua`:

- `RoomBrowserUI`
- `RoomBrowserFloatUI`
- `Backdrop`
- `Panel`
- `RoomList`
- `RoomPreviewPanel`
- `RoomPanel`
- `PasswordModal`
- `KickNoticeModal`
- `CountdownOverlay`
- `InvitePopup`
- `RoomBrowserFloatButton`

Render dinamis yang tetap runtime-only dan memang masih dibutuhkan:

- row daftar room di `RoomList`
- card pemain preview di `RoomPreviewPanel.PlayersList`
- card pemain room di `RoomPanel.PlayersList`
- row invite di `InviteDropdown.InviteList`

## Canonical Contract

Nama widget yang wajib dipertahankan:

- `RoomBrowserUI.Backdrop.Panel`
- `RoomBrowserUI.Backdrop.Panel.CloseButton`
- `RoomBrowserUI.Backdrop.Panel.ClassicButton`
- `RoomBrowserUI.Backdrop.Panel.AllModesButton`
- `RoomBrowserUI.Backdrop.Panel.RankedButton`
- `RoomBrowserUI.Backdrop.Panel.RoomList`
- `RoomBrowserUI.Backdrop.Panel.RoomPreviewPanel.Title`
- `RoomBrowserUI.Backdrop.Panel.RoomPreviewPanel.Info`
- `RoomBrowserUI.Backdrop.Panel.RoomPreviewPanel.MapPlaceholder.MapTitle`
- `RoomBrowserUI.Backdrop.Panel.RoomPreviewPanel.MapPlaceholder.MapLabel`
- `RoomBrowserUI.Backdrop.Panel.RoomPreviewPanel.MapPlaceholder.Mood`
- `RoomBrowserUI.Backdrop.Panel.RoomPreviewPanel.MapPlaceholder.Stats`
- `RoomBrowserUI.Backdrop.Panel.RoomPreviewPanel.PlayersList`
- `RoomBrowserUI.Backdrop.Panel.JoinPassword`
- `RoomBrowserUI.Backdrop.Panel.RefreshButton`
- `RoomBrowserUI.Backdrop.Panel.CreateRoomButton`
- `RoomBrowserUI.Backdrop.Panel.QueueButton`
- `RoomBrowserUI.Backdrop.Panel.QuickJoinClassicButton`
- `RoomBrowserUI.Backdrop.Panel.QuickJoinRankedButton`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.RoomTitle`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.HostLabel`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.PlayersList`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.ModeSelector`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.ModeDropdown.ClassicOption`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.ModeDropdown.RankedOption`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.MapSelector`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.MapDropdown.MapOption_1`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.MapDropdown.MapOption_2`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.MapDropdown.MapOption_3`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.MapDropdown.MapOption_4`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.RankedTierLabel`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.MapPreview.MapImagePlaceholder.MoodChip`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.SetPasswordBox`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.SetPasswordButton`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.ReadyButton`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.StartButton`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.CancelStartButton`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.LeaveRoomButton`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.InviteButton`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.InviteDropdown.InviteList`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.KickNameBox`
- `RoomBrowserUI.Backdrop.Panel.RoomPanel.KickButton`
- `RoomBrowserUI.PasswordModal.PasswordCard.PasswordInput`
- `RoomBrowserUI.PasswordModal.PasswordCard.JoinButton`
- `RoomBrowserUI.PasswordModal.PasswordCard.CancelButton`
- `RoomBrowserUI.KickNoticeModal.KickNoticeCard.KickNoticeText`
- `RoomBrowserUI.CountdownOverlay.CountdownLabel`
- `RoomBrowserUI.CountdownOverlay.CancelCountdown`
- `RoomBrowserUI.InvitePopup.Text`
- `RoomBrowserUI.InvitePopup.AcceptButton`
- `RoomBrowserUI.InvitePopup.DeclineButton`
- `RoomBrowserFloatUI.RoomBrowserFloatButton`

## Owner Edit Status

`RoomBrowserUI` dan `RoomBrowserFloatUI` sekarang masuk checkpoint edit owner untuk lane PC.

Artinya:

- owner boleh drag/resize/reposition panel utama RoomBrowser
- owner boleh ubah layout preview map, spacing action stack, hierarchy tipografi, warna, border, stroke, dan contrast
- owner boleh ubah shell modal password / kick notice / invite popup
- owner boleh pindah posisi `RoomBrowserFloatButton` pada lane desktop PC

Catatan:

- lane mobile/compact tetap memakai adaptive sizing runtime.
- row dinamis di daftar room / player list / invite list tetap runtime-generated, jadi yang owner edit adalah shell container dan styling authored-nya, bukan clone row hasil runtime.

## Verification

- `rojo build default.project.json --output .codex/tmp/roombrowser-authored-check.rbxlx`
  - PASS
- `scripts/release-preflight.ps1 -Json -CanonicalPlaceOutput ''`
  - PASS

## Recommended Next Slice

Target berikutnya sebelum owner pass besar berikutnya:

1. `MainMenuUI`
2. `LeaderboardUI`

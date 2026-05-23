# UI Icon Asset Registry

Tanggal: 2026-05-04
Source input: `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\UI\icons\asset-id-icon.txt`

Registry source runtime: `src/shared/GameData/UIIconAssets.lua`

## Status

- Asset icon dari file owner sudah dimasukkan ke registry source dan Studio aktif `PASRAHPHOBIA.rbxlx`.
- `SettingsWindow` sekarang punya `OwnerRowIcon` pada 13 settings row.
- Toggle settings row sekarang punya `ToggleOn`, `ToggleOff`, dan `ToggleDisabled` beserta `StateIcon`.
- Logic settings tetap memakai `OwnerSettingsLauncher`; perubahan ini visual binding saja.

## Missing / Tidak Dipakai Dulu

- `PASSWORD_ON` masih `NOT_FOUND` di file input, jadi belum bisa dipakai.
- `EMF_READER_ON` masih `NOT_FOUND` di file input, tidak masuk kebutuhan settings saat ini.
- Existing text-image button lama seperti close, refresh, create room, room actions, lobby buttons, quest buttons, dan flashlight/cursor toggle tidak diganti dulu karena state lama sudah sehat.

## Boleh Diedit Owner

- `StarterGui > PASRAHPHOBIA_BottomNavbar_Static > Windows > SettingsWindow > SettingsContent > *Section > *Row > OwnerRowIcon`
- `StarterGui > PASRAHPHOBIA_BottomNavbar_Static > Windows > SettingsWindow > SettingsContent > *Section > *Row > ToggleOn > StateIcon`
- `StarterGui > PASRAHPHOBIA_BottomNavbar_Static > Windows > SettingsWindow > SettingsContent > *Section > *Row > ToggleOff > StateIcon`
- `StarterGui > PASRAHPHOBIA_BottomNavbar_Static > Windows > SettingsWindow > SettingsContent > *Section > *Row > ToggleDisabled > StateIcon`

## Jangan Diedit / Rename

- Jangan rename `OwnerRowIcon`, `StateIcon`, `ToggleOn`, `ToggleOff`, atau `ToggleDisabled`.
- Jangan hapus `UIIconAssets` karena `OwnerSettingsLauncher` sekarang membaca icon dari registry itu.
- Jangan aktifkan `PASRAHPHOBIA_BottomNavbar_Static.BottomNav` atau `FloatingUI` sebagai nav runtime.

## DoD

- Play Test tidak error pada `UIIconAssets` dan `OwnerSettingsLauncher`.
- Settings window bisa dibuka.
- Row settings menampilkan icon.
- Toggle row tetap berubah `ON/OFF` sesuai state runtime.

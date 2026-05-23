# UI Surface Ownership Matrix

Tanggal: 2026-05-04  
File Studio wajib: `PASRAHPHOBIA.rbxlx`  
Status: decision matrix awal, bukan instruksi delete

Dokumen ini mengunci arah UI agar tidak ada surface yang dianggap duplicate tanpa alasan. Prinsipnya: **jangan hapus UI hanya karena terlihat overlap**. Setiap surface harus punya status, tujuan, pemilik logic, dan keputusan sementara.

## Status Legend

- `PRIMARY`: surface utama pada fase game tertentu.
- `GLOBAL`: akses global yang boleh tampil lintas fase jika tidak mengganggu.
- `FEATURE PANEL`: panel fitur spesifik, hanya muncul saat dipanggil.
- `RUNTIME HUD`: muncul karena state gameplay/runtime.
- `FLOW OVERLAY`: muncul saat transisi, loading, result, atau popup.
- `REFERENCE ONLY`: hanya referensi visual, tidak boleh dianggap runtime utama.
- `HOLD`: jangan hapus; belum final, perlu keputusan desain/flow.
- `DELETE CANDIDATE`: boleh dipertimbangkan hapus hanya setelah audit wiring dan approval owner.

## Keputusan Utama

- `LobbyUI` adalah primary hub lobby.
- `OwnerSettingsLauncher` adalah entry global settings kanan atas.
- `PASRAHPHOBIA_BottomNavbar_Static` bukan bottom nav runtime final; hanya `Windows.SettingsWindow` yang dipakai runtime.
- `MainMenuUI` tidak boleh dihapus dulu; statusnya `HOLD` sampai diputuskan apakah game butuh title/menu screen sebelum lobby.
- `RoomBrowserFloatUI` tidak boleh dihapus dulu; statusnya `HOLD` sampai diputuskan apakah masih butuh shortcut floating selain `LobbyUI`.
- Semua feature panel tetap dipertahankan karena mereka mewakili fitur terpisah.
- Semua runtime HUD/overlay tetap dipertahankan karena dipanggil berdasarkan fase game.

## Surface Matrix

| Surface | Status | Tujuan Final | Kapan Muncul | Owner Logic | Keputusan |
|---|---|---|---|---|---|
| `LobbyUI` | `PRIMARY` | Hub utama lobby: room browser, profile, shop, royal pass, menu/rank entry | Saat player berada di lobby normal | `Client.UI.Main` / runtime lobby UI | Aktif, jangan hapus |
| `OwnerSettingsLauncher` | `GLOBAL` | Tombol settings fixed kanan atas | Lintas lobby/match jika tidak mengganggu | `OwnerSettingsLauncher.lua` | Aktif, boleh edit visual |
| `PASRAHPHOBIA_BottomNavbar_Static` | `REFERENCE ONLY + SETTINGS HOST` | Referensi visual owner dan host `Windows.SettingsWindow` | ScreenGui aktif untuk host window; `BottomNav`/`FloatingUI` hidden | `OwnerSettingsLauncher.lua` untuk Settings window | Jangan hapus; jangan aktifkan bottom nav sebagai nav runtime |
| `RoomBrowserUI` | `FEATURE PANEL` | Browse/create/join/leave room | Saat dibuka dari lobby/menu/shortcut | Room browser runtime dalam `Client.UI.Main` | Aktif sebagai panel, jangan hapus |
| `RoomBrowserFloatUI` | `HOLD` | Shortcut floating ke Room Browser jika dibutuhkan | Belum final; bisa redundant dengan `LobbyUI` | `Client.UI.Main` | Jangan hapus dulu; putuskan setelah UX nav final |
| `MainMenuUI` | `HOLD` | Calon title/main menu atau overlay menu | Belum final; overlap dengan `LobbyUI` | `Client.UI.Main` | Jangan hapus dulu; perlu keputusan apakah ada title screen |
| `ShopUI` | `FEATURE PANEL` | Shop/catalog/currency/reward purchase surface | Saat player membuka shop | `Client.UI.Main` / shop runtime | Pertahankan |
| `RoyalPassUI` | `FEATURE PANEL` | Royal pass progression/reward panel | Saat player membuka royal pass | `Client.UI.Main` / royal pass runtime | Pertahankan |
| `ProfileUI` | `FEATURE PANEL` | Profile, stats, wardrobe/progression identity | Saat player membuka profile | `Client.UI.Main` / profile runtime | Pertahankan |
| `LeaderboardUI` | `FEATURE PANEL` | Leaderboard/rank view | Saat player membuka leaderboard/rank | `Client.UI.Main` | Pertahankan |
| `JournalUI` | `FEATURE PANEL` | Journal/evidence/history style panel | Saat player membuka journal | `Client.UI.Main` | Pertahankan |
| `QuestJournalGui` | `FEATURE PANEL` | Quest journal detail/tabbed quest UI | Saat player membuka quest journal | `QuestJournal.lua` | Pertahankan |
| `QuestTrackerGui` | `RUNTIME HUD` | Quest tracker compact | Saat quest tracking aktif | `QuestTracker.lua` | Pertahankan |
| `QuestPopupGui` | `FLOW OVERLAY` | Popup quest complete/update | Saat quest event terjadi | `QuestTracker.lua` / quest runtime | Pertahankan |
| `MatchUI` | `RUNTIME HUD` | Match HUD: objectives, tools, match status | Saat match/preparation/investigation | `Client.UI.Main` | Pertahankan |
| `MatchUXGui` | `RUNTIME HUD` | Match UX layer/result/support HUD | Saat match/result state | `Client.UI.Main` | Pertahankan |
| `MatchLoadingUI` | `FLOW OVERLAY` | Loading/transisi match | Saat teleport/transisi match | runtime loading flow | Pertahankan |
| `TeleportScreen` | `FLOW OVERLAY` | Fullscreen teleport/loading overlay | Saat teleport/loading | teleport/loading runtime | Pertahankan |
| `SanityHUDGui` | `RUNTIME HUD` | Sanity bar/vignette HUD | Saat sanity HUD aktif | sanity/HUD runtime | Pertahankan; bisa controlled by Settings |
| `SensoryHorrorHUD` | `RUNTIME HUD` | Vignette/horror sensory overlay | Saat horror/sanity/effect runtime aktif | `HorrorHUD.luau` | Pertahankan |
| `SpectatorUI` | `RUNTIME HUD` | Spectator UI and overlays | Saat spectator/death state | `SpectatorEffects` / spectator runtime | Pertahankan |
| `LobbyUXGui` | `RUNTIME HUD / ONBOARDING` | Lobby training/support/evidence onboarding | Saat lobby training/evidence support aktif | `Client.UI.Main` / Lobby UX runtime | Pertahankan; bukan duplicate nav |
| `PASRA_UI` | `FEATURE PANEL / HOLD` | PASRA brand/system panel; fungsi final perlu dikunci | Saat dipanggil feature terkait | `Client.UI.Main` | Hold, jangan hapus sampai flow PASRA final jelas |
| `FlashlightToggleUI` | `RUNTIME HUD / TOOL SHORTCUT` | Toggle flashlight mobile/desktop shortcut | Saat relevant tool/input mode aktif | flashlight/input runtime | Pertahankan |
| `FPVCursorToggleUI` | `RUNTIME HUD / INPUT SHORTCUT` | Toggle cursor/FPV control | Saat relevant input mode aktif | cursor/input runtime | Pertahankan |

## Navigation Model Final Yang Disarankan

`LobbyUI` menjadi pusat navigasi utama di lobby.

Global:

- Settings: `OwnerSettingsLauncher`.

Lobby feature entries:

- Room Browser: dari `LobbyUI`.
- Profile: dari `LobbyUI`.
- Shop: dari `LobbyUI`.
- Royal Pass: dari `LobbyUI`.
- Leaderboard/Rank: dari `LobbyUI`.
- Quest Journal: dari quest tracker/open button jika tetap nyaman.

Hold decision:

- `MainMenuUI` hanya dipakai jika ada title/menu screen sebelum lobby.
- `RoomBrowserFloatUI` hanya dipakai jika setelah playtest terbukti player butuh shortcut room browser yang selalu terlihat.
- `PASRA_UI` perlu diputuskan apakah ini fitur brand/system panel atau hanya legacy.

## Delete Policy

Tidak ada surface pada matrix ini yang boleh dihapus langsung.

Syarat sebelum suatu UI boleh menjadi `DELETE CANDIDATE`:

- grep/source audit tidak ada script yang mencari nama surface itu.
- Studio Play Test membuktikan flow tetap jalan tanpa surface tersebut.
- owner menyetujui secara eksplisit.
- `TASK_ACTIVE.md` mencatat alasan delete.
- jika surface punya visual unik yang mungkin berguna, pindahkan dulu ke reference/asset archive, bukan delete langsung.

## Hide Policy

Untuk UI yang overlap tetapi belum final:

- default `Enabled=false` atau `Visible=false`.
- jangan rename.
- jangan delete.
- jangan duplicate dengan nama baru.
- tulis alasan `HOLD` di dokumen ini.

## Current Runtime Visibility Baseline

Baseline Studio aktif terakhir:

- `LobbyUI`: default `Enabled=true`.
- `OwnerSettingsLauncher`: default `Enabled=true`, `IgnoreGuiInset=false`.
- `PASRAHPHOBIA_BottomNavbar_Static`: default `Enabled=true`, tetapi `BottomNav` dan `FloatingUI` hidden; dipakai untuk host `Windows.SettingsWindow`.
- `QuestTrackerGui`, `QuestPopupGui`, `SanityHUDGui`: default aktif karena runtime/HUD standby.
- Panel fitur lain default disabled sampai dipanggil.

## Owner Edit Guidance

Owner boleh mengedit visual semua surface yang statusnya bukan protected script. Namun untuk surface `HOLD`, edit visual boleh dilakukan, tetapi jangan mengubah arah fungsi sebelum status final diputuskan.

Prioritas edit owner yang paling aman:

1. `LobbyUI`
2. `RoomBrowserUI`
3. `OwnerSettingsLauncher`
4. `PASRAHPHOBIA_BottomNavbar_Static.Windows.SettingsWindow`
5. `ShopUI`
6. `RoyalPassUI`
7. `ProfileUI`
8. `QuestJournalGui` / `QuestTrackerGui`
9. Runtime HUD match/spectator/sanity setelah panel lobby stabil

## Open Decisions

- Apakah `MainMenuUI` akan menjadi title screen final sebelum lobby?
- Apakah `RoomBrowserFloatUI` masih dibutuhkan setelah `LobbyUI` jelas?
- Apa fungsi final `PASRA_UI`?
- Apakah quest journal dibuka dari `LobbyUI`, tracker, atau dedicated shortcut?
- Apakah `FlashlightToggleUI` dan `FPVCursorToggleUI` tampil hanya mobile, hanya desktop, atau adaptif?

## DoD UI Direction Pass

UI direction dianggap pass jika:

- setiap `StarterGui` punya status di matrix.
- tidak ada surface runtime yang muncul tanpa konteks.
- tidak ada duplicate nav yang aktif bersamaan tanpa tujuan.
- feature panel hanya muncul saat dipanggil.
- runtime HUD hanya muncul di fase yang benar.
- reference visual tidak ikut menjadi navigasi runtime.
- delete hanya terjadi setelah audit dan approval owner.

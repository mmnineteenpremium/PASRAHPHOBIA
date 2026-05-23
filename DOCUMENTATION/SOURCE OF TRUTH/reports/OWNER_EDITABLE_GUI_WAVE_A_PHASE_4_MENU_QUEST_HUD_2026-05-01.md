# OWNER-EDITABLE GUI WAVE A PHASE 4 MENU QUEST HUD - 2026-05-01

## Scope

- `MainMenuUI`
- `LeaderboardUI`
- `QuestTrackerGui`
- `QuestJournalGui`
- `SanityHUDGui`

## Goal

- pindahkan shell visual lima surface Wave A tersisa ke `src/StarterGui` supaya owner dapat edit langsung di Studio.
- pertahankan wiring logic, state ownership, remote flow, dan refresh runtime lama.
- hapus jalur builder shell runtime aktif untuk surface yang sudah dimigrasikan; jangan tinggalkan duplicate visible builder.

## Source Changes

- tambah shell authored:
  - `src/StarterGui/MainMenuUI.model.json`
  - `src/StarterGui/LeaderboardUI.model.json`
  - `src/StarterGui/QuestTrackerGui.model.json`
  - `src/StarterGui/QuestJournalGui.model.json`
  - `src/StarterGui/SanityHUDGui.model.json`
- `src/client/UI/Main.lua`
  - tambah binder `UISystem:_bindAuthoredBasicWindowUi(guiName, gui)` untuk `MainMenuUI` dan `LeaderboardUI`
  - `_ensureBasicUIs()` sekarang bind ke shell authored untuk dua surface itu, bukan lagi membuat shell panel/float via runtime branch
  - float rail desktop tidak lagi memaksa posisi `MainMenuFloatButton` dan `LeaderboardFloatButton`
  - sizing desktop tidak lagi meng-overwrite authored PC layout dua surface itu
- `src/client/UI/QuestTracker.lua`
  - `BuildUI()` sekarang bind ke `QuestTrackerGui` authored
  - desktop authored layout dipreservasi; compact/mobile override tetap hidup
- `src/client/UI/QuestJournal.lua`
  - `BuildUI()` sekarang bind ke `QuestJournalGui` authored
  - desktop authored layout dipreservasi; compact/mobile override tetap hidup
- `src/client/UI/SanityHUD.lua`
  - `BuildUI()` sekarang bind ke `SanityHUDGui` authored

## Canonical Widget Contracts

- `MainMenuUI.MainPanel.RoomBrowserButton`
- `MainMenuUI.MainPanel.ProfileButton`
- `MainMenuUI.MainPanel.ShopButton`
- `MainMenuUI.MainPanel.RankButton`
- `MainMenuUI.MainPanel.GraphicsButton`
- `MainMenuUI.MainMenuFloatButton`
- `LeaderboardUI.MainPanel.ContentFrame.ContentText`
- `LeaderboardUI.MainPanel.ProfileButton`
- `LeaderboardUI.MainPanel.RoomBrowserButton`
- `LeaderboardUI.MainPanel.MenuButton`
- `LeaderboardUI.LeaderboardFloatButton`
- `QuestTrackerGui.QuestContainer.Header`
- `QuestTrackerGui.QuestContainer.CollapseButton`
- `QuestTrackerGui.ReopenButton`
- `QuestJournalGui.OpenButton`
- `QuestJournalGui.Panel.Header`
- `QuestJournalGui.Panel.TabBar.STORYTab`
- `QuestJournalGui.Panel.TabBar.DAILYTab`
- `QuestJournalGui.Panel.TabBar.WEEKLYTab`
- `QuestJournalGui.Panel.Content`
- `SanityHUDGui.Container.Bar.Fill`
- `SanityHUDGui.Container.ValueLabel`
- `SanityHUDGui.SanityVignette`

## Owner Edit Checkpoint

- owner sekarang bisa edit langsung di Studio:
  - `StarterGui > MainMenuUI`
  - `StarterGui > LeaderboardUI`
  - `StarterGui > QuestTrackerGui`
  - `StarterGui > QuestJournalGui`
  - `StarterGui > SanityHUDGui`
- lane PC sekarang tidak lagi dioverwrite untuk layout desktop `MainMenuUI` dan `LeaderboardUI`
- lane compact/mobile override tetap aktif untuk `QuestTrackerGui` dan `QuestJournalGui`

## Known Limits

- `RoomBrowserUI` rows, `QuestTracker` mission cards, `QuestJournal` mission cards, dan popup completion quest masih runtime-generated.
- surface itu belum jadi template authored terpisah pada slice ini; owner masih mengedit shell/container utama dulu.

## Validation

- semua file `src/StarterGui/*.model.json` parse bersih via `ConvertFrom-Json`
- `pwsh -NoLogo -File scripts/Invoke-Rojo.ps1 build default.project.json --output .codex/tmp/owner-editable-wave-a-phase4.rbxlx`
- `pwsh -NoLogo -File scripts/release-preflight.ps1 -Json -CanonicalPlaceOutput ''`
- hasil preflight:
  - `buildOk: true`
  - `missingReports: []`
  - blocker resmi tetap hanya `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Next

- lanjut Wave B:
  - `ProfileUI`
  - `ShopUI`
  - `RoyalPassUI`
  - `PASRA_UI`
  - `SpectatorUI`

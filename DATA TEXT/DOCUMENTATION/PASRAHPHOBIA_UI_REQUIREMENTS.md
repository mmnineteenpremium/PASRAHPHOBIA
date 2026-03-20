# PASRAHPHOBIA - UI REQUIREMENTS

This document consolidates explicit UI requirements from project documentation and structure.

## Global Rules
- Server authoritative. Client handles only UI, audio, visual, and player input. (Source: `PASRAHPHOBIA_DOC_INDEX.txt`)
- UI systems are client-side modules. (Source: `PASRAHPHOBIA_DOC_INDEX.txt`)

## Required UI Modules and Models (by Project Structure)
Client UI module folders must exist under `src/client/UI`:
- `JournalUI`
- `LobbyUI`
- `MatchUI`
- `ProfileUI`
- `ShopUI`
- `RoyalPassUI`

Starter GUI models must exist under `src/StarterGui`:
- `LeaderboardUI.model.json`
- `LobbyUI.model.json`
- `MainMenuUI.model.json`
- `MatchUI.model.json`
- `PASRA_UI.model.json`
- `ShopUI.model.json`
- `SpectatorUI.model.json`

Source: `STRUKTUR FOLDER.txt`

## Lobby UI Requirements
- Lobby must include a Contract Board display: contracts are shown on the Contract Board inside the Lobby Social Hub. (Source: `PASRAHPHOBIA_DOC_INDEX.txt`)
- Room Board UI must be created for the lobby flow. (Source: `PASRAHPHOBIA_AI_MASTER_CONTEXT.txt`)

## Journal UI Requirements
- Evidence deduction flow ends in `JournalUI`. It must display evidence mapping results for ghost identification. (Source: `PASRAHPHOBIA_DOC_INDEX.txt`)

## Spectator UI Requirements
- Spectator system is client-only for dead players; modules include `SpectatorCamera`, `SpectatorDistortionSystem`, `SpectatorTargetSwitch`, and `DeathMessageUI`. (Source: `PASRAHPHOBIA_DOC_INDEX.txt`)
- No hint system, no spectator UI clue, no spectator markers, and no spectator message system. (Source: `PASRAHPHOBIA_DOC_INDEX.txt`)

## Death Notice UI Requirements
When a player dies, a death notice UI must appear:
- Text (center screen, 5 seconds):
  - "Kematian menipumu,"
  - "yang kamu lihat belum tentu benar"
- After 5 seconds, the notice moves to the left and remains small until endgame.

Source: `PASRAHPHOBIA_DOC_INDEX.txt`

## Warning UI for Living Players
When a teammate dies, a warning UI must appear:
- Text (center screen, 5 seconds):
  - "Jangan terlalu percaya orang mati"
  - "Gunakan instingmu"

Source: `PASRAHPHOBIA_DOC_INDEX.txt`


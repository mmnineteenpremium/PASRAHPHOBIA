# OWNER-EDITABLE GUI QUEST OVERRIDE CLEANUP

Date: 2026-05-01
Owner context: Miftah
Lane: visual-only / authored GUI
Batch: T280

## Goal

Close the remaining authored-shell geometry overrides found after the broader single-owner responsive lock.

## Scope

- `src/client/UI/QuestJournal.lua`
- `src/client/UI/QuestTracker.lua`

## Execution

- Added the same authored-owner layout preservation rule to `QuestJournal` and `QuestTracker`.
- Runtime compact/mobile geometry for the authored quest shells is now bypassed on the active owner-edit lane.
- Runtime behavior such as visibility, data refresh, and mission-card generation remains unchanged.

## Result

- `QuestJournalGui` no longer repositions/resizes its authored shell during the active owner-edit lane.
- `QuestTrackerGui` no longer repositions/resizes its authored shell during the active owner-edit lane.
- The remaining quest popup completion widget is intentionally kept runtime-only because it is a transient notification, not the main authored shell.

## Verification

- `scripts/release-preflight.ps1 -Json -CanonicalPlaceOutput ''`
  - `buildOk: true`
  - `missingReports: []`

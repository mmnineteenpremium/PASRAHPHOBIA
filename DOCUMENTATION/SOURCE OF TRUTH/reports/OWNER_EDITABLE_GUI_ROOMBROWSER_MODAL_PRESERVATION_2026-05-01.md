# OWNER-EDITABLE GUI ROOMBROWSER MODAL PRESERVATION

Date: 2026-05-01
Owner context: Miftah
Lane: visual-only / authored GUI
Batch: T282

## Goal

Stop runtime viewport-driven geometry from overriding authored RoomBrowser modal shells.

## Scope

- `src/client/UI/Main.lua`
- `RoomBrowserUI` authored modal shells:
  - `PasswordModal`
  - `KickNoticeModal`
  - `InvitePopup`

## Execution

- Added authored-owner layout lock guards to:
  - `updatePasswordModalLayout()`
  - `updateKickNoticeLayout()`
  - `updateInvitePopupLayout()`

## Result

- Authored RoomBrowser modal and popup layout is now preserved during the owner-edit lane.
- Runtime still controls visibility and dynamic invite payload text, but no longer owns modal shell geometry.

## Verification

- `scripts/release-preflight.ps1 -Json -CanonicalPlaceOutput ''`
  - `buildOk: true`
  - `missingReports: []`

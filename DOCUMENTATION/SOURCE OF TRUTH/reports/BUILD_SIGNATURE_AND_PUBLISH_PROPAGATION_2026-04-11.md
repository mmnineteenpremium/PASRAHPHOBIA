# Build Signature And Publish Propagation - 2026-04-11

## Summary
- Added a visible UI build signature so runtime devices can prove whether they loaded the latest UI build.
- Signature token locked for this patch: `PHB-20260411-UI1`.
- The signature is now surfaced in three places:
  - lobby hint text
  - quick menu footer
  - room browser status line
- The same token is also written as the `PasrahBuildSignature` attribute on the relevant UI instances.

## Source Changes
- File changed: `src/client/UI/Main.lua`
- Inserted constant:
  - `local UI_BUILD_SIGNATURE = "PHB-20260411-UI1"`
- Inserted helpers:
  - `pasrahGetBuildSignatureText()`
  - `pasrahAppendBuildSignature(text, separator)`
- Applied in runtime refresh paths:
  - `_refreshBasicLobbyPanel()`
  - `_refreshMainMenuPanel()`
  - `_refreshRoomBrowserView()`

## Verification
- Local source contains the signature token and attributes.
- Active Studio session attached to the published place also contains the same token and updated UI text wiring.
- `release-preflight.ps1` remains green after the patch:
  - `Build ok: True`
  - `Missing reports: 0`
  - `Safe items missing ID: 0`
  - `Safe items disabled: 0`
  - `Hold items enabled: 0`

## Publish Propagation Finding
- Official Roblox docs do not describe a generic moderation/review delay for publishing a new version of an already public experience.
- The documented blockers are account/compliance requirements for making a new or existing public experience update eligible.
- Official docs also explicitly recommend restarting servers when changing the start place of a live experience.
- Inference for this project:
  - if iPhone still shows the older UI after the script in the attached cloud Studio is already updated, the likely cause is runtime propagation or the player landing in an older live server, not missing source changes.

## Canonical Next Publish Path
1. Use the Studio session attached to `PlaceId=113010869463813`.
2. Confirm the UI script in that session still contains `PHB-20260411-UI1`.
3. Publish from that attached Studio session.
4. Force-close Roblox on both iPhones.
5. Rejoin from the experience page and verify the visible build signature on-device.

# Visual Batch T2 Continuation 2026-04-24

## Scope

- Continue from `VISUAL_BATCH_T_SMOKE_2026-04-24.md` blocker state.
- Recover publish lane if Open Cloud endpoint is ready.
- Revalidate mobile lane readiness using current device mapping (not legacy emulator aliases).

## Runtime Environment

- Date: 2026-04-24 (Asia/Bangkok)
- Workspace lane: `final-source-of-truth`
- Active publish target:
  - `placeId=113010869463813`
  - `universeId=9802743087`

## What Was Executed

1. Build integrity and gate check:
   - `pwsh -NoLogo -File scripts/release-preflight.ps1 -Json`
   - Result: `buildOk=true`
2. Mobile lane deep check:
   - `adb devices -l` -> detected `266a038c0a017ece model:SM_N960U state=device`
   - `mobile_list_available_devices` -> detected Android device `SM-N960U` (`266a038c0a017ece`)
3. Resolver alignment patch:
   - Updated `scripts/resolve-mobile-mcp-stack.ps1` to canonical lane `Samsung-N960` and model-prefix matching.
   - Legacy hardcoded alias requirement (`Samsung-NOTE10`, `S22-ultra`) removed as strict requirement.
4. Mobile strict revalidation after patch:
   - `pwsh -NoLogo -File scripts/resolve-mobile-mcp-stack.ps1 -Strict`
   - Result: `ready=true`, alias resolved `Samsung-N960`
5. Publish retry continuation:
   - Open Cloud upload retried with staged backoff
   - Attempt 1: `400 Bad request`
   - Attempt 2: success (`exit code 0`)
6. Android single-client smoke (runtime reachability):
   - `mobile_launch_app` -> `com.roblox.client`
   - Opened publish page `https://www.roblox.com/games/113010869463813`
   - Entered PASRAHPHOBIA runtime and reached lobby surface (`LOBBY PANEL`, `OPEN ROOM BROWSER`, `MISSION`, `TRACKER` visible)
   - Evidence: `.codex/evidence/mobile-smoke-2026-04-24/android_n960_pasrah_lobby_t2.png`

## Observations

- Previous mobile blocker from strict resolver was a script-level false-negative caused by stale legacy alias assumptions.
- Current Android lane is available and script-validated as ready.
- Android runtime smoke confirms the publish target is reachable from `SM-N960U` and loads lobby UI surface.
- Publish lane endpoint instability is still intermittent, but upload succeeded in this continuation run.

## Current Blockers

- Cross-device lane `both` remains blocked by missing iOS device availability in this session (`iPhone-14-Pro-Max` not detected).

## Status

- Android mobile lane: `READY`
- Android single-client smoke to PASRAHPHOBIA lobby: `PASS`
- Publish lane: `RECOVERED (session success on retry attempt 2)`
- Cross-device parity (Android + iOS): `BLOCKED (iOS unavailable in current session)`

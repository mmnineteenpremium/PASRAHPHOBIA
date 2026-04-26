# Runtime Authored Lock Hardening 2026-04-26

## Scope

- Enforce runtime spawn authority to authored preparation spawn area only.
- Remove active synthetic/recreate spawn lane from runtime patch flow.
- Add fail-fast runtime validation before teleport.

## Files Changed

- `src/ServerScriptService/Server/MatchSystem/MapRuntimePatches.lua`
- `src/ServerScriptService/Server/MatchSystem/MatchTeleport.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`

## Change Summary

1. `MapRuntimePatches.patchPreparationStaging` now runs strict-authored flow only:
   - requires authored `Runtime.PreparationStagingRuntime.PreparationSpawnArea`
   - tags authored spawn nodes with `PasrahPreparationSpawn=true`
   - removes legacy `SpawnPoints` folder from map clone
   - validates entry door source (`PasrahPreparationAdvanceDoor`)
   - validates authored runtime boundary presence
   - sets strict runtime debug markers:
     - `PreparationStagingRuntimePatched=true`
     - `PreparationStagingRuntimeDebug=strict_native_runtime_authoritative`

2. Removed active fallback wiring from apply lane:
   - scaffold fallback calls removed from `MapRuntimePatches.Apply`
   - spawn override apply call removed from `MapRuntimePatches.Apply`
   - runtime mainfloor/boundary fallback apply calls removed from `MapRuntimePatches.Apply`
   - legacy spawn override payload (`PlayerSpawn_*`) removed from active config.

3. `MatchTeleport` now fail-fast validates authored runtime before teleport:
   - hard validation for canonical maps:
     - strict patch marker
     - strict debug marker
     - boundary source/authored boundary parts
     - canonical preparation entry door exists and tagged
   - authored boundary resolver now accepts canonical boundary folders under runtime tree, including:
     - `Runtime.MapBoundaryRuntime`
     - `Runtime.RuntimeBoundary`
     - `Runtime.OutdoorBaseplateRuntime.Boundary_*` (when those folders contain `BasePart` descendants)
   - if validation fails, teleport flow aborts with explicit runtime error.

4. Removed direct CFrame teleport fallback branch in player teleport loop:
   - if `safeTeleportCharacter` fails, player is skipped and traced as `teleport_failed`
   - no direct fallback CFrame assignment branch retained.

## Verification

- `scripts/release-preflight.ps1 -Json`:
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending Operational Closure

- `smoke test 2 client nyata` tetap dibutuhkan untuk verifikasi end-to-end runtime behavior pada active device lane, dan eksekusinya berada di owner/user lane.

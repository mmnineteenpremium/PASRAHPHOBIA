# Visual Batch T269 ToolVisual Mount CFrame Normalization 2026-04-30

## Scope

- Fix live tool/hand visual runtime issue found in the active `PASRAHPHOBIA.rbxlx` Studio gameflow.
- Normalize tool mount `cframe` specs so serialized table offsets and native `CFrame` offsets resolve identically.
- Keep the existing tool/hand visual parity lane intact without adding a new system.

## Files Changed

- src/client/ToolVisualController.client.lua
- DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md
- DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md
- DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md

## Change Summary

1. Mount-spec normalization:
   - Added normalization for tool mount specs before runtime world-space multiplication.
   - Serialized table-form `cframe` offsets are converted into usable `CFrame` data before they reach mount resolution.

2. Live runtime recovery:
   - Removes the previously observed live error `invalid argument #2 (Vector3 expected, got table)` from the active tool visual lane.
   - Keeps existing mount/pose behavior in the same runtime path instead of splitting into a new lane.

3. Scope guard:
   - No new gameplay, economy, reward, or match-authority behavior.
   - Purely a repair inside the active tool/hand visual presentation lane.

## Verification

- Verified in the active `PASRAHPHOBIA.rbxlx` through a live Studio run covering lobby -> room browser -> staging -> tool/journal interaction.
- `LogService:GetLogHistory()` no longer returned the prior ToolVisualController mount error in the exercised path.
- Full `scripts/release-preflight.ps1 -Json -CanonicalPlaceOutput ''` passed after source sync.

## Pending

- Owner validates tool/hand pose continuity on real multi-client smoke when that lane is reopened.
- Owner executes manual 2-client smoke.

# Visual Batch T Smoke 2026-04-24

## Scope

- Validate visual tool lane after Batch T:
  - global non-map tool resizing readability
  - right/left hand mounting readability
  - tool-use VFX readability
- Keep acceptance human-visual first (not log-only).

## Runtime Environment

- Date: 2026-04-24 (Asia/Bangkok)
- Workspace lane: `final-source-of-truth`
- Studio MCP: attached to `PASRAHPHOBIA` instance
- Validation mode: Studio Play smoke with runtime harness (visual staging)

## What Was Executed

1. Build integrity pre-check:
   - `scripts/release-preflight.ps1 -Json`
   - Result: `buildOk=true`
2. Runtime visual harness in Studio Play:
   - `Workspace.PasrahVisualBatchTTest.ToolResizeGridSky`
   - `Workspace.PasrahVisualBatchTTest.HandMountStageSky`
3. Captured visual evidence from the harness.

## Visual Evidence Captures

- `BatchT_ToolResizeGridSky_15_NoLabels`
  - Purpose: global resized tool grid readability.
- `BatchT_ProxyHandStageSky_11_Close`
  - Purpose: right/left hand mounting readability.
- `BatchT_ProxyHandStageSky_13_VFXRate`
  - Purpose: use VFX burst readability.

## Observations

- Tool models are no longer visually extreme in size in the staged grid.
- Right-hand and left-hand mounting offsets are visually distinguishable in staged proxy mounts.
- Use VFX bursts are visible around mounted tools in staged validation.

## Lane Limitations During This Run

- Active Studio session did not auto-live-sync the newly added `ToolVisualController` from source into DataModel during this run.
- To keep human-visual validation moving, smoke used a runtime harness in Play mode.

## Mobile Parity Blocker (Current)

- `scripts/resolve-mobile-mcp-stack.ps1 -Strict` failed:
  - missing/offline required Android lanes: `Samsung-NOTE10`, `S22-ultra`
- `mobile_list_available_devices` returned:
  - `devices=[]`

## Publish Lane Blocker (Current)

- Open Cloud upload retries to
  - `placeId=113010869463813`
  - `universeId=9802743087`
- Returned mixed errors in this session:
  - `Conflict: server busy`
  - intermittent `400 Bad request`
- Studio was closed before retry as part of conflict handling, but upload still did not complete.

## Status

- Visual smoke evidence for Batch T exists and is recorded.
- Real-client parity smoke (PC + mobile) remains blocked by device stack and unstable publish endpoint responses.

# Playable Loop Event + Tool Smoke - 2026-05-17

Branch/runtime target: `brian-second-final` / active `PASRAHPHOBIA.rbxlx`.

## Scope

Continuation after ghost animation/grounding validation. This pass checked existing runtime wiring only:

- map interaction snapshot
- map events: light flicker, object throw, window knock, radio static
- evidence tools: `JejakEnergi`, `BukuTerkutuk`
- utility tools: `Salib`, `Dupa`, `Garam`
- hunt-protection consumption
- safe-zone/hiding snapshot

## Source Patch

`StudioE2EControlSystem:GetMapInteractionSnapshot` now returns a balanced sample of map objects instead of the first 12 sorted entries. Before the patch, the sample was all doors, so Studio smoke scripts could not pick a light/prop/window/radio target even though counts showed those objects existed.

Changed file:

- `src/ServerScriptService/Server/StudioE2EControlSystem/Main.lua`

The active Studio module was mirrored with the same change.

## Validation

Smoke path:

1. `SetForcedGhost` -> `Kuntilanak`
2. `StartSoloMatch` -> `HauntedHouse`, `Classic`, `Mudah`
3. `SetPreparationFocusTool` -> `EMF`
4. `AdvancePhase` -> `InvestigationPhase`
5. `GetMapInteractionSnapshot`
6. trigger map events and tools through `StudioE2EControl`

Snapshot result:

- total objects: `71`
- counts: `Door=18`, `Light=20`, `Object=20`, `Radio=7`, `Window=6`
- balanced sample included:
  - `Light_Bathroom1`
  - `Prop_Bathroom1Cabinet`
  - `Window_Bedroom1`
  - `Panel_Garage`

Map events:

| Event | Target | Result |
|---|---|---|
| `LightFlicker` | `Light_Bathroom1` | `ack=true` |
| `ObjectThrow` | `Prop_Bathroom1Cabinet` | `ack=true` |
| `WindowKnock` | `Window_Bedroom1` | `ack=true` |
| `RadioStatic` | `Panel_Garage` | `ack=true` |

Evidence / utility tools:

| Tool | Result |
|---|---|
| `JejakEnergi` | `ack=true`, evidence `MEDOK`, fallback publish path |
| `BukuTerkutuk` | `ack=true`, evidence `BukuTerkutuk`, fallback publish path |
| `Salib` | `ack=true`, utility visual placed |
| `Dupa` | `ack=true`, utility visual placed |
| `Garam` | `ack=true`, utility visual placed |

Runtime utility visuals:

- `InvestigationTools` total: `3`
- by type: `Garam=1`, `Dupa=1`, `Salib=1`

Hunt protection:

- `ConsumeHuntProtection` returned `ack=true`
- reason: `smudge_repellent_active`
- room: `DiningRoom`
- tool type: `Dupa`

Hiding snapshot:

- system running: `true`
- active match: `match_1`
- safe zone count: `2`
- zone folder children: `2`
- snapshot found `SafeZone_1` and `SafeZone_2`

## Notes

- The first tool smoke intentionally consumed `Dupa` protection before `ForceHunt`, so the forced hunt was blocked/softened by runtime utility logic. That confirms the protection path, but it is not a pure chase test.
- A later map-event smoke advanced to `InvestigationPhase` before the client post-teleport flow had fully promoted local `MatchPhase`, so the panel still displayed `STAGING` while authoritative `MatchLifecyclePhase=InvestigationPhase`. Treat this as E2E harness timing, not a real-flow UI conclusion.
- The next full owner-visible flow should use the real breach/door path and wait for the local UI to reach investigation before event/tool demonstrations.

## Verification

- `rojo sourcemap` passed after the `StudioE2EControlSystem` patch.

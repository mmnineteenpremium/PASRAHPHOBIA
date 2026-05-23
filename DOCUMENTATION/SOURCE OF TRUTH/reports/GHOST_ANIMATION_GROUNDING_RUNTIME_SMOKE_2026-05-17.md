# Ghost Animation + Grounding Runtime Smoke - 2026-05-17

Branch/runtime target: `brian-second-final` / active `PASRAHPHOBIA.rbxlx`.

## Result

- 12/12 ghost templates are present with skinned mesh, bones, SurfaceAppearance, and 7 animation assets each.
- 84/84 ghost clips loaded and moved the target rig bones in Play Mode.
- Runtime `GhostSystem.Service:InitializeMatch` grounding passed for 12/12 ghosts.
- Runtime-scaled visual proof grid showed all 12 ghosts playing `GhostRoam` with `bottom=0.04`.
- Actual match smoke with forced `SilumanUlar` reached `InvestigationPhase`, then hunt; `GhostHunt` played on the live match ghost at `time=1.888`, `weight=1.000`.
- Owner-visible continuation smoke in active Studio showed live `SilumanUlar` and `Genderuwo` hunts through the real `StudioE2EControl` match path. Both used the runtime ghost model, not a raw clone.
- A 12-ghost runtime sweep verified all ghosts spawn as non-placeholder match ghosts and enter hunt/cooldown runtime states with their own per-ghost animation assets available.
- Focused retest of the initially weak samples (`Genderuwo`, `Jerangkong`, `Tuyul`, `WeweGombel`) confirmed `GhostHunt` reaches `WeightCurrent=1.00` and moves bones after blend/load settling.
- Temporary smoke folders were removed from `Workspace` after validation.

## Animation Motion Smoke

Each ghost was cloned from `ReplicatedStorage.Assets.Models.Ghosts`, kept Humanoid-free, assigned an `AnimationController.Animator`, then tested against all runtime clips:

- `GhostIdle`
- `GhostRoam`
- `GhostHunt`
- `GhostManifest`
- `GhostAttack`
- `GhostJumpscare`
- `GhostCooldown`

Pass condition: loaded track has `TimePosition > 0.1`, `WeightCurrent > 0.1`, and at least one `Bone.Transform` changes from bind pose.

Result: `0` failures across `84` clips.

## Runtime Grounding Smoke

Each ghost was spawned through `GhostSystem.Service:InitializeMatch` into a test match container with a floor marker. Pass condition: skinned mesh present, bones present, no fallback `GhostHumanoid`, `Animator` present, and visual bottom sits on floor within tolerance.

| Ghost | Asset ID | Size (X,Y,Z) | Bottom Delta | Skinned | Bones | Surface | Humanoid | Animator |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| Banaspati | 125985418520274 | 2.00, 3.02, 2.12 | 0.040 | 1 | 1 | 1 | 0 | 1 |
| Genderuwo | 116514308503184 | 2.00, 2.86, 1.00 | 0.040 | 1 | 54 | 1 | 0 | 1 |
| HantuTanah | 97068595212213 | 2.00, 2.22, 1.00 | 0.040 | 1 | 54 | 1 | 0 | 1 |
| Jerangkong | 115554451751983 | 2.00, 3.15, 1.00 | 0.040 | 1 | 10 | 1 | 0 | 1 |
| Kuntilanak | 111714179492317 | 2.00, 2.39, 1.00 | 0.040 | 1 | 54 | 1 | 0 | 1 |
| Leak | 98855032697085 | 2.00, 2.05, 1.00 | 0.040 | 1 | 54 | 1 | 0 | 1 |
| Palasik | 78260225419720 | 2.00, 2.26, 1.14 | 0.040 | 1 | 11 | 1 | 0 | 1 |
| Pocong | 135270375666027 | 2.00, 2.22, 1.00 | 0.040 | 1 | 16 | 1 | 0 | 1 |
| SilumanUlar | 87361945667344 | 2.20, 4.53, 1.56 | 0.040 | 1 | 119 | 1 | 0 | 1 |
| SundelBolong | 89326336764042 | 2.15, 3.19, 1.36 | 0.040 | 1 | 48 | 1 | 0 | 1 |
| Tuyul | 128588579954533 | 2.00, 2.00, 1.00 | 0.040 | 1 | 54 | 1 | 0 | 1 |
| WeweGombel | 101666948803556 | 2.00, 2.61, 1.00 | 0.040 | 1 | 54 | 1 | 0 | 1 |

## Actual Match Smoke

Forced ghost: `SilumanUlar`.

Flow:

- Start Play Test fresh.
- Force ghost type to `SilumanUlar`.
- Start solo `HauntedHouse`.
- Advance to `InvestigationPhase`.
- Force manifest, then force hunt.

Observed live match ghost:

- Path: `Workspace.ActiveMatches.Match_match_1.Ghost_SilumanUlar`
- Asset: `87361945667344`
- Visual type: `SilumanUlar`
- Humanoid: `nil`
- Animator: `Workspace.ActiveMatches.Match_match_1.Ghost_SilumanUlar.AnimationController.Animator`
- Hunt active: `true`
- Playing track: `GhostHunt`
- AnimationId: `rbxassetid://124180414586258`
- Track state: `time=1.888`, `weight=1.000`
- Bounds: `2.20, 4.53, 1.56`

## Owner-Visible Hunt Continuation

Additional Play Mode validation was run in the open `PASRAHPHOBIA.rbxlx` Studio session using temporary LocalScripts under the live player's `PlayerScripts`. These scripts only existed for the Play session and were not written into source.

### SilumanUlar

- Runtime path: `Workspace.ActiveMatches.Match_match_1.Ghost_SilumanUlar`
- State: `Hunting`
- Visual motion: `Hunting`
- Target mode: `Player`
- Navigation mode: `direct`
- Bounds: `2.20, 4.53, 1.56`
- Orientation sanity: `lookY` stayed near horizontal (`-0.09` to `0.08`) instead of the raw imported vertical pivot.
- Track: `GhostHunt`, `WeightCurrent=1.00`, time advanced and looped.

### Genderuwo

- Runtime path: `Workspace.ActiveMatches.Match_match_1.Ghost_Genderuwo`
- State: `Hunting`
- Visual motion: `Hunting`
- Target mode: `Player`
- Bounds: `3.07, 4.14, 1.04`
- Orientation sanity: `lookY` stayed near horizontal (`-0.09` to `0.09`), so the ghost did not face upward in runtime.
- Track: `GhostHunt`, `WeightCurrent=1.00`, time advanced and looped after blend/load settling.

## Runtime 12-Ghost Sweep

Temporary E2E sweep sequence:

1. `SetForcedGhost`
2. `StartSoloMatch` on `HauntedHouse`
3. `SetPreparationFocusTool` with `EMF`
4. `AdvancePhase` to `InvestigationPhase`
5. `ForceHunt`
6. sample runtime ghost attributes and playing tracks
7. `EndMatch`

The first broad sweep intentionally sampled quickly so it could cycle through all ghosts. A few rows showed `WeightCurrent=0.00` because the track was still blending/loading or the hunt had already cooled down. The focused retest below is the authoritative animation check for those rows.

Focused retest results:

| Ghost | Hunt Track | Weight | Bones Moved | Orientation |
|---|---|---:|---:|---|
| Genderuwo | `GhostHunt` | 1.00 | 44-46 / 54 | horizontal |
| Jerangkong | `GhostHunt` | 1.00 | 4 / 10 | horizontal |
| Tuyul | `GhostHunt` | 1.00 | 47-49 / 54 | horizontal |
| WeweGombel | `GhostHunt` | 1.00 | 44-46 / 54 | horizontal |

## Notes

- The previous HantuTanah stall was caused by runtime fallback `GhostHumanoid` suppressing `AnimationController.Animator` evaluation on skinned ghost rigs. The permanent patch keeps skinned ghost rigs Humanoid-free.
- A first rapid batch produced false negatives before preload/settling; retry with preload and bone-transform checks passed.
- Grounding smoke confirms floor contact, not final artistic scale. Some ghost heights may still need owner visual tuning if the intended silhouette should be taller or shorter.
- Follow-up pathing hardening in the same Studio session fixed a broad door-traversal bug: map-level `DoorTraversalMode` no longer makes every map descendant count as a door. Runtime probe confirmed `OutdoorMainFloor => door=false`, `Door_FrontEntry => door=true`, and direct ghost-to-player ray now blocks on real `HauntedHouse.Part` geometry instead of clearing through the whole house.
- HauntedHouse has no authored `NavigationNodes`, so `GhostSystem.Service` now falls back to existing `Rooms + Doors` parts as navigation nodes and casts navigation rays at room/interior height instead of rig pivot height. Live `Kuntilanak` hunt reached `VisualNavigationMode=node_path` with `VisualTargetDistance=5.36` before the hunt naturally transitioned into cooldown.
- Some broad-sweep `groundDelta` numbers are not authoritative because the simple client ray can hit map decor/door/window geometry. The grounding authority remains the runtime `InitializeMatch` smoke with controlled floor markers, where all 12 ghosts passed at `bottomDelta=0.040`.
- Remaining validation gap: full room-to-room owner-visible chase route, plus map event/tool interactions such as flicker, poltergeist, fingerprints, cursed writing, crucifix/drop-tool behavior, and UV/camera evidence must still be verified in the actual playable loop.

# PASRAHPHOBIA State

## 2026-06-15

- OwnerDebugPanel plugin now normalizes spawned ghosts into a model container, clears the full debug root on despawn, and resolves `AnimationController` as well as `Humanoid` when playing ghost animations.
- Live Studio validation in Edit mode confirmed:
  - `Workspace.__OwnerDebugPanel:ClearAllChildren()` removes all spawned ghosts.
  - `Model:ScaleTo()` changes ghost bounds on the spawned rigged ghost.
  - `AnimationController.Animator:LoadAnimation()` can play `GhostIdle` on the spawned ghost.

- 2026-06-15 lobby UI and NPC dialogue follow-up:
  - Respawn guard now disables reset in lobby/match/spawn-protected states.
  - Lobby social UI reveal motion was extended into the 0.5-1.0s range for the main panel, quest tracker, quest popup, and key HUD fades.
  - `QuestTracker` cards are normalized in script so the quest list stays within the viewport instead of inheriting offscreen authored sizes.
  - `NpcDialogueController` is registered in client bootstrap, dedupes repeated opens for the same NPC/dialogue, and now closes/unfreezes correctly after `CLOSE`.
  - Lobby dialogue prompt handling now guards against duplicate triggers, and investigator NPC spawn positions use wider ring offsets plus random yaw so they do not stack on each other.
  - Studio runtime verification after reload confirmed `OPEN` sets `PasrahNpcDialogueActive=true`, locks camera/input, and `CLOSE` restores `WalkSpeed=10`, `JumpPower=50`, `MouseBehavior=Default`, and `PasrahNpcDialogueActive=false`.

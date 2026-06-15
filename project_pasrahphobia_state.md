# PASRAHPHOBIA State

## 2026-06-15

- OwnerDebugPanel plugin now normalizes spawned ghosts into a model container, clears the full debug root on despawn, and resolves `AnimationController` as well as `Humanoid` when playing ghost animations.
- Live Studio validation in Edit mode confirmed:
  - `Workspace.__OwnerDebugPanel:ClearAllChildren()` removes all spawned ghosts.
  - `Model:ScaleTo()` changes ghost bounds on the spawned rigged ghost.
  - `AnimationController.Animator:LoadAnimation()` can play `GhostIdle` on the spawned ghost.

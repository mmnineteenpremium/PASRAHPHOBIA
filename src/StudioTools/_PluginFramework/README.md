# Studio Plugin Framework Shell

This folder is a placeholder for future Studio plugin tools.

Pattern:

- `Plugin entry`: one file that wires `Plugin` APIs, toolbar actions, and widget lifecycle.
- `Dock widget`: UI and controls live in a plugin widget, not in Play-mode scripts.
- `Shared config`: all tool state comes from `ReplicatedStorage` config or editor-selected instances.
- `Workspace preview`: temporary test rigs and visual markers are created under a dedicated root folder and are safe to delete.

Current consumer:

- `OwnerDebugPanel` is the first plugin following this shell.

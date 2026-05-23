#!/usr/bin/env python
"""Project launcher for the global Roblox Cube3D wrapper."""

from __future__ import annotations

import runpy
from pathlib import Path


GLOBAL_TOOL = Path(
    r"D:\MovedFromC_UserProfile\.codex\tools\roblox-asset-workflow\generate_cube3d.py"
)

if not GLOBAL_TOOL.exists():
    raise SystemExit(f"Global generate_cube3d.py not found: {GLOBAL_TOOL}")

runpy.run_path(str(GLOBAL_TOOL), run_name="__main__")

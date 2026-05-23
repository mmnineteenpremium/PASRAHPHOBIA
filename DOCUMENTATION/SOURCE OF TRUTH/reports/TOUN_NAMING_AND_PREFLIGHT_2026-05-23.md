# To'un Naming and Preflight Audit - 2026-05-23

## To'un Naming Result

- Status: changed.
- File: `src/shared/GameData/ToolVisualConfig.lua`
- Entry: `BolaArwah`
- Field changed: `sourceLabel`
- Old value: `Kamera To'un - Night Vision Recorder`
- New value: `Kamera To'un`
- Scope note: key/ID, evidence wiring, asset IDs, mount data, screen data, and other fields were not changed.
- `src/shared/DataTypes/ToolDefinitions.lua`: not present in this source tree.

## Release Preflight Output

Command:

```powershell
.\scripts\release-preflight.ps1
```

Output summary:

```text
Building project 'PASRAHPHOBIA'
Built project to _tmp_release_preflight_build.rbxlx
== Release Preflight ==
Build ok:              True
Build output:          _tmp_release_preflight_build.rbxlx
Canonical mirror:      PASRAHPHOBIA.rbxlx
Canonical mirror ok:   True
Missing reports:       0
Robux items:           10
Safe items missing ID: 0
Safe items disabled:   0
Hold items enabled:    0

Known manual blockers:
- smoke test 2 client nyata: owner task manual (eksekusi user)
```

Preflight pass/fail:

- buildOk: PASS
- canonicalMirrorOk: PASS
- missingReports: PASS (`0`)
- safeItemsMissingMarketplaceId: PASS (`0`)
- safeItemsDisabled: PASS (`0`)
- holdItemsEnabled: PASS (`0`)
- Known manual blocker: `smoke test 2 client nyata`

## Marketplace Mapping Audit

Command:

```powershell
.\scripts\audit-marketplace-mapping.ps1
```

Output summary:

```text
== Creator Hub Marketplace Mapping Audit ==
Catalog Robux items: 10
Safe enable now:   6
Keep disabled:     4

Safe items missing marketplaceId: 0
Safe items still disabled:        0
Hold items accidentally enabled:  0
Unclassified items:               0
```

Requested categories:

- safeItemsMissingMarketplaceId: `0`
- holdItemsAccidentallyEnabled: `0`
- unclassifiedItems: `0`

## Rojo Sourcemap Result

Command:

```powershell
.\.aftman\bin\rojo.exe sourcemap default.project.json
```

Result: PASS. The command exited successfully and emitted the sourcemap JSON to stdout.

## Overall Launch Readiness

PERLU PERHATIAN.

No automated preflight or marketplace audit FAIL items were found. The remaining attention item is the known manual blocker reported by preflight: `smoke test 2 client nyata`, which is owner/manual validation and was not run in this prompt.

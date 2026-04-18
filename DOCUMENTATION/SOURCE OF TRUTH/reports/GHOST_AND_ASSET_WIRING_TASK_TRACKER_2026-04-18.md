# Ghost And Asset Wiring Task Tracker 2026-04-18

## Status

- Overall progress: 84%
- Current lane: ghost asset source-of-truth remap + runtime template replacement lock
- Current state: authoritative CSV mapping locked, wrong Leak row removed from local CSV, live ghost template replacement synced back to source, cloud publish completed
- Runtime wiring execution: ghost asset lane completed, deeper runtime validation still continuing

## Goal

Replace ghost assets and related investigation assets end-to-end using the owner-imported Roblox assets from local `ROBLOX CREATOR HUB`, then wire them into canonical gameplay behavior without placeholder content, drift, duplicate systems, or undocumented substitutions.

## Hard Rules

- Do not create new systems.
- Do not change architecture.
- Do not duplicate runtime ownership.
- Do not improvise asset replacement when exact asset identity is unclear.
- If a needed asset ID cannot be mapped confidently from CSV or live Studio inventory, stop and ask the owner.
- Use default imported size first for all ghost assets.
- Keep Pocong on default uploaded size baseline for this new replacement pass.
- Treat all local assets in `ROBLOX CREATOR HUB` as the intended source pool because the owner stated they are already bulk imported to Roblox Studio with custom rig where applicable.

## Source Of Truth Inputs

- Local root:
  - `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB`
- Asset ID CSV:
  - `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\[ASSETID]\Models & Packages.csv`
  - `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\ROBLOX CREATOR HUB\[ASSETID]\Meshes.csv`
- Canonical runtime/code references:
  - `src/shared/GameData`
  - `src/ServerScriptService/Server`
  - `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
  - `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`

## Local Source Audit Snapshot

### Ghost Source Folders Found

- `Banaspati`
- `Genderuwo`
- `Hantu Tanah`
- `Jerangkong`
- `Kuntilanak`
- `Leak`
- `Palasik`
- `Pocong`
- `Siluman Ular`
- `Sundel Bolong`
- `Tuyul`
- `Wewe Gombel`

### Investigation Tool Source Folders Found

- `01 - Detektor MEDOK - EMF Reader`
- `02 - Termometer Suhu - Thermometer`
- `03 - Buku Terkutuk Kosong - Ghost Writing Book`
- `04 - Kamera To'un - UV Camera - Spirit Orb Camera`
- `05 - Kotak Suara - Spirit Box`
- `06 - Sensor Pengganggu - Motion Sensor`
- `07 - Senter - Flashlight`
- `08 - Garam - Salt`
- `09 - Salib - Crucifix`
- `10 - Dupa - Smudge Stick`
- `flashlight-headlight`

### CSV Notes

- `Models & Packages.csv` is the primary candidate for uploaded model/package asset IDs.
- `Meshes.csv` is the primary candidate for uploaded mesh asset IDs.
- The CSV contains duplicate or ambiguous labels such as `SALIB KAYU`, `Garam`, `ht`, `EMF - MEDOK`, and redacted-looking rows such as `########`.
- Those duplicate labels are not auto-resolved in this tracker.
- If runtime wiring later needs one exact row and Studio naming does not disambiguate it, owner confirmation is mandatory.

## Execution Phases

### Phase 0 - Task Guardrails

- Lock task scope for ghost replacement and asset-based wiring only.
- Lock blocker rule: no placeholder and no guessed asset IDs.
- Lock size rule: use default uploaded scale first.

Status: completed

### Phase 1 - Source Audit

- Audit local `ROBLOX CREATOR HUB` folders.
- Audit CSV source files.
- Verify canonical ghost set count against local source count.
- Verify investigation tool set count against local source count.

Status: completed

Done:
- local ghost folders discovered
- local investigation tool folders discovered
- asset ID CSV files discovered

Remaining:
- cross-map local source names to live imported Studio inventory names
- isolate exact canonical mapping rows for each ghost and tool

### Phase 2 - Live Inventory / Studio Audit

- Audit imported ghost assets already present in Roblox Studio inventory/runtime roots.
- Audit imported investigation tools already present in Roblox Studio inventory/runtime roots.
- Record exact asset identity used by live game for each canonical slot.
- Identify mismatch between old runtime asset and new owner-imported asset.

Status: completed

Initial live findings from active Studio before replacement:

- `ReplicatedStorage.Assets.Models.Ghosts` currently exposes only:
  - `Genderuwo`
  - `Kuntilanak`
  - `KuntilanakAggressive`
  - `Leak`
  - `Pocong`
- `ReplicatedStorage.Assets.Models.Tools` currently exposes only:
  - `Dupa`
  - `Garam`
  - `Salib`
- `ServerStorage.Assets.Models.Ghosts` currently exposes no ghost models.
- `ServerStorage.Assets.Models.Tools` currently exposes no tool models.
- The remaining canonical ghosts exist in code/config naming lanes, but are not yet exposed as live models in the audited runtime asset folder.

Live ghost asset identity findings:

- `Genderuwo`
  - `GhostAssetId=117009327297852`
  - CSV label match found: `genderuwo`
- `Kuntilanak`
  - `GhostAssetId=93357688576883`
  - CSV label match found: `kuntilanak_Iv Pole Walking`
- `KuntilanakAggressive`
  - `GhostAssetId=118867381731250`
  - CSV label match found: `Kunti Agresive`
- `Leak`
  - `GhostAssetId=129878813436863`
  - CSV row exists, but current label is `dark+armored+knight+more+spikey`
  - this is not a confident canonical-name match
- `Pocong`
  - live model found
  - `GhostAssetId` attribute not present on audited live model
  - no direct asset ID lock from live runtime attributes yet

Final audit result after replacement/syncback:

- full `12`-ghost replacement is now present in `ReplicatedStorage.Assets.Models.Ghosts`
- approved aggressive/event variants already supported by the existing naming lane are present
- `Leak` now resolves to the canonical row `leakkk_roblox (99042834683066)`
- `Pocong` now resolves to the canonical row `pocong PASRAHPHOBIA (123151303766691)`

### Phase 3 - Canonical Ghost Mapping

- Map each of the 12 canonical ghosts to exact owner-imported asset IDs.
- Record variant models per ghost where available.
- Classify variants by intended use:
  - base
  - angry
  - aggressive
  - alternate event form
- Keep default uploaded size unless owner says otherwise.

Status: completed

Authoritative canonical ghost mapping locked from local `ROBLOX CREATOR HUB` + `Models & Packages.csv`:

| Canonical Slot | CSV Label | Asset ID | Notes |
|---|---|---:|---|
| `Banaspati` | `banaspati` | `91700421463863` | base/default |
| `BanaspatiAggressive` | `Banaspati Agressive` | `117153307100171` | aggressive variant wired through existing suffix resolver |
| `Genderuwo` | `genderuwo` | `117009327297852` | base/default |
| `GenderuwoAggressive` | `GENDERUWO AGRESIVE_roblox` | `138432330933642` | aggressive variant |
| `HantuTanah` | `hantutanah_roblox` | `79247394068873` | base/default |
| `Jerangkong` | `jerangkong_roblox` | `78522466547915` | base/default |
| `Kuntilanak` | `kuntilanak_Iv Pole Walking` | `93357688576883` | base/default |
| `KuntilanakAggressive` | `Kunti Agresive` | `118867381731250` | aggressive variant |
| `Leak` | `leakkk_roblox` | `99042834683066` | base/default after deleting wrong CSV row |
| `LeakAggressive` | `LeaxAggresive_roblox` | `115214614318321` | aggressive variant |
| `Palasik` | `palasik1` | `107658913093426` | base/default |
| `PalasikAngry` | `Palasik Angry` | `95122370433014` | event / angry variant |
| `Pocong` | `pocong PASRAHPHOBIA` | `123151303766691` | authoritative Pocong replacement |
| `SilumanUlar` | `siluman ular_roblox` | `93238005114915` | base/default |
| `SundelBolong` | `SUNDELBOLONG_roblox` | `77251173218842` | base/default |
| `SundelBolongAggressive` | `SundelBolongAgressive_roblox` | `113356865728207` | aggressive variant |
| `Tuyul` | `Tuyul Angry` | `108895029067567` | only uploaded/runtime-ready Tuyul model found in source pool |
| `WeweGombel` | `wewegombellalaki_roblox` | `115717855449052` | base/default |

Notes:

- Wrong `Leak` row `dark+armored+knight+more+spikey (129878813436863)` was removed from local CSV by owner instruction.
- `Tuyul` currently maps to the only imported source candidate available in the CSV/source pool. No second neutral/base asset was found locally.
- Variants outside the runtime suffix lane are not auto-wired in this pass to avoid inventing a new switching system.

### Phase 4 - Canonical Investigation Tool Mapping

- Map each investigation tool to exact owner-imported asset IDs.
- Confirm whether flashlight and headlamp variants are gameplay variants, cosmetic variants, or support assets.
- Stop if any canonical tool has no exact owner-imported mapping.

Status: base-slot mapping locked, template syncback completed

Owner clarification locked on 2026-04-18:

- `LobbySocialHub` remains the authoritative play-entry lobby and is expected around `x ~= 1600`.
- Duplicate investigation tool uploads are intentional and will feed future rarity/category expansion.
- Current runtime lane must therefore lock exactly one `base/default/common` asset per canonical tool for gameplay wiring, while preserving the remaining imported variants as a `rarity pool` for later work.
- Do not auto-promote alternate tool uploads into live runtime without an explicit base-slot decision.

Confident mappings from local `ROBLOX CREATOR HUB` + `Models & Packages.csv`:

| Canonical Tool | Local Source Pattern | CSV Label | Asset ID | Confidence |
|---|---|---|---:|---|
| `SuhuMembeku` | `02 - Termometer Suhu - Thermometer` | `Termometer Suhu` | `106744635077484` | high |
| `GerakanGaib` | `06 - Sensor Pengganggu - Motion Sensor` | `SensorPengganggu` | `109093713235033` | high |
| `BolaArwah` | `04 - Kamera To'un - UV Camera - Spirit Orb Camera` | `CameraUV R5` | `80883221689326` | medium-high |

Historical ambiguity resolved into base-slot lock:

- `JejakEnergi`
  - `EMF - MEDOK = 121559455873224`
  - `EMF - MEDOK = 124662372824994`
- `KotakArwah`
  - `ht-KOTAK SUARA = 80024667585179`
  - `ht-KOTAK SUARA = 103210317836293`
- `BukuTerkutuk`
  - `Buku Terkutuk (tertutup) = 123135502718934`
  - `Buku Terkutuk (Terbuka) = 135643662585349`
  - `Buku Terkutuk (tertutup) = 108333222574742`
- `Garam`
  - `Garam Diawur = 70968882423059`
  - `Garam = 117103968659967`
  - `Garam = 85676391823588`
  - `Garam Diawur = 123531417425505`
- `Salib`
  - `salib2 = 118327808345553`
  - `SALIB KAYU = 128686833722709`
  - `SALIB KAYU = 74458723326407`
  - `salib2 = 84267196435822`
- `Dupa`
  - `dupastick = 128740632500448`
  - `dupastick = 116816609439903`
  - local source also contains `Dupa Pot Merah` and `Dupa pot`, but no confident CSV row has been locked yet
- `Flashlight`
  - `Flashlight besar hitam = 127298509562779`
  - `Flashlight besar hitam = 83570453208896`
  - `FlashlightHitam Kecil = 86818981706974`
  - `HeadLamp Biru = 70727435874806`
  - `HeadLamp Hitam = 139597366473925`

Owner-provided authoritative mapping:

| Canonical Tool | Source | Asset ID | Status |
|---|---|---:|---|
| `PilSanity` | owner-provided post-import asset id | `135462688002407` | locked |

Working rule for the next slice:

- `ghost/evidence gameplay runtime` uses one locked base asset per tool slot
- `rarity variants` stay documented but unwired until the rarity/content lane is implemented

Classification notes from local source folders:

- `BukuTerkutuk`
  - `tertutup` is the strongest `base/default/common` candidate
  - `Terbuka` reads as an interaction/state variant, not a separate baseline slot
- `Garam`
  - `Garam` is the strongest `base/default/common` candidate
  - `Garam Diawur` reads as a deployed/used state variant
- `KotakArwah`
  - `ht-KOTAK SUARA` is the strongest canonical-name match
  - `ht` reads as a secondary/short-name upload and should not automatically replace the canonical slot
- `Dupa`
  - `dupastick` is the strongest `base/default/common` candidate
  - `Dupa Pot Merah` and `Dupa pot` read as alternate/support prop variants
- `Flashlight`
  - `Flashlight besar hitam` is the strongest main-hand flashlight candidate
  - `HeadLamp Biru` and `HeadLamp Hitam` read as headlamp/support variants, not primary flashlight baseline

Base-slot defaults locked into source config on 2026-04-18:

| Canonical Tool | Locked Base Asset ID | Basis |
|---|---:|---|
| `JejakEnergi` | `121559455873224` | first canonical `EMF - MEDOK` row retained as base |
| `KotakArwah` | `80024667585179` | first canonical `ht-KOTAK SUARA` row retained as base |
| `SuhuMembeku` | `106744635077484` | single confident thermometer row |
| `BukuTerkutuk` | `123135502718934` | `tertutup` retained as base, `Terbuka` demoted to state variant |
| `BolaArwah` | `80883221689326` | only confident camera row in imported pool |
| `GerakanGaib` | `109093713235033` | single confident motion-sensor row |
| `Garam` | `117103968659967` | `Garam` retained as base, `Garam Diawur` demoted to deployed-state variant |
| `PilSanity` | `135462688002407` | owner-provided post-import authoritative id |
| `Salib` | `128686833722709` | `SALIB KAYU` retained as base/default crucifix |
| `Dupa` | `128740632500448` | first `dupastick` row retained as base |
| `Flashlight` | `127298509562779` | `Flashlight besar hitam` retained as base main-hand light |

Syncback completion on 2026-04-18:

- active Studio loaded the owner-imported tool assets directly from asset ids into `ReplicatedStorage.Assets.Models.Tools`
- place file `PASRAHPHOBIA.rbxlx` was saved after the live import pass
- syncback completed into `src/ReplicatedStorage/Assets/Models/Tools`
- source tree now contains canonical tool templates for all base slots:
  - `JejakEnergi`
  - `KotakArwah`
  - `SuhuMembeku`
  - `BukuTerkutuk`
  - `BolaArwah`
  - `GerakanGaib`
  - `Garam`
  - `PilSanity`
  - `Salib`
  - `Dupa`
  - `Flashlight`

### Phase 5 - Wiring Dependency Audit

- Audit current codepaths that spawn or reference ghosts.
- Audit current codepaths that spawn or reference investigation tools.
- Audit current codepaths for animation, behavior, movement, event trigger, and evidence interactions.
- Mark each dependency as one of:
  - already wired
  - wired to old asset
  - disabled
  - placeholder
  - missing

Status: pending

### Phase 6 - Ghost Wiring Implementation

- Replace old ghost asset references with new owner-imported assets.
- Preserve canonical ghost behavior, movement logic, and evidence profile.
- Use owner-imported variants only when canonical behavior or event trigger justifies it.
- Do not invent variant switching without owner approval.

Status: completed for ghost lane

Done:

- `ReplicatedStorage.Assets.Models.Ghosts` live template folder in active Studio was replaced with canonical wrappers for:
  - all `12` base ghosts
  - `6` aggressive/angry variants already supported by the existing suffix naming lane
- each runtime ghost template now carries:
  - `GhostAssetId`
  - `GhostImportedAt`
  - `GhostSourceCsvLabel`
- `GhostVisualTuning.lua` in source now maps the canonical ghost set to new owner-imported asset IDs
- `Pocong` legacy single-mesh profile and hardcoded mesh asset references were removed from source
- `Service.lua` no longer forces old Pocong-only template offsets/mesh overrides and now resolves existing aggressive suffix variants from the current runtime lane
- ghost template replacements were saved to `PASRAHPHOBIA.rbxlx`, synced back with `scripts/pull-from-studio.ps1`, and published to the canonical cloud target

Remaining:

- verify one live in-match ghost manifestation against the new published template set
- continue tool asset lane after ghost lane is stable

### Phase 7 - Tool Wiring Implementation

- Replace old investigation tool asset references with owner-imported tools.
- Preserve existing gameplay ownership and tool logic.
- Do not create duplicate tool systems.

Status: pending

### Phase 8 - Runtime Validation

- Smoke test published runtime.
- Smoke test multiclient:
  - Roblox Player PC as room owner / host lane
  - Android as joiner lane
- Validate:
  - lobby spawn
  - room browser
  - staging behavior
  - map entry flow
  - ghost visual replacement
  - tool visual replacement
  - no UI duplication

Status: in progress

Completed validation slices:

- Published source build uploaded after ghost syncback.
- PC player published boot smoke reached lobby UI successfully:
  - `LOBBY PANEL`
  - `OPEN ROOM BROWSER`
  - `PROFILE`
  - `SHOP`
  - `ROYAL PASS`
  - `RANK`
- Android lane resolved into the Roblox app place page for `PASRAHPHOBIA`.
- active Studio save completed to `PASRAHPHOBIA.rbxlx`, then syncback completed from that saved place file
- canonical cloud publish completed after the syncback using the current branch source

Remaining validation slices:

- start/join room flow on published runtime
- confirm one live match uses the new ghost template set in runtime
- continue deeper UI/multiclient smoke only after ghost lane is locked in commit
- `LobbySocialHub` authoritative world source is still blocked:
  - published runtime no longer falls into the completely empty gray world
  - but the restored historical `LobbySocialHub.model.json` still resolves to an incorrect blockout-like lobby state
  - historical git versions of `src/Workspace/Maps/LobbySocialHub/LobbySocialHub.model.json` do not expose a more complete lobby source
  - syncback from current `PASRAHPHOBIA.rbxlx` did not provide a healthier `LobbySocialHub` source to restore from

### Phase 9 - Lock And Report

- Syncback if Studio-side changes are part of the approved lane.
- Commit source/doc/report changes.
- Publish to Roblox cloud target.
- Append final report with exact changed assets and wiring coverage.

Status: in progress

Done:

- live Studio ghost template replacement saved into local place file
- syncback from `PASRAHPHOBIA.rbxlx` completed
- canonical source files updated:
  - `src/shared/GameData/GhostVisualTuning.lua`
  - `src/ServerScriptService/Server/GhostSystem/Service.lua`
  - `src/ReplicatedStorage/Assets/GhostVisualProfiles/Pocong.lua`
  - `src/ReplicatedStorage/Assets/Models/Ghosts/*`
  - `DOCUMENTATION/SOURCE OF TRUTH/CANONICAL_SPECIFICATIONS_v2.md`
  - `DOCUMENTATION/SOURCE OF TRUTH/PASRAHPHOBIA_DOC_INDEX.md`
- canonical cloud publish completed to:
  - `PlaceId=113010869463813`
  - `UniverseId=9802743087`

Remaining:

- isolate and commit only ghost/doc files from the dirty branch
- append final execution log for this ghost source-of-truth lock

## Required Stop Conditions

- Asset ID needed for canonical slot is not found in CSV or live imported asset list.
- Multiple CSV rows match the same canonical asset and Studio naming cannot disambiguate them.
- Live imported asset exists but rig/type is incompatible with the target wiring path.
- A runtime path still points to a placeholder or old asset and the new owner asset cannot be resolved safely.
- A live ghost carries an asset ID that maps to a non-canonical or suspicious CSV label and cannot be resolved confidently.
- A live ghost model exists but has no stable `GhostAssetId` attribute for authoritative mapping.

## Progress Update Format For This Task

Every meaningful update for this tracker should state:

- current phase
- exact asset family being audited or changed
- blocker or no blocker
- overall progress percent

## Immediate Next Step

- finalize the ghost lane commit
- continue deeper published runtime validation
- then move to investigation tool asset lane using the same source-of-truth rule

## Active Blocker Snapshot

- No hard blocker in the ghost source-of-truth lane.
- Remaining work is validation depth, not mapping uncertainty:
  - full published room flow smoke
  - confirm in-match ghost visual replacement through a live match

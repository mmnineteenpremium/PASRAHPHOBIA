# PASRAHPHOBIA IMPLEMENTATION BASELINE

Last updated: 2026-04-01
Purpose: baseline progress snapshot before continuing implementation work

## 1. Source Priority

Use these sources in this order:

1. `REPORTS.md` = current runtime truth and authoritative status snapshot.
2. `CANONICAL_SPECIFICATIONS_v2.md` = design target.
3. `PASRAHPHOBIA_DOC_INDEX.md` = phase definitions and broad design map.
4. `CLAUDE.md` = historical session context only, not current truth.

Reason:

- `REPORTS.md` explicitly says earlier phase notes are stale and that it is now the single authoritative runtime status file.
- `CLAUDE.md` still reflects an earlier checkpoint.

## 2. Executive Verdict

Current project position:

- Estimated overall completion: `82%`
- Practical implementation score: `81%` to `82%`
- Current working phase: `late Phase 6 -> early Phase 7 consistency lock`
- Interpretation: the project is no longer mainly blocked by config drift, local profile-shape fragmentation, classic difficulty exposure, or leaderboard formula drift; it is now mainly blocked by validation coverage and missing completion-layer systems.

This means PASRAHPHOBIA is already in the "substantially implemented but not yet cleanly validated" stage.

## 3. How The 82% Was Estimated

Based on the runtime row-status audit categories in `REPORTS.md` after the lobby flex runtime-model pass:

- `31` rows = Implemented active
- `24` rows = Resolved / Resolved (runtime model)
- `4` rows = Improved
- `0` rows = Partial/conflicted
- `4` rows = Not found / not confirmed
- Total audited runtime rows = `63`

Weighted estimate used for planning:

- Implemented active = `1.0`
- Resolved = `0.75`
- Improved = `0.6`
- Partial/conflicted = `0.5`
- Not found = `0.0`

Formula:

`(31 x 1.0) + (24 x 0.75) + (4 x 0.6) + (0 x 0.5) + (4 x 0.0) = 51.40`

`51.40 / 63 = 81.59%`

Rounded planning number:

- `81.59%` by raw row-weight score
- `81% - 82%` as the practical management range
- `82%` as the practical management figure

Important note:

- If measured by "code exists somewhere", the number looks higher.
- If measured by "release-ready and validated", the number is lower.
- The management range is intentionally lower than the raw row-weight score because live gameplay validation, real DataStore behavior, and several completion-layer systems are still not finished.

## 4. Phase Breakdown

Phase definitions below follow `PASRAHPHOBIA_DOC_INDEX.md`.

| Phase | Name | Estimate | Status summary |
| --- | --- | ---: | --- |
| 1 | Architecture Design | 92% | Core architecture exists, and active registry load order now respects explicit preload plus grouped ordering; the remaining gap is documentation shape and validation, not purely alphabetical boot drift. |
| 2 | System Modules | 86% | Most major systems exist in runtime and are wired; the remaining risk is consistency, not absence. |
| 3 | Data Structures | 70% | Progression, rank, and public profile shape now converge through `ProfileSystem`, but live persistence validation and some direct persistence readers still need hardening. |
| 4 | Gameplay Mechanics | 83% | Core room -> match -> investigation -> result loop is playable and substantial, with Classic now routed through hidden auto-balance instead of player-facing named tiers. |
| 5 | Economy and Monetization | 76% | Economy/shop/rewards are active and cleaner, the canonical `R1-R5` rarity model and gift runtime path are now aligned in active shop/catalog/daily reward flows, but Robux monetization is still missing. |
| 6 | Social Systems | 83% | Lobby, party, profile view, cosmetics, room browser, leaderboard semantics, and the active flex-zone spotlight loop are stronger after map-preview, room-trace, canonical rank-board cleanup, and live lobby cosmetic/flex runtime alignment. |
| 7 | QA Validation | 38% | Validation structure exists, Studio can now opt into real DataStore, but live persistence behavior and full gameplay hardening are still not confirmed here. |

Phase conclusion:

- Phases `1` to `5` are largely built.
- Phase `6` is substantially present in runtime.
- Phase `7` has started conceptually, but is not complete.
- The real current position is `late Phase 6 / early Phase 7 consistency lock`.

## 5. What Is Already Strong Enough To Build On

These areas are strong enough to treat as real implementation, not placeholders:

- Core boot pipeline and EventBus
- Data persistence shell
- Match flow, match lifecycle, and teleport flow
- Lobby room flow and room browser remote handling
- Game phase control
- Ghost gameplay core
- Ghost database with `12` ghosts in config
- Evidence gameplay core
- Spectator gameplay core
- Sanity and aggression systems
- Hunt runtime systems
- Inventory, shop, cosmetics, and economy
- Reward pipeline
- Party, daily check-in, daily missions, and royal pass
- Leaderboard and player profile view
- Camera, movement, flashlight sync, client evidence tools, and main UI

Operational conclusion:

- We should extend these systems carefully.
- We should avoid unnecessary rewrites in these areas unless they are directly involved in a confirmed conflict.

## 6. What Is Partial And Needs Cleanup Before Large Feature Expansion

These are the most important incomplete or conflicted areas:

### A. Boot and autoload architecture

- `SystemRegistry` active load behavior does not match the intended grouped boot design.
- Explicit preload coverage now exists for the critical non-`*System` runtime folders.
- The remaining risk is architectural drift between intended grouped boot and actual registry scan order.

Most important examples:

- `HorrorDirector`
- `LobbySocialHub`
- `EvidenceDeductionEngine`

### B. Remaining source-of-truth drift

- Progression/stat/profile/rank ownership is now concentrated in `ProfileSystem`, and `PlayerProfileSystem` now consumes the canonical snapshot.
- Ranked persistence is cleaner because `RankedSystem` now boots from canonical profile data and syncs through the canonical owner first.
Practical risk:
- some narrow systems still read persistence directly for their own slices
- live production persistence behavior is still not validated outside Studio
- runtime behavior still diverges from spec mainly in validation coverage and missing completion-layer features

### C. Persistence validation gap

- `ProgressionSystem` and `RankedSystem` now route through `ProfileSystem` first, with direct persistence only as fallback.
- `ProfileSystem` now loads and saves canonical progression/statistics/profile/rank state in one shape.
- Studio still cannot validate live DataStore persistence behavior.

Practical risk:

- local logic is cleaner, but production persistence edge cases still need live validation

### D. Remaining canonical/runtime divergence

- active shop/catalog rarity is now canonical `R1-R5`, but the broader monetization layer that should consume that model remains incomplete
- documentation still contains a `Sang Ahli` loss-rule conflict, but active runtime now follows `CANONICAL_SPECIFICATIONS_v2.md` for leaderboard and top-tier counter semantics

### E. Validation and launch gap

- Studio disables real DataStore persistence, so local tests do not verify real persistence behavior
- end-to-end validation still depends on manual gameplay passes from lobby to return-to-lobby
- monetization and several completion-layer systems are still not runtime-confirmed

## 7. What Is Still Missing Or Not Confirmed

According to the latest runtime audit, these remain missing or not runtime-confirmed:

- Evidence training gameplay system
- Robux monetization flow
- Live-validated canonical rank persistence behavior
- Live-validated classic auto-balance behavior
- Clean lobby flex gameplay loop

Implementation interpretation:

- The game is not missing its core loop.
- It is still missing several completion-layer systems and canonical polish targets.

## 8. Safe Priority Order Before New Major Features

Recommended order for implementation work from this point:

1. Align active boot path with intended architecture.
2. Restore autoload or explicit startup for critical skipped systems.
3. Clean ghost, evidence, and rank source-of-truth conflicts.
4. Validate the now-cleaner progression, rank, and profile persistence flow in production-like conditions.
5. Remove outdated config mismatches for maps, difficulty, and currencies.
6. Validate the new utility-tool runtime path before broader feature expansion.
7. Run full manual gameplay validation from lobby to return-to-lobby.
8. After validation is stable, continue launch preparation and publish work.

## 9. Guardrails For Next Implementation Session

Use these guardrails when continuing work:

- Treat `REPORTS.md` as the runtime source of truth.
- Treat `CANONICAL_SPECIFICATIONS_v2.md` as the target to converge toward.
- Do not trust old phase labels in `CLAUDE.md` as current status.
- Do not patch legacy duplicate trees unless the active runtime path also requires it.
- Prefer fixing wiring and source-of-truth conflicts before adding new feature layers.
- Avoid refactoring stable systems unless they are directly causing runtime inconsistency.

## 10. Final Baseline

Always update this section whenever the baseline changes.

Percentage format rule:

- Use a percentage range, not a single fixed number.
- Example format: `76% - 77%`

Short version for future reference:

- PASRAHPHOBIA is about `81% - 82%` complete.
- The project is in `late Phase 6 / early Phase 7 consistency lock`.
- Core gameplay and many supporting systems are already real and active.
- The main blocker is now validation truth and completion-layer gaps, not the absence of the core loop.
- The safest next move is cleanup and validation before broad feature expansion.

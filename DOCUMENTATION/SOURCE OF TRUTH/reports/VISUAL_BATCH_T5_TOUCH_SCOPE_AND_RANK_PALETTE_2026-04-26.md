# Visual Batch T5 Touch Scope + Rank Palette 2026-04-26

## Scope

- Continue visual-only lane after Android staging readability fix.
- Narrow touch header suppression so it only targets `Preparation/Loading` staging context.
- Align ranked visual accent palette to canonical HTML reference tokens (bronze/silver/gold/platinum/diamond/oni/dragon/legend/master).
- Keep runtime behavior/system architecture unchanged.

## Reference Source

- `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\asset-ui-ux-gui\acuan-visual-ui-ux-gui-pasrahphobia-ui.html`
- `C:\Projects\ROBLOX\PASRAHPHOBIA\asset mentah\pasrahphobia-ui.html`

Token alignment used from reference root variables:

- `rank-bronze = #c87941`
- `rank-silver = #8fa8b8`
- `rank-gold = #d4a820`
- `rank-platinum = #40c8e0`
- `rank-diamond = #40a0ff`
- `rank-oni = #e04020`
- `rank-dragon = #20e080`
- `rank-legend = #e0c040`
- `rank-master = #e080ff`

## Files Changed

- `src/client/UI/Main.lua`
- `DOCUMENTATION/SOURCE OF TRUTH/TASK_ACTIVE.md`

## Change Summary

1. Match header touch suppression scoping:
   - `UISystem:_suppressTouchMatchHeaderBodyText` now accepts `viewState`.
   - Suppression exits early unless `viewState` is `Preparation` or `Loading`.
   - `hideHeaderBodyText` in `_refreshBasicMatchPanel` changed from broad touch rule to staging-only rule.
   - Result: overlap mitigation remains active for staging lane, while non-staging touch header body text is no longer force-hidden.

2. Rank visual palette alignment:
   - Added `RANK_VISUAL_COLORS` map aligned to canonical HTML rank color tokens.
   - Added `resolveRankVisualAccent(rankLabel)` with alias handling (`sang ahli`, `bayi`, Indonesian/English variants).
   - `LeaderboardUI` rank badge/row accents now derive from resolved rank accent.
   - Ranked room preview cards now use accent-derived preview tones instead of fixed brown values.

3. Room Browser ranked tier visual:
   - Added `TierStroke` to `RankedTierLabel`.
   - `RankedTierLabel` background/text/stroke now adapt to resolved host tier accent.

4. Rank action tone alignment:
   - `BUTTON_TONES.rank` updated from older green-leaning tone to gold rank-accent tone aligned with reference token direction.

5. Shop filter visual hierarchy:
   - `ShopUI` status badge base color now follows active filter (`MM`, `PP`, `Robux`, `Owned`) for faster context scanning.
   - Filter button tone for `Robux` changed from success-like green to warning lane to avoid misleading safe-state visual semantics.

## Verification

- `scripts/release-preflight.ps1 -Json`
  - `buildOk=true`
  - `canonicalMirrorOk=true`
  - manual blocker remains:
    - `smoke test 2 client nyata: owner task manual (eksekusi user)`

## Pending

- Owner visual retest on non-touch/desktop presentation after touch-scope change.
- Continue final visual pass for canonical panels (Rank/EXP/Profiling/Daily/Gacha/Shop/RoyalPass/MM/PP/Item/Hidden Gems) against HTML references.

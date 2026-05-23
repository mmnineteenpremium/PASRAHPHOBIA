# Mission, RoyalPass, Reward Implementation Audit - 2026-05-21

Progress marker: n=80%
Branch: brian-second-final
Place file: PASRAHPHOBIA.rbxlx
Owner pass status: PENDING owner confirmation
Orchestrator pass status: NOT FINAL; audit-only slice, no owner pass requested yet

## Scope

Read/detect only against `DOCUMENTATION/SOURCE OF TRUTH/MISSION, ROYALPASS, REWARD`.
This file records what is already implemented in the project, what is partial, and what is still a gap.

## Implemented

### Daily engagement canonical system - PASS

- `src/ServerScriptService/Server/DailyEngagementSystem/Service.lua` exists and is the active owner for:
  - `data.daily`
  - `data.royalPass`
  - `data.gacha`
  - `data.gachaTickets`
- It resolves existing systems instead of creating a parallel route:
  - `EventBus`
  - `DataPersistenceService`
  - `EconomySystem`
  - `ProgressionSystem`
  - `InventorySystem`
- Evidence:
  - `Service.lua:311-316` resolves dependencies.
  - `Service.lua:372-386` loads persisted daily/royalPass/gacha data through `DataPersistenceService`.
  - `Service.lua:437-443` saves daily/royalPass/gacha data through `SaveProfile`.
  - `Service.lua:1021-1063` grants MM/PP/XP/cosmetic/ticket rewards through existing systems.

### SystemRegistry integration - PASS

- `DailyEngagementSystem` is registered in `LiveServiceSystems`.
- Load order is compatible with source-of-truth:
  - `InventorySystem` loads in `CoreSystems`.
  - `EconomySystem`, `ProgressionSystem`, then `DailyEngagementSystem` load in `LiveServiceSystems`.
- Legacy state owners are disabled:
  - `DailyCheckinSystem`
  - `DailyMissionSystem`
  - `RoyalPassSystem`
- Evidence:
  - `src/ServerScriptService/Server/Core/SystemRegistry.lua:27-30`
  - `src/ServerScriptService/Server/Core/SystemRegistry.lua:82-104`
  - `src/ServerScriptService/Server/Core/SystemRegistry.lua:178`

### Config files - PASS

- Present:
  - `src/shared/Config/DailyMissionConfig.lua`
  - `src/shared/Config/CheckinRewardConfig.lua`
  - `src/shared/Config/RoyalPassConfig.lua`
  - `src/shared/Config/GachaConfig.lua`
- Evidence:
  - `DailyMissionConfig.lua:3` daily pool.
  - `DailyMissionConfig.lua:142` challenge pool.
  - `DailyMissionConfig.lua:212` `GetTodaysMissions`.
  - `CheckinRewardConfig.lua:3-60` 7-day streak, 30-day milestone, streak multiplier, reset hour.
  - `RoyalPassConfig.lua:3-17` season length, tiers, premium price, XP per tier, XP sources.
  - `RoyalPassConfig.lua:19-74` generated tier reward table.
  - `GachaConfig.lua:3-19` pity thresholds, rates, costs.
  - `GachaConfig.lua:21-77` gacha pool and rarity indexes.

### RemoteEvents - PASS

Required remotes exist in `src/ReplicatedStorage/RemoteEvents`:

- `DailyEngagementSync.model.json`
- `DailyCheckinRequest.model.json`
- `DailyMissionClaimRequest.model.json`
- `GachaPullRequest.model.json`
- `GachaResult.model.json`
- `RoyalPassTierUp.model.json`

Also present:

- `RoyalPassEvent.model.json`

### Daily mission and check-in flow - PASS

- Daily missions are generated from config.
- Daily check-in grants streak/milestone rewards.
- Royal Pass XP uses config values instead of hardcoded reward constants in service logic.
- Evidence:
  - `DailyEngagementSystem/Service.lua:500-542` resets/generates daily missions.
  - `DailyEngagementSystem/Service.lua:544-615` handles check-in and publishes reward events.
  - `DailyEngagementSystem/Service.lua:733-795` claims mission rewards.
  - `DailyEngagementSystem/Service.lua:810-847` grants Royal Pass XP from config.

### Royal Pass progression and rewards - PASS

- Royal Pass state uses `RoyalPassConfig`.
- Tier reward claim supports free and premium tracks.
- Tier-up events are published and sent to client.
- Evidence:
  - `DailyEngagementSystem/Service.lua:850-890` claims free/premium tier rewards.
  - `DailyEngagementSystem/Service.lua:875-890` publishes `RoyalPassTierUnlocked` / `RoyalPassTierUp`.

### Gacha core flow - PASS

- Gacha supports ticket/MM payment.
- Paid random items policy gate exists before spend/grant.
- Soft pity, hard pity, and guaranteed epic logic are implemented.
- Gacha results are granted through the same reward function.
- Evidence:
  - `DailyEngagementSystem/Service.lua:923-968` handles pull request and payment.
  - `DailyEngagementSystem/Service.lua:929-930` blocks when paid random items are restricted.
  - `DailyEngagementSystem/Service.lua:970-1019` pity and rarity logic.
  - `DailyEngagementSystem/Service.lua:1065-1074` grants pulled item/currency.

### EventBus and match progress - PASS

- Daily engagement subscribes to existing gameplay events.
- Match completion updates daily missions and grants Royal Pass XP from config.
- Evidence:
  - `DailyEngagementSystem/Controller.lua:201-206` subscription wrapper.
  - `DailyEngagementSystem/Controller.lua:209-231` player/remotes connections.
  - `DailyEngagementSystem/Service.lua:1342-1423` match-end mission/Royal Pass updates.

### Remote validation and cooldown - PASS

- Daily check-in, mission claim, and gacha remotes have server-side cooldown and optional security validation.
- Evidence:
  - `DailyEngagementSystem/Controller.lua:249-276`

### Shop/RoyalPass obstructing asset cleanup - PASS local/source

- `PASRAHPHOBIA-ASSETID.md` with hyphen is not present.
- Actual manifest is `C:\Projects\ROBLOX\PASRAHPHOBIA\PASRAHPHOBIA_ASSETID.md/json`.
- Usable button border asset:
  - `96807162342543`, used as `rbxassetid://96807162342543`.
- Private/unverified RoyalPass/Shop surface IDs were removed/hidden from current source/UI paths:
  - `76420084860647`
  - `135564383987942`
  - `98127480673917`
  - `90268220179568`
  - `79062908978656`
  - `124067893180355`
  - `105312181896893`
- Evidence:
  - `src/client/UI/Main.lua:1000-1002`
  - `src/ReplicatedStorage/Assets/VisualTemplates.model.json:3810`
  - `rg` over `src/client/UI/Main.lua`, `src/StarterGui`, `src/ReplicatedStorage/Assets` only finds `96807162342543`.

## Partial

### Monetization - PARTIAL

Implemented:

- Marketplace bridge exists in `ShopSystem`.
- `ProcessReceipt` is wired for Developer Products.
- GamePass prompt finished flow is wired.
- Client prompts GamePass/DeveloperProduct via `MarketplaceService`.
- `ShopMarketplaceConfig.lua` has official-looking product/pass IDs for brian lane.

Evidence:

- `ShopSystem/Controller.lua:355-360` GamePass finished + `ProcessReceipt`.
- `ShopSystem/Controller.lua:385-417` owned GamePass sync.
- `ShopSystem/Controller.lua:451-490` Developer Product receipt grant.
- `ShopSystem/Controller.lua:701-723` marketplace prompt intent.
- `ShopSystem/Service.lua:634-660` purchase intent resolution.
- `ShopSystem/Service.lua:851-905` marketplace grant.
- `src/client/UI/Main.lua:16506-16514` client marketplace prompt.
- `ShopMarketplaceConfig.lua:14-55` current pass/product IDs.

Not fully aligned to `08_MONETIZATION_MANAGER.md`:

- No exact `MonetizationConfig.lua` file detected; project uses `ShopMarketplaceConfig.lua` + `ShopCatalog.lua`.
- GamePass items are present but disabled by config:
  - `royalpass_premium_track`
  - `class_dukun_unlock`
  - `class_detective_unlock`
  - `lifetime_bonus_pass`
- Current pass/product names and prices do not match all source-of-truth monetization rows.
- Subscription plan is not implemented.
- Season skip products are not implemented in current config.

### Royal Pass cosmetic asset registry - PARTIAL

Implemented:

- Royal Pass rewards produce `cosmeticId`, `seasonBadgeId`, and `exclusiveEmoteId`.
- `DailyEngagementSystem` grants those IDs via `InventorySystem:GrantItem`.
- `src/shared/Config/CosmeticRegistry.lua` now enumerates every Royal Pass reward ID from `RoyalPassConfig` and `assets/manifest/ASSET_MANIFEST.json` with tier/track/sourceKey/file metadata.
- `DailyEngagementSystem` now looks up `CosmeticRegistry` when granting cosmetic rewards and forwards registry metadata into the inventory grant payload.

Gap:

- Uploaded Roblox asset IDs are still pending for most Royal Pass rewards.
- Therefore ownership/model/icon mapping for generated reward IDs such as `royal_free_tier_5` / `royal_premium_tier_5` remains unconfirmed live even though the source registry now exists and is consumed by reward grants.

### UI consumption - PARTIAL

Implemented:

- `Main.lua` consumes `DailyEngagementSync`, `RoyalPassEvent`, `RoyalPassTierUp`, check-in, mission claim, and gacha remotes.
- Authored `RoyalPassUI` binding exists.

Gap:

- This audit slice did not run a dedicated end-to-end Mission claim / Royal Pass tier-up visual flow.
- Previous visual smoke only confirmed spawn stability and that obstructing Shop/RoyalPass private images are gone locally.

## Gaps / Blockers

### Live publish for latest spawn/surface fix - BLOCKED

- Current spawn/surface repair is verified locally but not confirmed live.
- Open Cloud direct `.rbxlx` upload failed with `413 Payload Too Large`.
- Rojo 7.7.0-rc.1 build/publish crashes in `rbx_binary`.
- Rojo 7.6.1 cannot parse current JSON model structure.
- Studio UI publish and Studio local `Server & Clients` child flow require Roblox 2-Step Verification.

### Local Studio Server & Clients - BLOCKED

- Test dropdown `Server...` with 2 players was used.
- Child Studio stopped at Roblox 2-Step Verification.
- Smoke evidence exists, but local multi-client PASS cannot be claimed.

### Mobile online multi-client - BLOCKED

- Mobile MCP returned no devices.
- `Samsung-N960` / iOS lane not detected in this session.

## Verification Commands Run

- `rg --files` over source-of-truth folder and source tree.
- `rg`/`Select-String` for DailyEngagement, RoyalPass, Gacha, remotes, registry, monetization, and asset IDs.
- JSON parse previously passed for edited UI model files.
- `rojo sourcemap default.project.json` previously passed for current spawn/surface source slice.

## Stop / Blocker Reason

Not stopped permanently. This audit slice is complete enough to record implementation status at n=80%.

The remaining blockers are validation/publish lanes, not a lack of code evidence:

- owner 2FA needed for Studio child/publish lanes, or
- separate Rojo serializer fix needed for source publish, and
- physical mobile device availability needed for mobile online smoke.

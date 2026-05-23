# Brian Monetization Bootstrap - 2026-05-20

Branch/runtime target: `brian-second-final`  
Universe: `10138560838`  
Root place: `89787959603872`  
Owner lane: `briankotak`

## Result

Brian-lane Roblox monetization IDs were created and wired into `src/shared/DataTypes/ShopMarketplaceConfig.lua`.

Bridge code was already present:

- `MarketplaceService.ProcessReceipt` in `src/ServerScriptService/Server/ShopSystem/Controller.lua`
- `MarketplaceService.PromptGamePassPurchaseFinished` in `src/ServerScriptService/Server/ShopSystem/Controller.lua`
- GamePass ownership restore through `UserOwnsGamePassAsync`
- final grant path through `ShopSystem.Service:GrantMarketplacePurchase`

## Developer Products

These are repeatable currency products and are enabled in source.

| Item | ProductId | Price | Grant |
| --- | ---: | ---: | --- |
| `pp_pack_small` | `3595563338` | `29` | `PP +10` |
| `pp_pack_standard` | `3595563345` | `79` | `PP +25` |
| `pp_pack_large` | `3595563353` | `149` | `PP +55` |
| `mm_pack_small` | `3595563373` | `19` | `MM +2500` |
| `mm_pack_medium` | `3595563381` | `49` | `MM +8000` |
| `mm_pack_large` | `3595563400` | `99` | `MM +18000` |

## Game Pass Entitlements

These permanent entitlement GamePasses exist in the Brian universe, but remain disabled in source and `isForSale=false` until the fairness/non-pay-to-win review is explicitly cleared.

| Item | GamePassId | Price | Source status |
| --- | ---: | ---: | --- |
| `royalpass_premium_track` | `1846924611` | `149` | `enabled=false` |
| `class_dukun_unlock` | `1847326612` | `89` | `enabled=false` |
| `class_detective_unlock` | `1846726626` | `89` | `enabled=false` |
| `lifetime_bonus_pass` | `1846342643` | `249` | `enabled=false` |

`autoEnableWhenIdPresent` is now `false` so the four entitlement hold items do not become purchasable just because official IDs exist.

## Validation

- Studio `MarketplaceService:GetProductInfo` confirmed the six currency IDs resolve as `Enum.InfoType.Product` with the expected names, prices, and `isForSale=true`.
- Studio `MarketplaceService:GetProductInfo` confirmed the four entitlement IDs resolve as `Enum.InfoType.GamePass` with `isForSale=false`.
- Studio active `ReplicatedStorage.Shared.DataTypes.ShopCatalog` resolves `10` Robux items: `6` enabled DeveloperProducts and `0` enabled GamePasses.
- `powershell -ExecutionPolicy Bypass -File scripts\audit-marketplace-mapping.ps1 -Strict -Json` passed.
- `.\.aftman\bin\rojo.exe build default.project.json --output .codex\tmp\brian-monetization-build.rbxlx` passed.


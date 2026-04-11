# Persistence Result 2026-04-11 Real DataStore

## Meta

- date: `2026-04-11`
- environment: published Studio place with real DataStore override
- place: `PASRAHPHOBIA`
- `PlaceId`: `113010869463813`
- `GameId`: `9802743087`
- account: `ZyraaaVex`
- `UserId`: `10576163165`
- Studio flag: `ReplicatedStorage.PasrahUseStudioDataStore = true`

## Timeline

- initial run on `2026-04-11` proved:
  - real DataStore mode was active
  - profile persistence worked
  - inventory and cosmetic equip persistence worked
  - wallet `MM/PP` reverted on reconnect
- follow-up fix wired `EconomySystem` wallet load/save into the canonical persistence owner and added save checkpoints on:
  - player join
  - currency grant
  - currency spend
  - player removal
  - Studio shutdown (`BindToClose`)
- rerun in the same published place now passes end-to-end.

## Fix Applied

- source changes:
  - `src/ServerScriptService/Server/EconomySystem/Service.lua`
  - `src/ServerScriptService/Server/EconomySystem/Controller.lua`
- runtime behavior added:
  - wallet load from persisted profile during `PlayerAdded`
  - debounced wallet save after `MM/PP/Robux` mutations
  - final wallet flush during `PlayerRemoving`
  - Studio `BindToClose` save loop to avoid local play shutdown loss

## Rerun Diagnostics Before Mutation

- `GetPersistenceMode`:
  - `mode=datastore hasDataStore=true allowStudioDataStore=true trackedPlayers=1 schemaVersion=2 lastLoadSchema=2 lastSaveSchema=none`
- wallet before mutation:
  - `MM=2722 PP=19 Robux=0`
- profile before mutation:
  - `level=1 rank=Bayi III totalMatches=0 totalWins=0 winRate=0 favoriteTool=GerakanGaib gallery=3 bio=persist-wallet-fix-1775846551`
- cosmetic before mutation:
  - `owned=2 equipped=2`
- ownership probe before mutation:
  - `cos_accessory_wardingcharm`
    - `MM=2722 PP=19 Robux=0 inventory=2 cosmetics=2 ownedCount=2 item=cos_accessory_wardingcharm hasItem=true ownsCosmetic=true ownedSnapshot=true`
  - `cos_head_duskmask`
    - `MM=2722 PP=19 Robux=0 inventory=2 cosmetics=2 ownedCount=2 item=cos_head_duskmask hasItem=false ownsCosmetic=false ownedSnapshot=false`

## Rerun Mutations Applied

- `GrantCurrency MM +2222`
- `GrantCurrency PP +7`
- `UpdateProfileSnapshot`:
  - `bio = persist-wallet-fix-1775847013`
  - `favoriteTool = GerakanGaib`
  - `galleryItems = 3`
- `ProcessShopPurchase`:
  - item `cos_head_duskmask`
- `EquipCosmeticSnapshot`:
  - item `cos_head_duskmask`
  - slot `head`

## State Before Disconnect

- `GetPersistenceMode` after mutation:
  - `mode=datastore hasDataStore=true allowStudioDataStore=true trackedPlayers=1 schemaVersion=2 lastLoadSchema=2 lastSaveSchema=2`
- wallet after mutation:
  - `MM=4094 PP=26 Robux=0`
- profile after mutation:
  - `level=1 rank=Bayi III totalMatches=0 totalWins=0 winRate=0 favoriteTool=GerakanGaib gallery=3 bio=persist-wallet-fix-1775847013`
- cosmetic after mutation:
  - `owned=3 equipped=3`
- item ownership after mutation:
  - `MM=4094 PP=26 Robux=0 inventory=3 cosmetics=3 ownedCount=3 item=cos_head_duskmask hasItem=true ownsCosmetic=true ownedSnapshot=true`

## State After Reconnect

- `GetPersistenceMode` after reconnect:
  - `mode=datastore hasDataStore=true allowStudioDataStore=true trackedPlayers=1 schemaVersion=2 lastLoadSchema=2 lastSaveSchema=none`
- wallet after reconnect:
  - `MM=4094 PP=26 Robux=0`
- profile after reconnect:
  - `level=1 rank=Bayi III totalMatches=0 totalWins=0 winRate=0 favoriteTool=GerakanGaib gallery=3 bio=persist-wallet-fix-1775847013`
- cosmetic after reconnect:
  - `owned=3 equipped=3`
- item ownership after reconnect:
  - `MM=4094 PP=26 Robux=0 inventory=3 cosmetics=3 ownedCount=3 item=cos_head_duskmask hasItem=true ownsCosmetic=true ownedSnapshot=true`

## Interpretation

- Real DataStore path is confirmed live in the published Studio place.
- `ProfileSystem` persistence is working.
- `InventorySystem` / cosmetic ownership persistence is working.
- `EconomySystem` wallet persistence is now working:
  - granted and spent `MM/PP` values survived reconnect exactly.
- The original wallet-reset bug is closed in the active runtime.

## Additional Runtime Signals

- mutation-phase persistence signal:
  - `lastSaveSchema=2` confirmed the wallet payload flushed before disconnect
- reconnect-phase persistence signal:
  - `lastLoadSchema=2` confirmed the saved profile was loaded again on session boot
- note:
  - `GetPublishReadiness` was not the authority for this verification path
  - the pass decision here is based on a real reconnect and state comparison in the published place

## Final Status

- status: `PASS`
- passed:
  - real datastore mode
  - profile persistence
  - inventory persistence
  - cosmetic equip persistence
  - wallet `MM/PP` retention across reconnect
- remaining blocker outside this report:
  - multiplayer smoke `2` client nyata
  - legal/licensing final review

local Service = {}
Service.__index = Service
local Services = require(script.Parent.Parent.Core.Services)

local function resolveEconomyService(deps)
    local economy = Services.Get(deps, "EconomySystem")
    if type(economy) ~= "table" then
        return nil
    end
    if type(economy.SpendCurrency) == "function" then
        return economy
    end
    if type(economy.Service) == "table" and type(economy.Service.SpendCurrency) == "function" then
        return economy.Service
    end
    return nil
end

local function resolveInventoryService(deps)
    local inventory = Services.Get(deps, "InventorySystem")
    if type(inventory) ~= "table" then
        return nil
    end
    if type(inventory.AddCosmeticOwnership) == "function" then
        return inventory
    end
    if type(inventory.Service) == "table" and type(inventory.Service.AddCosmeticOwnership) == "function" then
        return inventory.Service
    end
    return nil
end

local function resolvePersistenceService(deps)
    local persistence = Services.Get(deps, "DataPersistenceService")
        or Services.Get(deps, "DataPersistenceSystem")
    if type(persistence) ~= "table" then
        return nil
    end
    if type(persistence.SaveInventory) == "function" then
        return persistence
    end
    if type(persistence.Service) == "table" and type(persistence.Service.SaveInventory) == "function" then
        return persistence.Service
    end
    return nil
end

local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
    if type(eventBus) ~= "table" then
        return nil
    end
    if type(eventBus.Publish) == "function" then
        return eventBus
    end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then
        return eventBus.Service
    end
    return nil
end

local function toUserId(player)
    if type(player) == "number" then
        return player
    end
    if typeof(player) == "Instance" and player:IsA("Player") then
        return player.UserId
    end
    return nil
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._economy = resolveEconomyService(self._deps)
    self._inventory = resolveInventoryService(self._deps)
    self._persistence = resolvePersistenceService(self._deps)
    self._eventBus = resolveEventBus(self._deps)
    self._cooldownSeconds = tonumber(self._deps.ShopPurchaseCooldownSeconds) or 0.75
    return self
end

function Service:Init()
    self._state:Set("catalog", self._state:Get("catalog") or {})
    self._state:Set("purchaseHistory", self._state:Get("purchaseHistory") or {})
    self._state:Set("cooldowns", self._state:Get("cooldowns") or {})
end

function Service:Start()
    -- runtime hooks for shop analytics if needed
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:GetCatalog()
    return self._state:Get("catalog") or {}
end

function Service:_ownsItem(player, itemId)
    if not self._inventory or type(self._inventory.GetInventory) ~= "function" then
        return false
    end
    local inventory = self._inventory:GetInventory(player)
    for _, ownedItemId in ipairs(inventory) do
        if ownedItemId == itemId then
            return true
        end
    end
    return false
end

function Service:_ownsCosmetic(player, cosmeticId)
    if not self._inventory or type(self._inventory.OwnsCosmetic) ~= "function" then
        return false
    end
    return self._inventory:OwnsCosmetic(player, cosmeticId)
end

function Service:_getBalance(player, currency)
    if not self._economy or type(self._economy.GetBalance) ~= "function" then
        return nil
    end
    local wallet = self._economy:GetBalance(player)
    if type(wallet) ~= "table" then
        return nil
    end
    return wallet[currency]
end

function Service:_inCooldown(userId)
    local cooldowns = self._state:Get("cooldowns") or {}
    local now = os.clock()
    local lastAt = cooldowns[userId]
    if type(lastAt) == "number" and (now - lastAt) < self._cooldownSeconds then
        return true
    end
    return false
end

function Service:_setCooldown(userId)
    local cooldowns = self._state:Get("cooldowns") or {}
    cooldowns[userId] = os.clock()
    self._state:Set("cooldowns", cooldowns)
end

function Service:ValidatePurchase(player, itemId)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end
    if type(itemId) ~= "string" or itemId == "" then
        return false, "invalid_item_id"
    end

    local itemDef = self:GetCatalog()[itemId]
    if type(itemDef) ~= "table" then
        return false, "missing_item"
    end
    local price = tonumber(itemDef.price)
    if not price or price <= 0 then
        return false, "invalid_price"
    end

    if self:_inCooldown(userId) then
        return false, "purchase_cooldown"
    end

    if itemDef.type == "cosmetic" and self:_ownsCosmetic(player, itemId) then
        return false, "already_owned"
    end
    if (itemDef.type == "equipment" or itemDef.type == "item") and self:_ownsItem(player, itemId) then
        return false, "already_owned"
    end

    if not self._economy then
        return false, "missing_economy"
    end
    local balance = self:_getBalance(player, "MM")
    if type(balance) == "number" and balance < price then
        return false, "insufficient_funds"
    end

    return true, nil, itemDef, userId
end

function Service:_persistInventory(player, userId)
    if self._inventory and type(self._inventory.GetSnapshotForPersistence) == "function" and self._persistence then
        local snapshot = self._inventory:GetSnapshotForPersistence(player)
        self._persistence:SaveInventory(userId, snapshot)
        return
    end
    if self._inventory and type(self._inventory.SavePlayerData) == "function" then
        self._inventory:SavePlayerData(player)
    end
end

function Service:ProcessPurchase(player, itemId)
    local valid, err, itemDef, userId = self:ValidatePurchase(player, itemId)
    if not valid then
        return false, err
    end

    local price = math.floor(itemDef.price)
    local ok, spendErr = self._economy:SpendCurrency(player, "MM", price, "ShopPurchase")
    if not ok then
        return false, spendErr
    end

    if not self._inventory then
        return false, "missing_inventory"
    end

    if itemDef.type == "cosmetic" then
        if type(self._inventory.AddCosmeticOwnership) ~= "function" then
            return false, "missing_inventory_cosmetic_grant"
        end
        self._inventory:AddCosmeticOwnership(player, itemId)
    else
        if type(self._inventory.StoreItem) ~= "function" then
            return false, "missing_inventory_item_grant"
        end
        self._inventory:StoreItem(player, itemId)
    end

    local history = self._state:Get("purchaseHistory") or {}
    history[userId] = history[userId] or {}
    local record = {
        itemId = itemId,
        itemType = itemDef.type or "item",
        price = price,
        currency = "MM",
        purchasedAt = os.time(),
    }
    table.insert(history[userId], record)
    self._state:Set("purchaseHistory", history)
    self:_setCooldown(userId)
    self:_persistInventory(player, userId)

    local purchasedPayload = {
        player = player,
        userId = userId,
        itemId = itemId,
        itemType = itemDef.type or "item",
        price = price,
        currency = "MM",
    }
    self:_publish("ItemPurchased", {
        player = purchasedPayload.player,
        userId = purchasedPayload.userId,
        itemId = purchasedPayload.itemId,
        itemType = purchasedPayload.itemType,
        price = purchasedPayload.price,
        currency = purchasedPayload.currency,
    })
    return true, nil, purchasedPayload
end

function Service:OnCurrencyEarned(payload)
    local player = payload and payload.player
    local amount = payload and payload.amount
    if not player or type(amount) ~= "number" then
        return
    end
    -- Keep lightweight runtime signal for analytics/debugging.
    self._state:Set("lastCurrencyEarned", {
        userId = toUserId(player),
        amount = amount,
        at = os.time(),
    })
end

return Service

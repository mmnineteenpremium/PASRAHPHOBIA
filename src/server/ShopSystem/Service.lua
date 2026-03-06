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
    self._eventBus = resolveEventBus(self._deps)
    return self
end

function Service:Init()
    self._state:Set("purchasesByUserId", {})
end

function Service:Start()
    -- runtime hooks for shop analytics if needed
end

function Service:Stop()
    -- cleanup if required
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:GetPrice(cosmeticId)
    local available = self._state:Get("availableCosmetics") or {}
    return available[cosmeticId]
end

function Service:GetItemPrice(itemId)
    local available = self._state:Get("availableItems") or {}
    return available[itemId]
end

function Service:PurchaseItem(player, itemId)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end
    local price = self:GetItemPrice(itemId)
    if not price then
        return false, "missing_item"
    end
    if not self._economy then
        return false, "missing_economy"
    end
    local ok, err = self._economy:SpendCurrency(player, "MM", price, "ShopPurchase")
    if not ok then
        return false, err
    end
    if not self._inventory then
        return false, "missing_inventory"
    end
    if type(self._inventory.StoreItem) ~= "function" then
        return false, "missing_inventory_store"
    end
    self._inventory:StoreItem(player, itemId)
    local purchases = self._state:Get("purchasesByUserId") or {}
    purchases[userId] = purchases[userId] or {}
    table.insert(purchases[userId], itemId)
    self._state:Set("purchasesByUserId", purchases)
    self:_publish("ItemPurchased", { player = player, itemId = itemId, price = price })
    return true
end

function Service:PurchaseCosmetic(player, cosmeticId)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end
    local price = self:GetPrice(cosmeticId)
    if not price then
        return false, "missing_cosmetic"
    end
    if not self._economy then
        return false, "missing_economy"
    end
    local ok, err = self._economy:SpendCurrency(player, "MM", price, "ShopPurchase")
    if not ok then
        return false, err
    end
    if not self._inventory then
        return false, "missing_inventory"
    end
    self._inventory:AddCosmeticOwnership(player, cosmeticId)
    local purchases = self._state:Get("purchasesByUserId") or {}
    purchases[userId] = purchases[userId] or {}
    table.insert(purchases[userId], cosmeticId)
    self._state:Set("purchasesByUserId", purchases)
    self:_publish("CosmeticPurchased", { player = player, cosmeticId = cosmeticId, price = price })
    return true
end

return Service

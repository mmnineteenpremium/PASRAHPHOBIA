local Service = {}
Service.__index = Service
local Services = require(script.Parent.Parent.Core.Services)

local function resolveEventBus(deps)
    local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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
    self._eventBus = resolveEventBus(self._deps)
    self._persistence = resolvePersistenceService(self._deps)
    return self
end

function Service:Init()
    self._state:Set("playerItems", {})
    self._state:Set("cosmeticOwnership", {})
    self._state:Set("unlockedItems", {})
    self._state:Set("equipmentSlots", {})
end

function Service:Start()
    -- runtime hooks can be initialized here.
end

function Service:Stop()
    -- cleanup if needed.
end

function Service:_getTable(key)
    local data = self._state:Get(key)
    if not data then
        data = {}
        self._state:Set(key, data)
    end
    return data
end

local function cloneDict(source)
    local result = {}
    for k, v in pairs(source or {}) do
        result[k] = v
    end
    return result
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:UnlockItem(player, itemId)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end
    local unlocked = self:_getTable("unlockedItems")
    unlocked[userId] = unlocked[userId] or {}
    if unlocked[userId][itemId] then
        return true
    end
    unlocked[userId][itemId] = true
    self:_publish("InventoryUpdated", { player = player, itemId = itemId, reason = "unlock" })
    return true
end

function Service:AddCosmeticOwnership(player, cosmeticId)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end
    local owned = self:_getTable("cosmeticOwnership")
    owned[userId] = owned[userId] or {}
    owned[userId][cosmeticId] = true
    self:_publish("CosmeticOwnershipChanged", { player = player, cosmeticId = cosmeticId })
    return true
end

function Service:OwnsCosmetic(player, cosmeticId)
    local userId = toUserId(player)
    if not userId then
        return false
    end
    local owned = self:_getTable("cosmeticOwnership")
    return owned[userId] and owned[userId][cosmeticId] == true
end

function Service:GetOwnedCosmetics(player)
    local userId = toUserId(player)
    if not userId then
        return {}
    end
    local owned = self:_getTable("cosmeticOwnership")
    local cv = owned[userId] or {}
    local list = {}
    for cosmeticId in pairs(cv) do
        table.insert(list, cosmeticId)
    end
    return list
end

function Service:SetPersistenceService(persistence)
    self._persistence = persistence
end

local function cloneMap(source)
    if type(source) ~= "table" then
        return {}
    end
    local result = {}
    for key, value in pairs(source) do
        result[key] = value
    end
    return result
end

function Service:GetSnapshotForPersistence(player)
    local userId = toUserId(player)
    if not userId then
        return {}
    end
    local inventory = self:_getTable("playerItems")
    local ownership = self:_getTable("cosmeticOwnership")
    local equipment = self:_getTable("equipmentSlots")
    local unlocked = self:_getTable("unlockedItems")
    return {
        items = cloneMap(inventory[userId] or {}),
        cosmetics = cloneMap(ownership[userId] or {}),
        equipment = cloneMap(equipment[userId] or {}),
        unlocked = cloneMap(unlocked[userId] or {}),
    }
end

function Service:GetInventory(player)
    local userId = toUserId(player)
    if not userId then
        return {}
    end
    local items = self:_getTable("playerItems")
    return items[userId] or {}
end

function Service:GetEquipmentSlots(player)
    local userId = toUserId(player)
    if not userId then
        return {}
    end
    local slots = self:_getTable("equipmentSlots")
    return cloneDict(slots[userId] or {})
end

function Service:AssignToSlot(player, slotName, itemId)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end
    local slots = self:_getTable("equipmentSlots")
    slots[userId] = slots[userId] or {}
    slots[userId][slotName] = itemId
    self:_publish("EquipmentUpdated", {
        player = player,
        slotName = slotName,
        itemId = itemId,
    })
    return true
end

function Service:LoadPlayerData(player)
    if not self._persistence then
        return
    end
    local userId = toUserId(player)
    if not userId then
        return
    end
    local data = self._persistence:LoadInventory(userId)
    if type(data) ~= "table" then
        return
    end
    if data.items then
        local inventory = self:_getTable("playerItems")
        inventory[userId] = data.items
        self._state:Set("playerItems", inventory)
    end
    if data.cosmetics then
        local ownership = self:_getTable("cosmeticOwnership")
        ownership[userId] = data.cosmetics
        self._state:Set("cosmeticOwnership", ownership)
    end
    if data.equipment then
        local slots = self:_getTable("equipmentSlots")
        slots[userId] = data.equipment
        self._state:Set("equipmentSlots", slots)
    end
    if data.unlocked then
        local unlocked = self:_getTable("unlockedItems")
        unlocked[userId] = data.unlocked
        self._state:Set("unlockedItems", unlocked)
    end
end

function Service:SavePlayerData(player)
    if not self._persistence then
        return
    end
    local userId = toUserId(player)
    if not userId then
        return
    end
    local snapshot = self:GetSnapshotForPersistence(player)
    self._persistence:SaveInventory(userId, snapshot)
end

function Service:StoreItem(player, itemId)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end
    local inventory = self:_getTable("playerItems")
    inventory[userId] = inventory[userId] or {}
    table.insert(inventory[userId], itemId)
    self:_publish("InventoryUpdated", {
        player = player,
        itemId = itemId,
        reason = "store",
    })
    return true
end

local function resolvePersistenceService(deps)
    local persistence = Services.Get(deps, "DataPersistenceService")
        or Services.Get(deps, "DataPersistenceSystem")
        or (deps and deps.PersistenceService)
    if type(persistence) ~= "table" then
        return nil
    end
    if type(persistence.LoadInventory) == "function" and type(persistence.SaveInventory) == "function" then
        return persistence
    end
    if type(persistence.Service) == "table"
        and type(persistence.Service.LoadInventory) == "function"
        and type(persistence.Service.SaveInventory) == "function" then
        return persistence.Service
    end
    return nil
end

return Service

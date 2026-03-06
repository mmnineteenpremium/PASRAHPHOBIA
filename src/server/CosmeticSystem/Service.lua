local Service = {}
Service.__index = Service
local Services = require(script.Parent.Parent.Core.Services)

local function resolveInventoryService(deps)
    local inventory = Services.Get(deps, "InventoryService") or Services.Get(deps, "InventorySystem")
    if type(inventory) ~= "table" then
        return nil
    end
    if type(inventory.OwnsCosmetic) == "function" then
        return inventory
    end
    if type(inventory.Service) == "table" and type(inventory.Service.OwnsCosmetic) == "function" then
        return inventory.Service
    end
    return nil
end

local function resolveLobbyService(deps)
    local lobby = Services.Get(deps, "LobbySocialHub")
    if type(lobby) ~= "table" then
        return nil
    end
    if type(lobby.ApplyCosmetic) == "function" then
        return lobby
    end
    if type(lobby.Service) == "table" and type(lobby.Service.ApplyCosmetic) == "function" then
        return lobby.Service
    end
    return lobby
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

local function cloneMap(source)
    local result = {}
    for key, value in pairs(source or {}) do
        result[key] = value
    end
    return result
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._inventory = resolveInventoryService(self._deps)
    self._profile = Services.Get(self._deps, "ProfileSystem")
    self._lobby = resolveLobbyService(self._deps)
    return self
end

function Service:Init()
    self._state:Set("equippedByUserId", {})
    self._state:Set("categories", self._deps.CosmeticCategories or self._state:Get("categories") or {})
end

function Service:Start()
    -- Event-driven cosmetic service.
end

function Service:Stop()
    -- No runtime resources to release currently.
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:GetEquipped(player)
    local userId = toUserId(player)
    if not userId then
        return {}
    end
    local equippedByUserId = self._state:Get("equippedByUserId") or {}
    return cloneMap(equippedByUserId[userId])
end

function Service:GetCosmeticCategory(cosmeticId)
    local categories = self._state:Get("categories") or {}
    return categories[cosmeticId]
end

function Service:GetEquippedByCategory(player, category)
    local equipped = self:GetEquipped(player)
    return equipped[category]
end

function Service:_syncWithLobby(player, cosmeticId, category)
    if self._lobby and type(self._lobby.ApplyCosmetic) == "function" then
        self._lobby:ApplyCosmetic(player, cosmeticId, category)
    end
end

function Service:EquipCosmetic(player, cosmeticId)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end
    if not self._inventory or not self._inventory:OwnsCosmetic(player, cosmeticId) then
        return false, "missing_cosmetic"
    end
    local category = self:GetCosmeticCategory(cosmeticId) or "default"
    local equippedByUser = self._state:Get("equippedByUserId") or {}
    equippedByUser[userId] = equippedByUser[userId] or {}
    equippedByUser[userId][category] = cosmeticId
    self._state:Set("equippedByUserId", equippedByUser)

    if self._profile and type(self._profile.SyncCosmetic) == "function" then
        self._profile:SyncCosmetic(player, cosmeticId)
    end

    self:_syncWithLobby(player, cosmeticId, category)
    self:_publish("CosmeticApplyRequested", {
        player = player,
        cosmeticId = cosmeticId,
        category = category,
    })
    self:_publish("CosmeticEquipped", {
        player = player,
        cosmeticId = cosmeticId,
        category = category,
    })
    return true
end

function Service:UnequipCosmetic(player, category)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end
    local equippedByUser = self._state:Get("equippedByUserId") or {}
    local slots = equippedByUser[userId]
    if not slots then
        return true
    end
    if category then
        slots[category] = nil
    else
        for key in pairs(slots) do
            slots[key] = nil
        end
    end
    self._state:Set("equippedByUserId", equippedByUser)
    self:_publish("CosmeticUnequipped", {
        player = player,
        category = category,
    })
    return true
end

return Service

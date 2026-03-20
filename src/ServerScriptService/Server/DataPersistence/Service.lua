local Service = {}
Service.__index = Service

local function resolveRegistry(deps)
    if type(deps) ~= "table" then
        return nil
    end
    return deps.Services or deps.ServiceRegistry
end

local function getService(registry, name)
    if type(registry) ~= "table" then
        return nil
    end
    if type(registry.GetService) == "function" then
        local value = registry:GetService(name)
        if value ~= nil then
            return value
        end
    end
    if type(registry.Get) == "function" then
        return registry:Get(name)
    end
    return nil
end

local function registerService(registry, name, service)
    if type(registry) ~= "table" then
        return
    end
    if getService(registry, name) ~= nil then
        return
    end
    if type(registry.RegisterService) == "function" then
        registry:RegisterService(name, service)
        return
    end
    if type(registry.Register) == "function" then
        registry:Register(name, service)
    end
end

local function clone(source)
    if type(source) ~= "table" then
        return source
    end
    local out = {}
    for key, value in pairs(source) do
        if type(value) == "table" then
            out[key] = clone(value)
        else
            out[key] = value
        end
    end
    return out
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._registry = resolveRegistry(self._deps)
    return self
end

function Service:Init()
    self._state:Set("playerData", self._state:Get("playerData") or {})
    self._state:Set("economyData", self._state:Get("economyData") or {})
    self._state:Set("inventoryData", self._state:Get("inventoryData") or {})
    self._state:Set("rankData", self._state:Get("rankData") or {})
    registerService(self._registry, "DataPersistence", self)
    -- Compatibility alias for systems still expecting DataPersistenceService.
    registerService(self._registry, "DataPersistenceService", self)
end

function Service:Start()
    -- Data persistence is request-driven.
end

function Service:Stop()
    self._state:Clear()
end

function Service:LoadPlayerData(playerId)
    local playerData = self._state:Get("playerData") or {}
    local economyData = self._state:Get("economyData") or {}
    local inventoryData = self._state:Get("inventoryData") or {}
    local rankData = self._state:Get("rankData") or {}
    return {
        player = clone(playerData[playerId] or {}),
        economy = clone(economyData[playerId] or {}),
        inventory = clone(inventoryData[playerId] or {}),
        rank = clone(rankData[playerId] or {}),
    }
end

function Service:SavePlayerData(playerId, data)
    local playerData = self._state:Get("playerData") or {}
    local economyData = self._state:Get("economyData") or {}
    local inventoryData = self._state:Get("inventoryData") or {}
    local rankData = self._state:Get("rankData") or {}

    playerData[playerId] = clone(data and data.player or {})
    economyData[playerId] = clone(data and data.economy or {})
    inventoryData[playerId] = clone(data and data.inventory or {})
    rankData[playerId] = clone(data and data.rank or {})

    self._state:Set("playerData", playerData)
    self._state:Set("economyData", economyData)
    self._state:Set("inventoryData", inventoryData)
    self._state:Set("rankData", rankData)
    return true
end

function Service:UpdatePlayerData(playerId, changes)
    local current = self:LoadPlayerData(playerId)
    current.player = current.player or {}
    current.economy = current.economy or {}
    current.inventory = current.inventory or {}
    current.rank = current.rank or {}

    for key, value in pairs(changes and changes.player or {}) do
        current.player[key] = value
    end
    for key, value in pairs(changes and changes.economy or {}) do
        current.economy[key] = value
    end
    for key, value in pairs(changes and changes.inventory or {}) do
        current.inventory[key] = value
    end
    for key, value in pairs(changes and changes.rank or {}) do
        current.rank[key] = value
    end
    return self:SavePlayerData(playerId, current)
end

function Service:LoadInventory(playerId)
    local inventoryData = self._state:Get("inventoryData") or {}
    return clone(inventoryData[playerId] or {})
end

function Service:SaveInventory(playerId, inventory)
    local inventoryData = self._state:Get("inventoryData") or {}
    inventoryData[playerId] = clone(inventory or {})
    self._state:Set("inventoryData", inventoryData)
    return true
end

function Service:LoadProfile(playerId)
    local playerData = self._state:Get("playerData") or {}
    local rankData = self._state:Get("rankData") or {}
    return {
        profile = clone(playerData[playerId] or {}),
        rank = clone(rankData[playerId] or {}),
    }
end

function Service:SaveProfile(playerId, profileData)
    local playerData = self._state:Get("playerData") or {}
    local rankData = self._state:Get("rankData") or {}
    local profile = profileData and profileData.profile
    local rank = profileData and profileData.rank

    if profile == nil and type(profileData) == "table" then
        profile = profileData
    end
    if rank == nil and type(profileData) == "table" and profileData.playerRank ~= nil then
        rank = {
            playerRank = profileData.playerRank,
            playerLevel = profileData.playerLevel,
            stars = profileData.stars,
            division = profileData.division,
            victories = profileData.victories,
        }
    end

    playerData[playerId] = clone(profile or {})
    rankData[playerId] = clone(rank or rankData[playerId] or {})
    self._state:Set("playerData", playerData)
    self._state:Set("rankData", rankData)
    return true
end

return Service

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Service = {}
Service.__index = Service

local function toKey(playerId)
    return tostring(playerId)
end

local function toProfileKey(playerId)
    return string.format("profile:%s", toKey(playerId))
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._dataStore = nil
    self._playersService = self._deps.Players or game:GetService("Players")
    self._inventoryService = self._deps.InventoryService
    self._autosaveInterval = self._state:Get("autosaveIntervalSeconds") or 60
    self._lastAutosave = 0
    self._trackedPlayers = {}

    if RunService:IsStudio() then
        warn("[DataPersistenceService] DataStore disabled in Studio")
        return self
    end

    local storeName = self._state:Get("dataStoreName") or "InventorySystemStore"
    self._dataStore = DataStoreService:GetDataStore(storeName)
    return self
end

function Service:SetInventoryService(inventoryService)
    self._inventoryService = inventoryService
end

function Service:Init()
    self._trackedPlayers = {}
    self._lastAutosave = 0
end

function Service:Start()
    self._lastAutosave = 0
end

function Service:Stop()
    self._trackedPlayers = {}
end

function Service:RegisterPlayer(player)
    if not player then
        return
    end
    self._trackedPlayers[player.UserId] = player
end

function Service:UnregisterPlayer(player)
    if not player then
        return
    end
    self._trackedPlayers[player.UserId] = nil
end

function Service:SavePlayer(player)
    if not player or not self._inventoryService then
        return false, "missing_dependency"
    end
    local snapshot = self._inventoryService:GetSnapshotForPersistence(player)
    return self:SaveInventory(player.UserId, snapshot)
end

function Service:AutosaveTick(deltaTime)
    self._lastAutosave += deltaTime or 0
    if self._lastAutosave < self._autosaveInterval then
        return
    end
    self._lastAutosave = 0
    for _, player in pairs(self._trackedPlayers) do
        self:SavePlayer(player)
    end
end

function Service:SaveInventory(playerId, inventoryData)
    if not self._dataStore then
        warn("DataPersistenceService: DataStore disabled in Studio")
        return false, "datastore_disabled"
    end
    local key = toKey(playerId)
    inventoryData = inventoryData or {}
    local success, err = pcall(function()
        self._dataStore:SetAsync(key, inventoryData)
    end)
    if not success then
        warn("DataPersistenceService: failed to save inventory for", playerId, err)
    end
    return success, err
end

function Service:LoadInventory(playerId)
    if not self._dataStore then
        warn("DataPersistenceService: DataStore disabled in Studio")
        return nil, "datastore_disabled"
    end
    local key = toKey(playerId)
    local success, data = pcall(function()
        return self._dataStore:GetAsync(key)
    end)
    if not success then
        warn("DataPersistenceService: failed to load inventory for", playerId, data)
        return nil, data
    end
    return data
end

function Service:SaveProfile(playerId, profileData)
    if not self._dataStore then
        warn("DataPersistenceService: DataStore disabled in Studio")
        return false, "datastore_disabled"
    end
    local key = toProfileKey(playerId)
    profileData = profileData or {}
    local success, err = pcall(function()
        self._dataStore:SetAsync(key, profileData)
    end)
    if not success then
        warn("DataPersistenceService: failed to save profile for", playerId, err)
    end
    return success, err
end

function Service:LoadProfile(playerId)
    if not self._dataStore then
        warn("DataPersistenceService: DataStore disabled in Studio")
        return nil, "datastore_disabled"
    end
    local key = toProfileKey(playerId)
    local success, data = pcall(function()
        return self._dataStore:GetAsync(key)
    end)
    if not success then
        warn("DataPersistenceService: failed to load profile for", playerId, data)
        return nil, data
    end
    return data
end

return Service

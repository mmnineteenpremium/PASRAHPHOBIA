local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Service = {}
Service.__index = Service

local function toKey(playerId)
    return tostring(playerId)
end

local function toProfileKey(playerId)
    return string.format("profile:%s", toKey(playerId))
end

local RANK_PROFILE_FIELDS = {
    playerLevel = true,
    playerRank = true,
    division = true,
    stars = true,
    victories = true,
}

local function clone(value)
    if type(value) ~= "table" then
        return value
    end

    local out = {}
    for key, nested in pairs(value) do
        out[key] = clone(nested)
    end
    return out
end

local function deepMerge(base, patch)
    local merged = clone(type(base) == "table" and base or {})
    for key, value in pairs(type(patch) == "table" and patch or {}) do
        if type(value) == "table" and type(merged[key]) == "table" then
            merged[key] = deepMerge(merged[key], value)
        else
            merged[key] = clone(value)
        end
    end
    return merged
end

local function hasRankFields(profileData)
    if type(profileData) ~= "table" then
        return false
    end

    for key in pairs(RANK_PROFILE_FIELDS) do
        if profileData[key] ~= nil then
            return true
        end
    end

    return type(profileData.rank) == "table"
end

local function extractProfilePatch(profileData)
    if type(profileData) ~= "table" then
        return {}
    end

    if type(profileData.profile) == "table" then
        return profileData.profile
    end

    if not hasRankFields(profileData) then
        return profileData
    end

    local patch = {}
    for key, value in pairs(profileData) do
        if key ~= "rank" and RANK_PROFILE_FIELDS[key] ~= true then
            patch[key] = value
        end
    end
    return patch
end

local function extractRankPatch(profileData)
    if type(profileData) ~= "table" then
        return nil
    end

    local patch = {}
    if type(profileData.rank) == "table" then
        patch = deepMerge(patch, profileData.rank)
    end

    for key in pairs(RANK_PROFILE_FIELDS) do
        if profileData[key] ~= nil then
            patch[key] = clone(profileData[key])
        end
    end

    if next(patch) == nil then
        return nil
    end

    return patch
end

local function normalizeProfileRecord(profileData)
    if type(profileData) ~= "table" then
        return {
            profile = {},
            rank = {},
        }
    end

    if type(profileData.profile) == "table" or type(profileData.rank) == "table" then
        return {
            profile = clone(profileData.profile or {}),
            rank = clone(profileData.rank or {}),
        }
    end

    return {
        profile = clone(extractProfilePatch(profileData)),
        rank = clone(extractRankPatch(profileData) or {}),
    }
end

local function shouldUseStudioDataStore(state, deps)
    if type(deps) == "table" and deps.AllowStudioDataStore == true then
        return true
    end

    if type(state) == "table" and type(state.Get) == "function" and state:Get("allowStudioDataStore") == true then
        return true
    end

    local replicatedStorage = type(deps) == "table" and deps.ReplicatedStorage or ReplicatedStorage
    if replicatedStorage and replicatedStorage:GetAttribute("PasrahUseStudioDataStore") == true then
        return true
    end

    return false
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._dataStore = nil
    self._useMockStore = false
    self._studioMockStore = self._state:Get("studioMockStore") or {
        inventory = {},
        profiles = {},
    }
    self._playersService = self._deps.Players or game:GetService("Players")
    self._inventoryService = self._deps.InventoryService
    self._autosaveInterval = self._state:Get("autosaveIntervalSeconds") or 60
    self._lastAutosave = 0
    self._trackedPlayers = {}
    self._allowStudioDataStore = shouldUseStudioDataStore(self._state, self._deps)

    if RunService:IsStudio() and not self._allowStudioDataStore then
        self._useMockStore = true
        self._state:Set("studioMockStore", self._studioMockStore)
        print("[DataPersistenceService] Studio runtime detected. Using in-memory mock persistence.")
        return self
    end

    if RunService:IsStudio() and self._allowStudioDataStore then
        print("[DataPersistenceService] Studio runtime detected. Using real DataStore because studio override is enabled.")
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
    if self._useMockStore then
        self._state:Set("studioMockStore", self._studioMockStore)
    end
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
    if self._useMockStore then
        self._studioMockStore.inventory[toKey(playerId)] = clone(inventoryData or {})
        self._state:Set("studioMockStore", self._studioMockStore)
        return true, "mock_store"
    end
    if not self._dataStore then
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
    if self._useMockStore then
        return clone(self._studioMockStore.inventory[toKey(playerId)] or {})
    end
    if not self._dataStore then
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
    if self._useMockStore then
        local key = toProfileKey(playerId)
        local current = self._studioMockStore.profiles[key]
        local record = normalizeProfileRecord(current)
        local profilePatch = extractProfilePatch(profileData)
        local rankPatch = extractRankPatch(profileData)

        if next(profilePatch) ~= nil then
            record.profile = deepMerge(record.profile, profilePatch)
        end
        if rankPatch ~= nil then
            record.rank = deepMerge(record.rank, rankPatch)
        end

        self._studioMockStore.profiles[key] = record
        self._state:Set("studioMockStore", self._studioMockStore)
        return true, "mock_store"
    end
    if not self._dataStore then
        return false, "datastore_disabled"
    end
    local key = toProfileKey(playerId)
    local success, err = pcall(function()
        self._dataStore:UpdateAsync(key, function(current)
            local record = normalizeProfileRecord(current)
            local profilePatch = extractProfilePatch(profileData)
            local rankPatch = extractRankPatch(profileData)

            if next(profilePatch) ~= nil then
                record.profile = deepMerge(record.profile, profilePatch)
            end
            if rankPatch ~= nil then
                record.rank = deepMerge(record.rank, rankPatch)
            end

            return record
        end)
    end)
    if not success then
        warn("DataPersistenceService: failed to save profile for", playerId, err)
    end
    return success, err
end

function Service:LoadProfile(playerId)
    if self._useMockStore then
        local key = toProfileKey(playerId)
        local data = self._studioMockStore.profiles[key]
        if data == nil then
            return nil
        end
        return normalizeProfileRecord(clone(data))
    end
    if not self._dataStore then
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
    if data == nil then
        return nil
    end
    return normalizeProfileRecord(data)
end

return Service

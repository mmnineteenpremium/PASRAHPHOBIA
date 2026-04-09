local Players = game:GetService("Players")
local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

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

local function safeRequire(moduleScript)
    if not moduleScript then
        return nil
    end
    local ok, result = pcall(require, moduleScript)
    if ok then
        return result
    end
    return nil
end

local function getByPath(root, path)
    local node = root
    for _, segment in ipairs(path or {}) do
        if typeof(node) ~= "Instance" then
            return nil
        end
        node = node:FindFirstChild(segment)
        if not node then
            return nil
        end
    end
    return node
end

local function resolveCosmeticTypesModule()
    local pathOptions = {
        { "shared", "DataTypes", "Cosmetics", "CosmeticTypes" },
        { "Shared", "DataTypes", "Cosmetics", "CosmeticTypes" },
    }

    local cursor = script
    while cursor do
        for _, path in ipairs(pathOptions) do
            local moduleScript = getByPath(cursor, path)
            if moduleScript then
                return moduleScript
            end
        end
        cursor = cursor.Parent
    end

    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if ok and typeof(replicatedStorage) == "Instance" then
        for _, path in ipairs(pathOptions) do
            local moduleScript = getByPath(replicatedStorage, path)
            if moduleScript then
                return moduleScript
            end
        end
    end

    return nil
end

local function resolveShopCatalogModule()
    local pathOptions = {
        { "shared", "DataTypes", "ShopCatalog" },
        { "Shared", "DataTypes", "ShopCatalog" },
    }

    local cursor = script
    while cursor do
        for _, path in ipairs(pathOptions) do
            local moduleScript = getByPath(cursor, path)
            if moduleScript then
                return moduleScript
            end
        end
        cursor = cursor.Parent
    end

    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if ok and typeof(replicatedStorage) == "Instance" then
        for _, path in ipairs(pathOptions) do
            local moduleScript = getByPath(replicatedStorage, path)
            if moduleScript then
                return moduleScript
            end
        end
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

local function resolvePlayer(playerOrUserId)
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId
    end

    local userId = toUserId(playerOrUserId)
    if not userId then
        return nil
    end

    local ok, player = pcall(function()
        return Players:GetPlayerByUserId(userId)
    end)
    if ok then
        return player
    end
    return nil
end

local function isNonEmptyMap(value)
    if type(value) ~= "table" then
        return false
    end
    for _ in pairs(value) do
        return true
    end
    return false
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

local function countEntries(source)
    if type(source) ~= "table" then
        return 0
    end
    local total = 0
    for _ in pairs(source) do
        total += 1
    end
    return total
end

local function stampCosmeticRuntime(target, payload)
    if typeof(target) ~= "Instance" or not target:IsA("Player") then
        return
    end

    target:SetAttribute("PasrahCosmeticOwner", "CosmeticSystem")
    target:SetAttribute("PasrahCosmeticOwnedCount", math.max(0, math.floor(tonumber(payload.ownedCount) or 0)))
    target:SetAttribute("PasrahCosmeticEquippedCount", math.max(0, math.floor(tonumber(payload.equippedCount) or 0)))
    target:SetAttribute("PasrahCosmeticLastEvent", type(payload.lastEvent) == "string" and payload.lastEvent or nil)
    target:SetAttribute("PasrahCosmeticLastCosmeticId", type(payload.lastCosmeticId) == "string" and payload.lastCosmeticId or nil)
    target:SetAttribute("PasrahCosmeticLastSlot", type(payload.lastSlot) == "string" and payload.lastSlot or nil)
    target:SetAttribute("PasrahCosmeticLastReason", type(payload.lastReason) == "string" and payload.lastReason or nil)
    target:SetAttribute("PasrahCosmeticAppliedToLobby", payload.appliedToLobby == true)
    target:SetAttribute("PasrahCosmeticUpdatedAt", os.clock())
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    self._loadedProfiles = {}
    return self
end

function Service:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        InventorySystem = Services.Get(self._deps, "InventorySystem"),
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
        LobbySocialHub = Services.Get(self._deps, "LobbySocialHub"),
        DataPersistenceService = Services.Get(self._deps, "DataPersistenceService"),
    }
end

function Service:Init()
    local typesModule = resolveCosmeticTypesModule()
    local cosmeticTypes = safeRequire(typesModule) or {}
    local shopCatalog = safeRequire(resolveShopCatalogModule()) or {}

    local definitions = self._state:Get("cosmeticDefinitions") or {}
    for _, slotName in pairs(cosmeticTypes) do
        if type(slotName) == "string" and slotName ~= "" and definitions[slotName] == nil then
            definitions[slotName] = {
                slot = slotName,
            }
        end
    end

    local slotByCosmeticId = self._state:Get("catalogSlotByCosmeticId") or {}
    for _, entry in pairs(shopCatalog) do
        if type(entry) == "table"
            and entry.category == "Cosmetic"
            and type(entry.id) == "string"
            and entry.id ~= ""
            and type(entry.slot) == "string"
            and entry.slot ~= "" then
            slotByCosmeticId[entry.id] = entry.slot
            if definitions[entry.id] == nil then
                definitions[entry.id] = {
                    slot = entry.slot,
                }
            end
        end
    end

    self._state:Set("equippedCosmetics", self._state:Get("equippedCosmetics") or {})
    self._state:Set("cosmeticSlots", self._state:Get("cosmeticSlots") or {})
    self._state:Set("cosmeticDefinitions", definitions)
    self._state:Set("catalogSlotByCosmeticId", slotByCosmeticId)
end

function Service:Start()
    -- Event-driven cosmetic service.
end

function Service:Stop()
    self._state:Clear()
    table.clear(self._loadedProfiles)
end

function Service:_buildRuntimeSnapshot(playerOrUserId)
    local player = resolvePlayer(playerOrUserId)
    if not player then
        return nil
    end

    local ownedCosmeticIds = {}
    local inventory = self:_getInventory()
    if type(inventory) == "table" and type(inventory.GetOwnedCosmetics) == "function" then
        local ok, result = pcall(function()
            return inventory:GetOwnedCosmetics(player)
        end)
        if ok and type(result) == "table" then
            ownedCosmeticIds = result
        end
    end

    local equippedCosmetics = cloneMap(self:_resolveEquippedForPlayer(player))

    return {
        ownedCount = #ownedCosmeticIds,
        equippedCount = countEntries(equippedCosmetics),
    }
end

function Service:_stampRuntimeState(playerOrUserId, payload)
    local player = resolvePlayer(playerOrUserId)
    if not player then
        return
    end

    local snapshot = self:_buildRuntimeSnapshot(player)
    if type(snapshot) ~= "table" then
        return
    end

    local lastCosmeticId = type(payload) == "table" and payload.lastCosmeticId or nil
    if lastCosmeticId == nil then
        lastCosmeticId = player:GetAttribute("PasrahCosmeticLastCosmeticId")
    end
    local lastSlot = type(payload) == "table" and payload.lastSlot or nil
    if lastSlot == nil then
        lastSlot = player:GetAttribute("PasrahCosmeticLastSlot")
    end
    local lastReason = type(payload) == "table" and payload.lastReason or nil
    if lastReason == nil then
        lastReason = player:GetAttribute("PasrahCosmeticLastReason")
    end
    local appliedToLobby = type(payload) == "table" and payload.appliedToLobby
    if appliedToLobby == nil then
        appliedToLobby = player:GetAttribute("PasrahCosmeticAppliedToLobby") == true
    end

    stampCosmeticRuntime(player, {
        ownedCount = snapshot.ownedCount,
        equippedCount = snapshot.equippedCount,
        lastEvent = type(payload) == "table" and payload.lastEvent or nil,
        lastCosmeticId = lastCosmeticId,
        lastSlot = lastSlot,
        lastReason = lastReason,
        appliedToLobby = appliedToLobby,
    })
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_getInventory()
    local inventory = self._dependencies.InventorySystem
    if type(inventory) == "table" and type(inventory.Service) == "table" then
        return inventory.Service
    end
    return inventory
end

function Service:_getLobby()
    local lobby = self._dependencies.LobbySocialHub
    if type(lobby) == "table" and type(lobby.Service) == "table" then
        return lobby.Service
    end
    return lobby
end

function Service:_getPersistence()
    local persistence = self._dependencies.DataPersistenceService
    if type(persistence) == "table" and type(persistence.Service) == "table" then
        return persistence.Service
    end
    return persistence
end

function Service:_saveProfileWithRetry(userId, profileData, maxAttempts)
    local persistence = self:_getPersistence()
    if type(persistence) ~= "table" or type(persistence.SaveProfile) ~= "function" then
        return
    end

    local attempts = math.max(tonumber(maxAttempts) or 3, 1)
    task.spawn(function()
        for attempt = 1, attempts do
            local ok, result = pcall(function()
                return persistence:SaveProfile(userId, profileData)
            end)
            if ok and result ~= false then
                return
            end
            task.wait(0.3 * attempt)
        end
        warn("[CosmeticSystem] SaveProfile failed after retries for userId:", userId)
    end)
end

function Service:_getSlotForCosmetic(cosmeticId)
    local definitions = self._state:Get("cosmeticDefinitions") or {}
    local entry = definitions[cosmeticId]
    if type(entry) == "table" and type(entry.slot) == "string" then
        return entry.slot
    end
    local slotByCosmeticId = self._state:Get("catalogSlotByCosmeticId") or {}
    local slot = slotByCosmeticId[cosmeticId]
    if type(slot) == "string" and slot ~= "" then
        return slot
    end
    return nil
end

function Service:ValidateOwnership(player, cosmeticId)
    if not player or type(cosmeticId) ~= "string" or cosmeticId == "" then
        return false
    end

    local inventory = self:_getInventory()
    if type(inventory) ~= "table" then
        return false
    end

    if type(inventory.OwnsCosmetic) == "function" then
        local ok, result = pcall(function()
            return inventory:OwnsCosmetic(player, cosmeticId)
        end)
        if ok then
            return result == true
        end
    end

    if type(inventory.HasItem) == "function" then
        local ok, result = pcall(function()
            return inventory:HasItem(player, cosmeticId)
        end)
        if ok then
            return result == true
        end
    end

    return false
end

function Service:_resolveEquippedForPlayer(player)
    local userId = toUserId(player)
    if not userId then
        return {}
    end

    self:_loadEquippedFromProfile(player)

    local equipped = self._state:Get("equippedCosmetics") or {}
    local playerEquipped = equipped[userId]
    if isNonEmptyMap(playerEquipped) then
        return playerEquipped
    end

    local inventory = self:_getInventory()
    if type(inventory) == "table" and type(inventory.GetEquipmentSlots) == "function" then
        local ok, result = pcall(function()
            return inventory:GetEquipmentSlots(player)
        end)
        if ok and type(result) == "table" then
            return result
        end
    end

    return playerEquipped or {}
end

function Service:BuildClientSnapshot(player)
    local userId = toUserId(player)
    if not userId then
        return {
            ownedCosmeticIds = {},
            equippedCosmetics = {},
            ownedCount = 0,
            equippedCount = 0,
        }
    end

    local ownedCosmeticIds = {}
    local inventory = self:_getInventory()
    if type(inventory) == "table" and type(inventory.GetOwnedCosmetics) == "function" then
        local ok, result = pcall(function()
            return inventory:GetOwnedCosmetics(player)
        end)
        if ok and type(result) == "table" then
            ownedCosmeticIds = result
        end
    end
    table.sort(ownedCosmeticIds)

    local equippedCosmetics = cloneMap(self:_resolveEquippedForPlayer(player))

    local snapshot = {
        ownedCosmeticIds = ownedCosmeticIds,
        equippedCosmetics = equippedCosmetics,
        ownedCount = #ownedCosmeticIds,
        equippedCount = countEntries(equippedCosmetics),
        updatedAt = os.clock(),
    }
    self:_stampRuntimeState(player, {
        lastEvent = "CosmeticSnapshotBuilt",
    })
    return snapshot
end

function Service:_syncInventorySlot(player, slot, cosmeticId)
    local inventory = self:_getInventory()
    if type(inventory) == "table" and type(inventory.AssignToSlot) == "function" then
        pcall(function()
            inventory:AssignToSlot(player, slot, cosmeticId)
        end)
    end
end

function Service:_loadEquippedFromProfile(player)
    local userId = toUserId(player)
    if not userId then
        return
    end
    if self._loadedProfiles[userId] then
        return
    end
    self._loadedProfiles[userId] = true

    local persistence = self:_getPersistence()
    if type(persistence) ~= "table" or type(persistence.LoadProfile) ~= "function" then
        return
    end

    local ok, profileData = pcall(function()
        return persistence:LoadProfile(userId)
    end)
    if not ok then
        return
    end

    local profile = nil
    if type(profileData) == "table" then
        profile = profileData.profile or profileData
    end
    local equipped = type(profile) == "table" and profile.equippedCosmetics
    if type(equipped) ~= "table" then
        return
    end

    local stateEquipped = self._state:Get("equippedCosmetics") or {}
    stateEquipped[userId] = equipped
    self._state:Set("equippedCosmetics", stateEquipped)
end

function Service:ApplyCosmetic(player)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end

    local playerEquipped = self:_resolveEquippedForPlayer(player)
    local lobby = self:_getLobby()
    if type(lobby) == "table" and type(lobby.ApplyCosmetics) == "function" then
        pcall(function()
            lobby:ApplyCosmetics(player, playerEquipped)
        end)
    elseif type(lobby) == "table" and type(lobby.ApplyCosmetic) == "function" then
        for slot, cosmeticId in pairs(playerEquipped) do
            pcall(function()
                lobby:ApplyCosmetic(player, cosmeticId, slot)
            end)
        end
    end

    self:_publish("CosmeticAppliedToLobby", {
        player = player,
        userId = userId,
        equipped = playerEquipped,
    })
    self:_stampRuntimeState(player, {
        lastEvent = "CosmeticAppliedToLobby",
        lastReason = "apply_lobby",
        appliedToLobby = true,
    })
    return true
end

function Service:EquipCosmetic(player, cosmeticId)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end
    if type(cosmeticId) ~= "string" or cosmeticId == "" then
        return false, "invalid_cosmetic"
    end
    if not self:ValidateOwnership(player, cosmeticId) then
        return false, "cosmetic_not_owned"
    end

    local slot = self:_getSlotForCosmetic(cosmeticId) or "equipmentSkin"
    local equipped = self._state:Get("equippedCosmetics") or {}
    equipped[userId] = equipped[userId] or {}
    equipped[userId][slot] = cosmeticId
    self._state:Set("equippedCosmetics", equipped)
    self:_syncInventorySlot(player, slot, cosmeticId)

    self:ApplyCosmetic(player)

    self:_saveProfileWithRetry(userId, { profile = { equippedCosmetics = equipped[userId] } })

    self:_publish("CosmeticEquipped", {
        player = player,
        userId = userId,
        cosmeticId = cosmeticId,
        slot = slot,
    })
    self:_stampRuntimeState(player, {
        lastEvent = "CosmeticEquipped",
        lastCosmeticId = cosmeticId,
        lastSlot = slot,
        lastReason = "equip",
        appliedToLobby = true,
    })
    return true, nil, slot
end

function Service:UnequipCosmetic(player, cosmeticSlot)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end
    if type(cosmeticSlot) ~= "string" or cosmeticSlot == "" then
        return false, "invalid_slot"
    end

    local equipped = self._state:Get("equippedCosmetics") or {}
    local playerEquipped = equipped[userId]
    if type(playerEquipped) ~= "table" then
        return false, "nothing_equipped"
    end

    local previous = playerEquipped[cosmeticSlot]
    playerEquipped[cosmeticSlot] = nil
    equipped[userId] = playerEquipped
    self._state:Set("equippedCosmetics", equipped)
    self:_syncInventorySlot(player, cosmeticSlot, nil)

    self:ApplyCosmetic(player)

    self:_saveProfileWithRetry(userId, { profile = { equippedCosmetics = equipped[userId] } })

    self:_publish("CosmeticUnequipped", {
        player = player,
        userId = userId,
        slot = cosmeticSlot,
        cosmeticId = previous,
    })
    self:_stampRuntimeState(player, {
        lastEvent = "CosmeticUnequipped",
        lastCosmeticId = previous,
        lastSlot = cosmeticSlot,
        lastReason = "unequip",
        appliedToLobby = true,
    })
    return true
end

return Service

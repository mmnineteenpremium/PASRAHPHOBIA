local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local EXTRACTION_TAG = "ExtractionZone"
local EXTRACTION_FOLDER_NAME = "ExtractionZones"
local DEFAULT_ZONE_NAME = "ExtractionZone_Main"

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

local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then
        return playerOrUserId
    end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId.UserId
    end
    return nil
end

local function getPlayerFromHit(hit)
    local character = hit and hit.Parent
    if not character then
        return nil
    end
    return Players:GetPlayerFromCharacter(character)
end

local function getMapModel(mapId)
    local mapsFolder = Workspace:FindFirstChild("Maps")
    if not mapsFolder then
        return nil
    end
    if type(mapId) == "string" and mapId ~= "" then
        return mapsFolder:FindFirstChild(mapId)
    end
    return nil
end

local function ensureExtractionFolder(mapModel)
    if not mapModel then
        return nil
    end
    local folder = mapModel:FindFirstChild(EXTRACTION_FOLDER_NAME)
    if folder and folder:IsA("Folder") then
        return folder
    end
    folder = Instance.new("Folder")
    folder.Name = EXTRACTION_FOLDER_NAME
    folder.Parent = mapModel
    return folder
end

local function getFallbackZonePosition(mapModel)
    local spawnFolder = mapModel and mapModel:FindFirstChild("SpawnPoints")
    if spawnFolder then
        local firstSpawn = spawnFolder:FindFirstChildWhichIsA("BasePart")
        if firstSpawn then
            return firstSpawn.Position + Vector3.new(0, 2, 0)
        end
    end
    return mapModel and mapModel:GetPivot().Position + Vector3.new(0, 4, 0) or Vector3.new(0, 4, 0)
end

local function ensureZonePart(mapModel, folder)
    local zonePart = folder:FindFirstChildWhichIsA("BasePart")
    if zonePart then
        if not CollectionService:HasTag(zonePart, EXTRACTION_TAG) then
            CollectionService:AddTag(zonePart, EXTRACTION_TAG)
        end
        return zonePart
    end

    zonePart = Instance.new("Part")
    zonePart.Name = DEFAULT_ZONE_NAME
    zonePart.Anchored = true
    zonePart.CanCollide = false
    zonePart.Transparency = 1
    zonePart.Size = Vector3.new(18, 7, 18)
    zonePart.Position = getFallbackZonePosition(mapModel)
    zonePart.Parent = folder
    CollectionService:AddTag(zonePart, EXTRACTION_TAG)
    return zonePart
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {}
    self._zoneConnectionsByMatchId = {}
    return self
end

function Service:Init()
    self._dependencies = {
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
        InvestigationSystem = Services.Get(self._deps, "InvestigationSystem"),
    }
    self._state:Set("activeMatchId", self._state:Get("activeMatchId"))
    self._state:Set("playersAliveByMatchId", self._state:Get("playersAliveByMatchId") or {})
    self._state:Set("playersExtractedByMatchId", self._state:Get("playersExtractedByMatchId") or {})
    self._state:Set("ghostIdentifiedByMatchId", self._state:Get("ghostIdentifiedByMatchId") or {})
    self._state:Set("extractionCompletedByMatchId", self._state:Get("extractionCompletedByMatchId") or {})

    local mapsFolder = Workspace:FindFirstChild("Maps")
    if mapsFolder then
        for _, mapModel in ipairs(mapsFolder:GetChildren()) do
            if mapModel:IsA("Model") then
                local folder = ensureExtractionFolder(mapModel)
                if folder then
                    ensureZonePart(mapModel, folder)
                end
            end
        end
    end
end

function Service:Start()
end

function Service:Stop()
    for matchId, connections in pairs(self._zoneConnectionsByMatchId) do
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        self._zoneConnectionsByMatchId[matchId] = nil
    end
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_matchId(payload)
    return payload and payload.matchId or self._state:Get("activeMatchId")
end

function Service:_getMap(key)
    return self._state:Get(key) or {}
end

function Service:_setMap(key, value)
    self._state:Set(key, value)
end

function Service:_setAlive(matchId, userId, isAlive)
    local aliveByMatch = self:_getMap("playersAliveByMatchId")
    aliveByMatch[matchId] = aliveByMatch[matchId] or {}
    aliveByMatch[matchId][userId] = isAlive == true
    self:_setMap("playersAliveByMatchId", aliveByMatch)
end

function Service:_isAlive(matchId, userId)
    local aliveByMatch = self:_getMap("playersAliveByMatchId")
    return aliveByMatch[matchId] and aliveByMatch[matchId][userId] == true
end

function Service:_setExtracted(matchId, userId, extracted)
    local extractedByMatch = self:_getMap("playersExtractedByMatchId")
    extractedByMatch[matchId] = extractedByMatch[matchId] or {}
    extractedByMatch[matchId][userId] = extracted == true
    self:_setMap("playersExtractedByMatchId", extractedByMatch)
end

function Service:_isExtracted(matchId, userId)
    local extractedByMatch = self:_getMap("playersExtractedByMatchId")
    return extractedByMatch[matchId] and extractedByMatch[matchId][userId] == true
end

function Service:_setGhostIdentified(matchId, identified)
    local mapValue = self:_getMap("ghostIdentifiedByMatchId")
    mapValue[matchId] = identified == true
    self:_setMap("ghostIdentifiedByMatchId", mapValue)
end

function Service:_isGhostIdentified(matchId)
    local mapValue = self:_getMap("ghostIdentifiedByMatchId")
    return mapValue[matchId] == true
end

function Service:_setExtractionCompleted(matchId, completed)
    local mapValue = self:_getMap("extractionCompletedByMatchId")
    mapValue[matchId] = completed == true
    self:_setMap("extractionCompletedByMatchId", mapValue)
end

function Service:_isExtractionCompleted(matchId)
    local mapValue = self:_getMap("extractionCompletedByMatchId")
    return mapValue[matchId] == true
end

function Service:_countLiving(matchId)
    local aliveByMatch = self:_getMap("playersAliveByMatchId")
    local aliveMap = aliveByMatch[matchId] or {}
    local total = 0
    for _, isAlive in pairs(aliveMap) do
        if isAlive == true then
            total += 1
        end
    end
    return total
end

function Service:_countExtractedLiving(matchId)
    local aliveByMatch = self:_getMap("playersAliveByMatchId")
    local extractedByMatch = self:_getMap("playersExtractedByMatchId")
    local aliveMap = aliveByMatch[matchId] or {}
    local extractedMap = extractedByMatch[matchId] or {}
    local total = 0
    for userId, isAlive in pairs(aliveMap) do
        if isAlive == true and extractedMap[userId] == true then
            total += 1
        end
    end
    return total
end

function Service:_checkExtractionComplete(matchId)
    if self:_isExtractionCompleted(matchId) then
        return
    end
    local living = self:_countLiving(matchId)
    local extractedLiving = self:_countExtractedLiving(matchId)
    if living <= 0 or extractedLiving < living then
        return
    end

    self:_setExtractionCompleted(matchId, true)
    local payload = {
        matchId = matchId,
        extractedPlayers = extractedLiving,
        requiredPlayers = living,
        ghostIdentified = self:_isGhostIdentified(matchId),
        source = "HuntEscapeSystem",
    }

    self:_publish("MatchExtractionCompleted", payload)
    self:_publish("MatchPhaseTransitionRequested", {
        matchId = matchId,
        endMatch = true,
        reason = "extraction_complete",
        results = payload,
    })
end

function Service:_registerZones(matchId, mapId)
    local mapModel = getMapModel(mapId)
    if not mapModel then
        return
    end

    local folder = ensureExtractionFolder(mapModel)
    if not folder then
        return
    end

    local zonePart = ensureZonePart(mapModel, folder)
    if not zonePart then
        return
    end

    self._zoneConnectionsByMatchId[matchId] = self._zoneConnectionsByMatchId[matchId] or {}
    local connection = zonePart.Touched:Connect(function(hit)
        local player = getPlayerFromHit(hit)
        if player then
            self:HandlePlayerExtraction(player, matchId, zonePart.Name, "touch")
        end
    end)
    table.insert(self._zoneConnectionsByMatchId[matchId], connection)

    self:_publish("ExtractionZoneRegistered", {
        matchId = matchId,
        mapId = mapId,
        zoneName = zonePart.Name,
        source = "HuntEscapeSystem",
    })
end

function Service:_cleanupMatch(matchId)
    local keys = {
        "playersAliveByMatchId",
        "playersExtractedByMatchId",
        "ghostIdentifiedByMatchId",
        "extractionCompletedByMatchId",
    }
    for _, key in ipairs(keys) do
        local mapValue = self:_getMap(key)
        mapValue[matchId] = nil
        self:_setMap(key, mapValue)
    end

    local connections = self._zoneConnectionsByMatchId[matchId]
    if connections then
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        self._zoneConnectionsByMatchId[matchId] = nil
    end
end

function Service:HandlePlayerExtraction(player, matchId, zoneId, source)
    local userId = toUserId(player)
    if not userId or type(matchId) ~= "string" then
        return false, "invalid_player"
    end
    if self:_isExtracted(matchId, userId) then
        return false, "already_extracted"
    end
    if not self:_isAlive(matchId, userId) then
        return false, "player_not_alive"
    end
    if not self:_isGhostIdentified(matchId) then
        self:_publish("ExtractionDenied", {
            matchId = matchId,
            userId = userId,
            player = player,
            reason = "ghost_not_identified",
            source = "HuntEscapeSystem",
        })
        return false, "ghost_not_identified"
    end

    self:_setExtracted(matchId, userId, true)
    self:_publish("PlayerExtracted", {
        matchId = matchId,
        userId = userId,
        player = player,
        zoneId = zoneId,
        source = source or "HuntEscapeSystem",
    })
    self:_publish("PlayerEscapedHunt", {
        matchId = matchId,
        userId = userId,
        player = player,
        source = "HuntEscapeSystem",
    })

    self:_checkExtractionComplete(matchId)
    return true
end

function Service:HandleEvent(eventName, payload)
    if eventName == "MatchStarted" then
        local matchId = self:_matchId(payload)
        if type(matchId) ~= "string" then
            return
        end
        self._state:Set("activeMatchId", matchId)
        self:_setGhostIdentified(matchId, false)
        self:_setExtractionCompleted(matchId, false)

        local aliveByMatch = self:_getMap("playersAliveByMatchId")
        aliveByMatch[matchId] = {}
        self:_setMap("playersAliveByMatchId", aliveByMatch)

        local extractedByMatch = self:_getMap("playersExtractedByMatchId")
        extractedByMatch[matchId] = {}
        self:_setMap("playersExtractedByMatchId", extractedByMatch)

        local players = payload and payload.players or {}
        for _, player in ipairs(players) do
            local userId = toUserId(player)
            if userId then
                self:_setAlive(matchId, userId, true)
                self:_setExtracted(matchId, userId, false)
            end
        end

        self:_registerZones(matchId, payload and (payload.mapId or payload.map))
        return
    end

    if eventName == "MatchEnded" then
        local matchId = self:_matchId(payload)
        if type(matchId) ~= "string" then
            return
        end
        self:_cleanupMatch(matchId)
        if self._state:Get("activeMatchId") == matchId then
            self._state:Set("activeMatchId", nil)
        end
        return
    end

    local matchId = self:_matchId(payload)
    if type(matchId) ~= "string" then
        return
    end

    if eventName == "GhostIdentified" then
        self:_setGhostIdentified(matchId, true)
        return
    end

    if eventName == "PlayerDied" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        if userId then
            self:_setAlive(matchId, userId, false)
        end
        return
    end

    if eventName == "PlayerDisconnected" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        if userId then
            self:_setAlive(matchId, userId, false)
            self:_setExtracted(matchId, userId, false)
        end
        return
    end

    if eventName == "PlayerEnteredExtractionZone" then
        local player = payload and payload.player
        local userId = toUserId(player or payload.userId)
        if not userId then
            return
        end
        if not player and type(userId) == "number" then
            player = Players:GetPlayerByUserId(userId)
        end
        if player then
            self:HandlePlayerExtraction(player, matchId, payload and payload.zoneId, "event")
        end
    end
end

return Service

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local EXTRACTION_TAG = "ExtractionZone"
local EXTRACTION_FOLDER_NAME = "ExtractionZones"
local DEFAULT_ZONE_NAME = "ExtractionZone_Main"
local EXTRACTION_TRACE_ATTRIBUTE = "PasrahExtractionTrace"
local EXTRACTION_OVERRIDE_ATTRIBUTE = "PasrahAllowStudioExtraction"

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

local function shouldTraceExtraction()
    return ReplicatedStorage:GetAttribute(EXTRACTION_TRACE_ATTRIBUTE) == true
end

local function canUseStudioExtractionOverride()
    return RunService:IsStudio() and ReplicatedStorage:GetAttribute(EXTRACTION_OVERRIDE_ATTRIBUTE) == true
end

local function traceExtraction(message, payload)
    if not shouldTraceExtraction() then
        return
    end

    local parts = {}
    for key, value in pairs(payload or {}) do
        if type(value) ~= "table" then
            table.insert(parts, string.format("%s=%s", tostring(key), tostring(value)))
        end
    end
    table.sort(parts)
    if #parts > 0 then
        print(string.format("[EXTRACTION TRACE] %s [%s]", tostring(message), table.concat(parts, ", ")))
    else
        print(string.format("[EXTRACTION TRACE] %s", tostring(message)))
    end
end

local function getLiveMatch(matchSystem, matchId)
    if type(matchSystem) ~= "table" or type(matchId) ~= "string" or matchId == "" then
        return nil
    end
    if type(matchSystem.GetLiveMatch) == "function" then
        return matchSystem:GetLiveMatch(matchId)
    end
    if type(matchSystem.Service) == "table" and type(matchSystem.Service.GetLiveMatch) == "function" then
        return matchSystem.Service:GetLiveMatch(matchId)
    end
    return nil
end

local function getRuntimeMapModel(matchSystem, matchId)
    local liveMatch = getLiveMatch(matchSystem, matchId)
    if type(liveMatch) ~= "table" then
        return nil
    end

    local container = liveMatch.container
    if typeof(container) ~= "Instance" then
        return nil
    end

    for _, expectedName in ipairs({ liveMatch.mapId, liveMatch.map }) do
        if type(expectedName) == "string" and expectedName ~= "" then
            local exact = container:FindFirstChild(expectedName)
            if exact then
                return exact
            end
        end
    end

    for _, child in ipairs(container:GetChildren()) do
        if (child:IsA("Model") or child:IsA("Folder")) and not child.Name:match("^GhostPlaceholder_") then
            return child
        end
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

    local anchor = mapModel and mapModel:FindFirstChildWhichIsA("BasePart", true)
    if anchor then
        return anchor.Position + Vector3.new(0, 4, 0)
    end

    if mapModel and mapModel:IsA("Model") then
        local ok, pivot = pcall(function()
            return mapModel:GetPivot()
        end)
        if ok then
            return pivot.Position + Vector3.new(0, 4, 0)
        end
    end

    return Vector3.new(0, 4, 0)
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
    self._zonePartsByMatchId = {}
    return self
end

local function stampExtractionZoneRuntime(target, payload)
    if typeof(target) ~= "Instance" or not target:IsA("BasePart") then
        return
    end
    target:SetAttribute("PasrahExtractionOwner", "HuntEscapeSystem")
    target:SetAttribute("PasrahExtractionMatchId", type(payload.matchId) == "string" and payload.matchId or nil)
    target:SetAttribute("PasrahExtractionZoneId", type(payload.zoneId) == "string" and payload.zoneId or target.Name)
    target:SetAttribute("PasrahExtractionGhostIdentified", payload.ghostIdentified == true)
    target:SetAttribute("PasrahExtractionLivingCount", tonumber(payload.livingCount) or 0)
    target:SetAttribute("PasrahExtractionExtractedLivingCount", tonumber(payload.extractedLivingCount) or 0)
    target:SetAttribute("PasrahExtractionCompleted", payload.completed == true)
    target:SetAttribute("PasrahExtractionLastResult", type(payload.lastResult) == "string" and payload.lastResult or nil)
    target:SetAttribute("PasrahExtractionLastUpdatedAt", tonumber(payload.updatedAt) or os.clock())
end

local function stampExtractionPlayerRuntime(target, payload)
    if typeof(target) ~= "Instance" or not target:IsA("Player") then
        return
    end
    target:SetAttribute("PasrahExtractionOwner", "HuntEscapeSystem")
    target:SetAttribute("PasrahExtractionMatchId", type(payload.matchId) == "string" and payload.matchId or nil)
    target:SetAttribute("PasrahExtractionZoneId", type(payload.zoneId) == "string" and payload.zoneId or nil)
    target:SetAttribute("PasrahExtractionGhostIdentified", payload.ghostIdentified == true)
    target:SetAttribute("PasrahExtractionExtracted", payload.extracted == true)
    target:SetAttribute("PasrahExtractionCompleted", payload.completed == true)
    target:SetAttribute("PasrahExtractionLastResult", type(payload.lastResult) == "string" and payload.lastResult or nil)
    target:SetAttribute("PasrahExtractionLastUpdatedAt", tonumber(payload.updatedAt) or os.clock())
end

function Service:_resolveMapModel(matchId, mapId)
    local matchSystem = self._dependencies and self._dependencies.MatchSystem
    local runtimeMap = getRuntimeMapModel(matchSystem, matchId)
    if runtimeMap then
        return runtimeMap
    end
    return getMapModel(mapId)
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
    self._zonePartsByMatchId = {}
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

function Service:_stampExtractionRuntime(matchId, zoneId, player, lastResult)
    local zone = self._zonePartsByMatchId[matchId]
    if not zone then
        local mapModel = self:_resolveMapModel(matchId)
        local folder = mapModel and mapModel:FindFirstChild(EXTRACTION_FOLDER_NAME)
        zone = folder and folder:FindFirstChild(zoneId or DEFAULT_ZONE_NAME)
        if not zone then
            zone = folder and folder:FindFirstChildWhichIsA("BasePart")
        end
    end

    local payload = {
        matchId = matchId,
        zoneId = zoneId,
        ghostIdentified = self:_isGhostIdentified(matchId),
        livingCount = self:_countLiving(matchId),
        extractedLivingCount = self:_countExtractedLiving(matchId),
        completed = self:_isExtractionCompleted(matchId),
        lastResult = lastResult,
        updatedAt = os.clock(),
    }
    if typeof(zone) == "Instance" and zone:IsA("BasePart") then
        stampExtractionZoneRuntime(zone, payload)
    end
    if typeof(player) == "Instance" and player:IsA("Player") then
        payload.extracted = self:_isExtracted(matchId, player.UserId)
        if lastResult == "extracted" or lastResult == "extracted_via_studio_override" then
            payload.extracted = true
        end
        stampExtractionPlayerRuntime(player, payload)
    end
end

function Service:_registerZones(matchId, mapId)
    local mapModel = self:_resolveMapModel(matchId, mapId)
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
            traceExtraction("ZoneTouched", {
                matchId = matchId,
                player = player.Name,
                userId = player.UserId,
                zone = zonePart.Name,
            })
            self:HandlePlayerExtraction(player, matchId, zonePart.Name, "touch")
        end
    end)
    table.insert(self._zoneConnectionsByMatchId[matchId], connection)
    self._zonePartsByMatchId[matchId] = zonePart
    self:_stampExtractionRuntime(matchId, zonePart.Name, nil, "zone_registered")

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
    self._zonePartsByMatchId[matchId] = nil
end

function Service:HandlePlayerExtraction(player, matchId, zoneId, source)
    local userId = toUserId(player)
    if not userId or type(matchId) ~= "string" then
        return false, "invalid_player"
    end
    if typeof(player) == "Instance" and player:IsA("Player") then
        player:SetAttribute("PasrahLastExtractionResult", nil)
        player:SetAttribute("PasrahLastExtractionZone", zoneId)
    end
    if self:_isExtracted(matchId, userId) then
        if typeof(player) == "Instance" and player:IsA("Player") then
            player:SetAttribute("PasrahLastExtractionResult", "already_extracted")
        end
        self:_stampExtractionRuntime(matchId, zoneId, player, "already_extracted")
        return false, "already_extracted"
    end
    if not self:_isAlive(matchId, userId) then
        if typeof(player) == "Instance" and player:IsA("Player") then
            player:SetAttribute("PasrahLastExtractionResult", "player_not_alive")
        end
        self:_stampExtractionRuntime(matchId, zoneId, player, "player_not_alive")
        return false, "player_not_alive"
    end
    local ghostIdentified = self:_isGhostIdentified(matchId)
    local studioOverride = canUseStudioExtractionOverride()
    if not ghostIdentified and not studioOverride then
        if typeof(player) == "Instance" and player:IsA("Player") then
            player:SetAttribute("PasrahLastExtractionResult", "ghost_not_identified")
        end
        traceExtraction("ExtractionDenied", {
            matchId = matchId,
            player = player.Name,
            userId = userId,
            zone = zoneId,
            reason = "ghost_not_identified",
        })
        self:_publish("ExtractionDenied", {
            matchId = matchId,
            userId = userId,
            player = player,
            reason = "ghost_not_identified",
            source = "HuntEscapeSystem",
        })
        self:_stampExtractionRuntime(matchId, zoneId, player, "ghost_not_identified")
        return false, "ghost_not_identified"
    end

    self:_setExtracted(matchId, userId, true)
    if typeof(player) == "Instance" and player:IsA("Player") then
        player:SetAttribute("PasrahLastExtractionResult", studioOverride and "extracted_via_studio_override" or "extracted")
    end
    traceExtraction("ExtractionAccepted", {
        matchId = matchId,
        player = player.Name,
        userId = userId,
        zone = zoneId,
        source = source or "HuntEscapeSystem",
        studioOverride = studioOverride,
    })
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
    self:_stampExtractionRuntime(matchId, zoneId, player, studioOverride and "extracted_via_studio_override" or "extracted")
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
        self:_stampExtractionRuntime(matchId, DEFAULT_ZONE_NAME, nil, "match_started")
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
        self:_stampExtractionRuntime(matchId, DEFAULT_ZONE_NAME, payload and payload.player, "ghost_identified")
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

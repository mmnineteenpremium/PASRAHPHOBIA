local Controller = {}
Controller.__index = Controller

local EvidenceGateway = require(script.Parent.EvidenceGateway)
local Services = require(script.Parent.Parent.Core.Services)

local MIN_TENSION_DELTA_FOR_SPAWN = 1
local TENSION_SPAWN_COOLDOWN_SECONDS = 2.5
local TOOL_RESULT_EVENT_NAME = "EvidenceToolResult"
local EVIDENCE_REMOTE_NAME = "EvidenceEvent"

local TOOL_ALIASES = {
	jejakenergi = "JejakEnergi",
	medok = "JejakEnergi",
	kotakarwah = "KotakArwah",
	suara = "KotakArwah",
	suhumembeku = "SuhuMembeku",
	suhu = "SuhuMembeku",
	bukuterkutuk = "BukuTerkutuk",
	bolaarwah = "BolaArwah",
	toun = "BolaArwah",
	gerakangaib = "GerakanGaib",
	pengganggu = "GerakanGaib",
	garam = "Garam",
	salt = "Garam",
	salib = "Salib",
	crucifix = "Salib",
	dupa = "Dupa",
	smudge = "Dupa",
	smudgestick = "Dupa",
}

local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
    if type(eventBus) ~= "table" then
        return nil
    end
    if type(eventBus.Subscribe) == "function" then
        return eventBus
    end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Subscribe) == "function" then
        return eventBus.Service
    end
    return nil
end

local function resolveSecurityService(deps)
    local security = Services.Get(deps, "SecuritySystem")
    if type(security) ~= "table" then
        return nil
    end
    if type(security.ValidateRemoteRequest) == "function" then
        return security
    end
    if type(security.Service) == "table" and type(security.Service.ValidateRemoteRequest) == "function" then
        return security.Service
    end
    return nil
end


local function resolveSpectatorSystem(deps)
    local spectator = Services.Get(deps, "SpectatorSystem")
    if type(spectator) ~= "table" then
        return nil
    end
    if type(spectator.IsSpectator) == "function" then
        return spectator
    end
    if type(spectator.Service) == "table" and type(spectator.Service.IsSpectator) == "function" then
        return spectator.Service
    end
    return nil
end

local function resolvePlayersService(deps)
    if deps and deps.Players then
        return deps.Players
    end
    return game:GetService("Players")
end

local function resolveSharedEvidenceTypes()
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
        for _, segment in ipairs(path) do
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

    local cursor = script
    while cursor do
        local shared = cursor:FindFirstChild("shared") or cursor:FindFirstChild("Shared")
        if shared then
            local evidenceTypesModule = getByPath(shared, { "DataTypes", "Evidence", "EvidenceTypes", "ModuleScript" })
            local result = safeRequire(evidenceTypesModule)
            if result then
                return result
            end
        end
        cursor = cursor.Parent
    end

    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if ok and typeof(replicatedStorage) == "Instance" then
        local shared = replicatedStorage:FindFirstChild("shared") or replicatedStorage:FindFirstChild("Shared")
        if shared then
            local evidenceTypesModule = getByPath(shared, { "DataTypes", "Evidence", "EvidenceTypes", "ModuleScript" })
            return safeRequire(evidenceTypesModule)
        end
    end
    return nil
end

local function resolveSharedEvidenceConfig()
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
        for _, segment in ipairs(path) do
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

    local cursor = script
    while cursor do
        local shared = cursor:FindFirstChild("shared") or cursor:FindFirstChild("Shared")
        if shared then
            local configModule = getByPath(shared, { "GameData", "EvidenceConfig" })
            local result = safeRequire(configModule)
            if result then
                return result
            end
        end
        cursor = cursor.Parent
    end

    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if ok and typeof(replicatedStorage) == "Instance" then
        local shared = replicatedStorage:FindFirstChild("shared") or replicatedStorage:FindFirstChild("Shared")
        if shared then
            local configModule = getByPath(shared, { "GameData", "EvidenceConfig" })
            return safeRequire(configModule)
        end
    end
    return nil
end


local EVIDENCE_CONFIG = resolveSharedEvidenceConfig() or {}
local EVIDENCE_TOOL_IDS = {}
for _, def in pairs(EVIDENCE_CONFIG) do
    if type(def) == "table" and type(def.toolId) == "string" then
        table.insert(EVIDENCE_TOOL_IDS, def.toolId)
    end
end

local EVIDENCE_TYPES = resolveSharedEvidenceTypes() or {}
local UTILITY_TOOL_TYPES = {
	Dupa = true,
	Garam = true,
	Salib = true,
}
local function resolveMatchSystem(deps)
    local match = Services.Get(deps, "MatchSystem")
    if type(match) ~= "table" then
        return nil
    end
    return match
end

local function normalizeToolType(toolType)
    if type(toolType) ~= "string" then
        return nil
    end
    local canonical = toolType:gsub("[%s_%-]+", ""):lower()
    return TOOL_ALIASES[canonical]
end

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._subscriptions = {}
    self._eventBus = resolveEventBus(self._deps)
    self._security = resolveSecurityService(self._deps)
    self._matchSystem = resolveMatchSystem(self._deps)
    self._spectatorSystem = resolveSpectatorSystem(self._deps)
    self._playersService = resolvePlayersService(self._deps)
    self._evidenceRemote = nil
    self._remoteConnection = nil
    self._gateway = nil
    self._handlersRegistered = false
    self._lastTensionSpawnAtByMatch = {}
    self._rateLimitByUserId = {}
    return self
end

function Controller:Init()
    self._evidenceRemote = self:_resolveEvidenceRemote()
    self._gateway = EvidenceGateway.new(self._service, self._deps)
end

function Controller:_isPlayerValid(player)
    if not player or not player.UserId then
        return false
    end
    if not self._playersService then
        return true
    end
    return self._playersService:GetPlayerByUserId(player.UserId) ~= nil
end

function Controller:_isRateLimited(userId, eventName, now)
    if not userId then
        return true
    end
    local perUser = self._rateLimitByUserId[userId]
    if not perUser then
        perUser = {}
        self._rateLimitByUserId[userId] = perUser
    end

    local window = perUser[eventName]
    if not window then
        window = {}
        perUser[eventName] = window
    end

    local current = now or os.clock()
    local cutoff = current - 5
    local filtered = {}
    for _, timestamp in ipairs(window) do
        if timestamp >= cutoff then
            table.insert(filtered, timestamp)
        end
    end

    if #filtered >= 10 then
        perUser[eventName] = filtered
        return true
    end

    table.insert(filtered, current)
    perUser[eventName] = filtered
    return false
end

function Controller:_isSpectator(matchId, player)
    if not self._spectatorSystem or not player then
        return false
    end
    if type(self._spectatorSystem.IsSpectator) == "function" then
        return self._spectatorSystem:IsSpectator(matchId, player)
    end
    return false
end

function Controller:_isEvidenceTypeAllowed(evidenceType)
	if type(evidenceType) ~= "string" then
		return false
	end
	if UTILITY_TOOL_TYPES[evidenceType] == true then
		return true
	end
	for _, value in pairs(EVIDENCE_TOOL_IDS) do
		if value == evidenceType then
			return true
        end
    end
    return false
end

function Controller:_validateEvidenceNode(matchId, payload, evidenceType)
    local nodeId = payload and (payload.evidenceNodeId or payload.nodeId)
    if not nodeId then
        return true
    end
    local lookupKey = nodeId
    local spawned = self._service and self._service.GetSpawnedEvidence and self._service:GetSpawnedEvidence(matchId) or {}
    if spawned and spawned[lookupKey] then
        return true
    end
    return false
end

function Controller:_getMatchById(matchId)
    if not matchId then
        return nil
    end
    if self._matchSystem and type(self._matchSystem.GetMatch) == "function" then
        return self._matchSystem:GetMatch(matchId)
    end
    if self._matchSystem and type(self._matchSystem.Service) == "table" and type(self._matchSystem.Service.GetMatch) == "function" then
        return self._matchSystem.Service:GetMatch(matchId)
    end
    local state = self._matchSystem and self._matchSystem.State
    local matches = state and state:Get("matches")
    if type(matches) == "table" then
        return matches[matchId]
    end
    return nil
end

function Controller:_isPlayerAlive(matchId, player)
    if not player then
        return false
    end
    local match = self:_getMatchById(matchId)
    if not match then
        return false
    end
    local userId = player.UserId
    local aliveMap = match.alive or match.alivePlayers
    if type(aliveMap) == "table" and aliveMap[userId] == false then
        return false
    end
    local deadMap = match.dead or match.deadPlayers
    if type(deadMap) == "table" and deadMap[userId] == true then
        return false
    end
    local states = match.playerStates or match.playersState
    if type(states) == "table" and type(states[userId]) == "table" then
        if states[userId].isAlive == false or states[userId].dead == true then
            return false
        end
    end
    return true
end

function Controller:_broadcastEvidence(matchId, payload)
    if not self._evidenceRemote then
        return
    end
    local match = self:_getMatchById(matchId)
    if not match then
        return
    end
    for _, entry in ipairs(match.players or {}) do
        local player = entry
        if type(entry) == "number" and self._playersService then
            player = self._playersService:GetPlayerByUserId(entry)
        end
        if typeof(player) == "Instance" and player:IsA("Player") then
            self._evidenceRemote:FireClient(player, payload)
        end
    end
end

function Controller:_broadcastEvidenceFound(matchId, payload)
    if not self._evidenceFoundRemote then
        return
    end
    local match = self:_getMatchById(matchId)
    if not match then
        return
    end
    for _, entry in ipairs(match.players or {}) do
        local player = entry
        if type(entry) == "number" and self._playersService then
            player = self._playersService:GetPlayerByUserId(entry)
        end
        if typeof(player) == "Instance" and player:IsA("Player") then
            self._evidenceFoundRemote:FireClient(player, payload)
        end
    end
end

function Controller:RegisterEventHandlers()
    if self._handlersRegistered then
        return
    end

    if self._eventBus then
        self:_subscribe("MatchStarted", function(payload)
            self:OnMatchStarted(payload)
        end)
        self:_subscribe("MatchEnded", function(payload)
            self:OnMatchEnded(payload)
        end)
        self:_subscribe("GhostSpawned", function(payload)
            self:OnGhostSpawned(payload)
        end)
        self:_subscribe("PhaseStarted", function(payload)
            self:OnPhaseStarted(payload)
        end)
        self:_subscribe("GhostInteraction", function(payload)
            self:OnGhostInteraction(payload)
        end)
        self:_subscribe("GhostStateChanged", function(payload)
            self:OnGhostStateChanged(payload)
        end)
        self:_subscribe("EvidenceCollected", function(payload)
            self:OnEvidenceCollected(payload)
        end)
        self:_subscribe("GhostManifest", function(payload)
            self:OnGhostManifest(payload)
        end)
        self:_subscribe("TensionIncreased", function(payload)
            self:OnTensionIncreased(payload)
        end)
        self:_subscribe("InvestigationEvidenceRequested", function(payload)
            self:OnInvestigationEvidenceRequested(payload)
        end)
        self:_subscribe("InvestigationToolUsed", function(payload)
            self:OnInvestigationToolUsed(payload)
        end)
        self:_subscribe("InvestigationGhostGuessSubmitted", function(payload)
            self:OnInvestigationGhostGuessSubmitted(payload)
        end)
        self:_subscribe("DirectorTensionChanged", function(payload)
            self:OnDirectorTensionChanged(payload)
        end)
        self:_subscribe("GhostPersonalityAssigned", function(payload)
            self:OnGhostPersonalityAssigned(payload)
        end)
        self:_subscribe("GhostPersonalitySelected", function(payload)
            self:OnGhostPersonalitySelected(payload)
        end)
        self:_subscribe("SpectatorVisionUpdated", function(payload)
            self:OnSpectatorVisionUpdated(payload)
        end)
    end
    self:_connectEvidenceRemote()
    if self._gateway then
        self._gateway:Start()
    end
    self._handlersRegistered = true
end

function Controller:UnregisterEventHandlers()
    if not self._handlersRegistered then
        return
    end

    if self._eventBus then
        for _, subscription in ipairs(self._subscriptions) do
            self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
        end
    end
    table.clear(self._subscriptions)
    table.clear(self._lastTensionSpawnAtByMatch)
    table.clear(self._rateLimitByUserId)
    self:_disconnectEvidenceRemote()
    if self._gateway then
        self._gateway:Stop()
    end
    self._handlersRegistered = false
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

function Controller:_resolveEvidenceRemote()
    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if not ok then
        return nil
    end

    local remoteFolder = replicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteFolder then
        return nil
    end

    local remote = remoteFolder:FindFirstChild(EVIDENCE_REMOTE_NAME)
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
end

function Controller:_resolveEvidenceFoundRemote()
    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if not ok then
        return nil
    end

    local remoteFolder = replicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteFolder then
        return nil
    end

    local remote = remoteFolder:FindFirstChild("EvidenceFound")
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
end

function Controller:_connectEvidenceRemote()
    if self._remoteConnection then
        return
    end
    if not self._evidenceRemote then
        self._evidenceRemote = self:_resolveEvidenceRemote()
    end
    if not self._evidenceRemote then
        return
    end

    self._remoteConnection = self._evidenceRemote.OnServerEvent:Connect(function(player, request)
        self:OnEvidenceRemoteRequest(player, request)
    end)
end

function Controller:_disconnectEvidenceRemote()
    if self._remoteConnection then
        self._remoteConnection:Disconnect()
        self._remoteConnection = nil
    end
end

function Controller:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Controller:_sendToolResponse(player, payload)
    if not self._evidenceRemote or not player then
        return
    end
    self._evidenceRemote:FireClient(player, payload)
end

function Controller:_resolveMatchIdForPlayer(player, requestPayload)
    local providedMatchId = nil
    local state = self._matchSystem and self._matchSystem.State
    local matches = state and state:Get("matches")
    if type(matches) ~= "table" then
        return nil
    end

    for matchId, match in pairs(matches) do
        if (not providedMatchId) or matchId == providedMatchId then
            local players = match and match.players
            for _, entry in ipairs(players or {}) do
                if entry == player then
                    return matchId
                end
                if type(entry) == "number" and player and entry == player.UserId then
                    return matchId
                end
                if typeof(entry) == "Instance" and entry:IsA("Player") and player and entry.UserId == player.UserId then
                    return matchId
                end
            end
        end
    end

    return nil
end

function Controller:_validateRemoteRequest(player, remoteName, request)
    if type(request) ~= "table" then
        return false, "invalid_request"
    end

    local resolvedRemoteName = remoteName or EVIDENCE_REMOTE_NAME
    self:_publish("RemoteEventReceived", {
        player = player,
        remoteName = resolvedRemoteName,
        payload = request,
        context = {
            system = "EvidenceSystem",
        },
    })

    if not self._security then
        return true
    end

    local ok, reason = self._security:ValidateRemoteRequest(player, resolvedRemoteName, request, {
        system = "EvidenceSystem",
    })
    if not ok then
        return false, reason or "blocked_by_security"
    end
    return true
end

function Controller:OnEvidenceRemoteRequest(player, request)
    if not self:_isPlayerValid(player) then
        return
    end
    if type(request) ~= "table" then
        return
    end
    if type(request.payload) ~= "table" then
        return
    end

    local now = os.clock()
    if self:_isRateLimited(player.UserId, EVIDENCE_REMOTE_NAME, now) then
        return
    end

    local action = request.action
    if type(action) ~= "string" then
        return
    end

    local requestPayload = request.payload
    local canonicalToolType = normalizeToolType(request.toolType or requestPayload.toolType)
    if not canonicalToolType then
        warn("[ANTICHEAT] Invalid evidence submission from userId", player.UserId)
        return
    end
    if not self:_isEvidenceTypeAllowed(canonicalToolType) then
        warn("[ANTICHEAT] Invalid evidence submission from userId", player.UserId)
        return
    end

    local matchId = self:_resolveMatchIdForPlayer(player, requestPayload)
    if not matchId then
        return
    end

    if self:_isSpectator(matchId, player) then
        return
    end

    if not self:_isPlayerAlive(matchId, player) then
        return
    end

	if UTILITY_TOOL_TYPES[canonicalToolType] ~= true and not self:_validateEvidenceNode(matchId, requestPayload, canonicalToolType) then
		warn("[ANTICHEAT] Invalid evidence submission from userId", player.UserId)
		return
	end

    local validRequest = self:_validateRemoteRequest(player, EVIDENCE_REMOTE_NAME, request)
    if not validRequest then
        return
    end

    if action ~= "UseEvidenceTool" and action ~= "ToolUsed" then
        return
    end

    if self._security and type(self._security.ValidateMatchRequest) == "function" then
        local ok = self._security:ValidateMatchRequest(player, {
            action = "EvidenceToolUse",
            targetPosition = requestPayload.targetPosition,
        })
        if not ok then
            return
        end
    end

    local ok, reason, result = self._service:ProcessToolUse(player, matchId, {
        toolType = canonicalToolType,
        payload = requestPayload,
        evidenceNodeId = requestPayload.evidenceNodeId or requestPayload.nodeId,
        nodeId = requestPayload.nodeId,
    })

    self:_sendToolResponse(player, {
        eventName = TOOL_RESULT_EVENT_NAME,
        requestId = request.requestId,
        matchId = matchId,
        toolType = canonicalToolType,
        success = ok,
        reason = reason,
        result = result,
    })
end

function Controller:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self._service:StartMatch(matchId, payload)
    local evidenceCount = tonumber(payload and payload.difficultyProfile and payload.difficultyProfile.EvidenceCount)
        or tonumber(payload and payload.EvidenceCount)
        or 1
    evidenceCount = math.max(1, math.floor(evidenceCount))
    for _ = 1, evidenceCount do
        self._service:SpawnEvidence(matchId, {
            source = "match_start",
            activity = 0,
            now = payload and payload.now,
        })
    end
end

function Controller:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    if type(payload) == "table" and payload.evidenceFound == nil then
        local collected = self._service:GetCollectedEvidence(matchId) or {}
        payload.evidenceFound = #collected
    end
    self._service:EndMatch(matchId)
end

function Controller:OnGhostSpawned(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:SetGhostProfile(matchId, {
        ghostType = payload.ghostType,
        favoriteRoomId = payload.favoriteRoomId,
    })
end

function Controller:OnPhaseStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    local phaseName = payload.phaseName
    if phaseName ~= "Investigation" then
        return
    end

    self._service:SpawnEvidence(matchId, {
        source = "phase_tick",
        activity = payload.activity or 0,
        roomId = payload.roomId,
        now = payload.now,
    })
end

function Controller:OnGhostInteraction(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

	self._service:SpawnEvidence(matchId, {
		source = "ghost_interaction",
		trigger = "ghost_interaction",
		activity = payload.intensity or payload.activity or 2,
		roomId = payload.room,
		now = payload.now,
	})
	self._service:NotifyGhostPresence(matchId, {
		now = payload.now,
		roomId = payload.room or payload.roomId,
		source = "ghost_interaction",
	})
end

function Controller:OnGhostStateChanged(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    if payload.currentState ~= "Manifest" then
        return
    end

	self._service:SpawnEvidence(matchId, {
		source = "ghost_manifest",
		trigger = "manifest",
		activity = payload.intensity or 4,
		roomId = payload.roomId,
		now = payload.now,
	})
	self._service:NotifyGhostPresence(matchId, {
		now = payload.now,
		roomId = payload.roomId,
		source = "ghost_manifest",
	})
end

function Controller:OnEvidenceCollected(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self:_broadcastEvidence(matchId, {
        eventName = "EvidenceCollected",
        matchId = matchId,
        evidenceType = payload.evidenceType,
        playerId = payload.userId or (payload.player and payload.player.UserId),
        toolType = payload.toolType,
    })
    self:_broadcastEvidenceFound(matchId, {
        matchId = matchId,
        evidenceType = payload.evidenceType,
        playerId = payload.userId or (payload.player and payload.player.UserId),
        toolType = payload.toolType,
    })

    if payload.toolNearGhostRoom ~= true and payload.nearGhostRoom ~= true then
        return
    end

    self._service:SpawnEvidence(matchId, {
        source = "tool_near_ghost",
        trigger = "near_tool",
        activity = payload.activity or 3,
        roomId = payload.roomId,
        now = payload.now,
    })
end

function Controller:OnGhostManifest(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:SpawnEvidence(matchId, {
        source = "horror_director_manifest",
        trigger = "manifest",
        activity = payload.activity or 3,
        roomId = payload.roomId,
        now = payload.now,
    })
end

function Controller:OnTensionIncreased(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    local delta = payload and payload.delta
    if type(delta) == "number" and delta < MIN_TENSION_DELTA_FOR_SPAWN then
        return
    end
    local now = payload and payload.now or os.clock()
    local lastAt = self._lastTensionSpawnAtByMatch[matchId] or 0
    if (now - lastAt) < TENSION_SPAWN_COOLDOWN_SECONDS then
        return
    end
    self._lastTensionSpawnAtByMatch[matchId] = now
    self._service:SpawnEvidence(matchId, {
        source = "horror_director_tension",
        trigger = "phase_tick",
        activity = payload.delta or 1,
        roomId = payload.roomId,
        now = payload.now,
    })
end

function Controller:OnInvestigationEvidenceRequested(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:CollectEvidence(payload and payload.player, matchId, payload or {})
end

function Controller:OnInvestigationToolUsed(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:SpawnEvidence(matchId, {
        source = "investigation_tool",
        trigger = "near_tool",
        activity = payload.activity or 1,
        roomId = payload.roomId,
        now = payload.now,
    })
end

function Controller:OnInvestigationGhostGuessSubmitted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:ValidateJournalGuess(payload and payload.player, matchId, payload or {})
end

function Controller:OnDirectorTensionChanged(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:UpdateDirectorTension(matchId, payload.tension)
end

function Controller:OnGhostPersonalityAssigned(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:UpdateGhostPersonality(matchId, {
        name = payload.personality,
        eventFrequency = payload.eventFrequency,
        fakeEvidenceChance = payload.fakeEvidenceChance,
    })
end

function Controller:OnGhostPersonalitySelected(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    local personalityType = payload and (payload.personalityType or (payload.personality and payload.personality.type))
    self._service:UpdateGhostPersonality(matchId, {
        name = personalityType,
        eventFrequency = 1.0,
        fakeEvidenceChance = 0.0,
    })
end

function Controller:OnSpectatorVisionUpdated(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._service:UpdateSpectatorVision(matchId, payload)
end

return Controller


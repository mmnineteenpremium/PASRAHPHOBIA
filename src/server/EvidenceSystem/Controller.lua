local Controller = {}
Controller.__index = Controller

local MIN_TENSION_DELTA_FOR_SPAWN = 1
local TENSION_SPAWN_COOLDOWN_SECONDS = 2.5
local TOOL_RESULT_EVENT_NAME = "EvidenceToolResult"
local EVIDENCE_REMOTE_NAME = "EvidenceEvent"
local REMOTE_FUNCTIONS_FOLDER_NAME = "RemoteFunctions"
local EVIDENCE_REQUEST_FUNCTION_NAME = "EvidenceRequest"

local TOOL_ALIASES = {
	emf = "JejakEnergi",
	jejakenergi = "JejakEnergi",
	spiritbox = "KotakArwah",
	kotakarwah = "KotakArwah",
	thermometer = "SuhuMembeku",
	thermo = "SuhuMembeku",
	suhumembeku = "SuhuMembeku",
	writingbook = "BukuTerkutuk",
	bukuterkutuk = "BukuTerkutuk",
	orbcamera = "BolaArwah",
	bolaarwah = "BolaArwah",
	motionsensor = "GerakanGaib",
	gerakangaib = "GerakanGaib",
	emfscan = "JejakEnergi",
	spiritboxquestion = "KotakArwah",
	temperaturereading = "SuhuMembeku",
	ghostwritingcheck = "BukuTerkutuk",
}

local function resolveEventBus(deps)
    local eventBus = deps.EventBus
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
    local security = deps.SecuritySystem
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

local function resolveMatchSystem(deps)
    local match = deps.MatchSystem
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
    self._evidenceRemote = nil
    self._remoteConnection = nil
    self._evidenceRequestFunction = nil
    self._handlersRegistered = false
    self._lastTensionSpawnAtByMatch = {}
    return self
end

function Controller:Init()
    self._evidenceRemote = self:_resolveEvidenceRemote()
    self._evidenceRequestFunction = self:_resolveEvidenceRequestFunction()
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
    self:_connectEvidenceRequestFunction()
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
    self:_disconnectEvidenceRemote()
    self:_disconnectEvidenceRequestFunction()
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

function Controller:_resolveEvidenceRequestFunction()
    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if not ok then
        return nil
    end

    local remoteFunctionsFolder = replicatedStorage:FindFirstChild(REMOTE_FUNCTIONS_FOLDER_NAME)
    if not remoteFunctionsFolder then
        remoteFunctionsFolder = Instance.new("Folder")
        remoteFunctionsFolder.Name = REMOTE_FUNCTIONS_FOLDER_NAME
        remoteFunctionsFolder.Parent = replicatedStorage
    end

    local requestFunction = remoteFunctionsFolder:FindFirstChild(EVIDENCE_REQUEST_FUNCTION_NAME)
    if requestFunction and requestFunction:IsA("RemoteFunction") then
        return requestFunction
    end

    local created = Instance.new("RemoteFunction")
    created.Name = EVIDENCE_REQUEST_FUNCTION_NAME
    created.Parent = remoteFunctionsFolder
    return created
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

function Controller:_connectEvidenceRequestFunction()
    if not self._evidenceRequestFunction then
        self._evidenceRequestFunction = self:_resolveEvidenceRequestFunction()
    end
    if not self._evidenceRequestFunction then
        return
    end

    self._evidenceRequestFunction.OnServerInvoke = function(player, request)
        return self:OnEvidenceRequestInvoke(player, request)
    end
end

function Controller:_disconnectEvidenceRemote()
    if self._remoteConnection then
        self._remoteConnection:Disconnect()
        self._remoteConnection = nil
    end
end

function Controller:_disconnectEvidenceRequestFunction()
    if self._evidenceRequestFunction then
        self._evidenceRequestFunction.OnServerInvoke = nil
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
    local providedMatchId = requestPayload and requestPayload.matchId
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
    local validRequest, requestErr = self:_validateRemoteRequest(player, EVIDENCE_REMOTE_NAME, request)
    local requestId = type(request) == "table" and request.requestId or nil
    if not validRequest then
        self:_sendToolResponse(player, {
            eventName = TOOL_RESULT_EVENT_NAME,
            requestId = requestId,
            success = false,
            reason = requestErr,
        })
        return
    end

    local action = request.action
    if action ~= "UseEvidenceTool" and action ~= "ToolUsed" then
        self:_sendToolResponse(player, {
            eventName = TOOL_RESULT_EVENT_NAME,
            requestId = requestId,
            success = false,
            reason = "unsupported_action",
        })
        return
    end

    local requestPayload = type(request.payload) == "table" and request.payload or {}
    if self._security and type(self._security.ValidateMatchRequest) == "function" then
        local ok, reason = self._security:ValidateMatchRequest(player, {
            action = "EvidenceToolUse",
            targetPosition = requestPayload.targetPosition,
        })
        if not ok then
            self:_sendToolResponse(player, {
                eventName = TOOL_RESULT_EVENT_NAME,
                requestId = requestId,
                success = false,
                reason = reason or "match_validation_failed",
            })
            return
        end
    end

    local canonicalToolType = normalizeToolType(request.toolType or requestPayload.toolType)
    if not canonicalToolType then
        self:_sendToolResponse(player, {
            eventName = TOOL_RESULT_EVENT_NAME,
            requestId = requestId,
            success = false,
            reason = "invalid_tool_type",
        })
        return
    end

    local matchId = self:_resolveMatchIdForPlayer(player, requestPayload)
    if not matchId then
        self:_sendToolResponse(player, {
            eventName = TOOL_RESULT_EVENT_NAME,
            requestId = requestId,
            success = false,
            reason = "missing_match_id",
            toolType = canonicalToolType,
        })
        return
    end

    local ok, reason, result = self._service:ProcessToolUse(player, matchId, {
        toolType = canonicalToolType,
        payload = requestPayload,
    })

    self:_sendToolResponse(player, {
        eventName = TOOL_RESULT_EVENT_NAME,
        requestId = requestId,
        matchId = matchId,
        toolType = canonicalToolType,
        success = ok,
        reason = reason,
        result = result,
    })
end

function Controller:_normalizeRequestType(request)
    local requestType = request and (request.requestType or request.action)
    if type(requestType) ~= "string" then
        return nil
    end
    return requestType:gsub("[%s_%-_]+", ""):lower()
end

function Controller:_resolveToolTypeFromRequest(request)
    local requestPayload = type(request.payload) == "table" and request.payload or {}
    local rawToolType = request.toolType or requestPayload.toolType
    local canonicalTool = normalizeToolType(rawToolType)
    if canonicalTool then
        return canonicalTool
    end
    local normalizedRequestType = self:_normalizeRequestType(request)
    if normalizedRequestType then
        return TOOL_ALIASES[normalizedRequestType]
    end
    return nil
end

function Controller:_buildEvidenceRequestData(toolType, ok, reason, result)
    local evidenceData = {
        toolType = toolType,
        validated = ok == true,
        reason = reason,
    }

    if toolType == "JejakEnergi" then
        evidenceData.requestType = "EMFScan"
        evidenceData.emfLevel = ok and 5 or 1
    elseif toolType == "KotakArwah" then
        evidenceData.requestType = "SpiritBoxQuestion"
        evidenceData.ghostResponse = ok == true
        evidenceData.responseText = ok and "Behind you..." or "..."
    elseif toolType == "SuhuMembeku" then
        evidenceData.requestType = "TemperatureReading"
        evidenceData.temperatureC = ok and -5 or 9
        evidenceData.freezing = ok == true
    elseif toolType == "BukuTerkutuk" then
        evidenceData.requestType = "GhostWritingCheck"
        evidenceData.writingAppeared = ok == true
    end

    if type(result) == "table" then
        evidenceData.result = result
    end
    return evidenceData
end

function Controller:OnEvidenceRequestInvoke(player, request)
    local validRequest, requestErr = self:_validateRemoteRequest(player, EVIDENCE_REQUEST_FUNCTION_NAME, request)
    if not validRequest then
        return {
            success = false,
            reason = requestErr,
        }
    end

    local requestPayload = type(request.payload) == "table" and request.payload or {}
    if self._security and type(self._security.ValidateMatchRequest) == "function" then
        local ok, reason = self._security:ValidateMatchRequest(player, {
            action = "EvidenceRequest",
            targetPosition = requestPayload.targetPosition,
        })
        if not ok then
            return {
                success = false,
                reason = reason or "match_validation_failed",
            }
        end
    end

    local toolType = self:_resolveToolTypeFromRequest(request)
    if not toolType then
        return {
            success = false,
            reason = "invalid_request_type",
        }
    end

    local matchId = self:_resolveMatchIdForPlayer(player, requestPayload)
    if not matchId then
        return {
            success = false,
            reason = "missing_match_id",
            toolType = toolType,
        }
    end

    local ok, reason, result = self._service:ProcessToolUse(player, matchId, {
        toolType = toolType,
        payload = requestPayload,
    })

    return {
        success = ok,
        reason = reason,
        matchId = matchId,
        toolType = toolType,
        data = self:_buildEvidenceRequestData(toolType, ok, reason, result),
    }
end

function Controller:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    self._service:StartMatch(matchId, payload)
    self._service:SpawnEvidence(matchId, {
        source = "match_start",
        activity = 0,
        now = payload and payload.now,
    })
end

function Controller:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
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
end

function Controller:OnEvidenceCollected(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

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


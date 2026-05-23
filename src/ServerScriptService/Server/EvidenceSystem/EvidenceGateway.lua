local EvidenceGateway = {}
EvidenceGateway.__index = EvidenceGateway
local Services = require(script.Parent.Parent.Core.Services)

local REMOTE_FUNCTIONS_FOLDER_NAME = "RemoteFunctions"
local EVIDENCE_REQUEST_FUNCTION_NAME = "EvidenceRequest"
local READY_ATTRIBUTE_NAME = "PasrahEvidenceGatewayReady"
local TOOL_REQUEST_COOLDOWN_SECONDS = 0.4
local MAX_GHOST_SCAN_DISTANCE = 22
local MODDED_SPIRIT_BOX_RANGE = 26
local ELITE_SPIRIT_BOX_RANGE = 30
local MODDED_SPIRIT_BOX_OWNED_ATTR = "PasrahOwnsModdedSpiritBox"
local ELITE_SPIRIT_BOX_OWNED_ATTR = "PasrahOwnsEliteSpiritBox"
local MATCH_MODE_ATTR = "MatchMode"

local EVIDENCE_NAME_BY_TOOL = {
	JejakEnergi = "MEDOK",
	KotakArwah = "Suara",
	SuhuMembeku = "Suhu",
	BukuTerkutuk = "Buku Terkutuk",
	BolaArwah = "To'un",
	GerakanGaib = "Pengganggu",
}

local UTILITY_TOOL_TYPES = {
	Garam = true,
	PilSanity = true,
	Salib = true,
	Dupa = true,
}

local REQUEST_TYPE_TO_TOOL = {
	jejakenergiscan = "JejakEnergi",
	kotakarwahquestion = "KotakArwah",
	suhureading = "SuhuMembeku",
	bukuterkutukcheck = "BukuTerkutuk",
	toundetection = "BolaArwah",
	pengganggucheck = "GerakanGaib",
	saltplacement = "Garam",
	sanitypilluse = "PilSanity",
	crucifixplacement = "Salib",
	smudgeignite = "Dupa",
}

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
	saltbag = "Garam",
	salib = "Salib",
	crucifix = "Salib",
	dupa = "Dupa",
	pilsanity = "PilSanity",
	sanitypill = "PilSanity",
	smudge = "Dupa",
	smudgestick = "Dupa",
}

local function setStudioEvidenceGatewayTrace(player, stage, detail)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return
	end
	player:SetAttribute("PasrahEvidenceGatewayStage", tostring(stage or "unknown"))
	if detail ~= nil then
		player:SetAttribute("PasrahEvidenceGatewayDetail", tostring(detail))
	end
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

local function resolveMatchSystem(deps)
	local match = Services.Get(deps, "MatchSystem")
	if type(match) ~= "table" then
		return nil
	end
	return match
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

local function resolveSanitySystem(deps)
	local sanity = Services.Get(deps, "SanitySystem")
	if type(sanity) ~= "table" then
		return nil
	end
	if type(sanity.GetSanity) == "function" then
		return sanity
	end
	if type(sanity.Service) == "table" and type(sanity.Service.GetSanity) == "function" then
		return sanity.Service
	end
	return nil
end

local function normalizeToken(value)
	if type(value) ~= "string" then
		return nil
	end
	return value:gsub("[%s_%-_]+", ""):lower()
end

function EvidenceGateway.new(service, deps)
	local self = setmetatable({}, EvidenceGateway)
	self._service = service
	self._deps = deps or {}
	self._eventBus = resolveEventBus(self._deps)
	self._security = resolveSecurityService(self._deps)
	self._matchSystem = resolveMatchSystem(self._deps)
	self._sanitySystem = resolveSanitySystem(self._deps)
	self._spectatorSystem = resolveSpectatorSystem(self._deps)
	self._requestRemote = nil
	self._lastRequestAtByUserId = {}
	return self
end

function EvidenceGateway:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function EvidenceGateway:_resolveRemoteFunction()
	local ok, replicatedStorage = pcall(function()
		return game:GetService("ReplicatedStorage")
	end)
	if not ok or typeof(replicatedStorage) ~= "Instance" then
		return nil
	end

	local remoteFunctionsFolder = replicatedStorage:FindFirstChild(REMOTE_FUNCTIONS_FOLDER_NAME)
	if not remoteFunctionsFolder then
		remoteFunctionsFolder = Instance.new("Folder")
		remoteFunctionsFolder.Name = REMOTE_FUNCTIONS_FOLDER_NAME
		remoteFunctionsFolder.Parent = replicatedStorage
	elseif not remoteFunctionsFolder:IsA("Folder") then
		warn(string.format(
			"[EvidenceGateway] Canonical path ReplicatedStorage.%s is not a Folder",
			REMOTE_FUNCTIONS_FOLDER_NAME
		))
		return nil
	end

	local requestFunction = remoteFunctionsFolder:FindFirstChild(EVIDENCE_REQUEST_FUNCTION_NAME)
	if not requestFunction then
		requestFunction = Instance.new("RemoteFunction")
		requestFunction.Name = EVIDENCE_REQUEST_FUNCTION_NAME
		requestFunction.Parent = remoteFunctionsFolder
	elseif not requestFunction:IsA("RemoteFunction") then
		warn(string.format(
			"[EvidenceGateway] Canonical remote ReplicatedStorage.%s.%s is not a RemoteFunction",
			REMOTE_FUNCTIONS_FOLDER_NAME,
			EVIDENCE_REQUEST_FUNCTION_NAME
		))
		return nil
	end
	return requestFunction
end

function EvidenceGateway:_setReadyFlag(isReady)
	local ok, replicatedStorage = pcall(function()
		return game:GetService("ReplicatedStorage")
	end)
	if ok and typeof(replicatedStorage) == "Instance" then
		replicatedStorage:SetAttribute(READY_ATTRIBUTE_NAME, isReady == true)
	end
end

function EvidenceGateway:_bindRemoteFunction()
	self._requestRemote = self:_resolveRemoteFunction()
	if not self._requestRemote then
		self:_setReadyFlag(false)
		return false
	end
	self._requestRemote.OnServerInvoke = function(player, request)
		return self:HandleRequest(player, request)
	end
	self:_setReadyFlag(true)
	return true
end

function EvidenceGateway:Start()
	self:_bindRemoteFunction()
end

function EvidenceGateway:Stop()
	if self._requestRemote then
		self._requestRemote.OnServerInvoke = nil
	end
	self:_setReadyFlag(false)
	table.clear(self._lastRequestAtByUserId)
end

function EvidenceGateway:_resolveMatchIdForPlayer(player, requestPayload)
	local providedMatchId = requestPayload and requestPayload.matchId
	if player and providedMatchId == nil then
		providedMatchId = player:GetAttribute("MatchId")
	end
	if providedMatchId ~= nil then
		providedMatchId = tostring(providedMatchId)
	end
	local state = self._matchSystem and self._matchSystem.State
	local matches = state and state:Get("matches")
	if type(matches) ~= "table" then
		return providedMatchId
	end

	if providedMatchId and matches[providedMatchId] ~= nil then
		return providedMatchId
	end

	for matchId, match in pairs(matches) do
		if (not providedMatchId) or matchId == providedMatchId then
			for _, entry in ipairs((match and match.players) or {}) do
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


function EvidenceGateway:_isEvidenceTypeAllowed(evidenceType)
	return type(evidenceType) == "string" and EVIDENCE_NAME_BY_TOOL[evidenceType] ~= nil
end

function EvidenceGateway:_isSupportedToolType(toolType)
	return self:_isEvidenceTypeAllowed(toolType) or UTILITY_TOOL_TYPES[toolType] == true
end

function EvidenceGateway:_resolveToolType(request)
	local requestPayload = type(request.payload) == "table" and request.payload or {}

	local toolToken = normalizeToken(request.toolType or requestPayload.toolType)
	if toolToken and TOOL_ALIASES[toolToken] then
		return TOOL_ALIASES[toolToken]
	end

	local requestTypeToken = normalizeToken(request.requestType or request.action)
	if requestTypeToken and REQUEST_TYPE_TO_TOOL[requestTypeToken] then
		return REQUEST_TYPE_TO_TOOL[requestTypeToken]
	end

	return nil
end

function EvidenceGateway:_isJournalSubmitRequest(request)
	local requestTypeToken = normalizeToken(request and (request.action or request.requestType))
	return requestTypeToken == "submitjournalguess" or requestTypeToken == "journalguesssubmit"
end

function EvidenceGateway:_isJournalEndRequest(request)
	local requestTypeToken = normalizeToken(request and (request.action or request.requestType))
	return requestTypeToken == "endinvestigation" or requestTypeToken == "lockanswer"
end

function EvidenceGateway:_fireEvidenceEvent(player, payload)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return
	end
	local ok, replicatedStorage = pcall(function()
		return game:GetService("ReplicatedStorage")
	end)
	if not ok or typeof(replicatedStorage) ~= "Instance" then
		return
	end
	local remoteFolder = replicatedStorage:FindFirstChild("RemoteEvents")
	local remote = remoteFolder and remoteFolder:FindFirstChild("EvidenceEvent") or nil
	if remote and remote:IsA("RemoteEvent") then
		remote:FireClient(player, payload)
	end
end

function EvidenceGateway:_buildData(toolType, ok, reason, result)
	local data = {
		toolType = toolType,
		validated = ok == true,
		reason = reason,
	}

	if toolType == "JejakEnergi" then
		data.requestType = "JejakEnergiScan"
		data.emfLevel = ok and 5 or 1
	elseif toolType == "KotakArwah" then
		data.requestType = "KotakArwahQuestion"
		data.ghostResponse = ok == true
		data.responseText = type(result) == "table" and result.responseText or (ok and "Behind you..." or "...")
		data.responseTier = type(result) == "table" and result.responseTier or "base"
		data.detectionChance = type(result) == "table" and result.detectionChance or nil
	elseif toolType == "SuhuMembeku" then
		data.requestType = "SuhuReading"
		data.temperatureC = ok and -5 or 9
		data.freezing = ok == true
	elseif toolType == "BukuTerkutuk" then
		data.requestType = "BukuTerkutukCheck"
		data.writingAppeared = ok == true
	elseif toolType == "BolaArwah" then
		data.requestType = "TounDetection"
		data.ghostOrbDetected = ok == true
	elseif toolType == "GerakanGaib" then
		data.requestType = "PenggangguCheck"
		data.motionDetected = ok == true
	elseif toolType == "Garam" then
		data.requestType = "SaltPlacement"
		data.utility = true
		data.tracksDetected = type(result) == "table" and result.tracksDetected == true or false
		data.placementActive = type(result) == "table" and result.placementActive == true or false
		data.placementId = type(result) == "table" and result.placementId or nil
		data.roomId = type(result) == "table" and result.roomId or nil
		data.usesRemaining = type(result) == "table" and result.usesRemaining or nil
		data.visualPlaced = type(result) == "table" and result.visualPlaced == true or false
	elseif toolType == "Salib" then
		data.requestType = "CrucifixPlacement"
		data.utility = true
		data.chargesRemaining = type(result) == "table" and result.chargesRemaining or nil
		data.placementActive = type(result) == "table" and result.placementActive == true or false
		data.placementId = type(result) == "table" and result.placementId or nil
		data.roomId = type(result) == "table" and result.roomId or nil
		data.usesRemaining = type(result) == "table" and result.usesRemaining or nil
		data.visualPlaced = type(result) == "table" and result.visualPlaced == true or false
	elseif toolType == "Dupa" then
		data.requestType = "SmudgeIgnite"
		data.utility = true
		data.placementId = type(result) == "table" and result.placementId or nil
		data.repellentUntil = type(result) == "table" and result.repellentUntil or nil
		data.sanityRestored = type(result) == "table" and result.sanityRestored or nil
		data.huntRepelled = type(result) == "table" and result.huntRepelled == true or false
		data.roomId = type(result) == "table" and result.roomId or nil
		data.usesRemaining = type(result) == "table" and result.usesRemaining or nil
		data.visualPlaced = type(result) == "table" and result.visualPlaced == true or false
	elseif toolType == "PilSanity" then
		data.requestType = "SanityPillUse"
		data.utility = true
		data.sanityRestored = type(result) == "table" and result.sanityRestored or nil
		data.resultingSanity = type(result) == "table" and result.resultingSanity or nil
		data.usesRemaining = type(result) == "table" and result.usesRemaining or nil
		data.tier = type(result) == "table" and result.tier or nil
	end

	if type(result) == "table" then
		data.evidenceType = result.evidenceType or data.evidenceType
		data.visualPlaced = result.visualPlaced == true
		data.visualKind = result.visualKind
		data.visualPosition = result.visualPosition
		data.result = result
	end
	return data
end

function EvidenceGateway:_validateRequest(player, request)
	setStudioEvidenceGatewayTrace(player, "validate_request_begin")
	if type(request) ~= "table" then
		return false, "invalid_request"
	end

	setStudioEvidenceGatewayTrace(player, "before_remote_event_publish")
	self:_publish("RemoteEventReceived", {
		player = player,
		remoteName = EVIDENCE_REQUEST_FUNCTION_NAME,
		payload = request,
		context = {
			system = "EvidenceSystem",
		},
	})
	setStudioEvidenceGatewayTrace(player, "after_remote_event_publish")

	if self._security then
		setStudioEvidenceGatewayTrace(player, "before_security_validate_remote")
		local ok, reason = self._security:ValidateRemoteRequest(player, EVIDENCE_REQUEST_FUNCTION_NAME, request, {
			system = "EvidenceSystem",
		})
		setStudioEvidenceGatewayTrace(player, "after_security_validate_remote", reason or "ok")
		if not ok then
			return false, reason or "blocked_by_security"
		end
	end
	return true
end

function EvidenceGateway:_handleSubmitJournalGuess(player, request)
	local requestPayload = type(request.payload) == "table" and request.payload or {}
	local matchId = self:_resolveMatchIdForPlayer(player, requestPayload)
	if self._spectatorSystem and type(self._spectatorSystem.IsSpectator) == "function" then
		if self._spectatorSystem:IsSpectator(matchId, player) then
			return {
				success = false,
				reason = "spectator_blocked",
			}
		end
	end
	if not matchId then
		return {
			success = false,
			reason = "missing_match_id",
		}
	end

	local now = os.clock()
	local guessedGhostType = requestPayload.ghostType or requestPayload.guessedGhostType
	local guessedEvidence = type(requestPayload.evidence) == "table" and requestPayload.evidence
		or (type(requestPayload.selectedEvidence) == "table" and requestPayload.selectedEvidence or {})
	local ok, reason, result = self._service:ValidateJournalGuess(player, matchId, {
		ghostType = guessedGhostType,
		evidence = guessedEvidence,
		now = now,
		source = "JournalSubmit",
	})
	local identified = ok == true and type(result) == "table" and result.identified == true
	local internalPayload = {
		player = player,
		userId = player and player.UserId or nil,
		matchId = matchId,
		guessedGhostType = type(result) == "table" and result.guessedGhostType or guessedGhostType,
		actualGhostType = type(result) == "table" and result.actualGhostType or nil,
		correct = identified,
		identified = identified,
		ghostMatches = type(result) == "table" and result.ghostMatches == true or false,
		evidenceMatches = type(result) == "table" and result.evidenceMatches == true or false,
		guessedEvidence = type(result) == "table" and result.guessedEvidence or guessedEvidence,
		expectedEvidence = type(result) == "table" and result.expectedEvidence or nil,
		reason = reason,
		source = "JournalSubmit",
		validatedAt = now,
	}

	if ok == true then
		self:_publish("GhostGuessValidated", internalPayload)
	end

	local clientData = {
		identified = identified,
		correct = identified,
		guessedGhostType = internalPayload.guessedGhostType,
		guessedEvidence = internalPayload.guessedEvidence,
	}
	if identified then
		clientData.actualGhostType = internalPayload.actualGhostType
		clientData.expectedEvidence = internalPayload.expectedEvidence
	end

	local clientPayload = {
		eventName = "JournalGuessResult",
		matchId = matchId,
		success = ok == true,
		reason = reason,
		identified = identified,
		correct = identified,
		guessedGhostType = clientData.guessedGhostType,
		guessedEvidence = clientData.guessedEvidence,
		data = clientData,
		autoOpenJournal = true,
	}
	if identified then
		clientPayload.actualGhostType = clientData.actualGhostType
		clientPayload.expectedEvidence = clientData.expectedEvidence
	end
	self:_fireEvidenceEvent(player, clientPayload)

	return {
		success = ok == true,
		reason = reason,
		matchId = matchId,
		requestType = "SubmitJournalGuess",
		data = clientData,
	}
end

function EvidenceGateway:_handleEndInvestigation(player, request)
	local requestPayload = type(request.payload) == "table" and request.payload or {}
	local matchId = self:_resolveMatchIdForPlayer(player, requestPayload)
	if not matchId then
		return {
			success = false,
			reason = "missing_match_id",
		}
	end
	if self._spectatorSystem and type(self._spectatorSystem.IsSpectator) == "function" then
		if self._spectatorSystem:IsSpectator(matchId, player) then
			return {
				success = false,
				reason = "spectator_blocked",
			}
		end
	end

	local guessedGhostType = requestPayload.ghostType or requestPayload.guessedGhostType
	local guessedEvidence = type(requestPayload.evidence) == "table" and requestPayload.evidence
		or (type(requestPayload.selectedEvidence) == "table" and requestPayload.selectedEvidence or {})
	local now = os.clock()
	local ok, reason, result = self._service:ValidateJournalGuess(player, matchId, {
		ghostType = guessedGhostType,
		evidence = guessedEvidence,
		now = now,
		source = "JournalEndInvestigation",
	})
	if ok ~= true then
		return {
			success = false,
			reason = reason or "guess_not_ready",
			matchId = matchId,
			requestType = "EndInvestigation",
		}
	end

	local identified = type(result) == "table" and result.identified == true
	local actualGhostType = type(result) == "table" and result.actualGhostType or nil
	local resolvedGuess = type(result) == "table" and result.guessedGhostType or guessedGhostType
	local resolvedEvidence = type(result) == "table" and result.guessedEvidence or guessedEvidence
	local expectedEvidence = type(result) == "table" and result.expectedEvidence or nil

	self:_publish("GhostGuessValidated", {
		player = player,
		userId = player and player.UserId or nil,
		matchId = matchId,
		guessedGhostType = resolvedGuess,
		actualGhostType = actualGhostType,
		correct = identified,
		identified = identified,
		ghostMatches = type(result) == "table" and result.ghostMatches == true or false,
		evidenceMatches = type(result) == "table" and result.evidenceMatches == true or false,
		guessedEvidence = resolvedEvidence,
		expectedEvidence = expectedEvidence,
		reason = reason,
		source = "JournalEndInvestigation",
		validatedAt = now,
	})

	self:_publish("MatchPhaseTransitionRequested", {
		matchId = matchId,
		endMatch = true,
		reason = "journal_end_investigation",
		extractionCompleted = true,
		ghostIdentified = identified,
		results = {
			reason = "journal_end_investigation",
			extractionCompleted = true,
			ghostIdentified = identified,
			correctGuess = identified,
			contractSuccess = identified,
			teamSuccess = identified,
			ghostType = actualGhostType,
			guessedGhostType = resolvedGuess,
			guessedEvidence = resolvedEvidence,
			expectedEvidence = expectedEvidence,
			evidenceCollected = #(resolvedEvidence or {}),
			source = "JournalEndInvestigation",
		},
	})

	self:_fireEvidenceEvent(player, {
		eventName = "JournalInvestigationEnded",
		matchId = matchId,
		success = true,
		reason = "ended_by_player",
		identified = identified,
		correct = identified,
		guessedGhostType = resolvedGuess,
		guessedEvidence = resolvedEvidence,
		actualGhostType = actualGhostType,
		expectedEvidence = expectedEvidence,
		autoOpenJournal = false,
	})

	return {
		success = true,
		reason = "ended",
		matchId = matchId,
		requestType = "EndInvestigation",
		data = {
			identified = identified,
			correct = identified,
			guessedGhostType = resolvedGuess,
			guessedEvidence = resolvedEvidence,
			actualGhostType = actualGhostType,
			expectedEvidence = expectedEvidence,
		},
	}
end

function EvidenceGateway:HandleRequest(player, request)
	setStudioEvidenceGatewayTrace(player, "handle_request_begin")
	local validRequest, requestErr = self:_validateRequest(player, request)
	if not validRequest then
		return {
			success = false,
			reason = requestErr,
		}
	end

	local requestPayload = type(request.payload) == "table" and request.payload or {}
	if self._security and type(self._security.ValidateMatchRequest) == "function" then
		setStudioEvidenceGatewayTrace(player, "before_security_validate_match")
		local ok, reason = self._security:ValidateMatchRequest(player, {
			action = (self:_isJournalSubmitRequest(request) and "SubmitJournalGuess")
				or (self:_isJournalEndRequest(request) and "EndInvestigation")
				or "EvidenceRequest",
			targetPosition = requestPayload.targetPosition,
		})
		setStudioEvidenceGatewayTrace(player, "after_security_validate_match", reason or "ok")
		if not ok then
			return {
				success = false,
				reason = reason or "match_validation_failed",
			}
		end
	end

	local userId = player and player.UserId
	if userId then
		local now = os.clock()
		local last = self._lastRequestAtByUserId[userId] or 0
		if (now - last) < TOOL_REQUEST_COOLDOWN_SECONDS then
			return {
				success = false,
				reason = "tool_cooldown",
			}
		end
		self._lastRequestAtByUserId[userId] = now
	end

	if self:_isJournalSubmitRequest(request) then
		setStudioEvidenceGatewayTrace(player, "before_submit_journal_guess")
		local response = self:_handleSubmitJournalGuess(player, request)
		setStudioEvidenceGatewayTrace(player, "after_submit_journal_guess", response and response.reason or "ok")
		return response
	end
	if self:_isJournalEndRequest(request) then
		setStudioEvidenceGatewayTrace(player, "before_end_investigation")
		local response = self:_handleEndInvestigation(player, request)
		setStudioEvidenceGatewayTrace(player, "after_end_investigation", response and response.reason or "ok")
		return response
	end

	local toolType = self:_resolveToolType(request)
	local utilityTool = UTILITY_TOOL_TYPES[toolType] == true
	if not toolType or not self:_isSupportedToolType(toolType) then
		return {
			success = false,
			reason = "invalid_request_type",
		}
	end

	local matchId = self:_resolveMatchIdForPlayer(player, requestPayload)
	if self._spectatorSystem and type(self._spectatorSystem.IsSpectator) == "function" then
		if self._spectatorSystem:IsSpectator(matchId, player) then
			return {
				success = false,
				reason = "spectator_blocked",
			}
		end
	end
	if not matchId then
		return {
			success = false,
			reason = "missing_match_id",
			toolType = toolType,
		}
	end

	if self._sanitySystem and type(self._sanitySystem.GetSanity) == "function" then
		setStudioEvidenceGatewayTrace(player, "before_sanity_check")
		local sanity = self._sanitySystem:GetSanity(player, matchId)
		setStudioEvidenceGatewayTrace(player, "after_sanity_check", sanity)
		if type(sanity) == "number" and sanity <= 0 then
			return {
				success = false,
				reason = "insufficient_sanity",
				toolType = toolType,
			}
		end
	end

	local distanceToGhost = tonumber(requestPayload.distanceToGhost)
	local nearGhostRoom = requestPayload.nearGhostRoom == true
	local maxGhostScanDistance = MAX_GHOST_SCAN_DISTANCE
	if toolType == "KotakArwah" and typeof(player) == "Instance" and player:IsA("Player") then
		local rankedMode = player:GetAttribute(MATCH_MODE_ATTR) == "Ranked"
		if not rankedMode and player:GetAttribute(ELITE_SPIRIT_BOX_OWNED_ATTR) == true then
			maxGhostScanDistance = ELITE_SPIRIT_BOX_RANGE
		elseif not rankedMode and player:GetAttribute(MODDED_SPIRIT_BOX_OWNED_ATTR) == true then
			maxGhostScanDistance = MODDED_SPIRIT_BOX_RANGE
		end
	end
	if not utilityTool and (type(distanceToGhost) == "number" and distanceToGhost > maxGhostScanDistance) and not nearGhostRoom then
		return {
			success = false,
			reason = "ghost_out_of_range",
			toolType = toolType,
	}
	end

	setStudioEvidenceGatewayTrace(player, "before_process_tool_use", toolType)
	local ok, reason, result = self._service:ProcessToolUse(player, matchId, {
		toolType = toolType,
		payload = requestPayload,
	})
	setStudioEvidenceGatewayTrace(player, "after_process_tool_use", reason or (ok and "success" or "nil"))

	return {
		success = ok,
		reason = reason,
		matchId = matchId,
		toolType = toolType,
		data = self:_buildData(toolType, ok, reason, result),
	}
end

return EvidenceGateway

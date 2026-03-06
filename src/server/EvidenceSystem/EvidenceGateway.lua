local EvidenceGateway = {}
EvidenceGateway.__index = EvidenceGateway
local Services = require(script.Parent.Parent.Core.Services)

local REMOTE_FUNCTIONS_FOLDER_NAME = "RemoteFunctions"
local EVIDENCE_REQUEST_FUNCTION_NAME = "EvidenceRequest"
local TOOL_REQUEST_COOLDOWN_SECONDS = 0.4
local MAX_GHOST_SCAN_DISTANCE = 22

local REQUEST_TYPE_TO_TOOL = {
	emfscan = "JejakEnergi",
	emfreader = "JejakEnergi",
	spiritboxquestion = "KotakArwah",
	spiritbox = "KotakArwah",
	temperaturereading = "SuhuMembeku",
	thermometer = "SuhuMembeku",
	ghostwritingcheck = "BukuTerkutuk",
	ghostwritingbook = "BukuTerkutuk",
	ghostorbcameradetection = "BolaArwah",
	ghostorbcamera = "BolaArwah",
	motionsensorcheck = "GerakanGaib",
	motionsensor = "GerakanGaib",
}

local TOOL_ALIASES = {
	emf = "JejakEnergi",
	emfreader = "JejakEnergi",
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
	ghostwritingbook = "BukuTerkutuk",
	ghostorbcamera = "BolaArwah",
}

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

function EvidenceGateway:Start()
	if not self._requestRemote then
		self._requestRemote = self:_resolveRemoteFunction()
	end
	if not self._requestRemote then
		return
	end
	self._requestRemote.OnServerInvoke = function(player, request)
		return self:HandleRequest(player, request)
	end
end

function EvidenceGateway:Stop()
	if self._requestRemote then
		self._requestRemote.OnServerInvoke = nil
	end
	table.clear(self._lastRequestAtByUserId)
end

function EvidenceGateway:_resolveMatchIdForPlayer(player, requestPayload)
	local providedMatchId = requestPayload and requestPayload.matchId
	local state = self._matchSystem and self._matchSystem.State
	local matches = state and state:Get("matches")
	if type(matches) ~= "table" then
		return nil
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

function EvidenceGateway:_buildData(toolType, ok, reason, result)
	local data = {
		toolType = toolType,
		validated = ok == true,
		reason = reason,
	}

	if toolType == "JejakEnergi" then
		data.requestType = "EMFScan"
		data.emfLevel = ok and 5 or 1
	elseif toolType == "KotakArwah" then
		data.requestType = "SpiritBoxQuestion"
		data.ghostResponse = ok == true
		data.responseText = ok and "Behind you..." or "..."
	elseif toolType == "SuhuMembeku" then
		data.requestType = "TemperatureReading"
		data.temperatureC = ok and -5 or 9
		data.freezing = ok == true
	elseif toolType == "BukuTerkutuk" then
		data.requestType = "GhostWritingCheck"
		data.writingAppeared = ok == true
	elseif toolType == "BolaArwah" then
		data.requestType = "GhostOrbCameraDetection"
		data.ghostOrbDetected = ok == true
	elseif toolType == "GerakanGaib" then
		data.requestType = "MotionSensorCheck"
		data.motionDetected = ok == true
	end

	if type(result) == "table" then
		data.result = result
	end
	return data
end

function EvidenceGateway:_validateRequest(player, request)
	if type(request) ~= "table" then
		return false, "invalid_request"
	end

	self:_publish("RemoteEventReceived", {
		player = player,
		remoteName = EVIDENCE_REQUEST_FUNCTION_NAME,
		payload = request,
		context = {
			system = "EvidenceSystem",
		},
	})

	if self._security then
		local ok, reason = self._security:ValidateRemoteRequest(player, EVIDENCE_REQUEST_FUNCTION_NAME, request, {
			system = "EvidenceSystem",
		})
		if not ok then
			return false, reason or "blocked_by_security"
		end
	end
	return true
end

function EvidenceGateway:HandleRequest(player, request)
	local validRequest, requestErr = self:_validateRequest(player, request)
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

	local toolType = self:_resolveToolType(request)
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

	if self._sanitySystem and type(self._sanitySystem.GetSanity) == "function" then
		local sanity = self._sanitySystem:GetSanity(player, matchId)
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
	if (type(distanceToGhost) == "number" and distanceToGhost > MAX_GHOST_SCAN_DISTANCE) and not nearGhostRoom then
		return {
			success = false,
			reason = "ghost_out_of_range",
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
		data = self:_buildData(toolType, ok, reason, result),
	}
end

return EvidenceGateway

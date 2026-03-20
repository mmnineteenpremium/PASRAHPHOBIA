local EvidenceGateway = {}
EvidenceGateway.__index = EvidenceGateway
local Services = require(script.Parent.Parent.Core.Services)

local REMOTE_FUNCTIONS_FOLDER_NAME = "RemoteFunctions"
local EVIDENCE_REQUEST_FUNCTION_NAME = "EvidenceRequest"
local TOOL_REQUEST_COOLDOWN_SECONDS = 0.4
local MAX_GHOST_SCAN_DISTANCE = 22

local EVIDENCE_NAME_BY_TOOL = {
	JejakEnergi = "Jejak Energi",
	KotakArwah = "Kotak Arwah",
	SuhuMembeku = "Suhu Membeku",
	BukuTerkutuk = "Buku Terkutuk",
	BolaArwah = "Bola Arwah",
	GerakanGaib = "Gerakan Gaib",
}

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

local function resolveEvidenceConfigSystem(deps)
	local evidenceConfig = Services.Get(deps, "EvidenceConfigSystem")
	if type(evidenceConfig) ~= "table" then
		return nil
	end
	if type(evidenceConfig.GetEvidenceDefinition) == "function" or type(evidenceConfig.GetEvidenceDefinitions) == "function" then
		return evidenceConfig
	end
	if type(evidenceConfig.Service) == "table" and (type(evidenceConfig.Service.GetEvidenceDefinition) == "function" or type(evidenceConfig.Service.GetEvidenceDefinitions) == "function") then
		return evidenceConfig.Service
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

local EVIDENCE_TYPES = resolveSharedEvidenceTypes() or {}
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
	self._evidenceConfigSystem = resolveEvidenceConfigSystem(self._deps)
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
	local providedMatchId = nil
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


function EvidenceGateway:_isEvidenceTypeAllowed(evidenceType)
    if type(evidenceType) ~= "string" then
        return false
    end
    for _, value in pairs(EVIDENCE_TYPES) do
        if value == evidenceType then
            return true
        end
    end
    return false
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

function EvidenceGateway:_resolveEvidenceName(toolType, requestPayload)
	local mapped = EVIDENCE_NAME_BY_TOOL[toolType]
	if mapped then
		return mapped
	end
	if type(requestPayload) == "table" then
		local provided = requestPayload.evidenceName
		if type(provided) == "string" and provided ~= "" then
			return provided
		end
	end
	return nil
end

function EvidenceGateway:_isEvidenceNameValid(evidenceName)
	if type(evidenceName) ~= "string" or evidenceName == "" then
		return false
	end
	if not self._evidenceConfigSystem then
		return false
	end
	if type(self._evidenceConfigSystem.GetEvidenceDefinition) == "function" then
		if self._evidenceConfigSystem:GetEvidenceDefinition(evidenceName) then
			return true
		end
	end
	if type(self._evidenceConfigSystem.GetEvidenceDefinitions) == "function" then
		local definitions = self._evidenceConfigSystem:GetEvidenceDefinitions()
		if type(definitions) == "table" then
			if definitions[evidenceName] ~= nil then
				return true
			end
			for _, definition in pairs(definitions) do
				if type(definition) == "table" and definition.evidenceName == evidenceName then
					return true
				end
			end
		end
	end
	return false
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
	if not toolType or not self:_isEvidenceTypeAllowed(toolType) then
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

	if ok then
		local evidenceName = self:_resolveEvidenceName(toolType, requestPayload)
		if evidenceName and self:_isEvidenceNameValid(evidenceName) then
			self:_publish("EvidenceDetected", evidenceName)
		end
	end

	return {
		success = ok,
		reason = reason,
		matchId = matchId,
		toolType = toolType,
		data = self:_buildData(toolType, ok, reason, result),
	}
end

return EvidenceGateway

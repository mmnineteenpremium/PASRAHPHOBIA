local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local HttpService = game:GetService("HttpService")

local Services = require(script.Parent.Parent.Core.Services)

local StudioE2EControlSystem = {}
StudioE2EControlSystem.__index = StudioE2EControlSystem

local REMOTE_FOLDER_NAME = "RemoteEvents"
local REMOTE_NAME = "StudioE2EControl"
local READY_ATTR = "PasrahStudioE2EReady"
local TRACE_ATTR = "PasrahStudioE2ELastAction"
local RESULT_ATTR = "PasrahStudioE2ELastResult"
local PLAYER_TRACE_ATTR = "PasrahStudioE2ELastAction"
local PLAYER_RESULT_ATTR = "PasrahStudioE2ELastResult"
local GHOST_SNAPSHOT_ATTR = "PasrahStudioGhostRuntimeSnapshot"
local PLAYER_GHOST_SNAPSHOT_ATTR = "PasrahStudioGhostRuntimeSnapshot"
local EXTRACTION_OVERRIDE_ATTR = "PasrahAllowStudioExtraction"
local FORCE_GHOST_TYPE_ATTR = "PasrahForceGhostType"
local FORCE_GHOST_VISUAL_STATE_ATTR = "PasrahForceGhostVisualState"
local QA_GATE_MAX_TOTAL_MEMORY_MB = 2600
local QA_GATE_MIN_PHYSICS_FPS = 35

local VALID_PHASES = {
	PreparationPhase = true,
	InvestigationPhase = true,
	HuntPhase = true,
	EndgamePhase = true,
}

local STUDIO_TOOL_EVIDENCE_MAP = {
	JejakEnergi = "MEDOK",
	KotakArwah = "Suara",
	SuhuMembeku = "Suhu",
	BukuTerkutuk = "BukuTerkutuk",
	BolaArwah = "To'un",
	GerakanGaib = "Pengganggu",
	TounDetection = "To'un",
}
local LOBBY_TRAINING_TOOL_PART_MAP = {
	emf = "Table_Tools_1",
	jejakenergi = "Table_Tools_1",
	uv = "Table_Tools_2",
	uvcam = "Table_Tools_2",
	bolaarwah = "Table_Tools_2",
	thermo = "Table_Tools_3",
	suhumembeku = "Table_Tools_3",
	box = "Table_Tools_4",
	spiritbox = "Table_Tools_4",
	kotakarwah = "Table_Tools_4",
	writing = "Table_Tools_5",
	bukuterkutuk = "Table_Tools_5",
	sensor = "Table_Tools_6",
	gerakangaib = "Table_Tools_6",
}
local LOBBY_TRAINING_SUPPORT_MAP = {
	garam = {
		label = "GARAM",
		toolType = "Garam",
	},
	salib = {
		label = "SALIB",
		toolType = "Salib",
	},
	dupa = {
		label = "DUPA",
		toolType = "Dupa",
	},
}

local function resolveService(deps, name, methodName)
	local service = Services.Get(deps, name)
	if type(service) ~= "table" then
		return nil
	end
	if type(service[methodName]) == "function" then
		return service
	end
	if type(service.Service) == "table" and type(service.Service[methodName]) == "function" then
		return service.Service
	end
	return nil
end

local function resolveSystem(deps, name)
	local system = Services.Get(deps, name)
	if type(system) ~= "table" then
		return nil
	end
	return system
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

local function summarizeSpectatorCameraState(state)
	if type(state) ~= "table" then
		return "state=missing"
	end
	local position = typeof(state.position) == "Vector3" and tostring(state.position) or "nil"
	local rotation = typeof(state.rotation) == "Vector3" and tostring(state.rotation) or "nil"
	return string.format(
		"mode=%s target=%s position=%s rotation=%s limited=%s",
		tostring(state.mode),
		tostring(state.targetUserId),
		position,
		rotation,
		tostring(state.limitedAwareness == true)
	)
end

local function summarizeSpectatorVisionState(vision, communication)
	if type(vision) ~= "table" then
		return "vision=missing"
	end
	local signalType = type(vision.ghostSignal) == "table" and tostring(vision.ghostSignal.type) or "nil"
	local roomId = type(vision.ghostSignal) == "table" and tostring(vision.ghostSignal.roomId) or "nil"
	return string.format(
		"outcome=%s signal=%s room=%s target=%s voice=%s hint=%s",
		tostring(vision.outcome),
		signalType,
		roomId,
		tostring(vision.followTargetUserId),
		tostring(type(communication) == "table" and communication.canTransmitVoice == true),
		tostring(type(communication) == "table" and communication.distortionHint or nil)
	)
end

local function ensureRemote()
	local remoteFolder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = REMOTE_FOLDER_NAME
		remoteFolder.Parent = ReplicatedStorage
	end

	local remote = remoteFolder:FindFirstChild(REMOTE_NAME)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end

	if remote then
		remote:Destroy()
	end

	remote = Instance.new("RemoteEvent")
	remote.Name = REMOTE_NAME
	remote.Parent = remoteFolder
	return remote
end

local function resolveMatchEventRemote()
	local remoteFolder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
	if not remoteFolder then
		return nil
	end

	local remote = remoteFolder:FindFirstChild("MatchEvent")
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end

	return nil
end

local function encodeSummary(parts)
	local buffer = {}
	for _, part in ipairs(parts) do
		table.insert(buffer, tostring(part))
	end
	return table.concat(buffer, " | ")
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

local function cloneArray(source)
	if type(source) ~= "table" then
		return {}
	end
	local copy = {}
	for _, value in ipairs(source) do
		table.insert(copy, value)
	end
	return copy
end

local function normalizeToken(value)
	local token = tostring(value or "")
	token = token:gsub("[%s%p_%-]+", ""):lower()
	return token
end

local function coerceVector3(value)
	if typeof(value) == "Vector3" then
		return value
	end
	if type(value) == "table" then
		local x = tonumber(value.x or value.X)
		local y = tonumber(value.y or value.Y)
		local z = tonumber(value.z or value.Z)
		if x and y and z then
			return Vector3.new(x, y, z)
		end
	end
	return nil
end

local function resolveSharedGameDataModule(moduleName)
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:FindFirstChild("shared")
	if not shared then
		return nil
	end
	local gameData = shared:FindFirstChild("GameData")
	if not gameData then
		return nil
	end
	local moduleScript = gameData:FindFirstChild(moduleName)
	if moduleScript and moduleScript:IsA("ModuleScript") then
		return moduleScript
	end
	return nil
end

local function safeRequireModule(moduleScript)
	if not (moduleScript and moduleScript:IsA("ModuleScript")) then
		return nil
	end
	local ok, result = pcall(require, moduleScript)
	if ok and type(result) == "table" then
		return result
	end
	return nil
end

local function resolveGhostVisualConfig(ghostType)
	if type(ghostType) ~= "string" or ghostType == "" then
		return nil
	end
	local tuning = safeRequireModule(resolveSharedGameDataModule("GhostVisualTuning"))
	local ghosts = type(tuning) == "table" and tuning.ghosts or nil
	return type(ghosts) == "table" and ghosts[ghostType] or nil
end

local function resolveGhostTargetBounds(ghostType)
	local config = resolveGhostVisualConfig(ghostType)
	if type(config) ~= "table" then
		return nil
	end
	return coerceVector3(config.targetBounds) or coerceVector3(config.meshSize)
end

local function resolveGhostInventoryModelAssetId(ghostType)
	local config = resolveGhostVisualConfig(ghostType)
	if type(config) ~= "table" then
		return nil
	end
	local assetId = config.inventoryModelAssetId
	if type(assetId) == "string" and assetId ~= "" then
		return assetId
	end
	return nil
end

local function compactLogMessage(message)
	message = tostring(message or "")
	message = message:gsub("[%c\r\n\t]+", " ")
	message = message:gsub("%s+", " ")
	message = message:match("^%s*(.-)%s*$") or ""
	if #message > 96 then
		message = string.sub(message, 1, 93) .. "..."
	end
	return message
end

local function collectLogSummary()
	local warningCount = 0
	local errorCount = 0
	local samples = {}
	local ok, history = pcall(function()
		return LogService:GetLogHistory()
	end)
	if not ok or type(history) ~= "table" then
		return warningCount, errorCount, "unavailable"
	end
	for _, entry in ipairs(history) do
		local messageType = tostring(entry.messageType or entry.MessageType or "")
		local isError = string.find(messageType, "Error", 1, true) ~= nil
		local isWarning = string.find(messageType, "Warning", 1, true) ~= nil
		if isError then
			errorCount += 1
		elseif isWarning then
			warningCount += 1
		end
		if (isError or isWarning) and #samples < 3 then
			table.insert(samples, compactLogMessage(entry.message or entry.Message))
		end
	end
	return warningCount, errorCount, #samples > 0 and table.concat(samples, " || ") or "clean"
end

local function resolveLiveMatchPhase(matchSystem, matchId)
	if type(matchId) ~= "string" or matchId == "" or type(matchSystem) ~= "table" or type(matchSystem.GetLiveMatch) ~= "function" then
		return "none"
	end
	local ok, liveMatch = pcall(function()
		return matchSystem:GetLiveMatch(matchId)
	end)
	if not ok or type(liveMatch) ~= "table" then
		return "none"
	end
	if type(liveMatch.phase) == "string" and liveMatch.phase ~= "" then
		return liveMatch.phase
	end
	if type(liveMatch.GetState) == "function" then
		local stateOk, state = pcall(function()
			return liveMatch:GetState()
		end)
		if stateOk then
			if type(state) == "table" then
				return tostring(state.currentPhase or state.phase or "unknown")
			end
			if type(state) == "string" and state ~= "" then
				return state
			end
		end
	end
	return "none"
end

function StudioE2EControlSystem.new(deps)
	local self = setmetatable({}, StudioE2EControlSystem)
	self._deps = deps or {}
	self._remote = nil
	self._remoteConnection = nil
	self._matchSystem = nil
	self._huntEscapeSystem = nil
	self._sanitySystem = nil
	self._economyService = nil
	self._persistenceService = nil
	self._shopService = nil
	self._inventoryService = nil
	self._royalPassService = nil
	self._progressionService = nil
	self._profileService = nil
	self._cosmeticService = nil
	self._playerProfileService = nil
	self._rankedService = nil
	self._evidenceService = nil
	self._lobbyHubService = nil
	self._ghostSystem = nil
	self._mapEventSystem = nil
	self._mapInteractionSystem = nil
	self._eventBus = nil
	return self
end

function StudioE2EControlSystem:Init()
	self._matchSystem = resolveService(self._deps, "MatchSystem", "AdvanceMatchPhase")
	self._huntEscapeSystem = resolveService(self._deps, "HuntEscapeSystem", "HandlePlayerExtraction")
	self._sanitySystem = resolveService(self._deps, "SanitySystem", "DrainSanity")
	self._economyService = resolveService(self._deps, "EconomySystem", "GetBalance")
	self._persistenceService = resolveService(self._deps, "DataPersistenceService", "HasProcessedReceipt")
	self._shopService = resolveService(self._deps, "ShopSystem", "GetCatalog")
	self._inventoryService = resolveService(self._deps, "InventorySystem", "HasItem")
	self._royalPassService = resolveService(self._deps, "RoyalPassSystem", "GetPlayerSnapshot")
	self._progressionService = resolveService(self._deps, "ProgressionSystem", "GetPlayerLevel")
	self._profileService = resolveService(self._deps, "ProfileSystem", "GetPlayerProfile")
	self._cosmeticService = resolveService(self._deps, "CosmeticSystem", "BuildClientSnapshot")
	self._playerProfileService = resolveService(self._deps, "PlayerProfileSystem", "GetPublicProfile")
	self._rankedService = resolveService(self._deps, "RankedSystem", "GetPlayerRank")
	self._evidenceService = resolveService(self._deps, "EvidenceSystem", "ProcessToolUse")
	self._lobbyHubService = resolveService(self._deps, "LobbySocialHub", "OnPlayerEnteredZone")
	self._ghostSystem = resolveService(self._deps, "GhostSystem", "GetGhostState")
	self._mapEventSystem = resolveService(self._deps, "MapEventSystem", "TriggerEvent")
	self._mapInteractionSystem = resolveService(self._deps, "MapInteractionSystem", "ListObjects")
	self._eventBus = resolveEventBus(self._deps)
end

function StudioE2EControlSystem:_setTrace(parts, player)
	if not RunService:IsStudio() then
		return
	end
	local encoded = encodeSummary(parts)
	ReplicatedStorage:SetAttribute(TRACE_ATTR, encoded)
	if typeof(player) == "Instance" and player:IsA("Player") then
		player:SetAttribute(PLAYER_TRACE_ATTR, encoded)
	end
end

function StudioE2EControlSystem:_setResult(parts, player)
	if not RunService:IsStudio() then
		return
	end
	local encoded = encodeSummary(parts)
	ReplicatedStorage:SetAttribute(RESULT_ATTR, encoded)
	if typeof(player) == "Instance" and player:IsA("Player") then
		player:SetAttribute(PLAYER_RESULT_ATTR, encoded)
	end
end

function StudioE2EControlSystem:_setGhostSnapshot(snapshotJson, player)
	if not RunService:IsStudio() then
		return
	end
	local encoded = type(snapshotJson) == "string" and snapshotJson or ""
	ReplicatedStorage:SetAttribute(GHOST_SNAPSHOT_ATTR, encoded)
	if typeof(player) == "Instance" and player:IsA("Player") then
		player:SetAttribute(PLAYER_GHOST_SNAPSHOT_ATTR, encoded)
	end
end

function StudioE2EControlSystem:_resolveMatchId(player, request)
	if type(request) == "table" and type(request.matchId) == "string" and request.matchId ~= "" then
		return request.matchId
	end
	if typeof(player) == "Instance" and player:IsA("Player") then
		local attribute = player:GetAttribute("MatchId")
		if type(attribute) == "string" and attribute ~= "" then
			return attribute
		end
	end
	return nil
end

function StudioE2EControlSystem:_handleAdvancePhase(player, request)
	if not self._matchSystem then
		return false, "missing_match_system"
	end

	local matchId = self:_resolveMatchId(player, request)
	local nextPhase = type(request) == "table" and request.nextPhase or nil
	if not matchId or VALID_PHASES[nextPhase] ~= true then
		return false, "invalid_arguments"
	end

	local payload, reason = self._matchSystem:AdvanceMatchPhase(matchId, nextPhase)
	if not payload then
		return false, tostring(reason or "advance_failed")
	end
	return true, string.format("match=%s nextPhase=%s", matchId, nextPhase)
end

function StudioE2EControlSystem:_handleStartSoloMatch(player, request)
	if not self._matchSystem then
		return false, "missing_match_system"
	end
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local requestedMapId = type(request) == "table" and request.mapId or nil
	if type(requestedMapId) ~= "string" or requestedMapId == "" then
		requestedMapId = "HauntedHouse"
	end

	local payload = {
		players = { player },
		mapId = requestedMapId,
		mode = type(request) == "table" and (request.mode or request.gameMode) or nil,
		difficulty = type(request) == "table" and request.difficulty or nil,
	}
	local createdMatch, createReason = self._matchSystem:CreateMatch(payload)
	if not createdMatch or not createdMatch.matchId then
		return false, tostring(createReason or "create_match_failed")
	end
	local match, startReason = self._matchSystem:StartMatch(createdMatch.matchId)
	if not match then
		return false, tostring(startReason or "start_match_failed")
	end
	return true, string.format(
		"match=%s map=%s mode=%s difficulty=%s players=%d",
		tostring(match.matchId),
		tostring(match.mapId),
		tostring(match.mode or match.gameMode or "Classic"),
		tostring(match.difficulty or "Mudah"),
		#(match.players or {})
	)
end

function StudioE2EControlSystem:_handleSetPreparationFocusTool(player, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
	end

	local lifecyclePhase = tostring(player:GetAttribute("MatchLifecyclePhase") or "")
	if lifecyclePhase ~= "PreparationPhase" then
		return false, string.format("not_preparation_phase phase=%s", lifecyclePhase)
	end

	local focusTool = type(request) == "table" and (request.tool or request.focusTool) or nil
	if focusTool == nil or tostring(focusTool) == "" then
		player:SetAttribute("PreparationFocusTool", nil)
		return true, string.format("match=%s focus=nil", matchId)
	end

	local token = tostring(focusTool):gsub("[%s_%-%.]+", ""):upper()
	local allowedTools = {
		EMF = "EMF",
		UV = "UV CAM",
		UVCAM = "UV CAM",
		THERMO = "THERMO",
		BOX = "BOX",
		WRITING = "WRITING",
		SENSOR = "SENSOR",
	}
	local resolvedTool = allowedTools[token]
	if resolvedTool == nil then
		return false, "invalid_tool"
	end

	player:SetAttribute("PreparationFocusTool", resolvedTool)
	return true, string.format("match=%s focus=%s", matchId, resolvedTool)
end

function StudioE2EControlSystem:_handleSimulateLobbyZone(player, request)
	if type(self._lobbyHubService) ~= "table" or type(self._lobbyHubService.OnPlayerEnteredZone) ~= "function" then
		return false, "missing_lobby_hub_service"
	end
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end
	local zoneName = type(request) == "table" and tostring(request.zoneName or "") or ""
	if zoneName == "" then
		return false, "missing_zone_name"
	end
	self._lobbyHubService:OnPlayerEnteredZone(player, zoneName)
	return true, string.format("zone=%s simulated", zoneName)
end

function StudioE2EControlSystem:_handleLobbyTrainingSnapshot(player, request)
	local registry = rawget(_G, "SystemRegistry")
	local registryLobbyHub = type(registry) == "table"
		and ((type(registry.GetService) == "function" and registry:GetService("LobbySocialHub")) or (type(registry.Get) == "function" and registry:Get("LobbySocialHub")))
		or nil
	local lobbyHubSystem = registryLobbyHub or resolveSystem(self._deps, "LobbySocialHub") or self._lobbyHubService
	local lobbyHub = type(lobbyHubSystem) == "table"
		and (type(lobbyHubSystem.StudioGetEvidenceTrainingSnapshot) == "function" and lobbyHubSystem or lobbyHubSystem.Service)
		or nil
	if type(lobbyHub) ~= "table" or type(lobbyHub.StudioGetEvidenceTrainingSnapshot) ~= "function" then
		return false, "missing_lobby_training_service"
	end

	return true, HttpService:JSONEncode(lobbyHub:StudioGetEvidenceTrainingSnapshot())
end

function StudioE2EControlSystem:_handleLobbyTrainingUseTool(player, request)
	local registry = rawget(_G, "SystemRegistry")
	local registryLobbyHub = type(registry) == "table"
		and ((type(registry.GetService) == "function" and registry:GetService("LobbySocialHub")) or (type(registry.Get) == "function" and registry:Get("LobbySocialHub")))
		or nil
	local lobbyHubSystem = registryLobbyHub or resolveSystem(self._deps, "LobbySocialHub") or self._lobbyHubService
	local lobbyHub = type(lobbyHubSystem) == "table"
		and (type(lobbyHubSystem.StudioUseEvidenceTrainingTool) == "function" and lobbyHubSystem or lobbyHubSystem.Service)
		or nil
	if type(lobbyHub) ~= "table" or type(lobbyHub.StudioUseEvidenceTrainingTool) ~= "function" then
		return false, "missing_lobby_training_service"
	end

	local token = type(request) == "table" and (request.tool or request.toolType or request.partName) or ""
	local okUse, result = lobbyHub:StudioUseEvidenceTrainingTool(player, token)
	if okUse ~= true then
		return false, tostring(result or "lobby_training_tool_failed")
	end
	return true, HttpService:JSONEncode(result)
end

function StudioE2EControlSystem:_handleLobbyTrainingUseSupport(player, request)
	local registry = rawget(_G, "SystemRegistry")
	local registryLobbyHub = type(registry) == "table"
		and ((type(registry.GetService) == "function" and registry:GetService("LobbySocialHub")) or (type(registry.Get) == "function" and registry:Get("LobbySocialHub")))
		or nil
	local lobbyHubSystem = registryLobbyHub or resolveSystem(self._deps, "LobbySocialHub") or self._lobbyHubService
	local lobbyHub = type(lobbyHubSystem) == "table"
		and (type(lobbyHubSystem.StudioUseEvidenceTrainingSupportTool) == "function" and lobbyHubSystem or lobbyHubSystem.Service)
		or nil
	if type(lobbyHub) ~= "table" or type(lobbyHub.StudioUseEvidenceTrainingSupportTool) ~= "function" then
		return false, "missing_lobby_training_service"
	end

	local token = type(request) == "table" and (request.tool or request.toolType or request.supportTool) or ""
	local okUse, result = lobbyHub:StudioUseEvidenceTrainingSupportTool(player, token)
	if okUse ~= true then
		return false, tostring(result or "lobby_support_tool_failed")
	end
	return true, HttpService:JSONEncode(result)
end

function StudioE2EControlSystem:_handleLobbyTrainingRotate(player, request)
	local registry = rawget(_G, "SystemRegistry")
	local registryLobbyHub = type(registry) == "table"
		and ((type(registry.GetService) == "function" and registry:GetService("LobbySocialHub")) or (type(registry.Get) == "function" and registry:Get("LobbySocialHub")))
		or nil
	local lobbyHubSystem = registryLobbyHub or resolveSystem(self._deps, "LobbySocialHub") or self._lobbyHubService
	local lobbyHub = type(lobbyHubSystem) == "table"
		and (type(lobbyHubSystem.StudioRotateEvidenceTrainingGhost) == "function" and lobbyHubSystem or lobbyHubSystem.Service)
		or nil
	if type(lobbyHub) ~= "table" or type(lobbyHub.StudioRotateEvidenceTrainingGhost) ~= "function" then
		return false, "missing_lobby_training_service"
	end

	local excludedGhostType = type(request) == "table" and tostring(request.excludedGhostType or request.excludeGhostType or "") or ""
	return true, HttpService:JSONEncode(lobbyHub:StudioRotateEvidenceTrainingGhost(excludedGhostType))
end

function StudioE2EControlSystem:_handleForceHunt(player, request)
	if not self._eventBus then
		return false, "missing_event_bus"
	end

	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
	end
	local currentPhase = resolveLiveMatchPhase(self._matchSystem, matchId)
	if currentPhase ~= "InvestigationPhase" and currentPhase ~= "HuntPhase" then
		return false, string.format("match_not_hunt_ready phase=%s", tostring(currentPhase))
	end

	self._eventBus:Publish("ForceHunt", {
		matchId = matchId,
		source = "StudioE2EControlSystem",
		reason = type(request) == "table" and request.reason or "studio_e2e",
		now = os.clock(),
	})
	return true, string.format("match=%s forced", matchId)
end

function StudioE2EControlSystem:_handleForceManifest(player, request)
	if not self._eventBus then
		return false, "missing_event_bus"
	end

	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
	end
	local currentPhase = resolveLiveMatchPhase(self._matchSystem, matchId)
	if currentPhase ~= "InvestigationPhase" and currentPhase ~= "HuntPhase" then
		return false, string.format("match_not_manifest_ready phase=%s", tostring(currentPhase))
	end

	self._eventBus:Publish("ForceManifest", {
		matchId = matchId,
		source = "StudioE2EControlSystem",
		reason = type(request) == "table" and request.reason or "studio_e2e",
		now = os.clock(),
	})
	return true, string.format("match=%s manifest_forced", matchId)
end

function StudioE2EControlSystem:_handleTriggerMapEvent(player, request)
	local mapEventSystem = self._mapEventSystem
	if type(mapEventSystem) ~= "table" or type(mapEventSystem.TriggerEvent) ~= "function" then
		return false, "missing_map_event_system"
	end

	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
	end

	local eventType = type(request) == "table" and tostring(request.eventType or request.type or "") or ""
	if eventType == "" then
		eventType = "LightFlicker"
	end

	local payload = {
		matchId = matchId,
		eventType = eventType,
		targetObject = type(request) == "table" and (request.targetObject or request.objectId) or nil,
		roomId = type(request) == "table" and request.roomId or nil,
		intensity = tonumber(type(request) == "table" and request.intensity) or 0.85,
		source = "StudioE2EControlSystem",
		now = os.clock(),
	}

	local ok, result = mapEventSystem:TriggerEvent(payload)
	if ok ~= true then
		return false, tostring(result or "map_event_failed")
	end

	local targetObject = type(result) == "table" and result.targetObject or payload.targetObject
	return true, string.format(
		"match=%s mapEvent=%s target=%s",
		tostring(matchId),
		tostring(eventType),
		tostring(targetObject)
	)
end

function StudioE2EControlSystem:_handleGetMapInteractionSnapshot(player, request)
	local mapInteractionSystem = self._mapInteractionSystem
	if type(mapInteractionSystem) ~= "table" or type(mapInteractionSystem.ListObjects) ~= "function" then
		return false, "missing_map_interaction_system"
	end

	local objects = mapInteractionSystem:ListObjects()
	if type(objects) ~= "table" then
		return false, "missing_map_interaction_objects"
	end

	local countsByType = {}
	local selected = {}
	local targetObject = type(request) == "table" and tostring(request.targetObject or request.objectId or "") or ""
	for _, objectData in ipairs(objects) do
		if type(objectData) == "table" then
			local objectType = tostring(objectData.type or "Unknown")
			countsByType[objectType] = (countsByType[objectType] or 0) + 1
			if #selected < 12
				or (targetObject ~= "" and tostring(objectData.id or "") == targetObject) then
				table.insert(selected, {
					id = tostring(objectData.id or ""),
					type = objectType,
					roomId = tostring(objectData.roomId or ""),
					interactions = objectData.interactions,
				})
			end
		end
	end

	local snapshot = {
		objectCount = #objects,
		countsByType = countsByType,
		sample = selected,
		targetObject = targetObject ~= "" and targetObject or nil,
	}
	return true, HttpService:JSONEncode(snapshot)
end

function StudioE2EControlSystem:_handleTriggerMapInteraction(player, request)
	local mapInteractionSystem = self._mapInteractionSystem
	if type(mapInteractionSystem) ~= "table" or type(mapInteractionSystem.ExecuteInteraction) ~= "function" then
		return false, "missing_map_interaction_system"
	end

	local objectId = type(request) == "table" and tostring(request.objectId or request.targetObject or "") or ""
	local interactionType = type(request) == "table" and tostring(request.interactionType or request.interaction or "") or ""
	if objectId == "" or interactionType == "" then
		return false, "invalid_map_interaction_request"
	end

	local ok, reason = mapInteractionSystem:ExecuteInteraction(objectId, interactionType)
	if ok ~= true then
		return false, tostring(reason or "interaction_failed")
	end
	return true, string.format("object=%s interaction=%s", objectId, interactionType)
end

function StudioE2EControlSystem:_handleGetGhostRuntimeSnapshot(player, request)
	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
	end

	local match = self._matchSystem and self._matchSystem.GetLiveMatch and self._matchSystem:GetLiveMatch(matchId) or nil
	local ghostService = self._ghostSystem
	local ghostState = ghostService and ghostService.GetGhostState and ghostService:GetGhostState(matchId) or nil
	local ghostModel = type(match) == "table" and match.ghost or nil
	local meshPart = ghostModel and ghostModel:FindFirstChildWhichIsA("MeshPart", true) or nil

	local snapshot = {
		matchId = matchId,
		hasLiveMatch = type(match) == "table",
		matchPhase = type(match) == "table" and tostring(match.phase or "") or nil,
		matchGhostType = type(match) == "table" and tostring(match.ghostType or "") or nil,
		forcedGhostType = ReplicatedStorage:GetAttribute(FORCE_GHOST_TYPE_ATTR),
		hasGhostState = type(ghostState) == "table",
		ghostState = type(ghostState) == "table" and tostring(ghostState.state or "") or nil,
		ghostRoomId = type(ghostState) == "table" and ghostState.currentRoomId or nil,
		huntActive = type(ghostState) == "table" and ghostState.huntActive == true or false,
		hasGhostModel = typeof(ghostModel) == "Instance",
	}
	local targetBounds = resolveGhostTargetBounds(snapshot.matchGhostType)
	if typeof(targetBounds) == "Vector3" then
		snapshot.ghostTargetBounds = tostring(targetBounds)
	end
	local inventoryModelAssetId = resolveGhostInventoryModelAssetId(snapshot.matchGhostType)
	if type(inventoryModelAssetId) == "string" and inventoryModelAssetId ~= "" then
		snapshot.ghostInventoryModelAssetId = inventoryModelAssetId
	end

	if typeof(ghostModel) == "Instance" then
		snapshot.ghostPath = ghostModel:GetFullName()
		snapshot.ghostName = ghostModel.Name
		snapshot.placeholder = ghostModel:GetAttribute("PlaceholderVisual")
		snapshot.runtimeState = ghostModel:GetAttribute("RuntimeGhostState")
		snapshot.visualTemplateName = ghostModel:GetAttribute("VisualTemplateName")
		if ghostModel:IsA("Model") then
			local okExtents, extents = pcall(function()
				return ghostModel:GetExtentsSize()
			end)
			if okExtents and typeof(extents) == "Vector3" then
				snapshot.ghostExtents = tostring(extents)
			end
			local okScale, scale = pcall(function()
				return ghostModel:GetScale()
			end)
			if okScale and type(scale) == "number" then
				snapshot.ghostScale = scale
			end
			snapshot.ghostPosition = tostring(ghostModel:GetPivot().Position)
		end
	end

	if meshPart and meshPart:IsA("MeshPart") then
		snapshot.meshPartName = meshPart.Name
		snapshot.meshSize = tostring(meshPart.Size)
		snapshot.meshTransparency = meshPart.Transparency
		snapshot.meshColor = tostring(meshPart.Color)
		snapshot.meshMaterial = tostring(meshPart.Material)
		local textureOk, textureId = pcall(function()
			return meshPart.TextureID
		end)
		if textureOk then
			snapshot.meshTextureId = tostring(textureId or "")
		end
	end

	if typeof(ghostModel) == "Instance" then
		local surfaceAppearances = {}
		local decalTextureCount = 0
		for _, descendant in ipairs(ghostModel:GetDescendants()) do
			if descendant:IsA("SurfaceAppearance") then
				local record = {
					name = descendant.Name,
					parent = descendant.Parent and descendant.Parent.Name or "",
				}
				local colorMapOk, colorMap = pcall(function()
					return descendant.ColorMap
				end)
				if colorMapOk then
					record.colorMap = tostring(colorMap or "")
				end
				local normalMapOk, normalMap = pcall(function()
					return descendant.NormalMap
				end)
				if normalMapOk then
					record.normalMap = tostring(normalMap or "")
				end
				local roughnessMapOk, roughnessMap = pcall(function()
					return descendant.RoughnessMap
				end)
				if roughnessMapOk then
					record.roughnessMap = tostring(roughnessMap or "")
				end
				local metalnessMapOk, metalnessMap = pcall(function()
					return descendant.MetalnessMap
				end)
				if metalnessMapOk then
					record.metalnessMap = tostring(metalnessMap or "")
				end
				table.insert(surfaceAppearances, record)
			elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
				decalTextureCount += 1
			end
		end
		snapshot.surfaceAppearanceCount = #surfaceAppearances
		snapshot.surfaceAppearances = surfaceAppearances
		snapshot.decalTextureCount = decalTextureCount
	end

	local encoded = HttpService:JSONEncode(snapshot)
	self:_setGhostSnapshot(encoded, player)
	return true, string.format(
		"match=%s snapshot_ready hasGhost=%s placeholder=%s template=%s",
		tostring(matchId),
		tostring(snapshot.hasGhostModel == true),
		tostring(snapshot.placeholder),
		tostring(snapshot.visualTemplateName)
	)
end

function StudioE2EControlSystem:_handleExtractSelf(player, request)
	if not self._huntEscapeSystem then
		return false, "missing_hunt_escape_system"
	end
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
	end

	local zoneId = type(request) == "table" and request.zoneId or "StudioE2EZone"
	local previousOverride = ReplicatedStorage:GetAttribute(EXTRACTION_OVERRIDE_ATTR)
	local useStudioOverride = type(request) == "table" and request.allowStudioOverride == true
	if useStudioOverride then
		ReplicatedStorage:SetAttribute(EXTRACTION_OVERRIDE_ATTR, true)
	end

	local ok, reason = self._huntEscapeSystem:HandlePlayerExtraction(player, matchId, zoneId, "studio_e2e")

	if useStudioOverride then
		ReplicatedStorage:SetAttribute(EXTRACTION_OVERRIDE_ATTR, previousOverride)
	end

	if ok ~= true then
		return false, tostring(reason or "extract_failed")
	end
	return true, string.format("match=%s zone=%s", matchId, tostring(zoneId))
end

function StudioE2EControlSystem:_handleEndMatch(player, request)
	if not self._matchSystem then
		return false, "missing_match_system"
	end

	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
	end

	local results = {
		reason = type(request) == "table" and request.reason or "studio_e2e",
		success = type(request) == "table" and request.success ~= false or true,
		missionFailed = type(request) == "table" and request.missionFailed == true or false,
		correctGuess = type(request) == "table" and request.correctGuess ~= false or true,
		source = "StudioE2EControlSystem",
	}
	local payload = self._matchSystem:EndMatch(matchId, results)
	if payload then
		return true, string.format("match=%s ended", matchId)
	end

	-- Studio fallback:
	-- If MatchSystem no longer has the match entry but client still stuck InMatch,
	-- publish synthetic MatchEnded so reward/UI pipelines can unwind for E2E loops.
	if RunService:IsStudio() and self._eventBus then
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return false, "invalid_player"
		end
		if player:GetAttribute("InMatch") ~= true then
			return false, "end_match_failed"
		end
		local liveMatchId = player:GetAttribute("MatchId")
		if type(liveMatchId) == "string" and liveMatchId ~= "" and liveMatchId ~= matchId then
			return false, "match_id_mismatch"
		end

		local userId = typeof(player) == "Instance" and player:IsA("Player") and player.UserId or nil
		local performancePercent = tonumber(type(request) == "table" and request.performancePercent) or 75
		local survived = type(request) == "table" and request.survived ~= false or true
		local extracted = type(request) == "table" and request.extracted == true or false
		self._eventBus:Publish("MatchEnded", {
			matchId = matchId,
			players = { player },
			player = player,
			userId = userId,
			playerOutcome = {
				[tostring(userId)] = {
					player = player,
					userId = userId,
					performancePercent = performancePercent,
					survived = survived,
					extracted = extracted,
				},
			},
			results = {
				playerResults = {
					{
						player = player,
						userId = userId,
						performancePercent = performancePercent,
						survived = survived,
						extracted = extracted,
					},
				},
				playerOutcome = {
					[tostring(userId)] = {
						player = player,
						userId = userId,
						performancePercent = performancePercent,
						survived = survived,
						extracted = extracted,
					},
				},
			},
			source = "StudioE2EControlFallback",
			reason = results.reason,
			success = results.success,
			missionFailed = results.missionFailed,
			correctGuess = results.correctGuess,
		})
		if typeof(player) == "Instance" and player:IsA("Player") then
			player:SetAttribute("InMatch", false)
			player:SetAttribute("MatchId", "")
		end
		return true, string.format("match=%s ended_fallback", matchId)
	end

	return false, "end_match_failed"
end

function StudioE2EControlSystem:_handleDrainSanity(player, request)
	if not self._sanitySystem then
		return false, "missing_sanity_system"
	end
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
	end

	local amount = tonumber(type(request) == "table" and request.amount) or 0
	if amount <= 0 then
		return false, "invalid_amount"
	end

	local newSanity, reason = self._sanitySystem:DrainSanity(player, amount, matchId, "studio_e2e")
	if newSanity == nil then
		return false, tostring(reason or "drain_failed")
	end
	return true, string.format("match=%s sanity=%s", matchId, tostring(newSanity))
end

function StudioE2EControlSystem:_handleGetWallet(player)
	if not self._economyService then
		return false, "missing_economy_service"
	end
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local wallet = self._economyService:GetBalance(player)
	if type(wallet) ~= "table" then
		return false, "wallet_unavailable"
	end

	return true, string.format(
		"MM=%d PP=%d Robux=%d",
		math.max(0, math.floor(tonumber(wallet.MM) or 0)),
		math.max(0, math.floor(tonumber(wallet.PP) or 0)),
		math.max(0, math.floor(tonumber(wallet.Robux) or 0))
	)
end

function StudioE2EControlSystem:_handleGrantCurrency(player, request)
	if type(self._economyService) ~= "table" or type(self._economyService.AddCurrency) ~= "function" then
		return false, "missing_economy_service"
	end
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local currency = tostring(type(request) == "table" and request.currency or "MM")
	local amount = math.max(0, math.floor(tonumber(type(request) == "table" and request.amount) or 0))
	if amount <= 0 then
		return false, "invalid_amount"
	end

	local ok, reason, granted = self._economyService:AddCurrency(player, currency, amount, "studio_e2e_grant")
	if ok ~= true then
		return false, tostring(reason or "grant_failed")
	end

	local wallet = self._economyService:GetBalance(player) or {}
	return true, string.format(
		"currency=%s granted=%d MM=%d PP=%d Robux=%d",
		currency,
		math.max(0, math.floor(tonumber(granted) or 0)),
		math.max(0, math.floor(tonumber(wallet.MM) or 0)),
		math.max(0, math.floor(tonumber(wallet.PP) or 0)),
		math.max(0, math.floor(tonumber(wallet.Robux) or 0))
	)
end

function StudioE2EControlSystem:_handleGrantMarketplacePurchase(player, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local shopService = self._shopService
	if type(shopService) ~= "table"
		or type(shopService.GrantMarketplacePurchase) ~= "function"
		or type(shopService.GetCatalog) ~= "function"
	then
		return false, "missing_shop_service"
	end

	local itemId = type(request) == "table" and tostring(request.itemId or "") or ""
	if itemId == "" then
		return false, "missing_item_id"
	end

	local catalog = shopService:GetCatalog()
	local item = type(catalog) == "table" and catalog[itemId] or nil
	if type(item) ~= "table" then
		return false, "item_not_found"
	end

	local ok, reason = shopService:GrantMarketplacePurchase(player, itemId, {
		source = type(request) == "table" and tostring(request.source or "StudioE2EMarketplacePurchase")
			or "StudioE2EMarketplacePurchase",
	})
	if ok ~= true then
		return false, tostring(reason or "grant_failed")
	end

	local snapshot
	if type(shopService._buildClientSnapshot) == "function" then
		local snapshotOk, snapshotResult = pcall(function()
			return shopService:_buildClientSnapshot(player)
		end)
		if snapshotOk and type(snapshotResult) == "table" then
			snapshot = snapshotResult
		end
	elseif type(shopService.BuildClientSnapshot) == "function" then
		local snapshotOk, snapshotResult = pcall(function()
			return shopService:BuildClientSnapshot(player)
		end)
		if snapshotOk and type(snapshotResult) == "table" then
			snapshot = snapshotResult
		end
	end

	local owned = false
	local ownedCount = 0
	if type(snapshot) == "table" then
		local ownedItemIds = type(snapshot.ownedItemIds) == "table" and snapshot.ownedItemIds or {}
		ownedCount = #ownedItemIds
		for _, ownedItemId in ipairs(ownedItemIds) do
			if ownedItemId == itemId then
				owned = true
				break
			end
		end
	end

	local wallet = type(self._economyService) == "table" and self._economyService:GetBalance(player) or {}

	return true, string.format(
		"item=%s category=%s currency=%s owned=%s ownedCount=%d MM=%d PP=%d Robux=%d",
		itemId,
		tostring(item.category or ""),
		tostring(item.currency or ""),
		tostring(owned),
		ownedCount,
		math.max(0, math.floor(tonumber(wallet.MM) or 0)),
		math.max(0, math.floor(tonumber(wallet.PP) or 0)),
		math.max(0, math.floor(tonumber(wallet.Robux) or 0))
	)
end

function StudioE2EControlSystem:_handleGrantMarketplaceEntitlement(player, request)
	local shopService = self._shopService
	if type(shopService) ~= "table" or type(shopService.GetCatalog) ~= "function" then
		return false, "missing_shop_service"
	end

	local itemId = type(request) == "table" and tostring(request.itemId or "") or ""
	local catalog = shopService:GetCatalog()
	local item = type(catalog) == "table" and catalog[itemId] or nil
	if type(item) ~= "table" then
		return false, "item_not_found"
	end
	if tostring(item.category or "") ~= "Entitlement" then
		return false, "not_entitlement_item"
	end

	request = type(request) == "table" and request or {}
	request.source = "StudioE2EEntitlement"
	return self:_handleGrantMarketplacePurchase(player, request)
end

function StudioE2EControlSystem:_handleGetPersistenceMode()
	local persistence = self._persistenceService
	if type(persistence) ~= "table" then
		return false, "missing_persistence_service"
	end

	local diagnostics = type(persistence.GetDiagnostics) == "function" and persistence:GetDiagnostics() or nil
	local useMockStore = diagnostics and diagnostics.mode == "mock" or persistence._useMockStore == true
	local hasDataStore = diagnostics and diagnostics.hasDataStore or persistence._dataStore ~= nil
	local allowStudioDataStore = diagnostics and diagnostics.allowStudioDataStore or persistence._allowStudioDataStore == true
	local trackedPlayers = diagnostics and diagnostics.trackedPlayers or 0
	local schemaVersion = diagnostics and diagnostics.profileSchemaVersion or "unknown"
	local lastLoadSchema = diagnostics and diagnostics.lastProfileLoad and diagnostics.lastProfileLoad.schemaVersion or "none"
	local lastSaveSchema = diagnostics and diagnostics.lastProfileSave and diagnostics.lastProfileSave.schemaVersion or "none"

	return true, string.format(
		"mode=%s hasDataStore=%s allowStudioDataStore=%s trackedPlayers=%d schemaVersion=%s lastLoadSchema=%s lastSaveSchema=%s",
		useMockStore and "mock" or "datastore",
		tostring(hasDataStore),
		tostring(allowStudioDataStore),
		trackedPlayers,
		tostring(schemaVersion),
		tostring(lastLoadSchema),
		tostring(lastSaveSchema)
	)
end

local function buildQAGateMetrics(self, player, request)
	local playerCount = #Players:GetPlayers()
	local activeMatchCount = 0
	local activeMatchesFolder = workspace:FindFirstChild("ActiveMatches")
	if activeMatchesFolder and activeMatchesFolder:IsA("Folder") then
		activeMatchCount = #activeMatchesFolder:GetChildren()
	end

	local currentMatchId = self:_resolveMatchId(player, request)
	local currentPhase = resolveLiveMatchPhase(self._matchSystem, currentMatchId)

	local scriptMemoryMb = (collectgarbage("count") or 0) / 1024
	local totalMemoryMb = 0
	local memoryOk, memoryValue = pcall(function()
		return Stats:GetTotalMemoryUsageMb()
	end)
	if memoryOk then
		totalMemoryMb = tonumber(memoryValue) or 0
	end

	local physicsFps = 0
	local fpsOk, fpsValue = pcall(function()
		return workspace:GetRealPhysicsFPS()
	end)
	if fpsOk then
		physicsFps = tonumber(fpsValue) or 0
	end

	local pingMs = "n/a"
	if typeof(player) == "Instance" and player:IsA("Player") and type(player.GetNetworkPing) == "function" then
		local pingOk, pingValue = pcall(function()
			return player:GetNetworkPing()
		end)
		if pingOk and tonumber(pingValue) then
			pingMs = tostring(math.floor((tonumber(pingValue) * 1000) + 0.5))
		end
	end

	local warningCount, errorCount, logSample = collectLogSummary()
	return {
		playerCount = playerCount,
		activeMatchCount = activeMatchCount,
		currentMatchId = currentMatchId,
		currentPhase = currentPhase,
		scriptMemoryMb = scriptMemoryMb,
		totalMemoryMb = totalMemoryMb,
		physicsFps = physicsFps,
		pingMs = pingMs,
		warningCount = warningCount,
		errorCount = errorCount,
		logSample = logSample,
	}
end

function StudioE2EControlSystem:_handleGetQAGateSnapshot(player, request)
	local metrics = buildQAGateMetrics(self, player, request)
	return true, string.format(
		"players=%d activeMatches=%d currentMatch=%s phase=%s scriptMemoryMb=%.2f totalMemoryMb=%.2f physicsFps=%.2f pingMs=%s warnings=%d errors=%d logSample=%s",
		metrics.playerCount,
		metrics.activeMatchCount,
		tostring(metrics.currentMatchId or "none"),
		metrics.currentPhase,
		metrics.scriptMemoryMb,
		metrics.totalMemoryMb,
		metrics.physicsFps,
		metrics.pingMs,
		metrics.warningCount,
		metrics.errorCount,
		metrics.logSample
	)
end

function StudioE2EControlSystem:_handleGetQAGateReadiness(player, request)
	local metrics = buildQAGateMetrics(self, player, request)
	local memoryOk = metrics.totalMemoryMb > 0 and metrics.totalMemoryMb <= QA_GATE_MAX_TOTAL_MEMORY_MB
	local fpsOk = metrics.physicsFps >= QA_GATE_MIN_PHYSICS_FPS
	local logOk = metrics.warningCount == 0 and metrics.errorCount == 0
	local soloOk = metrics.playerCount >= 1 and fpsOk and logOk and memoryOk
	local multiplayerGate = "manual_check_required"
	local overall = (soloOk and "pass_with_manual_multiplayer") or "fail"

	return true, string.format(
		"overall=%s solo=%s multiplayer=%s memoryOk=%s fpsOk=%s logOk=%s totalMemoryMb=%.2f physicsFps=%.2f warnings=%d errors=%d phase=%s currentMatch=%s",
		overall,
		tostring(soloOk),
		multiplayerGate,
		tostring(memoryOk),
		tostring(fpsOk),
		tostring(logOk),
		metrics.totalMemoryMb,
		metrics.physicsFps,
		metrics.warningCount,
		metrics.errorCount,
		metrics.currentPhase,
		tostring(metrics.currentMatchId or "none")
	)
end

function StudioE2EControlSystem:_handleGetShopReadiness()
	local shopService = self._shopService
	if type(shopService) ~= "table" or type(shopService.GetCatalog) ~= "function" then
		return false, "missing_shop_service"
	end

	local catalog = shopService:GetCatalog()
	if type(catalog) ~= "table" then
		return false, "catalog_unavailable"
	end

	local total = 0
	local mm = 0
	local pp = 0
	local robux = 0
	local disabled = 0
	local robuxMissingId = 0

	for _, item in pairs(catalog) do
		if type(item) == "table" then
			total += 1
			local currency = tostring(item.currency or "MM")
			if currency == "MM" then
				mm += 1
			elseif currency == "PP" then
				pp += 1
			elseif currency == "Robux" or currency == "RBX" then
				robux += 1
				if tonumber(item.marketplaceId) == nil or tonumber(item.marketplaceId) <= 0 then
					robuxMissingId += 1
				end
			end

			if item.enabled == false then
				disabled += 1
			end
		end
	end

	return true, string.format(
		"total=%d MM=%d PP=%d Robux=%d disabled=%d robuxMissingId=%d",
		total,
		mm,
		pp,
		robux,
		disabled,
		robuxMissingId
	)
end

function StudioE2EControlSystem:_handleGetPublishReadiness(player, request)
	local metrics = buildQAGateMetrics(self, player, request)
	local qaMemoryOk = metrics.totalMemoryMb > 0 and metrics.totalMemoryMb <= QA_GATE_MAX_TOTAL_MEMORY_MB
	local qaFpsOk = metrics.physicsFps >= QA_GATE_MIN_PHYSICS_FPS
	local qaLogOk = metrics.warningCount == 0 and metrics.errorCount == 0
	local qaSoloOk = metrics.playerCount >= 1 and qaMemoryOk and qaFpsOk and qaLogOk

	local persistenceMode = "unknown"
	local persistenceReady = false
	if type(self._persistenceService) == "table" then
		local diagnostics = type(self._persistenceService.GetDiagnostics) == "function" and self._persistenceService:GetDiagnostics() or nil
		local useMockStore = diagnostics and diagnostics.mode == "mock" or self._persistenceService._useMockStore == true
		persistenceMode = useMockStore and "mock" or "datastore"
		persistenceReady = useMockStore ~= true
	end

	local robuxMissingId = 0
	local robuxVisible = 0
	if type(self._shopService) == "table" and type(self._shopService.GetCatalog) == "function" then
		local catalog = self._shopService:GetCatalog()
		if type(catalog) == "table" then
			for _, item in pairs(catalog) do
				if type(item) == "table" then
					local currency = tostring(item.currency or "MM")
					if currency == "Robux" or currency == "RBX" then
						if item.enabled ~= false then
							robuxVisible += 1
						end
						if tonumber(item.marketplaceId) == nil or tonumber(item.marketplaceId) <= 0 then
							robuxMissingId += 1
						end
					end
				end
			end
		end
	end

	local commerceReady = robuxVisible == 0 or robuxMissingId == 0
	local multiplayerGate = "manual_check_required"
	local overall = (qaSoloOk and persistenceReady and commerceReady)
		and "pass_with_manual_multiplayer"
		or "fail"

	return true, string.format(
		"overall=%s qaSolo=%s multiplayer=%s persistence=%s persistenceReady=%s commerceReady=%s robuxVisible=%d robuxMissingId=%d totalMemoryMb=%.2f physicsFps=%.2f warnings=%d errors=%d phase=%s currentMatch=%s",
		overall,
		tostring(qaSoloOk),
		multiplayerGate,
		persistenceMode,
		tostring(persistenceReady),
		tostring(commerceReady),
		robuxVisible,
		robuxMissingId,
		metrics.totalMemoryMb,
		metrics.physicsFps,
		metrics.warningCount,
		metrics.errorCount,
		metrics.currentPhase,
		tostring(metrics.currentMatchId or "none")
	)
end

function StudioE2EControlSystem:_handleGetShopPlayerSnapshot(player, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end
	if type(self._economyService) ~= "table" or type(self._economyService.GetBalance) ~= "function" then
		return false, "missing_economy_service"
	end
	if type(self._inventoryService) ~= "table" then
		return false, "missing_inventory_service"
	end

	local wallet = self._economyService:GetBalance(player)
	if type(wallet) ~= "table" then
		return false, "wallet_unavailable"
	end

	local inventoryCount = 0
	if type(self._inventoryService.GetInventory) == "function" then
		local ok, inventory = pcall(function()
			return self._inventoryService:GetInventory(player)
		end)
		if ok then
			inventoryCount = countEntries(inventory)
		end
	end

	local cosmeticCount = 0
	if type(self._inventoryService.GetOwnedCosmetics) == "function" then
		local ok, cosmetics = pcall(function()
			return self._inventoryService:GetOwnedCosmetics(player)
		end)
		if ok and type(cosmetics) == "table" then
			cosmeticCount = #cosmetics
		end
	end

	local itemId = type(request) == "table" and tostring(request.itemId or "") or ""
	local hasItem = false
	local ownsCosmetic = false
	local ownedSnapshot = false
	local ownedCount = 0
	if itemId ~= "" then
		if type(self._inventoryService.HasItem) == "function" then
			local ok, result = pcall(function()
				return self._inventoryService:HasItem(player, itemId)
			end)
			if ok then
				hasItem = result == true
			end
		end
		if type(self._inventoryService.OwnsCosmetic) == "function" then
			local ok, result = pcall(function()
				return self._inventoryService:OwnsCosmetic(player, itemId)
			end)
			if ok then
				ownsCosmetic = result == true
			end
		end
	end

	if type(self._shopService) == "table" and type(self._shopService.BuildClientSnapshot) == "function" then
		local ok, snapshot = pcall(function()
			return self._shopService:BuildClientSnapshot(player)
		end)
		if ok and type(snapshot) == "table" then
			local ownedItemIds = type(snapshot.ownedItemIds) == "table" and snapshot.ownedItemIds or {}
			ownedCount = #ownedItemIds
			if itemId ~= "" then
				for _, ownedItemId in ipairs(ownedItemIds) do
					if ownedItemId == itemId then
						ownedSnapshot = true
						break
					end
				end
			end
		end
	end

	return true, string.format(
		"MM=%d PP=%d Robux=%d inventory=%d cosmetics=%d ownedCount=%d item=%s hasItem=%s ownsCosmetic=%s ownedSnapshot=%s",
		math.max(0, math.floor(tonumber(wallet.MM) or 0)),
		math.max(0, math.floor(tonumber(wallet.PP) or 0)),
		math.max(0, math.floor(tonumber(wallet.Robux) or 0)),
		inventoryCount,
		cosmeticCount,
		ownedCount,
		itemId ~= "" and itemId or "-",
		tostring(hasItem),
		tostring(ownsCosmetic),
		tostring(ownedSnapshot)
	)
end

function StudioE2EControlSystem:_handleProcessShopPurchase(player, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local shopService = self._shopService
	if type(shopService) ~= "table"
		or type(shopService.ProcessPurchase) ~= "function"
		or type(shopService.BuildClientSnapshot) ~= "function"
	then
		return false, "missing_shop_service"
	end
	if type(self._economyService) ~= "table" or type(self._economyService.GetBalance) ~= "function" then
		return false, "missing_economy_service"
	end

	local itemId = type(request) == "table" and tostring(request.itemId or "") or ""
	if itemId == "" then
		return false, "missing_item_id"
	end

	local ok, reason = shopService:ProcessPurchase(player, itemId)
	if ok ~= true then
		return false, tostring(reason or "purchase_failed")
	end

	local snapshot = {}
	if type(shopService._buildClientSnapshot) == "function" then
		local snapshotOk, snapshotResult = pcall(function()
			return shopService:_buildClientSnapshot(player)
		end)
		if snapshotOk and type(snapshotResult) == "table" then
			snapshot = snapshotResult
		end
	elseif type(shopService.BuildClientSnapshot) == "function" then
		local snapshotOk, snapshotResult = pcall(function()
			return shopService:BuildClientSnapshot(player)
		end)
		if snapshotOk and type(snapshotResult) == "table" then
			snapshot = snapshotResult
		end
	end
	local wallet = self._economyService:GetBalance(player) or {}
	local ownedCount = type(snapshot.ownedItemIds) == "table" and #snapshot.ownedItemIds or 0

	return true, string.format(
		"item=%s MM=%d PP=%d Robux=%d ownedCount=%d",
		itemId,
		math.max(0, math.floor(tonumber(wallet.MM) or 0)),
		math.max(0, math.floor(tonumber(wallet.PP) or 0)),
		math.max(0, math.floor(tonumber(wallet.Robux) or 0)),
		ownedCount
	)
end

function StudioE2EControlSystem:_handleGetRoyalPassSnapshot(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local royalPassService = self._royalPassService
	if type(royalPassService) ~= "table" or type(royalPassService.GetPlayerSnapshot) ~= "function" then
		return false, "missing_royalpass_service"
	end

	local snapshot = royalPassService:GetPlayerSnapshot(player)
	if type(snapshot) ~= "table" then
		return false, "snapshot_unavailable"
	end

	return true, string.format(
		"season=%s premium=%s tier=%d totalXP=%d tierXP=%d remainingXP=%d unlocked=%d nextTier=%s",
		tostring(snapshot.seasonId),
		tostring(snapshot.premiumOwned == true),
		math.max(1, math.floor(tonumber(snapshot.currentTier) or 1)),
		math.max(0, math.floor(tonumber(snapshot.totalXP) or 0)),
		math.max(0, math.floor(tonumber(snapshot.currentTierXP) or 0)),
		math.max(0, math.floor(tonumber(snapshot.remainingXP) or 0)),
		math.max(0, math.floor(tonumber(snapshot.unlockedTierCount) or 0)),
		tostring(snapshot.nextTier)
	)
end

function StudioE2EControlSystem:_handleGrantRoyalPassXP(player, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local royalPassService = self._royalPassService
	if type(royalPassService) ~= "table" or type(royalPassService.AddXP) ~= "function" then
		return false, "missing_royalpass_service"
	end

	local amount = math.max(0, math.floor(tonumber(type(request) == "table" and request.amount) or 0))
	if amount <= 0 then
		return false, "invalid_amount"
	end

	local ok, reason = royalPassService:AddXP(player, amount, type(request) == "table" and request.source or "studio_e2e")
	if ok ~= true then
		return false, tostring(reason or "grant_failed")
	end

	local snapshot
	if type(royalPassService._buildPlayerSnapshot) == "function" then
		local snapshotOk, snapshotResult = pcall(function()
			return royalPassService:_buildPlayerSnapshot(player)
		end)
		if snapshotOk and type(snapshotResult) == "table" then
			snapshot = snapshotResult
		end
	elseif type(royalPassService.GetPlayerSnapshot) == "function" then
		local snapshotOk, snapshotResult = pcall(function()
			return royalPassService:GetPlayerSnapshot(player)
		end)
		if snapshotOk and type(snapshotResult) == "table" then
			snapshot = snapshotResult
		end
	end

	if type(snapshot) ~= "table" then
		return false, "snapshot_unavailable"
	end

	return true, string.format(
		"amount=%d premium=%s tier=%d totalXP=%d tierXP=%d unlocked=%d nextTier=%s",
		amount,
		tostring(snapshot.premiumOwned == true),
		math.max(1, math.floor(tonumber(snapshot.currentTier) or 1)),
		math.max(0, math.floor(tonumber(snapshot.totalXP) or 0)),
		math.max(0, math.floor(tonumber(snapshot.currentTierXP) or 0)),
		math.max(0, math.floor(tonumber(snapshot.unlockedTierCount) or 0)),
		tostring(snapshot.nextTier)
	)
end

function StudioE2EControlSystem:_handleGetProgressionSnapshot(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local progressionService = self._progressionService
	if type(progressionService) ~= "table" then
		return false, "missing_progression_service"
	end

	local snapshot = nil
	if type(progressionService.GetPlayerSnapshot) == "function" then
		snapshot = progressionService:GetPlayerSnapshot(player)
	elseif type(progressionService._buildRuntimeSnapshot) == "function" then
		snapshot = progressionService:_buildRuntimeSnapshot(player)
	end
	if type(snapshot) ~= "table" then
		return false, "snapshot_unavailable"
	end

	return true, string.format(
		"storedXP=%d storedLevel=%d sessionXP=%d sessionLevel=%d",
		math.max(0, math.floor(tonumber(snapshot.storedXP) or 0)),
		math.max(1, math.floor(tonumber(snapshot.storedLevel) or 1)),
		math.max(0, math.floor(tonumber(snapshot.sessionXP) or 0)),
		math.max(1, math.floor(tonumber(snapshot.sessionLevel) or 1))
	)
end

function StudioE2EControlSystem:_handleGrantProgressionXP(player, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local progressionService = self._progressionService
	if type(progressionService) ~= "table" or type(progressionService.GrantXP) ~= "function" then
		return false, "missing_progression_service"
	end

	local amount = math.max(0, math.floor(tonumber(type(request) == "table" and request.amount) or 0))
	if amount <= 0 then
		return false, "invalid_amount"
	end

	local ok, reason = progressionService:GrantXP(player, amount)
	if ok ~= true then
		return false, tostring(reason or "grant_failed")
	end

	local snapshot = nil
	if type(progressionService._buildRuntimeSnapshot) == "function" then
		snapshot = progressionService:_buildRuntimeSnapshot(player)
	elseif type(progressionService.GetPlayerSnapshot) == "function" then
		snapshot = progressionService:GetPlayerSnapshot(player)
	end
	if type(snapshot) ~= "table" then
		return false, "snapshot_unavailable"
	end

	return true, string.format(
		"amount=%d storedXP=%d storedLevel=%d sessionXP=%d sessionLevel=%d",
		amount,
		math.max(0, math.floor(tonumber(snapshot.storedXP) or 0)),
		math.max(1, math.floor(tonumber(snapshot.storedLevel) or 1)),
		math.max(0, math.floor(tonumber(snapshot.sessionXP) or 0)),
		math.max(1, math.floor(tonumber(snapshot.sessionLevel) or 1))
	)
end

function StudioE2EControlSystem:_handleGetProfileSnapshot(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local profileService = self._profileService
	if type(profileService) ~= "table" or type(profileService.GetPlayerProfile) ~= "function" then
		return false, "missing_profile_service"
	end

	local snapshot = profileService:GetPlayerProfile(player)
	if type(snapshot) ~= "table" then
		return false, "snapshot_unavailable"
	end

	local favoriteTool = type(snapshot.statistics) == "table" and snapshot.statistics.favoriteTool or nil
	local bio = type(snapshot.profile) == "table" and snapshot.profile.bio or nil
	local galleryItems = type(snapshot.profile) == "table" and snapshot.profile.galleryItems or nil
	return true, string.format(
		"level=%d rank=%s totalMatches=%d totalWins=%d winRate=%d favoriteTool=%s gallery=%d bio=%s",
		math.max(1, math.floor(tonumber(snapshot.playerLevel) or 1)),
		tostring(type(snapshot.rank) == "table" and snapshot.rank.playerRank or "Bayi III"),
		math.max(0, math.floor(tonumber(snapshot.totalMatches) or 0)),
		math.max(0, math.floor(tonumber(snapshot.totalWins) or 0)),
		math.max(0, math.floor(tonumber(snapshot.winRate) or 0)),
		tostring(favoriteTool or "-"),
		type(galleryItems) == "table" and #galleryItems or 0,
		tostring(bio or "")
	)
end

function StudioE2EControlSystem:_handleUpdateProfileSnapshot(player, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local profileService = self._profileService
	if type(profileService) ~= "table" or type(profileService.UpdateProfile) ~= "function" then
		return false, "missing_profile_service"
	end

	local payload = {
		profile = {
			bio = type(request) == "table" and tostring(request.bio or "studio profile sync") or "studio profile sync",
			flexBorder = type(request) == "table" and request.flexBorder or "border_emerald",
			winrateVisible = type(request) == "table" and request.winrateVisible ~= false or true,
			galleryItems = type(request) == "table" and type(request.galleryItems) == "table" and cloneArray(request.galleryItems)
				or { "gallery_evidence", "gallery_contract", "gallery_survival" },
		},
		statistics = {
			favoriteTool = type(request) == "table" and request.favoriteTool or "JejakEnergi",
		},
	}

	local ok, reason, snapshot = profileService:UpdateProfile(player, payload)
	if ok ~= true then
		return false, tostring(reason or "update_failed")
	end
	if type(snapshot) ~= "table" then
		return false, "snapshot_unavailable"
	end

	local favoriteTool = type(snapshot.statistics) == "table" and snapshot.statistics.favoriteTool or nil
	local galleryItems = type(snapshot.profile) == "table" and snapshot.profile.galleryItems or nil
	return true, string.format(
		"level=%d rank=%s favoriteTool=%s gallery=%d bio=%s",
		math.max(1, math.floor(tonumber(snapshot.playerLevel) or 1)),
		tostring(type(snapshot.rank) == "table" and snapshot.rank.playerRank or "Bayi III"),
		tostring(favoriteTool or "-"),
		type(galleryItems) == "table" and #galleryItems or 0,
		tostring(type(snapshot.profile) == "table" and snapshot.profile.bio or "")
	)
end

function StudioE2EControlSystem:_handleGetCosmeticSnapshot(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local cosmeticService = self._cosmeticService
	if type(cosmeticService) ~= "table" or type(cosmeticService.BuildClientSnapshot) ~= "function" then
		return false, "missing_cosmetic_service"
	end

	local snapshot = cosmeticService:BuildClientSnapshot(player)
	if type(snapshot) ~= "table" then
		return false, "snapshot_unavailable"
	end

	return true, string.format(
		"owned=%d equipped=%d",
		math.max(0, math.floor(tonumber(snapshot.ownedCount) or 0)),
		math.max(0, math.floor(tonumber(snapshot.equippedCount) or 0))
	)
end

function StudioE2EControlSystem:_handleEquipCosmeticSnapshot(player, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local cosmeticService = self._cosmeticService
	if type(cosmeticService) ~= "table" or type(cosmeticService.EquipCosmetic) ~= "function" then
		return false, "missing_cosmetic_service"
	end

	local cosmeticId = type(request) == "table" and tostring(request.cosmeticId or request.itemId or "") or ""
	if cosmeticId == "" then
		return false, "invalid_cosmetic"
	end

	local ok, reason, slot = cosmeticService:EquipCosmetic(player, cosmeticId)
	if ok ~= true then
		return false, tostring(reason or "equip_failed")
	end

	local snapshot = type(cosmeticService.BuildClientSnapshot) == "function" and cosmeticService:BuildClientSnapshot(player) or nil
	return true, string.format(
		"cosmetic=%s slot=%s owned=%d equipped=%d",
		cosmeticId,
		tostring(slot or "-"),
		type(snapshot) == "table" and math.max(0, math.floor(tonumber(snapshot.ownedCount) or 0)) or 0,
		type(snapshot) == "table" and math.max(0, math.floor(tonumber(snapshot.equippedCount) or 0)) or 0
	)
end

function StudioE2EControlSystem:_handleUnequipCosmeticSnapshot(player, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local cosmeticService = self._cosmeticService
	if type(cosmeticService) ~= "table" or type(cosmeticService.UnequipCosmetic) ~= "function" then
		return false, "missing_cosmetic_service"
	end

	local slot = type(request) == "table" and tostring(request.slot or request.cosmeticSlot or "") or ""
	if slot == "" then
		return false, "invalid_slot"
	end

	local ok, reason = cosmeticService:UnequipCosmetic(player, slot)
	if ok ~= true then
		return false, tostring(reason or "unequip_failed")
	end

	local snapshot = type(cosmeticService.BuildClientSnapshot) == "function" and cosmeticService:BuildClientSnapshot(player) or nil
	return true, string.format(
		"slot=%s owned=%d equipped=%d",
		slot,
		type(snapshot) == "table" and math.max(0, math.floor(tonumber(snapshot.ownedCount) or 0)) or 0,
		type(snapshot) == "table" and math.max(0, math.floor(tonumber(snapshot.equippedCount) or 0)) or 0
	)
end

function StudioE2EControlSystem:_handleGetPublicProfileSnapshot(player, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local playerProfileService = self._playerProfileService
	if type(playerProfileService) ~= "table" or type(playerProfileService.GetPublicProfile) ~= "function" then
		return false, "missing_player_profile_service"
	end

	local target = player
	if type(request) == "table" and tonumber(request.targetUserId) then
		target = math.floor(tonumber(request.targetUserId))
	end

	local snapshot = playerProfileService:GetPublicProfile(target, player)
	if type(snapshot) ~= "table" then
		return false, "snapshot_unavailable"
	end

	local galleryCount = type(snapshot.flexGallery) == "table" and #snapshot.flexGallery or 0
	local equippedCount = type(snapshot.equippedCosmetics) == "table" and countEntries(snapshot.equippedCosmetics) or 0
	local viewerViewCount = math.max(0, math.floor(tonumber(player:GetAttribute("PasrahPlayerProfileViewCount")) or 0))
	return true, string.format(
		"target=%d level=%d rank=%s totalMatches=%d totalWins=%d winRate=%d gallery=%d equipped=%d viewCount=%d",
		math.max(0, math.floor(tonumber(snapshot.userId) or 0)),
		math.max(1, math.floor(tonumber(snapshot.playerLevel) or 1)),
		tostring(snapshot.rankTier or "Bayi III"),
		math.max(0, math.floor(tonumber(snapshot.totalMatches) or 0)),
		math.max(0, math.floor(tonumber(snapshot.totalWins) or 0)),
		math.max(0, math.floor(tonumber(snapshot.winRate) or 0)),
		galleryCount,
		equippedCount,
		viewerViewCount
	)
end

function StudioE2EControlSystem:_handleGetRankSnapshot(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local rankedService = self._rankedService
	if type(rankedService) ~= "table" or type(rankedService.GetPlayerRank) ~= "function" then
		return false, "missing_ranked_service"
	end

	local snapshot = rankedService:GetPlayerRank(player)
	if type(snapshot) ~= "table" then
		return false, "snapshot_unavailable"
	end

	return true, string.format(
		"rank=%s tier=%s division=%d stars=%d victories=%d difficulty=%d",
		tostring(snapshot.playerRank or snapshot.rank or "Bayi III"),
		tostring(snapshot.tier or "Bayi"),
		math.max(0, math.floor(tonumber(snapshot.division) or 0)),
		math.max(0, math.floor(tonumber(snapshot.stars) or 0)),
		math.max(0, math.floor(tonumber(snapshot.victories) or 0)),
		math.max(0, math.floor(tonumber(type(rankedService.CalculateRankDifficulty) == "function" and rankedService:CalculateRankDifficulty(player) or 0) or 0))
	)
end

function StudioE2EControlSystem:_handleAddRankStarSnapshot(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local rankedService = self._rankedService
	if type(rankedService) ~= "table" or type(rankedService.AddStar) ~= "function" then
		return false, "missing_ranked_service"
	end

	local snapshot = rankedService:AddStar(player)
	if type(snapshot) ~= "table" then
		return false, "rank_update_failed"
	end

	return true, string.format(
		"rank=%s tier=%s division=%d stars=%d victories=%d",
		tostring(snapshot.playerRank or snapshot.rank or "Bayi III"),
		tostring(snapshot.tier or "Bayi"),
		math.max(0, math.floor(tonumber(snapshot.division) or 0)),
		math.max(0, math.floor(tonumber(snapshot.stars) or 0)),
		math.max(0, math.floor(tonumber(snapshot.victories) or 0))
	)
end

function StudioE2EControlSystem:_handleRemoveRankStarSnapshot(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local rankedService = self._rankedService
	if type(rankedService) ~= "table" or type(rankedService.RemoveStar) ~= "function" then
		return false, "missing_ranked_service"
	end

	local snapshot = rankedService:RemoveStar(player)
	if type(snapshot) ~= "table" then
		return false, "rank_update_failed"
	end

	return true, string.format(
		"rank=%s tier=%s division=%d stars=%d victories=%d",
		tostring(snapshot.playerRank or snapshot.rank or "Bayi III"),
		tostring(snapshot.tier or "Bayi"),
		math.max(0, math.floor(tonumber(snapshot.division) or 0)),
		math.max(0, math.floor(tonumber(snapshot.stars) or 0)),
		math.max(0, math.floor(tonumber(snapshot.victories) or 0))
	)
end

function StudioE2EControlSystem:_handleUseEvidenceTool(player, request)
	local evidenceService = self._evidenceService
	if type(evidenceService) ~= "table" or type(evidenceService.ProcessToolUse) ~= "function" then
		return false, "missing_evidence_service"
	end
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
	end

	local toolType = type(request) == "table" and tostring(request.toolType or "") or ""
	if toolType == "" then
		toolType = "JejakEnergi"
	end

	local payload = {
		toolType = toolType,
		payload = {
			baseChance = 1,
			detectionChance = 1,
			nearGhostRoom = type(request) == "table" and request.nearGhostRoom ~= false or true,
			activity = tonumber(type(request) == "table" and request.activity) or 2,
			roomId = type(request) == "table" and request.roomId or nil,
			now = os.clock(),
		},
	}

	local ok, reason, result = evidenceService:ProcessToolUse(player, matchId, payload)
	if ok ~= true then
		local mappedEvidenceType = STUDIO_TOOL_EVIDENCE_MAP[toolType]
		if mappedEvidenceType and type(evidenceService.CollectEvidence) == "function" then
			if type(evidenceService.SpawnEvidence) == "function" then
				evidenceService:SpawnEvidence(matchId, {
					source = "studio_e2e_tool",
					trigger = "studio_e2e",
					activity = payload.payload.activity,
					evidenceType = mappedEvidenceType,
					roomId = payload.payload.roomId,
					now = payload.payload.now,
				})
			end
			local collectOk, collectReason = evidenceService:CollectEvidence(player, matchId, {
				evidenceType = mappedEvidenceType,
				toolType = toolType,
				toolEvidenceType = mappedEvidenceType,
				nearGhostRoom = true,
				toolNearGhostRoom = true,
				activity = payload.payload.activity,
				roomId = payload.payload.roomId,
				now = payload.payload.now,
			})
			if collectOk == true then
				return true, string.format(
					"match=%s tool=%s evidence=%s fallback=collect",
					matchId,
					toolType,
					mappedEvidenceType
				)
			end
			if self._eventBus then
				self._eventBus:Publish("EvidenceCollected", {
					player = player,
					userId = player.UserId,
					matchId = matchId,
					evidenceType = mappedEvidenceType,
					toolType = toolType,
					nearGhostRoom = true,
					toolNearGhostRoom = true,
					source = "StudioE2EControlFallback",
					now = payload.payload.now,
				})
				return true, string.format(
					"match=%s tool=%s evidence=%s fallback=publish",
					matchId,
					toolType,
					mappedEvidenceType
				)
			end
			return false, tostring(collectReason or reason or "tool_use_failed")
		end
		return false, tostring(reason or "tool_use_failed")
	end

	local evidenceType = type(result) == "table" and tostring(result.evidenceType or "") or ""
	return true, string.format("match=%s tool=%s evidence=%s", matchId, toolType, evidenceType)
end

function StudioE2EControlSystem:_handleConsumeHuntProtection(player, request)
	local evidenceService = self._evidenceService
	if type(evidenceService) ~= "table" or type(evidenceService.TryConsumeHuntProtection) ~= "function" then
		return false, "missing_evidence_service"
	end

	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
	end

	local payload = {
		now = os.clock(),
		roomId = type(request) == "table" and request.roomId or nil,
	}
	local ok, reason, result = evidenceService:TryConsumeHuntProtection(matchId, payload)
	if ok ~= true then
		return false, tostring(reason or "consume_failed")
	end

	return true, HttpService:JSONEncode({
		matchId = matchId,
		reason = reason,
		result = result,
	})
end

function StudioE2EControlSystem:_handleSetForcedGhost(player, request)
	if not RunService:IsStudio() then
		return false, "studio_only"
	end

	local ghostType = type(request) == "table" and request.ghostType or nil
	local visualState = type(request) == "table" and request.visualState or nil

	if ghostType == false or ghostType == "" then
		ghostType = nil
	end
	if visualState == false or visualState == "" then
		visualState = nil
	end

	if ghostType ~= nil and type(ghostType) ~= "string" then
		return false, "invalid_ghost_type"
	end
	if visualState ~= nil and type(visualState) ~= "string" then
		return false, "invalid_visual_state"
	end

	ReplicatedStorage:SetAttribute(FORCE_GHOST_TYPE_ATTR, ghostType)
	ReplicatedStorage:SetAttribute(FORCE_GHOST_VISUAL_STATE_ATTR, visualState)

	return true, string.format(
		"ghostType=%s visualState=%s",
		tostring(ReplicatedStorage:GetAttribute(FORCE_GHOST_TYPE_ATTR)),
		tostring(ReplicatedStorage:GetAttribute(FORCE_GHOST_VISUAL_STATE_ATTR))
	)
end

function StudioE2EControlSystem:_handleTriggerJumpscare(player, request)
	if not self._eventBus then
		return false, "missing_event_bus"
	end
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
	end

	self._eventBus:Publish("JumpscareTriggered", {
		matchId = matchId,
		player = player,
		userId = player.UserId,
		cue = type(request) == "table" and request.cue or "jumpscare_stinger",
		roomId = type(request) == "table" and request.roomId or nil,
		intensity = tonumber(type(request) == "table" and request.intensity) or 1.0,
		now = os.clock(),
		source = "StudioE2EControlSystem",
	})

	return true, string.format("match=%s jumpscare=triggered", tostring(matchId))
end

function StudioE2EControlSystem:_handleTriggerAudioCue(player, request)
	if not self._eventBus then
		return false, "missing_event_bus"
	end

	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
	end

	local category = type(request) == "table" and tostring(request.category or "") or ""
	local eventName = nil
	if category == "AmbientAudio" then
		eventName = "AmbientAudioTriggered"
	elseif category == "EnvironmentalAudio" then
		eventName = "EnvironmentalAudioTriggered"
	elseif category == "GhostAudio" then
		eventName = "GhostAudioTriggered"
	elseif category == "FearAudio" then
		eventName = "FearAudioTriggered"
	elseif category == "HuntAudio" then
		eventName = "HuntAudioTriggered"
	elseif category == "JumpscareAudio" then
		eventName = "JumpscareAudioTriggered"
	else
		return false, "invalid_audio_category"
	end

	local payload = {
		matchId = matchId,
		category = category,
		cue = type(request) == "table" and request.cue or nil,
		eventType = type(request) == "table" and request.eventType or nil,
		roomId = type(request) == "table" and request.roomId or nil,
		intensity = tonumber(type(request) == "table" and request.intensity) or 1.0,
		now = os.clock(),
		source = "StudioE2EControlSystem",
	}
	local position = coerceVector3(type(request) == "table" and request.position or nil)
	if position then
		payload.position = position
	end

	self._eventBus:Publish(eventName, payload)
	return true, string.format(
		"match=%s category=%s cue=%s roomId=%s position=%s",
		tostring(matchId),
		tostring(category),
		tostring(payload.cue),
		tostring(payload.roomId),
		tostring(position)
	)
end

function StudioE2EControlSystem:_handleSimulateTeammateWarning(player, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
	end

	local remote = resolveMatchEventRemote()
	if not remote then
		return false, "missing_match_event_remote"
	end

	local teammateUserId = tonumber(type(request) == "table" and request.teammateUserId) or 900001
	if teammateUserId == player.UserId then
		teammateUserId += 1
	end
	local teammateName = type(request) == "table" and tostring(request.teammateName or "") or ""
	if teammateName == "" then
		teammateName = string.format("Teammate_%d", teammateUserId)
	end

	remote:FireClient(player, {
		eventName = "PlayerKilled",
		matchId = matchId,
		userId = teammateUserId,
		teammateUserId = teammateUserId,
		teammateName = teammateName,
		localPlayerKilled = false,
		reason = type(request) == "table" and request.reason or "studio_simulated_teammate_down",
		simulated = true,
		source = "StudioE2EControlSystem",
	})

	return true, string.format("match=%s teammate=%s(%d)", tostring(matchId), tostring(teammateName), teammateUserId)
end

function StudioE2EControlSystem:_handleSimulateSpectatorCamera(player, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local matchId = self:_resolveMatchId(player, request)
	if type(matchId) ~= "string" or matchId == "" then
		return false, "missing_match_id"
	end

	local eventBus = self._eventBus or resolveEventBus(self._deps)
	if not eventBus then
		return false, "missing_event_bus"
	end

	local cameraSystem = resolveSystem(self._deps, "SpectatorCameraSystem")
	if type(cameraSystem) ~= "table" or type(cameraSystem.State) ~= "table" or type(cameraSystem.State.Get) ~= "function" then
		return false, "missing_spectator_camera_system"
	end

	local minBound = coerceVector3(type(request) == "table" and request.boundsMin)
	local maxBound = coerceVector3(type(request) == "table" and request.boundsMax)
	local bounds = nil
	if minBound and maxBound then
		bounds = {
			min = minBound,
			max = maxBound,
		}
	end

	local targetUserId = tonumber(type(request) == "table" and request.targetUserId) or 910001
	local reason = type(request) == "table" and request.reason or "studio_probe"
	eventBus:Publish("SpectatorModeStarted", {
		matchId = matchId,
		player = player,
		userId = player.UserId,
		targetUserId = targetUserId,
		cameraBounds = bounds,
		limitedAwareness = true,
		reason = reason,
		source = "StudioE2EControlSystem",
	})

	local moveVector = coerceVector3(type(request) == "table" and request.moveVector)
	local rotation = coerceVector3(type(request) == "table" and request.rotation)
	if moveVector or rotation then
		eventBus:Publish("SpectatorCameraInput", {
			matchId = matchId,
			player = player,
			userId = player.UserId,
			moveVector = moveVector,
			rotation = rotation,
			deltaTime = tonumber(type(request) == "table" and request.deltaTime) or 0.05,
			speed = tonumber(type(request) == "table" and request.speed) or 28,
			source = "StudioE2EControlSystem",
		})
	end

	local switchTargetUserId = tonumber(type(request) == "table" and request.switchTargetUserId)
	if switchTargetUserId then
		eventBus:Publish("SpectatorTargetChanged", {
			matchId = matchId,
			player = player,
			userId = player.UserId,
			targetUserId = switchTargetUserId,
			source = "StudioE2EControlSystem",
		})
	end

	local cameraMap = cameraSystem.State:Get("cameraStateBySpectator") or {}
	local state = cameraMap[player.UserId]
	return true, string.format("match=%s %s", matchId, summarizeSpectatorCameraState(state))
end

function StudioE2EControlSystem:_handleEndSpectatorCamera(player, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local matchId = self:_resolveMatchId(player, request)
	if type(matchId) ~= "string" or matchId == "" then
		return false, "missing_match_id"
	end

	local eventBus = self._eventBus or resolveEventBus(self._deps)
	if not eventBus then
		return false, "missing_event_bus"
	end

	eventBus:Publish("SpectatorModeEnded", {
		matchId = matchId,
		player = player,
		userId = player.UserId,
		reason = type(request) == "table" and request.reason or "studio_probe_end",
		source = "StudioE2EControlSystem",
	})

	return true, string.format("match=%s spectator_camera_ended", matchId)
end

function StudioE2EControlSystem:_handleSimulateSpectatorVision(player, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local matchId = self:_resolveMatchId(player, request)
	if type(matchId) ~= "string" or matchId == "" then
		return false, "missing_match_id"
	end

	local spectatorSystem = resolveSystem(self._deps, "SpectatorSystem")
	local service = type(spectatorSystem) == "table" and spectatorSystem.Service or nil
	if type(service) ~= "table" then
		return false, "missing_spectator_system"
	end
	local coreService = type(service._spectatorService) == "table" and service._spectatorService or service

	local roomId = type(request) == "table" and tostring(request.roomId or "") or ""
	if roomId == "" then
		roomId = "Room_LivingRoom"
	end
	local roomIds = type(request) == "table" and request.roomIds or nil
	if type(roomIds) ~= "table" or #roomIds == 0 then
		roomIds = { roomId, "Room_Hallway", "Room_Bedroom" }
	end

	service:StartMatch(matchId, {
		matchId = matchId,
		players = { player },
		roomIds = roomIds,
	})

	local targetUserId = tonumber(type(request) == "table" and request.targetUserId) or 950001
	local match = coreService:_ensureMatch(matchId)
	match.aliveByUserId[targetUserId] = true
	match.playerRooms[targetUserId] = roomId
	match.roomIds = roomIds

	service:EnterSpectator(player, matchId, {
		reason = type(request) == "table" and request.reason or "studio_vision_probe",
		playerRooms = {
			[targetUserId] = roomId,
		},
	})

	local activityType = type(request) == "table" and request.activityType or "ghost_roamed"
	local ghostRoomId = type(request) == "table" and tostring(request.ghostRoomId or roomId) or roomId
	local eventsPublished = service:ProcessGhostActivity(matchId, {
		activityType = activityType,
		room = ghostRoomId,
		playerRooms = {
			[targetUserId] = roomId,
		},
		now = os.clock(),
	})

	local vision = service:GetSpectatorVision(player, matchId)
	local communication = service:GetCommunicationContext(player, matchId)
	return true, string.format(
		"match=%s events=%s %s",
		matchId,
		tostring(eventsPublished),
		summarizeSpectatorVisionState(vision, communication)
	)
end

function StudioE2EControlSystem:_handleEndSpectatorVision(player, request)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local matchId = self:_resolveMatchId(player, request)
	if type(matchId) ~= "string" or matchId == "" then
		return false, "missing_match_id"
	end

	local spectatorSystem = resolveSystem(self._deps, "SpectatorSystem")
	local service = type(spectatorSystem) == "table" and spectatorSystem.Service or nil
	if type(service) ~= "table" then
		return false, "missing_spectator_system"
	end

	local ok = service:ExitSpectator(player, matchId)
	if ok ~= true then
		return false, "spectator_exit_failed"
	end

	return true, string.format("match=%s spectator_vision_ended", matchId)
end

function StudioE2EControlSystem:_handleHidingDebugSnapshot(player, request)
	local hidingSystem = resolveSystem(self._deps, "HidingSystem")
	if type(hidingSystem) ~= "table" then
		return false, "missing_hiding_system"
	end

	local service = hidingSystem.Service
	local state = hidingSystem.State
	if type(service) ~= "table" or type(state) ~= "table" then
		return false, "invalid_hiding_system"
	end

	local matchId = self:_resolveMatchId(player, request)
	local hiddenPlayers = type(state.Get) == "function" and (state:Get("hiddenPlayers") or {}) or {}
	local safeZonesByMatchId = service._safeZonesByMatchId or {}
	local safeZoneState = type(matchId) == "string" and safeZonesByMatchId[matchId] or nil
	local zoneCount = type(safeZoneState) == "table" and type(safeZoneState.records) == "table" and #safeZoneState.records or 0
	local hiddenCount = 0
	local zoneSummary = {}
	local safeZoneFolderPath = "nil"
	local safeZoneFolderChildCount = 0
	if type(safeZoneState) == "table" then
		local folder = safeZoneState.folder
		if typeof(folder) == "Instance" then
			safeZoneFolderPath = folder:GetFullName()
			safeZoneFolderChildCount = #folder:GetChildren()
		end
		if type(safeZoneState.records) == "table" then
			for index, record in ipairs(safeZoneState.records) do
				if index > 4 then
					break
				end
				local part = type(record) == "table" and record.part or nil
				local position = typeof(part) == "Instance" and part:IsA("BasePart") and part.Position or nil
				local parentPath = typeof(part) == "Instance" and part.Parent and part.Parent:GetFullName() or "nil"
				table.insert(
					zoneSummary,
					string.format(
						"%s@%s parent=%s alive=%s",
						tostring(type(record) == "table" and record.id or ("zone_" .. tostring(index))),
						position and string.format("%.1f,%.1f,%.1f", position.X, position.Y, position.Z) or "nil",
						parentPath,
						tostring(typeof(part) == "Instance" and part.Parent ~= nil)
					)
				)
			end
		end
	end
	for _ in pairs(hiddenPlayers) do
		hiddenCount += 1
	end

	if typeof(player) == "Instance" and player:IsA("Player") then
		player:SetAttribute("PasrahStudioE2EHidingSnapshotAt", os.clock())
		player:SetAttribute("PasrahStudioE2EHidingRunning", service._running == true)
		player:SetAttribute("PasrahStudioE2EHidingStateMatchId", tostring(type(state.Get) == "function" and state:Get("activeMatchId") or ""))
		player:SetAttribute("PasrahStudioE2EHidingZoneCount", zoneCount)
		player:SetAttribute("PasrahStudioE2EHidingHiddenCount", hiddenCount)
		player:SetAttribute("PasrahStudioE2EHidingZoneSummary", table.concat(zoneSummary, " | "))
		player:SetAttribute("PasrahStudioE2EHidingZoneFolder", safeZoneFolderPath)
		player:SetAttribute("PasrahStudioE2EHidingZoneFolderChildCount", safeZoneFolderChildCount)
	end

	return true, string.format(
		"running=%s activeMatchId=%s matchId=%s zoneCount=%d hiddenCount=%d folderChildren=%d eventBus=%s zones=%s",
		tostring(service._running == true),
		tostring(type(state.Get) == "function" and state:Get("activeMatchId") or nil),
		tostring(matchId),
		zoneCount,
		hiddenCount,
		safeZoneFolderChildCount,
		tostring(service._eventBus ~= nil)
		,
		#zoneSummary > 0 and table.concat(zoneSummary, " || ") or "none"
	)
end

function StudioE2EControlSystem:_handleEnterHide(player, request)
	if not self._eventBus then
		return false, "missing_event_bus"
	end
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
	end

	local zoneId = type(request) == "table" and (request.zoneId or request.closetId) or nil
	if type(zoneId) ~= "string" or zoneId == "" then
		zoneId = "StudioE2EHide"
	end

	local spotType = type(request) == "table" and request.spotType or "Closet"
	if type(spotType) ~= "string" or spotType == "" then
		spotType = "Closet"
	end

	self._eventBus:Publish("PlayerAttemptHide", {
		player = player,
		userId = player.UserId,
		matchId = matchId,
		zoneId = zoneId,
		closetId = zoneId,
		spotType = spotType,
		movementLevel = 0,
		noiseLevel = 0,
		source = "StudioE2EControlSystem",
	})

	return true, string.format("match=%s zone=%s spotType=%s", matchId, zoneId, spotType)
end

function StudioE2EControlSystem:_handleExitHide(player, request)
	if not self._eventBus then
		return false, "missing_event_bus"
	end
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
	end

	local zoneId = type(request) == "table" and (request.zoneId or request.closetId) or nil
	if type(zoneId) ~= "string" or zoneId == "" then
		zoneId = "StudioE2EHide"
	end

	local spotType = type(request) == "table" and request.spotType or "Closet"
	if type(spotType) ~= "string" or spotType == "" then
		spotType = "Closet"
	end

	self._eventBus:Publish("PlayerExitHide", {
		player = player,
		userId = player.UserId,
		matchId = matchId,
		zoneId = zoneId,
		closetId = zoneId,
		spotType = spotType,
		source = "StudioE2EControlSystem",
	})

	return true, string.format("match=%s zone=%s spotType=%s", matchId, zoneId, spotType)
end

function StudioE2EControlSystem:_handleRequest(player, request)
	local action = type(request) == "table" and request.action or nil
	self:_setTrace({
		"action=" .. tostring(action),
		"player=" .. tostring(player and player.Name),
		"match=" .. tostring(self:_resolveMatchId(player, request)),
	}, player)

	local ok = false
	local result = "unsupported_action"
	local dispatchOk, dispatchResultA, dispatchResultB = xpcall(function()
		if action == "AdvancePhase" then
			return self:_handleAdvancePhase(player, request)
		elseif action == "StartSoloMatch" then
			return self:_handleStartSoloMatch(player, request)
		elseif action == "SetPreparationFocusTool" then
			return self:_handleSetPreparationFocusTool(player, request)
		elseif action == "SimulateLobbyZone" then
			return self:_handleSimulateLobbyZone(player, request)
		elseif action == "LobbyTrainingSnapshot" then
			return self:_handleLobbyTrainingSnapshot(player, request)
		elseif action == "LobbyTrainingUseTool" then
			return self:_handleLobbyTrainingUseTool(player, request)
		elseif action == "LobbyTrainingUseSupport" then
			return self:_handleLobbyTrainingUseSupport(player, request)
		elseif action == "LobbyTrainingRotate" then
			return self:_handleLobbyTrainingRotate(player, request)
		elseif action == "ForceHunt" then
			return self:_handleForceHunt(player, request)
		elseif action == "ForceManifest" then
			return self:_handleForceManifest(player, request)
		elseif action == "TriggerMapEvent" then
			return self:_handleTriggerMapEvent(player, request)
		elseif action == "GetMapInteractionSnapshot" then
			return self:_handleGetMapInteractionSnapshot(player, request)
		elseif action == "TriggerMapInteraction" then
			return self:_handleTriggerMapInteraction(player, request)
		elseif action == "GetGhostRuntimeSnapshot" then
			return self:_handleGetGhostRuntimeSnapshot(player, request)
		elseif action == "ExtractSelf" then
			return self:_handleExtractSelf(player, request)
		elseif action == "DrainSanity" then
			return self:_handleDrainSanity(player, request)
		elseif action == "SetForcedGhost" then
			return self:_handleSetForcedGhost(player, request)
		elseif action == "EndMatch" then
			return self:_handleEndMatch(player, request)
		elseif action == "GetWallet" then
			return self:_handleGetWallet(player)
		elseif action == "GrantCurrency" then
			return self:_handleGrantCurrency(player, request)
		elseif action == "GrantMarketplacePurchase" then
			return self:_handleGrantMarketplacePurchase(player, request)
		elseif action == "GrantMarketplaceEntitlement" then
			return self:_handleGrantMarketplaceEntitlement(player, request)
		elseif action == "GetPersistenceMode" then
			return self:_handleGetPersistenceMode()
		elseif action == "GetQAGateSnapshot" then
			return self:_handleGetQAGateSnapshot(player, request)
		elseif action == "GetQAGateReadiness" then
			return self:_handleGetQAGateReadiness(player, request)
		elseif action == "GetPublishReadiness" then
			return self:_handleGetPublishReadiness(player, request)
		elseif action == "GetShopReadiness" then
			return self:_handleGetShopReadiness()
		elseif action == "GetShopPlayerSnapshot" then
			return self:_handleGetShopPlayerSnapshot(player, request)
		elseif action == "ProcessShopPurchase" then
			return self:_handleProcessShopPurchase(player, request)
		elseif action == "GetRoyalPassSnapshot" then
			return self:_handleGetRoyalPassSnapshot(player)
		elseif action == "GrantRoyalPassXP" then
			return self:_handleGrantRoyalPassXP(player, request)
		elseif action == "GetProgressionSnapshot" then
			return self:_handleGetProgressionSnapshot(player)
		elseif action == "GrantProgressionXP" then
			return self:_handleGrantProgressionXP(player, request)
		elseif action == "GetProfileSnapshot" then
			return self:_handleGetProfileSnapshot(player)
		elseif action == "UpdateProfileSnapshot" then
			return self:_handleUpdateProfileSnapshot(player, request)
		elseif action == "GetCosmeticSnapshot" then
			return self:_handleGetCosmeticSnapshot(player)
		elseif action == "EquipCosmeticSnapshot" then
			return self:_handleEquipCosmeticSnapshot(player, request)
		elseif action == "UnequipCosmeticSnapshot" then
			return self:_handleUnequipCosmeticSnapshot(player, request)
		elseif action == "GetPublicProfileSnapshot" then
			return self:_handleGetPublicProfileSnapshot(player, request)
		elseif action == "GetRankSnapshot" then
			return self:_handleGetRankSnapshot(player)
		elseif action == "AddRankStarSnapshot" then
			return self:_handleAddRankStarSnapshot(player)
		elseif action == "RemoveRankStarSnapshot" then
			return self:_handleRemoveRankStarSnapshot(player)
		elseif action == "UseEvidenceTool" then
			return self:_handleUseEvidenceTool(player, request)
		elseif action == "ConsumeHuntProtection" then
			return self:_handleConsumeHuntProtection(player, request)
		elseif action == "TriggerJumpscare" then
			return self:_handleTriggerJumpscare(player, request)
		elseif action == "TriggerAudioCue" then
			return self:_handleTriggerAudioCue(player, request)
		elseif action == "SimulateTeammateWarning" then
			return self:_handleSimulateTeammateWarning(player, request)
		elseif action == "SimulateSpectatorCamera" then
			return self:_handleSimulateSpectatorCamera(player, request)
		elseif action == "EndSpectatorCamera" then
			return self:_handleEndSpectatorCamera(player, request)
		elseif action == "SimulateSpectatorVision" then
			return self:_handleSimulateSpectatorVision(player, request)
		elseif action == "EndSpectatorVision" then
			return self:_handleEndSpectatorVision(player, request)
		elseif action == "HidingDebugSnapshot" then
			return self:_handleHidingDebugSnapshot(player, request)
		elseif action == "EnterHide" then
			return self:_handleEnterHide(player, request)
		elseif action == "ExitHide" then
			return self:_handleExitHide(player, request)
		end
		return false, "unsupported_action"
	end, function(err)
		return debug.traceback(err)
	end)

	if dispatchOk then
		ok = dispatchResultA
		result = dispatchResultB
	else
		ok = false
		result = "handler_error"
		warn(string.format("[StudioE2EControlSystem] action=%s failed\n%s", tostring(action), tostring(dispatchResultA)))
	end

	self:_setResult({
		"ok=" .. tostring(ok),
		"action=" .. tostring(action),
		"result=" .. tostring(result),
	}, player)

	if self._remote then
		self._remote:FireClient(player, {
			eventName = "StudioE2EAck",
			action = action,
			ok = ok,
			result = result,
		})
	end
end

function StudioE2EControlSystem:Start()
	if not RunService:IsStudio() then
		return
	end

	self._remote = ensureRemote()
	self._remoteConnection = self._remote.OnServerEvent:Connect(function(player, request)
		self:_handleRequest(player, request)
	end)
	ReplicatedStorage:SetAttribute(READY_ATTR, true)
	self:_setResult({ "ok=true", "action=Init", "result=ready" })
end

function StudioE2EControlSystem:Shutdown()
	if self._remoteConnection then
		self._remoteConnection:Disconnect()
		self._remoteConnection = nil
	end
	if self._remote then
		self._remote:Destroy()
		self._remote = nil
	end
	if RunService:IsStudio() then
		ReplicatedStorage:SetAttribute(READY_ATTR, nil)
		ReplicatedStorage:SetAttribute(TRACE_ATTR, nil)
		ReplicatedStorage:SetAttribute(RESULT_ATTR, nil)
		ReplicatedStorage:SetAttribute(GHOST_SNAPSHOT_ATTR, nil)
	end
end

return StudioE2EControlSystem

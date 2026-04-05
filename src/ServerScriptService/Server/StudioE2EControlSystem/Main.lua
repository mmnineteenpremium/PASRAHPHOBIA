local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")

local Services = require(script.Parent.Parent.Core.Services)

local StudioE2EControlSystem = {}
StudioE2EControlSystem.__index = StudioE2EControlSystem

local REMOTE_FOLDER_NAME = "RemoteEvents"
local REMOTE_NAME = "StudioE2EControl"
local READY_ATTR = "PasrahStudioE2EReady"
local TRACE_ATTR = "PasrahStudioE2ELastAction"
local RESULT_ATTR = "PasrahStudioE2ELastResult"
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
	BolaArwah = "To'un",
	TounDetection = "To'un",
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
	self._evidenceService = nil
	self._lobbyHubService = nil
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
	self._evidenceService = resolveService(self._deps, "EvidenceSystem", "ProcessToolUse")
	self._lobbyHubService = resolveService(self._deps, "LobbySocialHub", "OnPlayerEnteredZone")
	self._eventBus = resolveEventBus(self._deps)
end

function StudioE2EControlSystem:_setTrace(parts)
	if not RunService:IsStudio() then
		return
	end
	ReplicatedStorage:SetAttribute(TRACE_ATTR, encodeSummary(parts))
end

function StudioE2EControlSystem:_setResult(parts)
	if not RunService:IsStudio() then
		return
	end
	ReplicatedStorage:SetAttribute(RESULT_ATTR, encodeSummary(parts))
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

	local payload = {
		players = { player },
		mapId = type(request) == "table" and request.mapId or nil,
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
	if type(shopService.BuildClientSnapshot) == "function" then
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
	for _ in pairs(hiddenPlayers) do
		hiddenCount += 1
	end

	if typeof(player) == "Instance" and player:IsA("Player") then
		player:SetAttribute("PasrahStudioE2EHidingSnapshotAt", os.clock())
		player:SetAttribute("PasrahStudioE2EHidingRunning", service._running == true)
		player:SetAttribute("PasrahStudioE2EHidingStateMatchId", tostring(type(state.Get) == "function" and state:Get("activeMatchId") or ""))
		player:SetAttribute("PasrahStudioE2EHidingZoneCount", zoneCount)
		player:SetAttribute("PasrahStudioE2EHidingHiddenCount", hiddenCount)
	end

	return true, string.format(
		"running=%s activeMatchId=%s matchId=%s zoneCount=%d hiddenCount=%d eventBus=%s",
		tostring(service._running == true),
		tostring(type(state.Get) == "function" and state:Get("activeMatchId") or nil),
		tostring(matchId),
		zoneCount,
		hiddenCount,
		tostring(service._eventBus ~= nil)
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
	})

	local ok = false
	local result = "unsupported_action"

	if action == "AdvancePhase" then
		ok, result = self:_handleAdvancePhase(player, request)
	elseif action == "StartSoloMatch" then
		ok, result = self:_handleStartSoloMatch(player, request)
	elseif action == "SimulateLobbyZone" then
		ok, result = self:_handleSimulateLobbyZone(player, request)
	elseif action == "ForceHunt" then
		ok, result = self:_handleForceHunt(player, request)
	elseif action == "ExtractSelf" then
		ok, result = self:_handleExtractSelf(player, request)
	elseif action == "DrainSanity" then
		ok, result = self:_handleDrainSanity(player, request)
	elseif action == "SetForcedGhost" then
		ok, result = self:_handleSetForcedGhost(player, request)
	elseif action == "EndMatch" then
		ok, result = self:_handleEndMatch(player, request)
	elseif action == "GetWallet" then
		ok, result = self:_handleGetWallet(player)
	elseif action == "GrantCurrency" then
		ok, result = self:_handleGrantCurrency(player, request)
	elseif action == "GrantMarketplacePurchase" then
		ok, result = self:_handleGrantMarketplacePurchase(player, request)
	elseif action == "GrantMarketplaceEntitlement" then
		ok, result = self:_handleGrantMarketplaceEntitlement(player, request)
	elseif action == "GetPersistenceMode" then
		ok, result = self:_handleGetPersistenceMode()
	elseif action == "GetQAGateSnapshot" then
		ok, result = self:_handleGetQAGateSnapshot(player, request)
	elseif action == "GetQAGateReadiness" then
		ok, result = self:_handleGetQAGateReadiness(player, request)
	elseif action == "GetPublishReadiness" then
		ok, result = self:_handleGetPublishReadiness(player, request)
	elseif action == "GetShopReadiness" then
		ok, result = self:_handleGetShopReadiness()
	elseif action == "GetShopPlayerSnapshot" then
		ok, result = self:_handleGetShopPlayerSnapshot(player, request)
	elseif action == "UseEvidenceTool" then
		ok, result = self:_handleUseEvidenceTool(player, request)
	elseif action == "ConsumeHuntProtection" then
		ok, result = self:_handleConsumeHuntProtection(player, request)
	elseif action == "TriggerJumpscare" then
		ok, result = self:_handleTriggerJumpscare(player, request)
	elseif action == "TriggerAudioCue" then
		ok, result = self:_handleTriggerAudioCue(player, request)
	elseif action == "HidingDebugSnapshot" then
		ok, result = self:_handleHidingDebugSnapshot(player, request)
	elseif action == "EnterHide" then
		ok, result = self:_handleEnterHide(player, request)
	elseif action == "ExitHide" then
		ok, result = self:_handleExitHide(player, request)
	else
		ok, result = false, "unsupported_action"
	end

	self:_setResult({
		"ok=" .. tostring(ok),
		"action=" .. tostring(action),
		"result=" .. tostring(result),
	})

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
	end
end

return StudioE2EControlSystem

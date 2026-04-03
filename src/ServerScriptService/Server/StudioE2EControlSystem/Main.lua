local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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

local VALID_PHASES = {
	PreparationPhase = true,
	InvestigationPhase = true,
	HuntPhase = true,
	EndgamePhase = true,
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

function StudioE2EControlSystem.new(deps)
	local self = setmetatable({}, StudioE2EControlSystem)
	self._deps = deps or {}
	self._remote = nil
	self._remoteConnection = nil
	self._matchSystem = nil
	self._huntEscapeSystem = nil
	self._sanitySystem = nil
	self._eventBus = nil
	return self
end

function StudioE2EControlSystem:Init()
	self._matchSystem = resolveService(self._deps, "MatchSystem", "AdvanceMatchPhase")
	self._huntEscapeSystem = resolveService(self._deps, "HuntEscapeSystem", "HandlePlayerExtraction")
	self._sanitySystem = resolveService(self._deps, "SanitySystem", "DrainSanity")
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

function StudioE2EControlSystem:_handleForceHunt(player, request)
	if not self._eventBus then
		return false, "missing_event_bus"
	end

	local matchId = self:_resolveMatchId(player, request)
	if not matchId then
		return false, "missing_match_id"
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
	if not payload then
		return false, "end_match_failed"
	end
	return true, string.format("match=%s ended", matchId)
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
	elseif action == "HidingDebugSnapshot" then
		ok, result = self:_handleHidingDebugSnapshot(player, request)
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

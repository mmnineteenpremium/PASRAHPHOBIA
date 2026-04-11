local SpectatorDistortionEngine = require(script.Parent.SpectatorDistortionEngine)
local SpectatorVision = require(script.Parent.SpectatorVision)
local SpectatorGhostGenerator = require(script.Parent.SpectatorGhostGenerator)
local SpectatorCommunication = require(script.Parent.SpectatorCommunication)
local Services = require(script.Parent.Parent.Core.Services)

local SpectatorService = {}
SpectatorService.__index = SpectatorService

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


local function resolveEvidenceTypes()
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
    return {}
end

local EVIDENCE_TYPES = resolveEvidenceTypes()
local function resolveGhostService(deps)
	local ghostSystem = Services.Get(deps, "GhostSystem")
	if type(ghostSystem) ~= "table" then
		return nil
	end
	if type(ghostSystem.GetGhostState) == "function" then
		return ghostSystem
	end
	if type(ghostSystem.Service) == "table" and type(ghostSystem.Service.GetGhostState) == "function" then
		return ghostSystem.Service
	end
	return nil
end

local function getNow(now)
	return now or os.clock()
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

local function sortedAliveUserIds(aliveByUserId)
	local userIds = {}
	for userId, isAlive in pairs(aliveByUserId or {}) do
		if isAlive == true then
			table.insert(userIds, userId)
		end
	end
	table.sort(userIds)
	return userIds
end

local function stampSpectatorVisionRuntime(target, payload)
	if typeof(target) ~= "Instance" or not target:IsA("Player") then
		return
	end

	target:SetAttribute("PasrahSpectatorVisionOwner", "SpectatorSystem")
	target:SetAttribute("PasrahSpectatorVisionMatchId", type(payload.matchId) == "string" and payload.matchId or nil)
	target:SetAttribute("PasrahSpectatorVisionActive", payload.active == true)
	target:SetAttribute("PasrahSpectatorVisionTargetUserId", tonumber(payload.targetUserId))
	target:SetAttribute("PasrahSpectatorVisionLastOutcome", type(payload.outcome) == "string" and payload.outcome or nil)
	target:SetAttribute("PasrahSpectatorVisionLastSignalType", type(payload.signalType) == "string" and payload.signalType or nil)
	target:SetAttribute("PasrahSpectatorVisionLastRoomId", type(payload.roomId) == "string" and payload.roomId or nil)
	target:SetAttribute("PasrahSpectatorVisionReliability", type(payload.reliability) == "string" and payload.reliability or nil)
	target:SetAttribute("PasrahSpectatorVisionVoiceAllowed", payload.canTransmitVoice == true)
	target:SetAttribute("PasrahSpectatorVisionDistortionHint", type(payload.distortionHint) == "string" and payload.distortionHint or nil)
	target:SetAttribute("PasrahSpectatorVisionLikelyMisleading", payload.isLikelyMisleading == true)
	target:SetAttribute("PasrahSpectatorVisionLastEvent", type(payload.lastEvent) == "string" and payload.lastEvent or nil)
	target:SetAttribute("PasrahSpectatorVisionLastActivityType", type(payload.activityType) == "string" and payload.activityType or nil)
	target:SetAttribute("PasrahSpectatorVisionReason", type(payload.reason) == "string" and payload.reason or nil)
	target:SetAttribute("PasrahSpectatorVisionCreatedAt", type(payload.createdAt) == "number" and payload.createdAt or nil)
	target:SetAttribute("PasrahSpectatorVisionVisibleUntil", type(payload.visibilityEndsAt) == "number" and payload.visibilityEndsAt or nil)
	target:SetAttribute("PasrahSpectatorVisionLastUpdatedAt", os.clock())
end

function SpectatorService.new(state, deps)
	local self = setmetatable({}, SpectatorService)
	self._state = state
	self._deps = deps or {}
	self._eventBus = resolveEventBus(self._deps)
	self._ghostService = resolveGhostService(self._deps)

	self._distortionEngine = SpectatorDistortionEngine.new(self._deps, self._deps.SpectatorDistortionConfig)
	self._vision = SpectatorVision.new(self._deps, self._deps.SpectatorVisionConfig)
	self._ghostGenerator = SpectatorGhostGenerator.new(self._deps, self._deps.SpectatorGhostGeneratorConfig)
	self._communication = SpectatorCommunication.new(self._state, self._deps, self._deps.SpectatorCommunicationConfig)
	self._evidenceTypes = EVIDENCE_TYPES
	return self
end

function SpectatorService:Init()
	self._state:Set("spectatorMatches", {})
	self._state:Set("communicationByMatch", {})
end

function SpectatorService:Start()
	-- Runtime is event-driven.
	local eventBus = self._eventBus
	if eventBus and eventBus.Subscribe then
		eventBus:Subscribe("SpectatorModeStarted", function(payload)
			local matchId = payload and payload.matchId
			local player = payload and payload.player
			if not player and payload and payload.userId then
				local Players = game:GetService("Players")
				player = Players:GetPlayerByUserId(payload.userId)
				if not player then
					for _, candidate in ipairs(Players:GetPlayers()) do
						if candidate.UserId == payload.userId then
							player = candidate
							break
						end
					end
				end
			end
			if not player or not matchId then
				return
			end
			self:EnterSpectator(player, matchId, payload)
		end)
		eventBus:Subscribe("SpectatorModeEnded", function(payload)
			local matchId = payload and payload.matchId
			local player = payload and payload.player
			if not player and payload and payload.userId then
				local Players = game:GetService("Players")
				player = Players:GetPlayerByUserId(payload.userId)
			end
			if not player or not matchId then
				return
			end
			self:ExitSpectator(player, matchId)
		end)
	end
end

function SpectatorService:Stop()
	self._state:Set("spectatorMatches", {})
	self._state:Set("communicationByMatch", {})
end

function SpectatorService:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function SpectatorService:_getMatches()
	return self._state:Get("spectatorMatches") or {}
end

function SpectatorService:_setMatches(matches)
	self._state:Set("spectatorMatches", matches)
end

function SpectatorService:_getMatch(matchId)
	local matches = self:_getMatches()
	return matches[matchId]
end

function SpectatorService:_ensureMatch(matchId)
	local matches = self:_getMatches()
	local match = matches[matchId]
	if match then
		return match
	end

	match = {
		matchId = matchId,
		aliveByUserId = {},
		playersByUserId = {},
		playerRooms = {},
		spectatorsByUserId = {},
		spectators = {},
		alive = {},
		roomIds = {},
		spectatorFlagsByUserId = {},
	}
	matches[matchId] = match
	self:_setMatches(matches)
	self._communication:EnsureSession(matchId)
	return match
end

function SpectatorService:_removeMatch(matchId)
	local matches = self:_getMatches()
	matches[matchId] = nil
	self:_setMatches(matches)
	self._communication:RemoveSession(matchId)
end

function SpectatorService:_chooseInitialTarget(match)
	local aliveUserIds = sortedAliveUserIds(match.aliveByUserId)
	return aliveUserIds[1]
end

function SpectatorService:_rotateTarget(match, currentTargetUserId, direction)
	local aliveUserIds = sortedAliveUserIds(match.aliveByUserId)
	if #aliveUserIds == 0 then
		return nil
	end

	if #aliveUserIds == 1 then
		return aliveUserIds[1]
	end

	local currentIndex = 1
	for index, userId in ipairs(aliveUserIds) do
		if userId == currentTargetUserId then
			currentIndex = index
			break
		end
	end

	local nextIndex = currentIndex + (direction or 1)
	if nextIndex > #aliveUserIds then
		nextIndex = 1
	elseif nextIndex < 1 then
		nextIndex = #aliveUserIds
	end

	return aliveUserIds[nextIndex]
end

function SpectatorService:_refreshSpectatorTargets(match)
	for _, spectator in pairs(match.spectatorsByUserId) do
		if spectator.targetUserId and match.aliveByUserId[spectator.targetUserId] then
			continue
		end
		spectator.targetUserId = self:_chooseInitialTarget(match)
	end
end

function SpectatorService:_stampSpectatorRuntime(player, payload)
	stampSpectatorVisionRuntime(player, payload or {})
end

function SpectatorService:_getGhostState(matchId)
	if not self._ghostService then
		return {}
	end
	return self._ghostService:GetGhostState(matchId) or {}
end

function SpectatorService:_isNearGhost(match, spectator, ghostState, activityPayload)
	local targetUserId = spectator.targetUserId
	if not targetUserId then
		return false
	end

	local observerRoomId = match.playerRooms[targetUserId]
	if not observerRoomId then
		return false
	end

	local ghostRoomId = ghostState.currentRoomId or activityPayload.room
	if not ghostRoomId then
		return false
	end

	return observerRoomId == ghostRoomId
end

function SpectatorService:StartMatch(matchId, payload)
	local match = self:_ensureMatch(matchId)
	local players = payload and payload.players or {}
	match.roomIds = payload and (payload.roomIds or payload.rooms) or match.roomIds

	for _, player in ipairs(players) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			match.playersByUserId[player.UserId] = player
			match.aliveByUserId[player.UserId] = true
			self:_stampSpectatorRuntime(player, {
				matchId = matchId,
				active = false,
				lastEvent = "SpectatorMatchStarted",
				reason = "match_started",
			})
		end
	end

	self:_publish("SpectatorMatchStarted", {
		matchId = matchId,
		playerCount = #players,
	})

	return match
end

function SpectatorService:EndMatch(matchId)
	local match = self:_getMatch(matchId)
	if match and type(match.playersByUserId) == "table" then
		for _, player in pairs(match.playersByUserId) do
			self:_stampSpectatorRuntime(player, {
				matchId = matchId,
				active = false,
				lastEvent = "SpectatorMatchEnded",
				reason = "match_ended",
			})
		end
	end
	self:_removeMatch(matchId)
	self:_publish("SpectatorMatchEnded", { matchId = matchId })
end

function SpectatorService:ClearSpectators(matchId)
	self:_removeMatch(matchId)
end

function SpectatorService:EnterSpectator(player, matchId, payload)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return nil, "invalid_player"
	end

	print("[SpectatorService] Starting spectator session")
	print("[SpectatorService] Spectator activated for", player.UserId)

	local match = self:_ensureMatch(matchId)
	match.playersByUserId[player.UserId] = player
	match.aliveByUserId[player.UserId] = false
	match.spectators[player.UserId] = true
	match.alive[player.UserId] = false
	local existingSpectator = match.spectatorsByUserId[player.UserId]
	if existingSpectator then
		existingSpectator.player = player
		self:_refreshSpectatorTargets(match)
		return existingSpectator
	end

	if payload and payload.playerRooms then
		for userId, roomId in pairs(payload.playerRooms) do
			match.playerRooms[userId] = roomId
		end
	end

	local targetUserId = self:_chooseInitialTarget(match)
	local spectator = {
		player = player,
		targetUserId = targetUserId,
		lastDistortionAt = 0,
		lastVision = nil,
		outcomeHistory = {},
	}
	match.spectatorsByUserId[player.UserId] = spectator
	match.spectatorFlagsByUserId[player.UserId] = true
	self._communication:RegisterSpectator(matchId, player.UserId)
	self:_refreshSpectatorTargets(match)
	local communicationContext = self._communication:GetCommunicationContext(matchId, player.UserId)
	self:_stampSpectatorRuntime(player, {
		matchId = matchId,
		active = true,
		targetUserId = targetUserId,
		canTransmitVoice = communicationContext.canTransmitVoice,
		distortionHint = communicationContext.distortionHint,
		isLikelyMisleading = communicationContext.isLikelyMisleading,
		lastEvent = "SpectatorEntered",
		reason = payload and payload.reason or "spectator_entered",
	})

	self:_publish("SpectatorEntered", {
		matchId = matchId,
		player = player,
		targetUserId = targetUserId,
	})

	return spectator
end

function SpectatorService:ExitSpectator(player, matchId)
	local userId = toUserId(player)
	if not userId then
		return false, "invalid_player"
	end

	local match = self:_getMatch(matchId)
	if not match then
		return false, "missing_match"
	end

	local spectator = match.spectatorsByUserId[userId]
	if not spectator then
		return false, "not_spectator"
	end

	match.spectatorsByUserId[userId] = nil
	self._communication:UnregisterSpectator(matchId, userId)
	self:_stampSpectatorRuntime(typeof(player) == "Instance" and player:IsA("Player") and player or match.playersByUserId[userId], {
		matchId = matchId,
		active = false,
		lastEvent = "SpectatorExited",
		reason = "spectator_exited",
	})

	self:_publish("SpectatorExited", {
		matchId = matchId,
		userId = userId,
	})

	return true
end

function SpectatorService:GetSpectatorTarget(player, matchId)
	local userId = toUserId(player)
	if not userId then
		return nil
	end

	local match = self:_getMatch(matchId)
	if not match then
		return nil
	end

	local spectator = match.spectatorsByUserId[userId]
	return spectator and spectator.targetUserId or nil
end

function SpectatorService:SwitchSpectatorTarget(player, matchId, direction)
	local userId = toUserId(player)
	if not userId then
		return nil, "invalid_player"
	end

	local match = self:_getMatch(matchId)
	if not match then
		return nil, "missing_match"
	end

	local spectator = match.spectatorsByUserId[userId]
	if not spectator then
		return nil, "not_spectator"
	end

	local nextTarget = self:_rotateTarget(match, spectator.targetUserId, direction or 1)
	spectator.targetUserId = nextTarget
	local communicationContext = self._communication:GetCommunicationContext(matchId, userId)
	self:_stampSpectatorRuntime(spectator.player, {
		matchId = matchId,
		active = true,
		targetUserId = nextTarget,
		canTransmitVoice = communicationContext.canTransmitVoice,
		distortionHint = communicationContext.distortionHint,
		isLikelyMisleading = communicationContext.isLikelyMisleading,
		lastEvent = "SpectatorTargetChanged",
		reason = "target_switched",
	})

	self:_publish("SpectatorTargetChanged", {
		matchId = matchId,
		userId = userId,
		targetUserId = nextTarget,
	})

	return nextTarget
end

function SpectatorService:_updatePresenceFromPayload(match, payload)
	if payload.playerRooms then
		for userId, roomId in pairs(payload.playerRooms) do
			match.playerRooms[userId] = roomId
		end
	end

	local player = payload.player
	local userId = payload.userId or toUserId(player)
	if not userId then
		return
	end

	match.playersByUserId[userId] = player or match.playersByUserId[userId]
	if payload.alive ~= nil then
		match.aliveByUserId[userId] = payload.alive == true
	end

	if payload.roomId then
		match.playerRooms[userId] = payload.roomId
	end
end

function SpectatorService:_endRealVisionsForHuntStart(match, matchId, now)
	for userId, spectator in pairs(match.spectatorsByUserId) do
		local lastVision = spectator.lastVision
		if not lastVision then
			continue
		end
		if lastVision.outcome ~= "real" then
			continue
		end
		if lastVision.visibilityEndsAt <= now then
			continue
		end

		local endedVision = self._vision:BuildEndedRealVisionState({
			matchId = matchId,
			spectator = spectator,
			now = now,
			reason = "hunt_started",
		})
		if not endedVision then
			continue
		end
		spectator.lastVision = endedVision
		self._communication:RecordVisionOutcome(matchId, userId, "uncertain")
		local communicationContext = self._communication:GetCommunicationContext(matchId, userId)
		self:_stampSpectatorRuntime(spectator.player, {
			matchId = matchId,
			active = true,
			targetUserId = spectator.targetUserId,
			outcome = endedVision.outcome,
			signalType = endedVision.ghostSignal and endedVision.ghostSignal.type,
			roomId = endedVision.ghostSignal and endedVision.ghostSignal.roomId,
			reliability = endedVision.reliability,
			canTransmitVoice = communicationContext.canTransmitVoice,
			distortionHint = communicationContext.distortionHint,
			isLikelyMisleading = communicationContext.isLikelyMisleading,
			lastEvent = "SpectatorVisionUpdated",
			activityType = "hunt_started",
			reason = endedVision.ghostSignal and endedVision.ghostSignal.reason,
			createdAt = endedVision.createdAt,
			visibilityEndsAt = endedVision.visibilityEndsAt,
		})

		self:_publish("SpectatorVisionUpdated", {
			matchId = matchId,
			player = spectator.player,
			vision = endedVision,
			communication = communicationContext,
		})
	end
end

function SpectatorService:ProcessGhostActivity(matchId, payload)
	local match = self:_getMatch(matchId)
	if not match then
		return 0, "missing_match"
	end

	local now = getNow(payload and payload.now)
	local safePayload = payload or {}

	self:_updatePresenceFromPayload(match, safePayload)
	self:_refreshSpectatorTargets(match)

	if safePayload.activityType == "hunt_started" then
		self:_endRealVisionsForHuntStart(match, matchId, now)
	end

	local ghostState = self:_getGhostState(matchId)
	local eventsPublished = 0
	for spectatorUserId, spectator in pairs(match.spectatorsByUserId) do
		if not spectator.targetUserId then
			continue
		end

		local decision, reason = self._distortionEngine:BuildDecision({
			now = now,
			lastDistortionAt = spectator.lastDistortionAt,
			isNearGhost = self:_isNearGhost(match, spectator, ghostState, safePayload),
		})

		if not decision then
			if reason == "cooldown" then
				continue
			end
			continue
		end

		local generatedSignal = self._ghostGenerator:Generate(decision, {
			matchId = matchId,
			spectator = spectator.player,
			roomIds = match.roomIds,
			observerRoomId = match.playerRooms[spectator.targetUserId],
			ghostState = ghostState,
			activityPayload = safePayload,
			now = now,
		})
		if not generatedSignal then
			continue
		end

		local visionState = self._vision:BuildVisionState({
			matchId = matchId,
			spectator = spectator,
			decision = decision,
			generatedSignal = generatedSignal,
			ghostState = ghostState,
			activityPayload = safePayload,
			now = now,
		})
		if not visionState then
			continue
		end

		spectator.lastDistortionAt = decision.nextAllowedAt
		spectator.lastVision = visionState
		table.insert(spectator.outcomeHistory, decision.outcome)
		self._communication:RecordVisionOutcome(matchId, spectatorUserId, visionState.outcome)

		local communicationContext = self._communication:GetCommunicationContext(matchId, spectatorUserId)
		self:_stampSpectatorRuntime(spectator.player, {
			matchId = matchId,
			active = true,
			targetUserId = spectator.targetUserId,
			outcome = visionState.outcome,
			signalType = visionState.ghostSignal and visionState.ghostSignal.type,
			roomId = visionState.ghostSignal and visionState.ghostSignal.roomId,
			reliability = visionState.reliability,
			canTransmitVoice = communicationContext.canTransmitVoice,
			distortionHint = communicationContext.distortionHint,
			isLikelyMisleading = communicationContext.isLikelyMisleading,
			lastEvent = "SpectatorVisionUpdated",
			activityType = safePayload.activityType,
			reason = decision.outcome,
			createdAt = visionState.createdAt,
			visibilityEndsAt = visionState.visibilityEndsAt,
		})
		self:_publish("SpectatorVisionUpdated", {
			matchId = matchId,
			player = spectator.player,
			vision = visionState,
			communication = communicationContext,
		})

		eventsPublished += 1
	end

	return eventsPublished
end


function SpectatorService:GetSpectators(matchId)
    local match = self:_getMatch(matchId)
    return match and match.spectatorsByUserId or {}
end

function SpectatorService:DistortEvidence(payload)
    return self._distortionEngine:DistortEvidence(payload, self._evidenceTypes)
end

function SpectatorService:IsSpectator(matchId, playerOrUserId)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return false
    end

    local match = self:_getMatch(matchId)
    if not match then
        return false
    end

    if match.spectatorFlagsByUserId and match.spectatorFlagsByUserId[userId] then
        return true
    end

    return match.spectatorsByUserId and match.spectatorsByUserId[userId] ~= nil
end

function SpectatorService:ProcessEvidenceEvent(matchId, payload)
    local match = self:_getMatch(matchId)
    if not match then
        return 0, "missing_match"
    end

    local eventsPublished = 0
    for userId, spectator in pairs(match.spectatorsByUserId) do
        local distortion = self._distortionEngine:DistortEvidence(payload, self._evidenceTypes)
        self:_stampSpectatorRuntime(spectator.player, {
            matchId = matchId,
            active = true,
            targetUserId = spectator.targetUserId,
            outcome = distortion and distortion.outcome,
            signalType = "Evidence",
            reliability = distortion and distortion.outcome == "real" and "high" or "low",
            canTransmitVoice = self._communication:CanTransmitVoice(matchId, userId),
            distortionHint = distortion and distortion.outcome or "unknown",
            isLikelyMisleading = distortion and (distortion.outcome == "fake" or distortion.outcome == "uncertain") or false,
            lastEvent = "SpectatorEvidenceUpdated",
            activityType = "evidence",
            reason = distortion and distortion.payload and distortion.payload.message or nil,
        })
        self:_publish("SpectatorEvidenceUpdated", {
            matchId = matchId,
            player = spectator.player,
            evidence = distortion and distortion.payload or nil,
            outcome = distortion and distortion.outcome or "uncertain",
            roll = distortion and distortion.roll or nil,
        })
        eventsPublished += 1
    end

    return eventsPublished
end
function SpectatorService:GetSpectatorVision(player, matchId)
	local userId = toUserId(player)
	if not userId then
		return nil
	end

	local match = self:_getMatch(matchId)
	if not match then
		return nil
	end

	local spectator = match.spectatorsByUserId[userId]
	if not spectator then
		return nil
	end

	return spectator.lastVision
end

function SpectatorService:GetCommunicationContext(player, matchId)
	local userId = toUserId(player)
	if not userId then
		return nil
	end

	local match = self:_getMatch(matchId)
	if not match or not match.spectatorsByUserId[userId] then
		return nil
	end

	return self._communication:GetCommunicationContext(matchId, userId)
end

return SpectatorService



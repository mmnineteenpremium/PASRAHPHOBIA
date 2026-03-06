local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local function resolveEventBus(deps)
	local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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

local function resolveUserId(player)
	if type(player) == "table" and player.userId then
		return player.userId
	end
	if type(player) == "userdata" and player.UserId then
		return player.UserId
	end
	return nil
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, nestedValue in pairs(value) do
		copy[key] = deepCopy(nestedValue)
	end
	return copy
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = nil
	self._dependencies = {}
	self._batchSize = (self._deps.TelemetryConfig and self._deps.TelemetryConfig.BatchSize) or 25
	return self
end

function Service:Create()
	self._eventBus = resolveEventBus(self._deps)
	self._dependencies = {
		MatchSystem = Services.Get(self._deps, "MatchSystem"),
		ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
		DataPersistenceService = Services.Get(self._deps, "DataPersistenceService"),
		LobbySocialHub = Services.Get(self._deps, "LobbySocialHub"),
	}
end

function Service:Init()
	self._state:Set("matchMetrics", {})
	self._state:Set("playerMetrics", {})
	self._state:Set("timeline", {})
	self._state:Set("eventBuffer", self._state:Get("eventBuffer") or {})
	self._state:Set("telemetryCounters", self._state:Get("telemetryCounters") or {})
end

function Service:Start()
	-- Driven by controller events.
end

function Service:Stop()
	self._state:Clear()
end

function Service:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function Service:_matchMetrics()
	return self._state:Get("matchMetrics") or {}
end

function Service:_setMatchMetrics(metrics)
	self._state:Set("matchMetrics", metrics)
end

function Service:_playerMetrics()
	return self._state:Get("playerMetrics") or {}
end

function Service:_setPlayerMetrics(metrics)
	self._state:Set("playerMetrics", metrics)
end

function Service:_timeline()
	return self._state:Get("timeline") or {}
end

function Service:_setTimeline(timeline)
	self._state:Set("timeline", timeline)
end

function Service:_getOrCreateMatch(matchId)
	local metrics = self:_matchMetrics()
	metrics[matchId] = metrics[matchId] or {
		matchId = matchId,
		startedAt = os.clock(),
		endedAt = nil,
		duration = 0,
		ghostType = nil,
		evidenceDiscovered = {},
		playerDeaths = 0,
		playerCount = 0,
		survivalRate = 1,
		currencyEarned = 0,
	}
	self:_setMatchMetrics(metrics)
	return metrics[matchId]
end

function Service:_getOrCreatePlayer(userId)
	local players = self:_playerMetrics()
	players[userId] = players[userId] or {
		userId = userId,
		matchesPlayed = 0,
		matchesSurvived = 0,
		evidenceFound = 0,
		currencyEarned = 0,
	}
	self:_setPlayerMetrics(players)
	return players[userId]
end

function Service:RecordEvent(eventName, payload)
	local counters = self._state:Get("telemetryCounters") or {}
	counters[eventName] = (counters[eventName] or 0) + 1
	self._state:Set("telemetryCounters", counters)

	local timeline = self:_timeline()
	table.insert(timeline, {
		eventName = eventName,
		payload = deepCopy(payload),
		at = os.clock(),
	})
	self:_setTimeline(timeline)

	local buffer = self._state:Get("eventBuffer") or {}
	table.insert(buffer, {
		eventName = eventName,
		payload = deepCopy(payload),
		at = os.time(),
	})
	self._state:Set("eventBuffer", buffer)

	self:_publish("TelemetryEvent", {
		eventName = eventName,
		payload = payload,
		at = os.clock(),
	})
	self:_publish("TelemetryEventRecorded", {
		eventName = eventName,
		payload = payload,
		at = os.clock(),
	})

	if #buffer >= self._batchSize then
		self:FlushBatch("batch_size_reached")
	end
end

function Service:FlushBatch(reason)
	local buffer = self._state:Get("eventBuffer") or {}
	if #buffer == 0 then
		return false
	end
	local batch = deepCopy(buffer)
	self._state:Set("eventBuffer", {})
	self:_publish("TelemetryBatchSubmitted", {
		reason = reason or "manual_flush",
		count = #batch,
		events = batch,
	})
	return true
end

function Service:OnMatchStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	local match = self:_getOrCreateMatch(matchId)
	match.startedAt = payload.now or os.clock()
	match.playerCount = #(payload.players or {})
	match.duration = 0
	match.endedAt = nil

	for _, player in ipairs(payload.players or {}) do
		local userId = resolveUserId(player)
		if userId then
			local metrics = self:_getOrCreatePlayer(userId)
			metrics.matchesPlayed += 1
		end
	end

	self:RecordEvent("MatchStarted", {
		matchId = matchId,
		playerCount = match.playerCount,
	})
end

function Service:OnGhostSpawned(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	local match = self:_getOrCreateMatch(matchId)
	match.ghostType = payload.ghostType
	self:RecordEvent("GhostTypeSelected", {
		matchId = matchId,
		ghostType = payload.ghostType,
	})
end

function Service:OnEvidenceCollected(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	local match = self:_getOrCreateMatch(matchId)
	local evidenceType = payload.evidenceType or "unknown"
	match.evidenceDiscovered[evidenceType] = (match.evidenceDiscovered[evidenceType] or 0) + 1

	local userId = resolveUserId(payload.player)
	if userId then
		local playerMetrics = self:_getOrCreatePlayer(userId)
		playerMetrics.evidenceFound += 1
	end

	self:RecordEvent("EvidenceDiscovered", {
		matchId = matchId,
		evidenceType = evidenceType,
		playerUserId = userId,
	})
end

function Service:OnPlayerKilled(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	local match = self:_getOrCreateMatch(matchId)
	match.playerDeaths += 1
	self:RecordEvent("PlayerKilled", {
		matchId = matchId,
		playerUserId = resolveUserId(payload.player),
	})
end

function Service:OnRewardsGranted(payload)
	local player = payload and payload.player
	local rewardData = payload and payload.rewardData or {}
	local amount = rewardData.currency or rewardData.amount or 0
	local userId = resolveUserId(player)
	if not userId then
		return
	end
	local metrics = self:_getOrCreatePlayer(userId)
	metrics.currencyEarned += amount
	self:RecordEvent("CurrencyEarned", {
		playerUserId = userId,
		amount = amount,
	})
end

function Service:OnMatchEnded(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	local match = self:_getOrCreateMatch(matchId)
	match.endedAt = payload.now or os.clock()
	match.duration = math.max(0, match.endedAt - (match.startedAt or match.endedAt))
	if match.playerCount > 0 then
		local survived = math.max(0, match.playerCount - match.playerDeaths)
		match.survivalRate = survived / match.playerCount
	end

	local results = payload.results or {}
	match.currencyEarned = results.totalCurrency or results.currencyEarned or match.currencyEarned

	if type(results.survivors) == "table" then
		for _, player in ipairs(results.survivors) do
			local userId = resolveUserId(player)
			if userId then
				local metrics = self:_getOrCreatePlayer(userId)
				metrics.matchesSurvived += 1
			end
		end
	end

	self:RecordEvent("MatchEnded", {
		matchId = matchId,
		matchDuration = match.duration,
		ghostType = match.ghostType,
		survivalRate = match.survivalRate,
		currencyEarned = match.currencyEarned,
	})
	self:FlushBatch("match_ended")
end

function Service:GetMatchMetrics(matchId)
	return deepCopy(self:_matchMetrics()[matchId])
end

function Service:GetPlayerMetrics(userId)
	return deepCopy(self:_playerMetrics()[userId])
end

return Service

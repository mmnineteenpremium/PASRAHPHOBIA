local Service = {}
Service.__index = Service

local DEFAULT_CONFIG = {
	SampleInterval = 5,
	MaxFrameTime = 0.08,
	MaxMemoryMb = 768,
	MaxNetworkEventRate = 120,
	MaxGhostLoad = 200,
	MaxEventLoad = 200,
}

local function resolveEventBus(deps)
	local eventBus = deps.EventBus
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

local function mergeConfig(base, override)
	local merged = {}
	for key, value in pairs(base) do
		merged[key] = value
	end
	for key, value in pairs(override or {}) do
		merged[key] = value
	end
	return merged
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = resolveEventBus(self._deps)
	self._config = mergeConfig(DEFAULT_CONFIG, self._deps.ServerPerformanceConfig)
	self._running = false
	return self
end

function Service:Init()
	self._state:Set("metrics", {
		lastTickAt = os.clock(),
		serverFrameTime = 0,
		serverTickRate = 0,
		memoryMb = 0,
		activeEntities = 0,
		ghostAiLoad = 0,
		eventSystemLoad = 0,
		networkEventRate = 0,
		windowStartedAt = os.clock(),
		windowEvents = 0,
	})
end

function Service:Start()
	self._running = true
	task.spawn(function()
		self:_samplingLoop()
	end)
end

function Service:Stop()
	self._running = false
end

function Service:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function Service:_metrics()
	return self._state:Get("metrics") or {}
end

function Service:_setMetrics(metrics)
	self._state:Set("metrics", metrics)
end

function Service:_samplingLoop()
	while self._running do
		task.wait(self._config.SampleInterval)
		if not self._running then
			break
		end
		self:Sample("periodic")
	end
end

function Service:Sample(reason)
	local metrics = self:_metrics()
	local now = os.clock()
	metrics.memoryMb = (collectgarbage("count") or 0) / 1024
	metrics.activeEntities = (metrics.ghostAiLoad or 0) + (metrics.eventSystemLoad or 0)

	local windowDuration = math.max(1, now - (metrics.windowStartedAt or now))
	metrics.networkEventRate = (metrics.windowEvents or 0) / windowDuration
	metrics.windowStartedAt = now
	metrics.windowEvents = 0

	self:_setMetrics(metrics)
	self:_checkThresholds(metrics, reason or "sample")
	return metrics
end

function Service:_checkThresholds(metrics, reason)
	local warningType = nil
	local value = nil

	if metrics.serverFrameTime > self._config.MaxFrameTime then
		warningType = "frame_time_spike"
		value = metrics.serverFrameTime
	elseif metrics.memoryMb > self._config.MaxMemoryMb then
		warningType = "memory_spike"
		value = metrics.memoryMb
	elseif metrics.networkEventRate > self._config.MaxNetworkEventRate then
		warningType = "network_event_rate_spike"
		value = metrics.networkEventRate
	elseif metrics.ghostAiLoad > self._config.MaxGhostLoad then
		warningType = "ghost_ai_load_spike"
		value = metrics.ghostAiLoad
	elseif metrics.eventSystemLoad > self._config.MaxEventLoad then
		warningType = "event_system_load_spike"
		value = metrics.eventSystemLoad
	end

	if warningType then
		self:_publish("ServerPerformanceWarning", {
			warningType = warningType,
			value = value,
			reason = reason,
			metrics = deepCopy(metrics),
		})
	end
end

function Service:OnPhaseTick(payload)
	local metrics = self:_metrics()
	local now = payload and payload.now or os.clock()
	local last = metrics.lastTickAt or now
	local frameTime = math.max(0.0001, now - last)
	metrics.lastTickAt = now
	metrics.serverFrameTime = frameTime
	metrics.serverTickRate = 1 / frameTime
	metrics.windowEvents = (metrics.windowEvents or 0) + 1
	self:_setMetrics(metrics)
	self:_checkThresholds(metrics, "phase_tick")
end

function Service:AddGhostLoad(amount)
	local metrics = self:_metrics()
	metrics.ghostAiLoad = math.max(0, (metrics.ghostAiLoad or 0) + (amount or 1))
	self:_setMetrics(metrics)
end

function Service:AddEventSystemLoad(amount)
	local metrics = self:_metrics()
	metrics.eventSystemLoad = math.max(0, (metrics.eventSystemLoad or 0) + (amount or 1))
	self:_setMetrics(metrics)
end

function Service:CountNetworkEvent(amount)
	local metrics = self:_metrics()
	metrics.windowEvents = (metrics.windowEvents or 0) + (amount or 1)
	self:_setMetrics(metrics)
end

function Service:GetMetrics()
	return deepCopy(self:_metrics())
end

return Service

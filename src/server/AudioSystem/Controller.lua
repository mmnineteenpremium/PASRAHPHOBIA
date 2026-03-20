local Controller = {}
Controller.__index = Controller

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

function Controller.new(state, service, deps)
	local self = setmetatable({}, Controller)
	self._state = state
	self._service = service
	self._deps = deps or {}
	self._subscriptions = {}
	self._eventBus = resolveEventBus(self._deps)
	return self
end

function Controller:Init()
	-- Event wiring only.
end

function Controller:RegisterEventHandlers()
	if not self._eventBus then
		return
	end
	self:_subscribe("MatchStarted", function(payload)
		self:OnMatchStarted(payload)
	end)
	self:_subscribe("MatchEnded", function(payload)
		self:OnMatchEnded(payload)
	end)
	self:_subscribe("PhaseStarted", function(payload)
		self:OnPhaseStarted(payload)
	end)
	self:_subscribe("EnvironmentEventTriggered", function(payload)
		self:OnEnvironmentEventTriggered(payload)
	end)
	self:_subscribe("GhostInteraction", function(payload)
		self:OnGhostInteraction(payload)
	end)
	self:_subscribe("GhostManifest", function(payload)
		self:OnGhostManifest(payload)
	end)
	self:_subscribe("FearLevelChanged", function(payload)
		self:OnFearLevelChanged(payload)
	end)
	self:_subscribe("HuntStarted", function(payload)
		self:OnHuntStarted(payload)
	end)
	self:_subscribe("HuntEnded", function(payload)
		self:OnHuntEnded(payload)
	end)
end

function Controller:UnregisterEventHandlers()
	if not self._eventBus then
		return
	end
	for _, subscription in ipairs(self._subscriptions) do
		self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
	end
	table.clear(self._subscriptions)
end

function Controller:_subscribe(eventName, callback)
	self._eventBus:Subscribe(eventName, callback)
	table.insert(self._subscriptions, {
		eventName = eventName,
		callback = callback,
	})
end

function Controller:OnMatchStarted(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:StartMatch(matchId)
	end
end

function Controller:OnMatchEnded(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:EndMatch(matchId)
	end
end

function Controller:OnPhaseStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	local phaseName = payload.phaseName
	if phaseName == "Investigation" or phaseName == "InvestigationPhase" then
		self._service:TriggerAmbientAudio(matchId, {
			cue = "ambient_investigation",
			intensity = 0.45,
			now = payload.now,
		})
	elseif phaseName == "Hunt" or phaseName == "HuntPhase" then
		self._service:TriggerHuntAudio(matchId, {
			cue = "hunt_phase_loop",
			intensity = 0.95,
			now = payload.now,
		})
	end
end

function Controller:OnEnvironmentEventTriggered(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:TriggerEnvironmentalAudio(matchId, {
			eventType = payload.eventType,
			roomId = payload.roomId,
			cue = "env_" .. tostring(payload.eventType or "event"),
			intensity = 0.7,
			now = payload.now,
		})
	end
end

function Controller:OnGhostInteraction(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:TriggerGhostAudio(matchId, {
			roomId = payload.room,
			cue = "ghost_interaction",
			intensity = 0.7,
			now = payload.now,
		})
	end
end

function Controller:OnGhostManifest(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:TriggerGhostAudio(matchId, {
			roomId = payload.roomId,
			cue = "ghost_manifest",
			intensity = 0.85,
			now = payload.now,
		})
	end
end

function Controller:OnFearLevelChanged(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	local fearLevel = payload.fearLevel or 0
	self._service:TriggerFearAudio(matchId, {
		cue = fearLevel >= 70 and "fear_critical" or "fear_rise",
		intensity = math.min(1, fearLevel / 100),
		now = payload.now,
	})
end

function Controller:OnHuntStarted(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:TriggerHuntAudio(matchId, {
			cue = "hunt_start",
			intensity = 1.0,
			now = payload.now,
		})
	end
end

function Controller:OnHuntEnded(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:TriggerAmbientAudio(matchId, {
			cue = "post_hunt_calm",
			intensity = 0.4,
			now = payload.now,
		})
	end
end

return Controller

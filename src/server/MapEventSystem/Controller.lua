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

local function isGameplayPhase(phaseName)
	return phaseName == "Investigation"
		or phaseName == "InvestigationPhase"
		or phaseName == "Hunt"
		or phaseName == "HuntPhase"
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
	-- Controller wiring only.
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
	self:_subscribe("GhostSpawned", function(payload)
		self:OnGhostSpawned(payload)
	end)
	self:_subscribe("GhostRoamed", function(payload)
		self:OnGhostRoamed(payload)
	end)
	self:_subscribe("PhaseStarted", function(payload)
		self:OnPhaseStarted(payload)
	end)
	self:_subscribe("GhostInteraction", function(payload)
		self:OnGhostInteraction(payload)
	end)
	self:_subscribe("EnvironmentEventTriggered", function(payload)
		self:OnEnvironmentEventTriggered(payload)
	end)
	self:_subscribe("GhostManifest", function(payload)
		self:OnGhostManifest(payload)
	end)
	self:_subscribe("DirectorTriggeredHunt", function(payload)
		self:OnDirectorTriggeredHunt(payload)
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
	if not matchId then
		return
	end

	self._service:StartMatch(matchId, {
		roomIds = payload.roomIds or payload.rooms,
		roomMeta = payload.roomMeta,
		ghostRoomId = payload.favoriteRoomId,
	})
end

function Controller:OnMatchEnded(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:EndMatch(matchId)
end

function Controller:OnGhostSpawned(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:SetGhostRoom(matchId, payload.favoriteRoomId)
end

function Controller:OnGhostRoamed(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:SetGhostRoom(matchId, payload.room)
end

function Controller:OnPhaseStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId or not isGameplayPhase(payload.phaseName) then
		return
	end
	self._service:MaybeTriggerRandom(matchId, {
		source = "random",
		now = payload.now,
		roomId = payload.roomId,
	})
end

function Controller:OnGhostInteraction(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end

	local eventType = "DoorSlam"
	local interactionType = payload.interactionType
	if interactionType == "Manifest" then
		eventType = "ShadowMovement"
	elseif interactionType == "HuntPressure" then
		eventType = "LightFlicker"
	end

	self._service:TriggerEvent(matchId, eventType, {
		source = "ghost_ai",
		roomId = payload.room,
		now = payload.now,
		bypassProbability = true,
	})
end

function Controller:OnEnvironmentEventTriggered(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	if payload.source == "MapEventSystem" then
		return
	end
	if type(payload.eventType) ~= "string" then
		return
	end

	self._service:TriggerEvent(matchId, payload.eventType, {
		source = payload.source or "external",
		now = payload.now,
		roomId = payload.roomId,
		bypassProbability = true,
		delaySec = payload.delaySec or 0.1,
	})
end

function Controller:OnGhostManifest(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:TriggerEvent(matchId, "ShadowMovement", {
		source = "horror_director",
		now = payload.now,
		roomId = payload.roomId,
		bypassProbability = true,
	})
end

function Controller:OnDirectorTriggeredHunt(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:TriggerEvent(matchId, "LightFlicker", {
		source = "horror_director",
		now = payload.now,
		bypassProbability = true,
	})
end

return Controller

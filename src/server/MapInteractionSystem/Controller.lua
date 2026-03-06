local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
	local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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
	self._handlersRegistered = false
	return self
end

function Controller:Init()
	-- Controller wiring only.
end

function Controller:RegisterEventHandlers()
	if not self._eventBus or self._handlersRegistered then
		return
	end

	self:_subscribe("MatchStarted", function(payload)
		self:OnMatchStarted(payload)
	end)
	self:_subscribe("MatchEnded", function(payload)
		self:OnMatchEnded(payload)
	end)
	self:_subscribe("EnvironmentEventTriggered", function(payload)
		self:OnEnvironmentEventTriggered(payload)
	end)
	self:_subscribe("GhostInteraction", function(payload)
		self:OnGhostInteraction(payload)
	end)
	self:_subscribe("HuntStarted", function(payload)
		self:OnHuntStarted(payload)
	end)
	self:_subscribe("HuntEnded", function(payload)
		self:OnHuntEnded(payload)
	end)
	self:_subscribe("DirectorTensionChanged", function(payload)
		self:OnDirectorTensionChanged(payload)
	end)
	self:_subscribe("FearLevelChanged", function(payload)
		self:OnFearLevelChanged(payload)
	end)
	self:_subscribe("GhostPersonalityAssigned", function(payload)
		self:OnGhostPersonalityAssigned(payload)
	end)
	self:_subscribe("GhostPersonalitySelected", function(payload)
		self:OnGhostPersonalitySelected(payload)
	end)
	self._handlersRegistered = true
end

function Controller:UnregisterEventHandlers()
	if not self._eventBus or not self._handlersRegistered then
		return
	end
	for _, subscription in ipairs(self._subscriptions) do
		self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
	end
	table.clear(self._subscriptions)
	self._handlersRegistered = false
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
	})
end

function Controller:OnMatchEnded(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:EndMatch(matchId)
end

function Controller:OnEnvironmentEventTriggered(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	if payload.source and payload.source ~= "MapEventSystem" then
		return
	end
	self._service:HandleHorrorEvent(matchId, payload.eventType, payload)
end

function Controller:OnGhostInteraction(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	local interactionType = payload.interactionType
	if interactionType == "Manifest" then
		self._service:FlickerLights(matchId, payload.room, {
			state = "overload",
			source = "ghost_ai",
			now = payload.now,
		})
	elseif interactionType == "HuntPressure" then
		self._service:DisturbElectronics(matchId, "global_radio", "tv_glitch", {
			roomId = payload.room,
			source = "ghost_ai",
			now = payload.now,
		})
	else
		self._service:SlamDoor(matchId, "nearby_door", {
			roomId = payload.room,
			source = "ghost_ai",
			now = payload.now,
		})
	end
end

function Controller:OnHuntStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:SetDoorLock(matchId, "all_doors", true, {
		source = "hunt",
		now = payload.now,
	})
end

function Controller:OnHuntEnded(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:SetDoorLock(matchId, "all_doors", false, {
		source = "hunt",
		now = payload.now,
	})
end

function Controller:OnDirectorTensionChanged(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:UpdateTension(matchId, payload.tension, payload.now)
end

function Controller:OnFearLevelChanged(payload)
	if payload and payload.global == true then
		return
	end
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:UpdateFearLevel(matchId, payload.fearLevel, payload.now)
end

function Controller:OnGhostPersonalityAssigned(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:UpdateGhostPersonality(matchId, {
		name = payload.personality,
		huntThreshold = payload.huntThreshold,
		eventFrequency = payload.eventFrequency,
		fakeEvidenceChance = payload.fakeEvidenceChance,
	}, payload.now)
end

function Controller:OnGhostPersonalitySelected(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	local personalityType = payload and (payload.personalityType or (payload.personality and payload.personality.type))
	self._service:UpdateGhostPersonality(matchId, {
		name = personalityType,
		eventFrequency = 1.0,
	}, payload and payload.now)
end

return Controller

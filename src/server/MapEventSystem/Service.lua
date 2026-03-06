local EventRegistry = require(script.Parent.Modules.EventRegistry)
local EventEngine = require(script.Parent.Modules.EventEngine)

local Service = {}
Service.__index = Service

local DEFAULT_CONFIG = {
	RandomTriggerChance = 0.04,
	DefaultRooms = { "RoomA", "RoomB", "RoomC", "RoomD" },
}

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

local function merge(base, override)
	local merged = deepCopy(base)
	for key, value in pairs(override or {}) do
		if type(value) == "table" and type(merged[key]) == "table" then
			merged[key] = merge(merged[key], value)
		else
			merged[key] = value
		end
	end
	return merged
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = resolveEventBus(self._deps)
	self._rng = self._deps.Random or Random.new()
	self._config = merge(DEFAULT_CONFIG, self._deps.MapEventConfig or {})
	self._registry = EventRegistry.new(self._config.Registry)
	self._engine = EventEngine.new(self._registry, self._rng)
	return self
end

function Service:Init()
	self._state:Set("sessions", {})
	self._state:Set("nextEventId", 1)
end

function Service:Start()
	-- Driven by controller events.
end

function Service:Stop()
	self._state:Set("sessions", {})
	self._state:Set("nextEventId", 1)
end

function Service:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function Service:_sessions()
	return self._state:Get("sessions") or {}
end

function Service:_setSessions(sessions)
	self._state:Set("sessions", sessions)
end

function Service:_newEventId()
	local id = self._state:Get("nextEventId") or 1
	self._state:Set("nextEventId", id + 1)
	return id
end

function Service:_getOrCreateSession(matchId, payload)
	local sessions = self:_sessions()
	local session = sessions[matchId]
	if session then
		return session
	end

	session = {
		matchId = matchId,
		roomIds = payload and payload.roomIds or self._config.DefaultRooms,
		roomMeta = payload and payload.roomMeta or {},
		ghostRoomId = payload and payload.ghostRoomId or nil,
		cooldowns = {},
		activeEvents = {},
	}
	sessions[matchId] = session
	self:_setSessions(sessions)
	return session
end

function Service:StartMatch(matchId, payload)
	if not matchId then
		return nil, "invalid_arguments"
	end
	return self:_getOrCreateSession(matchId, payload)
end

function Service:EndMatch(matchId)
	local sessions = self:_sessions()
	sessions[matchId] = nil
	self:_setSessions(sessions)
end

function Service:SetGhostRoom(matchId, roomId)
	local session = self:_getOrCreateSession(matchId)
	session.ghostRoomId = roomId
end

function Service:SetRooms(matchId, roomIds, roomMeta)
	local session = self:_getOrCreateSession(matchId)
	if type(roomIds) == "table" and #roomIds > 0 then
		session.roomIds = roomIds
	end
	if type(roomMeta) == "table" then
		session.roomMeta = roomMeta
	end
end

function Service:TriggerEvent(matchId, eventType, payload)
	if not matchId then
		return nil, "invalid_arguments"
	end

	local session = self:_getOrCreateSession(matchId, payload)
	local now = payload and payload.now or os.clock()
	session.now = now

	local selectedType = self._engine:SelectEventType(session, eventType)
	if not selectedType then
		return nil, "no_event_available"
	end

	local canTrigger, reason = self._engine:CanTrigger(session, selectedType, payload and payload.bypassProbability)
	if not canTrigger then
		return nil, reason
	end

	local roomId = self._engine:SelectLocation(session, selectedType, payload)
	local duration = payload and payload.duration or self._engine:GetDuration(selectedType)
	local cooldown = payload and payload.cooldown or self._engine:GetCooldown(selectedType)
	local delaySec = payload and payload.delaySec or 0
	local eventId = self:_newEventId()

	session.cooldowns[selectedType] = now + cooldown
	local eventRecord = {
		eventId = eventId,
		eventType = selectedType,
		roomId = roomId,
		startedAt = now + delaySec,
		endsAt = now + delaySec + duration,
		triggerSource = payload and payload.source or "MapEventSystem",
	}
	session.activeEvents[eventId] = eventRecord

	task.delay(delaySec, function()
		local sessions = self:_sessions()
		local activeSession = sessions[matchId]
		if not activeSession then
			return
		end
		if not activeSession.activeEvents[eventId] then
			return
		end

		self:_publish("EnvironmentEventTriggered", {
			matchId = matchId,
			eventId = eventId,
			eventType = selectedType,
			roomId = roomId,
			source = "MapEventSystem",
			triggerSource = eventRecord.triggerSource,
		})
		self:_publish("MapEventStarted", {
			matchId = matchId,
			eventId = eventId,
			eventType = selectedType,
			roomId = roomId,
		})

		task.delay(duration, function()
			self:EndEvent(matchId, eventId)
		end)
	end)

	return eventRecord
end

function Service:GetActiveEvents(matchId)
	local sessions = self:_sessions()
	local session = sessions[matchId]
	if not session then
		return {}
	end

	local events = {}
	for _, eventRecord in pairs(session.activeEvents) do
		table.insert(events, deepCopy(eventRecord))
	end
	table.sort(events, function(a, b)
		return a.eventId < b.eventId
	end)
	return events
end

function Service:EndEvent(matchId, eventTypeOrId)
	local sessions = self:_sessions()
	local session = sessions[matchId]
	if not session then
		return false
	end

	local foundId = nil
	local foundEvent = nil
	for eventId, eventRecord in pairs(session.activeEvents) do
		if eventId == eventTypeOrId or eventRecord.eventType == eventTypeOrId then
			foundId = eventId
			foundEvent = eventRecord
			break
		end
	end
	if not foundId then
		return false
	end

	session.activeEvents[foundId] = nil
	self:_publish("MapEventEnded", {
		matchId = matchId,
		eventId = foundId,
		eventType = foundEvent.eventType,
		roomId = foundEvent.roomId,
	})
	return true
end

function Service:MaybeTriggerRandom(matchId, payload)
	local roll = self._rng:NextNumber()
	if roll > self._config.RandomTriggerChance then
		return nil, "random_miss"
	end
	return self:TriggerEvent(matchId, nil, payload)
end

return Service

local Service = {}
Service.__index = Service

local DoorInteraction = require(script.Parent.DoorInteraction)
local LightInteraction = require(script.Parent.LightInteraction)
local ObjectMovement = require(script.Parent.ObjectMovement)
local ElectronicDisturbance = require(script.Parent.ElectronicDisturbance)
local HorrorEvents = require(script.Parent.HorrorEvents)
local EventScheduler = require(script.Parent.EventScheduler)

local DEFAULT_CONFIG = {
	UpdateIntervalSeconds = 2.0,
	MinInteractionCooldownSeconds = 1.0,
	MinSchedulerIntervalSeconds = 6.0,
	MaxSchedulerIntervalSeconds = 16.0,
	BaseSchedulerChance = 0.12,
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

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = resolveEventBus(self._deps)
	self._rng = self._deps.Random or Random.new()
	self._config = {}
	for key, value in pairs(DEFAULT_CONFIG) do
		self._config[key] = value
	end
	for key, value in pairs(self._deps.MapInteractionConfig or {}) do
		self._config[key] = value
	end
	self._door = DoorInteraction.new()
	self._lights = LightInteraction.new()
	self._objects = ObjectMovement.new()
	self._electronics = ElectronicDisturbance.new()
	self._horrorEvents = HorrorEvents.new()
	self._scheduler = EventScheduler.new(self._rng, self._config)
	self._loopRunning = false
	self._loopToken = 0
	self._loopThread = nil
	return self
end

function Service:Init()
	self._state:Set("sessions", {})
end

function Service:Start()
	self:_startLoop()
end

function Service:Stop()
	self:_stopLoop()
	self._state:Set("sessions", {})
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

function Service:_getOrCreateSession(matchId, payload)
	local sessions = self:_sessions()
	local session = sessions[matchId]
	if session then
		return session
	end

	session = {
		matchId = matchId,
		doors = {},
		lights = {},
		objects = {},
		electronics = {},
		roomIds = payload and payload.roomIds or {},
		tension = 0,
		fearLevel = 0,
		personality = nil,
		nextScheduledAt = 0,
		nextInteractionAt = {},
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

function Service:OpenDoor(matchId, doorId, payload)
	local session = self:_getOrCreateSession(matchId)
	local state = self._door:Open(session, doorId, payload)
	return deepCopy(state)
end

function Service:SlamDoor(matchId, doorId, payload)
	local session = self:_getOrCreateSession(matchId)
	local state, id = self._door:Slam(session, doorId, payload)

	self:_publish("DoorSlammed", {
		matchId = matchId,
		doorId = id,
		roomId = payload and payload.roomId,
		source = payload and payload.source or "MapInteractionSystem",
	})
	return deepCopy(state)
end

function Service:SetDoorLock(matchId, doorId, isLocked, payload)
	local session = self:_getOrCreateSession(matchId)
	local state = self._door:SetLock(session, doorId, isLocked, payload)
	return deepCopy(state)
end

function Service:FlickerLights(matchId, roomId, payload)
	local session = self:_getOrCreateSession(matchId)
	local state, id = self._lights:Flicker(session, roomId, payload)

	self:_publish("LightsFlickered", {
		matchId = matchId,
		roomId = id,
		mode = state.state,
		source = payload and payload.source or "MapInteractionSystem",
	})
	return deepCopy(state)
end

function Service:MoveObject(matchId, objectId, mode, payload)
	local session = self:_getOrCreateSession(matchId)
	local state, id = self._objects:Move(session, objectId, mode, payload)

	self:_publish("ObjectMoved", {
		matchId = matchId,
		objectId = id,
		mode = state.mode,
		roomId = state.roomId,
		source = payload and payload.source or "MapInteractionSystem",
	})
	return deepCopy(state)
end

function Service:DisturbElectronics(matchId, targetId, mode, payload)
	local session = self:_getOrCreateSession(matchId)
	local state, id = self._electronics:Disturb(session, targetId, mode, payload)

	self:_publish("ElectronicDisturbance", {
		matchId = matchId,
		targetId = id,
		mode = state.mode,
		roomId = state.roomId,
		source = payload and payload.source or "MapInteractionSystem",
	})
	return deepCopy(state)
end

function Service:HandleHorrorEvent(matchId, eventType, payload)
	local now = payload and payload.now or os.clock()
	local session = self:_getOrCreateSession(matchId, payload)
	local interactionType = eventType or "UnknownEvent"
	local nextAt = session.nextInteractionAt[interactionType] or 0
	if payload and payload.bypassThrottle ~= true and now < nextAt then
		return nil, "cooldown"
	end
	session.nextInteractionAt[interactionType] = now + self._config.MinInteractionCooldownSeconds

	local resolved = self._horrorEvents:Resolve(eventType, payload)
	if not resolved then
		return nil, "unknown_event"
	end
	local source = payload and payload.source or "MapInteractionSystem"
	if resolved.action == "lights" then
		self:FlickerLights(matchId, resolved.roomId, {
			state = resolved.state,
			source = source,
			now = now,
		})
	elseif resolved.action == "door_slam" then
		self:SlamDoor(matchId, resolved.doorId, {
			roomId = resolved.roomId,
			source = source,
			now = now,
		})
	elseif resolved.action == "object_move" then
		self:MoveObject(matchId, resolved.objectId, resolved.mode, {
			roomId = resolved.roomId,
			source = source,
			now = now,
		})
	elseif resolved.action == "electronic" then
		self:DisturbElectronics(matchId, resolved.targetId, resolved.mode, {
			roomId = resolved.roomId,
			source = source,
			now = now,
		})
	end

	self:_publish("HorrorEventTriggered", {
		matchId = matchId,
		eventType = eventType,
		roomId = resolved.roomId,
		source = source,
		now = now,
	})
	return true
end

function Service:UpdateTension(matchId, tension, now)
	local session = self:_getOrCreateSession(matchId, { now = now })
	if type(tension) == "number" then
		session.tension = math.clamp(tension, 0, 100)
	end
end

function Service:UpdateFearLevel(matchId, fearLevel, now)
	local session = self:_getOrCreateSession(matchId, { now = now })
	if type(fearLevel) == "number" then
		session.fearLevel = math.clamp(fearLevel, 0, 100)
	end
end

function Service:UpdateGhostPersonality(matchId, personality, now)
	local session = self:_getOrCreateSession(matchId, { now = now })
	session.personality = personality
end

function Service:_runScheduler(session, now)
	if not self._scheduler:ShouldTrigger(session, now) then
		return
	end

	local eventType = self._scheduler:PickEventType(session)
	self:HandleHorrorEvent(session.matchId, eventType, {
		source = "MapInteractionScheduler",
		now = now,
	})
end

function Service:_startLoop()
	if self._loopRunning then
		return
	end
	self._loopRunning = true
	self._loopToken += 1
	local token = self._loopToken
	self._loopThread = task.spawn(function()
		while self._loopRunning and token == self._loopToken do
			local now = os.clock()
			for _, session in pairs(self:_sessions()) do
				self:_runScheduler(session, now)
			end
			task.wait(self._config.UpdateIntervalSeconds)
		end
	end)
end

function Service:_stopLoop()
	self._loopRunning = false
	self._loopToken += 1
	if self._loopThread then
		task.cancel(self._loopThread)
		self._loopThread = nil
	end
end

return Service

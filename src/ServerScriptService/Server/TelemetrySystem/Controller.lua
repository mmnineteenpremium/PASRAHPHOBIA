local Services = require(script.Parent.Parent.Core.Services)

local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
	local eventBus = Services.Get(deps, "EventBus")
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
	self._eventBus = nil
	self._registered = false
	return self
end

function Controller:Create()
	self._eventBus = resolveEventBus(self._deps)
end

function Controller:Init()
	-- Wiring only.
end

function Controller:Start()
	self:RegisterEventHandlers()
end

function Controller:Stop()
	self:UnregisterEventHandlers()
end

function Controller:RegisterEventHandlers()
    if not self._eventBus or self._registered then
        return
    end
    self:_subscribe("MatchStarted", function(payload)
        self._service:CaptureMatchStart(
            payload and payload.matchId,
            payload and payload.mapId,
            payload and (payload.mode or payload.gameMode),
            payload and (payload.difficulty or (payload.difficultyProfile and payload.difficultyProfile.name))
        )
    end)
    self:_subscribe("MatchEnded", function(payload)
        self._service:CaptureMatchEnd(payload and payload.matchId, payload and (payload.results or payload))
    end)
    self:_subscribe("EvidenceCollected", function(payload)
        local userId = payload and (payload.userId or (payload.player and payload.player.UserId))
        self._service:CaptureEvidenceFound(payload and payload.matchId, userId, payload and payload.evidenceType)
    end)
    self:_subscribe("HuntStarted", function(payload)
        self._service:CaptureHuntTriggered(payload and payload.matchId, payload and payload.aggression, payload and payload.averageSanity)
    end)
    self:_subscribe("PlayerDied", function(payload)
        local userId = payload and (payload.userId or payload.playerId or (payload.player and payload.player.UserId))
        self._service:CapturePlayerDeath(payload and payload.matchId, userId, payload and payload.reason)
    end)
    self:_subscribe("LevelUp", function(payload)
        self._service:CaptureLevelUp(payload and payload.userId, payload and payload.newLevel)
    end)
    self._registered = true
end

function Controller:UnregisterEventHandlers()
	if not self._eventBus or not self._registered then
		return
	end
	for _, subscription in ipairs(self._subscriptions) do
		self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
	end
	table.clear(self._subscriptions)
	self._registered = false
end

function Controller:_subscribe(eventName, callback)
	self._eventBus:Subscribe(eventName, callback)
	table.insert(self._subscriptions, {
		eventName = eventName,
		callback = callback,
	})
end

return Controller

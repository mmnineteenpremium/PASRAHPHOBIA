local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEFAULT_INTERACTION_COOLDOWN = 0.75

local STATE_BY_INTERACTION = {
	Open = "Open",
	Close = "Closed",
	Slam = "Slammed",
	Knock = "Knocked",
	TurnOn = "On",
	TurnOff = "Off",
	Flicker = "Flickering",
	Move = "Moved",
	Throw = "Thrown",
	Rotate = "Rotated",
	PlayNoise = "PlayingNoise",
	StaticDistortion = "Static",
}

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

local function listToSet(list)
	local out = {}
	for _, value in ipairs(list or {}) do
		if type(value) == "string" then
			out[value] = true
		end
	end
	return out
end

local function normalizeObjectData(objectData)
	if type(objectData) ~= "table" then
		return nil, "invalid_object_data"
	end

	local objectId = objectData.id or objectData.objectId
	if type(objectId) ~= "string" or objectId == "" then
		return nil, "invalid_object_id"
	end

	local objectType = objectData.type or objectData.objectType
	if type(objectType) ~= "string" or objectType == "" then
		return nil, "invalid_object_type"
	end

	local interactions = objectData.interactions
	if type(interactions) ~= "table" then
		return nil, "invalid_interactions"
	end

	return {
		id = objectId,
		type = objectType,
		position = objectData.position,
		roomId = objectData.roomId,
		metadata = type(objectData.metadata) == "table" and objectData.metadata or {},
		interactions = interactions,
		interactionSet = listToSet(interactions),
	}, nil
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = nil
	self._dependencies = {}
	return self
end

function Service:Create()
	self._eventBus = resolveEventBus(self._deps)
	self._dependencies = {
		GhostSystem = Services.Get(self._deps, "GhostSystem"),
		EvidenceSystem = Services.Get(self._deps, "EvidenceSystem"),
		HorrorDirector = Services.Get(self._deps, "HorrorDirector"),
		MatchSystem = Services.Get(self._deps, "MatchSystem"),
	}
end

function Service:Init()
	self._state:Set("registeredObjects", {})
	self._state:Set("objectStates", {})
	self._state:Set("interactionCooldowns", {})
	self._state:Set("activeMatchId", nil)
end

function Service:Start()
	-- Event-driven system.
end

function Service:Stop()
	self._state:Clear()
end

function Service:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function Service:_getRegisteredObjects()
	return self._state:Get("registeredObjects") or {}
end

function Service:_getObjectStates()
	return self._state:Get("objectStates") or {}
end

function Service:_getCooldowns()
	return self._state:Get("interactionCooldowns") or {}
end

function Service:_setObjectStateInternal(objectId, newState)
	local states = self:_getObjectStates()
	states[objectId] = newState
	self._state:Set("objectStates", states)
end

function Service:RegisterObject(objectData)
	local normalized, err = normalizeObjectData(objectData)
	if not normalized then
		return false, err
	end

	local registeredObjects = self:_getRegisteredObjects()
	registeredObjects[normalized.id] = normalized
	self._state:Set("registeredObjects", registeredObjects)

	local currentStates = self:_getObjectStates()
	if currentStates[normalized.id] == nil then
		currentStates[normalized.id] = "Idle"
		self._state:Set("objectStates", currentStates)
	end

	return true
end

function Service:GetObject(objectId)
	if type(objectId) ~= "string" or objectId == "" then
		return nil
	end
	return self:_getRegisteredObjects()[objectId]
end

function Service:ListObjects()
	local out = {}
	for _, objectData in pairs(self:_getRegisteredObjects()) do
		out[#out + 1] = objectData
	end
	table.sort(out, function(a, b)
		return tostring(a.id) < tostring(b.id)
	end)
	return out
end

function Service:UpdateObjectState(objectId, newState, metadata)
	local objectData = self:GetObject(objectId)
	if not objectData then
		return false, "object_not_found"
	end

	local states = self:_getObjectStates()
	local previousState = states[objectId]
	states[objectId] = newState
	self._state:Set("objectStates", states)

	self:_publish("MapObjectStateChanged", {
		matchId = self._state:Get("activeMatchId"),
		objectId = objectId,
		objectType = objectData.type,
		previousState = previousState,
		newState = newState,
		metadata = metadata,
	})

	return true
end

function Service:ExecuteInteraction(objectId, interactionType, context)
	local objectData = self:GetObject(objectId)
	if not objectData then
		return false, "object_not_found"
	end
	if type(interactionType) ~= "string" or interactionType == "" then
		return false, "invalid_interaction"
	end
	if objectData.interactionSet[interactionType] ~= true then
		return false, "interaction_not_supported"
	end

	local nowTime = (type(context) == "table" and context.now) or os.clock()
	local cooldownKey = string.format("%s:%s", objectId, interactionType)
	local cooldowns = self:_getCooldowns()
	local nextAllowedTime = cooldowns[cooldownKey] or 0
	if nowTime < nextAllowedTime then
		return false, "interaction_on_cooldown"
	end
	cooldowns[cooldownKey] = nowTime + DEFAULT_INTERACTION_COOLDOWN
	self._state:Set("interactionCooldowns", cooldowns)

	local stateName = STATE_BY_INTERACTION[interactionType] or interactionType
	self:UpdateObjectState(objectId, stateName, {
		interactionType = interactionType,
		source = context and context.source or "MapInteractionSystem",
	})

	self:_publish("MapObjectInteracted", {
		matchId = self._state:Get("activeMatchId"),
		objectId = objectId,
		objectType = objectData.type,
		interactionType = interactionType,
		position = objectData.position,
		source = context and context.source or "MapInteractionSystem",
	})

	return true
end

function Service:OnMatchStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end

	self._state:ResetForMatch(matchId)

	local objects = payload.objects or payload.mapObjects or payload.registeredObjects
	if type(objects) ~= "table" then
		return
	end

	for _, objectData in ipairs(objects) do
		self:RegisterObject(objectData)
	end
end

function Service:OnGhostInteraction(payload)
	local matchId = payload and payload.matchId
	if self._state:Get("activeMatchId") ~= matchId then
		return
	end

	local objectId = payload.objectId or payload.targetId
	local action = payload.action or payload.interactionType
	if type(objectId) ~= "string" or type(action) ~= "string" then
		return
	end
	self:ExecuteInteraction(objectId, action, {
		now = payload.now,
		source = "GhostSystem",
	})
end

function Service:OnDirectorEvent(payload)
	local matchId = payload and payload.matchId
	if self._state:Get("activeMatchId") ~= matchId then
		return
	end

	local objectId = payload.objectId or payload.targetId
	local action = payload.action or payload.interactionType or payload.eventType
	if type(objectId) ~= "string" or type(action) ~= "string" then
		return
	end
	self:ExecuteInteraction(objectId, action, {
		now = payload.now,
		source = "HorrorDirector",
	})
end

function Service:OnMatchEnded(payload)
	local matchId = payload and payload.matchId
	if self._state:Get("activeMatchId") ~= matchId then
		return
	end
	self._state:Clear()
end

return Service

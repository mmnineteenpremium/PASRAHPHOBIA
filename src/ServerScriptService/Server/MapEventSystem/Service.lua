local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local EVENT_LIBRARY = {
	{ eventType = "DoorSlam", interaction = "Slam", objectType = "Door", baseIntensity = 0.55, cooldown = 4 },
	{ eventType = "ObjectThrow", interaction = "Throw", objectType = "Object", baseIntensity = 0.65, cooldown = 6 },
	{ eventType = "LightFlicker", interaction = "Flicker", objectType = "Light", baseIntensity = 0.50, cooldown = 3 },
	{ eventType = "WindowKnock", interaction = "Knock", objectType = "Window", baseIntensity = 0.40, cooldown = 5 },
	{ eventType = "RadioStatic", interaction = "StaticDistortion", objectType = "Radio", baseIntensity = 0.35, cooldown = 5 },
	{ eventType = "ShadowApparition", interaction = nil, objectType = nil, baseIntensity = 0.75, cooldown = 8 },
	{ eventType = "FootstepSound", interaction = nil, objectType = nil, baseIntensity = 0.45, cooldown = 4 },
	{ eventType = "SuddenWhisper", interaction = nil, objectType = nil, baseIntensity = 0.50, cooldown = 4 },
	{ eventType = "TemperatureDrop", interaction = nil, objectType = nil, baseIntensity = 0.60, cooldown = 6 },
}

local EVENT_TYPE_ALIASES = {
	ObjectMovement = "ObjectThrow",
	RadioNoise = "RadioStatic",
	ShadowMovement = "ShadowApparition",
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

local function findEventConfig(eventType)
	eventType = EVENT_TYPE_ALIASES[eventType] or eventType
	for _, config in ipairs(EVENT_LIBRARY) do
		if config.eventType == eventType then
			return config
		end
	end
	return nil
end

local function resolveMapInteractionSystem(deps)
	local interactionSystem = Services.Get(deps, "MapInteractionSystem")
	if type(interactionSystem) ~= "table" then
		local registry = rawget(_G, "SystemRegistry")
		if type(registry) == "table" then
			if type(registry.Get) == "function" then
				interactionSystem = registry:Get("MapInteractionSystem")
			elseif type(registry.GetService) == "function" then
				interactionSystem = registry:GetService("MapInteractionSystem")
			end
		end
	end
	return type(interactionSystem) == "table" and interactionSystem or nil
end

local function safeCall(target, methodName, ...)
	if type(target) ~= "table" then
		return nil
	end
	local method = target[methodName]
	if type(method) ~= "function" then
		return nil
	end
	local ok, result = pcall(method, target, ...)
	if not ok then
		return nil
	end
	return result
end

local function isGameplayPhase(phaseName)
	return phaseName == "Investigation"
		or phaseName == "InvestigationPhase"
		or phaseName == "Hunt"
		or phaseName == "HuntPhase"
end

local function pickFromArray(rng, list)
	if type(list) ~= "table" or #list == 0 then
		return nil
	end
	return list[rng:NextInteger(1, #list)]
end

local function listRegisteredObjects(mapInteractionSystem)
	if type(mapInteractionSystem) ~= "table" then
		return {}
	end
	if type(mapInteractionSystem.ListObjects) == "function" then
		return mapInteractionSystem:ListObjects()
	end
	if type(mapInteractionSystem.Service) == "table" and type(mapInteractionSystem.Service.ListObjects) == "function" then
		return mapInteractionSystem.Service:ListObjects()
	end
	return {}
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = nil
	self._rng = self._deps.Random or Random.new()
	self._dependencies = {}
	return self
end

function Service:Create()
	self._eventBus = resolveEventBus(self._deps)
	self._dependencies = {
		MapInteractionSystem = Services.Get(self._deps, "MapInteractionSystem"),
		GhostSystem = Services.Get(self._deps, "GhostSystem"),
		HorrorDirector = Services.Get(self._deps, "HorrorDirector"),
		SanitySystem = Services.Get(self._deps, "SanitySystem"),
		AggressionSystem = Services.Get(self._deps, "AggressionSystem"),
		MatchSystem = Services.Get(self._deps, "MatchSystem"),
	}
end

function Service:Init()
	self._state:Set("activeEvents", {})
	self._state:Set("eventCooldowns", {})
	self._state:Set("eventHistory", {})
	self._state:Set("activeMatchId", nil)
	self._state:Set("currentPhase", "Lobby")
	self._state:Set("lastSanity", 100)
	self._state:Set("lastAggression", 0)
	self._state:Set("lastDirectorIntensity", 0)
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

function Service:_baseContext()
	return {
		matchId = self._state:Get("activeMatchId"),
		phase = self._state:Get("currentPhase"),
		sanity = self._state:Get("lastSanity") or 100,
		aggression = self._state:Get("lastAggression") or 0,
		directorIntensity = self._state:Get("lastDirectorIntensity") or 0,
		now = os.clock(),
	}
end

function Service:ValidateEventConditions(eventData)
	if type(eventData) ~= "table" then
		return false, "invalid_event_data"
	end

	local matchId = eventData.matchId or self._state:Get("activeMatchId")
	if not matchId or matchId ~= self._state:Get("activeMatchId") then
		return false, "invalid_match"
	end

	local phase = eventData.phase or self._state:Get("currentPhase")
	if not isGameplayPhase(phase) then
		return false, "invalid_phase"
	end

	local eventType = eventData.eventType
	if type(eventType) ~= "string" or findEventConfig(eventType) == nil then
		return false, "invalid_event_type"
	end

	local cooldowns = self._state:Get("eventCooldowns") or {}
	local nowTime = eventData.now or os.clock()
	local nextAllowedTime = cooldowns[eventType] or 0
	if nowTime < nextAllowedTime then
		return false, "event_on_cooldown"
	end

	return true
end

function Service:SelectRandomEvent(context)
	local sanity = math.clamp(tonumber(context.sanity) or 100, 0, 100)
	local aggression = math.clamp(tonumber(context.aggression) or 0, 0, 100)
	local tension = math.clamp(tonumber(context.directorIntensity) or 0, 0, 100)

	local score = ((100 - sanity) * 0.4) + (aggression * 0.35) + (tension * 0.25)

	if score < 25 then
		return pickFromArray(self._rng, { "FootstepSound", "WindowKnock", "SuddenWhisper" })
	end
	if score < 50 then
		return pickFromArray(self._rng, { "LightFlicker", "DoorSlam", "RadioStatic", "TemperatureDrop" })
	end
	if score < 75 then
		return pickFromArray(self._rng, { "ObjectThrow", "DoorSlam", "LightFlicker", "ShadowApparition" })
	end
	return pickFromArray(self._rng, { "ShadowApparition", "ObjectThrow", "TemperatureDrop", "DoorSlam" })
end

function Service:ApplyEventEffect(eventData)
	local mapInteractionSystem = self._dependencies.MapInteractionSystem or resolveMapInteractionSystem(self._deps)
	self._dependencies.MapInteractionSystem = mapInteractionSystem
	local eventConfig = findEventConfig(eventData.eventType)

	if not eventConfig or not eventConfig.interaction then
		return true
	end

	if type(mapInteractionSystem) ~= "table" then
		return true
	end

	local targetObject = eventData.targetObject
	if type(targetObject) ~= "string" or targetObject == "" then
		return true
	end

	local ok, result = pcall(function()
		if type(mapInteractionSystem.ExecuteInteraction) == "function" then
			return mapInteractionSystem:ExecuteInteraction(targetObject, eventConfig.interaction)
		end
		if type(mapInteractionSystem.Service) == "table"
			and type(mapInteractionSystem.Service.ExecuteInteraction) == "function" then
			return mapInteractionSystem.Service:ExecuteInteraction(targetObject, eventConfig.interaction, {
				source = "MapEventSystem",
				now = eventData.now,
			})
		end
		return true
	end)
	if not ok then
		return false, "interaction_apply_failed"
	end

	if result == false then
		return false, "interaction_rejected"
	end
	return true
end

function Service:_resolveTargetObject(eventData, eventConfig)
	if type(eventData.targetObject) == "string" and eventData.targetObject ~= "" then
		return eventData.targetObject, eventData.roomId
	end
	if not eventConfig or not eventConfig.objectType then
		return nil, eventData.roomId
	end

	local candidates = {}
	local roomScoped = {}
	local mapInteractionSystem = self._dependencies.MapInteractionSystem or resolveMapInteractionSystem(self._deps)
	self._dependencies.MapInteractionSystem = mapInteractionSystem
	for _, objectData in ipairs(listRegisteredObjects(mapInteractionSystem)) do
		if type(objectData) == "table" and objectData.type == eventConfig.objectType then
			candidates[#candidates + 1] = objectData
			if type(eventData.roomId) == "string" and eventData.roomId ~= "" and objectData.roomId == eventData.roomId then
				roomScoped[#roomScoped + 1] = objectData
			end
		end
	end

	local chosen = pickFromArray(self._rng, #roomScoped > 0 and roomScoped or candidates)
	if type(chosen) ~= "table" then
		return nil, eventData.roomId
	end
	return chosen.id, chosen.roomId or eventData.roomId
end

function Service:TriggerEvent(eventData)
	local context = self:_baseContext()
	local payload = {}
	for key, value in pairs(context) do
		payload[key] = value
	end
	for key, value in pairs(eventData or {}) do
		payload[key] = value
	end

	if type(payload.eventType) ~= "string" then
		payload.eventType = self:SelectRandomEvent(payload)
	end
	payload.eventType = EVENT_TYPE_ALIASES[payload.eventType] or payload.eventType

	local valid, reason = self:ValidateEventConditions(payload)
	if not valid then
		return false, reason
	end

	local eventConfig = findEventConfig(payload.eventType)
	payload.targetObject, payload.roomId = self:_resolveTargetObject(payload, eventConfig)
	local eventRecord = {
		eventType = payload.eventType,
		targetObject = payload.targetObject,
		intensity = tonumber(payload.intensity) or eventConfig.baseIntensity,
		position = payload.position,
		roomId = payload.roomId,
		source = payload.source or "MapEventSystem",
		time = payload.now or os.clock(),
		matchId = payload.matchId,
	}

	local activeEvents = self._state:Get("activeEvents") or {}
	activeEvents[payload.eventType] = eventRecord
	self._state:Set("activeEvents", activeEvents)

	local eventHistory = self._state:Get("eventHistory") or {}
	table.insert(eventHistory, eventRecord)
	if #eventHistory > 100 then
		table.remove(eventHistory, 1)
	end
	self._state:Set("eventHistory", eventHistory)

	local cooldowns = self._state:Get("eventCooldowns") or {}
	cooldowns[payload.eventType] = eventRecord.time + eventConfig.cooldown
	self._state:Set("eventCooldowns", cooldowns)

	local applied, applyReason = self:ApplyEventEffect(eventRecord)
	if not applied then
		return false, applyReason
	end

	self:_publish("ParanormalEvent", eventRecord)
	self:_publish("MapEventTriggered", eventRecord)
	self:_publish("EnvironmentalDisturbance", {
		eventType = eventRecord.eventType,
		intensity = eventRecord.intensity,
		position = eventRecord.position,
		matchId = eventRecord.matchId,
	})

	return true, eventRecord
end

function Service:OnMatchStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._state:ResetForMatch(matchId)
end

function Service:OnDirectorEvent(payload)
	if not payload or payload.matchId ~= self._state:Get("activeMatchId") then
		return
	end
	self._state:Set("lastDirectorIntensity", tonumber(payload.tension) or tonumber(payload.intensity) or 0)
	self:TriggerEvent({
		matchId = payload.matchId,
		eventType = payload.eventType,
		targetObject = payload.objectId or payload.targetId,
		intensity = payload.intensity,
		position = payload.position,
		source = "HorrorDirector",
		now = payload.now,
	})
end

function Service:OnGhostInteraction(payload)
	if not payload or payload.matchId ~= self._state:Get("activeMatchId") then
		return
	end
	self:TriggerEvent({
		matchId = payload.matchId,
		targetObject = payload.objectId or payload.targetId,
		source = "GhostSystem",
		now = payload.now,
	})
end

function Service:OnPlayerSanityChanged(payload)
	if not payload or payload.matchId ~= self._state:Get("activeMatchId") then
		return
	end
	self._state:Set("lastSanity", tonumber(payload.newSanity) or 100)
	self:TriggerEvent({
		matchId = payload.matchId,
		source = "SanitySystem",
		now = payload.now,
	})
end

function Service:OnHuntTriggered(payload)
	if not payload or payload.matchId ~= self._state:Get("activeMatchId") then
		return
	end
	self._state:Set("currentPhase", "Hunt")
	self:TriggerEvent({
		matchId = payload.matchId,
		eventType = "ShadowApparition",
		intensity = 0.9,
		source = "AggressionSystem",
		now = payload.now,
	})
end

function Service:OnMatchEnded(payload)
	if not payload or payload.matchId ~= self._state:Get("activeMatchId") then
		return
	end
	self._state:Clear()
end

function Service:SetAggression(aggression)
	self._state:Set("lastAggression", tonumber(aggression) or 0)
end

function Service:SetPhase(phaseName)
	if type(phaseName) == "string" and phaseName ~= "" then
		self._state:Set("currentPhase", phaseName)
	end
end

return Service

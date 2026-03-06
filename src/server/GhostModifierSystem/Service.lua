local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

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

local function toArrayKeys(map)
	local list = {}
	for key in pairs(map or {}) do
		table.insert(list, key)
	end
	table.sort(list)
	return list
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = nil
	self._dependencies = {}
	self._rng = self._deps.Random or Random.new()
	return self
end

function Service:Create()
	self._eventBus = resolveEventBus(self._deps)
	self._dependencies = {
		GhostSystem = Services.Get(self._deps, "GhostSystem"),
		HorrorDirector = Services.Get(self._deps, "HorrorDirector"),
		AggressionSystem = Services.Get(self._deps, "AggressionSystem"),
		MatchSystem = Services.Get(self._deps, "MatchSystem"),
	}
end

function Service:Init()
	self._state:Set("activeModifiers", {})
	self._state:Set("modifierHistory", self._state:Get("modifierHistory") or {})
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

function Service:_modifierDefinitions()
	return self._state:Get("modifierDefinitions") or {}
end

function Service:_activeModifiers()
	return self._state:Get("activeModifiers") or {}
end

function Service:_setActiveModifiers(activeModifiers)
	self._state:Set("activeModifiers", activeModifiers)
end

function Service:_appendHistory(entry)
	local history = self._state:Get("modifierHistory") or {}
	table.insert(history, entry)
	if #history > 200 then
		table.remove(history, 1)
	end
	self._state:Set("modifierHistory", history)
end

function Service:_selectRandomModifier()
	local definitions = self:_modifierDefinitions()
	local modifierNames = toArrayKeys(definitions)
	if #modifierNames == 0 then
		return nil
	end
	return modifierNames[self._rng:NextInteger(1, #modifierNames)]
end

function Service:AssignModifier(ghostId, requestedModifier)
	if type(ghostId) ~= "string" or ghostId == "" then
		return nil, "invalid_ghost_id"
	end

	local modifierName = requestedModifier
	if type(modifierName) ~= "string" or modifierName == "" then
		modifierName = self:_selectRandomModifier()
	end
	if type(modifierName) ~= "string" then
		return nil, "no_modifier_available"
	end

	local definitions = self:_modifierDefinitions()
	local modifierDefinition = definitions[modifierName]
	if type(modifierDefinition) ~= "table" then
		return nil, "unknown_modifier"
	end

	local activeModifiers = self:_activeModifiers()
	activeModifiers[ghostId] = modifierName
	self:_setActiveModifiers(activeModifiers)

	local record = {
		matchId = self._state:Get("activeMatchId"),
		ghostId = ghostId,
		modifier = modifierName,
		time = os.clock(),
	}
	self:_appendHistory(record)

	self:_publish("GhostModifierAssigned", record)
	self:ApplyModifierEffects(ghostId)

	return modifierName
end

function Service:GetModifier(ghostId)
	if type(ghostId) ~= "string" or ghostId == "" then
		return nil
	end
	return self:_activeModifiers()[ghostId]
end

function Service:ApplyModifierEffects(ghostId)
	local modifierName = self:GetModifier(ghostId)
	if not modifierName then
		return nil, "modifier_not_found"
	end

	local modifierDefinition = self:_modifierDefinitions()[modifierName]
	if type(modifierDefinition) ~= "table" then
		return nil, "modifier_definition_not_found"
	end

	local payload = {
		matchId = self._state:Get("activeMatchId"),
		ghostId = ghostId,
		modifier = modifierName,
		effects = modifierDefinition,
	}

	local ghostSystem = self._dependencies.GhostSystem
	local aggressionSystem = self._dependencies.AggressionSystem
	local horrorDirector = self._dependencies.HorrorDirector

	safeCall(ghostSystem, "ApplyGhostModifier", ghostId, modifierDefinition)
	safeCall(ghostSystem, "ApplyModifierEffects", ghostId, modifierDefinition)
	safeCall(aggressionSystem, "ApplyGhostModifier", ghostId, modifierDefinition)
	safeCall(aggressionSystem, "IncreaseAggression", self._state:Get("activeMatchId"), (modifierDefinition.aggressionMultiplier or 1) - 1, "ghost_modifier")
	safeCall(horrorDirector, "ApplyGhostModifier", ghostId, modifierDefinition)

	self:_publish("GhostBehaviorModified", payload)
	return payload
end

function Service:RemoveModifier(ghostId)
	if type(ghostId) ~= "string" or ghostId == "" then
		return false, "invalid_ghost_id"
	end

	local activeModifiers = self:_activeModifiers()
	if activeModifiers[ghostId] == nil then
		return false, "modifier_not_found"
	end
	activeModifiers[ghostId] = nil
	self:_setActiveModifiers(activeModifiers)
	return true
end

function Service:OnMatchStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._state:ResetForMatch(matchId)
end

function Service:OnGhostSpawned(payload)
	local matchId = payload and payload.matchId
	if self._state:Get("activeMatchId") ~= matchId then
		return nil
	end

	local ghostId = payload and (payload.ghostId or payload.id)
	local requestedModifier = payload and payload.modifier
	if type(ghostId) ~= "string" then
		return nil
	end
	return self:AssignModifier(ghostId, requestedModifier)
end

function Service:OnMatchEnded(payload)
	local matchId = payload and payload.matchId
	if self._state:Get("activeMatchId") ~= matchId then
		return
	end

	local activeModifiers = self:_activeModifiers()
	for ghostId in pairs(activeModifiers) do
		self:RemoveModifier(ghostId)
	end
	self._state:Set("activeMatchId", nil)
end

return Service

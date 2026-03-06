local MatchLifecycle = {}
MatchLifecycle.__index = MatchLifecycle

local PHASE_ORDER = {
	"PreparationPhase",
	"InvestigationPhase",
	"HuntPhase",
	"EndgamePhase",
}

local LEGACY_TO_PHASE = {
	Preparation = "PreparationPhase",
	Investigation = "InvestigationPhase",
	Hunt = "HuntPhase",
	Endgame = "EndgamePhase",
}

local PHASE_TO_LEGACY = {
	PreparationPhase = "Preparation",
	InvestigationPhase = "Investigation",
	HuntPhase = "Hunt",
	EndgamePhase = "Endgame",
}

local PHASE_EVENT_BY_NAME = {
	PreparationPhase = "PreparationStarted",
	InvestigationPhase = "InvestigationStarted",
	HuntPhase = "HuntStarted",
	EndgamePhase = "EndgameStarted",
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

local function getNow(now)
	return now or os.clock()
end

local function normalizePhase(phaseName)
	return LEGACY_TO_PHASE[phaseName] or phaseName
end

local function indexOfPhase(name)
	local normalized = normalizePhase(name)
	for index, phase in ipairs(PHASE_ORDER) do
		if phase == normalized then
			return index
		end
	end
	return nil
end

function MatchLifecycle.new(deps, config)
	local self = setmetatable({}, MatchLifecycle)
	self._deps = deps or {}
	self._config = config or {}
	self._eventBus = resolveEventBus(self._deps)
	return self
end

function MatchLifecycle:_publish(eventName, payload)
	if not self._eventBus then
		return
	end
	self._eventBus:Publish(eventName, payload)
end

function MatchLifecycle:_notifyPhase(match, phaseName, now)
	local legacyPhaseName = PHASE_TO_LEGACY[phaseName] or phaseName
	local at = getNow(now)
	local phaseEventName = PHASE_EVENT_BY_NAME[phaseName]

	if phaseEventName then
		self:_publish(phaseEventName, {
			matchId = match.matchId,
			phase = phaseName,
			phaseName = phaseName,
			source = "MatchLifecycle",
			at = at,
		})
	end

	-- Keep legacy consumers of PhaseStarted compatible.
	self:_publish("PhaseStarted", {
		matchId = match.matchId,
		phase = phaseName,
		phaseName = legacyPhaseName,
		lifecyclePhase = phaseName,
		source = "MatchLifecycle",
		at = at,
	})
end

function MatchLifecycle:Begin(match, now)
	match:SetState("Starting", now)
	match:MarkStarted(now)
	match:SetPhase("PreparationPhase", now)
	self:_notifyPhase(match, "PreparationPhase", now)
	return match.phase
end

function MatchLifecycle:Advance(match, requestedPhase, now)
	local currentIndex = indexOfPhase(match.phase)
	if not currentIndex then
		return nil, "invalid_current_phase"
	end

	local targetPhase = normalizePhase(requestedPhase)
	if not targetPhase then
		targetPhase = PHASE_ORDER[currentIndex + 1]
	end
	if not targetPhase then
		return nil, "no_next_phase"
	end

	local targetIndex = indexOfPhase(targetPhase)
	if not targetIndex then
		return nil, "invalid_target_phase"
	end
	if targetIndex ~= currentIndex + 1 then
		return nil, "invalid_transition"
	end

	match:SetPhase(targetPhase, now)
	self:_notifyPhase(match, targetPhase, now)
	return targetPhase
end

function MatchLifecycle:Finish(match, results, now)
	if normalizePhase(match.phase) ~= "EndgamePhase" then
		match:SetPhase("EndgamePhase", now)
		self:_notifyPhase(match, "EndgamePhase", now)
	end
	match:SetState("Ending", now)
	match:MarkEnded(results, now)
	return match.state
end

return MatchLifecycle

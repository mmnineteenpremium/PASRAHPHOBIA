local IdleState = require(script.Parent.States.IdleState)
local RoamingState = require(script.Parent.States.RoamingState)
local InteractState = require(script.Parent.States.InteractState)
local HuntState = require(script.Parent.States.HuntState)
local ManifestState = require(script.Parent.States.ManifestState)
local RetreatState = require(script.Parent.States.RetreatState)

local DEFAULT_STATE = "Idle"

local VALID_TRANSITIONS = {
    Idle = { "Roaming", "Manifestation" },
    Roaming = { "Manifestation", "Hunting", "Idle" },
    Manifestation = { "Roaming", "Hunting" },
    Hunting = { "Cooldown" },
    Cooldown = { "Idle" },
}

local function normalizeState(stateName)
    if stateName == "Manifest" or stateName == "Manifestation" then
        return "Manifestation"
    end
    if stateName == "Hunt" or stateName == "Hunting" then
        return "Hunting"
    end
    if stateName == "Retreat" or stateName == "Cooldown" then
        return "Cooldown"
    end
    if stateName == "Interact" or stateName == "Investigating" or stateName == "Interaction" then
        return "Roaming"
    end
    return stateName
end

local function toInternalState(stateName)
    if stateName == "Manifestation" then
        return "Manifest"
    end
    if stateName == "Hunting" then
        return "Hunt"
    end
    if stateName == "Cooldown" then
        return "Retreat"
    end
    return stateName
end

local GhostStateMachine = {}
GhostStateMachine.__index = GhostStateMachine

function GhostStateMachine.new(ghost)
	local self = setmetatable({}, GhostStateMachine)
	self._states = {
		Idle = IdleState,
		Roaming = RoamingState,
		Interact = InteractState,
		Hunt = HuntState,
		Manifest = ManifestState,
		Retreat = RetreatState,
		Investigating = InteractState,
		Interaction = InteractState,
	}
	self._currentState = nil
	self._lastTransitionTime = 0
	self._ghost = ghost
	self._running = false
	return self
end

function GhostStateMachine:Start()
	self._currentState = DEFAULT_STATE
	self._running = true
end

function GhostStateMachine:Stop()
	self._running = false
end

function GhostStateMachine:GetState()
	return self._currentState or DEFAULT_STATE
end

function GhostStateMachine:SetState(stateName)
	if type(stateName) ~= "string" or stateName == "" then
		return
	end
	self._currentState = stateName
end

function GhostStateMachine:_enterState(session, stateName, context)
	session.currentState = stateName
	session.stateEnteredAt = context.now
	self._currentState = stateName
	local state = self._states[stateName]
	if state and state.Enter then
		state.Enter(session, context)
	end
end

function GhostStateMachine:RequestTransition(session, newStateName, context)
	local internalCurrent = self._currentState or DEFAULT_STATE
	local currentName = normalizeState(internalCurrent)
	local now = os.clock()
	if now - self._lastTransitionTime < 0.2 then
		warn("[GhostStateMachine] transition throttled", newStateName, debug.traceback())
		return false
	end
	local requested = normalizeState(newStateName)
	if currentName == requested then
		warn("[GhostSM] Rejected: " .. tostring(currentName) .. " -> " .. tostring(requested))
		return false
	end

	local allowed = VALID_TRANSITIONS[currentName]
	if not (type(allowed) == "table" and table.find(allowed, requested)) then
		warn("[GhostSM] Rejected: " .. tostring(currentName) .. " -> " .. tostring(requested))
		return false
	end

	local internalNext = toInternalState(requested)
	local nextState = self._states[internalNext]
	if not nextState then
		warn("[GhostSM] Rejected: " .. tostring(currentName) .. " -> " .. tostring(requested))
		return false
	end

	local currentState = self._states[internalCurrent]
	if currentState and currentState.Exit then
		currentState.Exit(session, context)
	end

	print("[GhostStateMachine] transition", currentName, "", requested)
	self:_enterState(session, internalNext, context)
	self._lastTransitionTime = now
	return true
end

function GhostStateMachine:TransitionTo(session, nextStateName, context)
	self:RequestTransition(session, nextStateName, context)
	return session.currentState
end

function GhostStateMachine:Tick(session, context)
	local currentStateName = self:GetState()
	if not session.stateEnteredAt then
		self:_enterState(session, currentStateName, context)
	end

	context.elapsedInState = context.now - (session.stateEnteredAt or context.now)

	local state = self._states[currentStateName]
	if not state then
		return self:GetState()
	end

	local nextStateName = state.Update and state.Update(session, context) or nil
	if nextStateName and nextStateName ~= currentStateName then
		self:RequestTransition(session, nextStateName, context)
	end

	return self:GetState()
end

return GhostStateMachine

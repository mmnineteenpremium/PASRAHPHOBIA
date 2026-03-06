local IdleState = require(script.Parent.States.IdleState)
local RoamingState = require(script.Parent.States.RoamingState)
local InteractState = require(script.Parent.States.InteractState)
local HuntState = require(script.Parent.States.HuntState)
local ManifestState = require(script.Parent.States.ManifestState)
local RetreatState = require(script.Parent.States.RetreatState)

local GhostStateMachine = {}
GhostStateMachine.__index = GhostStateMachine

function GhostStateMachine.new()
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
	return self
end

function GhostStateMachine:TransitionTo(session, nextStateName, context)
	local currentName = session.currentState
	local currentState = self._states[currentName]
	local nextState = self._states[nextStateName]
	if not nextState or currentName == nextStateName then
		return currentName
	end

	if currentState and currentState.Exit then
		currentState.Exit(session, context)
	end

	session.currentState = nextStateName
	session.stateEnteredAt = context.now

	if nextState.Enter then
		nextState.Enter(session, context)
	end

	return nextStateName
end

function GhostStateMachine:Tick(session, context)
	if not session.currentState then
		session.currentState = "Idle"
		session.stateEnteredAt = context.now
		local initialState = self._states[session.currentState]
		if initialState and initialState.Enter then
			initialState.Enter(session, context)
		end
	end

	context.elapsedInState = context.now - (session.stateEnteredAt or context.now)

	local state = self._states[session.currentState]
	if not state then
		return session.currentState
	end

	local nextStateName = state.Update and state.Update(session, context) or nil
	if nextStateName and nextStateName ~= session.currentState then
		self:TransitionTo(session, nextStateName, context)
	end

	return session.currentState
end

return GhostStateMachine

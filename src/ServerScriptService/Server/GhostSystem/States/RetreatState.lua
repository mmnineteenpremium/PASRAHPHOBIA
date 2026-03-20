local RetreatState = {}

function RetreatState.Enter(session, context)
	local cooldown = math.random(25, 45)
	session.stateData.retreatEndsAt = context.now + cooldown
	local token = (session.stateData.cooldownToken or 0) + 1
	session.stateData.cooldownToken = token
	local stateMachine = context.stateMachine
	local scheduledNow = context.now
	if stateMachine then
		task.delay(cooldown, function()
			if session._destroyed then
				return
			end
			if session.stateData.cooldownToken ~= token then
				return
			end
			stateMachine:TransitionTo(session, "Idle", {
				now = scheduledNow + cooldown,
				snapshot = context.snapshot,
				rng = context.rng,
				config = context.config,
				roaming = context.roaming,
				targeting = context.targeting,
				huntController = context.huntController,
				emit = context.emit,
				difficultyProfile = context.difficultyProfile,
				stateMachine = stateMachine,
			})
		end)
	end

	if session.favoriteRoomId then
		session.currentRoomId = session.favoriteRoomId
	end
end

function RetreatState.Update(session, context)
	if session.hunt.active then
		return "Hunt"
	end

	if context.now >= (session.stateData.retreatEndsAt or context.now) then
		session.disturbed = false
		return "Idle"
	end

	return nil
end

function RetreatState.Exit(session)
	session.stateData.retreatEndsAt = nil
end

return RetreatState

local ManifestState = {}

function ManifestState.Enter(session, context)
	local duration = math.random(3, 7)
	session.stateData.manifestEndsAt = context.now + duration
	local token = (session.stateData.manifestToken or 0) + 1
	session.stateData.manifestToken = token
	local stateMachine = context.stateMachine
	local scheduledNow = context.now
	if stateMachine then
		task.delay(duration, function()
			if session._destroyed then
				return
			end
			if session.stateData.manifestToken ~= token then
				return
			end
			stateMachine:TransitionTo(session, "Roaming", {
				now = scheduledNow + duration,
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
	context.emit("interaction", {
		interactionType = "Manifest",
		intensity = 2.0,
		roomId = session.currentRoomId,
	})
end

function ManifestState.Update(session, context)
	if session.hunt.active then
		return "Hunt"
	end
	if context.now >= (session.stateData.manifestEndsAt or context.now) then
		return "Roaming"
	end
	return nil
end

function ManifestState.Exit(session)
	session.stateData.manifestEndsAt = nil
end

return ManifestState

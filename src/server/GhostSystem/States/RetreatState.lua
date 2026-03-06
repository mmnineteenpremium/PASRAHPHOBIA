local RetreatState = {}

function RetreatState.Enter(session, context)
	local personality = session.personality or {}
	local baseDuration = context.config.RetreatDuration or 6
	local scaled = baseDuration * (personality.retreatDurationScale or 1)
	session.stateData.retreatEndsAt = context.now + math.max(2.0, scaled)

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
		if context.rng:NextNumber() <= (context.config.ReturnToIdleChanceAfterRetreat or 0.65) then
			return "Idle"
		end
		return "Roaming"
	end

	return nil
end

function RetreatState.Exit(session)
	session.stateData.retreatEndsAt = nil
end

return RetreatState

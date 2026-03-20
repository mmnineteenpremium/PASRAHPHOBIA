local IdleState = {}

function IdleState.Enter(session, context)
	local minDuration = context.config.IdleMinDuration or 4
	local maxDuration = context.config.IdleMaxDuration or 9
	local duration = context.rng:NextNumber(minDuration, maxDuration)
	session.stateData.idleEndsAt = context.now + duration
end

function IdleState.Update(session, context)
	if session.hunt.active then
		return "Hunt"
	end

	local snapshot = context.snapshot
	if snapshot.playerNearFavoriteRoom or snapshot.playerNearGhost then
		return "Interact"
	end

	if session.disturbed and context.rng:NextNumber() <= (context.config.DisturbedRetreatChance or 0.4) then
		return "Retreat"
	end

	if context.now >= (session.stateData.idleEndsAt or context.now) then
		return "Roaming"
	end

	return nil
end

function IdleState.Exit(session)
	session.stateData.idleEndsAt = nil
end

return IdleState

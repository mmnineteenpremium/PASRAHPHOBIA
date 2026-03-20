local InvestigatingState = {}

function InvestigatingState.Enter(session, context)
	local duration = context.config.InvestigatingDuration or 6
	session.stateData.investigatingEndsAt = context.now + duration
end

function InvestigatingState.Update(session, context)
	if session.hunt.active then
		return "Hunt"
	end

	local snapshot = context.snapshot
	local roomActivity = snapshot.roomActivity or {}
	local currentRoomActivity = roomActivity[session.currentRoomId] or 0
	local playerNearGhost = snapshot.playerNearGhost or false

	if context.now >= (session.stateData.investigatingEndsAt or context.now) then
		return "Roaming"
	end

	if not playerNearGhost and currentRoomActivity <= (context.config.MinInvestigatingActivity or 0.2) then
		return "Roaming"
	end

	if (session.aggression or 0) >= (context.config.ManifestAggressionThreshold or 45)
		and context.rng:NextNumber() <= (context.config.ManifestChanceWhileInvestigating or 0.15)
	then
		return "Manifest"
	end

	return nil
end

function InvestigatingState.Exit(session)
	session.stateData.investigatingEndsAt = nil
end

return InvestigatingState

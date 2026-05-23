local InteractState = {}

function InteractState.Enter(session, context)
	local personality = session.personality or {}
	local baseDuration = context.config.InteractDuration or 5
	local duration = baseDuration * (2 - math.min(1.5, personality.interactionRate or 1))
	session.stateData.interactEndsAt = context.now + math.max(2.25, duration)
	session.stateData.nextInteractionPulseAt = context.now
end

function InteractState.Update(session, context)
	if session.hunt.active then
		return "Hunt"
	end

	if context.now >= (session.stateData.interactEndsAt or context.now) then
		return "Roaming"
	end

	if session.disturbed and context.rng:NextNumber() <= (context.config.DisturbedRetreatChance or 0.4) then
		return "Idle"
	end

	if context.now >= (session.stateData.nextInteractionPulseAt or context.now) then
		context.emit("interaction", {
			interactionType = "Environmental",
			intensity = 1 + ((session.aggression or 0) / 100),
			roomId = session.currentRoomId,
		})
		local pulseInterval = context.config.InteractPulseInterval or 2.0
		session.stateData.nextInteractionPulseAt = context.now + pulseInterval
	end

	local aggression = session.aggression or 0
	local personality = session.personality or {}
	local manifestScale = personality.manifestChanceScale or 1.0
	if context.manifestAllowed == true
		and aggression >= (context.config.ManifestAggressionThreshold or 45)
		and context.rng:NextNumber() <= ((context.config.ManifestChanceWhileInteracting or 0.2) * manifestScale)
	then
		return "Manifest"
	end

	return nil
end

function InteractState.Exit(session)
	session.stateData.interactEndsAt = nil
	session.stateData.nextInteractionPulseAt = nil
end

return InteractState

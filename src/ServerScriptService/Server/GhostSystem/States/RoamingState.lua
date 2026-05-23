local RoamingState = {}

local function resolveRoamShiftInterval(context)
	local difficultyProfile = context.difficultyProfile or {}
	local aggressionValue = tonumber(difficultyProfile.GhostAggression) or 0
	local configuredBase = tonumber(context.config.RoamShiftInterval) or 5
	local baseInterval = math.max(3, configuredBase)

	if aggressionValue >= 75 then
		return context.rng:NextInteger(2, 4)
	end
	if aggressionValue >= 50 then
		return context.rng:NextInteger(3, 5)
	end
	return context.rng:NextInteger(math.max(3, baseInterval - 1), baseInterval + 2)
end

function RoamingState.Enter(session, context)
	local nextRoom = context.roaming:SelectNextRoom(session, context.snapshot)
	if nextRoom then
		session.currentRoomId = nextRoom
	end

	session.stateData.nextRoamShiftAt = context.now + resolveRoamShiftInterval(context)
end

function RoamingState.Update(session, context)
	if session.hunt.active then
		return "Hunt"
	end

	local snapshot = context.snapshot
	local noiseLevel = snapshot.playerNoiseLevel or 0
	local playerNearGhost = snapshot.playerNearGhost or false
	if noiseLevel >= (context.config.InvestigationNoiseThreshold or 0.5) or playerNearGhost then
		return "Interact"
	end

	if session.disturbed and context.rng:NextNumber() <= (context.config.DisturbedRetreatChance or 0.4) then
		return "Idle"
	end

	if context.now >= (session.stateData.nextRoamShiftAt or context.now) then
		local nextRoom = context.roaming:SelectNextRoom(session, snapshot)
		if nextRoom then
			session.currentRoomId = nextRoom
		end
		session.stateData.nextRoamShiftAt = context.now + resolveRoamShiftInterval(context)
	end

	local aggression = session.aggression or 0
	local manifestThreshold = context.config.ManifestAggressionThreshold or 45
	local personality = session.personality or {}
	local manifestScale = personality.manifestChanceScale or 1.0
	if context.manifestAllowed == true
		and aggression >= manifestThreshold
		and context.rng:NextNumber() <= ((context.config.ManifestChanceWhileRoaming or 0.1) * manifestScale)
	then
		return "Manifest"
	end

	return nil
end

function RoamingState.Exit(session)
	session.stateData.nextRoamShiftAt = nil
end

return RoamingState

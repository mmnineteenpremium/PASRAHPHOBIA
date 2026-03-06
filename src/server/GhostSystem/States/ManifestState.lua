local ManifestState = {}

function ManifestState.Enter(session, context)
	local duration = context.config.ManifestDuration or 2.5
	session.stateData.manifestEndsAt = context.now + duration
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
		if context.rng:NextNumber() <= (context.config.RetreatChanceAfterManifest or 0.5) then
			return "Retreat"
		end
		return "Roaming"
	end
	return nil
end

function ManifestState.Exit(session)
	session.stateData.manifestEndsAt = nil
end

return ManifestState

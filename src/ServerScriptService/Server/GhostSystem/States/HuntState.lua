local HuntState = {}

function HuntState.Enter(session, context)
	session.stateData.huntEnteredAt = context.now
	context.emit("interaction", {
		interactionType = "HuntPressure",
		intensity = 3.0,
		roomId = session.currentRoomId,
	})
end

function HuntState.Update(session)
	if session.hunt.active then
		return nil
	end

	return "Retreat"
end

function HuntState.Exit(session)
	session.stateData.huntEnteredAt = nil
end

return HuntState

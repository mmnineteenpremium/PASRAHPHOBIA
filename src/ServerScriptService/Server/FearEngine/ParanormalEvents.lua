local ParanormalEvents = {}

function ParanormalEvents.trigger()
	local events = {
		"door_slam",
		"light_flicker",
		"object_move",
		"radio_noise"
	}

	local event = events[math.random(1,#events)]
	print("Paranormal event:", event)
end

return ParanormalEvents

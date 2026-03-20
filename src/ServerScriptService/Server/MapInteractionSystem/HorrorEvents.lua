local HorrorEvents = {}
HorrorEvents.__index = HorrorEvents

function HorrorEvents.new()
	return setmetatable({}, HorrorEvents)
end

function HorrorEvents:Resolve(eventType, payload)
	local roomId = payload and payload.roomId
	if eventType == "LightFlicker" then
		return {
			action = "lights",
			roomId = roomId,
			state = "flicker",
		}
	elseif eventType == "DoorSlam" then
		return {
			action = "door_slam",
			doorId = payload and payload.doorId or "nearby_door",
			roomId = roomId,
		}
	elseif eventType == "ObjectThrow" then
		return {
			action = "object_move",
			objectId = payload and payload.objectId or "nearby_object",
			mode = "throw",
			roomId = roomId,
		}
	elseif eventType == "RadioNoise" then
		return {
			action = "electronic",
			targetId = payload and payload.targetId or "nearby_radio",
			mode = "radio_static",
			roomId = roomId,
		}
	elseif eventType == "ShadowMovement" then
		return {
			action = "electronic",
			targetId = payload and payload.targetId or "shadow_channel",
			mode = "em_interference",
			roomId = roomId,
		}
	end
	return nil
end

return HorrorEvents

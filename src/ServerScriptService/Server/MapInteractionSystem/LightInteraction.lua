local LightInteraction = {}
LightInteraction.__index = LightInteraction

local function copy(value)
	local out = {}
	for k, v in pairs(value or {}) do
		out[k] = v
	end
	return out
end

function LightInteraction.new()
	return setmetatable({}, LightInteraction)
end

function LightInteraction:Flicker(session, roomId, payload)
	local id = roomId or "unknown_room"
	session.lights[id] = session.lights[id] or {}
	session.lights[id].state = payload and payload.state or "flicker"
	session.lights[id].updatedAt = payload and payload.now or os.clock()
	return copy(session.lights[id]), id
end

return LightInteraction

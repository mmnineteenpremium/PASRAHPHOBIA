local ElectronicDisturbance = {}
ElectronicDisturbance.__index = ElectronicDisturbance

local function copy(value)
	local out = {}
	for k, v in pairs(value or {}) do
		out[k] = v
	end
	return out
end

function ElectronicDisturbance.new()
	return setmetatable({}, ElectronicDisturbance)
end

function ElectronicDisturbance:Disturb(session, targetId, mode, payload)
	local id = targetId or "unknown_device"
	session.electronics[id] = session.electronics[id] or {}
	session.electronics[id].mode = mode or "radio_static"
	session.electronics[id].roomId = payload and payload.roomId
	session.electronics[id].updatedAt = payload and payload.now or os.clock()
	return copy(session.electronics[id]), id
end

return ElectronicDisturbance

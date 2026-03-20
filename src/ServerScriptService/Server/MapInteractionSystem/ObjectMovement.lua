local ObjectMovement = {}
ObjectMovement.__index = ObjectMovement

local function copy(value)
	local out = {}
	for k, v in pairs(value or {}) do
		out[k] = v
	end
	return out
end

function ObjectMovement.new()
	return setmetatable({}, ObjectMovement)
end

function ObjectMovement:Move(session, objectId, mode, payload)
	local id = objectId or "unknown_object"
	session.objects[id] = session.objects[id] or {}
	session.objects[id].mode = mode or "slide"
	session.objects[id].roomId = payload and payload.roomId
	session.objects[id].updatedAt = payload and payload.now or os.clock()
	return copy(session.objects[id]), id
end

return ObjectMovement

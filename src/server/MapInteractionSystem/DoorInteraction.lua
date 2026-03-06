local DoorInteraction = {}
DoorInteraction.__index = DoorInteraction

local function copy(value)
	local out = {}
	for k, v in pairs(value or {}) do
		out[k] = v
	end
	return out
end

function DoorInteraction.new()
	return setmetatable({}, DoorInteraction)
end

function DoorInteraction:Open(session, doorId, payload)
	local id = doorId or "unknown_door"
	session.doors[id] = session.doors[id] or {}
	session.doors[id].isOpen = true
	session.doors[id].locked = session.doors[id].locked == true
	session.doors[id].updatedAt = payload and payload.now or os.clock()
	return copy(session.doors[id]), id
end

function DoorInteraction:Slam(session, doorId, payload)
	local state, id = self:Open(session, doorId, payload)
	state.isOpen = false
	session.doors[id].isOpen = false
	session.doors[id].updatedAt = payload and payload.now or os.clock()
	return copy(session.doors[id]), id
end

function DoorInteraction:SetLock(session, doorId, isLocked, payload)
	local id = doorId or "all_doors"
	session.doors[id] = session.doors[id] or {}
	session.doors[id].locked = isLocked == true
	session.doors[id].updatedAt = payload and payload.now or os.clock()
	return copy(session.doors[id]), id
end

return DoorInteraction

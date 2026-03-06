local EventEngine = {}
EventEngine.__index = EventEngine

local function weightedChoice(weightedItems, rng)
	local total = 0
	for _, entry in ipairs(weightedItems) do
		total += entry.weight
	end
	if total <= 0 then
		return nil
	end

	local roll = rng:NextNumber() * total
	local cumulative = 0
	for _, entry in ipairs(weightedItems) do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.value
		end
	end
	return weightedItems[#weightedItems].value
end

local function supportsConstraint(roomData, constraints, ghostRoomId)
	if type(constraints) ~= "table" or type(roomData) ~= "table" then
		return true
	end
	if constraints.allowSafeZone == false and roomData.isSafeZone == true then
		return false
	end
	if constraints.requireElectronics == true and roomData.hasElectronics ~= true then
		return false
	end
	if constraints.preferNearGhost == true and ghostRoomId and roomData.roomId ~= ghostRoomId and roomData.isNearGhostRoom ~= true then
		return false
	end
	return true
end

function EventEngine.new(registry, rng)
	local self = setmetatable({}, EventEngine)
	self._registry = registry
	self._rng = rng
	return self
end

function EventEngine:SelectEventType(matchSession, forcedType)
	if forcedType then
		return forcedType
	end

	local weighted = {}
	for eventType, definition in pairs(self._registry:GetAll()) do
		local cooldownEndsAt = matchSession.cooldowns[eventType] or 0
		if matchSession.now >= cooldownEndsAt then
			table.insert(weighted, {
				value = eventType,
				weight = math.max(0.01, definition.probability or 0.2),
			})
		end
	end

	return weightedChoice(weighted, self._rng)
end

function EventEngine:CanTrigger(matchSession, eventType, bypassProbability)
	local definition = self._registry:Get(eventType)
	if not definition then
		return false, "unknown_event_type"
	end

	local cooldownEndsAt = matchSession.cooldowns[eventType] or 0
	if matchSession.now < cooldownEndsAt then
		return false, "cooldown"
	end

	if bypassProbability ~= true and self._rng:NextNumber() > (definition.probability or 0) then
		return false, "probability_failed"
	end

	return true, nil
end

function EventEngine:SelectLocation(matchSession, eventType, payload)
	if payload and payload.roomId then
		return payload.roomId
	end

	local definition = self._registry:Get(eventType)
	local roomIds = matchSession.roomIds or {}
	local roomMeta = matchSession.roomMeta or {}
	if #roomIds == 0 then
		return nil
	end

	local candidates = {}
	for _, roomId in ipairs(roomIds) do
		local roomData = roomMeta[roomId] or { roomId = roomId }
		roomData.roomId = roomId
		if supportsConstraint(roomData, definition and definition.roomConstraints, matchSession.ghostRoomId) then
			local weight = 1.0
			if roomId == matchSession.ghostRoomId then
				weight += 0.75
			end
			table.insert(candidates, { value = roomId, weight = weight })
		end
	end

	if #candidates == 0 then
		return roomIds[self._rng:NextInteger(1, #roomIds)]
	end
	return weightedChoice(candidates, self._rng)
end

function EventEngine:GetDuration(eventType)
	local definition = self._registry:Get(eventType)
	return definition and definition.duration or 2.0
end

function EventEngine:GetCooldown(eventType)
	local definition = self._registry:Get(eventType)
	return definition and definition.cooldown or 6.0
end

return EventEngine

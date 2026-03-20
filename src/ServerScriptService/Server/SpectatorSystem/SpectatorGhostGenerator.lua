local SpectatorGhostGenerator = {}
SpectatorGhostGenerator.__index = SpectatorGhostGenerator

local DEFAULT_UNCERTAIN_MANIFESTATIONS = {
	"ShadowMovement",
	"FootstepAudio",
	"WhisperAudio",
	"ObjectDisturbance",
	"LightFlicker",
	"DoorCreak",
}

local function cloneArray(source)
	local array = {}
	for index, value in ipairs(source or {}) do
		array[index] = value
	end
	return array
end

local function playerFromPayload(payload)
	if payload and typeof(payload.player) == "Instance" then
		return payload.player
	end
	return nil
end

function SpectatorGhostGenerator.new(deps, config)
	local self = setmetatable({}, SpectatorGhostGenerator)
	self._deps = deps or {}
	self._rng = self._deps.Random or Random.new()
	self._config = config or {}
	self._uncertainManifestations = cloneArray(
		self._config.UncertainManifestations or DEFAULT_UNCERTAIN_MANIFESTATIONS
	)
	return self
end

function SpectatorGhostGenerator:_chooseUncertainManifestation()
	if #self._uncertainManifestations == 0 then
		return "UnknownDisturbance"
	end
	local index = self._rng:NextInteger(1, #self._uncertainManifestations)
	return self._uncertainManifestations[index]
end

function SpectatorGhostGenerator:_chooseFakeRoom(roomIds, realGhostRoomId, observerRoomId)
	local candidates = {}
	for _, roomId in ipairs(roomIds or {}) do
		if roomId ~= realGhostRoomId then
			table.insert(candidates, roomId)
		end
	end

	if #candidates == 0 then
		return observerRoomId or realGhostRoomId
	end

	local index = self._rng:NextInteger(1, #candidates)
	return candidates[index]
end

function SpectatorGhostGenerator:Generate(decision, context)
	print("[SpectatorGhostGenerator] Generating ghost")
	if not decision then
		return nil, "missing_decision"
	end

	local matchId = context and context.matchId
	local spectator = context and context.spectator
	local ghostState = context and context.ghostState or {}
	local activityPayload = context and context.activityPayload or {}

	local realGhostRoomId = ghostState.currentRoomId or activityPayload.room
	local roomIds = context and context.roomIds or {}
	local observerRoomId = context and context.observerRoomId
	local now = context and context.now or os.clock()

	if decision.outcome == "fake" then
		local roomId = self:_chooseFakeRoom(roomIds, realGhostRoomId, observerRoomId)
		local fakePosition = nil
		if typeof(ghostState.position) == "Vector3" then
			fakePosition = ghostState.position + Vector3.new(
				self._rng:NextNumber(-12, 12),
				self._rng:NextNumber(-4, 4),
				self._rng:NextNumber(-12, 12)
			)
		end
		return {
			matchId = matchId,
			spectator = spectator,
			type = "FakeGhost",
			roomId = roomId,
			position = fakePosition,
			durationSeconds = self._rng:NextNumber(3, 7),
			isReliable = false,
			generatedAt = now,
		}
	end

	if decision.outcome == "uncertain" then
		return {
			matchId = matchId,
			spectator = spectator,
			type = "UncertainGhost",
			manifestation = self:_chooseUncertainManifestation(),
			roomId = observerRoomId or realGhostRoomId,
			durationSeconds = self._rng:NextNumber(1.5, 4),
			isReliable = false,
			generatedAt = now,
		}
	end

	if decision.outcome == "real" then
		local duration = decision.realDurationSeconds or self._rng:NextNumber(2, 4)
		return {
			matchId = matchId,
			spectator = spectator,
			type = "RealGhost",
			roomId = realGhostRoomId,
			position = ghostState.position,
			durationSeconds = duration,
			isReliable = true,
			generatedAt = now,
		}
	end

	return nil, "unknown_outcome"
end

function SpectatorGhostGenerator:GetObserverRoomId(spectatorRecord, activityPayload)
	local player = playerFromPayload(spectatorRecord)
	if player then
		return activityPayload.playerRooms and activityPayload.playerRooms[player.UserId] or nil
	end
	return nil
end

return SpectatorGhostGenerator

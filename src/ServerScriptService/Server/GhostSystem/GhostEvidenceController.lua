local GhostEvidenceController = {}
GhostEvidenceController.__index = GhostEvidenceController

local EVIDENCE_TYPES = {
	"SuhuMembeku",
	"BolaArwah",
	"BukuTerkutuk",
	"KotakArwah",
	"JejakEnergi",
	"GerakanGaib",
}

local STATE_BONUS = {
	Idle = 0.0,
	Roaming = 0.05,
	Interact = 0.25,
	Manifest = 0.2,
	Hunt = 0.15,
	Retreat = 0.05,
}

local function clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

local function pickWeighted(items, rng)
	local total = 0
	for _, entry in ipairs(items) do
		total += entry.weight
	end
	if total <= 0 then
		return nil
	end

	local roll = rng:NextNumber() * total
	local cumulative = 0
	for _, entry in ipairs(items) do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.value
		end
	end
	return items[#items].value
end

function GhostEvidenceController.new(config, rng)
	local self = setmetatable({}, GhostEvidenceController)
	self._config = {
		BaseChancePerTick = config.BaseChancePerTick or 0.1,
		ProximityBonus = config.ProximityBonus or 0.18,
		RoomActivityScale = config.RoomActivityScale or 0.2,
		Cooldown = config.Cooldown or 8,
		MaxChance = config.MaxChance or 0.9,
	}
	self._rng = rng
	return self
end

function GhostEvidenceController:_computeProximity(snapshot, session)
	if snapshot.playerNearGhost == true then
		return 1
	end

	local players = snapshot.players
	if type(players) ~= "table" then
		return 0
	end

	local inRoom = 0
	for _, playerData in ipairs(players) do
		if playerData.isAlive ~= false and playerData.roomId == session.currentRoomId then
			inRoom += 1
		end
	end
	return inRoom > 0 and 1 or 0
end

function GhostEvidenceController:_computeChance(session, snapshot)
	local personality = session.personality or {}
	local chance = self._config.BaseChancePerTick * (personality.evidenceSpawnProbability or 1.0)
	chance += self:_computeProximity(snapshot, session) * self._config.ProximityBonus

	local roomActivity = snapshot.roomActivity or {}
	local roomLevel = roomActivity[session.currentRoomId] or snapshot.roomActivityLevel or 0
	chance += roomLevel * self._config.RoomActivityScale
	chance += STATE_BONUS[session.currentState] or 0

	return clamp(chance, 0, self._config.MaxChance)
end

function GhostEvidenceController:_pickEvidenceType(session)
	local allowedEvidence = session.evidenceSet
	if type(allowedEvidence) ~= "table" or #allowedEvidence == 0 then
		allowedEvidence = EVIDENCE_TYPES
	end

	local weighted = {}
	local evidenceBias = (session.personality and session.personality.evidenceBias) or {}
	for _, evidenceType in ipairs(allowedEvidence) do
		table.insert(weighted, {
			value = evidenceType,
			weight = math.max(0.05, evidenceBias[evidenceType] or 1.0),
		})
	end
	return pickWeighted(weighted, self._rng)
end

function GhostEvidenceController:TryTrigger(session, snapshot, now)
	local nextAllowedAt = session.nextEvidenceAllowedAt or 0
	if now < nextAllowedAt then
		return nil
	end

	local chance = self:_computeChance(session, snapshot)
	if self._rng:NextNumber() > chance then
		return nil
	end

	local evidenceType = self:_pickEvidenceType(session)
	if not evidenceType then
		return nil
	end

	local personality = session.personality or {}
	local isFake = false
	local fakeChance = tonumber(personality.fakeEvidenceChance) or 0
	if fakeChance > 0 and self._rng:NextNumber() <= fakeChance then
		isFake = true
	end

	session.nextEvidenceAllowedAt = now + self._config.Cooldown
	return {
		evidenceType = evidenceType,
		roomId = session.currentRoomId or session.favoriteRoomId,
		chance = chance,
		isFake = isFake,
	}
end

return GhostEvidenceController

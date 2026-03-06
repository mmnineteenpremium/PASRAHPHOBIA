local GhostIntelligence = {}
GhostIntelligence.__index = GhostIntelligence

local DECEPTION_TYPES = {
	"fake_evidence",
	"fake_ghost_sound",
	"fake_footsteps",
	"fake_manifestation",
}

local function weightedChoice(weightedEntries, rng)
	local total = 0
	for _, entry in ipairs(weightedEntries) do
		total += entry.weight
	end
	if total <= 0 then
		return nil
	end

	local roll = rng:NextNumber() * total
	local cumulative = 0
	for _, entry in ipairs(weightedEntries) do
		cumulative += entry.weight
		if roll <= cumulative then
			return entry.value
		end
	end
	return weightedEntries[#weightedEntries].value
end

function GhostIntelligence.new(rng)
	local self = setmetatable({}, GhostIntelligence)
	self._rng = rng
	return self
end

function GhostIntelligence:InitializeSession(session)
	local personalityType = session.personality and session.personality.type or "Default"
	session.intelligence = {
		personalityType = personalityType,
		huntStrategy = nil,
		roomStrategy = nil,
		nextDeceptionAt = 0,
		nextDecisionAt = 0,
	}
end

function GhostIntelligence:SelectHuntStrategy(session, snapshot, now)
	local personality = session.personality or {}
	local weights = personality.huntStrategyWeights or {}
	local weighted = {
		{ value = "nearest_player", weight = weights.nearest_player or 1.0 },
		{ value = "lowest_sanity_player", weight = weights.lowest_sanity_player or 1.0 },
		{ value = "isolated_player", weight = weights.isolated_player or 1.0 },
		{ value = "random_target", weight = weights.random_target or 1.0 },
	}

	local selected = weightedChoice(weighted, self._rng) or "nearest_player"
	local intelligence = session.intelligence or {}
	local previous = intelligence.huntStrategy
	intelligence.huntStrategy = selected
	session.intelligence = intelligence
	session.hunt.strategy = selected

	if previous ~= selected then
		return {
			type = "strategy_changed",
			strategyCategory = "hunt",
			previousStrategy = previous,
			currentStrategy = selected,
			now = now,
		}
	end
	return nil
end

function GhostIntelligence:_selectRoomStrategy(session)
	local personality = session.personality or {}
	local weights = personality.roomStrategyWeights or {}
	local weighted = {
		{ value = "stay", weight = weights.stay or 1.0 },
		{ value = "roam", weight = weights.roam or 1.0 },
		{ value = "change_favorite", weight = weights.change_favorite or 0.6 },
	}
	return weightedChoice(weighted, self._rng) or "stay"
end

function GhostIntelligence:_reactToInvestigation(session, snapshot, now, context)
	local toolNearGhost = snapshot.playerUsingToolNearGhostRoom == true
		or snapshot.toolUseNearGhostRoom == true
		or snapshot.investigationToolUsedNearGhostRoom == true
	if not toolNearGhost then
		return nil
	end

	local personality = session.personality or {}
	local reactionWeights = personality.investigationReactionWeights or {}
	local decision = weightedChoice({
		{ value = "hide_evidence", weight = reactionWeights.hide_evidence or 1.0 },
		{ value = "fake_evidence", weight = reactionWeights.fake_evidence or 1.0 },
		{ value = "move_room", weight = reactionWeights.move_room or 1.0 },
		{ value = "increase_aggression", weight = reactionWeights.increase_aggression or 1.0 },
	}, self._rng) or "increase_aggression"

	if decision == "hide_evidence" then
		session.stateData.hideEvidenceUntil = now + 10
	elseif decision == "fake_evidence" then
		return {
			type = "deception_triggered",
			deceptionType = "fake_evidence",
			now = now,
			reason = "investigation_reaction",
		}
	elseif decision == "move_room" then
		local nextRoom = context.roaming:SelectNextRoom(session, snapshot)
		if nextRoom then
			session.currentRoomId = nextRoom
		end
	elseif decision == "increase_aggression" then
		session.aggression = math.min(100, (session.aggression or 0) + 8)
	end

	return {
		type = "decision_made",
		decision = decision,
		now = now,
	}
end

function GhostIntelligence:_maybeDeceive(session, snapshot, now)
	local intelligence = session.intelligence or {}
	if now < (intelligence.nextDeceptionAt or 0) then
		return nil
	end

	local personality = session.personality or {}
	local chance = personality.deceptionChance or 0
	if chance <= 0 or self._rng:NextNumber() > chance then
		return nil
	end

	local deceptionWeights = personality.deceptionWeights or {}
	local weighted = {}
	for _, deceptionType in ipairs(DECEPTION_TYPES) do
		table.insert(weighted, {
			value = deceptionType,
			weight = deceptionWeights[deceptionType] or 1.0,
		})
	end
	local deceptionType = weightedChoice(weighted, self._rng)
	if not deceptionType then
		return nil
	end

	intelligence.nextDeceptionAt = now + (personality.deceptionCooldown or 12)
	session.intelligence = intelligence
	return {
		type = "deception_triggered",
		deceptionType = deceptionType,
		now = now,
		reason = "personality_deception",
	}
end

function GhostIntelligence:Tick(session, snapshot, now, context)
	local runtimeEvents = {}
	if not session.intelligence then
		self:InitializeSession(session)
		table.insert(runtimeEvents, {
			type = "personality_selected",
			personalityType = session.intelligence.personalityType,
			now = now,
		})
	end

	local intelligence = session.intelligence
	if now >= (intelligence.nextDecisionAt or 0) then
		intelligence.nextDecisionAt = now + 4
		local roomStrategy = self:_selectRoomStrategy(session)
		local previous = intelligence.roomStrategy
		intelligence.roomStrategy = roomStrategy
		if previous ~= roomStrategy then
			table.insert(runtimeEvents, {
				type = "strategy_changed",
				strategyCategory = "room",
				previousStrategy = previous,
				currentStrategy = roomStrategy,
				now = now,
			})
		end
	end

	local reactionEvent = self:_reactToInvestigation(session, snapshot, now, context)
	if reactionEvent then
		table.insert(runtimeEvents, reactionEvent)
	end

	local deceptionEvent = self:_maybeDeceive(session, snapshot, now)
	if deceptionEvent then
		table.insert(runtimeEvents, deceptionEvent)
	end

	return runtimeEvents
end

return GhostIntelligence

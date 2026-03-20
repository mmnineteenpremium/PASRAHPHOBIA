local GhostAbilityRegistry = require(script.Parent.GhostAbilityRegistry)

local GhostAbilityEngine = {}
GhostAbilityEngine.__index = GhostAbilityEngine

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

local function getAverageSanity(snapshot)
	if type(snapshot.averageSanity) == "number" then
		return snapshot.averageSanity
	end
	local players = snapshot.players
	if type(players) ~= "table" or #players == 0 then
		return 100
	end
	local total = 0
	local count = 0
	for _, playerData in ipairs(players) do
		if playerData.isAlive ~= false then
			total += playerData.sanity or 100
			count += 1
		end
	end
	if count == 0 then
		return 100
	end
	return total / count
end

local function isProximitySatisfied(snapshot, session)
	if snapshot.playerNearGhost == true or snapshot.playerNearFavoriteRoom == true then
		return true
	end
	local players = snapshot.players
	if type(players) ~= "table" then
		return false
	end
	for _, playerData in ipairs(players) do
		if playerData.isAlive ~= false and playerData.roomId == session.currentRoomId then
			return true
		end
	end
	return false
end

local function evaluatePhase(trigger, session, snapshot)
	local phase = trigger and trigger.phase or "any"
	if phase == "any" then
		return true
	end
	local huntActive = session.hunt and session.hunt.active == true
	if phase == "hunt" then
		return huntActive
	end
	if phase == "non_hunt" then
		return not huntActive
	end

	local phaseName = snapshot.phaseName
	if not phaseName then
		return true
	end
	if phase == "investigation" then
		return phaseName == "Investigation" or phaseName == "InvestigationPhase"
	end
	return true
end

function GhostAbilityEngine.new(config, rng)
	local self = setmetatable({}, GhostAbilityEngine)
	self._rng = rng
	self._registry = GhostAbilityRegistry.new(config)
	return self
end

function GhostAbilityEngine:InitializeSession(session)
	local personalityType = session.personality and session.personality.type or "Default"
	local abilityList = self._registry:ResolveAbilities(
		session.ghostType,
		personalityType,
		session.ghostTypeData
	)

	session.abilities = {
		registered = abilityList,
		cooldowns = {},
		active = {},
		nextAttemptAt = 0,
		attemptInterval = 2.5,
		baseTriggerChance = 0.35,
		maxConcurrent = 2,
	}
end

function GhostAbilityEngine:_isTriggeredByConditions(definition, session, snapshot)
	local trigger = definition.trigger or {}
	local averageSanity = getAverageSanity(snapshot)
	local tension = snapshot.tensionLevel or snapshot.directorTension or 0

	if type(trigger.minTension) == "number" and tension < trigger.minTension then
		return false
	end
	if type(trigger.maxSanity) == "number" and averageSanity > trigger.maxSanity then
		return false
	end
	if trigger.proximityRequired == true and not isProximitySatisfied(snapshot, session) then
		return false
	end
	if not evaluatePhase(trigger, session, snapshot) then
		return false
	end
	return true
end

function GhostAbilityEngine:_applyAbilityEffect(session, abilityType, now, snapshot, context)
	if abilityType == "Teleport" then
		local roomIds = session.roomIds or {}
		if #roomIds > 0 then
			local nextRoom = context.roaming:SelectNextRoom(session, snapshot) or roomIds[self._rng:NextInteger(1, #roomIds)]
			if nextRoom then
				session.currentRoomId = nextRoom
			end
		end
	elseif abilityType == "ShadowWalk" then
		session.stateData.shadowWalkUntil = now + 4.5
	elseif abilityType == "FastRoam" then
		local nextRoom = context.roaming:SelectNextRoom(session, snapshot)
		if nextRoom then
			session.currentRoomId = nextRoom
		end
		session.stateData.fastRoamUntil = now + 5
	elseif abilityType == "DoorLock" then
		session.hunt.doorsLocked = true
		session.hunt.doorUnlockAt = math.max(session.hunt.doorUnlockAt or 0, now + 4)
	elseif abilityType == "LightDrain" then
		session.stateData.lightDrainUntil = now + 6
	elseif abilityType == "WhisperSound" then
		return {
			type = "interaction",
			payload = {
				interactionType = "WhisperSound",
				intensity = 0.8,
				roomId = session.currentRoomId,
			},
		}
	elseif abilityType == "FakeEvidence" then
		return {
			type = "deception_triggered",
			deceptionType = "fake_evidence",
			reason = "ability_fake_evidence",
			now = now,
		}
	elseif abilityType == "FakeFootsteps" then
		return {
			type = "deception_triggered",
			deceptionType = "fake_footsteps",
			reason = "ability_fake_footsteps",
			now = now,
		}
	elseif abilityType == "ObjectThrow" then
		return {
			type = "interaction",
			payload = {
				interactionType = "ObjectThrow",
				intensity = 1.0,
				roomId = session.currentRoomId,
			},
		}
	end

	return nil
end

function GhostAbilityEngine:_updateCompletedAbilities(session, now)
	local runtimeEvents = {}
	local active = session.abilities.active
	local removeIndexes = {}

	for index, activeAbility in ipairs(active) do
		if now >= activeAbility.endsAt then
			table.insert(runtimeEvents, {
				type = "ability_completed",
				abilityType = activeAbility.abilityType,
				now = now,
			})
			table.insert(removeIndexes, 1, index)
		end
	end

	for _, index in ipairs(removeIndexes) do
		table.remove(active, index)
	end

	return runtimeEvents
end

function GhostAbilityEngine:Tick(session, snapshot, now, context)
	if not session.abilities then
		self:InitializeSession(session)
	end

	local runtimeEvents = {}
	for _, eventData in ipairs(self:_updateCompletedAbilities(session, now)) do
		table.insert(runtimeEvents, eventData)
	end

	if now < (session.abilities.nextAttemptAt or 0) then
		return runtimeEvents
	end

	local currentActive = #((session.abilities and session.abilities.active) or {})
	if currentActive >= (session.abilities.maxConcurrent or 2) then
		session.abilities.nextAttemptAt = now + (session.abilities.attemptInterval or 2.5)
		return runtimeEvents
	end

	local weighted = {}
	for _, abilityType in ipairs(session.abilities.registered or {}) do
		local definition = self._registry:GetDefinition(abilityType)
		local cooldownEndsAt = session.abilities.cooldowns[abilityType] or 0
		if definition and now >= cooldownEndsAt and self:_isTriggeredByConditions(definition, session, snapshot) then
			table.insert(weighted, {
				value = abilityType,
				weight = math.max(0.01, definition.chance or 0.1),
			})
		end
	end

	session.abilities.nextAttemptAt = now + (session.abilities.attemptInterval or 2.5)

	local baseTriggerChance = session.abilities.baseTriggerChance or 0.35
	local tension = snapshot.tensionLevel or snapshot.directorTension or 0
	local averageSanity = getAverageSanity(snapshot)
	local tensionBonus = math.clamp(tension / 200, 0, 0.35)
	local lowSanityBonus = math.clamp((100 - averageSanity) / 250, 0, 0.25)
	local shouldTrigger = self._rng:NextNumber() <= (baseTriggerChance + tensionBonus + lowSanityBonus)
	if not shouldTrigger then
		return runtimeEvents
	end

	local abilityType = weightedChoice(weighted, self._rng)
	if not abilityType then
		return runtimeEvents
	end

	local definition = self._registry:GetDefinition(abilityType)
	if not definition then
		return runtimeEvents
	end

	local cooldown = definition.cooldown or 10
	local duration = definition.duration or 0.5
	session.abilities.cooldowns[abilityType] = now + cooldown
	table.insert(session.abilities.active, {
		abilityType = abilityType,
		endsAt = now + duration,
	})

	table.insert(runtimeEvents, {
		type = "ability_triggered",
		abilityType = abilityType,
		category = definition.category,
		cooldown = cooldown,
		duration = duration,
		now = now,
	})
	table.insert(runtimeEvents, {
		type = "ability_cooldown",
		abilityType = abilityType,
		cooldownEndsAt = now + cooldown,
		now = now,
	})

	local effectEvent = self:_applyAbilityEffect(session, abilityType, now, snapshot, context)
	if effectEvent then
		table.insert(runtimeEvents, effectEvent)
	end

	return runtimeEvents
end

return GhostAbilityEngine

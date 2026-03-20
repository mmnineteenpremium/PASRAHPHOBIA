local GhostAbilityRegistry = {}
GhostAbilityRegistry.__index = GhostAbilityRegistry

local ABILITY_DEFINITIONS = {
	Teleport = {
		abilityType = "Teleport",
		category = "Movement",
		cooldown = 16,
		duration = 0.1,
		chance = 0.18,
		trigger = {
			minTension = 35,
			proximityRequired = true,
			phase = "any",
		},
	},
	ShadowWalk = {
		abilityType = "ShadowWalk",
		category = "Movement",
		cooldown = 14,
		duration = 4.5,
		chance = 0.22,
		trigger = {
			maxSanity = 55,
			phase = "non_hunt",
		},
	},
	FastRoam = {
		abilityType = "FastRoam",
		category = "Movement",
		cooldown = 12,
		duration = 5.0,
		chance = 0.26,
		trigger = {
			minTension = 30,
			phase = "any",
		},
	},
	ObjectThrow = {
		abilityType = "ObjectThrow",
		category = "Interaction",
		cooldown = 10,
		duration = 1.5,
		chance = 0.28,
		trigger = {
			proximityRequired = true,
			phase = "any",
		},
	},
	DoorLock = {
		abilityType = "DoorLock",
		category = "Interaction",
		cooldown = 18,
		duration = 4.0,
		chance = 0.2,
		trigger = {
			minTension = 45,
			phase = "any",
		},
	},
	LightDrain = {
		abilityType = "LightDrain",
		category = "Interaction",
		cooldown = 12,
		duration = 6.0,
		chance = 0.24,
		trigger = {
			minTension = 25,
			phase = "any",
		},
	},
	WhisperSound = {
		abilityType = "WhisperSound",
		category = "PlayerManipulation",
		cooldown = 9,
		duration = 2.0,
		chance = 0.3,
		trigger = {
			maxSanity = 65,
			phase = "any",
		},
	},
	FakeEvidence = {
		abilityType = "FakeEvidence",
		category = "PlayerManipulation",
		cooldown = 20,
		duration = 2.0,
		chance = 0.18,
		trigger = {
			minTension = 40,
			phase = "non_hunt",
		},
	},
	FakeFootsteps = {
		abilityType = "FakeFootsteps",
		category = "PlayerManipulation",
		cooldown = 11,
		duration = 2.5,
		chance = 0.25,
		trigger = {
			proximityRequired = true,
			phase = "any",
		},
	},
}

local GHOST_ABILITY_MAP = {
	Default = { "ObjectThrow", "WhisperSound" },
	Pocong = { "ShadowWalk", "WhisperSound", "FakeFootsteps" },
	Kuntilanak = { "Teleport", "WhisperSound", "FakeEvidence" },
	Tuyul = { "FastRoam", "ObjectThrow", "FakeFootsteps" },
	Genderuwo = { "DoorLock", "LightDrain", "ObjectThrow" },
	["Wewe Gombel"] = { "WhisperSound", "FakeFootsteps", "ShadowWalk" },
	Palasik = { "FastRoam", "Teleport", "LightDrain" },
	Banaspati = { "FastRoam", "DoorLock", "ObjectThrow" },
	["Sundel Bolong"] = { "WhisperSound", "FakeEvidence", "LightDrain" },
	Leak = { "ShadowWalk", "Teleport", "FakeFootsteps" },
	["Hantu Jeruk Purut"] = { "WhisperSound", "DoorLock", "ShadowWalk" },
	["Hantu Cermin"] = { "FakeEvidence", "ShadowWalk", "WhisperSound" },
	["Arwah Penunggu"] = { "DoorLock", "LightDrain", "ObjectThrow" },
}

local PERSONALITY_ABILITY_MAP = {
	Aggressive = { "FastRoam", "ObjectThrow", "DoorLock" },
	Shy = { "ShadowWalk", "WhisperSound" },
	Manipulator = { "FakeEvidence", "WhisperSound", "FakeFootsteps" },
	Roamer = { "Teleport", "FastRoam", "FakeFootsteps" },
	Territorial = { "DoorLock", "LightDrain", "ObjectThrow" },
	Default = { "ObjectThrow", "WhisperSound" },
}

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, nestedValue in pairs(value) do
		copy[key] = deepCopy(nestedValue)
	end
	return copy
end

function GhostAbilityRegistry.new(config)
	local self = setmetatable({}, GhostAbilityRegistry)
	self._definitions = deepCopy(ABILITY_DEFINITIONS)
	self._ghostMap = deepCopy(GHOST_ABILITY_MAP)
	self._personalityMap = deepCopy(PERSONALITY_ABILITY_MAP)

	local overrideDefs = config and config.AbilityDefinitions or {}
	for abilityType, definition in pairs(overrideDefs) do
		self._definitions[abilityType] = definition
	end
	local overrideGhostMap = config and config.GhostAbilityMap or {}
	for ghostType, list in pairs(overrideGhostMap) do
		self._ghostMap[ghostType] = list
	end
	local overridePersonalityMap = config and config.PersonalityAbilityMap or {}
	for personalityType, list in pairs(overridePersonalityMap) do
		self._personalityMap[personalityType] = list
	end

	return self
end

function GhostAbilityRegistry:GetDefinition(abilityType)
	return self._definitions[abilityType]
end

function GhostAbilityRegistry:ResolveAbilities(ghostType, personalityType, ghostTypeData)
	if type(ghostTypeData) == "table" and type(ghostTypeData.abilities) == "table" and #ghostTypeData.abilities > 0 then
		return ghostTypeData.abilities
	end

	local byGhostType = self._ghostMap[ghostType]
	if type(byGhostType) == "table" and #byGhostType > 0 then
		return byGhostType
	end

	local byPersonality = self._personalityMap[personalityType or "Default"]
	if type(byPersonality) == "table" and #byPersonality > 0 then
		return byPersonality
	end

	return self._personalityMap.Default
end

return GhostAbilityRegistry

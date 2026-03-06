local GhostPersonalityEngine = {}
GhostPersonalityEngine.__index = GhostPersonalityEngine

local DEFAULT_PERSONALITIES = {
	Default = {
		type = "Default",
		huntFrequency = 1.0,
		interactionRate = 1.0,
		favoriteRoomBias = 1.0,
		evidenceSpawnProbability = 1.0,
		manifestChanceScale = 1.0,
		roamBias = 1.0,
		aggressionGainScale = 1.0,
		retreatDurationScale = 1.0,
		deceptionChance = 0.06,
		deceptionCooldown = 14,
		huntStrategyWeights = {
			nearest_player = 1.0,
			lowest_sanity_player = 1.0,
			isolated_player = 1.0,
			random_target = 0.8,
		},
		roomStrategyWeights = {
			stay = 1.0,
			roam = 1.0,
			change_favorite = 0.8,
		},
		investigationReactionWeights = {
			hide_evidence = 1.0,
			fake_evidence = 1.0,
			move_room = 1.0,
			increase_aggression = 1.0,
		},
		deceptionWeights = {
			fake_evidence = 1.0,
			fake_ghost_sound = 1.0,
			fake_footsteps = 1.0,
			fake_manifestation = 1.0,
		},
		evidenceBias = {},
	},
	Shy = {
		type = "Shy",
		huntFrequency = 0.75,
		interactionRate = 0.9,
		favoriteRoomBias = 1.4,
		evidenceSpawnProbability = 0.9,
		manifestChanceScale = 0.9,
		roamBias = 0.75,
		aggressionGainScale = 0.9,
		retreatDurationScale = 1.2,
		deceptionChance = 0.08,
		huntStrategyWeights = {
			nearest_player = 0.8,
			lowest_sanity_player = 1.2,
			isolated_player = 1.0,
			random_target = 1.1,
		},
		roomStrategyWeights = {
			stay = 1.5,
			roam = 0.8,
			change_favorite = 1.1,
		},
		investigationReactionWeights = {
			hide_evidence = 1.5,
			fake_evidence = 1.0,
			move_room = 1.2,
			increase_aggression = 0.8,
		},
		evidenceBias = {
			KotakArwah = 1.2,
			BukuTerkutuk = 1.1,
		},
	},
	Aggressive = {
		type = "Aggressive",
		huntFrequency = 1.35,
		interactionRate = 1.2,
		favoriteRoomBias = 0.9,
		evidenceSpawnProbability = 1.1,
		manifestChanceScale = 1.3,
		roamBias = 1.15,
		aggressionGainScale = 1.25,
		retreatDurationScale = 0.7,
		deceptionChance = 0.04,
		huntStrategyWeights = {
			nearest_player = 1.5,
			lowest_sanity_player = 1.1,
			isolated_player = 0.9,
			random_target = 0.6,
		},
		roomStrategyWeights = {
			stay = 0.8,
			roam = 1.2,
			change_favorite = 0.6,
		},
		investigationReactionWeights = {
			hide_evidence = 0.6,
			fake_evidence = 0.7,
			move_room = 0.9,
			increase_aggression = 1.6,
		},
		evidenceBias = {
			JejakEnergi = 1.25,
			GerakanGaib = 1.2,
		},
	},
	Manipulator = {
		type = "Manipulator",
		huntFrequency = 0.95,
		interactionRate = 1.25,
		favoriteRoomBias = 1.0,
		evidenceSpawnProbability = 0.95,
		manifestChanceScale = 1.15,
		roamBias = 1.05,
		aggressionGainScale = 1.0,
		retreatDurationScale = 1.0,
		deceptionChance = 0.22,
		deceptionCooldown = 9,
		huntStrategyWeights = {
			nearest_player = 0.9,
			lowest_sanity_player = 1.3,
			isolated_player = 1.2,
			random_target = 1.0,
		},
		roomStrategyWeights = {
			stay = 0.9,
			roam = 1.1,
			change_favorite = 1.0,
		},
		investigationReactionWeights = {
			hide_evidence = 1.2,
			fake_evidence = 1.8,
			move_room = 1.1,
			increase_aggression = 0.8,
		},
		deceptionWeights = {
			fake_evidence = 1.6,
			fake_ghost_sound = 1.4,
			fake_footsteps = 1.2,
			fake_manifestation = 1.1,
		},
		evidenceBias = {
			BolaArwah = 1.2,
			KotakArwah = 1.2,
		},
	},
	Roamer = {
		type = "Roamer",
		huntFrequency = 0.9,
		interactionRate = 1.05,
		favoriteRoomBias = 0.8,
		evidenceSpawnProbability = 1.0,
		manifestChanceScale = 1.0,
		roamBias = 1.5,
		aggressionGainScale = 1.0,
		retreatDurationScale = 1.0,
		deceptionChance = 0.07,
		huntStrategyWeights = {
			nearest_player = 1.0,
			lowest_sanity_player = 0.9,
			isolated_player = 1.3,
			random_target = 1.0,
		},
		roomStrategyWeights = {
			stay = 0.6,
			roam = 1.7,
			change_favorite = 1.1,
		},
		investigationReactionWeights = {
			hide_evidence = 0.9,
			fake_evidence = 1.0,
			move_room = 1.7,
			increase_aggression = 0.9,
		},
		evidenceBias = {
			GerakanGaib = 1.2,
			BolaArwah = 1.1,
		},
	},
	Territorial = {
		type = "Territorial",
		huntFrequency = 1.1,
		interactionRate = 1.0,
		favoriteRoomBias = 1.5,
		evidenceSpawnProbability = 1.05,
		manifestChanceScale = 1.05,
		roamBias = 0.65,
		aggressionGainScale = 1.1,
		retreatDurationScale = 0.85,
		deceptionChance = 0.05,
		huntStrategyWeights = {
			nearest_player = 1.2,
			lowest_sanity_player = 1.0,
			isolated_player = 1.4,
			random_target = 0.6,
		},
		roomStrategyWeights = {
			stay = 1.8,
			roam = 0.7,
			change_favorite = 0.5,
		},
		investigationReactionWeights = {
			hide_evidence = 1.1,
			fake_evidence = 0.7,
			move_room = 0.5,
			increase_aggression = 1.7,
		},
		evidenceBias = {
			SuhuMembeku = 1.3,
			BukuTerkutuk = 1.1,
		},
	},
	Wanderer = {
		type = "Roamer",
		huntFrequency = 0.95,
		interactionRate = 1.15,
		favoriteRoomBias = 0.85,
		evidenceSpawnProbability = 1.0,
		manifestChanceScale = 1.0,
		roamBias = 1.4,
		aggressionGainScale = 1.0,
		retreatDurationScale = 1.0,
		deceptionChance = 0.07,
		huntStrategyWeights = {
			nearest_player = 1.0,
			lowest_sanity_player = 0.9,
			isolated_player = 1.3,
			random_target = 1.0,
		},
		roomStrategyWeights = {
			stay = 0.6,
			roam = 1.6,
			change_favorite = 1.0,
		},
		investigationReactionWeights = {
			hide_evidence = 0.9,
			fake_evidence = 1.0,
			move_room = 1.6,
			increase_aggression = 0.9,
		},
		evidenceBias = {
			BolaArwah = 1.3,
			GerakanGaib = 1.1,
		},
	},
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

local function merge(baseTable, overrideTable)
	local merged = deepCopy(baseTable)
	for key, value in pairs(overrideTable or {}) do
		if type(value) == "table" and type(merged[key]) == "table" then
			merged[key] = merge(merged[key], value)
		else
			merged[key] = value
		end
	end
	return merged
end

function GhostPersonalityEngine.new(config)
	local self = setmetatable({}, GhostPersonalityEngine)
	self._profiles = merge(DEFAULT_PERSONALITIES, config and config.PersonalityProfiles or {})
	return self
end

function GhostPersonalityEngine:Resolve(ghostType, payload)
	local explicit = payload and payload.personality
	if type(explicit) == "table" then
		return merge(self._profiles.Default, explicit)
	end

	local profileName = payload and payload.personalityType
	if type(profileName) ~= "string" and type(ghostType) == "table" then
		profileName = ghostType.personality or ghostType.personalityType
	end

	if profileName == "Wanderer" then
		profileName = "Roamer"
	end
	local baseProfile = self._profiles[profileName] or self._profiles.Default
	local ghostOverrides = nil
	if type(ghostType) == "table" then
		ghostOverrides = ghostType.personalityOverrides
	end
	return merge(baseProfile, ghostOverrides or {})
end

return GhostPersonalityEngine

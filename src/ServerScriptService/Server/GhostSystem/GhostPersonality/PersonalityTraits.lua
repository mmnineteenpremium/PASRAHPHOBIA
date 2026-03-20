local PersonalityTraits = {
    Aggressive = {
        huntFrequency = 1.35,
        aggressionGainScale = 1.25,
        manifestChanceScale = 1.2,
        roamBias = 1.1,
        huntStrategyWeights = {
            nearest_player = 1.3,
            lowest_sanity_player = 1.15,
            isolated_player = 0.9,
        },
    },
    Passive = {
        huntFrequency = 0.8,
        aggressionGainScale = 0.85,
        manifestChanceScale = 0.75,
        interactionRate = 0.8,
        deceptionChance = 0.05,
    },
    Territorial = {
        favoriteRoomBias = 1.6,
        roamBias = 0.65,
        aggressionGainScale = 1.1,
        roomStrategyWeights = {
            stay = 1.8,
            roam = 0.7,
            change_favorite = 0.5,
        },
    },
    Roamer = {
        roamBias = 1.6,
        favoriteRoomBias = 0.8,
        roomStrategyWeights = {
            stay = 0.6,
            roam = 1.7,
            change_favorite = 1.1,
        },
    },
    Shy = {
        manifestChanceScale = 0.65,
        huntFrequency = 0.85,
        retreatDurationScale = 1.2,
        favoriteRoomBias = 1.3,
    },
    Trickster = {
        deceptionChance = 0.24,
        deceptionCooldown = 8,
        fakeEvidenceChance = 0.45,
        deceptionWeights = {
            fake_evidence = 1.8,
            fake_ghost_sound = 1.3,
            fake_footsteps = 1.2,
            fake_manifestation = 1.1,
        },
        investigationReactionWeights = {
            hide_evidence = 1.0,
            fake_evidence = 2.0,
            move_room = 1.1,
            increase_aggression = 0.8,
        },
    },
    Deceptive = {
        deceptionChance = 0.3,
        deceptionCooldown = 7,
        fakeEvidenceChance = 0.5,
        manifestChanceScale = 1.15,
        deceptionWeights = {
            fake_evidence = 2.1,
            fake_ghost_sound = 1.4,
            fake_footsteps = 1.3,
            fake_manifestation = 1.35,
        },
        investigationReactionWeights = {
            hide_evidence = 1.1,
            fake_evidence = 2.3,
            move_room = 1.2,
            increase_aggression = 0.7,
        },
    },
    Stalker = {
        huntFrequency = 1.2,
        aggressionGainScale = 1.1,
        huntStrategyWeights = {
            nearest_player = 1.0,
            lowest_sanity_player = 1.1,
            isolated_player = 1.7,
            random_target = 0.6,
        },
        roomStrategyWeights = {
            stay = 1.1,
            roam = 1.2,
            change_favorite = 0.9,
        },
    },
    Noisy = {
        interactionRate = 1.4,
        manifestChanceScale = 1.05,
        deceptionChance = 0.1,
    },
    Silent = {
        interactionRate = 0.75,
        manifestChanceScale = 0.85,
        deceptionChance = 0.06,
        evidenceSpawnProbability = 0.95,
    },
}

return PersonalityTraits

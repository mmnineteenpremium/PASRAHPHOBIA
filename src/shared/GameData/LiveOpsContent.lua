local now = os.time({ year = 2026, month = 10, day = 1, hour = 0, min = 0, sec = 0 })

return {
    Version = "phase60_live_ops",

    DailyContracts = {
        ResetHours = 24,
        ActiveContractCount = 4,
        Contracts = {
            {
                id = "identify_ghosts",
                objectiveType = "identify_ghost",
                target = 3,
                weight = 10,
                reward = {
                    currency = 450,
                    xp = 180,
                    royalPassXP = 120,
                },
            },
            {
                id = "collect_evidence",
                objectiveType = "collect_evidence",
                target = 6,
                weight = 12,
                reward = {
                    currency = 350,
                    xp = 150,
                    royalPassXP = 100,
                },
            },
            {
                id = "survive_hunts",
                objectiveType = "survive_hunt",
                target = 2,
                weight = 9,
                reward = {
                    currency = 400,
                    xp = 160,
                    royalPassXP = 110,
                },
            },
            {
                id = "complete_no_death",
                objectiveType = "no_death_match",
                target = 1,
                weight = 8,
                reward = {
                    currency = 500,
                    xp = 220,
                    royalPassXP = 140,
                },
            },
        },
    },

    WeeklyChallenges = {
        ResetDays = 7,
        ActiveChallengeCount = 4,
        Challenges = {
            {
                id = "complete_investigations",
                objectiveType = "complete_investigation",
                target = 10,
                weight = 10,
                reward = {
                    currency = 2000,
                    xp = 650,
                    royalPassXP = 350,
                    cosmeticId = "Weekly_Investigator_Badge",
                },
            },
            {
                id = "identify_ghosts_weekly",
                objectiveType = "identify_ghost",
                target = 8,
                weight = 11,
                reward = {
                    currency = 1800,
                    xp = 600,
                    royalPassXP = 320,
                    cosmeticId = "Weekly_GhostHunter_Icon",
                },
            },
            {
                id = "survive_hunts_weekly",
                objectiveType = "survive_hunt",
                target = 6,
                weight = 8,
                reward = {
                    currency = 1700,
                    xp = 540,
                    royalPassXP = 300,
                    cosmeticId = "Weekly_SteadyNerves_Banner",
                },
            },
            {
                id = "evidence_mastery",
                objectiveType = "collect_evidence",
                target = 24,
                weight = 9,
                reward = {
                    currency = 2200,
                    xp = 700,
                    royalPassXP = 380,
                    cosmeticId = "Weekly_EvidenceArchivist_Frame",
                },
            },
        },
    },

    SeasonalEvents = {
        Enabled = true,
        ForceActiveEventId = nil,
        Events = {
            Halloween = {
                enabled = true,
                startUnix = now,
                endUnix = now + (60 * 60 * 24 * 45),
                eventCurrency = "EC",
                temporaryGhostTypes = { "PumpkinWraith", "LanternWidow" },
                eventCosmetics = { "Halloween_Mask_01", "Halloween_Emote_Scared" },
                limitedMaps = { "HalloweenSchool", "AbandonedHospital", "RitualTemple" },
                mapRotation = {
                    enabled = true,
                    eventMaps = { "HalloweenSchool", "AbandonedHospital", "RitualTemple" },
                },
            },
            HauntedChristmas = {
                enabled = false,
                startUnix = now + (60 * 60 * 24 * 60),
                endUnix = now + (60 * 60 * 24 * 95),
                eventCurrency = "EC",
                temporaryGhostTypes = { "FrostSpecter" },
                eventCosmetics = { "Holiday_Bell_Badge", "Holiday_Emote_Wave" },
                limitedMaps = { "FrozenManor" },
                mapRotation = {
                    enabled = true,
                    eventMaps = { "FrozenManor" },
                },
            },
        },
    },

    DynamicInvestigationEvents = {
        Enabled = true,
        BaseIntervalSeconds = 36,
        MinIntervalSeconds = 12,
        EventTypes = {
            {
                id = "cold_spot",
                title = "Sudden Cold Spot",
                mapEventType = "TemperatureDrop",
                escalationWeight = {
                    Calm = 1.0,
                    Tension = 1.2,
                    Aggressive = 1.35,
                    Hunting = 1.5,
                },
            },
            {
                id = "emf_spike",
                title = "Unusual EMF Spike",
                mapEventType = "LightFlicker",
                escalationWeight = {
                    Calm = 0.9,
                    Tension = 1.1,
                    Aggressive = 1.3,
                    Hunting = 1.45,
                },
            },
            {
                id = "object_chain",
                title = "Object Chain Reaction",
                mapEventType = "ObjectThrow",
                escalationWeight = {
                    Calm = 0.8,
                    Tension = 1.2,
                    Aggressive = 1.4,
                    Hunting = 1.6,
                },
            },
            {
                id = "room_lockdown",
                title = "Room Lockdown",
                mapEventType = "DoorSlam",
                escalationWeight = {
                    Calm = 0.7,
                    Tension = 1.15,
                    Aggressive = 1.45,
                    Hunting = 1.75,
                },
            },
        },
    },

    SocialEmotes = {
        CooldownSeconds = 2,
        AllowedEmotes = {
            Wave = { id = "Wave", category = "LobbyAndMatch" },
            Point = { id = "Point", category = "LobbyAndMatch" },
            Scared = { id = "Scared", category = "LobbyAndMatch" },
            SilentSignal = { id = "SilentSignal", category = "LobbyAndMatch" },
        },
    },

    Reputation = {
        DefaultScore = 100,
        MinScore = 0,
        MaxScore = 500,
        Positive = {
            HelpTeammate = 4,
            CorrectGhostIdentification = 8,
            CompleteInvestigation = 12,
            SurviveAndExtract = 6,
        },
        Negative = {
            LeaveMatchEarly = -15,
            Griefing = -25,
            TeamSabotage = -30,
        },
        BadgeThresholds = {
            { score = 160, badgeId = "TrustedInvestigator" },
            { score = 240, badgeId = "EliteCooperator" },
        },
        CosmeticThresholds = {
            { score = 220, cosmeticId = "Reputation_Aura_Trusted" },
            { score = 300, cosmeticId = "Reputation_Badge_Heroic" },
        },
    },

    ContentPools = {
        GhostTypes = {
            "Pocong",
            "Kuntilanak",
            "Genderuwo",
            "Leak",
            "Banaspati",
            "Jerangkong",
        },
        EvidenceCombinations = {
            "EMF+Orb+Writing",
            "Freezing+SpiritBox+Fingerprints",
            "EMF+Freezing+SpiritBox",
        },
        MapPools = {
            Core = {
                "AbandonedPalace",
                "HauntedHouse",
                "EmptyBuilding",
                "StudioMMNineteen",
            },
            Event = {
                "HalloweenSchool",
                "AbandonedHospital",
                "RitualTemple",
            },
        },
    },
}

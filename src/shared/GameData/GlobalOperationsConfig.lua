return {
    ServerScaling = {
        Enabled = true,
        MaxPlayersPerServer = 40,
        TargetFillRatio = 0.72,
        Regions = { "us-east", "us-west", "eu-central", "asia-sg" },
        HealthWarningThreshold = {
            minPhysicsFps = 35,
            maxMemoryMb = 2600,
            maxNetworkLatencyMs = 240,
        },
    },

    Matchmaking = {
        LatencyWeight = 0.5,
        ExperienceWeight = 0.3,
        AvailabilityWeight = 0.2,
        PreferredPingMs = 120,
        MaxPingMs = 280,
        PartyPriorityBoost = 0.15,
    },

    Platform = {
        UiScale = {
            PC = 1.0,
            Mobile = 1.18,
            Console = 1.08,
            Unknown = 1.0,
        },
        PerformanceTier = {
            PC = "High",
            Mobile = "Medium",
            Console = "High",
            Unknown = "Medium",
        },
        VoiceChat = {
            RequireOptIn = true,
            RespectPrivacySettings = true,
        },
    },

    Moderation = {
        ReportCategories = {
            "Cheating",
            "Griefing",
            "AbusiveChat",
            "MatchSabotage",
        },
        DefaultMuteMinutes = 30,
        DefaultTempBanHours = 24,
        AutoActionThresholds = {
            Cheating = 4,
            Griefing = 6,
            AbusiveChat = 8,
            MatchSabotage = 5,
        },
        ChatFilter = {
            blockedWords = { "badword1", "badword2", "slur1" },
        },
    },

    LiveContent = {
        LivePatchingEnabled = true,
        CloudSyncEnabled = true,
        CommunityEvents = {
            DoubleXPWeekend = {
                enabled = false,
                rewardMultiplier = 2,
            },
            SpecialGhostEvent = {
                enabled = false,
                aggressionMultiplier = 1.2,
            },
        },
    },

    Commerce = {
        TradingEnabled = true,
        MarketplaceEnabled = true,
        TradeTimeoutSeconds = 120,
        TradeFeeCurrency = "MM",
        TradeFeeAmount = 50,
    },

    Seasons = {
        Enabled = true,
        CurrentSeasonId = "S1",
        SeasonLengthDays = 90,
        PassXpPerMatch = 120,
        PassXpPerObjective = 45,
    },

    Engagement = {
        ReturningPlayerDays = 7,
        ReturningPlayerReward = {
            currency = 650,
            xp = 220,
        },
        DiscoveryRetentionDays = 3,
    },

    QA = {
        AutomatedTestingEnabled = true,
        LoadTestEnabled = true,
        BackupIntervalSeconds = 300,
        ReleaseGateRequired = {
            stability = true,
            matchmaking = true,
            economy = true,
        },
    },
}

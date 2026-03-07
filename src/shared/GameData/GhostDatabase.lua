return {
    Revenant = {
        ghostName = "Revenant",
        evidenceTypes = { "GhostOrb", "WritingBook", "FreezingTemp" },
        behaviorTraits = { "SlowRoam", "FastHuntNearTarget", "DoorSlamBias" },
        aggressionRange = { min = 45, max = 85 },
    },
    Wraith = {
        ghostName = "Wraith",
        evidenceTypes = { "SpiritBox", "GhostOrb", "EMF5" },
        behaviorTraits = { "NoFootstepBias", "AggressiveManifest", "TargetSwap" },
        aggressionRange = { min = 35, max = 75 },
    },
    Shade = {
        ghostName = "Shade",
        evidenceTypes = { "WritingBook", "EMF5", "FreezingTemp" },
        behaviorTraits = { "PassiveSolo", "LowManifest", "LateHunt" },
        aggressionRange = { min = 20, max = 55 },
    },
    Oni = {
        ghostName = "Oni",
        evidenceTypes = { "SpiritBox", "WritingBook", "DOTS" },
        behaviorTraits = { "FrequentManifest", "NoiseBias", "HighPressure" },
        aggressionRange = { min = 50, max = 90 },
    },
}

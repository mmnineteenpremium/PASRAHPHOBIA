local EvidenceRules = {

    BolaArwah = {
        tool = "BolaArwah",
        roomRequired = true
    },

    BukuTerkutuk = {
        tool = "BukuTerkutuk",
        interaction = "GhostWriting"
    },

    GerakanGaib = {
        tool = "GerakanGaib",
        motionRequired = true
    },

    JejakEnergi = {
        tool = "JejakEnergi",
        surfaceTrace = true
    },

    KotakArwah = {
        tool = "KotakArwah",
        voiceResponse = true
    },

    SuhuMembeku = {
        tool = "Thermo",
        freezingTemp = true
    }

}

EvidenceRules.DifficultyModifiers = {
    Easy = {
        spawnChanceMultiplier = 1.15,
        fakeEvidenceChanceMultiplier = 0.75,
        validationTolerance = 1.2,
    },
    Normal = {
        spawnChanceMultiplier = 1.0,
        fakeEvidenceChanceMultiplier = 1.0,
        validationTolerance = 1.0,
    },
    Hard = {
        spawnChanceMultiplier = 0.85,
        fakeEvidenceChanceMultiplier = 1.25,
        validationTolerance = 0.9,
    },
}

return EvidenceRules

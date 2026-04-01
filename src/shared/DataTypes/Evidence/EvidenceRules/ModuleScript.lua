local EvidenceRules = {

    MEDOK = {
        tool = "JejakEnergi",
        surfaceTrace = true
    },

    Suhu = {
        tool = "SuhuMembeku",
        freezingTemp = true
    },

    BukuTerkutuk = {
        tool = "BukuTerkutuk",
        interaction = "BukuTerkutukWrite"
    },

    ["To'un"] = {
        tool = "BolaArwah",
        roomRequired = true
    },

    Suara = {
        tool = "KotakArwah",
        voiceResponse = true
    },

    Pengganggu = {
        tool = "GerakanGaib",
        motionRequired = true
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

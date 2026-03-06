local SpectatorDistortionRules = {}

SpectatorDistortionRules.Probabilities = {
    fake = 60,
    uncertain = 30,
    real = 10,
}

SpectatorDistortionRules.EventTypes = {
    fake = {
        "FakeGhostMovement",
        "FakeShadow",
        "FakeSound",
        "FakeObjectInteraction",
    },
    uncertain = {
        "AmbiguousShadow",
        "AmbiguousSound",
        "AmbiguousMovement",
    },
    real = {
        "RealGhostEvent",
    },
}

function SpectatorDistortionRules:GetProbability(outcome)
    return self.Probabilities[outcome] or 0
end

function SpectatorDistortionRules:GetOutcomes()
    return {
        "fake",
        "uncertain",
        "real",
    }
end

return SpectatorDistortionRules

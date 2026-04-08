-- MEDOK rarity visual VFX profile for runtime use in Roblox.
-- Focus zones: screen area + upper body edge.

return {
    R1 = {
        TierName = "B-ajah",
        GlowColor = Color3.fromRGB(178, 178, 186),
        Aura = {
            PulseMin = 0.06,
            PulseMax = 0.11,
            PulseSpeed = 1.4,
            Opacity = 0.22,
        },
        Spark = {
            Rate = 1.0,
            Lifetime = NumberRange.new(0.15, 0.30),
            Size = NumberSequence.new(0.03),
        },
        EmitZones = {"Screen", "TopBodyEdge"},
    },
    R2 = {
        TierName = "B-Lebih",
        GlowColor = Color3.fromRGB(77, 235, 108),
        Aura = {
            PulseMin = 0.08,
            PulseMax = 0.13,
            PulseSpeed = 1.6,
            Opacity = 0.25,
        },
        Spark = {
            Rate = 1.4,
            Lifetime = NumberRange.new(0.16, 0.32),
            Size = NumberSequence.new(0.035),
        },
        EmitZones = {"Screen", "TopBodyEdge"},
    },
    R3 = {
        TierName = "Lumayan",
        GlowColor = Color3.fromRGB(66, 168, 255),
        Aura = {
            PulseMin = 0.10,
            PulseMax = 0.16,
            PulseSpeed = 1.8,
            Opacity = 0.28,
        },
        Spark = {
            Rate = 1.8,
            Lifetime = NumberRange.new(0.17, 0.34),
            Size = NumberSequence.new(0.04),
        },
        EmitZones = {"Screen", "TopBodyEdge"},
    },
    R4 = {
        TierName = "Langka",
        GlowColor = Color3.fromRGB(184, 107, 255),
        Aura = {
            PulseMin = 0.11,
            PulseMax = 0.19,
            PulseSpeed = 2.0,
            Opacity = 0.32,
        },
        Spark = {
            Rate = 2.3,
            Lifetime = NumberRange.new(0.18, 0.38),
            Size = NumberSequence.new(0.045),
        },
        EmitZones = {"Screen", "TopBodyEdge"},
    },
    R5 = {
        TierName = "Gagah",
        GlowColor = Color3.fromRGB(255, 200, 80), -- gold/amber
        Aura = {
            PulseMin = 0.12, -- thin pulse
            PulseMax = 0.21,
            PulseSpeed = 2.2,
            Opacity = 0.36,
        },
        Spark = {
            Rate = 3.2, -- small intermittent sparks
            Lifetime = NumberRange.new(0.20, 0.42),
            Size = NumberSequence.new(0.05),
        },
        EmitZones = {"Screen", "TopBodyEdge"},
    },
}

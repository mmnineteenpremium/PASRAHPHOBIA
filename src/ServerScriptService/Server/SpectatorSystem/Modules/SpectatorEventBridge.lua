local SpectatorEventBridge = {}
SpectatorEventBridge.__index = SpectatorEventBridge

local EVENT_MAP = {
    PlayerKilled = "PlayerDied",
    SpectatorEntered = "PlayerEnteredSpectator",
    SpectatorVisionUpdated = "SpectatorGhostSeen",
    SpectatorVisionDistorted = "SpectatorDistortionGenerated",
}

function SpectatorEventBridge.new()
    local self = setmetatable({}, SpectatorEventBridge)
    return self
end

function SpectatorEventBridge:MapEvent(eventName)
    return EVENT_MAP[eventName] or eventName
end

function SpectatorEventBridge:MapPayload(eventName, payload)
    return {
        eventName = self:MapEvent(eventName),
        payload = payload,
    }
end

return SpectatorEventBridge

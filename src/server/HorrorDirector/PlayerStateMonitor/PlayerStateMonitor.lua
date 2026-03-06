local PlayerStateMonitor = {}
PlayerStateMonitor.__index = PlayerStateMonitor

function PlayerStateMonitor.new()
    local self = setmetatable({}, PlayerStateMonitor)
    return self
end

function PlayerStateMonitor:Evaluate(snapshot)
    local data = snapshot or {}
    return {
        lowSanity = data.lowSanity == true,
        isolated = data.isolated == true,
        longSilence = data.longSilence == true,
        failedInvestigation = data.failedInvestigation == true,
        spectatorHints = data.spectatorHints == true,
    }
end

return PlayerStateMonitor

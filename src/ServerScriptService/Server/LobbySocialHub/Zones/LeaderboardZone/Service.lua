local Service = {}
Service.__index = Service

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    return self
end

function Service:Init()
    self._state:Set("status", "initialized")
end

function Service:Start()
    self._state:Set("status", "running")
end

function Service:Stop()
    self._state:Set("status", "stopped")
end

function Service:TrackEntry(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return false, "invalid_player"
    end

    local visitors = self._state:Get("visitorsByUserId")
    visitors[player.UserId] = true
    self._state:Set("lastEnteredUserId", player.UserId)
    return true
end

return Service
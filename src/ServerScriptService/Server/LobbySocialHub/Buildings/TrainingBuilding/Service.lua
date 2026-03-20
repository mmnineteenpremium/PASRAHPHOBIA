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
    local activeUserIds = self._state:Get("activeUserIds")
    table.clear(activeUserIds)
end

function Service:MarkPlayerActive(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return false, "invalid_player"
    end

    local activeUserIds = self._state:Get("activeUserIds")
    activeUserIds[player.UserId] = true
    self._state:Set("lastActiveUserId", player.UserId)
    return true
end

return Service
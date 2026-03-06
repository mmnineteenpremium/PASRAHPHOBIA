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
    local playersInLobby = self._state:Get("playersInLobby")
    table.clear(playersInLobby)
end

function Service:EnterLobby(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return false, "invalid_player"
    end

    local playersInLobby = self._state:Get("playersInLobby")
    playersInLobby[player.UserId] = true
    return true
end

return Service
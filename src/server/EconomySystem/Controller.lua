local Controller = {}
Controller.__index = Controller

local function resolvePlayersService(deps)
    if deps.Players then
        return deps.Players
    end
    return game:GetService("Players")
end

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._playersService = resolvePlayersService(self._deps)
    self._connections = {}
    return self
end

function Controller:Init()
    -- Placeholder for future controller wiring.
end

function Controller:RegisterEventHandlers()
    if not self._playersService then
        return
    end

    table.insert(self._connections, self._playersService.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded({
            player = player,
        })
    end))

    table.insert(self._connections, self._playersService.PlayerRemoving:Connect(function(player)
        self:OnPlayerRemoving({
            player = player,
        })
    end))

    for _, player in ipairs(self._playersService:GetPlayers()) do
        self:OnPlayerAdded({
            player = player,
        })
    end
end

function Controller:UnregisterEventHandlers()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
end

function Controller:OnPlayerAdded(payload)
    local player = payload and payload.player
    if not player then
        return
    end
    self._service:RegisterPlayer(player)
end

function Controller:OnPlayerRemoving(payload)
    local player = payload and payload.player
    if not player then
        return
    end
    self._service:RemovePlayer(player)
end

return Controller

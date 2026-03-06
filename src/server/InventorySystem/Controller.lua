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
    -- Inventory wiring can be expanded when needed.
end

function Controller:RegisterEventHandlers()
    if not self._playersService then
        return
    end

    table.insert(self._connections, self._playersService.PlayerAdded:Connect(function(player)
        self:OnPlayerAdded(player)
    end))

    table.insert(self._connections, self._playersService.PlayerRemoving:Connect(function(player)
        self:OnPlayerRemoving(player)
    end))

    for _, player in ipairs(self._playersService:GetPlayers()) do
        self:OnPlayerAdded(player)
    end
end

function Controller:UnregisterEventHandlers()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
end

function Controller:OnPlayerAdded(player)
    if not player then
        return
    end
    self._service:LoadPlayerData(player)
end

function Controller:OnPlayerRemoving(player)
    if not player then
        return
    end
end

return Controller

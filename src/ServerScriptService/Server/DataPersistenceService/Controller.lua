local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Controller = {}
Controller.__index = Controller

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._playersService = self._deps.Players or Players
    self._runService = self._deps.RunService or RunService
    self._connections = {}
    self._handlersRegistered = false
    return self
end

function Controller:Init()
    -- Data persistence controller can be extended if needed.
end

function Controller:RegisterEventHandlers()
    if self._handlersRegistered then
        return
    end

    if self._playersService then
        table.insert(self._connections, self._playersService.PlayerAdded:Connect(function(player)
            self._service:RegisterPlayer(player)
        end))
        table.insert(self._connections, self._playersService.PlayerRemoving:Connect(function(player)
            self._service:SavePlayer(player)
            self._service:UnregisterPlayer(player)
        end))
        for _, player in ipairs(self._playersService:GetPlayers()) do
            self._service:RegisterPlayer(player)
        end
    end

    if self._runService then
        table.insert(self._connections, self._runService.Heartbeat:Connect(function(delta)
            self._service:AutosaveTick(delta)
        end))
    end

    self._handlersRegistered = true
end

function Controller:UnregisterEventHandlers()
    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end
    table.clear(self._connections)
    self._handlersRegistered = false
end

return Controller

local Services = require(script.Parent.Parent.Core.Services)

local Controller = {}
Controller.__index = Controller

local REMOTE_NAME = "FlashlightEvent"

local function resolvePlayers(deps)
    return deps and deps.Players or game:GetService("Players")
end

local function resolveRemote(deps)
    if deps and deps.FlashlightRemote then
        return deps.FlashlightRemote
    end
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local remoteFolder = replicatedStorage:WaitForChild("RemoteEvents")
    local remote = remoteFolder:WaitForChild(REMOTE_NAME)
    return remote
end

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._players = resolvePlayers(self._deps)
    self._remote = nil
    self._connections = {}
    self._registered = false
    return self
end

function Controller:Init()
    self._remote = resolveRemote(self._deps)
end

function Controller:Start()
    self:RegisterEventHandlers()
end

function Controller:Stop()
    self:UnregisterEventHandlers()
end

function Controller:RegisterEventHandlers()
    if self._registered then
        return
    end

    if self._remote then
        table.insert(self._connections, self._remote.OnServerEvent:Connect(function(player, payload)
            self._service:HandleRemote(player, payload)
        end))
    end

    if self._players then
        table.insert(self._connections, self._players.PlayerAdded:Connect(function(player)
            self._service:OnPlayerAdded(player)
        end))
        table.insert(self._connections, self._players.PlayerRemoving:Connect(function(player)
            self._service:OnPlayerRemoving(player)
        end))

        for _, player in ipairs(self._players:GetPlayers()) do
            self._service:OnPlayerAdded(player)
        end
    end

    self._registered = true
end

function Controller:UnregisterEventHandlers()
    if not self._registered then
        return
    end

    for _, connection in ipairs(self._connections) do
        connection:Disconnect()
    end

    table.clear(self._connections)
    self._registered = false
end

return Controller

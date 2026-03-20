local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local LobbySystem = {}
LobbySystem.__index = LobbySystem

function LobbySystem.new(deps)
    local self = setmetatable({}, LobbySystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function LobbySystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function LobbySystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function LobbySystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function LobbySystem:Shutdown()
    self:Stop()
end

return LobbySystem

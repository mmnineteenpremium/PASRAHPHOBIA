local State = require(script.Parent.State)
local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)

local PlayerPresence = {}
PlayerPresence.__index = PlayerPresence

function PlayerPresence.new(deps)
    local self = setmetatable({}, PlayerPresence)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function PlayerPresence:Init()
    self.Service:Init()
    self.Controller:Init()
end

function PlayerPresence:Start()
    self.Service:Start()
end

function PlayerPresence:Stop()
    self.Service:Stop()
end

return PlayerPresence
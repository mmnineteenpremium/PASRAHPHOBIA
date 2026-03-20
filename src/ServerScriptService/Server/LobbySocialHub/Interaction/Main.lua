local State = require(script.Parent.State)
local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)

local Interaction = {}
Interaction.__index = Interaction

function Interaction.new(deps)
    local self = setmetatable({}, Interaction)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function Interaction:Init()
    self.Service:Init()
    self.Controller:Init()
end

function Interaction:Start()
    self.Service:Start()
end

function Interaction:Stop()
    self.Service:Stop()
end

return Interaction
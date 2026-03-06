local State = require(script.Parent.State)
local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)

local Building = {}
Building.__index = Building

function Building.new(deps)
    local self = setmetatable({}, Building)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function Building:Init()
    self.Service:Init()
    self.Controller:Init()
end

function Building:Start()
    self.Service:Start()
end

function Building:Stop()
    self.Service:Stop()
end

return Building
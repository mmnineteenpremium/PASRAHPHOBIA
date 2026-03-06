local State = require(script.Parent.State)
local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)

local Zone = {}
Zone.__index = Zone

function Zone.new(deps)
    local self = setmetatable({}, Zone)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function Zone:Init()
    self.Service:Init()
    self.Controller:Init()
end

function Zone:Start()
    self.Service:Start()
end

function Zone:Stop()
    self.Service:Stop()
end

return Zone
local State = require(script.Parent.State)
local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)

local PartySystemModule = {}
PartySystemModule.__index = PartySystemModule

function PartySystemModule.new(deps)
    local self = setmetatable({}, PartySystemModule)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function PartySystemModule:Init()
    self.Service:Init()
    self.Controller:Init()
end

function PartySystemModule:Start()
    self.Service:Start()
end

function PartySystemModule:Stop()
    self.Service:Stop()
end

return PartySystemModule
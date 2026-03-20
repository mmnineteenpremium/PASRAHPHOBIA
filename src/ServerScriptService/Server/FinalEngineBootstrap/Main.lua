local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local FinalEngineBootstrap = {}
FinalEngineBootstrap.__index = FinalEngineBootstrap

function FinalEngineBootstrap.new(deps)
    local self = setmetatable({}, FinalEngineBootstrap)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function FinalEngineBootstrap:Init()
    self.Service:Init()
    self.Controller:Init()
end

function FinalEngineBootstrap:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function FinalEngineBootstrap:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return FinalEngineBootstrap

local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local EngineStartupValidator = {}
EngineStartupValidator.__index = EngineStartupValidator

function EngineStartupValidator.new(deps)
    local self = setmetatable({}, EngineStartupValidator)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function EngineStartupValidator:Init()
    self.Service:Init()
    self.Controller:Init()
end

function EngineStartupValidator:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function EngineStartupValidator:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return EngineStartupValidator

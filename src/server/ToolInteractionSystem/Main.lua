local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local ToolInteractionSystem = {}
ToolInteractionSystem.__index = ToolInteractionSystem

function ToolInteractionSystem.new(deps)
    local self = setmetatable({}, ToolInteractionSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function ToolInteractionSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function ToolInteractionSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function ToolInteractionSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return ToolInteractionSystem

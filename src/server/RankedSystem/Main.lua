local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local RankedSystem = {}
RankedSystem.__index = RankedSystem

function RankedSystem.new(deps)
    local self = setmetatable({}, RankedSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function RankedSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function RankedSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function RankedSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return RankedSystem

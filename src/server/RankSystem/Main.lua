local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local RankSystem = {}
RankSystem.__index = RankSystem

function RankSystem.new(deps)
    local self = setmetatable({}, RankSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.RankState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function RankSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function RankSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function RankSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return RankSystem

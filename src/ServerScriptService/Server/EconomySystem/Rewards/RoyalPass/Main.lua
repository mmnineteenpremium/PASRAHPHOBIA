local State = require(script.Parent.State)
local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)

local RoyalPass = {}
RoyalPass.__index = RoyalPass

function RoyalPass.new(deps)
    local self = setmetatable({}, RoyalPass)
    self._deps = deps or {}
    self.State = State.new(self._deps.RoyalPassState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function RoyalPass:Init()
    self.Service:Init()
    self.Controller:Init()
end

function RoyalPass:Start()
    self.Service:Start()
end

function RoyalPass:Stop()
    self.Service:Stop()
end

return RoyalPass

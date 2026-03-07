local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local SocialCommerceSystem = {}
SocialCommerceSystem.__index = SocialCommerceSystem

function SocialCommerceSystem.new(deps)
    local self = setmetatable({}, SocialCommerceSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.SocialCommerceState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function SocialCommerceSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function SocialCommerceSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function SocialCommerceSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

return SocialCommerceSystem

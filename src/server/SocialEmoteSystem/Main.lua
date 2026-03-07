local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local SocialEmoteSystem = {}
SocialEmoteSystem.__index = SocialEmoteSystem

function SocialEmoteSystem.new(deps)
    local self = setmetatable({}, SocialEmoteSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.SocialEmoteState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function SocialEmoteSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function SocialEmoteSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function SocialEmoteSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

function SocialEmoteSystem:RequestEmote(player, payload)
    return self.Service:RequestEmote(player, payload)
end

return SocialEmoteSystem

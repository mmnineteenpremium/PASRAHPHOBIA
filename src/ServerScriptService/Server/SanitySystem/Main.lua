local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local SanitySystem = {}
SanitySystem.__index = SanitySystem

function SanitySystem.new(deps)
    local self = setmetatable({}, SanitySystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function SanitySystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function SanitySystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function SanitySystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function SanitySystem:GetSanity(player, matchId)
    return self.Service:GetSanity(player, matchId)
end

function SanitySystem:DrainSanity(player, amount, matchId, reason)
    return self.Service:DrainSanity(player, amount, matchId, reason)
end

function SanitySystem:RestoreSanity(player, amount, matchId, reason)
    return self.Service:RestoreSanity(player, amount, matchId, reason)
end

function SanitySystem:GetAverageTeamSanity(matchId)
    return self.Service:GetAverageTeamSanity(matchId)
end

return SanitySystem

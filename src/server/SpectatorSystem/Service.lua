local SpectatorService = require(script.Parent.SpectatorService)

local Service = {}
Service.__index = Service

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._spectatorService = SpectatorService.new(self._state, self._deps)
    return self
end

function Service:Init()
    self._spectatorService:Init()
end

function Service:Start()
    self._spectatorService:Start()
end

function Service:Stop()
    self._spectatorService:Stop()
end

function Service:StartMatch(matchId, payload)
    return self._spectatorService:StartMatch(matchId, payload)
end

function Service:EndMatch(matchId)
    self._spectatorService:EndMatch(matchId)
end

function Service:EnterSpectator(player, matchId, payload)
    return self._spectatorService:EnterSpectator(player, matchId, payload)
end

function Service:ExitSpectator(player, matchId)
    return self._spectatorService:ExitSpectator(player, matchId)
end

function Service:GetSpectatorTarget(player, matchId)
    return self._spectatorService:GetSpectatorTarget(player, matchId)
end

function Service:SwitchSpectatorTarget(player, matchId, direction)
    return self._spectatorService:SwitchSpectatorTarget(player, matchId, direction)
end

function Service:ProcessGhostActivity(matchId, payload)
    return self._spectatorService:ProcessGhostActivity(matchId, payload)
end

function Service:GetSpectatorVision(player, matchId)
    return self._spectatorService:GetSpectatorVision(player, matchId)
end

function Service:GetCommunicationContext(player, matchId)
    return self._spectatorService:GetCommunicationContext(player, matchId)
end

return Service


local Service = {}
Service.__index = Service

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    return self
end

function Service:Init()
    -- placeholder for init logic
end

function Service:Start()
    -- start listening for match results
end


function Service:GrantMatchReward(player, performancePercent)
    local economyService = self._deps.CurrencyService
    if not economyService then
        return
    end
    local entry = player and {
        player = player,
        userId = player.UserId,
        performancePercent = performancePercent,
    } or nil
    local payload = {
        entry = entry,
        matchId = self._deps.MatchId,
        reason = "MatchCompletion",
    }
    economyService:GrantMatchReward(payload)
end

return Service

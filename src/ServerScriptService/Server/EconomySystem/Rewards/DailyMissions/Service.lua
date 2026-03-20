local Service = {}
Service.__index = Service
local Services = require(script.Parent.Parent.Parent.Parent.Core.Services)

local MISSION_REWARD = 1000
local ALL_BONUS = 2000

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = Services.Get(self._deps, "EventBus")
    return self
end

function Service:Init()
    self._state:Set("status", "initialized")
end

function Service:Start()
    self._state:Set("status", "running")
end

function Service:Stop()
    self._state:Set("status", "stopped")
end

function Service:CompleteMission(player)
    local missionCount = self._state:Get("missionsCompleted")
    if missionCount >= self._state:Get("dailyMissionLimit") then
        return false, "limit_reached"
    end

    local ok, err, amount = false, nil, 0
    if self._deps.CurrencyService then
        ok, err, amount = self._deps.CurrencyService:GrantMissionCompleted(player)
    else
        ok = true
    end

    if not ok then
        return ok, err
    end

    missionCount += 1
    self._state:Set("missionsCompleted", missionCount)

    if self._eventBus then
        self._eventBus:Publish("MissionCompleted", {
            player = player,
            amount = amount,
            missionCount = missionCount,
        })
    end
    return true, nil, amount
end

function Service:CompleteAllMissions(player)
    if self._state:Get("allMissionsClaimed") then
        return false, "already_claimed"
    end

    local ok, err, amount = false, nil, 0
    if self._deps.CurrencyService then
        ok, err, amount = self._deps.CurrencyService:GrantAllMissionsCompleted(player)
    else
        ok = true
    end

    if not ok then
        return ok, err
    end

    self._state:Set("allMissionsClaimed", true)
    return true, nil, amount
end

return Service

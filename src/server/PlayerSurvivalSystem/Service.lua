local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
    if type(eventBus) ~= "table" then return nil end
    if type(eventBus.Publish) == "function" then return eventBus end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then return eventBus.Service end
    return nil
end

local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then return playerOrUserId end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then return playerOrUserId.UserId end
    return nil
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {}
    return self
end

function Service:Init()
    self._dependencies = {
        GhostSystem = Services.Get(self._deps, "GhostSystem"),
        InvestigationSystem = Services.Get(self._deps, "InvestigationSystem"),
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
        EconomySystem = Services.Get(self._deps, "EconomySystem"),
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
    }
end

function Service:Start() end
function Service:Stop() self._state:Clear() end

function Service:_publish(eventName, payload)
    if self._eventBus then self._eventBus:Publish(eventName, payload) end
end

function Service:HandleEvent(eventName, payload)
    if eventName == "MatchStarted" then
        self._state:Set("activeMatchId", payload and payload.matchId)
    elseif eventName == "MatchEnded" then
        self._state:Set("activeMatchId", nil)
    end
    if eventName == "MatchStarted" then
        self._state:Set("playerSurvival", {})
    elseif eventName == "PlayerSanityChanged" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        if userId then
            local data = self._state:Get("playerSurvival") or {}
            data[userId] = data[userId] or { alive = true, survivalTime = 0, danger = 0 }
            data[userId].danger = math.clamp((100 - (tonumber(payload.sanity) or 100)) / 100, 0, 1)
            self._state:Set("playerSurvival", data)
        end
    elseif eventName == "GhostInteraction" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        if userId then
            local data = self._state:Get("playerSurvival") or {}
            data[userId] = data[userId] or { alive = true, survivalTime = 0, danger = 0 }
            if payload and payload.action == "GhostNear" then
                data[userId].danger = math.clamp((data[userId].danger or 0) + 0.15, 0, 1)
            end
            self._state:Set("playerSurvival", data)
        end
    elseif eventName == "GameplayTick" then
        local dt = tonumber(payload and payload.dt) or 1
        local data = self._state:Get("playerSurvival") or {}
        for _, entry in pairs(data) do
            if entry.alive ~= false then
                entry.survivalTime = (entry.survivalTime or 0) + dt
            end
        end
        self._state:Set("playerSurvival", data)
    elseif eventName == "PlayerDied" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        local data = self._state:Get("playerSurvival") or {}
        if userId and data[userId] then data[userId].alive = false; self._state:Set("playerSurvival", data) end
    elseif eventName == "PlayerDisconnected" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        local data = self._state:Get("playerSurvival") or {}
        if userId then data[userId] = nil; self._state:Set("playerSurvival", data) end
    end
end

return Service

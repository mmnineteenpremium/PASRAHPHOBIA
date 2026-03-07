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
    if eventName == "MatchStarted" then self._state:Set("activeMatchId", payload and payload.matchId)
    elseif eventName == "MatchEnded" then self._state:Set("activeMatchId", nil) end
    if eventName == "MatchStarted" then
        self._state:Set("playerOutcome", {})
    elseif eventName == "PlayerDied" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        if userId then
            local outcome = self._state:Get("playerOutcome") or {}
            outcome[userId] = outcome[userId] or {}
            outcome[userId].survived = false
            self._state:Set("playerOutcome", outcome)
        end
    elseif eventName == "MatchEnded" then
        local result = {
            matchId = payload and payload.matchId or self._state:Get("activeMatchId"),
            contractSuccess = payload and payload.contractSuccess,
            ghostIdentified = payload and payload.ghostIdentified,
            playerOutcome = self._state:Get("playerOutcome") or {},
        }
        self._state:Set("lastResult", result)
        self:_publish("MatchCompleted", result)
    elseif eventName == "ContractCompletionEvaluated" then
        local last = self._state:Get("lastResult") or {}
        last.contractSuccess = payload and payload.contractSuccess
        last.objectivesCompleted = payload and payload.objectivesCompleted
        self._state:Set("lastResult", last)
    end
end
return Service

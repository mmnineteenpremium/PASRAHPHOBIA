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
    end
    if eventName == "MatchStarted" then
        self._state:Set("objectivesCompleted", 0)
        self._state:Set("ghostIdentified", false)
        self._state:Set("playersExtracted", 0)
        self._state:Set("contractSuccess", false)
    elseif eventName == "GhostIdentified" then
        self._state:Set("ghostIdentified", true)
    elseif eventName == "ObjectiveCompleted" then
        local total = (self._state:Get("objectivesCompleted") or 0) + 1
        self._state:Set("objectivesCompleted", total)
    elseif eventName == "PlayerEscapedHunt" then
        local total = (self._state:Get("playersExtracted") or 0) + 1
        self._state:Set("playersExtracted", total)
    elseif eventName == "MatchEnded" then
        local matchId = (payload and payload.matchId) or self._state:Get("activeMatchId")
        local success = (self._state:Get("ghostIdentified") == true) and ((self._state:Get("objectivesCompleted") or 0) >= 1) and ((self._state:Get("playersExtracted") or 0) >= 1)
        self._state:Set("contractSuccess", success)
        self:_publish("ContractCompletionEvaluated", { matchId = matchId, contractSuccess = success, ghostIdentified = self._state:Get("ghostIdentified"), objectivesCompleted = self._state:Get("objectivesCompleted"), playersExtracted = self._state:Get("playersExtracted") })
        self._state:Set("activeMatchId", nil)
    end
end
return Service

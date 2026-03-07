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
        self._state:Set("currentPhase", "Preparation")
        self._state:Set("phaseStartAt", os.clock())
        self:_publish("GameplayPhaseChanged", { matchId = self._state:Get("activeMatchId"), phase = "Preparation" })
    elseif eventName == "GameplayTick" then
        local phase = self._state:Get("currentPhase")
        local elapsed = os.clock() - (self._state:Get("phaseStartAt") or os.clock())
        if phase == "Preparation" and elapsed >= 20 then
            self._state:Set("currentPhase", "Investigation")
            self._state:Set("phaseStartAt", os.clock())
            self:_publish("GameplayPhaseChanged", { matchId = self._state:Get("activeMatchId"), phase = "Investigation" })
        elseif phase == "Extraction" and elapsed >= 20 then
            self._state:Set("currentPhase", "Result")
            self._state:Set("phaseStartAt", os.clock())
            self:_publish("GameplayPhaseChanged", { matchId = self._state:Get("activeMatchId"), phase = "Result" })
        end
    elseif eventName == "HuntStarted" then
        self._state:Set("currentPhase", "Hunt")
        self._state:Set("phaseStartAt", os.clock())
        self:_publish("GameplayPhaseChanged", { matchId = self._state:Get("activeMatchId"), phase = "Hunt" })
    elseif eventName == "HuntEnded" then
        self._state:Set("currentPhase", "Extraction")
        self._state:Set("phaseStartAt", os.clock())
        self:_publish("GameplayPhaseChanged", { matchId = self._state:Get("activeMatchId"), phase = "Extraction" })
    elseif eventName == "MatchCompleted" then
        self._state:Set("currentPhase", "Result")
        self._state:Set("phaseStartAt", os.clock())
        self:_publish("GameplayPhaseChanged", { matchId = self._state:Get("activeMatchId"), phase = "Result" })
    elseif eventName == "MatchEnded" then
        self._state:Set("currentPhase", "Lobby")
        self._state:Set("phaseStartAt", os.clock())
        self:_publish("GameplayPhaseChanged", { matchId = nil, phase = "Lobby" })
    end
end
return Service

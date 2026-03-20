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
    if eventName == "HuntStarted" then
        self._state:Set("huntPhase", "Warning")
        self._state:Set("phaseTimer", 5)
        self:_publish("HuntPhaseChanged", { matchId = self._state:Get("activeMatchId"), phase = "Warning" })
    elseif eventName == "GameplayTick" then
        local timer = tonumber(self._state:Get("phaseTimer")) or 0
        if timer > 0 then
            timer -= (tonumber(payload and payload.dt) or 1)
            self._state:Set("phaseTimer", timer)
            if timer <= 0 then
                local current = self._state:Get("huntPhase")
                if current == "Warning" then
                    self._state:Set("huntPhase", "Chase")
                    self._state:Set("phaseTimer", 30)
                    self:_publish("HuntPhaseChanged", { matchId = self._state:Get("activeMatchId"), phase = "Chase" })
                elseif current == "Chase" then
                    self._state:Set("huntPhase", "Cooldown")
                    self._state:Set("phaseTimer", 10)
                    self:_publish("HuntPhaseChanged", { matchId = self._state:Get("activeMatchId"), phase = "Cooldown" })
                elseif current == "Cooldown" then
                    self._state:Set("huntPhase", "Idle")
                    self:_publish("HuntPhaseChanged", { matchId = self._state:Get("activeMatchId"), phase = "Idle" })
                end
            end
        end
    elseif eventName == "HuntEnded" then
        self._state:Set("huntPhase", "Idle")
        self._state:Set("phaseTimer", 0)
        self:_publish("HuntPhaseChanged", { matchId = self._state:Get("activeMatchId"), phase = "Idle" })
    end
end

return Service

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
        self._state:Set("rewardHistory", {})
    elseif eventName == "MatchCompleted" then
        local difficulty = payload and (payload.difficulty or "Normal") or "Normal"
        local difficultyMultiplier = ({ Easy = 1.0, Normal = 1.2, Hard = 1.5, Nightmare = 2.0 })[difficulty] or 1.2
        local rewards = {}
        for userId, playerOutcome in pairs(payload and payload.playerOutcome or {}) do
            local base = 100
            local survivedBonus = (playerOutcome.survived == false) and 0 or 50
            local identifiedBonus = payload and payload.ghostIdentified and 100 or 0
            local contractBonus = payload and payload.contractSuccess and 150 or 0
            local amount = math.floor((base + survivedBonus + identifiedBonus + contractBonus) * difficultyMultiplier)
            rewards[userId] = { currency = "MM", amount = amount, xp = math.max(1, math.floor(amount / 10)) }
        end
        local history = self._state:Get("rewardHistory") or {}
        table.insert(history, { matchId = payload and payload.matchId, rewards = rewards, at = os.clock() })
        self._state:Set("rewardHistory", history)
        self:_publish("RewardsGranted", { matchId = payload and payload.matchId, rewards = rewards, sourceSystem = "RewardCalculationSystem" })
    end
end
return Service

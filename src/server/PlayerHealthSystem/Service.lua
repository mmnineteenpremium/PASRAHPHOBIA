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
        self._state:Set("playerHealth", {})
    elseif eventName == "GhostInteraction" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        if not userId then return end
        local healthMap = self._state:Get("playerHealth") or {}
        local health = healthMap[userId]
        if type(health) ~= "number" then health = 100 end
        if payload and payload.action == "Attack" then
            health -= (tonumber(payload.damage) or 25)
            healthMap[userId] = math.max(health, 0)
            self._state:Set("playerHealth", healthMap)
            self:_publish("PlayerHealthChanged", { userId = userId, player = payload.player, health = healthMap[userId], matchId = self._state:Get("activeMatchId") })
            if healthMap[userId] <= 0 then
                self:_publish("PlayerDied", { userId = userId, player = payload.player, reason = "ghost_attack", matchId = self._state:Get("activeMatchId") })
            end
        end
    elseif eventName == "PlayerDisconnected" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        local healthMap = self._state:Get("playerHealth") or {}
        if userId then healthMap[userId] = nil; self._state:Set("playerHealth", healthMap) end
    end
end
return Service

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
        self._state:Set("hiddenPlayers", {})
        self._state:Set("detectedPlayers", {})
    elseif eventName == "PlayerAttemptHide" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        if userId then
            local hidden = self._state:Get("hiddenPlayers") or {}
            hidden[userId] = { spotType = payload.spotType or "Unknown", noise = tonumber(payload.noiseLevel) or 0, movement = tonumber(payload.movementLevel) or 0, enteredAt = os.clock() }
            self._state:Set("hiddenPlayers", hidden)
            self:_publish("PlayerHid", { userId = userId, player = payload.player, spotType = hidden[userId].spotType, matchId = self._state:Get("activeMatchId") })
        end
    elseif eventName == "PlayerExitHide" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        local hidden = self._state:Get("hiddenPlayers") or {}
        if userId then
            hidden[userId] = nil
            self._state:Set("hiddenPlayers", hidden)
            self:_publish("PlayerRevealed", { userId = userId, player = payload.player, matchId = self._state:Get("activeMatchId") })
        end
    elseif eventName == "GhostInteraction" and payload and payload.action == "GhostNearHidingSpot" then
        local hidden = self._state:Get("hiddenPlayers") or {}
        for userId, data in pairs(hidden) do
            local score = (tonumber(data.noise) or 0) + (tonumber(data.movement) or 0) + (tonumber(payload.proximity) or 0)
            if score >= 1.5 then
                local detected = self._state:Get("detectedPlayers") or {}
                detected[userId] = true
                self._state:Set("detectedPlayers", detected)
                self:_publish("PlayerHidingDetected", { userId = userId, matchId = self._state:Get("activeMatchId") })
            end
        end
    end
end
return Service

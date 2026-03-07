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
        self._state:Set("closetOccupancy", {})
    elseif eventName == "PlayerAttemptHide" then
        if payload and payload.spotType ~= "Closet" and payload.spotType ~= "Locker" then return end
        local userId = toUserId(payload and (payload.player or payload.userId))
        if userId then
            local occupancy = self._state:Get("closetOccupancy") or {}
            local closetId = payload.closetId or ("closet_" .. tostring(userId))
            occupancy[closetId] = userId
            self._state:Set("closetOccupancy", occupancy)
            self:_publish("ClosetHideEntered", { userId = userId, player = payload.player, closetId = closetId, matchId = self._state:Get("activeMatchId") })
        end
    elseif eventName == "PlayerExitHide" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        local occupancy = self._state:Get("closetOccupancy") or {}
        if userId then
            for closetId, occupantId in pairs(occupancy) do
                if occupantId == userId then
                    occupancy[closetId] = nil
                    self:_publish("ClosetHideExited", { userId = userId, player = payload.player, closetId = closetId, matchId = self._state:Get("activeMatchId") })
                end
            end
            self._state:Set("closetOccupancy", occupancy)
        end
    end
end
return Service

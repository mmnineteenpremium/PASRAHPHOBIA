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
    if eventName == "GhostChaseStarted" then
        local userId = toUserId(payload and (payload.player or payload.userId)) or (payload and payload.userId)
        local path = { targetUserId = userId, nodes = { "ghost_origin", "hallway", "target_last_known" }, chaseSpeed = payload and payload.chaseSpeed or 1 }
        self._state:Set("activePath", path)
        self._state:Set("lastPathUpdateAt", os.clock())
        self:_publish("GhostPathUpdated", { matchId = self._state:Get("activeMatchId"), targetUserId = userId, nodes = path.nodes, chaseSpeed = path.chaseSpeed })
    elseif eventName == "GhostTargetLost" then
        self._state:Set("activePath", {})
        self._state:Set("lastPathUpdateAt", os.clock())
    elseif eventName == "GameplayTick" then
        local path = self._state:Get("activePath")
        if type(path) == "table" and path.targetUserId then self._state:Set("lastPathUpdateAt", os.clock()) end
    end
end
return Service

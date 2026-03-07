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
    if eventName == "PlayerSanityChanged" then
        local sanity = tonumber(payload and payload.sanity) or 100
        local now = os.clock()
        if sanity <= 35 and self._state:Get("huntActive") ~= true and now >= (self._state:Get("huntCooldownUntil") or 0) then
            self._state:Set("huntActive", true)
            self._state:Set("huntTimer", 45)
            self._state:Set("huntIntensity", math.clamp((35 - sanity) / 35, 0.2, 1))
            self:_publish("HuntStarted", { matchId = self._state:Get("activeMatchId"), reason = "low_sanity", intensity = self._state:Get("huntIntensity") })
        end
    elseif eventName == "GhostInteraction" and self._state:Get("huntActive") == true then
        local nextIntensity = math.clamp((self._state:Get("huntIntensity") or 0.2) + 0.1, 0, 1)
        self._state:Set("huntIntensity", nextIntensity)
        self:_publish("HuntIntensityChanged", { matchId = self._state:Get("activeMatchId"), intensity = nextIntensity })
    elseif eventName == "GameplayTick" and self._state:Get("huntActive") == true then
        local dt = tonumber(payload and payload.dt) or 1
        local nextTimer = (self._state:Get("huntTimer") or 0) - dt
        self._state:Set("huntTimer", nextTimer)
        if nextTimer <= 0 then
            self._state:Set("huntActive", false)
            self._state:Set("huntTimer", 0)
            self._state:Set("huntCooldownUntil", os.clock() + 20)
            self:_publish("HuntEnded", { matchId = self._state:Get("activeMatchId"), reason = "timer_elapsed" })
        end
    end
end

return Service

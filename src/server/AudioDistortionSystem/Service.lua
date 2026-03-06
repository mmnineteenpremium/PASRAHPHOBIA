local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
    if type(eventBus) ~= "table" then
        return nil
    end
    if type(eventBus.Publish) == "function" then
        return eventBus
    end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then
        return eventBus.Service
    end
    return nil
end

local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then
        return playerOrUserId
    end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId.UserId
    end
    return nil
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    return self
end

function Service:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        SanitySystem = Services.Get(self._deps, "SanitySystem"),
        HorrorDirector = Services.Get(self._deps, "HorrorDirector"),
        GhostSystem = Services.Get(self._deps, "GhostSystem"),
        MapEventSystem = Services.Get(self._deps, "MapEventSystem"),
    }
end

function Service:Init()
    self._state:Set("distortionIntensity", self._state:Get("distortionIntensity") or {})
    self._state:Set("activeDistortions", self._state:Get("activeDistortions") or {})
end

function Service:Start()
    -- Event-driven service.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_stopForUser(userId, reason)
    local intensityMap = self._state:Get("distortionIntensity") or {}
    local activeMap = self._state:Get("activeDistortions") or {}
    local previousIntensity = intensityMap[userId] or 0
    intensityMap[userId] = 0
    activeMap[userId] = nil
    self._state:Set("distortionIntensity", intensityMap)
    self._state:Set("activeDistortions", activeMap)

    self:_publish("AudioDistortionStopped", {
        userId = userId,
        previousIntensity = previousIntensity,
        reason = reason or "fear_low",
    })
end

function Service:OnFearLevelUpdated(payload)
    if type(payload) ~= "table" then
        return
    end

    local userId = toUserId(payload.player or payload.userId)
    if not userId then
        return
    end

    local fearLevel = math.max(0, math.min(100, tonumber(payload.fearLevel) or 0))
    local newIntensity = fearLevel / 100

    local intensityMap = self._state:Get("distortionIntensity") or {}
    local activeMap = self._state:Get("activeDistortions") or {}

    local oldIntensity = intensityMap[userId] or 0

    if fearLevel >= 35 then
        intensityMap[userId] = newIntensity
        activeMap[userId] = {
            startedAt = activeMap[userId] and activeMap[userId].startedAt or os.clock(),
            lastUpdate = os.clock(),
            matchId = payload.matchId,
        }
        self._state:Set("distortionIntensity", intensityMap)
        self._state:Set("activeDistortions", activeMap)

        self:_publish("AudioDistortionStarted", {
            userId = userId,
            matchId = payload.matchId,
            intensity = newIntensity,
            previousIntensity = oldIntensity,
            layers = {
                radioStatic = newIntensity >= 0.35,
                ghostWhispers = newIntensity >= 0.55,
                distortedVoices = newIntensity >= 0.7,
                heartbeat = newIntensity >= 0.8,
            },
        })
    else
        if activeMap[userId] then
            self:_stopForUser(userId, "fear_low")
        else
            intensityMap[userId] = 0
            self._state:Set("distortionIntensity", intensityMap)
        end
    end
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    local activeMap = self._state:Get("activeDistortions") or {}

    for userId, active in pairs(activeMap) do
        if matchId == nil or active.matchId == matchId then
            self:_stopForUser(userId, "match_ended")
        end
    end
end

return Service
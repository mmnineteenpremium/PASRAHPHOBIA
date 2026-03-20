local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local LOOP_INTERVAL = 2
local FEAR_MIN = 0
local FEAR_MAX = 100

local function clamp(value, minValue, maxValue)
    if value < minValue then
        return minValue
    end
    if value > maxValue then
        return maxValue
    end
    return value
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
    self._state:Set("playerFearLevels", self._state:Get("playerFearLevels") or {})
    self._state:Set("playerContext", self._state:Get("playerContext") or {})
    self._state:Set("thresholdState", self._state:Get("thresholdState") or {})
    self._state:Set("running", false)
    self._state:Set("loopToken", 0)
end

function Service:Start()
    self:_startLoop()
end

function Service:Stop()
    self:_stopLoop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_ensurePlayerContext(userId)
    local playerContext = self._state:Get("playerContext") or {}
    playerContext[userId] = playerContext[userId] or {
        sanity = 100,
        ghostProximity = 0,
        paranormal = 0,
        darkness = 0,
        matchId = nil,
        lastUpdate = os.clock(),
    }
    self._state:Set("playerContext", playerContext)
    return playerContext[userId]
end

function Service:_computeFearFromContext(ctx)
    local sanityFactor = (100 - clamp(tonumber(ctx.sanity) or 100, 0, 100)) / 100
    local proximityFactor = clamp(tonumber(ctx.ghostProximity) or 0, 0, 1)
    local paranormalFactor = clamp(tonumber(ctx.paranormal) or 0, 0, 1)
    local darknessFactor = clamp(tonumber(ctx.darkness) or 0, 0, 1)

    local fear = (sanityFactor * 45)
        + (proximityFactor * 25)
        + (paranormalFactor * 20)
        + (darknessFactor * 10)

    return clamp(math.floor(fear + 0.5), FEAR_MIN, FEAR_MAX)
end

function Service:_thresholdName(fear)
    if fear >= 70 then
        return "HIGH"
    end
    if fear >= 35 then
        return "MEDIUM"
    end
    return "LOW"
end

function Service:_updateFearForUser(userId)
    local playerFearLevels = self._state:Get("playerFearLevels") or {}
    local thresholdState = self._state:Get("thresholdState") or {}
    local ctx = self:_ensurePlayerContext(userId)

    local previousFear = playerFearLevels[userId] or 0
    local nextFear = self:_computeFearFromContext(ctx)
    playerFearLevels[userId] = nextFear
    self._state:Set("playerFearLevels", playerFearLevels)

    if previousFear ~= nextFear then
        self:_publish("FearLevelUpdated", {
            userId = userId,
            matchId = ctx.matchId,
            previousFear = previousFear,
            fearLevel = nextFear,
            sanity = ctx.sanity,
            ghostProximity = ctx.ghostProximity,
            paranormal = ctx.paranormal,
            darkness = ctx.darkness,
        })
    end

    local previousThreshold = thresholdState[userId] or "LOW"
    local currentThreshold = self:_thresholdName(nextFear)
    if previousThreshold ~= currentThreshold then
        thresholdState[userId] = currentThreshold
        self._state:Set("thresholdState", thresholdState)
        self:_publish("FearThresholdTriggered", {
            userId = userId,
            matchId = ctx.matchId,
            fromThreshold = previousThreshold,
            threshold = currentThreshold,
            fearLevel = nextFear,
        })
    end
end

function Service:_tickDecay()
    local nowTime = os.clock()
    local playerContext = self._state:Get("playerContext") or {}
    for userId, ctx in pairs(playerContext) do
        local dt = math.max(0, nowTime - (ctx.lastUpdate or nowTime))
        ctx.lastUpdate = nowTime
        ctx.paranormal = clamp((ctx.paranormal or 0) - (0.15 * dt), 0, 1)
        ctx.ghostProximity = clamp((ctx.ghostProximity or 0) - (0.2 * dt), 0, 1)
        ctx.darkness = clamp((ctx.darkness or 0) - (0.05 * dt), 0, 1)
        playerContext[userId] = ctx
        self:_updateFearForUser(userId)
    end
    self._state:Set("playerContext", playerContext)
end

function Service:_startLoop()
    if self._state:Get("running") == true then
        return
    end
    self._state:Set("running", true)
    local token = (self._state:Get("loopToken") or 0) + 1
    self._state:Set("loopToken", token)

    task.spawn(function()
        while self._state:Get("running") and self._state:Get("loopToken") == token do
            self:_tickDecay()
            task.wait(LOOP_INTERVAL)
        end
    end)
end

function Service:_stopLoop()
    self._state:Set("running", false)
    self._state:Set("loopToken", (self._state:Get("loopToken") or 0) + 1)
end

function Service:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    local players = payload and payload.players
    if type(players) == "table" then
        for _, player in ipairs(players) do
            local userId = toUserId(player)
            if userId then
                local ctx = self:_ensurePlayerContext(userId)
                ctx.matchId = matchId
                ctx.sanity = 100
                ctx.paranormal = 0
                ctx.ghostProximity = 0
                ctx.darkness = 0
                ctx.lastUpdate = os.clock()
                self:_updateFearForUser(userId)
            end
        end
    end
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    local playerContext = self._state:Get("playerContext") or {}
    local playerFearLevels = self._state:Get("playerFearLevels") or {}
    local thresholdState = self._state:Get("thresholdState") or {}

    for userId, ctx in pairs(playerContext) do
        if matchId == nil or ctx.matchId == matchId then
            playerContext[userId] = nil
            playerFearLevels[userId] = nil
            thresholdState[userId] = nil
        end
    end

    self._state:Set("playerContext", playerContext)
    self._state:Set("playerFearLevels", playerFearLevels)
    self._state:Set("thresholdState", thresholdState)
end

function Service:OnPlayerSanityChanged(payload)
    if type(payload) ~= "table" then
        return
    end
    local userId = toUserId(payload.player or payload.userId)
    if not userId then
        return
    end
    local ctx = self:_ensurePlayerContext(userId)
    ctx.sanity = tonumber(payload.newSanity) or tonumber(payload.sanity) or ctx.sanity
    ctx.matchId = payload.matchId or ctx.matchId
    ctx.lastUpdate = os.clock()
    self:_updateFearForUser(userId)
end

function Service:OnGhostProximityDetected(payload)
    if type(payload) ~= "table" then
        return
    end
    local userId = toUserId(payload.player or payload.userId)
    if not userId then
        return
    end
    local ctx = self:_ensurePlayerContext(userId)
    local proximity = tonumber(payload.proximity) or 1
    ctx.ghostProximity = clamp(proximity, 0, 1)
    ctx.matchId = payload.matchId or ctx.matchId
    ctx.lastUpdate = os.clock()
    self:_updateFearForUser(userId)
end

function Service:OnParanormalEvent(payload)
    if type(payload) ~= "table" then
        return
    end

    local function applyToUser(userId, matchId, intensity)
        local ctx = self:_ensurePlayerContext(userId)
        ctx.paranormal = clamp((ctx.paranormal or 0) + intensity, 0, 1)
        ctx.matchId = matchId or ctx.matchId
        ctx.lastUpdate = os.clock()
        self:_updateFearForUser(userId)
    end

    local intensity = clamp(tonumber(payload.intensity) or 0.25, 0, 1)
    if payload.player or payload.userId then
        local userId = toUserId(payload.player or payload.userId)
        if userId then
            applyToUser(userId, payload.matchId, intensity)
        end
        return
    end

    local playerContext = self._state:Get("playerContext") or {}
    for userId, ctx in pairs(playerContext) do
        if payload.matchId == nil or ctx.matchId == payload.matchId then
            applyToUser(userId, payload.matchId, intensity)
        end
    end
end

function Service:GetFearLevel(playerOrUserId)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return 0
    end
    local playerFearLevels = self._state:Get("playerFearLevels") or {}
    return playerFearLevels[userId] or 0
end

return Service
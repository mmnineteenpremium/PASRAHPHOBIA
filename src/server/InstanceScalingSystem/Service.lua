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

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    self._loopRunning = false
    self._loopToken = 0
    self._loopThread = nil
    return self
end

function Service:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
        LobbySocialHub = Services.Get(self._deps, "LobbySocialHub"),
        TeleportService = Services.Get(self._deps, "TeleportService"),
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
        DataPersistenceService = Services.Get(self._deps, "DataPersistenceService"),
    }
end

function Service:Init()
    self._state:Set("serverLoad", self._state:Get("serverLoad") or { playerCount = 0, utilization = 0 })
    self._state:Set("activeInstances", self._state:Get("activeInstances") or {})
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

function Service:_nextInstanceId()
    return string.format("instance_%d_%d", os.time(), math.random(1000, 9999))
end

function Service:_calculateLoad()
    local players = game:GetService("Players")
    local playerCount = #players:GetPlayers()
    local cfg = self._state:Get("scalingConfig") or {}
    local maxPlayers = math.max(1, cfg.maxPlayersPerInstance or 4)
    local utilization = math.clamp(playerCount / maxPlayers, 0, 2)
    return {
        playerCount = playerCount,
        utilization = utilization,
    }
end

function Service:_updateLoadAndScale()
    local load = self:_calculateLoad()
    self._state:Set("serverLoad", load)
    self:_publish("ServerLoadUpdated", load)

    local cfg = self._state:Get("scalingConfig") or {}
    local threshold = cfg.scaleOutThreshold or 0.85
    if load.utilization < threshold then
        return
    end

    local activeInstances = self._state:Get("activeInstances") or {}
    local newInstanceId = self:_nextInstanceId()
    activeInstances[newInstanceId] = {
        instanceId = newInstanceId,
        createdAt = os.clock(),
        status = "allocated",
        loadAtCreation = load.utilization,
    }
    self._state:Set("activeInstances", activeInstances)

    self:_publish("ServerInstanceCreated", {
        instanceId = newInstanceId,
        reason = "load_threshold",
        load = load,
    })
end

function Service:_startLoop()
    if self._loopRunning then
        return
    end
    self._loopRunning = true
    self._loopToken += 1
    local token = self._loopToken
    local interval = ((self._state:Get("scalingConfig") or {}).checkIntervalSeconds or 5)
    self._loopThread = task.spawn(function()
        while self._loopRunning and token == self._loopToken do
            self:_updateLoadAndScale()
            task.wait(interval)
        end
    end)
end

function Service:_stopLoop()
    self._loopRunning = false
    self._loopToken += 1
    if self._loopThread then
        task.cancel(self._loopThread)
        self._loopThread = nil
    end
end

function Service:OnMatchStarted()
    self:_updateLoadAndScale()
end

function Service:OnMatchEnded()
    self:_updateLoadAndScale()
end

return Service

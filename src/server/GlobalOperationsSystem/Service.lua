local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for key, nested in pairs(value) do
        out[key] = deepCopy(nested)
    end
    return out
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

local function resolveGameDataModule(moduleName)
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local shared = replicatedStorage:FindFirstChild("Shared") or replicatedStorage:FindFirstChild("shared")
    if not shared then
        return nil
    end
    local gameData = shared:FindFirstChild("GameData")
    if not gameData then
        return nil
    end
    return gameData:FindFirstChild(moduleName)
end

local function safeRequire(moduleScript)
    if not moduleScript then
        return nil
    end
    local ok, result = pcall(require, moduleScript)
    if ok then
        return result
    end
    return nil
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._players = self._deps.Players or game:GetService("Players")
    self._stats = self._deps.Stats or game:GetService("Stats")
    return self
end

function Service:Init()
    self._eventBus = resolveEventBus(self._deps)
    self:ReloadConfig()
end

function Service:Start()
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:ReloadConfig()
    local cfg = safeRequire(resolveGameDataModule("GlobalOperationsConfig")) or {}
    self._state:Set("config", cfg)

    local regions = (((cfg or {}).ServerScaling or {}).Regions) or {}
    local status = {}
    for _, region in ipairs(regions) do
        status[region] = {
            region = region,
            availableServers = 0,
            load = 0,
            health = "Unknown",
        }
    end
    self._state:Set("regionStatus", status)

    self:_publish("GlobalOperationsConfigLoaded", {
        regionCount = #regions,
        timestamp = os.time(),
    })
end

function Service:_safeNumber(value, fallback)
    local numeric = tonumber(value)
    if numeric == nil then
        return fallback
    end
    return numeric
end

function Service:CollectHealthSnapshot()
    local playerCount = #self._players:GetPlayers()

    local physicsFps = 60
    local okFps, fpsValue = pcall(function()
        return workspace:GetRealPhysicsFPS()
    end)
    if okFps then
        physicsFps = self:_safeNumber(fpsValue, physicsFps)
    end

    local memoryMb = 0
    local okMem, memValue = pcall(function()
        return self._stats:GetTotalMemoryUsageMb()
    end)
    if okMem then
        memoryMb = self:_safeNumber(memValue, memoryMb)
    end

    local snapshot = {
        playerCount = playerCount,
        physicsFps = physicsFps,
        memoryMb = memoryMb,
        networkLatencyMs = 0,
        timestamp = os.time(),
    }

    self._state:Set("health", snapshot)
    self:_publish("ServerHealthMetricsUpdated", deepCopy(snapshot))

    return snapshot
end

function Service:EvaluateScaling(snapshot)
    local cfg = self._state:Get("config") or {}
    local scaling = cfg.ServerScaling or {}
    if scaling.Enabled == false then
        return
    end

    local maxPlayers = math.max(1, math.floor(tonumber(scaling.MaxPlayersPerServer) or 40))
    local targetFill = tonumber(scaling.TargetFillRatio) or 0.72
    local desired = math.max(1, math.ceil((snapshot.playerCount / (maxPlayers * targetFill))))

    self:_publish("ServerScalingRequested", {
        desiredServerCount = desired,
        playerCount = snapshot.playerCount,
        maxPlayersPerServer = maxPlayers,
        targetFillRatio = targetFill,
        timestamp = snapshot.timestamp,
    })

    self:_publish("DynamicServerAllocationRequested", {
        desiredServerCount = desired,
        regions = deepCopy((scaling.Regions or {})),
        reason = "auto_scaling",
    })
end

function Service:CheckHealthThresholds(snapshot)
    local cfg = self._state:Get("config") or {}
    local thresholds = ((cfg.ServerScaling or {}).HealthWarningThreshold) or {}

    local warnings = {}
    if snapshot.physicsFps < (tonumber(thresholds.minPhysicsFps) or 35) then
        table.insert(warnings, "low_fps")
    end
    if snapshot.memoryMb > (tonumber(thresholds.maxMemoryMb) or 2600) then
        table.insert(warnings, "high_memory")
    end
    if snapshot.networkLatencyMs > (tonumber(thresholds.maxNetworkLatencyMs) or 240) then
        table.insert(warnings, "high_network_latency")
    end

    if #warnings > 0 then
        self:_publish("ServerHealthWarning", {
            warnings = warnings,
            snapshot = deepCopy(snapshot),
        })
        self:_publish("SafeServerRestartRequested", {
            reason = "health_unstable",
            warnings = warnings,
            snapshot = deepCopy(snapshot),
        })
    end
end

function Service:OnHeartbeatTick()
    local snapshot = self:CollectHealthSnapshot()
    self:EvaluateScaling(snapshot)
    self:CheckHealthThresholds(snapshot)
end

function Service:OnTelemetryEventRecorded(payload)
    local counters = self._state:Get("telemetryCounters") or {}
    local key = payload and payload.eventName or payload and payload.name or "unknown"
    counters[key] = (counters[key] or 0) + 1
    self._state:Set("telemetryCounters", counters)
end

function Service:OnMatchStarted(payload)
    local snapshots = self._state:Get("matchSnapshots") or {}
    local matchId = payload and payload.matchId
    if type(matchId) ~= "string" then
        return
    end
    snapshots[matchId] = {
        startedAt = os.time(),
        players = payload.players,
        mapId = payload.mapId or payload.map,
    }
    self._state:Set("matchSnapshots", snapshots)
end

function Service:OnMatchEnded(payload)
    local snapshots = self._state:Get("matchSnapshots") or {}
    local matchId = payload and payload.matchId
    if type(matchId) ~= "string" then
        return
    end

    snapshots[matchId] = nil
    self._state:Set("matchSnapshots", snapshots)

    self:_publish("CrashRecoveryCheckpoint", {
        matchId = matchId,
        results = payload.results,
        timestamp = os.time(),
    })
end

function Service:OnServerHealthWarning(payload)
    self:_publish("CrashRecoveryRequested", {
        reason = "server_health_warning",
        payload = payload,
        timestamp = os.time(),
    })
end

function Service:EvaluateReleaseReadiness()
    local health = self._state:Get("health") or {}
    local counters = self._state:Get("telemetryCounters") or {}

    local readiness = {
        stability = (health.physicsFps or 0) >= 35 and (health.memoryMb or 9999) <= 2600,
        matchmaking = (counters.MatchmakingStarted or 0) >= 1,
        economy = (counters.CurrencyEarned or 0) >= 1,
    }
    readiness.ready = readiness.stability and readiness.matchmaking and readiness.economy

    self._state:Set("releaseReadiness", readiness)
    self:_publish("GlobalReleaseReadinessUpdated", deepCopy(readiness))
    return readiness
end

function Service:OnGlobalReleaseReadinessRequested()
    self:EvaluateReleaseReadiness()
end

return Service

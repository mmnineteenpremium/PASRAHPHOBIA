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

function Service:ReloadConfig()
    local cfg = safeRequire(resolveGameDataModule("GlobalOperationsConfig")) or {}
    self._state:Set("config", cfg.Matchmaking or {})
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:OnLatencyUpdated(payload)
    local userId = toUserId(payload and (payload.player or payload.userId))
    if not userId then
        return
    end
    local latency = math.max(0, math.floor(tonumber(payload.pingMs or payload.latencyMs) or 0))
    local map = self._state:Get("latencyByUserId") or {}
    map[userId] = latency
    self._state:Set("latencyByUserId", map)
end

function Service:OnPlayerLevelUp(payload)
    local userId = toUserId(payload and (payload.player or payload.userId))
    if not userId then
        return
    end
    local level = math.max(1, math.floor(tonumber(payload.newLevel or payload.level) or 1))
    local map = self._state:Get("experienceByUserId") or {}
    map[userId] = level
    self._state:Set("experienceByUserId", map)
end

function Service:OnPartyState(payload)
    local partyId = payload and payload.partyId
    if type(partyId) ~= "string" then
        return
    end

    local map = self._state:Get("partyByUserId") or {}
    for _, userId in ipairs(payload.members or {}) do
        if type(userId) == "number" then
            map[userId] = partyId
        end
    end
    self._state:Set("partyByUserId", map)
end

function Service:OnServerHealthMetrics(payload)
    local status = self._state:Get("serverAvailability") or {}
    status.current = {
        playerCount = payload and payload.playerCount or 0,
        physicsFps = payload and payload.physicsFps or 60,
        memoryMb = payload and payload.memoryMb or 0,
        timestamp = payload and payload.timestamp or os.time(),
    }
    self._state:Set("serverAvailability", status)
end

function Service:_scorePlayer(userId)
    local cfg = self._state:Get("config") or {}
    local latencyMap = self._state:Get("latencyByUserId") or {}
    local expMap = self._state:Get("experienceByUserId") or {}

    local latency = latencyMap[userId] or (cfg.MaxPingMs or 280)
    local exp = expMap[userId] or 1

    local latencyWeight = tonumber(cfg.LatencyWeight) or 0.5
    local expWeight = tonumber(cfg.ExperienceWeight) or 0.3
    local preferredPing = tonumber(cfg.PreferredPingMs) or 120
    local maxPing = tonumber(cfg.MaxPingMs) or 280

    local latencyScore = 1 - math.clamp((latency - preferredPing) / math.max(1, (maxPing - preferredPing)), 0, 1)
    local experienceScore = math.clamp(exp / 100, 0, 1)

    return (latencyScore * latencyWeight) + (experienceScore * expWeight)
end

function Service:OnMatchmakingStarted(payload)
    local players = payload and payload.players or {}
    if #players == 0 and payload and payload.leader then
        players = { payload.leader }
    end

    local scored = {}
    for _, player in ipairs(players) do
        local userId = toUserId(player)
        if userId then
            table.insert(scored, {
                userId = userId,
                qualityScore = self:_scorePlayer(userId),
                latencyMs = (self._state:Get("latencyByUserId") or {})[userId] or nil,
                level = (self._state:Get("experienceByUserId") or {})[userId] or 1,
            })
        end
    end

    self:_publish("MatchmakingQualityEvaluated", {
        partyId = payload and payload.partyId,
        players = scored,
        requestedQueueType = payload and payload.queueType,
        timestamp = os.time(),
    })

    self:_publish("MatchmakingAllocationSuggested", {
        partyId = payload and payload.partyId,
        scoreAverage = #scored > 0 and (function()
            local total = 0
            for _, entry in ipairs(scored) do
                total += entry.qualityScore
            end
            return total / #scored
        end)() or 0,
        serverAvailability = self._state:Get("serverAvailability"),
        timestamp = os.time(),
    })
end

return Service

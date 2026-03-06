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
        ServerQueueSystem = Services.Get(self._deps, "ServerQueueSystem"),
    }
end

function Service:Init()
    self._state:Set("activeMatches", self._state:Get("activeMatches") or {})
    self._state:Set("pendingGroups", self._state:Get("pendingGroups") or {})
end

function Service:Start()
    -- Event-driven.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_teamSizeForMode(mode)
    local cfg = self._state:Get("matchmakingConfig") or {}
    if mode == "Solo" then
        return cfg.soloSize or 1
    end
    return cfg.teamSize or 4
end

function Service:TryBuildMatch(mode)
    local queueSystem = self._dependencies.ServerQueueSystem
    if type(queueSystem) ~= "table" then
        return nil
    end

    local teamSize = self:_teamSizeForMode(mode)
    local queueService = queueSystem.Service or queueSystem
    if type(queueService.PopCandidates) ~= "function" then
        return nil
    end

    self:_publish("MatchmakingStarted", { mode = mode, requestedTeamSize = teamSize })

    local candidates = queueService:PopCandidates(teamSize)
    if type(candidates) ~= "table" then
        return nil
    end

    local minTeamSize = (self._state:Get("matchmakingConfig") or {}).minTeamSize or 2
    if mode == "Solo" then
        minTeamSize = 1
    end
    if #candidates < minTeamSize then
        for _, userId in ipairs(candidates) do
            if type(queueService.JoinQueue) == "function" then
                queueService:JoinQueue(userId, { mode = mode, priority = 0 })
            end
        end
        return nil
    end

    local matchId = string.format("mm_%d_%d", os.time(), math.random(1000, 9999))
    local activeMatches = self._state:Get("activeMatches") or {}
    activeMatches[matchId] = {
        matchId = matchId,
        mode = mode,
        players = candidates,
        createdAt = os.clock(),
        status = "ready",
    }
    self._state:Set("activeMatches", activeMatches)

    local payload = {
        matchId = matchId,
        mode = mode,
        players = candidates,
        teamSize = #candidates,
    }
    self:_publish("MatchFound", payload)
    self:_publish("MatchReady", payload)

    return payload
end

function Service:OnQueueUpdated()
    self:TryBuildMatch("Team")
end

function Service:OnPartyCreated(payload)
    if type(payload) ~= "table" then
        return
    end
    self:TryBuildMatch(payload.mode or "Team")
end

function Service:OnMatchStarted(payload)
    if type(payload) ~= "table" then
        return
    end
    local matchId = payload.matchId
    if type(matchId) ~= "string" then
        return
    end
    local activeMatches = self._state:Get("activeMatches") or {}
    if activeMatches[matchId] then
        activeMatches[matchId].status = "started"
    end
    self._state:Set("activeMatches", activeMatches)
end

function Service:OnMatchEnded(payload)
    if type(payload) ~= "table" then
        return
    end
    local matchId = payload.matchId
    local activeMatches = self._state:Get("activeMatches") or {}
    activeMatches[matchId] = nil
    self._state:Set("activeMatches", activeMatches)
end

return Service

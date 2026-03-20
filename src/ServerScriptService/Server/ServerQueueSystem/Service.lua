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
    }
end

function Service:Init()
    self._state:Set("waitingPlayers", self._state:Get("waitingPlayers") or {})
    self._state:Set("queuedParties", self._state:Get("queuedParties") or {})
    self._state:Set("queuePriorities", self._state:Get("queuePriorities") or {})
    self._state:Set("queueJoinedAt", self._state:Get("queueJoinedAt") or {})
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

function Service:GetQueueSnapshot()
    return {
        waitingPlayers = self._state:Get("waitingPlayers"),
        queuedParties = self._state:Get("queuedParties"),
    }
end

function Service:GetEstimatedWaitTime()
    local waitingPlayers = self._state:Get("waitingPlayers") or {}
    local queuedParties = self._state:Get("queuedParties") or {}

    local queuedCount = 0
    for _ in pairs(waitingPlayers) do
        queuedCount += 1
    end
    for _, party in pairs(queuedParties) do
        queuedCount += #(party.members or {})
    end

    return math.max(8, queuedCount * 3)
end

function Service:JoinQueue(playerId, options)
    if type(playerId) ~= "number" then
        return false, "invalid_player_id"
    end
    options = options or {}

    local waitingPlayers = self._state:Get("waitingPlayers") or {}
    local queuePriorities = self._state:Get("queuePriorities") or {}
    local queueJoinedAt = self._state:Get("queueJoinedAt") or {}

    waitingPlayers[playerId] = {
        playerId = playerId,
        requestedAt = os.clock(),
        mode = options.mode or "Team",
    }
    queuePriorities[playerId] = tonumber(options.priority) or 0
    queueJoinedAt[playerId] = os.time()

    self._state:Set("waitingPlayers", waitingPlayers)
    self._state:Set("queuePriorities", queuePriorities)
    self._state:Set("queueJoinedAt", queueJoinedAt)

    self:_publish("QueueJoined", {
        playerId = playerId,
        estimatedWait = self:GetEstimatedWaitTime(),
    })
    self:_publish("QueueUpdated", self:GetQueueSnapshot())
    return true
end

function Service:JoinPartyQueue(partyId, memberIds, options)
    if type(partyId) ~= "string" or partyId == "" then
        return false, "invalid_party_id"
    end
    if type(memberIds) ~= "table" or #memberIds == 0 then
        return false, "invalid_party_members"
    end
    options = options or {}

    local queuedParties = self._state:Get("queuedParties") or {}
    queuedParties[partyId] = {
        id = partyId,
        members = memberIds,
        requestedAt = os.clock(),
        priority = tonumber(options.priority) or 0,
        mode = options.mode or "Team",
    }
    self._state:Set("queuedParties", queuedParties)

    for _, userId in ipairs(memberIds) do
        local waitingPlayers = self._state:Get("waitingPlayers") or {}
        waitingPlayers[userId] = nil
        self._state:Set("waitingPlayers", waitingPlayers)
    end

    self:_publish("QueueJoined", {
        partyId = partyId,
        members = memberIds,
        estimatedWait = self:GetEstimatedWaitTime(),
    })
    self:_publish("QueueUpdated", self:GetQueueSnapshot())
    return true
end

function Service:LeaveQueue(playerId)
    if type(playerId) ~= "number" then
        return false, "invalid_player_id"
    end

    local waitingPlayers = self._state:Get("waitingPlayers") or {}
    local queuePriorities = self._state:Get("queuePriorities") or {}
    local queueJoinedAt = self._state:Get("queueJoinedAt") or {}

    waitingPlayers[playerId] = nil
    queuePriorities[playerId] = nil
    queueJoinedAt[playerId] = nil

    self._state:Set("waitingPlayers", waitingPlayers)
    self._state:Set("queuePriorities", queuePriorities)
    self._state:Set("queueJoinedAt", queueJoinedAt)

    self:_publish("QueueLeft", { playerId = playerId })
    self:_publish("QueueUpdated", self:GetQueueSnapshot())
    return true
end

function Service:RemovePartyFromQueue(partyId)
    local queuedParties = self._state:Get("queuedParties") or {}
    if queuedParties[partyId] == nil then
        return false
    end
    queuedParties[partyId] = nil
    self._state:Set("queuedParties", queuedParties)
    self:_publish("QueueLeft", { partyId = partyId })
    self:_publish("QueueUpdated", self:GetQueueSnapshot())
    return true
end

function Service:PopCandidates(teamSize)
    local requestedSize = math.max(1, tonumber(teamSize) or 4)
    local waitingPlayers = self._state:Get("waitingPlayers") or {}
    local queuePriorities = self._state:Get("queuePriorities") or {}
    local queueJoinedAt = self._state:Get("queueJoinedAt") or {}
    local queuedParties = self._state:Get("queuedParties") or {}

    local candidates = {}

    local partyIds = {}
    for partyId in pairs(queuedParties) do
        table.insert(partyIds, partyId)
    end
    table.sort(partyIds, function(a, b)
        local pa = queuedParties[a]
        local pb = queuedParties[b]
        if (pa.priority or 0) == (pb.priority or 0) then
            return (pa.requestedAt or 0) < (pb.requestedAt or 0)
        end
        return (pa.priority or 0) > (pb.priority or 0)
    end)

    for _, partyId in ipairs(partyIds) do
        local party = queuedParties[partyId]
        local members = party.members or {}
        if #candidates + #members <= requestedSize then
            for _, userId in ipairs(members) do
                table.insert(candidates, userId)
            end
            queuedParties[partyId] = nil
        end
    end

    local singleIds = {}
    for playerId in pairs(waitingPlayers) do
        table.insert(singleIds, playerId)
    end
    table.sort(singleIds, function(a, b)
        if (queuePriorities[a] or 0) == (queuePriorities[b] or 0) then
            return (queueJoinedAt[a] or 0) < (queueJoinedAt[b] or 0)
        end
        return (queuePriorities[a] or 0) > (queuePriorities[b] or 0)
    end)

    for _, userId in ipairs(singleIds) do
        if #candidates >= requestedSize then
            break
        end
        table.insert(candidates, userId)
        waitingPlayers[userId] = nil
        queuePriorities[userId] = nil
        queueJoinedAt[userId] = nil
    end

    self._state:Set("waitingPlayers", waitingPlayers)
    self._state:Set("queuedParties", queuedParties)
    self._state:Set("queuePriorities", queuePriorities)
    self._state:Set("queueJoinedAt", queueJoinedAt)
    self:_publish("QueueUpdated", self:GetQueueSnapshot())

    return candidates
end

return Service

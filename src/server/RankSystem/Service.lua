local Service = {}
Service.__index = Service

local Services = require(script.Parent.Parent.Core.Services)

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

local function resolveProfileService(deps)
    local profile = Services.Get(deps, "ProfileSystem")
    if type(profile) ~= "table" then
        return nil
    end
    if type(profile.GetPlayerLevel) == "function" then
        return profile
    end
    if type(profile.Service) == "table" and type(profile.Service.GetPlayerLevel) == "function" then
        return profile.Service
    end
    return nil
end

local function resolvePersistenceService(deps)
    local persistence = Services.Get(deps, "DataPersistenceService")
    if type(persistence) ~= "table" then
        return nil
    end
    if type(persistence.SaveProfile) == "function" then
        return persistence
    end
    if type(persistence.Service) == "table" and type(persistence.Service.SaveProfile) == "function" then
        return persistence.Service
    end
    return nil
end

local function resolveLobbySocialHubService(deps)
    local lobby = Services.Get(deps, "LobbySocialHub")
    if type(lobby) ~= "table" then
        return nil
    end
    if type(lobby.ApplyRank) == "function" or type(lobby.UpdateRankDisplay) == "function" then
        return lobby
    end
    if type(lobby.Service) == "table" then
        if type(lobby.Service.ApplyRank) == "function" or type(lobby.Service.UpdateRankDisplay) == "function" then
            return lobby.Service
        end
    end
    return lobby
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._profile = resolveProfileService(self._deps)
    self._persistence = resolvePersistenceService(self._deps)
    self._lobby = resolveLobbySocialHubService(self._deps)
    return self
end

function Service:Init()
    self._state:Set("rankTable", self._state:Get("rankTable") or {})
    self._state:Set("recentRankUpdates", self._state:Get("recentRankUpdates") or {})
    self._state:Set("rankByUserId", self._state:Get("rankByUserId") or {})
end

function Service:Start()
    -- Event-driven rank service.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_resolveRankForLevel(level)
    local rankTable = self._state:Get("rankTable") or {}
    local targetLevel = math.max(math.floor(level or 1), 1)
    local selected = rankTable[1] or { level = 1, rank = "Rookie" }
    for _, entry in ipairs(rankTable) do
        if targetLevel >= (entry.level or 1) then
            selected = entry
        else
            break
        end
    end
    return selected
end

function Service:_recordRankUpdate(userId, payload)
    local updates = self._state:Get("recentRankUpdates") or {}
    updates[userId] = updates[userId] or {}
    table.insert(updates[userId], payload)
    self._state:Set("recentRankUpdates", updates)
end

function Service:_syncProfileRank(playerOrUserId, rankName)
    if not self._profile then
        return
    end
    if type(self._profile.SetPlayerRank) == "function" then
        self._profile:SetPlayerRank(playerOrUserId, rankName)
        return
    end
    if type(self._profile.UpdateRank) == "function" then
        self._profile:UpdateRank(playerOrUserId, rankName)
        return
    end
    if type(self._profile.UpdateProfile) == "function" then
        self._profile:UpdateProfile(playerOrUserId, {
            profile = {
                rank = rankName,
            },
        })
    end
end

function Service:_syncPersistenceRank(userId, rankName, level)
    if not self._persistence or type(self._persistence.SaveProfile) ~= "function" then
        return
    end
    self._persistence:SaveProfile(userId, {
        playerRank = rankName,
        playerLevel = level,
    })
end

function Service:_syncLobbyRank(playerOrUserId, rankPayload)
    if not self._lobby then
        return
    end
    if type(self._lobby.ApplyRank) == "function" then
        self._lobby:ApplyRank(playerOrUserId, rankPayload.rank, rankPayload.rankLevel)
        return
    end
    if type(self._lobby.UpdateRankDisplay) == "function" then
        self._lobby:UpdateRankDisplay(playerOrUserId, rankPayload.rank, rankPayload.rankLevel)
        return
    end
    self:_publish("LobbyRankDisplayRequested", rankPayload)
end

function Service:GetRank(playerOrUserId)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return nil
    end
    local rankByUserId = self._state:Get("rankByUserId") or {}
    return rankByUserId[userId]
end

function Service:SetRank(playerOrUserId, rankName, rankLevel, level)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return false, "invalid_player"
    end

    local rankByUserId = self._state:Get("rankByUserId") or {}
    local previous = rankByUserId[userId]
    local previousRank = previous and previous.rank or nil
    local changed = previousRank ~= rankName

    rankByUserId[userId] = {
        userId = userId,
        rank = rankName,
        rankLevel = rankLevel,
        level = level,
    }
    self._state:Set("rankByUserId", rankByUserId)

    local payload = {
        player = type(playerOrUserId) == "number" and nil or playerOrUserId,
        userId = userId,
        rank = rankName,
        rankLevel = rankLevel,
        level = level,
        previousRank = previousRank,
        changed = changed,
    }

    self:_recordRankUpdate(userId, payload)
    self:_syncProfileRank(playerOrUserId, rankName)
    self:_syncPersistenceRank(userId, rankName, level)
    self:_syncLobbyRank(playerOrUserId, payload)
    self:_publish("RankUpdated", payload)
    return true, nil, payload
end

function Service:EvaluateRank(playerOrUserId, levelHint)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return false, "invalid_player"
    end

    local level = levelHint
    if level == nil and self._profile and type(self._profile.GetPlayerLevel) == "function" then
        level = self._profile:GetPlayerLevel(playerOrUserId)
    end
    level = math.max(math.floor(level or 1), 1)

    local tier = self:_resolveRankForLevel(level)
    return self:SetRank(playerOrUserId, tier.rank, tier.level, level)
end

function Service:OnLevelUp(payload)
    local playerOrUserId = payload and (payload.player or payload.userId)
    if not playerOrUserId then
        return
    end
    local level = payload and (payload.levelAfter or payload.level)
    self:EvaluateRank(playerOrUserId, level)
end

return Service

local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DAILY_MISSIONS = {
    { id = "IdentifyGhost", target = 1, reward = { currency = 200, xp = 80 } },
    { id = "CollectEvidence", target = 3, reward = { currency = 150, xp = 60 } },
    { id = "SurviveHunt", target = 1, reward = { currency = 175, xp = 70 } },
    { id = "CompleteContract", target = 1, reward = { currency = 250, xp = 100 } },
}

local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then
        return playerOrUserId
    end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId.UserId
    end
    return nil
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, nested in pairs(value) do
        copy[key] = deepCopy(nested)
    end
    return copy
end

local function safeCall(target, methodName, ...)
    if type(target) ~= "table" then
        return nil
    end
    local fn = target[methodName]
    if type(fn) ~= "function" then
        return nil
    end
    local ok, result = pcall(fn, target, ...)
    if not ok then
        return nil
    end
    return result
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
        EconomySystem = Services.Get(self._deps, "EconomySystem"),
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
        DataPersistenceService = Services.Get(self._deps, "DataPersistenceService"),
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
    }
end

function Service:Init()
    self._state:Set("activeMissions", self._state:Get("activeMissions") or {})
    self._state:Set("completedMissions", self._state:Get("completedMissions") or {})
    self._state:Set("missionProgress", self._state:Get("missionProgress") or {})
    self._state:Set("missionDate", self._state:Get("missionDate") or {})
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

function Service:_todayKey()
    return os.date("!%Y-%m-%d")
end

function Service:_ensurePlayerMissionState(player)
    local userId = toUserId(player)
    if not userId then
        return nil
    end

    local activeMissions = self._state:Get("activeMissions") or {}
    local completedMissions = self._state:Get("completedMissions") or {}
    local missionProgress = self._state:Get("missionProgress") or {}
    local missionDate = self._state:Get("missionDate") or {}

    activeMissions[userId] = activeMissions[userId] or {}
    completedMissions[userId] = completedMissions[userId] or {}
    missionProgress[userId] = missionProgress[userId] or {}

    self._state:Set("activeMissions", activeMissions)
    self._state:Set("completedMissions", completedMissions)
    self._state:Set("missionProgress", missionProgress)
    self._state:Set("missionDate", missionDate)

    return userId
end

function Service:GenerateDailyMissions(player)
    local userId = self:_ensurePlayerMissionState(player)
    if not userId then
        return false, "invalid_player"
    end

    local today = self:_todayKey()
    local missionDate = self._state:Get("missionDate") or {}
    if missionDate[userId] == today then
        return true, nil, self:GetDailyMissions(player)
    end

    local activeMissions = self._state:Get("activeMissions") or {}
    local completedMissions = self._state:Get("completedMissions") or {}
    local missionProgress = self._state:Get("missionProgress") or {}

    activeMissions[userId] = {}
    completedMissions[userId] = {}
    missionProgress[userId] = {}

    for _, template in ipairs(DAILY_MISSIONS) do
        activeMissions[userId][template.id] = {
            id = template.id,
            target = template.target,
            reward = deepCopy(template.reward),
        }
        missionProgress[userId][template.id] = 0
        self:_publish("MissionStarted", {
            player = player,
            userId = userId,
            mission = deepCopy(activeMissions[userId][template.id]),
            date = today,
        })
    end

    missionDate[userId] = today

    self._state:Set("activeMissions", activeMissions)
    self._state:Set("completedMissions", completedMissions)
    self._state:Set("missionProgress", missionProgress)
    self._state:Set("missionDate", missionDate)

    return true, nil, self:GetDailyMissions(player)
end

function Service:GetDailyMissions(player)
    local userId = self:_ensurePlayerMissionState(player)
    if not userId then
        return {}
    end
    local activeMissions = self._state:Get("activeMissions") or {}
    return deepCopy(activeMissions[userId] or {})
end

function Service:_grantRewards(player, reward)
    local economySystem = self._dependencies.EconomySystem
    local currency = math.max(0, math.floor(tonumber(reward.currency) or 0))
    local xp = math.max(0, math.floor(tonumber(reward.xp) or 0))

    if currency > 0 then
        local granted = false
        granted = safeCall(economySystem, "GrantCurrency", player, currency, "DailyMission") == true or granted
        granted = safeCall(economySystem, "AddCurrency", player, currency, "DailyMission") == true or granted
        if not granted then
            self:_publish("CurrencyEarned", {
                player = player,
                amount = currency,
                source = "DailyMission",
            })
        end
    end

    if xp > 0 then
        self:_publish("RewardGranted", {
            player = player,
            xp = xp,
            source = "DailyMission",
        })
    end
end

function Service:CompleteMission(player, missionId)
    local userId = self:_ensurePlayerMissionState(player)
    if not userId then
        return false, "invalid_player"
    end

    local activeMissions = self._state:Get("activeMissions") or {}
    local completedMissions = self._state:Get("completedMissions") or {}

    local mission = activeMissions[userId] and activeMissions[userId][missionId]
    if not mission then
        return false, "mission_not_found"
    end
    if completedMissions[userId] and completedMissions[userId][missionId] then
        return true
    end

    completedMissions[userId][missionId] = true
    self._state:Set("completedMissions", completedMissions)

    self:_grantRewards(player, mission.reward or {})

    self:_publish("MissionCompleted", {
        player = player,
        userId = userId,
        missionId = missionId,
        reward = deepCopy(mission.reward or {}),
    })

    return true
end

function Service:UpdateMissionProgress(player, missionId, amount)
    local userId = self:_ensurePlayerMissionState(player)
    if not userId then
        return false, "invalid_player"
    end

    local activeMissions = self._state:Get("activeMissions") or {}
    local completedMissions = self._state:Get("completedMissions") or {}
    local missionProgress = self._state:Get("missionProgress") or {}

    local mission = activeMissions[userId] and activeMissions[userId][missionId]
    if not mission then
        return false, "mission_not_found"
    end
    if completedMissions[userId] and completedMissions[userId][missionId] then
        return true
    end

    local current = tonumber(missionProgress[userId][missionId]) or 0
    local nextValue = current + math.max(0, math.floor(tonumber(amount) or 0))
    missionProgress[userId][missionId] = nextValue
    self._state:Set("missionProgress", missionProgress)

    self:_publish("MissionProgress", {
        player = player,
        userId = userId,
        missionId = missionId,
        progress = nextValue,
        target = mission.target,
    })

    if nextValue >= (mission.target or 1) then
        self:CompleteMission(player, missionId)
    end

    return true
end

function Service:OnPlayerJoinedLobby(payload)
    local player = payload and payload.player or payload
    if player then
        self:GenerateDailyMissions(player)
    end
end

function Service:OnObjectiveCompleted(payload)
    if type(payload) ~= "table" or not payload.player then
        return
    end
    local objectiveId = payload.objectiveId or (payload.objective and payload.objective.id)
    if objectiveId == "CaptureEvidence" then
        self:UpdateMissionProgress(payload.player, "CollectEvidence", 1)
    elseif objectiveId == "IdentifyGhost" then
        self:UpdateMissionProgress(payload.player, "IdentifyGhost", 1)
    elseif objectiveId == "CompleteInvestigation" then
        self:UpdateMissionProgress(payload.player, "CompleteContract", 1)
    end
end

function Service:OnMatchEnded(payload)
    if type(payload) ~= "table" then
        return
    end

    local function processPlayer(player, result)
        if result and (result.correctGhostIdentification == true or result.ghostIdentifiedCorrectly == true) then
            self:UpdateMissionProgress(player, "IdentifyGhost", 1)
        end
        if result and (result.didSurviveHunt == true or result.survivedHunt == true) then
            self:UpdateMissionProgress(player, "SurviveHunt", 1)
        end
        if result and (result.contractCompleted == true or result.didWin == true) then
            self:UpdateMissionProgress(player, "CompleteContract", 1)
        end
    end

    if payload.player then
        processPlayer(payload.player, payload)
        return
    end

    if type(payload.results) == "table" and type(payload.results.playerResults) == "table" then
        for _, result in ipairs(payload.results.playerResults) do
            local player = result.player or result.userId
            if player then
                processPlayer(player, result)
            end
        end
    end
end

return Service
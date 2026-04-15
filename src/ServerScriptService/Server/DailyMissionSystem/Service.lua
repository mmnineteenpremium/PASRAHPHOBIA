local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DAILY_MISSIONS = {
    {
        id = "IdentifyGhost",
        title = "Identifikasi Ghost",
        description = "Tentukan jenis ghost yang benar sebelum kontrak berakhir.",
        objectiveLabel = "Ghost teridentifikasi",
        target = 1,
        reward = { currency = 200, xp = 80 },
    },
    {
        id = "CollectEvidence",
        title = "Kumpulkan Evidence",
        description = "Kumpulkan tiga bukti investigasi dalam satu sesi.",
        objectiveLabel = "Evidence terkumpul",
        target = 3,
        reward = { currency = 150, xp = 60 },
    },
    {
        id = "SurviveHunt",
        title = "Bertahan Dari Hunt",
        description = "Lolos dari satu fase hunt tanpa mati.",
        objectiveLabel = "Hunt survived",
        target = 1,
        reward = { currency = 175, xp = 70 },
    },
    {
        id = "CompleteContract",
        title = "Selesaikan Kontrak",
        description = "Tuntaskan investigasi dan akhiri match dengan sukses tim.",
        objectiveLabel = "Kontrak selesai",
        target = 1,
        reward = { currency = 250, xp = 100 },
    },
}

local QUEST_OWNER_ATTR = "PasrahQuestOwner"
local QUEST_DATA_ATTR = "PasrahQuestData"
local QUEST_UPDATED_AT_ATTR = "PasrahQuestDataUpdatedAt"
local QUEST_ACTIVE_COUNT_ATTR = "PasrahQuestActiveCount"
local QUEST_COMPLETED_COUNT_ATTR = "PasrahQuestCompletedCount"
local QUEST_LAST_COMPLETED_ID_ATTR = "PasrahQuestLastCompletedId"
local QUEST_LAST_COMPLETED_TITLE_ATTR = "PasrahQuestLastCompletedTitle"
local QUEST_LAST_COMPLETED_XP_ATTR = "PasrahQuestLastCompletedXP"
local QUEST_LAST_COMPLETED_AT_ATTR = "PasrahQuestLastCompletedAt"

local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then
        return playerOrUserId
    end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId.UserId
    end
    return nil
end

local function toPlayer(playerOrUserId)
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId
    end

    local userId = toUserId(playerOrUserId)
    if not userId then
        return nil
    end

    local ok, player = pcall(function()
        return Players:GetPlayerByUserId(userId)
    end)
    if ok then
        return player
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

local function disconnectAll(connections)
    for _, connection in ipairs(connections or {}) do
        connection:Disconnect()
    end
    table.clear(connections)
end

local function findMissionTemplate(missionId)
    for _, template in ipairs(DAILY_MISSIONS) do
        if template.id == missionId then
            return template
        end
    end
    return nil
end

local function nowMillis()
    return DateTime.now().UnixTimestampMillis
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
    self._connections = {}
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
    disconnectAll(self._connections)

    table.insert(self._connections, Players.PlayerAdded:Connect(function(player)
        self:GenerateDailyMissions(player)
        self:SyncPlayer(player)
    end))

    for _, player in ipairs(Players:GetPlayers()) do
        self:GenerateDailyMissions(player)
        self:SyncPlayer(player)
    end
end

function Service:Stop()
    disconnectAll(self._connections)
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
        self:SyncPlayer(player)
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

    self:SyncPlayer(player)
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

function Service:_buildQuestEntry(template, progressValue)
    local clampedProgress = math.max(0, math.floor(tonumber(progressValue) or 0))
    local required = math.max(1, math.floor(tonumber(template.target) or 1))
    return {
        id = template.id,
        title = template.title or template.id,
        description = template.description or "",
        type = "DAILY",
        objectives = {
            {
                id = template.id,
                label = template.objectiveLabel or template.id,
                required = required,
            },
        },
        progress = {
            [template.id] = math.min(clampedProgress, required),
        },
        rewards = {
            xp = math.max(0, math.floor(tonumber(template.reward and template.reward.xp) or 0)),
            currency = math.max(0, math.floor(tonumber(template.reward and template.reward.currency) or 0)),
            currencyType = "MM",
        },
    }
end

function Service:_buildQuestPayload(playerOrUserId)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return {
            active = {},
            completed = {},
            updatedAt = nowMillis(),
        }
    end

    local activeMissions = self._state:Get("activeMissions") or {}
    local completedMissions = self._state:Get("completedMissions") or {}
    local missionProgress = self._state:Get("missionProgress") or {}
    local missionDate = self._state:Get("missionDate") or {}

    local playerActiveMissions = activeMissions[userId] or {}
    local playerCompletedMissions = completedMissions[userId] or {}
    local playerProgress = missionProgress[userId] or {}
    local active = {}
    local completed = {}

    for _, template in ipairs(DAILY_MISSIONS) do
        local progressValue = tonumber(playerProgress[template.id]) or 0
        local isCompleted = playerCompletedMissions[template.id] == true
        if playerActiveMissions[template.id] ~= nil and not isCompleted then
            table.insert(active, self:_buildQuestEntry(template, progressValue))
        end
        if isCompleted then
            table.insert(completed, self:_buildQuestEntry(template, template.target))
        end
    end

    return {
        active = active,
        completed = completed,
        date = missionDate[userId],
        updatedAt = nowMillis(),
    }
end

function Service:SyncPlayer(playerOrUserId)
    local player = toPlayer(playerOrUserId)
    if not player then
        return false, "missing_player"
    end

    local payload = self:_buildQuestPayload(player)
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(payload)
    end)
    if not ok then
        warn(("[DailyMissionSystem] Failed to encode quest payload for %s: %s"):format(player.Name, tostring(encoded)))
        return false, "encode_failed"
    end

    player:SetAttribute(QUEST_OWNER_ATTR, "DailyMissionSystem")
    player:SetAttribute(QUEST_DATA_ATTR, encoded)
    player:SetAttribute(QUEST_UPDATED_AT_ATTR, payload.updatedAt)
    player:SetAttribute(QUEST_ACTIVE_COUNT_ATTR, #(payload.active or {}))
    player:SetAttribute(QUEST_COMPLETED_COUNT_ATTR, #(payload.completed or {}))
    return true
end

function Service:_stampCompletedMission(playerOrUserId, missionId)
    local player = toPlayer(playerOrUserId)
    local template = findMissionTemplate(missionId)
    if not player or not template then
        return
    end

    player:SetAttribute(QUEST_LAST_COMPLETED_ID_ATTR, template.id)
    player:SetAttribute(QUEST_LAST_COMPLETED_TITLE_ATTR, template.title or template.id)
    player:SetAttribute(QUEST_LAST_COMPLETED_XP_ATTR, math.max(0, math.floor(tonumber(template.reward and template.reward.xp) or 0)))
    player:SetAttribute(QUEST_LAST_COMPLETED_AT_ATTR, nowMillis())
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

    local livePlayer = toPlayer(player)
    if livePlayer then
        self:_grantRewards(livePlayer, mission.reward or {})
    end

    self:_publish("MissionCompleted", {
        player = livePlayer or player,
        userId = userId,
        missionId = missionId,
        reward = deepCopy(mission.reward or {}),
    })

    self:_stampCompletedMission(livePlayer or player, missionId)
    self:SyncPlayer(livePlayer or player)

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
        player = toPlayer(player) or player,
        userId = userId,
        missionId = missionId,
        progress = nextValue,
        target = mission.target,
    })

    if nextValue >= (mission.target or 1) then
        self:CompleteMission(player, missionId)
    else
        self:SyncPlayer(player)
    end

    return true
end

function Service:OnPlayerJoinedLobby(payload)
    local player = payload and payload.player or payload
    if player then
        self:GenerateDailyMissions(player)
        self:SyncPlayer(player)
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

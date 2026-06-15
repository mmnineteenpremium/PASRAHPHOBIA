local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEFAULT_TEMPLATES = {
    {
        id = "chapter_1_act_1",
        chapter = 1,
        act = 1,
        objectiveType = "complete_investigation",
        title = "Awal yang Gelap",
        desc = "Selesaikan 3 investigasi pertama",
        target = 3,
        reward = { currency = 500, xp = 200, cosmeticId = "Story_Chapter1_Badge" },
    },
    {
        id = "chapter_1_act_2",
        chapter = 1,
        act = 2,
        objectiveType = "identify_ghost",
        title = "Mengenal Lawsuit",
        desc = "Identifikasi Pocong dan Kuntilanak masing-masing 1 kali",
        target = 2,
        reward = { currency = 800, xp = 350, cosmeticId = "Story_GhostWhisperer_Icon" },
    },
    {
        id = "chapter_2_act_1",
        chapter = 2,
        act = 1,
        objectiveType = "collect_evidence",
        title = "Di Balik Pintu",
        desc = "Kumpulkan 10 evidence dari map HauntedHouse",
        target = 10,
        reward = { currency = 1200, xp = 500, cosmeticId = "Story_Investigator_Frame" },
    },
}

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

local function safeCall(target, methodName, ...)
    if type(target) ~= "table" then
        return nil
    end
    local method = target[methodName]
    if type(method) ~= "function" then
        return nil
    end
    local ok, a, b, c = pcall(method, target, ...)
    if not ok then
        return nil
    end
    return a, b, c
end

local function normalizeTemplates(raw)
    local out = {}
    for _, template in ipairs(raw or {}) do
        if type(template) == "table" and type(template.id) == "string" and type(template.objectiveType) == "string" then
            table.insert(out, {
                id = template.id,
                chapter = tonumber(template.chapter) or 1,
                act = tonumber(template.act) or 1,
                objectiveType = template.objectiveType,
                title = type(template.title) == "string" and template.title or nil,
                desc = type(template.desc) == "string" and template.desc or nil,
                target = math.max(1, math.floor(tonumber(template.target) or 1)),
                reward = {
                    currency = math.max(0, math.floor(tonumber(template.reward and template.reward.currency) or 0)),
                    xp = math.max(0, math.floor(tonumber(template.reward and template.reward.xp) or 0)),
                    cosmeticId = template.reward and template.reward.cosmeticId,
                },
            })
        end
    end
    table.sort(out, function(a, b)
        if a.chapter ~= b.chapter then
            return a.chapter < b.chapter
        end
        return a.act < b.act
    end)
    if #out == 0 then
        return deepCopy(DEFAULT_TEMPLATES)
    end
    return out
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    return self
end

function Service:Init()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        EconomySystem = Services.Get(self._deps, "EconomySystem"),
        ProgressionSystem = Services.Get(self._deps, "ProgressionSystem"),
        InventorySystem = Services.Get(self._deps, "InventorySystem"),
        ContentUpdatePipelineSystem = Services.Get(self._deps, "ContentUpdatePipelineSystem"),
        DataPersistenceService = Services.Get(self._deps, "DataPersistenceService") or Services.Get(self._deps, "DataPersistence"),
    }

    self:_loadConfig()
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

function Service:_loadConfig()
    local section = nil
    local contentSystem = self._dependencies.ContentUpdatePipelineSystem
    if type(contentSystem) == "table" and type(contentSystem.GetSection) == "function" then
        section = contentSystem:GetSection("StoryMissions")
    elseif type(contentSystem) == "table" and type(contentSystem.Service) == "table" and type(contentSystem.Service.GetSection) == "function" then
        section = contentSystem.Service:GetSection("StoryMissions")
    end

    section = section or {}

    self._state:Set("activeStoryCount", math.max(1, math.floor(tonumber(section.ActiveStoryCount) or 3)))
    self._state:Set("templates", normalizeTemplates(section.Chapters or DEFAULT_TEMPLATES))
end

function Service:_persistKey()
    return "storyMissions"
end

function Service:_loadPersistence(userId)
    local persistence = self._dependencies.DataPersistenceService
    if type(persistence) ~= "table" then
        return nil
    end

    local profileData = safeCall(persistence, "LoadProfile", userId)
    if type(profileData) ~= "table" then
        profileData = safeCall(persistence, "LoadPlayerData", userId)
    end

    if type(profileData) ~= "table" then
        return nil
    end

    local liveOps = profileData.liveOps or profileData.profile and profileData.profile.liveOps
    if type(liveOps) ~= "table" then
        return nil
    end

    local story = liveOps[self:_persistKey()]
    if type(story) ~= "table" then
        return nil
    end

    return story
end

function Service:_savePersistence(userId)
    local persistence = self._dependencies.DataPersistenceService
    if type(persistence) ~= "table" then
        return
    end

    local storiesByUser = self._state:Get("playerStories") or {}

    local loaded = safeCall(persistence, "LoadProfile", userId)
    local profile = {}
    if type(loaded) == "table" then
        profile = loaded.profile or loaded
    end

    profile.liveOps = profile.liveOps or {}
    profile.liveOps[self:_persistKey()] = deepCopy(storiesByUser[userId] or {})

    safeCall(persistence, "SaveProfile", userId, {
        profile = profile,
        rank = type(loaded) == "table" and loaded.rank or nil,
    })
end

function Service:_initPlayerStories(userId)
    local storiesByUser = self._state:Get("playerStories") or {}

    if storiesByUser[userId] == nil then
        local persisted = self:_loadPersistence(userId)
        if type(persisted) == "table" and type(persisted.missions) == "table" then
            storiesByUser[userId] = deepCopy(persisted.missions)
        else
            local templates = deepCopy(self._state:Get("templates") or DEFAULT_TEMPLATES)
            local activeCount = self._state:Get("activeStoryCount") or 3
            local init = {}
            for i = 1, math.min(activeCount, #templates) do
                local mission = deepCopy(templates[i])
                mission.progress = 0
                mission.completed = false
                table.insert(init, mission)
            end
            storiesByUser[userId] = init
        end

        self._state:Set("playerStories", storiesByUser)
    end

    return storiesByUser[userId] or {}
end

function Service:_resolvePlayer(userId)
    local playersByUserId = self._state:Get("playersByUserId") or {}
    return playersByUserId[userId] or userId
end

function Service:_grantRewards(userId, mission)
    local playerRef = self:_resolvePlayer(userId)
    local reward = mission.reward or {}

    local economy = self._dependencies.EconomySystem
    local progression = self._dependencies.ProgressionSystem
    local inventory = self._dependencies.InventorySystem

    local currency = math.max(0, math.floor(tonumber(reward.currency) or 0))
    local xp = math.max(0, math.floor(tonumber(reward.xp) or 0))

    if currency > 0 then
        local granted = safeCall(economy, "AddCurrency", playerRef, "MM", currency, "StoryMission")
        if granted ~= true then
            safeCall(economy, "AddCurrency", playerRef, currency, "StoryMission")
        end
        self:_publish("CurrencyEarned", {
            player = typeof(playerRef) == "Instance" and playerRef or nil,
            userId = userId,
            currency = "MM",
            amount = currency,
            reason = "StoryMission",
            missionId = mission.id,
        })
    end

    if xp > 0 then
        safeCall(progression, "GrantXP", playerRef, xp)
        if type(progression) == "table" and type(progression.Service) == "table" then
            safeCall(progression.Service, "GrantXP", playerRef, xp)
        end
        self:_publish("XPGranted", {
            player = typeof(playerRef) == "Instance" and playerRef or nil,
            userId = userId,
            amount = xp,
            reason = "StoryMission",
            missionId = mission.id,
        })
    end

    if type(reward.cosmeticId) == "string" and reward.cosmeticId ~= "" then
        safeCall(inventory, "AddCosmeticOwnership", playerRef, reward.cosmeticId)
        if type(inventory) == "table" and type(inventory.Service) == "table" then
            safeCall(inventory.Service, "AddCosmeticOwnership", playerRef, reward.cosmeticId)
        end
        self:_publish("RewardGranted", {
            player = typeof(playerRef) == "Instance" and playerRef or nil,
            userId = userId,
            rewardType = "Cosmetic",
            cosmeticId = reward.cosmeticId,
            reason = "StoryMission",
            missionId = mission.id,
        })
    end
end

function Service:_completeMission(userId, mission, context)
    if mission.completed == true then
        return
    end

    mission.completed = true
    mission.progress = mission.target
    self:_grantRewards(userId, mission)

    local playerRef = self:_resolvePlayer(userId)
    self:_publish("StoryMissionCompleted", {
        player = typeof(playerRef) == "Instance" and playerRef or nil,
        userId = userId,
        missionId = mission.id,
        chapter = mission.chapter,
        act = mission.act,
        objectiveType = mission.objectiveType,
        reward = deepCopy(mission.reward),
        context = context,
    })

    self:_savePersistence(userId)
end

function Service:_applyProgress(userId, objectiveType, delta, context)
    if delta <= 0 then
        return
    end

    local storiesByUser = self._state:Get("playerStories") or {}
    local stories = storiesByUser[userId]
    if type(stories) ~= "table" then
        return
    end

    local changed = false
    for _, mission in ipairs(stories) do
        if mission.objectiveType == objectiveType and mission.completed ~= true then
            mission.progress = math.min(mission.target, (mission.progress or 0) + delta)
            changed = true

            self:_publish("StoryMissionProgress", {
                userId = userId,
                missionId = mission.id,
                objectiveType = mission.objectiveType,
                progress = mission.progress,
                target = mission.target,
                context = context,
            })

            if mission.progress >= mission.target then
                self:_completeMission(userId, mission, context)
            end
        end
    end

    if changed then
        storiesByUser[userId] = stories
        self._state:Set("playerStories", storiesByUser)
    end
end

function Service:OnPlayerAdded(player)
    local userId = self:_ensurePlayer(player)
    if userId then
        self:_savePersistence(userId)
    end
end

function Service:OnPlayerRemoving(player)
    local userId = toUserId(player)
    if not userId then
        return
    end

    self:_savePersistence(userId)

    local playersByUserId = self._state:Get("playersByUserId") or {}
    playersByUserId[userId] = nil
    self._state:Set("playersByUserId", playersByUserId)
end

function Service:_ensurePlayer(playerOrUserId)
    local userId = toUserId(playerOrUserId)
    if not userId then
        return nil
    end

    local playersByUserId = self._state:Get("playersByUserId") or {}
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        playersByUserId[userId] = playerOrUserId
        self._state:Set("playersByUserId", playersByUserId)
    end

    self:_initPlayerStories(userId)
    return userId
end

function Service:OnMatchEnded(payload)
    local userId = self:_ensurePlayer(payload and payload.player)
    if not userId then
        return
    end

    self:_applyProgress(userId, "complete_investigation", 1, {
        event = "MatchEnded",
        matchId = payload and payload.matchId,
        reason = payload and payload.results and payload.results.reason,
    })
    self:_savePersistence(userId)
end

function Service:OnGhostIdentified(payload)
    local userId = self:_ensurePlayer(payload and payload.player)
    if not userId then
        return
    end

    self:_applyProgress(userId, "identify_ghost", 1, {
        event = "GhostIdentified",
        matchId = payload and payload.matchId,
    })
end

function Service:OnEvidenceCollected(payload)
    local userId = self:_ensurePlayer(payload and payload.player)
    if not userId then
        return
    end

    self:_applyProgress(userId, "collect_evidence", 1, {
        event = "EvidenceCollected",
        matchId = payload and payload.matchId,
        evidenceType = payload and payload.evidenceType,
    })
end

function Service:OnContentCatalogUpdated()
    self:_loadConfig()
end

function Service:GetStoryMissions(playerOrUserId)
    local userId = self:_ensurePlayer(playerOrUserId)
    if not userId then
        return {}
    end
    local storiesByUser = self._state:Get("playerStories") or {}
    return deepCopy(storiesByUser[userId] or {})
end

function Service:GetStorySnapshot(playerOrUserId)
    local userId = self:_ensurePlayer(playerOrUserId)
    if not userId then
        return nil
    end

    local storiesByUser = self._state:Get("playerStories") or {}
    local active = {}
    local completed = {}

    for _, mission in ipairs(storiesByUser[userId] or {}) do
        local target = math.max(1, math.floor(tonumber(mission.target) or 1))
        local progress = math.clamp(math.floor(tonumber(mission.progress) or 0), 0, target)
        local reward = mission.reward or {}
        local entry = {
            id = mission.id,
            title = mission.title or mission.id,
            description = mission.desc or "",
            type = "STORY",
            chapter = mission.chapter or 1,
            act = mission.act or 1,
            objectives = {
                {
                    id = mission.id,
                    label = mission.desc or mission.title or mission.id,
                    required = target,
                },
            },
            progress = {
                [mission.id] = progress,
            },
            rewards = {
                xp = math.max(0, math.floor(tonumber(reward.xp) or 0)),
                currency = math.max(0, math.floor(tonumber(reward.currency) or 0)),
                currencyType = "MM",
            },
        }

        if mission.completed == true then
            table.insert(completed, entry)
        else
            table.insert(active, entry)
        end
    end

    return {
        userId = userId,
        updatedAt = DateTime.now().UnixTimestampMillis,
        active = active,
        completed = completed,
    }
end

return Service
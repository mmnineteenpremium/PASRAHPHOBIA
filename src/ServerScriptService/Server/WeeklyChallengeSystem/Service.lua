local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEFAULT_TEMPLATES = {
    {
        id = "complete_investigations",
        objectiveType = "complete_investigation",
        target = 10,
        reward = { currency = 2000, xp = 650, royalPassXP = 350, cosmeticId = "Weekly_Investigator_Badge" },
    },
    {
        id = "identify_ghosts_weekly",
        objectiveType = "identify_ghost",
        target = 8,
        reward = { currency = 1800, xp = 600, royalPassXP = 320, cosmeticId = "Weekly_GhostHunter_Icon" },
    },
    {
        id = "survive_hunts_weekly",
        objectiveType = "survive_hunt",
        target = 6,
        reward = { currency = 1700, xp = 540, royalPassXP = 300, cosmeticId = "Weekly_SteadyNerves_Banner" },
    },
    {
        id = "evidence_mastery",
        objectiveType = "collect_evidence",
        target = 24,
        reward = { currency = 2200, xp = 700, royalPassXP = 380, cosmeticId = "Weekly_EvidenceArchivist_Frame" },
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
                objectiveType = template.objectiveType,
                target = math.max(1, math.floor(tonumber(template.target) or 1)),
                reward = {
                    currency = math.max(0, math.floor(tonumber(template.reward and template.reward.currency) or 0)),
                    xp = math.max(0, math.floor(tonumber(template.reward and template.reward.xp) or 0)),
                    royalPassXP = math.max(0, math.floor(tonumber(template.reward and template.reward.royalPassXP) or 0)),
                    cosmeticId = template.reward and template.reward.cosmeticId,
                },
            })
        end
    end
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
    self._rng = self._deps.Random or Random.new()
    self._dependencies = {}
    return self
end

function Service:Init()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        EconomySystem = Services.Get(self._deps, "EconomySystem"),
        ProgressionSystem = Services.Get(self._deps, "ProgressionSystem"),
        RoyalPassSystem = Services.Get(self._deps, "RoyalPassSystem"),
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
        section = contentSystem:GetSection("WeeklyChallenges")
    elseif type(contentSystem) == "table" and type(contentSystem.Service) == "table" and type(contentSystem.Service.GetSection) == "function" then
        section = contentSystem.Service:GetSection("WeeklyChallenges")
    end

    section = section or {}

    local resetDays = math.max(1, math.floor(tonumber(section.ResetDays) or 7))
    self._state:Set("resetSeconds", resetDays * 86400)
    self._state:Set("activeChallengeCount", math.max(1, math.floor(tonumber(section.ActiveChallengeCount) or 4)))
    self._state:Set("templates", normalizeTemplates(section.Challenges or DEFAULT_TEMPLATES))
end

function Service:_cycleStart(nowUnix)
    local resetSeconds = self._state:Get("resetSeconds") or 604800
    local nowValue = math.max(0, math.floor(tonumber(nowUnix) or os.time()))
    return nowValue - (nowValue % resetSeconds)
end

function Service:_persistKey()
    return "weeklyChallenges"
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

    local weekly = liveOps[self:_persistKey()]
    if type(weekly) ~= "table" then
        return nil
    end

    return weekly
end

function Service:_savePersistence(userId)
    local persistence = self._dependencies.DataPersistenceService
    if type(persistence) ~= "table" then
        return
    end

    local challengesByUser = self._state:Get("playerChallenges") or {}
    local cycleByUser = self._state:Get("playerCycleStart") or {}

    local payload = {
        cycleStart = cycleByUser[userId],
        challenges = deepCopy(challengesByUser[userId] or {}),
    }

    local loaded = safeCall(persistence, "LoadProfile", userId)
    local profile = {}
    if type(loaded) == "table" then
        profile = loaded.profile or loaded
    end

    profile.liveOps = profile.liveOps or {}
    profile.liveOps[self:_persistKey()] = payload

    safeCall(persistence, "SaveProfile", userId, {
        profile = profile,
        rank = type(loaded) == "table" and loaded.rank or nil,
    })
end

function Service:_buildChallengesForCycle(userId, cycleStart)
    local templates = deepCopy(self._state:Get("templates") or DEFAULT_TEMPLATES)
    local count = math.min(#templates, self._state:Get("activeChallengeCount") or 4)
    local selected = {}

    while #selected < count and #templates > 0 do
        local index = self._rng:NextInteger(1, #templates)
        local picked = table.remove(templates, index)
        picked.progress = 0
        picked.completed = false
        picked.cycleStart = cycleStart
        picked.userId = userId
        table.insert(selected, picked)
    end

    return selected
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

    local nowUnix = os.time()
    local cycleStart = self:_cycleStart(nowUnix)

    local cycleByUser = self._state:Get("playerCycleStart") or {}
    local challengesByUser = self._state:Get("playerChallenges") or {}

    if challengesByUser[userId] == nil then
        local persisted = self:_loadPersistence(userId)
        if type(persisted) == "table" and type(persisted.challenges) == "table" and tonumber(persisted.cycleStart) == cycleStart then
            challengesByUser[userId] = deepCopy(persisted.challenges)
            cycleByUser[userId] = cycleStart
        else
            challengesByUser[userId] = self:_buildChallengesForCycle(userId, cycleStart)
            cycleByUser[userId] = cycleStart
            self:_publish("WeeklyChallengesGenerated", {
                userId = userId,
                challenges = deepCopy(challengesByUser[userId]),
                cycleStart = cycleStart,
            })
        end

        self._state:Set("playerChallenges", challengesByUser)
        self._state:Set("playerCycleStart", cycleByUser)
    end

    if cycleByUser[userId] ~= cycleStart then
        challengesByUser[userId] = self:_buildChallengesForCycle(userId, cycleStart)
        cycleByUser[userId] = cycleStart
        self._state:Set("playerChallenges", challengesByUser)
        self._state:Set("playerCycleStart", cycleByUser)

        self:_publish("WeeklyChallengesReset", {
            userId = userId,
            cycleStart = cycleStart,
            challenges = deepCopy(challengesByUser[userId]),
        })
    end

    return userId
end

function Service:GetWeeklyChallenges(playerOrUserId)
    local userId = self:_ensurePlayer(playerOrUserId)
    if not userId then
        return {}
    end
    local challengesByUser = self._state:Get("playerChallenges") or {}
    return deepCopy(challengesByUser[userId] or {})
end

function Service:_resolvePlayer(userId)
    local playersByUserId = self._state:Get("playersByUserId") or {}
    return playersByUserId[userId] or userId
end

function Service:_grantRewards(userId, challenge)
    local playerRef = self:_resolvePlayer(userId)
    local reward = challenge.reward or {}

    local economy = self._dependencies.EconomySystem
    local progression = self._dependencies.ProgressionSystem
    local royalPass = self._dependencies.RoyalPassSystem
    local inventory = self._dependencies.InventorySystem

    local currency = math.max(0, math.floor(tonumber(reward.currency) or 0))
    local xp = math.max(0, math.floor(tonumber(reward.xp) or 0))
    local passXP = math.max(0, math.floor(tonumber(reward.royalPassXP) or 0))

    if currency > 0 then
        local granted = safeCall(economy, "AddCurrency", playerRef, "MM", currency, "WeeklyChallenge")
        if granted ~= true then
            safeCall(economy, "AddCurrency", playerRef, currency, "WeeklyChallenge")
        end
        self:_publish("CurrencyEarned", {
            player = typeof(playerRef) == "Instance" and playerRef or nil,
            userId = userId,
            currency = "MM",
            amount = currency,
            reason = "WeeklyChallenge",
            challengeId = challenge.id,
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
            reason = "WeeklyChallenge",
            challengeId = challenge.id,
        })
    end

    if passXP > 0 then
        local added = safeCall(royalPass, "AddXP", playerRef, passXP, "WeeklyChallenge")
        if added == nil and type(royalPass) == "table" and type(royalPass.Service) == "table" then
            safeCall(royalPass.Service, "AddXP", playerRef, passXP, "WeeklyChallenge")
        end
        self:_publish("RoyalPassProgressGranted", {
            player = typeof(playerRef) == "Instance" and playerRef or nil,
            userId = userId,
            amount = passXP,
            source = "WeeklyChallenge",
            challengeId = challenge.id,
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
            reason = "WeeklyChallenge",
            challengeId = challenge.id,
        })
    end
end

function Service:_completeChallenge(userId, challenge, context)
    if challenge.completed == true then
        return
    end

    challenge.completed = true
    challenge.progress = challenge.target
    self:_grantRewards(userId, challenge)

    local playerRef = self:_resolvePlayer(userId)
    self:_publish("WeeklyChallengeCompleted", {
        player = typeof(playerRef) == "Instance" and playerRef or nil,
        userId = userId,
        challengeId = challenge.id,
        objectiveType = challenge.objectiveType,
        reward = deepCopy(challenge.reward),
        context = context,
    })

    self:_savePersistence(userId)
end

function Service:_applyProgress(userId, objectiveType, delta, context)
    if delta <= 0 then
        return
    end

    local challengesByUser = self._state:Get("playerChallenges") or {}
    local challenges = challengesByUser[userId]
    if type(challenges) ~= "table" then
        return
    end

    local changed = false
    for _, challenge in ipairs(challenges) do
        if challenge.objectiveType == objectiveType and challenge.completed ~= true then
            challenge.progress = math.min(challenge.target, (challenge.progress or 0) + delta)
            changed = true

            self:_publish("WeeklyChallengeProgress", {
                userId = userId,
                challengeId = challenge.id,
                objectiveType = challenge.objectiveType,
                progress = challenge.progress,
                target = challenge.target,
                context = context,
            })

            if challenge.progress >= challenge.target then
                self:_completeChallenge(userId, challenge, context)
            end
        end
    end

    if changed then
        challengesByUser[userId] = challenges
        self._state:Set("playerChallenges", challengesByUser)
    end
end

function Service:_forEachAliveInMatch(matchId, callback)
    local matchPlayers = self._state:Get("matchPlayers") or {}
    local players = matchPlayers[matchId]
    if type(players) ~= "table" then
        return
    end

    for userId, entry in pairs(players) do
        if entry.alive ~= false then
            callback(userId, entry)
        end
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

function Service:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    if type(matchId) ~= "string" then
        return
    end

    local matchPlayers = self._state:Get("matchPlayers") or {}
    matchPlayers[matchId] = {}

    for _, player in ipairs(payload.players or {}) do
        local userId = self:_ensurePlayer(player)
        if userId then
            matchPlayers[matchId][userId] = {
                player = player,
                alive = true,
            }
        end
    end

    self._state:Set("matchPlayers", matchPlayers)
end

function Service:OnPlayerDied(payload)
    local matchId = payload and payload.matchId
    local userId = payload and (payload.userId or toUserId(payload.player))
    if type(matchId) ~= "string" or not userId then
        return
    end

    local matchPlayers = self._state:Get("matchPlayers") or {}
    local players = matchPlayers[matchId]
    if type(players) ~= "table" then
        return
    end

    if type(players[userId]) ~= "table" then
        players[userId] = {
            alive = false,
            player = payload.player,
        }
    end
    players[userId].alive = false
    matchPlayers[matchId] = players
    self._state:Set("matchPlayers", matchPlayers)
end

function Service:OnHuntEnded(payload)
    local matchId = payload and payload.matchId
    if type(matchId) ~= "string" then
        return
    end

    self:_forEachAliveInMatch(matchId, function(userId)
        self:_ensurePlayer(userId)
        self:_applyProgress(userId, "survive_hunt", 1, {
            event = "HuntEnded",
            matchId = matchId,
        })
    end)
end

function Service:OnGhostIdentified(payload)
    local userId = payload and (payload.userId or toUserId(payload.player))
    if not userId then
        return
    end

    self:_ensurePlayer(userId)
    self:_applyProgress(userId, "identify_ghost", 1, {
        event = "GhostIdentified",
        matchId = payload.matchId,
    })
end

function Service:OnEvidenceCollected(payload)
    local userId = payload and (payload.userId or toUserId(payload.player))
    if not userId then
        return
    end

    self:_ensurePlayer(userId)
    self:_applyProgress(userId, "collect_evidence", 1, {
        event = "EvidenceCollected",
        matchId = payload.matchId,
        evidenceType = payload.evidenceType,
    })
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    if type(matchId) ~= "string" then
        return
    end

    local matchPlayers = self._state:Get("matchPlayers") or {}
    local players = matchPlayers[matchId] or {}

    for userId in pairs(players) do
        self:_ensurePlayer(userId)
        self:_applyProgress(userId, "complete_investigation", 1, {
            event = "MatchEnded",
            matchId = matchId,
            reason = payload and payload.results and payload.results.reason,
        })
        self:_savePersistence(userId)
    end

    matchPlayers[matchId] = nil
    self._state:Set("matchPlayers", matchPlayers)
end

function Service:OnContentCatalogUpdated()
    self:_loadConfig()
end

return Service

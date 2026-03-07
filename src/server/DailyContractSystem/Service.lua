local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEFAULT_TEMPLATES = {
    {
        id = "identify_ghosts",
        objectiveType = "identify_ghost",
        target = 3,
        reward = { currency = 450, xp = 180, royalPassXP = 120 },
    },
    {
        id = "collect_evidence",
        objectiveType = "collect_evidence",
        target = 6,
        reward = { currency = 350, xp = 150, royalPassXP = 100 },
    },
    {
        id = "survive_hunts",
        objectiveType = "survive_hunt",
        target = 2,
        reward = { currency = 400, xp = 160, royalPassXP = 110 },
    },
    {
        id = "complete_no_death",
        objectiveType = "no_death_match",
        target = 1,
        reward = { currency = 500, xp = 220, royalPassXP = 140 },
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
        section = contentSystem:GetSection("DailyContracts")
    elseif type(contentSystem) == "table" and type(contentSystem.Service) == "table" and type(contentSystem.Service.GetSection) == "function" then
        section = contentSystem.Service:GetSection("DailyContracts")
    end

    section = section or {}

    local resetHours = math.max(1, math.floor(tonumber(section.ResetHours) or 24))
    self._state:Set("resetSeconds", resetHours * 3600)
    self._state:Set("activeContractCount", math.max(1, math.floor(tonumber(section.ActiveContractCount) or 4)))
    self._state:Set("templates", normalizeTemplates(section.Contracts or DEFAULT_TEMPLATES))
end

function Service:_cycleStart(nowUnix)
    local resetSeconds = self._state:Get("resetSeconds") or 86400
    local nowValue = math.max(0, math.floor(tonumber(nowUnix) or os.time()))
    return nowValue - (nowValue % resetSeconds)
end

function Service:_persistKey()
    return "dailyContracts"
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

    local daily = liveOps[self:_persistKey()]
    if type(daily) ~= "table" then
        return nil
    end

    return daily
end

function Service:_savePersistence(userId)
    local persistence = self._dependencies.DataPersistenceService
    if type(persistence) ~= "table" then
        return
    end

    local contractsByUser = self._state:Get("playerContracts") or {}
    local cycleByUser = self._state:Get("playerCycleStart") or {}

    local payload = {
        cycleStart = cycleByUser[userId],
        contracts = deepCopy(contractsByUser[userId] or {}),
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

function Service:_buildContractsForCycle(userId, cycleStart)
    local templates = deepCopy(self._state:Get("templates") or DEFAULT_TEMPLATES)
    local count = math.min(#templates, self._state:Get("activeContractCount") or 4)
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
    local contractsByUser = self._state:Get("playerContracts") or {}

    if contractsByUser[userId] == nil then
        local persisted = self:_loadPersistence(userId)
        if type(persisted) == "table" and type(persisted.contracts) == "table" and tonumber(persisted.cycleStart) == cycleStart then
            contractsByUser[userId] = deepCopy(persisted.contracts)
            cycleByUser[userId] = cycleStart
        else
            contractsByUser[userId] = self:_buildContractsForCycle(userId, cycleStart)
            cycleByUser[userId] = cycleStart
            self:_publish("DailyContractsGenerated", {
                userId = userId,
                contracts = deepCopy(contractsByUser[userId]),
                cycleStart = cycleStart,
            })
        end

        self._state:Set("playerContracts", contractsByUser)
        self._state:Set("playerCycleStart", cycleByUser)
    end

    if cycleByUser[userId] ~= cycleStart then
        contractsByUser[userId] = self:_buildContractsForCycle(userId, cycleStart)
        cycleByUser[userId] = cycleStart
        self._state:Set("playerContracts", contractsByUser)
        self._state:Set("playerCycleStart", cycleByUser)

        self:_publish("DailyContractsReset", {
            userId = userId,
            cycleStart = cycleStart,
            contracts = deepCopy(contractsByUser[userId]),
        })
    end

    return userId
end

function Service:GetDailyContracts(playerOrUserId)
    local userId = self:_ensurePlayer(playerOrUserId)
    if not userId then
        return {}
    end
    local contractsByUser = self._state:Get("playerContracts") or {}
    return deepCopy(contractsByUser[userId] or {})
end

function Service:_resolvePlayer(userId)
    local playersByUserId = self._state:Get("playersByUserId") or {}
    return playersByUserId[userId] or userId
end

function Service:_grantRewards(userId, contract)
    local playerRef = self:_resolvePlayer(userId)
    local reward = contract.reward or {}

    local economy = self._dependencies.EconomySystem
    local progression = self._dependencies.ProgressionSystem
    local royalPass = self._dependencies.RoyalPassSystem

    local currency = math.max(0, math.floor(tonumber(reward.currency) or 0))
    local xp = math.max(0, math.floor(tonumber(reward.xp) or 0))
    local passXP = math.max(0, math.floor(tonumber(reward.royalPassXP) or 0))

    if currency > 0 then
        local granted = safeCall(economy, "AddCurrency", playerRef, "MM", currency, "DailyContract")
        if granted ~= true then
            safeCall(economy, "AddCurrency", playerRef, currency, "DailyContract")
        end
        self:_publish("CurrencyEarned", {
            player = typeof(playerRef) == "Instance" and playerRef or nil,
            userId = userId,
            currency = "MM",
            amount = currency,
            reason = "DailyContract",
            contractId = contract.id,
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
            reason = "DailyContract",
            contractId = contract.id,
        })
    end

    if passXP > 0 then
        local added = safeCall(royalPass, "AddXP", playerRef, passXP, "DailyContract")
        if added == nil and type(royalPass) == "table" and type(royalPass.Service) == "table" then
            safeCall(royalPass.Service, "AddXP", playerRef, passXP, "DailyContract")
        end
        self:_publish("RoyalPassProgressGranted", {
            player = typeof(playerRef) == "Instance" and playerRef or nil,
            userId = userId,
            amount = passXP,
            source = "DailyContract",
            contractId = contract.id,
        })
    end
end

function Service:_completeContract(userId, contract, context)
    if contract.completed == true then
        return
    end

    contract.completed = true
    contract.progress = contract.target
    self:_grantRewards(userId, contract)

    local playerRef = self:_resolvePlayer(userId)
    self:_publish("DailyContractCompleted", {
        player = typeof(playerRef) == "Instance" and playerRef or nil,
        userId = userId,
        contractId = contract.id,
        objectiveType = contract.objectiveType,
        reward = deepCopy(contract.reward),
        context = context,
    })

    self:_publish("MissionCompleted", {
        player = typeof(playerRef) == "Instance" and playerRef or nil,
        userId = userId,
        missionId = contract.id,
        xpAmount = contract.reward and contract.reward.xp,
        mmAmount = contract.reward and contract.reward.currency,
        royalPassXP = contract.reward and contract.reward.royalPassXP,
        source = "DailyContractSystem",
    })

    self:_savePersistence(userId)
end

function Service:_applyProgress(userId, objectiveType, delta, context)
    if delta <= 0 then
        return
    end

    local contractsByUser = self._state:Get("playerContracts") or {}
    local contracts = contractsByUser[userId]
    if type(contracts) ~= "table" then
        return
    end

    local changed = false
    for _, contract in ipairs(contracts) do
        if contract.objectiveType == objectiveType and contract.completed ~= true then
            contract.progress = math.min(contract.target, (contract.progress or 0) + delta)
            changed = true

            self:_publish("DailyContractProgress", {
                userId = userId,
                contractId = contract.id,
                objectiveType = contract.objectiveType,
                progress = contract.progress,
                target = contract.target,
                context = context,
            })

            if contract.progress >= contract.target then
                self:_completeContract(userId, contract, context)
            end
        end
    end

    if changed then
        contractsByUser[userId] = contracts
        self._state:Set("playerContracts", contractsByUser)
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

    for userId, entry in pairs(players) do
        self:_ensurePlayer(userId)
        if entry.alive ~= false then
            self:_applyProgress(userId, "no_death_match", 1, {
                event = "MatchEnded",
                matchId = matchId,
                reason = payload and payload.results and payload.results.reason,
            })
        end
        self:_savePersistence(userId)
    end

    matchPlayers[matchId] = nil
    self._state:Set("matchPlayers", matchPlayers)
end

function Service:OnContentCatalogUpdated()
    self:_loadConfig()
end

return Service

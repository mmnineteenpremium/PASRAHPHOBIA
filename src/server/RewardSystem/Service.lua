local Service = {}
Service.__index = Service

local DEFAULTS = {
    matchMMBase = 300,
    matchMMPerPerformancePoint = 8,
    contractMM = 500,
    contractXP = 75,
    missionMM = 200,
    missionXP = 25,
}

local function resolveEventBus(deps)
    local eventBus = deps and deps.EventBus
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

local function resolveEconomyService(deps)
    local economy = deps and deps.EconomySystem
    if type(economy) ~= "table" then
        return nil
    end
    if type(economy.AddCurrency) == "function" then
        return economy
    end
    if type(economy.Service) == "table" and type(economy.Service.AddCurrency) == "function" then
        return economy.Service
    end
    return nil
end

local function resolveProgressionService(deps)
    local progression = deps and deps.ProgressionSystem
    if type(progression) ~= "table" then
        return nil
    end
    if type(progression.GrantExperience) == "function" then
        return progression
    end
    if type(progression.Service) == "table" and type(progression.Service.GrantExperience) == "function" then
        return progression.Service
    end
    return nil
end

local function resolveInventoryService(deps)
    local inventory = deps and deps.InventorySystem
    if type(inventory) ~= "table" then
        return nil
    end
    if type(inventory.StoreItem) == "function" then
        return inventory
    end
    if type(inventory.Service) == "table" and type(inventory.Service.StoreItem) == "function" then
        return inventory.Service
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

local function makePlayerRef(playerOrUserId)
    if type(playerOrUserId) == "number" then
        return nil, playerOrUserId
    end
    return playerOrUserId, toUserId(playerOrUserId)
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._config = self._deps.RewardConfig or DEFAULTS
    self._eventBus = resolveEventBus(self._deps)
    self._economy = resolveEconomyService(self._deps)
    self._progression = resolveProgressionService(self._deps)
    self._inventory = resolveInventoryService(self._deps)
    return self
end

function Service:Init()
    self._state:Set("processedMatchIds", self._state:Get("processedMatchIds") or {})
    self._state:Set("processedContractKeys", self._state:Get("processedContractKeys") or {})
    self._state:Set("processedMissionKeys", self._state:Get("processedMissionKeys") or {})
end

function Service:Start()
    -- Event-driven reward pipeline.
    self:_ensureIntegrations()
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_ensureIntegrations()
    if self._economy and self._progression and self._inventory then
        return
    end
    local services = self._deps and (self._deps.Services or self._deps.ServiceRegistry)
    if type(services) ~= "table" then
        return
    end
    local getService = services.GetService or services.Get
    if type(getService) ~= "function" then
        return
    end

    if not self._economy then
        self._economy = resolveEconomyService({
            EconomySystem = getService(services, "EconomySystem"),
        })
    end
    if not self._progression then
        self._progression = resolveProgressionService({
            ProgressionSystem = getService(services, "ProgressionSystem"),
        })
    end
    if not self._inventory then
        self._inventory = resolveInventoryService({
            InventorySystem = getService(services, "InventorySystem"),
        })
    end
end

function Service:_markProcessed(setKey, id)
    if not id then
        return false
    end
    local processed = self._state:Get(setKey) or {}
    if processed[id] then
        return true
    end
    processed[id] = true
    self._state:Set(setKey, processed)
    return false
end

function Service:_grantReward(playerOrUserId, mmAmount, xpAmount, reason, context)
    self:_ensureIntegrations()
    local player, userId = makePlayerRef(playerOrUserId)
    if not userId then
        return
    end

    local mm = math.max(math.floor(mmAmount or 0), 0)
    local xp = math.max(math.floor(xpAmount or 0), 0)

    if mm > 0 and self._economy then
        self._economy:AddCurrency(player or userId, "MM", mm, reason or "reward_system")
        self:_publish("CurrencyEarned", {
            player = player,
            userId = userId,
            currency = "MM",
            amount = mm,
            reason = reason,
            context = context,
        })
    end

    if xp > 0 and self._progression then
        self._progression:GrantExperience(player or userId, xp, reason or "reward_system", context)
    end

    if xp > 0 then
        self:_publish("ExperienceGranted", {
            player = player,
            userId = userId,
            amount = xp,
            reason = reason,
            context = context,
        })
    end

    self:_publish("RewardGranted", {
        player = player,
        userId = userId,
        reward = {
            currency = "MM",
            mm = mm,
            xp = xp,
        },
        reason = reason,
        context = context,
    })
end

function Service:_collectPlayers(payload)
    local players = {}
    local seen = {}
    local function addPlayer(playerOrUserId)
        local userId = toUserId(playerOrUserId)
        if not userId or seen[userId] then
            return
        end
        seen[userId] = true
        table.insert(players, playerOrUserId)
    end

    local directPlayer = payload and (payload.player or payload.userId)
    if directPlayer then
        addPlayer(directPlayer)
    end

    local results = payload and payload.results or {}
    for _, entry in ipairs(results.playerResults or {}) do
        addPlayer(entry.player or entry.userId)
    end
    for _, player in ipairs(payload and payload.players or {}) do
        addPlayer(player)
    end

    return players
end

function Service:HandleMatchEnded(payload)
    local matchId = payload and payload.matchId
    if self:_markProcessed("processedMatchIds", matchId) then
        return
    end

    local results = payload and payload.results or {}
    local playerResults = results.playerResults or {}
    if #playerResults == 0 then
        for _, playerOrUserId in ipairs(self:_collectPlayers(payload)) do
            self:_grantReward(
                playerOrUserId,
                self._config.matchMMBase or DEFAULTS.matchMMBase,
                math.floor((self._config.matchMMBase or DEFAULTS.matchMMBase) / 10),
                "match_completed",
                payload
            )
        end
        return
    end

    for _, entry in ipairs(playerResults) do
        local perf = math.clamp(math.floor(entry.performancePercent or entry.performance or 0), 0, 100)
        local mm = (self._config.matchMMBase or DEFAULTS.matchMMBase)
            + (perf * (self._config.matchMMPerPerformancePoint or DEFAULTS.matchMMPerPerformancePoint))
        local xp = math.max(math.floor(mm / 10), 1)
        self:_grantReward(entry.player or entry.userId, mm, xp, "match_completed", {
            matchId = matchId,
            performancePercent = perf,
        })
    end
end

function Service:HandleContractCompleted(payload)
    local contractId = payload and payload.contractId
    local matchId = payload and payload.matchId
    local key = tostring(contractId or "contract") .. ":" .. tostring(matchId or "match")
    if self:_markProcessed("processedContractKeys", key) then
        return
    end

    local mm = math.max(math.floor(payload and payload.mmAmount or self._config.contractMM or DEFAULTS.contractMM), 0)
    local xp = math.max(math.floor(payload and payload.xpAmount or self._config.contractXP or DEFAULTS.contractXP), 0)
    local players = self:_collectPlayers(payload)

    for _, playerOrUserId in ipairs(players) do
        self:_grantReward(playerOrUserId, mm, xp, "contract_completed", payload)
    end
end

function Service:HandleMissionCompleted(payload)
    local missionId = payload and payload.missionId or payload and payload.objectiveId
    local playerOrUserId = payload and (payload.player or payload.userId)
    local userId = toUserId(playerOrUserId)
    local key = tostring(missionId or "mission") .. ":" .. tostring(userId or "unknown")
    if self:_markProcessed("processedMissionKeys", key) then
        return
    end

    local mm = math.max(math.floor(payload and payload.mmAmount or self._config.missionMM or DEFAULTS.missionMM), 0)
    local xp = math.max(math.floor(payload and payload.xpAmount or self._config.missionXP or DEFAULTS.missionXP), 0)
    self:_grantReward(playerOrUserId, mm, xp, "mission_completed", payload)

    if self._inventory and payload and payload.itemId then
        self._inventory:StoreItem(playerOrUserId, payload.itemId)
    end
end

return Service

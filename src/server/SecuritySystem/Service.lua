local Service = {}
Service.__index = Service

local DEFAULT_CONFIG = {
    AllowedRemotes = {
        EvidenceEvent = true,
        EvidenceRequest = true,
        LobbyEvent = true,
        MatchEvent = true,
        PurchaseEvent = true,
        SanityEvent = true,
    },
    RateLimitWindowSec = 5,
    MaxRemoteCallsPerWindow = 30,
    MaxTeleportDistance = 120,
    ViolationKickScore = 6,
    KickOnViolation = false,
}

local DISALLOWED_ACTIONS = {
    GrantCurrency = true,
    GiveCurrency = true,
    SpawnItem = true,
    SpawnInventoryItem = true,
    ForceMatchStart = true,
    ForceMatchEnd = true,
    DuplicateItem = true,
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

local function resolvePlayersService(deps)
    if deps and deps.Players then
        return deps.Players
    end
    local ok, players = pcall(function()
        return game:GetService("Players")
    end)
    if ok then
        return players
    end
    return nil
end

local function resolveEconomyService(deps)
    local economy = deps and deps.EconomySystem
    if type(economy) ~= "table" then
        return nil
    end
    if type(economy.SpendCurrency) == "function" then
        return economy
    end
    if type(economy.Service) == "table" and type(economy.Service.SpendCurrency) == "function" then
        return economy.Service
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

local function resolveMatchService(deps)
    local match = deps and deps.MatchSystem
    if type(match) ~= "table" then
        return nil
    end
    if type(match.StartMatch) == "function" then
        return match
    end
    if type(match.Service) == "table" and type(match.Service.StartMatch) == "function" then
        return match.Service
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

local function mergeConfig(base, override)
    local merged = {}
    for key, value in pairs(base) do
        merged[key] = value
    end
    for key, value in pairs(override or {}) do
        merged[key] = value
    end
    return merged
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._players = resolvePlayersService(self._deps)
    self._economy = resolveEconomyService(self._deps)
    self._inventory = resolveInventoryService(self._deps)
    self._match = resolveMatchService(self._deps)
    self._config = mergeConfig(DEFAULT_CONFIG, self._deps.SecurityConfig)
    return self
end

function Service:Init()
    self._state:Set("violationsByUserId", self._state:Get("violationsByUserId") or {})
    self._state:Set("violationScoreByUserId", self._state:Get("violationScoreByUserId") or {})
    self._state:Set("remoteCallsByUserId", self._state:Get("remoteCallsByUserId") or {})
    self._state:Set("matchParticipationByUserId", self._state:Get("matchParticipationByUserId") or {})
end

function Service:Start()
    -- Event-driven validation.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_markViolation(player, violationType, severity, details)
    local userId = toUserId(player)
    if not userId then
        return
    end

    local scores = self._state:Get("violationScoreByUserId") or {}
    local violations = self._state:Get("violationsByUserId") or {}

    local scoreToAdd = math.max(math.floor(severity or 1), 1)
    local newScore = (scores[userId] or 0) + scoreToAdd
    scores[userId] = newScore
    self._state:Set("violationScoreByUserId", scores)

    violations[userId] = violations[userId] or {}
    table.insert(violations[userId], {
        type = violationType,
        severity = scoreToAdd,
        details = details,
        at = os.clock(),
    })
    self._state:Set("violationsByUserId", violations)

    warn(string.format("[SecuritySystem] Violation detected for userId=%s type=%s", tostring(userId), tostring(violationType)))
    self:_publish("SecurityViolationDetected", {
        player = player,
        userId = userId,
        violationType = violationType,
        severity = scoreToAdd,
        score = newScore,
        details = details,
    })

    if self._config.KickOnViolation and newScore >= self._config.ViolationKickScore then
        local targetPlayer = player
        if type(targetPlayer) ~= "userdata" and self._players and type(self._players.GetPlayerByUserId) == "function" then
            local ok, resolved = pcall(function()
                return self._players:GetPlayerByUserId(userId)
            end)
            if ok then
                targetPlayer = resolved
            end
        end
        if targetPlayer and type(targetPlayer.Kick) == "function" then
            targetPlayer:Kick("Security violation detected.")
        end
    end
end

function Service:_isRemoteRateLimited(userId, remoteName)
    local now = os.clock()
    local callsByUser = self._state:Get("remoteCallsByUserId") or {}
    callsByUser[userId] = callsByUser[userId] or {}
    callsByUser[userId][remoteName] = callsByUser[userId][remoteName] or {}

    local calls = callsByUser[userId][remoteName]
    local minAllowed = now - self._config.RateLimitWindowSec
    local filtered = {}
    for _, t in ipairs(calls) do
        if t >= minAllowed then
            table.insert(filtered, t)
        end
    end
    table.insert(filtered, now)
    callsByUser[userId][remoteName] = filtered
    self._state:Set("remoteCallsByUserId", callsByUser)

    return #filtered > self._config.MaxRemoteCallsPerWindow, #filtered
end

function Service:_validateCurrencyPayload(payload)
    local action = payload and payload.action
    if action and DISALLOWED_ACTIONS[action] then
        return false, "blocked_action"
    end

    local amount = tonumber(payload and (payload.amount or payload.delta))
    if amount and amount > 0 and (action == "GrantCurrency" or action == "GiveCurrency") then
        return false, "client_currency_grant_blocked"
    end
    return true
end

function Service:_validateInventoryPayload(payload)
    local action = payload and payload.action
    if action and DISALLOWED_ACTIONS[action] then
        return false, "blocked_action"
    end

    local quantity = tonumber(payload and payload.quantity)
    if quantity and quantity > 1 and action == "DuplicateItem" then
        return false, "inventory_duplication_attempt"
    end
    if action == "SpawnItem" or action == "SpawnInventoryItem" then
        return false, "item_spawn_blocked"
    end
    return true
end

function Service:_validateMatchPayload(player, payload)
    local action = payload and payload.action
    if action and DISALLOWED_ACTIONS[action] then
        return false, "blocked_action"
    end

    if action == "ForceMatchStart" or action == "ForceMatchEnd" then
        return false, "client_match_override_blocked"
    end

    local targetPosition = payload and payload.targetPosition
    if targetPosition and typeof(targetPosition) == "Vector3" and typeof(player) == "Instance" and player:IsA("Player") then
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            local distance = (targetPosition - root.Position).Magnitude
            if distance > self._config.MaxTeleportDistance then
                return false, "teleport_abuse_detected"
            end
        end
    end
    return true
end

function Service:ValidateRemoteRequest(player, remoteName, payload, context)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end

    if not self._config.AllowedRemotes[remoteName] then
        self:_markViolation(player, "remote_not_allowed", 2, {
            remoteName = remoteName,
            context = context,
        })
        return false, "remote_not_allowed"
    end

    local rateLimited, calls = self:_isRemoteRateLimited(userId, remoteName)
    if rateLimited then
        self:_markViolation(player, "remote_rate_limited", 2, {
            remoteName = remoteName,
            callsInWindow = calls,
        })
        return false, "remote_rate_limited"
    end

    local action = payload and payload.action
    if action and DISALLOWED_ACTIONS[action] then
        self:_markViolation(player, "disallowed_action", 3, {
            remoteName = remoteName,
            action = action,
            payload = payload,
        })
        return false, "disallowed_action"
    end

    return true
end

function Service:ValidateCurrencyRequest(player, payload)
    local ok, err = self:_validateCurrencyPayload(payload)
    if not ok then
        self:_markViolation(player, "currency_validation_failed", 3, payload)
    end
    return ok, err
end

function Service:ValidateInventoryRequest(player, payload)
    local ok, err = self:_validateInventoryPayload(payload)
    if not ok then
        self:_markViolation(player, "inventory_validation_failed", 3, payload)
    end
    return ok, err
end

function Service:ValidateMatchRequest(player, payload)
    local ok, err = self:_validateMatchPayload(player, payload)
    if not ok then
        self:_markViolation(player, "match_validation_failed", 3, payload)
    end
    return ok, err
end

function Service:OnRemoteEventReceived(payload)
    local player = payload and payload.player
    local remoteName = payload and payload.remoteName
    if not player or not remoteName then
        return
    end
    self:ValidateRemoteRequest(player, remoteName, payload.payload, payload.context)
end

function Service:OnCurrencyTransactionRequested(payload)
    local player = payload and payload.player
    if player then
        self:ValidateCurrencyRequest(player, payload)
    end
end

function Service:OnInventoryUpdateRequested(payload)
    local player = payload and payload.player
    if player then
        self:ValidateInventoryRequest(player, payload)
    end
end

function Service:OnMatchEventRequested(payload)
    local player = payload and payload.player
    if player then
        self:ValidateMatchRequest(player, payload)
    end
end

function Service:OnMatchStarted(payload)
    local participants = self._state:Get("matchParticipationByUserId") or {}
    for _, player in ipairs(payload and payload.players or {}) do
        local userId = toUserId(player)
        if userId then
            participants[userId] = true
        end
    end
    local results = payload and payload.results or {}
    for _, entry in ipairs(results.playerResults or {}) do
        local userId = toUserId(entry.player or entry.userId)
        if userId then
            participants[userId] = true
        end
    end
    self._state:Set("matchParticipationByUserId", participants)
end

function Service:OnMatchEnded(payload)
    local participants = self._state:Get("matchParticipationByUserId") or {}
    local results = payload and payload.results or {}
    for _, entry in ipairs(results.playerResults or {}) do
        local userId = toUserId(entry.player or entry.userId)
        if userId then
            participants[userId] = nil
        end
    end
    self._state:Set("matchParticipationByUserId", participants)
end

function Service:OnCurrencyChanged(payload)
    local player = payload and payload.player
    if not player then
        return
    end
    local delta = tonumber(payload and payload.delta) or 0
    local reason = tostring(payload and payload.reason or "")
    if delta > 100000 then
        self:_markViolation(player, "impossible_currency_delta", 3, payload)
        return
    end
    if delta > 0 and (reason == "client_request" or reason == "grant_currency") then
        self:_markViolation(player, "suspicious_currency_grant", 3, payload)
    end
end

function Service:OnInventoryUpdated(payload)
    local player = payload and payload.player
    if not player then
        return
    end
    local reason = tostring(payload and payload.reason or "")
    if reason == "spawn" or reason == "duplicate" then
        self:_markViolation(player, "suspicious_inventory_update", 3, payload)
    end
end

return Service

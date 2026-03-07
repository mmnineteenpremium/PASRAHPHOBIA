local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEFAULT_EMOTES = {
    Wave = { id = "Wave", category = "LobbyAndMatch" },
    Point = { id = "Point", category = "LobbyAndMatch" },
    Scared = { id = "Scared", category = "LobbyAndMatch" },
    SilentSignal = { id = "SilentSignal", category = "LobbyAndMatch" },
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
    local ok, result = pcall(method, target, ...)
    if not ok then
        return nil
    end
    return result
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
        InventorySystem = Services.Get(self._deps, "InventorySystem"),
        ContentUpdatePipelineSystem = Services.Get(self._deps, "ContentUpdatePipelineSystem"),
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
    local content = self._dependencies.ContentUpdatePipelineSystem
    if type(content) == "table" and type(content.GetSection) == "function" then
        section = content:GetSection("SocialEmotes")
    elseif type(content) == "table" and type(content.Service) == "table" and type(content.Service.GetSection) == "function" then
        section = content.Service:GetSection("SocialEmotes")
    end

    section = section or {}

    self._state:Set("cooldownSeconds", math.max(1, math.floor(tonumber(section.CooldownSeconds) or 2)))

    local allowed = section.AllowedEmotes
    if type(allowed) ~= "table" then
        allowed = DEFAULT_EMOTES
    end

    local normalized = {}
    for emoteId, emoteData in pairs(allowed) do
        if type(emoteId) == "string" then
            normalized[emoteId] = {
                id = emoteData.id or emoteId,
                category = emoteData.category or "LobbyAndMatch",
                requiresCosmetic = emoteData.requiresCosmetic,
            }
        end
    end

    self._state:Set("allowedEmotes", normalized)
end

function Service:_isOnCooldown(userId)
    local nowClock = os.clock()
    local lastEmoteAt = self._state:Get("lastEmoteAtByUser") or {}
    local cooldownSeconds = self._state:Get("cooldownSeconds") or 2
    local previous = lastEmoteAt[userId] or 0

    if nowClock - previous < cooldownSeconds then
        return true, cooldownSeconds - (nowClock - previous)
    end

    lastEmoteAt[userId] = nowClock
    self._state:Set("lastEmoteAtByUser", lastEmoteAt)
    return false, 0
end

function Service:_canUseOwnedEmote(playerRef, emoteData)
    local requiredCosmetic = emoteData and emoteData.requiresCosmetic
    if type(requiredCosmetic) ~= "string" or requiredCosmetic == "" then
        return true
    end

    local inventory = self._dependencies.InventorySystem
    local owns = safeCall(inventory, "OwnsCosmetic", playerRef, requiredCosmetic)
    if owns == nil and type(inventory) == "table" and type(inventory.Service) == "table" then
        owns = safeCall(inventory.Service, "OwnsCosmetic", playerRef, requiredCosmetic)
    end

    return owns == true
end

function Service:RequestEmote(player, payload)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end

    local emoteId = payload and payload.emoteId or payload and payload.id
    if type(emoteId) ~= "string" or emoteId == "" then
        return false, "invalid_emote"
    end

    local allowed = self._state:Get("allowedEmotes") or {}
    local emoteData = allowed[emoteId]
    if type(emoteData) ~= "table" then
        return false, "emote_not_allowed"
    end

    local onCooldown, cooldownLeft = self:_isOnCooldown(userId)
    if onCooldown then
        return false, string.format("cooldown_%.2f", cooldownLeft)
    end

    if not self:_canUseOwnedEmote(player, emoteData) then
        return false, "emote_not_owned"
    end

    local playersInMatch = self._state:Get("playersInMatch") or {}
    local context = payload and payload.context
    if type(context) ~= "string" then
        context = playersInMatch[userId] and "Investigation" or "Lobby"
    end

    local emotePayload = {
        player = player,
        userId = userId,
        emoteId = emoteData.id,
        context = context,
        source = "SocialEmoteSystem",
        cosmeticOnly = true,
        now = os.time(),
    }

    self:_publish("EmotePerformed", emotePayload)
    self:_publish("SocialEmoteUsed", emotePayload)

    return true, nil, emotePayload
end

function Service:OnMatchStarted(payload)
    local playersInMatch = self._state:Get("playersInMatch") or {}
    for _, player in ipairs(payload and payload.players or {}) do
        local userId = toUserId(player)
        if userId then
            playersInMatch[userId] = true
        end
    end
    self._state:Set("playersInMatch", playersInMatch)
end

function Service:OnMatchEnded(payload)
    local playersInMatch = self._state:Get("playersInMatch") or {}

    for _, player in ipairs(payload and payload.players or {}) do
        local userId = toUserId(player)
        if userId then
            playersInMatch[userId] = nil
        end
    end

    local results = payload and payload.results
    for userId, result in pairs(results and results.playerOutcome or {}) do
        local parsed = tonumber(userId)
        if parsed then
            playersInMatch[parsed] = nil
        elseif type(result) == "table" and result.userId then
            playersInMatch[result.userId] = nil
        end
    end

    self._state:Set("playersInMatch", playersInMatch)
end

function Service:OnPlayerRemoving(player)
    local userId = toUserId(player)
    if not userId then
        return
    end

    local playersInMatch = self._state:Get("playersInMatch") or {}
    local lastEmoteAt = self._state:Get("lastEmoteAtByUser") or {}

    playersInMatch[userId] = nil
    lastEmoteAt[userId] = nil

    self._state:Set("playersInMatch", playersInMatch)
    self._state:Set("lastEmoteAtByUser", lastEmoteAt)
end

function Service:OnContentCatalogUpdated()
    self:_loadConfig()
end

return Service

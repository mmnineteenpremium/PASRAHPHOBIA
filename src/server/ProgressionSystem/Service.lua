local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEFAULT_MATCH_XP = 200
local DEFAULT_EVIDENCE_XP = 50
local DEFAULT_OBJECTIVE_XP = 100

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

local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then
        return playerOrUserId
    end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId.UserId
    end
    return nil
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

local function getLevelThreshold(xpTable, level)
    local numeric = xpTable[level]
    if type(numeric) == "number" then
        return numeric
    end

    local named = xpTable[string.format("level%d", level)]
    if type(named) == "number" then
        return named
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
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
        EconomySystem = Services.Get(self._deps, "EconomySystem"),
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
        ContractObjectiveSystem = Services.Get(self._deps, "ContractObjectiveSystem"),
    }
end

function Service:Init()
    self._state:Set("playerXP", self._state:Get("playerXP") or {})
    self._state:Set("playerLevels", self._state:Get("playerLevels") or {})
    self._state:Set("xpTable", self._state:Get("xpTable") or {})
end

function Service:Start()
    -- Event-driven progression service.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_readProfileProgress(player)
    local profileSystem = self._dependencies.ProfileSystem
    local profile = safeCall(profileSystem, "GetPlayerProfile", player)

    if type(profile) ~= "table" and type(profileSystem) == "table" and type(profileSystem.Service) == "table" then
        profile = safeCall(profileSystem.Service, "GetPlayerProfile", player)
    end

    if type(profile) ~= "table" then
        return 0, 1
    end

    local progression = profile.progression or {}
    local xp = tonumber(profile.playerXP or progression.exp) or 0
    local level = tonumber(profile.playerLevel or progression.level) or 1
    return math.max(0, math.floor(xp)), math.max(1, math.floor(level))
end

function Service:_syncProfileProgress(player, xp, level)
    local profileSystem = self._dependencies.ProfileSystem

    if type(profileSystem) == "table" then
        if type(profileSystem.SetPlayerProgression) == "function" then
            safeCall(profileSystem, "SetPlayerProgression", player, xp, level)
            return
        end

        if type(profileSystem.Service) == "table" and type(profileSystem.Service.SetPlayerProgression) == "function" then
            safeCall(profileSystem.Service, "SetPlayerProgression", player, xp, level)
            return
        end

        if type(profileSystem.SetPlayerXP) == "function" then
            safeCall(profileSystem, "SetPlayerXP", player, xp)
        elseif type(profileSystem.Service) == "table" and type(profileSystem.Service.SetPlayerXP) == "function" then
            safeCall(profileSystem.Service, "SetPlayerXP", player, xp)
        end

        if type(profileSystem.SetPlayerLevel) == "function" then
            safeCall(profileSystem, "SetPlayerLevel", player, level)
        elseif type(profileSystem.Service) == "table" and type(profileSystem.Service.SetPlayerLevel) == "function" then
            safeCall(profileSystem.Service, "SetPlayerLevel", player, level)
        end

        if type(profileSystem.UpdateProfile) == "function" then
            safeCall(profileSystem, "UpdateProfile", player, {
                playerXP = xp,
                playerLevel = level,
                progression = {
                    exp = xp,
                    level = level,
                },
            })
        elseif type(profileSystem.Service) == "table" and type(profileSystem.Service.UpdateProfile) == "function" then
            safeCall(profileSystem.Service, "UpdateProfile", player, {
                playerXP = xp,
                playerLevel = level,
                progression = {
                    exp = xp,
                    level = level,
                },
            })
        end
    end
end

function Service:_ensurePlayerProgress(player)
    local userId = toUserId(player)
    if not userId then
        return nil
    end

    local playerXP = self._state:Get("playerXP") or {}
    local playerLevels = self._state:Get("playerLevels") or {}

    if playerXP[userId] == nil or playerLevels[userId] == nil then
        local initialXP, initialLevel = self:_readProfileProgress(player)
        if playerXP[userId] == nil then
            playerXP[userId] = initialXP
        end
        if playerLevels[userId] == nil then
            playerLevels[userId] = initialLevel
        end
        self._state:Set("playerXP", playerXP)
        self._state:Set("playerLevels", playerLevels)
    end

    return userId
end

function Service:CalculateLevel(playerXP)
    local xp = math.max(0, math.floor(tonumber(playerXP) or 0))
    local xpTable = self._state:Get("xpTable") or {}
    local level = 1

    for candidateLevel = 2, 200 do
        local threshold = getLevelThreshold(xpTable, candidateLevel)
        if type(threshold) ~= "number" then
            break
        end

        if xp >= threshold then
            level = candidateLevel
        else
            break
        end
    end

    return level
end

function Service:GetPlayerLevel(player)
    local userId = self:_ensurePlayerProgress(player)
    if not userId then
        return nil
    end

    local playerLevels = self._state:Get("playerLevels") or {}
    return playerLevels[userId] or 1
end

function Service:GrantXP(player, amount)
    local userId = self:_ensurePlayerProgress(player)
    if not userId then
        return false, "invalid_player"
    end

    local xpAmount = math.max(0, math.floor(tonumber(amount) or 0))
    if xpAmount <= 0 then
        return true
    end

    local playerXP = self._state:Get("playerXP") or {}
    local previousXP = playerXP[userId] or 0
    local totalXP = previousXP + xpAmount
    playerXP[userId] = totalXP
    self._state:Set("playerXP", playerXP)

    self:_publish("XPGranted", {
        player = player,
        userId = userId,
        amount = xpAmount,
        previousXP = previousXP,
        totalXP = totalXP,
    })

    self:CheckLevelUp(player)
    return true
end

function Service:CheckLevelUp(player)
    local userId = self:_ensurePlayerProgress(player)
    if not userId then
        return false, "invalid_player"
    end

    local playerXP = self._state:Get("playerXP") or {}
    local playerLevels = self._state:Get("playerLevels") or {}

    local totalXP = playerXP[userId] or 0
    local previousLevel = playerLevels[userId] or 1
    local newLevel = self:CalculateLevel(totalXP)

    if newLevel > previousLevel then
        playerLevels[userId] = newLevel
        self._state:Set("playerLevels", playerLevels)

        self:_publish("PlayerLevelUp", {
            player = player,
            userId = userId,
            previousLevel = previousLevel,
            newLevel = newLevel,
            totalXP = totalXP,
        })
    end

    self:_syncProfileProgress(player, totalXP, playerLevels[userId] or previousLevel)
    return true
end

function Service:OnMatchEnded(payload)
    if type(payload) ~= "table" then
        return
    end

    local difficultyMultiplier = tonumber(payload.difficultyMultiplier or payload.difficulty) or 1
    local baseXP = tonumber(payload.xp) or DEFAULT_MATCH_XP
    local bonusXP = math.max(0, math.floor((difficultyMultiplier - 1) * 50))
    local totalXP = baseXP + bonusXP

    if payload.player then
        self:GrantXP(payload.player, totalXP)
    elseif type(payload.players) == "table" then
        for _, player in ipairs(payload.players) do
            self:GrantXP(player, totalXP)
        end
    end
end

function Service:OnObjectiveCompleted(payload)
    if type(payload) ~= "table" then
        return
    end

    local player = payload.player
    if not player then
        return
    end

    local xp = tonumber(payload.xp) or DEFAULT_OBJECTIVE_XP
    self:GrantXP(player, xp)
end

function Service:OnEvidenceCollected(payload)
    if type(payload) ~= "table" then
        return
    end

    local player = payload.player
    if not player then
        return
    end

    local xp = tonumber(payload.xp) or DEFAULT_EVIDENCE_XP
    self:GrantXP(player, xp)
end

return Service

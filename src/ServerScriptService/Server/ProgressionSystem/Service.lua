local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEFAULT_MATCH_XP = 200
local DEFAULT_EVIDENCE_XP = 50
local DEFAULT_OBJECTIVE_XP = 100

local XP_TABLE = {
    [1]=0,      [2]=100,    [3]=250,    [4]=450,    [5]=700,
    [6]=1000,   [7]=1350,   [8]=1750,   [9]=2200,   [10]=2700,
    [11]=3250,  [12]=3850,  [13]=4500,  [14]=5200,  [15]=5950,
    [16]=6750,  [17]=7600,  [18]=8500,  [19]=9450,  [20]=10450,
    [21]=11500, [22]=12600, [23]=13750, [24]=14950, [25]=16200,
    [26]=17500, [27]=18850, [28]=20250, [29]=21700, [30]=23200,
    [31]=24750, [32]=26350, [33]=28000, [34]=29700, [35]=31450,
    [36]=33250, [37]=35100, [38]=37000, [39]=38950, [40]=40950,
    [41]=43000, [42]=45100, [43]=47250, [44]=49450, [45]=51700,
    [46]=54000, [47]=56350, [48]=58750, [49]=61200, [50]=63700,
    [51]=66250, [52]=68850, [53]=71500, [54]=74200, [55]=76950,
    [56]=79750, [57]=82600, [58]=85500, [59]=88450, [60]=91450,
    [61]=94500, [62]=97600, [63]=100750,[64]=103950,[65]=107200,
    [66]=110500,[67]=113850,[68]=117250,[69]=120700,[70]=124200,
    [71]=127750,[72]=131350,[73]=135000,[74]=138700,[75]=142450,
    [76]=146250,[77]=150100,[78]=154000,[79]=157950,[80]=161950,
    [81]=166000,[82]=170100,[83]=174250,[84]=178450,[85]=182700,
    [86]=187000,[87]=191350,[88]=195750,[89]=200200,[90]=204700,
    [91]=209250,[92]=213850,[93]=218500,[94]=223200,[95]=227950,
    [96]=232750,[97]=237600,[98]=242500,[99]=247450,[100]=999999
}

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
    self._sessions = {}
    return self
end

function Service:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
        EconomySystem = Services.Get(self._deps, "EconomySystem"),
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
        ContractObjectiveSystem = Services.Get(self._deps, "ContractObjectiveSystem"),
        DataPersistenceService = Services.Get(self._deps, "DataPersistenceService"),
    }
end

function Service:Init()
    self._state:Set("playerXP", self._state:Get("playerXP") or {})
    self._state:Set("playerLevels", self._state:Get("playerLevels") or {})
    self._state:Set("xpTable", self._state:Get("xpTable") or {})
    self._sessions = {}
    local current = self._state:Get("xpTable") or {}
    if next(current) == nil then

    local xpTable = {
        [1]=0,[2]=100,[3]=250,[4]=450,[5]=700,
        [6]=1000,[7]=1350,[8]=1750,[9]=2200,[10]=2700,
        [11]=3250,[12]=3850,[13]=4500,[14]=5200,[15]=5950,
        [16]=6750,[17]=7600,[18]=8500,[19]=9450,[20]=10450,
        [21]=11500,[22]=12600,[23]=13750,[24]=14950,[25]=16200,
        [26]=17500,[27]=18850,[28]=20250,[29]=21700,[30]=23200,
        [31]=24750,[32]=26350,[33]=28000,[34]=29700,[35]=31450,
        [36]=33250,[37]=35100,[38]=37000,[39]=38950,[40]=40950,
        [41]=43000,[42]=45100,[43]=47250,[44]=49450,[45]=51700,
        [46]=54000,[47]=56350,[48]=58750,[49]=61200,[50]=63700,
        [51]=66250,[52]=68850,[53]=71500,[54]=74200,[55]=76950,
        [56]=79750,[57]=82600,[58]=85500,[59]=88450,[60]=91450,
        [61]=94500,[62]=97600,[63]=100750,[64]=103950,[65]=107200,
        [66]=110500,[67]=113850,[68]=117250,[69]=120700,[70]=124200,
        [71]=127750,[72]=131350,[73]=135000,[74]=138700,[75]=142450,
        [76]=146250,[77]=150100,[78]=154000,[79]=157950,[80]=161950,
        [81]=166000,[82]=170100,[83]=174250,[84]=178450,[85]=182700,
        [86]=187000,[87]=191350,[88]=195750,[89]=200200,[90]=204700,
        [91]=209250,[92]=213850,[93]=218500,[94]=223200,[95]=227950,
        [96]=232750,[97]=237600,[98]=242500,[99]=247450,[100]=999999
    }
        self._state:Set("xpTable", xpTable)
    end
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

function Service:InitSession(userId, savedData)
    local resolvedId = toUserId(userId)
    if not resolvedId then
        return nil
    end

    local savedXp = 0
    local savedLevel = 1
    local persistence = self._dependencies.DataPersistenceService
    local data = savedData
    if not data and type(persistence) == "table" and type(persistence.GetData) == "function" then
        local ok, result = pcall(persistence.GetData, persistence, resolvedId)
        if ok then
            data = result
        end
    end

    if type(data) == "table" then
        savedXp = tonumber(data.xp or data.playerXP or data.exp) or 0
        savedLevel = tonumber(data.level or data.playerLevel) or 1
    end

    self._sessions[resolvedId] = {
        xp = savedXp or 0,
        level = savedLevel or 1,
    }
    return self._sessions[resolvedId]
end

function Service:SaveSession(userId)
    local resolvedId = toUserId(userId)
    if not resolvedId then
        return false
    end
    local session = self._sessions[resolvedId]
    if not session then
        return false
    end
    local persistence = self._dependencies.DataPersistenceService
    if type(persistence) == "table" and type(persistence.SaveData) == "function" then
        pcall(persistence.SaveData, persistence, resolvedId, {
            xp = session.xp or 0,
            level = session.level or 1,
        })
    end
    self._sessions[resolvedId] = nil
    return true
end

function Service:GetLevel(userId)
    local resolvedId = toUserId(userId)
    if not resolvedId then
        return nil
    end
    local session = self._sessions[resolvedId]
    return session and session.level or nil
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


function Service:AddXP(userId, amount)
    local resolvedId = toUserId(userId)
    if not resolvedId then
        return false, "invalid_player"
    end

    local session = self._sessions[resolvedId]
    if not session then
        warn("[ProgressionSystem] Missing session for userId", resolvedId)
        return false, "missing_session"
    end

    local xpAmount = math.max(0, math.floor(tonumber(amount) or 0))
    if xpAmount <= 0 then
        return true
    end

    session.xp = (session.xp or 0) + xpAmount

    while session.level < 100 do
        local needed = XP_TABLE[session.level + 1]
        if session.xp < needed then
            break
        end
        session.level += 1
        self:_publish("LevelUp", {
            userId = resolvedId,
            newLevel = session.level,
        })
        self:_publish("ProfileUpdateRequested", {
            userId = resolvedId,
            field = "level",
            value = session.level,
        })
    end

    if session.level > 100 then
        session.level = 100
    end
    return true
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
        self:AddXP(payload.player, totalXP)
    elseif type(payload.players) == "table" then
        for _, player in ipairs(payload.players) do
            self:AddXP(player, totalXP)
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

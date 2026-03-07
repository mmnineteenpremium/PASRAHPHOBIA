local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

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

local function resolveGameDataModule(moduleName)
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local shared = replicatedStorage:FindFirstChild("Shared") or replicatedStorage:FindFirstChild("shared")
    if not shared then
        return nil
    end
    local gameData = shared:FindFirstChild("GameData")
    if not gameData then
        return nil
    end
    return gameData:FindFirstChild(moduleName)
end

local function safeRequire(moduleScript)
    if not moduleScript then
        return nil
    end
    local ok, result = pcall(require, moduleScript)
    if ok then
        return result
    end
    return nil
end

local function contains(list, value)
    for _, entry in ipairs(list or {}) do
        if entry == value then
            return true
        end
    end
    return false
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._players = self._deps.Players or game:GetService("Players")
    return self
end

function Service:Init()
    self._eventBus = resolveEventBus(self._deps)
    self:ReloadConfig()
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

function Service:ReloadConfig()
    local cfg = safeRequire(resolveGameDataModule("GlobalOperationsConfig")) or {}
    self._state:Set("config", cfg.Moderation or {})
end

function Service:_nextReportId()
    local nextId = self._state:Get("nextReportId") or 1
    self._state:Set("nextReportId", nextId + 1)
    return string.format("report_%06d", nextId)
end

function Service:_recordAutoCounter(targetUserId, category)
    local counters = self._state:Get("autoActionCounters") or {}
    counters[targetUserId] = counters[targetUserId] or {}
    counters[targetUserId][category] = (counters[targetUserId][category] or 0) + 1
    self._state:Set("autoActionCounters", counters)
    return counters[targetUserId][category]
end

function Service:SubmitReport(payload)
    local reporterUserId = toUserId(payload and (payload.reporter or payload.reporterUserId or payload.player))
    local targetUserId = toUserId(payload and (payload.target or payload.targetUserId))
    local category = payload and payload.category

    local cfg = self._state:Get("config") or {}
    if not reporterUserId or not targetUserId then
        return false, "invalid_reporter_or_target"
    end
    if type(category) ~= "string" or not contains(cfg.ReportCategories, category) then
        return false, "invalid_category"
    end
    if reporterUserId == targetUserId then
        return false, "self_report_forbidden"
    end

    local report = {
        reportId = self:_nextReportId(),
        reporterUserId = reporterUserId,
        targetUserId = targetUserId,
        category = category,
        details = payload.details,
        evidence = payload.evidence,
        matchId = payload.matchId,
        createdAt = os.time(),
        status = "Pending",
    }

    local reports = self._state:Get("reports") or {}
    reports[report.reportId] = report
    self._state:Set("reports", reports)

    local idx = self._state:Get("reportIndexByTarget") or {}
    idx[targetUserId] = idx[targetUserId] or {}
    table.insert(idx[targetUserId], report.reportId)
    self._state:Set("reportIndexByTarget", idx)

    self:_publish("PlayerReportSubmitted", deepCopy(report))

    local count = self:_recordAutoCounter(targetUserId, category)
    local thresholds = cfg.AutoActionThresholds or {}
    local threshold = tonumber(thresholds[category]) or math.huge
    if count >= threshold then
        self:ApplyModerationAction({
            moderatorUserId = 0,
            targetUserId = targetUserId,
            action = "TempMute",
            reason = "auto_threshold_" .. category,
            durationMinutes = cfg.DefaultMuteMinutes,
            source = "ModerationAutoRule",
        })
    end

    return true, nil, report
end

function Service:ApplyModerationAction(payload)
    local targetUserId = toUserId(payload and (payload.target or payload.targetUserId))
    if not targetUserId then
        return false, "invalid_target"
    end

    local action = payload.action
    if type(action) ~= "string" then
        return false, "invalid_action"
    end

    local nowUnix = os.time()
    local cfg = self._state:Get("config") or {}

    if action == "TempMute" then
        local minutes = math.max(1, math.floor(tonumber(payload.durationMinutes) or cfg.DefaultMuteMinutes or 30))
        local map = self._state:Get("mutedUntilByUserId") or {}
        map[targetUserId] = nowUnix + (minutes * 60)
        self._state:Set("mutedUntilByUserId", map)
        self:_publish("PlayerMuted", {
            targetUserId = targetUserId,
            untilUnix = map[targetUserId],
            reason = payload.reason,
            source = payload.source or "Moderator",
        })
    elseif action == "TempBan" then
        local hours = math.max(1, math.floor(tonumber(payload.durationHours) or cfg.DefaultTempBanHours or 24))
        local map = self._state:Get("banByUserId") or {}
        map[targetUserId] = {
            type = "TempBan",
            untilUnix = nowUnix + (hours * 3600),
            reason = payload.reason,
        }
        self._state:Set("banByUserId", map)
        self:_publish("PlayerBanned", {
            targetUserId = targetUserId,
            untilUnix = map[targetUserId].untilUnix,
            reason = payload.reason,
            source = payload.source or "Moderator",
        })
    elseif action == "PermBan" then
        local map = self._state:Get("banByUserId") or {}
        map[targetUserId] = {
            type = "PermBan",
            untilUnix = nil,
            reason = payload.reason,
        }
        self._state:Set("banByUserId", map)
        self:_publish("PlayerBanned", {
            targetUserId = targetUserId,
            untilUnix = nil,
            reason = payload.reason,
            source = payload.source or "Moderator",
        })
    else
        return false, "unsupported_action"
    end

    self._state:PushAction({
        action = action,
        targetUserId = targetUserId,
        moderatorUserId = toUserId(payload.moderatorUserId) or payload.moderatorUserId,
        reason = payload.reason,
        at = nowUnix,
    })

    self:_publish("ModerationActionApplied", {
        action = action,
        targetUserId = targetUserId,
        reason = payload.reason,
        at = nowUnix,
    })

    local targetPlayer = self._players:GetPlayerByUserId(targetUserId)
    if targetPlayer and (action == "TempBan" or action == "PermBan") then
        pcall(function()
            targetPlayer:Kick("Moderation action applied: " .. action)
        end)
    end

    return true
end

function Service:IsUserMuted(userId)
    local muted = self._state:Get("mutedUntilByUserId") or {}
    local untilUnix = muted[userId]
    if type(untilUnix) ~= "number" then
        return false
    end
    if os.time() >= untilUnix then
        muted[userId] = nil
        self._state:Set("mutedUntilByUserId", muted)
        return false
    end
    return true
end

function Service:IsUserBanned(userId)
    local bans = self._state:Get("banByUserId") or {}
    local ban = bans[userId]
    if type(ban) ~= "table" then
        return false
    end
    if ban.type == "PermBan" then
        return true
    end
    if type(ban.untilUnix) == "number" and os.time() < ban.untilUnix then
        return true
    end
    bans[userId] = nil
    self._state:Set("banByUserId", bans)
    return false
end

function Service:OnPlayerJoinValidationRequested(payload)
    local userId = toUserId(payload and (payload.player or payload.userId))
    if not userId then
        return
    end

    self:_publish("PlayerJoinValidationEvaluated", {
        userId = userId,
        allowed = not self:IsUserBanned(userId),
        muted = self:IsUserMuted(userId),
        timestamp = os.time(),
    })
end

function Service:OnChatMessageSubmitted(payload)
    local userId = toUserId(payload and (payload.player or payload.userId))
    if not userId then
        return
    end

    if self:IsUserMuted(userId) then
        self:_publish("ChatMessageModerated", {
            userId = userId,
            accepted = false,
            reason = "muted",
            originalText = payload.text,
        })
        return
    end

    local text = tostring(payload.text or "")
    local lowered = string.lower(text)
    local cfg = self._state:Get("config") or {}
    local filter = cfg.ChatFilter or {}

    local accepted = true
    local reason = "ok"
    for _, word in ipairs(filter.blockedWords or {}) do
        if word ~= "" and string.find(lowered, string.lower(word), 1, true) then
            accepted = false
            reason = "blocked_word"
            break
        end
    end

    self:_publish("ChatMessageModerated", {
        userId = userId,
        accepted = accepted,
        reason = reason,
        originalText = text,
    })

    if not accepted then
        self:SubmitReport({
            reporterUserId = 0,
            targetUserId = userId,
            category = "AbusiveChat",
            details = "Auto-detected blocked word",
        })
    end
end

function Service:OnAntiCheatViolation(payload)
    local userId = toUserId(payload and (payload.player or payload.userId))
    if not userId then
        return
    end

    self:SubmitReport({
        reporterUserId = 0,
        targetUserId = userId,
        category = "Cheating",
        details = payload,
    })
end

return Service

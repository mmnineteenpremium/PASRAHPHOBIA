local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

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

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
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

function Service:ReloadConfig()
    local cfg = safeRequire(resolveGameDataModule("GlobalOperationsConfig")) or {}
    self._state:Set("config", cfg.Platform or {})
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:OnPlayerPlatformDeclared(payload)
    local userId = toUserId(payload and (payload.player or payload.userId))
    if not userId then
        return
    end

    local platformName = tostring(payload.platform or payload.deviceType or "Unknown")
    local byUser = self._state:Get("platformByUserId") or {}
    byUser[userId] = platformName
    self._state:Set("platformByUserId", byUser)

    local cfg = self._state:Get("config") or {}
    local scaleMap = cfg.UiScale or {}
    local perfMap = cfg.PerformanceTier or {}

    local profile = {
        platform = platformName,
        uiScale = tonumber(scaleMap[platformName]) or tonumber(scaleMap.Unknown) or 1,
        performanceTier = perfMap[platformName] or perfMap.Unknown or "Medium",
        timestamp = os.time(),
    }

    local profiles = self._state:Get("profileByUserId") or {}
    profiles[userId] = profile
    self._state:Set("profileByUserId", profiles)

    self:_publish("CrossPlatformProfileResolved", {
        userId = userId,
        profile = profile,
    })

    self:_publish("UIScalingSuggested", {
        userId = userId,
        platform = platformName,
        uiScale = profile.uiScale,
    })
end

function Service:OnVoiceChatPermissionRequested(payload)
    local userId = toUserId(payload and (payload.player or payload.userId))
    if not userId then
        return
    end

    local cfg = self._state:Get("config") or {}
    local voice = cfg.VoiceChat or {}

    local privacyEnabled = payload.privacyEnabled ~= false
    local optedIn = payload.optedIn == true

    local allowed = true
    if voice.RequireOptIn == true and not optedIn then
        allowed = false
    end
    if voice.RespectPrivacySettings == true and not privacyEnabled then
        allowed = false
    end

    self:_publish("VoiceChatPermissionEvaluated", {
        userId = userId,
        allowed = allowed,
        reason = allowed and "allowed" or "privacy_or_opt_in_restricted",
        matchId = payload.matchId,
    })
end

function Service:OnMatchStarted(payload)
    for _, player in ipairs(payload and payload.players or {}) do
        local userId = toUserId(player)
        if userId then
            local platform = (self._state:Get("platformByUserId") or {})[userId] or "Unknown"
            self:_publish("InputProfileSuggested", {
                userId = userId,
                platform = platform,
                profile = platform == "Mobile" and "Touch" or (platform == "Console" and "Gamepad" or "KeyboardMouse"),
            })
        end
    end
end

return Service

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
    self._state:Set("config", cfg.LiveContent or {})
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_mergeOverrides(target, patch)
    for key, value in pairs(patch or {}) do
        if type(value) == "table" and type(target[key]) == "table" then
            self:_mergeOverrides(target[key], value)
        else
            target[key] = value
        end
    end
end

function Service:ApplyLivePatch(payload)
    local cfg = self._state:Get("config") or {}
    if cfg.LivePatchingEnabled == false then
        return false, "live_patching_disabled"
    end

    local patch = payload and payload.patch
    if type(patch) ~= "table" then
        return false, "invalid_patch"
    end

    local overrides = self._state:Get("overrides") or {}
    self:_mergeOverrides(overrides, patch)
    self._state:Set("overrides", overrides)

    local version = (self._state:Get("patchVersion") or 0) + 1
    self._state:Set("patchVersion", version)

    self:_publish("LivePatchApplied", {
        version = version,
        patch = deepCopy(patch),
        appliedAt = os.time(),
    })
    self:_publish("ContentReloadRequested", {
        source = "LiveContentOpsSystem",
        reason = "live_patch",
        version = version,
    })

    return true, nil, version
end

function Service:RegisterContent(payload)
    local category = payload and payload.category
    local id = payload and payload.id
    local data = payload and payload.data

    if type(category) ~= "string" or type(id) ~= "string" or type(data) ~= "table" then
        return false, "invalid_content_registration"
    end

    local manifest = self._state:Get("contentManifest") or {}
    manifest[category] = manifest[category] or {}
    manifest[category][id] = deepCopy(data)
    self._state:Set("contentManifest", manifest)

    self:_publish("ContentRegistered", {
        category = category,
        id = id,
        data = deepCopy(data),
        registeredAt = os.time(),
    })

    if category == "maps" then
        self:_publish("MapContentRegistered", { mapId = id, data = deepCopy(data) })
    elseif category == "ghosts" then
        self:_publish("GhostContentRegistered", { ghostId = id, data = deepCopy(data) })
    elseif category == "cosmetics" then
        self:_publish("CosmeticContentRegistered", { cosmeticId = id, data = deepCopy(data) })
    elseif category == "events" then
        self:_publish("EventContentRegistered", { eventId = id, data = deepCopy(data) })
    end

    return true
end

function Service:RegisterMapVariant(payload)
    local mapId = payload and payload.mapId
    local variantId = payload and payload.variantId
    local data = payload and payload.data
    if type(mapId) ~= "string" or type(variantId) ~= "string" or type(data) ~= "table" then
        return false, "invalid_variant"
    end

    local manifest = self._state:Get("contentManifest") or {}
    manifest.mapVariants = manifest.mapVariants or {}
    manifest.mapVariants[mapId] = manifest.mapVariants[mapId] or {}
    manifest.mapVariants[mapId][variantId] = deepCopy(data)
    self._state:Set("contentManifest", manifest)

    self:_publish("SeasonalMapVariantRegistered", {
        mapId = mapId,
        variantId = variantId,
        data = deepCopy(data),
    })

    return true
end

function Service:ToggleCommunityEvent(payload)
    local eventId = payload and payload.eventId
    if type(eventId) ~= "string" then
        return false, "invalid_event_id"
    end

    local active = self._state:Get("activeCommunityEvents") or {}
    active[eventId] = payload.enabled == true
    self._state:Set("activeCommunityEvents", active)

    self:_publish("CommunityEventToggled", {
        eventId = eventId,
        enabled = active[eventId],
        meta = payload.meta,
        at = os.time(),
    })

    return true
end

function Service:OnCloudConfigurationSyncRequested(payload)
    local cfg = self._state:Get("config") or {}
    if cfg.CloudSyncEnabled == false then
        self:_publish("CloudConfigurationSyncFailed", {
            reason = "cloud_sync_disabled",
            requestedAt = os.time(),
        })
        return
    end

    self:_publish("CloudConfigurationSynced", {
        requestedBy = payload and payload.requestedBy,
        patchVersion = self._state:Get("patchVersion") or 0,
        syncedAt = os.time(),
    })
end

function Service:OnAdaptiveGhostAIUpdateRequested(payload)
    self:_publish("GhostAIAdaptiveAdjustmentApplied", {
        source = "LiveContentOpsSystem",
        adjustment = deepCopy(payload and payload.adjustment or {}),
        context = payload and payload.context,
        appliedAt = os.time(),
    })
end

function Service:OnCooperativeInvestigationEventRequested(payload)
    self:_publish("CooperativeInvestigationEventActivated", {
        eventId = payload and payload.eventId or "multi_ghost_manifestation",
        config = deepCopy(payload and payload.config or {}),
        activatedAt = os.time(),
    })
end

function Service:OnSpecialHuntVariantRequested(payload)
    self:_publish("SpecialHuntVariantActivated", {
        variantId = payload and payload.variantId or "extended_hunt",
        config = deepCopy(payload and payload.config or {}),
        activatedAt = os.time(),
    })
end

function Service:OnSocialHubFeatureRegisterRequested(payload)
    self:_publish("SocialHubFeatureRegistered", {
        featureId = payload and payload.featureId or "mini_activity",
        data = deepCopy(payload and payload.data or {}),
        registeredAt = os.time(),
    })
end

return Service

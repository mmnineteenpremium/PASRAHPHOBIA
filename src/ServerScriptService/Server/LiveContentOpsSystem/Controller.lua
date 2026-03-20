local Services = require(script.Parent.Parent.Core.Services)

local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
    if type(eventBus) ~= "table" then
        return nil
    end
    if type(eventBus.Subscribe) == "function" then
        return eventBus
    end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Subscribe) == "function" then
        return eventBus.Service
    end
    return nil
end

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._eventBus = nil
    self._subscriptions = {}
    self._registered = false
    return self
end

function Controller:Init()
    self._eventBus = resolveEventBus(self._deps)
end

function Controller:Start()
    self:RegisterEventHandlers()
end

function Controller:Stop()
    self:UnregisterEventHandlers()
end

function Controller:RegisterEventHandlers()
    if not self._eventBus or self._registered then
        return
    end

    self:_subscribe("LivePatchApplyRequested", function(payload)
        self._service:ApplyLivePatch(payload)
    end)
    self:_subscribe("ContentManifestRegisterRequested", function(payload)
        self._service:RegisterContent(payload)
    end)
    self:_subscribe("SeasonalVariantRegisterRequested", function(payload)
        self._service:RegisterMapVariant(payload)
    end)
    self:_subscribe("CommunityEventToggleRequested", function(payload)
        self._service:ToggleCommunityEvent(payload)
    end)
    self:_subscribe("CloudConfigurationSyncRequested", function(payload)
        self._service:OnCloudConfigurationSyncRequested(payload)
    end)
    self:_subscribe("AdaptiveGhostAIUpdateRequested", function(payload)
        self._service:OnAdaptiveGhostAIUpdateRequested(payload)
    end)
    self:_subscribe("CooperativeInvestigationEventRequested", function(payload)
        self._service:OnCooperativeInvestigationEventRequested(payload)
    end)
    self:_subscribe("SpecialHuntVariantRequested", function(payload)
        self._service:OnSpecialHuntVariantRequested(payload)
    end)
    self:_subscribe("SocialHubFeatureRegisterRequested", function(payload)
        self._service:OnSocialHubFeatureRegisterRequested(payload)
    end)
    self:_subscribe("LiveContentOpsConfigReloadRequested", function()
        self._service:ReloadConfig()
    end)

    self._registered = true
end

function Controller:UnregisterEventHandlers()
    if not self._eventBus or not self._registered then
        return
    end
    for _, sub in ipairs(self._subscriptions) do
        self._eventBus:Unsubscribe(sub.eventName, sub.callback)
    end
    table.clear(self._subscriptions)
    self._registered = false
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, { eventName = eventName, callback = callback })
end

return Controller

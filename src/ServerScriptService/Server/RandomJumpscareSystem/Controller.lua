local Services = require(script.Parent.Parent.Core.Services)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local function resolveMatchSystem(deps)
    local matchSystem = Services.Get(deps, "MatchSystem")
    if type(matchSystem) ~= "table" then
        return nil
    end
    if type(matchSystem.GetLiveMatch) == "function" then
        return matchSystem
    end
    if type(matchSystem.Service) == "table" and type(matchSystem.Service.GetLiveMatch) == "function" then
        return matchSystem.Service
    end
    return nil
end

local function resolveMatchRemote()
    local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteFolder then
        return nil
    end
    local remote = remoteFolder:FindFirstChild("MatchEvent")
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
end

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._eventBus = nil
    self._matchSystem = nil
    self._matchRemote = nil
    self._subscriptions = {}
    self._registered = false
    return self
end

function Controller:Init()
    self._eventBus = resolveEventBus(self._deps)
    self._matchSystem = resolveMatchSystem(self._deps)
    self._matchRemote = resolveMatchRemote()
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

    self:_subscribe("MatchStarted", function(payload)
        self._service:OnMatchStarted(payload)
    end)
    self:_subscribe("MatchEnded", function(payload)
        self._service:OnMatchEnded(payload)
    end)
    self:_subscribe("GhostInteraction", function(payload)
        self._service:OnGhostInteraction(payload)
    end)
    self:_subscribe("GhostStateChanged", function(payload)
        self._service:OnGhostStateChanged(payload)
    end)
    self:_subscribe("PlayerSanityChanged", function(payload)
        self._service:OnPlayerSanityChanged(payload)
    end)
    self:_subscribe("PhaseStarted", function(payload)
        self._service:OnPhaseStarted(payload)
    end)
    self:_subscribe("JumpscareTriggered", function(payload)
        self:OnJumpscareTriggered(payload)
    end)

    self._registered = true
end

function Controller:UnregisterEventHandlers()
    if not self._eventBus then
        return
    end

    for _, subscription in ipairs(self._subscriptions) do
        self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
    end
    table.clear(self._subscriptions)
    self._registered = false
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

function Controller:_forwardMatchEvent(eventName, payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end

    local matchSystem = self._matchSystem or resolveMatchSystem(self._deps)
    local remote = self._matchRemote or resolveMatchRemote()
    if not matchSystem or not remote then
        return
    end

    self._matchSystem = matchSystem
    self._matchRemote = remote

    local match = matchSystem:GetLiveMatch(matchId)
    local players = type(match) == "table" and match.players or nil
    if type(players) ~= "table" then
        return
    end

    local clientPayload = {}
    for key, value in pairs(payload or {}) do
        clientPayload[key] = value
    end
    clientPayload.eventName = eventName
    clientPayload.source = clientPayload.source or "RandomJumpscareSystem"

    for _, player in ipairs(players) do
        if typeof(player) == "Instance" and player:IsA("Player") then
            remote:FireClient(player, clientPayload)
        end
    end
end

function Controller:OnJumpscareTriggered(payload)
    self:_forwardMatchEvent("JumpscareTriggered", payload)
end

return Controller

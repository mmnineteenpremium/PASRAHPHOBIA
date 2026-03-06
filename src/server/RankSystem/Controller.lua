local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
    local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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
    self._eventBus = resolveEventBus(self._deps)
    self._subscriptions = {}
    self._handlersRegistered = false
    return self
end

function Controller:Init()
    -- Rank events are bound at runtime.
end

function Controller:RegisterEventHandlers()
    if not self._eventBus or self._handlersRegistered then
        return
    end

    self:_subscribe("ExperienceGranted", function(payload)
        self._service:OnExperienceGranted(payload)
    end)
    self:_subscribe("LevelUp", function(payload)
        self._service:OnLevelUp(payload)
    end)
    self:_subscribe("RankUp", function(payload)
        self._service:OnRankUp(payload)
    end)
    self:_subscribe("MatchEnded", function(payload)
        self:OnMatchEnded(payload)
    end)
    self:_subscribe("MissionCompleted", function(payload)
        self:OnMissionCompleted(payload)
    end)
    self:_subscribe("ContractCompleted", function(payload)
        self:OnContractCompleted(payload)
    end)
    self._handlersRegistered = true
end

function Controller:UnregisterEventHandlers()
    if not self._eventBus or not self._handlersRegistered then
        return
    end
    for _, sub in ipairs(self._subscriptions) do
        self._eventBus:Unsubscribe(sub.eventName, sub.callback)
    end
    table.clear(self._subscriptions)
    self._handlersRegistered = false
end

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

function Controller:OnMatchEnded(payload)
    local results = payload and payload.results or {}
    for _, entry in ipairs(results.playerResults or {}) do
        local playerOrUserId = entry.player or entry.userId
        if playerOrUserId then
            self._service:SyncRank(playerOrUserId, nil, "MatchEnded", {
                survived = entry.survived == true,
                performancePercent = entry.performancePercent or entry.performance,
            })
        end
    end
end

function Controller:OnMissionCompleted(payload)
    local playerOrUserId = payload and (payload.player or payload.userId)
    if playerOrUserId then
        self._service:SyncRank(playerOrUserId, nil, "MissionCompleted", payload)
    end
end

function Controller:OnContractCompleted(payload)
    local players = payload and payload.players or {}
    for _, playerOrUserId in ipairs(players) do
        self._service:SyncRank(playerOrUserId, nil, "ContractCompleted", payload)
    end
    local single = payload and (payload.player or payload.userId)
    if single and #players == 0 then
        self._service:SyncRank(single, nil, "ContractCompleted", payload)
    end
end

return Controller

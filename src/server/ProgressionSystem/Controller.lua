local Controller = {}
Controller.__index = Controller

local DEFAULT_XP_REWARDS = {
    MatchCompleted = 30,
    MatchSurvivedBonus = 20,
    MissionCompleted = 40,
    ContractCompleted = 75,
}

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
    -- Event subscriptions are registered in Start.
end

function Controller:RegisterEventHandlers()
    if not self._eventBus or self._handlersRegistered then
        return
    end

    self:_subscribe("PlayerRewardGranted", function(payload)
        self:OnPlayerRewardGranted(payload)
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

function Controller:OnPlayerRewardGranted(payload)
    self._service:OnPlayerRewardGranted(payload)
end

function Controller:OnMatchEnded(payload)
    local results = payload and payload.results or {}
    for _, entry in ipairs(results.playerResults or {}) do
        local playerOrUserId = entry.player or entry.userId
        if playerOrUserId then
            local xp = DEFAULT_XP_REWARDS.MatchCompleted
            if entry.survived == true then
                xp += DEFAULT_XP_REWARDS.MatchSurvivedBonus
            end
            self._service:GrantExperience(playerOrUserId, xp, "match_completed", payload)
        end
    end
end

function Controller:OnMissionCompleted(payload)
    local playerOrUserId = payload and (payload.player or payload.userId)
    if not playerOrUserId then
        return
    end
    self._service:GrantExperience(playerOrUserId, DEFAULT_XP_REWARDS.MissionCompleted, "mission_completed", payload)
end

function Controller:OnContractCompleted(payload)
    local players = payload and payload.players or {}
    if #players > 0 then
        for _, playerOrUserId in ipairs(players) do
            self._service:GrantExperience(playerOrUserId, DEFAULT_XP_REWARDS.ContractCompleted, "contract_completed", payload)
        end
        return
    end
    local playerOrUserId = payload and (payload.player or payload.userId)
    if playerOrUserId then
        self._service:GrantExperience(playerOrUserId, DEFAULT_XP_REWARDS.ContractCompleted, "contract_completed", payload)
    end
end

return Controller

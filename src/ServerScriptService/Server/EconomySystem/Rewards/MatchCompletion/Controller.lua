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
    return self
end

function Controller:Init()
    -- zone-level wiring happens externally.
end

function Controller:RegisterEventHandlers()
    if not self._eventBus then
        return
    end
    local function handleMatchEnded(payload)
        local playerOutcome = payload and payload.playerOutcome
        if type(playerOutcome) == "table" then
            for userIdStr, outcome in pairs(playerOutcome) do
                local player = outcome and outcome.player
                if typeof(player) == "Instance" and player:IsA("Player") then
                    local percent = 0
                    if outcome.survived == true then
                        percent = percent + 50
                    end
                    if outcome.extracted == true then
                        percent = percent + 50
                    end
                    self._service:GrantMatchReward(player, percent)
                end
            end
        end
    end
    self._eventBus:Subscribe("MatchEnded", handleMatchEnded)
    table.insert(self._subscriptions, { eventName = "MatchEnded", callback = handleMatchEnded })
end

function Controller:UnregisterEventHandlers()
    if not self._eventBus then
        return
    end
    for _, sub in ipairs(self._subscriptions) do
        self._eventBus:Unsubscribe(sub.eventName, sub.callback)
    end
    table.clear(self._subscriptions)
end

return Controller

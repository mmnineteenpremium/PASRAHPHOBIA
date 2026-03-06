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
    -- Additional cosmetic hooks can be registered here.
end

function Controller:RegisterEventHandlers()
    if not self._eventBus then
        return
    end

    local function handlePurchased(payload)
        local player = payload and payload.player
        local cosmeticId = payload and payload.cosmeticId
        if player and cosmeticId then
            self._service:EquipCosmetic(player, cosmeticId)
        end
    end
    self._eventBus:Subscribe("CosmeticPurchased", handlePurchased)
    table.insert(self._subscriptions, { eventName = "CosmeticPurchased", callback = handlePurchased })

    local function handleEquipRequested(payload)
        local player = payload and payload.player
        local cosmeticId = payload and payload.cosmeticId
        if not player or not cosmeticId then
            return
        end

        local ok, err = self._service:EquipCosmetic(player, cosmeticId)
        if ok then
            self._eventBus:Publish("CosmeticEquipSucceeded", {
                player = player,
                cosmeticId = cosmeticId,
                source = payload and payload.source,
            })
            return
        end
        self._eventBus:Publish("CosmeticEquipFailed", {
            player = player,
            cosmeticId = cosmeticId,
            error = err,
            source = payload and payload.source,
        })
    end
    self._eventBus:Subscribe("CosmeticEquipRequested", handleEquipRequested)
    table.insert(self._subscriptions, { eventName = "CosmeticEquipRequested", callback = handleEquipRequested })
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

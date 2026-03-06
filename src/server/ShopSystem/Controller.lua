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
    -- Shop request handling is event-driven.
end

function Controller:RegisterEventHandlers()
    if not self._eventBus then
        return
    end

    self:_subscribe("ShopPurchaseRequested", function(payload)
        self:OnShopPurchaseRequested(payload)
    end)
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

function Controller:_subscribe(eventName, callback)
    self._eventBus:Subscribe(eventName, callback)
    table.insert(self._subscriptions, {
        eventName = eventName,
        callback = callback,
    })
end

function Controller:OnShopPurchaseRequested(payload)
    local player = payload and payload.player
    local cosmeticId = payload and payload.cosmeticId
    local itemId = payload and payload.itemId
    local itemType = payload and payload.itemType
    if not player or (not cosmeticId and not itemId) then
        return
    end

    local targetId = cosmeticId or itemId
    local ok, err
    if itemType == "item" and itemId then
        ok, err = self._service:PurchaseItem(player, itemId)
    else
        ok, err = self._service:PurchaseCosmetic(player, targetId)
    end

    if ok then
        self._eventBus:Publish("ShopPurchaseSucceeded", {
            player = player,
            itemId = targetId,
            cosmeticId = cosmeticId,
            itemType = itemType or (cosmeticId and "cosmetic" or "item"),
            source = payload and payload.source,
        })
        return
    end

    self._eventBus:Publish("ShopPurchaseFailed", {
        player = player,
        itemId = targetId,
        cosmeticId = cosmeticId,
        itemType = itemType or (cosmeticId and "cosmetic" or "item"),
        error = err,
        source = payload and payload.source,
    })
end

return Controller

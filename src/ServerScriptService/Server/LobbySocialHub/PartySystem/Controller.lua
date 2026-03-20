local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
    local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    return self
end

function Controller:Init()
    -- Event relay is intentionally minimal.
end

function Controller:EmitJoined(player, partyId)
    if self._eventBus then
        self._eventBus:Publish("PlayerJoinedParty", {
            player = player,
            partyId = partyId,
        })
    end
end

function Controller:EmitLeft(player, partyId)
    if self._eventBus then
        self._eventBus:Publish("PlayerLeftParty", {
            player = player,
            partyId = partyId,
        })
    end
end

return Controller
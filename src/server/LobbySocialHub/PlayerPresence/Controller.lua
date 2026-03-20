local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
    local eventBus = deps and deps.EventBus
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
    -- Hook player lifecycle events here when this module is wired.
end

function Controller:OnPlayerEnteredLobby(player)
    local ok = self._service:EnterLobby(player)
    if not ok then
        return false
    end

    if self._eventBus then
        self._eventBus:Publish("PlayerEnteredLobby", {
            player = player,
        })
    end

    return true
end

return Controller
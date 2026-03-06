local Controller = {}
Controller.__index = Controller

local ServiceRegistry = require(script.Parent.ServiceRegistry)
local SystemLoader = require(script.Parent.SystemLoader.Main)
local SystemFactory = require(script.Parent.SystemFactory)

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._subscriptions = {}
    self._registry = self._deps.Services or self._deps.ServiceRegistry
    self._systemLoader = nil
    self._systemFactory = nil
    return self
end

function Controller:Init()
    -- Prepare startup orchestration and dependency checks.
    if not self._registry then
        self._registry = ServiceRegistry.new()
    end
    self._deps.Services = self._registry
    self._deps.ServiceRegistry = self._registry
    self._systemLoader = SystemLoader.new(self._deps)
    local factoryDeps = {}
    for key, value in pairs(self._deps) do
        factoryDeps[key] = value
    end
    factoryDeps.Services = self._registry
    factoryDeps.ServiceRegistry = self._registry
    self._systemFactory = SystemFactory.new(self._registry, factoryDeps)
    for _, systemName in ipairs(self._service:GetStartupOrder() or {}) do
        local constructor = nil
        if type(self._deps.SystemFactories) == "table" then
            constructor = self._deps.SystemFactories[systemName]
        end
        if type(constructor) ~= "function" then
            constructor = self._systemLoader:GetFactory(systemName)
        end
        if type(constructor) == "function" then
            self._systemFactory:RegisterSystem(systemName, constructor)
        end
    end
    self._deps.SystemFactory = self._systemFactory
end

function Controller:RegisterEventHandlers()
    -- Bootstrap typically does not subscribe to runtime gameplay events.
end

function Controller:UnregisterEventHandlers()
end

function Controller:BootstrapSystems()
    if not self._systemFactory then
        return false, "Missing ServiceRegistry dependency"
    end

    local ok, err = self._systemFactory:CreateSystems(self._service:GetStartupOrder())
    if not ok then
        return false, err
    end

    local registry = self._registry
    self._registry = registry
    self._deps.Services = registry
    self._deps.ServiceRegistry = registry
    self._state:Set("serviceRegistry", registry)
    self._state:Set("services", registry)
    return true
end

function Controller:InitSystems()
    if not self._systemFactory then
        return
    end
    self._systemFactory:InitSystems(self._service:GetStartupOrder())
end

function Controller:StartSystems()
    if not self._systemFactory then
        return
    end
    self._systemFactory:StartSystems(self._service:GetStartupOrder())
end

function Controller:StopSystems()
    if not self._systemFactory then
        return
    end
    self._systemFactory:StopSystems(self._service:GetStartupOrder())
end

function Controller:RestartSystem(systemName)
    if not self._systemFactory then
        return false, "missing_system_factory"
    end
    return self._systemFactory:RestartSystem(systemName, self._service:GetStartupOrder())
end

return Controller

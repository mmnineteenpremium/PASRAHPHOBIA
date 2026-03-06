local Controller = {}
Controller.__index = Controller

local ServiceRegistry = require(script.Parent.ServiceRegistry)
local SystemFactory = require(script.Parent.SystemFactory)
local RemoteFunctionProvisioner = require(script.Parent.RemoteFunctionProvisioner)

function Controller.new(state, service, deps)
    local self = setmetatable({}, Controller)
    self._state = state
    self._service = service
    self._deps = deps or {}
    self._subscriptions = {}
    self._registry = self._deps.Services or self._deps.ServiceRegistry
    self._systemFactory = nil
    self._systemsBootstrapped = false
    self._systemsInitialized = false
    self._systemsStarted = false
    return self
end

local function tryRequire(moduleScript)
    if not moduleScript then
        return nil
    end
    local ok, result = pcall(require, moduleScript)
    if ok then
        return result
    end
    return nil
end

function Controller:_resolveSystemMainFactory(systemName)
    if type(self._deps.SystemFactories) == "table" then
        local customFactory = self._deps.SystemFactories[systemName]
        if type(customFactory) == "function" then
            return customFactory
        end
    end

    local serverRoot = script.Parent.Parent.Parent
    local systemFolder = serverRoot:FindFirstChild(systemName)
    local mainModule = systemFolder and systemFolder:FindFirstChild("Main")
    local mainFactory = tryRequire(mainModule)
    if type(mainFactory) == "table" and type(mainFactory.new) == "function" then
        return function(factoryDeps)
            return mainFactory.new(factoryDeps)
        end
    end

    return nil
end

function Controller:Init()
    -- Prepare startup orchestration and dependency checks.
    if not self._registry then
        self._registry = ServiceRegistry.new()
    end
    RemoteFunctionProvisioner.Ensure(self._deps)
    self._deps.Services = self._registry
    self._deps.ServiceRegistry = self._registry
    local factoryDeps = {}
    for key, value in pairs(self._deps) do
        factoryDeps[key] = value
    end
    factoryDeps.Services = self._registry
    factoryDeps.ServiceRegistry = self._registry
    self._systemFactory = SystemFactory.new(self._registry, factoryDeps)
    for _, systemName in ipairs(self._service:GetStartupOrder() or {}) do
        local constructor = self:_resolveSystemMainFactory(systemName)
        if type(constructor) == "function" then
            self._systemFactory:RegisterSystem(systemName, constructor)
        else
            warn(string.format("[Bootstrap] Missing factory for system '%s' from SYSTEM_MAP order", tostring(systemName)))
        end
    end
    warn(string.format("[Bootstrap] Startup order resolved (%d systems): %s", #(self._service:GetStartupOrder() or {}), table.concat(self._service:GetStartupOrder() or {}, ", ")))
    self._deps.SystemFactory = self._systemFactory
end

function Controller:RegisterEventHandlers()
    -- Bootstrap typically does not subscribe to runtime gameplay events.
end

function Controller:UnregisterEventHandlers()
end

function Controller:BootstrapSystems()
    if self._systemsBootstrapped then
        return true
    end
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
    local loaded = {}
    for _, systemName in ipairs(self._service:GetStartupOrder() or {}) do
        local hasSystem = (type(registry.Has) == "function" and registry:Has(systemName))
            or (type(registry.Get) == "function" and registry:Get(systemName) ~= nil)
        if hasSystem then
            table.insert(loaded, systemName)
        end
    end
    self._state:Set("loadedSystems", loaded)
    warn(string.format("[Bootstrap] Bootstrapped systems (%d): %s", #loaded, table.concat(loaded, ", ")))
    self._systemsBootstrapped = true
    return true
end

function Controller:InitSystems()
    if self._systemsInitialized then
        return true
    end
    if not self._systemFactory then
        return false, "missing_system_factory"
    end
    local ok, err = self._systemFactory:InitSystems(self._service:GetStartupOrder())
    if ok then
        self._systemsInitialized = true
        warn("[Bootstrap] Systems initialized.")
    end
    return ok, err
end

function Controller:StartSystems()
    if self._systemsStarted then
        return true
    end
    if not self._systemFactory then
        return false, "missing_system_factory"
    end
    local ok, err = self._systemFactory:StartSystems(self._service:GetStartupOrder())
    if ok then
        self._systemsStarted = true
        warn("[Bootstrap] Systems started.")
    end
    return ok, err
end

function Controller:StopSystems()
    if not self._systemFactory then
        return false, "missing_system_factory"
    end
    local ok, err = self._systemFactory:StopSystems(self._service:GetStartupOrder())
    self._systemsStarted = false
    self._systemsInitialized = false
    self._systemsBootstrapped = false
    if ok then
        warn("[Bootstrap] Systems stopped.")
    end
    return ok, err
end

function Controller:RestartSystem(systemName)
    if not self._systemFactory then
        return false, "missing_system_factory"
    end
    return self._systemFactory:RestartSystem(systemName, self._service:GetStartupOrder())
end

return Controller

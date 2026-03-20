local FactoryModule = {}
FactoryModule.__index = FactoryModule
local ServiceRegistry = require(script.Parent.ServiceRegistry)
local Services = require(script.Parent.Parent.Services)

local function defaultLogger(message)
    print(message)
end

local function getService(registry, name)
    if type(registry) ~= "table" then
        return nil
    end
    if type(registry.GetService) == "function" then
        return registry:GetService(name)
    end
    if type(registry.Get) == "function" then
        return registry:Get(name)
    end
    return nil
end

local function registerService(registry, name, service)
    if type(registry) ~= "table" then
        return false
    end
    if type(registry.RegisterService) == "function" then
        return registry:RegisterService(name, service)
    end
    if type(registry.Register) == "function" then
        return registry:Register(name, service)
    end
    return false
end

local function getAllServices(registry)
    if type(registry) ~= "table" then
        return {}
    end
    if type(registry.GetServicesByName) == "function" then
        return registry:GetServicesByName()
    end
    if type(registry.GetAll) == "function" then
        return registry:GetAll()
    end
    return {}
end

function FactoryModule.new(services, deps)
    local self = setmetatable({}, FactoryModule)
    self._services = services or Services.GetRegistry(deps) or ServiceRegistry.new()
    self._deps = deps or {}
    self._constructorsByName = {}
    self._createdByName = {}
    self._initializedByName = {}
    self._startedByName = {}
    self._log = self._deps.LogWarning or defaultLogger
    return self
end

function FactoryModule:RegisterSystem(name, constructor)
    if type(name) ~= "string" or name == "" then
        return false
    end
    if type(constructor) ~= "function" then
        return false
    end
    if self._constructorsByName[name] ~= nil then
        self._log(string.format("[SystemFactory] Duplicate register ignored for '%s'", name))
        return false
    end
    self._constructorsByName[name] = constructor
    return true
end

function FactoryModule:Register(name, instance)
    if type(name) ~= "string" or name == "" or type(instance) ~= "table" then
        return false, "invalid_registration"
    end
    if getService(self._services, name) ~= nil then
        return false, "already_registered"
    end
    local ok = registerService(self._services, name, instance)
    if not ok then
        return false, "registry_rejected"
    end
    self._createdByName[name] = true
    return true
end

function FactoryModule:Create(systemName, deps)
    if type(systemName) ~= "string" or systemName == "" then
        return false, "invalid_system_name"
    end
    if getService(self._services, systemName) ~= nil then
        self._createdByName[systemName] = true
        return true, getService(self._services, systemName)
    end

    local constructor = self._constructorsByName[systemName]
    if type(constructor) ~= "function" then
        return false, "missing_factory"
    end

    local localDeps = self:_buildDeps()
    for key, value in pairs(deps or {}) do
        localDeps[key] = value
    end

    local ok, system = pcall(constructor, localDeps)
    if not ok or type(system) ~= "table" then
        self._log(string.format("[SystemFactory] Failed creating system '%s': %s", systemName, tostring(system)))
        return false, "factory_failed"
    end
    if type(system.Init) ~= "function" or type(system.Start) ~= "function" or type(system.Stop) ~= "function" then
        self._log(string.format("[SystemFactory] System '%s' missing lifecycle methods (Init/Start/Stop).", systemName))
    end

    local registered = registerService(self._services, systemName, system)
    if not registered then
        return false, "already_registered"
    end
    self._createdByName[systemName] = true
    self._log(string.format("[SystemFactory] Created system '%s'", systemName))
    return true, system
end

function FactoryModule:_buildDeps()
    local out = {}
    for key, value in pairs(self._deps or {}) do
        out[key] = value
    end

    local services = getAllServices(self._services)
    for name, service in pairs(services) do
        out[name] = service
    end
    out.Services = self._services
    out.ServiceRegistry = self._services
    return out
end

function FactoryModule:CreateSystems(startupOrder)
    for _, name in ipairs(startupOrder or {}) do
        if self._createdByName[name] ~= true then
            local constructor = self._constructorsByName[name]
            if constructor then
                local ok, result = self:Create(name)
                if not ok then
                    return false, string.format("%s:%s", tostring(result), name)
                end
            end
        end
    end
    return true
end

function FactoryModule:InitSystems(startupOrder)
    for _, name in ipairs(startupOrder or {}) do
        if self._initializedByName[name] ~= true then
            local system = getService(self._services, name)
            if system and type(system.Init) == "function" then
                local ok, err = pcall(function()
                    system:Init()
                end)
                if not ok then
                    self._log(string.format("[SystemFactory] Init failed for '%s': %s", name, tostring(err)))
                    return false, string.format("init_failed:%s", name)
                end
            end
            self._initializedByName[name] = true
        end
    end
    return true
end

function FactoryModule:StartSystems(startupOrder)
    for _, name in ipairs(startupOrder or {}) do
        if self._startedByName[name] ~= true then
            local system = getService(self._services, name)
            if system and type(system.Start) == "function" then
                local ok, err = pcall(function()
                    system:Start()
                end)
                if not ok then
                    self._log(string.format("[SystemFactory] Start failed for '%s': %s", name, tostring(err)))
                    return false, string.format("start_failed:%s", name)
                end
            end
            self._startedByName[name] = true
        end
    end
    return true
end

function FactoryModule:StopSystems(startupOrder)
    local order = startupOrder or {}
    for i = #order, 1, -1 do
        local name = order[i]
        if self._startedByName[name] == true then
            local system = getService(self._services, name)
            if system and type(system.Stop) == "function" then
                local ok, err = pcall(function()
                    system:Stop()
                end)
                if not ok then
                    self._log(string.format("[SystemFactory] Stop failed for '%s': %s", name, tostring(err)))
                end
            end
        end
        self._startedByName[name] = nil
        self._initializedByName[name] = nil
    end
    return true
end

function FactoryModule:RestartSystem(name, startupOrder)
    if type(name) ~= "string" or name == "" then
        return false, "invalid_system_name"
    end

    local constructor = self._constructorsByName[name]
    if not constructor then
        return false, "missing_factory"
    end

    local system = getService(self._services, name)
    if not system then
        local ok, created = pcall(constructor, self:_buildDeps())
        if not ok or type(created) ~= "table" then
            return false, "factory_failed"
        end
        registerService(self._services, name, created)
        self._createdByName[name] = true
        system = created
    end

    if self._startedByName[name] == true and type(system.Stop) == "function" then
        local stopOk = pcall(function()
            system:Stop()
        end)
        if not stopOk then
            return false, "restart_stop_failed"
        end
        self._startedByName[name] = nil
    end

    if type(system.Init) == "function" then
        local initOk = pcall(function()
            system:Init()
        end)
        if not initOk then
            return false, "restart_init_failed"
        end
        self._initializedByName[name] = true
    end

    if type(system.Start) == "function" then
        local startOk = pcall(function()
            system:Start()
        end)
        if not startOk then
            return false, "restart_start_failed"
        end
        self._startedByName[name] = true
    end

    if startupOrder and self._createdByName[name] ~= true then
        self._createdByName[name] = true
    end

    return true
end

return FactoryModule

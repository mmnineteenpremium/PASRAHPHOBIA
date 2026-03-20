local SystemFactory = {}
SystemFactory.__index = SystemFactory

local function defaultLogger(message)
    warn(message)
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

function SystemFactory.new(services, deps)
    local self = setmetatable({}, SystemFactory)
    self._services = services
    self._deps = deps or {}
    self._constructorsByName = {}
    self._createdByName = {}
    self._initializedByName = {}
    self._startedByName = {}
    self._log = self._deps.LogWarning or defaultLogger
    return self
end

function SystemFactory:RegisterSystem(name, constructor)
    if type(name) ~= "string" or name == "" then
        return false
    end
    if type(constructor) ~= "function" then
        return false
    end
    self._constructorsByName[name] = constructor
    return true
end

function SystemFactory:_buildDeps()
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

function SystemFactory:CreateSystems(startupOrder)
    for _, name in ipairs(startupOrder or {}) do
        if self._createdByName[name] ~= true then
            local constructor = self._constructorsByName[name]
            if constructor then
                local ok, system = pcall(constructor, self:_buildDeps())
                if ok and type(system) == "table" then
                    registerService(self._services, name, system)
                    self._createdByName[name] = true
                else
                    self._log(string.format("[SystemFactory] Failed creating system '%s': %s", name, tostring(system)))
                    return false, string.format("factory_failed:%s", name)
                end
            end
        end
    end
    return true
end

function SystemFactory:InitSystems(startupOrder)
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

function SystemFactory:StartSystems(startupOrder)
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

function SystemFactory:StopSystems(startupOrder)
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

function SystemFactory:RestartSystem(name, startupOrder)
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

return SystemFactory

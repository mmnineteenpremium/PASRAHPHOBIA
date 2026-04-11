-- ServiceRegistry.lua
-- PASRAHPHOBIA Core Infrastructure - Tier 1
-- Dependency injection hub for all systems
-- Rule: gameplay systems should resolve dependencies through the registry

local RuntimeRegistry = require(script.Parent.SystemRegistry)

local ServiceRegistry = {
    _registry = RuntimeRegistry,
    _initOrder = {},
}

local function contains(list, target)
    for _, value in ipairs(list) do
        if value == target then
            return true
        end
    end
    return false
end

local function collectRegisteredNames(registry)
    local names = {}

    if type(registry) == "table" and type(registry.GetSystemsByName) == "function" then
        for name in pairs(registry:GetSystemsByName()) do
            table.insert(names, name)
        end
    end

    table.sort(names)
    return names
end

function ServiceRegistry:Register(name, service)
    assert(type(name) == "string" and name ~= "", "ServiceRegistry:Register - name must be a non-empty string")
    assert(service ~= nil, "ServiceRegistry:Register - service must not be nil")

    if self:Has(name) then
        error(string.format("ServiceRegistry: '%s' is already registered. Use a unique name.", name))
    end

    local registered = false
    if type(self._registry) == "table" and type(self._registry.RegisterService) == "function" then
        registered = self._registry:RegisterService(name, service) ~= false
    elseif type(self._registry) == "table" and type(self._registry.Register) == "function" then
        registered = self._registry:Register(name, service) ~= false
    end

    if not registered then
        error(string.format("ServiceRegistry: failed to register '%s'.", name))
    end

    if not contains(self._initOrder, name) then
        table.insert(self._initOrder, name)
    end

    print(string.format("[ServiceRegistry] Registered: %s", name))
    return service
end

function ServiceRegistry:RegisterService(name, service)
    return self:Register(name, service)
end

function ServiceRegistry:Get(name)
    local service = self:SafeGet(name)
    if service == nil then
        error(string.format("[ServiceRegistry] Service '%s' not found. Register it before calling Get().", tostring(name)))
    end
    return service
end

function ServiceRegistry:SafeGet(name)
    if type(name) ~= "string" or name == "" then
        return nil
    end

    if type(self._registry) == "table" and type(self._registry.Get) == "function" then
        return self._registry:Get(name)
    end
    if type(self._registry) == "table" and type(self._registry.GetService) == "function" then
        return self._registry:GetService(name)
    end

    return nil
end

function ServiceRegistry:Has(name)
    if type(name) ~= "string" or name == "" then
        return false
    end

    if type(self._registry) == "table" and type(self._registry.Has) == "function" then
        return self._registry:Has(name)
    end
    if type(self._registry) == "table" and type(self._registry.HasService) == "function" then
        return self._registry:HasService(name)
    end

    return self:SafeGet(name) ~= nil
end

function ServiceRegistry:ListAll()
    return collectRegisteredNames(self._registry)
end

function ServiceRegistry:GetReport()
    local ordered = {}
    local seen = {}

    for _, name in ipairs(self._initOrder) do
        if not seen[name] then
            seen[name] = true
            table.insert(ordered, name)
        end
    end

    if type(self._registry) == "table" and type(self._registry.GetSystemLoadOrder) == "function" then
        for _, name in ipairs(self._registry:GetSystemLoadOrder()) do
            if self:Has(name) and not seen[name] then
                seen[name] = true
                table.insert(ordered, name)
            end
        end
    end

    for _, name in ipairs(self:ListAll()) do
        if not seen[name] then
            seen[name] = true
            table.insert(ordered, name)
        end
    end

    print("=== ServiceRegistry Report ===")
    for index, name in ipairs(ordered) do
        print(string.format("  [%d] %s", index, name))
    end
    print("==============================")

    return ordered
end

return ServiceRegistry

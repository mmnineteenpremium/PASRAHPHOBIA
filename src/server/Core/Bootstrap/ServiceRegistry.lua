local ServiceRegistry = {}
ServiceRegistry.__index = ServiceRegistry

function ServiceRegistry.new()
    local self = setmetatable({}, ServiceRegistry)
    self._services = {}
    return self
end

function ServiceRegistry:Register(name, service)
    if type(name) ~= "string" or name == "" or service == nil then
        return false
    end
    if self._services[name] then
        return false
    end
    self._services[name] = service
    return true
end

function ServiceRegistry:Get(name)
    return self._services[name]
end

function ServiceRegistry:Has(name)
    return self._services[name] ~= nil
end

function ServiceRegistry:GetAll()
    local out = {}
    for name, service in pairs(self._services) do
        out[name] = service
    end
    return out
end

-- Compatibility aliases for older callers.
function ServiceRegistry:RegisterService(name, service)
    if self._services[name] == nil then
        self._services[name] = service
        return true
    end
    self._services[name] = service
    return true
end

function ServiceRegistry:GetService(name)
    return self:Get(name)
end

function ServiceRegistry:GetServicesByName()
    return self:GetAll()
end

return ServiceRegistry

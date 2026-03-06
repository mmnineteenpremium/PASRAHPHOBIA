local Services = {}

local function resolveRegistry(deps)
    if type(deps) ~= "table" then
        return nil
    end
    return deps.Services or deps.ServiceRegistry
end

local function getFromRegistry(registry, name)
    if type(registry) ~= "table" then
        return nil
    end
    if type(registry.Get) == "function" then
        local value = registry:Get(name)
        if value ~= nil then
            return value
        end
    end
    if type(registry.GetService) == "function" then
        local value = registry:GetService(name)
        if value ~= nil then
            return value
        end
    end
    return nil
end

function Services.GetRegistry(deps)
    return resolveRegistry(deps)
end

function Services.Get(deps, name)
    if type(name) ~= "string" or name == "" then
        return nil
    end

    -- Resolution order:
    -- 1) deps.Services[name] when Services is a direct map table
    -- 2) deps[name]
    -- 3) ServiceRegistry:Get(name) style lookup
    local services = deps and deps.Services or nil
    if type(services) == "table" and type(services.Get) ~= "function" and type(services.GetService) ~= "function" then
        local value = services[name]
        if value ~= nil then
            return value
        end
    end

    if type(deps) == "table" then
        local value = deps[name]
        if value ~= nil then
            return value
        end
    end

    return getFromRegistry(resolveRegistry(deps), name)
end

return Services

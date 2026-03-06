local Services = {}

local function resolveRegistry(deps)
    if type(deps) ~= "table" then
        return nil
    end
    return deps.Services or deps.ServiceRegistry
end

function Services.GetRegistry(deps)
    return resolveRegistry(deps)
end

function Services.Get(deps, name)
    if type(name) ~= "string" or name == "" then
        return nil
    end

    local registry = resolveRegistry(deps)
    if type(registry) == "table" then
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
    end

    return deps and deps[name] or nil
end

return Services

local SystemRegistry = {}
SystemRegistry.__index = SystemRegistry

function SystemRegistry.new()
    local self = setmetatable({}, SystemRegistry)
    self._systemsByName = {}
    self._order = {}
    return self
end

function SystemRegistry:RegisterService(name, system)
    if type(name) ~= "string" or system == nil then
        return false
    end
    if self._systemsByName[name] == nil then
        table.insert(self._order, name)
    end
    self._systemsByName[name] = system
    return true
end

function SystemRegistry:GetService(name)
    return self._systemsByName[name]
end

function SystemRegistry:GetOrder()
    local out = {}
    for i, name in ipairs(self._order) do
        out[i] = name
    end
    return out
end

function SystemRegistry:GetServicesByName()
    local out = {}
    for name, system in pairs(self._systemsByName) do
        out[name] = system
    end
    return out
end

return SystemRegistry

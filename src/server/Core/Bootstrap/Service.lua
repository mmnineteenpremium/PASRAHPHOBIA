local Service = {}
Service.__index = Service

local SYSTEM_MAP = require(script.Parent.SYSTEM_MAP)

local GROUP_ORDER = {
    "Core",
    "Gameplay",
    "AI",
    "Player",
    "Economy",
    "Social",
}

local IMPLICIT_CORE_SYSTEMS = {
    "EventBus",
}

local function appendUnique(target, seen, value)
    if type(value) ~= "string" or value == "" or seen[value] then
        return
    end
    seen[value] = true
    table.insert(target, value)
end

local function buildStartupOrder(systemMap)
    local out = {}
    local seen = {}

    for _, systemName in ipairs(IMPLICIT_CORE_SYSTEMS) do
        appendUnique(out, seen, systemName)
    end

    for _, groupName in ipairs(GROUP_ORDER) do
        for _, systemName in ipairs(systemMap[groupName] or {}) do
            appendUnique(out, seen, systemName)
        end
    end

    return out
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    return self
end

function Service:Init()
    self._state:Set('systemMap', SYSTEM_MAP)
    self._state:Set('startupGroups', GROUP_ORDER)
    self._state:Set('startupOrder', buildStartupOrder(SYSTEM_MAP))
    self._state:Set('initialized', false)
end

function Service:Start()
    self._state:Set('initialized', true)
end

function Service:Stop()
    self._state:Set('initialized', false)
end

function Service:GetStartupOrder()
    return self._state:Get('startupOrder')
end

function Service:GetSystemMap()
    return self._state:Get("systemMap")
end

function Service:GetStartupGroups()
    return self._state:Get("startupGroups")
end

function Service:IsInitialized()
    return self._state:Get('initialized') == true
end

return Service

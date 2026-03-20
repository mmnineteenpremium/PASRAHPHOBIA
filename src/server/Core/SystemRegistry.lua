local SystemRegistry = {}
SystemRegistry.__index = SystemRegistry

local SYSTEM_GROUP_ORDER = {
    "CoreSystems",
    "GameSystems",
    "GameplaySystems",
    "LiveServiceSystems",
}

local SYSTEMS_BY_GROUP = {
    CoreSystems = {
        "GamePhaseSystem",
    },
    GameSystems = {
        "MatchSystem",
        "GhostSystem",
        "EvidenceSystem",
    },
    GameplaySystems = {
        "SpectatorSystem",
        "LobbySystem",
    },
    LiveServiceSystems = {
        "EconomySystem",
    },
}

local function buildSystemOrder()
    local ordered = {}
    for _, groupName in ipairs(SYSTEM_GROUP_ORDER) do
        for _, systemName in ipairs(SYSTEMS_BY_GROUP[groupName] or {}) do
            table.insert(ordered, systemName)
        end
    end
    return ordered
end

local function cloneArray(source)
    local out = {}
    for index, value in ipairs(source) do
        out[index] = value
    end
    return out
end

local function instantiateSystem(factoryOrSystem, deps)
    if type(factoryOrSystem) ~= "table" then
        return nil, "module did not return a table"
    end
    if type(factoryOrSystem.new) == "function" then
        local ok, systemOrError = pcall(factoryOrSystem.new, deps)
        if not ok then
            return nil, systemOrError
        end
        return systemOrError
    end
    return factoryOrSystem
end

local function validateLifecycle(systemName, system)
    if type(system) ~= "table" then
        return false, string.format("%s instance is not a table", systemName)
    end
    if type(system.Init) ~= "function" then
        return false, string.format("%s missing Init()", systemName)
    end
    if type(system.Start) ~= "function" then
        return false, string.format("%s missing Start()", systemName)
    end
    if type(system.Shutdown) ~= "function" then
        return false, string.format("%s missing Shutdown()", systemName)
    end
    return true
end

function SystemRegistry.new(deps)
    local self = setmetatable({}, SystemRegistry)
    self._deps = deps or {}
    self._systems = {}
    self._systemOrder = buildSystemOrder()
    self._initialized = false
    self._started = false
    return self
end

function SystemRegistry:GetSystemLoadOrder()
    return cloneArray(self._systemOrder)
end

function SystemRegistry:GetSystemsByName()
    local out = {}
    for name, system in pairs(self._systems) do
        out[name] = system
    end
    return out
end

function SystemRegistry:Initialize()
    if self._initialized then
        return true
    end

    print("[Registry] Systems registering")

    local serverRoot = script.Parent.Parent
    local seen = {}

    for _, systemName in ipairs(self._systemOrder) do
        if seen[systemName] then
            error(string.format("[Registry] Duplicate module in load order: %s", systemName))
        end
        seen[systemName] = true

        local systemFolder = serverRoot:FindFirstChild(systemName)
        if not systemFolder then
            error(string.format("[Registry] Missing system folder: %s", systemName))
        end

        local mainModule = systemFolder:FindFirstChild("Main")
        if not mainModule then
            error(string.format("[Registry] Missing Main module for %s", systemName))
        end

        local requireOk, moduleOrError = pcall(require, mainModule)
        if not requireOk then
            error(string.format("[Registry] Failed requiring %s.Main: %s", systemName, tostring(moduleOrError)))
        end

        local instance, instantiateError = instantiateSystem(moduleOrError, self._deps)
        if not instance then
            error(string.format("[Registry] Failed instantiating %s: %s", systemName, tostring(instantiateError)))
        end

        local validLifecycle, lifecycleError = validateLifecycle(systemName, instance)
        if not validLifecycle then
            error(string.format("[Registry] Invalid lifecycle for %s: %s", systemName, lifecycleError))
        end

        self._systems[systemName] = instance
    end

    for _, systemName in ipairs(self._systemOrder) do
        local system = self._systems[systemName]
        local initOk, initError = pcall(function()
            system:Init()
        end)
        if not initOk then
            error(string.format("[Registry] %s Init failed: %s", systemName, tostring(initError)))
        end
        print(string.format("[%s] Init", systemName))
    end

    self._initialized = true
    return true
end

function SystemRegistry:Start()
    if not self._initialized then
        self:Initialize()
    end
    if self._started then
        return true
    end

    for _, systemName in ipairs(self._systemOrder) do
        local system = self._systems[systemName]
        local startOk, startError = pcall(function()
            system:Start()
        end)
        if not startOk then
            error(string.format("[Registry] %s Start failed: %s", systemName, tostring(startError)))
        end
    end

    self._started = true
    print("[Registry] All systems started")
    return true
end

function SystemRegistry:Shutdown()
    if not self._initialized then
        return true
    end

    for index = #self._systemOrder, 1, -1 do
        local systemName = self._systemOrder[index]
        local system = self._systems[systemName]
        if system then
            local ok, shutdownError = pcall(function()
                system:Shutdown()
            end)
            if not ok then
                warn(string.format("[Registry] %s Shutdown failed: %s", systemName, tostring(shutdownError)))
            end
        end
    end

    self._started = false
    return true
end

return SystemRegistry.new()

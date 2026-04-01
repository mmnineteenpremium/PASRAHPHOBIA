local SystemRegistry = {}
SystemRegistry.__index = SystemRegistry

local SYSTEM_GROUP_ORDER = {
    "CoreSystems",
    "GameSystems",
    "GameplaySystems",
    "LiveServiceSystems",
}

local DISABLED_RUNTIME_SYSTEM_NAMES = {
    -- Match flow ownership lives in LobbySystem + MatchSystem.
    MatchmakingSystem = true,
    ServerQueueSystem = true,
    -- Evidence detection ownership lives in EvidenceSystem/EvidenceGateway.
    EvidenceToolSystem = true,
    ToolSignalProcessingSystem = true,
    ToolInteractionSystem = true,
    -- Journal/UI evidence ownership lives in JournalSystem.
    EvidenceJournalSystem = true,
    -- Generic reward fan-out duplicates active reward owners.
    RewardSystem = true,
    ContractRewardSystem = true,
    -- Config loader mirrors publish unused events and are not active owners.
    ContractConfigSystem = true,
    GameConfigSystem = true,
    -- Startup and diagnostics observers only emit orphan internal events.
    EngineStartupValidator = true,
    FinalEngineBootstrap = true,
    SystemIntegrationController = true,
    SystemDiagnosticsController = true,
    DependencyVerificationSystem = true,
    RuntimeIntegritySystem = true,
    ProductionSafetySystem = true,
    -- Monitoring and recovery mirrors emit orphan internal events or depend on stale monitor chains.
    ErrorMonitoringSystem = true,
    LatencyMonitoringSystem = true,
    MemoryTrackingSystem = true,
    RuntimeMetricsSystem = true,
    ServerProfilerSystem = true,
    DataIntegritySystem = true,
    AutoRecoverySystem = true,
    FailSafeSystem = true,
    BackendStabilitySystem = true,
    WatchdogSystem = true,
    -- Legacy health/performance monitors overlap active owners or publish orphan warnings.
    ServerHealthSystem = true,
    ServerPerformanceSystem = true,
    ServerPerformance = true,
    -- QA/platform advisory layers are not wired into the active runtime graph.
    OperationsQASystem = true,
    PlatformSupportSystem = true,
}

local EXPLICIT_SYSTEM_NAMES = {
    EvidenceDeductionEngine = true,
    HorrorDirector = true,
    LobbySocialHub = true,
}

local EARLY_PRELOAD_SYSTEMS = {
    "EventBus",
    "DataPersistenceService",
    "ProfileSystem",
    "RankedSystem",
    "MatchSystem",
    "HorrorDirector",
    "LobbySocialHub",
    "EvidenceDeductionEngine",
}

local SYSTEMS_BY_GROUP = {
    CoreSystems = {
        "EventBus",
        "DataPersistenceService",
        "ProfileSystem",
        "InventorySystem",
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
        "ShopSystem",
        "CosmeticSystem",
        "ProgressionSystem",
        "RankedSystem",
        "ContractRewardSystem",
        "TelemetrySystem",
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
        system.Shutdown = function() end
    end
    return true
end

local function isSystemContainer(candidate)
    if not candidate then
        return false
    end
    if not (candidate:IsA("Folder") or candidate:IsA("ModuleScript")) then
        return false
    end
    local name = candidate.Name
    if DISABLED_RUNTIME_SYSTEM_NAMES[name] == true then
        return false
    end
    if EXPLICIT_SYSTEM_NAMES[name] == true then
        return true
    end
    if name == "EventBus" then
        return true
    end
    if name:match("System$") then
        return true
    end
    if name:match("Service$") then
        return true
    end
    return false
end

local function resolveSystemModule(systemContainer)
    if systemContainer:IsA("ModuleScript") then
        return systemContainer
    end

    local mainModule = systemContainer:FindFirstChild("Main")
    if mainModule and mainModule:IsA("ModuleScript") then
        return mainModule
    end

    return nil
end

local function collectSystemContainers(serverRoot)
    local systemsByName = {}

    for _, child in ipairs(serverRoot:GetChildren()) do
        if isSystemContainer(child) then
            if systemsByName[child.Name] ~= nil then
                warn(string.format("[Registry] Duplicate system folder: %s", child.Name))
            else
                systemsByName[child.Name] = child
            end
        end
    end

    return systemsByName
end

local function buildContainerLoadList(systemsByName)
    local ordered = {}
    local seen = {}

    for _, systemName in ipairs(EARLY_PRELOAD_SYSTEMS) do
        local container = systemsByName[systemName]
        if container ~= nil then
            table.insert(ordered, container)
            seen[systemName] = true
        end
    end

    for _, systemName in ipairs(buildSystemOrder()) do
        local container = systemsByName[systemName]
        if container ~= nil and seen[systemName] ~= true then
            table.insert(ordered, container)
            seen[systemName] = true
        end
    end

    local remaining = {}
    for systemName, container in pairs(systemsByName) do
        if seen[systemName] ~= true then
            table.insert(remaining, container)
        end
    end

    table.sort(remaining, function(a, b)
        return a.Name < b.Name
    end)

    for _, container in ipairs(remaining) do
        table.insert(ordered, container)
    end

    return ordered
end

function SystemRegistry.new(deps)
    local self = setmetatable({}, SystemRegistry)
    self._deps = deps or {}
    self._systems = {}
    self._systemOrder = buildSystemOrder()
    self._initialized = false
    self._started = false
    self._deps.Services = self
    self._deps.ServiceRegistry = self
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

function SystemRegistry:RegisterService(name, service)
    if type(name) ~= "string" or name == "" or type(service) ~= "table" then
        return false
    end
    if self._systems[name] ~= nil then
        return false
    end
    self._systems[name] = service
    return true
end

function SystemRegistry:Register(name, service)
    return self:RegisterService(name, service)
end

function SystemRegistry:GetService(name)
    return self._systems[name]
end

function SystemRegistry:Get(name)
    return self:GetService(name)
end

function SystemRegistry:HasService(name)
    return self._systems[name] ~= nil
end

function SystemRegistry:Has(name)
    return self:HasService(name)
end

function SystemRegistry:Initialize()
    if self._initialized then
        return true
    end

    print("[Registry] Deterministic system order enabled")
    print("[Registry] Systems registering")

    self._bootStart = os.clock()

    local serverRoot = script.Parent.Parent
    local systemsByName = collectSystemContainers(serverRoot)
    local systems = buildContainerLoadList(systemsByName)

    local seen = {}
    local loadOrder = {}
    local loadedSystems = {}

    for _, systemContainer in ipairs(systems) do
        local systemName = systemContainer.Name
        if seen[systemName] then
            warn(string.format("[Registry] Duplicate system folder: %s", systemName))
        else
            seen[systemName] = true

            local systemModule = resolveSystemModule(systemContainer)
            if not systemModule then
                error(string.format("[Registry] Missing Main module for %s", systemName))
            end

            local requireOk, moduleOrError = pcall(require, systemModule)
            if not requireOk then
                error(string.format("[Registry] Failed requiring %s module: %s", systemName, tostring(moduleOrError)))
            end

            local instance, instantiateError = instantiateSystem(moduleOrError, self._deps)
            if not instance then
                error(string.format("[Registry] Failed instantiating %s: %s", systemName, tostring(instantiateError)))
            end

            local validLifecycle, lifecycleError = validateLifecycle(systemName, instance)
            if not validLifecycle then
                error(string.format("[Registry] Invalid lifecycle for %s: %s", systemName, lifecycleError))
            end

            table.insert(loadOrder, systemName)
            self._systems[systemName] = instance
        end
    end

    self._systemOrder = loadOrder
    for _, systemName in ipairs(self._systemOrder) do
        local system = self._systems[systemName]
        if type(system) ~= "table" then
            warn(string.format("[Registry] Invalid system for Init: %s", systemName))
        elseif type(system.Init) ~= "function" then
            warn(string.format("[Registry] Missing Init() for %s", systemName))
        else
            if type(system.Dependencies) == "table" then
                for _, dep in ipairs(system.Dependencies) do
                    if not loadedSystems[dep] then
                        warn(string.format("[Registry] Dependency not initialized for %s: missing %s", systemName, dep))
                    end
                end
            end
            local t0 = os.clock()
            local initOk, initError = pcall(function()
                system:Init()
            end)
            local t1 = os.clock()
            if not initOk then
                error(string.format("[Registry] %s Init failed: %s", systemName, tostring(initError)))
            end
            loadedSystems[systemName] = true
            print(string.format("[%s] Init", systemName))
            print(string.format("[Registry] %s Init %d ms", systemName, math.floor((t1 - t0) * 1000)))
        end
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
        if type(system) ~= "table" then
            warn(string.format("[Registry] Invalid system for Start: %s", systemName))
        elseif type(system.Start) ~= "function" then
            warn(string.format("[Registry] Missing Start() for %s", systemName))
        else
            local t2 = os.clock()
            local startOk, startError = pcall(function()
                system:Start()
            end)
            local t3 = os.clock()
            if not startOk then
                error(string.format("[Registry] %s Start failed: %s", systemName, tostring(startError)))
            end
            print(string.format("[Registry] %s Start %d ms", systemName, math.floor((t3 - t2) * 1000)))
        end
    end

    local bootEnd = os.clock()
    self._started = true
    print("[Registry] All systems started")
    local bootStart = self._bootStart or bootEnd
    print("[Registry] Boot completed in", math.floor((bootEnd - bootStart) * 1000), "ms")
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


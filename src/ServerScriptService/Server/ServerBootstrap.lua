local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerBootstrap = {}
local _started = false

local function hasStudioE2ERemote()
    local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteFolder then
        return false
    end

    local remote = remoteFolder:FindFirstChild("StudioE2EControl")
    return remote ~= nil and ReplicatedStorage:GetAttribute("PasrahStudioE2EReady") == true
end

local function hasStudioRuntimeSystemReady(attributeName)
    return type(attributeName) == "string"
        and attributeName ~= ""
        and ReplicatedStorage:GetAttribute(attributeName) == true
end

local function ensureStudioRuntimeSystem(systemRegistry, systemName, readyAttributeName)
    if not RunService:IsStudio() or hasStudioRuntimeSystemReady(readyAttributeName) then
        return
    end

    local existingSystem = nil
    if type(systemRegistry) == "table" and type(systemRegistry.Get) == "function" then
        local ok, result = pcall(function()
            return systemRegistry:Get(systemName)
        end)
        if ok then
            existingSystem = result
        end
    end

    if type(existingSystem) == "table" and type(existingSystem.Start) == "function" then
        existingSystem:Start()
        if hasStudioRuntimeSystemReady(readyAttributeName) then
            print(string.format("[Bootstrap] %s restarted from registry", systemName))
            return
        end
    end

    local serverRoot = ServerScriptService:WaitForChild("Server")
    local systemContainer = serverRoot:FindFirstChild(systemName)
    local systemModule = systemContainer and systemContainer:FindFirstChild("Main")
    if not (systemModule and systemModule:IsA("ModuleScript")) then
        warn(string.format("[Bootstrap] %s fallback skipped: missing module", systemName))
        return
    end

    local moduleValue = require(systemModule)
    local instance = moduleValue
    if type(moduleValue) == "table" and type(moduleValue.new) == "function" then
        instance = moduleValue.new({
            Services = systemRegistry,
            ServiceRegistry = systemRegistry,
        })
    end

    if type(instance) ~= "table" then
        warn(string.format("[Bootstrap] %s fallback failed: invalid instance", systemName))
        return
    end

    if type(instance.Init) == "function" then
        instance:Init()
    end
    if type(instance.Start) == "function" then
        instance:Start()
    end

    if type(systemRegistry) == "table"
        and type(systemRegistry.Has) == "function"
        and type(systemRegistry.RegisterService) == "function"
        and not systemRegistry:Has(systemName)
    then
        systemRegistry:RegisterService(systemName, instance)
    end

    if hasStudioRuntimeSystemReady(readyAttributeName) then
        print(string.format("[Bootstrap] %s started via Studio fallback", systemName))
    else
        warn(string.format("[Bootstrap] %s fallback did not expose readiness", systemName))
    end
end

local function ensureEvidenceGatewayBinding(systemRegistry)
    if not RunService:IsStudio() then
        return
    end

    local evidenceSystem = nil
    if type(systemRegistry) == "table" and type(systemRegistry.Get) == "function" then
        local ok, result = pcall(function()
            return systemRegistry:Get("EvidenceSystem")
        end)
        if ok then
            evidenceSystem = result
        end
    end

    if type(evidenceSystem) ~= "table" then
        warn("[Bootstrap] Evidence gateway verify skipped: missing EvidenceSystem")
        return
    end

    local controller = evidenceSystem.Controller
    if type(controller) ~= "table" then
        warn("[Bootstrap] Evidence gateway verify skipped: missing controller")
        return
    end

    if controller._handlersRegistered ~= true and type(controller.RegisterEventHandlers) == "function" then
        controller:RegisterEventHandlers()
    end

    local gateway = controller._gateway
    if type(gateway) == "table" and type(gateway._bindRemoteFunction) == "function" then
        gateway:_bindRemoteFunction()
    end

    local ready = ReplicatedStorage:GetAttribute("PasrahEvidenceGatewayReady") == true
    ReplicatedStorage:SetAttribute("PasrahEvidenceBootstrapVerified", ready)
    if ready then
        print("[Bootstrap] Evidence gateway binding verified")
    else
        warn("[Bootstrap] Evidence gateway binding verify failed")
    end
end

local function ensureStudioE2EControl(systemRegistry)
    if not RunService:IsStudio() then
        return
    end
    if hasStudioE2ERemote() then
        return
    end

    local existingSystem = nil
    if type(systemRegistry) == "table" and type(systemRegistry.Get) == "function" then
        local ok, result = pcall(function()
            return systemRegistry:Get("StudioE2EControlSystem")
        end)
        if ok then
            existingSystem = result
        end
    end

    if type(existingSystem) == "table" and type(existingSystem.Start) == "function" then
        existingSystem:Start()
        if hasStudioE2ERemote() then
            print("[Bootstrap] StudioE2EControlSystem restarted from registry")
            return
        end
    end

    local serverRoot = ServerScriptService:WaitForChild("Server")
    local systemContainer = serverRoot:FindFirstChild("StudioE2EControlSystem")
    local systemModule = systemContainer and systemContainer:FindFirstChild("Main")
    if not (systemModule and systemModule:IsA("ModuleScript")) then
        warn("[Bootstrap] StudioE2EControlSystem fallback skipped: missing module")
        return
    end

    local moduleValue = require(systemModule)
    local instance = moduleValue
    if type(moduleValue) == "table" and type(moduleValue.new) == "function" then
        instance = moduleValue.new({
            Services = systemRegistry,
            ServiceRegistry = systemRegistry,
        })
    end

    if type(instance) ~= "table" then
        warn("[Bootstrap] StudioE2EControlSystem fallback failed: invalid instance")
        return
    end

    if type(instance.Init) == "function" then
        instance:Init()
    end
    if type(instance.Start) == "function" then
        instance:Start()
    end

    if type(systemRegistry) == "table"
        and type(systemRegistry.Has) == "function"
        and type(systemRegistry.RegisterService) == "function"
        and not systemRegistry:Has("StudioE2EControlSystem")
    then
        systemRegistry:RegisterService("StudioE2EControlSystem", instance)
    end

    if hasStudioE2ERemote() then
        print("[Bootstrap] StudioE2EControlSystem started via Studio fallback")
    else
        warn("[Bootstrap] StudioE2EControlSystem fallback did not expose remote")
    end
end

function ServerBootstrap.Start()
    if _started then
        return
    end

    local ok, err = pcall(function()
        print("=== PASRAHPHOBIA SERVER BOOT START ===")

        local ServerRoot = ServerScriptService:WaitForChild("Server")
        local Core = ServerRoot:WaitForChild("Core")

        local SystemRegistry = require(Core:WaitForChild("SystemRegistry"))
        local Diagnostics = require(Core:WaitForChild("SystemDiagnostics"))
        local AudioErrorGuard = require(Core:WaitForChild("AudioErrorGuard"))
        local AudioSanitizer = require(Core:WaitForChild("AudioSanitizer"))

        AudioSanitizer.Scan()
        SystemRegistry:Start()
        ensureStudioRuntimeSystem(SystemRegistry, "HidingSystem", "PasrahHidingReady")
        ensureStudioRuntimeSystem(SystemRegistry, "PlayerHealthSystem", "PasrahHuntPressureReady")
        ensureStudioRuntimeSystem(SystemRegistry, "EvidenceSystem", "PasrahEvidenceGatewayReady")
        ensureEvidenceGatewayBinding(SystemRegistry)
        ensureStudioE2EControl(SystemRegistry)
        _G.SystemRegistry = SystemRegistry
        print("[Bootstrap] _G.SystemRegistry exposed")
        AudioErrorGuard.Scan()
        Diagnostics.PrintReport()

        print("=== PASRAHPHOBIA SERVER BOOT COMPLETE ===")
    end)

    if not ok then
        _started = false
        warn("[Bootstrap] Server boot failed, startup guard reset:", tostring(err))
        error(err)
    end

    _started = true
end

return ServerBootstrap


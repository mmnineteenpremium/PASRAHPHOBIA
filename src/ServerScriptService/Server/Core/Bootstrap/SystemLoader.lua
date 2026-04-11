-- SystemLoader.lua
-- PASRAHPHOBIA server bootstrap helper
-- Load order follows the canonical 7-tier dependency model

local ServerScriptService = game:GetService("ServerScriptService")

local ServiceRegistry = require(script.Parent.Parent.ServiceRegistry)

local SystemLoader = {}

local LOAD_ORDER = {
    -- Tier 1: Core infrastructure
    { tier = 1, name = "EventBus", path = "Server.Core.EventBus" },
    { tier = 1, name = "ServiceRegistry", path = "Server.Core.ServiceRegistry" },
    { tier = 1, name = "SecurityValidator", path = "Server.Core.SecurityValidator" },

    -- Tier 2: Persistence
    { tier = 2, name = "DataPersistenceService", path = "Server.DataPersistenceService.Service" },

    -- Tier 3: Player systems
    { tier = 3, name = "ProfileSystem", path = "Server.ProfileSystem.Service" },
    { tier = 3, name = "ProgressionSystem", path = "Server.ProgressionSystem.Service" },
    { tier = 3, name = "RankedSystem", path = "Server.RankedSystem.Service" },

    -- Tier 4: Lobby systems
    { tier = 4, name = "LobbySocialHub", path = "Server.LobbySocialHub.Service" },
    { tier = 4, name = "PartySystem", path = "Server.PartySystem.Service" },
    { tier = 4, name = "ContractSystem", path = "Server.ContractSystem.Service" },

    -- Tier 5: Match systems
    { tier = 5, name = "MatchQueue", path = "Server.MatchSystem.MatchQueue" },
    { tier = 5, name = "MatchBuilder", path = "Server.MatchSystem.MatchBuilder" },
    { tier = 5, name = "MatchInstance", path = "Server.MatchSystem.MatchInstance" },
    { tier = 5, name = "MatchLifecycle", path = "Server.MatchSystem.MatchLifecycle" },
    { tier = 5, name = "GamePhaseSystem", path = "Server.GamePhaseSystem.Service" },

    -- Tier 6: Gameplay systems
    { tier = 6, name = "GhostSystem", path = "Server.GhostSystem.Service" },
    { tier = 6, name = "EvidenceSystem", path = "Server.EvidenceSystem.Service" },
    { tier = 6, name = "SanitySystem", path = "Server.SanitySystem.Service" },
    { tier = 6, name = "AggressionSystem", path = "Server.AggressionSystem.Service" },
    { tier = 6, name = "InvestigationSystem", path = "Server.InvestigationSystem.Service" },

    -- Tier 7: Advanced systems
    { tier = 7, name = "HorrorDirector", path = "Server.HorrorDirector.Service" },
    { tier = 7, name = "GhostModifierSystem", path = "Server.GhostModifierSystem.Service" },
    { tier = 7, name = "MapInteractionSystem", path = "Server.MapInteractionSystem.Service" },
    { tier = 7, name = "MapEventSystem", path = "Server.MapEventSystem.Service" },
}

local function splitPath(path)
    local segments = {}
    for segment in string.gmatch(path or "", "[^%.]+") do
        table.insert(segments, segment)
    end
    return segments
end

local function resolveBySegments(root, segments)
    local current = root
    for _, segment in ipairs(segments) do
        if typeof(current) ~= "Instance" then
            return nil
        end
        current = current:FindFirstChild(segment)
        if not current then
            return nil
        end
    end
    return current
end

local function resolveMainModule(container)
    if typeof(container) ~= "Instance" then
        return nil
    end
    if container:IsA("ModuleScript") then
        return container
    end
    if container:IsA("Folder") then
        local mainModule = container:FindFirstChild("Main")
        if mainModule and mainModule:IsA("ModuleScript") then
            return mainModule
        end
    end
    return nil
end

local function resolveModuleForEntry(serverRoot, entry)
    local segments = splitPath(entry.path)
    if segments[1] == "Server" then
        table.remove(segments, 1)
    end

    local resolved = resolveBySegments(serverRoot, segments)
    if resolved and resolved:IsA("ModuleScript") then
        local parent = resolved.Parent
        if segments[#segments] == "Service" and parent and parent.Name == entry.name then
            local mainModule = parent:FindFirstChild("Main")
            if mainModule and mainModule:IsA("ModuleScript") then
                return mainModule
            end
        end
        return resolved
    end

    local mainModule = resolveMainModule(resolved)
    if mainModule then
        return mainModule
    end

    local fallback = serverRoot:FindFirstChild(entry.name, true)
    return resolveMainModule(fallback)
end

local function buildDeps()
    local eventBus = nil
    if ServiceRegistry:Has("EventBus") then
        eventBus = ServiceRegistry:SafeGet("EventBus")
    end

    return {
        Services = ServiceRegistry,
        ServiceRegistry = ServiceRegistry,
        EventBus = eventBus,
    }
end

local function instantiateIfNeeded(moduleValue)
    if type(moduleValue) ~= "table" or type(moduleValue.new) ~= "function" then
        return moduleValue, nil, false
    end

    -- Only instantiate modules that expose a lifecycle contract.
    if type(moduleValue.Init) ~= "function"
        and type(moduleValue.Stop) ~= "function"
        and type(moduleValue.Shutdown) ~= "function"
    then
        return moduleValue, nil, false
    end

    local ok, instance = pcall(moduleValue.new, buildDeps())
    if not ok then
        return nil, instance, false
    end

    return instance, nil, true
end

local function registerLoadedModule(name, moduleValue)
    if ServiceRegistry:Has(name) then
        return false, "already_registered"
    end

    local ok, err = pcall(function()
        ServiceRegistry:Register(name, moduleValue)
    end)
    if not ok then
        return false, tostring(err)
    end

    return true
end

function SystemLoader:GetLoadOrder()
    return LOAD_ORDER
end

function SystemLoader:LoadAll()
    local serverRoot = ServerScriptService:WaitForChild("Server")
    local loaded = {}
    local failed = {}
    local currentTier = 0

    print("=== [SystemLoader] PASRAHPHOBIA Server Bootstrap START ===")

    for _, entry in ipairs(LOAD_ORDER) do
        if entry.tier ~= currentTier then
            currentTier = entry.tier
            print("")
            print(string.format("--- Tier %d ---", currentTier))
        end

        local moduleScript = resolveModuleForEntry(serverRoot, entry)
        if not moduleScript then
            warn(string.format("  [SystemLoader] Missing module for %s (%s)", entry.name, entry.path))
            table.insert(failed, entry.name)
            continue
        end

        local requireOk, moduleValue = pcall(require, moduleScript)
        if not requireOk then
            warn(string.format("  [SystemLoader] Failed requiring %s: %s", entry.name, tostring(moduleValue)))
            table.insert(failed, entry.name)
            continue
        end

        local instance, instantiateErr, instantiated = instantiateIfNeeded(moduleValue)
        if not instance then
            warn(string.format("  [SystemLoader] Failed instantiating %s: %s", entry.name, tostring(instantiateErr)))
            table.insert(failed, entry.name)
            continue
        end

        loaded[entry.name] = instance

        local registered, registerErr = registerLoadedModule(entry.name, instance)
        if not registered and registerErr ~= "already_registered" then
            warn(string.format("  [SystemLoader] Failed registering %s: %s", entry.name, tostring(registerErr)))
        end

        if type(instance) == "table" and type(instance.Init) == "function" then
            local initOk, initErr = pcall(function()
                instance:Init()
            end)
            if not initOk then
                warn(string.format("  [SystemLoader] %s.Init() failed: %s", entry.name, tostring(initErr)))
            end
        end

        if instantiated then
            print(string.format("  [OK] %s (instantiated)", entry.name))
        else
            print(string.format("  [OK] %s", entry.name))
        end
    end

    print("")
    print("=== [SystemLoader] Bootstrap COMPLETE ===")
    print(string.format("  Loaded: %d | Failed: %d", #LOAD_ORDER - #failed, #failed))

    if #failed > 0 then
        warn("[SystemLoader] Failed systems: " .. table.concat(failed, ", "))
    end

    return loaded, failed
end

return SystemLoader

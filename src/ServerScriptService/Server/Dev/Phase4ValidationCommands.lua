local DevCommands = {}

local Services = require(game.ServerScriptService.Server.Core.Services)

local function getSystem(name)
    local system = Services.Get(name)
    if not system then
        error(name .. " not registered")
    end
    return system
end

local function callFirst(target, methods, ...)
    if type(target) ~= "table" then
        return false
    end
    for _, method in ipairs(methods) do
        local fn = target[method]
        if type(fn) == "function" then
            fn(target, ...)
            return true
        end
    end
    return false
end

local function callSystem(system, methods, ...)
    if callFirst(system, methods, ...) then
        return true
    end
    if callFirst(system.Service, methods, ...) then
        return true
    end
    if callFirst(system.Controller, methods, ...) then
        return true
    end
    return false
end

function DevCommands.ghost_test()
    local system = getSystem("GhostSystem")
    local ok = callSystem(system, {
        "DevTest",
        "TestBehavior",
        "TriggerBehaviorPipeline",
        "RunBehaviorPipeline",
        "StartBehaviorPipeline",
    })
    if not ok then
        warn("[DEV] GhostSystem test hook not found")
    end
    print("[DEV] Ghost behavior test triggered")
end

function DevCommands.evidence_test()
    local system = getSystem("EvidenceSystem")
    local ok = callSystem(system, {
        "DevTest",
        "TestEvidence",
        "SpawnEvidenceEngine",
        "StartEvidenceEngine",
        "TriggerEvidenceEngine",
    })
    if not ok then
        warn("[DEV] EvidenceSystem test hook not found")
    end
    print("[DEV] Evidence test triggered")
end

function DevCommands.hunt_test()
    local system = getSystem("HuntSystem")
    local ok = callSystem(system, {
        "DevTest",
        "ForceHunt",
        "StartHunt",
        "BeginHunt",
        "TriggerHunt",
        "ForceStartHuntPhase",
    })
    if not ok then
        warn("[DEV] HuntSystem test hook not found")
    end
    print("[DEV] Hunt test triggered")
end

function DevCommands.sanity_test()
    local system = getSystem("SanitySystem")
    local ok = callSystem(system, {
        "DevTest",
        "DrainSanity",
        "ApplySanityDrain",
        "TestSanityDrain",
    })
    if not ok then
        warn("[DEV] SanitySystem test hook not found")
    end
    print("[DEV] Sanity test triggered")
end

return DevCommands

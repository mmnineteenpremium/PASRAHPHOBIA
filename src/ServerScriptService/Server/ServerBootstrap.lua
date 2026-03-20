local ServerBootstrap = {}
local _started = false

function ServerBootstrap.Start()
    if _started then
        return
    end
    _started = true

    print("=== PASRAHPHOBIA SERVER BOOT START ===")

    local ServerScriptService = game:GetService("ServerScriptService")
    local ServerRoot = ServerScriptService:WaitForChild("Server")
    local Core = ServerRoot:WaitForChild("Core")

    local SystemRegistry = require(Core:WaitForChild("SystemRegistry"))
    local Diagnostics = require(Core:WaitForChild("SystemDiagnostics"))
    local AudioErrorGuard = require(Core:WaitForChild("AudioErrorGuard"))
    local AudioSanitizer = require(Core:WaitForChild("AudioSanitizer"))

    AudioSanitizer.Scan()
    SystemRegistry:Start()
    _G.SystemRegistry = SystemRegistry
    print("[Bootstrap] _G.SystemRegistry exposed")
    local spectatorSystem = SystemRegistry:Get("SpectatorSystem")

    if spectatorSystem and spectatorSystem.Service then
        spectatorSystem.Service:Start()
    end
    
    local EventBus = SystemRegistry:Get("EventBus")
    local deathSystem = SystemRegistry:Get("DeathStateSystem")
    local DeathEventBridge = require(ServerScriptService.Server.DeathStateSystem.DeathEventBridge)
    DeathEventBridge.Start(deathSystem.Service)
    AudioErrorGuard.Scan()
    Diagnostics.PrintReport()

    print("=== PASRAHPHOBIA SERVER BOOT COMPLETE ===")
end

return ServerBootstrap


local ServerBootstrap = {}
local _started = false

function ServerBootstrap.Start()
    if _started then
        return
    end

    local ok, err = pcall(function()
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


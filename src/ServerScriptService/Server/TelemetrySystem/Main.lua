local TelemetrySystem = {}
TelemetrySystem.__index = TelemetrySystem

local Service = require(script.Parent.Service)

function TelemetrySystem.new()
    return setmetatable({ Service = Service }, TelemetrySystem)
end

function TelemetrySystem:Init()
    print("[TelemetrySystem] Init")
end

function TelemetrySystem:Start()
    print("[TelemetrySystem] Start")
end

function TelemetrySystem:Shutdown()
    print("[TelemetrySystem] Shutdown")
end

return TelemetrySystem

local TelemetrySystem = {}
TelemetrySystem.__index = TelemetrySystem

local Service = require(script.Service)

function TelemetrySystem:Init()
    self.Service = Service
    print("[TelemetrySystem] Init")
end

function TelemetrySystem:Start()
    print("[TelemetrySystem] Start")
end

function TelemetrySystem:Shutdown()
    print("[TelemetrySystem] Shutdown")
end

return TelemetrySystem

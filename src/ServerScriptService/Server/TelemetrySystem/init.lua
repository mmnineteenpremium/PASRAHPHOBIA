local TelemetrySystem = {}
TelemetrySystem.__index = TelemetrySystem

local Service = require(script.Service)

function TelemetrySystem:Init()
    self.Service = Service
end

function TelemetrySystem:Start()
end

function TelemetrySystem:Shutdown()
end

return TelemetrySystem

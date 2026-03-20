local HttpService = game:GetService("HttpService")

local TelemetrySystem = {}

function TelemetrySystem:Init()
end

function TelemetrySystem:Start()
end

function TelemetrySystem:Shutdown()
end

function TelemetrySystem.LogEvent(category, data)
    local entry = {
        timestamp = os.time(),
        category = category,
        data = data,
    }
    print("[TELEMETRY]", HttpService:JSONEncode(entry))
end

return TelemetrySystem

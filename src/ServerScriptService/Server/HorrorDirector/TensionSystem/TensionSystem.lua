local TensionSystem = {}
TensionSystem.__index = TensionSystem

function TensionSystem.new(config)
    local self = setmetatable({}, TensionSystem)
    self._config = config or {
        min = 0,
        max = 100,
    }
    return self
end

function TensionSystem:Clamp(value)
    local minValue = self._config.min or 0
    local maxValue = self._config.max or 100
    local n = tonumber(value) or 0
    if n < minValue then
        return minValue
    end
    if n > maxValue then
        return maxValue
    end
    return n
end

function TensionSystem:ApplyDelta(current, delta)
    return self:Clamp((tonumber(current) or 0) + (tonumber(delta) or 0))
end

return TensionSystem

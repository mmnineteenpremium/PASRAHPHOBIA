local DirectorRules = {}
DirectorRules.__index = DirectorRules

local DEFAULT_RULES = {
    low = {
        minTension = 0,
        maxTension = 25,
        events = { "EnvironmentalEvent" },
    },
    medium = {
        minTension = 26,
        maxTension = 65,
        events = { "EnvironmentalEvent", "GhostEventTriggered" },
    },
    high = {
        minTension = 66,
        maxTension = 100,
        events = { "GhostEventTriggered", "HuntTriggered" },
    },
}

function DirectorRules.new(config)
    local self = setmetatable({}, DirectorRules)
    self._rules = config or DEFAULT_RULES
    return self
end

function DirectorRules:GetRules()
    return self._rules
end

function DirectorRules:ResolveTier(tension)
    local value = math.floor(tonumber(tension) or 0)
    if value >= self._rules.high.minTension then
        return "high"
    end
    if value >= self._rules.medium.minTension then
        return "medium"
    end
    return "low"
end

return DirectorRules

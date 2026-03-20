local EventScheduler = {}
EventScheduler.__index = EventScheduler

function EventScheduler.new(rng)
    local self = setmetatable({}, EventScheduler)
    self._rng = rng or Random.new()
    return self
end

function EventScheduler:BuildEventQueue(matchId, tier, now)
    local queue = {
        matchId = matchId,
        createdAt = now or os.clock(),
        tier = tier or "low",
        events = {},
    }

    if queue.tier == "low" then
        table.insert(queue.events, "EnvironmentalEvent")
    elseif queue.tier == "medium" then
        table.insert(queue.events, "EnvironmentalEvent")
        table.insert(queue.events, "GhostEventTriggered")
    else
        table.insert(queue.events, "GhostEventTriggered")
        table.insert(queue.events, "HuntTriggered")
    end

    return queue
end

return EventScheduler

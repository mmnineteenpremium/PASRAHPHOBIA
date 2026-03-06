local Behavior = {}

Behavior.Name = "AmbushBehavior"

function Behavior.Score(context)
    if context.huntActive then
        return 0
    end
    local fear = context.fearLevel or 0
    local sanity = context.averageSanity or 100
    local aggression = context.aggression or 0
    if fear < 45 or aggression < 30 then
        return 0
    end
    return (fear * 0.4) + ((100 - sanity) * 0.3) + (aggression * 0.25)
end

function Behavior.BuildActions(context, now)
    return {
        {
            type = "force_manifest",
            payload = {
                matchId = context.matchId,
                reason = "ghost_director_ambush",
                duration = 7,
                now = now,
            },
        },
        {
            type = "increase_aggression",
            payload = {
                matchId = context.matchId,
                amount = 1.2,
                reason = "ghost_director_ambush",
            },
        },
    }
end

return Behavior

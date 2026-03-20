local Behavior = {}

Behavior.Name = "HuntBehavior"

function Behavior.Score(context)
    if context.huntActive then
        return 0
    end
    local fear = context.fearLevel or 0
    local sanity = context.averageSanity or 100
    local aggression = context.aggression or 0
    local tension = context.tension or 0

    if aggression < 70 and fear < 60 and sanity > 35 then
        return 0
    end

    return (aggression * 0.55) + (fear * 0.35) + ((100 - sanity) * 0.35) + (tension * 0.2)
end

function Behavior.BuildActions(context, now)
    return {
        {
            type = "force_hunt",
            payload = {
                matchId = context.matchId,
                reason = "ghost_director_hunt",
                now = now,
            },
        },
        {
            type = "increase_aggression",
            payload = {
                matchId = context.matchId,
                amount = 1.5,
                reason = "ghost_director_hunt_commit",
            },
        },
    }
end

return Behavior

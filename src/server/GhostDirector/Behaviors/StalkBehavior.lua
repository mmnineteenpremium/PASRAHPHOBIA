local Behavior = {}

Behavior.Name = "StalkBehavior"

function Behavior.Score(context)
    if context.huntActive then
        return 0
    end
    local fear = context.fearLevel or 0
    local sanity = context.averageSanity or 100
    local tension = context.tension or 0
    if fear < 25 or sanity > 70 then
        return 0
    end
    return (fear * 0.35) + ((100 - sanity) * 0.25) + (tension * 0.2)
end

function Behavior.BuildActions(context, now)
    return {
        {
            type = "force_roam",
            payload = {
                matchId = context.matchId,
                reason = "ghost_director_stalk",
                duration = 6,
                now = now,
            },
        },
    }
end

return Behavior

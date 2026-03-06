local Behavior = {}

Behavior.Name = "ManifestBehavior"

function Behavior.Score(context)
    if context.huntActive then
        return 0
    end
    local tension = context.tension or 0
    local fear = context.fearLevel or 0
    if tension < 40 and fear < 35 then
        return 0
    end
    return (tension * 0.45) + (fear * 0.2) + ((100 - (context.averageSanity or 100)) * 0.2)
end

function Behavior.BuildActions(context, now)
    return {
        {
            type = "force_manifest",
            payload = {
                matchId = context.matchId,
                reason = "ghost_director_manifest",
                duration = 8,
                now = now,
            },
        },
    }
end

return Behavior

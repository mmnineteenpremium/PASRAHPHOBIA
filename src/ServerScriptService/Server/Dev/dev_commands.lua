local Dev = {}

local Players = game:GetService("Players")

local Services = require(
    game.ServerScriptService.Server.Core.Services
)

function Dev.Match(mode)
    print("[DEV] forcing match creation")

    local MatchService = Services.Get("MatchService")

    if not MatchService then
        error("MatchService not registered")
    end

    for _, player in pairs(Players:GetPlayers()) do
        MatchService:JoinQueue(player, {
            mode = mode or "Classic",
        })
    end

    local match, reason = MatchService:TryCreateMatchFromQueue()

    print("[DEV] match result", match, reason)
end

return Dev

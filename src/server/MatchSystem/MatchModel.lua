local MatchModel = {}

function MatchModel.ToPayload(match)

    return {
        id = match.id,
        map = match.map,
        players = match.players,
        ghostType = match.ghostType,
        contractId = match.contractId,
        state = match.state
    }

end

return MatchModel

local Match = {}
Match.__index = Match

function Match.new(data)
    local self = setmetatable({}, Match)

    self.id = data.id
    self.map = data.map
    self.players = data.players or {}
    self.ghostType = data.ghostType
    self.contractId = data.contractId
    self.state = "Created"

    return self
end

function Match:SetState(state)
    self.state = state
end

function Match:GetState()
    return self.state
end

return Match

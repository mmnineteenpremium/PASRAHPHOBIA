local Board = {}
Board.__index = Board

function Board.new()
    local self = setmetatable({}, Board)
    return self
end

function Board:Replace(contractIds)
    local out = {}
    for _, contractId in ipairs(contractIds or {}) do
        table.insert(out, contractId)
    end
    return out
end

return Board

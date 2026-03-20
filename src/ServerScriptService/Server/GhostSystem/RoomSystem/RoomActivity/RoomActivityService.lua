local RoomActivityService = {}
RoomActivityService.__index = RoomActivityService

function RoomActivityService.new()
    local self = setmetatable({}, RoomActivityService)
    return self
end

function RoomActivityService:Record(matchId, payload)
    return {
        matchId = matchId,
        payload = payload,
    }
end

return RoomActivityService

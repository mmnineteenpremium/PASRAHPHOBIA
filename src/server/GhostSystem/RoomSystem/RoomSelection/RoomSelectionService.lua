local RoomSelectionService = {}
RoomSelectionService.__index = RoomSelectionService

function RoomSelectionService.new()
    local self = setmetatable({}, RoomSelectionService)
    return self
end

function RoomSelectionService:SelectNearby(roomIds, favoriteRoomId)
    local nearby = {}
    for _, roomId in ipairs(roomIds or {}) do
        if roomId ~= favoriteRoomId then
            table.insert(nearby, roomId)
        end
    end
    return nearby
end

return RoomSelectionService

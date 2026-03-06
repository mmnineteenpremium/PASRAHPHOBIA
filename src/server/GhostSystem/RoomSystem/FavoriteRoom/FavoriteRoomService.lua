local FavoriteRoomService = {}
FavoriteRoomService.__index = FavoriteRoomService

function FavoriteRoomService.new()
    local self = setmetatable({}, FavoriteRoomService)
    return self
end

function FavoriteRoomService:Select(roomIds)
    if type(roomIds) ~= "table" or #roomIds == 0 then
        return nil
    end
    return roomIds[1]
end

return FavoriteRoomService

local RoomRoamingService = {}
RoomRoamingService.__index = RoomRoamingService

function RoomRoamingService.new()
    local self = setmetatable({}, RoomRoamingService)
    return self
end

function RoomRoamingService:GetNext(currentRoomId, roomIds)
    if type(roomIds) ~= "table" or #roomIds == 0 then
        return currentRoomId
    end

    if not currentRoomId then
        return roomIds[1]
    end

    for index, roomId in ipairs(roomIds) do
        if roomId == currentRoomId then
            local nextIndex = (index % #roomIds) + 1
            return roomIds[nextIndex]
        end
    end

    return roomIds[1]
end

return RoomRoamingService

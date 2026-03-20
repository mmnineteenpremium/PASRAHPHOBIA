local FavoriteRoomService = require(script.Parent.FavoriteRoom)
local RoomActivityService = require(script.Parent.RoomActivity)
local RoomRoamingService = require(script.Parent.RoomRoaming)
local RoomSelectionService = require(script.Parent.RoomSelection)

local RoomSystem = {}
RoomSystem.__index = RoomSystem

function RoomSystem.new()
    local self = setmetatable({}, RoomSystem)
    self.favoriteRoom = FavoriteRoomService.new()
    self.activity = RoomActivityService.new()
    self.roaming = RoomRoamingService.new()
    self.selection = RoomSelectionService.new()
    return self
end

return RoomSystem

local Layout = {}

local function v3(x, y, z)
	return Vector3.new(x, y, z)
end

Layout.mapId = "StudioMMNineteen"

Layout.rooms = {
	{ roomId = "FrontPorch", floor = 1, center = v3(-13.3, 9.6, -16.4), size = v3(12, 8, 10) },
	{ roomId = "LivingRoom", floor = 1, center = v3(14.0, 11.2, -4.8), size = v3(21, 12, 28) },
	{ roomId = "LaundryRoom", floor = 1, center = v3(-13.9, 10.6, 3.7), size = v3(26, 11, 13) },
	{ roomId = "StairHallL1", floor = 1, center = v3(-1.5, 10.8, -6.0), size = v3(12, 10, 10) },
	{ roomId = "Kitchen", floor = 2, center = v3(21.5, 22.2, -17.2), size = v3(19, 8, 14) },
	{ roomId = "DiningArea", floor = 2, center = v3(17.2, 20.5, 3.0), size = v3(9, 5, 13) },
	{ roomId = "Bathroom", floor = 2, center = v3(-6.3, 22.9, 5.2), size = v3(27, 9, 23) },
	{ roomId = "StairHallL2", floor = 2, center = v3(1.2, 22.3, -5.8), size = v3(10, 9, 10) },
	{ roomId = "UpperHall", floor = 3, center = v3(3.3, 33.4, -17.6), size = v3(12, 8, 10) },
	{ roomId = "Bedroom1", floor = 3, center = v3(5.8, 34.0, -28.9), size = v3(24, 11, 26) },
	{ roomId = "Bedroom2", floor = 3, center = v3(25.7, 34.8, -13.1), size = v3(27, 12, 21) },
	{ roomId = "StairHallL3", floor = 3, center = v3(18.5, 33.4, -13.3), size = v3(10, 8, 10) },
}

Layout.spawnPoints = {
	{ name = "PlayerSpawn_1", position = v3(-20.8, 10.2, -22.8) },
	{ name = "PlayerSpawn_2", position = v3(-18.4, 10.2, -24.1) },
	{ name = "PlayerSpawn_3", position = v3(-16.0, 10.2, -25.3) },
	{ name = "PlayerSpawn_4", position = v3(-13.6, 10.2, -26.5) },
}

Layout.safeZones = {
	{ name = "SafeZone_1", position = v3(-19.0, 10.2, -20.5) },
	{ name = "SafeZone_2", position = v3(-15.8, 10.2, -22.3) },
}

Layout.ghostSpawns = {
	{ name = "GhostSpawnZone_1", roomId = "LivingRoom", position = v3(2.4, 10.4, -3.6) },
	{ name = "GhostSpawnZone_2", roomId = "LaundryRoom", position = v3(-11.4, 7.3, 16.9) },
	{ name = "GhostSpawnZone_3", roomId = "Kitchen", position = v3(22.7, 21.9, -17.6) },
	{ name = "GhostSpawnZone_4", roomId = "Bathroom", position = v3(-6.9, 22.6, 6.1) },
	{ name = "GhostSpawnZone_5", roomId = "Bedroom1", position = v3(6.0, 34.4, -30.0) },
	{ name = "GhostSpawnZone_6", roomId = "Bedroom2", position = v3(27.1, 35.2, -13.5) },
}

Layout.evidenceNodes = {
	{ name = "EvidenceNode_1", roomId = "FrontPorch", position = v3(-13.4, 9.8, -16.5) },
	{ name = "EvidenceNode_2", roomId = "LivingRoom", position = v3(14.6, 10.3, -4.4) },
	{ name = "EvidenceNode_3", roomId = "LaundryRoom", position = v3(-14.9, 9.6, 4.6) },
	{ name = "EvidenceNode_4", roomId = "StairHallL1", position = v3(-1.0, 10.9, -7.0) },
	{ name = "EvidenceNode_5", roomId = "Kitchen", position = v3(22.7, 21.9, -17.6) },
	{ name = "EvidenceNode_6", roomId = "DiningArea", position = v3(18.0, 20.0, 3.8) },
	{ name = "EvidenceNode_7", roomId = "Bathroom", position = v3(-6.9, 22.6, 6.1) },
	{ name = "EvidenceNode_8", roomId = "StairHallL2", position = v3(1.2, 22.3, -5.8) },
	{ name = "EvidenceNode_9", roomId = "UpperHall", position = v3(3.4, 33.4, -17.6) },
	{ name = "EvidenceNode_10", roomId = "Bedroom1", position = v3(5.6, 34.7, -25.5) },
	{ name = "EvidenceNode_11", roomId = "Bedroom2", position = v3(25.7, 35.2, -13.5) },
	{ name = "EvidenceNode_12", roomId = "StairHallL3", position = v3(18.5, 33.4, -13.3) },
}

Layout.doors = {
	{ objectId = "Door_FrontEntry", label = "Pintu Depan", roomId = "FrontPorch", proxyPosition = v3(-13.3, 9.6, -16.4), mode = "Swing", advanceFromPreparation = true },
	{ objectId = "Door_LivingRoom", label = "Pintu Living Room", roomId = "LivingRoom", proxyPosition = v3(2.2, 10.2, -7.4), mode = "Swing" },
	{ objectId = "Door_LaundryRoom", label = "Pintu Laundry", roomId = "LaundryRoom", proxyPosition = v3(-10.8, 9.9, -0.2), mode = "Swing" },
	{ objectId = "Door_StairToMid", label = "Pintu Lantai Tengah", roomId = "StairHallL2", proxyPosition = v3(1.2, 22.3, -5.8), mode = "Swing" },
	{ objectId = "Door_Kitchen", label = "Pintu Kitchen", roomId = "Kitchen", proxyPosition = v3(15.2, 21.8, -10.8), mode = "Swing" },
	{ objectId = "Door_DiningArea", label = "Pintu Dining", roomId = "DiningArea", proxyPosition = v3(16.9, 20.3, -2.4), mode = "Swing" },
	{ objectId = "Door_Bathroom", label = "Pintu Bathroom", roomId = "Bathroom", proxyPosition = v3(-7.0, 22.4, 8.2), mode = "Swing" },
	{ objectId = "Door_UpperHall", label = "Pintu Hall Atas", roomId = "UpperHall", proxyPosition = v3(3.4, 33.4, -17.6), mode = "Swing" },
	{ objectId = "Door_Bedroom1", label = "Pintu Bedroom 1", roomId = "Bedroom1", proxyPosition = v3(6.0, 34.2, -23.8), mode = "Swing" },
	{ objectId = "Door_Bedroom2", label = "Pintu Bedroom 2", roomId = "Bedroom2", proxyPosition = v3(18.5, 33.4, -13.3), mode = "Swing" },
}

Layout.lights = {
	{ objectId = "Light_FrontPorch", roomId = "FrontPorch", proxyPosition = v3(-13.3, 13.6, -16.4), generated = { kind = "ceiling_light", position = v3(-13.3, 13.4, -16.4) } },
	{ objectId = "Light_LivingRoom", roomId = "LivingRoom", proxyPosition = v3(14.6, 15.1, -4.4), generated = { kind = "ceiling_light", position = v3(14.6, 14.9, -4.4) } },
	{ objectId = "Light_LaundryRoom", roomId = "LaundryRoom", proxyPosition = v3(-14.9, 14.0, 4.6), generated = { kind = "ceiling_light", position = v3(-14.9, 13.8, 4.6) } },
	{ objectId = "Light_StairHallL1", roomId = "StairHallL1", proxyPosition = v3(-1.5, 14.0, -6.0), generated = { kind = "ceiling_light", position = v3(-1.5, 13.8, -6.0) } },
	{ objectId = "Light_Kitchen", roomId = "Kitchen", proxyPosition = v3(22.7, 25.9, -17.6), generated = { kind = "ceiling_light", position = v3(22.7, 25.7, -17.6) } },
	{ objectId = "Light_DiningArea", roomId = "DiningArea", proxyPosition = v3(18.0, 24.0, 3.8), generated = { kind = "ceiling_light", position = v3(18.0, 23.8, 3.8) } },
	{ objectId = "Light_Bathroom", roomId = "Bathroom", proxyPosition = v3(-6.9, 26.5, 6.1), generated = { kind = "ceiling_light", position = v3(-6.9, 26.3, 6.1) } },
	{ objectId = "Light_StairHallL2", roomId = "StairHallL2", proxyPosition = v3(1.2, 26.2, -5.8), generated = { kind = "ceiling_light", position = v3(1.2, 26.0, -5.8) } },
	{ objectId = "Light_UpperHall", roomId = "UpperHall", proxyPosition = v3(3.4, 37.0, -17.6), generated = { kind = "ceiling_light", position = v3(3.4, 36.8, -17.6) } },
	{ objectId = "Light_Bedroom1", roomId = "Bedroom1", proxyPosition = v3(5.6, 39.2, -25.5), generated = { kind = "ceiling_light", position = v3(5.6, 39.0, -25.5) } },
	{ objectId = "Light_Bedroom2", roomId = "Bedroom2", proxyPosition = v3(25.7, 39.6, -13.5), generated = { kind = "ceiling_light", position = v3(25.7, 39.4, -13.5) } },
	{ objectId = "Light_StairHallL3", roomId = "StairHallL3", proxyPosition = v3(18.5, 37.3, -13.3), generated = { kind = "ceiling_light", position = v3(18.5, 37.1, -13.3) } },
}

Layout.props = {
	{ objectId = "Prop_FrontPorch", roomId = "FrontPorch", proxyPosition = v3(-12.2, 9.9, -17.4), generated = { kind = "prop_crate", position = v3(-12.2, 9.9, -17.4) } },
	{ objectId = "Prop_LivingRoom", roomId = "LivingRoom", proxyPosition = v3(12.0, 10.8, -2.6), generated = { kind = "prop_box", position = v3(12.0, 10.8, -2.6) } },
	{ objectId = "Prop_LaundryRoom", roomId = "LaundryRoom", proxyPosition = v3(-12.2, 9.2, 14.8), generated = { kind = "prop_crate", position = v3(-12.2, 9.2, 14.8) } },
	{ objectId = "Prop_StairHallL1", roomId = "StairHallL1", proxyPosition = v3(-2.2, 10.9, -4.6), generated = { kind = "prop_box", position = v3(-2.2, 10.9, -4.6) } },
	{ objectId = "Prop_Kitchen", roomId = "Kitchen", proxyPosition = v3(24.0, 21.6, -18.8), generated = { kind = "prop_box", position = v3(24.0, 21.6, -18.8) } },
	{ objectId = "Prop_DiningArea", roomId = "DiningArea", proxyPosition = v3(18.0, 20.2, 5.8), generated = { kind = "prop_box", position = v3(18.0, 20.2, 5.8) } },
	{ objectId = "Prop_Bathroom", roomId = "Bathroom", proxyPosition = v3(-10.0, 21.9, 15.8), generated = { kind = "prop_box", position = v3(-10.0, 21.9, 15.8) } },
	{ objectId = "Prop_StairHallL2", roomId = "StairHallL2", proxyPosition = v3(2.6, 22.1, -8.8), generated = { kind = "prop_box", position = v3(2.6, 22.1, -8.8) } },
	{ objectId = "Prop_UpperHall", roomId = "UpperHall", proxyPosition = v3(3.8, 33.7, -19.8), generated = { kind = "prop_box", position = v3(3.8, 33.7, -19.8) } },
	{ objectId = "Prop_Bedroom1", roomId = "Bedroom1", proxyPosition = v3(8.6, 34.5, -28.4), generated = { kind = "prop_box", position = v3(8.6, 34.5, -28.4) } },
	{ objectId = "Prop_Bedroom2", roomId = "Bedroom2", proxyPosition = v3(21.4, 34.7, -20.8), generated = { kind = "prop_box", position = v3(21.4, 34.7, -20.8) } },
	{ objectId = "Prop_StairHallL3", roomId = "StairHallL3", proxyPosition = v3(17.8, 33.8, -15.4), generated = { kind = "prop_box", position = v3(17.8, 33.8, -15.4) } },
}

Layout.electronics = {
	{ objectId = "TV_LivingRoom", roomId = "LivingRoom", proxyPosition = v3(2.4, 11.4, -4.0), generated = { kind = "tv", position = v3(2.4, 11.4, -4.0) } },
	{ objectId = "TV_Bedroom1", roomId = "Bedroom1", proxyPosition = v3(5.6, 34.8, -25.5), generated = { kind = "tv", position = v3(5.6, 34.8, -25.5) } },
	{ objectId = "Radio_Bedroom2", roomId = "Bedroom2", proxyPosition = v3(21.4, 39.2, -24.5), generated = { kind = "radio", position = v3(21.4, 39.2, -24.5) } },
	{ objectId = "Radio_KitchenCounter", roomId = "Kitchen", proxyPosition = v3(28.0, 22.5, -17.4), generated = { kind = "radio", position = v3(28.0, 22.5, -17.4) } },
	{ objectId = "Panel_Laundry", roomId = "LaundryRoom", proxyPosition = v3(-11.4, 7.2, 16.9), generated = { kind = "radio", position = v3(-11.4, 7.2, 16.9) } },
	{ objectId = "Panel_Bathroom", roomId = "Bathroom", proxyPosition = v3(-9.5, 21.9, 16.0), generated = { kind = "radio", position = v3(-9.5, 21.9, 16.0) } },
}

Layout.windows = {
	{ objectId = "Window_LaundryWest", roomId = "LaundryRoom", proxyPosition = v3(-23.4, 11.2, -1.8), targetRootName = "Glass", targetName = "Part", expectedPosition = v3(-23.4, 11.2, -1.8) },
	{ objectId = "Window_FrontNorth", roomId = "FrontPorch", proxyPosition = v3(-14.6, 11.4, -26.8), targetRootName = "Glass", targetName = "Part", expectedPosition = v3(-14.6, 11.4, -26.8) },
	{ objectId = "Window_LivingSouth", roomId = "LivingRoom", proxyPosition = v3(21.1, 11.2, 9.9), targetRootName = "Glass", targetName = "Part", expectedPosition = v3(21.1, 11.2, 9.9) },
	{ objectId = "Window_BathroomMid", roomId = "Bathroom", proxyPosition = v3(1.4, 22.3, 11.6), targetRootName = "Glass", targetName = "Part", expectedPosition = v3(1.4, 22.3, 11.6) },
	{ objectId = "Window_Bedroom1Top", roomId = "Bedroom1", proxyPosition = v3(19.9, 35.5, -30.9), targetRootName = "Glass", targetName = "Part", expectedPosition = v3(19.9, 35.5, -30.9) },
	{ objectId = "Window_Bedroom2Top", roomId = "Bedroom2", proxyPosition = v3(36.5, 35.5, -13.2), targetRootName = "Glass", targetName = "Part", expectedPosition = v3(36.5, 35.5, -13.2) },
}

Layout.roomIds = {}
Layout.roomIndex = {}
for _, room in ipairs(Layout.rooms) do
	Layout.roomIds[#Layout.roomIds + 1] = room.roomId
	Layout.roomIndex[room.roomId] = room
end

Layout.floorRoomCount = {
	floor1 = 4,
	floor2 = 4,
	floor3 = 4,
}

return Layout

local Layout = {}

local function v3(x, y, z)
	return Vector3.new(x, y, z)
end

Layout.mapId = "HauntedHouse"

Layout.rooms = {
	{ roomId = "Foyer", floor = 1, center = v3(-23.5, 50.5, -3.0), size = v3(14, 9, 16) },
	{ roomId = "DiningRoom", floor = 1, center = v3(-7.0, 50.5, 1.0), size = v3(24, 9, 18) },
	{ roomId = "Bathroom1", floor = 1, center = v3(-36.0, 50.5, 9.5), size = v3(12, 9, 10) },
	{ roomId = "StairHall", floor = 1, center = v3(-20.0, 50.5, 18.0), size = v3(18, 9, 16) },
	{ roomId = "LaundryRoom", floor = 1, center = v3(-12.5, 50.5, 24.0), size = v3(10, 9, 12) },
	{ roomId = "Bathroom2", floor = 1, center = v3(10.0, 50.5, 24.0), size = v3(24, 9, 18) },
	{ roomId = "Kitchen", floor = 1, center = v3(-39.0, 50.5, 36.0), size = v3(22, 9, 20) },
	{ roomId = "Pantry", floor = 1, center = v3(-45.0, 50.5, 17.0), size = v3(8, 9, 8) },
	{ roomId = "LivingRoom", floor = 1, center = v3(-18.0, 50.5, 49.0), size = v3(44, 9, 24) },
	{ roomId = "Garage", floor = 1, center = v3(-80.0, 50.5, 56.0), size = v3(28, 9, 20) },
	{ roomId = "HallwayMain", floor = 2, center = v3(-10.0, 63.0, 15.0), size = v3(20, 9, 16) },
	{ roomId = "Bathroom3", floor = 2, center = v3(-21.0, 63.0, -1.0), size = v3(18, 9, 12) },
	{ roomId = "Bedroom1", floor = 2, center = v3(-40.0, 63.0, 0.0), size = v3(20, 9, 24) },
	{ roomId = "ClosetA", floor = 2, center = v3(-44.0, 63.0, 11.5), size = v3(8, 9, 7) },
	{ roomId = "Bedroom2", floor = 2, center = v3(-23.0, 63.0, 24.0), size = v3(14, 9, 14) },
	{ roomId = "LinenCloset", floor = 2, center = v3(-30.0, 63.0, 21.5), size = v3(6, 9, 5) },
	{ roomId = "Bedroom3", floor = 2, center = v3(11.0, 63.0, 11.0), size = v3(24, 9, 24) },
	{ roomId = "ClosetB", floor = 2, center = v3(20.5, 63.0, 3.0), size = v3(8, 9, 8) },
	{ roomId = "Bathroom4", floor = 2, center = v3(-14.0, 63.0, 27.0), size = v3(16, 9, 12) },
	{ roomId = "BonusRoom", floor = 2, center = v3(-15.0, 63.0, 49.0), size = v3(44, 9, 24) },
}

Layout.spawnPoints = {
	{ name = "PlayerSpawn_1", position = v3(-19.2, 50.5, -26.5) },
	{ name = "PlayerSpawn_2", position = v3(-22.1, 50.5, -28.2) },
	{ name = "PlayerSpawn_3", position = v3(-25.0, 50.5, -28.2) },
	{ name = "PlayerSpawn_4", position = v3(-27.9, 50.5, -26.5) },
}

Layout.safeZones = {
	{ name = "SafeZone_FoyerExterior", position = v3(-30.5, 50.5, -25.0) },
	{ name = "SafeZone_FrontPorch", position = v3(-16.5, 50.5, -25.0) },
	{ name = "SafeZone_ClosetA", position = v3(-44.0, 63.0, 11.5) },
	{ name = "SafeZone_LinenCloset", position = v3(-30.0, 63.0, 21.5) },
	{ name = "SafeZone_ClosetB", position = v3(20.5, 63.0, 3.0) },
}

Layout.ghostSpawns = {
	{ name = "GhostSpawnZone_1", roomId = "LivingRoom", position = v3(-18.0, 50.5, 49.0) },
	{ name = "GhostSpawnZone_2", roomId = "Kitchen", position = v3(-39.0, 50.5, 36.0) },
	{ name = "GhostSpawnZone_3", roomId = "Garage", position = v3(-80.0, 50.5, 56.0) },
	{ name = "GhostSpawnZone_4", roomId = "Bedroom1", position = v3(-40.0, 63.0, 0.0) },
	{ name = "GhostSpawnZone_5", roomId = "Bedroom3", position = v3(11.0, 63.0, 11.0) },
	{ name = "GhostSpawnZone_6", roomId = "BonusRoom", position = v3(-15.0, 63.0, 49.0) },
}

Layout.evidenceNodes = {
	{ name = "EvidenceNode_1", roomId = "Foyer", position = v3(-22.0, 50.5, -5.0) },
	{ name = "EvidenceNode_2", roomId = "DiningRoom", position = v3(-4.0, 50.5, 2.5) },
	{ name = "EvidenceNode_3", roomId = "Bathroom1", position = v3(-37.0, 50.5, 8.5) },
	{ name = "EvidenceNode_4", roomId = "LaundryRoom", position = v3(-12.0, 50.5, 23.0) },
	{ name = "EvidenceNode_5", roomId = "Bathroom2", position = v3(9.5, 50.5, 23.5) },
	{ name = "EvidenceNode_6", roomId = "Kitchen", position = v3(-36.5, 50.5, 35.0) },
	{ name = "EvidenceNode_7", roomId = "LivingRoom", position = v3(-17.0, 50.5, 50.0) },
	{ name = "EvidenceNode_8", roomId = "Garage", position = v3(-79.0, 50.5, 58.0) },
	{ name = "EvidenceNode_9", roomId = "Bathroom3", position = v3(-21.0, 63.0, -3.0) },
	{ name = "EvidenceNode_10", roomId = "Bedroom1", position = v3(-39.0, 63.0, 1.0) },
	{ name = "EvidenceNode_11", roomId = "Bedroom2", position = v3(-23.0, 63.0, 23.0) },
	{ name = "EvidenceNode_12", roomId = "Bedroom3", position = v3(11.0, 63.0, 12.0) },
	{ name = "EvidenceNode_13", roomId = "Bathroom4", position = v3(-14.0, 63.0, 27.0) },
	{ name = "EvidenceNode_14", roomId = "BonusRoom", position = v3(-14.0, 63.0, 47.0) },
}

Layout.doors = {
	{ objectId = "Door_FrontEntry", label = "Pintu Depan", roomId = "Foyer", proxyPosition = v3(-23.5, 50.4, -10.7), targetRootName = "Decorative Exterior Door", targetName = "Door", expectedPosition = v3(-23.5, 50.1, -10.7), mode = "Swing", advanceFromPreparation = true },
	{ objectId = "Door_DiningRoom", label = "Pintu Dining", roomId = "DiningRoom", proxyPosition = v3(0.4, 50.4, 2.8), targetRootName = "Double Decorative Interior Door", targetName = "Door", expectedPosition = v3(0.4, 50.1, 2.8), mode = "Swing" },
	{ objectId = "Door_Bathroom1", label = "Pintu Bathroom 1", roomId = "Bathroom1", proxyPosition = v3(-29.6, 50.4, 13.6), targetRootName = "Decorative Interior Door", targetName = "Door", expectedPosition = v3(-29.6, 50.4, 13.6), mode = "Swing" },
	{ objectId = "Door_LaundryRoom", label = "Pintu Laundry", roomId = "LaundryRoom", proxyPosition = v3(-22.0, 50.4, 20.6), targetRootName = "Decorative Interior Door", targetName = "Door", expectedPosition = v3(-22.0, 50.4, 20.6), mode = "Swing" },
	{ objectId = "Door_Pantry", label = "Pintu Pantry", roomId = "Pantry", proxyPosition = v3(-45.3, 50.3, 17.3), targetRootName = "Closet Sliding Door", targetName = "Door", expectedPosition = v3(-45.3, 50.3, 17.3), mode = "Slide" },
	{ objectId = "Door_Bathroom2", label = "Pintu Bathroom 2", roomId = "Bathroom2", proxyPosition = v3(14.7, 50.4, 30.0), targetRootName = "Decorative Interior Door", targetName = "Door", expectedPosition = v3(14.7, 50.4, 30.0), mode = "Swing" },
	{ objectId = "Door_LivingRoom", label = "Pintu Living", roomId = "LivingRoom", proxyPosition = v3(-3.6, 50.4, 34.6), targetRootName = "Decorative Interior Door", targetName = "Door", expectedPosition = v3(-3.6, 50.4, 34.6), mode = "Swing" },
	{ objectId = "Door_BackPatio", label = "Pintu Patio", roomId = "LivingRoom", proxyPosition = v3(-40.3, 50.2, 54.7), targetRootName = "BackSlidingDoor", targetName = "SlidingDoor", expectedPosition = v3(-37.6, 50.0, 54.8), mode = "Slide" },
	{ objectId = "Door_Garage", label = "Pintu Garage", roomId = "Garage", proxyPosition = v3(-69.8, 50.4, 61.6), targetRootName = "Decorative Exterior Door", targetName = "Door", expectedPosition = v3(-69.8, 50.4, 61.6), mode = "Swing" },
	{ objectId = "Door_Bathroom3", label = "Pintu Bathroom 3", roomId = "Bathroom3", proxyPosition = v3(-25.7, 62.8, 10.8), targetRootName = "Decorative Interior Door", targetName = "Door", expectedPosition = v3(-25.7, 62.8, 10.8), mode = "Swing" },
	{ objectId = "Door_Bedroom1", label = "Pintu Bedroom 1", roomId = "Bedroom1", proxyPosition = v3(-29.8, 62.8, 15.2), targetRootName = "Decorative Interior Door", targetName = "Door", expectedPosition = v3(-29.8, 62.8, 15.2), mode = "Swing" },
	{ objectId = "Door_ClosetA", label = "Pintu Closet A", roomId = "ClosetA", proxyPosition = v3(-43.4, 62.7, 11.2), targetRootName = "Closet Sliding Door", targetName = "Door", expectedPosition = v3(-43.4, 62.7, 11.2), mode = "Slide" },
	{ objectId = "Door_Bedroom2", label = "Pintu Bedroom 2", roomId = "Bedroom2", proxyPosition = v3(-29.8, 62.8, 29.4), targetRootName = "Decorative Interior Door", targetName = "Door", expectedPosition = v3(-29.8, 62.8, 29.4), mode = "Swing" },
	{ objectId = "Door_LinenCloset", label = "Pintu Linen Closet", roomId = "LinenCloset", proxyPosition = v3(-30.0, 62.7, 22.0), targetRootName = "Closet Sliding Door", targetName = "Door", expectedPosition = v3(-30.0, 62.7, 22.0), mode = "Slide" },
	{ objectId = "Door_Bedroom3", label = "Pintu Bedroom 3", roomId = "Bedroom3", proxyPosition = v3(-1.1, 62.8, 10.8), targetRootName = "Decorative Interior Door", targetName = "Door", expectedPosition = v3(-1.1, 62.8, 10.8), mode = "Swing" },
	{ objectId = "Door_ClosetB", label = "Pintu Closet B", roomId = "ClosetB", proxyPosition = v3(20.6, 62.7, 2.8), targetRootName = "Closet Sliding Door", targetName = "Door", expectedPosition = v3(20.6, 62.7, 2.8), mode = "Slide" },
	{ objectId = "Door_Bathroom4", label = "Pintu Bathroom 4", roomId = "Bathroom4", proxyPosition = v3(-8.9, 62.8, 30.9), targetRootName = "Decorative Interior Door", targetName = "Door", expectedPosition = v3(-8.9, 62.8, 30.9), mode = "Swing" },
	{ objectId = "Door_BonusRoom", label = "Pintu Bonus Room", roomId = "BonusRoom", proxyPosition = v3(0.2, 62.8, 30.5), targetRootName = "Double Decorative Interior Door", targetName = "Door", expectedPosition = v3(0.2, 62.8, 30.5), mode = "Swing" },
}

Layout.lights = {
	{ objectId = "Light_DiningRoom", roomId = "DiningRoom", proxyPosition = v3(-7.0, 54.8, 0.0), generated = { kind = "ceiling_light", position = v3(-7.0, 54.6, 0.0) } },
	{ objectId = "Light_Foyer", roomId = "Foyer", proxyPosition = v3(-23.5, 54.8, -2.0), generated = { kind = "ceiling_light", position = v3(-23.5, 54.6, -2.0) } },
	{ objectId = "Light_Bathroom1", roomId = "Bathroom1", proxyPosition = v3(-36.0, 54.8, 9.0), generated = { kind = "ceiling_light", position = v3(-36.0, 54.6, 9.0) } },
	{ objectId = "Light_StairHall", roomId = "StairHall", proxyPosition = v3(-20.0, 54.8, 18.0), generated = { kind = "ceiling_light", position = v3(-20.0, 54.6, 18.0) } },
	{ objectId = "Light_LaundryRoom", roomId = "LaundryRoom", proxyPosition = v3(-12.0, 53.5, 19.0), targetRootName = "SWF&L Fluorescent Lamp", expectedPosition = v3(-12.1, 51.4, 17.9) },
	{ objectId = "Light_Bathroom2", roomId = "Bathroom2", proxyPosition = v3(9.0, 53.8, 20.0), targetRootName = "SWF&L Fluorescent Lamp", expectedPosition = v3(6.3, 52.3, 20.4) },
	{ objectId = "Light_Kitchen", roomId = "Kitchen", proxyPosition = v3(-35.0, 53.6, 34.0), targetRootName = "CFC Kitchen 4 Light Flourescent", expectedPosition = v3(-35.4, 52.9, 34.0) },
	{ objectId = "Light_Pantry", roomId = "Pantry", proxyPosition = v3(-45.0, 54.4, 17.0), generated = { kind = "ceiling_light", position = v3(-45.0, 54.2, 17.0) } },
	{ objectId = "Light_LivingRoom", roomId = "LivingRoom", proxyPosition = v3(-17.0, 54.5, 42.0), targetRootName = "Six's Fan CO. 4 Arm Light Kit", expectedPosition = v3(-16.6, 54.8, 42.0) },
	{ objectId = "Light_Garage", roomId = "Garage", proxyPosition = v3(-79.5, 53.5, 64.0), targetRootName = "SWF&L Fluorescent Lamp", expectedPosition = v3(-79.5, 51.5, 64.1) },
	{ objectId = "Light_HallwayMain", roomId = "HallwayMain", proxyPosition = v3(-2.5, 66.2, 13.8), targetRootName = "CFC Contractor Bowl Light", expectedPosition = v3(-2.4, 65.6, 13.8) },
	{ objectId = "Light_Bathroom3", roomId = "Bathroom3", proxyPosition = v3(-18.5, 68.3, 5.0), generated = { kind = "ceiling_light", position = v3(-18.5, 68.1, 5.0) } },
	{ objectId = "Light_Bedroom1", roomId = "Bedroom1", proxyPosition = v3(-40.0, 69.0, 0.0), generated = { kind = "ceiling_light", position = v3(-40.0, 68.8, 0.0) } },
	{ objectId = "Light_ClosetA", roomId = "ClosetA", proxyPosition = v3(-44.0, 67.6, 11.5), generated = { kind = "ceiling_light", position = v3(-44.0, 67.4, 11.5) } },
	{ objectId = "Light_Bedroom2", roomId = "Bedroom2", proxyPosition = v3(-25.5, 69.0, 28.0), generated = { kind = "ceiling_light", position = v3(-25.5, 68.8, 28.0) } },
	{ objectId = "Light_LinenCloset", roomId = "LinenCloset", proxyPosition = v3(-30.0, 67.6, 21.5), generated = { kind = "ceiling_light", position = v3(-30.0, 67.4, 21.5) } },
	{ objectId = "Light_Bedroom3", roomId = "Bedroom3", proxyPosition = v3(12.8, 69.0, 11.0), generated = { kind = "ceiling_light", position = v3(12.8, 68.8, 11.0) } },
	{ objectId = "Light_ClosetB", roomId = "ClosetB", proxyPosition = v3(20.5, 67.6, 3.0), generated = { kind = "ceiling_light", position = v3(20.5, 67.4, 3.0) } },
	{ objectId = "Light_Bathroom4", roomId = "Bathroom4", proxyPosition = v3(-11.8, 68.3, 22.0), generated = { kind = "ceiling_light", position = v3(-11.8, 68.1, 22.0) } },
	{ objectId = "Light_BonusRoom", roomId = "BonusRoom", proxyPosition = v3(-15.0, 69.0, 49.0), generated = { kind = "ceiling_light", position = v3(-15.0, 68.8, 49.0) } },
}

Layout.windows = {
	{ objectId = "Window_Foyer", roomId = "Foyer", proxyPosition = v3(-26.9, 52.0, -10.8), targetRootName = "Narrow Sliding Window", expectedPosition = v3(-26.9, 50.2, -10.8) },
	{ objectId = "Window_DiningRoom", roomId = "DiningRoom", proxyPosition = v3(-20.1, 52.0, -10.8), targetRootName = "Narrow Sliding Window", expectedPosition = v3(-20.1, 50.2, -10.8) },
	{ objectId = "Window_LivingRoom", roomId = "LivingRoom", proxyPosition = v3(-24.3, 52.0, 54.7), targetRootName = "Sliding Window", expectedPosition = v3(-24.3, 51.8, 54.7) },
	{ objectId = "Window_Bedroom1", roomId = "Bedroom1", proxyPosition = v3(-44.3, 64.8, -12.0), targetRootName = "Single Sliding Window", expectedPosition = v3(-44.3, 64.0, -12.2) },
	{ objectId = "Window_Bedroom3", roomId = "Bedroom3", proxyPosition = v3(9.9, 64.8, -4.6), targetRootName = "Sliding Window", expectedPosition = v3(9.9, 64.0, -4.6) },
	{ objectId = "Window_BonusRoom", roomId = "BonusRoom", proxyPosition = v3(-49.9, 64.8, 30.0), targetRootName = "Sliding Window", expectedPosition = v3(-49.9, 64.0, 30.0) },
}

Layout.props = {
	{ objectId = "Prop_FoyerStand", roomId = "Foyer", proxyPosition = v3(-21.5, 50.8, -1.0), generated = { kind = "prop_box", position = v3(-21.5, 50.8, -1.0) } },
	{ objectId = "Prop_DiningStand", roomId = "DiningRoom", proxyPosition = v3(-4.5, 50.8, 1.5), generated = { kind = "prop_box", position = v3(-4.5, 50.8, 1.5) } },
	{ objectId = "Prop_Bathroom1Cabinet", roomId = "Bathroom1", proxyPosition = v3(-37.5, 50.8, 10.5), generated = { kind = "prop_box", position = v3(-37.5, 50.8, 10.5) } },
	{ objectId = "Prop_StairHallConsole", roomId = "StairHall", proxyPosition = v3(-16.5, 50.8, 19.0), generated = { kind = "prop_box", position = v3(-16.5, 50.8, 19.0) } },
	{ objectId = "Prop_LaundryCrate", roomId = "LaundryRoom", proxyPosition = v3(-11.5, 50.8, 22.0), generated = { kind = "prop_crate", position = v3(-11.5, 50.8, 22.0) } },
	{ objectId = "Prop_Bathroom2Hamper", roomId = "Bathroom2", proxyPosition = v3(8.0, 50.8, 22.0), generated = { kind = "prop_box", position = v3(8.0, 50.8, 22.0) } },
	{ objectId = "Prop_KitchenCrate", roomId = "Kitchen", proxyPosition = v3(-41.0, 50.8, 31.0), generated = { kind = "prop_crate", position = v3(-41.0, 50.8, 31.0) } },
	{ objectId = "Prop_PantryShelf", roomId = "Pantry", proxyPosition = v3(-44.5, 50.8, 18.0), generated = { kind = "prop_box", position = v3(-44.5, 50.8, 18.0) } },
	{ objectId = "Prop_LivingStand", roomId = "LivingRoom", proxyPosition = v3(-9.0, 50.8, 46.0), generated = { kind = "prop_box", position = v3(-9.0, 50.8, 46.0) } },
	{ objectId = "Prop_GarageBox", roomId = "Garage", proxyPosition = v3(-77.0, 50.8, 58.0), generated = { kind = "prop_crate", position = v3(-77.0, 50.8, 58.0) } },
	{ objectId = "Prop_HallwayMainTable", roomId = "HallwayMain", proxyPosition = v3(-7.0, 63.3, 13.5), generated = { kind = "prop_box", position = v3(-7.0, 63.3, 13.5) } },
	{ objectId = "Prop_Bathroom3Cabinet", roomId = "Bathroom3", proxyPosition = v3(-19.5, 63.3, -1.0), generated = { kind = "prop_box", position = v3(-19.5, 63.3, -1.0) } },
	{ objectId = "Prop_Bedroom1Stand", roomId = "Bedroom1", proxyPosition = v3(-38.0, 63.3, 4.0), generated = { kind = "prop_box", position = v3(-38.0, 63.3, 4.0) } },
	{ objectId = "Prop_ClosetAHanger", roomId = "ClosetA", proxyPosition = v3(-44.3, 63.3, 12.5), generated = { kind = "prop_box", position = v3(-44.3, 63.3, 12.5) } },
	{ objectId = "Prop_Bedroom2Stand", roomId = "Bedroom2", proxyPosition = v3(-22.0, 63.3, 22.0), generated = { kind = "prop_box", position = v3(-22.0, 63.3, 22.0) } },
	{ objectId = "Prop_LinenClosetStack", roomId = "LinenCloset", proxyPosition = v3(-29.5, 63.3, 21.2), generated = { kind = "prop_box", position = v3(-29.5, 63.3, 21.2) } },
	{ objectId = "Prop_Bedroom3Stand", roomId = "Bedroom3", proxyPosition = v3(8.0, 63.3, 13.0), generated = { kind = "prop_box", position = v3(8.0, 63.3, 13.0) } },
	{ objectId = "Prop_ClosetBBox", roomId = "ClosetB", proxyPosition = v3(20.0, 63.3, 4.2), generated = { kind = "prop_box", position = v3(20.0, 63.3, 4.2) } },
	{ objectId = "Prop_Bathroom4Cabinet", roomId = "Bathroom4", proxyPosition = v3(-12.0, 63.3, 25.5), generated = { kind = "prop_box", position = v3(-12.0, 63.3, 25.5) } },
	{ objectId = "Prop_BonusStand", roomId = "BonusRoom", proxyPosition = v3(-11.0, 63.3, 47.0), generated = { kind = "prop_box", position = v3(-11.0, 63.3, 47.0) } },
}

Layout.electronics = {
	{ objectId = "Radio_KitchenCounter", roomId = "Kitchen", proxyPosition = v3(-34.5, 49.5, 35.5), generated = { kind = "radio", position = v3(-34.5, 49.5, 35.5) } },
	{ objectId = "TV_LivingRoom", roomId = "LivingRoom", proxyPosition = v3(-9.0, 51.6, 48.0), generated = { kind = "tv", position = v3(-9.0, 51.6, 48.0) } },
	{ objectId = "Panel_StairHall", roomId = "StairHall", proxyPosition = v3(-18.5, 51.7, 16.7), generated = { kind = "radio", position = v3(-18.5, 51.3, 16.7) } },
	{ objectId = "TV_Bedroom1", roomId = "Bedroom1", proxyPosition = v3(-37.0, 63.6, -1.0), generated = { kind = "tv", position = v3(-37.0, 63.6, -1.0) } },
	{ objectId = "TV_Bedroom3", roomId = "Bedroom3", proxyPosition = v3(9.0, 63.6, 10.0), generated = { kind = "tv", position = v3(9.0, 63.6, 10.0) } },
	{ objectId = "TV_BonusRoom", roomId = "BonusRoom", proxyPosition = v3(-10.0, 63.6, 51.0), generated = { kind = "tv", position = v3(-10.0, 63.6, 51.0) } },
	{ objectId = "Panel_Garage", roomId = "Garage", proxyPosition = v3(-70.0, 49.9, 57.1), generated = { kind = "radio", position = v3(-70.0, 49.5, 57.1) } },
}

Layout.roomIds = {}
Layout.roomIndex = {}
for _, room in ipairs(Layout.rooms) do
	Layout.roomIds[#Layout.roomIds + 1] = room.roomId
	Layout.roomIndex[room.roomId] = room
end

Layout.floorRoomCount = {
	floor1 = 10,
	floor2 = 10,
}

return Layout

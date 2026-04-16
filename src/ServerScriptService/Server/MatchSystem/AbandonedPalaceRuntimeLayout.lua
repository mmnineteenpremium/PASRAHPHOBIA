local Layout = {}

local function v3(x, y, z)
	return Vector3.new(x, y, z)
end

Layout.mapId = "AbandonedPalace"

Layout.rooms = {
	{ roomId = "GrandHall", floor = 1, center = v3(0.0, 0.5, 0.0), size = v3(58.0, 1.0, 58.0) },
	{ roomId = "RoyalCorridor", floor = 1, center = v3(35.0, 0.5, 0.0), size = v3(18.0, 1.0, 118.0) },
	{ roomId = "DiningHall", floor = 1, center = v3(-45.0, 0.5, 25.0), size = v3(33.0, 1.0, 26.0) },
	{ roomId = "Library", floor = 1, center = v3(-45.0, 0.5, -25.0), size = v3(33.0, 1.0, 26.0) },
	{ roomId = "GuestRoomA", floor = 1, center = v3(65.0, 0.5, -45.0), size = v3(26.0, 1.0, 18.0) },
	{ roomId = "GuestRoomB", floor = 1, center = v3(65.0, 0.5, -15.0), size = v3(26.0, 1.0, 18.0) },
	{ roomId = "GuestRoomC", floor = 1, center = v3(65.0, 0.5, 15.0), size = v3(26.0, 1.0, 18.0) },
	{ roomId = "ServantRoomA", floor = 1, center = v3(-65.0, 0.5, 45.0), size = v3(24.0, 1.0, 16.0) },
	{ roomId = "ServantRoomB", floor = 1, center = v3(-65.0, 0.5, 20.0), size = v3(24.0, 1.0, 16.0) },
	{ roomId = "ServantRoomC", floor = 1, center = v3(-65.0, 0.5, -10.0), size = v3(24.0, 1.0, 16.0) },
	{ roomId = "Basement", floor = 1, center = v3(0.0, 0.5, 65.0), size = v3(38.0, 1.0, 22.0) },
	{ roomId = "Courtyard", floor = 1, center = v3(0.0, 0.5, -70.0), size = v3(48.0, 1.0, 28.0) },
	{ roomId = "Armory", floor = 1, center = v3(-10.0, 0.5, -70.0), size = v3(22.0, 1.0, 16.0) },
	{ roomId = "Chapel", floor = 1, center = v3(10.0, 0.5, -70.0), size = v3(22.0, 1.0, 16.0) },
	{ roomId = "Ballroom", floor = 1, center = v3(20.0, 0.5, 55.0), size = v3(38.0, 1.0, 26.0) },
	{ roomId = "Observatory", floor = 1, center = v3(45.0, 0.5, 70.0), size = v3(24.0, 1.0, 16.0) },
	{ roomId = "StorageWing", floor = 1, center = v3(-45.0, 0.5, 70.0), size = v3(24.0, 1.0, 16.0) },
	{ roomId = "CeremonyRoom", floor = 1, center = v3(-10.0, 0.5, 55.0), size = v3(26.0, 1.0, 18.0) },
}

Layout.spawnPoints = {
	{ name = "PlayerSpawn_1", position = v3(-10.0, 4.0, -10.0) },
	{ name = "PlayerSpawn_2", position = v3(10.0, 4.0, -10.0) },
	{ name = "PlayerSpawn_3", position = v3(-10.0, 4.0, 10.0) },
	{ name = "PlayerSpawn_4", position = v3(10.0, 4.0, 10.0) },
}

Layout.safeZones = {
	{ name = "SafeZone_1", position = v3(-61.2, 4.0, 32.4) },
	{ name = "SafeZone_2", position = v3(61.2, 4.0, -32.4) },
}

Layout.ghostSpawns = {
	{ name = "GhostSpawnZone_1", roomId = "Courtyard", position = v3(-32.0, 6.0, -60.0) },
	{ name = "GhostSpawnZone_2", roomId = "RoyalCorridor", position = v3(0.0, 6.0, -60.0) },
	{ name = "GhostSpawnZone_3", roomId = "GuestRoomA", position = v3(32.0, 6.0, -60.0) },
	{ name = "GhostSpawnZone_4", roomId = "GuestRoomA", position = v3(64.0, 6.0, -60.0) },
	{ name = "GhostSpawnZone_5", roomId = "ServantRoomB", position = v3(-64.0, 6.0, 20.0) },
}

Layout.evidenceNodes = {
	{ name = "EvidenceNode_1", roomId = "ServantRoomC", position = v3(-68.57, 2.0, -65.78) },
	{ name = "EvidenceNode_2", roomId = "Armory", position = v3(-25.90, 2.0, -65.78) },
	{ name = "EvidenceNode_3", roomId = "Courtyard", position = v3(-4.57, 2.0, -52.30) },
	{ name = "EvidenceNode_4", roomId = "Chapel", position = v3(38.10, 2.0, -65.78) },
	{ name = "EvidenceNode_5", roomId = "GuestRoomA", position = v3(59.42, 2.0, -65.78) },
	{ name = "EvidenceNode_6", roomId = "Library", position = v3(-57.90, 2.0, -12.30) },
	{ name = "EvidenceNode_7", roomId = "Library", position = v3(-36.58, 2.0, -25.77) },
	{ name = "EvidenceNode_8", roomId = "GrandHall", position = v3(6.10, 2.0, -25.77) },
	{ name = "EvidenceNode_9", roomId = "RoyalCorridor", position = v3(27.42, 2.0, -12.30) },
	{ name = "EvidenceNode_10", roomId = "GuestRoomB", position = v3(70.10, 2.0, -25.77) },
	{ name = "EvidenceNode_11", roomId = "ServantRoomB", position = v3(-68.57, 2.0, 14.23) },
	{ name = "EvidenceNode_12", roomId = "DiningHall", position = v3(-25.90, 2.0, 27.70) },
	{ name = "EvidenceNode_13", roomId = "CeremonyRoom", position = v3(-4.57, 2.0, 14.23) },
	{ name = "EvidenceNode_14", roomId = "Ballroom", position = v3(38.10, 2.0, 14.23) },
}

Layout.doors = {
	{ objectId = "Door_GrandHall", label = "Pintu Grand Hall", roomId = "GrandHall", proxyPosition = v3(-12.0, 3.5, 28.0), targetRootName = "MainEntryDoor", targetName = "Door", expectedPosition = v3(-12.0, 3.5, 28.0), mode = "Swing", advanceFromPreparation = true },
	{ objectId = "Door_RoyalCorridor", label = "Pintu Royal Corridor", roomId = "RoyalCorridor", proxyPosition = v3(25.25, 3.5, 0.0), mode = "Swing" },
	{ objectId = "Door_DiningHall", label = "Pintu Dining Hall", roomId = "DiningHall", proxyPosition = v3(-27.75, 3.5, 25.0), mode = "Swing" },
	{ objectId = "Door_Library", label = "Pintu Library", roomId = "Library", proxyPosition = v3(-27.75, 3.5, -25.0), mode = "Swing" },
	{ objectId = "Door_GuestRoomA", label = "Pintu Guest A", roomId = "GuestRoomA", proxyPosition = v3(51.25, 3.5, -45.0), mode = "Swing" },
	{ objectId = "Door_GuestRoomB", label = "Pintu Guest B", roomId = "GuestRoomB", proxyPosition = v3(51.25, 3.5, -15.0), mode = "Swing" },
	{ objectId = "Door_GuestRoomC", label = "Pintu Guest C", roomId = "GuestRoomC", proxyPosition = v3(51.25, 3.5, 15.0), mode = "Swing" },
	{ objectId = "Door_ServantRoomA", label = "Pintu Servant A", roomId = "ServantRoomA", proxyPosition = v3(-52.25, 3.5, 45.0), mode = "Swing" },
	{ objectId = "Door_ServantRoomB", label = "Pintu Servant B", roomId = "ServantRoomB", proxyPosition = v3(-52.25, 3.5, 20.0), mode = "Swing" },
	{ objectId = "Door_ServantRoomC", label = "Pintu Servant C", roomId = "ServantRoomC", proxyPosition = v3(-52.25, 3.5, -10.0), mode = "Swing" },
	{ objectId = "Door_Basement", label = "Pintu Basement", roomId = "Basement", proxyPosition = v3(0.0, 3.5, 53.25), mode = "Swing" },
	{ objectId = "Door_Courtyard", label = "Pintu Courtyard", roomId = "Courtyard", proxyPosition = v3(0.0, 3.5, -55.25), mode = "Swing" },
	{ objectId = "Door_Armory", label = "Pintu Armory", roomId = "Armory", proxyPosition = v3(-10.0, 3.5, -61.25), mode = "Swing" },
	{ objectId = "Door_Chapel", label = "Pintu Chapel", roomId = "Chapel", proxyPosition = v3(10.0, 3.5, -61.25), mode = "Swing" },
	{ objectId = "Door_Ballroom", label = "Pintu Ballroom", roomId = "Ballroom", proxyPosition = v3(20.0, 3.5, 41.25), mode = "Swing" },
	{ objectId = "Door_Observatory", label = "Pintu Observatory", roomId = "Observatory", proxyPosition = v3(32.25, 3.5, 70.0), mode = "Swing" },
	{ objectId = "Door_StorageWing", label = "Pintu Storage Wing", roomId = "StorageWing", proxyPosition = v3(-32.25, 3.5, 70.0), mode = "Swing" },
	{ objectId = "Door_CeremonyRoom", label = "Pintu Ceremony", roomId = "CeremonyRoom", proxyPosition = v3(-10.0, 3.5, 45.25), mode = "Swing" },
}

Layout.lights = {
	{ objectId = "Light_GrandHall", roomId = "GrandHall", proxyPosition = v3(0.0, 9.5, 0.0), generated = { kind = "ceiling_light", position = v3(0.0, 9.3, 0.0) } },
	{ objectId = "Light_RoyalCorridor", roomId = "RoyalCorridor", proxyPosition = v3(35.0, 9.5, 0.0), generated = { kind = "ceiling_light", position = v3(35.0, 9.3, 0.0) } },
	{ objectId = "Light_DiningHall", roomId = "DiningHall", proxyPosition = v3(-45.0, 9.5, 25.0), generated = { kind = "ceiling_light", position = v3(-45.0, 9.3, 25.0) } },
	{ objectId = "Light_Library", roomId = "Library", proxyPosition = v3(-45.0, 9.5, -25.0), generated = { kind = "ceiling_light", position = v3(-45.0, 9.3, -25.0) } },
	{ objectId = "Light_GuestRoomA", roomId = "GuestRoomA", proxyPosition = v3(65.0, 9.5, -45.0), generated = { kind = "ceiling_light", position = v3(65.0, 9.3, -45.0) } },
	{ objectId = "Light_GuestRoomB", roomId = "GuestRoomB", proxyPosition = v3(65.0, 9.5, -15.0), generated = { kind = "ceiling_light", position = v3(65.0, 9.3, -15.0) } },
	{ objectId = "Light_GuestRoomC", roomId = "GuestRoomC", proxyPosition = v3(65.0, 9.5, 15.0), generated = { kind = "ceiling_light", position = v3(65.0, 9.3, 15.0) } },
	{ objectId = "Light_ServantRoomA", roomId = "ServantRoomA", proxyPosition = v3(-65.0, 9.5, 45.0), generated = { kind = "ceiling_light", position = v3(-65.0, 9.3, 45.0) } },
	{ objectId = "Light_ServantRoomB", roomId = "ServantRoomB", proxyPosition = v3(-65.0, 9.5, 20.0), generated = { kind = "ceiling_light", position = v3(-65.0, 9.3, 20.0) } },
	{ objectId = "Light_ServantRoomC", roomId = "ServantRoomC", proxyPosition = v3(-65.0, 9.5, -10.0), generated = { kind = "ceiling_light", position = v3(-65.0, 9.3, -10.0) } },
	{ objectId = "Light_Basement", roomId = "Basement", proxyPosition = v3(0.0, 9.5, 65.0), generated = { kind = "ceiling_light", position = v3(0.0, 9.3, 65.0) } },
	{ objectId = "Light_Courtyard", roomId = "Courtyard", proxyPosition = v3(0.0, 9.5, -70.0), generated = { kind = "ceiling_light", position = v3(0.0, 9.3, -70.0) } },
	{ objectId = "Light_Armory", roomId = "Armory", proxyPosition = v3(-10.0, 9.5, -70.0), generated = { kind = "ceiling_light", position = v3(-10.0, 9.3, -70.0) } },
	{ objectId = "Light_Chapel", roomId = "Chapel", proxyPosition = v3(10.0, 9.5, -70.0), generated = { kind = "ceiling_light", position = v3(10.0, 9.3, -70.0) } },
	{ objectId = "Light_Ballroom", roomId = "Ballroom", proxyPosition = v3(20.0, 9.5, 55.0), generated = { kind = "ceiling_light", position = v3(20.0, 9.3, 55.0) } },
	{ objectId = "Light_Observatory", roomId = "Observatory", proxyPosition = v3(45.0, 9.5, 70.0), generated = { kind = "ceiling_light", position = v3(45.0, 9.3, 70.0) } },
	{ objectId = "Light_StorageWing", roomId = "StorageWing", proxyPosition = v3(-45.0, 9.5, 70.0), generated = { kind = "ceiling_light", position = v3(-45.0, 9.3, 70.0) } },
	{ objectId = "Light_CeremonyRoom", roomId = "CeremonyRoom", proxyPosition = v3(-10.0, 9.5, 55.0), generated = { kind = "ceiling_light", position = v3(-10.0, 9.3, 55.0) } },
}

Layout.props = {
	{ objectId = "Prop_GrandHall", roomId = "GrandHall", proxyPosition = v3(2.0, 1.0, 2.0), generated = { kind = "prop_box", position = v3(2.0, 1.0, 2.0) } },
	{ objectId = "Prop_RoyalCorridor", roomId = "RoyalCorridor", proxyPosition = v3(37.0, 1.0, 2.0), generated = { kind = "prop_box", position = v3(37.0, 1.0, 2.0) } },
	{ objectId = "Prop_DiningHall", roomId = "DiningHall", proxyPosition = v3(-43.0, 1.0, 27.0), generated = { kind = "prop_box", position = v3(-43.0, 1.0, 27.0) } },
	{ objectId = "Prop_Library", roomId = "Library", proxyPosition = v3(-43.0, 1.0, -23.0), generated = { kind = "prop_box", position = v3(-43.0, 1.0, -23.0) } },
	{ objectId = "Prop_GuestRoomA", roomId = "GuestRoomA", proxyPosition = v3(67.0, 1.0, -43.0), generated = { kind = "prop_box", position = v3(67.0, 1.0, -43.0) } },
	{ objectId = "Prop_GuestRoomB", roomId = "GuestRoomB", proxyPosition = v3(67.0, 1.0, -13.0), generated = { kind = "prop_box", position = v3(67.0, 1.0, -13.0) } },
	{ objectId = "Prop_GuestRoomC", roomId = "GuestRoomC", proxyPosition = v3(67.0, 1.0, 17.0), generated = { kind = "prop_box", position = v3(67.0, 1.0, 17.0) } },
	{ objectId = "Prop_ServantRoomA", roomId = "ServantRoomA", proxyPosition = v3(-63.0, 1.0, 47.0), generated = { kind = "prop_crate", position = v3(-63.0, 1.0, 47.0) } },
	{ objectId = "Prop_ServantRoomB", roomId = "ServantRoomB", proxyPosition = v3(-63.0, 1.0, 22.0), generated = { kind = "prop_crate", position = v3(-63.0, 1.0, 22.0) } },
	{ objectId = "Prop_ServantRoomC", roomId = "ServantRoomC", proxyPosition = v3(-63.0, 1.0, -8.0), generated = { kind = "prop_crate", position = v3(-63.0, 1.0, -8.0) } },
	{ objectId = "Prop_Basement", roomId = "Basement", proxyPosition = v3(2.0, 1.0, 67.0), generated = { kind = "prop_crate", position = v3(2.0, 1.0, 67.0) } },
	{ objectId = "Prop_Courtyard", roomId = "Courtyard", proxyPosition = v3(2.0, 1.0, -68.0), generated = { kind = "prop_crate", position = v3(2.0, 1.0, -68.0) } },
	{ objectId = "Prop_Armory", roomId = "Armory", proxyPosition = v3(-8.0, 1.0, -68.0), generated = { kind = "prop_crate", position = v3(-8.0, 1.0, -68.0) } },
	{ objectId = "Prop_Chapel", roomId = "Chapel", proxyPosition = v3(12.0, 1.0, -68.0), generated = { kind = "prop_box", position = v3(12.0, 1.0, -68.0) } },
	{ objectId = "Prop_Ballroom", roomId = "Ballroom", proxyPosition = v3(22.0, 1.0, 57.0), generated = { kind = "prop_box", position = v3(22.0, 1.0, 57.0) } },
	{ objectId = "Prop_Observatory", roomId = "Observatory", proxyPosition = v3(47.0, 1.0, 72.0), generated = { kind = "prop_box", position = v3(47.0, 1.0, 72.0) } },
	{ objectId = "Prop_StorageWing", roomId = "StorageWing", proxyPosition = v3(-43.0, 1.0, 72.0), generated = { kind = "prop_crate", position = v3(-43.0, 1.0, 72.0) } },
	{ objectId = "Prop_CeremonyRoom", roomId = "CeremonyRoom", proxyPosition = v3(-8.0, 1.0, 57.0), generated = { kind = "prop_box", position = v3(-8.0, 1.0, 57.0) } },
}

Layout.electronics = {
	{ objectId = "Radio_GrandHall", roomId = "GrandHall", proxyPosition = v3(14.5, 1.5, -14.5), generated = { kind = "radio", position = v3(14.5, 1.5, -14.5) } },
	{ objectId = "Radio_Library", roomId = "Library", proxyPosition = v3(-53.25, 1.5, -18.5), generated = { kind = "radio", position = v3(-53.25, 1.5, -18.5) } },
	{ objectId = "TV_GuestRoomA", roomId = "GuestRoomA", proxyPosition = v3(58.5, 1.5, -40.5), generated = { kind = "tv", position = v3(58.5, 1.5, -40.5) } },
	{ objectId = "TV_GuestRoomB", roomId = "GuestRoomB", proxyPosition = v3(58.5, 1.5, -10.5), generated = { kind = "tv", position = v3(58.5, 1.5, -10.5) } },
	{ objectId = "Panel_Basement", roomId = "Basement", proxyPosition = v3(-9.5, 1.5, 70.5), generated = { kind = "radio", position = v3(-9.5, 1.5, 70.5) } },
	{ objectId = "TV_Ballroom", roomId = "Ballroom", proxyPosition = v3(29.5, 1.5, 48.5), generated = { kind = "tv", position = v3(29.5, 1.5, 48.5) } },
}

Layout.windows = {
	{ objectId = "Window_North_1", roomId = "GuestRoomA", proxyPosition = v3(70.0, 6.0, -65.0), generated = { kind = "prop_box", position = v3(70.0, 6.0, -65.0) } },
	{ objectId = "Window_North_2", roomId = "Courtyard", proxyPosition = v3(0.0, 6.0, -80.0), generated = { kind = "prop_box", position = v3(0.0, 6.0, -80.0) } },
	{ objectId = "Window_East_1", roomId = "GuestRoomC", proxyPosition = v3(80.0, 6.0, 15.0), generated = { kind = "prop_box", position = v3(80.0, 6.0, 15.0) } },
	{ objectId = "Window_West_1", roomId = "ServantRoomA", proxyPosition = v3(-80.0, 6.0, 45.0), generated = { kind = "prop_box", position = v3(-80.0, 6.0, 45.0) } },
	{ objectId = "Window_South_1", roomId = "StorageWing", proxyPosition = v3(-45.0, 6.0, 82.0), generated = { kind = "prop_box", position = v3(-45.0, 6.0, 82.0) } },
	{ objectId = "Window_South_2", roomId = "Observatory", proxyPosition = v3(45.0, 6.0, 82.0), generated = { kind = "prop_box", position = v3(45.0, 6.0, 82.0) } },
}

Layout.roomIds = {}
Layout.roomIndex = {}
for _, room in ipairs(Layout.rooms) do
	Layout.roomIds[#Layout.roomIds + 1] = room.roomId
	Layout.roomIndex[room.roomId] = room
end

Layout.floorRoomCount = {
	floor1 = 18,
}

return Layout

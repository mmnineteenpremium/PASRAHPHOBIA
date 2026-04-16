local Layout = {}

local function v3(x, y, z)
	return Vector3.new(x, y, z)
end

Layout.mapId = "EmptyBuilding"

Layout.rooms = {
	{ roomId = "Lobby", floor = 1, center = v3(800.0, 0.5, -20.0), size = v3(48.0, 1.0, 28.0) },
	{ roomId = "SecurityRoom", floor = 1, center = v3(770.0, 0.5, -20.0), size = v3(16.0, 1.0, 12.0) },
	{ roomId = "Storage", floor = 1, center = v3(830.0, 0.5, -20.0), size = v3(18.0, 1.0, 16.0) },
	{ roomId = "ElectricalRoom", floor = 1, center = v3(830.0, 0.5, 10.0), size = v3(16.0, 1.0, 14.0) },
	{ roomId = "OfficeA", floor = 1, center = v3(770.0, 0.5, 15.0), size = v3(18.0, 1.0, 14.0) },
	{ roomId = "OfficeB", floor = 1, center = v3(770.0, 0.5, 35.0), size = v3(18.0, 1.0, 14.0) },
	{ roomId = "Bathroom1", floor = 1, center = v3(830.0, 0.5, 35.0), size = v3(14.0, 1.0, 10.0) },
	{ roomId = "StaircaseNorth", floor = 1, center = v3(800.0, 0.5, -50.0), size = v3(12.0, 1.0, 12.0) },
	{ roomId = "StaircaseSouth", floor = 1, center = v3(800.0, 0.5, 50.0), size = v3(12.0, 1.0, 12.0) },
	{ roomId = "WorkspaceOpen", floor = 2, center = v3(800.0, 12.5, 0.0), size = v3(58.0, 1.0, 38.0) },
	{ roomId = "MeetingRoom", floor = 2, center = v3(825.0, 12.5, -30.0), size = v3(22.0, 1.0, 16.0) },
	{ roomId = "ServerRoom", floor = 2, center = v3(775.0, 12.5, -30.0), size = v3(20.0, 1.0, 16.0) },
	{ roomId = "ArchiveRoom", floor = 2, center = v3(825.0, 12.5, 30.0), size = v3(20.0, 1.0, 16.0) },
	{ roomId = "Bathroom2", floor = 2, center = v3(775.0, 12.5, 30.0), size = v3(14.0, 1.0, 10.0) },
}

Layout.spawnPoints = {
	{ name = "PlayerSpawn_1", position = v3(790.0, 4.0, -10.0) },
	{ name = "PlayerSpawn_2", position = v3(810.0, 4.0, -10.0) },
	{ name = "PlayerSpawn_3", position = v3(790.0, 4.0, 10.0) },
	{ name = "PlayerSpawn_4", position = v3(810.0, 4.0, 10.0) },
}

Layout.safeZones = {
	{ name = "SafeZone_1", position = v3(766.0, 4.0, 18.0) },
	{ name = "SafeZone_2", position = v3(834.0, 4.0, -18.0) },
}

Layout.ghostSpawns = {
	{ name = "GhostSpawnZone_1", roomId = "MeetingRoom", position = v3(826.67, 6.0, -26.67) },
	{ name = "GhostSpawnZone_2", roomId = "OfficeA", position = v3(773.33, 6.0, 0.0) },
	{ name = "GhostSpawnZone_3", roomId = "WorkspaceOpen", position = v3(800.0, 18.0, -26.67) },
	{ name = "GhostSpawnZone_4", roomId = "MeetingRoom", position = v3(826.67, 18.0, -26.67) },
	{ name = "GhostSpawnZone_5", roomId = "ServerRoom", position = v3(773.33, 18.0, 0.0) },
}

Layout.evidenceNodes = {
	{ name = "EvidenceNode_1", roomId = "SecurityRoom", position = v3(769.56, 2.0, -30.44) },
	{ name = "EvidenceNode_2", roomId = "Lobby", position = v3(805.03, 2.0, -30.44) },
	{ name = "EvidenceNode_3", roomId = "Storage", position = v3(822.89, 2.0, -21.63) },
	{ name = "EvidenceNode_4", roomId = "OfficeA", position = v3(778.37, 2.0, -3.78) },
	{ name = "EvidenceNode_5", roomId = "Lobby", position = v3(796.22, 2.0, -3.78) },
	{ name = "EvidenceNode_6", roomId = "ElectricalRoom", position = v3(831.70, 2.0, 5.03) },
	{ name = "EvidenceNode_7", roomId = "OfficeB", position = v3(769.56, 2.0, 22.89) },
	{ name = "EvidenceNode_8", roomId = "ServerRoom", position = v3(778.37, 14.0, -30.44) },
	{ name = "EvidenceNode_9", roomId = "MeetingRoom", position = v3(796.22, 14.0, -21.63) },
}

Layout.doors = {
	{ objectId = "Door_Lobby", label = "Pintu Depan", roomId = "Lobby", proxyPosition = v3(800.0, 3.5, -5.25), mode = "Swing", advanceFromPreparation = true },
	{ objectId = "Door_SecurityRoom", label = "Pintu Security", roomId = "SecurityRoom", proxyPosition = v3(778.75, 3.5, -20.0), mode = "Swing" },
	{ objectId = "Door_Storage", label = "Pintu Storage", roomId = "Storage", proxyPosition = v3(820.25, 3.5, -20.0), mode = "Swing" },
	{ objectId = "Door_ElectricalRoom", label = "Pintu Electrical", roomId = "ElectricalRoom", proxyPosition = v3(821.25, 3.5, 10.0), mode = "Swing" },
	{ objectId = "Door_OfficeA", label = "Pintu Office A", roomId = "OfficeA", proxyPosition = v3(779.75, 3.5, 15.0), mode = "Swing" },
	{ objectId = "Door_OfficeB", label = "Pintu Office B", roomId = "OfficeB", proxyPosition = v3(779.75, 3.5, 35.0), mode = "Swing" },
	{ objectId = "Door_Bathroom1", label = "Pintu Bathroom 1", roomId = "Bathroom1", proxyPosition = v3(822.25, 3.5, 35.0), mode = "Swing" },
	{ objectId = "Door_StaircaseNorth", label = "Pintu Tangga Utara", roomId = "StaircaseNorth", proxyPosition = v3(800.0, 3.5, -43.25), mode = "Swing" },
	{ objectId = "Door_StaircaseSouth", label = "Pintu Tangga Selatan", roomId = "StaircaseSouth", proxyPosition = v3(800.0, 3.5, 43.25), mode = "Swing" },
	{ objectId = "Door_WorkspaceOpen", label = "Pintu Workspace", roomId = "WorkspaceOpen", proxyPosition = v3(800.0, 15.5, 19.75), mode = "Swing" },
	{ objectId = "Door_MeetingRoom", label = "Pintu Meeting", roomId = "MeetingRoom", proxyPosition = v3(813.25, 15.5, -30.0), mode = "Swing" },
	{ objectId = "Door_ServerRoom", label = "Pintu Server", roomId = "ServerRoom", proxyPosition = v3(785.75, 15.5, -30.0), mode = "Swing" },
	{ objectId = "Door_ArchiveRoom", label = "Pintu Archive", roomId = "ArchiveRoom", proxyPosition = v3(814.25, 15.5, 30.0), mode = "Swing" },
	{ objectId = "Door_Bathroom2", label = "Pintu Bathroom 2", roomId = "Bathroom2", proxyPosition = v3(782.75, 15.5, 30.0), mode = "Swing" },
}

Layout.lights = {
	{ objectId = "Light_Lobby", roomId = "Lobby", proxyPosition = v3(800.0, 9.5, -20.0), generated = { kind = "ceiling_light", position = v3(800.0, 9.3, -20.0) } },
	{ objectId = "Light_SecurityRoom", roomId = "SecurityRoom", proxyPosition = v3(770.0, 9.5, -20.0), generated = { kind = "ceiling_light", position = v3(770.0, 9.3, -20.0) } },
	{ objectId = "Light_Storage", roomId = "Storage", proxyPosition = v3(830.0, 9.5, -20.0), generated = { kind = "ceiling_light", position = v3(830.0, 9.3, -20.0) } },
	{ objectId = "Light_ElectricalRoom", roomId = "ElectricalRoom", proxyPosition = v3(830.0, 9.5, 10.0), generated = { kind = "ceiling_light", position = v3(830.0, 9.3, 10.0) } },
	{ objectId = "Light_OfficeA", roomId = "OfficeA", proxyPosition = v3(770.0, 9.5, 15.0), generated = { kind = "ceiling_light", position = v3(770.0, 9.3, 15.0) } },
	{ objectId = "Light_OfficeB", roomId = "OfficeB", proxyPosition = v3(770.0, 9.5, 35.0), generated = { kind = "ceiling_light", position = v3(770.0, 9.3, 35.0) } },
	{ objectId = "Light_Bathroom1", roomId = "Bathroom1", proxyPosition = v3(830.0, 9.5, 35.0), generated = { kind = "ceiling_light", position = v3(830.0, 9.3, 35.0) } },
	{ objectId = "Light_StaircaseNorth", roomId = "StaircaseNorth", proxyPosition = v3(800.0, 9.5, -50.0), generated = { kind = "ceiling_light", position = v3(800.0, 9.3, -50.0) } },
	{ objectId = "Light_StaircaseSouth", roomId = "StaircaseSouth", proxyPosition = v3(800.0, 9.5, 50.0), generated = { kind = "ceiling_light", position = v3(800.0, 9.3, 50.0) } },
	{ objectId = "Light_WorkspaceOpen", roomId = "WorkspaceOpen", proxyPosition = v3(800.0, 21.5, 0.0), generated = { kind = "ceiling_light", position = v3(800.0, 21.3, 0.0) } },
	{ objectId = "Light_MeetingRoom", roomId = "MeetingRoom", proxyPosition = v3(825.0, 21.5, -30.0), generated = { kind = "ceiling_light", position = v3(825.0, 21.3, -30.0) } },
	{ objectId = "Light_ServerRoom", roomId = "ServerRoom", proxyPosition = v3(775.0, 21.5, -30.0), generated = { kind = "ceiling_light", position = v3(775.0, 21.3, -30.0) } },
	{ objectId = "Light_ArchiveRoom", roomId = "ArchiveRoom", proxyPosition = v3(825.0, 21.5, 30.0), generated = { kind = "ceiling_light", position = v3(825.0, 21.3, 30.0) } },
	{ objectId = "Light_Bathroom2", roomId = "Bathroom2", proxyPosition = v3(775.0, 21.5, 30.0), generated = { kind = "ceiling_light", position = v3(775.0, 21.3, 30.0) } },
}

Layout.props = {
	{ objectId = "Prop_Lobby", roomId = "Lobby", proxyPosition = v3(802.0, 1.0, -18.0), generated = { kind = "prop_box", position = v3(802.0, 1.0, -18.0) } },
	{ objectId = "Prop_SecurityRoom", roomId = "SecurityRoom", proxyPosition = v3(772.0, 1.0, -18.0), generated = { kind = "prop_box", position = v3(772.0, 1.0, -18.0) } },
	{ objectId = "Prop_Storage", roomId = "Storage", proxyPosition = v3(832.0, 1.0, -18.0), generated = { kind = "prop_crate", position = v3(832.0, 1.0, -18.0) } },
	{ objectId = "Prop_ElectricalRoom", roomId = "ElectricalRoom", proxyPosition = v3(832.0, 1.0, 12.0), generated = { kind = "prop_crate", position = v3(832.0, 1.0, 12.0) } },
	{ objectId = "Prop_OfficeA", roomId = "OfficeA", proxyPosition = v3(772.0, 1.0, 17.0), generated = { kind = "prop_box", position = v3(772.0, 1.0, 17.0) } },
	{ objectId = "Prop_OfficeB", roomId = "OfficeB", proxyPosition = v3(772.0, 1.0, 37.0), generated = { kind = "prop_box", position = v3(772.0, 1.0, 37.0) } },
	{ objectId = "Prop_Bathroom1", roomId = "Bathroom1", proxyPosition = v3(832.0, 1.0, 37.0), generated = { kind = "prop_box", position = v3(832.0, 1.0, 37.0) } },
	{ objectId = "Prop_StaircaseNorth", roomId = "StaircaseNorth", proxyPosition = v3(802.0, 1.0, -48.0), generated = { kind = "prop_crate", position = v3(802.0, 1.0, -48.0) } },
	{ objectId = "Prop_StaircaseSouth", roomId = "StaircaseSouth", proxyPosition = v3(802.0, 1.0, 52.0), generated = { kind = "prop_crate", position = v3(802.0, 1.0, 52.0) } },
	{ objectId = "Prop_WorkspaceOpen", roomId = "WorkspaceOpen", proxyPosition = v3(802.0, 13.0, 2.0), generated = { kind = "prop_box", position = v3(802.0, 13.0, 2.0) } },
	{ objectId = "Prop_MeetingRoom", roomId = "MeetingRoom", proxyPosition = v3(827.0, 13.0, -28.0), generated = { kind = "prop_box", position = v3(827.0, 13.0, -28.0) } },
	{ objectId = "Prop_ServerRoom", roomId = "ServerRoom", proxyPosition = v3(777.0, 13.0, -28.0), generated = { kind = "prop_box", position = v3(777.0, 13.0, -28.0) } },
	{ objectId = "Prop_ArchiveRoom", roomId = "ArchiveRoom", proxyPosition = v3(827.0, 13.0, 32.0), generated = { kind = "prop_box", position = v3(827.0, 13.0, 32.0) } },
	{ objectId = "Prop_Bathroom2", roomId = "Bathroom2", proxyPosition = v3(777.0, 13.0, 32.0), generated = { kind = "prop_box", position = v3(777.0, 13.0, 32.0) } },
}

Layout.electronics = {
	{ objectId = "Panel_Lobby", roomId = "Lobby", proxyPosition = v3(788.0, 1.5, -13.0), generated = { kind = "radio", position = v3(788.0, 1.5, -13.0) } },
	{ objectId = "Panel_SecurityRoom", roomId = "SecurityRoom", proxyPosition = v3(774.0, 1.5, -23.0), generated = { kind = "radio", position = v3(774.0, 1.5, -23.0) } },
	{ objectId = "Panel_ElectricalRoom", roomId = "ElectricalRoom", proxyPosition = v3(834.0, 1.5, 6.5), generated = { kind = "radio", position = v3(834.0, 1.5, 6.5) } },
	{ objectId = "TV_WorkspaceOpen", roomId = "WorkspaceOpen", proxyPosition = v3(814.5, 13.5, -9.5), generated = { kind = "tv", position = v3(814.5, 13.5, -9.5) } },
	{ objectId = "Panel_ServerRoom", roomId = "ServerRoom", proxyPosition = v3(780.0, 13.5, -34.0), generated = { kind = "radio", position = v3(780.0, 13.5, -34.0) } },
	{ objectId = "TV_ArchiveRoom", roomId = "ArchiveRoom", proxyPosition = v3(820.0, 13.5, 34.0), generated = { kind = "tv", position = v3(820.0, 13.5, 34.0) } },
}

Layout.windows = {
	{ objectId = "Window_N_1_0", roomId = "StaircaseNorth", proxyPosition = v3(760.0, 6.0, -49.4), mode = "Knock" },
	{ objectId = "Window_S_1_0", roomId = "StaircaseSouth", proxyPosition = v3(760.0, 6.0, 49.4), mode = "Knock" },
	{ objectId = "Window_N_1_2", roomId = "Lobby", proxyPosition = v3(800.0, 6.0, -49.4), mode = "Knock" },
	{ objectId = "Window_S_1_2", roomId = "Lobby", proxyPosition = v3(800.0, 6.0, 49.4), mode = "Knock" },
	{ objectId = "Window_N_1_4", roomId = "Storage", proxyPosition = v3(840.0, 6.0, -49.4), mode = "Knock" },
	{ objectId = "Window_S_1_4", roomId = "Bathroom1", proxyPosition = v3(840.0, 6.0, 49.4), mode = "Knock" },
	{ objectId = "Window_N_2_0", roomId = "ServerRoom", proxyPosition = v3(760.0, 18.0, -49.4), mode = "Knock" },
	{ objectId = "Window_S_2_0", roomId = "Bathroom2", proxyPosition = v3(760.0, 18.0, 49.4), mode = "Knock" },
	{ objectId = "Window_N_2_2", roomId = "WorkspaceOpen", proxyPosition = v3(800.0, 18.0, -49.4), mode = "Knock" },
	{ objectId = "Window_S_2_2", roomId = "WorkspaceOpen", proxyPosition = v3(800.0, 18.0, 49.4), mode = "Knock" },
	{ objectId = "Window_N_2_4", roomId = "ArchiveRoom", proxyPosition = v3(840.0, 18.0, -49.4), mode = "Knock" },
	{ objectId = "Window_S_2_4", roomId = "ArchiveRoom", proxyPosition = v3(840.0, 18.0, 49.4), mode = "Knock" },
}

Layout.roomIds = {}
Layout.roomIndex = {}
for _, room in ipairs(Layout.rooms) do
	Layout.roomIds[#Layout.roomIds + 1] = room.roomId
	Layout.roomIndex[room.roomId] = room
end

Layout.floorRoomCount = {
	floor1 = 9,
	floor2 = 5,
}

return Layout

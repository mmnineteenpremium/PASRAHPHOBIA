local function resolveNamedModule(container, childName)
    local fallbackMainModule = nil

    for _, child in ipairs(container:GetChildren()) do
        if child.Name == childName then
            if child:IsA("ModuleScript") then
                return child
            end

            if child:IsA("Folder") then
                local mainModule = child:FindFirstChild("Main")
                if mainModule and mainModule:IsA("ModuleScript") then
                    fallbackMainModule = mainModule
                end
            end
        end
    end

    return fallbackMainModule
end

local function requireNamedModule(container, childName)
    local moduleScript = resolveNamedModule(container, childName)
    if not moduleScript then
        error(string.format("[LobbyService] Missing module child: %s", childName))
    end

    return require(moduleScript)
end

local LobbyPlayerManager = requireNamedModule(script.Parent, "LobbyPlayerManager")
local LobbyZoneManager = requireNamedModule(script.Parent, "LobbyZoneManager")
local LobbyInteraction = requireNamedModule(script.Parent, "LobbyInteraction")
local PartySystem = requireNamedModule(script.Parent, "PartySystem")
local LobbyPopulationController = requireNamedModule(script.Parent, "LobbyPopulationController")
local LobbyLocator = require(script.Parent.Parent.Core.LobbyLocator)
local Services = require(script.Parent.Parent.Core.Services)

local LOBBY_COSMETIC_FOLDER_NAME = "LobbyCosmeticVisuals"
local LOBBY_COSMETIC_GUI_NAME = "LobbyCosmeticBillboard"
local FLEX_SPOTLIGHT_PARTICIPANT_LIMIT = 4
local LOBBY_ZONE_GUIDE_FOLDER_NAME = "LobbyZoneGuideRuntime"
local LOBBY_ZONE_GUIDE_BILLBOARD_NAME = "Billboard"
local LOBBY_ZONE_GUIDE_HIGHLIGHT_NAME = "Highlight"
local LOBBY_ZONE_ENTRY_GUIDE_FOLDER_NAME = "LobbyZoneEntryGuideRuntime"
local LOBBY_ZONE_ENTRY_GUIDE_BILLBOARD_NAME = "Billboard"
local LOBBY_ZONE_ENTRY_GUIDE_HIGHLIGHT_NAME = "Highlight"
local LOBBY_ZONE_ENTRY_GUIDE_ACCENT_NAME = "AccentBar"
local LOBBY_ZONE_ENTRY_GUIDE_LIGHT_NAME = "AccentLight"
local LOBBY_ZONE_ENTRY_GUIDE_FRAME_TOP_NAME = "FrameTop"
local LOBBY_ZONE_ENTRY_GUIDE_FRAME_LEFT_NAME = "FrameLeft"
local LOBBY_ZONE_ENTRY_GUIDE_FRAME_RIGHT_NAME = "FrameRight"
local LOBBY_ZONE_ENTRY_GUIDE_HEADER_NAME = "HeaderBand"
local LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_BOARD_NAME = "ContractBoard"
local LOBBY_ZONE_ENTRY_GUIDE_TOOLS_BOARD_NAME = "ToolsBoard"
local LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME = "BoardFrontSurface"
local LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME = "BoardBackSurface"
local LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_STAND_NAME = "ContractStand"
local LOBBY_ZONE_ENTRY_GUIDE_TOOLS_STAND_NAME = "ToolsStand"
local LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_BASE_NAME = "ContractBase"
local LOBBY_ZONE_ENTRY_GUIDE_TOOLS_BASE_NAME = "ToolsBase"
local LOBBY_ZONE_ENTRY_GUIDE_CENTER_BOARD_NAME = "CenterBoard"
local LOBBY_ZONE_ENTRY_GUIDE_CENTER_STAND_NAME = "CenterStand"
local LOBBY_ZONE_ENTRY_GUIDE_CENTER_BASE_NAME = "CenterBase"
local LOBBY_ZONE_ENTRY_GUIDE_CENTER_DESK_NAME = "CenterDesk"
local LOBBY_ZONE_ENTRY_GUIDE_CENTER_DESK_TOP_NAME = "CenterDeskTop"
local LOBBY_ZONE_ENTRY_GUIDE_LEFT_CASE_NAME = "LeftDisplayCase"
local LOBBY_ZONE_ENTRY_GUIDE_RIGHT_CASE_NAME = "RightDisplayCase"
local LOBBY_ZONE_ENTRY_GUIDE_CENTER_BACKDROP_NAME = "CenterBackdrop"
local LOBBY_ZONE_ENTRY_GUIDE_FLOOR_RUNNER_NAME = "FloorRunner"
local LOBBY_ZONE_ENTRY_GUIDE_LEFT_CASE_STRIP_NAME = "LeftCaseAccentStrip"
local LOBBY_ZONE_ENTRY_GUIDE_RIGHT_CASE_STRIP_NAME = "RightCaseAccentStrip"
local LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_CLIPBOARD_NAME = "ContractClipboard"
local LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_PAPER_NAME = "ContractPaper"
local LOBBY_ZONE_ENTRY_GUIDE_ROOM_LEDGER_NAME = "RoomLedger"
local LOBBY_ZONE_ENTRY_GUIDE_ROOM_CARDS_NAME = "RoomCards"
local LOBBY_ZONE_ENTRY_GUIDE_TOOL_EMF_NAME = "ToolDisplayEMF"
local LOBBY_ZONE_ENTRY_GUIDE_TOOL_UV_NAME = "ToolDisplayUV"
local LOBBY_ZONE_ENTRY_GUIDE_TOOL_BOX_NAME = "ToolDisplayBox"
local LOBBY_ZONE_ENTRY_GUIDE_DESK_MAP_PLATE_NAME = "DeskMapPlate"
local LOBBY_ZONE_ENTRY_GUIDE_DESK_MODE_PLATE_NAME = "DeskModePlate"
local LOBBY_ZONE_ENTRY_GUIDE_DESK_START_PLATE_NAME = "DeskStartPlate"
local LOBBY_ZONE_ENTRY_GUIDE_FORECOURT_PAD_NAME = "ForecourtPad"
local LOBBY_ZONE_ENTRY_GUIDE_LEFT_BENCH_NAME = "LeftBench"
local LOBBY_ZONE_ENTRY_GUIDE_RIGHT_BENCH_NAME = "RightBench"
local LOBBY_ZONE_ENTRY_GUIDE_LEFT_PLANTER_NAME = "LeftPlanter"
local LOBBY_ZONE_ENTRY_GUIDE_RIGHT_PLANTER_NAME = "RightPlanter"
local LOBBY_ZONE_ENTRY_GUIDE_LEFT_PLANTER_TOP_NAME = "LeftPlanterTop"
local LOBBY_ZONE_ENTRY_GUIDE_RIGHT_PLANTER_TOP_NAME = "RightPlanterTop"
local LOBBY_ZONE_ENTRY_GUIDE_ZONE_COUNTER_NAME = "ZoneCounter"
local LOBBY_ZONE_ENTRY_GUIDE_ZONE_COUNTER_TOP_NAME = "ZoneCounterTop"
local LOBBY_ZONE_ENTRY_GUIDE_ZONE_LEFT_DISPLAY_NAME = "ZoneLeftDisplay"
local LOBBY_ZONE_ENTRY_GUIDE_ZONE_RIGHT_DISPLAY_NAME = "ZoneRightDisplay"
local LOBBY_ZONE_ENTRY_GUIDE_ZONE_PRIMARY_PROP_NAME = "ZonePrimaryProp"
local LOBBY_ZONE_ENTRY_GUIDE_ZONE_SECONDARY_PROP_NAME = "ZoneSecondaryProp"
local LOBBY_MAINHUB_DECOR_FOLDER_NAME = "MainHubDecorRuntime"
local LOBBY_MAINHUB_DIRECTORY_PAD_NAME = "DirectoryPad"
local LOBBY_MAINHUB_DIRECTORY_PILLAR_NAME = "DirectoryPillar"
local LOBBY_MAINHUB_DIRECTORY_PANEL_NAME = "DirectoryPanel"
local LOBBY_MAINHUB_ROUTE_NORTH_NAME = "RouteNorth"
local LOBBY_MAINHUB_ROUTE_EAST_NAME = "RouteEast"
local LOBBY_MAINHUB_ROUTE_WEST_NAME = "RouteWest"
local LOBBY_MAINHUB_ROUTE_SOUTH_NAME = "RouteSouth"
local LOBBY_MAINHUB_ROUTE_FLEX_NAME = "RouteFlex"
local LOBBY_MAINHUB_NODE_NORTH_NAME = "NodeNorth"
local LOBBY_MAINHUB_NODE_EAST_NAME = "NodeEast"
local LOBBY_MAINHUB_NODE_WEST_NAME = "NodeWest"
local LOBBY_MAINHUB_NODE_SOUTH_NAME = "NodeSouth"
local LOBBY_MAINHUB_NODE_FLEX_NAME = "NodeFlex"
local LOBBY_MAINHUB_PLANTER_NW_NAME = "HubPlanterNorthWest"
local LOBBY_MAINHUB_PLANTER_NE_NAME = "HubPlanterNorthEast"
local LOBBY_MAINHUB_PLANTER_SW_NAME = "HubPlanterSouthWest"
local LOBBY_MAINHUB_PLANTER_SE_NAME = "HubPlanterSouthEast"
local LOBBY_MAINHUB_PLANTER_NW_TOP_NAME = "HubPlanterNorthWestTop"
local LOBBY_MAINHUB_PLANTER_NE_TOP_NAME = "HubPlanterNorthEastTop"
local LOBBY_MAINHUB_PLANTER_SW_TOP_NAME = "HubPlanterSouthWestTop"
local LOBBY_MAINHUB_PLANTER_SE_TOP_NAME = "HubPlanterSouthEastTop"
local LOBBY_MAINHUB_WALL_NW_NAME = "HubWallNorthWest"
local LOBBY_MAINHUB_WALL_NE_NAME = "HubWallNorthEast"
local LOBBY_MAINHUB_WALL_SW_NAME = "HubWallSouthWest"
local LOBBY_MAINHUB_WALL_SE_NAME = "HubWallSouthEast"
local LOBBY_ZONE_ENTRY_GUIDE_SIGN_PANEL_NAME = "EntrySignPanel"
local LOBBY_ZONE_ENTRY_GUIDE_CANOPY_NAME = "FacadeCanopy"
local LOBBY_ZONE_ENTRY_GUIDE_APRON_NAME = "FacadeApron"
local LOBBY_ZONE_ENTRY_GUIDE_WING_LEFT_NAME = "FacadeWingLeft"
local LOBBY_ZONE_ENTRY_GUIDE_WING_RIGHT_NAME = "FacadeWingRight"
local LOBBY_ZONE_ENTRY_GUIDE_WINDOW_LEFT_NAME = "FacadeWindowLeft"
local LOBBY_ZONE_ENTRY_GUIDE_WINDOW_RIGHT_NAME = "FacadeWindowRight"
local LOBBY_ZONE_ENTRY_GUIDE_LAMP_LEFT_NAME = "FacadeLampLeft"
local LOBBY_ZONE_ENTRY_GUIDE_LAMP_RIGHT_NAME = "FacadeLampRight"
local FACADE_SIGN_ZONE_FLAGS = {
    MatchmakingZone = true,
    ShopZone = true,
    PartyZone = true,
    DailyRewardZone = true,
    FlexZone = true,
}
local LOBBY_ZONE_GUIDES_ENABLED = false
local LOBBY_ZONE_ENTRY_GUIDES_ENABLED = false
local LOBBY_LOGIC_VOLUME_TRANSPARENCY = 1
local LOBBY_LOGIC_VOLUME_FOLDER_NAMES = {
	"Rooms",
	"SafeZones",
	"InteractionPoints",
	"NavigationNodes",
	"SpawnPoints",
}
local LOBBY_MAINHUB_VISUAL_PATCH = {
	Roof_MainHubPlaza = {
		transparency = 0.52,
		color = Color3.fromRGB(88, 96, 108),
		castShadow = false,
	},
	Floor_1_Main = {
		color = Color3.fromRGB(84, 94, 108),
	},
	Wall_MainHubPlaza_North = {
		transparency = 1,
		castShadow = false,
		canCollide = false,
		canQuery = false,
		canTouch = false,
	},
	Wall_MainHubPlaza_South = {
		transparency = 1,
		castShadow = false,
		canCollide = false,
		canQuery = false,
		canTouch = false,
	},
	Wall_MainHubPlaza_East = {
		transparency = 1,
		castShadow = false,
		canCollide = false,
		canQuery = false,
		canTouch = false,
	},
	Wall_MainHubPlaza_West = {
		transparency = 1,
		castShadow = false,
		canCollide = false,
		canQuery = false,
		canTouch = false,
	},
}
local LOBBY_EXTERIOR_VISUAL_PATCH = {
	Door_NorthEvidenceBuilding = {
		color = Color3.fromRGB(102, 132, 168),
		material = Enum.Material.Metal,
		transparency = 0.04,
	},
	Door_NorthEvidenceBuilding_FrameL = {
		color = Color3.fromRGB(148, 188, 255),
		material = Enum.Material.Neon,
		transparency = 0.16,
	},
	Door_NorthEvidenceBuilding_FrameTop = {
		color = Color3.fromRGB(148, 188, 255),
		material = Enum.Material.Neon,
		transparency = 0.16,
	},
	Door_NorthEvidenceBuilding_FrameR = {
		color = Color3.fromRGB(148, 188, 255),
		material = Enum.Material.Neon,
		transparency = 0.16,
	},
	Wall_NorthEvidenceBuilding_South_R = {
		transparency = 1,
		canCollide = false,
		canQuery = false,
		canTouch = false,
		castShadow = false,
	},
	Wall_NorthEvidenceBuilding_South_L = {
		transparency = 1,
		canCollide = false,
		canQuery = false,
		canTouch = false,
		castShadow = false,
	},
	Wall_NorthEvidenceBuilding_West = {
		color = Color3.fromRGB(64, 76, 94),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_NorthEvidenceBuilding_East = {
		color = Color3.fromRGB(64, 76, 94),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_NorthEvidenceBuilding_North = {
		color = Color3.fromRGB(56, 68, 84),
		material = Enum.Material.SmoothPlastic,
	},
	Roof_NorthEvidenceBuilding = {
		color = Color3.fromRGB(42, 54, 72),
		material = Enum.Material.Metal,
		transparency = 0.08,
		castShadow = false,
	},
	Door_EastShopBuilding = {
		color = Color3.fromRGB(158, 120, 76),
		material = Enum.Material.Metal,
		transparency = 0.04,
	},
	Door_EastShopBuilding_FrameTop = {
		color = Color3.fromRGB(255, 201, 120),
		material = Enum.Material.Neon,
		transparency = 0.16,
	},
	Door_EastShopBuilding_FrameR = {
		color = Color3.fromRGB(255, 201, 120),
		material = Enum.Material.Neon,
		transparency = 0.16,
	},
	Door_EastShopBuilding_FrameL = {
		color = Color3.fromRGB(255, 201, 120),
		material = Enum.Material.Neon,
		transparency = 0.16,
	},
	Wall_EastShopBuilding_West_R = {
		color = Color3.fromRGB(108, 92, 72),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_EastShopBuilding_West_L = {
		color = Color3.fromRGB(108, 92, 72),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_EastShopBuilding_North = {
		color = Color3.fromRGB(96, 82, 64),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_EastShopBuilding_East = {
		color = Color3.fromRGB(88, 74, 58),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_EastShopBuilding_South = {
		color = Color3.fromRGB(96, 82, 64),
		material = Enum.Material.SmoothPlastic,
	},
	Roof_EastShopBuilding = {
		color = Color3.fromRGB(70, 56, 42),
		material = Enum.Material.Metal,
		transparency = 0.08,
		castShadow = false,
	},
	Door_WestPartyZone = {
		color = Color3.fromRGB(90, 132, 132),
		material = Enum.Material.Metal,
		transparency = 0.04,
	},
	Door_WestPartyZone_FrameL = {
		color = Color3.fromRGB(132, 224, 212),
		material = Enum.Material.Neon,
		transparency = 0.16,
	},
	Door_WestPartyZone_FrameTop = {
		color = Color3.fromRGB(132, 224, 212),
		material = Enum.Material.Neon,
		transparency = 0.16,
	},
	Door_WestPartyZone_FrameR = {
		color = Color3.fromRGB(132, 224, 212),
		material = Enum.Material.Neon,
		transparency = 0.16,
	},
	Wall_WestPartyZone_South = {
		color = Color3.fromRGB(78, 102, 106),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_WestPartyZone_East_L = {
		color = Color3.fromRGB(70, 94, 96),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_WestPartyZone_North = {
		color = Color3.fromRGB(78, 102, 106),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_WestPartyZone_East_R = {
		color = Color3.fromRGB(70, 94, 96),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_WestPartyZone_West = {
		color = Color3.fromRGB(60, 82, 84),
		material = Enum.Material.SmoothPlastic,
	},
	Roof_WestPartyZone = {
		color = Color3.fromRGB(46, 66, 68),
		material = Enum.Material.Metal,
		transparency = 0.08,
		castShadow = false,
	},
	Door_SouthSocialGarden = {
		color = Color3.fromRGB(118, 148, 110),
		material = Enum.Material.Metal,
		transparency = 0.04,
	},
	Door_SouthSocialGarden_FrameTop = {
		color = Color3.fromRGB(152, 228, 166),
		material = Enum.Material.Neon,
		transparency = 0.16,
	},
	Door_SouthSocialGarden_FrameR = {
		color = Color3.fromRGB(152, 228, 166),
		material = Enum.Material.Neon,
		transparency = 0.16,
	},
	Door_SouthSocialGarden_FrameL = {
		color = Color3.fromRGB(152, 228, 166),
		material = Enum.Material.Neon,
		transparency = 0.16,
	},
	Wall_SouthSocialGarden_North_L = {
		color = Color3.fromRGB(82, 104, 82),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_SouthSocialGarden_West = {
		color = Color3.fromRGB(72, 94, 74),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_SouthSocialGarden_East = {
		color = Color3.fromRGB(72, 94, 74),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_SouthSocialGarden_North_R = {
		color = Color3.fromRGB(82, 104, 82),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_SouthSocialGarden_South = {
		color = Color3.fromRGB(64, 82, 64),
		material = Enum.Material.SmoothPlastic,
	},
	Roof_SouthSocialGarden = {
		color = Color3.fromRGB(50, 68, 52),
		material = Enum.Material.Metal,
		transparency = 0.08,
		castShadow = false,
	},
	Door_SouthEastFlexZone = {
		color = Color3.fromRGB(126, 118, 168),
		material = Enum.Material.Metal,
		transparency = 0.04,
	},
	Door_SouthEastFlexZone_FrameR = {
		color = Color3.fromRGB(204, 164, 255),
		material = Enum.Material.Neon,
		transparency = 0.16,
	},
	Door_SouthEastFlexZone_FrameTop = {
		color = Color3.fromRGB(204, 164, 255),
		material = Enum.Material.Neon,
		transparency = 0.16,
	},
	Door_SouthEastFlexZone_FrameL = {
		color = Color3.fromRGB(204, 164, 255),
		material = Enum.Material.Neon,
		transparency = 0.16,
	},
	Wall_SouthEastFlexZone_West_L = {
		color = Color3.fromRGB(88, 82, 118),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_SouthEastFlexZone_East = {
		color = Color3.fromRGB(74, 68, 106),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_SouthEastFlexZone_North = {
		color = Color3.fromRGB(88, 82, 118),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_SouthEastFlexZone_West_R = {
		color = Color3.fromRGB(88, 82, 118),
		material = Enum.Material.SmoothPlastic,
	},
	Wall_SouthEastFlexZone_South = {
		color = Color3.fromRGB(74, 68, 106),
		material = Enum.Material.SmoothPlastic,
	},
	Roof_SouthEastFlexZone = {
		color = Color3.fromRGB(58, 54, 84),
		material = Enum.Material.Metal,
		transparency = 0.08,
		castShadow = false,
	},
}
local LOBBY_LIGHT_FIXTURE_PATCH = {
	Light_MainHubPlaza = {
		color = Color3.fromRGB(198, 220, 255),
		brightness = 2.2,
		range = 52,
	},
	LightSource_MainHubPlaza = {
		color = Color3.fromRGB(188, 216, 255),
		brightness = 1.5,
		range = 42,
	},
	Light_NorthEvidenceBuilding = {
		color = Color3.fromRGB(176, 208, 255),
		brightness = 2,
		range = 42,
	},
	LightSource_NorthEvidenceBuilding = {
		color = Color3.fromRGB(176, 208, 255),
		brightness = 1.4,
		range = 30,
	},
	Light_EastShopBuilding = {
		color = Color3.fromRGB(255, 214, 158),
		brightness = 1.9,
		range = 38,
	},
	LightSource_EastShopBuilding = {
		color = Color3.fromRGB(255, 214, 158),
		brightness = 1.3,
		range = 28,
	},
	Light_WestPartyZone = {
		color = Color3.fromRGB(170, 238, 226),
		brightness = 1.9,
		range = 38,
	},
	LightSource_WestPartyZone = {
		color = Color3.fromRGB(170, 238, 226),
		brightness = 1.3,
		range = 28,
	},
	Light_SouthSocialGarden = {
		color = Color3.fromRGB(182, 238, 188),
		brightness = 2,
		range = 42,
	},
	LightSource_SouthSocialGarden = {
		color = Color3.fromRGB(182, 238, 188),
		brightness = 1.4,
		range = 30,
	},
	Light_SouthEastFlexZone = {
		color = Color3.fromRGB(214, 182, 255),
		brightness = 1.9,
		range = 38,
	},
	LightSource_SouthEastFlexZone = {
		color = Color3.fromRGB(214, 182, 255),
		brightness = 1.3,
		range = 28,
	},
}
local LOBBY_ZONE_FEEDBACK = {
    SpawnPlaza = {
        title = "Lobby plaza aktif.",
        hint = "Semua panel utama tetap bisa diakses dari quick menu tanpa harus menyentuh bangunan tertentu.",
    },
    MatchmakingZone = {
        title = "Area contract & evidence aktif.",
        hint = "Gunakan PLAY atau Room Browser untuk membuat room, lalu pakai bangunan utara sebagai anchor contract board dan training evidence.",
    },
    ShopZone = {
        title = "Area shop aktif.",
        hint = "Buka SHOP untuk melihat item MM/PP/Robux yang memang visible dan compliant.",
    },
    PartyZone = {
        title = "Area party aktif.",
        hint = "Gunakan Room Browser untuk invite, ready, dan kontrol room tanpa sentuhan UI yang membingungkan.",
    },
    FlexZone = {
        title = "Area flex aktif.",
        hint = "Spotlight flex tetap hidup untuk kosmetik lobby, tetapi tidak memaksa panel lain terbuka.",
    },
    DailyRewardZone = {
        title = "Area social garden aktif.",
        hint = "Zona ini dipakai sebagai anchor reward/social sampai pass restruktur visual final selesai.",
    },
}

local LOBBY_ZONE_GUIDE_STYLE = {
    SpawnPlaza = {
        color = Color3.fromRGB(110, 186, 244),
        subtitle = "Hub utama dan quick access",
    },
    MatchmakingZone = {
        color = Color3.fromRGB(132, 186, 255),
        subtitle = "Contract board, evidence training, start match",
    },
    ShopZone = {
        color = Color3.fromRGB(255, 196, 118),
        subtitle = "MM / PP / Robux yang visible",
    },
    PartyZone = {
        color = Color3.fromRGB(142, 214, 198),
        subtitle = "Invite, ready, dan kontrol room",
    },
    FlexZone = {
        color = Color3.fromRGB(214, 146, 255),
        subtitle = "Spotlight kosmetik lobby",
    },
    DailyRewardZone = {
        color = Color3.fromRGB(138, 228, 178),
        subtitle = "Reward dan social anchor",
    },
}

local LOBBY_ZONE_ENTRY_COPY = {
    MatchmakingZone = {
        title = "PLAY",
        subtitle = "Contract board & start match",
        meta = "TOOLS TRAINING • CONTRACT",
    },
    ShopZone = {
        title = "SHOP",
        subtitle = "Masuk ke toko",
    },
    PartyZone = {
        title = "PARTY",
        subtitle = "Masuk ke room party",
    },
    DailyRewardZone = {
        title = "GARDEN",
        subtitle = "Masuk ke social garden",
    },
    FlexZone = {
        title = "FLEX",
        subtitle = "Masuk ke spotlight kosmetik",
    },
}

local LOBBY_ZONE_ENTRY_KIOSK_COPY = {
    ShopZone = {
        title = "SHOP BOARD",
        subtitle = "MM • PP • R$",
    },
    PartyZone = {
        title = "ROOM BOARD",
        subtitle = "Invite • Ready • Join",
    },
    DailyRewardZone = {
        title = "GARDEN BOARD",
        subtitle = "Reward • Social • Claim",
    },
    FlexZone = {
        title = "FLEX BOARD",
        subtitle = "Spotlight • Cosmetics",
    },
}

local LOBBY_ZONE_ENTRY_SECONDARY_COPY = {
    ShopZone = {
        centerTitle = "SHOP COUNTER",
        centerSubtitle = "Bundle • Utility",
        leftTitle = "LOADOUT",
        leftSubtitle = "MM • PP",
        rightTitle = "COSMETIC",
        rightSubtitle = "Preview • Equip",
    },
    PartyZone = {
        centerTitle = "READY DESK",
        centerSubtitle = "Party • Room",
        leftTitle = "CREATE",
        leftSubtitle = "Host • Private",
        rightTitle = "INVITE",
        rightSubtitle = "Join • Friend",
    },
    DailyRewardZone = {
        centerTitle = "GARDEN DESK",
        centerSubtitle = "Reward • Event",
        leftTitle = "DAILY",
        leftSubtitle = "Claim • Reset",
        rightTitle = "SOCIAL",
        rightSubtitle = "Bench • NPC",
    },
    FlexZone = {
        centerTitle = "FLEX DESK",
        centerSubtitle = "Showcase • Promo",
        leftTitle = "SPOTLIGHT",
        leftSubtitle = "Featured • Cosmetic",
        rightTitle = "NEWS",
        rightSubtitle = "Update • Event",
    },
}

local LOBBY_ZONE_ENTRY_ANCHORS = {
    MatchmakingZone = { "Door_NorthEvidenceBuilding", "Interact_NorthEvidenceBuilding" },
    ShopZone = { "Door_EastShopBuilding", "Interact_EastShopBuilding" },
    PartyZone = { "Door_WestPartyZone", "Interact_WestPartyZone" },
    DailyRewardZone = { "Door_SouthSocialGarden", "Interact_SouthSocialGarden" },
    FlexZone = { "Door_SouthEastFlexZone", "Interact_SouthEastFlexZone" },
}

local SLOT_DISPLAY_ORDER = {
    outfit = 1,
    body = 2,
    head = 3,
    accessory = 4,
    emote = 5,
}

local RARITY_COLORS = {
    R1 = Color3.fromRGB(150, 189, 255),
    R2 = Color3.fromRGB(118, 232, 196),
    R3 = Color3.fromRGB(255, 183, 112),
    R4 = Color3.fromRGB(255, 130, 130),
    R5 = Color3.fromRGB(214, 146, 255),
    Common = Color3.fromRGB(150, 189, 255),
    Rare = Color3.fromRGB(118, 232, 196),
    Epic = Color3.fromRGB(255, 183, 112),
    Legendary = Color3.fromRGB(255, 130, 130),
    Mythic = Color3.fromRGB(214, 146, 255),
}

local LobbyService = {}
LobbyService.__index = LobbyService

local function resolveEventBus(deps)
    local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
    if type(eventBus) ~= "table" then
        return nil
    end
    if type(eventBus.Publish) == "function" then
        return eventBus
    end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then
        return eventBus.Service
    end
    return nil
end

local function resolveLobbySystemController(deps)
    local lobbySystem = Services.Get(deps, "LobbySystem")
    if type(lobbySystem) ~= "table" then
        return nil
    end
    if type(lobbySystem.OnRequestRoomBrowserSnapshot) == "function" and type(lobbySystem.OnQueueFromRoomBrowser) == "function" then
        return lobbySystem
    end
    if type(lobbySystem.Controller) == "table" then
        return lobbySystem.Controller
    end
    return nil
end

local function resolveContractService(deps)
    local contractSystem = Services.Get(deps, "ContractSystem")
    if type(contractSystem) ~= "table" then
        return nil
    end
    if type(contractSystem.GetBoardContracts) == "function" then
        return contractSystem
    end
    if type(contractSystem.Service) == "table" and type(contractSystem.Service.GetBoardContracts) == "function" then
        return contractSystem.Service
    end
    return nil
end

local function humanizeLobbyMapId(mapId)
    local raw = tostring(mapId or "")
    if raw == "" then
        return "Unknown"
    end
    raw = raw:gsub("_", " ")
    raw = raw:gsub("(%l)(%u)", "%1 %2")
    return raw
end

local function lobbyPromptColor(zoneName)
    local style = LOBBY_ZONE_GUIDE_STYLE[zoneName]
    if type(style) == "table" and typeof(style.color) == "Color3" then
        return style.color
    end
    return Color3.fromRGB(96, 118, 148)
end

local function safeRequire(moduleScript)
    if not moduleScript then
        return nil
    end
    local ok, result = pcall(require, moduleScript)
    if ok then
        return result
    end
    return nil
end

local function getByPath(root, path)
    local node = root
    for _, segment in ipairs(path or {}) do
        if typeof(node) ~= "Instance" then
            return nil
        end
        node = node:FindFirstChild(segment)
        if not node then
            return nil
        end
    end
    return node
end

local function resolveShopCatalogModule()
    local pathOptions = {
        { "shared", "DataTypes", "ShopCatalog" },
        { "Shared", "DataTypes", "ShopCatalog" },
    }

    local cursor = script
    while cursor do
        for _, path in ipairs(pathOptions) do
            local moduleScript = getByPath(cursor, path)
            if moduleScript then
                return moduleScript
            end
        end
        cursor = cursor.Parent
    end

    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if ok and typeof(replicatedStorage) == "Instance" then
        for _, path in ipairs(pathOptions) do
            local moduleScript = getByPath(replicatedStorage, path)
            if moduleScript then
                return moduleScript
            end
        end
    end

    return nil
end

local function toUserId(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return nil
    end
    return player.UserId
end

local function cloneMap(source)
    local result = {}
    if type(source) ~= "table" then
        return result
    end
    for key, value in pairs(source) do
        result[key] = value
    end
    return result
end

local function cloneArray(source)
    local result = {}
    if type(source) ~= "table" then
        return result
    end
    for index, value in ipairs(source) do
        result[index] = value
    end
    return result
end

local function removeArrayValue(source, targetValue)
    if type(source) ~= "table" then
        return
    end
    for index = #source, 1, -1 do
        if source[index] == targetValue then
            table.remove(source, index)
        end
    end
end

local function sanitizeEquippedCosmetics(equippedCosmetics)
    local sanitized = {}
    if type(equippedCosmetics) ~= "table" then
        return sanitized
    end
    for slot, cosmeticId in pairs(equippedCosmetics) do
        if type(slot) == "string" and slot ~= "" and type(cosmeticId) == "string" and cosmeticId ~= "" then
            sanitized[slot] = cosmeticId
        end
    end
    return sanitized
end

local function titleCaseToken(token)
    if token == "" then
        return token
    end
    if #token <= 3 and string.match(token, "^%u+$") then
        return token
    end
    return string.upper(string.sub(token, 1, 1)) .. string.lower(string.sub(token, 2))
end

local function humanizeCosmeticId(cosmeticId)
    local cleaned = tostring(cosmeticId or "")
        :gsub("^cos_", "")
        :gsub("^eq_", "")
        :gsub("^cosmetic_", "")
        :gsub("_", " ")

    local words = {}
    for token in string.gmatch(cleaned, "%S+") do
        table.insert(words, titleCaseToken(token))
    end

    if #words == 0 then
        return "Cosmetic"
    end
    return table.concat(words, " ")
end

local function getCharacterPart(character, partNames)
    if not character then
        return nil
    end
    for _, partName in ipairs(partNames or {}) do
        local candidate = character:FindFirstChild(partName)
        if candidate and candidate:IsA("BasePart") then
            return candidate
        end
    end
    return nil
end

local function createVisualFolder(character)
    local folder = Instance.new("Folder")
    folder.Name = LOBBY_COSMETIC_FOLDER_NAME
    folder.Parent = character
    return folder
end

local function createWeldedVisual(folder, anchorPart, name, props)
    if not folder or not anchorPart then
        return nil
    end

    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = false
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Massless = true
    part.Locked = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Material = props.material or Enum.Material.SmoothPlastic
    part.Transparency = props.transparency or 0
    part.Color = props.color or Color3.fromRGB(255, 255, 255)
    part.Size = props.size or Vector3.new(1, 1, 1)
    part.Shape = props.shape or Enum.PartType.Block
    part.CFrame = anchorPart.CFrame * (props.offset or CFrame.new())
    part.Parent = folder

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = anchorPart
    weld.Part1 = part
    weld.Parent = part

    return part
end

local function chooseRarityColor(rarity, fallback)
    if type(rarity) == "string" and RARITY_COLORS[rarity] then
        return RARITY_COLORS[rarity]
    end
    return fallback
end

local function isLobbyCharacter(player, character)
    return player
        and character
        and player:GetAttribute("InLobby") == true
        and player:GetAttribute("InMatch") ~= true
end

local function clampDisplayNames(entries)
    local names = {}
    for _, entry in ipairs(entries) do
        table.insert(names, entry.name)
        if #names >= 3 then
            break
        end
    end
    return names
end

local function ensureNeonGuidePart(parent, name)
    local part = parent:FindFirstChild(name)
    if not (part and part:IsA("Part")) then
        if part then
            part:Destroy()
        end
        part = Instance.new("Part")
        part.Name = name
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.CastShadow = false
        part.Locked = true
        part.Material = Enum.Material.Neon
        part.Parent = parent
    end
    return part
end

local function ensureGuidePanelPart(parent, name)
    local part = parent:FindFirstChild(name)
    if not (part and part:IsA("Part")) then
        if part then
            part:Destroy()
        end
        part = Instance.new("Part")
        part.Name = name
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.CastShadow = false
        part.Locked = true
        part.Material = Enum.Material.SmoothPlastic
        part.Parent = parent
    end
    return part
end

local function ensurePointLight(parent, name)
    local light = parent:FindFirstChild(name)
    if not (light and light:IsA("PointLight")) then
        if light then
            light:Destroy()
        end
        light = Instance.new("PointLight")
        light.Name = name
        light.Parent = parent
    end
    return light
end

local function clearLegacyBoardGui(parent)
    if not parent then
        return
    end
    local legacy = parent:FindFirstChild("BoardBillboard")
    if legacy then
        legacy:Destroy()
    end
end

local function ensureGuideBoardSurface(parent, name, face, titleText, subtitleText, accentColor)
    local surface = parent:FindFirstChild(name)
    if not (surface and surface:IsA("SurfaceGui")) then
        if surface then
            surface:Destroy()
        end
        surface = Instance.new("SurfaceGui")
        surface.Name = name
        surface.Parent = parent
    end

    surface.Active = false
    surface.Adornee = parent
    surface.AlwaysOnTop = false
    surface.Brightness = 1
    surface.LightInfluence = 0
    surface.ClipsDescendants = true
    surface.ResetOnSpawn = false
    surface.Face = face
    surface.PixelsPerStud = 40
    surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    surface.CanvasSize = Vector2.new(220, 150)

    local panel = surface:FindFirstChild("Panel")
    if not (panel and panel:IsA("Frame")) then
        if panel then
            panel:Destroy()
        end
        panel = Instance.new("Frame")
        panel.Name = "Panel"
        panel.Parent = surface

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = panel

        local stroke = Instance.new("UIStroke")
        stroke.Name = "Stroke"
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Thickness = 1
        stroke.Parent = panel

        local accent = Instance.new("Frame")
        accent.Name = "Accent"
        accent.AnchorPoint = Vector2.new(0, 0.5)
        accent.BorderSizePixel = 0
        accent.Position = UDim2.new(0, 8, 0.5, 0)
        accent.Size = UDim2.fromOffset(3, 36)
        accent.Parent = panel

        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(1, 0)
        accentCorner.Parent = accent

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.BackgroundTransparency = 1
        title.BorderSizePixel = 0
        title.Font = Enum.Font.GothamBold
        title.Text = titleText
        title.TextColor3 = Color3.fromRGB(245, 248, 252)
        title.TextSize = 20
        title.TextTransparency = 0
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextYAlignment = Enum.TextYAlignment.Center
        title.Position = UDim2.new(0, 22, 0, 18)
        title.Size = UDim2.new(1, -34, 0, 30)
        title.Parent = panel

        local subtitle = Instance.new("TextLabel")
        subtitle.Name = "Subtitle"
        subtitle.BackgroundTransparency = 1
        subtitle.BorderSizePixel = 0
        subtitle.Font = Enum.Font.GothamMedium
        subtitle.Text = subtitleText
        subtitle.TextColor3 = accentColor:Lerp(Color3.fromRGB(245, 248, 252), 0.25)
        subtitle.TextSize = 14
        subtitle.TextTransparency = 0
        subtitle.TextWrapped = true
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.TextYAlignment = Enum.TextYAlignment.Top
        subtitle.Position = UDim2.new(0, 22, 0, 54)
        subtitle.Size = UDim2.new(1, -34, 0, 56)
        subtitle.Parent = panel
    end

    panel.Size = UDim2.new(1, -18, 1, -18)
    panel.Position = UDim2.fromOffset(9, 9)
    panel.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
    panel.BackgroundTransparency = 0.08
    panel.BorderSizePixel = 0

    local stroke = panel:FindFirstChild("Stroke")
    if stroke and stroke:IsA("UIStroke") then
        stroke.Color = accentColor
        stroke.Transparency = 0.22
    end
    local accent = panel:FindFirstChild("Accent")
    if accent and accent:IsA("Frame") then
        accent.BackgroundColor3 = accentColor
    end
    local title = panel:FindFirstChild("Title")
    if title and title:IsA("TextLabel") then
        title.Text = titleText
    end
    local subtitle = panel:FindFirstChild("Subtitle")
    if subtitle and subtitle:IsA("TextLabel") then
        subtitle.Text = subtitleText
        subtitle.TextColor3 = accentColor:Lerp(Color3.fromRGB(245, 248, 252), 0.25)
    end

    return surface
end

local function createGuideTextLabel(name, font, textSize, textColor, text, height, position)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Position = position
    label.Size = UDim2.new(1, -18, 0, height)
    label.Font = font
    label.Text = text
    label.TextColor3 = textColor
    label.TextSize = textSize
    label.TextStrokeTransparency = 0.84
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    return label
end

local function sanitizeLobbyLogicPart(part)
	if not (part and part:IsA("BasePart")) then
		return false
	end

	local changed = false
	if part.Transparency ~= LOBBY_LOGIC_VOLUME_TRANSPARENCY then
		part.Transparency = LOBBY_LOGIC_VOLUME_TRANSPARENCY
		changed = true
	end
	if part.CanCollide then
		part.CanCollide = false
		changed = true
	end
	if part.CanTouch then
		part.CanTouch = false
		changed = true
	end
	if part.CanQuery ~= true then
		part.CanQuery = true
		changed = true
	end
	if part.CastShadow then
		part.CastShadow = false
		changed = true
	end
	return changed
end

local function sanitizeLobbyLogicVolumes()
	local lobbyRoot = LobbyLocator.ResolveRoot("LobbySocialHub", workspace)
	if not lobbyRoot then
		return false
	end

	local changed = false
	for _, folderName in ipairs(LOBBY_LOGIC_VOLUME_FOLDER_NAMES) do
		local folder = lobbyRoot:FindFirstChild(folderName, true)
		if folder then
			for _, descendant in ipairs(folder:GetDescendants()) do
				if descendant:IsA("BasePart") then
					changed = sanitizeLobbyLogicPart(descendant) or changed
				end
			end
		end
	end
	return changed
end

local function applyMainHubVisualPatch()
	local lobbyRoot = LobbyLocator.ResolveRoot("LobbySocialHub", workspace)
	if not lobbyRoot then
		return false
	end

	local changed = false
	local function applyStaticVisualPatch(patchTable)
		for partName, patch in pairs(patchTable) do
			local part = lobbyRoot:FindFirstChild(partName, true)
			if part and part:IsA("BasePart") then
				if patch.color and part.Color ~= patch.color then
					part.Color = patch.color
					changed = true
				end
				if patch.material and part.Material ~= patch.material then
					part.Material = patch.material
					changed = true
				end
				if type(patch.transparency) == "number" and part.Transparency ~= patch.transparency then
					part.Transparency = patch.transparency
					changed = true
				end
				if type(patch.castShadow) == "boolean" and part.CastShadow ~= patch.castShadow then
					part.CastShadow = patch.castShadow
					changed = true
				end
				if type(patch.canCollide) == "boolean" and part.CanCollide ~= patch.canCollide then
					part.CanCollide = patch.canCollide
					changed = true
				end
				if type(patch.canQuery) == "boolean" and part.CanQuery ~= patch.canQuery then
					part.CanQuery = patch.canQuery
					changed = true
				end
				if type(patch.canTouch) == "boolean" and part.CanTouch ~= patch.canTouch then
					part.CanTouch = patch.canTouch
					changed = true
				end
			end
		end
	end

	applyStaticVisualPatch(LOBBY_MAINHUB_VISUAL_PATCH)
	applyStaticVisualPatch(LOBBY_EXTERIOR_VISUAL_PATCH)

	for partName, profile in pairs(LOBBY_LIGHT_FIXTURE_PATCH) do
		local part = lobbyRoot:FindFirstChild(partName, true)
		if part and part:IsA("BasePart") then
			if part.Transparency ~= 1 then
				part.Transparency = 1
				changed = true
			end
			if part.CanCollide then
				part.CanCollide = false
				changed = true
			end
			if part.CanQuery then
				part.CanQuery = false
				changed = true
			end
			if part.CanTouch then
				part.CanTouch = false
				changed = true
			end
			local light = ensurePointLight(part, "LobbyRuntimePointLight")
			if light.Color ~= profile.color then
				light.Color = profile.color
				changed = true
			end
			if light.Brightness ~= profile.brightness then
				light.Brightness = profile.brightness
				changed = true
			end
			if light.Range ~= profile.range then
				light.Range = profile.range
				changed = true
			end
			if light.Shadows ~= false then
				light.Shadows = false
				changed = true
			end
			if light.Enabled ~= true then
				light.Enabled = true
				changed = true
			end
		end
	end

    local decorFolder = lobbyRoot:FindFirstChild(LOBBY_MAINHUB_DECOR_FOLDER_NAME)
    if not (decorFolder and decorFolder:IsA("Folder")) then
        if decorFolder then
            decorFolder:Destroy()
        end
        decorFolder = Instance.new("Folder")
        decorFolder.Name = LOBBY_MAINHUB_DECOR_FOLDER_NAME
        decorFolder.Parent = lobbyRoot
        changed = true
    end

    local function ensureDecorPart(name)
        local part = decorFolder:FindFirstChild(name)
        if not (part and part:IsA("Part")) then
            if part then
                part:Destroy()
            end
            part = Instance.new("Part")
            part.Name = name
            part.Anchored = true
            part.CanCollide = false
            part.CanQuery = false
            part.CanTouch = false
            part.CastShadow = false
            part.Locked = true
            part.TopSurface = Enum.SurfaceType.Smooth
            part.BottomSurface = Enum.SurfaceType.Smooth
            part.Parent = decorFolder
            changed = true
        end
        return part
    end

    local function applyPartProps(part, props)
        if not part then
            return
        end
        if part.Size ~= props.size then
            part.Size = props.size
            changed = true
        end
        if part.CFrame ~= props.cframe then
            part.CFrame = props.cframe
            changed = true
        end
        if part.Color ~= props.color then
            part.Color = props.color
            changed = true
        end
        if part.Material ~= (props.material or Enum.Material.SmoothPlastic) then
            part.Material = props.material or Enum.Material.SmoothPlastic
            changed = true
        end
        if part.Transparency ~= (props.transparency or 0) then
            part.Transparency = props.transparency or 0
            changed = true
        end
        if props.shape and part.Shape ~= props.shape then
            part.Shape = props.shape
            changed = true
        end
        if type(props.canCollide) == "boolean" and part.CanCollide ~= props.canCollide then
            part.CanCollide = props.canCollide
            changed = true
        end
        if type(props.canQuery) == "boolean" and part.CanQuery ~= props.canQuery then
            part.CanQuery = props.canQuery
            changed = true
        end
        if type(props.canTouch) == "boolean" and part.CanTouch ~= props.canTouch then
            part.CanTouch = props.canTouch
            changed = true
        end
        if type(props.castShadow) == "boolean" and part.CastShadow ~= props.castShadow then
            part.CastShadow = props.castShadow
            changed = true
        end
    end

    local function ensurePrompt(parent, name)
        local prompt = parent and parent:FindFirstChild(name)
        if not (prompt and prompt:IsA("ProximityPrompt")) then
            if prompt then
                prompt:Destroy()
            end
            prompt = Instance.new("ProximityPrompt")
            prompt.Name = name
            prompt.Parent = parent
            changed = true
        end
        return prompt
    end

    local function applyPrompt(prompt, objectText, actionText, maxDistance)
        if not prompt then
            return
        end
        if prompt.ObjectText ~= objectText then
            prompt.ObjectText = objectText
            changed = true
        end
        if prompt.ActionText ~= actionText then
            prompt.ActionText = actionText
            changed = true
        end
        if prompt.HoldDuration ~= 0 then
            prompt.HoldDuration = 0
            changed = true
        end
        if prompt.MaxActivationDistance ~= maxDistance then
            prompt.MaxActivationDistance = maxDistance
            changed = true
        end
        if prompt.RequiresLineOfSight ~= false then
            prompt.RequiresLineOfSight = false
            changed = true
        end
        if prompt.Enabled ~= true then
            prompt.Enabled = true
            changed = true
        end
        if prompt.KeyboardKeyCode ~= Enum.KeyCode.E then
            prompt.KeyboardKeyCode = Enum.KeyCode.E
            changed = true
        end
    end

    local function applyDecorPointLight(part, name, props)
        local light = ensurePointLight(part, name)
        if light.Color ~= props.color then
            light.Color = props.color
            changed = true
        end
        if light.Brightness ~= props.brightness then
            light.Brightness = props.brightness
            changed = true
        end
        if light.Range ~= props.range then
            light.Range = props.range
            changed = true
        end
        if light.Enabled ~= true then
            light.Enabled = true
            changed = true
        end
        if light.Shadows ~= (props.shadows == true) then
            light.Shadows = props.shadows == true
            changed = true
        end
    end

    local function applyRoutePart(name, startPos, endPos, color)
        local route = ensureDecorPart(name)
        local delta = endPos - startPos
        local length = delta.Magnitude
        applyPartProps(route, {
            size = Vector3.new(6.8, 0.1, length),
            cframe = CFrame.lookAt((startPos + endPos) * 0.5, endPos),
            color = color,
            material = Enum.Material.Neon,
            transparency = 0.08,
        })
    end

    local function applyWalkway(namePrefix, startPos, endPos, width, accentColor)
        local slab = ensureDecorPart(namePrefix .. "Slab")
        local edgeLeft = ensureDecorPart(namePrefix .. "EdgeLeft")
        local edgeRight = ensureDecorPart(namePrefix .. "EdgeRight")
        local delta = endPos - startPos
        local length = delta.Magnitude + 6
        local cframe = CFrame.lookAt((startPos + endPos) * 0.5, endPos)
        applyPartProps(slab, {
            size = Vector3.new(width, 0.16, length),
            cframe = cframe * CFrame.new(0, 0.04, 0),
            color = Color3.fromRGB(30, 42, 58),
            material = Enum.Material.Slate,
            transparency = 0.02,
        })
        applyPartProps(edgeLeft, {
            size = Vector3.new(0.24, 0.18, length),
            cframe = cframe * CFrame.new((width * 0.5) - 0.12, 0.07, 0),
            color = accentColor,
            material = Enum.Material.Neon,
            transparency = 0.16,
        })
        applyPartProps(edgeRight, {
            size = Vector3.new(0.24, 0.18, length),
            cframe = cframe * CFrame.new(-(width * 0.5) + 0.12, 0.07, 0),
            color = accentColor,
            material = Enum.Material.Neon,
            transparency = 0.16,
        })
    end

    local function applyNodePart(name, position, color, title, subtitle)
        local node = ensureDecorPart(name)
        applyPartProps(node, {
            size = Vector3.new(4.6, 0.16, 4.6),
            cframe = CFrame.new(position),
            color = color:Lerp(Color3.fromRGB(255, 255, 255), 0.18),
            material = Enum.Material.Neon,
            transparency = 0.12,
        })
        ensureGuideBoardSurface(node, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Top, title, subtitle, color)
        ensureGuideBoardSurface(node, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, Enum.NormalId.Bottom, title, subtitle, color)
    end

    local function applyBeaconPart(namePrefix, position, lookTarget, color, title, subtitle)
        local post = ensureDecorPart(namePrefix .. "Post")
        local panel = ensureDecorPart(namePrefix .. "Panel")
        local cap = ensureDecorPart(namePrefix .. "Cap")

        applyPartProps(post, {
            size = Vector3.new(0.48, 2.8, 0.48),
            cframe = CFrame.new(position + Vector3.new(0, 1.4, 0)),
            color = Color3.fromRGB(24, 34, 48),
            material = Enum.Material.Metal,
            transparency = 0.03,
        })

        applyPartProps(cap, {
            size = Vector3.new(1.9, 0.18, 0.18),
            cframe = CFrame.lookAt(position + Vector3.new(0, 2.95, 0), lookTarget + Vector3.new(0, 2.95, 0)),
            color = color:Lerp(Color3.fromRGB(255, 255, 255), 0.18),
            material = Enum.Material.Neon,
            transparency = 0.08,
        })

        applyPartProps(panel, {
            size = Vector3.new(2.8, 3.0, 0.28),
            cframe = CFrame.lookAt(position + Vector3.new(0, 2.1, 0), lookTarget + Vector3.new(0, 2.1, 0)),
            color = Color3.fromRGB(14, 22, 34),
            material = Enum.Material.SmoothPlastic,
            transparency = 0.02,
        })

        ensureGuideBoardSurface(panel, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Back, title, subtitle, color)
        ensureGuideBoardSurface(panel, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, Enum.NormalId.Front, title, subtitle, color)
    end

    local function applyHubLamp(namePrefix, position, facing, color)
        local base = ensureDecorPart(namePrefix .. "Base")
        local post = ensureDecorPart(namePrefix .. "Post")
        local lantern = ensureDecorPart(namePrefix .. "Lantern")
        local brace = ensureDecorPart(namePrefix .. "Brace")
        applyPartProps(base, {
            size = Vector3.new(1.5, 0.18, 1.5),
            cframe = CFrame.new(position + Vector3.new(0, 0.09, 0)),
            color = Color3.fromRGB(24, 34, 48),
            material = Enum.Material.Slate,
            transparency = 0.02,
        })
        applyPartProps(post, {
            size = Vector3.new(0.36, 5.8, 0.36),
            cframe = CFrame.new(position + Vector3.new(0, 2.99, 0)),
            color = Color3.fromRGB(34, 44, 58),
            material = Enum.Material.Metal,
            transparency = 0.02,
        })
        applyPartProps(lantern, {
            size = Vector3.new(1.2, 1.2, 1.2),
            cframe = CFrame.new(position + Vector3.new(0, 5.6, 0)),
            color = color:Lerp(Color3.fromRGB(255, 255, 255), 0.18),
            material = Enum.Material.Glass,
            transparency = 0.18,
        })
        applyPartProps(brace, {
            size = Vector3.new(0.18, 0.18, 1.2),
            cframe = CFrame.lookAt(position + Vector3.new(0, 5.05, 0), facing + Vector3.new(0, 5.05, 0)),
            color = color,
            material = Enum.Material.Neon,
            transparency = 0.12,
        })
        applyDecorPointLight(lantern, "Glow", {
            color = color,
            brightness = 1.6,
            range = 24,
        })
    end

    local function applyGatewayWall(name, size, cframe)
        local part = ensureDecorPart(name)
        applyPartProps(part, {
            size = size,
            cframe = cframe,
            color = Color3.fromRGB(74, 88, 108),
            material = Enum.Material.SmoothPlastic,
            transparency = 0.02,
        })
    end

    local function applyGatewayAccent(name, size, cframe, color)
        local part = ensureDecorPart(name)
        applyPartProps(part, {
            size = size,
            cframe = cframe,
            color = color,
            material = Enum.Material.Neon,
            transparency = 0.16,
        })
    end

    local function applyWingLight(name, position, color, range)
        local lamp = ensureDecorPart(name)
        applyPartProps(lamp, {
            size = Vector3.new(0.72, 0.72, 0.72),
            cframe = CFrame.new(position),
            color = color:Lerp(Color3.fromRGB(255, 255, 255), 0.18),
            material = Enum.Material.Glass,
            transparency = 0.1,
        })
        applyDecorPointLight(lamp, "Glow", {
            color = color,
            brightness = 2.3,
            range = range or 24,
        })
    end

    local function applyTree(namePrefix, trunkPos, canopyColor)
        local trunk = ensureDecorPart(namePrefix .. "Trunk")
        local canopy = ensureDecorPart(namePrefix .. "Canopy")
        applyPartProps(trunk, {
            size = Vector3.new(0.9, 4.8, 0.9),
            cframe = CFrame.new(trunkPos + Vector3.new(0, 2.4, 0)),
            color = Color3.fromRGB(84, 64, 46),
            material = Enum.Material.WoodPlanks,
            transparency = 0.02,
        })
        applyPartProps(canopy, {
            size = Vector3.new(4.8, 3.8, 4.8),
            cframe = CFrame.new(trunkPos + Vector3.new(0, 5.7, 0)),
            color = canopyColor,
            material = Enum.Material.Grass,
            transparency = 0.06,
            shape = Enum.PartType.Ball,
        })
    end

    local function applyWingShell(namePrefix, center, width, depth, height, rightVector, forwardVector, palette)
        local floor = ensureDecorPart(namePrefix .. "Floor")
        local backWall = ensureDecorPart(namePrefix .. "BackWall")
        local sideLeft = ensureDecorPart(namePrefix .. "SideLeft")
        local sideRight = ensureDecorPart(namePrefix .. "SideRight")
        local ceiling = ensureDecorPart(namePrefix .. "Ceiling")
        local threshold = ensureDecorPart(namePrefix .. "Threshold")
        local accent = ensureDecorPart(namePrefix .. "Accent")
        local frame = CFrame.fromMatrix(center, rightVector, Vector3.yAxis, forwardVector)

        applyPartProps(floor, {
            size = Vector3.new(width, 0.16, depth),
            cframe = frame * CFrame.new(0, 0.08, 0),
            color = palette.floorColor,
            material = Enum.Material.Slate,
            transparency = 0.02,
        })
        applyPartProps(backWall, {
            size = Vector3.new(width, height, 0.32),
            cframe = frame * CFrame.new(0, height * 0.5, -(depth * 0.5) + 0.16),
            color = palette.wallColor,
            material = Enum.Material.SmoothPlastic,
            transparency = 0.02,
        })
        applyPartProps(sideLeft, {
            size = Vector3.new(0.32, height, depth),
            cframe = frame * CFrame.new(-(width * 0.5) + 0.16, height * 0.5, 0),
            color = palette.sideColor or palette.wallColor,
            material = Enum.Material.SmoothPlastic,
            transparency = 0.02,
        })
        applyPartProps(sideRight, {
            size = Vector3.new(0.32, height, depth),
            cframe = frame * CFrame.new((width * 0.5) - 0.16, height * 0.5, 0),
            color = palette.sideColor or palette.wallColor,
            material = Enum.Material.SmoothPlastic,
            transparency = 0.02,
        })
        applyPartProps(ceiling, {
            size = Vector3.new(width, 0.18, depth),
            cframe = frame * CFrame.new(0, height + 0.09, 0),
            color = palette.ceilingColor or palette.wallColor,
            material = Enum.Material.Metal,
            transparency = 0.08,
        })
        applyPartProps(threshold, {
            size = Vector3.new(width * 0.74, 0.12, 2.2),
            cframe = frame * CFrame.new(0, 0.11, (depth * 0.5) - 1.1),
            color = palette.thresholdColor or palette.floorColor,
            material = Enum.Material.Slate,
            transparency = 0.02,
        })
        applyPartProps(accent, {
            size = Vector3.new(width * 0.76, 0.18, 0.26),
            cframe = frame * CFrame.new(0, height - 0.72, (depth * 0.5) - 0.18),
            color = palette.accentColor,
            material = Enum.Material.Neon,
            transparency = 0.16,
        })
    end

    local function applyWingFrontage(namePrefix, center, width, depth, height, rightVector, forwardVector, accentColor, title, subtitle)
        local frame = CFrame.fromMatrix(center, rightVector, Vector3.yAxis, forwardVector)
        local frontZ = (depth * 0.5) - 0.18
        local openingWidth = math.min(width * 0.42, 18)
        local signWidth = math.min(width * 0.46, 16)
        local sideWallWidth = math.max(((width - openingWidth) * 0.5) - 0.6, 2.4)
        local wallLeft = ensureDecorPart(namePrefix .. "FrontWallLeft")
        local wallRight = ensureDecorPart(namePrefix .. "FrontWallRight")
        local jambLeft = ensureDecorPart(namePrefix .. "EntryJambLeft")
        local jambRight = ensureDecorPart(namePrefix .. "EntryJambRight")
        local header = ensureDecorPart(namePrefix .. "EntryHeader")
        local accent = ensureDecorPart(namePrefix .. "EntryAccent")
        local canopy = ensureDecorPart(namePrefix .. "EntryCanopy")
        local signPanel = ensureDecorPart(namePrefix .. "EntrySignPanel")
        local windowLeft = ensureDecorPart(namePrefix .. "EntryWindowLeft")
        local windowRight = ensureDecorPart(namePrefix .. "EntryWindowRight")
        local lampLeft = ensureDecorPart(namePrefix .. "EntryLampLeft")
        local lampRight = ensureDecorPart(namePrefix .. "EntryLampRight")

        applyPartProps(wallLeft, {
            size = Vector3.new(sideWallWidth, height, 0.34),
            cframe = frame * CFrame.new(-((openingWidth * 0.5) + (sideWallWidth * 0.5) + 0.3), height * 0.5, frontZ),
            color = Color3.fromRGB(58, 70, 88),
            material = Enum.Material.SmoothPlastic,
            transparency = 0.02,
        })
        applyPartProps(wallRight, {
            size = Vector3.new(sideWallWidth, height, 0.34),
            cframe = frame * CFrame.new(((openingWidth * 0.5) + (sideWallWidth * 0.5) + 0.3), height * 0.5, frontZ),
            color = Color3.fromRGB(58, 70, 88),
            material = Enum.Material.SmoothPlastic,
            transparency = 0.02,
        })
        applyPartProps(jambLeft, {
            size = Vector3.new(0.42, height - 0.7, 0.42),
            cframe = frame * CFrame.new(-(openingWidth * 0.5), (height - 0.7) * 0.5, frontZ),
            color = Color3.fromRGB(78, 92, 112),
            material = Enum.Material.Metal,
            transparency = 0.02,
        })
        applyPartProps(jambRight, {
            size = Vector3.new(0.42, height - 0.7, 0.42),
            cframe = frame * CFrame.new(openingWidth * 0.5, (height - 0.7) * 0.5, frontZ),
            color = Color3.fromRGB(78, 92, 112),
            material = Enum.Material.Metal,
            transparency = 0.02,
        })
        applyPartProps(header, {
            size = Vector3.new(openingWidth + 0.9, 0.96, 0.42),
            cframe = frame * CFrame.new(0, height - 0.62, frontZ),
            color = Color3.fromRGB(56, 68, 86),
            material = Enum.Material.Metal,
            transparency = 0.02,
        })
        applyPartProps(accent, {
            size = Vector3.new(openingWidth + 1.6, 0.18, 0.5),
            cframe = frame * CFrame.new(0, height - 0.06, frontZ + 0.02),
            color = accentColor,
            material = Enum.Material.Neon,
            transparency = 0.14,
        })
        applyPartProps(canopy, {
            size = Vector3.new(signWidth + 3.2, 0.2, 3.8),
            cframe = frame * CFrame.new(0, height - 1.86, frontZ + 1.72),
            color = Color3.fromRGB(26, 38, 52),
            material = Enum.Material.Metal,
            transparency = 0.03,
        })
        applyPartProps(signPanel, {
            size = Vector3.new(signWidth, 2.8, 0.24),
            cframe = frame * CFrame.new(0, height - 2.88, frontZ + 0.22),
            color = Color3.fromRGB(12, 20, 32),
            material = Enum.Material.SmoothPlastic,
            transparency = 0.02,
        })
        ensureGuideBoardSurface(signPanel, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Back, title, subtitle, accentColor)
        ensureGuideBoardSurface(signPanel, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, Enum.NormalId.Front, title, subtitle, accentColor)
        applyPartProps(windowLeft, {
            size = Vector3.new(3.4, 2.3, 0.18),
            cframe = frame * CFrame.new(-(openingWidth * 0.5) - 4.2, 1.52, frontZ + 0.08),
            color = accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.12),
            material = Enum.Material.Glass,
            transparency = 0.34,
        })
        applyPartProps(windowRight, {
            size = Vector3.new(3.4, 2.3, 0.18),
            cframe = frame * CFrame.new((openingWidth * 0.5) + 4.2, 1.52, frontZ + 0.08),
            color = accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.12),
            material = Enum.Material.Glass,
            transparency = 0.34,
        })
        applyPartProps(lampLeft, {
            size = Vector3.new(0.3, 2.8, 0.3),
            cframe = frame * CFrame.new(-(openingWidth * 0.5) - 1.6, 1.5, frontZ + 0.56),
            color = accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.16),
            material = Enum.Material.Neon,
            transparency = 0.1,
        })
        applyPartProps(lampRight, {
            size = Vector3.new(0.3, 2.8, 0.3),
            cframe = frame * CFrame.new((openingWidth * 0.5) + 1.6, 1.5, frontZ + 0.56),
            color = accentColor:Lerp(Color3.fromRGB(255, 255, 255), 0.16),
            material = Enum.Material.Neon,
            transparency = 0.1,
        })
        applyDecorPointLight(lampLeft, "Glow", {
            color = accentColor,
            brightness = 1.4,
            range = 18,
        })
        applyDecorPointLight(lampRight, "Glow", {
            color = accentColor,
            brightness = 1.4,
            range = 18,
        })
    end

    local function applyHubPlanter(name, topName, position)
        local planter = ensureDecorPart(name)
        local top = ensureDecorPart(topName)
        applyPartProps(planter, {
            size = Vector3.new(4.2, 1.18, 2.9),
            cframe = CFrame.new(position + Vector3.new(0, 0.59, 0)),
            color = Color3.fromRGB(30, 42, 58),
            material = Enum.Material.Slate,
            transparency = 0.02,
        })
        applyPartProps(top, {
            size = Vector3.new(3.4, 0.38, 2.1),
            cframe = CFrame.new(position + Vector3.new(0, 1.17, 0)),
            color = Color3.fromRGB(98, 138, 102),
            material = Enum.Material.Grass,
            transparency = 0.04,
        })
    end

    local function applyHubWall(name, position, size, lookTarget)
        local wall = ensureDecorPart(name)
        applyPartProps(wall, {
            size = size,
            cframe = CFrame.lookAt(position, lookTarget),
            color = Color3.fromRGB(28, 40, 56),
            material = Enum.Material.Slate,
            transparency = 0.04,
        })
    end

    local hubCenter = Vector3.new(1600, 0.18, -44)
    local northNodePos = Vector3.new(1600, 0.2, -92)
    local eastNodePos = Vector3.new(1658, 0.2, -44)
    local westNodePos = Vector3.new(1542, 0.2, -44)
    local southNodePos = Vector3.new(1600, 0.2, 36)
    local flexNodePos = Vector3.new(1668, 0.2, 84)

    local pad = ensureDecorPart(LOBBY_MAINHUB_DIRECTORY_PAD_NAME)
    applyPartProps(pad, {
        size = Vector3.new(24, 0.18, 24),
        cframe = CFrame.new(hubCenter),
        color = Color3.fromRGB(18, 28, 42),
        material = Enum.Material.Slate,
        transparency = 0.03,
    })

    local queuePlatform = ensureDecorPart("QueuePlatform")
    applyPartProps(queuePlatform, {
        size = Vector3.new(11.6, 0.22, 11.6),
        cframe = CFrame.new(hubCenter + Vector3.new(0, 0.21, 0)),
        color = Color3.fromRGB(24, 38, 58),
        material = Enum.Material.Slate,
        transparency = 0.02,
    })
    local queueRing = ensureDecorPart("QueueRing")
    applyPartProps(queueRing, {
        size = Vector3.new(12.8, 0.1, 12.8),
        cframe = CFrame.new(hubCenter + Vector3.new(0, 0.35, 0)),
        color = Color3.fromRGB(150, 196, 255),
        material = Enum.Material.Neon,
        transparency = 0.18,
    })
    local queueSign = ensureDecorPart("QueueSign")
    applyPartProps(queueSign, {
        size = Vector3.new(7.6, 3.4, 0.32),
        cframe = CFrame.lookAt(hubCenter + Vector3.new(0, 2.4, -10.6), hubCenter + Vector3.new(0, 2.4, 0)),
        color = Color3.fromRGB(14, 22, 34),
        material = Enum.Material.SmoothPlastic,
        transparency = 0.02,
    })
    ensureGuideBoardSurface(queueSign, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Back, "QUEUE HUB", "Match • Party • Start", Color3.fromRGB(150, 196, 255))
    ensureGuideBoardSurface(queueSign, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, Enum.NormalId.Front, "QUEUE HUB", "Match • Party • Start", Color3.fromRGB(150, 196, 255))
    local matchQueuePlatform = ensureDecorPart("MatchQueuePlatform")
    applyPartProps(matchQueuePlatform, {
        size = queuePlatform.Size,
        cframe = queuePlatform.CFrame,
        color = queuePlatform.Color,
        material = queuePlatform.Material,
        transparency = 0.04,
    })
    local queueTrigger = ensureDecorPart("QueueTrigger")
    applyPartProps(queueTrigger, {
        size = Vector3.new(11.6, 5.2, 11.6),
        cframe = CFrame.new(hubCenter + Vector3.new(0, 2.6, 0)),
        color = Color3.fromRGB(150, 196, 255),
        material = Enum.Material.ForceField,
        transparency = 1,
        canCollide = false,
        canQuery = true,
        canTouch = true,
        castShadow = false,
    })
    applyPrompt(ensurePrompt(queueTrigger, "InteractPrompt"), "Queue Hub", "Join Queue", 14)

    local pillar = ensureDecorPart(LOBBY_MAINHUB_DIRECTORY_PILLAR_NAME)
    applyPartProps(pillar, {
        size = Vector3.new(2.6, 6.8, 2.6),
        cframe = CFrame.new(hubCenter + Vector3.new(0, 3.3, 0)),
        color = Color3.fromRGB(26, 38, 54),
        material = Enum.Material.Metal,
        transparency = 0.02,
    })

    local directoryPanel = ensureDecorPart(LOBBY_MAINHUB_DIRECTORY_PANEL_NAME)
    applyPartProps(directoryPanel, {
        size = Vector3.new(15.8, 5.8, 0.35),
        cframe = CFrame.new(hubCenter + Vector3.new(0, 5.1, 2.3)),
        color = Color3.fromRGB(12, 20, 32),
        material = Enum.Material.SmoothPlastic,
        transparency = 0.02,
    })
    ensureGuideBoardSurface(
        directoryPanel,
        LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME,
        Enum.NormalId.Back,
        "LOBBY DIRECTORY",
        "PLAY • NORTH\nSHOP • EAST • PARTY • WEST\nGARDEN • SOUTH • FLEX • SE",
        Color3.fromRGB(150, 196, 255)
    )
    ensureGuideBoardSurface(
        directoryPanel,
        LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME,
        Enum.NormalId.Front,
        "LOBBY DIRECTORY",
        "PLAY • NORTH\nSHOP • EAST • PARTY • WEST\nGARDEN • SOUTH • FLEX • SE",
        Color3.fromRGB(150, 196, 255)
    )

    applyHubPlanter(LOBBY_MAINHUB_PLANTER_NW_NAME, LOBBY_MAINHUB_PLANTER_NW_TOP_NAME, hubCenter + Vector3.new(-9.2, 0, -8.6))
    applyHubPlanter(LOBBY_MAINHUB_PLANTER_NE_NAME, LOBBY_MAINHUB_PLANTER_NE_TOP_NAME, hubCenter + Vector3.new(9.2, 0, -8.6))
    applyHubPlanter(LOBBY_MAINHUB_PLANTER_SW_NAME, LOBBY_MAINHUB_PLANTER_SW_TOP_NAME, hubCenter + Vector3.new(-9.2, 0, 8.6))
    applyHubPlanter(LOBBY_MAINHUB_PLANTER_SE_NAME, LOBBY_MAINHUB_PLANTER_SE_TOP_NAME, hubCenter + Vector3.new(9.2, 0, 8.6))

    applyHubWall(LOBBY_MAINHUB_WALL_NW_NAME, hubCenter + Vector3.new(-4.6, 0.72, -7.8), Vector3.new(6.2, 1.44, 0.52), hubCenter + Vector3.new(-10.2, 0.72, -2.6))
    applyHubWall(LOBBY_MAINHUB_WALL_NE_NAME, hubCenter + Vector3.new(4.6, 0.72, -7.8), Vector3.new(6.2, 1.44, 0.52), hubCenter + Vector3.new(10.2, 0.72, -2.6))
    applyHubWall(LOBBY_MAINHUB_WALL_SW_NAME, hubCenter + Vector3.new(-4.6, 0.72, 7.8), Vector3.new(6.2, 1.44, 0.52), hubCenter + Vector3.new(-10.2, 0.72, 2.6))
    applyHubWall(LOBBY_MAINHUB_WALL_SE_NAME, hubCenter + Vector3.new(4.6, 0.72, 7.8), Vector3.new(6.2, 1.44, 0.52), hubCenter + Vector3.new(10.2, 0.72, 2.6))

    applyWalkway("PathNorth", hubCenter + Vector3.new(0, 0, -11), northNodePos + Vector3.new(0, 0, 9), 13.4, LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color)
    applyWalkway("PathEast", hubCenter + Vector3.new(11, 0, 0), eastNodePos + Vector3.new(-9, 0, 0), 13.4, LOBBY_ZONE_GUIDE_STYLE.ShopZone.color)
    applyWalkway("PathWest", hubCenter + Vector3.new(-11, 0, 0), westNodePos + Vector3.new(9, 0, 0), 13.4, LOBBY_ZONE_GUIDE_STYLE.PartyZone.color)
    applyWalkway("PathSouth", hubCenter + Vector3.new(0, 0, 11), southNodePos + Vector3.new(0, 0, -9), 13.4, LOBBY_ZONE_GUIDE_STYLE.DailyRewardZone.color)
    applyWalkway("PathFlex", southNodePos + Vector3.new(5, 0, 5), flexNodePos + Vector3.new(-7, 0, -7), 11.8, LOBBY_ZONE_GUIDE_STYLE.FlexZone.color)

    applyHubLamp("HubLampNorthWest", hubCenter + Vector3.new(-15.6, 0, -12.8), hubCenter, Color3.fromRGB(188, 216, 255))
    applyHubLamp("HubLampNorthEast", hubCenter + Vector3.new(15.6, 0, -12.8), hubCenter, Color3.fromRGB(188, 216, 255))
    applyHubLamp("HubLampSouthWest", hubCenter + Vector3.new(-15.6, 0, 12.8), hubCenter, Color3.fromRGB(182, 238, 188))
    applyHubLamp("HubLampSouthEast", hubCenter + Vector3.new(15.6, 0, 12.8), hubCenter, Color3.fromRGB(214, 182, 255))
    applyHubLamp("HubLampNorth", hubCenter + Vector3.new(0, 0, -17.6), hubCenter, Color3.fromRGB(150, 196, 255))
    applyHubLamp("HubLampSouth", hubCenter + Vector3.new(0, 0, 17.6), hubCenter, Color3.fromRGB(182, 238, 188))

    applyGatewayWall("MainHubNorthWallLeft", Vector3.new(52, 10, 0.9), CFrame.new(1557, 5, -69.5))
    applyGatewayWall("MainHubNorthWallRight", Vector3.new(52, 10, 0.9), CFrame.new(1643, 5, -69.5))
    applyGatewayWall("MainHubNorthHeader", Vector3.new(35.2, 1.2, 0.9), CFrame.new(1600, 8.4, -69.5))
    applyGatewayWall("MainHubNorthJambLeft", Vector3.new(0.9, 8.8, 0.9), CFrame.new(1582.4, 4.4, -69.5))
    applyGatewayWall("MainHubNorthJambRight", Vector3.new(0.9, 8.8, 0.9), CFrame.new(1617.6, 4.4, -69.5))
    applyGatewayAccent("MainHubNorthAccent", Vector3.new(36, 0.22, 1.02), CFrame.new(1600, 8.98, -69.5), LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color)

    applyGatewayWall("MainHubSouthWallLeft", Vector3.new(52, 10, 0.9), CFrame.new(1557, 5, 69.5))
    applyGatewayWall("MainHubSouthWallRight", Vector3.new(52, 10, 0.9), CFrame.new(1643, 5, 69.5))
    applyGatewayWall("MainHubSouthHeader", Vector3.new(35.2, 1.2, 0.9), CFrame.new(1600, 8.4, 69.5))
    applyGatewayWall("MainHubSouthJambLeft", Vector3.new(0.9, 8.8, 0.9), CFrame.new(1582.4, 4.4, 69.5))
    applyGatewayWall("MainHubSouthJambRight", Vector3.new(0.9, 8.8, 0.9), CFrame.new(1617.6, 4.4, 69.5))
    applyGatewayAccent("MainHubSouthAccent", Vector3.new(36, 0.22, 1.02), CFrame.new(1600, 8.98, 69.5), LOBBY_ZONE_GUIDE_STYLE.DailyRewardZone.color)

    applyGatewayWall("MainHubEastWallTop", Vector3.new(0.9, 10, 52), CFrame.new(1669.5, 5, -43))
    applyGatewayWall("MainHubEastWallBottom", Vector3.new(0.9, 10, 52), CFrame.new(1669.5, 5, 43))
    applyGatewayWall("MainHubEastHeader", Vector3.new(0.9, 1.2, 35.2), CFrame.new(1669.5, 8.4, 0))
    applyGatewayWall("MainHubEastJambTop", Vector3.new(0.9, 8.8, 0.9), CFrame.new(1669.5, 4.4, -17.6))
    applyGatewayWall("MainHubEastJambBottom", Vector3.new(0.9, 8.8, 0.9), CFrame.new(1669.5, 4.4, 17.6))
    applyGatewayAccent("MainHubEastAccent", Vector3.new(1.02, 0.22, 36), CFrame.new(1669.5, 8.98, 0), LOBBY_ZONE_GUIDE_STYLE.ShopZone.color)

    applyGatewayWall("MainHubWestWallTop", Vector3.new(0.9, 10, 52), CFrame.new(1530.5, 5, -43))
    applyGatewayWall("MainHubWestWallBottom", Vector3.new(0.9, 10, 52), CFrame.new(1530.5, 5, 43))
    applyGatewayWall("MainHubWestHeader", Vector3.new(0.9, 1.2, 35.2), CFrame.new(1530.5, 8.4, 0))
    applyGatewayWall("MainHubWestJambTop", Vector3.new(0.9, 8.8, 0.9), CFrame.new(1530.5, 4.4, -17.6))
    applyGatewayWall("MainHubWestJambBottom", Vector3.new(0.9, 8.8, 0.9), CFrame.new(1530.5, 4.4, 17.6))
    applyGatewayAccent("MainHubWestAccent", Vector3.new(1.02, 0.22, 36), CFrame.new(1530.5, 8.98, 0), LOBBY_ZONE_GUIDE_STYLE.PartyZone.color)

    applyWingShell("NorthBay", Vector3.new(1600, 0, -152), 58, 36, 8.6, Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), {
        floorColor = Color3.fromRGB(24, 34, 48),
        wallColor = Color3.fromRGB(42, 54, 72),
        sideColor = Color3.fromRGB(48, 62, 82),
        ceilingColor = Color3.fromRGB(34, 46, 62),
        thresholdColor = Color3.fromRGB(28, 40, 58),
        accentColor = LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color,
    })
    applyWingShell("ShopBay", Vector3.new(1748, 0, -20), 42, 38, 8.4, Vector3.new(0, 0, 1), Vector3.new(-1, 0, 0), {
        floorColor = Color3.fromRGB(34, 26, 20),
        wallColor = Color3.fromRGB(76, 60, 44),
        sideColor = Color3.fromRGB(88, 70, 54),
        ceilingColor = Color3.fromRGB(54, 42, 30),
        thresholdColor = Color3.fromRGB(42, 32, 24),
        accentColor = LOBBY_ZONE_GUIDE_STYLE.ShopZone.color,
    })
    applyWingShell("PartyBay", Vector3.new(1452, 0, -20), 42, 38, 8.4, Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), {
        floorColor = Color3.fromRGB(20, 34, 34),
        wallColor = Color3.fromRGB(52, 76, 78),
        sideColor = Color3.fromRGB(60, 88, 90),
        ceilingColor = Color3.fromRGB(40, 60, 62),
        thresholdColor = Color3.fromRGB(24, 42, 42),
        accentColor = LOBBY_ZONE_GUIDE_STYLE.PartyZone.color,
    })
    applyWingShell("GardenBay", Vector3.new(1600, 0, 160), 54, 34, 8.4, Vector3.new(1, 0, 0), Vector3.new(0, 0, -1), {
        floorColor = Color3.fromRGB(26, 38, 28),
        wallColor = Color3.fromRGB(58, 82, 60),
        sideColor = Color3.fromRGB(64, 92, 68),
        ceilingColor = Color3.fromRGB(40, 60, 44),
        thresholdColor = Color3.fromRGB(30, 44, 32),
        accentColor = LOBBY_ZONE_GUIDE_STYLE.DailyRewardZone.color,
    })
    applyWingShell("FlexBay", Vector3.new(1748, 0, 140), 38, 34, 8.4, Vector3.new(0, 0, 1), Vector3.new(-1, 0, 0), {
        floorColor = Color3.fromRGB(24, 20, 38),
        wallColor = Color3.fromRGB(62, 56, 92),
        sideColor = Color3.fromRGB(72, 64, 106),
        ceilingColor = Color3.fromRGB(40, 34, 62),
        thresholdColor = Color3.fromRGB(28, 24, 44),
        accentColor = LOBBY_ZONE_GUIDE_STYLE.FlexZone.color,
    })
    applyWingFrontage("NorthBay", Vector3.new(1600, 0, -152), 58, 36, 8.6, Vector3.new(1, 0, 0), Vector3.new(0, 0, 1), LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color, "PLAY", "Contract • Tools • Start")
    applyWingFrontage("ShopBay", Vector3.new(1748, 0, -20), 42, 38, 8.4, Vector3.new(0, 0, 1), Vector3.new(-1, 0, 0), LOBBY_ZONE_GUIDE_STYLE.ShopZone.color, "SHOP", "Loadout • Currency • Utility")
    applyWingFrontage("PartyBay", Vector3.new(1452, 0, -20), 42, 38, 8.4, Vector3.new(0, 0, 1), Vector3.new(1, 0, 0), LOBBY_ZONE_GUIDE_STYLE.PartyZone.color, "PARTY", "Invite • Ready • Join")
    applyWingFrontage("GardenBay", Vector3.new(1600, 0, 160), 54, 34, 8.4, Vector3.new(1, 0, 0), Vector3.new(0, 0, -1), LOBBY_ZONE_GUIDE_STYLE.DailyRewardZone.color, "GARDEN", "Daily • Social • Claim")
    applyWingFrontage("FlexBay", Vector3.new(1748, 0, 140), 38, 34, 8.4, Vector3.new(0, 0, 1), Vector3.new(-1, 0, 0), LOBBY_ZONE_GUIDE_STYLE.FlexZone.color, "FLEX", "Spotlight • Cosmetic • News")

    -- North contract / evidence bay
    for _, data in ipairs({
        { name = "Table_Tools_1", pos = Vector3.new(1587, 1.02, -138), label = "EMF", color = Color3.fromRGB(132, 186, 255) },
        { name = "Table_Tools_2", pos = Vector3.new(1600, 1.02, -138), label = "UV", color = Color3.fromRGB(214, 146, 255) },
        { name = "Table_Tools_3", pos = Vector3.new(1613, 1.02, -138), label = "THERMO", color = Color3.fromRGB(142, 214, 198) },
        { name = "Table_Tools_4", pos = Vector3.new(1587, 1.02, -151), label = "BOX", color = Color3.fromRGB(255, 196, 118) },
        { name = "Table_Tools_5", pos = Vector3.new(1600, 1.02, -151), label = "WRITING", color = Color3.fromRGB(150, 189, 255) },
        { name = "Table_Tools_6", pos = Vector3.new(1613, 1.02, -151), label = "CAM", color = Color3.fromRGB(255, 130, 130) },
    }) do
        local tablePart = ensureDecorPart(data.name)
        applyPartProps(tablePart, {
            size = Vector3.new(3.2, 1.02, 2.0),
            cframe = CFrame.new(data.pos),
            color = Color3.fromRGB(28, 40, 56),
            material = Enum.Material.Slate,
            transparency = 0.03,
        })
        ensureGuideBoardSurface(tablePart, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Top, data.label, "Test Table", data.color)
        applyPrompt(ensurePrompt(tablePart, "InteractPrompt"), data.label .. " Table", "Test Tool", 10)
    end
    local northContractWall = ensureDecorPart("ContractBoard")
    applyPartProps(northContractWall, {
        size = Vector3.new(18, 4.8, 0.28),
        cframe = CFrame.new(1600, 4.1, -170.5),
        color = Color3.fromRGB(14, 22, 34),
        material = Enum.Material.SmoothPlastic,
        transparency = 0.02,
    })
    ensureGuideBoardSurface(northContractWall, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Front, "CONTRACT BAY", "Map • Mode • Briefing", LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color)
    applyPrompt(ensurePrompt(northContractWall, "InteractPrompt"), "Contract Board", "Open Board", 12)
    local northRoomStand = ensureDecorPart("RoomBoard")
    applyPartProps(northRoomStand, {
        size = Vector3.new(2.2, 3.4, 2.2),
        cframe = CFrame.new(1575, 2.0, -144),
        color = Color3.fromRGB(24, 34, 48),
        material = Enum.Material.Metal,
        transparency = 0.03,
    })
    ensureGuideBoardSurface(northRoomStand, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Front, "ROOM", "Create • Join • Ready", LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color)
    applyPrompt(ensurePrompt(northRoomStand, "InteractPrompt"), "Room Board", "Open Room Browser", 12)
    local northToolsStand = ensureDecorPart("ToolsBoard")
    applyPartProps(northToolsStand, {
        size = Vector3.new(2.2, 3.4, 2.2),
        cframe = CFrame.new(1625, 2.0, -144),
        color = Color3.fromRGB(24, 34, 48),
        material = Enum.Material.Metal,
        transparency = 0.03,
    })
    ensureGuideBoardSurface(northToolsStand, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Front, "TOOLS", "Train • Equip • Read", LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color)
    applyPrompt(ensurePrompt(northToolsStand, "InteractPrompt"), "Tools Board", "Open Training", 12)
    applyWingLight("NorthWingLight_A", Vector3.new(1588, 7.2, -142), LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color, 24)
    applyWingLight("NorthWingLight_B", Vector3.new(1600, 7.2, -142), LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color, 24)
    applyWingLight("NorthWingLight_C", Vector3.new(1612, 7.2, -142), LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color, 24)
    applyWingLight("NorthWingLight_D", Vector3.new(1588, 7.2, -160), LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color, 22)
    applyWingLight("NorthWingLight_E", Vector3.new(1600, 7.2, -160), LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color, 22)
    applyWingLight("NorthWingLight_F", Vector3.new(1612, 7.2, -160), LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color, 22)

    -- Shop wing
    local shopCounter = ensureDecorPart("ShopCounter")
    applyPartProps(shopCounter, {
        size = Vector3.new(8.8, 1.4, 2.6),
        cframe = CFrame.new(1727, 1.1, -20),
        color = Color3.fromRGB(34, 28, 22),
        material = Enum.Material.Slate,
        transparency = 0.03,
    })
    ensureGuideBoardSurface(shopCounter, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Top, "SHOP", "MM • PP • Utility", LOBBY_ZONE_GUIDE_STYLE.ShopZone.color)
    applyPrompt(ensurePrompt(shopCounter, "InteractPrompt"), "Shop Counter", "Open Shop", 12)
    local interactShop = ensureDecorPart("Interact_Shop")
    applyPartProps(interactShop, {
        size = Vector3.new(3.4, 3.2, 2.8),
        cframe = CFrame.new(1727, 1.8, -16.6),
        color = LOBBY_ZONE_GUIDE_STYLE.ShopZone.color,
        material = Enum.Material.ForceField,
        transparency = 1,
        canCollide = false,
        canQuery = true,
        canTouch = true,
        castShadow = false,
    })
    applyPrompt(ensurePrompt(interactShop, "InteractPrompt"), "Shop", "Browse", 12)
    local shopRack = ensureDecorPart("EquipmentRack")
    applyPartProps(shopRack, {
        size = Vector3.new(1.0, 3.8, 8.4),
        cframe = CFrame.new(1766, 2.0, -20),
        color = Color3.fromRGB(54, 42, 30),
        material = Enum.Material.Metal,
        transparency = 0.03,
    })
    local shopDisplayA = ensureDecorPart("DisplayTable_A")
    applyPartProps(shopDisplayA, {
        size = Vector3.new(2.2, 1.0, 2.4),
        cframe = CFrame.new(1739, 1.0, -33),
        color = Color3.fromRGB(56, 44, 34),
        material = Enum.Material.Slate,
        transparency = 0.03,
    })
    local shopDisplayB = ensureDecorPart("DisplayTable_B")
    applyPartProps(shopDisplayB, {
        size = Vector3.new(2.2, 1.0, 2.4),
        cframe = CFrame.new(1739, 1.0, -7),
        color = Color3.fromRGB(56, 44, 34),
        material = Enum.Material.Slate,
        transparency = 0.03,
    })
    applyWingLight("ShopWingLight_A", Vector3.new(1736, 7.0, -28), LOBBY_ZONE_GUIDE_STYLE.ShopZone.color, 22)
    applyWingLight("ShopWingLight_B", Vector3.new(1736, 7.0, -12), LOBBY_ZONE_GUIDE_STYLE.ShopZone.color, 22)
    applyWingLight("ShopWingLight_C", Vector3.new(1758, 7.0, -28), LOBBY_ZONE_GUIDE_STYLE.ShopZone.color, 20)
    applyWingLight("ShopWingLight_D", Vector3.new(1758, 7.0, -12), LOBBY_ZONE_GUIDE_STYLE.ShopZone.color, 20)

    -- Party wing
    local partyPlatform = ensureDecorPart("PartyPlatform")
    applyPartProps(partyPlatform, {
        size = Vector3.new(6.2, 0.18, 6.2),
        cframe = CFrame.new(1456, 0.19, -20),
        color = Color3.fromRGB(24, 40, 40),
        material = Enum.Material.Slate,
        transparency = 0.03,
    })
    local partyBoard = ensureDecorPart("PartyBoard")
    applyPartProps(partyBoard, {
        size = Vector3.new(0.42, 3.8, 6.0),
        cframe = CFrame.new(1469, 2.1, -23),
        color = Color3.fromRGB(16, 26, 34),
        material = Enum.Material.SmoothPlastic,
        transparency = 0.02,
    })
    ensureGuideBoardSurface(partyBoard, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Left, "PARTY", "Invite • Room • Ready", LOBBY_ZONE_GUIDE_STYLE.PartyZone.color)
    applyPrompt(ensurePrompt(partyBoard, "InteractPrompt"), "Party Board", "Open Party", 12)
    local partyTerminal = ensureDecorPart("PartyTerminal")
    applyPartProps(partyTerminal, {
        size = Vector3.new(1.2, 1.5, 1.2),
        cframe = CFrame.new(1458, 1.2, -12),
        color = Color3.fromRGB(32, 48, 52),
        material = Enum.Material.Metal,
        transparency = 0.03,
    })
    applyWingLight("PartyWingLight_A", Vector3.new(1458, 7.0, -28), LOBBY_ZONE_GUIDE_STYLE.PartyZone.color, 22)
    applyWingLight("PartyWingLight_B", Vector3.new(1458, 7.0, -12), LOBBY_ZONE_GUIDE_STYLE.PartyZone.color, 22)
    applyWingLight("PartyWingLight_C", Vector3.new(1440, 7.0, -28), LOBBY_ZONE_GUIDE_STYLE.PartyZone.color, 20)
    applyWingLight("PartyWingLight_D", Vector3.new(1440, 7.0, -12), LOBBY_ZONE_GUIDE_STYLE.PartyZone.color, 20)

    -- Garden wing
    local gardenTerminal = ensureDecorPart("DailyRewardTerminal")
    applyPartProps(gardenTerminal, {
        size = Vector3.new(2.4, 1.46, 1.84),
        cframe = CFrame.new(1600, 1.18, 149),
        color = Color3.fromRGB(28, 40, 30),
        material = Enum.Material.SmoothPlastic,
        transparency = 0.03,
    })
    ensureGuideBoardSurface(gardenTerminal, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Front, "DAILY", "Reward • Claim", LOBBY_ZONE_GUIDE_STYLE.DailyRewardZone.color)
    applyPrompt(ensurePrompt(gardenTerminal, "InteractPrompt"), "Daily Reward", "Claim", 12)
    applyTree("GardenTreeA", Vector3.new(1572, 0, 152), Color3.fromRGB(98, 150, 104))
    applyTree("GardenTreeB", Vector3.new(1628, 0, 170), Color3.fromRGB(98, 150, 104))
    local gardenBenchA = ensureDecorPart("GardenBenchA")
    applyPartProps(gardenBenchA, {
        size = Vector3.new(4.4, 0.62, 1.32),
        cframe = CFrame.new(1578, 0.64, 171),
        color = Color3.fromRGB(84, 64, 46),
        material = Enum.Material.WoodPlanks,
        transparency = 0.02,
    })
    local gardenBenchB = ensureDecorPart("GardenBenchB")
    applyPartProps(gardenBenchB, {
        size = Vector3.new(4.4, 0.62, 1.32),
        cframe = CFrame.new(1622, 0.64, 149),
        color = Color3.fromRGB(84, 64, 46),
        material = Enum.Material.WoodPlanks,
        transparency = 0.02,
    })
    applyWingLight("GardenWingLight_A", Vector3.new(1572, 6.8, 152), LOBBY_ZONE_GUIDE_STYLE.DailyRewardZone.color, 22)
    applyWingLight("GardenWingLight_B", Vector3.new(1628, 6.8, 170), LOBBY_ZONE_GUIDE_STYLE.DailyRewardZone.color, 22)
    applyWingLight("GardenWingLight_C", Vector3.new(1578, 6.8, 166), LOBBY_ZONE_GUIDE_STYLE.DailyRewardZone.color, 20)
    applyWingLight("GardenWingLight_D", Vector3.new(1622, 6.8, 154), LOBBY_ZONE_GUIDE_STYLE.DailyRewardZone.color, 20)

    -- Flex wing
    local flexStage = ensureDecorPart("FlexStage")
    applyPartProps(flexStage, {
        size = Vector3.new(6.2, 0.22, 6.2),
        cframe = CFrame.new(1748, 0.22, 140),
        color = Color3.fromRGB(28, 24, 44),
        material = Enum.Material.Slate,
        transparency = 0.03,
    })
    local flexBoard = ensureDecorPart("AnnouncementBoard")
    applyPartProps(flexBoard, {
        size = Vector3.new(0.42, 3.8, 6.0),
        cframe = CFrame.new(1764, 2.1, 140),
        color = Color3.fromRGB(18, 16, 34),
        material = Enum.Material.SmoothPlastic,
        transparency = 0.02,
    })
    ensureGuideBoardSurface(flexBoard, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Left, "FLEX", "Spotlight • Event", LOBBY_ZONE_GUIDE_STYLE.FlexZone.color)
    local flexPedestalA = ensureDecorPart("FlexWingPedestalA")
    applyPartProps(flexPedestalA, {
        size = Vector3.new(1.3, 1.2, 1.3),
        cframe = CFrame.new(1746, 1.2, 134),
        color = Color3.fromRGB(52, 44, 78),
        material = Enum.Material.Metal,
        transparency = 0.03,
    })
    local flexPedestalB = ensureDecorPart("FlexWingPedestalB")
    applyPartProps(flexPedestalB, {
        size = Vector3.new(1.3, 1.2, 1.3),
        cframe = CFrame.new(1746, 1.2, 146),
        color = Color3.fromRGB(52, 44, 78),
        material = Enum.Material.Metal,
        transparency = 0.03,
    })
    applyWingLight("FlexWingLight_A", Vector3.new(1748, 7.0, 134), LOBBY_ZONE_GUIDE_STYLE.FlexZone.color, 22)
    applyWingLight("FlexWingLight_B", Vector3.new(1748, 7.0, 146), LOBBY_ZONE_GUIDE_STYLE.FlexZone.color, 22)
    applyWingLight("FlexWingLight_C", Vector3.new(1760, 7.0, 134), LOBBY_ZONE_GUIDE_STYLE.FlexZone.color, 20)
    applyWingLight("FlexWingLight_D", Vector3.new(1760, 7.0, 146), LOBBY_ZONE_GUIDE_STYLE.FlexZone.color, 20)

    applyRoutePart(LOBBY_MAINHUB_ROUTE_NORTH_NAME, hubCenter, northNodePos, LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color)
    applyRoutePart(LOBBY_MAINHUB_ROUTE_EAST_NAME, hubCenter, eastNodePos, LOBBY_ZONE_GUIDE_STYLE.ShopZone.color)
    applyRoutePart(LOBBY_MAINHUB_ROUTE_WEST_NAME, hubCenter, westNodePos, LOBBY_ZONE_GUIDE_STYLE.PartyZone.color)
    applyRoutePart(LOBBY_MAINHUB_ROUTE_SOUTH_NAME, hubCenter, southNodePos, LOBBY_ZONE_GUIDE_STYLE.DailyRewardZone.color)
    applyRoutePart(LOBBY_MAINHUB_ROUTE_FLEX_NAME, southNodePos, flexNodePos, LOBBY_ZONE_GUIDE_STYLE.FlexZone.color)

    applyNodePart(LOBBY_MAINHUB_NODE_NORTH_NAME, northNodePos, LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color, "PLAY", "Contract • Evidence")
    applyNodePart(LOBBY_MAINHUB_NODE_EAST_NAME, eastNodePos, LOBBY_ZONE_GUIDE_STYLE.ShopZone.color, "SHOP", "MM • PP • R$")
    applyNodePart(LOBBY_MAINHUB_NODE_WEST_NAME, westNodePos, LOBBY_ZONE_GUIDE_STYLE.PartyZone.color, "PARTY", "Room • Invite")
    applyNodePart(LOBBY_MAINHUB_NODE_SOUTH_NAME, southNodePos, LOBBY_ZONE_GUIDE_STYLE.DailyRewardZone.color, "GARDEN", "Reward • Social")
    applyNodePart(LOBBY_MAINHUB_NODE_FLEX_NAME, flexNodePos, LOBBY_ZONE_GUIDE_STYLE.FlexZone.color, "FLEX", "Cosmetic • Spotlight")

    applyBeaconPart("BeaconNorth", northNodePos + Vector3.new(0, 0, 3.4), hubCenter, LOBBY_ZONE_GUIDE_STYLE.MatchmakingZone.color, "PLAY", "Contract")
    applyBeaconPart("BeaconEast", eastNodePos + Vector3.new(-3.4, 0, 0), hubCenter, LOBBY_ZONE_GUIDE_STYLE.ShopZone.color, "SHOP", "MM • PP • R$")
    applyBeaconPart("BeaconWest", westNodePos + Vector3.new(3.4, 0, 0), hubCenter, LOBBY_ZONE_GUIDE_STYLE.PartyZone.color, "PARTY", "Invite")
    applyBeaconPart("BeaconSouth", southNodePos + Vector3.new(0, 0, -3.4), hubCenter, LOBBY_ZONE_GUIDE_STYLE.DailyRewardZone.color, "GARDEN", "Reward")
    applyBeaconPart("BeaconFlex", flexNodePos + Vector3.new(-2.8, 0, -2.8), southNodePos, LOBBY_ZONE_GUIDE_STYLE.FlexZone.color, "FLEX", "Spotlight")

	return changed
end

function LobbyService.new(state, deps)
    local self = setmetatable({}, LobbyService)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._lobbyController = resolveLobbySystemController(self._deps)
    self._contractService = resolveContractService(self._deps)

    self._playerManager = LobbyPlayerManager.new(self._deps, self._deps.LobbyPlayerManagerConfig)
    self._zoneManager = LobbyZoneManager.new(self._deps, self._deps.LobbyZoneManagerConfig)
    self._interaction = LobbyInteraction.new(self._deps, self._deps.LobbyInteractionConfig)
    self._partySystem = PartySystem.new(self._deps, self._deps.PartySystemConfig)
    self._population = LobbyPopulationController.new(self._state, self._deps, self._deps.LobbyPopulationConfig)
    self._characterConnections = {}
    self._promptConnections = {}
    self._cosmeticCatalogById = {}
    self._dependencies = {}
    return self
end

function LobbyService:_loadCosmeticCatalog()
    local catalog = safeRequire(resolveShopCatalogModule()) or {}
    local catalogById = {}

    for _, entry in pairs(catalog) do
        if type(entry) == "table" and type(entry.id) == "string" and entry.id ~= "" then
            catalogById[entry.id] = entry
        end
    end

    self._cosmeticCatalogById = catalogById
end

function LobbyService:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function LobbyService:_disconnectPromptConnections()
    for _, connection in ipairs(self._promptConnections) do
        connection:Disconnect()
    end
    table.clear(self._promptConnections)
end

function LobbyService:_publishLobbyWorldEvent(player, eventName, zoneName, title, message, extraPayload)
    if not (typeof(player) == "Instance" and player:IsA("Player")) then
        return
    end

    local payload = {
        eventName = eventName,
        recipients = { player },
        zoneName = zoneName,
        title = title,
        message = message,
        accentColor = lobbyPromptColor(zoneName),
    }
    for key, value in pairs(extraPayload or {}) do
        payload[key] = value
    end
    self:_publish(eventName, payload)
end

function LobbyService:_connectWorldPrompt(partName, callback)
    local promptHost = workspace:FindFirstChild(partName, true)
    if not (promptHost and promptHost:IsA("BasePart")) then
        return false
    end

    local prompt = promptHost:FindFirstChild("InteractPrompt")
    if not (prompt and prompt:IsA("ProximityPrompt")) then
        return false
    end

    table.insert(self._promptConnections, prompt.Triggered:Connect(function(player)
        if not self._playerManager:IsInLobby(player) then
            return
        end
        callback(player, promptHost, prompt)
    end))
    return true
end

function LobbyService:_refreshNorthContractBoard()
    if not self._contractService then
        self._contractService = resolveContractService(self._deps)
    end
    if not self._contractService or type(self._contractService.GetBoardContracts) ~= "function" then
        return false
    end

    local board = workspace:FindFirstChild("ContractBoard", true)
    if not (board and board:IsA("BasePart")) then
        return false
    end

    local contracts = self._contractService:GetBoardContracts("lobby_main")
    if type(contracts) ~= "table" or #contracts == 0 then
        return false
    end

    local summaryLines = {}
    for index = 1, math.min(3, #contracts) do
        local entry = contracts[index]
        local mapLabel = humanizeLobbyMapId(entry and entry.mapId)
        local difficultyLabel = tostring((entry and entry.difficulty) or "Classic")
        table.insert(summaryLines, string.format("%d. %s • %s", index, mapLabel, difficultyLabel))
    end

    local subtitle = table.concat(summaryLines, "\n")
    ensureGuideBoardSurface(
        board,
        LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME,
        Enum.NormalId.Front,
        "CONTRACT BAY",
        subtitle,
        lobbyPromptColor("MatchmakingZone")
    )
    return true
end

function LobbyService:_bindWorldPrompts()
    self:_disconnectPromptConnections()

    local lobbyController = self._lobbyController
    if not lobbyController then
        lobbyController = resolveLobbySystemController(self._deps)
        self._lobbyController = lobbyController
    end

    self:_connectWorldPrompt("QueueTrigger", function(player)
        if lobbyController and type(lobbyController.OnQueueFromRoomBrowser) == "function" then
            lobbyController:OnQueueFromRoomBrowser(player, {
                source = "QueueTriggerPrompt",
            })
        end
        self:_publishLobbyWorldEvent(
            player,
            "LobbyWorldSurfaceRequested",
            "MatchmakingZone",
            "Queue pad aktif",
            "Queue dijalankan dan Room Browser dibuka untuk memantau state room.",
            {
                surface = "RoomBrowser",
            }
        )
    end)

    self:_connectWorldPrompt("ContractBoard", function(player)
        self:_publish("ContractBoardRequested", {
            player = player,
            lobbyId = "lobby_main",
            count = 3,
            now = os.clock(),
        })
        self:_refreshNorthContractBoard()
        if lobbyController and type(lobbyController.OnRequestRoomBrowserSnapshot) == "function" then
            lobbyController:OnRequestRoomBrowserSnapshot(player, {
                source = "ContractBoardPrompt",
            })
        end
        self:_publishLobbyWorldEvent(
            player,
            "LobbyWorldSurfaceRequested",
            "MatchmakingZone",
            "Contract board aktif",
            "Board direfresh dan Room Browser dibuka untuk pilih map, mode, lalu start.",
            {
                surface = "RoomBrowser",
            }
        )
    end)

    self:_connectWorldPrompt("RoomBoard", function(player)
        if lobbyController and type(lobbyController.OnRequestRoomBrowserSnapshot) == "function" then
            lobbyController:OnRequestRoomBrowserSnapshot(player, {
                source = "RoomBoardPrompt",
            })
        end
        self:_publishLobbyWorldEvent(
            player,
            "LobbyWorldSurfaceRequested",
            "MatchmakingZone",
            "Room board aktif",
            "Room Browser dibuka dari bay utara untuk create, join, dan ready.",
            {
                surface = "RoomBrowser",
            }
        )
    end)

    self:_connectWorldPrompt("ToolsBoard", function(player)
        self:_publishLobbyWorldEvent(
            player,
            "LobbyWorldPromptFeedback",
            "MatchmakingZone",
            "Tools bay aktif",
            "Training tools hidup. Lanjutkan test dari meja EMF, UV, THERMO, BOX, WRITING, dan CAM.",
            {}
        )
    end)

    self:_connectWorldPrompt("PartyBoard", function(player)
        if lobbyController and type(lobbyController.OnRequestRoomBrowserSnapshot) == "function" then
            lobbyController:OnRequestRoomBrowserSnapshot(player, {
                source = "PartyBoardPrompt",
            })
        end
        self:_publishLobbyWorldEvent(
            player,
            "LobbyWorldSurfaceRequested",
            "PartyZone",
            "Party board aktif",
            "Room Browser dibuka untuk create, invite, ready, dan kontrol room party.",
            {
                surface = "RoomBrowser",
            }
        )
    end)

    self:_connectWorldPrompt("ShopCounter", function(player)
        self:_publishLobbyWorldEvent(
            player,
            "LobbyWorldSurfaceRequested",
            "ShopZone",
            "Shop aktif",
            "Counter membuka surface shop untuk loadout, MM, PP, dan item store.",
            {
                surface = "ShopUI",
            }
        )
    end)

    self:_connectWorldPrompt("Interact_Shop", function(player)
        self:_publishLobbyWorldEvent(
            player,
            "LobbyWorldSurfaceRequested",
            "ShopZone",
            "Shop aktif",
            "Browse zone shop dibuka langsung dari area depan toko.",
            {
                surface = "ShopUI",
            }
        )
    end)

    self:_connectWorldPrompt("DailyRewardTerminal", function(player)
        self:_publish("DailyRewardClaimRequest", {
            player = player,
        })
        self:_publishLobbyWorldEvent(
            player,
            "LobbyWorldPromptFeedback",
            "DailyRewardZone",
            "Daily reward diproses",
            "Permintaan claim dikirim. Hasil reward akan tampil di feedback lobby.",
            {}
        )
    end)

    local toolLabels = {
        Table_Tools_1 = "EMF",
        Table_Tools_2 = "UV",
        Table_Tools_3 = "THERMO",
        Table_Tools_4 = "BOX",
        Table_Tools_5 = "WRITING",
        Table_Tools_6 = "CAM",
    }
    for partName, label in pairs(toolLabels) do
        self:_connectWorldPrompt(partName, function(player)
            self:_publishLobbyWorldEvent(
                player,
                "LobbyWorldPromptFeedback",
                "MatchmakingZone",
                label .. " training aktif",
                "Meja tools ini sekarang jadi anchor test evidence di bay utara.",
                {
                    toolLabel = label,
                    promptId = partName,
                }
            )
        end)
    end
end

function LobbyService:_getAppliedCosmeticsStore()
    local store = self._state:Get("appliedCosmeticsByUserId")
    if type(store) ~= "table" then
        store = {}
        self._state:Set("appliedCosmeticsByUserId", store)
    end
    return store
end

function LobbyService:_getAppliedCosmetics(player)
    local userId = toUserId(player)
    if not userId then
        return {}
    end

    local store = self:_getAppliedCosmeticsStore()
    return cloneMap(store[userId] or {})
end

function LobbyService:_setAppliedCosmetics(player, equippedCosmetics)
    local userId = toUserId(player)
    if not userId then
        return {}
    end

    local store = self:_getAppliedCosmeticsStore()
    local snapshot = sanitizeEquippedCosmetics(equippedCosmetics)
    store[userId] = snapshot
    self._state:Set("appliedCosmeticsByUserId", store)
    return snapshot
end

function LobbyService:_disconnectCharacterConnection(userId)
    local connection = self._characterConnections[userId]
    if connection then
        connection:Disconnect()
        self._characterConnections[userId] = nil
    end
end

function LobbyService:_clearCosmeticVisuals(character)
    if not character then
        return
    end

    local visuals = character:FindFirstChild(LOBBY_COSMETIC_FOLDER_NAME)
    if visuals then
        visuals:Destroy()
    end

    character:SetAttribute("LobbyEquippedEmote", nil)
end

function LobbyService:_buildDisplayEntries(equippedCosmetics)
    local entries = {}

    for slot, cosmeticId in pairs(equippedCosmetics or {}) do
        local catalogEntry = self._cosmeticCatalogById[cosmeticId]
        table.insert(entries, {
            slot = slot,
            cosmeticId = cosmeticId,
            name = (type(catalogEntry) == "table" and type(catalogEntry.name) == "string" and catalogEntry.name ~= "")
                    and catalogEntry.name
                or humanizeCosmeticId(cosmeticId),
            rarity = type(catalogEntry) == "table" and catalogEntry.rarity or nil,
        })
    end

    table.sort(entries, function(left, right)
        local leftOrder = SLOT_DISPLAY_ORDER[left.slot] or 99
        local rightOrder = SLOT_DISPLAY_ORDER[right.slot] or 99
        if leftOrder == rightOrder then
            return left.name < right.name
        end
        return leftOrder < rightOrder
    end)

    return entries
end

function LobbyService:_getFlexState()
    local flexState = self._state:Get("flexZoneState")
    if type(flexState) ~= "table" then
        flexState = {}
    end

    if type(flexState.participantsByUserId) ~= "table" then
        flexState.participantsByUserId = {}
    end
    if type(flexState.rotationOrder) ~= "table" then
        flexState.rotationOrder = {}
    end
    if type(flexState.spotlightUserId) ~= "number" then
        flexState.spotlightUserId = nil
    end

    self._state:Set("flexZoneState", flexState)
    return flexState
end

function LobbyService:_getPlayerProfileSystem()
    local profileSystem = self._dependencies.PlayerProfileSystem
    if profileSystem ~= nil then
        return profileSystem
    end

    profileSystem = Services.Get(self._deps, "PlayerProfileSystem")
    self._dependencies.PlayerProfileSystem = profileSystem
    return profileSystem
end

function LobbyService:_getPublicProfile(player)
    local profileSystem = self:_getPlayerProfileSystem()
    if type(profileSystem) ~= "table" then
        return nil
    end

    local profile = safeCall(profileSystem, "GetPublicProfile", player)
    if profile == nil and type(profileSystem.Service) == "table" then
        profile = safeCall(profileSystem.Service, "GetPublicProfile", player)
    end
    if profile ~= nil then
        return profile
    end

    profile = safeCall(profileSystem, "RefreshProfile", player)
    if profile == nil and type(profileSystem.Service) == "table" then
        profile = safeCall(profileSystem.Service, "RefreshProfile", player)
    end
    return profile
end

function LobbyService:_summarizeFlexShowcase(entry)
    local featuredNames = clampDisplayNames(entry and entry.showcaseItems or {})
    if #featuredNames == 0 then
        return "-"
    end
    return table.concat(featuredNames, ", ")
end

function LobbyService:_buildFlexParticipant(player)
    local userId = toUserId(player)
    if not userId then
        return nil
    end

    local profile = self:_getPublicProfile(player)
    local equippedCosmetics = self:_getAppliedCosmetics(player)
    if next(equippedCosmetics) == nil and type(profile) == "table" then
        equippedCosmetics = sanitizeEquippedCosmetics(profile.equippedCosmetics)
    end

    local displayEntries = self:_buildDisplayEntries(equippedCosmetics)
    local showcaseItems = {}
    for _, entry in ipairs(displayEntries) do
        table.insert(showcaseItems, {
            slot = entry.slot,
            cosmeticId = entry.cosmeticId,
            name = entry.name,
            rarity = entry.rarity,
        })
        if #showcaseItems >= FLEX_SPOTLIGHT_PARTICIPANT_LIMIT then
            break
        end
    end

    return {
        userId = userId,
        playerName = player.Name,
        displayName = player.DisplayName or player.Name,
        playerLevel = math.max(1, math.floor(tonumber(profile and profile.playerLevel) or 1)),
        rankTier = tostring(profile and profile.rankTier or "Bayi III"),
        winRate = math.max(0, math.floor(tonumber(profile and profile.winRate) or 0)),
        totalMatches = math.max(0, math.floor(tonumber(profile and profile.totalMatches) or 0)),
        totalWins = math.max(0, math.floor(tonumber(profile and profile.totalWins) or 0)),
        flexGallery = cloneArray(profile and profile.flexGallery or {}),
        equippedCosmetics = sanitizeEquippedCosmetics(equippedCosmetics),
        showcaseItems = showcaseItems,
        spotlightSummary = self:_summarizeFlexShowcase({
            showcaseItems = showcaseItems,
        }),
        updatedAt = os.time(),
    }
end

function LobbyService:_buildFlexParticipantSummary(entry)
    if type(entry) ~= "table" then
        return nil
    end
    return {
        userId = entry.userId,
        displayName = entry.displayName,
        playerName = entry.playerName,
        playerLevel = entry.playerLevel,
        rankTier = entry.rankTier,
        winRate = entry.winRate,
        totalMatches = entry.totalMatches,
        totalWins = entry.totalWins,
        showcaseSummary = entry.spotlightSummary,
        featuredNames = clampDisplayNames(entry.showcaseItems or {}),
    }
end

function LobbyService:_buildFlexSpotlight(entry)
    if type(entry) ~= "table" then
        return nil
    end
    return {
        userId = entry.userId,
        displayName = entry.displayName,
        playerName = entry.playerName,
        playerLevel = entry.playerLevel,
        rankTier = entry.rankTier,
        winRate = entry.winRate,
        totalMatches = entry.totalMatches,
        totalWins = entry.totalWins,
        showcaseSummary = entry.spotlightSummary,
        featuredNames = clampDisplayNames(entry.showcaseItems or {}),
        showcaseItems = cloneArray(entry.showcaseItems),
        flexGallery = cloneArray(entry.flexGallery),
        equippedCosmetics = cloneMap(entry.equippedCosmetics),
        updatedAt = entry.updatedAt,
    }
end

function LobbyService:_buildFlexParticipantsList(flexState)
    local participants = {}
    local participantsByUserId = flexState.participantsByUserId or {}

    for _, userId in ipairs(flexState.rotationOrder or {}) do
        local summary = self:_buildFlexParticipantSummary(participantsByUserId[userId])
        if summary then
            table.insert(participants, summary)
        end
        if #participants >= FLEX_SPOTLIGHT_PARTICIPANT_LIMIT then
            break
        end
    end

    return participants
end

function LobbyService:_publishFlexSpotlight(flexState, reason)
    local spotlight = flexState and flexState.participantsByUserId and flexState.participantsByUserId[flexState.spotlightUserId] or nil
    local payload = {
        eventName = spotlight and "LobbyFlexSpotlightUpdated" or "LobbyFlexSpotlightCleared",
        source = "LobbySocialHub",
        zoneName = "FlexZone",
        reason = reason or "updated",
        spotlight = self:_buildFlexSpotlight(spotlight),
        participants = self:_buildFlexParticipantsList(flexState or self:_getFlexState()),
        activeVisitorCount = #(flexState and flexState.rotationOrder or {}),
        updatedAt = os.time(),
        recipients = self:GetLobbyPlayers(),
    }
    flexState.lastPayload = payload
    flexState.lastUpdatedAt = payload.updatedAt
    self._state:Set("flexZoneState", flexState)
    self:_publish(payload.eventName, payload)
end

function LobbyService:_activateFlexSpotlight(player, reason)
    local participant = self:_buildFlexParticipant(player)
    if not participant then
        return
    end

    local flexState = self:_getFlexState()
    flexState.participantsByUserId[participant.userId] = participant
    removeArrayValue(flexState.rotationOrder, participant.userId)
    table.insert(flexState.rotationOrder, 1, participant.userId)
    flexState.spotlightUserId = participant.userId
    self:_publishFlexSpotlight(flexState, reason or "zone_entered")
end

function LobbyService:_removeFlexParticipant(player)
    local userId = toUserId(player)
    if not userId then
        return
    end

    local flexState = self:_getFlexState()
    if flexState.participantsByUserId[userId] == nil then
        return
    end

    flexState.participantsByUserId[userId] = nil
    removeArrayValue(flexState.rotationOrder, userId)

    if flexState.spotlightUserId == userId then
        flexState.spotlightUserId = flexState.rotationOrder[1]
        self:_publishFlexSpotlight(flexState, "spotlight_left")
        return
    end

    if flexState.spotlightUserId ~= nil then
        self:_publishFlexSpotlight(flexState, "participant_left")
        return
    end

    self._state:Set("flexZoneState", flexState)
end

function LobbyService:_refreshFlexParticipant(player, reason)
    local userId = toUserId(player)
    if not userId then
        return
    end

    local flexState = self:_getFlexState()
    if flexState.participantsByUserId[userId] == nil then
        return
    end

    local participant = self:_buildFlexParticipant(player)
    if not participant then
        return
    end

    flexState.participantsByUserId[userId] = participant
    if flexState.spotlightUserId == userId then
        self:_publishFlexSpotlight(flexState, reason or "spotlight_refreshed")
        return
    end

    self._state:Set("flexZoneState", flexState)
end

function LobbyService:_createBillboard(folder, head, equippedCosmetics)
    if not folder or not head then
        return
    end

    local entries = self:_buildDisplayEntries(equippedCosmetics)
    local emoteName = nil
    local flexEntries = {}

    for _, entry in ipairs(entries) do
        if entry.slot == "emote" and emoteName == nil then
            emoteName = entry.name
        else
            table.insert(flexEntries, entry)
        end
    end

    local primaryNames = clampDisplayNames(flexEntries)
    local primaryText = #primaryNames > 0 and table.concat(primaryNames, " | ") or "Lobby Flex Active"
    local secondaryText = emoteName and ("Emote: " .. emoteName) or "Cosmetics visible in lobby"

    local billboard = Instance.new("BillboardGui")
    billboard.Name = LOBBY_COSMETIC_GUI_NAME
    billboard.Adornee = head
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 80
    billboard.Size = UDim2.fromOffset(240, 56)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
    billboard.Parent = folder

    local primaryLabel = Instance.new("TextLabel")
    primaryLabel.Name = "Primary"
    primaryLabel.BackgroundTransparency = 1
    primaryLabel.Font = Enum.Font.GothamBold
    primaryLabel.TextColor3 = Color3.fromRGB(255, 244, 212)
    primaryLabel.TextScaled = true
    primaryLabel.TextStrokeTransparency = 0.5
    primaryLabel.TextWrapped = true
    primaryLabel.Size = UDim2.new(1, 0, 0.58, 0)
    primaryLabel.Text = primaryText
    primaryLabel.Parent = billboard

    local secondaryLabel = Instance.new("TextLabel")
    secondaryLabel.Name = "Secondary"
    secondaryLabel.BackgroundTransparency = 1
    secondaryLabel.Font = Enum.Font.Gotham
    secondaryLabel.TextColor3 = Color3.fromRGB(196, 232, 255)
    secondaryLabel.TextScaled = true
    secondaryLabel.TextStrokeTransparency = 0.65
    secondaryLabel.TextWrapped = true
    secondaryLabel.Position = UDim2.new(0, 0, 0.58, 0)
    secondaryLabel.Size = UDim2.new(1, 0, 0.42, 0)
    secondaryLabel.Text = secondaryText
    secondaryLabel.Parent = billboard
end

function LobbyService:_applyHeadVisual(folder, character, rarity)
    local head = getCharacterPart(character, { "Head" })
    if not head then
        return
    end

    createWeldedVisual(folder, head, "HeadVisual", {
        size = Vector3.new(1.5, 1.15, 0.18),
        offset = CFrame.new(0, 0, -0.5),
        color = chooseRarityColor(rarity, Color3.fromRGB(214, 224, 255)),
        transparency = 0.1,
        material = Enum.Material.SmoothPlastic,
    })

    createWeldedVisual(folder, head, "HeadSeal", {
        size = Vector3.new(0.55, 0.2, 0.14),
        offset = CFrame.new(0, -0.1, -0.6),
        color = chooseRarityColor(rarity, Color3.fromRGB(255, 244, 212)),
        transparency = 0,
        material = Enum.Material.Neon,
    })
end

function LobbyService:_applyBodyVisual(folder, character, rarity)
    local torso = getCharacterPart(character, { "UpperTorso", "Torso" })
    if not torso then
        return
    end

    createWeldedVisual(folder, torso, "BodyVisual", {
        size = Vector3.new(2.1, 2.35, 0.18),
        offset = CFrame.new(0, 0, -0.6),
        color = chooseRarityColor(rarity, Color3.fromRGB(112, 170, 255)),
        transparency = 0.15,
        material = Enum.Material.Fabric,
    })
end

function LobbyService:_applyOutfitVisual(folder, character, rarity)
    local torso = getCharacterPart(character, { "UpperTorso", "Torso" })
    if not torso then
        return
    end

    createWeldedVisual(folder, torso, "OutfitFront", {
        size = Vector3.new(2.25, 2.7, 0.16),
        offset = CFrame.new(0, -0.05, -0.58),
        color = chooseRarityColor(rarity, Color3.fromRGB(205, 128, 96)),
        transparency = 0.08,
        material = Enum.Material.Fabric,
    })

    createWeldedVisual(folder, torso, "OutfitBack", {
        size = Vector3.new(2, 2.8, 0.14),
        offset = CFrame.new(0, -0.2, 0.56),
        color = chooseRarityColor(rarity, Color3.fromRGB(82, 34, 34)),
        transparency = 0.2,
        material = Enum.Material.Fabric,
    })
end

function LobbyService:_applyAccessoryVisual(folder, character, rarity)
    local anchor = getCharacterPart(character, { "RightHand", "RightLowerArm", "Right Arm", "UpperTorso", "Torso" })
    if not anchor then
        return
    end

    local accessory = createWeldedVisual(folder, anchor, "AccessoryVisual", {
        size = Vector3.new(0.45, 0.45, 0.45),
        offset = CFrame.new(0.45, -0.2, -0.15),
        color = chooseRarityColor(rarity, Color3.fromRGB(255, 221, 145)),
        material = Enum.Material.Neon,
        shape = Enum.PartType.Ball,
    })

    if accessory then
        local charm = createWeldedVisual(folder, accessory, "AccessoryCharm", {
            size = Vector3.new(0.18, 0.6, 0.18),
            offset = CFrame.new(0, -0.45, 0),
            color = Color3.fromRGB(255, 244, 212),
            material = Enum.Material.Metal,
        })
        if charm then
            charm.Shape = Enum.PartType.Cylinder
            charm.CFrame = accessory.CFrame * CFrame.new(0, -0.45, 0) * CFrame.Angles(0, 0, math.rad(90))
        end
    end
end

function LobbyService:_renderLobbyCosmetics(player, character, equippedCosmetics)
    self:_clearCosmeticVisuals(character)

    if not isLobbyCharacter(player, character) then
        return true
    end

    local sanitized = sanitizeEquippedCosmetics(equippedCosmetics)
    if next(sanitized) == nil then
        return true
    end

    local head = getCharacterPart(character, { "Head" })
    local folder = createVisualFolder(character)

    for slot, cosmeticId in pairs(sanitized) do
        local catalogEntry = self._cosmeticCatalogById[cosmeticId]
        local rarity = type(catalogEntry) == "table" and catalogEntry.rarity or nil

        if slot == "head" then
            self:_applyHeadVisual(folder, character, rarity)
        elseif slot == "body" then
            self:_applyBodyVisual(folder, character, rarity)
        elseif slot == "outfit" then
            self:_applyOutfitVisual(folder, character, rarity)
        elseif slot == "accessory" then
            self:_applyAccessoryVisual(folder, character, rarity)
        elseif slot == "emote" then
            character:SetAttribute("LobbyEquippedEmote", humanizeCosmeticId(cosmeticId))
        end
    end

    self:_createBillboard(folder, head, sanitized)
    return true
end

function LobbyService:_ensureCharacterConnection(player)
    local userId = toUserId(player)
    if not userId then
        return
    end

    self:_disconnectCharacterConnection(userId)
    self._characterConnections[userId] = player.CharacterAdded:Connect(function(character)
        task.defer(function()
            task.wait()
            self:_renderLobbyCosmetics(player, character, self:_getAppliedCosmetics(player))
        end)
    end)
end

function LobbyService:_refreshPopulation()
    local playerCount = self._playerManager:GetLobbyPlayerCount()
    self._population:OnLobbyPlayerCountChanged(playerCount)
end

function LobbyService:_clearZoneGuides()
    local zoneParts = self._zoneManager and self._zoneManager:GetZoneParts() or {}
    for _, zonePart in pairs(zoneParts) do
        if typeof(zonePart) == "Instance" and zonePart:IsA("BasePart") then
            local folder = zonePart:FindFirstChild(LOBBY_ZONE_GUIDE_FOLDER_NAME)
            if folder then
                folder:Destroy()
            end
        end
    end
end

function LobbyService:_clearZoneEntryGuides()
    local lobbyRoot = LobbyLocator.ResolveRoot("LobbySocialHub", workspace)
    if not lobbyRoot then
        return
    end

    for _, descendant in ipairs(lobbyRoot:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local folder = descendant:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_FOLDER_NAME)
            if folder then
                folder:Destroy()
            end
        end
    end
end

function LobbyService:_ensureZoneGuide(zoneName, zonePart)
	if typeof(zonePart) ~= "Instance" or not zonePart:IsA("BasePart") or zonePart.Parent == nil then
		return false
	end
    if LOBBY_ZONE_GUIDES_ENABLED ~= true then
        local existingFolder = zonePart:FindFirstChild(LOBBY_ZONE_GUIDE_FOLDER_NAME)
        if existingFolder then
            existingFolder:Destroy()
        end
        return false
	end

	local feedback = LOBBY_ZONE_FEEDBACK[zoneName]
    local style = LOBBY_ZONE_GUIDE_STYLE[zoneName]
    if type(feedback) ~= "table" or type(style) ~= "table" then
        return false
    end

    local titleText = tostring(feedback.title or zoneName):gsub("%.$", "")
    local subtitleText = tostring(style.subtitle or feedback.hint or "")

    local folder = zonePart:FindFirstChild(LOBBY_ZONE_GUIDE_FOLDER_NAME)
    if not (folder and folder:IsA("Folder")) then
        if folder then
            folder:Destroy()
        end
        folder = Instance.new("Folder")
        folder.Name = LOBBY_ZONE_GUIDE_FOLDER_NAME
        folder.Parent = zonePart
    end

    local highlight = folder:FindFirstChild(LOBBY_ZONE_GUIDE_HIGHLIGHT_NAME)
    if not (highlight and highlight:IsA("Highlight")) then
        if highlight then
            highlight:Destroy()
        end
        highlight = Instance.new("Highlight")
        highlight.Name = LOBBY_ZONE_GUIDE_HIGHLIGHT_NAME
        highlight.Parent = folder
    end
    highlight.Adornee = zonePart
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = style.color
    highlight.FillTransparency = 0.92
    highlight.OutlineColor = style.color:Lerp(Color3.fromRGB(255, 255, 255), 0.24)
    highlight.OutlineTransparency = 0.18
    highlight.Enabled = true

    local billboard = folder:FindFirstChild(LOBBY_ZONE_GUIDE_BILLBOARD_NAME)
    if not (billboard and billboard:IsA("BillboardGui")) then
        if billboard then
            billboard:Destroy()
        end
        billboard = Instance.new("BillboardGui")
        billboard.Name = LOBBY_ZONE_GUIDE_BILLBOARD_NAME
        billboard.Parent = folder
    end
    billboard.Active = false
    billboard.Adornee = zonePart
    billboard.AlwaysOnTop = true
    billboard.Brightness = 2
    billboard.ClipsDescendants = false
    billboard.Enabled = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 120
    billboard.ResetOnSpawn = false
    billboard.Size = UDim2.fromOffset(228, 58)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, zonePart.Size.Y * 0.5 + 3.2, 0)

    local panel = billboard:FindFirstChild("Panel")
    if not (panel and panel:IsA("Frame")) then
        if panel then
            panel:Destroy()
        end
        panel = Instance.new("Frame")
        panel.Name = "Panel"
        panel.Parent = billboard

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = panel

        local stroke = Instance.new("UIStroke")
        stroke.Name = "Stroke"
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = style.color
        stroke.Transparency = 0.14
        stroke.Thickness = 1.4
        stroke.Parent = panel

        local accent = Instance.new("Frame")
        accent.Name = "Accent"
        accent.AnchorPoint = Vector2.new(0, 0.5)
        accent.BackgroundColor3 = style.color
        accent.BorderSizePixel = 0
        accent.Position = UDim2.new(0, 10, 0.5, 0)
        accent.Size = UDim2.fromOffset(3, 30)
        accent.Parent = panel

        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(1, 0)
        accentCorner.Parent = accent

        createGuideTextLabel(
            "Title",
            Enum.Font.GothamBold,
            13,
            Color3.fromRGB(245, 248, 252),
            titleText,
            18,
            UDim2.new(0, 20, 0, 6)
        ).Parent = panel

        createGuideTextLabel(
            "Subtitle",
            Enum.Font.GothamMedium,
            11,
            style.color:Lerp(Color3.fromRGB(240, 244, 248), 0.25),
            subtitleText,
            18,
            UDim2.new(0, 20, 0, 24)
        ).Parent = panel
    end

    panel.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
    panel.BackgroundTransparency = 0.12
    panel.BorderSizePixel = 0
    panel.Size = UDim2.fromScale(1, 1)
    return true
end

function LobbyService:_resolveZoneEntryAnchor(zoneName)
    local candidates = LOBBY_ZONE_ENTRY_ANCHORS[zoneName]
    if type(candidates) ~= "table" or #candidates == 0 then
        return nil
    end

    local lobbyRoot = LobbyLocator.ResolveRoot("LobbySocialHub", workspace)
    if not lobbyRoot then
        return nil
    end

    for _, candidateName in ipairs(candidates) do
        local candidate = lobbyRoot:FindFirstChild(candidateName, true)
        if candidate and candidate:IsA("BasePart") then
            return candidate
        end
    end

    return nil
end

function LobbyService:_ensureZoneEntryGuide(zoneName)
    local anchorPart = self:_resolveZoneEntryAnchor(zoneName)
    if not anchorPart then
        return false
    end
    if LOBBY_ZONE_ENTRY_GUIDES_ENABLED ~= true then
        local existingFolder = anchorPart:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_FOLDER_NAME)
        if existingFolder then
            existingFolder:Destroy()
        end
        return false
    end

    local style = LOBBY_ZONE_GUIDE_STYLE[zoneName]
    local copy = LOBBY_ZONE_ENTRY_COPY[zoneName]
    if type(style) ~= "table" or type(copy) ~= "table" then
        return false
    end

    local folder = anchorPart:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_FOLDER_NAME)
    if not (folder and folder:IsA("Folder")) then
        if folder then
            folder:Destroy()
        end
        folder = Instance.new("Folder")
        folder.Name = LOBBY_ZONE_ENTRY_GUIDE_FOLDER_NAME
        folder.Parent = anchorPart
    end

    local highlight = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_HIGHLIGHT_NAME)
    if not (highlight and highlight:IsA("Highlight")) then
        if highlight then
            highlight:Destroy()
        end
        highlight = Instance.new("Highlight")
        highlight.Name = LOBBY_ZONE_ENTRY_GUIDE_HIGHLIGHT_NAME
        highlight.Parent = folder
    end
    highlight.Adornee = anchorPart
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = style.color
    highlight.FillTransparency = 1
    highlight.OutlineColor = style.color
    highlight.OutlineTransparency = 1
    highlight.Enabled = false

    local billboard = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_BILLBOARD_NAME)
    if not (billboard and billboard:IsA("BillboardGui")) then
        if billboard then
            billboard:Destroy()
        end
        billboard = Instance.new("BillboardGui")
        billboard.Name = LOBBY_ZONE_ENTRY_GUIDE_BILLBOARD_NAME
        billboard.Parent = folder
    end
    billboard.Active = false
    billboard.Adornee = anchorPart
    billboard.AlwaysOnTop = true
    billboard.Brightness = 2
    billboard.ClipsDescendants = false
    billboard.Enabled = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 100
    billboard.ResetOnSpawn = false
    billboard.Size = UDim2.fromOffset(184, type(copy.meta) == "string" and copy.meta ~= "" and 64 or 46)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, anchorPart.Size.Y * 0.5 + 2.8, 0)

    local accentBar = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_ACCENT_NAME)
    if not (accentBar and accentBar:IsA("Part")) then
        if accentBar then
            accentBar:Destroy()
        end
        accentBar = Instance.new("Part")
        accentBar.Name = LOBBY_ZONE_ENTRY_GUIDE_ACCENT_NAME
        accentBar.Anchored = true
        accentBar.CanCollide = false
        accentBar.CanQuery = false
        accentBar.CanTouch = false
        accentBar.CastShadow = false
        accentBar.Locked = true
        accentBar.Material = Enum.Material.Neon
        accentBar.Parent = folder
    end
    accentBar.Color = style.color
    accentBar.Transparency = 0.12
    accentBar.Size = Vector3.new(math.max(anchorPart.Size.X, anchorPart.Size.Z) + 1.6, 0.28, 0.28)
    accentBar.CFrame = anchorPart.CFrame * CFrame.new(0, anchorPart.Size.Y * 0.5 + 0.95, 0)

    local accentLight = accentBar:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_LIGHT_NAME)
    if not (accentLight and accentLight:IsA("PointLight")) then
        if accentLight then
            accentLight:Destroy()
        end
        accentLight = Instance.new("PointLight")
        accentLight.Name = LOBBY_ZONE_ENTRY_GUIDE_LIGHT_NAME
        accentLight.Parent = accentBar
    end
    accentLight.Color = style.color
    accentLight.Brightness = 0.8
    accentLight.Range = 10
    accentLight.Shadows = false

    local doorWidth = math.max(anchorPart.Size.X, anchorPart.Size.Z)
    local frameDepth = math.min(anchorPart.Size.X, anchorPart.Size.Z) + 0.14
    local isWideOnX = anchorPart.Size.X >= anchorPart.Size.Z
    local sideOffset = (doorWidth * 0.5) + 0.42
    local topY = anchorPart.Size.Y * 0.5 + 0.42

    local frameTop = ensureNeonGuidePart(folder, LOBBY_ZONE_ENTRY_GUIDE_FRAME_TOP_NAME)
    local frameLeft = ensureNeonGuidePart(folder, LOBBY_ZONE_ENTRY_GUIDE_FRAME_LEFT_NAME)
    local frameRight = ensureNeonGuidePart(folder, LOBBY_ZONE_ENTRY_GUIDE_FRAME_RIGHT_NAME)
    for _, framePart in ipairs({ frameTop, frameLeft, frameRight }) do
        framePart.Color = style.color
        framePart.Transparency = 0.2
    end

    local headerBand = ensureNeonGuidePart(folder, LOBBY_ZONE_ENTRY_GUIDE_HEADER_NAME)
    headerBand.Color = style.color
    headerBand.Transparency = 0.08

    if isWideOnX then
        frameTop.Size = Vector3.new(anchorPart.Size.X + 0.9, 0.18, frameDepth)
        frameTop.CFrame = anchorPart.CFrame * CFrame.new(0, topY, 0)
        frameLeft.Size = Vector3.new(0.18, anchorPart.Size.Y + 0.2, frameDepth)
        frameLeft.CFrame = anchorPart.CFrame * CFrame.new(-sideOffset, 0, 0)
        frameRight.Size = Vector3.new(0.18, anchorPart.Size.Y + 0.2, frameDepth)
        frameRight.CFrame = anchorPart.CFrame * CFrame.new(sideOffset, 0, 0)
        headerBand.Size = Vector3.new(anchorPart.Size.X + 2.2, 1.55, frameDepth + 0.12)
        headerBand.CFrame = anchorPart.CFrame * CFrame.new(0, topY - 0.48, 0)
    else
        frameTop.Size = Vector3.new(frameDepth, 0.18, anchorPart.Size.Z + 0.9)
        frameTop.CFrame = anchorPart.CFrame * CFrame.new(0, topY, 0)
        frameLeft.Size = Vector3.new(frameDepth, anchorPart.Size.Y + 0.2, 0.18)
        frameLeft.CFrame = anchorPart.CFrame * CFrame.new(0, 0, -sideOffset)
        frameRight.Size = Vector3.new(frameDepth, anchorPart.Size.Y + 0.2, 0.18)
        frameRight.CFrame = anchorPart.CFrame * CFrame.new(0, 0, sideOffset)
        headerBand.Size = Vector3.new(frameDepth + 0.12, 1.55, anchorPart.Size.Z + 2.2)
        headerBand.CFrame = anchorPart.CFrame * CFrame.new(0, topY - 0.48, 0)
    end

    local contractBoard = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_BOARD_NAME)
    local toolsBoard = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_TOOLS_BOARD_NAME)
    local contractStand = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_STAND_NAME)
    local toolsStand = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_TOOLS_STAND_NAME)
    local contractBase = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_BASE_NAME)
    local toolsBase = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_TOOLS_BASE_NAME)
    local centerBoard = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CENTER_BOARD_NAME)
    local centerStand = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CENTER_STAND_NAME)
    local centerBase = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CENTER_BASE_NAME)
    local centerDesk = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CENTER_DESK_NAME)
    local centerDeskTop = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CENTER_DESK_TOP_NAME)
    local leftCase = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_LEFT_CASE_NAME)
    local rightCase = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_RIGHT_CASE_NAME)
    local centerBackdrop = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CENTER_BACKDROP_NAME)
    local floorRunner = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_FLOOR_RUNNER_NAME)
    local leftCaseStrip = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_LEFT_CASE_STRIP_NAME)
    local rightCaseStrip = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_RIGHT_CASE_STRIP_NAME)
    local contractClipboard = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_CLIPBOARD_NAME)
    local contractPaper = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_PAPER_NAME)
    local roomLedger = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_ROOM_LEDGER_NAME)
    local roomCards = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_ROOM_CARDS_NAME)
    local toolDisplayEMF = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_TOOL_EMF_NAME)
    local toolDisplayUV = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_TOOL_UV_NAME)
    local toolDisplayBox = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_TOOL_BOX_NAME)
    local deskMapPlate = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_DESK_MAP_PLATE_NAME)
    local deskModePlate = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_DESK_MODE_PLATE_NAME)
    local deskStartPlate = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_DESK_START_PLATE_NAME)
    local signPanel = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_SIGN_PANEL_NAME)
    local facadeCanopy = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CANOPY_NAME)
    local facadeApron = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_APRON_NAME)
    local facadeWingLeft = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_WING_LEFT_NAME)
    local facadeWingRight = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_WING_RIGHT_NAME)
    local facadeWindowLeft = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_WINDOW_LEFT_NAME)
    local facadeWindowRight = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_WINDOW_RIGHT_NAME)
    local facadeLampLeft = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_LAMP_LEFT_NAME)
    local facadeLampRight = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_LAMP_RIGHT_NAME)
    local forecourtPad = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_FORECOURT_PAD_NAME)
    local leftBench = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_LEFT_BENCH_NAME)
    local rightBench = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_RIGHT_BENCH_NAME)
    local leftPlanter = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_LEFT_PLANTER_NAME)
    local rightPlanter = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_RIGHT_PLANTER_NAME)
    local leftPlanterTop = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_LEFT_PLANTER_TOP_NAME)
    local rightPlanterTop = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_RIGHT_PLANTER_TOP_NAME)
    local zoneCounter = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_ZONE_COUNTER_NAME)
    local zoneCounterTop = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_ZONE_COUNTER_TOP_NAME)
    local zoneLeftDisplay = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_ZONE_LEFT_DISPLAY_NAME)
    local zoneRightDisplay = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_ZONE_RIGHT_DISPLAY_NAME)
    local zonePrimaryProp = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_ZONE_PRIMARY_PROP_NAME)
    local zoneSecondaryProp = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_ZONE_SECONDARY_PROP_NAME)
    local useFacadeSign = FACADE_SIGN_ZONE_FLAGS[zoneName] == true

    local function applyInteriorShell(shellWidth, shellDepth, shellHeight, forwardOffset)
        local floorPart = ensureGuidePanelPart(folder, "InteriorFloor")
        local backWall = ensureGuidePanelPart(folder, "InteriorBackWall")
        local sideLeft = ensureGuidePanelPart(folder, "InteriorSideLeft")
        local sideRight = ensureGuidePanelPart(folder, "InteriorSideRight")
        local ceiling = ensureGuidePanelPart(folder, "InteriorCeiling")

        for _, shellPart in ipairs({ floorPart, backWall, sideLeft, sideRight, ceiling }) do
            shellPart.Color = Color3.fromRGB(18, 26, 38)
            shellPart.Material = Enum.Material.SmoothPlastic
            shellPart.Transparency = 0.03
        end
        floorPart.Color = Color3.fromRGB(24, 34, 48)
        floorPart.Material = Enum.Material.Slate
        ceiling.Color = Color3.fromRGB(28, 38, 54)
        ceiling.Material = Enum.Material.Metal
        sideLeft.Color = Color3.fromRGB(28, 38, 54)
        sideRight.Color = Color3.fromRGB(28, 38, 54)

        if isWideOnX then
            floorPart.Size = Vector3.new(shellWidth, 0.16, shellDepth)
            floorPart.CFrame = anchorPart.CFrame * CFrame.new(0, (-anchorPart.Size.Y * 0.5) + 0.17, forwardOffset)
            backWall.Size = Vector3.new(shellWidth, shellHeight, 0.28)
            backWall.CFrame = anchorPart.CFrame * CFrame.new(0, (-anchorPart.Size.Y * 0.5) + (shellHeight * 0.5), forwardOffset + (shellDepth * 0.5) - 0.14)
            sideLeft.Size = Vector3.new(0.28, shellHeight, shellDepth)
            sideLeft.CFrame = anchorPart.CFrame * CFrame.new(-(shellWidth * 0.5) + 0.14, (-anchorPart.Size.Y * 0.5) + (shellHeight * 0.5), forwardOffset)
            sideRight.Size = Vector3.new(0.28, shellHeight, shellDepth)
            sideRight.CFrame = anchorPart.CFrame * CFrame.new((shellWidth * 0.5) - 0.14, (-anchorPart.Size.Y * 0.5) + (shellHeight * 0.5), forwardOffset)
            ceiling.Size = Vector3.new(shellWidth, 0.18, shellDepth)
            ceiling.CFrame = anchorPart.CFrame * CFrame.new(0, (-anchorPart.Size.Y * 0.5) + shellHeight - 0.09, forwardOffset)
        else
            floorPart.Size = Vector3.new(shellDepth, 0.16, shellWidth)
            floorPart.CFrame = anchorPart.CFrame * CFrame.new(forwardOffset, (-anchorPart.Size.Y * 0.5) + 0.17, 0)
            backWall.Size = Vector3.new(0.28, shellHeight, shellWidth)
            backWall.CFrame = anchorPart.CFrame * CFrame.new(forwardOffset + (shellDepth * 0.5) - 0.14, (-anchorPart.Size.Y * 0.5) + (shellHeight * 0.5), 0)
            sideLeft.Size = Vector3.new(shellDepth, shellHeight, 0.28)
            sideLeft.CFrame = anchorPart.CFrame * CFrame.new(forwardOffset, (-anchorPart.Size.Y * 0.5) + (shellHeight * 0.5), -(shellWidth * 0.5) + 0.14)
            sideRight.Size = Vector3.new(shellDepth, shellHeight, 0.28)
            sideRight.CFrame = anchorPart.CFrame * CFrame.new(forwardOffset, (-anchorPart.Size.Y * 0.5) + (shellHeight * 0.5), (shellWidth * 0.5) - 0.14)
            ceiling.Size = Vector3.new(shellDepth, 0.18, shellWidth)
            ceiling.CFrame = anchorPart.CFrame * CFrame.new(forwardOffset, (-anchorPart.Size.Y * 0.5) + shellHeight - 0.09, 0)
        end
    end

    if useFacadeSign then
        local backFace = isWideOnX and Enum.NormalId.Back or Enum.NormalId.Right
        local frontFace = isWideOnX and Enum.NormalId.Front or Enum.NormalId.Left
        signPanel = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_SIGN_PANEL_NAME)
        signPanel.Color = Color3.fromRGB(14, 22, 34)
        signPanel.Transparency = 0.02
        signPanel.Material = Enum.Material.SmoothPlastic
        if isWideOnX then
            local signWidth = zoneName == "MatchmakingZone" and (anchorPart.Size.X + 5.8) or (anchorPart.Size.X + 3.8)
            signPanel.Size = Vector3.new(signWidth, 2.5, 0.35)
            signPanel.CFrame = anchorPart.CFrame * CFrame.new(0, topY + 1.5, 1.95)
        else
            local signDepth = zoneName == "MatchmakingZone" and (anchorPart.Size.Z + 5.8) or (anchorPart.Size.Z + 3.8)
            signPanel.Size = Vector3.new(0.35, 2.5, signDepth)
            signPanel.CFrame = anchorPart.CFrame * CFrame.new(0, topY + 1.5, 1.95)
        end
        if billboard then
            billboard.Enabled = false
            billboard.Adornee = nil
        end
        ensureGuideBoardSurface(
            signPanel,
            LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME,
            backFace,
            copy.title,
            type(copy.meta) == "string" and copy.meta ~= "" and (copy.subtitle .. "\n" .. copy.meta:gsub(" • ", " • ")) or copy.subtitle,
            style.color
        )
        ensureGuideBoardSurface(
            signPanel,
            LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME,
            frontFace,
            copy.title,
            type(copy.meta) == "string" and copy.meta ~= "" and (copy.subtitle .. "\n" .. copy.meta:gsub(" • ", " • ")) or copy.subtitle,
            style.color
        )
    else
        if billboard then
            billboard.Enabled = true
            billboard.Adornee = anchorPart
        end
        if signPanel then
            signPanel:Destroy()
            signPanel = nil
        end
    end

    if zoneName == "MatchmakingZone" then
        contractBoard = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_BOARD_NAME)
        toolsBoard = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_TOOLS_BOARD_NAME)
        contractStand = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_STAND_NAME)
        toolsStand = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_TOOLS_STAND_NAME)
        contractBase = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_BASE_NAME)
        toolsBase = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_TOOLS_BASE_NAME)
        centerBoard = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CENTER_BOARD_NAME)
        centerStand = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CENTER_STAND_NAME)
        centerBase = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CENTER_BASE_NAME)
        centerDesk = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CENTER_DESK_NAME)
        centerDeskTop = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CENTER_DESK_TOP_NAME)
        leftCase = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_LEFT_CASE_NAME)
        rightCase = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_RIGHT_CASE_NAME)
        centerBackdrop = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CENTER_BACKDROP_NAME)
        floorRunner = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_FLOOR_RUNNER_NAME)
        leftCaseStrip = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_LEFT_CASE_STRIP_NAME)
        rightCaseStrip = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_RIGHT_CASE_STRIP_NAME)
        contractClipboard = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_CLIPBOARD_NAME)
        contractPaper = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_PAPER_NAME)
        roomLedger = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_ROOM_LEDGER_NAME)
        roomCards = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_ROOM_CARDS_NAME)
        toolDisplayEMF = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_TOOL_EMF_NAME)
        toolDisplayUV = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_TOOL_UV_NAME)
        toolDisplayBox = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_TOOL_BOX_NAME)
        deskMapPlate = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_DESK_MAP_PLATE_NAME)
        deskModePlate = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_DESK_MODE_PLATE_NAME)
        deskStartPlate = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_DESK_START_PLATE_NAME)
        facadeCanopy = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CANOPY_NAME)
        facadeApron = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_APRON_NAME)
        facadeWingLeft = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_WING_LEFT_NAME)
        facadeWingRight = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_WING_RIGHT_NAME)
        facadeWindowLeft = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_WINDOW_LEFT_NAME)
        facadeWindowRight = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_WINDOW_RIGHT_NAME)
        facadeLampLeft = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_LAMP_LEFT_NAME)
        facadeLampRight = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_LAMP_RIGHT_NAME)
        forecourtPad = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_FORECOURT_PAD_NAME)
        leftBench = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_LEFT_BENCH_NAME)
        rightBench = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_RIGHT_BENCH_NAME)
        leftPlanter = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_LEFT_PLANTER_NAME)
        rightPlanter = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_RIGHT_PLANTER_NAME)
        leftPlanterTop = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_LEFT_PLANTER_TOP_NAME)
        rightPlanterTop = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_RIGHT_PLANTER_TOP_NAME)
        local facadeFrontWallLeft = ensureGuidePanelPart(folder, "FacadeFrontWallLeft")
        local facadeFrontWallRight = ensureGuidePanelPart(folder, "FacadeFrontWallRight")
        local facadeFrontHeader = ensureGuidePanelPart(folder, "FacadeFrontHeader")
        local facadeFrontAccent = ensureGuidePanelPart(folder, "FacadeFrontAccent")
        for _, board in ipairs({ contractBoard, toolsBoard, centerBoard }) do
            board.Color = Color3.fromRGB(18, 26, 38)
            board.Transparency = 0.08
        end
        for _, standPart in ipairs({ contractStand, toolsStand, centerStand }) do
            standPart.Color = Color3.fromRGB(26, 34, 48)
            standPart.Transparency = 0.04
            standPart.Material = Enum.Material.Metal
        end
        for _, basePart in ipairs({ contractBase, toolsBase, centerBase }) do
            basePart.Color = Color3.fromRGB(38, 48, 64)
            basePart.Transparency = 0.02
            basePart.Material = Enum.Material.Slate
        end
        for _, propPart in ipairs({ centerDesk, centerDeskTop, leftCase, rightCase }) do
            propPart.Color = Color3.fromRGB(20, 28, 40)
            propPart.Transparency = 0.03
            propPart.Material = Enum.Material.SmoothPlastic
        end
        centerDeskTop.Color = Color3.fromRGB(42, 54, 72)
        centerDeskTop.Material = Enum.Material.Metal
        leftCase.Color = Color3.fromRGB(28, 36, 50)
        rightCase.Color = Color3.fromRGB(28, 36, 50)
        centerBackdrop.Color = Color3.fromRGB(16, 24, 36)
        centerBackdrop.Material = Enum.Material.SmoothPlastic
        centerBackdrop.Transparency = 0.04
        floorRunner.Color = Color3.fromRGB(24, 36, 54)
        floorRunner.Material = Enum.Material.Slate
        floorRunner.Transparency = 0.05
        leftCaseStrip.Color = style.color:Lerp(Color3.fromRGB(255, 255, 255), 0.2)
        leftCaseStrip.Material = Enum.Material.Neon
        leftCaseStrip.Transparency = 0.18
        rightCaseStrip.Color = style.color:Lerp(Color3.fromRGB(255, 255, 255), 0.2)
        rightCaseStrip.Material = Enum.Material.Neon
        rightCaseStrip.Transparency = 0.18
        contractClipboard.Color = Color3.fromRGB(32, 42, 58)
        contractClipboard.Material = Enum.Material.Metal
        contractPaper.Color = Color3.fromRGB(224, 230, 236)
        contractPaper.Material = Enum.Material.SmoothPlastic
        roomLedger.Color = Color3.fromRGB(52, 64, 84)
        roomLedger.Material = Enum.Material.Slate
        roomCards.Color = Color3.fromRGB(150, 189, 255)
        roomCards.Material = Enum.Material.SmoothPlastic
        toolDisplayEMF.Color = Color3.fromRGB(48, 58, 72)
        toolDisplayEMF.Material = Enum.Material.Metal
        toolDisplayUV.Color = Color3.fromRGB(214, 146, 255)
        toolDisplayUV.Material = Enum.Material.Neon
        toolDisplayBox.Color = Color3.fromRGB(72, 82, 98)
        toolDisplayBox.Material = Enum.Material.SmoothPlastic
        for _, plate in ipairs({ deskMapPlate, deskModePlate, deskStartPlate }) do
            plate.Color = Color3.fromRGB(22, 30, 42)
            plate.Material = Enum.Material.SmoothPlastic
            plate.Transparency = 0.03
        end
        for _, facadePart in ipairs({ facadeCanopy, facadeApron, facadeWingLeft, facadeWingRight }) do
            facadePart.Color = Color3.fromRGB(24, 32, 46)
            facadePart.Transparency = 0.02
        end
        facadeCanopy.Material = Enum.Material.Metal
        facadeApron.Material = Enum.Material.Slate
        facadeWingLeft.Material = Enum.Material.SmoothPlastic
        facadeWingRight.Material = Enum.Material.SmoothPlastic
        facadeFrontWallLeft.Color = Color3.fromRGB(80, 92, 112)
        facadeFrontWallLeft.Material = Enum.Material.SmoothPlastic
        facadeFrontWallLeft.Transparency = 0.02
        facadeFrontWallRight.Color = Color3.fromRGB(80, 92, 112)
        facadeFrontWallRight.Material = Enum.Material.SmoothPlastic
        facadeFrontWallRight.Transparency = 0.02
        facadeFrontHeader.Color = Color3.fromRGB(64, 76, 94)
        facadeFrontHeader.Material = Enum.Material.Metal
        facadeFrontHeader.Transparency = 0.02
        facadeFrontAccent.Color = style.color
        facadeFrontAccent.Material = Enum.Material.Neon
        facadeFrontAccent.Transparency = 0.14
        for _, windowPart in ipairs({ facadeWindowLeft, facadeWindowRight }) do
            windowPart.Color = style.color:Lerp(Color3.fromRGB(255, 255, 255), 0.12)
            windowPart.Material = Enum.Material.Glass
            windowPart.Transparency = 0.34
        end
        for _, lampPart in ipairs({ facadeLampLeft, facadeLampRight }) do
            lampPart.Color = style.color:Lerp(Color3.fromRGB(255, 255, 255), 0.22)
            lampPart.Material = Enum.Material.Neon
            lampPart.Transparency = 0.12
            local lampLight = ensurePointLight(lampPart, "Glow")
            lampLight.Color = style.color
            lampLight.Brightness = 1.35
            lampLight.Range = 18
            lampLight.Shadows = false
            lampLight.Enabled = true
        end
        forecourtPad.Color = Color3.fromRGB(20, 30, 44)
        forecourtPad.Material = Enum.Material.Slate
        forecourtPad.Transparency = 0.04
        for _, benchPart in ipairs({ leftBench, rightBench }) do
            benchPart.Color = Color3.fromRGB(42, 54, 72)
            benchPart.Material = Enum.Material.Metal
            benchPart.Transparency = 0.03
        end
        for _, planterPart in ipairs({ leftPlanter, rightPlanter }) do
            planterPart.Color = Color3.fromRGB(32, 42, 58)
            planterPart.Material = Enum.Material.Slate
            planterPart.Transparency = 0.02
        end
        for _, planterTopPart in ipairs({ leftPlanterTop, rightPlanterTop }) do
            planterTopPart.Color = Color3.fromRGB(96, 138, 102)
            planterTopPart.Material = Enum.Material.Grass
            planterTopPart.Transparency = 0.04
        end
        applyInteriorShell(anchorPart.Size.X + 16.8, 19.5, 5.8, 10.5)
        if isWideOnX then
            contractBoard.Size = Vector3.new(4.4, 3.4, frameDepth + 0.06)
            contractBoard.CFrame = anchorPart.CFrame * CFrame.new(-sideOffset - 5.2, -0.05, 0.3)
            toolsBoard.Size = Vector3.new(4.4, 3.4, frameDepth + 0.06)
            toolsBoard.CFrame = anchorPart.CFrame * CFrame.new(sideOffset + 5.2, -0.05, 0.3)
            contractStand.Size = Vector3.new(0.48, 2.3, 0.48)
            contractStand.CFrame = contractBoard.CFrame * CFrame.new(0, -2.75, 0)
            toolsStand.Size = Vector3.new(0.48, 2.3, 0.48)
            toolsStand.CFrame = toolsBoard.CFrame * CFrame.new(0, -2.75, 0)
            contractBase.Size = Vector3.new(2.4, 0.28, 1.8)
            contractBase.CFrame = contractStand.CFrame * CFrame.new(0, -1.28, 0.15)
            toolsBase.Size = Vector3.new(2.4, 0.28, 1.8)
            toolsBase.CFrame = toolsStand.CFrame * CFrame.new(0, -1.28, 0.15)
            centerBoard.Size = Vector3.new(5.8, 4.1, frameDepth + 0.08)
            centerBoard.CFrame = anchorPart.CFrame * CFrame.new(0, 0.12, 2.55)
            centerStand.Size = Vector3.new(0.56, 2.5, 0.56)
            centerStand.CFrame = centerBoard.CFrame * CFrame.new(0, -3.18, 0)
            centerBase.Size = Vector3.new(2.8, 0.3, 2.2)
            centerBase.CFrame = centerStand.CFrame * CFrame.new(0, -1.4, 0.2)
            centerDesk.Size = Vector3.new(6.4, 1.9, 2.8)
            centerDesk.CFrame = anchorPart.CFrame * CFrame.new(0, -1.25, 4.55)
            centerDeskTop.Size = Vector3.new(6.8, 0.2, 3.0)
            centerDeskTop.CFrame = centerDesk.CFrame * CFrame.new(0, 1.04, 0)
            leftCase.Size = Vector3.new(2.4, 1.55, 1.7)
            leftCase.CFrame = anchorPart.CFrame * CFrame.new(-sideOffset - 3.8, -1.35, 3.85)
            rightCase.Size = Vector3.new(2.4, 1.55, 1.7)
            rightCase.CFrame = anchorPart.CFrame * CFrame.new(sideOffset + 3.8, -1.35, 3.85)
            centerBackdrop.Size = Vector3.new(7.6, 5.3, 0.32)
            centerBackdrop.CFrame = anchorPart.CFrame * CFrame.new(0, -0.1, 1.86)
            floorRunner.Size = Vector3.new(5.2, 0.06, 5.8)
            floorRunner.CFrame = anchorPart.CFrame * CFrame.new(0, (-anchorPart.Size.Y * 0.5) + 0.19, 5.15)
            leftCaseStrip.Size = Vector3.new(2.1, 0.12, 0.12)
            leftCaseStrip.CFrame = leftCase.CFrame * CFrame.new(0, leftCase.Size.Y * 0.5 + 0.08, -0.52)
            rightCaseStrip.Size = Vector3.new(2.1, 0.12, 0.12)
            rightCaseStrip.CFrame = rightCase.CFrame * CFrame.new(0, rightCase.Size.Y * 0.5 + 0.08, -0.52)
            contractClipboard.Size = Vector3.new(1.45, 0.1, 1.0)
            contractClipboard.CFrame = centerDeskTop.CFrame * CFrame.new(0, 0.16, -0.28) * CFrame.Angles(math.rad(-12), 0, 0)
            contractPaper.Size = Vector3.new(1.12, 0.04, 0.72)
            contractPaper.CFrame = contractClipboard.CFrame * CFrame.new(0, 0.08, -0.02)
            roomLedger.Size = Vector3.new(1.2, 0.14, 0.82)
            roomLedger.CFrame = leftCase.CFrame * CFrame.new(0, leftCase.Size.Y * 0.5 + 0.12, 0) * CFrame.Angles(math.rad(-10), 0, 0)
            roomCards.Size = Vector3.new(0.74, 0.08, 0.46)
            roomCards.CFrame = leftCase.CFrame * CFrame.new(0.52, leftCase.Size.Y * 0.5 + 0.18, 0.1) * CFrame.Angles(0, math.rad(18), 0)
            toolDisplayEMF.Size = Vector3.new(0.42, 0.92, 0.42)
            toolDisplayEMF.CFrame = rightCase.CFrame * CFrame.new(-0.52, rightCase.Size.Y * 0.5 + 0.46, -0.18)
            toolDisplayUV.Size = Vector3.new(0.24, 0.24, 1.08)
            toolDisplayUV.CFrame = rightCase.CFrame * CFrame.new(0.0, rightCase.Size.Y * 0.5 + 0.14, 0.08)
            toolDisplayBox.Size = Vector3.new(0.74, 0.52, 0.42)
            toolDisplayBox.CFrame = rightCase.CFrame * CFrame.new(0.58, rightCase.Size.Y * 0.5 + 0.3, 0.02)
            deskMapPlate.Size = Vector3.new(1.48, 0.16, 0.72)
            deskMapPlate.CFrame = centerDeskTop.CFrame * CFrame.new(-1.74, 0.18, 0.72)
            deskModePlate.Size = Vector3.new(1.48, 0.16, 0.72)
            deskModePlate.CFrame = centerDeskTop.CFrame * CFrame.new(0, 0.18, 0.72)
            deskStartPlate.Size = Vector3.new(1.48, 0.16, 0.72)
            deskStartPlate.CFrame = centerDeskTop.CFrame * CFrame.new(1.74, 0.18, 0.72)
            facadeCanopy.Size = Vector3.new(anchorPart.Size.X + 6.8, 0.62, 3.8)
            facadeCanopy.CFrame = anchorPart.CFrame * CFrame.new(0, topY - 0.1, 1.9)
            facadeApron.Size = Vector3.new(anchorPart.Size.X + 9.4, 0.28, 8.8)
            facadeApron.CFrame = anchorPart.CFrame * CFrame.new(0, (-anchorPart.Size.Y * 0.5) + 0.15, 4.2)
            facadeWingLeft.Size = Vector3.new(1.25, anchorPart.Size.Y + 1.2, 3.2)
            facadeWingLeft.CFrame = anchorPart.CFrame * CFrame.new(-sideOffset - 1.7, 0, 1.55)
            facadeWingRight.Size = Vector3.new(1.25, anchorPart.Size.Y + 1.2, 3.2)
            facadeWingRight.CFrame = anchorPart.CFrame * CFrame.new(sideOffset + 1.7, 0, 1.55)
            forecourtPad.Size = Vector3.new(anchorPart.Size.X + 13.6, 0.16, 16)
            forecourtPad.CFrame = anchorPart.CFrame * CFrame.new(0, (-anchorPart.Size.Y * 0.5) + 0.18, 8.45)
            leftBench.Size = Vector3.new(4.4, 0.68, 1.42)
            leftBench.CFrame = anchorPart.CFrame * CFrame.new(-sideOffset - 6.2, -2.16, 8.15)
            rightBench.Size = Vector3.new(4.4, 0.68, 1.42)
            rightBench.CFrame = anchorPart.CFrame * CFrame.new(sideOffset + 6.2, -2.16, 8.15)
            leftPlanter.Size = Vector3.new(2.6, 1.08, 2.2)
            leftPlanter.CFrame = anchorPart.CFrame * CFrame.new(-sideOffset - 2.5, -1.96, 10.1)
            rightPlanter.Size = Vector3.new(2.6, 1.08, 2.2)
            rightPlanter.CFrame = anchorPart.CFrame * CFrame.new(sideOffset + 2.5, -1.96, 10.1)
            leftPlanterTop.Size = Vector3.new(2.02, 0.34, 1.62)
            leftPlanterTop.CFrame = leftPlanter.CFrame * CFrame.new(0, 0.56, 0)
            rightPlanterTop.Size = Vector3.new(2.02, 0.34, 1.62)
            rightPlanterTop.CFrame = rightPlanter.CFrame * CFrame.new(0, 0.56, 0)
        else
            contractBoard.Size = Vector3.new(frameDepth + 0.06, 3.4, 4.4)
            contractBoard.CFrame = anchorPart.CFrame * CFrame.new(0, 0.2, -sideOffset - 3.8)
            toolsBoard.Size = Vector3.new(frameDepth + 0.06, 3.4, 4.4)
            toolsBoard.CFrame = anchorPart.CFrame * CFrame.new(0, 0.2, sideOffset + 3.8)
            contractStand.Size = Vector3.new(0.48, 2.3, 0.48)
            contractStand.CFrame = contractBoard.CFrame * CFrame.new(0, -2.75, 0)
            toolsStand.Size = Vector3.new(0.48, 2.3, 0.48)
            toolsStand.CFrame = toolsBoard.CFrame * CFrame.new(0, -2.75, 0)
            contractBase.Size = Vector3.new(1.8, 0.28, 2.4)
            contractBase.CFrame = contractStand.CFrame * CFrame.new(0.15, -1.28, 0)
            toolsBase.Size = Vector3.new(1.8, 0.28, 2.4)
            toolsBase.CFrame = toolsStand.CFrame * CFrame.new(0.15, -1.28, 0)
            centerBoard.Size = Vector3.new(frameDepth + 0.08, 3.9, 5.6)
            centerBoard.CFrame = anchorPart.CFrame * CFrame.new(2.25, 0.45, 0)
            centerStand.Size = Vector3.new(0.56, 2.5, 0.56)
            centerStand.CFrame = centerBoard.CFrame * CFrame.new(0, -3.18, 0)
            centerBase.Size = Vector3.new(2.2, 0.3, 2.8)
            centerBase.CFrame = centerStand.CFrame * CFrame.new(0.2, -1.4, 0)
            facadeCanopy.Size = Vector3.new(3.8, 0.62, anchorPart.Size.Z + 6.8)
            facadeCanopy.CFrame = anchorPart.CFrame * CFrame.new(1.9, topY - 0.1, 0)
            facadeApron.Size = Vector3.new(8.8, 0.28, anchorPart.Size.Z + 9.4)
            facadeApron.CFrame = anchorPart.CFrame * CFrame.new(4.2, (-anchorPart.Size.Y * 0.5) + 0.15, 0)
            facadeWingLeft.Size = Vector3.new(3.2, anchorPart.Size.Y + 1.2, 1.25)
            facadeWingLeft.CFrame = anchorPart.CFrame * CFrame.new(1.55, 0, -sideOffset - 1.7)
            facadeWingRight.Size = Vector3.new(3.2, anchorPart.Size.Y + 1.2, 1.25)
            facadeWingRight.CFrame = anchorPart.CFrame * CFrame.new(1.55, 0, sideOffset + 1.7)
            forecourtPad.Size = Vector3.new(15.2, 0.16, anchorPart.Size.Z + 13.6)
            forecourtPad.CFrame = anchorPart.CFrame * CFrame.new(8.25, (-anchorPart.Size.Y * 0.5) + 0.18, 0)
            leftBench.Size = Vector3.new(1.42, 0.68, 4.4)
            leftBench.CFrame = anchorPart.CFrame * CFrame.new(8.02, -2.16, -sideOffset - 6.2)
            rightBench.Size = Vector3.new(1.42, 0.68, 4.4)
            rightBench.CFrame = anchorPart.CFrame * CFrame.new(8.02, -2.16, sideOffset + 6.2)
            leftPlanter.Size = Vector3.new(2.2, 1.08, 2.6)
            leftPlanter.CFrame = anchorPart.CFrame * CFrame.new(9.95, -1.96, -sideOffset - 2.5)
            rightPlanter.Size = Vector3.new(2.2, 1.08, 2.6)
            rightPlanter.CFrame = anchorPart.CFrame * CFrame.new(9.95, -1.96, sideOffset + 2.5)
            leftPlanterTop.Size = Vector3.new(1.62, 0.34, 2.02)
            leftPlanterTop.CFrame = leftPlanter.CFrame * CFrame.new(0, 0.56, 0)
            rightPlanterTop.Size = Vector3.new(1.62, 0.34, 2.02)
            rightPlanterTop.CFrame = rightPlanter.CFrame * CFrame.new(0, 0.56, 0)
        end
        if zoneCounter then
            zoneCounter:Destroy()
        end
        if zoneCounterTop then
            zoneCounterTop:Destroy()
        end
        if zoneLeftDisplay then
            zoneLeftDisplay:Destroy()
        end
        if zoneRightDisplay then
            zoneRightDisplay:Destroy()
        end
        if zonePrimaryProp then
            zonePrimaryProp:Destroy()
        end
        if zoneSecondaryProp then
            zoneSecondaryProp:Destroy()
        end
        clearLegacyBoardGui(contractBoard)
        clearLegacyBoardGui(toolsBoard)
        clearLegacyBoardGui(centerBoard)
        ensureGuideBoardSurface(contractBoard, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Back, "ROOM", "Create • Join • Ready", style.color)
        ensureGuideBoardSurface(contractBoard, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, Enum.NormalId.Front, "ROOM", "Create • Join • Ready", style.color)
        ensureGuideBoardSurface(toolsBoard, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Back, "TOOLS", "EMF • UV • BOX", style.color)
        ensureGuideBoardSurface(toolsBoard, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, Enum.NormalId.Front, "TOOLS", "EMF • UV • BOX", style.color)
        ensureGuideBoardSurface(centerBoard, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Back, "CONTRACT BOARD", "Map • Mode • Start", style.color)
        ensureGuideBoardSurface(centerBoard, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, Enum.NormalId.Front, "CONTRACT BOARD", "Map • Mode • Start", style.color)
        ensureGuideBoardSurface(deskMapPlate, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Top, "MAP", "Haunted House", style.color)
        ensureGuideBoardSurface(deskMapPlate, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, Enum.NormalId.Bottom, "MAP", "Haunted House", style.color)
        ensureGuideBoardSurface(deskModePlate, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Top, "MODE", "Classic", style.color)
        ensureGuideBoardSurface(deskModePlate, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, Enum.NormalId.Bottom, "MODE", "Classic", style.color)
        ensureGuideBoardSurface(deskStartPlate, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Top, "START", "Room Browser", style.color)
        ensureGuideBoardSurface(deskStartPlate, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, Enum.NormalId.Bottom, "START", "Room Browser", style.color)

        local trainingStations = {
            { "Table_Tools_1", "EMF", -10.6 },
            { "Table_Tools_2", "UV", -6.4 },
            { "Table_Tools_3", "THERMO", -2.2 },
            { "Table_Tools_4", "BOX", 2.2 },
            { "Table_Tools_5", "WRITING", 6.4 },
            { "Table_Tools_6", "CAM", 10.6 },
        }
        for _, station in ipairs(trainingStations) do
            local tablePart = ensureGuidePanelPart(folder, station[1])
            tablePart.Color = Color3.fromRGB(24, 34, 48)
            tablePart.Material = Enum.Material.Slate
            tablePart.Transparency = 0.03
            if isWideOnX then
                tablePart.Size = Vector3.new(3.1, 1.02, 1.82)
                tablePart.CFrame = anchorPart.CFrame * CFrame.new(station[3], -1.85, 12.65)
            else
                tablePart.Size = Vector3.new(1.82, 1.02, 3.1)
                tablePart.CFrame = anchorPart.CFrame * CFrame.new(12.65, -1.85, station[3])
            end
            ensureGuideBoardSurface(tablePart, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, Enum.NormalId.Top, station[2], "Training", style.color)
            ensureGuideBoardSurface(tablePart, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, Enum.NormalId.Bottom, station[2], "Training", style.color)
        end
    elseif zoneName == "ShopZone" or zoneName == "PartyZone" or zoneName == "DailyRewardZone" or zoneName == "FlexZone" then
        local kioskCopy = LOBBY_ZONE_ENTRY_KIOSK_COPY[zoneName]
        local secondaryCopy = LOBBY_ZONE_ENTRY_SECONDARY_COPY[zoneName]
        local boardBackFace = isWideOnX and Enum.NormalId.Back or Enum.NormalId.Right
        local boardFrontFace = isWideOnX and Enum.NormalId.Front or Enum.NormalId.Left

        centerBoard = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CENTER_BOARD_NAME)
        centerStand = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CENTER_STAND_NAME)
        centerBase = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CENTER_BASE_NAME)
        facadeCanopy = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CANOPY_NAME)
        facadeApron = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_APRON_NAME)
        facadeWingLeft = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_WING_LEFT_NAME)
        facadeWingRight = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_WING_RIGHT_NAME)
        forecourtPad = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_FORECOURT_PAD_NAME)
        leftBench = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_LEFT_BENCH_NAME)
        rightBench = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_RIGHT_BENCH_NAME)
        leftPlanter = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_LEFT_PLANTER_NAME)
        rightPlanter = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_RIGHT_PLANTER_NAME)
        leftPlanterTop = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_LEFT_PLANTER_TOP_NAME)
        rightPlanterTop = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_RIGHT_PLANTER_TOP_NAME)
        zoneCounter = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_ZONE_COUNTER_NAME)
        zoneCounterTop = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_ZONE_COUNTER_TOP_NAME)
        zoneLeftDisplay = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_ZONE_LEFT_DISPLAY_NAME)
        zoneRightDisplay = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_ZONE_RIGHT_DISPLAY_NAME)
        zonePrimaryProp = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_ZONE_PRIMARY_PROP_NAME)
        zoneSecondaryProp = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_ZONE_SECONDARY_PROP_NAME)

        centerBoard.Color = Color3.fromRGB(18, 26, 38)
        centerBoard.Transparency = 0.08
        centerStand.Color = Color3.fromRGB(26, 34, 48)
        centerStand.Transparency = 0.04
        centerStand.Material = Enum.Material.Metal
        centerBase.Color = Color3.fromRGB(38, 48, 64)
        centerBase.Transparency = 0.02
        centerBase.Material = Enum.Material.Slate

        for _, facadePart in ipairs({ facadeCanopy, facadeApron, facadeWingLeft, facadeWingRight }) do
            facadePart.Color = Color3.fromRGB(24, 32, 46)
            facadePart.Transparency = 0.02
        end
        facadeCanopy.Material = Enum.Material.Metal
        facadeApron.Material = Enum.Material.Slate
        facadeWingLeft.Material = Enum.Material.SmoothPlastic
        facadeWingRight.Material = Enum.Material.SmoothPlastic
        forecourtPad.Color = Color3.fromRGB(20, 30, 44)
        forecourtPad.Material = Enum.Material.Slate
        forecourtPad.Transparency = 0.04
        for _, benchPart in ipairs({ leftBench, rightBench }) do
            benchPart.Color = Color3.fromRGB(42, 54, 72)
            benchPart.Material = Enum.Material.Metal
            benchPart.Transparency = 0.03
        end
        for _, planterPart in ipairs({ leftPlanter, rightPlanter }) do
            planterPart.Color = Color3.fromRGB(32, 42, 58)
            planterPart.Material = Enum.Material.Slate
            planterPart.Transparency = 0.02
        end
        for _, planterTopPart in ipairs({ leftPlanterTop, rightPlanterTop }) do
            planterTopPart.Color = style.color:Lerp(Color3.fromRGB(112, 176, 116), 0.65)
            planterTopPart.Material = Enum.Material.Grass
            planterTopPart.Transparency = 0.04
        end
        if isWideOnX then
            applyInteriorShell(anchorPart.Size.X + 12.4, 14.8, 5.2, 7.8)
        else
            applyInteriorShell(anchorPart.Size.Z + 12.4, 14.8, 5.2, 7.8)
        end
        for _, propPart in ipairs({ zoneCounter, zoneLeftDisplay, zoneRightDisplay }) do
            propPart.Color = Color3.fromRGB(24, 34, 48)
            propPart.Material = Enum.Material.SmoothPlastic
            propPart.Transparency = 0.03
        end
        zoneCounterTop.Color = Color3.fromRGB(46, 58, 78)
        zoneCounterTop.Material = Enum.Material.Metal
        zoneCounterTop.Transparency = 0.02
        zonePrimaryProp.Color = style.color:Lerp(Color3.fromRGB(255, 255, 255), 0.18)
        zonePrimaryProp.Material = Enum.Material.Metal
        zonePrimaryProp.Transparency = 0.04
        zoneSecondaryProp.Color = style.color:Lerp(Color3.fromRGB(36, 44, 58), 0.42)
        zoneSecondaryProp.Material = Enum.Material.Neon
        zoneSecondaryProp.Transparency = 0.1

        if isWideOnX then
            centerBoard.Size = Vector3.new(4.8, 3.7, frameDepth + 0.08)
            centerBoard.CFrame = anchorPart.CFrame * CFrame.new(0, 0.35, 2.25)
            centerStand.Size = Vector3.new(0.52, 2.35, 0.52)
            centerStand.CFrame = centerBoard.CFrame * CFrame.new(0, -3.02, 0)
            centerBase.Size = Vector3.new(2.5, 0.3, 2)
            centerBase.CFrame = centerStand.CFrame * CFrame.new(0, -1.32, 0.18)
            facadeCanopy.Size = Vector3.new(anchorPart.Size.X + 4.8, 0.56, 3.2)
            facadeCanopy.CFrame = anchorPart.CFrame * CFrame.new(0, topY - 0.08, 1.7)
            facadeApron.Size = Vector3.new(anchorPart.Size.X + 6.8, 0.24, 6.6)
            facadeApron.CFrame = anchorPart.CFrame * CFrame.new(0, (-anchorPart.Size.Y * 0.5) + 0.13, 3.2)
            facadeWingLeft.Size = Vector3.new(1.05, anchorPart.Size.Y + 0.9, 2.5)
            facadeWingLeft.CFrame = anchorPart.CFrame * CFrame.new(-sideOffset - 1.2, 0, 1.28)
            facadeWingRight.Size = Vector3.new(1.05, anchorPart.Size.Y + 0.9, 2.5)
            facadeWingRight.CFrame = anchorPart.CFrame * CFrame.new(sideOffset + 1.2, 0, 1.28)
            facadeFrontWallLeft.Size = Vector3.new(28, 9.8, 0.9)
            facadeFrontWallLeft.CFrame = anchorPart.CFrame * CFrame.new(-25.2, 0.02, -0.16)
            facadeFrontWallRight.Size = Vector3.new(28, 9.8, 0.9)
            facadeFrontWallRight.CFrame = anchorPart.CFrame * CFrame.new(25.2, 0.02, -0.16)
            facadeFrontHeader.Size = Vector3.new(21.2, 1.24, 0.92)
            facadeFrontHeader.CFrame = anchorPart.CFrame * CFrame.new(0, 4.36, -0.16)
            facadeFrontAccent.Size = Vector3.new(22.2, 0.18, 0.98)
            facadeFrontAccent.CFrame = anchorPart.CFrame * CFrame.new(0, 4.95, -0.16)
            facadeWindowLeft.Size = Vector3.new(4.1, 2.4, 0.22)
            facadeWindowLeft.CFrame = anchorPart.CFrame * CFrame.new(-sideOffset - 6.0, 1.0, 1.42)
            facadeWindowRight.Size = Vector3.new(4.1, 2.4, 0.22)
            facadeWindowRight.CFrame = anchorPart.CFrame * CFrame.new(sideOffset + 6.0, 1.0, 1.42)
            facadeLampLeft.Size = Vector3.new(0.24, 3.0, 0.24)
            facadeLampLeft.CFrame = anchorPart.CFrame * CFrame.new(-sideOffset - 2.95, 1.16, 1.48)
            facadeLampRight.Size = Vector3.new(0.24, 3.0, 0.24)
            facadeLampRight.CFrame = anchorPart.CFrame * CFrame.new(sideOffset + 2.95, 1.16, 1.48)
            forecourtPad.Size = Vector3.new(anchorPart.Size.X + 10.8, 0.16, 12.8)
            forecourtPad.CFrame = anchorPart.CFrame * CFrame.new(0, (-anchorPart.Size.Y * 0.5) + 0.17, 6.1)
            leftBench.Size = Vector3.new(3.8, 0.64, 1.28)
            leftBench.CFrame = anchorPart.CFrame * CFrame.new(-sideOffset - 4.4, -2.2, 6.05)
            rightBench.Size = Vector3.new(3.8, 0.64, 1.28)
            rightBench.CFrame = anchorPart.CFrame * CFrame.new(sideOffset + 4.4, -2.2, 6.05)
            leftPlanter.Size = Vector3.new(2.28, 1.0, 1.96)
            leftPlanter.CFrame = anchorPart.CFrame * CFrame.new(-sideOffset - 1.9, -2.0, 7.6)
            rightPlanter.Size = Vector3.new(2.28, 1.0, 1.96)
            rightPlanter.CFrame = anchorPart.CFrame * CFrame.new(sideOffset + 1.9, -2.0, 7.6)
            leftPlanterTop.Size = Vector3.new(1.74, 0.32, 1.42)
            leftPlanterTop.CFrame = leftPlanter.CFrame * CFrame.new(0, 0.52, 0)
            rightPlanterTop.Size = Vector3.new(1.74, 0.32, 1.42)
            rightPlanterTop.CFrame = rightPlanter.CFrame * CFrame.new(0, 0.52, 0)
            zoneCounter.Size = Vector3.new(5.4, 1.36, 2.2)
            zoneCounter.CFrame = anchorPart.CFrame * CFrame.new(0, -1.52, 4.2)
            zoneCounterTop.Size = Vector3.new(5.8, 0.18, 2.34)
            zoneCounterTop.CFrame = zoneCounter.CFrame * CFrame.new(0, 0.77, 0)
            zoneLeftDisplay.Size = Vector3.new(1.96, 1.28, 1.54)
            zoneLeftDisplay.CFrame = anchorPart.CFrame * CFrame.new(-sideOffset - 3.3, -1.52, 4.35)
            zoneRightDisplay.Size = Vector3.new(1.96, 1.28, 1.54)
            zoneRightDisplay.CFrame = anchorPart.CFrame * CFrame.new(sideOffset + 3.3, -1.52, 4.35)
            zonePrimaryProp.Size = Vector3.new(1.0, 0.56, 0.76)
            zonePrimaryProp.CFrame = zoneCounterTop.CFrame * CFrame.new(-0.72, 0.38, -0.18)
            zoneSecondaryProp.Size = Vector3.new(0.38, 0.96, 0.38)
            zoneSecondaryProp.CFrame = zoneCounterTop.CFrame * CFrame.new(0.86, 0.54, 0.02)
        else
            facadeFrontWallLeft:Destroy()
            facadeFrontWallRight:Destroy()
            facadeFrontHeader:Destroy()
            facadeFrontAccent:Destroy()
            centerBoard.Size = Vector3.new(frameDepth + 0.08, 3.6, 4.9)
            centerBoard.CFrame = anchorPart.CFrame * CFrame.new(4.45, 0.38, 0)
            centerStand.Size = Vector3.new(0.52, 2.35, 0.52)
            centerStand.CFrame = centerBoard.CFrame * CFrame.new(0, -2.98, 0)
            centerBase.Size = Vector3.new(2.0, 0.3, 2.5)
            centerBase.CFrame = centerStand.CFrame * CFrame.new(0.18, -1.34, 0)
            facadeCanopy.Size = Vector3.new(3.2, 0.56, anchorPart.Size.Z + 4.8)
            facadeCanopy.CFrame = anchorPart.CFrame * CFrame.new(1.7, topY - 0.08, 0)
            facadeApron.Size = Vector3.new(6.6, 0.24, anchorPart.Size.Z + 6.8)
            facadeApron.CFrame = anchorPart.CFrame * CFrame.new(3.2, (-anchorPart.Size.Y * 0.5) + 0.13, 0)
            facadeWingLeft.Size = Vector3.new(2.5, anchorPart.Size.Y + 0.9, 1.05)
            facadeWingLeft.CFrame = anchorPart.CFrame * CFrame.new(1.28, 0, -sideOffset - 1.2)
            facadeWingRight.Size = Vector3.new(2.5, anchorPart.Size.Y + 0.9, 1.05)
            facadeWingRight.CFrame = anchorPart.CFrame * CFrame.new(1.28, 0, sideOffset + 1.2)
            facadeWindowLeft.Size = Vector3.new(0.22, 2.4, 4.1)
            facadeWindowLeft.CFrame = anchorPart.CFrame * CFrame.new(1.42, 1.0, -sideOffset - 6.0)
            facadeWindowRight.Size = Vector3.new(0.22, 2.4, 4.1)
            facadeWindowRight.CFrame = anchorPart.CFrame * CFrame.new(1.42, 1.0, sideOffset + 6.0)
            facadeLampLeft.Size = Vector3.new(0.24, 3.0, 0.24)
            facadeLampLeft.CFrame = anchorPart.CFrame * CFrame.new(1.48, 1.16, -sideOffset - 2.95)
            facadeLampRight.Size = Vector3.new(0.24, 3.0, 0.24)
            facadeLampRight.CFrame = anchorPart.CFrame * CFrame.new(1.48, 1.16, sideOffset + 2.95)
            forecourtPad.Size = Vector3.new(12.8, 0.16, anchorPart.Size.Z + 10.8)
            forecourtPad.CFrame = anchorPart.CFrame * CFrame.new(6.15, (-anchorPart.Size.Y * 0.5) + 0.17, 0)
            leftBench.Size = Vector3.new(1.28, 0.64, 3.8)
            leftBench.CFrame = anchorPart.CFrame * CFrame.new(5.95, -2.2, -sideOffset - 4.4)
            rightBench.Size = Vector3.new(1.28, 0.64, 3.8)
            rightBench.CFrame = anchorPart.CFrame * CFrame.new(5.95, -2.2, sideOffset + 4.4)
            leftPlanter.Size = Vector3.new(1.96, 1.0, 2.28)
            leftPlanter.CFrame = anchorPart.CFrame * CFrame.new(7.55, -2.0, -sideOffset - 1.9)
            rightPlanter.Size = Vector3.new(1.96, 1.0, 2.28)
            rightPlanter.CFrame = anchorPart.CFrame * CFrame.new(7.55, -2.0, sideOffset + 1.9)
            leftPlanterTop.Size = Vector3.new(1.42, 0.32, 1.74)
            leftPlanterTop.CFrame = leftPlanter.CFrame * CFrame.new(0, 0.52, 0)
            rightPlanterTop.Size = Vector3.new(1.42, 0.32, 1.74)
            rightPlanterTop.CFrame = rightPlanter.CFrame * CFrame.new(0, 0.52, 0)
            zoneCounter.Size = Vector3.new(2.2, 1.36, 5.4)
            zoneCounter.CFrame = anchorPart.CFrame * CFrame.new(4.18, -1.52, 0)
            zoneCounterTop.Size = Vector3.new(2.34, 0.18, 5.8)
            zoneCounterTop.CFrame = zoneCounter.CFrame * CFrame.new(0, 0.77, 0)
            zoneLeftDisplay.Size = Vector3.new(1.54, 1.28, 1.96)
            zoneLeftDisplay.CFrame = anchorPart.CFrame * CFrame.new(4.35, -1.52, -sideOffset - 3.3)
            zoneRightDisplay.Size = Vector3.new(1.54, 1.28, 1.96)
            zoneRightDisplay.CFrame = anchorPart.CFrame * CFrame.new(4.35, -1.52, sideOffset + 3.3)
            zonePrimaryProp.Size = Vector3.new(0.76, 0.56, 1.0)
            zonePrimaryProp.CFrame = zoneCounterTop.CFrame * CFrame.new(-0.18, 0.38, -0.72)
            zoneSecondaryProp.Size = Vector3.new(0.38, 0.96, 0.38)
            zoneSecondaryProp.CFrame = zoneCounterTop.CFrame * CFrame.new(0.02, 0.54, 0.86)
        end

        clearLegacyBoardGui(centerBoard)
        ensureGuideBoardSurface(centerBoard, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, boardBackFace, kioskCopy.title, kioskCopy.subtitle, style.color)
        ensureGuideBoardSurface(centerBoard, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, boardFrontFace, kioskCopy.title, kioskCopy.subtitle, style.color)
        ensureGuideBoardSurface(zoneCounter, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, boardBackFace, secondaryCopy.centerTitle, secondaryCopy.centerSubtitle, style.color)
        ensureGuideBoardSurface(zoneCounter, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, boardFrontFace, secondaryCopy.centerTitle, secondaryCopy.centerSubtitle, style.color)
        ensureGuideBoardSurface(zoneLeftDisplay, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, boardBackFace, secondaryCopy.leftTitle, secondaryCopy.leftSubtitle, style.color)
        ensureGuideBoardSurface(zoneLeftDisplay, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, boardFrontFace, secondaryCopy.leftTitle, secondaryCopy.leftSubtitle, style.color)
        ensureGuideBoardSurface(zoneRightDisplay, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, boardBackFace, secondaryCopy.rightTitle, secondaryCopy.rightSubtitle, style.color)
        ensureGuideBoardSurface(zoneRightDisplay, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, boardFrontFace, secondaryCopy.rightTitle, secondaryCopy.rightSubtitle, style.color)

        if zoneName == "ShopZone" then
            local rack = ensureGuidePanelPart(folder, "EquipmentRack")
            local tableA = ensureGuidePanelPart(folder, "DisplayTable_A")
            local tableB = ensureGuidePanelPart(folder, "DisplayTable_B")
            rack.Color = Color3.fromRGB(34, 44, 58)
            rack.Material = Enum.Material.Metal
            rack.Transparency = 0.03
            tableA.Color = Color3.fromRGB(26, 36, 50)
            tableA.Material = Enum.Material.Slate
            tableA.Transparency = 0.03
            tableB.Color = Color3.fromRGB(26, 36, 50)
            tableB.Material = Enum.Material.Slate
            tableB.Transparency = 0.03
            rack.Size = Vector3.new(0.78, 3.1, 6.8)
            rack.CFrame = anchorPart.CFrame * CFrame.new(10.65, 0.92, 0)
            tableA.Size = Vector3.new(1.8, 1.02, 2.3)
            tableA.CFrame = anchorPart.CFrame * CFrame.new(8.95, -1.86, -4.6)
            tableB.Size = Vector3.new(1.8, 1.02, 2.3)
            tableB.CFrame = anchorPart.CFrame * CFrame.new(8.95, -1.86, 4.6)
            ensureGuideBoardSurface(tableA, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, boardBackFace, "MM", "Starter • Pack", style.color)
            ensureGuideBoardSurface(tableA, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, boardFrontFace, "MM", "Starter • Pack", style.color)
            ensureGuideBoardSurface(tableB, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, boardBackFace, "PP", "Bonus • Bundle", style.color)
            ensureGuideBoardSurface(tableB, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, boardFrontFace, "PP", "Bonus • Bundle", style.color)
            ensureGuideBoardSurface(rack, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, boardBackFace, "RACK", "Utility • Equip", style.color)
            ensureGuideBoardSurface(rack, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, boardFrontFace, "RACK", "Utility • Equip", style.color)
        elseif zoneName == "PartyZone" then
            local platform = ensureGuidePanelPart(folder, "PartyPlatform")
            local board = ensureGuidePanelPart(folder, "PartyBoard")
            local terminal = ensureGuidePanelPart(folder, "PartyTerminal")
            platform.Color = Color3.fromRGB(26, 36, 50)
            platform.Material = Enum.Material.Slate
            platform.Transparency = 0.03
            board.Color = Color3.fromRGB(16, 24, 36)
            board.Material = Enum.Material.SmoothPlastic
            board.Transparency = 0.02
            terminal.Color = Color3.fromRGB(34, 44, 58)
            terminal.Material = Enum.Material.Metal
            terminal.Transparency = 0.03
            platform.Size = Vector3.new(5.8, 0.18, 5.8)
            platform.CFrame = anchorPart.CFrame * CFrame.new(8.25, -2.47, 0)
            board.Size = Vector3.new(0.42, 3.5, 5.4)
            board.CFrame = anchorPart.CFrame * CFrame.new(10.55, -0.08, -2.9)
            terminal.Size = Vector3.new(1.12, 1.4, 1.12)
            terminal.CFrame = anchorPart.CFrame * CFrame.new(9.8, -1.72, 2.85)
            ensureGuideBoardSurface(board, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, boardBackFace, "PARTY BOARD", "Create • Invite • Room", style.color)
            ensureGuideBoardSurface(board, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, boardFrontFace, "PARTY BOARD", "Create • Invite • Room", style.color)
            ensureGuideBoardSurface(terminal, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, boardBackFace, "TERMINAL", "Ready • Confirm", style.color)
            ensureGuideBoardSurface(terminal, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, boardFrontFace, "TERMINAL", "Ready • Confirm", style.color)
        elseif zoneName == "DailyRewardZone" then
            local terminal = ensureGuidePanelPart(folder, "DailyRewardTerminal")
            local npcSpotA = ensureNeonGuidePart(folder, "NPCSpot_A")
            local npcSpotB = ensureNeonGuidePart(folder, "NPCSpot_B")
            terminal.Color = Color3.fromRGB(24, 34, 48)
            terminal.Material = Enum.Material.SmoothPlastic
            terminal.Transparency = 0.03
            terminal.Size = Vector3.new(2.4, 1.46, 1.84)
            terminal.CFrame = anchorPart.CFrame * CFrame.new(0, -1.78, 8.95)
            npcSpotA.Color = style.color:Lerp(Color3.fromRGB(255, 255, 255), 0.22)
            npcSpotA.Transparency = 0.12
            npcSpotA.Size = Vector3.new(2.8, 0.1, 2.8)
            npcSpotA.CFrame = anchorPart.CFrame * CFrame.new(-5.1, -2.43, 9.8)
            npcSpotB.Color = style.color:Lerp(Color3.fromRGB(255, 255, 255), 0.22)
            npcSpotB.Transparency = 0.12
            npcSpotB.Size = Vector3.new(2.8, 0.1, 2.8)
            npcSpotB.CFrame = anchorPart.CFrame * CFrame.new(5.1, -2.43, 9.8)
            ensureGuideBoardSurface(terminal, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, boardBackFace, "CLAIM", "Daily • Reward", style.color)
            ensureGuideBoardSurface(terminal, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, boardFrontFace, "CLAIM", "Daily • Reward", style.color)
        elseif zoneName == "FlexZone" then
            local stage = ensureGuidePanelPart(folder, "FlexStage")
            local board = ensureGuidePanelPart(folder, "AnnouncementBoard")
            local pedestalLeft = ensureGuidePanelPart(folder, "SpotlightPedestalLeft")
            local pedestalRight = ensureGuidePanelPart(folder, "SpotlightPedestalRight")
            stage.Color = Color3.fromRGB(26, 36, 50)
            stage.Material = Enum.Material.Slate
            stage.Transparency = 0.03
            board.Color = Color3.fromRGB(16, 24, 36)
            board.Material = Enum.Material.SmoothPlastic
            board.Transparency = 0.02
            pedestalLeft.Color = Color3.fromRGB(34, 44, 58)
            pedestalLeft.Material = Enum.Material.Metal
            pedestalLeft.Transparency = 0.03
            pedestalRight.Color = Color3.fromRGB(34, 44, 58)
            pedestalRight.Material = Enum.Material.Metal
            pedestalRight.Transparency = 0.03
            stage.Size = Vector3.new(5.8, 0.22, 5.8)
            stage.CFrame = anchorPart.CFrame * CFrame.new(8.45, -2.45, 0)
            board.Size = Vector3.new(0.42, 3.6, 5.6)
            board.CFrame = anchorPart.CFrame * CFrame.new(10.7, 0.0, 0)
            pedestalLeft.Size = Vector3.new(1.26, 1.18, 1.26)
            pedestalLeft.CFrame = anchorPart.CFrame * CFrame.new(8.4, -1.96, -4.0)
            pedestalRight.Size = Vector3.new(1.26, 1.18, 1.26)
            pedestalRight.CFrame = anchorPart.CFrame * CFrame.new(8.4, -1.96, 4.0)
            ensureGuideBoardSurface(board, LOBBY_ZONE_ENTRY_GUIDE_BOARD_BACK_SURFACE_NAME, boardBackFace, "ANNOUNCEMENT", "Featured • Event", style.color)
            ensureGuideBoardSurface(board, LOBBY_ZONE_ENTRY_GUIDE_BOARD_FRONT_SURFACE_NAME, boardFrontFace, "ANNOUNCEMENT", "Featured • Event", style.color)
        end

        if contractBoard then
            contractBoard:Destroy()
        end
        if toolsBoard then
            toolsBoard:Destroy()
        end
        if contractStand then
            contractStand:Destroy()
        end
        if toolsStand then
            toolsStand:Destroy()
        end
        if contractBase then
            contractBase:Destroy()
        end
        if toolsBase then
            toolsBase:Destroy()
        end
    else
        if contractBoard then
            contractBoard:Destroy()
        end
        if toolsBoard then
            toolsBoard:Destroy()
        end
        if centerBoard then
            centerBoard:Destroy()
        end
        if contractStand then
            contractStand:Destroy()
        end
        if toolsStand then
            toolsStand:Destroy()
        end
        if centerStand then
            centerStand:Destroy()
        end
        if contractBase then
            contractBase:Destroy()
        end
        if toolsBase then
            toolsBase:Destroy()
        end
        if centerBase then
            centerBase:Destroy()
        end
        if centerDesk then
            centerDesk:Destroy()
        end
        if centerDeskTop then
            centerDeskTop:Destroy()
        end
        if leftCase then
            leftCase:Destroy()
        end
        if rightCase then
            rightCase:Destroy()
        end
        if centerBackdrop then
            centerBackdrop:Destroy()
        end
        if floorRunner then
            floorRunner:Destroy()
        end
        if leftCaseStrip then
            leftCaseStrip:Destroy()
        end
        if rightCaseStrip then
            rightCaseStrip:Destroy()
        end
        if contractClipboard then
            contractClipboard:Destroy()
        end
        if contractPaper then
            contractPaper:Destroy()
        end
        if roomLedger then
            roomLedger:Destroy()
        end
        if roomCards then
            roomCards:Destroy()
        end
        if toolDisplayEMF then
            toolDisplayEMF:Destroy()
        end
        if toolDisplayUV then
            toolDisplayUV:Destroy()
        end
        if toolDisplayBox then
            toolDisplayBox:Destroy()
        end
        if deskMapPlate then
            deskMapPlate:Destroy()
        end
        if deskModePlate then
            deskModePlate:Destroy()
        end
        if deskStartPlate then
            deskStartPlate:Destroy()
        end
        if facadeCanopy then
            facadeCanopy:Destroy()
        end
        if facadeApron then
            facadeApron:Destroy()
        end
        if facadeWingLeft then
            facadeWingLeft:Destroy()
        end
        if facadeWingRight then
            facadeWingRight:Destroy()
        end
        local facadeFrontWallLeft = folder:FindFirstChild("FacadeFrontWallLeft")
        local facadeFrontWallRight = folder:FindFirstChild("FacadeFrontWallRight")
        local facadeFrontHeader = folder:FindFirstChild("FacadeFrontHeader")
        local facadeFrontAccent = folder:FindFirstChild("FacadeFrontAccent")
        if facadeFrontWallLeft then
            facadeFrontWallLeft:Destroy()
        end
        if facadeFrontWallRight then
            facadeFrontWallRight:Destroy()
        end
        if facadeFrontHeader then
            facadeFrontHeader:Destroy()
        end
        if facadeFrontAccent then
            facadeFrontAccent:Destroy()
        end
        if facadeWindowLeft then
            facadeWindowLeft:Destroy()
        end
        if facadeWindowRight then
            facadeWindowRight:Destroy()
        end
        if facadeLampLeft then
            facadeLampLeft:Destroy()
        end
        if facadeLampRight then
            facadeLampRight:Destroy()
        end
        if forecourtPad then
            forecourtPad:Destroy()
        end
        if leftBench then
            leftBench:Destroy()
        end
        if rightBench then
            rightBench:Destroy()
        end
        if leftPlanter then
            leftPlanter:Destroy()
        end
        if rightPlanter then
            rightPlanter:Destroy()
        end
        if leftPlanterTop then
            leftPlanterTop:Destroy()
        end
        if rightPlanterTop then
            rightPlanterTop:Destroy()
        end
        if zoneCounter then
            zoneCounter:Destroy()
        end
        if zoneCounterTop then
            zoneCounterTop:Destroy()
        end
        if zoneLeftDisplay then
            zoneLeftDisplay:Destroy()
        end
        if zoneRightDisplay then
            zoneRightDisplay:Destroy()
        end
        if zonePrimaryProp then
            zonePrimaryProp:Destroy()
        end
        if zoneSecondaryProp then
            zoneSecondaryProp:Destroy()
        end
    end

    local panel = billboard:FindFirstChild("Panel")
    if not (panel and panel:IsA("Frame")) then
        if panel then
            panel:Destroy()
        end
        panel = Instance.new("Frame")
        panel.Name = "Panel"
        panel.Parent = billboard

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = panel

        local stroke = Instance.new("UIStroke")
        stroke.Name = "Stroke"
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = style.color
        stroke.Transparency = 0.18
        stroke.Thickness = 1.2
        stroke.Parent = panel

        local accent = Instance.new("Frame")
        accent.Name = "Accent"
        accent.AnchorPoint = Vector2.new(0, 0.5)
        accent.BackgroundColor3 = style.color
        accent.BorderSizePixel = 0
        accent.Position = UDim2.new(0, 10, 0.5, 0)
        accent.Size = UDim2.fromOffset(3, 24)
        accent.Parent = panel

        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(1, 0)
        accentCorner.Parent = accent

        createGuideTextLabel(
            "Title",
            Enum.Font.GothamBold,
            13,
            Color3.fromRGB(245, 248, 252),
            copy.title,
            18,
            UDim2.new(0, 20, 0, 6)
        ).Parent = panel

        createGuideTextLabel(
            "Subtitle",
            Enum.Font.GothamMedium,
            10,
            style.color:Lerp(Color3.fromRGB(240, 244, 248), 0.25),
            copy.subtitle,
            16,
            UDim2.new(0, 20, 0, 23)
        ).Parent = panel

        if type(copy.meta) == "string" and copy.meta ~= "" then
            createGuideTextLabel(
                "Meta",
                Enum.Font.GothamBold,
                9,
                style.color:Lerp(Color3.fromRGB(255, 255, 255), 0.45),
                copy.meta,
                14,
                UDim2.new(0, 20, 0, 39)
            ).Parent = panel
        end
    end

    panel.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
    panel.BackgroundTransparency = 0.14
    panel.BorderSizePixel = 0
    panel.Size = UDim2.fromScale(1, 1)
    return true
end

function LobbyService:_syncZoneGuides()
    self:_clearZoneGuides()
    self:_clearZoneEntryGuides()
    if LOBBY_ZONE_GUIDES_ENABLED ~= true and LOBBY_ZONE_ENTRY_GUIDES_ENABLED ~= true then
        return
    end
    local zoneParts = self._zoneManager and self._zoneManager:GetZoneParts() or {}
    local processedEntryZones = {}
    for zoneName, zonePart in pairs(zoneParts) do
        if LOBBY_ZONE_GUIDES_ENABLED == true then
            self:_ensureZoneGuide(zoneName, zonePart)
        end
        if LOBBY_ZONE_ENTRY_GUIDES_ENABLED == true then
            self:_ensureZoneEntryGuide(zoneName)
            processedEntryZones[zoneName] = true
        end
    end
    if LOBBY_ZONE_ENTRY_GUIDES_ENABLED == true then
        for zoneName in pairs(LOBBY_ZONE_ENTRY_ANCHORS) do
            if not processedEntryZones[zoneName] then
                self:_ensureZoneEntryGuide(zoneName)
            end
        end
    end
end

function LobbyService:Init()
    self._state:Set("lobbyStatus", "initialized")
    self._dependencies.PlayerProfileSystem = Services.Get(self._deps, "PlayerProfileSystem")
    self._state:Set("flexZoneState", self:_getFlexState())
    self:_loadCosmeticCatalog()
    self._playerManager:Init()
    self._zoneManager:Init()
    self._interaction:Init()
    self._partySystem:Init()
    self._population:Init()

    self._zoneManager:SetZoneEnteredCallback(function(player, zoneName)
        self:OnPlayerEnteredZone(player, zoneName)
    end)
    self._partySystem:SetCallbacks({
        onPlayerJoinedParty = function(player, party)
            self:_publish("PlayerJoinedParty", {
                player = player,
                partyId = party.partyId,
                leader = party.leader,
                members = party.members,
            })
        end,
    })
end

function LobbyService:Start()
    self._state:Set("lobbyStatus", "running")
    self._playerManager:Start()
    self._zoneManager:Start()
    sanitizeLobbyLogicVolumes()
    applyMainHubVisualPatch()
    self:_refreshNorthContractBoard()
    self:_syncZoneGuides()
    self:_bindWorldPrompts()
    self._interaction:Start()
    self._partySystem:Start()
    self._population:Start()
end

function LobbyService:Stop()
    self._state:Set("lobbyStatus", "stopped")
    self:_clearZoneGuides()
    self:_clearZoneEntryGuides()
    self:_disconnectPromptConnections()
    self._zoneManager:Stop()
    self._interaction:Stop()
    self._partySystem:Stop()
    self._playerManager:Stop()
    self._population:Stop()
    self._state:Set("flexZoneState", {
        participantsByUserId = {},
        rotationOrder = {},
        spotlightUserId = nil,
    })

    for userId in pairs(self._characterConnections) do
        self:_disconnectCharacterConnection(userId)
    end
end

function LobbyService:RegisterPlayer(player)
    local alreadyInLobby = self._playerManager:IsInLobby(player)
    local ok, reason = self._playerManager:RegisterPlayer(player)
    if not ok then
        return false, reason
    end
    if alreadyInLobby then
        return true
    end

    self:_ensureCharacterConnection(player)
    self:_publish("PlayerEnteredLobby", {
        player = player,
    })
    local flexState = self:_getFlexState()
    if type(flexState.lastPayload) == "table" and type(flexState.lastPayload.eventName) == "string" then
        local replayPayload = cloneMap(flexState.lastPayload)
        replayPayload.recipients = { player }
        self:_publish(replayPayload.eventName, replayPayload)
    end
    self:_refreshPopulation()
    task.defer(function()
        self:_renderLobbyCosmetics(player, player.Character, self:_getAppliedCosmetics(player))
    end)
    return true
end

function LobbyService:RemovePlayer(player)
    if not self._playerManager:IsInLobby(player) then
        return true
    end

    local ok, reason = self._playerManager:RemovePlayer(player)
    if not ok then
        return false, reason
    end

    self:_disconnectCharacterConnection(player.UserId)
    self:_clearCosmeticVisuals(player.Character)
    self:_removeFlexParticipant(player)
    self._partySystem:LeaveParty(player)
    self:_refreshPopulation()
    return true
end

function LobbyService:GetLobbyPlayers()
    return self._playerManager:GetLobbyPlayers()
end

function LobbyService:CreateParty(player)
    return self._partySystem:CreateParty(player)
end

function LobbyService:InvitePlayer(partyId, player)
    return self._partySystem:InvitePlayer(partyId, player)
end

function LobbyService:DisbandParty(partyId)
    return self._partySystem:DisbandParty(partyId)
end

function LobbyService:PrepareGroupMatchmaking(player)
    return self._partySystem:PrepareGroupMatchmaking(player)
end

function LobbyService:StartMatchmaking(player, payload)
    local matchmakingPackage, reason = self._partySystem:PrepareGroupMatchmaking(player)
    if not matchmakingPackage then
        return false, reason
    end

    self:_publish("MatchmakingStarted", {
        partyId = matchmakingPackage.partyId,
        leader = matchmakingPackage.leader,
        players = matchmakingPackage.players,
        queueType = matchmakingPackage.queueType,
        mapId = payload and payload.mapId or nil,
        difficulty = payload and payload.difficulty or nil,
        mode = payload and (payload.mode or payload.gameMode) or "Classic",
        gameMode = payload and (payload.gameMode or payload.mode) or "Classic",
        averageRankScore = payload and payload.averageRankScore or nil,
        playerRankScores = payload and payload.playerRankScores or nil,
        rankedDifficulty = payload and payload.rankedDifficulty or nil,
    })
    return true
end

function LobbyService:OnPlayerEnteredZone(player, zoneName)
    if not self._playerManager:IsInLobby(player) then
        return
    end

    self._interaction:HandleZoneEntry(player, zoneName)
    local zoneFeedback = LOBBY_ZONE_FEEDBACK[zoneName]
    local zoneStyle = LOBBY_ZONE_GUIDE_STYLE[zoneName]
    local zoneEntryCopy = LOBBY_ZONE_ENTRY_COPY[zoneName]
    if type(zoneFeedback) == "table" then
        self:_publish("LobbyZoneFocused", {
            eventName = "LobbyZoneFocused",
            zoneName = zoneName,
            title = zoneFeedback.title,
            hint = zoneFeedback.hint,
            badge = type(zoneEntryCopy) == "table" and zoneEntryCopy.title or zoneName,
            subtitle = type(zoneStyle) == "table" and zoneStyle.subtitle or "",
            accentColor = type(zoneStyle) == "table" and zoneStyle.color or nil,
            recipients = { player },
        })
    end

    if zoneName == "FlexZone" then
        self:_activateFlexSpotlight(player, "zone_entered")
    end
end

function LobbyService:HandlePlayerTeleported(payload)
    local player = payload and payload.player
    local mapId = payload and payload.mapId
    if not player then
        return
    end

    if mapId == "Lobby" then
        self:RegisterPlayer(player)
    else
        self:RemovePlayer(player)
    end
end

function LobbyService:ApplyCosmetics(player, equippedCosmetics)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end

    local snapshot = self:_setAppliedCosmetics(player, equippedCosmetics)
    self:_renderLobbyCosmetics(player, player.Character, snapshot)

    self:_publish("LobbyCosmeticApplied", {
        player = player,
        userId = userId,
        equipped = snapshot,
    })
    self:_refreshFlexParticipant(player, "cosmetics_updated")
    return true
end

function LobbyService:ApplyCosmetic(player, cosmeticId, category)
    local slot = category
    if (type(slot) ~= "string" or slot == "") and type(cosmeticId) == "string" then
        local catalogEntry = self._cosmeticCatalogById[cosmeticId]
        slot = type(catalogEntry) == "table" and catalogEntry.slot or nil
    end
    if type(slot) ~= "string" or slot == "" then
        return false, "invalid_slot"
    end

    local equipped = self:_getAppliedCosmetics(player)
    if type(cosmeticId) == "string" and cosmeticId ~= "" then
        equipped[slot] = cosmeticId
    else
        equipped[slot] = nil
    end

    return self:ApplyCosmetics(player, equipped)
end

return LobbyService


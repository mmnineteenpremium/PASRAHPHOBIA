--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local MapLoader = {}

local MAPS_FOLDER_NAME = "Maps"
local CURRENT_MAP_NAME = "CurrentMap"

-- =========================================
-- Internal Helpers
-- =========================================

local function getMapsFolder(): Folder
	local maps = ReplicatedStorage:FindFirstChild(MAPS_FOLDER_NAME)
	assert(maps and maps:IsA("Folder"),
		"[MapLoader] ReplicatedStorage.Maps not found"
	)
	return maps
end

local function getOrCreateCurrentMap(): Folder
	local existing = Workspace:FindFirstChild(CURRENT_MAP_NAME)

	if existing then
		existing:ClearAllChildren()
		return existing :: Folder
	end

	local folder = Instance.new("Folder")
	folder.Name = CURRENT_MAP_NAME
	folder.Parent = Workspace

	return folder
end

-- =========================================
-- Public API
-- =========================================

function MapLoader.Load(mapName: string): Model
	assert(type(mapName) == "string",
		"[MapLoader] mapName must be string"
	)

	local mapsFolder = getMapsFolder()

	-- With Rojo .model.json structure:
	-- Maps
	--  └── AbandonedPalace (Folder)
	--        └── AbandonedPalace (Model)

	local mapContainer = mapsFolder:FindFirstChild(mapName)
	assert(mapContainer and mapContainer:IsA("Folder"),
		"[MapLoader] Map container not found: " .. mapName
	)

local mapModel: Model? = nil

for _, child in ipairs(mapContainer:GetChildren()) do
	if child:IsA("Model") then
		mapModel = child
		break
	end
end

assert(mapModel,
	"[MapLoader] No Model found inside container: " .. mapName
)

	local currentMapFolder = getOrCreateCurrentMap()

	local clonedMap = mapModel:Clone()
	clonedMap.Parent = currentMapFolder

	print("[MapLoader] Loaded map:", mapName)

	return clonedMap
end

return MapLoader
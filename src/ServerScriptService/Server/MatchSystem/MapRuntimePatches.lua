local MapRuntimePatches = {}

local FLOOR_PATCH_ATTR = "SecondFloorRuntimePatched"
local MIN_SEGMENT_SIZE = 0.25
local STAIR_MARGIN = 0.75

local function normalizeToken(value)
	if type(value) ~= "string" then
		return nil
	end
	return value:gsub("[%s_%-%.]+", ""):lower()
end

local function getXZBounds(part)
	local halfSize = part.Size * 0.5
	return {
		minX = part.Position.X - halfSize.X,
		maxX = part.Position.X + halfSize.X,
		minZ = part.Position.Z - halfSize.Z,
		maxZ = part.Position.Z + halfSize.Z,
	}
end

local function hasArea(bounds)
	return bounds
		and (bounds.maxX - bounds.minX) > MIN_SEGMENT_SIZE
		and (bounds.maxZ - bounds.minZ) > MIN_SEGMENT_SIZE
end

local function intersectsXZ(a, b)
	if not a or not b then
		return false
	end
	return a.maxX > b.minX
		and a.minX < b.maxX
		and a.maxZ > b.minZ
		and a.minZ < b.maxZ
end

local function createFloorSegment(source, parent, name, bounds)
	if not hasArea(bounds) then
		return nil
	end

	local segment = source:Clone()
	segment.Name = name
	segment.Size = Vector3.new(bounds.maxX - bounds.minX, source.Size.Y, bounds.maxZ - bounds.minZ)
	segment.Position = Vector3.new(
		(bounds.minX + bounds.maxX) * 0.5,
		source.Position.Y,
		(bounds.minZ + bounds.maxZ) * 0.5
	)
	segment.Parent = parent
	return segment
end

local function collectStairBounds(mapClone)
	local bounds = nil

	for _, descendant in ipairs(mapClone:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local includePart = descendant.Name == "CentralStaircase" or string.match(descendant.Name, "^StairStep_") ~= nil
			if includePart then
				local partBounds = getXZBounds(descendant)
				if bounds == nil then
					bounds = partBounds
				else
					bounds.minX = math.min(bounds.minX, partBounds.minX)
					bounds.maxX = math.max(bounds.maxX, partBounds.maxX)
					bounds.minZ = math.min(bounds.minZ, partBounds.minZ)
					bounds.maxZ = math.max(bounds.maxZ, partBounds.maxZ)
				end
			end
		end
	end

	if bounds == nil then
		return nil
	end

	return {
		minX = bounds.minX - STAIR_MARGIN,
		maxX = bounds.maxX + STAIR_MARGIN,
		minZ = bounds.minZ - STAIR_MARGIN,
		maxZ = bounds.maxZ + STAIR_MARGIN,
	}
end

local function carveFloorAroundStairs(floorPart, stairBounds)
	if not floorPart or not floorPart:IsA("BasePart") or not hasArea(stairBounds) then
		return false
	end

	local floorBounds = getXZBounds(floorPart)
	if not intersectsXZ(floorBounds, stairBounds) then
		return false
	end

	local cutBounds = {
		minX = math.max(floorBounds.minX, stairBounds.minX),
		maxX = math.min(floorBounds.maxX, stairBounds.maxX),
		minZ = math.max(floorBounds.minZ, stairBounds.minZ),
		maxZ = math.min(floorBounds.maxZ, stairBounds.maxZ),
	}
	if not hasArea(cutBounds) then
		return false
	end

	local fragments = {
		{
			name = floorPart.Name .. "_North",
			bounds = {
				minX = floorBounds.minX,
				maxX = floorBounds.maxX,
				minZ = floorBounds.minZ,
				maxZ = cutBounds.minZ,
			},
		},
		{
			name = floorPart.Name .. "_South",
			bounds = {
				minX = floorBounds.minX,
				maxX = floorBounds.maxX,
				minZ = cutBounds.maxZ,
				maxZ = floorBounds.maxZ,
			},
		},
		{
			name = floorPart.Name .. "_West",
			bounds = {
				minX = floorBounds.minX,
				maxX = cutBounds.minX,
				minZ = cutBounds.minZ,
				maxZ = cutBounds.maxZ,
			},
		},
		{
			name = floorPart.Name .. "_East",
			bounds = {
				minX = cutBounds.maxX,
				maxX = floorBounds.maxX,
				minZ = cutBounds.minZ,
				maxZ = cutBounds.maxZ,
			},
		},
	}

	local parent = floorPart.Parent
	floorPart:Destroy()
	if not parent then
		return true
	end

	for _, fragment in ipairs(fragments) do
		if hasArea(fragment.bounds) then
			createFloorSegment(floorPart, parent, fragment.name, fragment.bounds)
		end
	end
	return true
end

local function patchSecondFloor(mapClone)
	if not mapClone or mapClone:GetAttribute(FLOOR_PATCH_ATTR) == true then
		return false
	end

	local removedDuplicateFloor = false
	local segmentedFloors = {}
	for _, descendant in ipairs(mapClone:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name == "Floor_2_Main" then
			removedDuplicateFloor = true
			descendant:Destroy()
		elseif descendant:IsA("BasePart") and string.match(descendant.Name, "^Floor_2_") ~= nil then
			table.insert(segmentedFloors, descendant)
		end
	end

	local stairBounds = collectStairBounds(mapClone)
	local carvedAnyFloor = false
	if stairBounds ~= nil then
		for _, floorPart in ipairs(segmentedFloors) do
			local isNorthFloor = string.match(floorPart.Name, "North") ~= nil
			if floorPart.Parent ~= nil and isNorthFloor then
				local carved = carveFloorAroundStairs(floorPart, stairBounds)
				carvedAnyFloor = carvedAnyFloor or carved
			end
		end
	end

	local didPatch = removedDuplicateFloor or carvedAnyFloor
	if didPatch then
		mapClone:SetAttribute(FLOOR_PATCH_ATTR, true)
	end
	return didPatch
end

function MapRuntimePatches.Apply(mapId, mapClone)
	local token = normalizeToken(mapId)
	if token == nil or mapClone == nil then
		return false
	end
	return patchSecondFloor(mapClone)
end

return MapRuntimePatches

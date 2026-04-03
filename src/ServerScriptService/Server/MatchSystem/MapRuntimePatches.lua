local MapRuntimePatches = {}

local FLOOR_PATCH_ATTR = "SecondFloorRuntimePatched"
local INTERACTION_PATCH_ATTR = "InteractionPointsRuntimePatched"
local DOOR_PATCH_ATTR = "DoorTraversalRuntimePatched"
local SAFE_ZONE_PATCH_ATTR = "SafeZoneRuntimePatched"
local DOOR_MODE_ATTR = "DoorTraversalMode"
local DOOR_POLICY_ATTR = "DoorTraversalPolicy"
local DOOR_OPEN_SOUND_ATTR = "DoorOpenSoundId"
local DOOR_CLOSE_SOUND_ATTR = "DoorCloseSoundId"
local DEFAULT_DOOR_POLICY = "HybridRadiusPrompt"
local DEFAULT_DOOR_OPEN_SOUND_ID = "rbxassetid://139204195403262"
local DEFAULT_DOOR_CLOSE_SOUND_ID = "rbxassetid://83336813491039"
local MIN_SEGMENT_SIZE = 0.25
local STAIR_MARGIN = 0.75
local INTERACTION_HEIGHT_OFFSET = 1.5
local INTERACTION_POSITION_OVERRIDES = {
}
local INTERACTION_DOOR_OVERRIDES = {
	hauntedhouse = {
		Interact_Bedroom1 = {
			doorName = "Door_Bedroom1",
			insideOffset = 5,
		},
		Interact_Kitchen = {
			doorName = "Door_Kitchen",
			insideOffset = 5,
		},
	},
	emptybuilding = {
		Interact_WorkspaceOpen = {
			doorName = "Door_WorkspaceOpen",
			insideOffset = 6,
		},
		Interact_OfficeB = {
			doorName = "Door_OfficeB",
			insideOffset = 5,
		},
		Interact_Bathroom1 = {
			doorName = "Door_Bathroom1",
			insideOffset = 4,
		},
	},
}
local SAFE_ZONE_POSITION_OVERRIDES = {
	abandonedpalace = {
		SafeZone_1 = Vector3.new(-63.2, 4, 32.4),
	},
	emptybuilding = {
		SafeZone_1 = Vector3.new(778, 4, -10),
		SafeZone_2 = Vector3.new(824, 4, -20),
	},
	studiommnineteen = {
		SafeZone_1 = Vector3.new(369.4, 4, 18.2),
	},
}

local function normalizeToken(value)
	if type(value) ~= "string" then
		return nil
	end
	return value:gsub("[%s_%-%.]+", ""):lower()
end

local function resolveMapOverrideToken(mapId, mapClone)
	local primaryToken = normalizeToken(mapId)
	if primaryToken then
		return primaryToken
	end
	if typeof(mapClone) == "Instance" then
		return normalizeToken(mapClone.Name)
	end
	return nil
end

local function flattenDirection(vector)
	if typeof(vector) ~= "Vector3" then
		return nil
	end

	local flattened = Vector3.new(vector.X, 0, vector.Z)
	if flattened.Magnitude <= 1e-4 then
		return nil
	end
	return flattened.Unit
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

local function patchInteractionPoints(mapId, mapClone)
	if not mapClone or mapClone:GetAttribute(INTERACTION_PATCH_ATTR) == true then
		return false
	end

	local mapToken = resolveMapOverrideToken(mapId, mapClone)
	if mapToken and INTERACTION_POSITION_OVERRIDES[mapToken] == nil then
		mapToken = resolveMapOverrideToken(nil, mapClone)
	end
	local interactionOverrides = mapToken and INTERACTION_POSITION_OVERRIDES[mapToken] or nil
	local interactionDoorOverrides = mapToken and INTERACTION_DOOR_OVERRIDES[mapToken] or nil

	local roomsFolder = mapClone:FindFirstChild("Rooms", true)
	local interactionPointsFolder = mapClone:FindFirstChild("InteractionPoints", true)
	local doorsFolder = mapClone:FindFirstChild("Doors", true)
	if not roomsFolder or not interactionPointsFolder then
		return false
	end

	local roomsByToken = {}
	for _, room in ipairs(roomsFolder:GetChildren()) do
		if room:IsA("BasePart") then
			local token = normalizeToken(room.Name:gsub("^Room_", ""))
			if token then
				roomsByToken[token] = room
			end
		end
	end

	local movedAny = false
	for _, interactionPoint in ipairs(interactionPointsFolder:GetChildren()) do
		if interactionPoint:IsA("BasePart") then
			local token = normalizeToken(interactionPoint.Name:gsub("^Interact_", ""))
			local room = token and roomsByToken[token] or nil
			if room then
				local targetPosition = room.Position + Vector3.new(0, INTERACTION_HEIGHT_OFFSET, 0)
				local doorOverride = interactionDoorOverrides and interactionDoorOverrides[interactionPoint.Name]
				if type(doorOverride) == "table" and doorsFolder then
					local door = doorsFolder:FindFirstChild(doorOverride.doorName)
					if door and door:IsA("BasePart") then
						local directionToRoom = flattenDirection(room.Position - door.Position)
						local insideOffset = tonumber(doorOverride.insideOffset) or 4
						if directionToRoom then
							targetPosition = Vector3.new(
								door.Position.X,
								room.Position.Y + INTERACTION_HEIGHT_OFFSET,
								door.Position.Z
							) + (directionToRoom * insideOffset)
						end
					end
				end
				local explicitOverride = interactionOverrides and interactionOverrides[interactionPoint.Name]
				if typeof(explicitOverride) == "Vector3" then
					targetPosition = explicitOverride
				end
				if (interactionPoint.Position - targetPosition).Magnitude > 0.5 then
					interactionPoint.CFrame = CFrame.new(targetPosition)
					movedAny = true
				end
			end
		end
	end

	if movedAny then
		mapClone:SetAttribute(INTERACTION_PATCH_ATTR, true)
	end
	return movedAny
end

local function ensureDoorPathModifier(part)
	local existing = part:FindFirstChild("DoorPathModifier")
	if existing and existing:IsA("PathfindingModifier") then
		existing.Label = "Doorway"
		existing.PassThrough = true
		return existing
	end

	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("PathfindingModifier") then
			child.Name = "DoorPathModifier"
			child.Label = "Doorway"
			child.PassThrough = true
			return child
		end
	end

	local ok, modifier = pcall(Instance.new, "PathfindingModifier")
	if not ok or not modifier then
		return nil
	end
	modifier.Name = "DoorPathModifier"
	modifier.Label = "Doorway"
	modifier.PassThrough = true
	modifier.Parent = part
	return modifier
end

local function patchDoorTraversal(mapClone)
	if not mapClone or mapClone:GetAttribute(DOOR_PATCH_ATTR) == true then
		return false
	end

	local doorsFolder = mapClone:FindFirstChild("Doors", true)
	if not doorsFolder then
		return false
	end

	-- MatchTeleport clones every playable map for both Classic and Ranked, so this fallback stays mode-agnostic.
	local patchedAny = false
	for _, descendant in ipairs(doorsFolder:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name:match("^Door_") and not descendant.Name:match("_Frame") then
			descendant.Anchored = true
			descendant.CanCollide = true
			descendant.CanTouch = true
			descendant.CanQuery = true
			descendant:SetAttribute("DoorLocked", false)
			descendant:SetAttribute("DoorIsOpen", false)
			descendant:SetAttribute(DOOR_POLICY_ATTR, DEFAULT_DOOR_POLICY)
			descendant:SetAttribute(DOOR_OPEN_SOUND_ATTR, DEFAULT_DOOR_OPEN_SOUND_ID)
			descendant:SetAttribute(DOOR_CLOSE_SOUND_ATTR, DEFAULT_DOOR_CLOSE_SOUND_ID)
			ensureDoorPathModifier(descendant)
			patchedAny = true
		end
	end

	if patchedAny then
		mapClone:SetAttribute(DOOR_PATCH_ATTR, true)
		mapClone:SetAttribute(DOOR_MODE_ATTR, DEFAULT_DOOR_POLICY)
	end
	return patchedAny
end

local function patchSafeZones(mapId, mapClone)
	local token = resolveMapOverrideToken(mapId, mapClone)
	if token and SAFE_ZONE_POSITION_OVERRIDES[token] == nil then
		token = resolveMapOverrideToken(nil, mapClone)
	end
	local overrides = token and SAFE_ZONE_POSITION_OVERRIDES[token]
	if not mapClone or not overrides or mapClone:GetAttribute(SAFE_ZONE_PATCH_ATTR) == true then
		return false
	end

	local safeZonesFolder = mapClone:FindFirstChild("SafeZones", true)
	if not safeZonesFolder then
		return false
	end

	local patchedAny = false
	for zoneName, targetPosition in pairs(overrides) do
		local zone = safeZonesFolder:FindFirstChild(zoneName)
		if zone and zone:IsA("BasePart") then
			if (zone.Position - targetPosition).Magnitude > 0.05 then
				zone.CFrame = CFrame.new(targetPosition)
				patchedAny = true
			end
			zone.Anchored = true
			zone.CanCollide = false
			zone.CanTouch = false
			zone.CanQuery = true
		end
	end

	if patchedAny then
		mapClone:SetAttribute(SAFE_ZONE_PATCH_ATTR, true)
	end
	return patchedAny
end

function MapRuntimePatches.Apply(mapId, mapClone)
	local token = resolveMapOverrideToken(mapId, mapClone)
	if token == nil or mapClone == nil then
		return false
	end

	local didPatch = false
	didPatch = patchSecondFloor(mapClone) or didPatch
	didPatch = patchDoorTraversal(mapClone) or didPatch
	didPatch = patchInteractionPoints(mapId, mapClone) or didPatch
	didPatch = patchSafeZones(mapId, mapClone) or didPatch
	return didPatch
end

return MapRuntimePatches

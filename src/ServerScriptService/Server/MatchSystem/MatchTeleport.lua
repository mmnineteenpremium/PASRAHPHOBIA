local MatchTeleport = {}
MatchTeleport.__index = MatchTeleport

local DoorRuntime = require(script.Parent.DoorRuntime)
local EnvironmentalObjectRuntime = require(script.Parent.EnvironmentalObjectRuntime)
local MapRuntimePatches = require(script.Parent.MapRuntimePatches)

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SAFE_MIN_SPAWN_Y = 2.5
local TARGET_MIN_MATCH_SPAWN_Y = 24
local FLOOR_CHECK_DISTANCE = 50
local FLOOR_RAY_START_OFFSET = 1.5
local DEFAULT_FLOOR_CLEARANCE = 3.0
local MIN_FLOOR_CLEARANCE = 2.75
local MAX_FLOOR_CLEARANCE = 3.4
local FLOOR_ABOVE_SPAWN_TOLERANCE = 1
local FLOOR_RETRY_MAX_ITERATIONS = 6
local FLOOR_RETRY_EPSILON = 0.05
local SPAWN_WAIT_TIMEOUT = 5
local SPAWN_WAIT_STEP = 0.1
local CHARACTER_WAIT_TIMEOUT = 5
local CHARACTER_WAIT_STEP = 0.1
local DEFAULT_FORWARD = Vector3.new(0, 0, -1)
local SPAWN_FORWARD_CLEARANCE_CHECK_DISTANCE = 8
local SPAWN_FORWARD_OFFSET_MAX = 2
local SPAWN_FORWARD_OFFSET_MIN_CLEARANCE = 2.5
local SPAWN_FORWARD_RAY_HEIGHT = 1.9

-- Streaming + physics stabilization for in-place teleports (StreamingEnabled = true).
-- Without this, clients can briefly have no colliders at the destination and the character can drift/fling.
local STREAM_AROUND_TIMEOUT = 8
local STREAM_AROUND_HARD_TIMEOUT = 10
local POST_TELEPORT_FREEZE_OK_SECONDS = 0.22
local POST_TELEPORT_FREEZE_TIMEOUT_SECONDS = 0.65
local POST_TELEPORT_SERVER_OWNERSHIP_STREAMING_SECONDS = 1.8
local POST_TELEPORT_SERVER_OWNERSHIP_NON_STREAMING_SECONDS = 1.1
local REQUEST_STREAM_API_MISSING_WARNED = false
local PREPARATION_STAGING_PATCH_ATTR = "PreparationStagingRuntimePatched"

local function getActiveMatchesFolder()
	local folder = Workspace:FindFirstChild("ActiveMatches")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "ActiveMatches"
		folder.Parent = Workspace
	end
	return folder
end

local function getMatchContainer(match)
	local activeMatches = getActiveMatchesFolder()
	if type(match) ~= "table" then
		return activeMatches
	end

	local matchId = match.matchId or match.id
	if not matchId then
		return activeMatches
	end

	local expectedName = "Match_" .. tostring(matchId)
	local container = match.container
	if typeof(container) ~= "Instance" or not container:IsA("Folder") or container.Parent ~= activeMatches or container.Name ~= expectedName then
		container = activeMatches:FindFirstChild(expectedName)
	end

	if not container then
		container = Instance.new("Folder")
		container.Name = expectedName
		container.Parent = activeMatches
	end

	match.container = container
	return container
end

local function normalizeMapName(value)
	if type(value) ~= "string" then
		return nil, nil
	end
	local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
	if trimmed == "" then
		return nil, nil
	end
	local token = trimmed:gsub("[%s_%-%.]+", ""):lower()
	return trimmed, token
end

local function resolveMapsFolder()
	local serverStorage = game:GetService("ServerStorage")
	local mapsFolder = serverStorage:FindFirstChild("Maps")
	if not mapsFolder then
		-- Rojo can sync this folder a moment after server scripts start in Studio.
		mapsFolder = serverStorage:WaitForChild("Maps", 10)
	end

	if mapsFolder and mapsFolder:IsA("Folder") and #mapsFolder:GetChildren() == 0 then
		local deadline = os.clock() + 3
		while #mapsFolder:GetChildren() == 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end

	return mapsFolder
end

local function findMapTemplateInFolder(mapsFolder, normalizedName, normalizedToken)
	if not mapsFolder then
		return nil, nil
	end

	local function resolveTemplateCandidate(candidate)
		if not candidate then
			return nil
		end
		if candidate:IsA("Folder") then
			local nestedDirect = candidate:FindFirstChild(normalizedName)
			if nestedDirect and not nestedDirect:IsA("Folder") then
				return nestedDirect
			end
			for _, nested in ipairs(candidate:GetChildren()) do
				if not nested:IsA("Folder") then
					return nested
				end
			end
			return nil
		end
		return candidate
	end

	local directMatch = mapsFolder:FindFirstChild(normalizedName)
	if directMatch then
		local resolved = resolveTemplateCandidate(directMatch)
		if resolved then
			return resolved, resolved.Name
		end
	end

	for _, child in ipairs(mapsFolder:GetChildren()) do
		local _, childToken = normalizeMapName(child.Name)
		if childToken and childToken == normalizedToken then
			local resolved = resolveTemplateCandidate(child)
			if resolved then
				return resolved, resolved.Name
			end
		end

		-- Support maps wrapped in a folder where the root map model is one level deeper.
		if child:IsA("Folder") then
			local nestedDirect = child:FindFirstChild(normalizedName)
			if nestedDirect and not nestedDirect:IsA("Folder") then
				return nestedDirect, nestedDirect.Name
			end

			for _, nested in ipairs(child:GetChildren()) do
				local _, nestedToken = normalizeMapName(nested.Name)
				if nestedToken and nestedToken == normalizedToken and not nested:IsA("Folder") then
					return nested, nested.Name
				end
			end
		end
	end

	return nil, nil
end

local function resolveMapTemplate(mapName)
	local normalizedName, normalizedToken = normalizeMapName(mapName)
	if not normalizedName then
		return nil, nil, nil, nil
	end

	local mapsFolder = resolveMapsFolder()
	local mapTemplate, resolvedTemplateName = findMapTemplateInFolder(mapsFolder, normalizedName, normalizedToken)
	if mapTemplate then
		return mapTemplate, "ServerStorage.Maps", resolvedTemplateName, mapsFolder
	end

	if mapsFolder then
		return nil, "ServerStorage.Maps", normalizedName, mapsFolder
	end

	return nil, "ServerStorage.Maps", normalizedName, nil
end

local function computeMatchOffset(container)
	local index = 0
	if container and container.Parent then
		local siblings = container.Parent:GetChildren()
		for i, sibling in ipairs(siblings) do
			if sibling == container then
				index = i - 1
				break
			end
		end
		if index < 0 then
			index = math.max(#siblings - 1, 0)
		end
	end
	local spacing = 3000
	return Vector3.new(index * spacing, 0, 0)
end

local function applyWorldOffset(instance, offset)
	if typeof(offset) ~= "Vector3" then
		return false
	end

	local function moveModel(model)
		if not model:FindFirstChildWhichIsA("BasePart", true) then
			return false
		end
		local ok, pivot = pcall(function()
			return model:GetPivot()
		end)
		if ok then
			model:PivotTo(pivot + offset)
			return true
		end
		return false
	end

	local function applyOffsetRecursive(node)
		if node:IsA("Model") then
			return moveModel(node)
		end
		if node:IsA("BasePart") then
			node.CFrame = node.CFrame + offset
			return true
		end

		local movedAny = false
		for _, child in ipairs(node:GetChildren()) do
			if child:IsA("Model") then
				if moveModel(child) then
					movedAny = true
				end
			elseif child:IsA("BasePart") then
				child.CFrame = child.CFrame + offset
				movedAny = true
			elseif child:IsA("Folder") then
				if applyOffsetRecursive(child) then
					movedAny = true
				end
			end
		end

		return movedAny
	end

	return applyOffsetRecursive(instance)
end

local function resolveSpatialAnchorCFrame(instance)
	if not instance then
		return nil, nil
	end

	if instance:IsA("Model") and instance:FindFirstChildWhichIsA("BasePart", true) then
		local ok, pivot = pcall(function()
			return instance:GetPivot()
		end)
		if ok then
			return pivot, instance.Name
		end
	end

	if instance:IsA("BasePart") then
		return instance.CFrame, instance.Name
	end

	local nestedModel = instance:FindFirstChildWhichIsA("Model", true)
	if nestedModel and nestedModel:FindFirstChildWhichIsA("BasePart", true) then
		local ok, pivot = pcall(function()
			return nestedModel:GetPivot()
		end)
		if ok then
			return pivot, nestedModel.Name
		end
	end

	local nestedPart = instance:FindFirstChildWhichIsA("BasePart", true)
	if nestedPart then
		return nestedPart.CFrame, nestedPart.Name
	end

	return nil, nil
end

local function getCharacterRoot(character)
	if not character then
		return nil
	end
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if humanoidRootPart and humanoidRootPart:IsA("BasePart") then
		return humanoidRootPart
	end
	if character.PrimaryPart and character.PrimaryPart:IsA("BasePart") then
		return character.PrimaryPart
	end
	return character:FindFirstChildWhichIsA("BasePart")
end

local function waitForCharacterRoot(player, timeoutSeconds)
	local function resolveCharacterAndRoot()
		local character = player and player.Character
		local root = getCharacterRoot(character)
		if character and root then
			return character, root
		end

		if typeof(player) == "Instance" and player:IsA("Player") then
			local fallbackCharacter = Workspace:FindFirstChild(player.Name)
			if fallbackCharacter and fallbackCharacter:IsA("Model") then
				local fallbackRoot = getCharacterRoot(fallbackCharacter)
				if fallbackRoot then
					return fallbackCharacter, fallbackRoot
				end
			end
		end

		return character, root
	end

	local deadline = os.clock() + (tonumber(timeoutSeconds) or CHARACTER_WAIT_TIMEOUT)
	repeat
		local character, root = resolveCharacterAndRoot()
		if character and root then
			return character, root
		end
		task.wait(CHARACTER_WAIT_STEP)
	until os.clock() >= deadline

	return resolveCharacterAndRoot()
end

local function setStudioTeleportTrace(summary, count)
	if not RunService:IsStudio() then
		return
	end
	ReplicatedStorage:SetAttribute("PasrahLastTeleportTrace", summary)
	ReplicatedStorage:SetAttribute("PasrahLastTeleportedCount", count)
end

local function updateStudioTeleportTrace(parts, count, segment)
	if type(segment) == "string" and segment ~= "" then
		table.insert(parts, segment)
	end
	setStudioTeleportTrace(table.concat(parts, " | "), count)
end

local function resolveHumanoidFloorClearance(character)
	local root = getCharacterRoot(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (root and root:IsA("BasePart") and humanoid) then
		return DEFAULT_FLOOR_CLEARANCE
	end

	local hipHeight = tonumber(humanoid.HipHeight) or 0
	local clearance = (root.Size.Y * 0.5) + math.max(hipHeight, 0) + 0.15
	if clearance < MIN_FLOOR_CLEARANCE then
		clearance = MIN_FLOOR_CLEARANCE
	elseif clearance > MAX_FLOOR_CLEARANCE then
		clearance = MAX_FLOOR_CLEARANCE
	end
	return clearance
end

local function clearAssemblyVelocities(rootPart)
	if not (rootPart and rootPart:IsA("BasePart")) then
		return
	end
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero
end

local function withServerNetworkOwnership(rootPart, durationSeconds)
	if not (rootPart and rootPart:IsA("BasePart")) then
		return
	end

	pcall(function()
		rootPart:SetNetworkOwner(nil)
	end)

	local seconds = tonumber(durationSeconds) or 0.75
	if seconds <= 0 then
		return
	end
	task.delay(seconds, function()
		if not (rootPart and rootPart.Parent) then
			return
		end
		pcall(function()
			rootPart:SetNetworkOwnershipAuto()
		end)
	end)
end

local function requestStreamAroundPlayer(player, position)
	if not Workspace.StreamingEnabled then
		return true
	end
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false
	end
	if typeof(position) ~= "Vector3" then
		return false
	end
	if typeof(player.RequestStreamAroundAsync) ~= "function" then
		if not REQUEST_STREAM_API_MISSING_WARNED then
			REQUEST_STREAM_API_MISSING_WARNED = true
			warn("[MatchTeleport] StreamingEnabled=true but Player:RequestStreamAroundAsync is not available in this runtime.")
		end
		return false
	end

	local completed = false
	task.spawn(function()
		pcall(function()
			player:RequestStreamAroundAsync(position, STREAM_AROUND_TIMEOUT)
		end)
		completed = true
	end)

	local deadline = os.clock() + STREAM_AROUND_HARD_TIMEOUT
	while not completed and os.clock() < deadline do
		task.wait(0.05)
	end

	return completed
end

local function resolveHorizontalForward(rawCFrame)
	if typeof(rawCFrame) ~= "CFrame" then
		return DEFAULT_FORWARD
	end

	local flatLook = Vector3.new(rawCFrame.LookVector.X, 0, rawCFrame.LookVector.Z)
	if flatLook.Magnitude > 1e-4 then
		return flatLook.Unit
	end

	local flatRight = Vector3.new(rawCFrame.RightVector.X, 0, rawCFrame.RightVector.Z)
	if flatRight.Magnitude > 1e-4 then
		return flatRight.Unit
	end

	return DEFAULT_FORWARD
end

local function buildUprightCFrame(position, rawCFrame)
	local forward = resolveHorizontalForward(rawCFrame)
	return CFrame.lookAt(position, position + forward, Vector3.yAxis)
end

local function safeTeleportCharacter(player, targetCFrame)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end
	if typeof(targetCFrame) ~= "CFrame" then
		return false, "invalid_target_cframe"
	end

	local character = player.Character
	if not character then
		return false, "missing_character"
	end

	local root = getCharacterRoot(character)
	if not (root and root:IsA("BasePart")) then
		return false, "missing_root"
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	local ownershipDuration = Workspace.StreamingEnabled
		and POST_TELEPORT_SERVER_OWNERSHIP_STREAMING_SECONDS
		or POST_TELEPORT_SERVER_OWNERSHIP_NON_STREAMING_SECONDS
	withServerNetworkOwnership(root, ownershipDuration)

	local uprightTargetCFrame = buildUprightCFrame(targetCFrame.Position, targetCFrame)
	local function applyUprightPose()
		if not (character and character.Parent and root and root.Parent) then
			return
		end
		local rootPosition = root.Position
		local uprightAtRoot = buildUprightCFrame(rootPosition, uprightTargetCFrame)
		local pivotOk = pcall(function()
			character:PivotTo(uprightAtRoot)
		end)
		if not pivotOk then
			root.CFrame = uprightAtRoot
		end
		clearAssemblyVelocities(root)
	end

	local previousAnchored = root.Anchored
	root.Anchored = true
	clearAssemblyVelocities(root)
	if humanoid then
		pcall(function()
			humanoid.PlatformStand = false
			humanoid.Sit = false
			humanoid.AutoRotate = true
		end)
	end

	local streamStart = os.clock()
	local streamedOk = requestStreamAroundPlayer(player, targetCFrame.Position)
	local streamDuration = os.clock() - streamStart
	if Workspace.StreamingEnabled and not streamedOk then
		warn(string.format(
			"[MatchTeleport] RequestStreamAroundAsync timed out (%.2fs) for %s at %s",
			streamDuration,
			player.Name,
			tostring(targetCFrame.Position)
		))
	end

	local pivotOk = pcall(function()
		character:PivotTo(uprightTargetCFrame)
	end)
	if not pivotOk then
		root.CFrame = uprightTargetCFrame
	end
	applyUprightPose()

	clearAssemblyVelocities(root)
	if Workspace.StreamingEnabled then
		task.wait(streamedOk and POST_TELEPORT_FREEZE_OK_SECONDS or POST_TELEPORT_FREEZE_TIMEOUT_SECONDS)
	else
		task.wait()
	end
	task.wait()
	root.Anchored = previousAnchored
	clearAssemblyVelocities(root)
	if humanoid then
		pcall(function()
			humanoid.PlatformStand = false
			humanoid.Sit = false
			humanoid.AutoRotate = true
			humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		end)
		pcall(function()
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end
	applyUprightPose()
	task.delay(0.12, function()
		if not (character and character.Parent and root and root.Parent) then
			return
		end
		if root.CFrame.UpVector.Y < 0.7 then
			applyUprightPose()
		end
	end)
	task.delay(0.3, function()
		if not (character and character.Parent and root and root.Parent) then
			return
		end
		if root.CFrame.UpVector.Y < 0.85 then
			applyUprightPose()
		end
	end)

	return true
end

local function extractSpawnCFrame(spawnNode)
	if not spawnNode then
		return nil
	end
	if spawnNode:IsA("BasePart") then
		return spawnNode.CFrame
	end
	if spawnNode:IsA("Model") then
		if spawnNode.PrimaryPart then
			return spawnNode.PrimaryPart.CFrame
		end
		local ok, pivot = pcall(function()
			return spawnNode:GetPivot()
		end)
		if ok then
			return pivot
		end
	end
	return nil
end

local function isPreparationSpawnName(name)
	name = tostring(name or "")
	return string.find(name, "PreparationSpawn_", 1, true) == 1
		or name == "PreparationSpawn"
end

local function hasPreparationStagingRuntime(mapClone)
	if typeof(mapClone) ~= "Instance" then
		return false
	end
	if mapClone:GetAttribute(PREPARATION_STAGING_PATCH_ATTR) == true then
		return true
	end
	local runtimeFolder = mapClone:FindFirstChild("Runtime")
	local preparationFolder = runtimeFolder and runtimeFolder:FindFirstChild("PreparationStagingRuntime")
	if preparationFolder and preparationFolder:IsA("Folder") then
		return true
	end

	for _, descendant in ipairs(mapClone:GetDescendants()) do
		if descendant:IsA("Folder") and descendant.Name == "Runtime" then
			local nestedPreparation = descendant:FindFirstChild("PreparationStagingRuntime")
			if nestedPreparation and nestedPreparation:IsA("Folder") then
				return true
			end
		end
	end
	return false
end

local function resolveCanonicalPreparationSpawnArea(mapClone)
	if typeof(mapClone) ~= "Instance" then
		return nil, nil
	end

	local runtimeFolder = mapClone:FindFirstChild("Runtime")
	local preparationFolder = runtimeFolder and runtimeFolder:FindFirstChild("PreparationStagingRuntime")
	local spawnArea = preparationFolder and preparationFolder:FindFirstChild("PreparationSpawnArea", true)
	if preparationFolder and preparationFolder:IsA("Folder") and spawnArea then
		return preparationFolder, spawnArea
	end

	for _, descendant in ipairs(mapClone:GetDescendants()) do
		if descendant:IsA("Folder") and descendant.Name == "Runtime" then
			local nestedPreparation = descendant:FindFirstChild("PreparationStagingRuntime")
			local nestedSpawnArea = nestedPreparation and nestedPreparation:FindFirstChild("PreparationSpawnArea", true)
			if nestedPreparation and nestedPreparation:IsA("Folder") and nestedSpawnArea then
				return nestedPreparation, nestedSpawnArea
			end
		end
	end

	return nil, nil
end

local function getPreparationSpawnCandidates(mapClone)
	if typeof(mapClone) ~= "Instance" then
		return {}
	end

	local _, spawnArea = resolveCanonicalPreparationSpawnArea(mapClone)
	if not spawnArea then
		return {}
	end

	local candidates = {}
	for _, child in ipairs(spawnArea:GetDescendants()) do
		if child:IsA("BasePart") then
			candidates[#candidates + 1] = child
		end
	end
	table.sort(candidates, function(a, b)
		local aName = tostring(a.Name)
		local bName = tostring(b.Name)
		if aName == bName then
			return a:GetFullName() < b:GetFullName()
		end
		return aName < bName
	end)
	return candidates
end

local function getSpawnCandidates(mapClone)
	local preparationCandidates = getPreparationSpawnCandidates(mapClone)
	if #preparationCandidates > 0 then
		return preparationCandidates, "PreparationStagingRuntime"
	end
	return {}, nil
end

local function waitForSpawnCandidates(mapClone)
	local deadline = os.clock() + SPAWN_WAIT_TIMEOUT
	repeat
		if mapClone and mapClone:IsDescendantOf(Workspace) then
			local candidates, source = getSpawnCandidates(mapClone)
			if #candidates > 0 then
				return candidates, source
			end
		end
		task.wait(SPAWN_WAIT_STEP)
	until os.clock() >= deadline

	return getSpawnCandidates(mapClone)
end

local function computeSpawnLift(mapClone)
	local minY = math.huge
	local candidates, _ = getSpawnCandidates(mapClone)
	for _, candidate in ipairs(candidates) do
		local candidateCFrame = extractSpawnCFrame(candidate)
		if candidateCFrame then
			minY = math.min(minY, candidateCFrame.Position.Y)
		end
	end

	if minY == math.huge or minY >= TARGET_MIN_MATCH_SPAWN_Y then
		return 0
	end

	return TARGET_MIN_MATCH_SPAWN_Y - minY
end

local function resolveUprightForward(rawCFrame)
	return resolveHorizontalForward(rawCFrame)
end

local function isPointInsideRoomPart(part, worldPosition)
	if not (part and part:IsA("BasePart") and typeof(worldPosition) == "Vector3") then
		return false
	end

	local localPosition = part.CFrame:PointToObjectSpace(worldPosition)
	local half = part.Size * 0.5
	local verticalTolerance = math.max(half.Y, 8)
	return math.abs(localPosition.X) <= (half.X + 2)
		and math.abs(localPosition.Y) <= verticalTolerance
		and math.abs(localPosition.Z) <= (half.Z + 2)
end

local function isPositionInsideAnyRoom(mapClone, worldPosition)
	if typeof(mapClone) ~= "Instance" or typeof(worldPosition) ~= "Vector3" then
		return false, nil
	end

	local roomsFolder = mapClone:FindFirstChild("Rooms", true)
	if not roomsFolder then
		return false, nil
	end

	for _, room in ipairs(roomsFolder:GetDescendants()) do
		if room:IsA("BasePart")
			and string.find(room.Name, "Room_", 1, true) == 1
			and isPointInsideRoomPart(room, worldPosition) then
			return true, room
		end
	end

	return false, nil
end

local function resolveSpawnFacingForward(mapClone, position, rawCFrame)
	if typeof(position) ~= "Vector3" then
		return resolveUprightForward(rawCFrame)
	end

	local interactionPointsFolder = mapClone and mapClone:FindFirstChild("InteractionPoints", true)
	local nearestInteraction = nil
	local nearestDistance = math.huge
	if interactionPointsFolder then
		for _, point in ipairs(interactionPointsFolder:GetChildren()) do
			if point:IsA("BasePart") then
				local offset = Vector3.new(point.Position.X - position.X, 0, point.Position.Z - position.Z)
				local distance = offset.Magnitude
				if distance >= 6 and distance <= 32 and distance < nearestDistance then
					nearestInteraction = point
					nearestDistance = distance
				end
			end
		end
	end
	if nearestInteraction then
		local towardInteraction = Vector3.new(
			nearestInteraction.Position.X - position.X,
			0,
			nearestInteraction.Position.Z - position.Z
		)
		if towardInteraction.Magnitude > 1e-4 then
			return towardInteraction.Unit
		end
	end

	local roomsFolder = mapClone and mapClone:FindFirstChild("Rooms", true)
	local containingRoom = nil
	local containingDistance = math.huge
	if roomsFolder then
		for _, room in ipairs(roomsFolder:GetChildren()) do
			if room:IsA("BasePart") and isPointInsideRoomPart(room, position) then
				local offset = Vector3.new(room.Position.X - position.X, 0, room.Position.Z - position.Z)
				local distance = offset.Magnitude
				if distance > 4 and distance < containingDistance then
					containingRoom = room
					containingDistance = distance
				end
			end
		end
	end
	if containingRoom then
		local towardRoomCenter = Vector3.new(
			containingRoom.Position.X - position.X,
			0,
			containingRoom.Position.Z - position.Z
		)
		if towardRoomCenter.Magnitude > 1e-4 then
			return towardRoomCenter.Unit
		end
	end

	local mapPivot = nil
	local anchorCFrame = mapClone and resolveSpatialAnchorCFrame(mapClone)
	if typeof(anchorCFrame) == "CFrame" then
		mapPivot = anchorCFrame
	end
	if typeof(mapPivot) == "CFrame" then
		local towardPivot = Vector3.new(mapPivot.Position.X - position.X, 0, mapPivot.Position.Z - position.Z)
		if towardPivot.Magnitude > 8 then
			return towardPivot.Unit
		end
	end

	return resolveUprightForward(rawCFrame)
end

local function buildUprightFacingCFrame(mapClone, position, rawCFrame)
	local forward = resolveSpawnFacingForward(mapClone, position, rawCFrame)
	return CFrame.lookAt(position, position + forward, Vector3.yAxis)
end

local function isPreparationSpawnCandidate(spawnCandidate)
	if typeof(spawnCandidate) ~= "Instance" then
		return false
	end
	if spawnCandidate:GetAttribute("PasrahPreparationSpawn") == true then
		return true
	end
	if isPreparationSpawnName(spawnCandidate.Name) then
		return true
	end
	local parent = spawnCandidate.Parent
	while parent do
		if parent.Name == "PreparationSpawnArea" or parent.Name == "PreparationStagingRuntime" then
			return true
		end
		parent = parent.Parent
	end
	return false
end

local function resolveSpawnForwardOffset(mapClone, position, forward)
	if not mapClone or typeof(position) ~= "Vector3" or typeof(forward) ~= "Vector3" or forward.Magnitude <= 1e-4 then
		return 0
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { mapClone }
	rayParams.IgnoreWater = true
	rayParams.RespectCanCollide = true

	local rayOrigin = position + Vector3.new(0, SPAWN_FORWARD_RAY_HEIGHT, 0)
	local rayDirection = forward.Unit * SPAWN_FORWARD_CLEARANCE_CHECK_DISTANCE
	local hit = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
	local clearance = hit and (hit.Position - rayOrigin).Magnitude or SPAWN_FORWARD_CLEARANCE_CHECK_DISTANCE
	if clearance <= SPAWN_FORWARD_OFFSET_MIN_CLEARANCE then
		return 0
	end

	return math.clamp(clearance - SPAWN_FORWARD_OFFSET_MIN_CLEARANCE, 0, SPAWN_FORWARD_OFFSET_MAX)
end

local function buildSafeSpawnCFrame(mapClone, rawCFrame, floorClearance, spawnCandidate)
	if not rawCFrame then
		return nil, "missing_spawn_cframe"
	end

	local rawPosition = rawCFrame.Position
	if rawPosition.Y < 0 then
		return nil, "spawn_below_zero_y"
	end

	local correctedPosition = Vector3.new(
		rawPosition.X,
		math.max(rawPosition.Y, SAFE_MIN_SPAWN_Y),
		rawPosition.Z
	)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { mapClone }
	rayParams.IgnoreWater = true
	rayParams.RespectCanCollide = true

	local rayOrigin = correctedPosition + Vector3.new(0, FLOOR_RAY_START_OFFSET, 0)
	local rayDirection = Vector3.new(0, -(FLOOR_RAY_START_OFFSET + FLOOR_CHECK_DISTANCE), 0)
	local floorHit = Workspace:Raycast(rayOrigin, rayDirection, rayParams)
	local retryCount = 0
	while floorHit and retryCount < FLOOR_RETRY_MAX_ITERATIONS do
		local hitY = floorHit.Position.Y
		if hitY <= (rawPosition.Y + FLOOR_ABOVE_SPAWN_TOLERANCE) then
			break
		end

		retryCount += 1
		local retryOriginY = hitY - FLOOR_RETRY_EPSILON
		local retryDistance = retryOriginY - (correctedPosition.Y - FLOOR_CHECK_DISTANCE)
		if retryDistance <= 0 then
			floorHit = nil
			break
		end
		floorHit = Workspace:Raycast(
			Vector3.new(correctedPosition.X, retryOriginY, correctedPosition.Z),
			Vector3.new(0, -retryDistance, 0),
			rayParams
		)
	end
	if not floorHit then
		return nil, "no_floor_within_50"
	end

	local floorY = floorHit.Position.Y
	local appliedClearance = tonumber(floorClearance) or DEFAULT_FLOOR_CLEARANCE
	local finalPosition = Vector3.new(
		correctedPosition.X,
		math.max(floorY + appliedClearance, SAFE_MIN_SPAWN_Y),
		correctedPosition.Z
	)

	local forward = if isPreparationSpawnCandidate(spawnCandidate)
		then resolveUprightForward(rawCFrame)
		else resolveSpawnFacingForward(mapClone, finalPosition, rawCFrame)
	local forwardOffset = resolveSpawnForwardOffset(mapClone, finalPosition, forward)
	if forwardOffset > 0 then
		finalPosition += (forward * forwardOffset)
	end

	if isPreparationSpawnCandidate(spawnCandidate) then
		local insideRoom, roomPart = isPositionInsideAnyRoom(mapClone, finalPosition)
		if insideRoom then
			return nil, string.format(
				"preparation_spawn_inside_room:%s",
				tostring(roomPart and roomPart.Name or "unknown")
			)
		end
	end

	return CFrame.lookAt(finalPosition, finalPosition + forward, Vector3.yAxis), nil
end

local function resolveSafeSpawnCFrame(mapClone, spawnCandidates, preferredIndex, floorClearance)
	local orderedCandidates = {}
	local preferred = spawnCandidates[preferredIndex] or spawnCandidates[#spawnCandidates]
	if preferred then
		table.insert(orderedCandidates, preferred)
	end

	for _, candidate in ipairs(spawnCandidates) do
		if candidate ~= preferred then
			table.insert(orderedCandidates, candidate)
		end
	end

	for _, candidate in ipairs(orderedCandidates) do
		local candidateCFrame = extractSpawnCFrame(candidate)
		local safeCFrame, reason = buildSafeSpawnCFrame(mapClone, candidateCFrame, floorClearance, candidate)
		if safeCFrame then
			return safeCFrame, candidate
		end
		if reason == "spawn_below_zero_y" then
			warn("[MatchTeleport] Invalid spawn Y<0 for candidate:", candidate:GetFullName())
		elseif type(reason) == "string" and string.find(reason, "preparation_spawn_inside_room", 1, true) == 1 then
			warn("[MatchTeleport] Rejected preparation spawn inside room:", candidate:GetFullName(), reason)
		end
	end

	return nil, nil
end

local function resolveTeleportService(deps)
	local service = deps.TeleportService
	if type(service) == "table" then
		return service
	end
	return nil
end

function MatchTeleport.new(deps, config)
	local self = setmetatable({}, MatchTeleport)
	self._deps = deps or {}
	self._config = config or {}
	self._teleportService = resolveTeleportService(self._deps)
	return self
end

function MatchTeleport:_teleport(player, placeId, options)
	if self._teleportService and type(self._teleportService.TeleportAsync) == "function" then
		local ok, err = pcall(function()
			self._teleportService:TeleportAsync(placeId, { player }, options)
		end)
		if not ok then
			return false, err
		end
	end
	return true
end

function MatchTeleport:TeleportPlayers(matchOrPlayers, mapName)
	local match = nil
	local players = nil
	local resolvedMapName = mapName
	local resolvedPlaceId = nil

	if type(matchOrPlayers) == "table" and matchOrPlayers.players then
		match = matchOrPlayers
		players = match.players or {}
		resolvedMapName = match.map or match.mapId or resolvedMapName
		resolvedPlaceId = match.mapReference or (self._config and self._config.MatchPlaceId)
	else
		players = matchOrPlayers or {}
	end

	local teleported = {}
	local mapTemplate, mapSource, resolvedTemplateName, mapsFolder = resolveMapTemplate(resolvedMapName)
	if mapTemplate then
		local container = getMatchContainer(match)
		for _, child in ipairs(container:GetChildren()) do
			child:Destroy()
		end

		local mapClone = mapTemplate:Clone()
		mapClone.Parent = container
		MapRuntimePatches.Apply(resolvedMapName or resolvedTemplateName, mapClone, match)
		if type(match) == "table" then
			match.preparationWorldBoard = hasPreparationStagingRuntime(mapClone)
		end
		local offset = computeMatchOffset(container) + Vector3.new(0, computeSpawnLift(mapClone), 0)
		if not applyWorldOffset(mapClone, offset) then
			warn("[MatchTeleport] Unable to apply map offset (no pivotable part):", mapClone:GetFullName())
		end
		DoorRuntime.Attach(match, mapClone, self._deps)
		EnvironmentalObjectRuntime.Attach(match, mapClone, self._deps)

		local teleportTrace = {
			string.format("match=%s", tostring(match and (match.matchId or match.id) or "nil")),
			string.format("map=%s", tostring(resolvedMapName or resolvedTemplateName)),
			"status=map_cloned",
			"status=waiting_spawn_candidates",
		}
		updateStudioTeleportTrace(teleportTrace, #teleported, nil)

			local spawnPoints, spawnSource = waitForSpawnCandidates(mapClone)
			if #spawnPoints == 0 then
				error(string.format(
					"[MatchTeleport] Preparation spawn candidates missing/empty after map load: %s",
					mapClone:GetFullName()
				))
			end

		updateStudioTeleportTrace(
			teleportTrace,
			#teleported,
			string.format(
				"status=spawn_candidates_ready count=%d source=%s",
				#spawnPoints,
				tostring(spawnSource or "none")
			)
		)
		local teleportedUserIds = {}
		for index, player in ipairs(players) do
			if typeof(player) == "Instance" and player:IsA("Player") then
				if teleportedUserIds[player.UserId] == true then
					updateStudioTeleportTrace(
						teleportTrace,
						#teleported,
						string.format("player=%s status=skip_duplicate", player.Name)
					)
					continue
				end
				updateStudioTeleportTrace(teleportTrace, #teleported, string.format("player=%s status=resolve_root", player.Name))
				local character, root = waitForCharacterRoot(player, CHARACTER_WAIT_TIMEOUT)
				local floorClearance = resolveHumanoidFloorClearance(character)
				updateStudioTeleportTrace(
					teleportTrace,
					#teleported,
					string.format(
						"player=%s status=root_%s",
						player.Name,
						root and "ok" or "missing"
					)
				)
				local safeSpawnCFrame = nil
				local spawnCandidate = nil
				local spawnOk, spawnResult = xpcall(function()
					local resolvedCFrame, resolvedCandidate = resolveSafeSpawnCFrame(mapClone, spawnPoints, index, floorClearance)
					return {
						cframe = resolvedCFrame,
						candidate = resolvedCandidate,
					}
				end, debug.traceback)
				if spawnOk then
					safeSpawnCFrame = spawnResult.cframe
					spawnCandidate = spawnResult.candidate
				else
					table.insert(teleportTrace, string.format("%s:spawnResolveError=%s", player.Name, tostring(spawnResult)))
					updateStudioTeleportTrace(
						teleportTrace,
						#teleported,
						string.format("player=%s status=spawn_error", player.Name)
					)
				end
					if not safeSpawnCFrame then
						warn("[MatchTeleport] NO VALID PREPARATION SPAWN, SKIP PLAYER")
						table.insert(teleportTrace, string.format("%s:skip_no_preparation_spawn", player.Name))
						updateStudioTeleportTrace(
							teleportTrace,
							#teleported,
							string.format("player=%s status=skip_no_preparation_spawn", player.Name)
						)
						continue
					elseif spawnCandidate then
						table.insert(teleportTrace, string.format("%s:spawnCandidate=%s", player.Name, spawnCandidate:GetFullName()))
					end

				if not root then
					local playerName = player and player.Name or "Unknown"
					warn(string.format("[MatchTeleport] Skip teleport for %s (invalid root).", playerName))
					table.insert(teleportTrace, string.format("%s:skip_invalid_root", playerName))
					updateStudioTeleportTrace(teleportTrace, #teleported, string.format("player=%s status=skip_invalid_root", playerName))
					continue
				end

				player:SetAttribute("SpawnProtected", true)
				player:SetAttribute("SpawnProtectedUntil", os.clock() + 3)

				updateStudioTeleportTrace(teleportTrace, #teleported, string.format("player=%s status=teleporting", player.Name))
				local teleOk = safeTeleportCharacter(player, safeSpawnCFrame)
				if not teleOk then
					-- Fallback: keep legacy behavior if character is in a strange state.
					root.CFrame = safeSpawnCFrame
					clearAssemblyVelocities(root)
					table.insert(teleportTrace, string.format("%s:teleportFallbackDirectCFrame", player.Name))
					updateStudioTeleportTrace(teleportTrace, #teleported, string.format("player=%s status=fallback_cframe", player.Name))
				else
					table.insert(teleportTrace, string.format("%s:teleportOk", player.Name))
					updateStudioTeleportTrace(teleportTrace, #teleported, string.format("player=%s status=teleport_ok", player.Name))
				end

				player:SetAttribute("InMatch", true)
				player:SetAttribute("InLobby", nil)
				if match and (match.matchId or match.id) then
					player:SetAttribute("MatchId", tostring(match.matchId or match.id))
				end
				table.insert(teleported, player)
				teleportedUserIds[player.UserId] = true
				updateStudioTeleportTrace(teleportTrace, #teleported, string.format("player=%s status=teleported_counted", player.Name))
			end
		end

			if #players > 0 and #teleported == 0 then
				error("[MatchTeleport] no_players_teleported_from_preparation_spawns")
			end
			setStudioTeleportTrace(table.concat(teleportTrace, " | "), #teleported)
			return teleported
		end

	local sourceLabel = mapSource or "ServerStorage.Maps"
	warn(string.format("[MatchTeleport] Map template not found in %s: %s", sourceLabel, tostring(resolvedMapName)))
	if not mapsFolder then
		warn("[MatchTeleport] No maps folder found in ServerStorage. Check Rojo sync for src/ServerStorage/Maps.")
	end
	if mapsFolder then
		local availableNames = {}
		for _, child in ipairs(mapsFolder:GetChildren()) do
			table.insert(availableNames, child.Name)
		end
		table.sort(availableNames)
		warn("[MatchTeleport] Available maps:", table.concat(availableNames, ", "))
	end

	if resolvedPlaceId then
		for _, player in ipairs(players or {}) do
			if typeof(player) == "Instance" and player:IsA("Player") then
				local ok = self:_teleport(player, resolvedPlaceId, nil)
				if ok then
					table.insert(teleported, player)
				end
			end
		end
	end

	return teleported
end

function MatchTeleport:ReturnPlayersToLobby(match)
	local teleported = {}
	local lobbyPlaceId = self._config.LobbyPlaceId

	for _, player in ipairs(match.players) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			local ok = true
			if lobbyPlaceId then
				ok = self:_teleport(player, lobbyPlaceId, nil)
			end
			if ok then
				player:SetAttribute("InMatch", false)
				player:SetAttribute("MatchId", nil)
				table.insert(teleported, player)
			end
		end
	end

	return teleported
end

return MatchTeleport

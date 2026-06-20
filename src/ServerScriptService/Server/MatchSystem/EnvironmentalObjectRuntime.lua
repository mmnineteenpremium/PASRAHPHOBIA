local Services = require(script.Parent.Parent.Core.Services)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AbandonedPalaceLayout = require(script.Parent.AbandonedPalaceRuntimeLayout)
local EmptyBuildingLayout = require(script.Parent.EmptyBuildingRuntimeLayout)
local HauntedLayout = require(script.Parent.HauntedHouseRuntimeLayout)
local StudioMMNineteenLayout = require(script.Parent.StudioMMNineteenRuntimeLayout)

local EnvironmentalObjectRuntime = {}

local GENERATED_FOLDER_NAME = "GeneratedEventAssets"
local GENERATED_REVERT_DELAY = 1.6
local LIGHT_FLICKER_DELAY = 0.08
local LIGHT_SWITCH_PROMPT_NAME = "LightSwitchPrompt"
local LIGHT_SWITCH_ON_COLOR = Color3.fromRGB(236, 214, 168)
local LIGHT_SWITCH_OFF_COLOR = Color3.fromRGB(82, 88, 98)
local LIGHT_SWITCH_WALL_HEIGHT = 3.2
local LIGHT_SWITCH_REMOTE_DISTANCE = 10
local LIGHT_SWITCH_REMOTE_COOLDOWN = 0.35
local MAP_INTERACTION_REMOTE_NAME = "MapInteractionEvent"
local WORLD_POINT_LIGHT_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldEffects", "WorldPointLightTemplate" }

local EventPropAssets = nil
do
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local gameData = (shared and shared:FindFirstChild("GameData")) or ReplicatedStorage:FindFirstChild("GameData")
	local moduleScript = gameData and gameData:FindFirstChild("EventPropAssets")
	if moduleScript and moduleScript:IsA("ModuleScript") then
		local ok, result = pcall(require, moduleScript)
		if ok and type(result) == "table" then
			EventPropAssets = result
		end
	end
end

local function resolveChildPath(root, path)
	local node = root
	for _, segment in ipairs(path) do
		if typeof(node) ~= "Instance" then
			return nil
		end
		node = node:FindFirstChild(segment)
	end
	return node
end

local function cloneWorldPointLightTemplate(name)
	local template = resolveChildPath(ReplicatedStorage, WORLD_POINT_LIGHT_TEMPLATE_PATH)
	if template and template:IsA("PointLight") then
		local clone = template:Clone()
		clone.Name = name
		return clone
	end
	return nil
end

local function ensureRemoteFolder()
	local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "RemoteEvents"
		folder.Parent = ReplicatedStorage
	end
	return folder
end

local function ensureMapInteractionRemote()
	local folder = ensureRemoteFolder()
	local remote = folder:FindFirstChild(MAP_INTERACTION_REMOTE_NAME)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	if remote then
		remote:Destroy()
	end
	remote = Instance.new("RemoteEvent")
	remote.Name = MAP_INTERACTION_REMOTE_NAME
	remote.Parent = folder
	return remote
end

local function normalizeToken(value)
	if type(value) ~= "string" then
		return nil
	end
	return value:gsub("[%s_%-%.]+", ""):lower()
end

local function resolveLayout(mapClone)
	if typeof(mapClone) ~= "Instance" then
		return nil
	end
	local mapToken = normalizeToken(mapClone.Name)
	if mapToken == normalizeToken(HauntedLayout.mapId) then
		return HauntedLayout
	end
	if mapToken == normalizeToken(StudioMMNineteenLayout.mapId) then
		return StudioMMNineteenLayout
	end
	if mapToken == normalizeToken(AbandonedPalaceLayout.mapId) then
		return AbandonedPalaceLayout
	end
	if mapToken == normalizeToken(EmptyBuildingLayout.mapId) then
		return EmptyBuildingLayout
	end
	return nil
end

local function parseVector3String(serialized)
	if type(serialized) ~= "string" or serialized == "" then
		return nil
	end
	local x, y, z = serialized:match("^%s*([%-%d%.eE]+),%s*([%-%d%.eE]+),%s*([%-%d%.eE]+)%s*$")
	x = tonumber(x)
	y = tonumber(y)
	z = tonumber(z)
	if x and y and z then
		return Vector3.new(x, y, z)
	end
	return nil
end

local function getInstanceCFrame(instance)
	if typeof(instance) ~= "Instance" then
		return nil
	end
	if instance:IsA("Model") then
		local ok, pivot = pcall(function()
			return instance:GetPivot()
		end)
		if ok then
			return pivot
		end
	elseif instance:IsA("BasePart") then
		return instance.CFrame
	end
	return nil
end

local function applyInstanceCFrame(instance, targetCFrame)
	if typeof(instance) ~= "Instance" or typeof(targetCFrame) ~= "CFrame" then
		return
	end
	if instance:IsA("Model") then
		pcall(function()
			instance:PivotTo(targetCFrame)
		end)
	elseif instance:IsA("BasePart") then
		instance.CFrame = targetCFrame
	end
end

local function resolveEventBus(deps)
	local eventBus = Services.Get(deps, "EventBus")
	if type(eventBus) ~= "table" then
		return nil
	end
	if type(eventBus.Subscribe) == "function" and type(eventBus.Unsubscribe) == "function" then
		return eventBus
	end
	if type(eventBus.Service) == "table"
		and type(eventBus.Service.Subscribe) == "function"
		and type(eventBus.Service.Unsubscribe) == "function" then
		return eventBus.Service
	end
	return nil
end

local function resolveMapInteractionSystem(deps)
	local interactionSystem = Services.Get(deps, "MapInteractionSystem")
	if type(interactionSystem) ~= "table" then
		local registry = rawget(_G, "SystemRegistry")
		if type(registry) == "table" then
			if type(registry.Get) == "function" then
				interactionSystem = registry:Get("MapInteractionSystem")
			elseif type(registry.GetService) == "function" then
				interactionSystem = registry:GetService("MapInteractionSystem")
			end
		end
	end
	return type(interactionSystem) == "table" and interactionSystem or nil
end

local function ensureFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if folder and folder:IsA("Folder") then
		return folder
	end
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function clearGeneratedRuntimeFolder(folder)
	if not (folder and folder:IsA("Folder")) then
		return
	end
	for _, child in ipairs(folder:GetChildren()) do
		child:Destroy()
	end
	folder:SetAttribute("PasrahRuntimeGenerated", true)
	folder:SetAttribute("PasrahRuntimeSource", "EnvironmentalObjectRuntime")
end

local function ensurePart(parent, name)
	local part = parent:FindFirstChild(name)
	if part and part:IsA("BasePart") then
		return part
	end
	if part then
		part:Destroy()
	end
	part = Instance.new("Part")
	part.Name = name
	part.Parent = parent
	return part
end

local function ensureMeshPart(parent, name)
	local part = parent:FindFirstChild(name)
	if part and part:IsA("MeshPart") then
		return part
	end
	if part then
		part:Destroy()
	end
	part = Instance.new("MeshPart")
	part.Name = name
	part.Parent = parent
	return part
end

local function configurePropBoxPart(part, kind, color)
	if not (part and part:IsA("BasePart")) then
		return nil
	end
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = false
	part.CanQuery = true
	part.Material = Enum.Material.WoodPlanks
	part.Color = color or (kind == "prop_crate" and Color3.fromRGB(96, 78, 58) or Color3.fromRGB(112, 90, 62))
	part.Transparency = 0
	part.Size = Vector3.new(1.6, 1.2, 1.1)
	return part
end

local function createCeilingLight(parent, name, position)
	local model = parent:FindFirstChild(name)
	if model and not model:IsA("Model") then
		model:Destroy()
		model = nil
	end
	if not model then
		model = Instance.new("Model")
		model.Name = name
		model.Parent = parent
	end

	local cap = ensurePart(model, "Cap")
	cap.Anchored = true
	cap.CanCollide = false
	cap.CanTouch = false
	cap.CanQuery = false
	cap.Material = Enum.Material.Metal
	cap.Color = Color3.fromRGB(96, 92, 88)
	cap.Size = Vector3.new(1.1, 0.16, 1.1)
	cap.CFrame = CFrame.new(position)

	local bulb = ensurePart(model, "Bulb")
	bulb.Anchored = true
	bulb.CanCollide = false
	bulb.CanTouch = false
	bulb.CanQuery = false
	bulb.Material = Enum.Material.Neon
	bulb.Color = Color3.fromRGB(255, 230, 196)
	bulb.Size = Vector3.new(0.8, 0.22, 0.8)
	bulb.CFrame = CFrame.new(position - Vector3.new(0, 0.22, 0))

	local pointLight = bulb:FindFirstChild("Light")
	if not (pointLight and pointLight:IsA("PointLight")) then
		if pointLight then
			pointLight:Destroy()
		end
		pointLight = cloneWorldPointLightTemplate("Light")
		if pointLight then
			pointLight.Name = "Light"
			pointLight.Parent = bulb
		else
			warn("[EnvironmentalObjectRuntime] Missing authored visual template: WorldEffects.WorldPointLightTemplate")
		end
	end
	if pointLight then
		pointLight.Range = 18
		pointLight.Brightness = 1.8
		pointLight.Color = bulb.Color
		pointLight.Enabled = true
	end

	model.PrimaryPart = cap
	return model
end

local function createPropBox(parent, name, position, color)
	local part = ensurePart(parent, name)
	configurePropBoxPart(part, nil, color or Color3.fromRGB(116, 92, 64))
	part.CFrame = CFrame.new(position)
	return part
end

local function resolveAuthoredEventPropSpec(kind, objectId)
	if type(EventPropAssets) ~= "table" or type(EventPropAssets.ResolveForGenerated) ~= "function" then
		return nil
	end
	local ok, spec = pcall(EventPropAssets.ResolveForGenerated, kind, objectId)
	if ok and type(spec) == "table" and type(spec.meshId) == "string" and spec.meshId ~= "" then
		return spec
	end
	return nil
end

local function createAuthoredEventProp(parent, name, kind, position)
	local spec = resolveAuthoredEventPropSpec(kind, name)
	if not spec then
		return nil
	end

	local model = parent:FindFirstChild(name)
	if model and not model:IsA("Model") then
		model:Destroy()
		model = nil
	end
	if not model then
		model = Instance.new("Model")
		model.Name = name
		model.Parent = parent
	end

	local mesh = ensureMeshPart(model, "Mesh")
	mesh.Anchored = true
	mesh.CanCollide = true
	mesh.CanTouch = false
	mesh.CanQuery = true
	mesh.Material = Enum.Material.SmoothPlastic
	mesh.Color = typeof(spec.color) == "Color3" and spec.color or Color3.fromRGB(112, 90, 62)
	mesh.Size = typeof(spec.size) == "Vector3" and spec.size or Vector3.new(1.4, 1.0, 1.2)
	mesh.CFrame = CFrame.new(position)
	pcall(function()
		mesh.MeshId = "rbxassetid://" .. tostring(spec.meshId)
	end)
	pcall(function()
		mesh.CollisionFidelity = Enum.CollisionFidelity.Box
	end)
	mesh:SetAttribute("PasrahPropAssetKey", tostring(spec.key or name))
	mesh:SetAttribute("PasrahPropMeshId", tostring(spec.meshId))
	mesh:SetAttribute("PasrahGeneratedKind", tostring(kind or ""))
	if kind == "ceiling_light" or kind == "light" or kind == "lamp" then
		mesh.Material = Enum.Material.Neon
		local pointLight = mesh:FindFirstChild("PointLight")
		if not (pointLight and pointLight:IsA("PointLight")) then
			if pointLight then
				pointLight:Destroy()
			end
			pointLight = cloneWorldPointLightTemplate("PointLight")
			if pointLight then
				pointLight.Name = "PointLight"
				pointLight.Parent = mesh
			else
				warn("[EnvironmentalObjectRuntime] Missing authored visual template: WorldEffects.WorldPointLightTemplate")
			end
		end
		if pointLight then
			pointLight.Range = 18
			pointLight.Brightness = 1.8
			pointLight.Color = mesh.Color
			pointLight.Enabled = true
		end
	end

	model.PrimaryPart = mesh
	model:SetAttribute("PasrahPropAssetKey", tostring(spec.key or name))
	model:SetAttribute("PasrahPropMeshId", tostring(spec.meshId))
	model:SetAttribute("PasrahGeneratedKind", tostring(kind or ""))
	return model
end

local function createTelevision(parent, name, position)
	local model = parent:FindFirstChild(name)
	if model and not model:IsA("Model") then
		model:Destroy()
		model = nil
	end
	if not model then
		model = Instance.new("Model")
		model.Name = name
		model.Parent = parent
	end

	local frame = ensurePart(model, "Frame")
	frame.Anchored = true
	frame.CanCollide = true
	frame.CanTouch = false
	frame.CanQuery = true
	frame.Material = Enum.Material.SmoothPlastic
	frame.Color = Color3.fromRGB(24, 26, 32)
	frame.Size = Vector3.new(2.6, 1.6, 0.24)
	frame.CFrame = CFrame.new(position)

	local screen = ensurePart(model, "Screen")
	screen.Anchored = true
	screen.CanCollide = false
	screen.CanTouch = false
	screen.CanQuery = false
	screen.Material = Enum.Material.Neon
	screen.Color = Color3.fromRGB(18, 24, 32)
	screen.Size = Vector3.new(2.15, 1.15, 0.06)
	screen.CFrame = frame.CFrame * CFrame.new(0, 0.06, -0.1)

	local stand = ensurePart(model, "Stand")
	stand.Anchored = true
	stand.CanCollide = false
	stand.CanTouch = false
	stand.CanQuery = false
	stand.Material = Enum.Material.Metal
	stand.Color = Color3.fromRGB(68, 72, 78)
	stand.Size = Vector3.new(0.16, 0.7, 0.16)
	stand.CFrame = frame.CFrame * CFrame.new(0, -1.05, 0.04)

	local glow = screen:FindFirstChild("Glow")
	if not (glow and glow:IsA("PointLight")) then
		if glow then
			glow:Destroy()
		end
		glow = cloneWorldPointLightTemplate("Glow")
		if glow then
			glow.Name = "Glow"
			glow.Parent = screen
		else
			warn("[EnvironmentalObjectRuntime] Missing authored visual template: WorldEffects.WorldPointLightTemplate")
		end
	end
	if glow then
		glow.Range = 10
		glow.Brightness = 0
		glow.Enabled = false
	end

	model.PrimaryPart = frame
	return model
end

local function createRadio(parent, name, position)
	local model = parent:FindFirstChild(name)
	if model and not model:IsA("Model") then
		model:Destroy()
		model = nil
	end
	if not model then
		model = Instance.new("Model")
		model.Name = name
		model.Parent = parent
	end

	local body = ensurePart(model, "Body")
	body.Anchored = true
	body.CanCollide = true
	body.CanTouch = false
	body.CanQuery = true
	body.Material = Enum.Material.SmoothPlastic
	body.Color = Color3.fromRGB(46, 54, 64)
	body.Size = Vector3.new(1.2, 0.7, 0.5)
	body.CFrame = CFrame.new(position)

	local indicator = ensurePart(model, "Indicator")
	indicator.Anchored = true
	indicator.CanCollide = false
	indicator.CanTouch = false
	indicator.CanQuery = false
	indicator.Material = Enum.Material.Neon
	indicator.Color = Color3.fromRGB(88, 214, 255)
	indicator.Size = Vector3.new(0.14, 0.14, 0.06)
	indicator.CFrame = body.CFrame * CFrame.new(0.4, 0.1, -0.28)

	local glow = indicator:FindFirstChild("Glow")
	if not (glow and glow:IsA("PointLight")) then
		if glow then
			glow:Destroy()
		end
		glow = cloneWorldPointLightTemplate("Glow")
		if glow then
			glow.Name = "Glow"
			glow.Parent = indicator
		else
			warn("[EnvironmentalObjectRuntime] Missing authored visual template: WorldEffects.WorldPointLightTemplate")
		end
	end
	if glow then
		glow.Range = 6
		glow.Brightness = 0
		glow.Enabled = false
	end

	model.PrimaryPart = body
	return model
end

local function createGeneratedTarget(generatedFolder, name, kind, position)
	if not (generatedFolder and generatedFolder:IsA("Folder") and type(kind) == "string" and kind ~= "" and typeof(position) == "Vector3") then
		return nil
	end
	local authoredProp = createAuthoredEventProp(generatedFolder, name, kind, position)
	if authoredProp then
		return authoredProp
	end
	if kind == "ceiling_light" then
		return createCeilingLight(generatedFolder, name, position)
	end
	if kind == "prop_box" then
		return createPropBox(generatedFolder, name, position, Color3.fromRGB(112, 90, 62))
	end
	if kind == "prop_crate" then
		return createPropBox(generatedFolder, name, position, Color3.fromRGB(96, 78, 58))
	end
	if kind == "tv" then
		return createTelevision(generatedFolder, name, position)
	end
	if kind == "radio" then
		return createRadio(generatedFolder, name, position)
	end
	return nil
end

local function findNearestNamedInstance(root, targetName, expectedPosition)
	if typeof(root) ~= "Instance" or type(targetName) ~= "string" or targetName == "" then
		return nil
	end
	local best = nil
	local bestDistance = math.huge
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant.Name == targetName then
			local candidateCFrame = getInstanceCFrame(descendant)
			if candidateCFrame then
				local distance = expectedPosition and (candidateCFrame.Position - expectedPosition).Magnitude or 0
				if best == nil or distance < bestDistance then
					best = descendant
					bestDistance = distance
				end
			end
		end
	end
	return best
end

local function resolveGeneratedTargetPosition(proxyPart, definition, generatedPosition)
	if not (proxyPart and proxyPart:IsA("BasePart")) then
		return generatedPosition
	end
	local runtimeProxyPosition = proxyPart.Position
	if typeof(generatedPosition) ~= "Vector3" then
		return runtimeProxyPosition
	end
	local authoredProxyPosition = type(definition) == "table" and definition.proxyPosition or nil
	if typeof(authoredProxyPosition) == "Vector3" then
		return runtimeProxyPosition + (generatedPosition - authoredProxyPosition)
	end
	return runtimeProxyPosition
end

local function resolveTargetInstance(mapClone, generatedFolder, proxyPart, definition)
	local generatedKind = proxyPart:GetAttribute("PasrahGeneratedKind")
	local generatedDefinition = type(definition) == "table" and definition.generated or nil
	if (type(generatedKind) ~= "string" or generatedKind == "") and type(generatedDefinition) == "table" then
		generatedKind = generatedDefinition.kind
	end
	if type(generatedKind) == "string" and generatedKind ~= "" then
		local generatedPosition = parseVector3String(proxyPart:GetAttribute("PasrahGeneratedPosition"))
		if typeof(generatedPosition) ~= "Vector3" and type(generatedDefinition) == "table" and proxyPart:GetAttribute("PasrahGeneratedKind") ~= nil then
			generatedPosition = generatedDefinition.position
		end
		if typeof(generatedPosition) ~= "Vector3" then
			generatedPosition = proxyPart.Position
		end
		generatedPosition = resolveGeneratedTargetPosition(proxyPart, definition, generatedPosition)
		if generatedKind == "prop_box" or generatedKind == "prop_crate" then
			local generatedTarget = createGeneratedTarget(generatedFolder, proxyPart.Name, generatedKind, generatedPosition)
			if generatedTarget then
				proxyPart.Transparency = 1
				proxyPart.CanCollide = false
				proxyPart.CanTouch = false
				proxyPart.CanQuery = false
				return generatedTarget
			end
			return configurePropBoxPart(proxyPart, generatedKind)
		end
		return createGeneratedTarget(generatedFolder, proxyPart.Name, generatedKind, generatedPosition)
	end

	local targetRootName = proxyPart:GetAttribute("PasrahTargetRootName")
	if (type(targetRootName) ~= "string" or targetRootName == "") and type(definition) == "table" then
		targetRootName = definition.targetRootName
	end
	if type(targetRootName) ~= "string" or targetRootName == "" then
		return nil
	end
	local expectedPosition = parseVector3String(proxyPart:GetAttribute("PasrahTargetPosition"))
	if typeof(expectedPosition) ~= "Vector3" and type(definition) == "table" then
		expectedPosition = definition.expectedPosition
	end
	local root = findNearestNamedInstance(mapClone, targetRootName, expectedPosition)
	if not root then
		return nil
	end
	local targetName = proxyPart:GetAttribute("PasrahTargetName")
	if (type(targetName) ~= "string" or targetName == "") and type(definition) == "table" then
		targetName = definition.targetName
	end
	if type(targetName) == "string" and targetName ~= "" then
		return findNearestNamedInstance(root, targetName, expectedPosition) or root
	end
	return root
end

local function collectLightDescendants(target)
	local lights = {}
	local neonParts = {}
	if typeof(target) ~= "Instance" then
		return lights, neonParts
	end
	local descendants = target:IsA("BasePart") and { target } or target:GetDescendants()
	for _, descendant in ipairs(descendants) do
		if descendant:IsA("PointLight") or descendant:IsA("SpotLight") or descendant:IsA("SurfaceLight") then
			lights[#lights + 1] = descendant
		elseif descendant:IsA("BasePart") and descendant.Material == Enum.Material.Neon then
			neonParts[#neonParts + 1] = descendant
		end
	end
	return lights, neonParts
end

local function collectBaseParts(target)
	local parts = {}
	if typeof(target) ~= "Instance" then
		return parts
	end
	if target:IsA("BasePart") then
		parts[1] = target
		return parts
	end
	for _, descendant in ipairs(target:GetDescendants()) do
		if descendant:IsA("BasePart") then
			parts[#parts + 1] = descendant
		end
	end
	return parts
end

local function findRoomPart(mapClone, roomId)
	if typeof(mapClone) ~= "Instance" or type(roomId) ~= "string" or roomId == "" then
		return nil
	end
	local roomsFolder = mapClone:FindFirstChild("Rooms", true)
	if not roomsFolder then
		return nil
	end
	local direct = roomsFolder:FindFirstChild("Room_" .. roomId)
	if direct and direct:IsA("BasePart") then
		return direct
	end
	for _, child in ipairs(roomsFolder:GetChildren()) do
		if child:IsA("BasePart")
			and (child.Name == roomId or tostring(child:GetAttribute("RoomId") or child:GetAttribute("PasrahRoomId") or "") == roomId) then
			return child
		end
	end
	return nil
end

local function createLightSwitch(generatedFolder, mapClone, definition, proxyPart)
	if not (generatedFolder and generatedFolder:IsA("Folder") and type(definition) == "table" and proxyPart and proxyPart:IsA("BasePart")) then
		return nil
	end
	local switchName = "Switch_" .. tostring(definition.objectId or proxyPart.Name)
	local switch = ensurePart(generatedFolder, switchName)
	local roomPart = findRoomPart(mapClone, definition.roomId)
	local proxyPosition = proxyPart.Position
	local switchPosition = proxyPosition - Vector3.new(0, 3.2, 0)
	local lookAt = proxyPosition + Vector3.new(0, 0, -1)
	if roomPart then
		local roomPosition = roomPart.Position
		local flatDirection = Vector3.new(proxyPosition.X - roomPosition.X, 0, proxyPosition.Z - roomPosition.Z)
		if flatDirection.Magnitude <= 0.1 then
			flatDirection = Vector3.new(1, 0, 0)
		end
		local wallDistance = math.max(2, math.min(roomPart.Size.X, roomPart.Size.Z) * 0.36)
		local floorY = roomPosition.Y - (roomPart.Size.Y * 0.5)
		switchPosition = Vector3.new(roomPosition.X, floorY + LIGHT_SWITCH_WALL_HEIGHT, roomPosition.Z)
			+ flatDirection.Unit * wallDistance
		lookAt = Vector3.new(roomPosition.X, switchPosition.Y, roomPosition.Z)
	end

	switch.Anchored = true
	switch.CanCollide = false
	switch.CanTouch = false
	switch.CanQuery = true
	switch.CastShadow = false
	switch.Material = Enum.Material.SmoothPlastic
	switch.Color = LIGHT_SWITCH_ON_COLOR
	switch.Size = Vector3.new(0.42, 0.62, 0.08)
	switch.CFrame = CFrame.lookAt(switchPosition, lookAt)
	switch:SetAttribute("PasrahEnvironmentalRuntime", true)
	switch:SetAttribute("PasrahLightSwitchObjectId", definition.objectId)
	switch:SetAttribute("PasrahRuntimeRoomId", definition.roomId)
	switch:SetAttribute("PasrahLightSwitchOn", true)

	local prompt = switch:FindFirstChild(LIGHT_SWITCH_PROMPT_NAME)
	if not (prompt and prompt:IsA("ProximityPrompt")) then
		if prompt then
			prompt:Destroy()
		end
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = LIGHT_SWITCH_PROMPT_NAME
		prompt.Parent = switch
	end
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.ObjectText = tostring(definition.roomId or "Lampu")
	prompt.ActionText = "Matikan Lampu"
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.AlwaysShow
	pcall(function()
		prompt.ClickablePrompt = true
	end)
	return switch
end

local function registerObject(interactionSystem, objectId, objectType, position, roomId, interactions)
	if not interactionSystem or type(interactionSystem.RegisterObject) ~= "function" then
		return
	end
	interactionSystem:RegisterObject({
		id = objectId,
		type = objectType,
		position = position,
		roomId = roomId,
		interactions = interactions,
	})
end

local function buildLookupFromFolder(definitions, folder, mapClone, generatedFolder, interactionSystem, objectType, interactions)
	local lookup = {}
	for _, definition in ipairs(definitions) do
		local proxy = folder:FindFirstChild(definition.objectId)
		if proxy and proxy:IsA("BasePart") then
			local target = resolveTargetInstance(mapClone, generatedFolder, proxy, definition)
			if target == nil and type(definition.generated) == "table" then
				if definition.generated.kind == "prop_box" or definition.generated.kind == "prop_crate" then
					target = configurePropBoxPart(proxy, definition.generated.kind)
				else
					target = createGeneratedTarget(
						generatedFolder,
						definition.objectId,
						definition.generated.kind,
						resolveGeneratedTargetPosition(proxy, definition, definition.generated.position)
					)
				end
			end
			if objectType == "Light" and type(definition.generated) == "table" then
				local lights, neonParts = collectLightDescendants(target)
				if #lights == 0 and #neonParts == 0 then
					if typeof(target) == "Instance" and target.Parent == generatedFolder then
						target:Destroy()
					end
					target = createGeneratedTarget(
						generatedFolder,
						definition.objectId,
						definition.generated.kind,
						resolveGeneratedTargetPosition(proxy, definition, definition.generated.position)
					)
				end
			end
			registerObject(interactionSystem, definition.objectId, objectType, proxy.Position, definition.roomId, interactions)
			lookup[definition.objectId] = {
				id = definition.objectId,
				objectType = objectType,
				roomId = definition.roomId,
				proxy = proxy,
				target = target,
				switch = objectType == "Light" and createLightSwitch(generatedFolder, mapClone, definition, proxy) or nil,
				lightOn = true,
				defaultCFrame = getInstanceCFrame(target),
			}
		end
	end
	return lookup
end

local function captureLightBaseline(target)
	local baseline = {
		lights = {},
		neonParts = {},
	}
	local lights, neonParts = collectLightDescendants(target)
	for _, light in ipairs(lights) do
		baseline.lights[light] = {
			enabled = light.Enabled,
			brightness = light.Brightness,
			color = light.Color,
		}
	end
	for _, part in ipairs(neonParts) do
		baseline.neonParts[part] = {
			transparency = part.Transparency,
			color = part.Color,
		}
	end
	return baseline
end

local function stampLightSwitch(record)
	local switch = record and record.switch
	if not (switch and switch:IsA("BasePart")) then
		return
	end
	local isOn = record.lightOn ~= false
	switch.Color = isOn and LIGHT_SWITCH_ON_COLOR or LIGHT_SWITCH_OFF_COLOR
	switch:SetAttribute("PasrahLightSwitchOn", isOn)
	local prompt = switch:FindFirstChild(LIGHT_SWITCH_PROMPT_NAME)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.ActionText = isOn and "Matikan Lampu" or "Nyalakan Lampu"
	end
end

local function applyLightPower(record, enabled)
	if type(record) ~= "table" or typeof(record.target) ~= "Instance" then
		return
	end
	record.lightBaseline = record.lightBaseline or captureLightBaseline(record.target)
	record.lightOn = enabled == true
	local baseline = record.lightBaseline
	for light, state in pairs(baseline.lights or {}) do
		if typeof(light) == "Instance" and light.Parent ~= nil then
			light.Enabled = record.lightOn
			light.Brightness = record.lightOn and (state.brightness or light.Brightness) or 0
			if typeof(state.color) == "Color3" then
				light.Color = state.color
			end
		end
	end
	for part, state in pairs(baseline.neonParts or {}) do
		if typeof(part) == "Instance" and part.Parent ~= nil and part:IsA("BasePart") then
			part.Transparency = record.lightOn and (state.transparency or 0) or 0.78
			if typeof(state.color) == "Color3" then
				part.Color = record.lightOn and state.color or state.color:Lerp(Color3.fromRGB(24, 26, 30), 0.74)
			end
		end
	end
	stampLightSwitch(record)
end

local function applyLightFlicker(record)
	if type(record) ~= "table" or typeof(record.target) ~= "Instance" then
		return
	end
	local lights, neonParts = collectLightDescendants(record.target)
	if #lights == 0 and #neonParts == 0 then
		return
	end
	task.spawn(function()
		local original = {}
		for _, light in ipairs(lights) do
			original[light] = { enabled = light.Enabled, brightness = light.Brightness }
		end
		for _, part in ipairs(neonParts) do
			original[part] = { transparency = part.Transparency, color = part.Color }
		end
		for index = 1, 4 do
			local enabled = index % 2 == 0
			for _, light in ipairs(lights) do
				light.Enabled = enabled
				light.Brightness = enabled and math.max(0.15, (original[light] and original[light].brightness or light.Brightness) * 0.85) or 0
			end
			for _, part in ipairs(neonParts) do
				part.Transparency = enabled and 0.08 or 0.72
			end
			task.wait(LIGHT_FLICKER_DELAY)
		end
		for instance, state in pairs(original) do
			if instance:IsA("PointLight") or instance:IsA("SpotLight") or instance:IsA("SurfaceLight") then
				instance.Enabled = record.lightOn == false and false or state.enabled
				instance.Brightness = record.lightOn == false and 0 or state.brightness
			elseif instance:IsA("BasePart") then
				instance.Transparency = record.lightOn == false and 0.78 or state.transparency
				instance.Color = record.lightOn == false and state.color:Lerp(Color3.fromRGB(24, 26, 30), 0.74) or state.color
			end
		end
		stampLightSwitch(record)
	end)
end

local function applyObjectMovement(record, interactionType)
	if type(record) ~= "table" or typeof(record.target) ~= "Instance" then
		return
	end
	local defaultCFrame = record.defaultCFrame or getInstanceCFrame(record.target)
	if typeof(defaultCFrame) ~= "CFrame" then
		return
	end
	local throwStrength = interactionType == "Throw" and 3.8 or 1.2
	local targetCFrame = defaultCFrame * CFrame.new(throwStrength, 0.25, -throwStrength * 0.35) * CFrame.Angles(0, math.rad(22), math.rad(10))
	applyInstanceCFrame(record.target, targetCFrame)
	task.delay(GENERATED_REVERT_DELAY, function()
		if typeof(record.target) == "Instance" and record.target.Parent ~= nil then
			applyInstanceCFrame(record.target, defaultCFrame)
		end
	end)
end

local function applyElectronicDisturbance(record, interactionType)
	if type(record) ~= "table" or typeof(record.target) ~= "Instance" then
		return
	end
	local descendants = record.target:IsA("BasePart") and { record.target } or record.target:GetDescendants()
	for _, descendant in ipairs(descendants) do
		if descendant:IsA("BasePart") and descendant.Name == "Screen" then
			descendant.Color = Color3.fromRGB(154, 214, 255)
			descendant.Transparency = 0.04
			local glow = descendant:FindFirstChild("Glow")
			if glow and glow:IsA("PointLight") then
				glow.Enabled = true
				glow.Brightness = interactionType == "TurnOn" and 1.4 or 2.4
			end
		elseif descendant:IsA("BasePart") and descendant.Name == "Indicator" then
			descendant.Color = Color3.fromRGB(112, 220, 255)
			local glow = descendant:FindFirstChild("Glow")
			if glow and glow:IsA("PointLight") then
				glow.Enabled = true
				glow.Brightness = 1.8
			end
		end
	end
	task.delay(GENERATED_REVERT_DELAY, function()
		if typeof(record.target) ~= "Instance" or record.target.Parent == nil then
			return
		end
		local restored = record.target:IsA("BasePart") and { record.target } or record.target:GetDescendants()
		for _, descendant in ipairs(restored) do
			if descendant:IsA("BasePart") and descendant.Name == "Screen" then
				descendant.Color = Color3.fromRGB(18, 24, 32)
				local glow = descendant:FindFirstChild("Glow")
				if glow and glow:IsA("PointLight") then
					glow.Enabled = false
					glow.Brightness = 0
				end
			elseif descendant:IsA("BasePart") and descendant.Name == "Indicator" then
				descendant.Color = Color3.fromRGB(88, 214, 255)
				local glow = descendant:FindFirstChild("Glow")
				if glow and glow:IsA("PointLight") then
					glow.Enabled = false
					glow.Brightness = 0
				end
			end
		end
	end)
end

local function applyWindowKnock(record)
	if type(record) ~= "table" or typeof(record.target) ~= "Instance" then
		return
	end
	local defaultCFrame = record.defaultCFrame or getInstanceCFrame(record.target)
	if typeof(defaultCFrame) ~= "CFrame" then
		return
	end
	applyInstanceCFrame(record.target, defaultCFrame * CFrame.new(0, 0, -0.08))
	task.delay(0.12, function()
		if typeof(record.target) ~= "Instance" or record.target.Parent == nil then
			return
		end
		applyInstanceCFrame(record.target, defaultCFrame * CFrame.new(0, 0, 0.08))
		task.delay(0.1, function()
			if typeof(record.target) == "Instance" and record.target.Parent ~= nil then
				applyInstanceCFrame(record.target, defaultCFrame)
			end
		end)
	end)
end

local function mergeLookups(...)
	local merged = {}
	for _, lookup in ipairs({ ... }) do
		for objectId, record in pairs(lookup or {}) do
			merged[objectId] = record
		end
	end
	return merged
end

function EnvironmentalObjectRuntime.Attach(match, mapClone, deps)
	if typeof(mapClone) ~= "Instance" then
		return false
	end
	local layout = resolveLayout(mapClone)
	if not layout then
		return false
	end

	local eventBus = resolveEventBus(deps)
	local interactionSystem = resolveMapInteractionSystem(deps)
	local generatedFolder = ensureFolder(mapClone, GENERATED_FOLDER_NAME)
	clearGeneratedRuntimeFolder(generatedFolder)
	local lightsFolder = mapClone:FindFirstChild("Lights", true)
	local propsFolder = mapClone:FindFirstChild("Props", true)
	local electronicsFolder = mapClone:FindFirstChild("Electronics", true)
	local windowsFolder = mapClone:FindFirstChild("Windows", true)
	if not (lightsFolder and propsFolder and electronicsFolder and windowsFolder) then
		return false
	end

	local objectLookup = mergeLookups(
		buildLookupFromFolder(layout.lights, lightsFolder, mapClone, generatedFolder, interactionSystem, "Light", { "TurnOn", "TurnOff", "Flicker" }),
		buildLookupFromFolder(layout.props, propsFolder, mapClone, generatedFolder, interactionSystem, "Object", { "Move", "Throw", "Rotate" }),
		buildLookupFromFolder(layout.electronics, electronicsFolder, mapClone, generatedFolder, interactionSystem, "Radio", { "TurnOn", "TurnOff", "PlayNoise", "StaticDistortion" }),
		buildLookupFromFolder(layout.windows, windowsFolder, mapClone, generatedFolder, interactionSystem, "Window", { "Knock" })
	)
	if next(objectLookup) == nil or not eventBus then
		return next(objectLookup) ~= nil
	end

	for _, record in pairs(objectLookup) do
		if record.objectType == "Light" and record.switch and record.switch:IsA("BasePart") then
			stampLightSwitch(record)
			local prompt = record.switch:FindFirstChild(LIGHT_SWITCH_PROMPT_NAME)
			if prompt and prompt:IsA("ProximityPrompt") then
				prompt.Triggered:Connect(function()
					local nextEnabled = record.lightOn == false
					local interactionSystem = resolveMapInteractionSystem(deps)
					if interactionSystem and type(interactionSystem.ExecuteInteraction) == "function" then
						interactionSystem:ExecuteInteraction(record.id, nextEnabled and "TurnOn" or "TurnOff", {
							source = "LightSwitchPrompt",
							now = os.clock(),
						})
					elseif interactionSystem and type(interactionSystem.Service) == "table"
						and type(interactionSystem.Service.ExecuteInteraction) == "function" then
						interactionSystem.Service:ExecuteInteraction(record.id, nextEnabled and "TurnOn" or "TurnOff", {
							source = "LightSwitchPrompt",
							now = os.clock(),
						})
					else
						applyLightPower(record, nextEnabled)
					end
				end)
			end
		end
	end

	if match and match._environmentRuntimeSubscription then
		eventBus:Unsubscribe("MapObjectInteracted", match._environmentRuntimeSubscription)
		match._environmentRuntimeSubscription = nil
	end
	if match and match._environmentRuntimeRemoteConnection then
		match._environmentRuntimeRemoteConnection:Disconnect()
		match._environmentRuntimeRemoteConnection = nil
	end

	local matchId = match and tostring(match.matchId or match.id or "") or ""
	local remoteCooldowns = {}
	local remote = ensureMapInteractionRemote()
	if remote and match then
		match._environmentRuntimeRemoteConnection = remote.OnServerEvent:Connect(function(player, request)
			if type(request) ~= "table" then
				return
			end
			if not (typeof(player) == "Instance" and player:IsA("Player")) then
				return
			end
			if player:GetAttribute("InMatch") ~= true or tostring(player:GetAttribute("MatchId") or "") ~= matchId then
				return
			end
			if tostring(player:GetAttribute("MatchLifecyclePhase") or "") ~= "InvestigationPhase" then
				if tostring(request.action or "") ~= "PreparationToolResponse" or tostring(player:GetAttribute("MatchLifecyclePhase") or "") ~= "PreparationPhase" then
					player:SetAttribute("PasrahLastMapInteractionResult", "rejected_phase")
					return
				end
			end

			local action = tostring(request.action or "")
			if action == "PreparationToolRequest" then
				local toolType = tostring(request.toolType or "")
				if toolType == "" then
					return
				end
				-- CrosshairInteraction client dispatch — replicate Prompt.Triggered behavior
				player:SetAttribute("PasrahPreparationToolPendingToolType", toolType)
				player:SetAttribute("PasrahPreparationToolPendingLabel", toolType)
				player:SetAttribute("PasrahPreparationToolPendingSource", "CrosshairClick")
				player:SetAttribute("PasrahPreparationToolPendingResponse", "")
				local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
				local matchRemote = remoteFolder and remoteFolder:FindFirstChild("MatchEvent")
				if matchRemote and matchRemote:IsA("RemoteEvent") then
					matchRemote:FireClient(player, {
						type = "toolConfirmRequest",
						toolType = toolType,
						toolLabel = toolType,
						message = string.format("Yakin pilih %s?", toolType),
					})
				end
				return
			end
			if action == "PreparationToolResponse" then
				local pendingToolType = tostring(player:GetAttribute("PasrahPreparationToolPendingToolType") or "")
				if pendingToolType == "" then
					player:SetAttribute("PasrahLastMapInteractionResult", "rejected_pending_missing")
					return
				end
				local requestedToolType = tostring(request.toolType or "")
				if requestedToolType ~= "" and requestedToolType ~= pendingToolType then
					player:SetAttribute("PasrahLastMapInteractionResult", "rejected_pending_mismatch")
					return
				end
				local response = tostring(request.response or "")
				if response ~= "confirm" and response ~= "cancel" then
					player:SetAttribute("PasrahLastMapInteractionResult", "rejected_pending_response")
					return
				end
				player:SetAttribute("PasrahPreparationToolPendingResponse", response .. ":" .. tostring(os.clock()))
				player:SetAttribute("PasrahLastMapInteractionResult", "ok:" .. response .. ":" .. pendingToolType)
				return
			end
			if action ~= "ToggleLight" then
				return
			end

			local objectId = tostring(request.objectId or "")
			local record = objectLookup[objectId]
			if type(record) ~= "table" or record.objectType ~= "Light" or not (record.switch and record.switch:IsA("BasePart")) then
				player:SetAttribute("PasrahLastMapInteractionResult", "rejected_object")
				return
			end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not (root and root:IsA("BasePart")) then
				player:SetAttribute("PasrahLastMapInteractionResult", "rejected_character")
				return
			end
			local distance = (root.Position - record.switch.Position).Magnitude
			if distance > LIGHT_SWITCH_REMOTE_DISTANCE then
				player:SetAttribute("PasrahLastMapInteractionResult", "rejected_distance:" .. tostring(math.floor(distance * 100 + 0.5) / 100))
				return
			end

			local now = os.clock()
			local cooldownKey = tostring(player.UserId) .. ":" .. objectId
			if now < (remoteCooldowns[cooldownKey] or 0) then
				player:SetAttribute("PasrahLastMapInteractionResult", "rejected_cooldown")
				return
			end
			remoteCooldowns[cooldownKey] = now + LIGHT_SWITCH_REMOTE_COOLDOWN

			local nextEnabled = record.lightOn == false
			local interactionSystem = resolveMapInteractionSystem(deps)
			local ok = false
			if interactionSystem and type(interactionSystem.ExecuteInteraction) == "function" then
				ok = interactionSystem:ExecuteInteraction(record.id, nextEnabled and "TurnOn" or "TurnOff", {
					source = "LightSwitchFallback",
					now = now,
				}) == true
			elseif interactionSystem and type(interactionSystem.Service) == "table"
				and type(interactionSystem.Service.ExecuteInteraction) == "function" then
				ok = interactionSystem.Service:ExecuteInteraction(record.id, nextEnabled and "TurnOn" or "TurnOff", {
					source = "LightSwitchFallback",
					now = now,
				}) == true
			else
				applyLightPower(record, nextEnabled)
				ok = true
			end
			player:SetAttribute("PasrahLastMapInteractionResult", ok and "ok:" .. objectId or "failed:" .. objectId)
		end)
	end

	local callback = function(payload)
		if type(payload) ~= "table" then
			return
		end
		local payloadMatchId = tostring(payload.matchId or "")
		if matchId ~= "" and payloadMatchId ~= "" and payloadMatchId ~= matchId then
			return
		end
		local record = objectLookup[payload.objectId]
		if not record then
			return
		end
		local interactionType = tostring(payload.interactionType or "")
		if interactionType == "Flicker" then
			applyLightFlicker(record)
		elseif record.objectType == "Light" and (interactionType == "TurnOn" or interactionType == "TurnOff") then
			applyLightPower(record, interactionType == "TurnOn")
		elseif interactionType == "Move" or interactionType == "Throw" or interactionType == "Rotate" then
			applyObjectMovement(record, interactionType)
		elseif interactionType == "TurnOn" or interactionType == "TurnOff" or interactionType == "PlayNoise" or interactionType == "StaticDistortion" then
			applyElectronicDisturbance(record, interactionType)
		elseif interactionType == "Knock" then
			applyWindowKnock(record)
		end
	end

	eventBus:Subscribe("MapObjectInteracted", callback)
	if match then
		match._environmentRuntimeSubscription = callback
	end
	return true
end

return EnvironmentalObjectRuntime

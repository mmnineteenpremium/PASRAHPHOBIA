local Services = require(script.Parent.Parent.Core.Services)
local TweenService = game:GetService("TweenService")

local AbandonedPalaceLayout = require(script.Parent.AbandonedPalaceRuntimeLayout)
local EmptyBuildingLayout = require(script.Parent.EmptyBuildingRuntimeLayout)
local HauntedLayout = require(script.Parent.HauntedHouseRuntimeLayout)
local StudioMMNineteenLayout = require(script.Parent.StudioMMNineteenRuntimeLayout)

local EnvironmentalObjectRuntime = {}

local GENERATED_FOLDER_NAME = "GeneratedEventAssets"
local GENERATED_REVERT_DELAY = 1.6
local LIGHT_FLICKER_DELAY = 0.08

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
		return nil
	end
	return interactionSystem
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
		pointLight = Instance.new("PointLight")
		pointLight.Name = "Light"
		pointLight.Parent = bulb
	end
	pointLight.Range = 18
	pointLight.Brightness = 1.8
	pointLight.Color = bulb.Color
	pointLight.Enabled = true

	model.PrimaryPart = cap
	return model
end

local function createPropBox(parent, name, position, color)
	local part = ensurePart(parent, name)
	part.Anchored = true
	part.CanCollide = true
	part.CanTouch = false
	part.CanQuery = true
	part.Material = Enum.Material.WoodPlanks
	part.Color = color or Color3.fromRGB(116, 92, 64)
	part.Size = Vector3.new(1.6, 1.2, 1.1)
	part.CFrame = CFrame.new(position)
	return part
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
		glow = Instance.new("PointLight")
		glow.Name = "Glow"
		glow.Parent = screen
	end
	glow.Range = 10
	glow.Brightness = 0
	glow.Enabled = false

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
		glow = Instance.new("PointLight")
		glow.Name = "Glow"
		glow.Parent = indicator
	end
	glow.Range = 6
	glow.Brightness = 0
	glow.Enabled = false

	model.PrimaryPart = body
	return model
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

local function resolveTargetInstance(mapClone, generatedFolder, proxyPart)
	local generatedKind = proxyPart:GetAttribute("PasrahGeneratedKind")
	if type(generatedKind) == "string" and generatedKind ~= "" then
		local generatedPosition = parseVector3String(proxyPart:GetAttribute("PasrahGeneratedPosition")) or proxyPart.Position
		if generatedKind == "ceiling_light" then
			return createCeilingLight(generatedFolder, proxyPart.Name, generatedPosition)
		end
		if generatedKind == "prop_box" then
			return createPropBox(generatedFolder, proxyPart.Name, generatedPosition, Color3.fromRGB(112, 90, 62))
		end
		if generatedKind == "prop_crate" then
			return createPropBox(generatedFolder, proxyPart.Name, generatedPosition, Color3.fromRGB(96, 78, 58))
		end
		if generatedKind == "tv" then
			return createTelevision(generatedFolder, proxyPart.Name, generatedPosition)
		end
		if generatedKind == "radio" then
			return createRadio(generatedFolder, proxyPart.Name, generatedPosition)
		end
	end

	local targetRootName = proxyPart:GetAttribute("PasrahTargetRootName")
	if type(targetRootName) ~= "string" or targetRootName == "" then
		return nil
	end
	local expectedPosition = parseVector3String(proxyPart:GetAttribute("PasrahTargetPosition"))
	local root = findNearestNamedInstance(mapClone, targetRootName, expectedPosition)
	if not root then
		return nil
	end
	local targetName = proxyPart:GetAttribute("PasrahTargetName")
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
			local target = resolveTargetInstance(mapClone, generatedFolder, proxy)
			registerObject(interactionSystem, definition.objectId, objectType, proxy.Position, definition.roomId, interactions)
			lookup[definition.objectId] = {
				id = definition.objectId,
				roomId = definition.roomId,
				proxy = proxy,
				target = target,
				defaultCFrame = getInstanceCFrame(target),
			}
		end
	end
	return lookup
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
				instance.Enabled = state.enabled
				instance.Brightness = state.brightness
			elseif instance:IsA("BasePart") then
				instance.Transparency = state.transparency
				instance.Color = state.color
			end
		end
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

	if match and match._environmentRuntimeSubscription then
		eventBus:Unsubscribe("MapObjectInteracted", match._environmentRuntimeSubscription)
		match._environmentRuntimeSubscription = nil
	end

	local matchId = match and tostring(match.matchId or match.id or "") or ""
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

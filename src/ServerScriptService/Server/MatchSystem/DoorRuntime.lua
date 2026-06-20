local Services = require(script.Parent.Parent.Core.Services)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DoorRuntime = {}

local PROMPT_NAME = "DoorPrompt"
local PATH_MODIFIER_NAME = "DoorPathModifier"
local POLICY_ATTR_NAME = "DoorTraversalPolicy"
local OPEN_SOUND_ATTR_NAME = "DoorOpenSoundId"
local CLOSE_SOUND_ATTR_NAME = "DoorCloseSoundId"
local OPEN_SOUND_NAME = "DoorOpenSound"
local CLOSE_SOUND_NAME = "DoorCloseSound"
local GUIDE_FOLDER_NAME = "DoorRouteGuideRuntime"
local GUIDE_HIGHLIGHT_NAME = "Highlight"
local GUIDE_BILLBOARD_NAME = "Billboard"
local DOOR_ROUTE_GUIDES_ENABLED = false
local OPEN_ANGLE = math.rad(88)
local INTERACTION_DISTANCE = 10
local PROMPT_HOLD_DURATION = 0
local POLICY_PROMPT_MANUAL = "PromptManual"
local POLICY_HYBRID_RADIUS_PROMPT = "HybridRadiusPrompt"
local HYBRID_OPEN_APPROACH_DEPTH = 6
local HYBRID_CLOSE_APPROACH_DEPTH = 8
local HYBRID_LATERAL_PADDING = 1.75
local HYBRID_VERTICAL_TOLERANCE = 6
local HYBRID_CLOSE_DELAY = 1.15
local MANUAL_OVERRIDE_SECONDS = 1.8
local LOCAL_PROMPT_SOURCE = "DoorRuntimePrompt"
local LOCAL_AUTO_SOURCE = "DoorRuntimeAuto"
local LOCAL_PREPARATION_PROXIMITY_SOURCE = "DoorRuntimePreparationProximity"
local PREPARATION_ADVANCE_APPROACH_DEPTH = 2.75
local PREPARATION_ADVANCE_LATERAL_PADDING = 2.35
local PREPARATION_ADVANCE_HOLD_SECONDS = 0.32
-- Staging-side interaction is often blocked by front-door collision/gate parts,
-- so center-distance fallback must cover realistic reachable player positions.
local PREPARATION_ADVANCE_RADIUS_FALLBACK = 9.5
local PREPARATION_BREACH_TARGET_RADIUS = 3.75
local PREPARATION_BREACH_PROMPT_NAME = "PreparationBreachPrompt"
local PREPARATION_BREACH_PROXY_NAME = "PreparationBreachDoorPrompt"
local PREPARATION_BREACH_PROMPT_DISTANCE = 14
local PREPARATION_ADVANCE_FAILSAFE_SECONDS = 1.6
local PREPARATION_ADVANCE_PROXIMITY_GRACE_SECONDS = 1.25
local INVESTIGATION_EXIT_ACTION_TEXT = "Kembali ke Base"
local INVESTIGATION_EXIT_TELEPORT_LIFT = 3
local DEFAULT_OPEN_SOUND_ID = "rbxassetid://119680795545028"
local DEFAULT_CLOSE_SOUND_ID = "rbxassetid://79226838058023"
local DEFAULT_SOUND_VOLUME = 0.45
local DEFAULT_SOUND_MAX_DISTANCE = 42
local DOOR_ROUTE_GUIDE_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldMarkers", "DoorRouteGuideBillboardTemplate" }
local DOOR_ROUTE_HIGHLIGHT_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldEffects", "WorldHighlightTemplate" }

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

local function cloneDoorRouteGuideTemplate()
	local template = resolveChildPath(ReplicatedStorage, DOOR_ROUTE_GUIDE_TEMPLATE_PATH)
	if template and template:IsA("BillboardGui") then
		local clone = template:Clone()
		clone.Name = GUIDE_BILLBOARD_NAME
		return clone
	end
	return nil
end

local function cloneDoorRouteHighlightTemplate()
	local template = resolveChildPath(ReplicatedStorage, DOOR_ROUTE_HIGHLIGHT_TEMPLATE_PATH)
	if template and template:IsA("Highlight") then
		local clone = template:Clone()
		clone.Name = GUIDE_HIGHLIGHT_NAME
		return clone
	end
	return nil
end

local function titleCaseToken(token)
	local raw = tostring(token or ""):gsub("(%d+)", " %1"):gsub("[_%-.]+", " ")
	raw = raw:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	if raw == "" then
		return "Pintu"
	end
	local words = {}
	for word in raw:gmatch("%S+") do
		words[#words + 1] = string.upper(word:sub(1, 1)) .. string.lower(word:sub(2))
	end
	return table.concat(words, " ")
end

local function resolveDoorLabel(part)
	if not (part and part:IsA("BasePart")) then
		return "Pintu"
	end
	local explicit = tostring(part:GetAttribute("DoorLabel") or "")
	if explicit ~= "" then
		return explicit
	end
	local token = tostring(part.Name or ""):gsub("^Door_", "")
	local label = titleCaseToken(token)
	if label == "" or label == "Door" then
		return "Pintu"
	end
	return "Pintu " .. label
end

local function resolveDoorGuideSubtitle(doorLabel)
	local token = tostring(doorLabel or ""):lower()
	if token:find("closet", 1, true) or token:find("locker", 1, true) then
		return "Refuge route"
	end
	if token:find("basement", 1, true) or token:find("attic", 1, true) or token:find("stair", 1, true) then
		return "Akses vertikal"
	end
	if token:find("bathroom", 1, true) or token:find("bedroom", 1, true) then
		return "Sweep evidence"
	end
	if token:find("kitchen", 1, true) or token:find("living", 1, true) or token:find("dining", 1, true) then
		return "Area investigasi"
	end
	return "Akses ruang"
end

local function getDoorGuidePalette(subtitle)
	if subtitle == "Refuge route" then
		return {
			accent = Color3.fromRGB(132, 186, 154),
			outline = Color3.fromRGB(188, 232, 204),
			title = Color3.fromRGB(244, 250, 246),
			subtitle = Color3.fromRGB(184, 222, 196),
		}
	end
	if subtitle == "Akses vertikal" then
		return {
			accent = Color3.fromRGB(142, 168, 236),
			outline = Color3.fromRGB(206, 220, 255),
			title = Color3.fromRGB(242, 246, 252),
			subtitle = Color3.fromRGB(188, 204, 236),
		}
	end
	if subtitle == "Sweep evidence" then
		return {
			accent = Color3.fromRGB(214, 160, 104),
			outline = Color3.fromRGB(244, 214, 172),
			title = Color3.fromRGB(250, 246, 238),
			subtitle = Color3.fromRGB(228, 196, 154),
		}
	end
	if subtitle == "Area investigasi" then
		return {
			accent = Color3.fromRGB(110, 188, 172),
			outline = Color3.fromRGB(176, 232, 220),
			title = Color3.fromRGB(240, 250, 248),
			subtitle = Color3.fromRGB(180, 224, 216),
		}
	end
	return {
		accent = Color3.fromRGB(148, 194, 240),
		outline = Color3.fromRGB(198, 224, 255),
		title = Color3.fromRGB(242, 246, 252),
		subtitle = Color3.fromRGB(178, 204, 228),
	}
end

local function ensureDoorRouteGuide(doorRecord)
	local part = type(doorRecord) == "table" and doorRecord.part or nil
	if not (part and part:IsA("BasePart") and part.Parent ~= nil) then
		return nil
	end
	if DOOR_ROUTE_GUIDES_ENABLED ~= true then
		local existingFolder = part:FindFirstChild(GUIDE_FOLDER_NAME)
		if existingFolder then
			existingFolder:Destroy()
		end
		doorRecord.guideHighlight = nil
		doorRecord.guideBillboard = nil
		doorRecord.guidePanel = nil
		return nil
	end
	local guideSubtitle = resolveDoorGuideSubtitle(doorRecord.label)
	local palette = getDoorGuidePalette(guideSubtitle)

	local folder = part:FindFirstChild(GUIDE_FOLDER_NAME)
	if not (folder and folder:IsA("Folder")) then
		if folder then
			folder:Destroy()
		end
		folder = Instance.new("Folder")
		folder.Name = GUIDE_FOLDER_NAME
		folder.Parent = part
	end

	local highlight = folder:FindFirstChild(GUIDE_HIGHLIGHT_NAME)
	if not (highlight and highlight:IsA("Highlight")) then
		if highlight then
			highlight:Destroy()
		end
		highlight = cloneDoorRouteHighlightTemplate()
		if not highlight then
			warn("[DoorRuntime] Missing authored visual template: WorldEffects.WorldHighlightTemplate")
			return nil
		end
		highlight.Name = GUIDE_HIGHLIGHT_NAME
		highlight.Parent = folder
	end
	highlight.Adornee = part
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = palette.accent
	highlight.FillTransparency = 0.97
	highlight.OutlineColor = palette.outline
	highlight.OutlineTransparency = 0.32
	highlight.Enabled = true
	doorRecord.guideHighlight = highlight

	local billboard = folder:FindFirstChild(GUIDE_BILLBOARD_NAME)
	if not (billboard and billboard:IsA("BillboardGui")) then
		if billboard then
			billboard:Destroy()
		end
		billboard = cloneDoorRouteGuideTemplate()
		if not billboard then
			warn("[DoorRuntime] Missing authored visual template: WorldMarkers.DoorRouteGuideBillboardTemplate")
			return nil
		end
		billboard.Name = GUIDE_BILLBOARD_NAME
		billboard.Parent = folder
	end
	billboard.Active = false
	billboard.Adornee = part
	billboard.AlwaysOnTop = true
	billboard.Brightness = 2
	billboard.ClipsDescendants = false
	billboard.Enabled = true
	billboard.LightInfluence = 0
	billboard.MaxDistance = 68
	billboard.ResetOnSpawn = false
	billboard.Size = UDim2.fromOffset(186, 42)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y * 0.5 + 2.4, 0)
	doorRecord.guideBillboard = billboard

	local panel = billboard:FindFirstChild("Panel")
	if not (panel and panel:IsA("Frame")) then
		if panel then
			panel:Destroy()
		end
		warn("[DoorRuntime] DoorRouteGuideBillboardTemplate missing required child: Panel")
		return nil
	end

	panel.BackgroundColor3 = Color3.fromRGB(10, 18, 28)
	panel.BackgroundTransparency = 0.16
	panel.BorderSizePixel = 0
	panel.Size = UDim2.fromScale(1, 1)
	doorRecord.guidePanel = panel
	return folder
end

local function updateDoorRouteGuide(doorRecord, isOpen, isLocked)
	local guideSubtitle = resolveDoorGuideSubtitle(doorRecord.label)
	local palette = getDoorGuidePalette(guideSubtitle)
	local doorPart = type(doorRecord) == "table" and doorRecord.part or nil
	if doorPart and doorPart:IsA("BasePart") then
		doorPart:SetAttribute("DoorRouteSubtitle", guideSubtitle)
		doorPart:SetAttribute(
			"DoorRouteStateText",
			isLocked and "Akses terkunci" or (isOpen and "Terbuka" or "Tertutup")
		)
	end
	local guide = ensureDoorRouteGuide(doorRecord)
	if not guide then
		return
	end

	local title = doorRecord.guidePanel and doorRecord.guidePanel:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		title.Text = doorRecord.label or "Pintu"
		title.TextColor3 = palette.title
	end

	local stroke = doorRecord.guidePanel and doorRecord.guidePanel:FindFirstChild("Stroke")
	if stroke and stroke:IsA("UIStroke") then
		stroke.Color = palette.accent
	end
	local accent = doorRecord.guidePanel and doorRecord.guidePanel:FindFirstChild("Accent")
	if accent and accent:IsA("Frame") then
		accent.BackgroundColor3 = palette.accent
	end
	if doorRecord.guideHighlight then
		doorRecord.guideHighlight.FillColor = palette.accent
		doorRecord.guideHighlight.OutlineColor = palette.outline
	end

	local subtitle = doorRecord.guidePanel and doorRecord.guidePanel:FindFirstChild("Subtitle")
	if subtitle and subtitle:IsA("TextLabel") then
		if isLocked then
			subtitle.Text = guideSubtitle .. " • Akses terkunci"
			subtitle.TextColor3 = Color3.fromRGB(228, 170, 170)
		elseif isOpen then
			subtitle.Text = guideSubtitle .. " • Terbuka"
			subtitle.TextColor3 = Color3.fromRGB(170, 218, 190)
		else
			subtitle.Text = guideSubtitle .. " • Tertutup"
			subtitle.TextColor3 = palette.subtitle
		end
	end
end

local function stampDoorRuntimeInstance(instance, channel, doorRecord, nearestDistance)
	if typeof(instance) ~= "Instance" or instance.Parent == nil or type(doorRecord) ~= "table" then
		return
	end

	local part = doorRecord.part
	local isOpen = part and part:GetAttribute("DoorIsOpen") == true or false
	local isLocked = part and part:GetAttribute("DoorLocked") == true or false
	local guideSubtitle = part and tostring(part:GetAttribute("DoorRouteSubtitle") or "") or ""
	local stateText = part and tostring(part:GetAttribute("DoorRouteStateText") or "") or ""

	instance:SetAttribute("PasrahDoorOwner", "DoorRuntime")
	instance:SetAttribute("PasrahDoorChannel", tostring(channel or instance.Name))
	instance:SetAttribute("PasrahDoorMatchId", type(doorRecord.matchId) == "string" and doorRecord.matchId or nil)
	instance:SetAttribute("PasrahDoorObjectId", type(doorRecord.objectId) == "string" and doorRecord.objectId or nil)
	instance:SetAttribute("PasrahDoorLabel", type(doorRecord.label) == "string" and doorRecord.label or nil)
	instance:SetAttribute("PasrahDoorRouteSubtitle", guideSubtitle ~= "" and guideSubtitle or nil)
	instance:SetAttribute("PasrahDoorPolicy", type(doorRecord.policy) == "string" and doorRecord.policy or nil)
	instance:SetAttribute("PasrahDoorStateText", stateText ~= "" and stateText or nil)
	instance:SetAttribute("PasrahDoorIsOpen", isOpen)
	instance:SetAttribute("PasrahDoorLocked", isLocked)
	instance:SetAttribute(
		"PasrahDoorNearestApproachDistance",
		type(nearestDistance) == "number" and nearestDistance < math.huge and math.floor(nearestDistance * 100 + 0.5) / 100 or nil
	)
	instance:SetAttribute(
		"PasrahDoorLastInteractionSource",
		type(doorRecord.lastInteractionSource) == "string" and doorRecord.lastInteractionSource or nil
	)
	if instance:IsA("ProximityPrompt") then
		instance:SetAttribute("PasrahDoorPromptActionText", tostring(instance.ActionText or ""))
		instance:SetAttribute("PasrahDoorPromptObjectText", tostring(instance.ObjectText or ""))
	end
end

local function stampDoorRuntime(doorRecord, nearestDistance)
	if type(doorRecord) ~= "table" then
		return
	end

	stampDoorRuntimeInstance(doorRecord.part, "DoorPart", doorRecord, nearestDistance)
	stampDoorRuntimeInstance(doorRecord.prompt, "DoorPrompt", doorRecord, nearestDistance)
	for _, prompt in ipairs(doorRecord.preparationBreachPrompts or {}) do
		stampDoorRuntimeInstance(prompt, "PreparationBreachPrompt", doorRecord, nearestDistance)
	end
	stampDoorRuntimeInstance(doorRecord.guideBillboard, "DoorGuideBillboard", doorRecord, nearestDistance)
	stampDoorRuntimeInstance(doorRecord.guidePanel, "DoorGuidePanel", doorRecord, nearestDistance)
	stampDoorRuntimeInstance(doorRecord.guideHighlight, "DoorGuideHighlight", doorRecord, nearestDistance)
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

local function ensurePathfindingModifier(part)
	local existing = part:FindFirstChild(PATH_MODIFIER_NAME)
	if existing and existing:IsA("PathfindingModifier") then
		existing.Label = "Doorway"
		existing.PassThrough = true
		return existing
	end

	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("PathfindingModifier") then
			child.Name = PATH_MODIFIER_NAME
			child.Label = "Doorway"
			child.PassThrough = true
			return child
		end
	end

	local ok, modifier = pcall(Instance.new, "PathfindingModifier")
	if not ok or not modifier then
		return nil
	end
	modifier.Name = PATH_MODIFIER_NAME
	modifier.Label = "Doorway"
	modifier.PassThrough = true
	modifier.Parent = part
	return modifier
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

local function getInstanceSize(instance)
	if typeof(instance) ~= "Instance" then
		return nil
	end
	if instance:IsA("Model") then
		local ok, size = pcall(function()
			return instance:GetExtentsSize()
		end)
		if ok then
			return size
		end
	elseif instance:IsA("BasePart") then
		return instance.Size
	end
	return nil
end

local function setInstanceCollision(instance, canCollide, canTouch)
	if typeof(instance) ~= "Instance" then
		return
	end
	if instance:IsA("BasePart") then
		instance.CanCollide = canCollide
		instance.CanTouch = canTouch
		instance.CanQuery = true
		return
	end
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = canCollide
			descendant.CanTouch = canTouch
			descendant.CanQuery = true
		end
	end
end

local function applyInstanceTransform(instance, targetCFrame)
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

local function getDoorPlaneFromSize(size)
	if typeof(size) ~= "Vector3" then
		return "thin_x"
	end
	if size.X <= size.Z then
		return "thin_x"
	end
	return "thin_z"
end

local function getDoorPlane(part)
	if not (part and part:IsA("BasePart")) then
		return "thin_x"
	end
	return getDoorPlaneFromSize(part.Size)
end

local function findNearestNamedInstance(root, targetName, expectedPosition, className)
	if typeof(root) ~= "Instance" or type(targetName) ~= "string" or targetName == "" then
		return nil
	end
	local best = nil
	local bestDistance = math.huge
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant.Name == targetName and (className == nil or descendant.ClassName == className) then
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

local function resolveDoorVisualTarget(mapClone, proxyPart)
	if typeof(proxyPart) ~= "Instance" or typeof(mapClone) ~= "Instance" then
		return proxyPart
	end
	local targetRootName = proxyPart:GetAttribute("PasrahTargetRootName")
	if type(targetRootName) ~= "string" or targetRootName == "" then
		return proxyPart
	end
	local expectedPosition = parseVector3String(proxyPart:GetAttribute("PasrahTargetPosition"))
	local targetPosition = expectedPosition
	if typeof(expectedPosition) == "Vector3" and (expectedPosition - proxyPart.Position).Magnitude > 80 then
		targetPosition = proxyPart.Position
	end
	local root = findNearestNamedInstance(mapClone, targetRootName, targetPosition)
	if not root then
		return proxyPart
	end
	local targetName = proxyPart:GetAttribute("PasrahTargetName")
	if type(targetName) ~= "string" or targetName == "" then
		return root
	end
	return findNearestNamedInstance(root, targetName, targetPosition) or root
end

local function buildOpenCFrame(instance, closedCFrame, mode)
	local size = getInstanceSize(instance)
	local plane = getDoorPlaneFromSize(size)
	if mode == "Slide" and typeof(size) == "Vector3" then
		local slideDistance = math.max(1.8, math.min(math.max(size.X, size.Z) * 0.45, 4.5))
		local axis = size.X >= size.Z and closedCFrame.RightVector or closedCFrame.LookVector
		return closedCFrame + (axis * slideDistance)
	end

	if instance and instance:IsA("Model") then
		local hinge = findNearestNamedInstance(instance, "PrimaryHinge", closedCFrame.Position, "Part")
			or findNearestNamedInstance(instance, "Hinge", closedCFrame.Position, "Part")
		if hinge then
			local hingeWorld = hinge.CFrame
			return hingeWorld * CFrame.Angles(0, OPEN_ANGLE, 0) * hingeWorld:Inverse() * closedCFrame
		end
	end

	if typeof(size) ~= "Vector3" then
		return closedCFrame
	end
	if plane == "thin_x" then
		local hingeLocal = Vector3.new(0, 0, -(size.Z * 0.5) + (size.X * 0.5))
		local hingeWorld = closedCFrame * CFrame.new(hingeLocal)
		return hingeWorld * CFrame.Angles(0, OPEN_ANGLE, 0) * CFrame.new(-hingeLocal)
	end

	local hingeLocal = Vector3.new(-(size.X * 0.5) + (size.Z * 0.5), 0, 0)
	local hingeWorld = closedCFrame * CFrame.new(hingeLocal)
	return hingeWorld * CFrame.Angles(0, -OPEN_ANGLE, 0) * CFrame.new(-hingeLocal)
end

local function setPromptState(prompt, isOpen, isLocked, doorLabel)
	if not prompt then
		return
	end
	prompt.ObjectText = doorLabel or "Pintu"
	if isLocked then
		prompt.ActionText = "Pintu Terkunci"
		prompt.Enabled = false
		return
	end
	prompt.Enabled = true
	prompt.ActionText = isOpen and "Tutup Pintu" or "Buka Pintu"
end

local function readInitialDoorState(part)
	return {
		isLocked = part:GetAttribute("DoorLocked") == true,
		isOpen = part:GetAttribute("DoorIsOpen") == true,
		policy = tostring(part:GetAttribute(POLICY_ATTR_NAME) or ""),
	}
end

local function normalizeSoundId(soundId)
	if type(soundId) ~= "string" or soundId == "" then
		return nil
	end
	if soundId:match("^rbxassetid://") then
		return soundId
	end
	local digits = soundId:match("(%d+)")
	if digits then
		return "rbxassetid://" .. digits
	end
	return soundId
end

local function ensureDoorSound(part, soundName, soundId)
	local normalizedSoundId = normalizeSoundId(soundId)
	if not normalizedSoundId then
		return nil
	end

	local sound = part:FindFirstChild(soundName)
	if sound and not sound:IsA("Sound") then
		sound:Destroy()
		sound = nil
	end
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = soundName
		sound.Parent = part
	end

	sound.SoundId = normalizedSoundId
	sound.RollOffMaxDistance = DEFAULT_SOUND_MAX_DISTANCE
	sound.RollOffMinDistance = 8
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.Volume = DEFAULT_SOUND_VOLUME
	sound.PlaybackSpeed = 1
	return sound
end

local function playDoorSound(sound, playbackSpeed)
	if not sound then
		return
	end
	sound.PlaybackSpeed = playbackSpeed or 1
	sound.TimePosition = 0
	sound:Play()
end

local function normalizePolicy(policy)
	if type(policy) ~= "string" then
		return POLICY_PROMPT_MANUAL
	end

	local normalized = policy:gsub("[%s_%-_%.]+", ""):lower()
	if normalized == "hybridradiusprompt" or normalized == "hybridassist" or normalized == "hybrid" then
		return POLICY_HYBRID_RADIUS_PROMPT
	end
	return POLICY_PROMPT_MANUAL
end

local function isLocalDoorSource(source)
	return source == LOCAL_PROMPT_SOURCE
		or source == LOCAL_AUTO_SOURCE
		or source == LOCAL_PREPARATION_PROXIMITY_SOURCE
end

local function applyDoorState(doorRecord, interactionType, suppressSound)
	local part = doorRecord.part
	if not part or part.Parent == nil then
		return
	end
	local targetInstance = doorRecord.targetInstance or part

	if interactionType == "Open" then
		applyInstanceTransform(targetInstance, doorRecord.openCFrame)
		part.CanCollide = false
		part.CanTouch = false
		setInstanceCollision(targetInstance, false, false)
		part:SetAttribute("DoorIsOpen", true)
		if suppressSound ~= true then
			playDoorSound(doorRecord.openSound, 1)
		end
	elseif interactionType == "Close" or interactionType == "Slam" then
		applyInstanceTransform(targetInstance, doorRecord.closedCFrame)
		part.CanCollide = true
		part.CanTouch = true
		setInstanceCollision(targetInstance, true, true)
		part:SetAttribute("DoorIsOpen", false)
		if suppressSound ~= true then
			playDoorSound(doorRecord.closeSound, interactionType == "Slam" and 0.9 or 1)
		end
	end

	setPromptState(
		doorRecord.prompt,
		part:GetAttribute("DoorIsOpen") == true,
		part:GetAttribute("DoorLocked") == true,
		doorRecord.label
	)
	updateDoorRouteGuide(
		doorRecord,
		part:GetAttribute("DoorIsOpen") == true,
		part:GetAttribute("DoorLocked") == true
	)
	stampDoorRuntime(doorRecord, doorRecord.lastNearestApproachDistance)
end

local function getPlayerDoorApproachDistance(doorRecord, player, depthThreshold, widthPadding)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return nil
	end

	if type(doorRecord) ~= "table" or typeof(doorRecord.part) ~= "Instance" then
		return nil
	end

	local part = doorRecord.part
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or (humanoid and humanoid.Health <= 0) then
		return nil
	end

	local referenceCFrame = doorRecord.closedCFrame or part.CFrame
	local localPosition = referenceCFrame:PointToObjectSpace(root.Position)
	local verticalTolerance = HYBRID_VERTICAL_TOLERANCE
	if typeof(part.Size) == "Vector3" then
		verticalTolerance = math.max(verticalTolerance, (part.Size.Y * 0.5) + 1.5)
	end
	if math.abs(localPosition.Y) > verticalTolerance then
		return nil
	end

	local plane = getDoorPlane(part)
	local threshold = depthThreshold or HYBRID_OPEN_APPROACH_DEPTH
	local lateralAllowance = widthPadding or HYBRID_LATERAL_PADDING

	if plane == "thin_x" then
		local normalDistance = math.max(0, math.abs(localPosition.X) - (part.Size.X * 0.5))
		local lateralDistance = math.abs(localPosition.Z)
		local lateralLimit = (part.Size.Z * 0.5) + lateralAllowance
		if lateralDistance > lateralLimit or normalDistance > threshold then
			return nil
		end
		return normalDistance
	end

	local normalDistance = math.max(0, math.abs(localPosition.Z) - (part.Size.Z * 0.5))
	local lateralDistance = math.abs(localPosition.X)
	local lateralLimit = (part.Size.X * 0.5) + lateralAllowance
	if lateralDistance > lateralLimit or normalDistance > threshold then
		return nil
	end
	return normalDistance
end

local ACTIVE_MATCH_PHASES = {
	PreparationPhase = true,
	InvestigationPhase = true,
	HuntPhase = true,
	EndgamePhase = true,
}

local function isRuntimeMatchParticipant(player, matchId)
	if not (typeof(player) == "Instance" and player:IsA("Player")) then
		return false
	end
	if matchId ~= nil and tostring(player:GetAttribute("MatchId") or "") ~= tostring(matchId) then
		return false
	end
	if player:GetAttribute("InMatch") == true then
		return true
	end
	local lifecyclePhase = tostring(player:GetAttribute("MatchLifecyclePhase") or "")
	return ACTIVE_MATCH_PHASES[lifecyclePhase] == true
end

local function getNearestPlayerApproachDistance(doorRecord, players, matchId, depthThreshold, widthPadding)
	local nearest = nil

	for _, player in ipairs(players or {}) do
		if isRuntimeMatchParticipant(player, matchId) then
			local distance = getPlayerDoorApproachDistance(doorRecord, player, depthThreshold, widthPadding)
			if distance and (nearest == nil or distance < nearest) then
				nearest = distance
			end
		end
	end

	return nearest
end

local function getNearestPlayerCenterDistance(doorRecord, players, matchId)
	if type(doorRecord) ~= "table" or typeof(doorRecord.part) ~= "Instance" then
		return nil
	end
	local part = doorRecord.part
	local nearest = nil
	for _, player in ipairs(players or {}) do
		if not isRuntimeMatchParticipant(player, matchId) then
			continue
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and not (humanoid and humanoid.Health <= 0) then
			local distance = (root.Position - part.Position).Magnitude
			if nearest == nil or distance < nearest then
				nearest = distance
			end
		end
	end
	return nearest
end

local function collectPreparationBreachTargets(doorRecord)
	if type(doorRecord) ~= "table" or typeof(doorRecord.mapClone) ~= "Instance" then
		return {}
	end

	local stagingFolder = doorRecord.mapClone:FindFirstChild("PreparationStagingRuntime", true)
	if not stagingFolder then
		return {}
	end

	local targets = {}
	for _, descendant in ipairs(stagingFolder:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name:match("^PreparationBreachTarget_") then
			table.insert(targets, descendant)
		end
	end
	return targets
end

local function resolvePreparationStagingFolder(doorRecord)
	if type(doorRecord) ~= "table" or typeof(doorRecord.mapClone) ~= "Instance" then
		return nil
	end
	return doorRecord.mapClone:FindFirstChild("PreparationStagingRuntime", true)
end

local function resolvePreparationSpawnCFrame(doorRecord)
	local stagingFolder = resolvePreparationStagingFolder(doorRecord)
	if not stagingFolder then
		return nil, nil
	end

	local spawnArea = stagingFolder:FindFirstChild("PreparationSpawnArea", true)
	if not spawnArea then
		return nil, nil
	end
	if spawnArea:IsA("BasePart") then
		return spawnArea.CFrame, spawnArea
	end

	local candidates = {}
	for _, descendant in ipairs(spawnArea:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(candidates, descendant)
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

	local spawnPart = candidates[1]
	return spawnPart and spawnPart.CFrame or nil, spawnPart
end

local function resolveCharacterRoot(character)
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return character:FindFirstChild("HumanoidRootPart")
		or (humanoid and humanoid.RootPart)
		or character.PrimaryPart
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("LowerTorso")
		or character:FindFirstChild("Torso")
end

local function teleportPlayerToPreparationStaging(doorRecord, player)
	if type(doorRecord) ~= "table" or not (doorRecord.part and doorRecord.part:IsA("BasePart")) then
		return false, "invalid_door"
	end
	if not (typeof(player) == "Instance" and player:IsA("Player")) then
		return false, "invalid_player"
	end
	if type(doorRecord.match) ~= "table" or tostring(doorRecord.match.phase or "") ~= "InvestigationPhase" then
		return false, "not_investigation"
	end
	if not isRuntimeMatchParticipant(player, doorRecord.matchId) then
		return false, "not_participant"
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = resolveCharacterRoot(character)
	if not character or not root or (humanoid and humanoid.Health <= 0) then
		return false, "missing_character"
	end

	local spawnCFrame, spawnPart = resolvePreparationSpawnCFrame(doorRecord)
	if not spawnCFrame then
		return false, "missing_preparation_spawn"
	end

	local targetCFrame = spawnCFrame + Vector3.new(0, INVESTIGATION_EXIT_TELEPORT_LIFT, 0)
	character:PivotTo(targetCFrame)
	doorRecord.lastInteractionAt = os.clock()
	doorRecord.lastInteractionSource = "DoorRuntimeInvestigationExit"
	doorRecord.part:SetAttribute("PasrahDoorLastInteractionSource", doorRecord.lastInteractionSource)
	doorRecord.part:SetAttribute("PasrahDoorLastExitToStagingAt", doorRecord.lastInteractionAt)
	doorRecord.part:SetAttribute("PasrahDoorLastExitPlayer", player.Name)
	doorRecord.part:SetAttribute("PasrahDoorLastExitSpawn", spawnPart and spawnPart:GetFullName() or "")
	player:SetAttribute("PasrahLastDoorExitResult", "ok:" .. tostring(doorRecord.objectId or doorRecord.part.Name))
	return true, "ok"
end

local function getNearestPreparationBreachTargetDistance(doorRecord, players, matchId)
	local targets = collectPreparationBreachTargets(doorRecord)
	if #targets == 0 then
		return nil
	end

	local nearest = nil
	for _, player in ipairs(players or {}) do
		if not isRuntimeMatchParticipant(player, matchId) then
			continue
		end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and not (humanoid and humanoid.Health <= 0) then
			for _, target in ipairs(targets) do
				local distance = (root.Position - target.Position).Magnitude
				if nearest == nil or distance < nearest then
					nearest = distance
				end
			end
		end
	end
	return nearest
end

local function hasPreparationFocusTool(players, matchId)
	for _, player in ipairs(players or {}) do
		local lifecyclePhase = tostring(player and player:GetAttribute("MatchLifecyclePhase") or "")
		if isRuntimeMatchParticipant(player, matchId) or lifecyclePhase == "PreparationPhase" then
			local focusTool = player:GetAttribute("PasrahPreparationFocusTool")
			local focusSource = tostring(player:GetAttribute("PasrahPreparationFocusToolSource") or "")
			local stationSelected = player:GetAttribute("PasrahPreparationToolSelected") == true
			if type(focusTool) == "string"
				and focusTool ~= ""
				and (focusSource == "WorldToolStation" or stationSelected) then
				return true
			end
		end
	end
	return false
end

local function resolvePreparationAdvancePlayers(players, matchId)
	local resolved = {}
	local seen = {}
	local expectedMatchId = matchId ~= nil and tostring(matchId) or nil

	local function includePlayer(player)
		if not (typeof(player) == "Instance" and player:IsA("Player")) then
			return
		end
		if seen[player] == true then
			return
		end

		local playerLifecycle = tostring(player:GetAttribute("MatchLifecyclePhase") or "")
		local playerMatchId = tostring(player:GetAttribute("MatchId") or "")
		local eligible = isRuntimeMatchParticipant(player, matchId)
			or playerLifecycle == "PreparationPhase"
			or (expectedMatchId ~= nil and expectedMatchId ~= "" and playerMatchId == expectedMatchId)
		if not eligible then
			return
		end

		seen[player] = true
		table.insert(resolved, player)
	end

	for _, player in ipairs(players or {}) do
		includePlayer(player)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		includePlayer(player)
	end
	return resolved
end

local function executeDoorInteraction(doorRecord, interactionType, interactionSource)
	if not doorRecord or not interactionType then
		return false
	end

	local now = os.clock()
	doorRecord.lastInteractionAt = now
	doorRecord.lastInteractionSource = interactionSource
	local isPreparationAdvanceDoor = doorRecord.part:GetAttribute("PasrahPreparationAdvanceDoor") == true
	if interactionType == "Close"
		and isPreparationAdvanceDoor
		and type(doorRecord.preparationAdvanceCommittedAt) == "number"
		and (now - doorRecord.preparationAdvanceCommittedAt) < 4 then
		return false
	end
	local isPreparationAdvanceOpen = interactionType == "Open"
		and isPreparationAdvanceDoor
		and type(doorRecord.match) == "table"
		and tostring(doorRecord.match.phase or "") == "PreparationPhase"
	if isPreparationAdvanceOpen then
		local preparationPlayers = resolvePreparationAdvancePlayers(doorRecord.match.players, doorRecord.matchId)
		if not hasPreparationFocusTool(preparationPlayers, doorRecord.matchId) then
			doorRecord.part:SetAttribute("PasrahPrepAdvanceBlockedReason", "missing_world_tool")
			doorRecord.part:SetAttribute("PasrahPrepAdvanceHasFocus", false)
			return false
		end
		doorRecord.part:SetAttribute("PasrahPrepAdvanceBlockedReason", nil)
	end
	if interactionSource == LOCAL_PROMPT_SOURCE then
		doorRecord.manualOverrideUntil = now + MANUAL_OVERRIDE_SECONDS
		doorRecord.manualOverrideState = interactionType == "Open" and "Open" or "Closed"
	elseif interactionSource == LOCAL_AUTO_SOURCE then
		doorRecord.manualOverrideState = nil
	else
		doorRecord.manualOverrideUntil = 0
		doorRecord.manualOverrideState = nil
	end

	applyDoorState(doorRecord, interactionType)
	if isPreparationAdvanceOpen then
		doorRecord.preparationAdvanceCommittedAt = now
	end
	if interactionType == "Open"
		and interactionSource ~= LOCAL_AUTO_SOURCE
		and isPreparationAdvanceDoor
		and type(doorRecord.match) == "table"
		and tostring(doorRecord.match.phase or "") == "PreparationPhase"
		and type(doorRecord.match.requestAdvancePhase) == "function" then
		doorRecord.match.requestAdvancePhase(nil, "InvestigationPhase")
	end
	local interactionSystem = doorRecord.mapInteractionSystem
	if interactionSystem then
		if type(interactionSystem.Service) == "table"
			and type(interactionSystem.Service.ExecuteInteraction) == "function" then
			interactionSystem.Service:ExecuteInteraction(doorRecord.objectId, interactionType, {
				now = now,
				source = interactionSource,
			})
	elseif type(interactionSystem.ExecuteInteraction) == "function" then
			interactionSystem:ExecuteInteraction(doorRecord.objectId, interactionType)
		end
	end
	if isPreparationAdvanceOpen then
		task.defer(function()
			if type(doorRecord) == "table"
				and doorRecord.part
				and doorRecord.part.Parent ~= nil
				and doorRecord.part:GetAttribute("DoorIsOpen") ~= true then
				applyDoorState(doorRecord, "Open", true)
			end
		end)
	end
	return true
end

local function ensurePrompt(part, doorLabel)
	local prompt = part:FindFirstChild(PROMPT_NAME)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.ObjectText = doorLabel or "Pintu"
		prompt.MaxActivationDistance = INTERACTION_DISTANCE
		prompt.RequiresLineOfSight = false
		prompt.HoldDuration = PROMPT_HOLD_DURATION
		prompt.Style = Enum.ProximityPromptStyle.Default
		return prompt
	else
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = PROMPT_NAME
	end

	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.ObjectText = doorLabel or "Pintu"
	prompt.ActionText = "Buka Pintu"
	prompt.MaxActivationDistance = INTERACTION_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = PROMPT_HOLD_DURATION
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Parent = part
	return prompt
end

local function setPreparationBreachPromptState(prompt, hasFocusTool, currentOpen, doorLabel)
	if not (prompt and prompt:IsA("ProximityPrompt")) then
		return
	end
	prompt.Enabled = true
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.MaxActivationDistance = PREPARATION_BREACH_PROMPT_DISTANCE
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = PROMPT_HOLD_DURATION
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.ActionText = hasFocusTool and (currentOpen and "Masuk Rumah" or "Buka Pintu") or "Pilih Tools Dulu"
	prompt.ObjectText = hasFocusTool and (doorLabel or "Pintu") or "Pintu Terkunci"
	prompt:SetAttribute("PasrahPreparationBreachPrompt", true)
end

local function ensurePreparationBreachPrompt(target, doorRecord)
	if not (target and target:IsA("BasePart")) then
		return nil
	end

	local prompt = target:FindFirstChild(PREPARATION_BREACH_PROMPT_NAME)
	if not (prompt and prompt:IsA("ProximityPrompt")) then
		if prompt then
			prompt:Destroy()
		end
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = PREPARATION_BREACH_PROMPT_NAME
		prompt.Parent = target
	end
	prompt.Enabled = true
	pcall(function()
		prompt.ClickablePrompt = true
	end)
	setPreparationBreachPromptState(prompt, false, false, doorRecord and doorRecord.label or "Pintu")

	if prompt:GetAttribute("PasrahPreparationBreachConnected") ~= true then
		prompt:SetAttribute("PasrahPreparationBreachConnected", true)
		prompt.Triggered:Connect(function(player)
			if type(doorRecord) ~= "table" then
				return
			end
			local part = doorRecord.part
			if not (part and part.Parent ~= nil) or part:GetAttribute("DoorLocked") == true then
				return
			end
			if type(doorRecord.match) ~= "table" or tostring(doorRecord.match.phase or "") ~= "PreparationPhase" then
				return
			end

			local preparationPlayers = resolvePreparationAdvancePlayers({ player }, doorRecord.matchId)
			if not hasPreparationFocusTool(preparationPlayers, doorRecord.matchId) then
				part:SetAttribute("PasrahPrepAdvanceBlockedReason", "missing_world_tool")
				part:SetAttribute("PasrahPrepAdvanceHasFocus", false)
				setPreparationBreachPromptState(prompt, false, part:GetAttribute("DoorIsOpen") == true, doorRecord.label)
				return
			end

			part:SetAttribute("PasrahPrepAdvanceBlockedReason", nil)
			local currentOpen = part:GetAttribute("DoorIsOpen") == true
			if currentOpen then
				if type(doorRecord.match.requestAdvancePhase) == "function" then
					doorRecord.preparationAdvanceCommittedAt = os.clock()
					doorRecord.match.requestAdvancePhase(nil, "InvestigationPhase")
				end
			else
				executeDoorInteraction(doorRecord, "Open", LOCAL_PROMPT_SOURCE)
			end
		end)
	end
	return prompt
end

local function ensurePreparationDoorPromptProxy(doorRecord, breachTargets)
	local part = type(doorRecord) == "table" and doorRecord.part or nil
	if not (part and part:IsA("BasePart")) then
		return nil
	end

	local stagingFolder = resolvePreparationStagingFolder(doorRecord)
	if not stagingFolder then
		return nil
	end

	local proxyName = PREPARATION_BREACH_PROXY_NAME .. "_" .. tostring(doorRecord.objectId or part.Name)
	local proxy = stagingFolder:FindFirstChild(proxyName)
	if not (proxy and proxy:IsA("BasePart")) then
		if proxy then
			proxy:Destroy()
		end
		proxy = Instance.new("Part")
		proxy.Name = proxyName
		proxy.Size = Vector3.new(1.5, 1.5, 1.5)
		proxy.Transparency = 0.9
		proxy.Anchored = true
		proxy.CanCollide = false
		proxy.CanTouch = false
		proxy.CanQuery = true
		proxy.Parent = stagingFolder
	end

	local centroid = Vector3.zero
	local counted = 0
	for _, target in ipairs(breachTargets or {}) do
		if target and target:IsA("BasePart") then
			centroid += target.Position
			counted += 1
		end
	end
	local stagingDirection = counted > 0 and ((centroid / counted) - part.Position) or nil
	if not stagingDirection or stagingDirection.Magnitude < 0.1 then
		stagingDirection = -part.CFrame.LookVector
	end
	local offset = math.min(math.max(stagingDirection.Magnitude * 0.22, 7), 10)
	local proxyPosition = part.Position + stagingDirection.Unit * offset
	if counted > 0 then
		proxyPosition = Vector3.new(proxyPosition.X, (centroid / counted).Y + 2.95, proxyPosition.Z)
	end
	proxy.CFrame = CFrame.new(proxyPosition)
	proxy:SetAttribute("PasrahPreparationDoorProxy", true)
	proxy:SetAttribute("PasrahDoorObjectId", tostring(doorRecord.objectId or part.Name))
	return proxy
end

local function ensurePreparationBreachPrompts(doorRecord)
	if type(doorRecord) ~= "table"
		or not (doorRecord.part and doorRecord.part:GetAttribute("PasrahPreparationAdvanceDoor") == true) then
		return {}
	end

	local prompts = {}
	local breachTargets = collectPreparationBreachTargets(doorRecord)
	local proxyTarget = ensurePreparationDoorPromptProxy(doorRecord, breachTargets)
	for _, target in ipairs(proxyTarget and { proxyTarget } or {}) do
		local prompt = ensurePreparationBreachPrompt(target, doorRecord)
		if prompt then
			table.insert(prompts, prompt)
		end
	end
	doorRecord.preparationBreachPrompts = prompts
	return prompts
end

local function isDoorPart(part)
	if not part:IsA("BasePart") then
		return false
	end
	if not part.Name:match("^Door_") then
		return false
	end
	if part.Name:match("_Frame") then
		return false
	end
	return true
end

local function registerDoorInteraction(mapInteractionSystem, doorId, position)
	if not mapInteractionSystem or type(mapInteractionSystem.RegisterObject) ~= "function" then
		return
	end
	mapInteractionSystem:RegisterObject({
		id = doorId,
		type = "Door",
		position = position,
		interactions = { "Open", "Close", "Slam" },
	})
end

function DoorRuntime.Attach(match, mapClone, deps)
	if typeof(mapClone) ~= "Instance" then
		return false
	end

	local doorsFolder = mapClone:FindFirstChild("Doors", true)
	local scanRoot = doorsFolder or mapClone

	local eventBus = resolveEventBus(deps)
	local mapInteractionSystem = resolveMapInteractionSystem(deps)
	local matchId = match and tostring(match.matchId or match.id or "") or ""
	local doorLookup = {}

	if match and match._doorRuntimeSubscription and eventBus then
		eventBus:Unsubscribe("MapObjectInteracted", match._doorRuntimeSubscription)
		match._doorRuntimeSubscription = nil
	end
	if match and match._doorRuntimeLockSubscriptions and eventBus then
		for _, subscription in ipairs(match._doorRuntimeLockSubscriptions) do
			eventBus:Unsubscribe(subscription.eventName, subscription.callback)
		end
		match._doorRuntimeLockSubscriptions = nil
	end

	local function isExitDoorRecord(doorRecord)
		local part = doorRecord and doorRecord.part
		if not part then
			return false
		end
		if part:GetAttribute("PasrahPreparationAdvanceDoor") == true then
			return true
		end
		local token = string.lower(tostring(doorRecord.objectId or part.Name or ""))
		return token:find("front", 1, true) ~= nil
			or token:find("entry", 1, true) ~= nil
			or token:find("lobby", 1, true) ~= nil
			or token:find("grandhall", 1, true) ~= nil
	end

	local function applyExitDoorLock(locked, source)
		for _, doorRecord in pairs(doorLookup) do
			if isExitDoorRecord(doorRecord) then
				local part = doorRecord.part
				part:SetAttribute("DoorLocked", locked == true)
				part:SetAttribute("DoorLockSource", locked and tostring(source or "HuntSystem") or nil)
				if locked and part:GetAttribute("DoorIsOpen") == true then
					applyDoorState(doorRecord, "Close", false)
				end
				setPromptState(
					doorRecord.prompt,
					part:GetAttribute("DoorIsOpen") == true,
					part:GetAttribute("DoorLocked") == true,
					doorRecord.label
				)
				stampDoorRuntime(doorRecord, doorRecord.lastNearestApproachDistance)
			end
		end
	end

	for _, descendant in ipairs(scanRoot:GetDescendants()) do
		if isDoorPart(descendant) then
			local doorLabel = resolveDoorLabel(descendant)
			local prompt = ensurePrompt(descendant, doorLabel)
			local targetInstance = resolveDoorVisualTarget(mapClone, descendant)
			local closedCFrame = getInstanceCFrame(targetInstance) or descendant.CFrame
			local initialState = readInitialDoorState(descendant)
			local record = {
				part = descendant,
				targetInstance = targetInstance,
				prompt = prompt,
				label = doorLabel,
				match = match,
				matchId = matchId ~= "" and matchId or nil,
				mapClone = mapClone,
				closedCFrame = closedCFrame,
				openCFrame = buildOpenCFrame(targetInstance, closedCFrame, descendant:GetAttribute("PasrahTargetMode")),
				policy = normalizePolicy(initialState.policy),
				openSound = ensureDoorSound(descendant, OPEN_SOUND_NAME, descendant:GetAttribute(OPEN_SOUND_ATTR_NAME) or DEFAULT_OPEN_SOUND_ID),
				closeSound = ensureDoorSound(descendant, CLOSE_SOUND_NAME, descendant:GetAttribute(CLOSE_SOUND_ATTR_NAME) or DEFAULT_CLOSE_SOUND_ID),
				objectId = descendant.Name,
				mapInteractionSystem = mapInteractionSystem,
				lastNearbyAt = 0,
				lastInteractionAt = 0,
				lastInteractionSource = "Attach",
				lastNearestApproachDistance = nil,
				manualOverrideUntil = 0,
				manualOverrideState = nil,
				preparationAdvanceArmedAt = nil,
				lastPreparationNearbyAt = 0,
			}
			doorLookup[descendant.Name] = record
			descendant.Anchored = true
			descendant.CanQuery = true
			descendant:SetAttribute("DoorObjectId", descendant.Name)
			descendant:SetAttribute("DoorRouteLabel", doorLabel)
			descendant:SetAttribute("DoorRouteSubtitle", resolveDoorGuideSubtitle(doorLabel))
			descendant:SetAttribute(POLICY_ATTR_NAME, record.policy)
			descendant:SetAttribute("DoorLocked", initialState.isLocked)
			descendant:SetAttribute("DoorIsOpen", initialState.isOpen)
			registerDoorInteraction(mapInteractionSystem, descendant.Name, descendant.Position)
			ensurePathfindingModifier(descendant)
			ensureDoorRouteGuide(record)
			ensurePreparationBreachPrompts(record)
			applyDoorState(record, initialState.isOpen and "Open" or "Close", true)
			setPromptState(prompt, initialState.isOpen, initialState.isLocked, doorLabel)

			prompt.Triggered:Connect(function(player)
				if descendant:GetAttribute("DoorLocked") == true then
					return
				end

				if descendant:GetAttribute("PasrahPreparationAdvanceDoor") == true
					and tostring(record.match and record.match.phase or "") == "InvestigationPhase" then
					local exited, exitReason = teleportPlayerToPreparationStaging(record, player)
					if exited then
						return
					end
					if typeof(player) == "Instance" and player:IsA("Player") then
						player:SetAttribute("PasrahLastDoorExitResult", "failed:" .. tostring(exitReason))
					end
				end

				local nextInteraction = descendant:GetAttribute("DoorIsOpen") == true and "Close" or "Open"
				executeDoorInteraction(record, nextInteraction, LOCAL_PROMPT_SOURCE)
			end)
		end
	end

	if match and match._doorRuntimeHeartbeat then
		match._doorRuntimeHeartbeat:Disconnect()
		match._doorRuntimeHeartbeat = nil
	end

if next(doorLookup) ~= nil and match then
		match._doorRuntimeHeartbeat = RunService.Heartbeat:Connect(function()
			if typeof(mapClone) ~= "Instance" or mapClone.Parent == nil then
				if match._doorRuntimeHeartbeat then
					match._doorRuntimeHeartbeat:Disconnect()
					match._doorRuntimeHeartbeat = nil
				end
				return
			end

			local now = os.clock()
			for _, doorRecord in pairs(doorLookup) do
				local part = doorRecord.part
				if not part or part.Parent == nil or part:GetAttribute("DoorLocked") == true then
					continue
				end

				local currentOpen = part:GetAttribute("DoorIsOpen") == true
				if part:GetAttribute("PasrahPreparationAdvanceDoor") == true
					and tostring(match.phase or "") == "PreparationPhase" then
					local preparationPlayers = resolvePreparationAdvancePlayers(
						match.players,
						matchId ~= "" and matchId or nil
					)
					-- Keep door as the phase trigger, but add a server-side proximity fallback.
					-- Use center distance as the primary metric so door orientation/mesh variance
					-- across maps does not block the preparation gate.
					local nearestPreparationDistance = getNearestPlayerCenterDistance(
						doorRecord,
						preparationPlayers,
						nil
					)
					local nearestApproachDistance = getNearestPlayerApproachDistance(
						doorRecord,
						preparationPlayers,
						nil,
						PREPARATION_ADVANCE_APPROACH_DEPTH,
						PREPARATION_ADVANCE_LATERAL_PADDING
					)
					local nearestBreachTargetDistance = getNearestPreparationBreachTargetDistance(
						doorRecord,
						preparationPlayers,
						nil
					)
					if type(nearestApproachDistance) == "number" then
						if type(nearestPreparationDistance) == "number" then
							nearestPreparationDistance = math.min(nearestPreparationDistance, nearestApproachDistance)
						else
							nearestPreparationDistance = nearestApproachDistance
						end
					end
					if type(nearestBreachTargetDistance) == "number"
						and nearestBreachTargetDistance <= PREPARATION_BREACH_TARGET_RADIUS then
						if type(nearestPreparationDistance) == "number" then
							nearestPreparationDistance = math.min(nearestPreparationDistance, nearestBreachTargetDistance)
						else
							nearestPreparationDistance = nearestBreachTargetDistance
						end
					end
					if type(nearestPreparationDistance) == "number"
						and nearestPreparationDistance > PREPARATION_ADVANCE_RADIUS_FALLBACK then
						nearestPreparationDistance = nil
					end
					doorRecord.lastNearestApproachDistance = nearestPreparationDistance
					local nearbyNow = type(nearestPreparationDistance) == "number"
					if nearbyNow then
						doorRecord.lastPreparationNearbyAt = now
					end
					local proximityActive = nearbyNow
						or ((now - (doorRecord.lastPreparationNearbyAt or 0)) <= PREPARATION_ADVANCE_PROXIMITY_GRACE_SECONDS)
					local hasFocusTool = hasPreparationFocusTool(preparationPlayers, nil)
					part:SetAttribute("PasrahPrepAdvanceNearest", type(nearestPreparationDistance) == "number" and nearestPreparationDistance or nil)
					part:SetAttribute("PasrahPrepAdvanceBreachTargetNearest", type(nearestBreachTargetDistance) == "number" and nearestBreachTargetDistance or nil)
					part:SetAttribute("PasrahPrepAdvanceHasFocus", hasFocusTool == true)
					part:SetAttribute("PasrahPrepAdvanceNearby", proximityActive == true)

					if doorRecord.prompt then
						doorRecord.prompt.ActionText = hasFocusTool and (currentOpen and "Tutup Pintu" or "Buka Pintu") or "Pilih Tools Dulu"
						doorRecord.prompt.ObjectText = hasFocusTool and doorRecord.label or "Pintu Terkunci"
					end
					for _, breachPrompt in ipairs(ensurePreparationBreachPrompts(doorRecord)) do
						setPreparationBreachPromptState(breachPrompt, hasFocusTool, currentOpen, doorRecord.label)
					end

					if currentOpen then
						if hasFocusTool and proximityActive
							and type(doorRecord.match) == "table"
							and tostring(doorRecord.match.phase or "") == "PreparationPhase"
							and type(doorRecord.match.requestAdvancePhase) == "function"
							and (type(doorRecord.preparationAdvanceCommittedAt) ~= "number"
								or (now - doorRecord.preparationAdvanceCommittedAt) > 2) then
							doorRecord.preparationAdvanceCommittedAt = now
							doorRecord.match.requestAdvancePhase(nil, "InvestigationPhase")
						end
						doorRecord.preparationAdvanceArmedAt = nil
					elseif hasFocusTool and proximityActive then
						local requiredHoldSeconds = nearbyNow
							and PREPARATION_ADVANCE_HOLD_SECONDS
							or PREPARATION_ADVANCE_FAILSAFE_SECONDS
						if type(doorRecord.preparationAdvanceArmedAt) ~= "number" then
							doorRecord.preparationAdvanceArmedAt = now
						elseif (now - doorRecord.preparationAdvanceArmedAt) >= requiredHoldSeconds then
							executeDoorInteraction(doorRecord, "Open", LOCAL_PREPARATION_PROXIMITY_SOURCE)
							doorRecord.preparationAdvanceArmedAt = nil
						end
					else
						doorRecord.preparationAdvanceArmedAt = nil
					end
					part:SetAttribute("PasrahPrepAdvanceArmed", type(doorRecord.preparationAdvanceArmedAt) == "number")
					stampDoorRuntime(doorRecord, doorRecord.lastNearestApproachDistance)
					continue
				elseif part:GetAttribute("PasrahPreparationAdvanceDoor") == true then
					for _, breachPrompt in ipairs(doorRecord.preparationBreachPrompts or {}) do
						if breachPrompt and breachPrompt:IsA("ProximityPrompt") then
							breachPrompt.Enabled = false
						end
					end
					if tostring(match.phase or "") == "InvestigationPhase" then
						if doorRecord.prompt then
							doorRecord.prompt.Enabled = true
							doorRecord.prompt.ObjectText = doorRecord.label or "Pintu"
							doorRecord.prompt.ActionText = INVESTIGATION_EXIT_ACTION_TEXT
						end
						local nearestOpenDistance = getNearestPlayerApproachDistance(
							doorRecord,
							match.players,
							matchId ~= "" and matchId or nil,
							HYBRID_OPEN_APPROACH_DEPTH,
							HYBRID_LATERAL_PADDING + 1
						)
						local nearestKeepOpenDistance = getNearestPlayerApproachDistance(
							doorRecord,
							match.players,
							matchId ~= "" and matchId or nil,
							HYBRID_CLOSE_APPROACH_DEPTH,
							HYBRID_LATERAL_PADDING + 1
						)
						doorRecord.lastNearestApproachDistance = nearestOpenDistance or nearestKeepOpenDistance
						local playerNearby = type(nearestOpenDistance) == "number"
						local playerWithinKeepOpen = type(nearestKeepOpenDistance) == "number"
						if playerNearby then
							doorRecord.lastNearbyAt = now
						end

						local overrideActive = now < (doorRecord.manualOverrideUntil or 0)
						local overrideState = doorRecord.manualOverrideState
						if playerNearby and not currentOpen and not (overrideActive and overrideState == "Closed") then
							executeDoorInteraction(doorRecord, "Open", LOCAL_AUTO_SOURCE)
						elseif currentOpen and not playerWithinKeepOpen and not overrideActive then
							local idleTime = now - (doorRecord.lastNearbyAt or 0)
							if idleTime >= HYBRID_CLOSE_DELAY then
								executeDoorInteraction(doorRecord, "Close", LOCAL_AUTO_SOURCE)
							end
						end
						stampDoorRuntime(doorRecord, doorRecord.lastNearestApproachDistance)
						continue
					end
				end

				if doorRecord.policy ~= POLICY_HYBRID_RADIUS_PROMPT then
					stampDoorRuntime(doorRecord, doorRecord.lastNearestApproachDistance)
					continue
				end

				local nearestOpenDistance = getNearestPlayerApproachDistance(
					doorRecord,
					match.players,
					matchId ~= "" and matchId or nil,
					HYBRID_OPEN_APPROACH_DEPTH,
					HYBRID_LATERAL_PADDING
				)
				local nearestKeepOpenDistance = getNearestPlayerApproachDistance(
					doorRecord,
					match.players,
					matchId ~= "" and matchId or nil,
					HYBRID_CLOSE_APPROACH_DEPTH,
					HYBRID_LATERAL_PADDING + 1
				)
				doorRecord.lastNearestApproachDistance = nearestOpenDistance or nearestKeepOpenDistance
				local playerNearby = type(nearestOpenDistance) == "number"
				local playerWithinKeepOpen = type(nearestKeepOpenDistance) == "number"
				if playerNearby then
					doorRecord.lastNearbyAt = now
				end

				local overrideActive = now < (doorRecord.manualOverrideUntil or 0)
				local overrideState = doorRecord.manualOverrideState

				if playerNearby and not currentOpen and not (overrideActive and overrideState == "Closed") then
					executeDoorInteraction(doorRecord, "Open", LOCAL_AUTO_SOURCE)
				elseif currentOpen and not playerWithinKeepOpen and not overrideActive then
					local idleTime = now - (doorRecord.lastNearbyAt or 0)
					if idleTime >= HYBRID_CLOSE_DELAY then
						executeDoorInteraction(doorRecord, "Close", LOCAL_AUTO_SOURCE)
					end
				end
				stampDoorRuntime(doorRecord, doorRecord.lastNearestApproachDistance)
			end
		end)
	end

	if eventBus then
		local callback = function(payload)
			if type(payload) ~= "table" then
				return
			end
			local matchId = match and tostring(match.matchId or match.id or "")
			local payloadMatchId = tostring(payload.matchId or "")
			if matchId ~= "" and payloadMatchId ~= "" and payloadMatchId ~= matchId then
				return
			end

			local doorRecord = doorLookup[payload.objectId]
			if not doorRecord then
				return
			end
			if isLocalDoorSource(payload.source) then
				return
			end

			local interactionType = payload.interactionType
			if interactionType == "Open" or interactionType == "Close" or interactionType == "Slam" then
				applyDoorState(doorRecord, interactionType, false)
			end
		end
		eventBus:Subscribe("MapObjectInteracted", callback)
		if match then
			match._doorRuntimeSubscription = callback
		end

		local lockCallback = function(payload)
			if type(payload) ~= "table" then
				return
			end
			local expectedMatchId = match and tostring(match.matchId or match.id or "")
			local payloadMatchId = tostring(payload.matchId or "")
			if expectedMatchId ~= "" and payloadMatchId ~= "" and payloadMatchId ~= expectedMatchId then
				return
			end
			applyExitDoorLock(payload.locked == true, payload.source)
		end
		eventBus:Subscribe("ExitDoorsLocked", lockCallback)
		eventBus:Subscribe("HuntDoorLockChanged", lockCallback)
		if match then
			match._doorRuntimeLockSubscriptions = {
				{ eventName = "ExitDoorsLocked", callback = lockCallback },
				{ eventName = "HuntDoorLockChanged", callback = lockCallback },
			}
		end
	end

	return next(doorLookup) ~= nil
end

return DoorRuntime

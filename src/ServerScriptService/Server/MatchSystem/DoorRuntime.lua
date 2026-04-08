local Services = require(script.Parent.Parent.Core.Services)
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
local DEFAULT_OPEN_SOUND_ID = "rbxassetid://83005562781593"
local DEFAULT_CLOSE_SOUND_ID = "rbxassetid://78764817933410"
local DEFAULT_SOUND_VOLUME = 0.45
local DEFAULT_SOUND_MAX_DISTANCE = 42

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
	label.TextStrokeTransparency = 0.82
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	return label
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
		highlight = Instance.new("Highlight")
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
		billboard = Instance.new("BillboardGui")
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
		panel = Instance.new("Frame")
		panel.Name = "Panel"
		panel.Parent = billboard

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = panel

		local stroke = Instance.new("UIStroke")
		stroke.Name = "Stroke"
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.Color = palette.accent
		stroke.Transparency = 0.18
		stroke.Thickness = 1.2
		stroke.Parent = panel

		local accent = Instance.new("Frame")
		accent.Name = "Accent"
		accent.AnchorPoint = Vector2.new(0, 0.5)
		accent.BackgroundColor3 = palette.accent
		accent.BorderSizePixel = 0
		accent.Position = UDim2.new(0, 10, 0.5, 0)
		accent.Size = UDim2.fromOffset(3, 22)
		accent.Parent = panel

		local accentCorner = Instance.new("UICorner")
		accentCorner.CornerRadius = UDim.new(1, 0)
		accentCorner.Parent = accent

		createGuideTextLabel(
			"Title",
			Enum.Font.GothamBold,
			12,
			palette.title,
			doorRecord.label or "Pintu",
			16,
			UDim2.new(0, 20, 0, 5)
		).Parent = panel

		createGuideTextLabel(
			"Subtitle",
			Enum.Font.GothamMedium,
			10,
			palette.subtitle,
			guideSubtitle,
			14,
			UDim2.new(0, 20, 0, 20)
		).Parent = panel
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
		return nil
	end
	return interactionSystem
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

local function getDoorPlane(part)
	if part.Size.X <= part.Size.Z then
		return "thin_x"
	end
	return "thin_z"
end

local function buildOpenCFrame(part, closedCFrame)
	local plane = getDoorPlane(part)
	if plane == "thin_x" then
		local hingeLocal = Vector3.new(0, 0, -(part.Size.Z * 0.5) + (part.Size.X * 0.5))
		local hingeWorld = closedCFrame * CFrame.new(hingeLocal)
		return hingeWorld * CFrame.Angles(0, OPEN_ANGLE, 0) * CFrame.new(-hingeLocal)
	end

	local hingeLocal = Vector3.new(-(part.Size.X * 0.5) + (part.Size.Z * 0.5), 0, 0)
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
	return source == LOCAL_PROMPT_SOURCE or source == LOCAL_AUTO_SOURCE
end

local function applyDoorState(doorRecord, interactionType, suppressSound)
	local part = doorRecord.part
	if not part or part.Parent == nil then
		return
	end

	if interactionType == "Open" then
		part.CFrame = doorRecord.openCFrame
		part.CanCollide = false
		part.CanTouch = false
		part:SetAttribute("DoorIsOpen", true)
		if suppressSound ~= true then
			playDoorSound(doorRecord.openSound, 1)
		end
	elseif interactionType == "Close" or interactionType == "Slam" then
		part.CFrame = doorRecord.closedCFrame
		part.CanCollide = true
		part.CanTouch = true
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
	if math.abs(localPosition.Y) > HYBRID_VERTICAL_TOLERANCE then
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

local function getNearestPlayerApproachDistance(doorRecord, players, matchId, depthThreshold, widthPadding)
	local nearest = nil

	for _, player in ipairs(players or {}) do
		if typeof(player) == "Instance"
			and player:IsA("Player")
			and (matchId == nil or tostring(player:GetAttribute("MatchId") or "") == tostring(matchId))
			and player:GetAttribute("InMatch") == true then
			local distance = getPlayerDoorApproachDistance(doorRecord, player, depthThreshold, widthPadding)
			if distance and (nearest == nil or distance < nearest) then
				nearest = distance
			end
		end
	end

	return nearest
end

local function executeDoorInteraction(doorRecord, interactionType, interactionSource)
	if not doorRecord or not interactionType then
		return false
	end

	local now = os.clock()
	doorRecord.lastInteractionAt = now
	doorRecord.lastInteractionSource = interactionSource
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

	for _, descendant in ipairs(scanRoot:GetDescendants()) do
		if isDoorPart(descendant) then
			local doorLabel = resolveDoorLabel(descendant)
			local prompt = ensurePrompt(descendant, doorLabel)
			local closedCFrame = descendant.CFrame
			local initialState = readInitialDoorState(descendant)
			local record = {
				part = descendant,
				prompt = prompt,
				label = doorLabel,
				matchId = matchId ~= "" and matchId or nil,
				closedCFrame = closedCFrame,
				openCFrame = buildOpenCFrame(descendant, closedCFrame),
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
			applyDoorState(record, initialState.isOpen and "Open" or "Close", true)
			setPromptState(prompt, initialState.isOpen, initialState.isLocked, doorLabel)

			prompt.Triggered:Connect(function()
				if descendant:GetAttribute("DoorLocked") == true then
					return
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

	if next(doorLookup) ~= nil and match and type(match.players) == "table" then
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
				if doorRecord.policy ~= POLICY_HYBRID_RADIUS_PROMPT then
					continue
				end

				local part = doorRecord.part
				if not part or part.Parent == nil or part:GetAttribute("DoorLocked") == true then
					continue
				end

				local currentOpen = part:GetAttribute("DoorIsOpen") == true
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
	end

	return next(doorLookup) ~= nil
end

return DoorRuntime

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
local DEFAULT_OPEN_SOUND_ID = "rbxassetid://139204195403262"
local DEFAULT_CLOSE_SOUND_ID = "rbxassetid://83336813491039"
local DEFAULT_SOUND_VOLUME = 0.45
local DEFAULT_SOUND_MAX_DISTANCE = 42

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

local function setPromptState(prompt, isOpen, isLocked)
	if not prompt then
		return
	end
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

	setPromptState(doorRecord.prompt, part:GetAttribute("DoorIsOpen") == true, part:GetAttribute("DoorLocked") == true)
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

local function ensurePrompt(part)
	local prompt = part:FindFirstChild(PROMPT_NAME)
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		prompt.ObjectText = "Pintu"
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
	prompt.ObjectText = "Pintu"
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
	local doorLookup = {}

	if match and match._doorRuntimeSubscription and eventBus then
		eventBus:Unsubscribe("MapObjectInteracted", match._doorRuntimeSubscription)
		match._doorRuntimeSubscription = nil
	end

	for _, descendant in ipairs(scanRoot:GetDescendants()) do
		if isDoorPart(descendant) then
			local prompt = ensurePrompt(descendant)
			local closedCFrame = descendant.CFrame
			local initialState = readInitialDoorState(descendant)
			local record = {
				part = descendant,
				prompt = prompt,
				closedCFrame = closedCFrame,
				openCFrame = buildOpenCFrame(descendant, closedCFrame),
				policy = normalizePolicy(initialState.policy),
				openSound = ensureDoorSound(descendant, OPEN_SOUND_NAME, descendant:GetAttribute(OPEN_SOUND_ATTR_NAME) or DEFAULT_OPEN_SOUND_ID),
				closeSound = ensureDoorSound(descendant, CLOSE_SOUND_NAME, descendant:GetAttribute(CLOSE_SOUND_ATTR_NAME) or DEFAULT_CLOSE_SOUND_ID),
				objectId = descendant.Name,
				mapInteractionSystem = mapInteractionSystem,
				lastNearbyAt = 0,
				lastInteractionAt = 0,
				manualOverrideUntil = 0,
				manualOverrideState = nil,
			}
			doorLookup[descendant.Name] = record
			descendant.Anchored = true
			descendant.CanQuery = true
			descendant:SetAttribute("DoorObjectId", descendant.Name)
			descendant:SetAttribute(POLICY_ATTR_NAME, record.policy)
			descendant:SetAttribute("DoorLocked", initialState.isLocked)
			descendant:SetAttribute("DoorIsOpen", initialState.isOpen)
			registerDoorInteraction(mapInteractionSystem, descendant.Name, descendant.Position)
			ensurePathfindingModifier(descendant)
			applyDoorState(record, initialState.isOpen and "Open" or "Close", true)
			setPromptState(prompt, initialState.isOpen, initialState.isLocked)

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
		local matchId = tostring(match.matchId or match.id or "")
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

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local LobbyPopulationController = {}
LobbyPopulationController.__index = LobbyPopulationController

local DEFAULT_CONFIG = {
	NpcCountWhenEmpty = 6,
	DefaultDummyAssetId = nil,
}

local NPC_SPAWN_TAG = "PasrahLobbyNpcSpawn"
local NPC_PATROL_TAG = "PasrahLobbyNpcPatrolNode"
local NPC_SORT_ORDER_ATTR = "PasrahLobbySortOrder"
local NPC_ROLE_ATTR = "PasrahLobbyNpcRole"
local NPC_DIALOGUE_ACTIVE_ATTR = "PasrahNpcDialogueActive"
local NPC_ROOTS_MISSING_WARN = "[LobbyPop] _NpcRoots not found, NPC disabled"
local NPC_RESPAWN_DELAY = 10
local NPC_DIALOGUE_TALK_ANIMATION_ID = "rbxassetid://507770239"
local NPC_DIALOGUE_GESTURE_INTERVAL = 5
local INVESTIGATOR_WALK_SPEED = 3.5
local NPC_DIALOGUE_GESTURES = { "wave", "point" }
local NPC_COLLISION_GROUP = "PasrahLobbyNPC"
local STATIC_DIALOGUE_ROLES = {
	Guide = true,
	TrainingGuide = true,
	GardenKeeper = true,
	Dukun = true,
}

local STATIC_DIALOGUE_NPC_SPECS = {
	{
		npcName = "LobbyGuide",
		role = "Guide",
		dialogueId = "guide_root",
		objectText = "Panduan Lobby",
		actionText = "Bicara",
		maxActivationDistance = 8,
		templateName = "NPC_Investigator_Placeholder",
		anchorPaths = {
			{ "LobbyZones", "SpawnPlaza", "Hub Mid", "QueuePlatform" },
			{ "Room_EastShopBuilding" },
			{ "Interact_EastShopBuilding" },
			{ "Prop_Room_EastShopBuilding_Counter" },
		},
		offsetDistance = 5,
		heightOffset = 3,
	},
	{
		npcName = "LobbyTrainingGuide",
		role = "TrainingGuide",
		dialogueId = "training_root",
		objectText = "Pelatih Tools",
		actionText = "Bicara",
		maxActivationDistance = 8,
		templateName = "NPC_Investigator_Placeholder",
		anchorPaths = {
			{ "LobbyZones", "TrainingZone", "TrainingZone" },
			{ "Room_EastShopBuilding" },
			{ "Prop_Room_EastShopBuilding_Shelf" },
			{ "Interact_EastShopBuilding" },
		},
		offsetDistance = 5,
		heightOffset = 3,
	},
	{
		npcName = "LobbyGardenKeeper",
		role = "GardenKeeper",
		dialogueId = "garden_root",
		objectText = "Penjaga Taman",
		actionText = "Bicara",
		maxActivationDistance = 8,
		templateName = "NPC_Investigator_Placeholder",
		anchorPaths = {
			{ "LobbyZones", "DailyRewardZone", "NodeGarden" },
			{ "Room_SouthSocialGarden" },
			{ "Prop_Room_SouthSocialGarden_Fountain" },
			{ "Prop_Room_SouthSocialGarden_Bench" },
		},
		offsetDistance = 4,
		heightOffset = 3,
	},
	{
		npcName = "LobbyDukun",
		role = "Dukun",
		dialogueId = "dukun_root",
		objectText = "Dukun",
		actionText = "Tanya",
		maxActivationDistance = 8,
		templateName = "NPC_Investigator_Placeholder",
		anchorPaths = {
			{ "LobbyZones", "FlexZone", "Flex", "NodeFlex" },
			{ "Room_SouthSocialGarden" },
			{ "Interact_SouthSocialGarden" },
			{ "Prop_Room_SouthSocialGarden_Bench" },
		},
		offsetDistance = 5,
		heightOffset = 3,
	},
}

local TRAINING_GUIDE_FALLBACK_POS = Vector3.new(1516, 1.0, 22)

local PRISTINE_NPC_TEMPLATES = {}
local NPC_MODELS_FOLDER_WARNED = false
local applyNpcNoCollision

local function countBaseParts(model)
	local basePartCount = 0
	local hasRootPart = false
	local hasHead = false
	local hasTorso = false
	for _, descendant in ipairs(model and model:GetDescendants() or {}) do
		if descendant:IsA("BasePart") then
			basePartCount += 1
			if descendant.Name == "HumanoidRootPart" then
				hasRootPart = true
			elseif descendant.Name == "Head" then
				hasHead = true
			elseif descendant.Name == "Torso" or descendant.Name == "UpperTorso" or descendant.Name == "LowerTorso" then
				hasTorso = true
			end
		end
	end
	return basePartCount, hasRootPart, hasHead, hasTorso
end

local function isValidNpcRig(model)
	local basePartCount, hasRootPart, hasHead, hasTorso = countBaseParts(model)
	return basePartCount >= 5 and hasRootPart and hasHead and hasTorso
end

local function resolveNpcRoots()
	local direct = Workspace:FindFirstChild("_NpcRoots", true)
	if direct then
		return direct
	end
	local maps = Workspace:FindFirstChild("Maps")
	local lobbySocialHub = maps and maps:FindFirstChild("LobbySocialHub")
	local lobbyRoot = lobbySocialHub and lobbySocialHub:FindFirstChild("LobbySocialHub")
	return lobbyRoot and lobbyRoot:FindFirstChild("_NpcRoots") or nil
end

local function resolveWorkspacePath(root, pathSegments)
	local current = root
	for _, segment in ipairs(pathSegments or {}) do
		if not current then
			return nil
		end
		current = current:FindFirstChild(segment)
	end
	if current and current:IsA("BasePart") then
		return current
	end
	return nil
end

local function resolveFirstAvailablePart(candidatePaths)
	for _, pathSegments in ipairs(candidatePaths or {}) do
		local resolved = resolveWorkspacePath(Workspace, pathSegments)
		if resolved then
			return resolved
		end
	end
	return nil
end

local function collectNamedParts(preferredNames)
	local nodes = {}
	local seen = {}
	for _, preferredName in ipairs(preferredNames or {}) do
		local found = Workspace:FindFirstChild(preferredName, true)
		if found and found:IsA("BasePart") and not seen[found] then
			seen[found] = true
			table.insert(nodes, found)
		end
	end
	return nodes
end

local function getFallbackLobbyOrigin()
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart"))
		if root and root:IsA("BasePart") then
			return root.Position + Vector3.new(0, 4, 0)
		end
	end

	local fallbackModel = Workspace:FindFirstChildWhichIsA("Model", true)
	if fallbackModel then
		local root = fallbackModel:FindFirstChild("HumanoidRootPart", true) or fallbackModel:FindFirstChildWhichIsA("BasePart", true)
		if root and root:IsA("BasePart") then
			return root.Position + Vector3.new(0, 4, 0)
		end
	end

	return Vector3.new(0, 8, 0)
end

local function createSyntheticAnchor(name, position)
	local part = Instance.new("Part")
	part.Name = name or "FallbackNpcAnchor"
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.Size = Vector3.new(2, 3, 2)
	part.Massless = true
	part.CFrame = CFrame.new(position or Vector3.new(0, 8, 0))
	return part
end

local function getSpawnCFrame(anchorPart)
	if not anchorPart or not anchorPart:IsA("BasePart") then
		return CFrame.new(0, 3, 0)
	end

	local origin = anchorPart.Position + Vector3.new(0, 50, 0)
	local direction = Vector3.new(0, -100, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {
		Workspace:FindFirstChild("_NpcRoots"),
		Workspace:FindFirstChild("LobbyZones"),
	}

	local hit = Workspace:Raycast(origin, direction, params)
	local groundY = hit and hit.Position.Y or anchorPart.Position.Y
	groundY = math.max(groundY, anchorPart.Position.Y, 0)

	return CFrame.new(anchorPart.Position.X, groundY + 3, anchorPart.Position.Z)
end

local function pivotNpcToSpawn(npc, anchorPart)
	if not npc then
		return
	end

	local spawnCF = getSpawnCFrame(anchorPart)
	npc:PivotTo(spawnCF)
end

local function stripHumanoidDescription(npc)
	if not npc then
		return
	end

	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end

	for _, child in ipairs(humanoid:GetChildren()) do
		if child:IsA("HumanoidDescription") then
			child:Destroy()
		end
	end

	humanoid.AutomaticScalingEnabled = false
end

local function isLobbyPlayer(player)
	return player
		and player:IsA("Player")
		and player:GetAttribute("InMatch") ~= true
		and player:GetAttribute("InLobby") ~= false
end

local function getTaggedNpcNodes(tagName, npcRoots, npcRole)
	local nodes = {}

	for _, instance in ipairs(CollectionService:GetTagged(tagName)) do
		if instance:IsA("BasePart") and (not npcRoots or instance:IsDescendantOf(npcRoots)) then
			if npcRole ~= nil and instance:GetAttribute(NPC_ROLE_ATTR) ~= npcRole then
				continue
			end
			table.insert(nodes, instance)
		end
	end

	table.sort(nodes, function(a, b)
		local aOrder = tonumber(a:GetAttribute(NPC_SORT_ORDER_ATTR)) or 0
		local bOrder = tonumber(b:GetAttribute(NPC_SORT_ORDER_ATTR)) or 0
		if aOrder == bOrder then
			return a.Name < b.Name
		end
		return aOrder < bOrder
	end)

	return nodes
end

local function createFallbackDummyModel(npcName)
	local model = Instance.new("Model")
	model.Name = npcName or "LobbyNpcFallback"

	local bodyColor = Color3.fromRGB(120, 120, 120)
	local accentColor = Color3.fromRGB(200, 200, 200)

	local function makePart(name, size, cframe, color, material)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = cframe
		part.Anchored = true
		part.CanCollide = true
		part.CanQuery = false
		part.CanTouch = true
		part.Material = material or Enum.Material.SmoothPlastic
		part.Color = color or bodyColor
		part.Parent = model
		return part
	end

	local root = makePart("HumanoidRootPart", Vector3.new(2, 2, 1), CFrame.new(0, 3, 0), accentColor, Enum.Material.SmoothPlastic)
	root.Transparency = 1
	root.CanCollide = false

	local torso = makePart("Torso", Vector3.new(2, 2, 1), root.CFrame * CFrame.new(0, 0, 0), bodyColor)
	local head = makePart("Head", Vector3.new(2, 1, 1), root.CFrame * CFrame.new(0, 1.5, 0), bodyColor)
	local leftArm = makePart("Left Arm", Vector3.new(1, 2, 1), root.CFrame * CFrame.new(-1.5, 0, 0), bodyColor)
	local rightArm = makePart("Right Arm", Vector3.new(1, 2, 1), root.CFrame * CFrame.new(1.5, 0, 0), bodyColor)
	local leftLeg = makePart("Left Leg", Vector3.new(1, 2, 1), root.CFrame * CFrame.new(-0.5, -2, 0), bodyColor)
	local rightLeg = makePart("Right Leg", Vector3.new(1, 2, 1), root.CFrame * CFrame.new(0.5, -2, 0), bodyColor)

	torso.CanCollide = true
	head.CanCollide = false
	leftArm.CanCollide = false
	rightArm.CanCollide = false
	leftLeg.CanCollide = true
	rightLeg.CanCollide = true

	local function weld(name, part0, part1)
		local weldConstraint = Instance.new("WeldConstraint")
		weldConstraint.Name = name
		weldConstraint.Part0 = part0
		weldConstraint.Part1 = part1
		weldConstraint.Parent = part0
	end

	weld("RootWeld", root, torso)
	weld("HeadWeld", root, head)
	weld("LeftArmWeld", root, leftArm)
	weld("RightArmWeld", root, rightArm)
	weld("LeftLegWeld", root, leftLeg)
	weld("RightLegWeld", root, rightLeg)

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.HipHeight = 2
	humanoid.RequiresNeck = false
	humanoid.Parent = model

	local bodyColors = Instance.new("BodyColors")
	bodyColors.HeadColor = BrickColor.new("Medium stone grey")
	bodyColors.TorsoColor = BrickColor.new("Dark stone grey")
	bodyColors.LeftArmColor = BrickColor.new("Medium stone grey")
	bodyColors.RightArmColor = BrickColor.new("Medium stone grey")
	bodyColors.LeftLegColor = BrickColor.new("Dark stone grey")
	bodyColors.RightLegColor = BrickColor.new("Dark stone grey")
	bodyColors.Parent = model

	local animate = Instance.new("LocalScript")
	animate.Name = "Animate"
	animate.Disabled = true
	animate.Parent = model

	model.PrimaryPart = root
	return model
end

local setupNpcAnimations

local function refreshNpcAnimatorTracks(controller, npc)
	if not controller or not npc then
		return
	end
	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local idleTrack, walkTrack, talkTrack = setupNpcAnimations(npc, humanoid)
	controller._npcTracks[npc] = {
		idleTrack = idleTrack,
		walkTrack = walkTrack,
		talkTrack = talkTrack,
		humanoid = humanoid,
	}
end

local function getNpcModelsFolder()
	local Assets = ServerStorage:FindFirstChild("Assets")
	local NPCModels = Assets and Assets:FindFirstChild("NPCModels")
	if not NPCModels or not NPCModels:IsA("Folder") then
		if not NPC_MODELS_FOLDER_WARNED then
			NPC_MODELS_FOLDER_WARNED = true
			warn("[LobbyPop] CRITICAL: ServerStorage.Assets.NPCModels tidak ditemukan. Semua NPC spawn dibatalkan.")
		end
		return nil
	end
	return NPCModels
end

local function loadTemplateFromServerStorage(templateName)
	local templateKey = templateName or "NPC_Investigator_Placeholder"
	local cached = PRISTINE_NPC_TEMPLATES[templateKey]
	if cached and cached:IsA("Model") then
		return cached:Clone()
	end

	local npcModels = getNpcModelsFolder()
	if not npcModels then
		return nil
	end

	local template = npcModels:FindFirstChild(templateKey)
	if not template then
		warn("[LobbyPop] Template tidak ada: " .. tostring(templateKey))
		return nil
	end
	if not template:IsA("Model") then
		warn("[LobbyPop] Template bukan Model: " .. tostring(templateKey))
		return nil
	end

	local clone = template:Clone()
	if not isValidNpcRig(clone) then
		warn("[LobbyPop] Template rig invalid: " .. tostring(templateKey))
		clone:Destroy()
		return nil
	end
	PRISTINE_NPC_TEMPLATES[templateKey] = clone:Clone()
	return clone
end

local function hasActiveLobbyPlayer()
	for _, player in ipairs(Players:GetPlayers()) do
		if isLobbyPlayer(player) then
			return true
		end
	end
	return false
end

local function ensureNpcCollisionGroup()
	pcall(function()
		PhysicsService:RegisterCollisionGroup(NPC_COLLISION_GROUP)
	end)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(NPC_COLLISION_GROUP, "Default", false)
	end)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(NPC_COLLISION_GROUP, NPC_COLLISION_GROUP, false)
	end)
end

applyNpcNoCollision = function(npc)
	if not npc then
		return
	end

	ensureNpcCollisionGroup()

	for _, descendant in ipairs(npc:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			pcall(function()
				PhysicsService:SetPartCollisionGroup(descendant, NPC_COLLISION_GROUP)
			end)
		end
	end
end

local function restoreNpcVisibility(npcModel)
	if not npcModel then return end
	for _, part in ipairs(npcModel:GetDescendants()) do
		if part:IsA("BasePart")
			and part.Name ~= "HumanoidRootPart"
			and part.Name ~= "DialogueTrigger" then
			if part.Transparency >= 1 then
				part.Transparency = 0
			end
		end
	end
end

local function destroyExistingNpcModelsWithName(npcName, keepModel)
	if type(npcName) ~= "string" or npcName == "" then
		return
	end

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Model") and descendant.Name == npcName and descendant ~= keepModel then
			descendant:Destroy()
		end
	end
end

function LobbyPopulationController.new(state, deps, config)
	local self = setmetatable({}, LobbyPopulationController)
	self._state = state
	self._deps = deps or {}
	self._config = {}
	for key, value in pairs(DEFAULT_CONFIG) do
		self._config[key] = value
	end
	for key, value in pairs(config or {}) do
		self._config[key] = value
	end
	self._connections = {}
	self._playerConnections = {}
	self._activeNpcs = {}
	self._npcTracks = {}
	self._dialoguePromptConnections = {}
	self._activeDialogueNpcsByPlayer = {}
	self._npcDialogueGestureTokens = {}
	self._spawnNodes = {}
	self._investigatorSpawnNodes = {}
	self._shopSpawnNodes = {}
	self._patrolNodes = {}
	self._npcRoots = nil
	self._supportNpcSpawnCount = 0
	self._started = false
	self._npcEnabled = false
	self._npcGeneration = 0
	self._respawnToken = 0
	self._matchStartSuppressed = false
	self._npcCount = 0
	return self
end

function LobbyPopulationController:_disconnectConnections()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)

	for _, connection in pairs(self._playerConnections) do
		connection:Disconnect()
	end
	table.clear(self._playerConnections)
end

function LobbyPopulationController:_resolveAndCacheNodes()
	self._npcRoots = resolveNpcRoots()
	if not self._npcRoots then
		warn(NPC_ROOTS_MISSING_WARN)
	end

	self._spawnNodes = getTaggedNpcNodes(NPC_SPAWN_TAG, self._npcRoots)
	self._shopSpawnNodes = getTaggedNpcNodes(NPC_SPAWN_TAG, self._npcRoots, "ShopKeeper")
	self._investigatorSpawnNodes = {}
	for _, node in ipairs(self._spawnNodes) do
		if node:GetAttribute(NPC_ROLE_ATTR) ~= "ShopKeeper" then
			table.insert(self._investigatorSpawnNodes, node)
		end
	end
	local rawPatrolNodes = getTaggedNpcNodes(NPC_PATROL_TAG, self._npcRoots)
	local correctedNodes = {}
	for _, node in ipairs(rawPatrolNodes) do
		if node and node:IsA("BasePart") then
			if node.Position.Y < 0.5 then
				node.Position = Vector3.new(node.Position.X, 1.0, node.Position.Z)
			end
			table.insert(correctedNodes, node)
		end
	end
	self._patrolNodes = correctedNodes

	if #self._spawnNodes == 0 then
		local origin = getFallbackLobbyOrigin()
		self._spawnNodes = {
			createSyntheticAnchor("FallbackInvestigatorSpawnA", origin + Vector3.new(4, 0, 6)),
			createSyntheticAnchor("FallbackInvestigatorSpawnB", origin + Vector3.new(-4, 0, 6)),
		}
	end
	self._investigatorSpawnNodes = {}
	for _, node in ipairs(self._spawnNodes) do
		if node:GetAttribute(NPC_ROLE_ATTR) ~= "ShopKeeper" then
			table.insert(self._investigatorSpawnNodes, node)
		end
	end
	if #self._shopSpawnNodes == 0 then
		local origin = getFallbackLobbyOrigin()
		self._shopSpawnNodes = {
			createSyntheticAnchor("FallbackShopSpawn", origin + Vector3.new(12, 0, 4)),
		}
	end
	if #self._patrolNodes == 0 then
		local origin = getFallbackLobbyOrigin()
		self._patrolNodes = {
			createSyntheticAnchor("FallbackPatrolA", origin + Vector3.new(6, 0, 8)),
			createSyntheticAnchor("FallbackPatrolB", origin + Vector3.new(-6, 0, 8)),
			createSyntheticAnchor("FallbackPatrolC", origin + Vector3.new(-6, 0, -2)),
			createSyntheticAnchor("FallbackPatrolD", origin + Vector3.new(6, 0, -2)),
		}
	end
	self._npcEnabled = true
	return true
end

function LobbyPopulationController:_isReadyToSpawn()
	return self._npcEnabled == true and self._started == true and self._matchStartSuppressed ~= true
end

function LobbyPopulationController:_getDesiredNpcCount()
	local npcCount = tonumber(self._state:Get("lobbyNpcInvestigators")) or 0
	if npcCount <= 0 then
		npcCount = 2
	end
	return npcCount
end

function LobbyPopulationController:_cloneNpcTemplate()
	local template = loadTemplateFromServerStorage("NPC_Investigator_Placeholder")
	if not template then
		return nil
	end
	return template
end

function LobbyPopulationController:_cloneSupportNpcTemplate(templateName)
	local template = loadTemplateFromServerStorage(templateName or "NPC_Investigator_Placeholder")
	if not template then
		return nil
	end
	return template
end

setupNpcAnimations = function(npc, humanoid)
	if not (npc and humanoid) then
		return nil, nil, nil
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local idleAnim = Instance.new("Animation")
	idleAnim.AnimationId = "rbxassetid://507766666"

	local walkAnim = Instance.new("Animation")
	walkAnim.AnimationId = "rbxassetid://507777826"

	local talkAnim = Instance.new("Animation")
	talkAnim.AnimationId = NPC_DIALOGUE_TALK_ANIMATION_ID

	local idleTrack = animator:LoadAnimation(idleAnim)
	local walkTrack = animator:LoadAnimation(walkAnim)
	local talkTrack = animator:LoadAnimation(talkAnim)

	idleTrack.Priority = Enum.AnimationPriority.Idle
	walkTrack.Priority = Enum.AnimationPriority.Movement
	talkTrack.Priority = Enum.AnimationPriority.Action
	talkTrack.Looped = true
	idleTrack:Play()

	return idleTrack, walkTrack, talkTrack
end

local function setNpcAnimationState(tracks, moving)
	if not tracks then
		return
	end

	if moving == true then
		if tracks.idleTrack and tracks.idleTrack.IsPlaying then
			tracks.idleTrack:Stop()
		end
		if tracks.walkTrack and not tracks.walkTrack.IsPlaying then
			tracks.walkTrack:Play()
		end
	else
		if tracks.walkTrack and tracks.walkTrack.IsPlaying then
			tracks.walkTrack:Stop()
		end
		if tracks.idleTrack and not tracks.idleTrack.IsPlaying then
			tracks.idleTrack:Play()
		end
	end
end

local function setNpcDialogueAnimationState(tracks, active)
	if not tracks then
		return
	end

	if active == true then
		if tracks.idleTrack and tracks.idleTrack.IsPlaying then
			tracks.idleTrack:Stop()
		end
		if tracks.walkTrack and tracks.walkTrack.IsPlaying then
			tracks.walkTrack:Stop()
		end
		if tracks.talkTrack and not tracks.talkTrack.IsPlaying then
			tracks.talkTrack:Play()
		end
	else
		if tracks.talkTrack and tracks.talkTrack.IsPlaying then
			tracks.talkTrack:Stop()
		end
	end
end

local function startNpcDialogueGestureLoop(controller, npc, humanoid, tracks)
	if not (controller and npc and humanoid) then
		return
	end

	controller._npcDialogueGestureTokens = controller._npcDialogueGestureTokens or {}
	controller._npcDialogueGestureTokens[npc] = (controller._npcDialogueGestureTokens[npc] or 0) + 1
	local token = controller._npcDialogueGestureTokens[npc]

	task.spawn(function()
		local gestureIndex = 1
		while controller._started == true
			and controller._npcDialogueGestureTokens[npc] == token
			and npc.Parent
			and npc:GetAttribute(NPC_DIALOGUE_ACTIVE_ATTR) == true do
			local emoteName = NPC_DIALOGUE_GESTURES[gestureIndex]
			gestureIndex += 1
			if gestureIndex > #NPC_DIALOGUE_GESTURES then
				gestureIndex = 1
			end

			local ok, played = pcall(function()
				return humanoid:PlayEmote(emoteName)
			end)
			if not ok or played ~= true then
				if tracks and tracks.talkTrack and not tracks.talkTrack.IsPlaying then
					tracks.talkTrack:Play()
				end
			end

			task.wait(NPC_DIALOGUE_GESTURE_INTERVAL)
		end
	end)
end

local function stopNpcDialogueGestureLoop(controller, npc, tracks)
	if controller and controller._npcDialogueGestureTokens then
		controller._npcDialogueGestureTokens[npc] = (controller._npcDialogueGestureTokens[npc] or 0) + 1
	end
	if tracks and tracks.talkTrack and tracks.talkTrack.IsPlaying then
		tracks.talkTrack:Stop()
	end
end

function LobbyPopulationController:_beginNpcDialogue(npc, player)
	if not npc then
		return
	end

	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local tracks = self._npcTracks[npc]
	if player and player:IsA("Player") then
		self._activeDialogueNpcsByPlayer[player] = {
			npc = npc,
			originalPivot = npc:GetPivot(),
		}
	end
	npc:SetAttribute(NPC_DIALOGUE_ACTIVE_ATTR, true)
	if player and player:IsA("Player") then
		npc:SetAttribute("PasrahNpcDialoguePlayerUserId", player.UserId)
	end
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.AutoRotate = false
	end
	setNpcAnimationState(tracks, false)
	setNpcDialogueAnimationState(tracks, false)
	stopNpcDialogueGestureLoop(self, npc, tracks)
	startNpcDialogueGestureLoop(self, npc, humanoid, tracks)

	if player and player.Character then
		local root = player.Character:FindFirstChild("HumanoidRootPart")
		local npcRoot = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart")
		if root and npcRoot and npcRoot:IsA("BasePart") then
			pcall(function()
				npc:PivotTo(CFrame.lookAt(npcRoot.Position, root.Position))
			end)
		end
	end
end

function LobbyPopulationController:_endNpcDialogue(entryOrNpc)
	local npc = entryOrNpc
	local originalPivot = nil
	if type(entryOrNpc) == "table" then
		npc = entryOrNpc.npc
		originalPivot = entryOrNpc.originalPivot
	end
	if not npc then
		return
	end

	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	local tracks = self._npcTracks[npc]
	npc:SetAttribute(NPC_DIALOGUE_ACTIVE_ATTR, false)
	npc:SetAttribute("PasrahNpcDialoguePlayerUserId", nil)
	stopNpcDialogueGestureLoop(self, npc, tracks)
	setNpcDialogueAnimationState(tracks, false)

	if humanoid then
		local role = npc:GetAttribute(NPC_ROLE_ATTR)
		if role == "ShopKeeper" or STATIC_DIALOGUE_ROLES[role] == true then
			humanoid.WalkSpeed = 0
			humanoid.AutoRotate = false
		else
			humanoid.WalkSpeed = INVESTIGATOR_WALK_SPEED
			humanoid.AutoRotate = true
		end
	end
	setNpcAnimationState(tracks, false)
	if originalPivot then
		pcall(function()
			npc:PivotTo(originalPivot)
		end)
	end
end

local function ensureDialoguePrompt(controller, npc, dialogueId, objectText, maxActivationDistance, actionText)
	if not npc then
		return nil
	end

	local rootPart = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart", true)
	local pivotCFrame = npc:GetPivot()
	if not rootPart then
		rootPart = nil
	end

	local promptParent = npc:FindFirstChild("DialogueTrigger")
	if not (promptParent and promptParent:IsA("BasePart")) then
		if promptParent then
			promptParent:Destroy()
		end
		promptParent = Instance.new("Part")
		promptParent.Name = "DialogueTrigger"
		promptParent.Anchored = false
		promptParent.CanCollide = false
		promptParent.CanTouch = false
		promptParent.CanQuery = false
		promptParent.Transparency = 1
		promptParent.Size = Vector3.new(2, 3, 2)
		promptParent.Massless = true
		promptParent.Anchored = rootPart == nil
		promptParent.CFrame = rootPart and rootPart.CFrame or pivotCFrame
		promptParent.Parent = npc

		if rootPart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = promptParent
			weld.Part1 = rootPart
			weld.Parent = promptParent
		end
	end

	local prompt = promptParent:FindFirstChild("DialoguePrompt")
	if not (prompt and prompt:IsA("ProximityPrompt")) then
		if prompt then
			prompt:Destroy()
		end
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "DialoguePrompt"
		prompt.ActionText = actionText or "Bicara"
		prompt.ObjectText = objectText or npc.Name
		prompt.MaxActivationDistance = maxActivationDistance or 10
		prompt.Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally
		prompt.RequiresLineOfSight = false
		prompt.HoldDuration = 0
		prompt.Parent = promptParent
	end

	prompt:SetAttribute("PasrahNpcDialogueId", dialogueId)
	npc:SetAttribute("PasrahNpcDialogueId", dialogueId)
	npc:SetAttribute("DialogueReady", true)
	prompt:SetAttribute("NpcDialogueBound", true)

	local connection
	connection = prompt.Triggered:Connect(function(player)
		if not player or not player:IsA("Player") then
			return
		end
		if controller and type(controller._beginNpcDialogue) == "function" then
			controller:_beginNpcDialogue(npc, player)
		end
		local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
		local remote = remoteFolder and remoteFolder:FindFirstChild("NpcDialogueEvent")
		if remote and remote:IsA("RemoteEvent") then
			remote:FireClient(player, "OPEN", dialogueId, npc)
		end
	end)
	return prompt, connection
end

function LobbyPopulationController:_spawnSupportDialogueNpc(spec)
	if not self:_isReadyToSpawn() then
		print("[LobbyPopDebug] support spawn blocked not ready", spec and spec.npcName)
		return nil
	end
	if type(spec) ~= "table" then
		print("[LobbyPopDebug] support spawn bad spec")
		return nil
	end

	local anchor = resolveFirstAvailablePart(spec.anchorPaths)
	if not anchor then
		if spec.role == "TrainingGuide" then
			anchor = createSyntheticAnchor((spec.npcName or "LobbySupportNpc") .. "_FallbackAnchor", TRAINING_GUIDE_FALLBACK_POS)
		else
			local origin = getFallbackLobbyOrigin()
			local fallbackOffsets = {
				Guide = Vector3.new(10, 0, -8),
				GardenKeeper = Vector3.new(-10, 0, 10),
				Dukun = Vector3.new(0, 0, 14),
			}
			anchor = createSyntheticAnchor((spec.npcName or "LobbySupportNpc") .. "_FallbackAnchor", origin + (fallbackOffsets[spec.role] or Vector3.new(8, 0, 8)))
		end
	end

	local npc = createFallbackDummyModel(spec.npcName or ("Lobby" .. tostring(spec.role or "SupportNpc")))

	npc.Name = spec.npcName or ("Lobby" .. tostring(spec.role or "SupportNpc"))
	destroyExistingNpcModelsWithName(npc.Name, npc)
	npc:SetAttribute("PasrahLobbyNpc", true)
	npc:SetAttribute(NPC_ROLE_ATTR, spec.role or "SupportNpc")

	for _, p in ipairs(npc:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
		end
	end

	pivotNpcToSpawn(npc, anchor)
	npc.Parent = Workspace

	task.defer(function()
		if not npc or not npc.Parent then return end

		local hum = npc:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.MaxHealth = 100
			hum.Health = 100
			hum.WalkSpeed = 8
		end

		restoreNpcVisibility(npc)

		for _, p in ipairs(npc:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				p.Anchored = false
			end
		end

		local hrp = npc:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.Anchored = false end
	end)

	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 8
	end

	if humanoid then
		local idleTrack, walkTrack, talkTrack = setupNpcAnimations(npc, humanoid)
		if walkTrack and walkTrack.IsPlaying then
			walkTrack:Stop()
		end
		self._npcTracks[npc] = {
			idleTrack = idleTrack,
			walkTrack = walkTrack,
			talkTrack = talkTrack,
			humanoid = humanoid,
		}
	end

	local prompt, connection = ensureDialoguePrompt(
		self,
		npc,
		spec.dialogueId or "guide_root",
		spec.objectText or npc.Name,
		spec.maxActivationDistance or 8,
		spec.actionText or "Bicara"
	)
	if prompt and connection then
		self._dialoguePromptConnections[npc] = connection
	end

	table.insert(self._activeNpcs, npc)
	print("[LobbyPopDebug] spawned support npc", spec.npcName, "role", spec.role, "anchor", anchor:GetFullName())
	return npc
end

function LobbyPopulationController:_ensureSupportDialogueNpcs()
	local spawnedCount = 0
	for _, spec in ipairs(STATIC_DIALOGUE_NPC_SPECS) do
		local existing = Workspace:FindFirstChild(spec.npcName)
		if existing and existing:IsA("Model") then
			if existing:GetAttribute(NPC_ROLE_ATTR) == spec.role then
				spawnedCount += 1
			end
		else
			local npc = self:_spawnSupportDialogueNpc(spec)
			if npc then
				spawnedCount += 1
			end
		end
	end
	self._supportNpcSpawnCount = spawnedCount
	print("[LobbyPopDebug] ensure support npc count", spawnedCount)
	return spawnedCount
end

function LobbyPopulationController:_spawnInvestigator(spawnNode, index)
	if not self:_isReadyToSpawn() then
		return nil
	end
	if not spawnNode or not spawnNode:IsA("BasePart") then
		return nil
	end

	local npc = createFallbackDummyModel("LobbyInvestigator_" .. tostring(index or (#self._activeNpcs + 1)))

	npc.Name = "LobbyInvestigator_" .. tostring(index or (#self._activeNpcs + 1))
	destroyExistingNpcModelsWithName(npc.Name, npc)
	npc:SetAttribute("PasrahLobbyNpc", true)
	npc:SetAttribute(NPC_ROLE_ATTR, "Investigator")

	for _, p in ipairs(npc:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
		end
	end

	pivotNpcToSpawn(npc, spawnNode)
	npc.Parent = Workspace

	task.defer(function()
		if not npc or not npc.Parent then return end

		local hum = npc:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.MaxHealth = 100
			hum.Health = 100
			hum.WalkSpeed = INVESTIGATOR_WALK_SPEED
		end

		restoreNpcVisibility(npc)

		for _, p in ipairs(npc:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				p.Anchored = false
			end
		end

		local hrp = npc:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.Anchored = false end
	end)

	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = INVESTIGATOR_WALK_SPEED
	end

	if humanoid then
		local idleTrack, walkTrack, talkTrack = setupNpcAnimations(npc, humanoid)
		self._npcTracks[npc] = {
			idleTrack = idleTrack,
			walkTrack = walkTrack,
			talkTrack = talkTrack,
			humanoid = humanoid,
		}
	end

	local prompt, connection = ensureDialoguePrompt(self, npc, "investigator_root", "Investigator", 7)
	if prompt and connection then
		self._dialoguePromptConnections[npc] = connection
	end
	table.insert(self._activeNpcs, npc)
	return npc
end

function LobbyPopulationController:_spawnShopKeeper(spawnNode)
	if not self:_isReadyToSpawn() then
		return nil
	end
	if not spawnNode or not spawnNode:IsA("BasePart") then
		return nil
	end

	local npc = createFallbackDummyModel("LobbyShopKeeper")

	npc.Name = "LobbyShopKeeper"
	destroyExistingNpcModelsWithName(npc.Name, npc)
	npc:SetAttribute("PasrahLobbyNpc", true)
	npc:SetAttribute(NPC_ROLE_ATTR, "ShopKeeper")

	for _, p in ipairs(npc:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
		end
	end

	pivotNpcToSpawn(npc, spawnNode)
	npc.Parent = Workspace

	task.defer(function()
		if not npc or not npc.Parent then return end

		local hum = npc:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.MaxHealth = 100
			hum.Health = 100
			hum.WalkSpeed = 0
		end

		restoreNpcVisibility(npc)

		for _, p in ipairs(npc:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				p.Anchored = false
			end
		end

		local hrp = npc:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.Anchored = false end
	end)

	local humanoid = npc:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
	end

	if humanoid then
		local idleTrack, walkTrack, talkTrack = setupNpcAnimations(npc, humanoid)
		if walkTrack and walkTrack.IsPlaying then
			walkTrack:Stop()
		end
		self._npcTracks[npc] = {
			idleTrack = idleTrack,
			walkTrack = walkTrack,
			talkTrack = talkTrack,
			humanoid = humanoid,
		}
	end

	local prompt, connection = ensureDialoguePrompt(self, npc, "shopkeeper_root", "Penjaga Toko", 6)
	if prompt and connection then
		self._dialoguePromptConnections[npc] = connection
	end
	table.insert(self._activeNpcs, npc)
	return npc
end

function LobbyPopulationController:_startPatrolLoop(npc, patrolNodes)
	if not npc then
		return
	end

	local generation = self._npcGeneration
	task.spawn(function()
		local patrolIndex = 1
		while self._started == true and self._npcGeneration == generation and npc.Parent do
			if npc:GetAttribute(NPC_DIALOGUE_ACTIVE_ATTR) == true then
				setNpcAnimationState(self._npcTracks[npc], false)
				task.wait(0.25)
				continue
			end

			local humanoid = npc:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				break
			end

			if #patrolNodes > 0 then
				local node = patrolNodes[patrolIndex]
				if not node or not node.Parent then
					break
				end
				setNpcAnimationState(self._npcTracks[npc], true)
				humanoid:MoveTo(node.Position)
				humanoid.MoveToFinished:Wait()
				setNpcAnimationState(self._npcTracks[npc], false)
				patrolIndex += 1
				if patrolIndex > #patrolNodes then
					patrolIndex = 1
				end
			end

			task.wait(1.5 + math.random(0, 2))
		end
	end)
end

function LobbyPopulationController:_despawnAllNpcs()
	self._npcGeneration += 1
	for _, npc in ipairs(self._activeNpcs) do
		local tracks = self._npcTracks[npc]
		local dialogueConnection = self._dialoguePromptConnections[npc]
		if dialogueConnection then
			dialogueConnection:Disconnect()
			self._dialoguePromptConnections[npc] = nil
		end
		if tracks then
			if tracks.walkTrack and tracks.walkTrack.IsPlaying then
				tracks.walkTrack:Stop()
			end
			if tracks.idleTrack and tracks.idleTrack.IsPlaying then
				tracks.idleTrack:Stop()
			end
			if tracks.talkTrack and tracks.talkTrack.IsPlaying then
				tracks.talkTrack:Stop()
			end
			self._npcTracks[npc] = nil
		end
		if npc and npc.Parent then
			npc:Destroy()
		end
	end
	table.clear(self._activeNpcs)
	table.clear(self._activeDialogueNpcsByPlayer)
	table.clear(self._npcDialogueGestureTokens)
	self._supportNpcSpawnCount = 0
end

function LobbyPopulationController:_spawnNpcWave()
	if not self:_isReadyToSpawn() then
		print("[LobbyPopDebug] spawn wave blocked not ready")
		return
	end
	if #self._investigatorSpawnNodes <= 0 and #self._shopSpawnNodes <= 0 then
		print("[LobbyPopDebug] spawn wave blocked no nodes")
		return
	end

	local desiredCount = self:_getDesiredNpcCount()
	if desiredCount <= 0 then
		return
	end

	self._npcGeneration += 1
	local generation = self._npcGeneration
	local patrolNodes = table.clone(self._patrolNodes)
	self._supportNpcSpawnCount = 0
	print("[LobbyPopDebug] spawn wave start", "investigators", #self._investigatorSpawnNodes, "shops", #self._shopSpawnNodes, "supports", #STATIC_DIALOGUE_NPC_SPECS)
	if #self._shopSpawnNodes > 0 then
		for _, spawnNode in ipairs(self._shopSpawnNodes) do
			self:_spawnShopKeeper(spawnNode)
		end
	end
	for _, spec in ipairs(STATIC_DIALOGUE_NPC_SPECS) do
		local npc = self:_spawnSupportDialogueNpc(spec)
		if npc then
			self._supportNpcSpawnCount += 1
		end
	end
	print("[LobbyPopDebug] spawn wave support count", self._supportNpcSpawnCount)
	local investigatorCount = #self._investigatorSpawnNodes > 0 and desiredCount or 0
	for i = 1, investigatorCount do
		local spawnNode = self._investigatorSpawnNodes[((i - 1) % #self._investigatorSpawnNodes) + 1]
		if spawnNode then
			local npc = self:_spawnInvestigator(spawnNode, i)
			if npc then
				if self._npcGeneration == generation and npc.Parent then
					self:_startPatrolLoop(npc, patrolNodes)
				end
			end
		end
	end
end

function LobbyPopulationController:_syncNpcPopulation()
	if not self:_isReadyToSpawn() then
		return
	end

	local shouldSpawn = hasActiveLobbyPlayer() == true and self._matchStartSuppressed ~= true
	if not shouldSpawn then
		if #self._activeNpcs > 0 then
			self:_despawnAllNpcs()
		end
		return
	end

	local desiredCount = self:_getDesiredNpcCount()
	local investigatorCount = #self._investigatorSpawnNodes > 0 and desiredCount or 0
	local desiredTotal = investigatorCount + #self._shopSpawnNodes + (self._supportNpcSpawnCount or 0)
	if #self._activeNpcs ~= desiredTotal then
		self:_despawnAllNpcs()
		self:_spawnNpcWave()
	end
end

function LobbyPopulationController:_trackPlayer(player)
	if not player or not player:IsA("Player") then
		return
	end

	local existing = self._playerConnections[player]
	if existing then
		for _, connection in ipairs(existing) do
			connection:Disconnect()
		end
	end

	local connections = {}
	self._playerConnections[player] = connections

	local function sync()
		if self._started ~= true then
			return
		end
		if player:GetAttribute("InMatch") == true then
			self:_handleMatchStarting()
		else
			self:_syncNpcPopulation()
		end
	end

	table.insert(connections, player:GetAttributeChangedSignal("InLobby"):Connect(sync))
	table.insert(connections, player:GetAttributeChangedSignal("InMatch"):Connect(sync))
	table.insert(connections, player.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			local stored = self._playerConnections[player]
			if stored then
				for _, connection in ipairs(stored) do
					connection:Disconnect()
				end
			end
			self._playerConnections[player] = nil
			if self._started == true then
				self:_syncNpcPopulation()
			end
		end
	end))
	sync()
end

function LobbyPopulationController:_bindRuntimeListeners()
	self:_disconnectConnections()

	table.insert(self._connections, Players.PlayerAdded:Connect(function(player)
		self:_trackPlayer(player)
	end))
	table.insert(self._connections, Players.PlayerRemoving:Connect(function(player)
		local connections = self._playerConnections[player]
		if connections then
			for _, connection in ipairs(connections) do
				connection:Disconnect()
			end
		end
		local entry = self._activeDialogueNpcsByPlayer[player]
		if entry and entry.npc and entry.npc.Parent then
			self:_endNpcDialogue(entry)
		end
		self._playerConnections[player] = nil
		self._activeDialogueNpcsByPlayer[player] = nil
		self:_syncNpcPopulation()
	end))

	for _, player in ipairs(Players:GetPlayers()) do
		self:_trackPlayer(player)
	end

	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	local dialogueEvent = remoteFolder and remoteFolder:FindFirstChild("NpcDialogueEvent")
	local matchEvent = remoteFolder and remoteFolder:FindFirstChild("MatchEvent")
	if dialogueEvent and dialogueEvent:IsA("RemoteEvent") then
		table.insert(self._connections, dialogueEvent.OnServerEvent:Connect(function(player, action)
			if action ~= "CLOSE" then
				return
			end

			local entry = self._activeDialogueNpcsByPlayer[player]
			if entry and entry.npc and entry.npc.Parent then
				self:_endNpcDialogue(entry)
			end
			self._activeDialogueNpcsByPlayer[player] = nil
		end))
	end
	if matchEvent and matchEvent:IsA("RemoteEvent") then
		table.insert(self._connections, matchEvent.OnServerEvent:Connect(function(_, action)
			if action == "MatchStarting" or action == "RoomMatchStarting" then
				self:_handleMatchStarting()
			end
		end))
	end
end

function LobbyPopulationController:_handleMatchStarting()
	if self._started ~= true then
		return
	end

	self._matchStartSuppressed = true
	self._respawnToken += 1
	self:_despawnAllNpcs()
	table.clear(self._activeDialogueNpcsByPlayer)

	local respawnToken = self._respawnToken
	task.delay(NPC_RESPAWN_DELAY, function()
		if self._started ~= true or self._respawnToken ~= respawnToken then
			return
		end
		self._matchStartSuppressed = false
		if hasActiveLobbyPlayer() == true then
			self:_syncNpcPopulation()
		end
	end)
end

function LobbyPopulationController:Init()
	self._state:Set("lobbyNpcInvestigators", 0)
	self:_resolveAndCacheNodes()
end

function LobbyPopulationController:Start()
	self._started = true
	if not self._npcEnabled then
		self:_resolveAndCacheNodes()
	end
	self:_bindRuntimeListeners()
	self:_ensureSupportDialogueNpcs()
	self:_syncNpcPopulation()
end

function LobbyPopulationController:Stop()
	self._started = false
	self._matchStartSuppressed = false
	self._respawnToken += 1
	self:_despawnAllNpcs()
	self:_disconnectConnections()
	self._state:Set("lobbyNpcInvestigators", 0)
end

function LobbyPopulationController:OnLobbyPlayerCountChanged(playerCount)
	local npcCount = 0
	if playerCount <= 0 then
		npcCount = self._config.NpcCountWhenEmpty
	end
	self._npcCount = npcCount
	self._state:Set("lobbyNpcInvestigators", npcCount)
	if self._started == true then
		self:_syncNpcPopulation()
	end
	return npcCount
end

function LobbyPopulationController:GetNpcCount()
	return self._state:Get("lobbyNpcInvestigators") or 0
end

return LobbyPopulationController

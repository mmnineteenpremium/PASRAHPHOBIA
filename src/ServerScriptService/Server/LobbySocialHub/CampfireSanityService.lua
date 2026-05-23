local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LobbyLocator = require(script.Parent.Parent.Core.LobbyLocator)
local Services = require(script.Parent.Parent.Core.Services)

local CampfireSanityService = {}
CampfireSanityService.__index = CampfireSanityService

local LOBBY_NAME = "LobbySocialHub"
local CAMPFIRE_FOLDER_NAME = "CampfireRuntime"
local CAMPFIRE_CENTER_NAME = "CampfireCenter"
local CAMPFIRE_CORE_NAME = "CampfireFireCore"
local CAMPFIRE_SAFE_RADIUS_ATTRIBUTE = "PasrahLobbyCampfireSafeRadius"
local CAMPFIRE_SEAT_COUNT = 6
local CAMPFIRE_SEAT_RADIUS = 15
local CAMPFIRE_SAFE_RADIUS = 12
local SANITY_RESTORE_PER_SECOND = 1.5
local SANITY_RESTORE_INTERVAL = 1
local WORLD_POINT_LIGHT_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldEffects", "WorldPointLightTemplate" }
local WORLD_FIRE_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldEffects", "WorldFireTemplate" }

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

local function cloneWorldFireTemplate(name)
	local template = resolveChildPath(ReplicatedStorage, WORLD_FIRE_TEMPLATE_PATH)
	if template and template:IsA("Fire") then
		local clone = template:Clone()
		clone.Name = name
		return clone
	end
	return nil
end

local function toUserId(player)
	if typeof(player) == "Instance" and player:IsA("Player") then
		return player.UserId
	end
	return nil
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

local function ensurePart(parent, name, className)
	local part = parent:FindFirstChild(name)
	if part and part.ClassName == className then
		return part
	end
	if part then
		part:Destroy()
	end
	part = Instance.new(className)
	part.Name = name
	part.Parent = parent
	return part
end

local function resolveLobbyRoot()
	return LobbyLocator.ResolveRoot(LOBBY_NAME, workspace)
end

local function resolveHubCenter(lobbyRoot)
	if not lobbyRoot then
		return nil
	end

	for _, name in ipairs({ "Room_MainHubPlaza", "Prop_MainHubPlaza", "Floor_1_Main" }) do
		local part = lobbyRoot:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			return part.Position
		end
	end

	local firstPart = lobbyRoot:FindFirstChildWhichIsA("BasePart", true)
	return firstPart and firstPart.Position or nil
end

function CampfireSanityService.new(state, deps, config)
	local self = setmetatable({}, CampfireSanityService)
	self._state = state
	self._deps = deps or {}
	self._config = config or {}
	self._heartbeatConnection = nil
	self._elapsed = 0
	self._lastRestoreAtByUserId = {}
	self._campfireCenter = nil
	return self
end

function CampfireSanityService:_resolveSanitySystem()
	return Services.Get(self._deps, "SanitySystem")
end

function CampfireSanityService:_resolveCampfireCenter()
	local lobbyRoot = resolveLobbyRoot()
	if not lobbyRoot then
		return nil
	end
	local folder = lobbyRoot:FindFirstChild(CAMPFIRE_FOLDER_NAME, true)
	local centerPart = folder and folder:FindFirstChild(CAMPFIRE_CENTER_NAME)
	if centerPart and centerPart:IsA("BasePart") then
		return centerPart.Position
	end
	return resolveHubCenter(lobbyRoot)
end

function CampfireSanityService:_restoreSeatedLobbySanity()
	local sanitySystem = self:_resolveSanitySystem()
	if type(sanitySystem) ~= "table" then
		return
	end

	local center = self._campfireCenter or self:_resolveCampfireCenter()
	if typeof(center) ~= "Vector3" then
		return
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("InLobby") == true and player:GetAttribute("InMatch") ~= true then
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local seatPart = humanoid and humanoid.SeatPart
			local validSeat = seatPart and seatPart:IsA("Seat") and seatPart:GetAttribute("PasrahCampfireSeat") == true
			local nearCampfire = root and (root.Position - center).Magnitude <= (CAMPFIRE_SAFE_RADIUS + 10)
			if validSeat and nearCampfire then
				local userId = toUserId(player)
				if userId then
					local now = os.clock()
					local lastRestoreAt = self._lastRestoreAtByUserId[userId] or 0
					if (now - lastRestoreAt) >= SANITY_RESTORE_INTERVAL then
						local lobbyMatchId = string.format("lobby:%d", userId)
						local current = nil
						if type(sanitySystem.GetSanity) == "function" then
							current = sanitySystem:GetSanity(player, lobbyMatchId)
						end
						if type(current) == "number" and current >= 100 and type(sanitySystem.GetSanity) == "function" and type(sanitySystem.DrainSanity) == "function" then
							local carryOver = sanitySystem:GetSanity(player, nil)
							if type(carryOver) == "number" and carryOver < 100 then
								sanitySystem:DrainSanity(player, 100 - carryOver, lobbyMatchId, "lobby_campfire_sync")
								current = sanitySystem:GetSanity(player, lobbyMatchId)
							end
						end
						if type(current) == "number" and current < 100 and type(sanitySystem.RestoreSanity) == "function" then
							sanitySystem:RestoreSanity(player, SANITY_RESTORE_PER_SECOND, lobbyMatchId, "lobby_campfire_idle")
						end
						self._lastRestoreAtByUserId[userId] = now
					end
				end
			end
		end
	end
end

function CampfireSanityService:_applyWoodenZoneTheme(lobbyRoot)
	local function shouldPatch(partName)
		local lowered = string.lower(partName)
		if not (
			string.find(lowered, "shop", 1, true)
			or string.find(lowered, "party", 1, true)
			or string.find(lowered, "dailyreward", 1, true)
			or string.find(lowered, "matchmaking", 1, true)
			or string.find(lowered, "database", 1, true)
			or string.find(lowered, "evidencebuilding", 1, true)
		) then
			return false
		end
		if string.find(lowered, "light", 1, true) or string.find(lowered, "neon", 1, true) then
			return false
		end
		return true
	end

	for _, descendant in ipairs(lobbyRoot:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Transparency < 0.98 and shouldPatch(descendant.Name) then
			if descendant.Material ~= Enum.Material.WoodPlanks then
				descendant.Material = Enum.Material.WoodPlanks
			end
			if descendant.Color ~= Color3.fromRGB(96, 72, 52) then
				descendant.Color = Color3.fromRGB(96, 72, 52)
			end
		end
	end
end

function CampfireSanityService:_ensureCampfireWorld()
	local lobbyRoot = resolveLobbyRoot()
	if not lobbyRoot then
		return
	end

	local center = resolveHubCenter(lobbyRoot)
	if typeof(center) ~= "Vector3" then
		return
	end
	self._campfireCenter = center

	local runtimeFolder = ensureFolder(lobbyRoot, CAMPFIRE_FOLDER_NAME)

	local centerPart = ensurePart(runtimeFolder, CAMPFIRE_CENTER_NAME, "Part")
	centerPart.Anchored = true
	centerPart.CanCollide = false
	centerPart.CanQuery = false
	centerPart.CanTouch = false
	centerPart.Transparency = 1
	centerPart.Size = Vector3.new(2, 1, 2)
	centerPart.CFrame = CFrame.new(center.X, center.Y + 0.5, center.Z)

	local firePit = ensurePart(runtimeFolder, "CampfirePit", "Part")
	firePit.Anchored = true
	firePit.CanCollide = true
	firePit.CanQuery = true
	firePit.CanTouch = false
	firePit.Material = Enum.Material.Slate
	firePit.Color = Color3.fromRGB(52, 48, 46)
	firePit.Size = Vector3.new(10, 0.8, 10)
	firePit.CFrame = CFrame.new(center.X, center.Y + 0.4, center.Z)

	local emberRing = ensurePart(runtimeFolder, "CampfireEmberRing", "Part")
	emberRing.Anchored = true
	emberRing.CanCollide = false
	emberRing.CanQuery = false
	emberRing.CanTouch = false
	emberRing.Material = Enum.Material.Ground
	emberRing.Color = Color3.fromRGB(84, 62, 44)
	emberRing.Shape = Enum.PartType.Cylinder
	emberRing.Size = Vector3.new(0.4, 8.2, 8.2)
	emberRing.CFrame = CFrame.new(center.X, center.Y + 0.65, center.Z) * CFrame.Angles(0, 0, math.rad(90))

	local core = ensurePart(runtimeFolder, CAMPFIRE_CORE_NAME, "Part")
	core.Anchored = true
	core.CanCollide = false
	core.CanQuery = false
	core.CanTouch = false
	core.Material = Enum.Material.Neon
	core.Color = Color3.fromRGB(255, 145, 52)
	core.Transparency = 0.15
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(2.2, 2.2, 2.2)
	core.CFrame = CFrame.new(center.X, center.Y + 1.4, center.Z)

	local light = core:FindFirstChild("CampfireLight")
	if not (light and light:IsA("PointLight")) then
		if light then
			light:Destroy()
		end
		light = cloneWorldPointLightTemplate("CampfireLight")
		if light then
			light.Name = "CampfireLight"
			light.Parent = core
		else
			warn("[CampfireSanityService] Missing authored visual template: WorldEffects.WorldPointLightTemplate")
		end
	end
	if light then
		light.Color = Color3.fromRGB(255, 168, 88)
		light.Brightness = 2.1
		light.Range = 24
		light.Shadows = false
		light.Enabled = true
	end

	local fireFx = core:FindFirstChild("CampfireFire")
	if not (fireFx and fireFx:IsA("Fire")) then
		if fireFx then
			fireFx:Destroy()
		end
		fireFx = cloneWorldFireTemplate("CampfireFire")
		if fireFx then
			fireFx.Name = "CampfireFire"
			fireFx.Parent = core
		else
			warn("[CampfireSanityService] Missing authored visual template: WorldEffects.WorldFireTemplate")
		end
	end
	if fireFx then
		fireFx.Color = Color3.fromRGB(255, 158, 68)
		fireFx.SecondaryColor = Color3.fromRGB(255, 218, 122)
		fireFx.Heat = 6
		fireFx.Size = 8
		fireFx.Enabled = true
	end

	for index = 1, CAMPFIRE_SEAT_COUNT do
		local angle = ((index - 1) / CAMPFIRE_SEAT_COUNT) * math.pi * 2
		local seatPosition = center + Vector3.new(math.cos(angle) * CAMPFIRE_SEAT_RADIUS, 0.7, math.sin(angle) * CAMPFIRE_SEAT_RADIUS)
		local seat = ensurePart(runtimeFolder, string.format("CampfireSeat_%d", index), "Seat")
		seat.Anchored = true
		seat.CanCollide = true
		seat.CanQuery = true
		seat.CanTouch = true
		seat.Material = Enum.Material.WoodPlanks
		seat.Color = Color3.fromRGB(116, 84, 56)
		seat.Size = Vector3.new(3.2, 1, 3)
		seat.CFrame = CFrame.lookAt(seatPosition, center)
		seat:SetAttribute("PasrahCampfireSeat", true)

		local backRest = ensurePart(runtimeFolder, string.format("CampfireSeatBack_%d", index), "Part")
		backRest.Anchored = true
		backRest.CanCollide = true
		backRest.CanQuery = true
		backRest.CanTouch = false
		backRest.Material = Enum.Material.WoodPlanks
		backRest.Color = Color3.fromRGB(108, 76, 50)
		backRest.Size = Vector3.new(3.2, 2.2, 0.35)
		backRest.CFrame = seat.CFrame * CFrame.new(0, 1.1, 1.35)
	end

	workspace:SetAttribute(CAMPFIRE_SAFE_RADIUS_ATTRIBUTE, CAMPFIRE_SAFE_RADIUS)
	self:_applyWoodenZoneTheme(lobbyRoot)
end

function CampfireSanityService:Init()
	self:_ensureCampfireWorld()
end

function CampfireSanityService:Start()
	if self._heartbeatConnection then
		return
	end
	self:_ensureCampfireWorld()
	self._heartbeatConnection = RunService.Heartbeat:Connect(function(dt)
		self._elapsed += dt
		if self._elapsed < 0.25 then
			return
		end
		self._elapsed = 0
		self:_restoreSeatedLobbySanity()
	end)
end

function CampfireSanityService:Stop()
	if self._heartbeatConnection then
		self._heartbeatConnection:Disconnect()
		self._heartbeatConnection = nil
	end
	table.clear(self._lastRestoreAtByUserId)
end

return CampfireSanityService

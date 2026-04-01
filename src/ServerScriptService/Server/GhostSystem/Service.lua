local GhostService = require(script.Parent.GhostService)
local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DEFAULT_GHOST_TYPES = {
	"Pocong",
	"Kuntilanak",
	"Genderuwo",
	"Tuyul",
	"Leak",
	"Banaspati",
	"Jerangkong",
	"WeweGombel",
	"Palasik",
	"SilumanUlar",
	"SundelBolong",
	"HantuTanah",
}

local function createGhostRigPart(model, name, size, offset, color)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.CFrame = offset
	part.Parent = model
	return part
end

local function createVisibleGhostPlaceholder(spawnCFrame, ghostType)
	local ghostModel = Instance.new("Model")
	ghostModel.Name = string.format("GhostPlaceholder_%s", tostring(ghostType or "Unknown"))
	ghostModel:SetAttribute("GhostType", ghostType)
	ghostModel:SetAttribute("PlaceholderVisual", true)

	local root = createGhostRigPart(ghostModel, "HumanoidRootPart", Vector3.new(2, 2, 1), spawnCFrame, Color3.fromRGB(80, 86, 96))
	root.Transparency = 1

	local torso = createGhostRigPart(ghostModel, "Torso", Vector3.new(2, 2, 1), spawnCFrame * CFrame.new(0, 0, 0), Color3.fromRGB(168, 176, 188))
	local head = createGhostRigPart(ghostModel, "Head", Vector3.new(2, 1, 1), spawnCFrame * CFrame.new(0, 1.5, 0), Color3.fromRGB(214, 220, 228))
	local leftArm = createGhostRigPart(ghostModel, "Left Arm", Vector3.new(1, 2, 1), spawnCFrame * CFrame.new(-1.5, 0, 0), Color3.fromRGB(160, 168, 182))
	local rightArm = createGhostRigPart(ghostModel, "Right Arm", Vector3.new(1, 2, 1), spawnCFrame * CFrame.new(1.5, 0, 0), Color3.fromRGB(160, 168, 182))
	local leftLeg = createGhostRigPart(ghostModel, "Left Leg", Vector3.new(1, 2, 1), spawnCFrame * CFrame.new(-0.5, -2, 0), Color3.fromRGB(124, 132, 148))
	local rightLeg = createGhostRigPart(ghostModel, "Right Leg", Vector3.new(1, 2, 1), spawnCFrame * CFrame.new(0.5, -2, 0), Color3.fromRGB(124, 132, 148))

	for _, limb in ipairs({ torso, head, leftArm, rightArm, leftLeg, rightLeg }) do
		limb.CastShadow = false
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "GhostHumanoid"
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.Parent = ghostModel

	ghostModel.PrimaryPart = root
	return ghostModel
end

local GHOST_RETRY_COUNT = 3
local GHOST_RETRY_WAIT = 0.05

local function safeRequire(moduleScript)
	if not moduleScript then
		return nil
	end
	local ok, result = pcall(require, moduleScript)
	if ok then
		return result
	end
	return nil
end

local function resolveSharedGameDataModule(moduleName)
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:FindFirstChild("shared")
	if not shared then
		return nil
	end
	local gameData = shared:FindFirstChild("GameData")
	if not gameData then
		return nil
	end
	return gameData:FindFirstChild(moduleName)
end

local function loadMapDatabase()
	local database = safeRequire(resolveSharedGameDataModule("MapConfig"))
	if type(database) == "table" then
		return database
	end
	return {}
end

local function loadGhostDatabase()
	local database = safeRequire(resolveSharedGameDataModule("GhostDatabase"))
	if type(database) == "table" then
		return database
	end
	return {}
end

local function resolveInvestigationToolService(deps)
	local evidenceSystem = Services.Get(deps, "EvidenceSystem")
	if type(evidenceSystem) ~= "table" then
		return nil
	end
	if type(evidenceSystem.TryConsumeHuntProtection) == "function" then
		return evidenceSystem
	end
	if type(evidenceSystem.Service) == "table" and type(evidenceSystem.Service.TryConsumeHuntProtection) == "function" then
		return evidenceSystem.Service
	end
	return nil
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for key, nested in pairs(value) do
		out[key] = deepCopy(nested)
	end
	return out
end

local function resolveMatchId(matchOrId)
	if type(matchOrId) == "string" then
		return matchOrId
	end
	if type(matchOrId) == "table" then
		return matchOrId.matchId or matchOrId.id
	end
	return nil
end

local function collectSpawnParts(root)
	local parts = {}
	if not root then
		return parts
	end
	for _, child in ipairs(root:GetDescendants()) do
		if child:IsA("BasePart") then
			table.insert(parts, child)
		end
	end
	return parts
end

local function resolveSpawnPart(container)
	if not container then
		return nil
	end
	local direct = container:FindFirstChild("GhostSpawn") or container:FindFirstChild("GhostSpawns")
	if direct then
		local parts = collectSpawnParts(direct)
		if #parts > 0 then
			return parts[1]
		end
	end
	local fallbackFolder = container:FindFirstChild("SpawnPoints") or container:FindFirstChild("GhostSpawnPoints")
	if fallbackFolder then
		local parts = collectSpawnParts(fallbackFolder)
		if #parts > 0 then
			return parts[1]
		end
	end
	local parts = collectSpawnParts(container)
	if #parts > 0 then
		return parts[1]
	end
	return nil
end

local function ensureActiveMatchesFolder()
	local folder = Workspace:FindFirstChild("ActiveMatches")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "ActiveMatches"
		folder.Parent = Workspace
	end
	return folder
end

local function resolveMatchContainer(match)
	if type(match) ~= "table" then
		return nil
	end
	local matchId = match.matchId or match.id
	if not matchId then
		return nil
	end
	local activeMatches = ensureActiveMatchesFolder()
	local expectedName = "Match_" .. tostring(matchId)
	local container = match.container
	if container and (not container:IsA("Folder") or container.Parent ~= activeMatches or container.Name ~= expectedName) then
		container = nil
	end
	if not container then
		container = activeMatches:FindFirstChild(expectedName)
	end
	if not container then
		container = Instance.new("Folder")
		container.Name = expectedName
		container.Parent = activeMatches
	end
	match.container = container
	return container, activeMatches
end

local function ensureGhostPlacement(match)
	if not (match and match.ghost) then
		return false
	end
	local container = match.container
	if not container then
		container = resolveMatchContainer(match)
	end
	if not container then
		return false
	end
	if match.ghost.Parent ~= container then
		match.ghost.Parent = container
	end
	return true
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._ghostService = GhostService.new(self._state, self._deps)
	self._investigationToolService = resolveInvestigationToolService(self._deps)
	self._matchSystem = Services.Get(self._deps, "MatchSystem")
	self._mapDatabase = loadMapDatabase()
	self._ghostDatabase = loadGhostDatabase()
	return self
end

function Service:Init()
	self._ghostService:Init()
end

function Service:Start()
	self._ghostService:Start()
end

function Service:Stop()
	self._ghostService:Stop()
end

function Service:_getMatchSystem()
	if self._matchSystem then
		return self._matchSystem
	end
	self._matchSystem = Services.Get(self._deps, "MatchSystem")
	return self._matchSystem
end

function Service:_resolveLiveMatch(matchOrId)
	local matchId = resolveMatchId(matchOrId)
	local matchData = type(matchOrId) == "table" and matchOrId or nil
	if not matchId then
		return nil, nil
	end

	if type(matchData) == "table" and matchData.playersByUserId and matchData.history then
		return matchData, matchId
	end

	local matchSystem = self:_getMatchSystem()
	if not matchSystem then
		return matchData, matchId
	end

	if type(matchSystem.GetLiveMatch) == "function" then
		return matchSystem:GetLiveMatch(matchId) or matchData, matchId
	end
	if type(matchSystem.Service) == "table" and type(matchSystem.Service.GetLiveMatch) == "function" then
		return matchSystem.Service:GetLiveMatch(matchId) or matchData, matchId
	end

	return matchData, matchId
end

function Service:_getMapDefinition(mapId)
	if type(mapId) ~= "string" or mapId == "" then
		return nil
	end
	local direct = self._mapDatabase[mapId]
	if type(direct) == "table" then
		return direct
	end
	local token = string.lower(mapId:gsub("[%s_%-%.]+", ""))
	for key, value in pairs(self._mapDatabase) do
		if string.lower(tostring(key):gsub("[%s_%-%.]+", "")) == token and type(value) == "table" then
			return value
		end
	end
	return nil
end

function Service:_buildGhostPayload(match, payload)
	local incoming = type(payload) == "table" and payload or {}
	local mapDefinition = self:_getMapDefinition(match and (match.mapId or match.map) or incoming.mapId)
	local ghostType = incoming.ghostType or (match and match.ghostType) or "Pocong"
	local ghostTypeData = incoming.ghostTypeData or self._ghostDatabase[ghostType]

	local roomIds = incoming.roomIds
		or (match and match.roomIds)
		or (mapDefinition and mapDefinition.rooms)
		or (mapDefinition and mapDefinition.ghostRoomCandidates)
		or {}

	return {
		roomIds = deepCopy(roomIds),
		roomGraph = incoming.roomGraph,
		roomSpawnRules = incoming.roomSpawnRules,
		ghostType = ghostType,
		ghostTypeData = ghostTypeData,
		personality = incoming.personality,
		personalityType = incoming.personalityType,
		evidenceSet = incoming.evidenceSet,
		initialAggression = incoming.initialAggression,
		difficulty = incoming.difficulty or (match and match.difficulty),
		mode = incoming.mode or incoming.gameMode or (match and (match.mode or match.gameMode)),
		gameMode = incoming.gameMode or incoming.mode or (match and (match.gameMode or match.mode)),
		difficultyProfile = deepCopy(incoming.difficultyProfile or (match and match.difficultyProfile) or {}),
		favoriteRoomId = incoming.favoriteRoomId,
		now = incoming.now,
	}
end

function Service:_ensureGhostReady(matchOrId, payload)
	local liveMatch, matchId = self:_resolveLiveMatch(matchOrId)
	if not matchId then
		return nil, nil, "missing_match_id"
	end

	local lastReason = nil
	for _ = 1, GHOST_RETRY_COUNT do
		if type(liveMatch) == "table" and not liveMatch.ghost then
			local _, initializeReason = self:InitializeMatch(liveMatch)
			if initializeReason then
				lastReason = initializeReason
			end
		end

		if self._ghostService:GetGhostState(matchId) == nil then
			local spawnedSession = self._ghostService:SpawnGhost(matchId, self:_buildGhostPayload(liveMatch, payload))
			if not spawnedSession then
				lastReason = lastReason or "spawn_returned_nil"
			end
		end

		if type(liveMatch) == "table" and liveMatch.ghost then
			ensureGhostPlacement(liveMatch)
			if liveMatch.ghostSpawnPart == nil then
				self:SelectGhostRoom(liveMatch)
			end
		end

		if self._ghostService:GetGhostState(matchId) ~= nil then
			return liveMatch, matchId, nil
		end

		task.wait(GHOST_RETRY_WAIT)
		liveMatch = select(1, self:_resolveLiveMatch(matchId)) or liveMatch
	end

	warn(string.format("[GhostSystem] Failed to ensure ghost for match %s (%s)", tostring(matchId), tostring(lastReason or "unknown")))
	return liveMatch, matchId, lastReason or "ghost_spawn_failed"
end

function Service:InitGhost(matchId, payload)
	local liveMatch, _, err = self:_ensureGhostReady(matchId, payload)
	if err then
		return nil, err
	end
	return liveMatch
end

function Service:SpawnGhost(match, payload)
	local liveMatch, _, err = self:_ensureGhostReady(match, payload)
	if err then
		return nil, err
	end
	return liveMatch
end

function Service:SelectGhostRoom(match)
	if type(match) ~= "table" or not match.ghost then
		return nil, "missing_ghost"
	end
	if not ensureGhostPlacement(match) then
		return nil, "missing_container"
	end
	local container = match.container
	if not container then
		return nil, "missing_container"
	end
	local ghostSpawns = container:FindFirstChild("GhostSpawns") or container:FindFirstChild("GhostSpawnZones")
	local spawnParts = collectSpawnParts(ghostSpawns)
	if #spawnParts == 0 then
		local fallbackSpawn = resolveSpawnPart(container)
		if fallbackSpawn then
			spawnParts = { fallbackSpawn }
		end
	end
	if #spawnParts == 0 then
		return nil, "no_spawn_parts"
	end
	local seed = tonumber(match.ghostSeed) or os.time()
	local rng = Random.new(seed + 1)
	local selectedPart = spawnParts[rng:NextInteger(1, #spawnParts)]
	if not selectedPart then
		return nil, "missing_selected_part"
	end
	local ghostRoom = selectedPart.Parent or ghostSpawns
	match.ghostRoom = ghostRoom
	match.ghostSpawnPart = selectedPart
	if match.ghost.PrimaryPart then
		match.ghost:SetPrimaryPartCFrame(selectedPart.CFrame)
	end
	return selectedPart
end

function Service:InitializeMatch(match)
	if type(match) ~= "table" then
		return nil, "invalid_match"
	end
	if match.ghost then
		return match.ghost
	end
	local matchId = match.matchId or match.id
	if not matchId then
		return nil, "missing_match_id"
	end
	local seed = tonumber(match.ghostSeed) or os.time()
	local rng = Random.new(seed)
	local ghostType = match.ghostType or DEFAULT_GHOST_TYPES[rng:NextInteger(1, #DEFAULT_GHOST_TYPES)]
	match.ghostType = ghostType

	local container = resolveMatchContainer(match)
	if not container then
		return nil, "missing_match_container"
	end

	local spawnPart = resolveSpawnPart(container)
	local spawnCFrame = spawnPart and spawnPart.CFrame or CFrame.new(0, 5, 0)

	local ghostModel = createVisibleGhostPlaceholder(spawnCFrame, ghostType)
	ghostModel.Parent = container

	match.ghost = ghostModel

	self:SelectGhostRoom(match)

	return ghostModel
end

function Service:OnSanityCritical(matchId)
	if not matchId then
		return nil, "missing_match_id"
	end
	return self:_startProtectedHunt(matchId, {}, os.clock())
end

function Service:OnAggressionThreshold(matchId)
	if not matchId then
		return nil, "missing_match_id"
	end
	return self:_startProtectedHunt(matchId, {}, os.clock())
end

function Service:_startProtectedHunt(match, snapshot, now)
	local _, authoritativeMatchId, err = self:_ensureGhostReady(match)
	if err then
		return nil, err
	end

	if self._investigationToolService and type(self._investigationToolService.TryConsumeHuntProtection) == "function" then
		local ghostState = self._ghostService:GetGhostState(authoritativeMatchId) or {}
		local ok, blocked = pcall(function()
			return self._investigationToolService:TryConsumeHuntProtection(authoritativeMatchId, {
				now = now or os.clock(),
				roomId = ghostState.currentRoomId or ghostState.favoriteRoomId or (snapshot and snapshot.roomId),
				snapshot = snapshot,
			})
		end)
		if ok and blocked == true then
			return false, "hunt_blocked"
		end
	end

	return self._ghostService:StartHunt(authoritativeMatchId, snapshot or {}, now)
end

function Service:TransitionGhostState(matchId, stateName, now, snapshot)
	if not matchId then
		return nil, "missing_match_id"
	end
	local _, authoritativeMatchId, err = self:_ensureGhostReady(matchId)
	if err then
		return nil, err
	end
	return self._ghostService:TransitionGhostState(authoritativeMatchId, stateName, now, snapshot)
end

function Service:TickGhost(match, snapshot, dt, now)
	local _, matchId, err = self:_ensureGhostReady(match)
	if err then
		return nil, err
	end
	return self._ghostService:TickGhost(matchId, snapshot, dt, now)
end

function Service:StartHunt(match, snapshot, now)
	return self:_startProtectedHunt(match, snapshot, now)
end

function Service:TriggerHunt(match, snapshot, now)
	local liveMatch, matchId, err = self:_ensureGhostReady(match)
	if err then
		return nil, err
	end
	return self:_startProtectedHunt(matchId, snapshot or (liveMatch and liveMatch.snapshot) or {}, now)
end

function Service:ForceHunt(match, snapshot, now)
	local _, matchId, err = self:_ensureGhostReady(match)
	if err then
		return nil, err
	end
	return self._ghostService:StartHunt(matchId, snapshot or {}, now)
end

function Service:EndHunt(match, now)
	local _, matchId = self:_resolveLiveMatch(match)
	if not matchId then
		return nil, "missing_match_id"
	end
	return self._ghostService:EndHunt(matchId, now)
end

function Service:GetGhostState(match)
	local _, matchId, err = self:_ensureGhostReady(match)
	if err then
		return nil, err
	end
	return self._ghostService:GetGhostState(matchId)
end

function Service:DespawnGhost(match)
	local matchData, matchId = self:_resolveLiveMatch(match)
	if not matchId then
		warn("[GhostSystem] Missing match id for DespawnGhost")
		return nil, "missing_match_id"
	end

	if matchData and matchData.ghost then
		local ghostModel = matchData.ghost
		matchData.ghost = nil
		matchData.ghostRoom = nil
		matchData.ghostSpawnPart = nil
		if ghostModel and ghostModel.Parent then
			for _, part in ipairs(ghostModel:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = 1
				end
			end
			ghostModel:Destroy()
		end
	end

	return self._ghostService:DespawnGhost(matchId)
end

function Service:ApplyDirectorEvent(match, eventName, payload)
	local _, matchId, err = self:_ensureGhostReady(match)
	if err then
		return nil, err
	end
	return self._ghostService:ApplyDirectorEvent(matchId, eventName, payload)
end

function Service:ForceManifest(match, now)
	local _, matchId, err = self:_ensureGhostReady(match)
	if err then
		return nil, err
	end
	return self._ghostService:ForceManifest(matchId, now)
end

return Service

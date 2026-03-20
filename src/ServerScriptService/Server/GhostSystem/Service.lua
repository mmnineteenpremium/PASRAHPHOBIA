local GhostService = require(script.Parent.GhostService)
local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local Workspace = game:GetService("Workspace")

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

local function guardGhost(match)
	if not match or not match.ghost then
		warn("[GhostSystem] Missing ghost for match")
		return false
	end
	return true
end

local function ensureGhostPlacement(match)
	if not guardGhost(match) then
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
	self._matchSystem = Services.Get(self._deps, "MatchSystem")
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

function Service:InitGhost(matchId, payload)
	if not matchId then
		return nil, "missing_match_id"
	end
	return self._ghostService:SpawnGhost(matchId, payload or {})
end

function Service:SpawnGhost(match, payload)
	if type(match) ~= "table" then
		warn("[GhostSystem] Missing match for SpawnGhost")
		return nil, "invalid_match"
	end
	local matchId = match.matchId or match.id
	if not matchId then
		warn("[GhostSystem] Missing match id for SpawnGhost")
		return nil, "missing_match_id"
	end
	return self._ghostService:SpawnGhost(matchId, payload)
end

function Service:SelectGhostRoom(match)
	if not guardGhost(match) then
		return nil, "missing_ghost"
	end
	if not ensureGhostPlacement(match) then
		return nil, "missing_container"
	end
	local container = match.container
	if not container then
		return nil, "missing_container"
	end
	local ghostSpawns = container:FindFirstChild("GhostSpawns")
	if not ghostSpawns then
		return nil, "missing_ghost_spawns"
	end
	local spawnParts = collectSpawnParts(ghostSpawns)
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
	local ghostTypes = { "Wraith", "Shade", "Oni", "Yurei", "Banshee", "Revenant" }
	local seed = tonumber(match.ghostSeed) or os.time()
	local rng = Random.new(seed)
	local ghostType = ghostTypes[rng:NextInteger(1, #ghostTypes)]
	match.ghostType = ghostType

	local container = resolveMatchContainer(match)
	if not container then
		return nil, "missing_match_container"
	end

	local spawnPart = resolveSpawnPart(container)
	local spawnCFrame = spawnPart and spawnPart.CFrame or CFrame.new(0, 5, 0)

	local ghostModel = Instance.new("Model")
	ghostModel.Name = "Ghost"
	ghostModel.Parent = container
	ghostModel:SetAttribute("GhostType", ghostType)

	local core = Instance.new("Part")
	core.Name = "GhostCore"
	core.Size = Vector3.new(2, 2, 2)
	core.Anchored = true
	core.CanCollide = false
	core.Transparency = 1
	core.CFrame = spawnCFrame
	core.Parent = ghostModel
	ghostModel.PrimaryPart = core

	match.ghost = ghostModel

	self:SelectGhostRoom(match)

	return ghostModel
end

function Service:OnSanityCritical(matchId)
	if not matchId then
		return nil, "missing_match_id"
	end
	return self._ghostService:StartHunt(matchId, {}, os.clock())
end

function Service:OnAggressionThreshold(matchId)
	if not matchId then
		return nil, "missing_match_id"
	end
	return self._ghostService:StartHunt(matchId, {}, os.clock())
end

function Service:TransitionGhostState(matchId, stateName, now, snapshot)
	if not matchId then
		return nil, "missing_match_id"
	end
	return self._ghostService:TransitionGhostState(matchId, stateName, now, snapshot)
end

function Service:TickGhost(match, snapshot, dt, now)
	if not guardGhost(match) then
		return nil, "missing_ghost"
	end
	local matchId = match.matchId or match.id
	if not matchId then
		warn("[GhostSystem] Missing match id for TickGhost")
		return nil, "missing_match_id"
	end
	return self._ghostService:TickGhost(matchId, snapshot, dt, now)
end

function Service:StartHunt(match, snapshot, now)
	if not guardGhost(match) then
		return nil, "missing_ghost"
	end
	local matchId = match.matchId or match.id
	if not matchId then
		warn("[GhostSystem] Missing match id for StartHunt")
		return nil, "missing_match_id"
	end
	return self._ghostService:StartHunt(matchId, snapshot, now)
end

function Service:TriggerHunt(match, snapshot, now)
	if not guardGhost(match) then
		return nil, "missing_ghost"
	end
	local matchId = match.matchId or match.id
	if not matchId then
		warn("[GhostSystem] Missing match id for TriggerHunt")
		return nil, "missing_match_id"
	end
	return self._ghostService:StartHunt(matchId, snapshot or match.snapshot or {}, now)
end

function Service:EndHunt(match, now)
	if not guardGhost(match) then
		return nil, "missing_ghost"
	end
	local matchId = match.matchId or match.id
	if not matchId then
		warn("[GhostSystem] Missing match id for EndHunt")
		return nil, "missing_match_id"
	end
	return self._ghostService:EndHunt(matchId, now)
end

function Service:GetGhostState(match)
	if not guardGhost(match) then
		return nil, "missing_ghost"
	end
	local matchId = match.matchId or match.id
	if not matchId then
		warn("[GhostSystem] Missing match id for GetGhostState")
		return nil, "missing_match_id"
	end
	return self._ghostService:GetGhostState(matchId)
end

function Service:DespawnGhost(match)
	local matchId = nil
	local matchData = nil
	if type(match) == "table" then
		matchId = match.matchId or match.id
		matchData = match
	elseif type(match) == "string" then
		matchId = match
	end

	if not matchId then
		warn("[GhostSystem] Missing match id for DespawnGhost")
		return nil, "missing_match_id"
	end

	if not matchData and self._matchSystem then
		if type(self._matchSystem.GetMatch) == "function" then
			matchData = self._matchSystem:GetMatch(matchId)
		elseif type(self._matchSystem.Service) == "table" and type(self._matchSystem.Service.GetMatch) == "function" then
			matchData = self._matchSystem.Service:GetMatch(matchId)
		end
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
	if not guardGhost(match) then
		return nil, "missing_ghost"
	end
	local matchId = match.matchId or match.id
	if not matchId then
		warn("[GhostSystem] Missing match id for ApplyDirectorEvent")
		return nil, "missing_match_id"
	end
	return self._ghostService:ApplyDirectorEvent(matchId, eventName, payload)
end

function Service:ForceManifest(match, now)
	if not guardGhost(match) then
		return nil, "missing_ghost"
	end
	local matchId = match.matchId or match.id
	if not matchId then
		warn("[GhostSystem] Missing match id for ForceManifest")
		return nil, "missing_match_id"
	end
	return self._ghostService:ForceManifest(matchId, now)
end

return Service

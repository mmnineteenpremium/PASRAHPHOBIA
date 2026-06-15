local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Services = require(script.Parent.Parent.Core.Services)
local OwnerCheatConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("OwnerCheatConfig"))

local OwnerCheatSystem = {}
OwnerCheatSystem.__index = OwnerCheatSystem

local REMOTE_FOLDER_NAME = "RemoteEvents"
local REMOTE_NAME = "OwnerCheatEvent"
local ROLE_STORE_NAME = "OwnerCheatRoles"

local GHOST_SFX_BY_TYPE = {
	Banaspati = "rbxassetid://77042021520991",
	Genderuwo = "rbxassetid://127220449004274",
	HantuTanah = "rbxassetid://133222140058153",
	Jerangkong = "rbxassetid://107677780610227",
	Kuntilanak = "rbxassetid://118997816874431",
	Leak = "rbxassetid://137119373988694",
	Palasik = "rbxassetid://94238755962872",
	Pocong = "rbxassetid://100251836150714",
	SilumanUlar = "rbxassetid://78766807826090",
	SundelBolong = "rbxassetid://137824753785141",
	Tuyul = "rbxassetid://89416140557652",
	WeweGombel = "rbxassetid://120515818081490",
}

local VALID_PHASES = {
	PreparationPhase = true,
	InvestigationPhase = true,
	HuntPhase = true,
	EndgamePhase = true,
}

local function ensureRemote()
	local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = REMOTE_FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end

	local remote = folder:FindFirstChild(REMOTE_NAME)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	if remote then
		remote:Destroy()
	end

	remote = Instance.new("RemoteEvent")
	remote.Name = REMOTE_NAME
	remote.Parent = folder
	return remote
end

local function copyArray(values)
	local out = {}
	for index, value in ipairs(values or {}) do
		out[index] = value
	end
	return out
end

local function copyMap(source)
	local out = {}
	for key, value in pairs(source or {}) do
		out[key] = value
	end
	return out
end

local function safeRequire(moduleScript)
	if not (moduleScript and moduleScript:IsA("ModuleScript")) then
		return nil
	end
	local ok, result = pcall(require, moduleScript)
	return ok and result or nil
end

local function childPath(root, path)
	local node = root
	for _, segment in ipairs(path or {}) do
		if typeof(node) ~= "Instance" then
			return nil
		end
		node = node:FindFirstChild(segment)
		if not node then
			return nil
		end
	end
	return node
end

local function unwrapService(deps, name, methodName)
	local service = Services.Get(deps, name)
	if type(service) ~= "table" then
		return nil
	end
	if type(service[methodName]) == "function" then
		return service
	end
	if type(service.Service) == "table" and type(service.Service[methodName]) == "function" then
		return service.Service
	end
	return service
end

local function normalizeGhostType(value)
	if type(value) ~= "string" then
		return nil
	end
	local token = value:gsub("^%s+", ""):gsub("%s+$", "")
	if token == "" then
		return nil
	end
	for _, ghostType in ipairs(OwnerCheatConfig.CANONICAL_GHOSTS) do
		if ghostType:lower() == token:lower() then
			return ghostType
		end
	end
	return nil
end

local function normalizeItemId(value)
	if type(value) ~= "string" then
		return nil
	end
	local id = value:gsub("^%s+", ""):gsub("%s+$", "")
	return id ~= "" and id or nil
end

local function getPlayerMatchId(player, payload)
	if type(payload) == "table" and type(payload.matchId) == "string" and payload.matchId ~= "" then
		return payload.matchId
	end
	if typeof(player) == "Instance" and player:IsA("Player") then
		for _, attributeName in ipairs({ "MatchId", "CurrentMatchId", "PasrahMatchId" }) do
			local matchId = player:GetAttribute(attributeName)
			if type(matchId) == "string" and matchId ~= "" then
				return matchId
			end
		end
	end
	return nil
end

local function findBasePartByName(root, names)
	if typeof(root) ~= "Instance" then
		return nil
	end
	local wanted = {}
	for _, name in ipairs(names or {}) do
		if type(name) == "string" and name ~= "" then
			wanted[name:lower()] = true
		end
	end
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") and wanted[descendant.Name:lower()] == true then
			return descendant
		end
	end
	return nil
end

function OwnerCheatSystem.new(deps)
	local self = setmetatable({}, OwnerCheatSystem)
	self._deps = deps or {}
	self._remote = nil
	self._connection = nil
	self._playerAddedConnection = nil
	self._playerRemovingConnection = nil
	self._roles = {
		ownerUserId = OwnerCheatConfig.DEFAULT_OWNER_USER_ID,
		qaUserIds = {},
		updatedAt = os.time(),
	}
	self._throttle = {}
	self._ghostScaleBaselines = setmetatable({}, { __mode = "k" })
	return self
end

function OwnerCheatSystem:Init()
	self._matchSystem = unwrapService(self._deps, "MatchSystem", "CreateMatch")
	self._ghostSystem = unwrapService(self._deps, "GhostSystem", "SpawnGhost")
	self._shopSystem = unwrapService(self._deps, "ShopSystem", "GrantItem")
	self._inventorySystem = unwrapService(self._deps, "InventorySystem", "GrantItem")
	self._cosmeticSystem = unwrapService(self._deps, "CosmeticSystem", "EquipCosmetic")
	self._eventBus = unwrapService(self._deps, "EventBus", "Publish")
	self:_loadRoles()
end

function OwnerCheatSystem:Start()
	self._remote = ensureRemote()
	self._connection = self._remote.OnServerEvent:Connect(function(player, request)
		self:_onRequest(player, request)
	end)
	self._playerAddedConnection = Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			self:_sendSnapshot(player, "PlayerAdded")
		end)
	end)
	self._playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
		self._throttle[player.UserId] = nil
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.defer(function()
			self:_sendSnapshot(player, "Start")
		end)
	end
	ReplicatedStorage:SetAttribute("PasrahOwnerCheatReady", true)
end

function OwnerCheatSystem:Shutdown()
	if self._connection then
		self._connection:Disconnect()
		self._connection = nil
	end
	if self._playerAddedConnection then
		self._playerAddedConnection:Disconnect()
		self._playerAddedConnection = nil
	end
	if self._playerRemovingConnection then
		self._playerRemovingConnection:Disconnect()
		self._playerRemovingConnection = nil
	end
	ReplicatedStorage:SetAttribute("PasrahOwnerCheatReady", nil)
end

function OwnerCheatSystem:_getStore()
	local ok, store = pcall(function()
		return DataStoreService:GetDataStore(ROLE_STORE_NAME)
	end)
	return ok and store or nil
end

function OwnerCheatSystem:_loadRoles()
	local store = self:_getStore()
	if not store then
		return
	end
	local ok, data = pcall(function()
		return store:GetAsync(OwnerCheatConfig.DATASTORE_KEY)
	end)
	if ok and type(data) == "table" and tonumber(data.ownerUserId) then
		self._roles.ownerUserId = tonumber(data.ownerUserId)
		self._roles.qaUserIds = type(data.qaUserIds) == "table" and data.qaUserIds or {}
		self._roles.updatedAt = tonumber(data.updatedAt) or os.time()
	end
end

function OwnerCheatSystem:_saveRoles()
	local store = self:_getStore()
	if not store then
		return false, RunService:IsStudio() and "datastore_unavailable_studio_fallback" or "datastore_unavailable"
	end
	local snapshot = {
		ownerUserId = self._roles.ownerUserId,
		qaUserIds = copyMap(self._roles.qaUserIds),
		updatedAt = os.time(),
	}
	local ok, err = pcall(function()
		store:SetAsync(OwnerCheatConfig.DATASTORE_KEY, snapshot)
	end)
	return ok, ok and nil or tostring(err)
end

function OwnerCheatSystem:_getRole(player)
	if not (typeof(player) == "Instance" and player:IsA("Player")) then
		return OwnerCheatConfig.ROLES.NONE
	end
	if player.UserId == self._roles.ownerUserId then
		return OwnerCheatConfig.ROLES.OWNER
	end
	if self._roles.qaUserIds[tostring(player.UserId)] == true then
		return OwnerCheatConfig.ROLES.QA
	end
	return OwnerCheatConfig.ROLES.NONE
end

function OwnerCheatSystem:_rolePayload(player)
	local role = self:_getRole(player)
	local qa = {}
	for userId in pairs(self._roles.qaUserIds or {}) do
		table.insert(qa, tonumber(userId) or userId)
	end
	table.sort(qa, function(a, b)
		return tostring(a) < tostring(b)
	end)
	return {
		role = role,
		authorized = role == OwnerCheatConfig.ROLES.OWNER or role == OwnerCheatConfig.ROLES.QA,
		isOwner = role == OwnerCheatConfig.ROLES.OWNER,
		ownerUserId = self._roles.ownerUserId,
		qaUserIds = qa,
	}
end

function OwnerCheatSystem:_buildCatalogSnapshot()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local shopCatalog = safeRequire(childPath(shared, { "DataTypes", "ShopCatalog" })) or {}
	local cosmeticRegistry = safeRequire(childPath(shared, { "Config", "CosmeticRegistry" })) or {}
	local royalPass = safeRequire(childPath(shared, { "Config", "RoyalPassConfig" })) or {}
	local mapConfig = safeRequire(childPath(shared, { "GameData", "MapConfig" })) or {}

	local items = {}
	local seen = {}

	local function addItem(id, label, category, source, extra)
		id = normalizeItemId(id)
		if not id or seen[source .. ":" .. id] then
			return
		end
		seen[source .. ":" .. id] = true
		table.insert(items, {
			id = id,
			label = label or id,
			category = category or "TestItem",
			source = source,
			slot = type(extra) == "table" and extra.slot or nil,
			track = type(extra) == "table" and extra.track or nil,
			tier = type(extra) == "table" and extra.tier or nil,
		})
	end

	for _, entry in ipairs(shopCatalog) do
		if type(entry) == "table" then
			addItem(entry.id, entry.name, entry.category, "ShopCatalog", entry)
		end
	end
	for _, rewardId in ipairs(type(cosmeticRegistry.GetAllRewardIds) == "function" and cosmeticRegistry.GetAllRewardIds() or {}) do
		local entry = cosmeticRegistry.Get(rewardId)
		addItem(rewardId, rewardId, type(entry) == "table" and entry.type or "Reward", "CosmeticRegistry", entry)
	end
	for _, tierConfig in pairs(type(royalPass.TIERS) == "table" and royalPass.TIERS or {}) do
		for trackName, reward in pairs({ FREE = tierConfig.free, PREMIUM = tierConfig.premium }) do
			if type(reward) == "table" then
				for key, value in pairs(reward) do
					if type(key) == "string" and key:match("Id$") then
						addItem(value, tostring(value), key, "RoyalPass", {
							track = trackName,
							tier = tierConfig.tier,
						})
					end
				end
			end
		end
	end

	local maps = {}
	for mapId, mapData in pairs(mapConfig) do
		if type(mapData) == "table" then
			table.insert(maps, {
				id = tostring(mapId),
				label = tostring(mapData.mapName or mapId),
				areas = copyArray(mapData.ghostRoomCandidates or mapData.rooms or {}),
			})
		end
	end
	table.sort(maps, function(a, b)
		return tostring(a.label) < tostring(b.label)
	end)
	table.sort(items, function(a, b)
		return tostring(a.label) < tostring(b.label)
	end)

	return {
		items = items,
		ghosts = copyArray(OwnerCheatConfig.CANONICAL_GHOSTS),
		animations = copyArray(OwnerCheatConfig.GHOST_ANIMATIONS),
		spawnLocations = copyArray(OwnerCheatConfig.GHOST_SPAWN_LOCATIONS),
		sfxByGhost = copyMap(GHOST_SFX_BY_TYPE),
		maps = maps,
	}
end

function OwnerCheatSystem:_sendSnapshot(player, reason)
	if not self._remote then
		return
	end
	local rolePayload = self:_rolePayload(player)
	if not rolePayload.authorized then
		self._remote:FireClient(player, {
			eventName = "OwnerCheatSnapshot",
			authorized = false,
			role = rolePayload.role,
			reason = reason,
		})
		return
	end
	rolePayload.eventName = "OwnerCheatSnapshot"
	rolePayload.reason = reason
	rolePayload.catalog = self:_buildCatalogSnapshot()
	self._remote:FireClient(player, rolePayload)
end

function OwnerCheatSystem:_ack(player, request, ok, result, data)
	if not self._remote then
		return
	end
	local payload = type(data) == "table" and data or {}
	payload.eventName = "OwnerCheatAck"
	payload.requestId = type(request) == "table" and request.requestId or nil
	payload.action = type(request) == "table" and request.action or nil
	payload.ok = ok == true
	payload.result = result
	payload.role = self:_getRole(player)
	self._remote:FireClient(player, payload)
end

function OwnerCheatSystem:_isThrottled(player)
	local cfg = OwnerCheatConfig.THROTTLE
	local now = os.clock()
	local bucket = self._throttle[player.UserId]
	if type(bucket) ~= "table" or now - bucket.windowStart > cfg.WINDOW_SECONDS then
		self._throttle[player.UserId] = {
			windowStart = now,
			count = 1,
		}
		return false
	end
	bucket.count += 1
	return bucket.count > cfg.BURST
end

function OwnerCheatSystem:_validate(player, action)
	if not OwnerCheatConfig.IsAllowedAction(action) then
		return false, "unsupported_action"
	end
	if self:_isThrottled(player) then
		return false, "throttled"
	end
	local role = self:_getRole(player)
	if OwnerCheatConfig.IsOwnerOnlyAction(action) then
		return role == OwnerCheatConfig.ROLES.OWNER, "owner_only"
	end
	return role == OwnerCheatConfig.ROLES.OWNER or role == OwnerCheatConfig.ROLES.QA, "not_authorized"
end

function OwnerCheatSystem:_resolveUserId(value)
	local userId = tonumber(value)
	if userId and userId > 0 then
		return math.floor(userId)
	end
	if type(value) == "string" and value ~= "" then
		local ok, result = pcall(function()
			return Players:GetUserIdFromNameAsync(value)
		end)
		if ok and tonumber(result) then
			return tonumber(result)
		end
	end
	return nil
end

function OwnerCheatSystem:_resolveLiveMatch(player, payload)
	local matchId = getPlayerMatchId(player, payload)
	if not matchId or type(self._matchSystem) ~= "table" or type(self._matchSystem.GetLiveMatch) ~= "function" then
		return nil, matchId, matchId and "missing_match_system" or "missing_match_id"
	end
	local ok, liveMatch = pcall(function()
		return self._matchSystem:GetLiveMatch(matchId)
	end)
	if ok and type(liveMatch) == "table" then
		return liveMatch, matchId, nil
	end
	return nil, matchId, "missing_live_match"
end

function OwnerCheatSystem:_moveGhostToArea(player, liveMatch, payload)
	if type(liveMatch) ~= "table" or typeof(liveMatch.ghost) ~= "Instance" then
		return false, "missing_ghost"
	end
	local area = type(payload) == "table" and tostring(payload.area or payload.roomId or "") or ""
	local spawnMode = type(payload) == "table" and tostring(payload.spawnMode or payload.location or "") or ""
	local frontMode = spawnMode == "in_front"
	if frontMode then
		local character = player and player.Character
		local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
		if typeof(root) ~= "Instance" or not root:IsA("BasePart") then
			return false, "missing_character"
		end
		local distance = tonumber(OwnerCheatConfig.GHOST_FRONT_SPAWN_DISTANCE_STUDS) or 4.3
		liveMatch.ghost:PivotTo(root.CFrame * CFrame.new(0, 0, -distance))
		liveMatch.ghost:SetAttribute("OwnerCheatSpawnMode", spawnMode)
		liveMatch.ghost:SetAttribute("OwnerCheatArea", area)
		return true
	end
	if area == "" or typeof(liveMatch.container) ~= "Instance" then
		liveMatch.ghost:SetAttribute("OwnerCheatSpawnMode", "in_place")
		return true
	end
	local part = findBasePartByName(liveMatch.container, { area, "Room_" .. area, area .. "Spawn", "GhostSpawn_" .. area })
	if not part then
		return false, "missing_area"
	end
	liveMatch.ghost:PivotTo(CFrame.new(part.Position + Vector3.new(0, 2.5, 0)))
	liveMatch.ghost:SetAttribute("OwnerCheatSpawnMode", "in_place")
	liveMatch.ghost:SetAttribute("OwnerCheatArea", area)
	return true
end

function OwnerCheatSystem:_captureScaleBaseline(model)
	local existing = self._ghostScaleBaselines[model]
	if existing then
		return existing
	end
	local pivot = model:GetPivot()
	local records = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(records, {
				part = descendant,
				size = descendant.Size,
				relative = pivot:ToObjectSpace(descendant.CFrame),
			})
		end
	end
	self._ghostScaleBaselines[model] = records
	return records
end

function OwnerCheatSystem:_applyGhostScale(model, scale)
	if typeof(model) ~= "Instance" or not model:IsA("Model") then
		return false, "missing_ghost_model"
	end
	local sx = math.clamp(tonumber(scale and scale.x) or 1, 0.2, 4)
	local sy = math.clamp(tonumber(scale and scale.y) or 1, 0.2, 4)
	local sz = math.clamp(tonumber(scale and scale.z) or 1, 0.2, 4)
	local pivot = model:GetPivot()
	local records = self:_captureScaleBaseline(model)
	for _, record in ipairs(records) do
		local part = record.part
		if part and part.Parent then
			local pos = record.relative.Position
			local rotation = record.relative - record.relative.Position
			part.Size = Vector3.new(record.size.X * sx, record.size.Y * sy, record.size.Z * sz)
			part.CFrame = pivot * (CFrame.new(pos.X * sx, pos.Y * sy, pos.Z * sz) * rotation)
		end
	end
	model:SetAttribute("OwnerCheatScaleX", sx)
	model:SetAttribute("OwnerCheatScaleY", sy)
	model:SetAttribute("OwnerCheatScaleZ", sz)
	return true
end

function OwnerCheatSystem:_resetGhostScale(model)
	local records = self._ghostScaleBaselines[model]
	if typeof(model) ~= "Instance" or not records then
		return false, "missing_scale_baseline"
	end
	local pivot = model:GetPivot()
	for _, record in ipairs(records) do
		local part = record.part
		if part and part.Parent then
			part.Size = record.size
			part.CFrame = pivot * record.relative
		end
	end
	model:SetAttribute("OwnerCheatScaleX", 1)
	model:SetAttribute("OwnerCheatScaleY", 1)
	model:SetAttribute("OwnerCheatScaleZ", 1)
	return true
end

function OwnerCheatSystem:_grantItem(player, itemId, equip)
	itemId = normalizeItemId(itemId)
	if not itemId then
		return false, "invalid_item_id"
	end

	local itemData = { id = itemId, category = itemId:match("^cos_") and "Cosmetic" or "Equipment" }
	local granted = false
	local grantReason = nil
	if type(self._shopSystem) == "table" and type(self._shopSystem.GrantItem) == "function" then
		local ok, result, reason = pcall(function()
			return self._shopSystem:GrantItem(player, itemId)
		end)
		granted = ok and (result == true or result == nil)
		grantReason = reason or result
	end
	if not granted and type(self._inventorySystem) == "table" and type(self._inventorySystem.GrantItem) == "function" then
		local ok, result, reason = pcall(function()
			return self._inventorySystem:GrantItem(player, itemId, itemData)
		end)
		granted = ok and (result == true or reason == "already_owned" or result == false and reason == "already_owned")
		grantReason = reason or result
	end
	if not granted and type(self._inventorySystem) == "table" and type(self._inventorySystem.StoreItem) == "function" then
		local ok, result, reason = pcall(function()
			return self._inventorySystem:StoreItem(player, itemId)
		end)
		granted = ok and (result == true or reason == "already_owned")
		grantReason = reason or result
	end
	if not granted then
		return false, tostring(grantReason or "grant_failed")
	end

	local equipped = false
	local slot = nil
	if equip == true and type(self._cosmeticSystem) == "table" and type(self._cosmeticSystem.EquipCosmetic) == "function" then
		local ok, result, _, resolvedSlot = pcall(function()
			return self._cosmeticSystem:EquipCosmetic(player, itemId)
		end)
		equipped = ok and result == true
		slot = resolvedSlot
	end
	player:SetAttribute("OwnerCheatLastTestItem", itemId)
	player:SetAttribute("OwnerCheatLastTestEquip", equipped)
	return true, equipped and ("equipped:" .. tostring(slot or "slot")) or "granted"
end

function OwnerCheatSystem:_handle(player, action, payload)
	if action == "RequestAuth" then
		self:_sendSnapshot(player, "RequestAuth")
		return true, "snapshot_sent"
	elseif action == "InspectRoleState" then
		return true, "role_state", self:_rolePayload(player)
	elseif action == "AddQA" then
		local userId = self:_resolveUserId(payload and (payload.userId or payload.username))
		if not userId or userId == self._roles.ownerUserId then
			return false, "invalid_user_id"
		end
		self._roles.qaUserIds[tostring(userId)] = true
		self:_saveRoles()
		return true, "qa_added", self:_rolePayload(player)
	elseif action == "RemoveQA" then
		local userId = self:_resolveUserId(payload and (payload.userId or payload.username))
		if not userId then
			return false, "invalid_user_id"
		end
		self._roles.qaUserIds[tostring(userId)] = nil
		self:_saveRoles()
		return true, "qa_removed", self:_rolePayload(player)
	elseif action == "TransferOwner" then
		local userId = self:_resolveUserId(payload and (payload.userId or payload.username))
		if not userId then
			return false, "invalid_user_id"
		end
		local previousOwner = self._roles.ownerUserId
		self._roles.ownerUserId = userId
		self._roles.qaUserIds[tostring(userId)] = nil
		if previousOwner and previousOwner ~= userId then
			self._roles.qaUserIds[tostring(previousOwner)] = true
		end
		self:_saveRoles()
		return true, "owner_transferred", self:_rolePayload(player)
	elseif action == "GetCatalogSnapshot" then
		return true, "catalog", { catalog = self:_buildCatalogSnapshot() }
	elseif action == "StartSoloMatch" then
		if type(self._matchSystem) ~= "table" or type(self._matchSystem.CreateMatch) ~= "function" or type(self._matchSystem.StartMatch) ~= "function" then
			return false, "missing_match_system"
		end
		local created, createReason = self._matchSystem:CreateMatch({
			players = { player },
			mapId = payload and payload.mapId or "HauntedHouse",
			mode = payload and (payload.mode or payload.gameMode) or "Classic",
			difficulty = payload and payload.difficulty or "Mudah",
		})
		if not created or not created.matchId then
			return false, tostring(createReason or "create_match_failed")
		end
		local match, startReason = self._matchSystem:StartMatch(created.matchId)
		return match ~= nil, match and "solo_match_started" or tostring(startReason or "start_match_failed"), { matchId = created.matchId }
	end

	local liveMatch, matchId, matchErr = self:_resolveLiveMatch(player, payload)
	if action == "EndMatch" then
		if not matchId or type(self._matchSystem) ~= "table" or type(self._matchSystem.EndMatch) ~= "function" then
			return false, matchErr or "missing_match_system"
		end
		self._matchSystem:EndMatch(matchId, { reason = "owner_cheat", forced = true })
		return true, "match_ended"
	elseif action == "AdvanceInvestigationPhase" then
		local phase = payload and payload.phase or "InvestigationPhase"
		if not VALID_PHASES[phase] then
			return false, "invalid_phase"
		end
		if not matchId or type(self._matchSystem) ~= "table" or type(self._matchSystem.AdvanceMatchPhase) ~= "function" then
			return false, matchErr or "missing_match_system"
		end
		local result, reason = self._matchSystem:AdvanceMatchPhase(matchId, phase)
		return result ~= nil, result and "phase_advanced" or tostring(reason or "advance_failed")
	elseif action == "GhostSpawn" then
		if not liveMatch then
			return false, matchErr
		end
		if type(self._ghostSystem) ~= "table" or type(self._ghostSystem.SpawnGhost) ~= "function" then
			return false, "missing_ghost_system"
		end
		local ghostType = normalizeGhostType(payload and payload.ghostType)
		if not ghostType then
			return false, "invalid_ghost_type"
		end
		liveMatch.ghostType = ghostType
		local result, reason = self._ghostSystem:SpawnGhost(liveMatch, { ghostType = ghostType })
		if not result then
			return false, tostring(reason or "ghost_spawn_failed")
		end
		local moved, moveReason = self:_moveGhostToArea(player, liveMatch, payload)
		if not moved then
			return false, tostring(moveReason or "ghost_move_failed")
		end
		player:SetAttribute("PasrahGhostType", ghostType)
		return true, "ghost_spawned", {
			matchId = matchId,
			ghostType = ghostType,
			spawnMode = type(payload) == "table" and tostring(payload.spawnMode or payload.location or "in_place") or "in_place",
		}
	elseif action == "GhostDespawn" then
		if type(self._ghostSystem) == "table" and type(self._ghostSystem.DespawnGhost) == "function" then
			local result, reason = self._ghostSystem:DespawnGhost(liveMatch or matchId)
			return result ~= nil, result and "ghost_despawned" or tostring(reason or "despawn_failed")
		end
		if liveMatch and typeof(liveMatch.ghost) == "Instance" then
			liveMatch.ghost:Destroy()
			liveMatch.ghost = nil
			return true, "ghost_despawned"
		end
		return false, "missing_ghost"
	elseif action == "GhostAnimation" then
		local animation = payload and payload.animation
		if type(animation) ~= "string" then
			return false, "invalid_animation"
		end
		player:SetAttribute("OwnerCheatGhostAnimation", animation)
		player:SetAttribute("PasrahGhostRuntimeState", animation:gsub("^Ghost", ""))
		return true, "animation_requested"
	elseif action == "GhostScale" then
		if not liveMatch or typeof(liveMatch.ghost) ~= "Instance" then
			return false, matchErr or "missing_ghost"
		end
		local ok, reason = self:_applyGhostScale(liveMatch.ghost, payload and payload.scale)
		return ok, reason or "ghost_scaled"
	elseif action == "GhostResetScale" then
		if not liveMatch or typeof(liveMatch.ghost) ~= "Instance" then
			return false, matchErr or "missing_ghost"
		end
		local ok, reason = self:_resetGhostScale(liveMatch.ghost)
		return ok, reason or "ghost_scale_reset"
	elseif action == "GhostFreeze" then
		if not liveMatch or typeof(liveMatch.ghost) ~= "Instance" then
			return false, matchErr or "missing_ghost"
		end
		local frozen = payload and payload.enabled == true
		for _, descendant in ipairs(liveMatch.ghost:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Anchored = frozen
			end
		end
		liveMatch.ghost:SetAttribute("OwnerCheatFrozen", frozen)
		return true, frozen and "ghost_frozen" or "ghost_unfrozen"
	elseif action == "GhostChase" then
		if not liveMatch or typeof(liveMatch.ghost) ~= "Instance" then
			return false, matchErr or "missing_ghost"
		end
		liveMatch.ghost:SetAttribute("OwnerCheatChaseEnabled", payload and payload.enabled == true)
		return true, "ghost_chase_toggled"
	elseif action == "ForceManifest" then
		if not liveMatch then
			return false, matchErr
		end
		if type(self._ghostSystem) ~= "table" or type(self._ghostSystem.ForceManifest) ~= "function" then
			return false, "missing_ghost_system"
		end
		local result, reason = self._ghostSystem:ForceManifest(liveMatch, os.clock())
		return result ~= nil, result and "manifest_forced" or tostring(reason or "manifest_failed")
	elseif action == "ForceHunt" then
		if not liveMatch then
			return false, matchErr
		end
		if type(self._ghostSystem) ~= "table" or type(self._ghostSystem.ForceHunt) ~= "function" then
			return false, "missing_ghost_system"
		end
		local result, reason = self._ghostSystem:ForceHunt(liveMatch, {}, os.clock())
		return result ~= nil, result and "hunt_forced" or tostring(reason or "hunt_failed")
	elseif action == "TriggerJumpscare" or action == "TriggerGhostAudio" or action == "PreviewGhostSFX" then
		local ghostType = normalizeGhostType(payload and payload.ghostType) or (liveMatch and liveMatch.ghostType) or "Pocong"
		local soundId = GHOST_SFX_BY_TYPE[ghostType]
		if type(self._eventBus) == "table" and type(self._eventBus.Publish) == "function" and action ~= "PreviewGhostSFX" then
			self._eventBus:Publish(action == "TriggerJumpscare" and "JumpscareAudioTriggered" or "GhostAudioTriggered", {
				player = player,
				matchId = matchId,
				ghostType = ghostType,
				cue = action == "TriggerJumpscare" and "jumpscare_stinger" or "ghost_interaction",
				source = "OwnerCheatSystem",
			})
		end
		return true, "audio_triggered", { ghostType = ghostType, soundId = soundId }
	elseif action == "GrantTestItem" or action == "EquipTestItem" then
		return self:_grantItem(player, payload and payload.itemId, action == "EquipTestItem")
	elseif action == "CleanupOwnerTestState" then
		if liveMatch and type(self._ghostSystem) == "table" and type(self._ghostSystem.DespawnGhost) == "function" then
			pcall(function()
				self._ghostSystem:DespawnGhost(liveMatch)
			end)
		elseif liveMatch and typeof(liveMatch.ghost) == "Instance" then
			liveMatch.ghost:Destroy()
			liveMatch.ghost = nil
		end
		player:SetAttribute("OwnerCheatLastTestItem", nil)
		player:SetAttribute("OwnerCheatLastTestEquip", nil)
		player:SetAttribute("OwnerCheatGhostAnimation", nil)
		player:SetAttribute("OwnerCheatFrozen", nil)
		player:SetAttribute("OwnerCheatChaseEnabled", nil)
		return true, "owner_test_state_cleaned"
	end

	return false, "unsupported_action"
end

function OwnerCheatSystem:_onRequest(player, request)
	if not (typeof(player) == "Instance" and player:IsA("Player")) or type(request) ~= "table" then
		return
	end
	local action = request.action
	local allowed, reason = self:_validate(player, action)
	if not allowed then
		self:_ack(player, request, false, reason)
		return
	end

	local dispatchOk, success, result, data = xpcall(function()
		return self:_handle(player, action, request.payload or request)
	end, function(err)
		return debug.traceback(err)
	end)
	if not dispatchOk then
		warn("[OwnerCheatSystem] " .. tostring(action) .. " failed\n" .. tostring(success))
		self:_ack(player, request, false, "handler_error")
		return
	end
	self:_ack(player, request, success == true, result or "ok", type(data) == "table" and data or nil)
	if action == "AddQA" or action == "RemoveQA" or action == "TransferOwner" or action == "RequestAuth" then
		for _, other in ipairs(Players:GetPlayers()) do
			self:_sendSnapshot(other, action)
		end
	end
end

return OwnerCheatSystem

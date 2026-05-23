local Services = require(script.Parent.Parent.Core.Services)
local ModeSelectionConfig = require(script.Parent.ModeSelectionConfig)

local Service = {}
Service.__index = Service

local TOUCH_DEBOUNCE_SECONDS = 1.0
local LOBBY_NAME = "LobbySocialHub"
local LOBBY_SPAWN_OFFSET = Vector3.new(0, 3, 0)
local LOBBY_SPAWN_MAX_DELTA_XZ = 350
local LOBBY_MIN_Y = -50
local LOBBY_MAX_SPAWN_Y = 15
local HOST_START_COUNTDOWN_SECONDS = 5
local DEFAULT_MAP_ID = "HauntedHouse"
local LOBBY_SPAWN_PROTECTION_SECONDS = 3
local SUPPORTED_MAP_IDS = {
	HauntedHouse = true,
	AbandonedPalace = true,
	EmptyBuilding = true,
	StudioMMNineteen = true,
}

local function resolveEventBus(deps)
	local eventBus = Services.Get(deps, "EventBus")
	if type(eventBus) ~= "table" then
		return nil
	end
	if type(eventBus.Publish) == "function" then
		return eventBus
	end
	if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then
		return eventBus.Service
	end
	return nil
end

local function resolveMatchSystem(deps)
	local match = Services.Get(deps, "MatchSystem")
	if type(match) ~= "table" then
		return nil
	end
	if type(match.JoinQueue) == "function" then
		return match
	end
	if type(match.Service) == "table" and type(match.Service.JoinQueue) == "function" then
		return match.Service
	end
	return nil
end

local function resolveProfileSystem(deps)
	local profile = Services.Get(deps, "ProfileSystem")
	if type(profile) ~= "table" then
		return nil
	end
	if type(profile.GetPlayerLevel) == "function" then
		return profile
	end
	if type(profile.Service) == "table" and type(profile.Service.GetPlayerLevel) == "function" then
		return profile.Service
	end
	return nil
end

local function resolveRoomManager()
	local roomManagerModule = script.Parent:FindFirstChild("RoomManager")
		or script.Parent:FindFirstChild("RoomManager,lua")
	if not roomManagerModule then
		return nil
	end

	local ok, roomManagerFactory = pcall(require, roomManagerModule)
	if not ok or type(roomManagerFactory) ~= "table" or type(roomManagerFactory.new) ~= "function" then
		return nil
	end

	local created, instance = pcall(roomManagerFactory.new)
	if created and type(instance) == "table" then
		return instance
	end
	return nil
end

local function resolvePlayersService(deps)
	if deps and deps.Players then
		return deps.Players
	end
	return game:GetService("Players")
end

local function nowClock()
	return os.clock()
end

local function applyLobbySpawnState(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return
	end

	local matchId = player:GetAttribute("MatchId")
	local lifecyclePhase = player:GetAttribute("MatchLifecyclePhase")
	local hasMatchContext = (type(matchId) == "string" and matchId ~= "")
		or (type(lifecyclePhase) == "string" and lifecyclePhase ~= "")
	if hasMatchContext then
		return
	end

	local protectUntil = os.clock() + LOBBY_SPAWN_PROTECTION_SECONDS
	player:SetAttribute("InLobby", true)
	player:SetAttribute("InMatch", nil)
	player:SetAttribute("MatchId", nil)
	player:SetAttribute("SpawnProtected", true)
	player:SetAttribute("SpawnProtectedUntil", protectUntil)

	task.delay(LOBBY_SPAWN_PROTECTION_SECONDS, function()
		if not player.Parent then
			return
		end
		local currentUntil = player:GetAttribute("SpawnProtectedUntil")
		if type(currentUntil) == "number" and currentUntil > os.clock() then
			return
		end
		player:SetAttribute("SpawnProtected", nil)
		player:SetAttribute("SpawnProtectedUntil", nil)
	end)
end

local function toUserId(player)
	if typeof(player) == "Instance" and player:IsA("Player") then
		return player.UserId
	end
	return nil
end

local function copyArray(list)
	local out = {}
	for index, value in ipairs(list or {}) do
		out[index] = value
	end
	return out
end

local function safeCall(target, methodName, ...)
	if type(target) ~= "table" then
		return nil
	end
	local method = target[methodName]
	if type(method) ~= "function" then
		return nil
	end
	local ok, result = pcall(method, target, ...)
	if not ok then
		return nil
	end
	return result
end

local function collectSpawnParts(root, out)
	out = out or {}
	if not root then
		return out
	end
	for _, child in ipairs(root:GetChildren()) do
		if child:IsA("BasePart") then
			table.insert(out, child)
		elseif child:IsA("Folder") or child:IsA("Model") then
			collectSpawnParts(child, out)
		end
	end
	return out
end

local function resolveLobbyRoot()
	local direct = workspace:FindFirstChild(LOBBY_NAME)
	if direct then
		return direct
	end

	local mapsFolder = workspace:FindFirstChild("Maps")
	if mapsFolder then
		local nested = mapsFolder:FindFirstChild(LOBBY_NAME)
		if nested then
			return nested
		end
	end

	local currentMap = workspace:FindFirstChild("CurrentMap")
	if currentMap and currentMap.Name == LOBBY_NAME then
		return currentMap
	end

	return nil
end

local function isValidLobbySpawnPart(lobbyRoot, spawnPart)
	if not (spawnPart and spawnPart:IsA("BasePart")) then
		return false
	end

	if spawnPart.Position.Y < LOBBY_MIN_Y then
		return false
	end

	if spawnPart.Position.Y > LOBBY_MAX_SPAWN_Y then
		return false
	end

	if lobbyRoot and spawnPart:IsDescendantOf(lobbyRoot) then
		return true
	end

	if lobbyRoot then
		local pivot = lobbyRoot:GetPivot().Position
		local delta = spawnPart.Position - pivot
		if math.abs(delta.X) > LOBBY_SPAWN_MAX_DELTA_XZ or math.abs(delta.Z) > LOBBY_SPAWN_MAX_DELTA_XZ then
			return false
		end
	end

	return true
end

local function resolveLobbySpawnParts()
	-- LobbySocialHub/LobbyPlayerManager is the authoritative spawn owner.
	-- Keep this helper inert so LobbySystem cannot reintroduce a competing spawn path.
	return {}
end

local function buildUprightPartCFrame(part, offset)
	if not (part and part:IsA("BasePart")) then
		return nil
	end

	local finalPosition = part.Position + (offset or Vector3.zero)
	local flatLook = Vector3.new(part.CFrame.LookVector.X, 0, part.CFrame.LookVector.Z)
	if flatLook.Magnitude <= 1e-4 then
		flatLook = Vector3.new(0, 0, -1)
	else
		flatLook = flatLook.Unit
	end
	return CFrame.lookAt(finalPosition, finalPosition + flatLook, Vector3.yAxis)
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = resolveEventBus(self._deps)
	self._matchSystem = resolveMatchSystem(self._deps)
	self._profileSystem = resolveProfileSystem(self._deps)
	self._players = resolvePlayersService(self._deps)
	self._modeConfig = ModeSelectionConfig.Load()
	self._roomManager = resolveRoomManager()
	self._spawnConnectionsByUserId = {}
	self._hostStartCountdownSeconds = HOST_START_COUNTDOWN_SECONDS
	return self
end

function Service:_getMatchSystem()
	if self._matchSystem then
		return self._matchSystem
	end

	self._matchSystem = resolveMatchSystem(self._deps)
	if self._matchSystem then
		return self._matchSystem
	end

	local ok, registry = pcall(function()
		return require(script.Parent.Parent.Core.SystemRegistry)
	end)
	if not ok or type(registry) ~= "table" then
		return nil
	end

	local match = nil
	if type(registry.GetSystemsByName) == "function" then
		local systems = registry:GetSystemsByName()
		match = systems and systems.MatchSystem
	end
	if type(match) ~= "table" and type(registry.GetService) == "function" then
		match = registry:GetService("MatchSystem")
	end
	if type(match) ~= "table" and type(registry.Get) == "function" then
		match = registry:Get("MatchSystem")
	end
	if type(match) ~= "table" then
		return nil
	end
	if type(match.JoinQueue) == "function" then
		self._matchSystem = match
		return self._matchSystem
	end
	if type(match.Service) == "table" and type(match.Service.JoinQueue) == "function" then
		self._matchSystem = match.Service
		return self._matchSystem
	end
	return nil
end

function Service:_getProfileSystem()
	if self._profileSystem then
		return self._profileSystem
	end

	self._profileSystem = resolveProfileSystem(self._deps)
	return self._profileSystem
end

function Service:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function Service:_getSelections()
	return self._state:Get("playerSelections") or {}
end

function Service:_setSelections(selections)
	self._state:Set("playerSelections", selections)
end

function Service:_getTouchDebounce()
	return self._state:Get("queueTriggerDebounceByUserId") or {}
end

function Service:_setTouchDebounce(debounce)
	self._state:Set("queueTriggerDebounceByUserId", debounce)
end

function Service:_normalizeMode(modeName)
	return ModeSelectionConfig.NormalizeMode(self._modeConfig, modeName)
end

function Service:_normalizeDifficulty(difficultyName)
	return ModeSelectionConfig.NormalizeDifficulty(self._modeConfig, difficultyName)
end

function Service:_resolveDisplayedDifficulty(modeName, difficultyName)
	return ModeSelectionConfig.ResolveDisplayedDifficulty(self._modeConfig, modeName, difficultyName)
end

function Service:_allowDifficultySelection(modeName)
	return ModeSelectionConfig.AllowDifficultySelection(self._modeConfig, modeName)
end

function Service:_normalizeMapId(mapId)
	if type(mapId) == "string" and SUPPORTED_MAP_IDS[mapId] == true then
		return mapId
	end
	return DEFAULT_MAP_ID
end

function Service:_resolveRankedDifficulty(payload)
	return ModeSelectionConfig.ResolveRankedDifficulty(self._modeConfig, payload)
end

function Service:_buildLevelBalanceData(players)
	local profileSystem = self:_getProfileSystem()
	local playerLevels = {}
	local totalLevel = 0
	local count = 0

	for _, player in ipairs(players or {}) do
		local level = nil
		if profileSystem then
			level = safeCall(profileSystem, "GetPlayerLevel", player)
		end
		level = tonumber(level) or tonumber(typeof(player) == "Instance" and player:GetAttribute("PlayerLevel") or nil) or 1
		level = math.max(1, math.floor(level))
		table.insert(playerLevels, level)
		totalLevel += level
		count += 1
	end

	return {
		playerLevels = playerLevels,
		averagePlayerLevel = count > 0 and (totalLevel / count) or 1,
		partySize = math.max(count, 1),
	}
end

function Service:_getQueueTriggerPart()
	local queuePart = workspace:FindFirstChild("QueueTrigger", true) or workspace:FindFirstChild("MatchQueueTrigger", true)
	if queuePart and queuePart:IsA("BasePart") then
		return queuePart
	end
	return nil
end

function Service:_teleportPlayerToQueueAreaIfOutside(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false, "invalid_player"
	end

	local queuePart = self:_getQueueTriggerPart()
	if not queuePart then
		return false, "queue_trigger_not_found"
	end

	local character = player.Character
	if not character then
		return false, "missing_character"
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false, "missing_root"
	end

	local distance = (root.Position - queuePart.Position).Magnitude
	if distance <= 28 then
		return true, "already_in_area"
	end

	local queueCFrame = buildUprightPartCFrame(queuePart, Vector3.new(0, 4, 0))
	if queueCFrame then
		root.CFrame = queueCFrame
	else
		root.CFrame = queuePart.CFrame + Vector3.new(0, 4, 0)
	end
	return true
end

function Service:_ensurePlayerSelection(player)
	local userId = toUserId(player)
	if not userId then
		return nil
	end

	local selections = self:_getSelections()
	local selection = selections[userId]
	if selection then
		return selection
	end

	selection = {
		mode = self:_normalizeMode(nil),
		difficulty = self:_resolveDisplayedDifficulty(self:_normalizeMode(nil), nil),
		mapId = self:_normalizeMapId(nil),
		updatedAt = nowClock(),
	}
	selections[userId] = selection
	self:_setSelections(selections)
	return selection
end

function Service:Init()
	self._state:Set("initialized", true)
	local ok, registry = pcall(function()
		return require(script.Parent.Parent.Core.SystemRegistry)
	end)
	if ok and type(registry) == "table" then
		local matchSystem = registry:GetService("MatchSystem")
		if matchSystem and matchSystem.Service then
			self._matchQueue = matchSystem.Service
		end
	end
	if not self._matchQueue then
		warn("[LobbySystem] MatchSystem not found in registry")
		return
	end
	self._state:Set("lobbyPlayers", self._state:Get("lobbyPlayers") or {})
	self._state:Set("playerSelections", {})
	self._state:Set("queueTriggerConnections", {})
	self._state:Set("queueTriggerDebounceByUserId", {})
end

function Service:Start()
	self._state:Set("started", true)
	self:BindQueueTrigger()
end

function Service:Stop()
	self._state:Set("started", false)
	self:UnbindQueueTrigger()
	for _, connection in pairs(self._spawnConnectionsByUserId) do
		connection:Disconnect()
	end
	table.clear(self._spawnConnectionsByUserId)
end

function Service:SetModeSelection(player, modeName, payload)
	local selection = self:_ensurePlayerSelection(player)
	if not selection then
		return false, "invalid_player"
	end

	local mode = self:_normalizeMode(modeName)
	selection.mode = mode
	if self:_allowDifficultySelection(mode) then
		selection.difficulty = self:_normalizeDifficulty(selection.difficulty)
	else
		selection.difficulty = self:_resolveDisplayedDifficulty(mode, nil)
	end
	selection.updatedAt = nowClock()

	self:_publish("RoomBrowserSelectionChanged", {
		player = player,
		userId = player.UserId,
		mode = selection.mode,
		difficulty = selection.difficulty,
	})

	return true, nil, {
		mode = selection.mode,
		difficulty = selection.difficulty,
		mapId = selection.mapId,
	}
end

function Service:SetDifficultySelection(player, difficultyName)
	local selection = self:_ensurePlayerSelection(player)
	if not selection then
		return false, "invalid_player"
	end
	if not self:_allowDifficultySelection(selection.mode) then
		return false, "difficulty_selection_disabled"
	end

	selection.difficulty = self:_normalizeDifficulty(difficultyName)
	selection.updatedAt = nowClock()

	self:_publish("RoomBrowserSelectionChanged", {
		player = player,
		userId = player.UserId,
		mode = selection.mode,
		difficulty = selection.difficulty,
	})

	return true, nil, {
		mode = selection.mode,
		difficulty = selection.difficulty,
		mapId = selection.mapId,
	}
end

function Service:SetMapSelection(player, mapId)
	local selection = self:_ensurePlayerSelection(player)
	if not selection then
		return false, "invalid_player"
	end

	selection.mapId = self:_normalizeMapId(mapId)
	selection.updatedAt = nowClock()

	self:_publish("RoomBrowserSelectionChanged", {
		player = player,
		userId = player.UserId,
		mode = selection.mode,
		difficulty = selection.difficulty,
		mapId = selection.mapId,
	})

	return true, nil, {
		mode = selection.mode,
		difficulty = selection.difficulty,
		mapId = selection.mapId,
	}
end

function Service:GetPlayerSelection(player, payload)
	local selection = self:_ensurePlayerSelection(player)
	if not selection then
		return nil
	end
	if not self:_allowDifficultySelection(selection.mode) then
		selection.difficulty = self:_resolveDisplayedDifficulty(selection.mode, selection.difficulty)
	end
	return {
		mode = selection.mode,
		difficulty = selection.difficulty,
		mapId = selection.mapId,
	}
end

function Service:JoinRoom(player, roomId, password)
	if not self._roomManager then
		return false, "room_manager_unavailable"
	end

	local numericRoomId = tonumber(roomId)
	if not numericRoomId then
		return false, "invalid_room_id"
	end

	local existing = self._roomManager:GetRoomByPlayer(player)
	if existing and existing.id ~= numericRoomId then
		self._roomManager:LeaveRoom(player)
	elseif existing and existing.id == numericRoomId then
		self:_teleportPlayerToQueueAreaIfOutside(player)
		return true
	end

	local ok, reason = self._roomManager:JoinRoom(player, numericRoomId, password)
	if not ok then
		return false, reason or "room_join_failed"
	end

	self:_teleportPlayerToQueueAreaIfOutside(player)

	self:_publish("RoomBrowserRoomJoined", {
		player = player,
		roomId = numericRoomId,
	})
	return true
end

function Service:LeaveRoom(player)
	if not self._roomManager then
		return false, "room_manager_unavailable"
	end
	local ok = self._roomManager:LeaveRoom(player)
	if not ok then
		return false, "room_leave_failed"
	end
	self:_publish("RoomBrowserRoomLeft", {
		player = player,
	})
	return true
end

function Service:SetReady(player, isReady)

	if not self._roomManager then

		return false, "room_manager_unavailable"

	end

	local ok, allReady = self._roomManager:SetReady(player, isReady)

	if not ok then

		return false, allReady

	end

	local room = self._roomManager:GetRoomByPlayer(player)

	if room then

		self:_publish("RoomReadyStateChanged", {

			roomId = room.id,

			player = player,

			isReady = isReady,

			allReady = allReady or false,

		})

	end

	return true, nil, { allReady = allReady or false }
end

function Service:_getHostStartRoom(player)
	if not self._roomManager then
		return nil, "room_manager_unavailable"
	end

	local room = self._roomManager:GetRoomByPlayer(player)
	if not room then
		return nil, "not_in_room"
	end

	if room.host ~= player then
		return nil, "not_host"
	end

	return room
end

function Service:BeginHostStart(player)
	local room, err = self:_getHostStartRoom(player)
	if not room then
		return false, err
	end

	if room.inGame or room.starting then
		return false, "already_in_game"
	end

	if room.host == player then
		room.readyPlayers[player] = true
	end

	if not self._roomManager:IsAllReady(room.id) then
		return false, "not_all_ready"
	end

	self._roomManager:SetInGame(room.id, true, true)
	return true, nil, {
		roomId = room.id,
		players = copyArray(room.players),
		countdownSeconds = self._hostStartCountdownSeconds,
	}
end

function Service:CommitHostStart(player, payload)
	local room, err = self:_getHostStartRoom(player)
	if not room then
		return false, err
	end

	if not room.starting then
		return false, "no_pending_start"
	end

	local queuePayload = {}
	for key, value in pairs(payload or {}) do
		queuePayload[key] = value
	end
	queuePayload.source = "HostStart"

	local ok, reason, queuedPayload = self:QueueFromRoomBrowser(player, queuePayload)
	if not ok then
		self._roomManager:SetInGame(room.id, false, true)
		return false, reason
	end

	room.starting = false
	room.status = "ingame"
	return true, nil, queuedPayload
end

function Service:CancelHostStart(player)
	local room, err = self:_getHostStartRoom(player)
	if not room then
		return false, err
	end

	if not room.starting then
		return false, "no_pending_start"
	end

	self._roomManager:SetInGame(room.id, false, true)
	return true, nil, {
		roomId = room.id,
		players = copyArray(room.players),
	}
end
function Service:KickPlayer(host, targetUserId)

	if not self._roomManager then

		return false, "room_manager_unavailable"

	end

	local targetPlayer = nil

	for _, p in ipairs(game:GetService("Players"):GetPlayers()) do

		if p.UserId == targetUserId then

			targetPlayer = p

			break

		end

	end

	if not targetPlayer then

		return false, "player_not_found"

	end

	local ok, err = self._roomManager:KickPlayer(host, targetPlayer)

	if not ok then

		return false, err

	end

	self:_publish("PlayerKickedFromRoom", {

		host = host,

		kicked = targetPlayer,

	})

	return true
end

function Service:SetRoomPassword(host, password)

	if not self._roomManager then

		return false, "room_manager_unavailable"

	end

	local normalized = nil
	if type(password) == "string" then
		normalized = password:gsub("%s+", "")
		if normalized == "" then
			normalized = nil
		elseif not normalized:match("^%d%d%d%d$") then
			return false, "password_must_be_4_digits"
		end
	end

	return self._roomManager:SetPassword(host, normalized)
end

function Service:GetRoomList()

	if not self._roomManager then

		return {}

	end

	local rooms = {}

	local roomMap = self._roomManager:GetRooms() or {}

	for _, room in pairs(roomMap) do

		local host = room.host

		local hostName = host and host.Name or nil

		local hostUserId = host and host.UserId or nil

		local leaderSelection = host and self:GetPlayerSelection(host) or nil

		local readyCount = 0
		local roomPlayers = {}

		for _, member in ipairs(room.players or {}) do

			if room.readyPlayers[member] then

				readyCount = readyCount + 1

			end

			table.insert(roomPlayers, {
				userId = member.UserId,
				name = member.Name,
				displayName = member.DisplayName,
				isHost = member == host,
				isReady = room.readyPlayers[member] == true,
			})

		end
		table.sort(roomPlayers, function(a, b)
			return tostring(a.name) < tostring(b.name)
		end)

		table.insert(rooms, {

			roomId = room.id,

			playerCount = #(room.players or {}),

			maxPlayers = room.maxPlayers or 4,

			status = room.status or "waiting",

			inGame = room.inGame or false,

			starting = room.starting or false,

			hostName = hostName,

			hostUserId = hostUserId,

			hasPassword = room.password ~= nil,

			readyCount = readyCount,

			mode = leaderSelection and leaderSelection.mode or self:_normalizeMode(nil),

			difficulty = leaderSelection and leaderSelection.difficulty or self:_resolveDisplayedDifficulty(self:_normalizeMode(nil), nil),

			mapId = leaderSelection and leaderSelection.mapId or self:_normalizeMapId(nil),

			players = roomPlayers,

		})

	end

	table.sort(rooms, function(a, b)

		return a.roomId < b.roomId

	end)

	return rooms
end

function Service:GetRoomBrowserSnapshot(player, payload)
	local selection = self:GetPlayerSelection(player, payload) or {
		mode = self:_normalizeMode(nil),
		difficulty = self:_resolveDisplayedDifficulty(self:_normalizeMode(nil), nil),
		mapId = self:_normalizeMapId(nil),
	}
	return {
		modes = ModeSelectionConfig.GetModeList(self._modeConfig),
		classicDifficulties = ModeSelectionConfig.GetPublicDifficultyList(self._modeConfig, selection.mode),
		selectedMode = selection.mode,
		selectedDifficulty = selection.difficulty,
		selectedMap = selection.mapId,
		rooms = self:GetRoomList(),
	}
end

function Service:_buildQueuePayload(player, payload)
	local selection = self:GetPlayerSelection(player, payload)
	if not selection then
		return nil, "invalid_player"
	end

	local mode = selection.mode
	local difficulty = selection.difficulty
	if mode == "Ranked" then
		difficulty = self:_resolveRankedDifficulty(payload)
	elseif not self:_allowDifficultySelection(mode) then
		difficulty = nil
	end

	local roomPlayers = { player }
	local partyId = "solo:" .. tostring(player.UserId)
	local room = self._roomManager and self._roomManager:GetRoomByPlayer(player) or nil
	if room then
		roomPlayers = copyArray(room.players)
		partyId = "room:" .. tostring(room.id)
	end

	local balanceData = self:_buildLevelBalanceData(roomPlayers)

	return {
		partyId = partyId,
		leader = player,
		players = roomPlayers,
		queueType = ((self._modeConfig.ModeDefinitions or {})[mode] and (self._modeConfig.ModeDefinitions or {})[mode].QueueType)
			or string.lower(mode),
		mode = mode,
		gameMode = mode,
		difficulty = difficulty,
		averagePlayerLevel = balanceData.averagePlayerLevel,
		playerLevels = balanceData.playerLevels,
		partySize = balanceData.partySize,
		averageRankScore = payload and payload.averageRankScore or nil,
		playerRankScores = payload and payload.playerRankScores or nil,
		rankedDifficulty = payload and payload.rankedDifficulty or nil,
		mapId = self:_normalizeMapId((payload and payload.mapId) or selection.mapId),
		now = payload and payload.now or nil,
	}
end

function Service:QueueFromRoomBrowser(player, payload)
	local queuePayload, err = self:_buildQueuePayload(player, payload)
	if not queuePayload then
		return false, err
	end

	local matchSystem = self:_getMatchSystem()
	if not matchSystem then
		return false, "missing_match_system"
	end

	if self._eventBus then
		self:_publish("MatchmakingStarted", queuePayload)
		return true, nil, queuePayload
	end

	local partyMembers = {}
	for _, entry in ipairs(queuePayload.players or {}) do
		if entry ~= player then
			table.insert(partyMembers, entry)
		end
	end

	local ok, reason = matchSystem:JoinQueue(player, {
		partyId = queuePayload.partyId,
		queueType = queuePayload.queueType,
		partyMembers = partyMembers,
		mapId = queuePayload.mapId,
		mode = queuePayload.mode,
		gameMode = queuePayload.gameMode,
		difficulty = queuePayload.difficulty,
		averageRankScore = queuePayload.averageRankScore,
		playerRankScores = queuePayload.playerRankScores,
		rankedDifficulty = queuePayload.rankedDifficulty,
		now = queuePayload.now,
	})
	if not ok then
		return false, reason
	end

	local match = matchSystem:TryCreateMatchFromQueue(queuePayload)
	if match and match.matchId then
		matchSystem:StartMatch(match.matchId)
	end
	return true, nil, queuePayload
end

function Service:_playerFromTouch(hitPart)
	if typeof(hitPart) ~= "Instance" then
		return nil
	end
	local model = hitPart.Parent
	if not model then
		return nil
	end
	return self._players:GetPlayerFromCharacter(model)
end

function Service:_isTouchDebounced(player)
	local userId = toUserId(player)
	if not userId then
		return true
	end
	local now = nowClock()
	local debounce = self:_getTouchDebounce()
	local previous = debounce[userId]
	if previous and (now - previous) < TOUCH_DEBOUNCE_SECONDS then
		return true
	end
	debounce[userId] = now
	self:_setTouchDebounce(debounce)
	return false
end

function Service:BindQueueTrigger()
	if self._state:Get("queueTriggerBound") == true then
		return false, "already_bound"
	end

	local queuePart = workspace:FindFirstChild("QueueTrigger", true) or workspace:FindFirstChild("MatchQueueTrigger", true)
	if not (queuePart and queuePart:IsA("BasePart")) then
		return false, "queue_trigger_not_found"
	end

	local connections = self._state:Get("queueTriggerConnections") or {}
	table.insert(connections, queuePart.Touched:Connect(function(hitPart)
		local player = self:_playerFromTouch(hitPart)
		if not player then
			return
		end
		if self:_isTouchDebounced(player) then
			return
		end
		self:_publish("LobbyWorldSurfaceRequested", {
			eventName = "LobbyWorldSurfaceRequested",
			player = player,
			recipients = { player },
			zoneName = "MatchmakingZone",
			title = "Room Browser dibuka",
			message = "Buat room, join room, lalu host start dari Room Browser sebelum match dimulai.",
			surface = "RoomBrowser",
			source = "QueueTriggerTouch",
		})
	end))
	self._state:Set("queueTriggerConnections", connections)
	self._state:Set("queueTriggerBound", true)
	self._state:Set("queueTriggerName", queuePart.Name)
	return true
end

function Service:UnbindQueueTrigger()
	local connections = self._state:Get("queueTriggerConnections") or {}
	for _, connection in ipairs(connections) do
		connection:Disconnect()
	end
	self._state:Set("queueTriggerConnections", {})
	self._state:Set("queueTriggerBound", false)
end


function Service:OnPlayerJoin(player)
	local userId = toUserId(player)
	if not userId then
		return
	end

	local previous = self._spawnConnectionsByUserId[userId]
	if previous then
		previous:Disconnect()
		self._spawnConnectionsByUserId[userId] = nil
	end

	-- LobbySocialHub owns lobby presence and spawn authority.
	-- LobbySystem only initializes room-browser state for connected players.
	self:_ensurePlayerSelection(player)
end

function Service:OnPlayerLeave(player)
	self:OnPlayerRemoved(player)
end

function Service:OnMatchStarted(matchId)
	self._state:Set("activeMatchId", matchId)
end

function Service:OnMatchEnded(matchId)
	if self._state:Get("activeMatchId") == matchId then
		self._state:Set("activeMatchId", nil)
	end
end
function Service:OnPlayerRemoved(player)
	local userId = toUserId(player)
	if not userId then
		return
	end

	local players = self._state:Get("lobbyPlayers") or {}
	players[userId] = nil
	self._state:Set("lobbyPlayers", players)

	if self._roomManager then
		local room = self._roomManager:GetRoomByPlayer(player)
		if room and room.starting then
			self._roomManager:SetInGame(room.id, false, true)
		end
		self._roomManager:LeaveRoom(player)
	end

	local selections = self:_getSelections()
	selections[userId] = nil
	self:_setSelections(selections)

	local debounce = self:_getTouchDebounce()
	debounce[userId] = nil
	self:_setTouchDebounce(debounce)

	local connection = self._spawnConnectionsByUserId[userId]
	if connection then
		connection:Disconnect()
		self._spawnConnectionsByUserId[userId] = nil
	end
end

return Service














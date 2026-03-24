local Services = require(script.Parent.Parent.Core.Services)
local ModeSelectionConfig = require(script.Parent.ModeSelectionConfig)

local Service = {}
Service.__index = Service

local TOUCH_DEBOUNCE_SECONDS = 1.0
local LOBBY_NAME = "LobbySocialHub"
local LOBBY_SPAWN_OFFSET = Vector3.new(0, 3, 0)
local LOBBY_SPAWN_MAX_DELTA_XZ = 350
local LOBBY_MIN_Y = -50
local HOST_START_COUNTDOWN_SECONDS = 5
local _standaloneMatchService = nil

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

local function resolveStandaloneMatchService(registry)
	if _standaloneMatchService then
		return _standaloneMatchService
	end

	local serverScriptService = game:GetService("ServerScriptService")
	local serverFolder = serverScriptService:FindFirstChild("Server")
	local matchFolder = serverFolder and serverFolder:FindFirstChild("MatchSystem")
	local stateModule = matchFolder and matchFolder:FindFirstChild("State")
	local serviceModule = matchFolder and matchFolder:FindFirstChild("Service")
	if not stateModule or not serviceModule then
		return nil
	end

	local okState, stateFactory = pcall(require, stateModule)
	local okService, serviceFactory = pcall(require, serviceModule)
	if not okState or not okService then
		return nil
	end
	if type(stateFactory) ~= "table" or type(stateFactory.new) ~= "function" then
		return nil
	end
	if type(serviceFactory) ~= "table" or type(serviceFactory.new) ~= "function" then
		return nil
	end

	local deps = {}
	if type(registry) == "table" then
		deps.Services = registry
		deps.ServiceRegistry = registry
	end

	local state = stateFactory.new()
	local service = serviceFactory.new(state, deps)
	if type(service) ~= "table" then
		return nil
	end

	if type(service.Init) == "function" then
		pcall(function()
			service:Init()
		end)
	end
	if type(service.Start) == "function" then
		pcall(function()
			service:Start()
		end)
	end

	if type(service.JoinQueue) == "function" and type(service.TryCreateMatchFromQueue) == "function" and type(service.StartMatch) == "function" then
		_standaloneMatchService = service
		return _standaloneMatchService
	end

	return nil
end

local function isValidLobbySpawnPart(lobbyRoot, spawnPart)
	if not (spawnPart and spawnPart:IsA("BasePart")) then
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
		if spawnPart.Position.Y < LOBBY_MIN_Y then
			return false
		end
	end

	return true
end

local function resolveLobbySpawnParts()
	local lobbyRoot = resolveLobbyRoot()
	if lobbyRoot then
		local lobbySpawn = lobbyRoot:FindFirstChild("LobbySpawn", true)
		if isValidLobbySpawnPart(lobbyRoot, lobbySpawn) then
			return { lobbySpawn }
		end

		local spawnFolder = lobbyRoot:FindFirstChild("SpawnPoints", true)
		local spawnParts = collectSpawnParts(spawnFolder, {})
		table.sort(spawnParts, function(a, b)
			return a.Name < b.Name
		end)

		local validSpawnParts = {}
		for _, spawnPart in ipairs(spawnParts) do
			if isValidLobbySpawnPart(lobbyRoot, spawnPart) then
				table.insert(validSpawnParts, spawnPart)
			end
		end
		if #validSpawnParts > 0 then
			return validSpawnParts
		end

		local spawnLocation = lobbyRoot:FindFirstChildWhichIsA("SpawnLocation", true)
		if isValidLobbySpawnPart(lobbyRoot, spawnLocation) then
			return { spawnLocation }
		end
	end

	local directSpawn = workspace:FindFirstChild("LobbySpawn")
	if isValidLobbySpawnPart(lobbyRoot, directSpawn) then
		return { directSpawn }
	end

	return {}
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = resolveEventBus(self._deps)
	self._matchSystem = resolveMatchSystem(self._deps)
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
		return resolveStandaloneMatchService(nil)
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
		return resolveStandaloneMatchService(registry)
	end
	if type(match.JoinQueue) == "function" then
		self._matchSystem = match
		return self._matchSystem
	end
	if type(match.Service) == "table" and type(match.Service.JoinQueue) == "function" then
		self._matchSystem = match.Service
		return self._matchSystem
	end
	return resolveStandaloneMatchService(registry)
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

function Service:_resolveRankedDifficulty(payload)
	return ModeSelectionConfig.ResolveRankedDifficulty(self._modeConfig, payload)
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

	root.CFrame = queuePart.CFrame + Vector3.new(0, 4, 0)
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
		difficulty = self:_normalizeDifficulty(nil),
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
	if mode == "Ranked" then
		selection.difficulty = self:_resolveRankedDifficulty(payload)
	else
		selection.difficulty = self:_normalizeDifficulty(selection.difficulty)
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
	}
end

function Service:SetDifficultySelection(player, difficultyName)
	local selection = self:_ensurePlayerSelection(player)
	if not selection then
		return false, "invalid_player"
	end
	if selection.mode == "Ranked" then
		return false, "ranked_difficulty_is_balanced"
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
	}
end

function Service:GetPlayerSelection(player, payload)
	local selection = self:_ensurePlayerSelection(player)
	if not selection then
		return nil
	end
	if selection.mode == "Ranked" then
		selection.difficulty = self:_resolveRankedDifficulty(payload)
	end
	return {
		mode = selection.mode,
		difficulty = selection.difficulty,
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

			difficulty = leaderSelection and leaderSelection.difficulty or self:_normalizeDifficulty(nil),

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
		difficulty = self:_normalizeDifficulty(nil),
	}
	return {
		modes = ModeSelectionConfig.GetModeList(self._modeConfig),
		classicDifficulties = ModeSelectionConfig.GetDifficultyList(self._modeConfig),
		selectedMode = selection.mode,
		selectedDifficulty = selection.difficulty,
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
	end

	local roomPlayers = { player }
	local partyId = "solo:" .. tostring(player.UserId)
	local room = self._roomManager and self._roomManager:GetRoomByPlayer(player) or nil
	if room then
		roomPlayers = copyArray(room.players)
		partyId = "room:" .. tostring(room.id)
	end

	return {
		partyId = partyId,
		leader = player,
		players = roomPlayers,
		queueType = ((self._modeConfig.ModeDefinitions or {})[mode] and (self._modeConfig.ModeDefinitions or {})[mode].QueueType)
			or string.lower(mode),
		mode = mode,
		gameMode = mode,
		difficulty = difficulty,
		averageMMR = payload and payload.averageMMR or nil,
		playerMMRs = payload and payload.playerMMRs or nil,
		rankedDifficulty = payload and payload.rankedDifficulty or nil,
		mapId = payload and payload.mapId or nil,
		now = payload and payload.now or nil,
	}
end

function Service:QueueFromRoomBrowser(player, payload)
	local queuePayload, err = self:_buildQueuePayload(player, payload)
	if not queuePayload then
		return false, err
	end

	if self._eventBus then
		self:_publish("MatchmakingStarted", queuePayload)
		return true, nil, queuePayload
	end

	local matchSystem = self:_getMatchSystem()
	if not matchSystem then
		return false, "missing_match_system"
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
		averageMMR = queuePayload.averageMMR,
		playerMMRs = queuePayload.playerMMRs,
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
		self:QueueFromRoomBrowser(player, {
			source = "QueueTrigger",
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
	local players = self._state:Get("lobbyPlayers") or {}
	players[userId] = player
	self._state:Set("lobbyPlayers", players)

	local previous = self._spawnConnectionsByUserId[userId]
	if previous then
		previous:Disconnect()
	end

	local function spawnToLobby(character, source)
		if player:GetAttribute("InMatch") == true then
			return
		end

		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") then
			root = character and character:WaitForChild("HumanoidRootPart", 5)
		end
		if not root or not root:IsA("BasePart") then
			warn(string.format("[LobbySystem] [%s] Missing root for %s", tostring(source), player.Name))
			return
		end

		local spawnParts = resolveLobbySpawnParts()
		if #spawnParts == 0 then
			warn(string.format("[LobbySystem] [%s] Lobby spawn unresolved for %s", tostring(source), player.Name))
			return
		end

		local index = (player.UserId % #spawnParts) + 1
		local spawnPart = spawnParts[index]
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
		root.CFrame = spawnPart.CFrame + LOBBY_SPAWN_OFFSET
		player:SetAttribute("InLobby", true)
		print(string.format("[LobbySystem] [%s] Spawned %s at %s", tostring(source), player.Name, tostring(spawnPart.Position)))
	end

	self._spawnConnectionsByUserId[userId] = player.CharacterAdded:Connect(function(character)
		task.defer(function()
			spawnToLobby(character, "CharacterAdded")
		end)
	end)

	if player.Character then
		task.defer(function()
			spawnToLobby(player.Character, "OnPlayerJoin")
		end)
	end
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














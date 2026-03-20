local Service = {}
Service.__index = Service

local DEFAULT_CONFIG = {
	MaxAllowedSpeed = 24,
	MaxTeleportDistance = 45,
	ViolationKickScore = 3,
	AllowedRemoteCalls = {},
}

local function resolveEventBus(deps)
	local eventBus = deps.EventBus
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

local function clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

local function resolveUserId(player)
	if type(player) == "table" and player.userId then
		return player.userId
	end
	if type(player) == "userdata" and player.UserId then
		return player.UserId
	end
	return nil
end

local function magnitude(delta)
	if type(delta) == "number" then
		return math.abs(delta)
	end
	if type(delta) == "table" and delta.x and delta.y and delta.z then
		return math.sqrt((delta.x * delta.x) + (delta.y * delta.y) + (delta.z * delta.z))
	end
	return 0
end

local function mergeConfig(base, override)
	local merged = {}
	for key, value in pairs(base) do
		merged[key] = value
	end
	for key, value in pairs(override or {}) do
		merged[key] = value
	end
	return merged
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._config = mergeConfig(DEFAULT_CONFIG, self._deps.AntiCheatConfig)
	self._eventBus = resolveEventBus(self._deps)
	self._kickFn = self._deps.KickPlayer
	return self
end

function Service:Init()
	self._state:Set("players", {})
	self._state:Set("violations", {})
end

function Service:Start()
	-- Event-driven checks only.
end

function Service:Stop()
	self._state:Clear()
end

function Service:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function Service:_players()
	return self._state:Get("players") or {}
end

function Service:_setPlayers(players)
	self._state:Set("players", players)
end

function Service:_violations()
	return self._state:Get("violations") or {}
end

function Service:_setViolations(violations)
	self._state:Set("violations", violations)
end

function Service:_getOrCreatePlayerEntry(player)
	local userId = resolveUserId(player)
	if not userId then
		return nil, nil
	end

	local players = self:_players()
	players[userId] = players[userId] or {
		userId = userId,
		violationScore = 0,
		lastPosition = nil,
		lastPositionAt = 0,
		rewardRequestIds = {},
		suspicious = false,
	}
	self:_setPlayers(players)
	return players[userId], userId
end

function Service:_recordViolation(player, violationType, severity, details)
	local entry, userId = self:_getOrCreatePlayerEntry(player)
	if not entry then
		return nil, "missing_user_id"
	end

	local scoreAdd = clamp(severity or 1, 1, 5)
	entry.violationScore += scoreAdd
	entry.suspicious = entry.violationScore >= 2

	local record = {
		userId = userId,
		violationType = violationType,
		severity = scoreAdd,
		details = details,
		at = os.clock(),
	}

	local violations = self:_violations()
	violations[userId] = violations[userId] or {}
	table.insert(violations[userId], record)
	self:_setViolations(violations)

	self:_publish("PlayerViolationDetected", {
		player = player,
		userId = userId,
		violationType = violationType,
		severity = scoreAdd,
		score = entry.violationScore,
		details = details,
	})

	if entry.violationScore >= self._config.ViolationKickScore then
		if type(self._kickFn) == "function" then
			self._kickFn(player, "AntiCheat violation: " .. tostring(violationType))
		end
	end

	return record
end

function Service:ValidateRemoteCall(player, remoteName, payload, context)
	local allowed = self._config.AllowedRemoteCalls
	if type(allowed) == "table" and next(allowed) ~= nil and allowed[remoteName] ~= true then
		self:_recordViolation(player, "invalid_remote_call", 2, {
			remoteName = remoteName,
			payload = payload,
			context = context,
		})
		return false, "invalid_remote_call"
	end
	return true
end

function Service:CheckMovement(player, movementPayload)
	local entry = self:_getOrCreatePlayerEntry(player)
	if not entry then
		return false, "missing_user_id"
	end

	local now = movementPayload and movementPayload.now or os.clock()
	local position = movementPayload and movementPayload.position
	if not position then
		return true
	end

	local previousPosition = entry.lastPosition
	local previousAt = entry.lastPositionAt or now
	entry.lastPosition = position
	entry.lastPositionAt = now

	if not previousPosition then
		return true
	end

	local deltaTime = math.max(0.016, now - previousAt)
	local distance = magnitude({
		x = (position.x or 0) - (previousPosition.x or 0),
		y = (position.y or 0) - (previousPosition.y or 0),
		z = (position.z or 0) - (previousPosition.z or 0),
	})
	local speed = distance / deltaTime

	if speed > self._config.MaxAllowedSpeed then
		self:_recordViolation(player, "speed_hack_detected", 1, {
			speed = speed,
			distance = distance,
			deltaTime = deltaTime,
		})
	end
	if distance > self._config.MaxTeleportDistance then
		self:_recordViolation(player, "teleport_abuse_detected", 2, {
			distance = distance,
		})
	end

	return true
end

function Service:CheckDuplicateReward(player, requestId, payload)
	local entry = self:_getOrCreatePlayerEntry(player)
	if not entry then
		return false, "missing_user_id"
	end
	if not requestId then
		self:_recordViolation(player, "invalid_reward_request", 1, payload)
		return false, "invalid_reward_request"
	end

	if entry.rewardRequestIds[requestId] then
		self:_recordViolation(player, "duplicate_reward_request", 2, {
			requestId = requestId,
			payload = payload,
		})
		return false, "duplicate_reward_request"
	end

	entry.rewardRequestIds[requestId] = true
	return true
end

function Service:GetPlayerViolations(player)
	local userId = resolveUserId(player)
	if not userId then
		return {}
	end
	local violations = self:_violations()
	return violations[userId] or {}
end

return Service

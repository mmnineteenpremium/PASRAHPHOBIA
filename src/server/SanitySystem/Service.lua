local Service = {}
Service.__index = Service

local DEFAULT_CONFIG = {
	MinSanity = 0,
	MaxSanity = 100,
	DefaultSanity = 100,
	LowTeamThreshold = 30,
	BaseDarkDrainPerSecond = 0.9,
	GhostProximityDrainPerSecond = 1.25,
	AloneDrainPerSecond = 0.55,
	ManifestDrain = 6,
	HuntDrain = 10,
	LightRecoveryPerSecond = 0.5,
	TeammateRecoveryPerSecond = 0.35,
	LeaveGhostRoomRecoveryPerSecond = 0.45,
}

local function resolveEventBus(deps)
	local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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

local function resolveUserId(player)
	if type(player) == "table" and player.userId then
		return player.userId
	end
	if type(player) == "userdata" and player.UserId then
		return player.UserId
	end
	return nil
end

local function resolvePlayerName(player)
	if type(player) == "userdata" and player.Name then
		return player.Name
	end
	if type(player) == "table" and player.name then
		return player.name
	end
	return nil
end

local function classifySanity(value)
	if value <= 10 then
		return "hunt_risk"
	end
	if value <= 30 then
		return "high_paranormal_activity"
	end
	if value <= 50 then
		return "unstable"
	end
	return "safe"
end

local function isCritical(value)
	return value <= 10
end

local function isRecovered(oldValue, newValue)
	if oldValue == nil then
		return false
	end
	if oldValue <= 50 and newValue > 50 then
		return true
	end
	if oldValue <= 30 and newValue > 30 then
		return true
	end
	if oldValue <= 10 and newValue > 10 then
		return true
	end
	return false
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = resolveEventBus(self._deps)
	self._config = mergeConfig(DEFAULT_CONFIG, self._deps.SanityConfig)
	return self
end

function Service:Init()
	self._state:Set("sessions", {})
end

function Service:Start()
	-- Driven by controller events.
end

function Service:Stop()
	self._state:Set("sessions", {})
end

function Service:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function Service:_sessions()
	return self._state:Get("sessions") or {}
end

function Service:_setSessions(sessions)
	self._state:Set("sessions", sessions)
end

function Service:_getOrCreateSession(matchId)
	local sessions = self:_sessions()
	local session = sessions[matchId]
	if session then
		return session
	end

	session = {
		matchId = matchId,
		players = {},
		huntActive = false,
		ghostRoomId = nil,
	}
	sessions[matchId] = session
	self:_setSessions(sessions)
	return session
end

function Service:StartMatch(matchId, payload)
	if not matchId then
		return nil, "invalid_arguments"
	end

	local session = self:_getOrCreateSession(matchId)
	for _, player in ipairs(payload and payload.players or {}) do
		local userId = resolveUserId(player)
		if userId then
			session.players[userId] = {
				sanity = self._config.DefaultSanity,
				player = player,
				playerName = resolvePlayerName(player),
			}
		end
	end
	return session
end

function Service:EndMatch(matchId)
	local sessions = self:_sessions()
	sessions[matchId] = nil
	self:_setSessions(sessions)
end

function Service:SetGhostRoom(matchId, roomId)
	local session = self:_getOrCreateSession(matchId)
	session.ghostRoomId = roomId
end

function Service:GetSanity(player, matchId)
	local userId = resolveUserId(player)
	if not userId then
		return self._config.DefaultSanity
	end

	if matchId then
		local session = self:_getOrCreateSession(matchId)
		local entry = session.players[userId]
		return entry and entry.sanity or self._config.DefaultSanity
	end

	for _, session in pairs(self:_sessions()) do
		local entry = session.players[userId]
		if entry then
			return entry.sanity
		end
	end
	return self._config.DefaultSanity
end

function Service:_setSanity(matchId, player, newSanity, reason)
	local session = self:_getOrCreateSession(matchId)
	local userId = resolveUserId(player)
	if not userId then
		return nil
	end

	session.players[userId] = session.players[userId] or {
		player = player,
		playerName = resolvePlayerName(player),
		sanity = self._config.DefaultSanity,
	}
	local oldValue = session.players[userId].sanity
	local clamped = clamp(newSanity, self._config.MinSanity, self._config.MaxSanity)
	session.players[userId].sanity = clamped

	if oldValue ~= clamped then
		self:_publish("SanityChanged", {
			matchId = matchId,
			player = player,
			userId = userId,
			newSanity = clamped,
			oldSanity = oldValue,
			sanityBand = classifySanity(clamped),
			reason = reason,
		})
		self:_publish("PlayerSanityChanged", {
			matchId = matchId,
			player = player,
			userId = userId,
			newSanity = clamped,
		})

		if isCritical(clamped) and not isCritical(oldValue) then
			self:_publish("SanityCritical", {
				matchId = matchId,
				player = player,
				userId = userId,
				sanity = clamped,
				reason = reason,
			})
		elseif isRecovered(oldValue, clamped) then
			self:_publish("SanityRecovered", {
				matchId = matchId,
				player = player,
				userId = userId,
				sanity = clamped,
				reason = reason,
			})
		end
	end
	return clamped
end

function Service:DrainSanity(player, amount, matchId, reason)
	if not matchId then
		return nil, "invalid_match"
	end
	local current = self:GetSanity(player, matchId)
	local nextValue = current - math.abs(amount or 0)
	return self:_setSanity(matchId, player, nextValue, reason or "drain")
end

function Service:RestoreSanity(player, amount, matchId, reason)
	if not matchId then
		return nil, "invalid_match"
	end
	local current = self:GetSanity(player, matchId)
	local nextValue = current + math.abs(amount or 0)
	return self:_setSanity(matchId, player, nextValue, reason or "restore")
end

function Service:GetAverageTeamSanity(matchId)
	local session = self:_sessions()[matchId]
	if not session then
		return self._config.DefaultSanity
	end

	local total, count = 0, 0
	for _, entry in pairs(session.players) do
		total += entry.sanity
		count += 1
	end
	if count == 0 then
		return self._config.DefaultSanity
	end
	return total / count
end

function Service:ApplySnapshotDrain(matchId, snapshot, now)
	local session = self:_getOrCreateSession(matchId)
	local players = snapshot and snapshot.players or {}
	local dt = snapshot and snapshot.dt or 1
	local timeNow = now or snapshot and snapshot.now or os.clock()

	local aliveCount = 0
	for _, playerData in ipairs(players) do
		if playerData.isAlive ~= false then
			aliveCount += 1
		end
	end

	for _, playerData in ipairs(players) do
		local player = playerData.player or playerData
		local userId = playerData.userId or resolveUserId(player)
		if userId and playerData.isAlive ~= false then
			local sanity = self:GetSanity({ userId = userId }, matchId)
			local drain = 0
			local restore = 0

			local inDark = playerData.inDarkArea == true or (playerData.lightLevel and playerData.lightLevel <= 0.25)
			local nearGhost = playerData.isNearGhost == true
				or playerData.nearGhostRoom == true
				or (session.ghostRoomId and playerData.roomId == session.ghostRoomId)
			local alone = aliveCount > 1 and (playerData.isAlone == true or (playerData.nearbyTeammates or 0) <= 0)
			local inLight = playerData.inLight == true or (playerData.lightLevel and playerData.lightLevel >= 0.65)
			local nearTeammates = (playerData.nearbyTeammates or 0) > 0
			local leftGhostRoom = playerData.leftGhostRoom == true

			if inDark then
				drain += self._config.BaseDarkDrainPerSecond * dt
			end
			if nearGhost then
				drain += self._config.GhostProximityDrainPerSecond * dt
			end
			if alone then
				drain += self._config.AloneDrainPerSecond * dt
			end
			if inLight then
				restore += self._config.LightRecoveryPerSecond * dt
			end
			if nearTeammates then
				restore += self._config.TeammateRecoveryPerSecond * dt
			end
			if leftGhostRoom then
				restore += self._config.LeaveGhostRoomRecoveryPerSecond * dt
			end

			sanity = clamp(sanity - drain + restore, self._config.MinSanity, self._config.MaxSanity)
			self:_setSanity(matchId, player, sanity, "snapshot_update")
			session.players[userId] = session.players[userId] or {}
			session.players[userId].lastUpdatedAt = timeNow
		end
	end

	local avg = self:GetAverageTeamSanity(matchId)
	if avg <= self._config.LowTeamThreshold then
		self:_publish("TeamSanityLow", {
			matchId = matchId,
			averageSanity = avg,
		})
	end

	return avg
end

function Service:OnGhostManifest(matchId, payload)
	local session = self:_getOrCreateSession(matchId)
	local players = payload and payload.players or {}
	for _, player in ipairs(players) do
		self:DrainSanity(player, self._config.ManifestDrain, matchId, "manifestation")
	end
	return session
end

function Service:OnHuntStarted(matchId, payload)
	local session = self:_getOrCreateSession(matchId)
	session.huntActive = true

	if payload and type(payload.players) == "table" then
		for _, player in ipairs(payload.players) do
			self:DrainSanity(player, self._config.HuntDrain, matchId, "hunt_start")
		end
	end
end

function Service:OnHuntEnded(matchId)
	local session = self:_getOrCreateSession(matchId)
	session.huntActive = false
end

function Service:OnEnvironmentalEvent(matchId, payload)
	local eventType = payload and payload.eventType
	if not eventType then
		return
	end

	local session = self:_getOrCreateSession(matchId)
	for userId, entry in pairs(session.players) do
		self:DrainSanity(entry.player or { userId = userId }, 0.5, matchId, "environmental_event")
	end
end

function Service:OnGhostEventTriggered(matchId, payload)
	local session = self:_getOrCreateSession(matchId)
	local intensity = payload and payload.intensity or 1
	for userId, entry in pairs(session.players) do
		self:DrainSanity(entry.player or { userId = userId }, 1.0 * intensity, matchId, "ghost_event")
	end
end

function Service:OnDirectorTriggeredHunt(matchId, payload)
	local session = self:_getOrCreateSession(matchId)
	local pressure = payload and payload.huntChance or 0.2
	for userId, entry in pairs(session.players) do
		self:DrainSanity(entry.player or { userId = userId }, 1.5 + pressure, matchId, "hunt_pressure")
	end
end

return Service


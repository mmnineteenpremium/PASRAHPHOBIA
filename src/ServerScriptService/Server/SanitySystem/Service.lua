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

local function resolvePlayerInstance(player)
	if typeof(player) == "Instance" and player:IsA("Player") then
		return player
	end
	return nil
end

local function stampSanityRuntime(target, payload)
	if typeof(target) ~= "Instance" then
		return
	end
	target:SetAttribute("PasrahSanityOwner", "SanitySystem")
	target:SetAttribute("PasrahSanityMatchId", type(payload.matchId) == "string" and payload.matchId or nil)
	target:SetAttribute("PasrahSanityValue", tonumber(payload.sanity))
	target:SetAttribute("PasrahSanityBand", type(payload.sanityBand) == "string" and payload.sanityBand or nil)
	target:SetAttribute("PasrahSanityCritical", payload.critical == true)
	target:SetAttribute("PasrahSanityReason", type(payload.reason) == "string" and payload.reason or nil)
	target:SetAttribute("PasrahSanityTeamAverage", tonumber(payload.teamAverage))
	target:SetAttribute("PasrahSanityHuntActive", payload.huntActive == true)
	target:SetAttribute("PasrahSanityGhostRoomId", type(payload.ghostRoomId) == "string" and payload.ghostRoomId or nil)
	target:SetAttribute("PasrahSanityLastUpdatedAt", tonumber(payload.updatedAt) or os.clock())
end

local function clearSanityRuntime(target)
	if typeof(target) ~= "Instance" then
		return
	end
	target:SetAttribute("PasrahSanityOwner", nil)
	target:SetAttribute("PasrahSanityMatchId", nil)
	target:SetAttribute("PasrahSanityValue", nil)
	target:SetAttribute("PasrahSanityBand", nil)
	target:SetAttribute("PasrahSanityCritical", nil)
	target:SetAttribute("PasrahSanityReason", nil)
	target:SetAttribute("PasrahSanityTeamAverage", nil)
	target:SetAttribute("PasrahSanityHuntActive", nil)
	target:SetAttribute("PasrahSanityGhostRoomId", nil)
	target:SetAttribute("PasrahSanityLastUpdatedAt", nil)
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

local function resolveDrainMultiplier(payload)
	local profile = payload and payload.difficultyProfile
	if type(profile) ~= "table" then
		return 1.0
	end
	local direct = tonumber(profile.SanityDrainMultiplier)
	if direct then
		return math.max(0.1, direct)
	end
	local legacy = tonumber(profile.SanityDrain)
	if legacy then
		return math.max(0.1, legacy)
	end
	return 1.0
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

function Service:_stampPlayerSanity(matchId, playerOrUserId, reason)
	local session = self:_sessions()[matchId]
	if type(session) ~= "table" then
		return
	end
	local userId = resolveUserId(playerOrUserId)
	if not userId then
		return
	end
	local entry = session.players[userId]
	if type(entry) ~= "table" then
		return
	end
	local player = resolvePlayerInstance(playerOrUserId) or resolvePlayerInstance(entry.player)
	if not player then
		return
	end
	stampSanityRuntime(player, {
		matchId = matchId,
		sanity = entry.sanity,
		sanityBand = classifySanity(entry.sanity),
		critical = entry.criticalFired == true,
		reason = reason,
		teamAverage = self:GetAverageTeamSanity(matchId),
		huntActive = session.huntActive == true,
		ghostRoomId = session.ghostRoomId,
		updatedAt = entry.lastUpdatedAt or os.clock(),
	})
end

function Service:_stampSessionPlayers(matchId, reason)
	local session = self:_sessions()[matchId]
	if type(session) ~= "table" then
		return
	end
	for userId, entry in pairs(session.players or {}) do
		self:_stampPlayerSanity(matchId, entry.player or { userId = userId }, reason)
	end
end

function Service:_clearSessionPlayers(matchId)
	local session = self:_sessions()[matchId]
	if type(session) ~= "table" then
		return
	end
	for _, entry in pairs(session.players or {}) do
		local player = resolvePlayerInstance(entry.player)
		if player then
			clearSanityRuntime(player)
		end
	end
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

function Service:StartMatch(matchId, payloadOrPlayers, difficultyProfile)
	if not matchId then
		return nil, "invalid_arguments"
	end

	local session = self:_getOrCreateSession(matchId)
	local payload = nil
	local players = {}
	if type(payloadOrPlayers) == "table" and payloadOrPlayers.players then
		payload = payloadOrPlayers
		players = payloadOrPlayers.players or {}
		if not difficultyProfile then
			difficultyProfile = payloadOrPlayers.difficultyProfile
		end
	elseif type(payloadOrPlayers) == "table" then
		players = payloadOrPlayers
	end

	session.difficultyProfile = difficultyProfile or {}
	session.lastDrainAt = session.lastDrainAt or 0
	session.lastTeamLowAt = session.lastTeamLowAt or 0

	for _, player in ipairs(players or {}) do
		local userId = resolveUserId(player)
		if userId then
			session.players[userId] = {
				sanity = self._config.DefaultSanity,
				player = player,
				playerName = resolvePlayerName(player),
				criticalFired = false,
			}
			self:_stampPlayerSanity(matchId, player, "match_started")
		end
	end
	return session
end

function Service:EndMatch(matchId)
	self:_clearSessionPlayers(matchId)
	local sessions = self:_sessions()
	sessions[matchId] = nil
	self:_setSessions(sessions)
end

function Service:SetGhostRoom(matchId, roomId)
	local session = self:_getOrCreateSession(matchId)
	session.ghostRoomId = roomId
	self:_stampSessionPlayers(matchId, "ghost_room_updated")
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
	session.players[userId].lastUpdatedAt = os.clock()

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

		local entry = session.players[userId]
		if clamped <= 25 and not entry.criticalFired then
			entry.criticalFired = true
			self:_publish("SanityCritical", {
				matchId = matchId,
				player = player,
				userId = userId,
				sanity = clamped,
				reason = reason,
			})
		elseif clamped > 35 and entry.criticalFired then
			entry.criticalFired = false
			self:_publish("SanityRecovered", {
				matchId = matchId,
				player = player,
				userId = userId,
				sanity = clamped,
				reason = reason,
			})
		end
		self:_stampPlayerSanity(matchId, player, reason)
	end
	return clamped
end

function Service:DrainSanity(player, amount, matchId, reason)
	if not matchId then
		return nil, "invalid_match"
	end
	local session = self:_getOrCreateSession(matchId)
	local drainMultiplier = tonumber(session and session.sanityDrainMultiplier) or 1.0
	local current = self:GetSanity(player, matchId)
	local nextValue = current - (math.abs(amount or 0) * drainMultiplier)
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
	local timeNow = now or (type(snapshot) == "table" and snapshot.now) or os.clock()
	if (timeNow - (session.lastDrainAt or 0)) < 5 then
		return self:GetAverageTeamSanity(matchId)
	end
	session.lastDrainAt = timeNow

	if type(snapshot) == "number" then
		for userId, entry in pairs(session.players) do
			self:DrainSanity(entry.player or { userId = userId }, snapshot, matchId, "ghost_manifest")
		end
		return self:GetAverageTeamSanity(matchId)
	end

	local players = snapshot and snapshot.players or {}
	local difficultyProfile = session.difficultyProfile or {}
	local drainPerTick = tonumber(difficultyProfile.SanityDrain) or tonumber(difficultyProfile.sanityDrainRate) or 0
	if session.huntActive then
		drainPerTick *= 2
	end

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
			local drain = drainPerTick
			local inDark = playerData.inDarkArea == true or (playerData.lightLevel and playerData.lightLevel <= 0.25)
			local nearGhost = playerData.isNearGhost == true
				or playerData.nearGhostRoom == true
				or (session.ghostRoomId and playerData.roomId == session.ghostRoomId)
			if inDark then
				drain += 0.5
			end
			if nearGhost then
				drain += 1.0
			end
			local current = self:GetSanity({ userId = userId }, matchId)
			local nextValue = math.max(0, current - drain)
			self:_setSanity(matchId, player, nextValue, "snapshot_update")
			session.players[userId] = session.players[userId] or {}
			session.players[userId].lastUpdatedAt = timeNow
		end
	end

	local avg = self:GetAverageTeamSanity(matchId)
	if avg < 35 then
		local lastAt = session.lastTeamLowAt or 0
		if (timeNow - lastAt) >= 30 then
			session.lastTeamLowAt = timeNow
			self:_publish("TeamSanityLow", {
				matchId = matchId,
				avg = avg,
			})
		end
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
	self:_stampSessionPlayers(matchId, "hunt_started")
end

function Service:OnHuntEnded(matchId)
	local session = self:_getOrCreateSession(matchId)
	session.huntActive = false
	self:_stampSessionPlayers(matchId, "hunt_ended")
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


function Service:OnGhostEvent(matchId, eventType)
    if not matchId then
        return
    end

    local session = self:_getOrCreateSession(matchId)
    local drain = 0
    if eventType == "Manifestation" then
        drain = self._config.ManifestDrain
    elseif eventType == "Roaming" then
        drain = 1.0
    else
        drain = 0.5
    end

    for userId, entry in pairs(session.players) do
        self:DrainSanity(entry.player or { userId = userId }, drain, matchId, "ghost_event")
    end
end

function Service:RemovePlayer(matchId, playerId)
    if not matchId or not playerId then
        return
    end
    local sessions = self:_sessions()
    local session = sessions[matchId]
    if not session then
        return
    end
    session.players[playerId] = nil
end
function Service:OnDirectorTriggeredHunt(matchId, payload)
	local session = self:_getOrCreateSession(matchId)
	local pressure = payload and payload.huntChance or 0.2
	for userId, entry in pairs(session.players) do
		self:DrainSanity(entry.player or { userId = userId }, 1.5 + pressure, matchId, "hunt_pressure")
	end
end

return Service


local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local REMOTE_FOLDER_NAME = "RemoteEvents"
local DAILY_SYNC_REMOTE_NAME = "DailyEngagementSync"
local GACHA_RESULT_REMOTE_NAME = "GachaResult"
local ROYAL_PASS_TIER_REMOTE_NAME = "RoyalPassTierUp"
local ROYAL_PASS_LEGACY_REMOTE_NAME = "RoyalPassEvent"
local AUTOSAVE_SECONDS = 30

local QUEST_OWNER_ATTR = "PasrahQuestOwner"
local QUEST_DATA_ATTR = "PasrahQuestData"
local QUEST_UPDATED_AT_ATTR = "PasrahQuestDataUpdatedAt"
local QUEST_ACTIVE_COUNT_ATTR = "PasrahQuestActiveCount"
local QUEST_COMPLETED_COUNT_ATTR = "PasrahQuestCompletedCount"
local QUEST_LAST_COMPLETED_ID_ATTR = "PasrahQuestLastCompletedId"
local QUEST_LAST_COMPLETED_TITLE_ATTR = "PasrahQuestLastCompletedTitle"
local QUEST_LAST_COMPLETED_XP_ATTR = "PasrahQuestLastCompletedXP"
local QUEST_LAST_COMPLETED_AT_ATTR = "PasrahQuestLastCompletedAt"

local DEFAULT_DATA = {
	daily = {
		lastResetDate = "",
		lastCheckinDate = "",
		lastCheckinTimestamp = 0,
		streakCount = 0,
		totalLoginDays = 0,
		missions = {},
		allRegularClaimBonusDate = "",
	},
	royalPass = {
		owned = false,
		xp = 0,
		tier = 0,
		season = 1,
		claimedFree = {},
		claimedPremium = {},
	},
	gacha = {
		pityCount = 0,
		epicPityCount = 0,
		history = {},
	},
	gachaTickets = 0,
}

local DIFFICULTY_RANK = {
	Easy = 1,
	Mudah = 1,
	Normal = 2,
	Lumayan = 2,
	Hard = 3,
	Angker = 3,
	Nightmare = 4,
	["Uji Nyali"] = 4,
}

local MATCH_LEVEL_MISSION_TYPES = {
	MATCH_COMPLETE = true,
	GHOST_IDENTIFIED = true,
	MATCH_NO_DEATH = true,
	FINISH_HIGH_SANITY = true,
	MATCH_ON_MAP = true,
	MATCH_DIFFICULTY = true,
	PERFECT_MATCH = true,
	ALL_EVIDENCE_IN_MATCH = true,
	SOLO_MATCH_COMPLETE = true,
	MATCH_WITH_PARTY = true,
	RANKED_MATCH = true,
	HOST_MATCH = true,
	SURVIVE_HUNT = true,
}

local function clone(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for key, nested in pairs(value) do
		out[key] = clone(nested)
	end
	return out
end

local function toUserId(playerOrUserId)
	if type(playerOrUserId) == "number" then
		return playerOrUserId
	end
	if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
		return playerOrUserId.UserId
	end
	return nil
end

local function toPlayer(playerOrUserId)
	if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
		return playerOrUserId
	end
	local userId = toUserId(playerOrUserId)
	if not userId then
		return nil
	end
	local ok, player = pcall(function()
		return Players:GetPlayerByUserId(userId)
	end)
	if ok then
		return player
	end
	return nil
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
		warn(string.format("[DailyEngagementSystem] %s failed: %s", methodName, tostring(result)))
		return nil
	end
	return result
end

local function callableService(system)
	if type(system) ~= "table" then
		return nil
	end
	if type(system.Service) == "table" then
		return system.Service
	end
	return system
end

local function getConfigModule(moduleName)
	local shared = ReplicatedStorage:WaitForChild("Shared", 10)
	local config = shared and shared:WaitForChild("Config", 10)
	local moduleScript = config and config:WaitForChild(moduleName, 10)
	if not moduleScript then
		error("[DailyEngagementSystem] Missing Shared.Config." .. tostring(moduleName))
	end
	return require(moduleScript)
end

local function getCheckinRewardConfig()
	return getConfigModule("CheckinRewardConfig")
end

local function getDailyMissionConfig()
	return getConfigModule("DailyMissionConfig")
end

local function getRoyalPassConfig()
	return getConfigModule("RoyalPassConfig")
end

local function getGachaConfig()
	return getConfigModule("GachaConfig")
end

local function getRemote(remoteName)
	local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
	if not folder then
		return nil
	end
	local remote = folder:FindFirstChild(remoteName)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	return nil
end

local function normalizeData(raw)
	local data = clone(DEFAULT_DATA)
	if type(raw) == "table" then
		if type(raw.daily) == "table" then
			for key, value in pairs(raw.daily) do
				data.daily[key] = clone(value)
			end
		end
		if type(raw.royalPass) == "table" then
			for key, value in pairs(raw.royalPass) do
				data.royalPass[key] = clone(value)
			end
		end
		if type(raw.gacha) == "table" then
			for key, value in pairs(raw.gacha) do
				data.gacha[key] = clone(value)
			end
		end
		if raw.gachaTickets ~= nil then
			data.gachaTickets = raw.gachaTickets
		end
	end

	data.daily.missions = type(data.daily.missions) == "table" and data.daily.missions or {}
	data.daily.streakCount = math.max(0, math.floor(tonumber(data.daily.streakCount) or 0))
	data.daily.totalLoginDays = math.max(0, math.floor(tonumber(data.daily.totalLoginDays) or 0))
	data.daily.lastResetDate = tostring(data.daily.lastResetDate or "")
	data.daily.lastCheckinDate = tostring(data.daily.lastCheckinDate or "")
	data.daily.lastCheckinTimestamp = math.max(0, math.floor(tonumber(data.daily.lastCheckinTimestamp) or 0))
	data.daily.allRegularClaimBonusDate = tostring(data.daily.allRegularClaimBonusDate or "")

	data.royalPass.owned = data.royalPass.owned == true
	data.royalPass.xp = math.max(0, math.floor(tonumber(data.royalPass.xp) or 0))
	data.royalPass.tier = math.max(0, math.floor(tonumber(data.royalPass.tier) or 0))
	data.royalPass.season = math.max(1, math.floor(tonumber(data.royalPass.season) or 1))
	data.royalPass.claimedFree = type(data.royalPass.claimedFree) == "table" and data.royalPass.claimedFree or {}
	data.royalPass.claimedPremium = type(data.royalPass.claimedPremium) == "table" and data.royalPass.claimedPremium or {}

	data.gacha.pityCount = math.max(0, math.floor(tonumber(data.gacha.pityCount) or 0))
	data.gacha.epicPityCount = math.max(0, math.floor(tonumber(data.gacha.epicPityCount) or 0))
	data.gacha.history = type(data.gacha.history) == "table" and data.gacha.history or {}
	data.gachaTickets = math.max(0, math.floor(tonumber(data.gachaTickets) or 0))

	return data
end

local function nowMillis()
	return DateTime.now().UnixTimestampMillis
end

local function normalizeDifficultyName(value, profile)
	if type(profile) == "table" then
		local mode = profile.DifficultyMode or profile.difficultyMode
		if type(mode) == "string" and mode ~= "" then
			return mode
		end
	end
	if type(value) ~= "string" then
		return ""
	end
	return value
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = nil
	self._data = nil
	self._economy = nil
	self._progression = nil
	self._inventory = nil
	self._running = false
	self._autosaveThread = nil
	return self
end

function Service:Create()
	self._eventBus = callableService(Services.Get(self._deps, "EventBus"))
	self._data = callableService(Services.Get(self._deps, "DataPersistenceService"))
	self._economy = callableService(Services.Get(self._deps, "EconomySystem"))
	self._progression = callableService(Services.Get(self._deps, "ProgressionSystem"))
	self._inventory = callableService(Services.Get(self._deps, "InventorySystem"))
end

function Service:Init()
	self._state:Set("dataByUserId", self._state:Get("dataByUserId") or {})
	self._state:Set("loadedByUserId", self._state:Get("loadedByUserId") or {})
	self._state:Set("dirtyByUserId", self._state:Get("dirtyByUserId") or {})
	self._state:Set("winStreakByUserId", self._state:Get("winStreakByUserId") or {})
	self._state:Set("evidenceCountByUserMatch", self._state:Get("evidenceCountByUserMatch") or {})
	self._state:Set("toolSetByUserMatch", self._state:Get("toolSetByUserMatch") or {})
	self._state:Set("missionDedupeByUserId", self._state:Get("missionDedupeByUserId") or {})
end

function Service:Start()
	if self._running then
		return
	end
	self._running = true
	self._autosaveThread = task.spawn(function()
		while self._running do
			task.wait(AUTOSAVE_SECONDS)
			self:_flushDirty()
		end
	end)
end

function Service:Stop()
	self._running = false
	self:_flushDirty()
	self._state:Clear()
end

function Service:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function Service:_sendRemote(player, remoteName, payload)
	if not player then
		return
	end
	local remote = getRemote(remoteName)
	if remote then
		remote:FireClient(player, payload)
	end
end

function Service:_dataByUserId()
	return self._state:Get("dataByUserId") or {}
end

function Service:_setDataByUserId(dataByUserId)
	self._state:Set("dataByUserId", dataByUserId)
end

function Service:_loadPersistedData(userId)
	if not self._data then
		return nil
	end
	local record = safeCall(self._data, "LoadProfile", userId)
	if type(record) ~= "table" then
		return nil
	end
	local profile = type(record.profile) == "table" and record.profile or record
	return {
		daily = profile.daily,
		royalPass = profile.royalPass,
		gacha = profile.gacha,
		gachaTickets = profile.gachaTickets,
	}
end

function Service:_ensurePlayerData(playerOrUserId, options)
	local userId = toUserId(playerOrUserId)
	if not userId then
		return nil
	end

	local dataByUserId = self:_dataByUserId()
	local loadedByUserId = self._state:Get("loadedByUserId") or {}
	local forceLoad = type(options) == "table" and options.forceLoad == true

	if forceLoad or not loadedByUserId[userId] or type(dataByUserId[userId]) ~= "table" then
		dataByUserId[userId] = normalizeData(self:_loadPersistedData(userId))
		loadedByUserId[userId] = true
		self:_setDataByUserId(dataByUserId)
		self._state:Set("loadedByUserId", loadedByUserId)
	else
		dataByUserId[userId] = normalizeData(dataByUserId[userId])
		self:_setDataByUserId(dataByUserId)
	end

	return dataByUserId[userId]
end

function Service:_markDirty(playerOrUserId, saveNow)
	local userId = toUserId(playerOrUserId)
	if not userId then
		return false
	end
	local dirty = self._state:Get("dirtyByUserId") or {}
	dirty[userId] = true
	self._state:Set("dirtyByUserId", dirty)
	if saveNow == true then
		return self:_persistPlayerData(userId)
	end
	return true
end

function Service:_persistPlayerData(playerOrUserId)
	local userId = toUserId(playerOrUserId)
	if not userId or not self._data then
		return false
	end

	local data = self:_ensurePlayerData(userId)
	if type(data) ~= "table" then
		return false
	end

	local ok = safeCall(self._data, "SaveProfile", userId, {
		profile = {
			daily = clone(data.daily),
			royalPass = clone(data.royalPass),
			gacha = clone(data.gacha),
			gachaTickets = data.gachaTickets,
		},
	}) == true

	if ok then
		local dirty = self._state:Get("dirtyByUserId") or {}
		dirty[userId] = nil
		self._state:Set("dirtyByUserId", dirty)
	end
	return ok
end

function Service:_flushDirty()
	local dirty = self._state:Get("dirtyByUserId") or {}
	for userId in pairs(dirty) do
		self:_persistPlayerData(userId)
	end
end

function Service:GetTodayDateString()
	return os.date("!%Y%m%d")
end

function Service:OnPlayerAdded(player)
	task.defer(function()
		if player.Parent ~= Players then
			return
		end
		self:_ensurePlayerData(player, { forceLoad = true })
		self:ResetDailyIfNeeded(player)
		self:_syncToClient(player)
	end)
end

function Service:OnPlayerRemoving(player)
	self:_persistPlayerData(player)
	local userId = toUserId(player)
	if not userId then
		return
	end
	local dataByUserId = self:_dataByUserId()
	local loadedByUserId = self._state:Get("loadedByUserId") or {}
	local dirtyByUserId = self._state:Get("dirtyByUserId") or {}
	dataByUserId[userId] = nil
	loadedByUserId[userId] = nil
	dirtyByUserId[userId] = nil
	self:_setDataByUserId(dataByUserId)
	self._state:Set("loadedByUserId", loadedByUserId)
	self._state:Set("dirtyByUserId", dirtyByUserId)
end

function Service:OnPlayerEnteredLobby(player)
	self:_ensurePlayerData(player)
	self:ResetDailyIfNeeded(player)
	self:_syncToClient(player)
end

function Service:ResetDailyIfNeeded(player)
	local data = self:_ensurePlayerData(player)
	if not data then
		return false, "no_data"
	end

	local today = self:GetTodayDateString()
	if data.daily.lastResetDate == today and type(data.daily.missions) == "table" and #data.daily.missions > 0 then
		return true
	end

	local missionConfig = getDailyMissionConfig()
	local missions = missionConfig.GetTodaysMissions(today)
	data.daily.lastResetDate = today
	data.daily.allRegularClaimBonusDate = ""
	data.daily.missions = {}

	for index, mission in ipairs(missions) do
		data.daily.missions[index] = {
			id = mission.id,
			title = mission.title,
			desc = mission.desc,
			type = mission.type,
			target = mission.target,
			xp = mission.xp,
			mm = mission.mm,
			pp = mission.pp or 0,
			icon = mission.icon,
			category = mission.category,
			progress = 0,
			claimed = false,
			isChallenge = mission.isChallenge or false,
			singleMatch = mission.singleMatch or false,
			mapId = mission.mapId,
			threshold = mission.threshold,
			minDifficulty = mission.minDifficulty,
			requiresUnlock = mission.requiresUnlock,
		}
	end

	self:_markDirty(player, true)
	self:_syncToClient(player)
	return true
end

function Service:HandleCheckin(player)
	local data = self:_ensurePlayerData(player)
	if not data then
		return false, "no_data"
	end

	self:ResetDailyIfNeeded(player)

	local today = self:GetTodayDateString()
	if data.daily.lastCheckinDate == today then
		return false, "already_checked_in"
	end

	local now = os.time()
	local checkinConfig = getCheckinRewardConfig()
	local lastTs = tonumber(data.daily.lastCheckinTimestamp) or 0
	if lastTs > 0 and ((now - lastTs) / 3600) <= 48 then
		data.daily.streakCount = (data.daily.streakCount or 0) + 1
	else
		data.daily.streakCount = 1
	end

	local streakDay = ((data.daily.streakCount - 1) % 7) + 1
	data.daily.totalLoginDays = (data.daily.totalLoginDays or 0) + 1
	data.daily.lastCheckinDate = today
	data.daily.lastCheckinTimestamp = now

	local streakReward = checkinConfig.STREAK_7[streakDay]
	local milestone = checkinConfig.MILESTONE_30[data.daily.totalLoginDays]
	if streakReward then
		self:_grantReward(player, streakReward, "checkin_streak_day_" .. tostring(streakDay))
	end
	if milestone then
		self:_grantReward(player, milestone, "checkin_milestone_" .. tostring(data.daily.totalLoginDays))
	end

	self:_grantRoyalPassXP(player, getRoyalPassConfig().XP_SOURCES.CHECKIN, "DailyCheckin")
	self:_updateStreakMultiplier(player, data.daily.streakCount)
	self:_markDirty(player, true)
	self:_syncToClient(player)

	local result = {
		streakDay = streakDay,
		streakCount = data.daily.streakCount,
		totalDays = data.daily.totalLoginDays,
		reward = streakReward,
		milestone = milestone,
	}

	self:_publish("DailyEngagementCheckinClaimed", {
		player = player,
		userId = toUserId(player),
		date = today,
		streak = data.daily.streakCount,
		reward = streakReward,
		milestone = milestone,
	})

	return true, result
end

function Service:OnDailyRewardClaimRequest(payload)
	local player = payload and payload.player
	if player then
		self:HandleCheckin(player)
	end
end

function Service:_meetsMinDifficulty(actual, minimum, profile)
	local actualName = normalizeDifficultyName(actual, profile)
	local minName = normalizeDifficultyName(minimum)
	return (DIFFICULTY_RANK[actualName] or 0) >= (DIFFICULTY_RANK[minName] or 0)
end

function Service:_missionEventSeen(userId, missionId, eventKey)
	if not userId or type(eventKey) ~= "string" or eventKey == "" then
		return false
	end
	local byUser = self._state:Get("missionDedupeByUserId") or {}
	byUser[userId] = byUser[userId] or {}
	local key = tostring(missionId) .. ":" .. eventKey
	if byUser[userId][key] == true then
		self._state:Set("missionDedupeByUserId", byUser)
		return true
	end
	byUser[userId][key] = true
	self._state:Set("missionDedupeByUserId", byUser)
	return false
end

function Service:UpdateMissionProgress(player, eventType, amount, metadata)
	local data = self:_ensurePlayerData(player)
	local userId = toUserId(player)
	if not data or not userId or type(data.daily.missions) ~= "table" then
		return false, "no_data"
	end

	self:ResetDailyIfNeeded(player)

	local updated = false
	local matchId = type(metadata) == "table" and metadata.matchId or nil
	local dedupeKey = nil
	if matchId and MATCH_LEVEL_MISSION_TYPES[eventType] then
		dedupeKey = eventType .. ":" .. tostring(matchId)
	end

	for _, mission in ipairs(data.daily.missions) do
		if mission.claimed == true or mission.type ~= eventType then
			continue
		end

		if dedupeKey and self:_missionEventSeen(userId, mission.id, dedupeKey) then
			continue
		end

		if mission.mapId and type(metadata) == "table" and metadata.mapId ~= mission.mapId and metadata.map ~= mission.mapId then
			continue
		end

		if mission.threshold and type(metadata) == "table" and (tonumber(metadata.finalSanity) or 0) < mission.threshold then
			continue
		end

		if mission.minDifficulty
			and not self:_meetsMinDifficulty(type(metadata) == "table" and metadata.difficulty or nil, mission.minDifficulty, type(metadata) == "table" and metadata.difficultyProfile or nil)
		then
			continue
		end

		if mission.singleMatch and matchId and mission.matchId ~= matchId then
			mission.matchId = matchId
			mission.progress = 0
		end

		if eventType == "TOOLS_VARIETY" then
			local toolId = type(metadata) == "table" and (metadata.toolId or metadata.toolType or metadata.toolName) or nil
			if type(toolId) ~= "string" or toolId == "" then
				continue
			end
			mission.toolIds = mission.toolIds or {}
			if mission.toolIds[toolId] == true then
				continue
			end
			mission.toolIds[toolId] = true
		end

		local current = math.max(0, math.floor(tonumber(mission.progress) or 0))
		local target = math.max(1, math.floor(tonumber(mission.target) or 1))
		local increment = math.max(0, math.floor(tonumber(amount) or 1))
		if eventType == "WIN_STREAK" then
			mission.progress = math.min(math.max(current, increment), target)
		else
			mission.progress = math.min(current + increment, target)
		end

		if mission.progress >= target then
			self:_publish("DailyMissionComplete", {
				player = player,
				userId = userId,
				mission = clone(mission),
			})
		end

		updated = true
	end

	if updated then
		self:_markDirty(player, false)
		self:_syncToClient(player)
	end

	return updated
end

function Service:ClaimMissionReward(player, missionId)
	local data = self:_ensurePlayerData(player)
	if not data then
		return false, "no_data"
	end

	self:ResetDailyIfNeeded(player)

	local royalConfig = getRoyalPassConfig()
	for _, mission in ipairs(data.daily.missions or {}) do
		if mission.id ~= missionId then
			continue
		end
		if mission.claimed == true then
			return false, "already_claimed"
		end
		if (tonumber(mission.progress) or 0) < (tonumber(mission.target) or 1) then
			return false, "not_complete"
		end

		mission.claimed = true
		local reward = {
			xp = mission.xp,
			mm = mission.mm,
			pp = mission.pp or 0,
		}
		self:_grantReward(player, reward, "mission_claim_" .. tostring(missionId))

		local royalXp = mission.isChallenge == true
			and royalConfig.XP_SOURCES.CHALLENGE_DONE
			or royalConfig.XP_SOURCES.DAILY_MISSION_DONE
		self:_grantRoyalPassXP(player, royalXp, "DailyMission")

		local regularClaimed = 0
		for _, other in ipairs(data.daily.missions or {}) do
			if other.isChallenge ~= true and other.claimed == true then
				regularClaimed += 1
			end
		end
		local today = self:GetTodayDateString()
		if regularClaimed >= 3 and data.daily.allRegularClaimBonusDate ~= today then
			data.daily.allRegularClaimBonusDate = today
			self:_grantRoyalPassXP(player, royalConfig.XP_SOURCES.ALL_3_TASKS_BONUS, "DailyMissionAllTasks")
		end

		self:_markDirty(player, true)
		self:_stampCompletedMission(player, mission)
		self:_syncToClient(player)
		self:_publish("DailyEngagementMissionClaimed", {
			player = player,
			userId = toUserId(player),
			missionId = missionId,
			reward = reward,
			royalPassXP = royalXp,
		})
		return true, clone(mission)
	end

	return false, "mission_not_found"
end

function Service:GetDailyMissions(player)
	local data = self:_ensurePlayerData(player)
	if not data then
		return {}
	end
	self:ResetDailyIfNeeded(player)
	return clone(data.daily.missions or {})
end

function Service:_grantRoyalPassXP(player, amount, source)
	local data = self:_ensurePlayerData(player)
	if not data then
		return false, "no_data"
	end
	local royalConfig = getRoyalPassConfig()
	local xpAmount = math.max(0, math.floor(tonumber(amount) or 0))
	if xpAmount <= 0 then
		return true
	end

	local pass = data.royalPass
	pass.xp += xpAmount

	self:_publish("RoyalPassXPGranted", {
		player = player,
		userId = toUserId(player),
		amount = xpAmount,
		totalXP = (pass.tier * royalConfig.XP_PER_TIER) + pass.xp,
		source = source,
	})

	while pass.tier < royalConfig.TOTAL_TIERS and pass.xp >= royalConfig.XP_PER_TIER do
		pass.xp -= royalConfig.XP_PER_TIER
		pass.tier += 1
		self:_claimTierReward(player, pass.tier, pass.owned)
	end

	self:_markDirty(player, false)
	self:_sendRoyalPassSnapshot(player, "RoyalPassProgress", {
		amount = xpAmount,
		source = source,
	})
	return true
end

function Service:AddXP(player, amount, source)
	return self:_grantRoyalPassXP(player, amount, source or "External")
end

function Service:_claimTierReward(player, tier, hasPremium)
	local data = self:_ensurePlayerData(player)
	if not data then
		return
	end
	local royalConfig = getRoyalPassConfig()
	local tierData = royalConfig.TIERS[tier]
	if not tierData then
		return
	end

	local tierKey = tostring(tier)
	data.royalPass.claimedFree = data.royalPass.claimedFree or {}
	data.royalPass.claimedPremium = data.royalPass.claimedPremium or {}

	if tierData.free and data.royalPass.claimedFree[tierKey] ~= true then
		data.royalPass.claimedFree[tierKey] = true
		self:_grantReward(player, tierData.free, "royalpass_free_tier_" .. tierKey)
	end

	if hasPremium == true and tierData.premium and data.royalPass.claimedPremium[tierKey] ~= true then
		data.royalPass.claimedPremium[tierKey] = true
		self:_grantReward(player, tierData.premium, "royalpass_premium_tier_" .. tierKey)
	end

	self:_publish("RoyalPassTierUnlocked", {
		player = player,
		userId = toUserId(player),
		tier = tier,
		seasonId = royalConfig.SEASON_ID or ("S" .. tostring(data.royalPass.season)),
	})
	self:_publish("RoyalPassTierUp", {
		player = player,
		userId = toUserId(player),
		tier = tier,
		hasPremium = hasPremium == true,
	})
	self:_sendRemote(player, ROYAL_PASS_TIER_REMOTE_NAME, {
		eventName = "RoyalPassTierUp",
		tier = tier,
		hasPremium = hasPremium == true,
		snapshot = self:GetPlayerSnapshot(player),
	})
	self:_sendRoyalPassSnapshot(player, "RoyalPassTierUnlocked", {
		tier = tier,
	})
end

function Service:SetPremiumOwnership(player, ownsPremium)
	local data = self:_ensurePlayerData(player)
	if not data then
		return false, "invalid_player"
	end

	data.royalPass.owned = ownsPremium == true
	if data.royalPass.owned then
		for tier = 1, data.royalPass.tier do
			self:_claimTierReward(player, tier, true)
		end
	end

	self:_markDirty(player, true)
	self:_publish("RoyalPassPremiumOwnershipChanged", {
		player = player,
		userId = toUserId(player),
		ownsPremium = data.royalPass.owned == true,
	})
	self:_sendRoyalPassSnapshot(player, "RoyalPassPremiumUpdated", {
		ownsPremium = data.royalPass.owned == true,
	})
	return true
end

function Service:PullGacha(player, pullCount, paymentType)
	local data = self:_ensurePlayerData(player)
	if not data then
		return false, "no_data"
	end

	local normalizedPullCount = math.floor(tonumber(pullCount) or 1)
	if normalizedPullCount ~= 1 and normalizedPullCount ~= 10 then
		return false, "invalid_pull_count"
	end

	local gachaConfig = getGachaConfig()
	local normalizedPayment = type(paymentType) == "string" and paymentType or "Ticket"
	if normalizedPayment == "MM" then
		local cost = normalizedPullCount == 10 and gachaConfig.TEN_PULL_MM or gachaConfig.SINGLE_PULL_MM
		if safeCall(self._economy, "SpendCurrency", player, "MM", cost, "gacha_pull") ~= true then
			return false, "insufficient_mm"
		end
	else
		local ticketCost = normalizedPullCount == 10 and gachaConfig.TEN_PULL_TICKET or gachaConfig.SINGLE_PULL_TICKET
		if (data.gachaTickets or 0) < ticketCost then
			return false, "insufficient_tickets"
		end
		data.gachaTickets -= ticketCost
	end

	local results = {}
	for _ = 1, normalizedPullCount do
		local item = self:_doPull(data.gacha, gachaConfig)
		table.insert(results, clone(item))
		self:_grantGachaItem(player, item)
	end

	self:_markDirty(player, true)
	self:_sendRemote(player, GACHA_RESULT_REMOTE_NAME, {
		eventName = "GachaResult",
		results = results,
		snapshot = self:BuildClientSnapshot(player),
	})
	self:_syncToClient(player)
	return true, results
end

function Service:_doPull(gachaState, gachaConfig)
	gachaState.pityCount = (gachaState.pityCount or 0) + 1
	gachaState.epicPityCount = (gachaState.epicPityCount or 0) + 1

	local roll = math.random()
	local rarity = nil

	if gachaState.pityCount >= gachaConfig.HARD_PITY then
		rarity = "LEGENDARY"
		gachaState.pityCount = 0
	elseif gachaState.pityCount >= gachaConfig.SOFT_PITY_START then
		local pullsIntoSoftPity = gachaState.pityCount - gachaConfig.SOFT_PITY_START
		local boostedRate = gachaConfig.BASE_RATES.LEGENDARY + (pullsIntoSoftPity * gachaConfig.SOFT_PITY_MULTIPLIER)
		if roll < boostedRate then
			rarity = "LEGENDARY"
			gachaState.pityCount = 0
		end
	elseif gachaState.epicPityCount >= gachaConfig.GUARANTEED_EPIC then
		rarity = "EPIC"
		gachaState.epicPityCount = 0
	end

	if not rarity then
		local rates = gachaConfig.BASE_RATES
		if roll < rates.LEGENDARY then
			rarity = "LEGENDARY"
			gachaState.pityCount = 0
		elseif roll < rates.LEGENDARY + rates.EPIC then
			rarity = "EPIC"
			gachaState.epicPityCount = 0
		elseif roll < rates.LEGENDARY + rates.EPIC + rates.RARE then
			rarity = "RARE"
		else
			rarity = "COMMON"
		end
	end

	local pool = gachaConfig.ByRarity[rarity]
	local item = pool[math.random(#pool)]
	table.insert(gachaState.history, {
		id = item.id,
		rarity = rarity,
		t = os.time(),
	})
	if #gachaState.history > 50 then
		table.remove(gachaState.history, 1)
	end

	return item
end

function Service:_grantReward(player, reward, reason)
	if type(reward) ~= "table" then
		return
	end

	local mm = math.max(0, math.floor(tonumber(reward.mm or reward.currency) or 0))
	local pp = math.max(0, math.floor(tonumber(reward.pp) or 0))
	local xp = math.max(0, math.floor(tonumber(reward.xp) or 0))

	if mm > 0 and self._economy then
		safeCall(self._economy, "AddCurrency", player, "MM", mm, reason)
	end
	if pp > 0 and self._economy then
		safeCall(self._economy, "AddCurrency", player, "PP", pp, reason)
	end
	if xp > 0 and self._progression then
		safeCall(self._progression, "GrantXP", player, xp)
	end

	local itemIds = {}
	for _, key in ipairs({ "cosmeticId", "seasonBadgeId", "exclusiveEmoteId" }) do
		if type(reward[key]) == "string" and reward[key] ~= "" then
			table.insert(itemIds, reward[key])
		end
	end
	if self._inventory then
		for _, itemId in ipairs(itemIds) do
			safeCall(self._inventory, "GrantItem", player, itemId, {
				category = "Cosmetic",
				source = reason,
			})
		end
	end

	local tickets = math.max(0, math.floor(tonumber(reward.gachaTickets) or 0))
	if tickets > 0 then
		local data = self:_ensurePlayerData(player)
		if data then
			data.gachaTickets = (data.gachaTickets or 0) + tickets
			self:_markDirty(player, false)
		end
	end
end

function Service:_grantGachaItem(player, item)
	if type(item) ~= "table" then
		return
	end
	if item.type == "currency" and item.mm then
		self:_grantReward(player, { mm = item.mm }, "gacha_" .. tostring(item.id))
		return
	end
	self:_grantReward(player, { cosmeticId = item.id }, "gacha_" .. tostring(item.id))
end

function Service:_updateStreakMultiplier(player, streakCount)
	local checkinConfig = getCheckinRewardConfig()
	local multiplier = 1.0
	for threshold, value in pairs(checkinConfig.STREAK_MULTIPLIER) do
		if streakCount >= threshold then
			multiplier = math.max(multiplier, value)
		end
	end
	player:SetAttribute("PasrahXPMultiplier", multiplier)
end

function Service:_buildQuestEntry(mission)
	local target = math.max(1, math.floor(tonumber(mission.target) or 1))
	local progress = math.clamp(math.floor(tonumber(mission.progress) or 0), 0, target)
	return {
		id = mission.id,
		title = mission.title or mission.id,
		description = mission.desc or "",
		type = mission.isChallenge == true and "DAILY_CHALLENGE" or "DAILY",
		objectives = {
			{
				id = mission.id,
				label = mission.desc or mission.title or mission.id,
				required = target,
			},
		},
		progress = {
			[mission.id] = progress,
		},
		rewards = {
			xp = math.max(0, math.floor(tonumber(mission.xp) or 0)),
			currency = math.max(0, math.floor(tonumber(mission.mm) or 0)),
			currencyType = "MM",
		},
	}
end

function Service:_buildQuestPayload(player)
	local data = self:_ensurePlayerData(player)
	local active = {}
	local completed = {}
	for _, mission in ipairs(data and data.daily.missions or {}) do
		if mission.claimed == true then
			table.insert(completed, self:_buildQuestEntry(mission))
		else
			table.insert(active, self:_buildQuestEntry(mission))
		end
	end
	return {
		active = active,
		completed = completed,
		date = data and data.daily.lastResetDate or self:GetTodayDateString(),
		updatedAt = nowMillis(),
	}
end

function Service:_stampQuestRuntime(player)
	if not player then
		return
	end
	local payload = self:_buildQuestPayload(player)
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(payload)
	end)
	if not ok then
		return
	end
	player:SetAttribute(QUEST_OWNER_ATTR, "DailyEngagementSystem")
	player:SetAttribute(QUEST_DATA_ATTR, encoded)
	player:SetAttribute(QUEST_UPDATED_AT_ATTR, payload.updatedAt)
	player:SetAttribute(QUEST_ACTIVE_COUNT_ATTR, #(payload.active or {}))
	player:SetAttribute(QUEST_COMPLETED_COUNT_ATTR, #(payload.completed or {}))
end

function Service:_stampCompletedMission(player, mission)
	if not player or type(mission) ~= "table" then
		return
	end
	player:SetAttribute(QUEST_LAST_COMPLETED_ID_ATTR, mission.id)
	player:SetAttribute(QUEST_LAST_COMPLETED_TITLE_ATTR, mission.title or mission.id)
	player:SetAttribute(QUEST_LAST_COMPLETED_XP_ATTR, math.max(0, math.floor(tonumber(mission.xp) or 0)))
	player:SetAttribute(QUEST_LAST_COMPLETED_AT_ATTR, nowMillis())
end

function Service:GetPlayerSnapshot(player)
	local data = self:_ensurePlayerData(player)
	if not data then
		return nil
	end
	local royalConfig = getRoyalPassConfig()
	local pass = data.royalPass
	local tier = math.clamp(math.floor(tonumber(pass.tier) or 0), 0, royalConfig.TOTAL_TIERS)
	local totalXP = (tier * royalConfig.XP_PER_TIER) + (pass.xp or 0)
	local unlockedTiers = {}
	for index = 1, tier do
		table.insert(unlockedTiers, index)
	end

	local nextTier = tier < royalConfig.TOTAL_TIERS and (tier + 1) or nil
	local nextReward = nil
	if nextTier and royalConfig.TIERS[nextTier] then
		local freeReward = royalConfig.TIERS[nextTier].free or {}
		nextReward = {
			currency = math.max(0, math.floor(tonumber(freeReward.mm or freeReward.currency) or 0)),
			xp = math.max(0, math.floor(tonumber(freeReward.xp) or 0)),
		}
	end

	local snapshot = {
		userId = toUserId(player),
		seasonId = royalConfig.SEASON_ID or ("S" .. tostring(pass.season or 1)),
		totalXP = totalXP,
		currentTier = math.max(1, tier),
		maxTier = royalConfig.TOTAL_TIERS,
		xpPerTier = royalConfig.XP_PER_TIER,
		currentTierXP = math.clamp(pass.xp or 0, 0, royalConfig.XP_PER_TIER),
		remainingXP = tier >= royalConfig.TOTAL_TIERS and 0 or math.max(0, royalConfig.XP_PER_TIER - (pass.xp or 0)),
		progressPercent = royalConfig.XP_PER_TIER > 0 and math.clamp((pass.xp or 0) / royalConfig.XP_PER_TIER, 0, 1) or 0,
		premiumOwned = pass.owned == true,
		unlockedTiers = unlockedTiers,
		unlockedTierCount = #unlockedTiers,
		nextTier = nextTier,
		nextReward = nextReward,
	}

	self:_stampRoyalPassRuntime(player, snapshot)
	return snapshot
end

function Service:_stampRoyalPassRuntime(player, snapshot)
	if not player or type(snapshot) ~= "table" then
		return
	end
	player:SetAttribute("PasrahRoyalPassOwner", "DailyEngagementSystem")
	player:SetAttribute("PasrahRoyalPassSeasonId", snapshot.seasonId)
	player:SetAttribute("PasrahRoyalPassTotalXP", snapshot.totalXP)
	player:SetAttribute("PasrahRoyalPassCurrentTier", snapshot.currentTier)
	player:SetAttribute("PasrahRoyalPassCurrentTierXP", snapshot.currentTierXP)
	player:SetAttribute("PasrahRoyalPassRemainingXP", snapshot.remainingXP)
	player:SetAttribute("PasrahRoyalPassProgressPercent", snapshot.progressPercent)
	player:SetAttribute("PasrahRoyalPassPremiumOwned", snapshot.premiumOwned == true)
	player:SetAttribute("PasrahRoyalPassUnlockedTierCount", snapshot.unlockedTierCount)
	player:SetAttribute("PasrahRoyalPassNextTier", snapshot.nextTier)
	player:SetAttribute("PasrahRoyalPassUpdatedAt", os.clock())
end

function Service:BuildClientSnapshot(player)
	local data = self:_ensurePlayerData(player)
	if not data then
		return nil
	end
	return {
		missions = clone(data.daily.missions or {}),
		checkin = {
			streakCount = data.daily.streakCount or 0,
			totalDays = data.daily.totalLoginDays or 0,
			lastDate = data.daily.lastCheckinDate or "",
		},
		royalPass = self:GetPlayerSnapshot(player),
		gacha = clone(data.gacha or {}),
		gachaTickets = data.gachaTickets or 0,
	}
end

function Service:_sendRoyalPassSnapshot(player, eventName, extraPayload)
	local payload = {
		eventName = eventName or "RoyalPassSnapshot",
		snapshot = self:GetPlayerSnapshot(player),
	}
	if type(extraPayload) == "table" then
		for key, value in pairs(extraPayload) do
			payload[key] = value
		end
	end
	self:_sendRemote(player, ROYAL_PASS_LEGACY_REMOTE_NAME, payload)
end

function Service:_syncToClient(player)
	if not player then
		return
	end
	self:_stampQuestRuntime(player)
	self:GetPlayerSnapshot(player)
	self:_sendRemote(player, DAILY_SYNC_REMOTE_NAME, {
		eventName = "DailyEngagementSync",
		snapshot = self:BuildClientSnapshot(player),
	})
end

function Service:_getMatchPlayerCount(payload)
	if type(payload) ~= "table" then
		return 0
	end
	if type(payload.players) == "table" then
		return #payload.players
	end
	if type(payload.playerOutcome) == "table" then
		local count = 0
		for _ in pairs(payload.playerOutcome) do
			count += 1
		end
		return count
	end
	return payload.player and 1 or 0
end

function Service:_collectMatchEntries(payload)
	local entries = {}
	if type(payload) ~= "table" then
		return entries
	end

	if payload.player then
		table.insert(entries, {
			player = payload.player,
			outcome = payload,
		})
		return entries
	end

	if type(payload.playerOutcome) == "table" then
		for _, outcome in pairs(payload.playerOutcome) do
			if type(outcome) == "table" and outcome.player then
				table.insert(entries, {
					player = outcome.player,
					outcome = outcome,
				})
			end
		end
	end

	if #entries == 0 and type(payload.results) == "table" and type(payload.results.playerResults) == "table" then
		for _, result in ipairs(payload.results.playerResults) do
			local player = result.player or result.userId
			if player then
				table.insert(entries, {
					player = player,
					outcome = result,
				})
			end
		end
	end

	if #entries == 0 and type(payload.players) == "table" then
		for _, player in ipairs(payload.players) do
			table.insert(entries, {
				player = player,
				outcome = {},
			})
		end
	end

	return entries
end

function Service:OnMatchStarted(payload)
	if type(payload) ~= "table" then
		return
	end
	local players = type(payload.players) == "table" and payload.players or {}
	local host = payload.host or payload.leader or players[1]
	if host then
		self:UpdateMissionProgress(host, "HOST_MATCH", 1, payload)
	end
end

function Service:OnMatchEnded(payload)
	if type(payload) ~= "table" then
		return
	end

	local royalConfig = getRoyalPassConfig()
	local matchPlayerCount = self:_getMatchPlayerCount(payload)
	local isRanked = payload.isRanked == true or payload.mode == "Ranked" or payload.gameMode == "Ranked"
	local completed = payload.completed ~= false
	local mapId = payload.mapId or payload.map
	local allSurvived = (tonumber(payload.playersDead) or 0) <= 0
	local allEvidenceCollected = payload.allEvidenceCollected == true or (tonumber(payload.evidenceCollected) or 0) >= 3

	for _, entry in ipairs(self:_collectMatchEntries(payload)) do
		local player = toPlayer(entry.player)
		if not player then
			continue
		end

		local outcome = entry.outcome or {}
		local died = outcome.died == true or outcome.survived == false
		local didWin = outcome.didWin == true or payload.teamSuccess == true or payload.contractSuccess == true or payload.extractionCompleted == true
		local ghostIdentified = outcome.correctGhostIdentification == true
			or outcome.ghostIdentifiedCorrectly == true
			or outcome.correctGuess == true
			or payload.correctGuess == true
			or payload.ghostIdentified == true

		local metadata = clone(payload)
		metadata.player = player
		metadata.mapId = mapId
		metadata.partySize = math.max(0, matchPlayerCount - 1)
		metadata.isSolo = matchPlayerCount <= 1
		metadata.completed = completed
		metadata.died = died
		metadata.isRanked = isRanked
		metadata.isWin = didWin
		metadata.allSurvived = allSurvived
		metadata.allEvidenceCollected = allEvidenceCollected
		metadata.finalSanity = outcome.finalSanity or payload.finalSanity

		if completed then
			self:UpdateMissionProgress(player, "MATCH_COMPLETE", 1, metadata)
			self:_grantRoyalPassXP(player, royalConfig.XP_SOURCES.MATCH_COMPLETE, "MatchComplete")
		end
		if ghostIdentified then
			self:UpdateMissionProgress(player, "GHOST_IDENTIFIED", 1, metadata)
			self:_grantRoyalPassXP(player, royalConfig.XP_SOURCES.GHOST_IDENTIFIED, "GhostIdentified")
		end
		if completed and not died then
			self:UpdateMissionProgress(player, "MATCH_NO_DEATH", 1, metadata)
		end
		if metadata.finalSanity then
			self:UpdateMissionProgress(player, "FINISH_HIGH_SANITY", 1, metadata)
		end
		if completed and mapId then
			self:UpdateMissionProgress(player, "MATCH_ON_MAP", 1, metadata)
		end
		if completed and payload.difficulty then
			self:UpdateMissionProgress(player, "MATCH_DIFFICULTY", 1, metadata)
		end
		if completed and ghostIdentified and allSurvived then
			self:UpdateMissionProgress(player, "PERFECT_MATCH", 1, metadata)
		end
		if allEvidenceCollected then
			self:UpdateMissionProgress(player, "ALL_EVIDENCE_IN_MATCH", 1, metadata)
		end
		if completed and metadata.isSolo then
			self:UpdateMissionProgress(player, "SOLO_MATCH_COMPLETE", 1, metadata)
		end
		if completed and metadata.partySize > 0 then
			self:UpdateMissionProgress(player, "MATCH_WITH_PARTY", 1, metadata)
		end
		if completed and isRanked then
			self:UpdateMissionProgress(player, "RANKED_MATCH", 1, metadata)
			if didWin then
				self:_grantRoyalPassXP(player, royalConfig.XP_SOURCES.RANKED_WIN, "RankedWin")
			end
		end

		self:_updateWinStreak(player, didWin, metadata)
	end
end

function Service:_updateWinStreak(player, didWin, metadata)
	local userId = toUserId(player)
	if not userId then
		return
	end
	local streaks = self._state:Get("winStreakByUserId") or {}
	if didWin == true then
		streaks[userId] = (streaks[userId] or 0) + 1
	else
		streaks[userId] = 0
	end
	self._state:Set("winStreakByUserId", streaks)
	if streaks[userId] > 0 then
		self:UpdateMissionProgress(player, "WIN_STREAK", streaks[userId], metadata)
	end
end

function Service:OnEvidenceCollected(payload)
	if type(payload) ~= "table" or not payload.player then
		return
	end
	self:UpdateMissionProgress(payload.player, "EVIDENCE_COLLECTED", 1, payload)

	local userId = toUserId(payload.player)
	local matchId = payload.matchId
	if not userId or not matchId then
		return
	end
	local counts = self._state:Get("evidenceCountByUserMatch") or {}
	counts[userId] = counts[userId] or {}
	counts[userId][matchId] = (counts[userId][matchId] or 0) + 1
	self._state:Set("evidenceCountByUserMatch", counts)

	if counts[userId][matchId] >= 3 then
		self:UpdateMissionProgress(payload.player, "ALL_EVIDENCE_IN_MATCH", 1, payload)
	end
end

function Service:OnGhostIdentified(payload)
	if type(payload) == "table" and payload.player then
		self:UpdateMissionProgress(payload.player, "GHOST_IDENTIFIED", 1, payload)
	end
end

function Service:OnHuntSurvived(payload)
	if type(payload) == "table" and payload.player then
		self:UpdateMissionProgress(payload.player, "SURVIVE_HUNT", 1, payload)
	end
end

function Service:OnHideSuccess(payload)
	if type(payload) == "table" and payload.player then
		self:UpdateMissionProgress(payload.player, "HIDE_SUCCESS", 1, payload)
	end
end

function Service:OnToolUsed(payload)
	if type(payload) ~= "table" or not payload.player then
		return
	end
	local toolMetadata = clone(payload)
	toolMetadata.toolId = toolMetadata.toolId or toolMetadata.toolType or toolMetadata.action or "Flashlight"
	self:UpdateMissionProgress(payload.player, "TOOL_USED", 1, toolMetadata)
	self:UpdateMissionProgress(payload.player, "TOOLS_VARIETY", 1, toolMetadata)
end

return Service

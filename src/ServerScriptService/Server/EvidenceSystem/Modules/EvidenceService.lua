local EvidenceEngine = require(script.Parent.EvidenceEngine)
local EvidenceSpawner = require(script.Parent.EvidenceSpawner)
local EvidenceValidator = require(script.Parent.EvidenceValidator)
local EvidenceTracker = require(script.Parent.EvidenceTracker)
local EvidenceDeduction = require(script.Parent.EvidenceDeduction)
local EvidenceDataTypes = require(script.Parent.EvidenceDataTypes)
local EvidenceRandomizer = require(script.Parent.Parent.EvidenceRandomizer)
local UtilityToolVisuals = require(script.Parent.UtilityToolVisuals)
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

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

local function getByPath(root, path)
    local node = root
    for _, segment in ipairs(path) do
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

local function resolveSharedModule(path)
    local cursor = script
    while cursor do
        local shared = cursor:FindFirstChild("shared") or cursor:FindFirstChild("Shared")
        if shared then
            local moduleScript = getByPath(shared, path)
            local result = safeRequire(moduleScript)
            if result then
                return result
            end
        end
        cursor = cursor.Parent
    end

    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if ok and typeof(replicatedStorage) == "Instance" then
        local shared = replicatedStorage:FindFirstChild("shared") or replicatedStorage:FindFirstChild("Shared")
        if shared then
            local moduleScript = getByPath(shared, path)
            return safeRequire(moduleScript)
        end
    end
    return nil
end

local GhostDatabase = resolveSharedModule({ "GameData", "GhostDatabase" })
local EvidenceConfig = resolveSharedModule({ "GameData", "EvidenceConfig" })
local EvidenceTypesModule = resolveSharedModule({ "DataTypes", "Evidence", "EvidenceTypes", "ModuleScript" })
local Services = require(script.Parent.Parent.Parent.Core.Services)

local EvidenceService = {}

local function normalizeToken(value)
    if type(value) ~= "string" then
        return nil
    end
    return value
        :gsub("[%s_%-]+", "")
        :gsub("[^%w]", "")
        :lower()
end

local EVIDENCE_ALIAS_TO_EVIDENCE = {}
if type(EvidenceConfig) == "table" then
    for key, def in pairs(EvidenceConfig) do
        if type(def) == "table" then
            local token = normalizeToken(key)
            local canonical = type(def.evidenceType) == "string" and def.evidenceType or key
            if token and canonical then
                EVIDENCE_ALIAS_TO_EVIDENCE[token] = canonical
            end
            if type(def.evidenceName) == "string" then
                local namedToken = normalizeToken(def.evidenceName)
                if namedToken and canonical then
                    EVIDENCE_ALIAS_TO_EVIDENCE[namedToken] = canonical
                end
            end
            if type(def.aliases) == "table" then
                for _, alias in ipairs(def.aliases) do
                    local aliasToken = normalizeToken(alias)
                    if aliasToken and canonical then
                        EVIDENCE_ALIAS_TO_EVIDENCE[aliasToken] = canonical
                    end
                end
            end
        end
    end
end

local ALL_EVIDENCE_TYPES = {}
if type(EvidenceTypesModule) == "table" then
    for _, evidenceType in pairs(EvidenceTypesModule) do
        if type(evidenceType) == "string" then
            table.insert(ALL_EVIDENCE_TYPES, evidenceType)
        end
    end
end
EvidenceService.__index = EvidenceService

local TOOL_TO_EVIDENCE = {
	BolaArwah = "To'un",
	BukuTerkutuk = "BukuTerkutuk",
	GerakanGaib = "Pengganggu",
	JejakEnergi = "MEDOK",
	KotakArwah = "Suara",
	SuhuMembeku = "Suhu",
}

local UTILITY_TOOL_TYPES = {
	Dupa = true,
	Garam = true,
	Salib = true,
}

local UTILITY_TOOL_CONFIG = {
	Dupa = {
		durationSeconds = 20,
		repelDistance = 12,
		sanityRestore = 10,
		maxUsesPerPlayer = 2,
	},
	Garam = {
		durationSeconds = 180,
		immediateTriggerDistance = 8,
		maxPlacements = 6,
		maxUsesPerPlayer = 3,
	},
	Salib = {
		charges = 3,
		durationSeconds = 180,
		maxUsesPerPlayer = 2,
	},
}

local UTILITY_TOOL_PLACEMENT = {
	Dupa = {
		forwardOffset = 2.2,
		heightOffset = 0.12,
	},
	Garam = {
		forwardOffset = 3.6,
		heightOffset = 0.06,
	},
	Salib = {
		forwardOffset = 2.8,
		heightOffset = 0.12,
	},
}

local EVIDENCE_ALIASES = {
	medok = "MEDOK",
	jejakenergi = "MEDOK",
	suara = "Suara",
	kotakarwah = "Suara",
	suhu = "Suhu",
	suhumembeku = "Suhu",
	toun = "To'un",
	bolaarwah = "To'un",
	pengganggu = "Pengganggu",
	gerakangaib = "Pengganggu",
	motionsensor = "Pengganggu",
	bukuterkutuk = "BukuTerkutuk",
}

local function normalizeGhostTypeKey(ghostType)
	if type(ghostType) ~= "string" then
		return nil
	end
	return ghostType:gsub("[%s_%-]+", ""):lower()
end

local function normalizeEvidenceType(evidenceType)
	if type(evidenceType) ~= "string" then
		return nil
	end
	local token = evidenceType:gsub("[%s_%-]+", ""):lower()
	token = token:gsub("[^%w]", "")
	return EVIDENCE_ALIASES[token] or EVIDENCE_ALIAS_TO_EVIDENCE[token] or evidenceType
end

local function normalizeEvidenceList(list)
	local out = {}
	local seen = {}
	for _, evidenceType in ipairs(list or {}) do
		local canonical = normalizeEvidenceType(evidenceType)
		if type(canonical) == "string" and canonical ~= "" and not seen[canonical] then
			seen[canonical] = true
			table.insert(out, canonical)
		end
	end
	table.sort(out)
	return out
end

local function resolveUserId(player)
	if type(player) == "number" then
		return player
	end
	if typeof(player) == "Instance" and player:IsA("Player") then
		return player.UserId
	end
	return nil
end

local function resolveRequestedRoomId(payload, ghostState)
	local roomId = payload and (payload.roomId or payload.targetRoomId or payload.room)
	if type(roomId) == "string" and roomId ~= "" then
		return roomId
	end

	if payload and payload.nearGhostRoom == true and type(ghostState) == "table" then
		local ghostRoomId = ghostState.currentRoomId or ghostState.favoriteRoomId
		if type(ghostRoomId) == "string" and ghostRoomId ~= "" then
			return ghostRoomId
		end
	end

	return nil
end

local function roomsMatch(roomA, roomB)
	if type(roomA) ~= "string" or roomA == "" then
		return false
	end
	if type(roomB) ~= "string" or roomB == "" then
		return false
	end
	return tostring(roomA) == tostring(roomB)
end

local function isWithinDistance(rawDistance, threshold)
	local distance = tonumber(rawDistance)
	return distance ~= nil and distance <= threshold
end

local function resolveRequestedPosition(rawPosition)
	if typeof(rawPosition) == "Vector3" then
		return rawPosition
	end
	if type(rawPosition) ~= "table" then
		return nil
	end

	local x = tonumber(rawPosition.x or rawPosition.X or rawPosition[1])
	local y = tonumber(rawPosition.y or rawPosition.Y or rawPosition[2])
	local z = tonumber(rawPosition.z or rawPosition.Z or rawPosition[3])
	if x == nil or y == nil or z == nil then
		return nil
	end
	return Vector3.new(x, y, z)
end

local function resolveCharacterRootPart(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return nil
	end
	local character = player.Character
	if typeof(character) ~= "Instance" then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	if character.PrimaryPart and character.PrimaryPart:IsA("BasePart") then
		return character.PrimaryPart
	end
	local head = character:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		return head
	end
	return nil
end

local function resolveUtilityPlacementCFrame(player, toolType, requestPayload)
	local config = UTILITY_TOOL_PLACEMENT[toolType] or UTILITY_TOOL_PLACEMENT.Garam
	local requestedPosition = resolveRequestedPosition(requestPayload and requestPayload.targetPosition)
	local rootPart = resolveCharacterRootPart(player)
	local flatLook = Vector3.new(0, 0, -1)
	if rootPart then
		local rootLook = rootPart.CFrame.LookVector
		local horizontalLook = Vector3.new(rootLook.X, 0, rootLook.Z)
		if horizontalLook.Magnitude > 0.001 then
			flatLook = horizontalLook.Unit
		end
	end

	local basePosition = requestedPosition
	if not basePosition then
		if rootPart then
			basePosition = rootPart.Position + flatLook * (config.forwardOffset or 3)
		else
			basePosition = Vector3.new(0, config.heightOffset or 0.12, 0)
		end
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = {}
	if rootPart and rootPart.Parent then
		table.insert(raycastParams.FilterDescendantsInstances, rootPart.Parent)
	end

	local rayOrigin = basePosition + Vector3.new(0, 6, 0)
	local rayResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -20, 0), raycastParams)
	local groundPosition = rayResult and rayResult.Position or basePosition
	local finalPosition = Vector3.new(
		groundPosition.X,
		groundPosition.Y + (config.heightOffset or 0.12),
		groundPosition.Z
	)
	return CFrame.lookAt(finalPosition, finalPosition + flatLook)
end

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

local function resolveGhostService(deps)
	local ghostSystem = Services.Get(deps, "GhostSystem")
	if type(ghostSystem) ~= "table" then
		return nil
	end
	if type(ghostSystem.GetGhostState) == "function" then
		return ghostSystem
	end
	if type(ghostSystem.Service) == "table" and type(ghostSystem.Service.GetGhostState) == "function" then
		return ghostSystem.Service
	end
	return nil
end

local function resolveSanityService(deps)
	local sanitySystem = Services.Get(deps, "SanitySystem")
	if type(sanitySystem) ~= "table" then
		return nil
	end
	if type(sanitySystem.RestoreSanity) == "function" then
		return sanitySystem
	end
	if type(sanitySystem.Service) == "table" and type(sanitySystem.Service.RestoreSanity) == "function" then
		return sanitySystem.Service
	end
	return nil
end

local function resolveInventoryService(deps)
	local inventory = Services.Get(deps, "InventorySystem")
	if type(inventory) ~= "table" then
		return nil
	end
	if type(inventory.HasItem) == "function" then
		return inventory
	end
	if type(inventory.Service) == "table" and type(inventory.Service.HasItem) == "function" then
		return inventory.Service
	end
	return nil
end

local function resolveEvidenceConfigSystem(deps)
	local evidenceConfig = Services.Get(deps, "EvidenceConfigSystem")
	if type(evidenceConfig) ~= "table" then
		return nil
	end
	if type(evidenceConfig.GetEvidenceCombinations) == "function" then
		return evidenceConfig
	end
	if type(evidenceConfig.Service) == "table" and type(evidenceConfig.Service.GetEvidenceCombinations) == "function" then
		return evidenceConfig.Service
	end
	return nil
end

local function resolveEvidenceSync(deps)
	local evidenceSync = Services.Get(deps, "EvidenceSync")
	if type(evidenceSync) ~= "table" then
		return nil
	end
	if type(evidenceSync.PushUpdate) == "function" then
		return evidenceSync
	end
	if type(evidenceSync.Service) == "table" and type(evidenceSync.Service.PushUpdate) == "function" then
		return evidenceSync.Service
	end
	return nil
end


function EvidenceService:_resolveGhostEvidence(ghostType)
    if type(GhostDatabase) ~= "table" or type(ghostType) ~= "string" then
        return nil
    end
    local ghostData = GhostDatabase[ghostType]
    if type(ghostData) ~= "table" then
        return nil
    end
    local evidenceList = {}
    local seen = {}
    for _, evidenceKey in ipairs(ghostData.evidenceTypes or {}) do
        local token = normalizeToken(evidenceKey)
        local mapped = token and EVIDENCE_ALIAS_TO_EVIDENCE[token] or nil
        if mapped and not seen[mapped] then
            seen[mapped] = true
            table.insert(evidenceList, mapped)
        end
    end
    return evidenceList
end

function EvidenceService:_applyGhostEvidencePool(matchId, ghostType)
    local session = self._engine:GetSession(matchId)
    if not session then
        return
    end

    local evidenceList = self:_resolveGhostEvidence(ghostType)
    if type(evidenceList) ~= "table" or #evidenceList == 0 then
        return
    end

    local rng = self._rngByMatchId and self._rngByMatchId[matchId] or self._deps.Random or Random.new()
    local difficultyMode = session.difficultyMode
    local evidencePool = {}
    local validationEvidence = {}
    local supplementalEvidence = {}

    for _, evidenceType in ipairs(evidenceList) do
        table.insert(evidencePool, evidenceType)
        table.insert(validationEvidence, evidenceType)
    end

    if difficultyMode == "Hard" and #evidenceList > 2 then
        local firstIndex = rng:NextInteger(1, #evidenceList)
        local secondIndex = firstIndex
        while secondIndex == firstIndex do
            secondIndex = rng:NextInteger(1, #evidenceList)
        end
        evidencePool = { evidenceList[firstIndex], evidenceList[secondIndex] }
        validationEvidence = { evidenceList[firstIndex], evidenceList[secondIndex] }
    elseif difficultyMode == "Easy" then
        for _, evidenceType in ipairs(ALL_EVIDENCE_TYPES) do
            local inList = false
            for _, current in ipairs(evidenceList) do
                if current == evidenceType then
                    inList = true
                    break
                end
            end
            if not inList then
                table.insert(supplementalEvidence, evidenceType)
            end
        end
    end

    session.ghostEvidence = evidenceList
    session.evidencePool = evidencePool
    session.supplementalEvidence = supplementalEvidence
    session.validationEvidence = validationEvidence
end

function EvidenceService:_computeDeductionCandidates(matchId)
    local session = self._engine:GetSession(matchId)
    if not session or type(GhostDatabase) ~= "table" then
        return {}
    end

    local collected = session.collectedEvidence or {}
    local collectedSet = {}
    for _, evidenceType in ipairs(collected) do
        collectedSet[evidenceType] = true
    end

    local candidates = {}
    for ghostType, ghostData in pairs(GhostDatabase) do
        if type(ghostData) == "table" then
            local evidenceList = self:_resolveGhostEvidence(ghostType) or {}
            local evidenceSet = {}
            for _, evidenceType in ipairs(evidenceList) do
                evidenceSet[evidenceType] = true
            end

            local matches = true
            for evidenceType in pairs(collectedSet) do
                if not evidenceSet[evidenceType] then
                    matches = false
                    break
                end
            end

            if matches then
                table.insert(candidates, ghostType)
            end
        end
    end

    table.sort(candidates)
    return candidates
end
function EvidenceService.new(state, deps)
	local self = setmetatable({}, EvidenceService)
	self._state = state
	self._deps = deps or {}
	self._dataTypes = EvidenceDataTypes.Resolve(self._deps)
	self._eventBus = resolveEventBus(self._deps)
	self._ghostService = resolveGhostService(self._deps)
	self._sanityService = resolveSanityService(self._deps)
	self._inventoryService = resolveInventoryService(self._deps)
	self._evidenceSync = resolveEvidenceSync(self._deps)
	self._evidenceConfigSystem = resolveEvidenceConfigSystem(self._deps)

	self._deduction = EvidenceDeduction.new(self._dataTypes.EvidenceGhostMap)
	self._tracker = EvidenceTracker.new()
	self._spawner = EvidenceSpawner.new({
		Random = self._deps.Random,
		EvidenceTypes = self._dataTypes.EvidenceTypes,
		EvidenceRules = self._dataTypes.EvidenceRules,
	})
	self._validator = EvidenceValidator.new({
		Deduction = self._deduction,
		EvidenceRules = self._dataTypes.EvidenceRules,
	})
	self._rngByMatchId = {}
	self._randomizer = EvidenceRandomizer.new({
		Random = self._deps.Random,
		EvidenceRandomizerConfig = self._deps.EvidenceRandomizerConfig,
	})
	self._utilityVisuals = UtilityToolVisuals.new()
	self._engine = EvidenceEngine.new({
		Spawner = self._spawner,
		Validator = self._validator,
		Tracker = self._tracker,
		Deduction = self._deduction,
		EvidenceTypes = self._dataTypes.EvidenceTypes,
	})

	return self
end

function EvidenceService:_sync(matchId, eventType, payload)
	if self._evidenceSync then
		self._evidenceSync:PushUpdate(matchId, eventType, payload)
	end
end

function EvidenceService:Init()
	self._state:Set("evidenceMatches", {})
	self._state:Set("utilityToolsByMatch", {})
	self._randomizer:Reset()
	self._rngByMatchId = {}
	self._utilityVisuals:ClearAll()
end

function EvidenceService:Start()
	-- Runtime ticks are driven by controller events.
end

function EvidenceService:Stop()
	self._engine:Reset()
	self._randomizer:Reset()
	self._rngByMatchId = {}
	self._utilityVisuals:ClearAll()
	self._state:Set("evidenceMatches", {})
	self._state:Set("utilityToolsByMatch", {})
end

function EvidenceService:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function EvidenceService:_resolveEvidenceCombinations()
	if not self._evidenceConfigSystem then
		return {}
	end
	local combinations = self._evidenceConfigSystem:GetEvidenceCombinations()
	if type(combinations) ~= "table" then
		return {}
	end
	return combinations
end

function EvidenceService:_resolveCombinationForGhost(combinations, ghostType)
	if type(ghostType) ~= "string" then
		return nil
	end

	local direct = combinations[ghostType]
	if type(direct) == "table" then
		return normalizeEvidenceList(direct)
	end

	local normalizedGhostType = normalizeGhostTypeKey(ghostType)
	if not normalizedGhostType then
		return nil
	end

	for candidateGhostType, evidenceList in pairs(combinations) do
		if normalizeGhostTypeKey(candidateGhostType) == normalizedGhostType and type(evidenceList) == "table" then
			return normalizeEvidenceList(evidenceList)
		end
	end

	return nil
end

function EvidenceService:_resolveCombinationCandidates(combinations, collectedEvidence)
	local canonicalCollected = normalizeEvidenceList(collectedEvidence)
	local collectedSet = {}
	for _, evidenceType in ipairs(canonicalCollected) do
		collectedSet[evidenceType] = true
	end

	local candidateGhosts = {}
	local exactMatches = {}

	for ghostType, expectedEvidence in pairs(combinations) do
		local normalizedExpected = normalizeEvidenceList(expectedEvidence)
		local expectedSet = {}
		for _, evidenceType in ipairs(normalizedExpected) do
			expectedSet[evidenceType] = true
		end

		local possible = true
		for evidenceType in pairs(collectedSet) do
			if not expectedSet[evidenceType] then
				possible = false
				break
			end
		end
		if possible then
			table.insert(candidateGhosts, ghostType)
		end

		local exact = #normalizedExpected == #canonicalCollected
		if exact then
			for evidenceType in pairs(collectedSet) do
				if not expectedSet[evidenceType] then
					exact = false
					break
				end
			end
		end
		if exact then
			table.insert(exactMatches, ghostType)
		end
	end

	table.sort(candidateGhosts)
	table.sort(exactMatches)

	local resolvedGhostType = nil
	if #exactMatches == 1 then
		resolvedGhostType = exactMatches[1]
	end

	return canonicalCollected, candidateGhosts, resolvedGhostType
end

function EvidenceService:_publishCombinationResolution(player, matchId, now)
	local combinations = self:_resolveEvidenceCombinations()
	if next(combinations) == nil then
		return
	end

	local session = self._engine:GetSession(matchId)
	if not session then
		return
	end

	local canonicalCollected, candidateGhosts, resolvedGhostType =
		self:_resolveCombinationCandidates(combinations, session.collectedEvidence)

	self:_publish("EvidenceCombinationResolved", {
		player = player,
		userId = player and player.UserId or nil,
		matchId = matchId,
		collectedEvidence = canonicalCollected,
		possibleGhosts = candidateGhosts,
		resolvedGhostType = resolvedGhostType,
		now = now,
	})
	self:_publish("GhostCandidatesUpdated", {
		player = player,
		userId = player and player.UserId or nil,
		matchId = matchId,
		candidates = candidateGhosts,
		discoveredEvidence = canonicalCollected,
	})
end

function EvidenceService:_validateCombinationJournalGuess(matchId, payload)
	local combinations = self:_resolveEvidenceCombinations()
	if next(combinations) == nil then
		return nil
	end

	local session = self._engine:GetSession(matchId)
	if not session then
		return nil
	end

	local expectedEvidence = self:_resolveCombinationForGhost(combinations, session.ghostType)
	if type(expectedEvidence) ~= "table" then
		return nil
	end

	local guessedGhostType = payload and payload.ghostType or ""
	local guessedEvidence = normalizeEvidenceList(payload and payload.evidence or {})
	local guessedEvidenceSet = {}
	for _, evidenceType in ipairs(guessedEvidence) do
		guessedEvidenceSet[evidenceType] = true
	end

	local expectedEvidenceSet = {}
	for _, evidenceType in ipairs(expectedEvidence) do
		expectedEvidenceSet[evidenceType] = true
	end

	local evidenceMatches = #guessedEvidence == #expectedEvidence
	if evidenceMatches then
		for evidenceType in pairs(expectedEvidenceSet) do
			if not guessedEvidenceSet[evidenceType] then
				evidenceMatches = false
				break
			end
		end
	end

	local ghostMatches = normalizeGhostTypeKey(guessedGhostType) == normalizeGhostTypeKey(session.ghostType)
	local identified = ghostMatches and evidenceMatches

	return {
		matchId = matchId,
		guessedGhostType = guessedGhostType,
		actualGhostType = session.ghostType,
		ghostMatches = ghostMatches,
		evidenceMatches = evidenceMatches,
		identified = identified,
		expectedEvidence = expectedEvidence,
		guessedEvidence = guessedEvidence,
		difficultyMode = session.difficultyMode,
	}
end

function EvidenceService:_getGhostState(matchId)
	if not self._ghostService then
		return nil
	end
	return self._ghostService:GetGhostState(matchId)
end

function EvidenceService:_getUtilityToolsByMatch()
	local utilityToolsByMatch = self._state:Get("utilityToolsByMatch")
	if type(utilityToolsByMatch) ~= "table" then
		utilityToolsByMatch = {}
		self._state:Set("utilityToolsByMatch", utilityToolsByMatch)
	end
	return utilityToolsByMatch
end

function EvidenceService:_getUtilityState(matchId)
	local utilityToolsByMatch = self:_getUtilityToolsByMatch()
	local utilityState = utilityToolsByMatch[matchId]
	if type(utilityState) ~= "table" then
		utilityState = {
			crucifixPlacements = {},
			playerToolStocks = {},
			saltPlacements = {},
			smudgeEffects = {},
		}
		utilityToolsByMatch[matchId] = utilityState
		self._state:Set("utilityToolsByMatch", utilityToolsByMatch)
	end
	if type(utilityState.playerToolStocks) ~= "table" then
		utilityState.playerToolStocks = {}
	end
	return utilityState
end

function EvidenceService:_saveUtilityState(matchId, utilityState)
	local utilityToolsByMatch = self:_getUtilityToolsByMatch()
	utilityToolsByMatch[matchId] = utilityState
	self._state:Set("utilityToolsByMatch", utilityToolsByMatch)
end

function EvidenceService:_clearUtilityState(matchId)
	local utilityToolsByMatch = self:_getUtilityToolsByMatch()
	utilityToolsByMatch[matchId] = nil
	self._state:Set("utilityToolsByMatch", utilityToolsByMatch)
end

function EvidenceService:_trimExpiredUtilityState(matchId, now)
	local currentTime = now or os.clock()
	local utilityState = self:_getUtilityState(matchId)

	local activeSaltPlacements = {}
	for _, placement in ipairs(utilityState.saltPlacements or {}) do
		if placement.triggered ~= true and (placement.expiresAt or 0) > currentTime then
			table.insert(activeSaltPlacements, placement)
		end
	end

	local activeCrucifixPlacements = {}
	for _, placement in ipairs(utilityState.crucifixPlacements or {}) do
		if (placement.expiresAt or 0) > currentTime and (placement.chargesRemaining or 0) > 0 then
			table.insert(activeCrucifixPlacements, placement)
		end
	end

	local activeSmudgeEffects = {}
	for _, effect in ipairs(utilityState.smudgeEffects or {}) do
		if (effect.expiresAt or 0) > currentTime then
			table.insert(activeSmudgeEffects, effect)
		end
	end

	utilityState.saltPlacements = activeSaltPlacements
	utilityState.crucifixPlacements = activeCrucifixPlacements
	utilityState.smudgeEffects = activeSmudgeEffects
	self:_saveUtilityState(matchId, utilityState)
	return utilityState
end

function EvidenceService:_generatePlacementId(toolType)
	return string.format("%s_%s", tostring(toolType or "Tool"), HttpService:GenerateGUID(false))
end

function EvidenceService:_playerOwnsItem(player, itemId)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false
	end
	if type(itemId) ~= "string" or itemId == "" then
		return false
	end
	if type(self._inventoryService) ~= "table" or type(self._inventoryService.HasItem) ~= "function" then
		return false
	end
	local ok, result = pcall(function()
		return self._inventoryService:HasItem(player, itemId)
	end)
	return ok and result == true
end

function EvidenceService:_getDefaultToolStock(toolType, player)
	local config = UTILITY_TOOL_CONFIG[toolType]
	local stock = config and tonumber(config.maxUsesPerPlayer) or nil
	if stock == nil then
		return 0
	end
	if toolType == "Garam" and self:_playerOwnsItem(player, "eq_saltbag_reinforced") then
		stock += 1
	end
	return math.max(0, math.floor(stock))
end

function EvidenceService:_consumePlayerToolStock(matchId, player, userId, toolType)
	if type(userId) ~= "number" or userId <= 0 then
		return false, "invalid_player", 0
	end

	local utilityState = self:_getUtilityState(matchId)
	local stocksByPlayer = utilityState.playerToolStocks or {}
	local userKey = tostring(userId)
	local userStock = stocksByPlayer[userKey]
	if type(userStock) ~= "table" then
		userStock = {}
		stocksByPlayer[userKey] = userStock
	end

	if userStock[toolType] == nil then
		userStock[toolType] = self:_getDefaultToolStock(toolType, player)
	end

	local current = math.max(0, math.floor(tonumber(userStock[toolType]) or 0))
	if current <= 0 then
		userStock[toolType] = 0
		utilityState.playerToolStocks = stocksByPlayer
		self:_saveUtilityState(matchId, utilityState)
		return false, "tool_out_of_stock", 0
	end

	local remaining = current - 1
	userStock[toolType] = remaining
	utilityState.playerToolStocks = stocksByPlayer
	self:_saveUtilityState(matchId, utilityState)
	return true, nil, remaining
end

function EvidenceService:_placeUtilityVisual(matchId, toolType, placementId, player, requestPayload)
	if not self._utilityVisuals or not matchId or not toolType or not placementId then
		return nil
	end
	local worldCFrame = resolveUtilityPlacementCFrame(player, toolType, requestPayload)
	return self._utilityVisuals:PlaceTool(matchId, toolType, placementId, worldCFrame)
end

function EvidenceService:_destroyUtilityVisual(matchId, placementId)
	if self._utilityVisuals and matchId and placementId then
		self._utilityVisuals:DestroyTool(matchId, placementId)
	end
end

function EvidenceService:_destroyUtilityVisualLater(matchId, placementId, delaySeconds)
	if not matchId or not placementId then
		return
	end
	local delayDuration = tonumber(delaySeconds)
	if delayDuration == nil or delayDuration <= 0 then
		self:_destroyUtilityVisual(matchId, placementId)
		return
	end

	task.delay(delayDuration, function()
		self:_destroyUtilityVisual(matchId, placementId)
	end)
end

function EvidenceService:_resolveGhostRoom(matchId)
	local ghostState = self:_getGhostState(matchId) or {}
	return ghostState.currentRoomId or ghostState.favoriteRoomId, ghostState
end

function EvidenceService:_handleSaltUse(player, matchId, requestPayload)
	local config = UTILITY_TOOL_CONFIG.Garam
	local now = requestPayload.now or os.clock()
	local ghostRoomId, ghostState = self:_resolveGhostRoom(matchId)
	local roomId = resolveRequestedRoomId(requestPayload, ghostState)
	local utilityState = self:_trimExpiredUtilityState(matchId, now)
	local userId = resolveUserId(player)
	local stockOk, stockReason, usesRemaining = self:_consumePlayerToolStock(matchId, player, userId, "Garam")
	if stockOk ~= true then
		return false, stockReason or "tool_out_of_stock", {
			toolType = "Garam",
			usesRemaining = math.max(0, tonumber(usesRemaining) or 0),
		}
	end
	local placementId = self:_generatePlacementId("Garam")

	local placement = {
		expiresAt = now + config.durationSeconds,
		id = placementId,
		placedAt = now,
		player = player,
		roomId = roomId,
		userId = userId,
	}

	if #utilityState.saltPlacements >= config.maxPlacements then
		local removedPlacement = table.remove(utilityState.saltPlacements, 1)
		if removedPlacement and removedPlacement.id then
			self:_destroyUtilityVisual(matchId, removedPlacement.id)
		end
	end
	table.insert(utilityState.saltPlacements, placement)
	local visualPlaced = self:_placeUtilityVisual(matchId, "Garam", placementId, player, requestPayload) ~= nil

	local shouldTriggerImmediately = requestPayload.nearGhostRoom == true
		or isWithinDistance(requestPayload.distanceToGhost, config.immediateTriggerDistance)
		or (roomId ~= nil and roomsMatch(roomId, ghostRoomId))

	if shouldTriggerImmediately then
		table.remove(utilityState.saltPlacements, #utilityState.saltPlacements)
		self:_saveUtilityState(matchId, utilityState)
		self._utilityVisuals:MarkSaltTriggered(matchId, placementId)
		self:_destroyUtilityVisualLater(matchId, placementId, 8)
		self:_publish("SaltTriggered", {
			matchId = matchId,
			now = now,
			placementId = placementId,
			player = player,
			roomId = roomId or ghostRoomId,
			source = "salt_placement",
			toolType = "Garam",
			userId = userId,
			usesRemaining = usesRemaining,
			visualPlaced = visualPlaced,
		})
		return true, "salt_triggered", {
			ghostRoomId = ghostRoomId,
			placementId = placementId,
			placementActive = false,
			roomId = roomId or ghostRoomId,
			toolType = "Garam",
			tracksDetected = true,
			usesRemaining = usesRemaining,
			visualPlaced = visualPlaced,
		}
	end

	self:_saveUtilityState(matchId, utilityState)
	self:_destroyUtilityVisualLater(matchId, placementId, config.durationSeconds)
	self:_publish("SaltPlaced", {
		expiresAt = placement.expiresAt,
		matchId = matchId,
		now = now,
		placementId = placementId,
		player = player,
		roomId = roomId,
		toolType = "Garam",
		userId = userId,
		usesRemaining = usesRemaining,
		visualPlaced = visualPlaced,
	})
	return true, "salt_placed", {
		ghostRoomId = ghostRoomId,
		placementId = placementId,
		placementActive = true,
		roomId = roomId,
		toolType = "Garam",
		tracksDetected = false,
		usesRemaining = usesRemaining,
		visualPlaced = visualPlaced,
	}
end

function EvidenceService:_handleCrucifixUse(player, matchId, requestPayload)
	local config = UTILITY_TOOL_CONFIG.Salib
	local now = requestPayload.now or os.clock()
	local ghostRoomId, ghostState = self:_resolveGhostRoom(matchId)
	local roomId = resolveRequestedRoomId(requestPayload, ghostState)
	local utilityState = self:_trimExpiredUtilityState(matchId, now)
	local userId = resolveUserId(player)
	local stockOk, stockReason, usesRemaining = self:_consumePlayerToolStock(matchId, player, userId, "Salib")
	if stockOk ~= true then
		return false, stockReason or "tool_out_of_stock", {
			toolType = "Salib",
			usesRemaining = math.max(0, tonumber(usesRemaining) or 0),
		}
	end
	local placementId = self:_generatePlacementId("Salib")

	local placement = {
		chargesRemaining = config.charges,
		expiresAt = now + config.durationSeconds,
		id = placementId,
		placedAt = now,
		player = player,
		roomId = roomId,
		userId = userId,
	}

	table.insert(utilityState.crucifixPlacements, placement)
	self:_saveUtilityState(matchId, utilityState)
	local visualPlaced = self:_placeUtilityVisual(matchId, "Salib", placementId, player, requestPayload) ~= nil
	self:_destroyUtilityVisualLater(matchId, placementId, config.durationSeconds)

	self:_publish("CrucifixPlaced", {
		chargesRemaining = placement.chargesRemaining,
		expiresAt = placement.expiresAt,
		matchId = matchId,
		now = now,
		placementId = placementId,
		player = player,
		roomId = roomId,
		toolType = "Salib",
		userId = userId,
		usesRemaining = usesRemaining,
		visualPlaced = visualPlaced,
	})

	return true, "crucifix_armed", {
		chargesRemaining = placement.chargesRemaining,
		expiresAt = placement.expiresAt,
		ghostRoomId = ghostRoomId,
		placementId = placementId,
		placementActive = true,
		roomId = roomId,
		toolType = "Salib",
		usesRemaining = usesRemaining,
		visualPlaced = visualPlaced,
	}
end

function EvidenceService:_handleSmudgeUse(player, matchId, requestPayload)
	local config = UTILITY_TOOL_CONFIG.Dupa
	local now = requestPayload.now or os.clock()
	local ghostRoomId, ghostState = self:_resolveGhostRoom(matchId)
	local roomId = resolveRequestedRoomId(requestPayload, ghostState)
	local utilityState = self:_trimExpiredUtilityState(matchId, now)
	local userId = resolveUserId(player)
	local stockOk, stockReason, usesRemaining = self:_consumePlayerToolStock(matchId, player, userId, "Dupa")
	if stockOk ~= true then
		return false, stockReason or "tool_out_of_stock", {
			toolType = "Dupa",
			usesRemaining = math.max(0, tonumber(usesRemaining) or 0),
		}
	end
	local placementId = self:_generatePlacementId("Dupa")

	local effect = {
		activatedAt = now,
		expiresAt = now + config.durationSeconds,
		id = placementId,
		player = player,
		roomId = roomId,
		userId = userId,
	}

	table.insert(utilityState.smudgeEffects, effect)
	self:_saveUtilityState(matchId, utilityState)
	local visualPlaced = self:_placeUtilityVisual(matchId, "Dupa", placementId, player, requestPayload) ~= nil
	self:_destroyUtilityVisualLater(matchId, placementId, config.durationSeconds)

	local resultingSanity = nil
	if self._sanityService and type(self._sanityService.RestoreSanity) == "function" then
		resultingSanity = self._sanityService:RestoreSanity(player, config.sanityRestore, matchId, "smudge_stick")
	end

	local shouldRepelHunt = requestPayload.nearGhostRoom == true
		or isWithinDistance(requestPayload.distanceToGhost, config.repelDistance)
		or (roomId ~= nil and roomsMatch(roomId, ghostRoomId))
	local huntRepelled = false
	if ghostState.huntActive == true and shouldRepelHunt and self._ghostService and type(self._ghostService.EndHunt) == "function" then
		local ok, ended = pcall(function()
			return self._ghostService:EndHunt(matchId, now)
		end)
		huntRepelled = ok and ended ~= false
	end

	self:_publish("SmudgeActivated", {
		huntRepelled = huntRepelled,
		matchId = matchId,
		now = now,
		placementId = placementId,
		player = player,
		repellentUntil = effect.expiresAt,
		roomId = roomId or ghostRoomId,
		sanityRestored = config.sanityRestore,
		toolType = "Dupa",
		userId = userId,
		usesRemaining = usesRemaining,
		visualPlaced = visualPlaced,
	})

	if huntRepelled then
		self:_publish("GhostRepelled", {
			matchId = matchId,
			now = now,
			placementId = placementId,
			roomId = roomId or ghostRoomId,
			toolType = "Dupa",
			userId = userId,
			visualPlaced = visualPlaced,
		})
	end

	return true, "smudge_activated", {
		ghostRoomId = ghostRoomId,
		huntRepelled = huntRepelled,
		placementId = placementId,
		repellentUntil = effect.expiresAt,
		resultingSanity = resultingSanity,
		roomId = roomId or ghostRoomId,
		sanityRestored = config.sanityRestore,
		toolType = "Dupa",
		usesRemaining = usesRemaining,
		visualPlaced = visualPlaced,
	}
end

function EvidenceService:_processUtilityToolUse(player, matchId, toolType, requestPayload)
	if toolType == "Garam" then
		return self:_handleSaltUse(player, matchId, requestPayload)
	end
	if toolType == "Salib" then
		return self:_handleCrucifixUse(player, matchId, requestPayload)
	end
	if toolType == "Dupa" then
		return self:_handleSmudgeUse(player, matchId, requestPayload)
	end
	return false, "invalid_tool_type", nil
end

function EvidenceService:TryConsumeHuntProtection(matchId, payload)
	if not matchId then
		return false, "missing_match_id", nil
	end

	local now = payload and payload.now or os.clock()
	local ghostRoomId = payload and payload.roomId
	if type(ghostRoomId) ~= "string" or ghostRoomId == "" then
		ghostRoomId = self:_resolveGhostRoom(matchId)
	end

	local utilityState = self:_trimExpiredUtilityState(matchId, now)

	for _, effect in ipairs(utilityState.smudgeEffects or {}) do
		if effect.roomId == nil or roomsMatch(effect.roomId, ghostRoomId) then
			local result = {
				repellentUntil = effect.expiresAt,
				roomId = effect.roomId or ghostRoomId,
				toolType = "Dupa",
			}
			self:_publish("HuntBlocked", {
				matchId = matchId,
				now = now,
				reason = "smudge_repellent_active",
				roomId = result.roomId,
				toolType = "Dupa",
			})
			return true, "smudge_repellent_active", result
		end
	end

	for index, placement in ipairs(utilityState.crucifixPlacements or {}) do
		if placement.roomId == nil or roomsMatch(placement.roomId, ghostRoomId) then
			placement.chargesRemaining = math.max(0, (placement.chargesRemaining or 0) - 1)
			local remaining = placement.chargesRemaining
			if remaining <= 0 then
				table.remove(utilityState.crucifixPlacements, index)
				self:_destroyUtilityVisual(matchId, placement.id)
			else
				self._utilityVisuals:UpdateCrucifixCharges(matchId, placement.id, remaining)
			end
			self:_saveUtilityState(matchId, utilityState)

			local result = {
				chargesRemaining = remaining,
				placementId = placement.id,
				roomId = placement.roomId or ghostRoomId,
				toolType = "Salib",
			}
			self:_publish("CrucifixTriggered", {
				chargesRemaining = remaining,
				matchId = matchId,
				now = now,
				placementId = placement.id,
				roomId = result.roomId,
				toolType = "Salib",
				userId = placement.userId,
			})
			self:_publish("HuntBlocked", {
				chargesRemaining = remaining,
				matchId = matchId,
				now = now,
				placementId = placement.id,
				reason = "crucifix_prevented_hunt",
				roomId = result.roomId,
				toolType = "Salib",
			})
			return true, "crucifix_prevented_hunt", result
		end
	end

	self:_saveUtilityState(matchId, utilityState)
	return false, "no_hunt_protection", nil
end

function EvidenceService:NotifyGhostPresence(matchId, payload)
	if not matchId then
		return nil
	end

	local now = payload and payload.now or os.clock()
	local utilityState = self:_trimExpiredUtilityState(matchId, now)
	local roomId = payload and (payload.roomId or payload.room)
	if type(roomId) ~= "string" or roomId == "" then
		roomId = self:_resolveGhostRoom(matchId)
	end
	if type(roomId) ~= "string" or roomId == "" then
		return nil
	end

	for index, placement in ipairs(utilityState.saltPlacements or {}) do
		if placement.roomId == nil or roomsMatch(placement.roomId, roomId) then
			table.remove(utilityState.saltPlacements, index)
			self:_saveUtilityState(matchId, utilityState)
			self._utilityVisuals:MarkSaltTriggered(matchId, placement.id)
			self:_destroyUtilityVisualLater(matchId, placement.id, 8)
			self:_publish("SaltTriggered", {
				matchId = matchId,
				now = now,
				placementId = placement.id,
				roomId = roomId,
				source = payload and payload.source or "ghost_presence",
				toolType = "Garam",
				userId = placement.userId,
			})
			return {
				placementId = placement.id,
				roomId = roomId,
				toolType = "Garam",
				userId = placement.userId,
			}
		end
	end

	self:_saveUtilityState(matchId, utilityState)
	return nil
end

function EvidenceService:StartMatch(matchId, payload)
	local seed = tonumber(payload and payload.ghostSeed)
	if type(seed) == "number" then
		local rng = Random.new(seed)
		self._rngByMatchId[matchId] = rng
		self._randomizer:SetMatchRng(matchId, rng)
		if type(payload) == "table" then
			payload.rng = rng
		end
	end
	local session = self._engine:StartMatch(matchId, payload)
	self._randomizer:StartMatch(matchId)
	self:_applyGhostEvidencePool(matchId, payload and payload.ghostType)
	local matches = self._state:Get("evidenceMatches") or {}
	matches[matchId] = session
	self._state:Set("evidenceMatches", matches)
	self:_saveUtilityState(matchId, {
		crucifixPlacements = {},
		saltPlacements = {},
		smudgeEffects = {},
	})
	self._utilityVisuals:StartMatch(matchId)
	local candidates = self:_computeDeductionCandidates(matchId)
	session.possibleGhosts = candidates
	self:_publish("DeductionUpdated", { matchId = matchId, candidates = candidates })
	return session
end

function EvidenceService:EndMatch(matchId)
	self._engine:EndMatch(matchId)
	self._randomizer:EndMatch(matchId)
	self._rngByMatchId[matchId] = nil
	local matches = self._state:Get("evidenceMatches") or {}
	matches[matchId] = nil
	self._state:Set("evidenceMatches", matches)
	self._utilityVisuals:ClearMatch(matchId)
	self:_clearUtilityState(matchId)
end

function EvidenceService:SetGhostProfile(matchId, payload)
	if type(payload) == "table" then
		payload.rng = self._rngByMatchId[matchId]
	end
	local session = self._engine:SetGhostProfile(matchId, payload)
	self:_applyGhostEvidencePool(matchId, payload and payload.ghostType)
	local matches = self._state:Get("evidenceMatches") or {}
	matches[matchId] = session
	self._state:Set("evidenceMatches", matches)
	local candidates = self:_computeDeductionCandidates(matchId)
	session.possibleGhosts = candidates
	self:_publish("DeductionUpdated", { matchId = matchId, candidates = candidates })
	return session
end

function EvidenceService:SpawnEvidence(matchId, payload)
	local t0 = tick()
	local function doSpawn(requestPayload)
		local ghostState = self:_getGhostState(matchId)
		local signal, reason = self._engine:TrySpawnEvidence(matchId, requestPayload, {
			ghostState = ghostState,
		})
		if signal then
			self:_sync(matchId, "EvidenceSpawned", {
				evidenceType = signal.evidenceType,
				location = signal.roomId,
				trigger = signal.trigger,
			})
			self:_publish("EvidenceSpawned", {
				matchId = matchId,
				evidenceType = signal.evidenceType,
				location = signal.roomId,
				trigger = signal.trigger,
				source = signal.source,
			})
		end
		return signal, reason
	end

	local rng = self._rngByMatchId[matchId]
	if type(payload) == "table" then
		payload.rng = rng
	end
	local result, reason = self._randomizer:Spawn(matchId, payload or {}, doSpawn, function(eventName, eventPayload)
		self:_publish(eventName, eventPayload)
	end)
	local elapsed = tick() - t0
	if elapsed > 0.1 then
		warn("[PERF] EvidenceService:SpawnEvidence exceeded 100ms: " .. elapsed)
	end
	return result, reason
end

function EvidenceService:ProcessToolUse(player, matchId, payload)
	if not matchId then
		return false, "missing_match_id", nil
	end
	if type(payload) ~= "table" then
		return false, "invalid_payload", nil
	end

	local toolType = payload.toolType
	local requestPayload = payload.payload or {}
	if UTILITY_TOOL_TYPES[toolType] == true then
		return self:_processUtilityToolUse(player, matchId, toolType, requestPayload)
	end

	local evidenceType = TOOL_TO_EVIDENCE[toolType]
	if not evidenceType then
		return false, "invalid_tool_type", nil
	end

	local session = self._engine:GetSession(matchId)
	local difficultyProfile = session and session.difficultyProfile or {}
	local clarity = tonumber(difficultyProfile.EvidenceClarity)
	if clarity == nil then
		clarity = tonumber(difficultyProfile.EvidenceClarityMultiplier)
	end
	clarity = math.clamp(clarity or 1, 0, 1)

	local baseChance = tonumber(requestPayload.baseChance) or tonumber(requestPayload.detectionChance) or 1
	local detectionChance = baseChance * clarity
	local roll = math.random()
	if roll > detectionChance then
		return false, "Inconclusive", {
			toolType = toolType,
			evidenceType = evidenceType,
			matchId = matchId,
			result = "Inconclusive",
		}
	end

	local now = requestPayload.now or os.clock()
	local activity = tonumber(requestPayload.activity) or 1
	local distanceToGhost = tonumber(requestPayload.distanceToGhost)

	local signal, spawnReason = self:SpawnEvidence(matchId, {
		source = "client_tool_use",
		trigger = "near_tool",
		activity = activity,
		evidenceType = evidenceType,
		roomId = requestPayload.roomId,
		now = now,
	})

	if spawnReason == "throttled" then
		return false, "tool_throttled", {
			toolType = toolType,
			evidenceType = evidenceType,
			matchId = matchId,
		}
	end
	if spawnReason == "delayed" then
		return false, "tool_pending_delay", {
			toolType = toolType,
			evidenceType = evidenceType,
			matchId = matchId,
		}
	end
	if spawnReason == "fake_spawned" then
		return false, "fake_evidence_generated", {
			toolType = toolType,
			evidenceType = evidenceType,
			matchId = matchId,
			isFake = true,
		}
	end
	if not signal then
		return false, spawnReason or "spawn_failed", {
			toolType = toolType,
			evidenceType = evidenceType,
			matchId = matchId,
		}
	end

	local ok, collectReason, collectResult = self:CollectEvidence(player, matchId, {
		evidenceType = evidenceType,
		toolType = toolType,
		toolEvidenceType = evidenceType,
		roomId = requestPayload.roomId,
		nearGhostRoom = requestPayload.nearGhostRoom == true,
		toolNearGhostRoom = requestPayload.nearGhostRoom == true,
		distanceToGhost = distanceToGhost,
		now = now,
	})

	if not ok then
		return false, collectReason or "collect_failed", {
			toolType = toolType,
			evidenceType = evidenceType,
			matchId = matchId,
		}
	end

	return true, collectReason or "collected", {
		toolType = toolType,
		evidenceType = evidenceType,
		matchId = matchId,
		result = collectResult,
	}
end

function EvidenceService:UpdateDirectorTension(matchId, tension)
	self._randomizer:UpdateTension(matchId, tension)
end

function EvidenceService:UpdateGhostPersonality(matchId, personality)
	self._randomizer:UpdateGhostPersonality(matchId, personality)
end

function EvidenceService:UpdateSpectatorVision(matchId, payload)
	self._randomizer:OnSpectatorVisionUpdated(matchId, payload)
end

function EvidenceService:CollectEvidence(player, matchId, payload)
	local ghostState = self:_getGhostState(matchId)
	local ok, reason, result = self._engine:TryCollectEvidence(matchId, player, payload, {
		ghostState = ghostState,
	})

	if ok and result then
		local session = self._engine:GetSession(matchId)
		self:_sync(matchId, "EvidenceDetected", {
			evidenceType = result.evidenceType,
			player = player,
		})
		self:_publish("EvidenceDetected", {
			player = player,
			matchId = matchId,
			evidenceType = result.evidenceType,
			toolType = payload and payload.toolType,
			playerPosition = payload and payload.playerPosition,
			ghostProximity = payload and (payload.ghostProximity or payload.distanceToGhost),
			environmentalConditions = payload and payload.environmentalConditions,
			now = payload and payload.now,
		})
		self:_publish("EvidenceValidated", {
			player = player,
			matchId = matchId,
			evidenceType = result.evidenceType,
			validated = true,
			now = payload and payload.now,
		})
		self:_publish("EvidenceCollected", {
			player = player,
			userId = player and player.UserId or nil,
			matchId = matchId,
			evidenceType = result.evidenceType,
			toolType = payload and payload.toolType,
			activity = payload and payload.activity,
			roomId = payload and payload.roomId,
			nearGhostRoom = payload and payload.nearGhostRoom == true,
			toolNearGhostRoom = payload and payload.toolNearGhostRoom == true,
			now = payload and payload.now,
		})
		self:_publishCombinationResolution(player, matchId, payload and payload.now)
		local candidates = self:_computeDeductionCandidates(matchId)
		if session then
			session.possibleGhosts = candidates
		end
		self:_publish("DeductionUpdated", { matchId = matchId, candidates = candidates })
	else
		self:_publish("EvidenceValidated", {
			player = player,
			matchId = matchId,
			evidenceType = payload and payload.evidenceType,
			validated = false,
			reason = reason,
			now = payload and payload.now,
		})
	end

	return ok, reason, result
end

function EvidenceService:ValidateJournalGuess(player, matchId, payload)
	local ok, reason, result = self._engine:ValidateJournalGuess(matchId, payload or {})
	if not ok then
		return false, reason, result
	end

	local combinationResult = self:_validateCombinationJournalGuess(matchId, payload or {})
	if combinationResult then
		result = combinationResult
		reason = combinationResult.identified and "identified" or "mismatch"
	end

	self:_publish("EvidenceValidated", {
		player = player,
		matchId = matchId,
		validated = result and result.evidenceMatches == true,
		ghostMatches = result and result.ghostMatches == true,
		identified = result and result.identified == true,
		reason = reason,
		now = payload and payload.now,
	})
	self:_sync(matchId, "EvidenceValidated", {
		validated = result and result.evidenceMatches == true,
		identified = result and result.identified == true,
	})

	if result and result.identified then
		self:_publish("GhostIdentified", {
			player = player,
			matchId = matchId,
			ghostType = result.actualGhostType,
			guessedGhostType = result.guessedGhostType,
			evidence = result.expectedEvidence,
			now = payload and payload.now,
		})
	end

	return true, reason, result
end

function EvidenceService:GetSpawnedEvidence(matchId)
    local session = self._engine:GetSession(matchId)
    return session and session.spawnedSignals or {}
end

function EvidenceService:GetCollectedEvidence(matchId)
	return self._engine:GetCollectedEvidence(matchId)
end

function EvidenceService:GetPossibleGhosts(matchId)
	return self._engine:GetPossibleGhosts(matchId)
end

return EvidenceService

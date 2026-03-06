local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

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

local function resolveModuleFromScript(pathOptions)
	local cursor = script
	while cursor do
		for _, path in ipairs(pathOptions) do
			local moduleScript = getByPath(cursor, path)
			if moduleScript then
				return moduleScript
			end
		end
		cursor = cursor.Parent
	end
	return nil
end

local function resolveModuleFromReplicatedStorage(pathOptions)
	local ok, replicatedStorage = pcall(function()
		return game:GetService("ReplicatedStorage")
	end)
	if not ok or typeof(replicatedStorage) ~= "Instance" then
		return nil
	end
	for _, path in ipairs(pathOptions) do
		local moduleScript = getByPath(replicatedStorage, path)
		if moduleScript then
			return moduleScript
		end
	end
	return nil
end

local function contains(list, value)
	for _, item in ipairs(list or {}) do
		if item == value then
			return true
		end
	end
	return false
end

local function uniqueList(list)
	local set = {}
	local out = {}
	for _, value in ipairs(list or {}) do
		if type(value) == "string" and set[value] ~= true then
			set[value] = true
			table.insert(out, value)
		end
	end
	return out
end

local function removeValue(list, value)
	local out = {}
	for _, item in ipairs(list or {}) do
		if item ~= value then
			table.insert(out, item)
		end
	end
	return out
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = nil
	self._dependencies = {}
	return self
end

function Service:Create()
	self._eventBus = resolveEventBus(self._deps)
	self._dependencies = {
		InvestigationSystem = Services.Get(self._deps, "InvestigationSystem"),
		GhostSystem = Services.Get(self._deps, "GhostSystem"),
	}
end

function Service:Init()
	self._state:Set("ghostDatabase", self:LoadGhostDatabase())
	self._state:Set("lastCandidates", {})
	self._state:Set("deductionHistory", {})
	self._state:Set("currentEvidence", {})
	self._state:Set("activeMatchId", nil)
end

function Service:Start()
	-- Event-driven engine.
end

function Service:Stop()
	self._state:Clear()
end

function Service:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function Service:_appendHistory(entry)
	local history = self._state:Get("deductionHistory") or {}
	table.insert(history, entry)
	if #history > 300 then
		table.remove(history, 1)
	end
	self._state:Set("deductionHistory", history)
end

function Service:LoadGhostDatabase()
	local ghostTypesPathOptions = {
		{ "shared", "DataTypes", "Ghosts", "GhostTypes", "ModuleScript" },
		{ "Shared", "DataTypes", "Ghosts", "GhostTypes", "ModuleScript" },
		{ "shared", "DataTypes", "GhostTypes", "ModuleScript" },
		{ "Shared", "DataTypes", "GhostTypes", "ModuleScript" },
	}
	local ghostEvidencePathOptions = {
		{ "shared", "DataTypes", "Ghosts", "GhostEvidenceMap", "ModuleScript" },
		{ "Shared", "DataTypes", "Ghosts", "GhostEvidenceMap", "ModuleScript" },
		{ "shared", "DataTypes", "Evidence", "EvidenceGhostMap", "ModuleScript" },
		{ "Shared", "DataTypes", "Evidence", "EvidenceGhostMap", "ModuleScript" },
	}

	local ghostTypesModule = resolveModuleFromScript(ghostTypesPathOptions)
		or resolveModuleFromReplicatedStorage(ghostTypesPathOptions)
	local ghostEvidenceMapModule = resolveModuleFromScript(ghostEvidencePathOptions)
		or resolveModuleFromReplicatedStorage(ghostEvidencePathOptions)

	local ghostTypes = safeRequire(ghostTypesModule) or {}
	local ghostEvidenceMap = safeRequire(ghostEvidenceMapModule) or {}
	local ghostDatabase = {}

	for _, ghostName in pairs(ghostTypes) do
		local evidence = ghostEvidenceMap[ghostName] or {}
		table.insert(ghostDatabase, {
			name = ghostName,
			evidence = evidence,
		})
	end

	table.sort(ghostDatabase, function(a, b)
		return a.name < b.name
	end)

	return ghostDatabase
end

function Service:ValidateEvidenceSet(evidenceList)
	if type(evidenceList) ~= "table" then
		return false, "invalid_evidence_list"
	end
	for _, evidenceType in ipairs(evidenceList) do
		if type(evidenceType) ~= "string" or evidenceType == "" then
			return false, "invalid_evidence_type"
		end
	end
	return true
end

function Service:CalculateCandidates(evidenceList)
	local valid, err = self:ValidateEvidenceSet(evidenceList)
	if not valid then
		return {}, err
	end

	local normalizedEvidence = uniqueList(evidenceList)
	local ghostDatabase = self._state:Get("ghostDatabase") or {}
	local candidates = {}

	for _, ghostEntry in ipairs(ghostDatabase) do
		local matches = true
		for _, requiredEvidence in ipairs(normalizedEvidence) do
			if not contains(ghostEntry.evidence, requiredEvidence) then
				matches = false
				break
			end
		end
		if matches then
			table.insert(candidates, ghostEntry.name)
		end
	end

	table.sort(candidates)
	self._state:Set("lastCandidates", candidates)

	self:_appendHistory({
		matchId = self._state:Get("activeMatchId"),
		evidence = normalizedEvidence,
		candidates = candidates,
		time = os.clock(),
	})

	self:_publish("GhostCandidatesUpdated", {
		matchId = self._state:Get("activeMatchId"),
		evidenceList = normalizedEvidence,
		candidates = candidates,
	})

	self:IdentifyGhost(candidates)
	return candidates
end

function Service:IdentifyGhost(candidates)
	if type(candidates) ~= "table" or #candidates ~= 1 then
		return nil
	end

	local ghostType = candidates[1]
	self:_publish("GhostIdentified", {
		matchId = self._state:Get("activeMatchId"),
		ghostType = ghostType,
		candidates = candidates,
		evidenceList = self._state:Get("currentEvidence") or {},
	})
	return ghostType
end

function Service:OnMatchStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._state:ResetForMatch(matchId)
end

function Service:OnEvidenceCollected(payload)
	if type(payload) ~= "table" then
		return
	end
	if self._state:Get("activeMatchId") ~= payload.matchId then
		return
	end

	local evidence = self._state:Get("currentEvidence") or {}
	if type(payload.evidenceList) == "table" then
		evidence = uniqueList(payload.evidenceList)
	elseif type(payload.evidenceType) == "string" and payload.evidenceType ~= "" then
		table.insert(evidence, payload.evidenceType)
		evidence = uniqueList(evidence)
	end

	self._state:Set("currentEvidence", evidence)
	self:CalculateCandidates(evidence)
end

function Service:OnEvidenceRemoved(payload)
	if type(payload) ~= "table" then
		return
	end
	if self._state:Get("activeMatchId") ~= payload.matchId then
		return
	end

	local evidence = self._state:Get("currentEvidence") or {}
	if type(payload.evidenceList) == "table" then
		evidence = uniqueList(payload.evidenceList)
	elseif type(payload.evidenceType) == "string" and payload.evidenceType ~= "" then
		evidence = removeValue(evidence, payload.evidenceType)
	end

	self._state:Set("currentEvidence", evidence)
	self:CalculateCandidates(evidence)
end

function Service:OnMatchEnded(payload)
	if type(payload) ~= "table" then
		return
	end
	if self._state:Get("activeMatchId") ~= payload.matchId then
		return
	end
	self._state:Clear()
end

return Service

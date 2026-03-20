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

local function contains(list, value)
	for _, item in ipairs(list or {}) do
		if item == value then
			return true
		end
	end
	return false
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

local function getDatabaseFromDeductionEngine(deductionEngine)
	if type(deductionEngine) ~= "table" then
		return nil
	end
	if type(deductionEngine.GetGhostDatabase) == "function" then
		return deductionEngine:GetGhostDatabase()
	end
	if type(deductionEngine.GetGhostEvidenceMap) == "function" then
		return deductionEngine:GetGhostEvidenceMap()
	end
	if type(deductionEngine.ghostDatabase) == "table" then
		return deductionEngine.ghostDatabase
	end
	if type(deductionEngine.ghostEvidenceMap) == "table" then
		return deductionEngine.ghostEvidenceMap
	end
	return nil
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
		EvidenceSystem = Services.Get(self._deps, "EvidenceSystem"),
		GhostSystem = Services.Get(self._deps, "GhostSystem"),
		MatchSystem = Services.Get(self._deps, "MatchSystem"),
		ContractObjectiveSystem = Services.Get(self._deps, "ContractObjectiveSystem"),
		EvidenceDeductionEngine = Services.Get(self._deps, "EvidenceDeductionEngine"),
	}

	local deductionDb = getDatabaseFromDeductionEngine(self._dependencies.EvidenceDeductionEngine)
	if type(deductionDb) == "table" and next(deductionDb) ~= nil then
		self._state:Set("ghostDatabase", deductionDb)
	end
end

function Service:Init()
	self._state:Set("discoveredEvidence", {})
	self._state:Set("possibleGhosts", {})
	self._state:Set("confirmedGhost", nil)
	self._state:Set("investigationState", "Searching")
	self._state:Set("activeMatchId", nil)
end

function Service:Start()
	-- Event-driven system.
end

function Service:Stop()
	self._state:Clear()
end

function Service:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function Service:_setInvestigationState(stateName)
	self._state:Set("investigationState", stateName)
	self:_publish("InvestigationUpdated", self:GetInvestigationState())
end

function Service:_getGhostDatabase()
	return self._state:Get("ghostDatabase") or {}
end

function Service:AddEvidence(evidenceType)
	if type(evidenceType) ~= "string" or evidenceType == "" then
		return false, "invalid_evidence"
	end

	local discoveredEvidence = self._state:Get("discoveredEvidence") or {}
	if not contains(discoveredEvidence, evidenceType) then
		table.insert(discoveredEvidence, evidenceType)
		self._state:Set("discoveredEvidence", discoveredEvidence)
	end

	self:_setInvestigationState("EvidenceFound")
	self:UpdateGhostCandidates()
	return true
end

function Service:RemoveEvidence(evidenceType)
	if type(evidenceType) ~= "string" or evidenceType == "" then
		return false, "invalid_evidence"
	end

	local discoveredEvidence = self._state:Get("discoveredEvidence") or {}
	self._state:Set("discoveredEvidence", removeValue(discoveredEvidence, evidenceType))

	if #(self._state:Get("discoveredEvidence") or {}) == 0 then
		self:_setInvestigationState("Searching")
	else
		self:_setInvestigationState("EvidenceFound")
	end
	self:UpdateGhostCandidates()
	return true
end

function Service:UpdateGhostCandidates()
	local discoveredEvidence = self._state:Get("discoveredEvidence") or {}
	local ghostDatabase = self:_getGhostDatabase()
	local possibleGhosts = {}

	for ghostType, evidenceList in pairs(ghostDatabase) do
		local matches = true
		for _, evidenceType in ipairs(discoveredEvidence) do
			if not contains(evidenceList, evidenceType) then
				matches = false
				break
			end
		end
		if matches then
			table.insert(possibleGhosts, ghostType)
		end
	end

	table.sort(possibleGhosts)
	self._state:Set("possibleGhosts", possibleGhosts)
	self:_publish("GhostCandidatesUpdated", {
		matchId = self._state:Get("activeMatchId"),
		possibleGhosts = possibleGhosts,
		discoveredEvidence = discoveredEvidence,
	})

	if #possibleGhosts == 1 then
		self:ConfirmGhost(possibleGhosts[1])
	elseif #possibleGhosts > 1 then
		self:_setInvestigationState("GhostCandidatesFiltered")
	end

	return possibleGhosts
end

function Service:ConfirmGhost(ghostType)
	if type(ghostType) ~= "string" or ghostType == "" then
		return false, "invalid_ghost_type"
	end
	self._state:Set("confirmedGhost", ghostType)
	self:_setInvestigationState("GhostIdentified")

	self:_publish("GhostIdentified", {
		matchId = self._state:Get("activeMatchId"),
		ghostType = ghostType,
		discoveredEvidence = self._state:Get("discoveredEvidence") or {},
	})

	self:_setInvestigationState("ExtractionReady")
	return true
end

function Service:GetInvestigationState()
	return {
		matchId = self._state:Get("activeMatchId"),
		discoveredEvidence = self._state:Get("discoveredEvidence") or {},
		possibleGhosts = self._state:Get("possibleGhosts") or {},
		confirmedGhost = self._state:Get("confirmedGhost"),
		investigationState = self._state:Get("investigationState"),
	}
end

function Service:OnMatchStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._state:ResetForMatch(matchId)
	self:_publish("InvestigationUpdated", self:GetInvestigationState())
end

function Service:OnMatchEnded(payload)
	local matchId = payload and payload.matchId
	if self._state:Get("activeMatchId") ~= matchId then
		return
	end
	self._state:Clear()
end

return Service

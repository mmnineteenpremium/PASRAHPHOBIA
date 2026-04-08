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

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for key, nested in pairs(value) do
		out[key] = deepCopy(nested)
	end
	return out
end

local function listToMapById(list)
	local out = {}
	for _, entry in ipairs(list or {}) do
		if type(entry) == "table" and type(entry.id) == "string" then
			out[entry.id] = {
				id = entry.id,
				type = entry.type or "Primary",
				target = tonumber(entry.target) or 1,
				completed = false,
			}
		end
	end
	return out
end

local function buildProgressSummary(objectives, progress, completed)
	local parts = {}
	for objectiveId, objective in pairs(objectives or {}) do
		local current = tonumber(progress and progress[objectiveId]) or 0
		local target = tonumber(objective.target) or 1
		local status = completed and completed[objectiveId] == true and "done" or "live"
		table.insert(parts, string.format("%s:%d/%d:%s", objectiveId, current, target, status))
	end
	table.sort(parts)
	return #parts > 0 and table.concat(parts, " | ") or nil
end

local function stampObjectiveRuntime(target, payload)
	if typeof(target) ~= "Instance" or not target:IsA("Player") then
		return
	end
	target:SetAttribute("PasrahObjectiveOwner", "ContractObjectiveSystem")
	target:SetAttribute("PasrahObjectiveMatchId", type(payload.matchId) == "string" and payload.matchId or nil)
	target:SetAttribute("PasrahObjectiveContractType", type(payload.contractType) == "string" and payload.contractType or nil)
	target:SetAttribute("PasrahObjectiveActiveCount", tonumber(payload.activeCount) or 0)
	target:SetAttribute("PasrahObjectiveCompletedCount", tonumber(payload.completedCount) or 0)
	target:SetAttribute("PasrahObjectiveProgressSummary", type(payload.progressSummary) == "string" and payload.progressSummary or nil)
	target:SetAttribute("PasrahObjectiveLastEvent", type(payload.lastEvent) == "string" and payload.lastEvent or nil)
	target:SetAttribute("PasrahObjectiveLastObjectiveId", type(payload.lastObjectiveId) == "string" and payload.lastObjectiveId or nil)
	target:SetAttribute("PasrahObjectiveLastProgress", tonumber(payload.lastProgress))
	target:SetAttribute("PasrahObjectiveAllPrimaryComplete", payload.allPrimaryComplete == true)
	target:SetAttribute("PasrahObjectiveLastUpdatedAt", tonumber(payload.updatedAt) or os.clock())
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
		MatchSystem = Services.Get(self._deps, "MatchSystem"),
		InvestigationSystem = Services.Get(self._deps, "InvestigationSystem"),
		EvidenceSystem = Services.Get(self._deps, "EvidenceSystem"),
		GhostSystem = Services.Get(self._deps, "GhostSystem"),
		EconomySystem = Services.Get(self._deps, "EconomySystem"),
	}
end

function Service:Init()
	self._state:Set("activeObjectives", {})
	self._state:Set("completedObjectives", {})
	self._state:Set("objectiveProgress", {})
	self._state:Set("contractType", nil)
	self._state:Set("activeMatchId", nil)
	self._state:Set("activePlayers", {})
end

function Service:Start()
	-- Event-driven service.
end

function Service:Stop()
	self._state:Clear()
end

function Service:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function Service:_stampPlayers(lastEvent, lastObjectiveId, lastProgress, allPrimaryComplete)
	local players = self._state:Get("activePlayers") or {}
	local objectives = self._state:Get("activeObjectives") or {}
	local completed = self._state:Get("completedObjectives") or {}
	local progress = self._state:Get("objectiveProgress") or {}
	local activeCount = 0
	local completedCount = 0
	for objectiveId, _ in pairs(objectives) do
		activeCount += 1
		if completed[objectiveId] == true then
			completedCount += 1
		end
	end
	local payload = {
		matchId = self._state:Get("activeMatchId"),
		contractType = self._state:Get("contractType"),
		activeCount = activeCount,
		completedCount = completedCount,
		progressSummary = buildProgressSummary(objectives, progress, completed),
		lastEvent = lastEvent,
		lastObjectiveId = lastObjectiveId,
		lastProgress = lastProgress,
		allPrimaryComplete = allPrimaryComplete == true,
		updatedAt = os.clock(),
	}
	for _, player in ipairs(players) do
		stampObjectiveRuntime(player, payload)
	end
end

function Service:LoadContractObjectives(contractType)
	local templates = self._state:Get("objectiveTemplates") or {}
	local selected = templates[contractType] or templates.Investigation or { primary = {}, optional = {} }

	local objectives = {}
	for id, objective in pairs(listToMapById(selected.primary)) do
		objectives[id] = objective
	end
	for id, objective in pairs(listToMapById(selected.optional)) do
		objectives[id] = objective
	end

	self._state:Set("activeObjectives", objectives)
	self._state:Set("completedObjectives", {})
	self._state:Set("objectiveProgress", {})
	self._state:Set("contractType", contractType)
	self:_stampPlayers("ObjectivesLoaded")
	return deepCopy(objectives)
end

function Service:StartObjectives()
	local objectives = self._state:Get("activeObjectives") or {}
	for _, objective in pairs(objectives) do
		self:_publish("ObjectiveStarted", {
			matchId = self._state:Get("activeMatchId"),
			contractType = self._state:Get("contractType"),
			objective = deepCopy(objective),
		})
	end
	self:_stampPlayers("ObjectivesStarted")
end

function Service:UpdateObjectiveProgress(objectiveId, amount)
	if type(objectiveId) ~= "string" or objectiveId == "" then
		return false, "invalid_objective"
	end

	local objectives = self._state:Get("activeObjectives") or {}
	local objective = objectives[objectiveId]
	if not objective then
		return false, "objective_not_found"
	end
	if objective.completed == true then
		return true
	end

	local progress = self._state:Get("objectiveProgress") or {}
	local current = tonumber(progress[objectiveId]) or 0
	local nextValue = current + (tonumber(amount) or 1)
	progress[objectiveId] = nextValue
	self._state:Set("objectiveProgress", progress)

	self:_publish("ObjectiveProgress", {
		matchId = self._state:Get("activeMatchId"),
		contractType = self._state:Get("contractType"),
		objectiveId = objectiveId,
		progress = nextValue,
		target = objective.target,
	})
	self:_stampPlayers("ObjectiveProgress", objectiveId, nextValue)

	if nextValue >= objective.target then
		self:CompleteObjective(objectiveId)
	end

	return true
end

function Service:CompleteObjective(objectiveId)
	if type(objectiveId) ~= "string" or objectiveId == "" then
		return false, "invalid_objective"
	end

	local objectives = self._state:Get("activeObjectives") or {}
	local objective = objectives[objectiveId]
	if not objective then
		return false, "objective_not_found"
	end
	if objective.completed then
		return true
	end

	objective.completed = true
	objectives[objectiveId] = objective
	self._state:Set("activeObjectives", objectives)

	local completed = self._state:Get("completedObjectives") or {}
	completed[objectiveId] = true
	self._state:Set("completedObjectives", completed)

	self:_publish("ObjectiveCompleted", {
		matchId = self._state:Get("activeMatchId"),
		contractType = self._state:Get("contractType"),
		objective = deepCopy(objective),
	})
	self:_stampPlayers("ObjectiveCompleted", objectiveId, tonumber((self._state:Get("objectiveProgress") or {})[objectiveId]) or objective.target)

	self:CheckContractCompletion()
	return true
end

function Service:CheckContractCompletion()
	local objectives = self._state:Get("activeObjectives") or {}
	local completed = self._state:Get("completedObjectives") or {}
	local allPrimaryComplete = true
	local completedCount = 0
	local totalCount = 0

	for objectiveId, objective in pairs(objectives) do
		totalCount += 1
		if completed[objectiveId] then
			completedCount += 1
		end
		if objective.type == "Primary" and completed[objectiveId] ~= true then
			allPrimaryComplete = false
		end
	end

	if allPrimaryComplete and totalCount > 0 then
		self:_stampPlayers("ContractCompleted", nil, nil, true)
		self:_publish("ContractCompleted", {
			matchId = self._state:Get("activeMatchId"),
			contractType = self._state:Get("contractType"),
			completedCount = completedCount,
			totalCount = totalCount,
			completedObjectives = completed,
		})
		return true
	end

	return false
end

function Service:OnMatchStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	local contractType = payload and payload.contractType or "Investigation"
	self._state:ResetForMatch(matchId, contractType)
	self._state:Set("activePlayers", payload and payload.players or {})
	self:LoadContractObjectives(contractType)
	self:StartObjectives()
end

function Service:OnEvidenceCollected(payload)
	if not payload or payload.matchId ~= self._state:Get("activeMatchId") then
		return
	end
	self:UpdateObjectiveProgress("CaptureEvidence", 1)
end

function Service:OnGhostIdentified(payload)
	if not payload or payload.matchId ~= self._state:Get("activeMatchId") then
		return
	end
	self:CompleteObjective("IdentifyGhost")
end

function Service:OnPlayerSurvivedHunt(payload)
	if not payload or payload.matchId ~= self._state:Get("activeMatchId") then
		return
	end
	self:CompleteObjective("SurviveHunt")
end

function Service:OnGhostInteraction(payload)
	if not payload or payload.matchId ~= self._state:Get("activeMatchId") then
		return
	end
	self:UpdateObjectiveProgress("WitnessGhostEvent", 1)
end

function Service:OnMatchEnded(payload)
	if not payload or payload.matchId ~= self._state:Get("activeMatchId") then
		return
	end
	self:CompleteObjective("CompleteInvestigation")
	self:CheckContractCompletion()
	self:_stampPlayers("MatchEnded")
	self._state:Clear()
end

return Service

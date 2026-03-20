local CoreEvidenceEngine = require(script.Parent.Parent.Modules.EvidenceEngine)
local Services = require(script.Parent.Parent.Parent.Core.Services)

local EvidenceEngine = {}
EvidenceEngine.__index = EvidenceEngine

local evidenceState = {}
local evidenceSubscriptionBound = false

local function resolveEventBus(deps)
	local eventBus = Services.Get(deps, "EventBus")
	if type(eventBus) ~= "table" then
		return nil
	end
	if type(eventBus.Subscribe) == "function" then
		return eventBus
	end
	if type(eventBus.Service) == "table" and type(eventBus.Service.Subscribe) == "function" then
		return eventBus.Service
	end
	return nil
end

function EvidenceEngine.new(deps)
    local self = setmetatable({}, EvidenceEngine)
    self._core = CoreEvidenceEngine.new(deps)
	self._eventBus = resolveEventBus(deps)
	if self._eventBus and not evidenceSubscriptionBound then
		evidenceSubscriptionBound = true
		self._eventBus:Subscribe("EvidenceDetected", function(evidenceName)
			if type(evidenceName) ~= "string" or evidenceName == "" then
				return
			end
			if evidenceState[evidenceName] then
				return
			end
			evidenceState[evidenceName] = true
			self._eventBus:Publish("EvidenceStateUpdated", evidenceState)
		end)
	end
    return self
end

function EvidenceEngine:StartMatch(matchId, payload)
    return self._core:StartMatch(matchId, payload)
end

function EvidenceEngine:EndMatch(matchId)
    return self._core:EndMatch(matchId)
end

function EvidenceEngine:TrySpawnEvidence(matchId, payload, context)
    return self._core:TrySpawnEvidence(matchId, payload, context)
end

function EvidenceEngine:TryCollectEvidence(matchId, player, payload, context)
    return self._core:TryCollectEvidence(matchId, player, payload, context)
end

function EvidenceEngine:GetEvidenceState()
	return evidenceState
end

return EvidenceEngine

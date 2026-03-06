local EvidenceEngine = require(script.Parent.EvidenceEngine)
local EvidenceSpawner = require(script.Parent.EvidenceSpawner)
local EvidenceValidator = require(script.Parent.EvidenceValidator)
local EvidenceTracker = require(script.Parent.EvidenceTracker)
local EvidenceDeduction = require(script.Parent.EvidenceDeduction)
local EvidenceDataTypes = require(script.Parent.EvidenceDataTypes)
local EvidenceRandomizer = require(script.Parent.Parent.EvidenceRandomizer)
local Services = require(script.Parent.Parent.Parent.Core.Services)

local EvidenceService = {}
EvidenceService.__index = EvidenceService

local TOOL_TO_EVIDENCE = {
	BolaArwah = "BolaArwah",
	BukuTerkutuk = "BukuTerkutuk",
	GerakanGaib = "GerakanGaib",
	JejakEnergi = "JejakEnergi",
	KotakArwah = "KotakArwah",
	SuhuMembeku = "SuhuMembeku",
}

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

function EvidenceService.new(state, deps)
	local self = setmetatable({}, EvidenceService)
	self._state = state
	self._deps = deps or {}
	self._dataTypes = EvidenceDataTypes.Resolve(self._deps)
	self._eventBus = resolveEventBus(self._deps)
	self._ghostService = resolveGhostService(self._deps)
	self._evidenceSync = resolveEvidenceSync(self._deps)

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
	self._randomizer = EvidenceRandomizer.new({
		Random = self._deps.Random,
		EvidenceRandomizerConfig = self._deps.EvidenceRandomizerConfig,
	})
	self._engine = EvidenceEngine.new({
		Spawner = self._spawner,
		Validator = self._validator,
		Tracker = self._tracker,
		Deduction = self._deduction,
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
	self._randomizer:Reset()
end

function EvidenceService:Start()
	-- Runtime ticks are driven by controller events.
end

function EvidenceService:Stop()
	self._engine:Reset()
	self._randomizer:Reset()
	self._state:Set("evidenceMatches", {})
end

function EvidenceService:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function EvidenceService:_getGhostState(matchId)
	if not self._ghostService then
		return nil
	end
	return self._ghostService:GetGhostState(matchId)
end

function EvidenceService:StartMatch(matchId, payload)
	local session = self._engine:StartMatch(matchId, payload)
	self._randomizer:StartMatch(matchId)
	local matches = self._state:Get("evidenceMatches") or {}
	matches[matchId] = session
	self._state:Set("evidenceMatches", matches)
	return session
end

function EvidenceService:EndMatch(matchId)
	self._engine:EndMatch(matchId)
	self._randomizer:EndMatch(matchId)
	local matches = self._state:Get("evidenceMatches") or {}
	matches[matchId] = nil
	self._state:Set("evidenceMatches", matches)
end

function EvidenceService:SetGhostProfile(matchId, payload)
	local session = self._engine:SetGhostProfile(matchId, payload)
	local matches = self._state:Get("evidenceMatches") or {}
	matches[matchId] = session
	self._state:Set("evidenceMatches", matches)
	return session
end

function EvidenceService:SpawnEvidence(matchId, payload)
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

	return self._randomizer:Spawn(matchId, payload or {}, doSpawn, function(eventName, eventPayload)
		self:_publish(eventName, eventPayload)
	end)
end

function EvidenceService:ProcessToolUse(player, matchId, payload)
	if not matchId then
		return false, "missing_match_id", nil
	end
	if type(payload) ~= "table" then
		return false, "invalid_payload", nil
	end

	local toolType = payload.toolType
	local evidenceType = TOOL_TO_EVIDENCE[toolType]
	if not evidenceType then
		return false, "invalid_tool_type", nil
	end

	local requestPayload = payload.payload or {}
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
		self:_sync(matchId, "EvidenceDetected", {
			evidenceType = result.evidenceType,
			player = player,
		})
		self:_publish("EvidenceDetected", {
			player = player,
			matchId = matchId,
			evidenceType = result.evidenceType,
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
			matchId = matchId,
			evidenceType = result.evidenceType,
		})
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

function EvidenceService:GetCollectedEvidence(matchId)
	return self._engine:GetCollectedEvidence(matchId)
end

function EvidenceService:GetPossibleGhosts(matchId)
	return self._engine:GetPossibleGhosts(matchId)
end

return EvidenceService

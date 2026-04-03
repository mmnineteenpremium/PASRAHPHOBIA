local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Controller = {}
Controller.__index = Controller

local function resolveEventBus(deps)
	local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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

local function resolveMatchSystem(deps)
	local matchSystem = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("MatchSystem")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("MatchSystem")) or (deps and deps.MatchSystem or nil)
	if type(matchSystem) ~= "table" then
		return nil
	end
	if type(matchSystem.GetLiveMatch) == "function" then
		return matchSystem
	end
	if type(matchSystem.Service) == "table" and type(matchSystem.Service.GetLiveMatch) == "function" then
		return matchSystem.Service
	end
	return nil
end

local function resolveMatchRemote()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		return nil
	end
	local remote = remoteFolder:FindFirstChild("MatchEvent")
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	return nil
end

function Controller.new(state, service, deps)
	local self = setmetatable({}, Controller)
	self._state = state
	self._service = service
	self._deps = deps or {}
	self._subscriptions = {}
	self._eventBus = resolveEventBus(self._deps)
	self._matchSystem = resolveMatchSystem(self._deps)
	self._matchRemote = resolveMatchRemote()
	return self
end

function Controller:Init()
	-- Event wiring only.
end

function Controller:RegisterEventHandlers()
	if not self._eventBus then
		return
	end
	self:_subscribe("MatchStarted", function(payload)
		self:OnMatchStarted(payload)
	end)
	self:_subscribe("MatchEnded", function(payload)
		self:OnMatchEnded(payload)
	end)
	self:_subscribe("PhaseStarted", function(payload)
		self:OnPhaseStarted(payload)
	end)
	self:_subscribe("EnvironmentEventTriggered", function(payload)
		self:OnEnvironmentEventTriggered(payload)
	end)
	self:_subscribe("GhostInteraction", function(payload)
		self:OnGhostInteraction(payload)
	end)
	self:_subscribe("GhostManifest", function(payload)
		self:OnGhostManifest(payload)
	end)
	self:_subscribe("FearLevelChanged", function(payload)
		self:OnFearLevelChanged(payload)
	end)
	self:_subscribe("HuntStarted", function(payload)
		self:OnHuntStarted(payload)
	end)
	self:_subscribe("HuntEnded", function(payload)
		self:OnHuntEnded(payload)
	end)
	self:_subscribe("JumpscareTriggered", function(payload)
		self:OnJumpscareTriggered(payload)
	end)
	self:_subscribe("AmbientAudioTriggered", function(payload)
		self:OnAudioTriggered("AmbientAudioTriggered", payload)
	end)
	self:_subscribe("EnvironmentalAudioTriggered", function(payload)
		self:OnAudioTriggered("EnvironmentalAudioTriggered", payload)
	end)
	self:_subscribe("FearAudioTriggered", function(payload)
		self:OnAudioTriggered("FearAudioTriggered", payload)
	end)
	self:_subscribe("GhostAudioTriggered", function(payload)
		self:OnAudioTriggered("GhostAudioTriggered", payload)
	end)
	self:_subscribe("HuntAudioTriggered", function(payload)
		self:OnAudioTriggered("HuntAudioTriggered", payload)
	end)
	self:_subscribe("JumpscareAudioTriggered", function(payload)
		self:OnAudioTriggered("JumpscareAudioTriggered", payload)
	end)
end

function Controller:UnregisterEventHandlers()
	if not self._eventBus then
		return
	end
	for _, subscription in ipairs(self._subscriptions) do
		self._eventBus:Unsubscribe(subscription.eventName, subscription.callback)
	end
	table.clear(self._subscriptions)
end

function Controller:_subscribe(eventName, callback)
	self._eventBus:Subscribe(eventName, callback)
	table.insert(self._subscriptions, {
		eventName = eventName,
		callback = callback,
	})
end

function Controller:OnMatchStarted(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:StartMatch(matchId)
	end
end

function Controller:OnMatchEnded(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:EndMatch(matchId)
	end
end

function Controller:OnPhaseStarted(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	local phaseName = payload.phaseName
	if phaseName == "Investigation" or phaseName == "InvestigationPhase" then
		self._service:TriggerAmbientAudio(matchId, {
			cue = "ambient_investigation",
			intensity = 0.45,
			now = payload.now,
		})
	elseif phaseName == "Hunt" or phaseName == "HuntPhase" then
		self._service:TriggerHuntAudio(matchId, {
			cue = "hunt_phase_loop",
			intensity = 0.95,
			now = payload.now,
		})
	end
end

function Controller:OnEnvironmentEventTriggered(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:TriggerEnvironmentalAudio(matchId, {
			eventType = payload.eventType,
			roomId = payload.roomId,
			cue = "env_" .. tostring(payload.eventType or "event"),
			intensity = 0.7,
			now = payload.now,
		})
	end
end

function Controller:OnGhostInteraction(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:TriggerGhostAudio(matchId, {
			roomId = payload.room,
			cue = "ghost_interaction",
			intensity = 0.7,
			now = payload.now,
		})
	end
end

function Controller:OnGhostManifest(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:TriggerGhostAudio(matchId, {
			roomId = payload.roomId,
			cue = "ghost_manifest",
			intensity = 0.85,
			now = payload.now,
		})
	end
end

function Controller:OnFearLevelChanged(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	local fearLevel = payload.fearLevel or 0
	self._service:TriggerFearAudio(matchId, {
		cue = fearLevel >= 70 and "fear_critical" or "fear_rise",
		intensity = math.min(1, fearLevel / 100),
		now = payload.now,
	})
end

function Controller:OnHuntStarted(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:TriggerHuntAudio(matchId, {
			cue = "hunt_start",
			intensity = 1.0,
			now = payload.now,
		})
	end
end

function Controller:OnHuntEnded(payload)
	local matchId = payload and payload.matchId
	if matchId then
		self._service:TriggerAmbientAudio(matchId, {
			cue = "post_hunt_calm",
			intensity = 0.4,
			now = payload.now,
		})
	end
end

function Controller:OnJumpscareTriggered(payload)
	local matchId = payload and payload.matchId
	if not matchId then
		return
	end
	self._service:TriggerJumpscareAudio(matchId, {
		cue = payload and payload.cue or "jumpscare_stinger",
		roomId = payload and payload.roomId,
		intensity = payload and payload.intensity or 1.0,
		now = payload and payload.now,
	})
end

function Controller:OnAudioTriggered(eventName, payload)
	local matchSystem = self._matchSystem or resolveMatchSystem(self._deps)
	local remote = self._matchRemote or resolveMatchRemote()
	local matchId = payload and payload.matchId
	if not matchSystem or not remote or not matchId then
		return
	end

	self._matchSystem = matchSystem
	self._matchRemote = remote

	local match = matchSystem:GetLiveMatch(matchId)
	local players = type(match) == "table" and match.players or nil
	if type(players) ~= "table" then
		return
	end

	local clientPayload = {}
	for key, value in pairs(payload or {}) do
		clientPayload[key] = value
	end
	clientPayload.eventName = eventName
	clientPayload.source = clientPayload.source or "AudioSystem"

	for _, player in ipairs(players) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			remote:FireClient(player, clientPayload)
		end
	end
end

return Controller

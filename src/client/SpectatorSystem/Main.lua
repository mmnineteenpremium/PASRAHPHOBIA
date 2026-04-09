local SpectatorSystem = {}
SpectatorSystem.__index = SpectatorSystem

local PROBABILITIES = {
	fake = 0.60,
	uncertain = 0.30,
	real = 0.10,
}

local function resolveTargetLabel(target)
	if typeof(target) == "Instance" then
		if target:IsA("Player") then
			return target.Name
		end
		return target:GetFullName()
	end
	if type(target) == "string" and target ~= "" then
		return target
	end
	return nil
end

function SpectatorSystem:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._connections = {}
	self._isSpectating = false
	self._cameraTarget = nil
	self._distortionState = "none"
	self._lastEvent = "Idle"
	self._lastReason = nil
	self._enteredAt = nil
	self:_stampRuntimeState()
end

function SpectatorSystem:Start()
	local matchEvent = self._remotes.MatchEvent
	if matchEvent and matchEvent.OnClientEvent then
		table.insert(self._connections, matchEvent.OnClientEvent:Connect(function(payload)
			self:_onMatchEvent(payload)
		end))
	end

	local lobbyEvent = self._remotes.LobbyEvent
	if lobbyEvent and lobbyEvent.OnClientEvent then
		table.insert(self._connections, lobbyEvent.OnClientEvent:Connect(function(payload)
			self:_onLobbyEvent(payload)
		end))
	end
end

function SpectatorSystem:_onMatchEvent(payload)
	local eventName = payload and payload.eventName
	if eventName == "PlayerKilled" and payload.localPlayerKilled == true then
		self:EnterSpectatorMode(payload)
	elseif eventName == "PlayerRespawned" and payload.localPlayerRespawned == true then
		self:ExitSpectatorMode("PlayerRespawned")
	elseif eventName == "MatchEnded" or eventName == "MatchCompleted" or eventName == "ReturnedToLobby" then
		self:ExitSpectatorMode(eventName)
	end
end

function SpectatorSystem:_onLobbyEvent(payload)
	local eventName = payload and payload.eventName
	if eventName == "LobbyEntered" or eventName == "RoomBrowserRoomLeft" then
		self:ExitSpectatorMode(eventName)
	end
end

function SpectatorSystem:EnterSpectatorMode(payload)
	self._isSpectating = true
	self._cameraTarget = payload and payload.targetPlayer
	self._distortionState = "active"
	self._lastEvent = payload and payload.eventName or "PlayerKilled"
	self._lastReason = payload and payload.reason or "PlayerKilled"
	self._enteredAt = os.clock()

	local renderer = self._context.Registry:Get("GhostRenderer")
	if renderer and renderer.SetSpectatorMode then
		renderer:SetSpectatorMode(true)
	end
	self:_stampRuntimeState()
end

function SpectatorSystem:ExitSpectatorMode(reason)
	self._isSpectating = false
	self._cameraTarget = nil
	self._distortionState = "none"
	self._lastEvent = type(reason) == "string" and reason ~= "" and reason or self._lastEvent
	self._lastReason = type(reason) == "string" and reason ~= "" and reason or self._lastReason
	self._enteredAt = nil

	local renderer = self._context.Registry:Get("GhostRenderer")
	if renderer and renderer.SetSpectatorMode then
		renderer:SetSpectatorMode(false)
	end
	self:_stampRuntimeState()
end

function SpectatorSystem:_stampRuntimeState()
	local player = self._context and self._context.LocalPlayer or game:GetService("Players").LocalPlayer
	local camera = workspace.CurrentCamera
	local targetLabel = resolveTargetLabel(self._cameraTarget)
	local active = self._isSpectating == true
	local mode = active and "FreeCamera" or "None"

	if player then
		player:SetAttribute("PasrahSpectatorClientOwner", "SpectatorSystem")
		player:SetAttribute("PasrahSpectatorClientActive", active)
		player:SetAttribute("PasrahSpectatorClientMode", mode)
		player:SetAttribute("PasrahSpectatorClientTarget", targetLabel)
		player:SetAttribute("PasrahSpectatorClientDistortionState", self._distortionState ~= "none" and self._distortionState or nil)
		player:SetAttribute("PasrahSpectatorClientLastEvent", self._lastEvent ~= "Idle" and self._lastEvent or nil)
		player:SetAttribute("PasrahSpectatorClientReason", self._lastReason)
		player:SetAttribute("PasrahSpectatorClientEnteredAt", self._enteredAt)
	end

	if camera then
		camera:SetAttribute("PasrahSpectatorClientOwner", "SpectatorSystem")
		camera:SetAttribute("PasrahSpectatorClientChannel", "CurrentCamera")
		camera:SetAttribute("PasrahSpectatorClientActive", active)
		camera:SetAttribute("PasrahSpectatorClientMode", mode)
		camera:SetAttribute("PasrahSpectatorClientTarget", targetLabel)
		camera:SetAttribute("PasrahSpectatorClientDistortionState", self._distortionState ~= "none" and self._distortionState or nil)
	end
end

function SpectatorSystem:GetGhostProbability()
	return PROBABILITIES
end

function SpectatorSystem:GetState()
	return {
		isSpectating = self._isSpectating,
		cameraTarget = self._cameraTarget,
		distortionState = self._distortionState,
		probability = PROBABILITIES,
	}
end

return setmetatable({}, SpectatorSystem)

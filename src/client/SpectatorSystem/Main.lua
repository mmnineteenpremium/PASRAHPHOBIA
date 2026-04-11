local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

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

local function resolveTargetPlayer(payload)
	local targetPlayer = payload and payload.targetPlayer
	if typeof(targetPlayer) == "Instance" and targetPlayer:IsA("Player") then
		return targetPlayer
	end
	local targetUserId = tonumber(payload and payload.targetUserId)
	if targetUserId then
		return Players:GetPlayerByUserId(targetUserId)
	end
	return nil
end

local function resolveTargetSubject(targetPlayer)
	if typeof(targetPlayer) ~= "Instance" or not targetPlayer:IsA("Player") then
		return nil
	end
	local character = targetPlayer.Character
	if typeof(character) ~= "Instance" or not character:IsA("Model") then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

local function resolveLocalSubject()
	local localPlayer = Players.LocalPlayer
	local character = localPlayer and localPlayer.Character
	if typeof(character) ~= "Instance" or not character:IsA("Model") then
		return nil
	end
	return character:FindFirstChildOfClass("Humanoid")
end

function SpectatorSystem:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._connections = {}
	self._isSpectating = false
	self._cameraTarget = nil
	self._cameraTargetUserId = nil
	self._targetCharacterConnection = nil
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

	table.insert(self._connections, RunService.RenderStepped:Connect(function()
		self:_applySpectatorCamera()
	end))
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

function SpectatorSystem:_disconnectTargetCharacterConnection()
	if self._targetCharacterConnection then
		self._targetCharacterConnection:Disconnect()
		self._targetCharacterConnection = nil
	end
end

function SpectatorSystem:_bindTargetCharacter()
	self:_disconnectTargetCharacterConnection()
	if typeof(self._cameraTarget) ~= "Instance" or not self._cameraTarget:IsA("Player") then
		return
	end
	self._targetCharacterConnection = self._cameraTarget.CharacterAdded:Connect(function()
		self:_applySpectatorCamera()
	end)
end

function SpectatorSystem:_applySpectatorCamera()
	if self._isSpectating ~= true then
		return
	end
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	if (typeof(self._cameraTarget) ~= "Instance" or not self._cameraTarget:IsA("Player")) and self._cameraTargetUserId then
		self._cameraTarget = Players:GetPlayerByUserId(self._cameraTargetUserId)
	end
	local targetSubject = resolveTargetSubject(self._cameraTarget)
	if targetSubject then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = targetSubject
	end
end

function SpectatorSystem:_restoreLocalCamera()
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	local localSubject = resolveLocalSubject()
	camera.CameraType = Enum.CameraType.Custom
	if localSubject then
		camera.CameraSubject = localSubject
	end
end

function SpectatorSystem:EnterSpectatorMode(payload)
	self._isSpectating = true
	self._cameraTarget = resolveTargetPlayer(payload)
	self._cameraTargetUserId = tonumber(payload and payload.targetUserId) or (self._cameraTarget and self._cameraTarget.UserId) or nil
	self._distortionState = "active"
	self._lastEvent = payload and payload.eventName or "PlayerKilled"
	self._lastReason = payload and payload.reason or "PlayerKilled"
	self._enteredAt = os.clock()
	self:_bindTargetCharacter()
	self:_applySpectatorCamera()

	local renderer = self._context.Registry:Get("GhostRenderer")
	if renderer and renderer.SetSpectatorMode then
		renderer:SetSpectatorMode(true)
	end
	self:_stampRuntimeState()
end

function SpectatorSystem:ExitSpectatorMode(reason)
	self._isSpectating = false
	self:_disconnectTargetCharacterConnection()
	self._cameraTarget = nil
	self._cameraTargetUserId = nil
	self._distortionState = "none"
	self._lastEvent = type(reason) == "string" and reason ~= "" and reason or self._lastEvent
	self._lastReason = type(reason) == "string" and reason ~= "" and reason or self._lastReason
	self._enteredAt = nil
	self:_restoreLocalCamera()

	local renderer = self._context.Registry:Get("GhostRenderer")
	if renderer and renderer.SetSpectatorMode then
		renderer:SetSpectatorMode(false)
	end
	self:_stampRuntimeState()
end

function SpectatorSystem:_stampRuntimeState()
	local player = self._context and self._context.LocalPlayer or Players.LocalPlayer
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

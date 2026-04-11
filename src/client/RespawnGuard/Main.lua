local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local RESET_BUTTON_CORE_KEY = "ResetButtonCallback"
local SET_CORE_ATTEMPTS = 20
local SET_CORE_RETRY_DELAY = 0.25

local RespawnGuard = {}
RespawnGuard.__index = RespawnGuard

local function setResetButtonEnabled(enabled)
	for _ = 1, SET_CORE_ATTEMPTS do
		local ok = pcall(function()
			StarterGui:SetCore(RESET_BUTTON_CORE_KEY, enabled == true)
		end)
		if ok then
			return true
		end
		task.wait(SET_CORE_RETRY_DELAY)
	end
	return false
end

local function resolveLocalPlayer()
	return Players.LocalPlayer
end

function RespawnGuard:Init(context)
	self._context = context
	self._connections = {}
	self._resetDisabled = nil
	self._lastSetCoreOk = nil
	self:_stampRuntime()
end

function RespawnGuard:Start()
	local player = resolveLocalPlayer()
	if not player then
		return
	end

	local function sync()
		self:_syncResetButton()
	end

	table.insert(self._connections, player:GetAttributeChangedSignal("InMatch"):Connect(sync))
	table.insert(self._connections, player:GetAttributeChangedSignal("MatchId"):Connect(sync))
	table.insert(self._connections, player:GetAttributeChangedSignal("PasrahSpectatorActive"):Connect(sync))

	task.defer(sync)
end

function RespawnGuard:_shouldDisableReset()
	local player = resolveLocalPlayer()
	if not player then
		return false
	end
	if player:GetAttribute("InMatch") == true then
		return true
	end
	return player:GetAttribute("MatchId") ~= nil
end

function RespawnGuard:_stampRuntime()
	local player = resolveLocalPlayer()
	if not player then
		return
	end
	player:SetAttribute("PasrahResetGuardOwner", "RespawnGuard")
	player:SetAttribute("PasrahResetGuardDisabled", self._resetDisabled == true)
	player:SetAttribute("PasrahResetGuardSetCoreReady", self._lastSetCoreOk == true)
end

function RespawnGuard:_syncResetButton()
	local shouldDisable = self:_shouldDisableReset()
	if self._resetDisabled == shouldDisable and self._lastSetCoreOk ~= false then
		self:_stampRuntime()
		return
	end

	self._lastSetCoreOk = setResetButtonEnabled(not shouldDisable)
	self._resetDisabled = shouldDisable
	self:_stampRuntime()
end

return setmetatable({}, RespawnGuard)

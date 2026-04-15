local Players = game:GetService("Players")

local SanityHUD = require(script.Parent.SanityHUD)

local OverlayController = {}
OverlayController.__index = OverlayController
OverlayController._sharedInstance = nil

function OverlayController.new()
	local self = setmetatable({}, OverlayController)
	self._initialized = false
	self._sanityHUD = nil
	return self
end

function OverlayController.shared()
	if OverlayController._sharedInstance then
		return OverlayController._sharedInstance
	end

	OverlayController._sharedInstance = OverlayController.new()
	return OverlayController._sharedInstance
end

function OverlayController:Init()
	if self._initialized then
		return
	end

	local player = Players.LocalPlayer
	if not player then
		return
	end

	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then
		return
	end

	self._sanityHUD = SanityHUD.new(playerGui)
	self._initialized = true
end

function OverlayController:Start()
	if not self._initialized then
		self:Init()
	end
end

return OverlayController

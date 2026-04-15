local OverlayController = require(script.Parent.UI.OverlayController)
local QuestUIController = require(script.Parent.UI.QuestUIController)

local ClientBootstrap = require(script.Parent.Core.ClientBootstrap)

local ClientMain = {}
ClientMain.__index = ClientMain
ClientMain._sharedInstance = nil

function ClientMain.new(deps)
	local self = setmetatable({}, ClientMain)
	self._bootstrap = ClientBootstrap.new(deps)
	self._overlayController = OverlayController.shared()
	self._questUIController = QuestUIController.shared()
	return self
end

function ClientMain.shared(deps)
	if ClientMain._sharedInstance then
		return ClientMain._sharedInstance
	end
	ClientMain._sharedInstance = ClientMain.new(deps)
	return ClientMain._sharedInstance
end

function ClientMain:Init()
	self._bootstrap:Init()
	self._overlayController:Init()
	self._questUIController:Init()
end

function ClientMain:Start()
	self._bootstrap:Start()
	self._overlayController:Start()
	self._questUIController:Start()
end

return ClientMain

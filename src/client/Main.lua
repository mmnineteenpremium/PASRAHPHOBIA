local ClientBootstrap = require(script.Parent.Core.ClientBootstrap)

local ClientMain = {}
ClientMain.__index = ClientMain
ClientMain._sharedInstance = nil

function ClientMain.new(deps)
	local self = setmetatable({}, ClientMain)
	self._bootstrap = ClientBootstrap.new(deps)
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
end

function ClientMain:Start()
	self._bootstrap:Start()
end

return ClientMain

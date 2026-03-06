local ClientBootstrap = require(script.Core.ClientBootstrap)

local ClientMain = {}
ClientMain.__index = ClientMain

function ClientMain.new(deps)
	local self = setmetatable({}, ClientMain)
	self._bootstrap = ClientBootstrap.new(deps)
	return self
end

function ClientMain:Init()
	self._bootstrap:Init()
end

function ClientMain:Start()
	self._bootstrap:Start()
end

return ClientMain

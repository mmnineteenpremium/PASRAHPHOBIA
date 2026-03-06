local GameServer = {}
local Bootstrap = require(script.Parent.Parent.Core.Bootstrap.Main)

local runtime = {
	bootstrap = nil,
}

function GameServer.start()
	if runtime.bootstrap then
		return runtime.bootstrap
	end

	local bootstrap = Bootstrap.new({})
	bootstrap:Init()
	bootstrap:Start()
	runtime.bootstrap = bootstrap

	print("PASRAHPHOBIA Game Server Started")
	return bootstrap
end

return GameServer

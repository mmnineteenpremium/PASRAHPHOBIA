local clientRoot = script.Parent:WaitForChild("Client")
local clientModule = clientRoot:WaitForChild("init")

local ok, ClientMain = pcall(require, clientModule)
if not ok then
	warn("ClientBootstrap failed to require client root:", ClientMain)
	return
end

local client = ClientMain.new()
client:Init()
client:Start()

local ServerScriptService = game:GetService("ServerScriptService")
local ServerFolder = ServerScriptService:WaitForChild("Server")
local ServerBootstrap = ServerFolder:WaitForChild("ServerBootstrap")

assert(ServerBootstrap:IsA("ModuleScript"), "ServerBootstrap must be a ModuleScript")

local Bootstrap = require(ServerBootstrap)
Bootstrap.Start()

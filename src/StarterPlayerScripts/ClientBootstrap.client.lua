local Players = game:GetService("Players")

local localPlayer = Players.LocalPlayer

local function setStage(stage, detail)
	if localPlayer then
		localPlayer:SetAttribute("PasrahClientBootstrapStage", tostring(stage))
		if detail ~= nil then
			localPlayer:SetAttribute("PasrahClientBootstrapDetail", tostring(detail))
		end
	end
end

setStage("require_client")

local clientModule = script.Parent:WaitForChild("Client", 15)
if not clientModule then
	setStage("missing_client")
	error("[ClientBootstrap] Missing Client module under PlayerScripts")
end

local okRequire, ClientMain = pcall(require, clientModule)
if not okRequire then
	setStage("require_failed", ClientMain)
	error(("[ClientBootstrap] Failed to require Client: %s"):format(tostring(ClientMain)))
end

setStage("init")
local client = ClientMain.shared()

local okInit, initErr = pcall(function()
	client:Init()
end)
if not okInit then
	setStage("init_failed", initErr)
	error(("[ClientBootstrap] Init failed: %s"):format(tostring(initErr)))
end

setStage("start")
local okStart, startErr = pcall(function()
	client:Start()
end)
if not okStart then
	setStage("start_failed", startErr)
	error(("[ClientBootstrap] Start failed: %s"):format(tostring(startErr)))
end

setStage("started")

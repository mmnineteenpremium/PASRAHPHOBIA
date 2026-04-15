local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local UI_INPUT_PROFILE_OVERRIDE_ATTR = "PasrahUIInputProfileOverride"
local STUDIO_TOUCH_MOBILE_MAX_VIEWPORT_X = 900
local STUDIO_TOUCH_MOBILE_MAX_VIEWPORT_Y = 430

local function setStage(stage, detail)
	if localPlayer then
		localPlayer:SetAttribute("PasrahClientBootstrapStage", tostring(stage))
		if detail ~= nil then
			localPlayer:SetAttribute("PasrahClientBootstrapDetail", tostring(detail))
		end
	end
end

local function applyStudioMobilePreviewOverride()
	if not RunService:IsStudio() then
		return
	end
	if UserInputService.TouchEnabled ~= true then
		return
	end
	task.spawn(function()
		if ReplicatedStorage:GetAttribute(UI_INPUT_PROFILE_OVERRIDE_ATTR) ~= nil then
			return
		end
		if localPlayer and localPlayer:GetAttribute(UI_INPUT_PROFILE_OVERRIDE_ATTR) ~= nil then
			return
		end

		local deadline = os.clock() + 3
		local camera = Workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.zero
		while os.clock() < deadline do
			camera = Workspace.CurrentCamera or camera
			viewport = camera and camera.ViewportSize or Vector2.zero
			if viewport.X > 0 and viewport.Y > 0 then
				break
			end
			task.wait()
		end

		if viewport.X <= viewport.Y then
			return
		end
		if viewport.X > STUDIO_TOUCH_MOBILE_MAX_VIEWPORT_X or viewport.Y > STUDIO_TOUCH_MOBILE_MAX_VIEWPORT_Y then
			return
		end

		if localPlayer then
			localPlayer:SetAttribute(UI_INPUT_PROFILE_OVERRIDE_ATTR, "mobile")
		end
	end)
end

setStage("require_client")
applyStudioMobilePreviewOverride()

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

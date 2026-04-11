local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer

local function setStatus(status, payload)
	player:SetAttribute("PasrahLegalProbeStatus", status)
	if payload ~= nil then
		player:SetAttribute("PasrahLegalProbeJson", HttpService:JSONEncode(payload))
	end
end

local function waitForChildOf(parent, name, timeoutSec)
	local started = os.clock()
	local child = parent:FindFirstChild(name)
	while not child and os.clock() - started < timeoutSec do
		task.wait(0.05)
		child = parent:FindFirstChild(name)
	end
	return child
end

local function snapshotBounds(guiObject)
	if not guiObject or not guiObject:IsA("GuiObject") then
		return nil
	end
	return {
		position = { x = guiObject.AbsolutePosition.X, y = guiObject.AbsolutePosition.Y },
		size = { x = guiObject.AbsoluteSize.X, y = guiObject.AbsoluteSize.Y },
		visible = guiObject.Visible == true,
	}
end

local function run()
	local mode = tostring(ReplicatedStorage:GetAttribute("PasrahLegalProbeMode") or "")
	if mode ~= "open_main_menu" then
		setStatus("error", { mode = mode, error = "unsupported_mode" })
		return
	end
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = waitForChildOf(playerGui, "MainMenuUI", 10)
	if not gui or not gui:IsA("ScreenGui") then
		setStatus("error", { error = "mainmenu_gui_missing" })
		return
	end
	local panel = waitForChildOf(gui, "MainPanel", 10)
	local footer = panel and waitForChildOf(panel, "FooterLabel", 10) or nil
	if not panel or not footer then
		setStatus("error", { error = "mainmenu_panel_or_footer_missing" })
		return
	end
	gui.Enabled = true
	panel.Visible = true
	local floatButton = gui:FindFirstChild("MainMenuFloatButton")
	if floatButton and floatButton:IsA("GuiObject") then
		floatButton.Visible = false
	end
	task.wait(0.35)
	setStatus("done", {
		mode = mode,
		guiEnabled = gui.Enabled == true,
		panel = snapshotBounds(panel),
		footer = snapshotBounds(footer),
		footerText = footer.Text,
		title = panel:FindFirstChild("Title") and panel.Title.Text or nil,
		badge = panel:FindFirstChild("StatusBadge") and panel.StatusBadge.Text or nil,
	})
end

setStatus("running", { mode = tostring(ReplicatedStorage:GetAttribute("PasrahLegalProbeMode") or "") })
run()

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer
local PLAYER_GUI = LOCAL_PLAYER:WaitForChild("PlayerGui")

local BASE_VIEWPORT = Vector2.new(1920, 1080)
local ROOT_SCALE_NAME = "PasrahGlobalResponsiveUIScale"
local SAFE_AREA_NAME = "PasrahGlobalSafeAreaPadding"
local MANAGED_ATTR = "PasrahGlobalResponsiveManaged"
local DISABLED_ATTR = "PasrahDisableGlobalResponsiveScale"

local DESKTOP_MIN_SCALE = 0.72
local DESKTOP_MAX_SCALE = 1.16
local MOBILE_MIN_SCALE = 0.58
local MOBILE_MAX_SCALE = 0.98
local CONSOLE_MIN_SCALE = 0.82
local CONSOLE_MAX_SCALE = 1.06

local function getViewportSize()
	local camera = Workspace.CurrentCamera
	if camera then
		local viewport = camera.ViewportSize
		if viewport.X > 0 and viewport.Y > 0 then
			return viewport
		end
	end
	return BASE_VIEWPORT
end

local function isMobileViewport(viewport)
	return UserInputService.TouchEnabled
		and not UserInputService.KeyboardEnabled
		and math.min(viewport.X, viewport.Y) <= 900
end

local function isConsoleInput()
	return UserInputService.GamepadEnabled
		and not UserInputService.KeyboardEnabled
		and not UserInputService.TouchEnabled
end

local function getScaleBounds(viewport)
	if isConsoleInput() then
		return CONSOLE_MIN_SCALE, CONSOLE_MAX_SCALE
	end
	if isMobileViewport(viewport) then
		return MOBILE_MIN_SCALE, MOBILE_MAX_SCALE
	end
	return DESKTOP_MIN_SCALE, DESKTOP_MAX_SCALE
end

local function computeGlobalScale(viewport)
	local fitScale = math.min(viewport.X / BASE_VIEWPORT.X, viewport.Y / BASE_VIEWPORT.Y)
	local minScale, maxScale = getScaleBounds(viewport)
	if viewport.X / math.max(viewport.Y, 1) > 2.05 then
		maxScale = math.min(maxScale, 1.04)
	end
	return math.clamp(fitScale, minScale, maxScale)
end

local function readGuiInset()
	local topLeft, bottomRight = GuiService:GetGuiInset()
	return topLeft, bottomRight
end

local function getSafePadding(viewport)
	local topLeft, bottomRight = readGuiInset()
	local isMobile = isMobileViewport(viewport)
	local isConsole = isConsoleInput()

	local edge = isMobile and 16 or 10
	if isConsole then
		edge = 42
	end

	return {
		left = math.max(edge, math.floor(topLeft.X)),
		top = math.max(edge, math.floor(topLeft.Y)),
		right = math.max(edge, math.floor(bottomRight.X)),
		bottom = math.max(edge, math.floor(bottomRight.Y)),
	}
end

local function shouldSkipGui(gui)
	if not gui:IsA("ScreenGui") then
		return true
	end
	if gui:GetAttribute(DISABLED_ATTR) == true then
		return true
	end
	if gui.Name == "TouchGui" or gui.Name == "RobloxGui" then
		return true
	end
	return false
end

local function ensureScale(parent)
	local scale = parent:FindFirstChild(ROOT_SCALE_NAME)
	if scale and not scale:IsA("UIScale") then
		scale:Destroy()
		scale = nil
	end
	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = ROOT_SCALE_NAME
		scale.Parent = parent
	end
	return scale
end

local function ensurePadding(parent)
	local padding = parent:FindFirstChild(SAFE_AREA_NAME)
	if padding and not padding:IsA("UIPadding") then
		padding:Destroy()
		padding = nil
	end
	if not padding then
		padding = Instance.new("UIPadding")
		padding.Name = SAFE_AREA_NAME
		padding.Parent = parent
	end
	return padding
end

local function findScaleRoot(gui)
	if gui:GetAttribute("PasrahResponsiveScaleDirectScreenGui") == true then
		return gui
	end

	local preferredNames = {
		"SafeArea",
		"Root",
		"RootPanel",
		"MainPanel",
		"Panel",
		"Backdrop",
	}
	for _, name in ipairs(preferredNames) do
		local found = gui:FindFirstChild(name, true)
		if found and found:IsA("GuiObject") and found:GetAttribute(DISABLED_ATTR) ~= true then
			return found
		end
	end

	for _, child in ipairs(gui:GetChildren()) do
		if child:IsA("GuiObject") and child:GetAttribute(DISABLED_ATTR) ~= true then
			return child
		end
	end
	return gui
end

local function findSafeAreaRoot(gui, scaleRoot)
	if gui:GetAttribute("PasrahResponsiveSafeAreaDirectScreenGui") == true then
		return gui
	end
	if scaleRoot and scaleRoot:IsA("GuiObject") then
		return scaleRoot
	end
	return gui
end

local function applyToGui(gui, viewport, globalScale, safePadding)
	if shouldSkipGui(gui) then
		return
	end

	local scaleRoot = findScaleRoot(gui)
	local safeRoot = findSafeAreaRoot(gui, scaleRoot)
	local scale = ensureScale(scaleRoot)
	scale.Scale = globalScale

	local padding = ensurePadding(safeRoot)
	padding.PaddingLeft = UDim.new(0, safePadding.left)
	padding.PaddingTop = UDim.new(0, safePadding.top)
	padding.PaddingRight = UDim.new(0, safePadding.right)
	padding.PaddingBottom = UDim.new(0, safePadding.bottom)

	gui:SetAttribute(MANAGED_ATTR, true)
	gui:SetAttribute("PasrahResponsiveScale", globalScale)
	gui:SetAttribute("PasrahResponsiveViewportX", viewport.X)
	gui:SetAttribute("PasrahResponsiveViewportY", viewport.Y)
	gui:SetAttribute("PasrahResponsiveSafeTop", safePadding.top)
	gui:SetAttribute("PasrahResponsiveSafeBottom", safePadding.bottom)
end

local updateQueued = false

local function applyAll()
	local viewport = getViewportSize()
	local globalScale = computeGlobalScale(viewport)
	local safePadding = getSafePadding(viewport)

	for _, child in ipairs(PLAYER_GUI:GetChildren()) do
		if child:IsA("ScreenGui") then
			applyToGui(child, viewport, globalScale, safePadding)
		end
	end
end

local function queueApplyAll()
	if updateQueued then
		return
	end
	updateQueued = true
	task.defer(function()
		updateQueued = false
		applyAll()
	end)
end

local function bindCamera(camera)
	if not camera then
		return
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(queueApplyAll)
end

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	bindCamera(Workspace.CurrentCamera)
	queueApplyAll()
end)

PLAYER_GUI.ChildAdded:Connect(function(child)
	if child:IsA("ScreenGui") then
		queueApplyAll()
	end
end)

UserInputService.LastInputTypeChanged:Connect(queueApplyAll)
bindCamera(Workspace.CurrentCamera)
queueApplyAll()

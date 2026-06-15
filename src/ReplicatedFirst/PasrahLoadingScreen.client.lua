local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LoadingSpriteAnimator = require(ReplicatedFirst:WaitForChild("LoadingSpriteAnimator"))
local LoadingSpriteAtlas = require(ReplicatedFirst:WaitForChild("LoadingSpriteAtlas"))

local LOCAL_PLAYER = Players.LocalPlayer
local PLAYER_GUI = LOCAL_PLAYER:WaitForChild("PlayerGui")

local GUI_NAME = "PasrahReplicatedFirstLoading"
local BASE_VIEWPORT = Vector2.new(1920, 1080)
local TELEPORT_HOLD_SECONDS = 10
local TRANSITION_READY_FALLBACK_SECONDS = 35
local FADE_SECONDS = 0.45
local DEFAULT_TIP = "Gunakan suara dan alat, bukan VFX ghost saja, untuk membangun evidence."

pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

local function getViewport()
	local camera = Workspace.CurrentCamera
	if camera and camera.ViewportSize.X > 0 and camera.ViewportSize.Y > 0 then
		return camera.ViewportSize
	end
	return BASE_VIEWPORT
end

local function computeScale(viewport)
	local fit = math.min(viewport.X / BASE_VIEWPORT.X, viewport.Y / BASE_VIEWPORT.Y)
	return math.clamp(fit, 0.58, 1.12)
end

local function toUDim2ScaleSize(width, height)
	return UDim2.fromOffset(width, height)
end

local function makeLabel(parent, name, text, size, position, font, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = position
	label.Size = size
	label.Font = font
	label.Text = text
	label.TextColor3 = color
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function buildGui()
	local old = PLAYER_GUI:FindFirstChild(GUI_NAME)
	if old then
		old:Destroy()
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = GUI_NAME
	gui.DisplayOrder = 20000
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui:SetAttribute("PasrahDisableGlobalResponsiveScale", true)
	gui.Enabled = false
	gui.Parent = PLAYER_GUI

	local root = Instance.new("Frame")
	root.Name = "Root"
	root.BackgroundColor3 = Color3.fromRGB(2, 3, 6)
	root.BorderSizePixel = 0
	root.Size = UDim2.fromScale(1, 1)
	root.Parent = gui

	local scale = Instance.new("UIScale")
	scale.Name = "ResponsiveScale"
	scale.Scale = computeScale(getViewport())
	scale.Parent = root

	local safePadding = Instance.new("UIPadding")
	safePadding.Name = "SafeAreaPadding"
	safePadding.Parent = root

	local vignette = Instance.new("ImageLabel")
	vignette.Name = "Vignette"
	vignette.BackgroundTransparency = 1
	vignette.Image = "rbxassetid://105007652506979"
	vignette.ImageTransparency = 0.08
	vignette.ScaleType = Enum.ScaleType.Crop
	vignette.Size = UDim2.fromScale(1, 1)
	vignette.Parent = root

	local shade = Instance.new("Frame")
	shade.Name = "Shade"
	shade.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shade.BackgroundTransparency = 0.22
	shade.BorderSizePixel = 0
	shade.Size = UDim2.fromScale(1, 1)
	shade.Parent = root

	local sprite = Instance.new("ImageLabel")
	sprite.Name = "LoadingSprite"
	sprite.BackgroundTransparency = 1
	sprite.AnchorPoint = Vector2.new(0.5, 0.5)
	sprite.Position = UDim2.fromScale(0.5, 0.47)
	sprite.Size = toUDim2ScaleSize(960, 540)
	sprite.ScaleType = Enum.ScaleType.Fit
	sprite.Parent = root

	local status = makeLabel(root, "StatusLabel", "MEMUAT PASRAHPHOBIA", UDim2.fromOffset(680, 34), UDim2.fromScale(0.5, 0.13), Enum.Font.GothamMedium, Color3.fromRGB(185, 199, 214))
	status.TextSize = 18

	local title = makeLabel(root, "TitleLabel", "Masuk ke lokasi...", UDim2.fromOffset(860, 64), UDim2.fromScale(0.5, 0.72), Enum.Font.GothamBlack, Color3.fromRGB(244, 246, 248))
	title.TextSize = 38

	local tip = makeLabel(root, "TipLabel", DEFAULT_TIP, UDim2.fromOffset(860, 54), UDim2.fromScale(0.5, 0.79), Enum.Font.Gotham, Color3.fromRGB(209, 218, 230))
	tip.TextSize = 18

	local guide = makeLabel(root, "GuideLabel", "Panduan: tunggu asset map, audio, tool, dan ghost selesai disiapkan.", UDim2.fromOffset(860, 40), UDim2.fromScale(0.5, 0.855), Enum.Font.GothamMedium, Color3.fromRGB(145, 164, 185))
	guide.TextSize = 14

	local track = Instance.new("Frame")
	track.Name = "ProgressTrack"
	track.AnchorPoint = Vector2.new(0.5, 0)
	track.Position = UDim2.fromScale(0.5, 0.91)
	track.Size = UDim2.fromOffset(520, 6)
	track.BackgroundColor3 = Color3.fromRGB(38, 48, 62)
	track.BorderSizePixel = 0
	track.Parent = root

	local fill = Instance.new("Frame")
	fill.Name = "ProgressFill"
	fill.BackgroundColor3 = Color3.fromRGB(153, 207, 225)
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0.08, 1)
	fill.Parent = track

	for _, target in ipairs({ track, fill }) do
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 999)
		corner.Parent = target
	end

	return {
		gui = gui,
		root = root,
		scale = scale,
		safePadding = safePadding,
		sprite = sprite,
		status = status,
		title = title,
		tip = tip,
		guide = guide,
		fill = fill,
	}
end

local ui = buildGui()
local stopSprite = nil
local visibleToken = 0
local activeMode = "Startup"
local transitionToken = 0
local hideSoon

local function applyViewport()
	local viewport = getViewport()
	ui.scale.Scale = computeScale(viewport)
	local topLeft, bottomRight = GuiService:GetGuiInset()
	local edge = math.max(10, math.floor(math.min(viewport.X, viewport.Y) * 0.012))
	ui.safePadding.PaddingLeft = UDim.new(0, math.max(edge, topLeft.X))
	ui.safePadding.PaddingTop = UDim.new(0, math.max(edge, topLeft.Y))
	ui.safePadding.PaddingRight = UDim.new(0, math.max(edge, bottomRight.X))
	ui.safePadding.PaddingBottom = UDim.new(0, math.max(edge, bottomRight.Y))
end

local function setText(mode, titleText, guideText)
	activeMode = mode or activeMode
	ui.status.Text = string.upper(activeMode)
	ui.title.Text = titleText or "Masuk ke lokasi..."
	ui.guide.Text = guideText or "Panduan: tunggu asset map, audio, tool, dan ghost selesai disiapkan."
end

local function show(mode, titleText, guideText)
	visibleToken += 1
	ui.gui.Enabled = true
	ui.root.BackgroundTransparency = 0
	setText(mode, titleText, guideText)
	if not stopSprite then
		stopSprite = LoadingSpriteAnimator.start(ui.sprite, LoadingSpriteAtlas)
	end
end

local function holdTransition(mode, titleText, guideText, fallbackSeconds)
	transitionToken += 1
	local token = transitionToken
	show(mode, titleText, guideText)
	task.delay(math.max(8, tonumber(fallbackSeconds) or TRANSITION_READY_FALLBACK_SECONDS), function()
		if transitionToken ~= token then
			return
		end
		hideSoon(0)
	end)
end

local function revealTransition(delaySeconds)
	transitionToken += 1
	hideSoon(delaySeconds or 0)
end

hideSoon = function(delaySeconds)
	local token = visibleToken + 1
	visibleToken = token
	task.delay(math.max(0, delaySeconds or 0), function()
		if visibleToken ~= token then
			return
		end
		local tween = TweenService:Create(ui.root, TweenInfo.new(FADE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		})
		tween:Play()
		tween.Completed:Connect(function()
			if visibleToken == token then
				ui.gui.Enabled = false
			end
		end)
	end)
end

task.spawn(function()
	pcall(function()
		ContentProvider:PreloadAsync(LoadingSpriteAtlas.Atlases)
	end)
end)

applyViewport()

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(applyViewport)
if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(applyViewport)
end

local function bindLobbyRemote(remote)
	if not (remote and remote:IsA("RemoteEvent")) then
		return
	end
	remote.OnClientEvent:Connect(function(payload)
		local eventName = payload and payload.eventName
		if eventName == "MatchPreparing" then
			holdTransition("Teleport Loading", "Memuat lokasi...", "Panduan loading: jangan klik ulang ready; tunggu runtime HauntedHouse, tools, dan ghost selesai disiapkan.", TRANSITION_READY_FALLBACK_SECONDS)
		elseif eventName == "MatchStarted" then
			holdTransition("Loading", "Sinkronisasi match...", "Panduan: menunggu posisi pemain, HUD, SFX, VFX, inventory, lights, dan teman aktif.", TRANSITION_READY_FALLBACK_SECONDS)
		elseif eventName == "MatchRuntimeReady" or eventName == "ClientMatchReveal" then
			setText("Ready", "Investigasi siap.", "Runtime map, lighting, tools, ghost, dan pemain sudah disinkronkan.")
			revealTransition(0.35)
		elseif eventName == "ReturnedToLobby" or eventName == "RoomBrowserRoomLeft" then
			revealTransition(0)
		end
	end)
end

task.spawn(function()
	local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents", 30)
	local lobbyRemote = remoteFolder and remoteFolder:WaitForChild("LobbyEvent", 30)
	local matchRemote = remoteFolder and remoteFolder:WaitForChild("MatchEvent", 30)
	bindLobbyRemote(lobbyRemote)
	bindLobbyRemote(matchRemote)
end)

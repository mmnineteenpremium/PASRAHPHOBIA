local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local UISystem = {}
UISystem.__index = UISystem

local RoomBrowserController = require(script.Parent.RoomBrowserController)

local UI_MODULES = {
	"JournalUI",
	"LobbyUI",
	"MatchUI",
	"ProfileUI",
	"ShopUI",
	"RoyalPassUI",
	"PASRA_UI",
	"SpectatorUI",
}

local REMOTE_NAMES = { "MatchEvent", "LobbyEvent", "EvidenceEvent", "PurchaseEvent", "RoyalPassEvent", "SanityEvent", "CosmeticEvent" }
local UI_INPUT_PROFILE_OVERRIDE_ATTR = "PasrahUIInputProfileOverride"
local UI_FORCE_COMPACT_ATTR = "PasrahUIForceCompact"
local UI_VIEWPORT_OVERRIDE_X_ATTR = "PasrahUIViewportOverrideX"
local UI_VIEWPORT_OVERRIDE_Y_ATTR = "PasrahUIViewportOverrideY"
local REINFORCED_SALT_OWNED_ATTR = "PasrahOwnsReinforcedSaltBag"
local ROOM_BROWSER_TOGGLE_KEY = Enum.KeyCode.M
local MATCH_PANEL_TOGGLE_KEY = Enum.KeyCode.K
local BASIC_GUI_NAMES = { "JournalUI", "LobbyUI", "MatchUI", "ProfileUI", "ShopUI", "RoyalPassUI", "PASRA_UI", "SpectatorUI", "LeaderboardUI", "MainMenuUI" }
local CONFLICT_BASIC_GUI_NAMES = { "MainMenuUI", "LeaderboardUI" }
local MAPS = { "HauntedHouse", "AbandonedPalace", "EmptyBuilding", "StudioMMNineteen" }
local LOBBY_ONLY_GUI_NAMES = {
	LobbyUI = true,
	ProfileUI = true,
	RoyalPassUI = true,
	ShopUI = true,
	LeaderboardUI = true,
	MainMenuUI = true,
}
local AUXILIARY_UI_NAMES = { "JournalUI", "ProfileUI", "ShopUI", "RoyalPassUI", "PASRA_UI", "SpectatorUI" }
local AUXILIARY_WINDOW_TOGGLE_KEYS = {
	JournalUI = Enum.KeyCode.J,
	ProfileUI = Enum.KeyCode.P,
	ShopUI = Enum.KeyCode.B,
	RoyalPassUI = Enum.KeyCode.R,
	PASRA_UI = Enum.KeyCode.U,
	SpectatorUI = Enum.KeyCode.V,
}
local AUXILIARY_WINDOW_CONFIG = {
	JournalUI = {
		title = "JURNAL",
		badgeText = "EVIDENCE",
		floatText = "JOURNAL",
		panelPosition = UDim2.fromOffset(16, 104),
		panelAnchorPoint = Vector2.new(0, 0),
		panelSize = Vector2.new(360, 396),
		floatPosition = UDim2.new(0, 18, 0.62, 0),
		badgeColor = Color3.fromRGB(56, 92, 128),
		footer = "Shortcut: J. Basic journal ini dibuat untuk test E2E deduction.",
	},
	ProfileUI = {
		title = "PROFILE",
		badgeText = "PLAYER",
		floatText = "PROFILE",
		panelPosition = UDim2.new(1, -372, 0, 16),
		panelAnchorPoint = Vector2.new(0, 0),
		panelSize = Vector2.new(340, 300),
		floatPosition = UDim2.new(1, -18, 0.28, 0),
		badgeColor = Color3.fromRGB(74, 96, 58),
		footer = "Ringkasan profil dasar ini memakai data runtime yang tersedia di client.",
	},
	ShopUI = {
		title = "SHOP",
		badgeText = "STORE",
		floatText = "SHOP",
		panelPosition = UDim2.new(1, -16, 1, -16),
		panelAnchorPoint = Vector2.new(1, 1),
		panelSize = Vector2.new(356, 424),
		floatPosition = UDim2.new(1, -18, 0.78, 0),
		badgeColor = Color3.fromRGB(124, 92, 48),
		footer = "Shop aktif mendukung MM/PP dan slot Robux yang siap diaktifkan lewat Creator Hub.",
	},
	RoyalPassUI = {
		title = "ROYAL PASS",
		badgeText = "PASS",
		floatText = "PASS",
		panelPosition = UDim2.new(1, -16, 0.5, 0),
		panelAnchorPoint = Vector2.new(1, 0.5),
		panelSize = Vector2.new(348, 340),
		floatPosition = UDim2.new(1, -18, 0.46, 0),
		badgeColor = Color3.fromRGB(116, 88, 44),
		footer = "Shortcut: R. Progress Royal Pass ini hanya surface client untuk snapshot runtime yang aktif.",
	},
	PASRA_UI = {
		title = "PASRA STATUS",
		badgeText = "SUMMARY",
		floatText = "PASRA",
		panelPosition = UDim2.new(0, 16, 1, -16),
		panelAnchorPoint = Vector2.new(0, 1),
		panelSize = Vector2.new(360, 300),
		floatPosition = UDim2.new(0, 18, 0.82, 0),
		badgeColor = Color3.fromRGB(58, 100, 88),
		footer = "Panel ini merangkum hasil match, reward, dan status runtime dasar.",
	},
	SpectatorUI = {
		title = "SPECTATOR",
		badgeText = "DEATH",
		floatText = "VIEW",
		panelPosition = UDim2.fromOffset(16, 16),
		panelAnchorPoint = Vector2.new(0, 0),
		panelSize = Vector2.new(360, 320),
		floatPosition = UDim2.new(0, 18, 0.42, 0),
		badgeColor = Color3.fromRGB(120, 52, 52),
		footer = "Info spectator basic. Tutup jika mengganggu, buka lagi dari tombol float.",
	},
}
local MATCH_PHASE = {
	LOBBY = "Lobby",
	PREPARING = "Preparing",
	LOADING = "Loading",
	BRIEFING = "Briefing",
	INGAME = "InGame",
	ESCALATION = "Escalation",
	HUNT = "Hunt",
	RESULT = "Result",
	END = "End",
}

local CLOSE_KEYBOARD_KEY = Enum.KeyCode.Escape
local CLOSE_GAMEPAD_KEY = Enum.KeyCode.ButtonB
local CLOSE_HINT_TEXT = "[Esc] / [B] / [X] untuk tutup"
local JOURNAL_TOOL_TYPE = "JejakEnergi"
local FIELD_KIT_TOOL_ORDER = { "JejakEnergi", "Garam", "Salib", "Dupa", "KotakArwah" }
local FIELD_KIT_TOOL_CONFIG = {
	JejakEnergi = {
		accent = Color3.fromRGB(66, 104, 146),
		glyph = "JN",
		label = "SCAN",
		openJournal = true,
		role = "Sensor",
		shortcut = "1",
		keyCode = Enum.KeyCode.One,
	},
	Garam = {
		accent = Color3.fromRGB(122, 110, 68),
		glyph = "GR",
		label = "GARAM",
		maxUses = 3,
		openJournal = false,
		role = "Trap",
		shortcut = "2",
		keyCode = Enum.KeyCode.Two,
	},
	Salib = {
		accent = Color3.fromRGB(110, 84, 58),
		glyph = "SL",
		label = "SALIB",
		maxCharges = 3,
		maxUses = 2,
		openJournal = false,
		role = "Guard",
		shortcut = "3",
		keyCode = Enum.KeyCode.Three,
	},
	Dupa = {
		accent = Color3.fromRGB(132, 78, 52),
		glyph = "DP",
		label = "DUPA",
		maxUses = 2,
		openJournal = false,
		role = "Repel",
		shortcut = "4",
		keyCode = Enum.KeyCode.Four,
	},
	KotakArwah = {
		accent = Color3.fromRGB(84, 120, 120),
		glyph = "KA",
		label = "SPIRIT",
		openJournal = false,
		role = "Voice",
		shortcut = "5",
		keyCode = Enum.KeyCode.Five,
	},
}

local function createDefaultFieldKitToolState(toolType)
	local config = FIELD_KIT_TOOL_CONFIG[toolType] or {}
	local usesRemaining = tonumber(config.maxUses)
	local localPlayer = Players.LocalPlayer
	if toolType == "Garam" and localPlayer and localPlayer:GetAttribute(REINFORCED_SALT_OWNED_ATTR) == true then
		usesRemaining = (usesRemaining or 0) + 1
	end
	return {
		usesRemaining = usesRemaining and math.max(0, math.floor(usesRemaining)) or nil,
		chargesRemaining = nil,
		visualPlaced = false,
		placementId = nil,
		pending = false,
		lastEvent = "Idle",
		lastReason = nil,
		lastSuccess = nil,
		lastUpdatedAt = 0,
	}
end

local function createDefaultFieldKitToolStates()
	local states = {}
	for _, toolType in ipairs(FIELD_KIT_TOOL_ORDER) do
		states[toolType] = createDefaultFieldKitToolState(toolType)
	end
	return states
end
local RESULTS_LOCK_SECONDS = 5
local DEFAULT_MATCH_OBJECTIVE_TEXT = "Investigate the location\nFind evidence\nIdentify the ghost"
local TELEPORT_OVERLAY_GUI_NAME = "TeleportScreen"
local TELEPORT_OVERLAY_FRAME_NAME = "LoadingOverlay"
local TELEPORT_OVERLAY_HOLD_SECONDS = 5
local TELEPORT_OVERLAY_FADE_SECONDS = 0.35
local LOADING_TIPS = {
	"Gunakan [J] untuk buka Journal dan cek evidence yang sudah terkumpul.",
	"Gunakan [F] untuk menyalakan flashlight saat area mulai gelap.",
	"Ghost bisa memburu kamu. Putus line-of-sight dan cari ruang aman.",
	"Perhatikan timer dan objective agar flow investigasi tetap jelas.",
}

local function safeRequire(moduleScript)
	if not moduleScript then
		return nil
	end
	local ok, result = pcall(require, moduleScript)
	if ok then
		return result
	end
	return nil
end

local function loadMapMetadata()
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:FindFirstChild("shared")
	if not shared then
		return {}
	end
	local gameDataFolder = shared:FindFirstChild("GameData")
	if not gameDataFolder then
		return {}
	end
	local mapsFolder = gameDataFolder:FindFirstChild("Maps")
	if not mapsFolder then
		return {}
	end

	local out = {}
	for _, moduleScript in ipairs(mapsFolder:GetChildren()) do
		if moduleScript:IsA("ModuleScript") then
			local value = safeRequire(moduleScript)
			if type(value) == "table" then
				out[moduleScript.Name] = value
			end
		end
	end
	return out
end

local MAP_METADATA = loadMapMetadata()
local UI_BRAND = {
	text = Color3.fromRGB(244, 241, 234),
	muted = Color3.fromRGB(184, 194, 208),
	ink = Color3.fromRGB(18, 22, 30),
	focus = Color3.fromRGB(236, 196, 116),
	focusSoft = Color3.fromRGB(132, 101, 58),
	sheen = Color3.fromRGB(255, 237, 199),
}
local BUTTON_TWEEN_INFO = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BUTTON_PRESS_TWEEN_INFO = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PANEL_REVEAL_TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local UI_SOUND_PATHS = {
	ButtonClick = { "Assets", "Audio", "UI", "ButtonClick_01" },
	CountdownTick = { "Assets", "Audio", "UI", "CountdownTick_01" },
	TeleportDrop = { "Assets", "Audio", "UI", "TeleportDrop_01" },
}
local UI_SOUND_FALLBACKS = {
	ButtonClick = {
		SoundId = "rbxasset://sounds/volume_slider.ogg",
		Volume = 0.14,
	},
}
local cachedSoundTemplates = {}
local activeRuntimeUISounds = {}

local function logRoomClickConnected(buttonName)
	return buttonName
end

local function ensureCorner(guiObject, name, radius)
	if not guiObject then
		return nil
	end

	local corner = nil
	if name then
		corner = guiObject:FindFirstChild(name)
	end
	if not corner then
		corner = guiObject:FindFirstChildOfClass("UICorner")
	end
	if not corner then
		corner = Instance.new("UICorner")
		if name then
			corner.Name = name
		end
		corner.Parent = guiObject
	end
	if radius then
		corner.CornerRadius = radius
	end
	return corner
end

local function ensureNamedScale(guiObject, name)
	local scale = guiObject:FindFirstChild(name)
	if scale and scale:IsA("UIScale") then
		return scale
	end

	scale = Instance.new("UIScale")
	scale.Name = name
	scale.Scale = 1
	scale.Parent = guiObject
	return scale
end

local function setOffsetBounds(guiObject, x, y, width, height)
	if not guiObject then
		return
	end
	guiObject.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
	guiObject.Size = UDim2.fromOffset(math.floor(width), math.floor(height))
end

local function tweenInstance(instance, tweenInfo, properties)
	local tween = TweenService:Create(instance, tweenInfo, properties)
	tween:Play()
	return tween
end

local function resolveSoundTemplate(pathSegments)
	local cursor = ReplicatedStorage
	for _, segment in ipairs(pathSegments) do
		if not cursor then
			return nil
		end
		cursor = cursor:FindFirstChild(segment)
	end

	if cursor and cursor:IsA("Sound") and tostring(cursor.SoundId or "") ~= "" then
		return cursor
	end

	return nil
end

local function createFallbackSoundTemplate(soundKey)
	local config = UI_SOUND_FALLBACKS[soundKey]
	if type(config) ~= "table" then
		return nil
	end

	local template = Instance.new("Sound")
	template.Name = "Fallback" .. tostring(soundKey)
	template.SoundId = tostring(config.SoundId or "")
	template.Volume = tonumber(config.Volume) or 0.2
	template.RollOffMinDistance = tonumber(config.RollOffMinDistance) or 5
	template.RollOffMaxDistance = tonumber(config.RollOffMaxDistance) or 40
	template.Looped = config.Looped == true
	template:SetAttribute("PasrahRuntimeTemplate", true)
	return template
end

local function getCachedSoundTemplate(soundKey)
	local pathSegments = UI_SOUND_PATHS[soundKey]
	if type(pathSegments) ~= "table" then
		return nil
	end

	local cached = cachedSoundTemplates[soundKey]
	if cached and (cached.Parent or cached:GetAttribute("PasrahRuntimeTemplate") == true) then
		return cached
	end

	local resolved = resolveSoundTemplate(pathSegments)
	if resolved and tostring(resolved.SoundId or "") ~= "" then
		cachedSoundTemplates[soundKey] = resolved
		return resolved
	end

	local fallback = createFallbackSoundTemplate(soundKey)
	if fallback then
		cachedSoundTemplates[soundKey] = fallback
		return fallback
	end

	return resolved
end

local function playRuntimeUISound(soundKey, options)
	local template = getCachedSoundTemplate(soundKey)
	if not template then
		return
	end

	local existing = activeRuntimeUISounds[soundKey]
	if options and options.SingleInstance and existing then
		if existing.Parent then
			existing:Stop()
			existing:Destroy()
		end
		activeRuntimeUISounds[soundKey] = nil
	end

	local runtimeSound = template:Clone()
	runtimeSound.Name = "Runtime" .. tostring(soundKey)
	runtimeSound.Looped = false
	if options and options.VolumeScale then
		runtimeSound.Volume = math.max(0, runtimeSound.Volume * options.VolumeScale)
	end
	if options and options.PlaybackSpeed then
		runtimeSound.PlaybackSpeed = options.PlaybackSpeed
	end
	if options and options.PlaybackJitter then
		local jitter = tonumber(options.PlaybackJitter) or 0
		runtimeSound.PlaybackSpeed = math.clamp(runtimeSound.PlaybackSpeed + ((math.random() * jitter) - (jitter * 0.5)), 0.85, 1.25)
	end
	runtimeSound.Parent = SoundService
	if options and options.SingleInstance then
		activeRuntimeUISounds[soundKey] = runtimeSound
	end
	runtimeSound:Play()
	runtimeSound.Ended:Connect(function()
		if activeRuntimeUISounds[soundKey] == runtimeSound then
			activeRuntimeUISounds[soundKey] = nil
		end
	end)
	task.delay(math.max(runtimeSound.TimeLength, 0.35) + 0.2, function()
		if runtimeSound and runtimeSound.Parent then
			runtimeSound:Destroy()
		end
		if activeRuntimeUISounds[soundKey] == runtimeSound then
			activeRuntimeUISounds[soundKey] = nil
		end
	end)
end

local function stopRuntimeUISound(soundKey)
	local existing = activeRuntimeUISounds[soundKey]
	if not existing then
		return
	end
	activeRuntimeUISounds[soundKey] = nil
	if existing.Parent then
		existing:Stop()
		existing:Destroy()
	end
end

local function playUIButtonClick()
	if not getCachedSoundTemplate("ButtonClick") then
		local fallbackConfig = UI_SOUND_FALLBACKS.ButtonClick
		if type(fallbackConfig) == "table" and type(fallbackConfig.SoundId) == "string" and fallbackConfig.SoundId ~= "" then
			local runtimeSound = Instance.new("Sound")
			runtimeSound.Name = "RuntimeButtonClick"
			runtimeSound.SoundId = fallbackConfig.SoundId
			runtimeSound.Volume = tonumber(fallbackConfig.Volume) or 0.14
			runtimeSound.Looped = false
			runtimeSound.Parent = SoundService
			runtimeSound:Play()
			task.delay(math.max(runtimeSound.TimeLength, 0.35) + 0.2, function()
				if runtimeSound and runtimeSound.Parent then
					runtimeSound:Destroy()
				end
			end)
			return
		end
	end

	playRuntimeUISound("ButtonClick", {
		PlaybackJitter = 0.04,
	})
end

local function pulseCountdownLabel(label)
	if not label then
		return
	end

	local scale = ensureNamedScale(label, "CountdownPulseScale")
	scale.Scale = 1.12
	tweenInstance(scale, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Scale = 1,
	})
end

local function ensureButtonPolish(button)
	if not button then
		return nil
	end

	button.ClipsDescendants = true
	ensureCorner(button, "ButtonCorner", UDim.new(0, 8))

	local scale = ensureNamedScale(button, "BrandScale")

	local overlay = button:FindFirstChild("BrandOverlay")
	if not overlay or not overlay:IsA("Frame") then
		overlay = Instance.new("Frame")
		overlay.Name = "BrandOverlay"
		overlay.BackgroundColor3 = UI_BRAND.sheen
		overlay.BackgroundTransparency = 0.95
		overlay.BorderSizePixel = 0
		overlay.Size = UDim2.fromScale(1, 1)
		overlay.ZIndex = math.max(0, button.ZIndex - 1)
		overlay.Active = false
		overlay.Parent = button
	end
	overlay.Size = UDim2.fromScale(1, 1)
	ensureCorner(overlay, "OverlayCorner", UDim.new(0, 8))

	local stroke = button:FindFirstChild("BrandStroke")
	if not stroke or not stroke:IsA("UIStroke") then
		stroke = Instance.new("UIStroke")
		stroke.Name = "BrandStroke"
		stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		stroke.LineJoinMode = Enum.LineJoinMode.Round
		stroke.Thickness = 1
		stroke.Transparency = 0.34
		stroke.Color = UI_BRAND.focusSoft
		stroke.Parent = button
	end

	local gradient = button:FindFirstChild("BrandGradient")
	if not gradient or not gradient:IsA("UIGradient") then
		gradient = Instance.new("UIGradient")
		gradient.Name = "BrandGradient"
		gradient.Rotation = 90
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(210, 220, 236)),
		})
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.12),
			NumberSequenceKeypoint.new(1, 0.34),
		})
		gradient.Parent = button
	end

	return {
		Scale = scale,
		Overlay = overlay,
		Stroke = stroke,
		Gradient = gradient,
	}
end

local function refreshButtonPolish(button, immediate)
	local parts = ensureButtonPolish(button)
	if not parts then
		return
	end

	local hovered = button:GetAttribute("BrandHovered") == true
	local focused = button:GetAttribute("BrandFocused") == true
	local pressed = button:GetAttribute("BrandPressed") == true
	local selected = button:GetAttribute("BrandSelected") == true

	local overlayTransparency = 0.95
	local strokeTransparency = 0.34
	local strokeThickness = 1
	local scaleTarget = 1

	if selected then
		overlayTransparency = 0.9
		strokeTransparency = 0.12
		strokeThickness = 1.8
	end
	if hovered then
		overlayTransparency = math.min(overlayTransparency, 0.87)
		strokeTransparency = math.min(strokeTransparency, 0.22)
		strokeThickness = math.max(strokeThickness, 1.4)
		scaleTarget = math.max(scaleTarget, 1.012)
	end
	if focused then
		overlayTransparency = math.min(overlayTransparency, 0.82)
		strokeTransparency = 0
		strokeThickness = math.max(strokeThickness, 2.2)
		scaleTarget = math.max(scaleTarget, 1.02)
	end
	if pressed then
		overlayTransparency = math.min(overlayTransparency, 0.76)
		strokeTransparency = 0
		strokeThickness = math.max(strokeThickness, 2.8)
		scaleTarget = 0.985
	end

	if immediate then
		parts.Overlay.BackgroundTransparency = overlayTransparency
		parts.Stroke.Transparency = strokeTransparency
		parts.Stroke.Thickness = strokeThickness
		parts.Scale.Scale = scaleTarget
	else
		local tweenInfo = pressed and BUTTON_PRESS_TWEEN_INFO or BUTTON_TWEEN_INFO
		tweenInstance(parts.Overlay, tweenInfo, { BackgroundTransparency = overlayTransparency })
		tweenInstance(parts.Stroke, tweenInfo, {
			Transparency = strokeTransparency,
			Thickness = strokeThickness,
		})
		tweenInstance(parts.Scale, tweenInfo, { Scale = scaleTarget })
	end
end

local function bindButtonPolish(button)
	if not button or button:GetAttribute("BrandFeedbackBound") == true then
		refreshButtonPolish(button, true)
		return
	end

	button:SetAttribute("BrandFeedbackBound", true)
	ensureButtonPolish(button)
	refreshButtonPolish(button, true)

	button.MouseEnter:Connect(function()
		button:SetAttribute("BrandHovered", true)
		refreshButtonPolish(button, false)
	end)
	button.MouseLeave:Connect(function()
		button:SetAttribute("BrandHovered", false)
		button:SetAttribute("BrandPressed", false)
		refreshButtonPolish(button, false)
	end)
	button.SelectionGained:Connect(function()
		button:SetAttribute("BrandFocused", true)
		refreshButtonPolish(button, false)
	end)
	button.SelectionLost:Connect(function()
		button:SetAttribute("BrandFocused", false)
		refreshButtonPolish(button, false)
	end)
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or tostring(input.KeyCode) == tostring(Enum.KeyCode.ButtonA)
		then
			button:SetAttribute("BrandPressed", true)
			refreshButtonPolish(button, false)
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or tostring(input.KeyCode) == tostring(Enum.KeyCode.ButtonA)
		then
			button:SetAttribute("BrandPressed", false)
			refreshButtonPolish(button, false)
		end
	end)
end

local function animatePanelReveal(panel, immediate)
	if not panel or not panel:IsA("GuiObject") then
		return
	end

	local scale = ensureNamedScale(panel, "BrandPanelScale")
	if immediate then
		scale.Scale = 1
		return
	end

	scale.Scale = 0.985
	tweenInstance(scale, PANEL_REVEAL_TWEEN_INFO, { Scale = 1 })
end

local function setAnimatedPanelVisible(panel, visible, immediate)
	if not panel or not panel:IsA("GuiObject") then
		return
	end

	local shouldShow = visible == true
	local wasVisible = panel:GetAttribute("BrandPanelVisible") == true or panel.Visible == true
	panel.Visible = shouldShow
	panel:SetAttribute("BrandPanelVisible", shouldShow)
	if shouldShow and not wasVisible then
		animatePanelReveal(panel, immediate)
	end
end

local function styleButton(button, text)
	button.Text = text
	button.TextColor3 = UI_BRAND.text
	button.Font = Enum.Font.GothamSemibold
	button.TextSize = 14
	button.BorderSizePixel = 0
	button.BackgroundColor3 = Color3.fromRGB(46, 57, 73)
	button.AutoButtonColor = false
	button.TextStrokeTransparency = 0.92
	button.TextStrokeColor3 = UI_BRAND.ink
	bindButtonPolish(button)
	refreshButtonPolish(button, true)
end

local function ensureFieldKitButtonVisuals(button, definition)
	if not button then
		return nil
	end

	button.Text = ""
	button.TextTransparency = 1
	button.ClipsDescendants = true

	local glyphPlate = button:FindFirstChild("GlyphPlate")
	if not glyphPlate or not glyphPlate:IsA("Frame") then
		glyphPlate = Instance.new("Frame")
		glyphPlate.Name = "GlyphPlate"
		glyphPlate.BorderSizePixel = 0
		glyphPlate.ZIndex = button.ZIndex + 1
		glyphPlate.Parent = button
	end
	ensureCorner(glyphPlate, "GlyphCorner", UDim.new(0, 10))

	local glyphLabel = glyphPlate:FindFirstChild("Glyph")
	if not glyphLabel or not glyphLabel:IsA("TextLabel") then
		glyphLabel = Instance.new("TextLabel")
		glyphLabel.Name = "Glyph"
		glyphLabel.BackgroundTransparency = 1
		glyphLabel.Font = Enum.Font.GothamBlack
		glyphLabel.TextSize = 12
		glyphLabel.TextXAlignment = Enum.TextXAlignment.Center
		glyphLabel.TextYAlignment = Enum.TextYAlignment.Center
		glyphLabel.ZIndex = glyphPlate.ZIndex + 1
		glyphLabel.Parent = glyphPlate
	end

	local shortcutLabel = button:FindFirstChild("ShortcutLabel")
	if not shortcutLabel or not shortcutLabel:IsA("TextLabel") then
		shortcutLabel = Instance.new("TextLabel")
		shortcutLabel.Name = "ShortcutLabel"
		shortcutLabel.BackgroundTransparency = 1
		shortcutLabel.Font = Enum.Font.GothamBlack
		shortcutLabel.TextSize = 8
		shortcutLabel.TextXAlignment = Enum.TextXAlignment.Right
		shortcutLabel.TextYAlignment = Enum.TextYAlignment.Center
		shortcutLabel.ZIndex = button.ZIndex + 1
		shortcutLabel.Parent = button
	end

	local titleLabel = button:FindFirstChild("TitleLabel")
	if not titleLabel or not titleLabel:IsA("TextLabel") then
		titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 11
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextYAlignment = Enum.TextYAlignment.Center
		titleLabel.ZIndex = button.ZIndex + 1
		titleLabel.Parent = button
	end

	local metaLabel = button:FindFirstChild("MetaLabel")
	if not metaLabel or not metaLabel:IsA("TextLabel") then
		metaLabel = Instance.new("TextLabel")
		metaLabel.Name = "MetaLabel"
		metaLabel.BorderSizePixel = 0
		metaLabel.Font = Enum.Font.GothamBlack
		metaLabel.TextSize = 8
		metaLabel.TextXAlignment = Enum.TextXAlignment.Center
		metaLabel.TextYAlignment = Enum.TextYAlignment.Center
		metaLabel.ZIndex = button.ZIndex + 1
		metaLabel.Parent = button
	end
	ensureCorner(metaLabel, "MetaCorner", UDim.new(1, 0))

	local footerLabel = button:FindFirstChild("FooterLabel")
	if not footerLabel or not footerLabel:IsA("TextLabel") then
		footerLabel = Instance.new("TextLabel")
		footerLabel.Name = "FooterLabel"
		footerLabel.BackgroundTransparency = 1
		footerLabel.Font = Enum.Font.GothamMedium
		footerLabel.TextSize = 8
		footerLabel.TextXAlignment = Enum.TextXAlignment.Left
		footerLabel.TextYAlignment = Enum.TextYAlignment.Center
		footerLabel.ZIndex = button.ZIndex + 1
		footerLabel.Parent = button
	end

	glyphLabel.Text = tostring((definition and definition.glyph) or "?")
	titleLabel.Text = tostring((definition and definition.label) or "TOOL")
	shortcutLabel.Text = string.format("[%s]", tostring((definition and definition.shortcut) or "?"))
	metaLabel.Text = "READY"
	footerLabel.Text = string.upper(tostring((definition and definition.role) or "UTILITY"))

	return {
		Button = button,
		GlyphPlate = glyphPlate,
		GlyphLabel = glyphLabel,
		ShortcutLabel = shortcutLabel,
		TitleLabel = titleLabel,
		MetaLabel = metaLabel,
		FooterLabel = footerLabel,
	}
end

local function deriveFloatGlyph(labelText)
	local compact = tostring(labelText or ""):gsub("[%c]+", " "):gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
	if compact == "" then
		return "UI"
	end

	local initials = {}
	for token in compact:gmatch("%S+") do
		table.insert(initials, token:sub(1, 1))
		if #initials >= 2 then
			break
		end
	end
	if #initials == 0 then
		return "UI"
	end
	if #initials == 1 then
		local collapsed = compact:gsub("%s+", "")
		return string.upper((collapsed:sub(1, 2) ~= "" and collapsed:sub(1, 2)) or initials[1])
	end
	return string.upper(table.concat(initials, ""))
end

local function styleFloatingButton(button, labelText, accentColor)
	if not button then
		return
	end

	local captionText = tostring(labelText or ""):gsub("[%c]+", " "):gsub("%s+", " "):match("^%s*(.-)%s*$") or "OPEN"
	if captionText == "" then
		captionText = "OPEN"
	end
	captionText = string.upper(captionText)

	local accent = accentColor or UI_BRAND.focus
	button.Text = ""
	button.AutoButtonColor = false
	button.TextScaled = false
	button.TextWrapped = false
	button.BackgroundColor3 = Color3.fromRGB(18, 24, 33)
	button.BackgroundTransparency = 0.08
	button.BorderSizePixel = 0
	button.ClipsDescendants = true
	ensureCorner(button, "FloatButtonCorner", UDim.new(0, 18))
	local polish = ensureButtonPolish(button)
	if polish and polish.Stroke then
		polish.Stroke.Color = accent:Lerp(Color3.fromRGB(255, 248, 236), 0.2)
	end
	if polish and polish.Gradient then
		polish.Gradient.Rotation = 32
		polish.Gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, accent:Lerp(Color3.fromRGB(255, 248, 236), 0.18)),
			ColorSequenceKeypoint.new(0.55, Color3.fromRGB(44, 56, 74)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 24, 33)),
		})
		polish.Gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.18),
			NumberSequenceKeypoint.new(1, 0.36),
		})
	end

	local accentBar = button:FindFirstChild("FloatAccent")
	if not accentBar or not accentBar:IsA("Frame") then
		accentBar = Instance.new("Frame")
		accentBar.Name = "FloatAccent"
		accentBar.BorderSizePixel = 0
		accentBar.ZIndex = button.ZIndex + 1
		accentBar.Parent = button
	end
	accentBar.BackgroundColor3 = accent
	accentBar.BackgroundTransparency = 0.08
	accentBar.Position = UDim2.new(0.18, 0, 0, 6)
	accentBar.Size = UDim2.new(0.64, 0, 0, 4)
	ensureCorner(accentBar, "FloatAccentCorner", UDim.new(0, 999))

	local glyph = button:FindFirstChild("FloatGlyph")
	if not glyph or not glyph:IsA("TextLabel") then
		glyph = Instance.new("TextLabel")
		glyph.Name = "FloatGlyph"
		glyph.BackgroundTransparency = 1
		glyph.Font = Enum.Font.GothamBlack
		glyph.ZIndex = button.ZIndex + 1
		glyph.Parent = button
	end
	glyph.Position = UDim2.new(0.08, 0, 0.12, 0)
	glyph.Size = UDim2.new(0.84, 0, 0.48, 0)
	glyph.Text = deriveFloatGlyph(captionText)
	glyph.TextColor3 = accent:Lerp(Color3.fromRGB(255, 245, 228), 0.35)
	glyph.TextTransparency = 0.18
	glyph.TextScaled = false
	glyph.TextSize = 22
	glyph.TextXAlignment = Enum.TextXAlignment.Center
	glyph.TextYAlignment = Enum.TextYAlignment.Center

	local caption = button:FindFirstChild("FloatCaption")
	if not caption or not caption:IsA("TextLabel") then
		caption = Instance.new("TextLabel")
		caption.Name = "FloatCaption"
		caption.BackgroundTransparency = 1
		caption.Font = Enum.Font.GothamBold
		caption.ZIndex = button.ZIndex + 1
		caption.Parent = button
	end
	caption.Position = UDim2.new(0.1, 0, 0.58, 0)
	caption.Size = UDim2.new(0.8, 0, 0.26, 0)
	caption.Text = captionText
	caption.TextColor3 = UI_BRAND.text
	caption.TextTransparency = 0.04
	caption.TextScaled = false
	caption.TextSize = 10
	caption.TextWrapped = true
	caption.TextXAlignment = Enum.TextXAlignment.Center
	caption.TextYAlignment = Enum.TextYAlignment.Top

	local subcaption = button:FindFirstChild("FloatSubcaption")
	if not subcaption or not subcaption:IsA("TextLabel") then
		subcaption = Instance.new("TextLabel")
		subcaption.Name = "FloatSubcaption"
		subcaption.BackgroundTransparency = 1
		subcaption.Font = Enum.Font.GothamSemibold
		subcaption.ZIndex = button.ZIndex + 1
		subcaption.Parent = button
	end
	subcaption.Position = UDim2.new(0.12, 0, 0.83, 0)
	subcaption.Size = UDim2.new(0.76, 0, 0.12, 0)
	subcaption.Text = "OPEN"
	subcaption.TextColor3 = accent:Lerp(Color3.fromRGB(255, 248, 236), 0.25)
	subcaption.TextTransparency = 0.22
	subcaption.TextScaled = false
	subcaption.TextSize = 8
	subcaption.TextXAlignment = Enum.TextXAlignment.Center
	subcaption.TextYAlignment = Enum.TextYAlignment.Center

	bindButtonPolish(button)
	refreshButtonPolish(button, true)
end

local function styleLabel(label, text, size)
	label.Text = text
	label.TextColor3 = Color3.fromRGB(235, 240, 245)
	label.Font = Enum.Font.Gotham
	label.TextSize = size or 14
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
end

local function createDefaultMatchResult()
	return {
		ghostType = "Unknown",
		correctGuess = false,
		evidenceCollected = 0,
		playersSurvived = 0,
		playersDead = 0,
		matchDuration = 0,
		currencyReward = 0,
		ppReward = 0,
		xpReward = 0,
	}
end

local function formatMatchDuration(seconds)
	local totalSeconds = math.max(0, math.floor(tonumber(seconds) or 0))
	local minutes = math.floor(totalSeconds / 60)
	local remainingSeconds = totalSeconds % 60
	return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function formatCountdown(seconds)
	local numeric = math.max(0, math.ceil(tonumber(seconds) or 0))
	local minutes = math.floor(numeric / 60)
	local remainingSeconds = numeric % 60
	return string.format("%02d:%02d", minutes, remainingSeconds)
end

local function formatCurrencyAndPrestigeReward(currencyReward, ppReward)
	local mm = math.floor(tonumber(currencyReward or 0) or 0)
	local pp = math.floor(tonumber(ppReward or 0) or 0)
	if pp > 0 then
		return string.format("%d MM | %d PP", mm, pp)
	end
	return tostring(mm)
end

local function formatJoinedValues(values, fallback)
	if type(values) ~= "table" then
		return fallback or "-"
	end

	local parts = {}
	for _, value in ipairs(values) do
		if type(value) == "string" and value ~= "" then
			table.insert(parts, value)
		end
	end

	if #parts == 0 then
		return fallback or "-"
	end
	return table.concat(parts, ", ")
end

local function resolveMapMetadata(mapId)
	if type(mapId) ~= "string" or mapId == "" then
		return nil
	end
	return MAP_METADATA[mapId]
end

local function getMapDisplayName(mapId)
	local metadata = resolveMapMetadata(mapId)
	if type(metadata) == "table" and type(metadata.mapName) == "string" and metadata.mapName ~= "" then
		return metadata.mapName
	end
	if type(mapId) == "string" and mapId ~= "" then
		return mapId
	end
	return "Lokasi Tidak Diketahui"
end

local function formatMapSummary(mapId)
	local metadata = resolveMapMetadata(mapId)
	local displayName = getMapDisplayName(mapId)
	if type(metadata) ~= "table" then
		return displayName
	end

	local details = {}
	if type(metadata.mapSize) == "string" and metadata.mapSize ~= "" then
		table.insert(details, metadata.mapSize)
	end
	local dimensions = metadata.mapDimensions or {}
	local width = tonumber(dimensions.width)
	local depth = tonumber(dimensions.depth)
	if width and depth then
		table.insert(details, string.format("%dx%d", width, depth))
	end
	local floors = tonumber(dimensions.floors)
	if floors then
		table.insert(details, string.format("%d lantai", floors))
	end
	if type(metadata.mapCategory) == "string" and metadata.mapCategory ~= "" then
		table.insert(details, metadata.mapCategory)
	end

	if #details == 0 then
		return displayName
	end

	return string.format("%s\n%s", displayName, table.concat(details, " | "))
end

local function humanizeToken(token)
	local raw = tostring(token or "-")
	raw = raw:gsub("_", " ")
	raw = raw:gsub("(%l)(%u)", "%1 %2")
	raw = raw:gsub("%s+", " ")
	raw = raw:match("^%s*(.-)%s*$")
	if raw == nil or raw == "" then
		return "-"
	end
	return raw
end

local MAP_PREVIEW_THEMES = {
	default = {
		background = Color3.fromRGB(24, 30, 40),
		stroke = Color3.fromRGB(75, 92, 120),
		accent = Color3.fromRGB(86, 116, 152),
		accentSoft = Color3.fromRGB(38, 52, 74),
		text = Color3.fromRGB(236, 242, 250),
		muted = Color3.fromRGB(196, 210, 228),
	},
	DomesticDecay = {
		background = Color3.fromRGB(32, 26, 24),
		stroke = Color3.fromRGB(124, 92, 78),
		accent = Color3.fromRGB(160, 114, 78),
		accentSoft = Color3.fromRGB(70, 48, 36),
		text = Color3.fromRGB(244, 232, 218),
		muted = Color3.fromRGB(214, 192, 172),
	},
	ColdRoyal = {
		background = Color3.fromRGB(28, 30, 46),
		stroke = Color3.fromRGB(118, 112, 170),
		accent = Color3.fromRGB(164, 156, 220),
		accentSoft = Color3.fromRGB(62, 58, 96),
		text = Color3.fromRGB(239, 236, 252),
		muted = Color3.fromRGB(202, 198, 232),
	},
	CorporateDerelict = {
		background = Color3.fromRGB(22, 30, 36),
		stroke = Color3.fromRGB(88, 118, 128),
		accent = Color3.fromRGB(114, 168, 174),
		accentSoft = Color3.fromRGB(34, 56, 62),
		text = Color3.fromRGB(228, 240, 242),
		muted = Color3.fromRGB(182, 208, 210),
	},
	BroadcastNightmare = {
		background = Color3.fromRGB(32, 22, 30),
		stroke = Color3.fromRGB(142, 88, 108),
		accent = Color3.fromRGB(206, 118, 144),
		accentSoft = Color3.fromRGB(78, 34, 54),
		text = Color3.fromRGB(248, 228, 236),
		muted = Color3.fromRGB(228, 184, 198),
	},
	ranked = {
		background = Color3.fromRGB(38, 24, 42),
		stroke = Color3.fromRGB(172, 136, 88),
		accent = Color3.fromRGB(224, 184, 92),
		accentSoft = Color3.fromRGB(84, 58, 28),
		text = Color3.fromRGB(252, 240, 214),
		muted = Color3.fromRGB(232, 208, 154),
	},
}

local function resolveMapPreviewTheme(mapId, modeText)
	if tostring(modeText or "") == "Ranked" then
		return MAP_PREVIEW_THEMES.ranked
	end

	local metadata = resolveMapMetadata(mapId)
	local ambiance = type(metadata) == "table" and type(metadata.visualTheme) == "table" and metadata.visualTheme.ambiance or nil
	return MAP_PREVIEW_THEMES[ambiance] or MAP_PREVIEW_THEMES.default
end

local function buildMapPreviewGlyph(mapId, modeText)
	if tostring(modeText or "") == "Ranked" then
		return "RP"
	end

	local displayName = getMapDisplayName(mapId)
	local letters = {}
	for word in string.gmatch(displayName, "[%w]+") do
		local first = string.sub(word, 1, 1)
		if first ~= "" then
			table.insert(letters, string.upper(first))
		end
		if #letters >= 2 then
			break
		end
	end

	if #letters == 0 then
		local compact = string.upper(string.sub(displayName, 1, 2))
		return compact ~= "" and compact or "??"
	end
	if #letters == 1 then
		local compact = string.upper(string.sub(displayName, 1, 2))
		return compact ~= "" and compact or (letters[1] .. letters[1])
	end
	return table.concat(letters, "")
end

local function buildMapPreviewMood(mapId, modeText)
	if tostring(modeText or "") == "Ranked" then
		return "RANKED PRESSURE"
	end

	local metadata = resolveMapMetadata(mapId)
	if type(metadata) == "table" and type(metadata.visualTheme) == "table" then
		local ambiance = metadata.visualTheme.ambiance
		if type(ambiance) == "string" and ambiance ~= "" then
			return string.upper(humanizeToken(ambiance))
		end
	end

	if type(metadata) == "table" and type(metadata.mapCategory) == "string" and metadata.mapCategory ~= "" then
		return string.upper(metadata.mapCategory)
	end

	return "UNKNOWN ATMOSPHERE"
end

local function buildMapPreviewStats(mapId)
	local metadata = resolveMapMetadata(mapId)
	if type(metadata) ~= "table" then
		return "DETAIL MAP BELUM TERSEDIA"
	end

	local details = {}
	if type(metadata.mapSize) == "string" and metadata.mapSize ~= "" then
		table.insert(details, string.upper(humanizeToken(metadata.mapSize)))
	end

	local roomCount = type(metadata.rooms) == "table" and #metadata.rooms or 0
	if roomCount > 0 then
		table.insert(details, string.format("%d ROOM", roomCount))
	end

	local dimensions = metadata.mapDimensions or {}
	local floors = math.max(1, math.floor(tonumber(dimensions.floors) or 1))
	table.insert(details, string.format("%d FLOOR", floors))

	local width = math.floor(tonumber(dimensions.width) or 0)
	local depth = math.floor(tonumber(dimensions.depth) or 0)
	if width > 0 and depth > 0 then
		table.insert(details, string.format("%dx%d", width, depth))
	end

	return table.concat(details, "  •  ")
end

local SHOP_CATEGORY_THEMES = {
	Cosmetic = {
		background = Color3.fromRGB(44, 30, 46),
		preview = Color3.fromRGB(76, 48, 82),
		accent = Color3.fromRGB(208, 126, 182),
		text = Color3.fromRGB(248, 228, 242),
	},
	Equipment = {
		background = Color3.fromRGB(28, 36, 44),
		preview = Color3.fromRGB(44, 62, 78),
		accent = Color3.fromRGB(118, 178, 214),
		text = Color3.fromRGB(228, 240, 248),
	},
	default = {
		background = Color3.fromRGB(24, 30, 40),
		preview = Color3.fromRGB(38, 52, 74),
		accent = Color3.fromRGB(86, 116, 152),
		text = Color3.fromRGB(236, 242, 250),
	},
}

local SHOP_CURRENCY_THEMES = {
	MM = {
		background = Color3.fromRGB(42, 66, 98),
		text = Color3.fromRGB(236, 244, 252),
	},
	PP = {
		background = Color3.fromRGB(102, 76, 28),
		text = Color3.fromRGB(250, 238, 206),
	},
	Robux = {
		background = Color3.fromRGB(30, 88, 60),
		text = Color3.fromRGB(228, 248, 236),
	},
	default = {
		background = Color3.fromRGB(60, 88, 128),
		text = Color3.fromRGB(245, 245, 245),
	},
}

local SHOP_RARITY_COLORS = {
	R1 = Color3.fromRGB(126, 144, 170),
	R2 = Color3.fromRGB(90, 156, 120),
	R3 = Color3.fromRGB(82, 136, 196),
	R4 = Color3.fromRGB(160, 110, 196),
	R5 = Color3.fromRGB(216, 162, 84),
}

local function resolveShopCategoryTheme(item)
	local category = type(item) == "table" and tostring(item.category or "") or ""
	return SHOP_CATEGORY_THEMES[category] or SHOP_CATEGORY_THEMES.default
end

local function resolveShopCurrencyTheme(currency)
	local key = tostring(currency or "MM")
	return SHOP_CURRENCY_THEMES[key] or SHOP_CURRENCY_THEMES.default
end

local function isShopMarketplaceReady(item)
	if type(item) ~= "table" then
		return false
	end
	if tostring(item.currency or "MM") ~= "Robux" then
		return true
	end
	local marketplaceType = tostring(item.marketplaceType or "")
	if marketplaceType ~= "GamePass" and marketplaceType ~= "DeveloperProduct" then
		return false
	end
	local marketplaceId = tonumber(item.marketplaceId)
	return marketplaceId ~= nil and marketplaceId > 0
end

local function isShopItemPurchasable(item)
	if type(item) ~= "table" then
		return false, "invalid_item"
	end
	if item.enabled == false then
		return false, "item_disabled"
	end
	if not isShopMarketplaceReady(item) then
		return false, "marketplace_id_missing"
	end
	return true, nil
end

local function describeShopPurchaseBlock(item, reason)
	if reason == "already_owned" then
		return "Item ini sudah kamu miliki."
	end
	if reason == "insufficient_currency" then
		return "Saldo currency belum cukup untuk item ini."
	end
	if reason == "item_disabled" then
		local setupHint = type(item) == "table" and item.setupHint or nil
		if type(setupHint) == "string" and setupHint ~= "" then
			return setupHint
		end
		return "Item belum diaktifkan."
	end
	if reason == "marketplace_id_missing" then
		return "Item Robux belum aktif. Isi marketplaceId valid di ShopMarketplaceConfig lalu publish lewat Creator Hub."
	end
	return "Item belum bisa dibeli saat ini."
end

local function buildOwnedItemLookup(ownedItemIds)
	local lookup = {}
	if type(ownedItemIds) ~= "table" then
		return lookup
	end
	for _, itemId in ipairs(ownedItemIds) do
		if type(itemId) == "string" and itemId ~= "" then
			lookup[itemId] = true
		end
	end
	return lookup
end

local function countLookupEntries(source)
	if type(source) ~= "table" then
		return 0
	end
	local total = 0
	for _ in pairs(source) do
		total += 1
	end
	return total
end

local function findShopCatalogItem(catalog, itemId)
	if type(itemId) ~= "string" or itemId == "" then
		return nil
	end
	for _, item in ipairs(catalog or {}) do
		if type(item) == "table" and item.id == itemId then
			return item
		end
	end
	return nil
end

local function formatShopWalletSummary(wallet)
	if type(wallet) ~= "table" then
		return "MM 0  •  PP 0  •  R$ 0"
	end
	return string.format(
		"MM %d  •  PP %d  •  R$ %d",
		math.max(0, math.floor(tonumber(wallet.MM) or 0)),
		math.max(0, math.floor(tonumber(wallet.PP) or 0)),
		math.max(0, math.floor(tonumber(wallet.Robux) or 0))
	)
end

local SHOP_FILTERS = {
	{ key = "All", label = "ALL" },
	{ key = "MM", label = "MM" },
	{ key = "PP", label = "PP" },
	{ key = "Robux", label = "R$" },
	{ key = "Owned", label = "OWNED" },
}

local function parseCurrencyPillValue(rawText)
	local amount, currency = tostring(rawText or ""):match("^([%+%-]?%d+)%s+([%a$]+)$")
	if amount and (currency == "MM" or currency == "PP" or currency == "Robux" or currency == "R$") then
		return amount, currency
	end
	return nil, nil
end

local function applyPricePillVisual(pricePill, rawText, backgroundColor, textColor)
	if not pricePill then
		return
	end

	local pillText = tostring(rawText or "-")
	local amount, currency = parseCurrencyPillValue(pillText)
	pricePill.BackgroundColor3 = backgroundColor
	pricePill.TextColor3 = textColor

	local amountLabel = pricePill:FindFirstChild("CurrencyAmount")
	if not amountLabel or not amountLabel:IsA("TextLabel") then
		amountLabel = Instance.new("TextLabel")
		amountLabel.Name = "CurrencyAmount"
		amountLabel.BackgroundTransparency = 1
		amountLabel.Font = Enum.Font.GothamBold
		amountLabel.TextSize = 9
		amountLabel.TextXAlignment = Enum.TextXAlignment.Left
		amountLabel.TextYAlignment = Enum.TextYAlignment.Center
		amountLabel.ZIndex = pricePill.ZIndex + 1
		amountLabel.Parent = pricePill
	end

	local unitLabel = pricePill:FindFirstChild("CurrencyUnit")
	if not unitLabel or not unitLabel:IsA("TextLabel") then
		unitLabel = Instance.new("TextLabel")
		unitLabel.Name = "CurrencyUnit"
		unitLabel.BackgroundTransparency = 1
		unitLabel.Font = Enum.Font.GothamBlack
		unitLabel.TextSize = 8
		unitLabel.TextXAlignment = Enum.TextXAlignment.Right
		unitLabel.TextYAlignment = Enum.TextYAlignment.Center
		unitLabel.ZIndex = pricePill.ZIndex + 1
		unitLabel.Parent = pricePill
	end

	local glyphPlate = pricePill:FindFirstChild("CurrencyGlyphPlate")
	if not glyphPlate or not glyphPlate:IsA("Frame") then
		glyphPlate = Instance.new("Frame")
		glyphPlate.Name = "CurrencyGlyphPlate"
		glyphPlate.BorderSizePixel = 0
		glyphPlate.ZIndex = pricePill.ZIndex + 1
		glyphPlate.Parent = pricePill
	end

	local glyphCorner = glyphPlate:FindFirstChild("CurrencyGlyphPlateCorner")
	if not glyphCorner or not glyphCorner:IsA("UICorner") then
		glyphCorner = Instance.new("UICorner")
		glyphCorner.Name = "CurrencyGlyphPlateCorner"
		glyphCorner.Parent = glyphPlate
	end
	glyphCorner.CornerRadius = UDim.new(1, 0)

	local glyphLabel = glyphPlate:FindFirstChild("CurrencyGlyph")
	if not glyphLabel or not glyphLabel:IsA("TextLabel") then
		glyphLabel = Instance.new("TextLabel")
		glyphLabel.Name = "CurrencyGlyph"
		glyphLabel.BackgroundTransparency = 1
		glyphLabel.Font = Enum.Font.GothamBlack
		glyphLabel.TextSize = 8
		glyphLabel.TextXAlignment = Enum.TextXAlignment.Center
		glyphLabel.TextYAlignment = Enum.TextYAlignment.Center
		glyphLabel.ZIndex = glyphPlate.ZIndex + 1
		glyphLabel.Parent = glyphPlate
	end

	if amount and currency then
		local unitText = currency == "Robux" and "R$" or currency
		local glyphText = currency == "Robux" and "R" or string.sub(unitText, 1, 1)
		pricePill.Text = ""
		glyphPlate.Visible = true
		amountLabel.Visible = true
		unitLabel.Visible = true
		glyphPlate.Position = UDim2.fromOffset(4, 2)
		glyphPlate.Size = UDim2.fromOffset(24, math.max(12, pricePill.AbsoluteSize.Y - 4))
		glyphPlate.BackgroundColor3 = backgroundColor:Lerp(Color3.fromRGB(255, 248, 236), 0.22)
		glyphPlate.BackgroundTransparency = 0.14
		glyphLabel.Size = UDim2.fromScale(1, 1)
		glyphLabel.Text = glyphText
		glyphLabel.TextColor3 = textColor
		amountLabel.Position = UDim2.fromOffset(32, 0)
		amountLabel.Size = UDim2.new(1, -56, 1, 0)
		amountLabel.Text = amount
		amountLabel.TextColor3 = textColor
		unitLabel.Position = UDim2.new(1, -24, 0, 0)
		unitLabel.Size = UDim2.fromOffset(20, pricePill.AbsoluteSize.Y)
		unitLabel.Text = unitText
		unitLabel.TextColor3 = textColor:Lerp(Color3.fromRGB(255, 248, 236), 0.08)
	else
		pricePill.Text = pillText
		glyphPlate.Visible = false
		amountLabel.Visible = false
		unitLabel.Visible = false
	end
end

local function buildShopItemGlyph(item)
	if type(item) ~= "table" then
		return "IT"
	end

	local tags = {}
	if type(item.tags) == "table" then
		for _, tag in ipairs(item.tags) do
			tags[string.lower(tostring(tag))] = true
		end
	end

	if tags.uv then
		return "UV"
	elseif tags.spiritbox then
		return "SB"
	elseif tags.sanity then
		return "SP"
	elseif tags.bundle then
		return "BD"
	elseif tags.emote then
		return "EM"
	elseif tags.lantern then
		return "LN"
	elseif tags.mask then
		return "MK"
	elseif tags.veil then
		return "VL"
	elseif tags.charm then
		return "CH"
	end

	local source = tostring(item.name or item.id or "IT")
	local letters = {}
	for word in string.gmatch(source, "[%w]+") do
		table.insert(letters, string.upper(string.sub(word, 1, 1)))
		if #letters >= 2 then
			break
		end
	end
	if #letters == 0 then
		return "IT"
	end
	if #letters == 1 then
		local compact = string.upper(string.sub(source, 1, 2))
		return compact ~= "" and compact or "IT"
	end
	return table.concat(letters, "")
end

local function buildShopItemBadge(item)
	if type(item) ~= "table" then
		return "ITEM"
	end

	local slot = type(item.slot) == "string" and humanizeToken(item.slot) or nil
	if slot and slot ~= "" and slot ~= "-" then
		return string.upper(slot)
	end
	local category = type(item.category) == "string" and humanizeToken(item.category) or "Item"
	return string.upper(category)
end

local function buildShopItemMeta(item)
	if type(item) ~= "table" then
		return "-"
	end

	local parts = {}
	if type(item.category) == "string" and item.category ~= "" then
		table.insert(parts, string.upper(humanizeToken(item.category)))
	end
	if type(item.rarityLabel) == "string" and item.rarityLabel ~= "" then
		table.insert(parts, tostring(item.rarityLabel))
	elseif type(item.rarity) == "string" and item.rarity ~= "" then
		table.insert(parts, tostring(item.rarity))
	end
	if type(item.tags) == "table" and #item.tags > 0 then
		local tagParts = {}
		for index = 1, math.min(#item.tags, 2) do
			table.insert(tagParts, string.upper(humanizeToken(item.tags[index])))
		end
		table.insert(parts, table.concat(tagParts, ", "))
	end
	if tostring(item.currency or "MM") == "Robux" then
		local flow = type(item.marketplaceType) == "string" and string.upper(item.marketplaceType) or "MARKETPLACE"
		table.insert(parts, flow)
		if item.enabled == false or not isShopMarketplaceReady(item) then
			table.insert(parts, "SETUP")
		end
	end
	return table.concat(parts, "  •  ")
end

local function resolveMapDisplayName(payload)
	if type(payload) ~= "table" then
		return "Lokasi Tidak Diketahui"
	end
	return getMapDisplayName(payload.mapName or payload.mapId or payload.selectedMap or payload.map)
end

local function buildRoomBrowserRenderKey(state)
	if type(state) ~= "table" then
		return "invalid"
	end

	local roomTokens = {}
	for _, room in ipairs(state.rooms or {}) do
		table.insert(roomTokens, string.format(
			"%s:%s:%s:%s:%s:%s",
			tostring(room.roomId or "?"),
			tostring(room.mode or "?"),
			tostring(room.mapId or "?"),
			tostring(room.playerCount or "?"),
			room.inGame == true and "1" or "0",
			room.starting == true and "1" or "0"
		))
	end

	local currentRoom = state.currentRoom
	local currentRoomId = type(currentRoom) == "table" and currentRoom.roomId or currentRoom
	return table.concat({
		tostring(state.selectedMode or "Classic"),
		tostring(state.selectedMap or "-"),
		tostring(currentRoomId or "-"),
		tostring(state.isHost == true),
		tostring(state.isReady == true),
		tostring(state.allReady == true),
		tostring(state.matchStarting == true),
		tostring(state.countdownSecondsLeft or state.countdownTotal or "-"),
		table.concat(roomTokens, "|"),
	}, "::")
end

local function decoratePhasePayload(payload)
	if type(payload) ~= "table" then
		return nil
	end
	if payload._clientReceivedAt == nil then
		payload._clientReceivedAt = tick()
	end
	return payload
end

local function resolvePhaseFromPayload(eventName, payload)
	if eventName == "MatchPreparing" then
		return MATCH_PHASE.PREPARING
	end
	if eventName == "MatchStarted" then
		return MATCH_PHASE.LOADING
	end

	local phaseToken = tostring(
		(payload and payload.phase)
			or (payload and payload.phaseName)
			or (payload and payload.lifecyclePhase)
			or ""
	)
	local normalized = phaseToken:gsub("[%s_%-]+", ""):lower()

	if normalized == "lobby" then
		return MATCH_PHASE.LOBBY
	end
	if normalized == "preparing" or normalized == "preparationphase" then
		return MATCH_PHASE.PREPARING
	end
	if normalized == "loading" then
		return MATCH_PHASE.LOADING
	end
	if normalized == "briefing" then
		return MATCH_PHASE.BRIEFING
	end
	if normalized == "ingame" or normalized == "investigationphase" then
		return MATCH_PHASE.INGAME
	end
	if normalized == "escalation" then
		return MATCH_PHASE.ESCALATION
	end
	if normalized == "hunt" or normalized == "huntphase" then
		return MATCH_PHASE.HUNT
	end
	if normalized == "result" or normalized == "endgamephase" then
		return MATCH_PHASE.RESULT
	end
	if normalized == "end" then
		return MATCH_PHASE.END
	end

	return nil
end

local function createSummaryRow(parent, rowName, labelText)
	local row = Instance.new("Frame")
	row.Name = rowName
	row.Size = UDim2.new(1, 0, 0, 28)
	row.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
	row.BackgroundTransparency = 0.08
	row.BorderSizePixel = 0
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = row

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Position = UDim2.fromOffset(10, 0)
	label.Size = UDim2.new(0.52, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = labelText
	label.TextColor3 = Color3.fromRGB(176, 190, 212)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = row

	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.AnchorPoint = Vector2.new(1, 0)
	value.Position = UDim2.new(1, -10, 0, 0)
	value.Size = UDim2.new(0.45, 0, 1, 0)
	value.BackgroundTransparency = 1
	value.Text = "-"
	value.TextColor3 = Color3.fromRGB(240, 244, 248)
	value.Font = Enum.Font.GothamSemibold
	value.TextSize = 12
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.Parent = row

	return value
end

local function createActionRow(parent, rowName, defaultTitle, defaultMeta, buttonText)
	local row = Instance.new("Frame")
	row.Name = rowName
	row.Size = UDim2.new(1, 0, 0, 72)
	row.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
	row.BackgroundTransparency = 0.06
	row.BorderSizePixel = 0
	row.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = row

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.fromOffset(6, 72)
	accent.BackgroundColor3 = Color3.fromRGB(86, 116, 152)
	accent.BorderSizePixel = 0
	accent.Parent = row

	local preview = Instance.new("Frame")
	preview.Name = "Preview"
	preview.Position = UDim2.fromOffset(14, 8)
	preview.Size = UDim2.fromOffset(52, 56)
	preview.BackgroundColor3 = Color3.fromRGB(38, 52, 74)
	preview.BorderSizePixel = 0
	preview.Parent = row
	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0, 8)
	previewCorner.Parent = preview

	local previewBadge = Instance.new("TextLabel")
	previewBadge.Name = "PreviewBadge"
	previewBadge.BackgroundColor3 = Color3.fromRGB(58, 76, 102)
	previewBadge.BackgroundTransparency = 0.12
	previewBadge.Position = UDim2.fromOffset(4, 4)
	previewBadge.Size = UDim2.new(1, -8, 0, 14)
	previewBadge.Font = Enum.Font.GothamBold
	previewBadge.TextSize = 8
	previewBadge.TextColor3 = Color3.fromRGB(236, 242, 250)
	previewBadge.BorderSizePixel = 0
	previewBadge.Text = "ITEM"
	previewBadge.Parent = preview
	local previewBadgeCorner = Instance.new("UICorner")
	previewBadgeCorner.CornerRadius = UDim.new(1, 0)
	previewBadgeCorner.Parent = previewBadge

	local previewGlyph = Instance.new("TextLabel")
	previewGlyph.Name = "PreviewGlyph"
	previewGlyph.BackgroundTransparency = 1
	previewGlyph.Position = UDim2.fromOffset(6, 16)
	previewGlyph.Size = UDim2.new(1, -12, 0, 34)
	previewGlyph.Font = Enum.Font.GothamBold
	previewGlyph.TextSize = 24
	previewGlyph.TextColor3 = Color3.fromRGB(236, 242, 250)
	previewGlyph.TextXAlignment = Enum.TextXAlignment.Left
	previewGlyph.TextYAlignment = Enum.TextYAlignment.Center
	previewGlyph.Text = "IT"
	previewGlyph.Parent = preview

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Position = UDim2.fromOffset(78, 8)
	title.Size = UDim2.new(1, -176, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = defaultTitle or "ITEM"
	title.TextColor3 = Color3.fromRGB(240, 244, 248)
	title.Font = Enum.Font.GothamSemibold
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = row

	local meta = Instance.new("TextLabel")
	meta.Name = "Meta"
	meta.Position = UDim2.fromOffset(78, 28)
	meta.Size = UDim2.new(1, -176, 0, 18)
	meta.BackgroundTransparency = 1
	meta.Text = defaultMeta or "-"
	meta.TextColor3 = Color3.fromRGB(176, 190, 212)
	meta.Font = Enum.Font.Gotham
	meta.TextSize = 11
	meta.TextXAlignment = Enum.TextXAlignment.Left
	meta.TextWrapped = true
	meta.Parent = row

	local pricePill = Instance.new("TextLabel")
	pricePill.Name = "PricePill"
	pricePill.BackgroundColor3 = Color3.fromRGB(60, 88, 128)
	pricePill.BackgroundTransparency = 0.08
	pricePill.Position = UDim2.fromOffset(78, 50)
	pricePill.Size = UDim2.fromOffset(92, 16)
	pricePill.Font = Enum.Font.GothamBold
	pricePill.TextSize = 9
	pricePill.TextColor3 = Color3.fromRGB(245, 245, 245)
	pricePill.Text = "-"
	pricePill.BorderSizePixel = 0
	pricePill.Parent = row
	local pricePillCorner = Instance.new("UICorner")
	pricePillCorner.CornerRadius = UDim.new(1, 0)
	pricePillCorner.Parent = pricePill

	local button = Instance.new("TextButton")
	button.Name = "ActionButton"
	button.AnchorPoint = Vector2.new(1, 0.5)
	button.Position = UDim2.new(1, -10, 0.5, 0)
	button.Size = UDim2.fromOffset(86, 32)
	styleButton(button, buttonText or "AKSI")
	button.BackgroundColor3 = Color3.fromRGB(60, 88, 128)
	button.Parent = row

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	return {
		Root = row,
		Accent = accent,
		Preview = preview,
		PreviewBadge = previewBadge,
		PreviewGlyph = previewGlyph,
		Title = title,
		Meta = meta,
		PricePill = pricePill,
		Button = button,
	}
end

local function formatRuntimeAreaLabel(areaId)
	if type(areaId) ~= "string" or areaId == "" then
		return nil
	end

	local formatted = areaId
		:gsub("_", " ")
		:gsub("([%a])(%d)", "%1 %2")
		:gsub("(%d)([%a])", "%1 %2")
		:gsub("^%l", string.upper)
	return formatted
end

local function formatSafeZoneLabel(zoneId)
	return formatRuntimeAreaLabel(zoneId)
end

local function formatHideSpotLabel(zoneId)
	if type(zoneId) ~= "string" or zoneId == "" then
		return nil
	end
	return formatRuntimeAreaLabel(zoneId:gsub("^Room_", ""))
end

local function getActiveMatchMapModel()
	local player = Players.LocalPlayer
	if not player then
		return nil
	end

	local matchId = tostring(player:GetAttribute("MatchId") or "")
	if matchId == "" then
		return nil
	end

	local activeMatches = Workspace:FindFirstChild("ActiveMatches")
	if not activeMatches then
		return nil
	end

	local matchFolder = activeMatches:FindFirstChild("Match_" .. matchId)
	if not matchFolder then
		for _, child in ipairs(activeMatches:GetChildren()) do
			if child:IsA("Folder") and tostring(child:GetAttribute("MatchId") or "") == matchId then
				matchFolder = child
				break
			end
		end
	end
	if not matchFolder then
		return nil
	end

	for _, child in ipairs(matchFolder:GetChildren()) do
		if (child:IsA("Model") or child:IsA("Folder"))
			and not child.Name:match("^GhostPlaceholder_")
			and not child.Name:match("^Ghost_") then
			return child
		end
	end

	return nil
end

local function getRuntimeHideSpotLabel(zoneId)
	if type(zoneId) ~= "string" or zoneId == "" then
		return nil
	end

	local mapModel = getActiveMatchMapModel()
	local roomsFolder = mapModel and mapModel:FindFirstChild("Rooms", true)
	if not roomsFolder then
		return nil
	end

	for _, child in ipairs(roomsFolder:GetChildren()) do
		if child:IsA("BasePart") then
			local childHideSpotId = tostring(child:GetAttribute("HideSpotId") or "")
			if childHideSpotId == zoneId or child.Name == zoneId then
				local label = tostring(child:GetAttribute("HideSpotLabel") or "")
				if label ~= "" then
					return label
				end
			end
		end
	end

	return nil
end

local function resolveHideZoneLabel(zoneId, spotType)
	if type(zoneId) ~= "string" or zoneId == "" then
		return nil
	end
	if tostring(spotType or "") == "SafeZone" or zoneId:match("^SafeZone") then
		return formatSafeZoneLabel(zoneId) or zoneId
	end
	return getRuntimeHideSpotLabel(zoneId) or formatHideSpotLabel(zoneId) or formatRuntimeAreaLabel(zoneId) or zoneId
end

local function getNearestSafeZoneInfo()
	local player = Players.LocalPlayer
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local mapModel = getActiveMatchMapModel()
	local safeZonesFolder = mapModel and mapModel:FindFirstChild("SafeZones", true)
	if not safeZonesFolder then
		return nil
	end

	local nearest = nil
	for _, child in ipairs(safeZonesFolder:GetChildren()) do
		if child:IsA("BasePart") then
			local distance = (root.Position - child.Position).Magnitude
			if nearest == nil or distance < nearest.distance then
				nearest = {
					zoneId = child.Name,
					label = formatSafeZoneLabel(child.Name) or child.Name,
					distance = distance,
				}
			end
		end
	end

	return nearest
end

local function getNearestHideSpotInfo()
	local player = Players.LocalPlayer
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local mapModel = getActiveMatchMapModel()
	local roomsFolder = mapModel and mapModel:FindFirstChild("Rooms", true)
	if not roomsFolder then
		return nil
	end

	local nearest = nil
	for _, child in ipairs(roomsFolder:GetChildren()) do
		if child:IsA("BasePart") then
			local hideSpotId = tostring(child:GetAttribute("HideSpotId") or "")
			local hideSpotType = tostring(child:GetAttribute("HideSpotType") or "")
			if hideSpotId == "" or hideSpotType == "" then
				local prompt = child:FindFirstChild("HideSpotPrompt")
				if prompt and prompt:IsA("ProximityPrompt") then
					hideSpotId = child.Name
					hideSpotType = "Closet"
				end
			end
			local hideSpotOccupied = child:GetAttribute("HideSpotOccupied") == true
			if hideSpotId ~= "" and hideSpotType ~= "" and not hideSpotOccupied then
				local distance = (root.Position - child.Position).Magnitude
				if nearest == nil or distance < nearest.distance then
					nearest = {
						kind = "HideSpot",
						zoneId = hideSpotId,
						spotType = hideSpotType,
						label = resolveHideZoneLabel(hideSpotId, hideSpotType) or hideSpotId,
						distance = distance,
					}
				end
			end
		end
	end

	return nearest
end

local function getSafeZoneHintText(nearestSafeZone)
	local info = nearestSafeZone or getNearestSafeZoneInfo()
	if type(info) ~= "table" then
		return "SAFE ZONE BIRU"
	end

	local label = info.label or "SAFE ZONE"
	if type(info.distance) == "number" then
		return string.format("%s %dst", label, math.max(0, math.floor(info.distance + 0.5)))
	end
	return label
end

local function getHideSpotHintText(nearestHideSpot)
	local info = nearestHideSpot or getNearestHideSpotInfo()
	if type(info) ~= "table" then
		return "HIDE SPOT TERDEKAT"
	end

	local label = info.label or "HIDE SPOT"
	if type(info.distance) == "number" then
		return string.format("%s %dst", label, math.max(0, math.floor(info.distance + 0.5)))
	end
	return label
end

local function getPreferredHuntRefugeInfo()
	local nearestSafeZone = getNearestSafeZoneInfo()
	local nearestHideSpot = getNearestHideSpotInfo()
	if nearestHideSpot and (not nearestSafeZone or nearestHideSpot.distance <= (nearestSafeZone.distance + 4)) then
		return nearestHideSpot, nearestSafeZone
	end
	return nearestSafeZone, nearestHideSpot
end

local function getRefugeHintText(refugeInfo)
	if type(refugeInfo) ~= "table" then
		return "RUANG AMAN"
	end
	if refugeInfo.kind == "HideSpot" then
		return getHideSpotHintText(refugeInfo)
	end
	return getSafeZoneHintText(refugeInfo)
end

local function getRefugeActionText(refugeInfo)
	local hintText = getRefugeHintText(refugeInfo)
	if type(refugeInfo) == "table" and refugeInfo.kind == "HideSpot" then
		return "masuk " .. hintText
	end
	return "menuju " .. hintText
end

local function getHuntObjectiveText()
	local player = Players.LocalPlayer
	if not player then
		return "Hunt aktif. Putus line-of-sight, gunakan pintu seperlunya, dan cari ruang aman jika tersedia."
	end

	local hideState = tostring(player:GetAttribute("PasrahHideState") or "Exposed")
	local hideSpotType = tostring(player:GetAttribute("PasrahHideSpotType") or "None")
	local hideZoneId = tostring(player:GetAttribute("PasrahHideZoneId") or "")
	local threatState = tostring(player:GetAttribute("PasrahHuntThreatState") or "Clear")
	local threatDistance = tonumber(player:GetAttribute("PasrahHuntThreatDistance"))
	local nearestRefuge, alternateRefuge = getPreferredHuntRefugeInfo()
	local refugeHint = getRefugeHintText(nearestRefuge)
	local refugeAction = getRefugeActionText(nearestRefuge)
	local alternateHint = getRefugeHintText(alternateRefuge)

	if hideState == "Hidden" then
		if hideZoneId ~= "" then
			return string.format(
				"Berlindung di %s. Diam dan tunggu hunt selesai sebelum keluar.",
				resolveHideZoneLabel(hideZoneId, hideSpotType) or hideZoneId
			)
		end
		return "Kamu sedang bersembunyi. Tunggu hunt selesai sebelum keluar."
	end

	if threatState == "Sheltered" then
		return string.format("Kamu sudah dekat %s. Jaga posisi dan jangan keluar saat hunt masih aktif.", refugeHint)
	end

	if threatState == "Critical" or threatState == "Close" then
		if threatDistance then
			if type(nearestRefuge) == "table" and nearestRefuge.kind == "HideSpot" and type(alternateRefuge) == "table" then
				return string.format(
					"Ghost dekat (%dst). Putus line-of-sight, rotasi lewat pintu, lalu %s. Jika tertutup, menuju %s.",
					threatDistance,
					refugeAction,
					alternateHint
				)
			end
			return string.format("Ghost dekat (%dst). Putus line-of-sight, rotasi lewat pintu, lalu %s.", threatDistance, refugeAction)
		end
		if type(nearestRefuge) == "table" and nearestRefuge.kind == "HideSpot" and type(alternateRefuge) == "table" then
			return string.format(
				"Ghost dekat. Putus line-of-sight, rotasi lewat pintu, lalu %s. Jika tertutup, menuju %s.",
				refugeAction,
				alternateHint
			)
		end
		return string.format("Ghost dekat. Putus line-of-sight, rotasi lewat pintu, lalu %s.", refugeAction)
	end

	if threatState == "Tracked" or threatState == "Warn" then
		if threatDistance then
			if type(nearestRefuge) == "table" and nearestRefuge.kind == "HideSpot" and type(alternateRefuge) == "table" then
				return string.format(
					"Ghost melacak (%dst). Putar jalur, jaga jarak, lalu %s. Jika gagal, menuju %s.",
					threatDistance,
					refugeAction,
					alternateHint
				)
			end
			return string.format("Ghost melacak (%dst). Putar jalur, jaga jarak, lalu %s.", threatDistance, refugeAction)
		end
		if type(nearestRefuge) == "table" and nearestRefuge.kind == "HideSpot" and type(alternateRefuge) == "table" then
			return string.format(
				"Ghost melacak. Putar jalur, jaga jarak, lalu %s. Jika gagal, menuju %s.",
				refugeAction,
				alternateHint
			)
		end
		return string.format("Ghost melacak. Putar jalur, jaga jarak, lalu %s.", refugeAction)
	end

	return string.format("Hunt aktif. Gunakan prompt pintu, putus line-of-sight, lalu %s.", refugeAction)
end

local function getHuntStatusSnapshot()
	local player = Players.LocalPlayer
	if not player then
		return {
			hideState = "Exposed",
			hideZoneId = "",
			threatState = "Clear",
			threatDistance = nil,
		}
	end

	return {
		hideState = tostring(player:GetAttribute("PasrahHideState") or "Exposed"),
		hideSpotType = tostring(player:GetAttribute("PasrahHideSpotType") or "None"),
		hideZoneId = tostring(player:GetAttribute("PasrahHideZoneId") or ""),
		threatState = tostring(player:GetAttribute("PasrahHuntThreatState") or "Clear"),
		threatDistance = tonumber(player:GetAttribute("PasrahHuntThreatDistance")),
	}
end

local function getHuntStatusBadge(snapshot)
	snapshot = snapshot or getHuntStatusSnapshot()
	if snapshot.hideState == "Hidden" then
		return "HIDDEN"
	end
	if snapshot.threatState == "Sheltered" then
		return "SHELTERED"
	end
	if snapshot.threatState == "Critical" or snapshot.threatState == "Close" then
		return "CRITICAL"
	end
	if snapshot.threatState == "Tracked" or snapshot.threatState == "Warn" then
		return "TRACKED"
	end
	return "HUNT"
end

local function getHuntControlsHintText()
	local snapshot = getHuntStatusSnapshot()
	local nearestRefuge, alternateRefuge = getPreferredHuntRefugeInfo()
	local refugeHint = getRefugeHintText(nearestRefuge)
	local alternateHint = getRefugeHintText(alternateRefuge)
	if snapshot.hideState == "Hidden" then
		local hiddenLabel = resolveHideZoneLabel(snapshot.hideZoneId, snapshot.hideSpotType) or refugeHint
		return string.upper(hiddenLabel) .. "  •  DIAM  •  TUNGGU HUNT SELESAI"
	end
	if snapshot.threatState == "Sheltered" then
		return string.format("%s  •  JAGA POSISI  •  TUNGGU HUNT", refugeHint)
	end
	if snapshot.threatState == "Critical" or snapshot.threatState == "Close" then
		if type(nearestRefuge) == "table" and nearestRefuge.kind == "HideSpot" and type(alternateRefuge) == "table" then
			return string.format("PUTUS LOS  •  PINTU: E/X/TAP  •  %s  •  ALT %s", refugeHint, alternateHint)
		end
		return string.format("PUTUS LINE-OF-SIGHT  •  PINTU: E/X/TAP  •  %s", refugeHint)
	end
	if snapshot.threatState == "Tracked" or snapshot.threatState == "Warn" then
		if type(nearestRefuge) == "table" and nearestRefuge.kind == "HideSpot" and type(alternateRefuge) == "table" then
			return string.format("PUTAR JALUR  •  %s  •  ALT %s", refugeHint, alternateHint)
		end
		return string.format("PUTAR JALUR  •  JAGA JARAK  •  %s", refugeHint)
	end
	return string.format("PINTU: E/X/TAP  •  TARGET: %s  •  JANGAN LARI LURUS", refugeHint)
end

local function bulletList(list, emptyText)
	if type(list) ~= "table" or #list == 0 then
		return emptyText or "- Tidak ada"
	end

	local lines = {}
	for _, item in ipairs(list) do
		table.insert(lines, "- " .. tostring(item))
	end
	return table.concat(lines, "\n")
end

local function titleCaseToken(token)
	local raw = tostring(token or "-"):gsub("_", " ")
	if raw == "" then
		return "-"
	end
	return string.upper(string.sub(raw, 1, 1)) .. string.sub(raw, 2)
end

local function buildToolContextSummary(data)
	if type(data) ~= "table" then
		return nil
	end

	local fragments = {}
	if type(data.roomId) == "string" and data.roomId ~= "" then
		table.insert(fragments, "Room " .. tostring(data.roomId))
	end

	local chargesRemaining = tonumber(data.chargesRemaining)
	if chargesRemaining ~= nil then
		table.insert(fragments, string.format("Charge %d", math.max(0, math.floor(chargesRemaining))))
	end

	local usesRemaining = tonumber(data.usesRemaining)
	if usesRemaining ~= nil then
		table.insert(fragments, string.format("Sisa pakai %d", math.max(0, math.floor(usesRemaining))))
	end

	if data.tracksDetected == true then
		table.insert(fragments, "Jejak terdeteksi")
	end
	if data.huntRepelled == true then
		table.insert(fragments, "Ghost terpukul mundur")
	end
	if data.repellentUntil ~= nil then
		table.insert(fragments, "Repellent aktif")
	end
	if type(data.responseText) == "string" and data.responseText ~= "" then
		table.insert(fragments, data.responseText)
	end
	if type(data.responseTier) == "string" and data.responseTier ~= "" then
		table.insert(fragments, string.format("Tier %s", string.upper(data.responseTier)))
	end

	if #fragments == 0 then
		return nil
	end
	return table.concat(fragments, " | ")
end

local function resolveToolFeedback(toolType, success, reason, data, eventName)
	local toolConfig = FIELD_KIT_TOOL_CONFIG[toolType]
	local toolLabel = toolConfig and toolConfig.label or titleCaseToken(toolType or "tool")
	local status = nil
	local detail = nil

	if eventName == "SaltPlaced" then
		status = "Garam aktif."
		detail = "Menunggu ghost menginjak area ini."
	elseif eventName == "SaltTriggered" then
		status = "Jejak garam terpicu."
		detail = "Ghost melintas di area garam."
	elseif eventName == "CrucifixPlaced" then
		status = "Salib disiagakan."
		detail = "Siap memblok hunt dekat titik ini."
	elseif eventName == "CrucifixTriggered" then
		local chargesRemaining = tonumber(data and data.chargesRemaining)
		status = "Salib bereaksi."
		detail = chargesRemaining and chargesRemaining > 0
			and string.format("Hunt diblokir. Sisa charge %d.", math.floor(chargesRemaining))
			or "Hunt diblokir. Charge habis."
	elseif eventName == "SmudgeActivated" then
		status = "Dupa menyala."
		detail = data and data.huntRepelled == true
			and "Ghost mundur. Manfaatkan jeda untuk reposisi."
			or "Area sementara lebih aman untuk rotasi."
	elseif eventName == "GhostRepelled" then
		status = "Ghost terpukul mundur."
		detail = "Jarak aman sementara tercipta."
	elseif eventName == "HuntBlocked" then
		status = "Hunt diblokir."
		detail = reason == "crucifix_prevented_hunt"
			and "Salib menahan trigger hunt."
			or "Repellent dupa masih aktif."
	elseif reason == "salt_placed" then
		status = "Garam terpasang."
		detail = "Titik investigasi siap dipantau."
	elseif reason == "salt_triggered" then
		status = "Jejak terdeteksi."
		detail = "Garam langsung bereaksi dekat ghost."
	elseif reason == "crucifix_armed" then
		status = "Salib siap."
		detail = "Perlindungan hunt dipasang."
	elseif reason == "smudge_activated" then
		status = "Dupa aktif."
		detail = data and data.huntRepelled == true
			and "Ghost terdorong dan sanity dipulihkan."
			or "Repellent menyala di area target."
	elseif reason == "sanity_restored" then
		status = "Sanity pulih."
		detail = data and data.resultingSanity ~= nil
			and string.format("Sanity sekarang %d.", math.floor(tonumber(data.resultingSanity) or 0))
			or "Pil dipakai untuk stabilisasi."
	elseif reason == "tool_local_cooldown" or reason == "tool_cooldown" then
		status = toolLabel .. " cooldown."
		detail = "Tunggu sebentar sebelum memakai tool lagi."
	elseif reason == "tool_out_of_stock" then
		status = toolLabel .. " habis."
		detail = "Stok tool habis untuk match ini."
	elseif reason == "ghost_out_of_range" then
		status = toolLabel .. " ditolak."
		detail = "Ghost terlalu jauh dari target."
	elseif reason == "spectator_blocked" then
		status = toolLabel .. " ditolak."
		detail = "Spectator tidak boleh memakai tool."
	elseif reason == "missing_match_id" then
		status = toolLabel .. " ditolak."
		detail = "Match aktif tidak terdeteksi."
	elseif success == false then
		status = toolLabel .. " ditolak."
		detail = titleCaseToken(reason or "unknown")
	else
		status = toolLabel .. " digunakan."
		detail = titleCaseToken(reason or "request_sent")
	end

	local contextSummary = buildToolContextSummary(data)
	if contextSummary and contextSummary ~= detail then
		detail = string.format("%s | %s", tostring(detail or "-"), contextSummary)
	end

	return status, detail
end

local function loadShopCatalog()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	if not shared then
		return {}
	end
	local dataTypes = shared:FindFirstChild("DataTypes")
	if not dataTypes then
		return {}
	end
	local moduleScript = dataTypes:FindFirstChild("ShopCatalog")
	if not moduleScript then
		return {}
	end
	local ok, result = pcall(require, moduleScript)
	if ok and type(result) == "table" then
		local filtered = {}
		for _, item in ipairs(result) do
			local currency = type(item) == "table" and tostring(item.currency or "MM") or "MM"
			local shouldHide = false
			if currency == "Robux" and RunService:IsStudio() ~= true then
				local enabled = type(item) == "table" and item.enabled ~= false
				local marketplaceReady = isShopMarketplaceReady(item)
				shouldHide = enabled ~= true or marketplaceReady ~= true
			end
			if shouldHide ~= true then
				table.insert(filtered, item)
			end
		end
		return filtered
	end
	return {}
end

local function findPlayerByUserId(userId)
	local target = tonumber(userId)
	if not target then
		return nil
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.UserId == target then
			return plr
		end
	end
	return nil
end

local function stripScripts(root)
	for _, child in ipairs(root:GetDescendants()) do
		if child:IsA("BaseScript") then
			child:Destroy()
		end
	end
end

local function buildPreviewCharacterModel(userId)
	local livePlayer = findPlayerByUserId(userId)
	if livePlayer and livePlayer.Character then
		local okClone, clone = pcall(function()
			return livePlayer.Character:Clone()
		end)
		if okClone and clone then
			stripScripts(clone)
			for _, d in ipairs(clone:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
				end
			end
			return clone
		end
	end

	local numeric = tonumber(userId)
	if numeric then
		local okModel, model = pcall(function()
			return Players:CreateHumanoidModelFromUserId(numeric)
		end)
		if okModel and model then
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
				end
			end
			return model
		end
	end

	return nil
end

local function renderCharacterPreview(viewportFrame, userId)
	for _, child in ipairs(viewportFrame:GetChildren()) do
		child:Destroy()
	end

	local cam = Instance.new("Camera")
	cam.Name = "PreviewCamera"
	cam.Parent = viewportFrame
	viewportFrame.CurrentCamera = cam

	local model = buildPreviewCharacterModel(userId)
	if not model then
		local fallback = Instance.new("Part")
		fallback.Anchored = true
		fallback.CanCollide = false
		fallback.Size = Vector3.new(1.8, 2.8, 1)
		fallback.Color = Color3.fromRGB(95, 95, 95)
		fallback.Parent = viewportFrame
		cam.CFrame = CFrame.new(Vector3.new(0, 1.3, 4), Vector3.new(0, 1.3, 0))
		return
	end

	model.Parent = viewportFrame
	local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
	if not root then
		return
	end
	model.PrimaryPart = root
	model:PivotTo(CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(180), 0))
	local extents = model:GetExtentsSize()
	local focusY = math.max(extents.Y * 0.45, 1.4)
	local distance = math.max(extents.X, extents.Y, extents.Z) * 1.8
	cam.CFrame = CFrame.new(Vector3.new(0, focusY, distance), Vector3.new(0, focusY, 0))
end

local function connectButtonPress(button, callback)
	if not button or type(callback) ~= "function" then
		return
	end
	bindButtonPolish(button)
	local lastPressAt = 0
	local function invoke()
		local now = os.clock()
		if (now - lastPressAt) < 0.2 then
			return
		end
		lastPressAt = now
		button:SetAttribute("BrandPressed", true)
		refreshButtonPolish(button, false)
		playUIButtonClick()
		task.delay(0.08, function()
			if button and button.Parent then
				button:SetAttribute("BrandPressed", false)
				refreshButtonPolish(button, false)
			end
		end)
		callback()
	end
	button.Activated:Connect(invoke)
end

local function makeFloatingButtonDraggable(button)
	if not button or button:GetAttribute("DragBound") == true then
		return
	end
	button:SetAttribute("DragBound", true)

	local dragging = false
	local dragStart = nil
	local startPos = nil

	local function updateDrag(input)
		if not dragging or not dragStart or not startPos then
			return
		end
		local delta = input.Position - dragStart
		button.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end

	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		dragStart = input.Position
		startPos = button.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end)

	button.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			updateDrag(input)
		end
	end)
end

local function disconnectAll(connections)
	for _, connection in ipairs(connections) do
		if connection then
			connection:Disconnect()
		end
	end
	table.clear(connections)
end

local function destroyAll(instances)
	for _, instance in ipairs(instances) do
		if instance and instance.Parent then
			instance:Destroy()
		end
	end
	table.clear(instances)
end

local function fadeGuiObject(guiObject, transparency, duration)
	if not guiObject then
		return
	end
	local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	if guiObject:IsA("Frame") or guiObject:IsA("TextButton") or guiObject:IsA("TextBox") then
		TweenService:Create(guiObject, tweenInfo, { BackgroundTransparency = transparency }):Play()
	elseif guiObject:IsA("TextLabel") then
		TweenService:Create(guiObject, tweenInfo, { TextTransparency = transparency }):Play()
	elseif guiObject:IsA("ImageLabel") or guiObject:IsA("ImageButton") then
		TweenService:Create(guiObject, tweenInfo, { ImageTransparency = transparency }):Play()
	end
end

local function resolveSafeInsets()
	local ok, insetA, insetB = pcall(function()
		return GuiService:GetSafeZoneInsets()
	end)
	if ok then
		if typeof(insetA) == "Vector2" and typeof(insetB) == "Vector2" then
			return insetA, insetB
		end
		if typeof(insetA) == "Rect" then
			return Vector2.new(insetA.Min.X, insetA.Min.Y), Vector2.new(insetA.Max.X, insetA.Max.Y)
		end
	end
	return Vector2.new(0, 0), Vector2.new(0, 0)
end

local function createDeviceProfile()
	local function resolveInputOverride()
		local raw = ReplicatedStorage:GetAttribute(UI_INPUT_PROFILE_OVERRIDE_ATTR)
		if type(raw) ~= "string" then
			return nil
		end
		local token = string.lower(raw)
		if token == "mobile" or token == "console" or token == "pc" then
			return token
		end
		return nil
	end

	local profile = {
		isMobile = false,
		isPC = true,
		isConsole = false,
		_inputType = "PC",
		overrideInput = nil,
	}

	function profile:Refresh(lastInputType)
		local overrideInput = resolveInputOverride()
		self.overrideInput = overrideInput
		if overrideInput == "mobile" then
			self.isMobile = true
			self.isConsole = false
			self.isPC = false
			self._inputType = "Mobile"
			return
		end
		if overrideInput == "console" then
			self.isMobile = false
			self.isConsole = true
			self.isPC = false
			self._inputType = "Console"
			return
		end
		if overrideInput == "pc" then
			self.isMobile = false
			self.isConsole = false
			self.isPC = true
			self._inputType = "PC"
			return
		end

		local inputName = lastInputType and tostring(lastInputType) or ""
		local usingTouch = inputName == tostring(Enum.UserInputType.Touch)
		local usingGamepad = string.find(inputName, "Gamepad", 1, true) ~= nil
		local usingKeyboardMouse = inputName == tostring(Enum.UserInputType.MouseButton1)
			or inputName == tostring(Enum.UserInputType.MouseMovement)
			or inputName == tostring(Enum.UserInputType.Keyboard)

		self.isMobile = UserInputService.TouchEnabled and (usingTouch or (not usingGamepad and not usingKeyboardMouse))
		self.isConsole = UserInputService.GamepadEnabled and (usingGamepad or (not UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled))
		self.isPC = UserInputService.KeyboardEnabled and not self.isMobile and not self.isConsole

		if self.isMobile then
			self._inputType = "Mobile"
		elseif self.isConsole then
			self._inputType = "Console"
		else
			self._inputType = "PC"
		end
	end

	function profile:GetTextSize()
		if self._inputType == "Mobile" then
			return 22
		end
		if self._inputType == "Console" then
			return 24
		end
		return 18
	end

	function profile:GetButtonSize()
		if self._inputType == "Mobile" then
			return Vector2.new(220, 80)
		end
		if self._inputType == "Console" then
			return Vector2.new(260, 72)
		end
		return Vector2.new(180, 42)
	end

	function profile:GetInputType()
		return self._inputType
	end

	profile:Refresh(UserInputService:GetLastInputType())
	return profile
end

function UISystem:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._connections = {}
	self._uxConnections = {}
	self._uxInstances = {}
	self._uiState = {}
	self._roomBrowser = RoomBrowserController.new(self._remotes and self._remotes.LobbyEvent or nil)
	self._roomBrowserController = self._roomBrowser
	self._lobbyConnection = nil
	self._roomBrowserGui = nil
	self._roomBrowserFloatGui = nil
	self._roomBrowserWidgets = nil
	self._roomBrowserLoopRunning = false
	self._roomBrowserRenderKey = nil
	self._roomBrowserVisible = false
	self._roomBrowserSuppressed = false
	self._roomBrowserInputBound = false
	self._auxiliaryInputBound = false
	self._windowCloseInputBound = false
	self._lobbyPanelCollapsed = false
	self._roomBrowserMissingWidgetsLogged = false
	self._roomBrowserModeView = "Selected"
	self._passwordJoinPendingRoomId = nil
	self._passwordJoinSubmitting = false
	self._kickNoticeVisible = false
	self._inviteDropdownOpen = false
	self._roomModeDropdownOpen = false
	self._roomMapDropdownOpen = false
	self._activeInviteId = nil
	self._uxReady = false
	self._deviceProfile = createDeviceProfile()
	self._uiStateManager = { state = "Lobby" }
	self._matchPhase = MATCH_PHASE.LOBBY
	self._phaseStartTime = 0
	self._phaseDuration = nil
	self._phasePayload = nil
	self._pendingInGamePayload = nil
	self._phaseTimerRunning = false
	self._loadingTransitionRunning = false
	self._loadingStartTime = 0
	self._hasPostTeleportLoaded = false
	self._postTeleportFlowRunning = false
	self._awaitingPostTeleportFlow = false
	self._postTeleportFlowToken = 0
	self._teleportOverlayToken = 0
	self._teleportOverlayTween = nil
	self._lastCountdownAudioSecond = nil
	self._matchWindowDismissed = false
	self._matchControlsHintText = "[1] Scan   [2] Garam   [3] Salib   [4] Dupa   [5] Spirit   [J] Journal   [F] Flashlight   [K] Match   [Esc] Tutup UI"
	self._uxWidgets = {
		match = {},
		lobby = {},
		basicWindows = {},
		windows = {},
	}
	self._windowDismissed = {
		JournalUI = true,
		ProfileUI = true,
		ShopUI = true,
		RoyalPassUI = true,
		PASRA_UI = false,
		SpectatorUI = false,
	}
	self._journalState = {
		lastEvent = "Idle",
		matchId = nil,
		discoveredEvidence = {},
		confirmedEvidence = {},
		candidates = {},
		toolType = JOURNAL_TOOL_TYPE,
		toolStates = createDefaultFieldKitToolStates(),
		toolStatus = "Tool belum dipakai.",
		toolReason = "Buka panel Evidence lalu tekan SCAN untuk uji E2E.",
		toolSuccess = nil,
		toolLastUsedAt = 0,
	}
	self._profileState = {
		lastEvent = "Idle",
		sanity = 100,
		status = "safe",
		level = 1,
		rank = "Bayi III",
		victories = 0,
		totalGames = 0,
		favoriteTool = "-",
		featuredFlex = nil,
		ownedCosmeticIds = {},
		equippedCosmetics = {},
		lastCosmeticMessage = "Wardrobe belum sinkron.",
		lastCosmeticSnapshotAt = 0,
		lastCosmeticRequestAt = 0,
	}
	self._shopState = {
		lastEvent = "Idle",
		catalog = loadShopCatalog(),
		lastPurchase = nil,
		lastMessage = "Pilih item untuk dibeli.",
		pendingMarketplacePrompt = nil,
		wallet = {
			MM = 0,
			PP = 0,
			Robux = 0,
		},
		ownedItemIds = {},
		lastSnapshotAt = 0,
		lastSnapshotRequestedAt = 0,
		filterKey = "All",
	}
	self._royalPassState = {
		lastEvent = "Idle",
		lastSource = nil,
		lastAmount = 0,
		seasonId = "S1",
		totalXP = 0,
		currentTier = 1,
		maxTier = 50,
		xpPerTier = 200,
		currentTierXP = 0,
		remainingXP = 200,
		progressPercent = 0,
		premiumOwned = false,
		unlockedTiers = {},
		unlockedTierCount = 0,
		nextTier = 2,
		nextReward = nil,
		viewMode = "Rewards",
	}
	self._royalPassTrackFocusKey = nil
	self._spectatorState = {
		lastEvent = "Idle",
		title = "Belum spectate.",
		subtitle = "Panel ini akan aktif saat local player mati atau mode spectator berjalan.",
		mode = "none",
	}
	self._pasraState = {
		lastEvent = "Idle",
		status = "Belum ada hasil match.",
		subtitle = "Panel ini akan terisi saat match selesai.",
	}
	self._shopRequestSeq = 0

	for _, moduleName in ipairs(UI_MODULES) do
		self._uiState[moduleName] = { lastEvent = nil, visible = false }
	end
	self._uiState.LobbyUI.visible = true
	self._uiState.RoyalPassUI.visible = true

	self._matchResult = createDefaultMatchResult()
end

function UISystem:Start()
	for _, remoteName in ipairs(REMOTE_NAMES) do
		if remoteName == "LobbyEvent" then
			continue
		end
		local remote = self._remotes[remoteName]
		if remote and remote.OnClientEvent then
			table.insert(self._connections, remote.OnClientEvent:Connect(function(payload)
				self:_onServerEvent(remoteName, payload)
			end))
		end
	end
	self:_connectLobbyEventRouting()
	table.insert(self._connections, MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if player ~= Players.LocalPlayer then
			return
		end
		self:_onMarketplacePromptFinished("GamePass", gamePassId, wasPurchased)
	end))
	table.insert(self._connections, MarketplaceService.PromptProductPurchaseFinished:Connect(function(_userId, productId, isPurchased)
		self:_onMarketplacePromptFinished("DeveloperProduct", productId, isPurchased)
	end))

	if self._roomBrowser then
		self._roomBrowser:Start()
	end

	self:_requestShopSnapshot(true)
	self:_requestCosmeticSnapshot(true)
	self:_ensureBasicUIs()
	self:_ensureRoomBrowserGui()
	self:_bindRoomBrowserMatchVisibility()
	self:_refreshRoomBrowserView()
	self:_startRoomBrowserLoop()
	self:_bindRoomBrowserToggleInput()
	self:_bindAuxiliaryToggleInput()
	self:_bindMatchPanelToggleInput()
	self:_bindMatchToolInput()
	self:_bindWindowCloseInput()
	self:_bindPostTeleportLoading()
	self:_startPhaseTimer()
	self:_setPhase(MATCH_PHASE.LOBBY)

	local player = Players.LocalPlayer
	if player and player:GetAttribute("LobbyPanelCollapsed") ~= nil then
		self._lobbyPanelCollapsed = player:GetAttribute("LobbyPanelCollapsed") == true
	end
	self:_syncLobbyPanelVisibility()

	task.defer(function()
		local playerGui = self:_getPlayerGui()
		if not playerGui then
			return
		end

		local lobbyReady = playerGui:WaitForChild("LobbyUI", 10)
		if not lobbyReady then
			return
		end

		if self:_ensureUXLayers() then
			self:_bindInputProfileUpdates()
			self._uxReady = true
		end
	end)
end

function UISystem:_connectLobbyEventRouting()
	if not self._roomBrowserController then
		return
	end
	if self._lobbyConnection then
		return
	end

	local remoteFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
	local lobbyEvent = remoteFolder:WaitForChild("LobbyEvent")
	self._lobbyConnection = lobbyEvent.OnClientEvent:Connect(function(payload)
		if not payload then
			return
		end

		self._roomBrowserController:HandleLobbyEvent(payload)
		self:_onServerEvent("LobbyEvent", payload)
	end)
end

function UISystem:_onServerEvent(remoteName, payload)
	local eventName = payload and payload.eventName or "UnknownEvent"

	if remoteName == "EvidenceEvent" then
		self._uiState.JournalUI.lastEvent = eventName
		local shouldAutoOpenJournal = payload == nil or payload.autoOpenJournal ~= false
		if shouldAutoOpenJournal then
			self._uiState.JournalUI.visible = true
			self._windowDismissed.JournalUI = false
			self:_closeConflictingWindows("JournalUI")
		end
		self._journalState.lastEvent = eventName
		self._journalState.matchId = payload and payload.matchId or self._journalState.matchId
		if eventName == "UIEvidenceUpdated" then
			self._journalState.discoveredEvidence = payload and payload.discoveredEvidence or self._journalState.discoveredEvidence
			self._journalState.confirmedEvidence = payload and payload.confirmedEvidence or self._journalState.confirmedEvidence
		elseif eventName == "JournalUpdated" then
			local journalData = payload and payload.journalData or {}
			self._journalState.discoveredEvidence = journalData.discoveredEvidence or self._journalState.discoveredEvidence
			self._journalState.confirmedEvidence = journalData.confirmedEvidence or self._journalState.confirmedEvidence
			self._journalState.candidates = journalData.ghostCandidates or self._journalState.candidates
		elseif eventName == "UIGhostPredictionUpdated" then
			self._journalState.candidates = payload and (payload.candidates or payload.possibleGhosts) or self._journalState.candidates
		elseif eventName == "EvidenceCollected" then
			local collectedToolType = payload and payload.toolType
			local collectedEvidenceType = payload and payload.evidenceType
			if type(payload and payload.discoveredEvidence) == "table" then
				self._journalState.discoveredEvidence = payload.discoveredEvidence
			end
			if type(payload and payload.confirmedEvidence) == "table" then
				self._journalState.confirmedEvidence = payload.confirmedEvidence
			end
			if type(payload and (payload.possibleGhosts or payload.candidates)) == "table" then
				self._journalState.candidates = payload.possibleGhosts or payload.candidates
			end
			if type(collectedToolType) == "string" and collectedToolType ~= "" then
				self._journalState.toolType = collectedToolType
				self._journalState.toolStatus = "Evidence berhasil dibaca."
				if type(collectedEvidenceType) == "string" and collectedEvidenceType ~= "" then
					self._journalState.toolReason = string.format("Collected %s", tostring(collectedEvidenceType))
				else
					self._journalState.toolReason = "Collected evidence."
				end
				self._journalState.toolSuccess = true
				self._journalState.toolLastUsedAt = os.clock()
			end
		elseif payload and type(payload.toolType) == "string" and FIELD_KIT_TOOL_CONFIG[payload.toolType] then
			local toolData = payload.result or payload.data or payload
			local statusText, detailText = resolveToolFeedback(
				payload.toolType,
				payload.success ~= false,
				payload.reason,
				toolData,
				eventName
			)
			self:_applyFieldKitToolUpdate(payload.toolType, payload.success ~= false, payload.reason, toolData, eventName)
			self._journalState.toolType = payload.toolType
			self._journalState.toolStatus = statusText
			self._journalState.toolReason = detailText
			self._journalState.toolSuccess = payload.success ~= false
			self._journalState.toolLastUsedAt = os.clock()
		end
	elseif remoteName == "LobbyEvent" then
		if eventName == "RoomBrowserRoomLeft" or eventName == "LobbyEntered" then
			if self._matchPhase ~= MATCH_PHASE.LOBBY then
				self:_forceCloseAllPanelsForTeleport()
				self:_showTeleportOverlay(TELEPORT_OVERLAY_HOLD_SECONDS)
			end
			self:_setPhase(MATCH_PHASE.LOBBY)
			self._matchResult = createDefaultMatchResult()
			self._uiState.MatchUI.visible = false
			self._uiState.JournalUI.visible = false
			self._uiState.RoyalPassUI.visible = true
			self._uiState.PASRA_UI.visible = false
			self._uiState.SpectatorUI.visible = false
			self:_resetFieldKitToolStates()
			self:_setMatchWindowDismissed(false)
			self:_refreshBasicMatchPanel("Lobby")
		end
		self._uiState.LobbyUI.lastEvent = eventName
		self._uiState.LobbyUI.visible = true
		if eventName == "RoomBrowserRoomJoined" then
			self._passwordJoinPendingRoomId = nil
			self._passwordJoinSubmitting = false
			if self._roomBrowserWidgets and self._roomBrowserWidgets.PasswordModal then
				self._roomBrowserWidgets.PasswordModal.Visible = false
			end
		elseif eventName == "RoomBrowserRoomJoinFailed" then
			self._passwordJoinSubmitting = false
			if self._roomBrowserWidgets and self._roomBrowserWidgets.PasswordModal and self._passwordJoinPendingRoomId ~= nil then
				self._roomBrowserWidgets.PasswordModal.Visible = true
			end
			if payload and payload.reason == "room_full" and self._roomBrowserWidgets and self._roomBrowserWidgets.KickNoticeModal then
				self._kickNoticeVisible = true
				self._roomBrowserWidgets.KickNoticeText.Text = "ROOM PENUH"
				self._roomBrowserWidgets.KickNoticeModal.Visible = true
			elseif payload and payload.reason == "room_in_game" and self._roomBrowserWidgets and self._roomBrowserWidgets.KickNoticeModal then
				self._kickNoticeVisible = true
				self._roomBrowserWidgets.KickNoticeText.Text = "PERMAINAN SEDANG BERLANGSUNG"
				self._roomBrowserWidgets.KickNoticeModal.Visible = true
			end
		elseif eventName == "RoomBrowserRoomLeft" and payload and payload.reason == "kicked" then
			self._kickNoticeVisible = true
			if self._roomBrowserWidgets and self._roomBrowserWidgets.KickNoticeModal then
				self._roomBrowserWidgets.KickNoticeText.Text = "ANDA TELAH DI KICK"
				self._roomBrowserWidgets.KickNoticeModal.Visible = true
			end
		elseif eventName == "RoomInviteReceived" then
			self:_showRoomInvitePopup(payload)
		elseif eventName == "LobbyFlexSpotlightUpdated" then
			local spotlight = payload and payload.spotlight or {}
			self._uiState.ProfileUI.lastEvent = eventName
			self._profileState.lastEvent = eventName
			self._profileState.featuredFlex = {
				displayName = spotlight.displayName or spotlight.playerName or "Player",
				rank = spotlight.rankTier or "Bayi III",
				level = tonumber(spotlight.playerLevel) or 1,
				winRate = tonumber(spotlight.winRate) or 0,
				totalMatches = tonumber(spotlight.totalMatches) or 0,
				totalWins = tonumber(spotlight.totalWins) or 0,
				showcaseSummary = spotlight.showcaseSummary or "-",
				featuredNames = spotlight.featuredNames or {},
				gallery = spotlight.flexGallery or {},
				activeVisitorCount = tonumber(payload and payload.activeVisitorCount) or 0,
			}
		elseif eventName == "LobbyFlexSpotlightCleared" then
			self._uiState.ProfileUI.lastEvent = eventName
			self._profileState.lastEvent = eventName
			self._profileState.featuredFlex = nil
		end
		self:_handleLobbyUXEvent(eventName, payload or {})
		local okRefresh, refreshErr = pcall(function()
			self:_refreshRoomBrowserView()
		end)
		if not okRefresh then
			local now = os.clock()
			if not self._lastRoomBrowserRefreshErrorAt or (now - self._lastRoomBrowserRefreshErrorAt) > 1 then
				self._lastRoomBrowserRefreshErrorAt = now
				warn("[UISystem] RoomBrowser refresh failed:", tostring(refreshErr))
			end
		end
	elseif remoteName == "MatchEvent" then
		self:_routeMatchPhaseEvent(eventName, payload or {})
		self._uiState.MatchUI.lastEvent = eventName
		local keepResultsVisible = (self._resultsCloseUnlockAt or 0) > tick() and self:_isMatchResultsPhase()
		self._uiState.MatchUI.visible = keepResultsVisible or (eventName ~= "ReturnedToLobby" and eventName ~= "RoomBrowserRoomLeft")
		self:_handleMatchUXEvent(eventName, payload or {})
		if eventName == "PlayerKilled" and payload and payload.localPlayerKilled == true then
			self._uiState.SpectatorUI.lastEvent = eventName
			self._uiState.SpectatorUI.visible = true
			self._spectatorState.lastEvent = eventName
			self._spectatorState.mode = "dead"
			self._spectatorState.title = "PLAYER DEAD - SPECTATOR"
			self._spectatorState.subtitle = "Kematian menipumu, yang kamu lihat belum tentu benar."
			self._windowDismissed.SpectatorUI = false
			self:_closeConflictingWindows("SpectatorUI")
		elseif eventName == "PlayerKilled" then
			self._spectatorState.lastEvent = eventName
			self._spectatorState.mode = "warning"
			self._spectatorState.title = "TEAMMATE DOWN"
			self._spectatorState.subtitle = "Jangan terlalu percaya orang mati. Gunakan instingmu."
			self._uiState.SpectatorUI.visible = true
			self._windowDismissed.SpectatorUI = false
			self:_closeConflictingWindows("SpectatorUI")
			task.delay(5, function()
				if self._spectatorState.mode == "warning" then
					self._uiState.SpectatorUI.visible = false
					self:_applyVisibility()
				end
			end)
		elseif eventName == "MatchEnded" or eventName == "MatchCompleted" then
			if payload and type(payload) == "table" then
				self._matchResult = {
					ghostType = payload.ghostType or "Unknown",
					correctGuess = payload.correctGuess == true,
					evidenceCollected = payload.evidenceCollected or 0,
					playersSurvived = payload.playersSurvived or 0,
					playersDead = payload.playersDead or 0,
					matchDuration = payload.matchDuration or 0,
					currencyReward = payload.currencyReward or 0,
					ppReward = payload.ppReward or payload.ppAmount or 0,
					xpReward = payload.xpReward or 0,
				}
			end
			self._profileState.totalGames = (tonumber(self._profileState.totalGames) or 0) + 1
			self._roomBrowserSuppressed = false
			self:_setRoomBrowserVisible(false)
			self._uiState.PASRA_UI.lastEvent = eventName
			self._uiState.PASRA_UI.visible = true
			self._uiState.SpectatorUI.visible = false
			self._uiState.MatchUI.visible = true
			self._pasraState.lastEvent = eventName
			self._pasraState.status = payload and payload.missionFailed == true and "Misi berakhir dengan gagal." or "Misi selesai. Hasil dan reward siap dibaca."
			self._pasraState.subtitle = "Panel PASRA tetap tersedia, tetapi hasil utama sekarang diprioritaskan di MATCH agar tidak overlap."
			self._windowDismissed.PASRA_UI = true
			self:_setMatchWindowDismissed(false)
			self:_refreshBasicMatchPanel("Results", payload)
			self:_renderResultsPanel(payload)
		elseif eventName == "MatchRewardSummary" then
			if payload and type(payload) == "table" then
				self._matchResult.currencyReward = payload.currencyReward or self._matchResult.currencyReward
				self._matchResult.ppReward = payload.ppReward or payload.ppAmount or self._matchResult.ppReward
				self._matchResult.xpReward = payload.xpReward or self._matchResult.xpReward
			end
			self._uiState.PASRA_UI.lastEvent = eventName
			self._uiState.PASRA_UI.visible = true
			self._uiState.SpectatorUI.visible = false
			self._uiState.MatchUI.visible = true
			self._pasraState.lastEvent = eventName
			self._pasraState.status = "Reward summary diterima dari server."
			self._pasraState.subtitle = string.format(
				"MM/PP %s | XP %s",
				formatCurrencyAndPrestigeReward(self._matchResult.currencyReward, self._matchResult.ppReward),
				tostring(math.floor(tonumber(self._matchResult.xpReward or 0) or 0))
			)
			self._windowDismissed.PASRA_UI = true
			self:_setMatchWindowDismissed(false)
			self:_refreshBasicMatchPanel("Results", payload)
			self:_renderResultsPanel(payload)
		elseif eventName == "MatchStarted" then
			self._matchResult = createDefaultMatchResult()
			self._roomBrowserSuppressed = true
			if self._roomBrowser and type(self._roomBrowser.ResetForMatchStart) == "function" then
				self._roomBrowser:ResetForMatchStart()
			end
			self:_forceCloseAllPanelsForTeleport()
			self._uiState.PASRA_UI.visible = false
			self._uiState.MatchUI.visible = true
			self._uiState.SpectatorUI.visible = false
			self._uiState.JournalUI.visible = true
			self._uiState.ProfileUI.visible = false
			self._uiState.ShopUI.visible = false
			self._windowDismissed.JournalUI = true
			self._windowDismissed.ProfileUI = true
			self._windowDismissed.ShopUI = true
			self._journalState.lastEvent = eventName
			self._journalState.discoveredEvidence = {}
			self._journalState.confirmedEvidence = {}
			self._journalState.candidates = {}
			self:_resetFieldKitToolStates()
			self._pasraState.lastEvent = eventName
			self._pasraState.status = "Match aktif."
			self._pasraState.subtitle = "Menunggu hasil akhir dan reward."
			self:_setMatchWindowDismissed(false)
			self:_refreshBasicMatchPanel("Preparation", payload)
		elseif eventName == "ReturnedToLobby" or eventName == "RoomBrowserRoomLeft" then
			local keepResultsVisible = (self._resultsCloseUnlockAt or 0) > tick() and self:_isMatchResultsPhase()
			self._uiState.MatchUI.visible = keepResultsVisible
			self._uiState.JournalUI.visible = false
			self._uiState.PASRA_UI.visible = false
			self._uiState.SpectatorUI.visible = false
			self._spectatorState.mode = "none"
			self:_resetFieldKitToolStates()
			self:_setMatchWindowDismissed(false)
			self:_refreshBasicMatchPanel(keepResultsVisible and "Results" or "Lobby", payload)
		end
	elseif remoteName == "PurchaseEvent" then
		self._uiState.ShopUI.lastEvent = eventName
		self._shopState.lastEvent = eventName
		if eventName ~= "ShopSnapshot" then
			self._uiState.ShopUI.visible = true
			self:_closeConflictingWindows("ShopUI")
		end
		if type(payload) == "table" and type(payload.snapshot) == "table" then
			self:_applyShopSnapshot(payload.snapshot)
		end
		if eventName == "ShopSnapshot" then
			self._shopState.lastMessage = "Snapshot shop diperbarui."
		elseif eventName == "PurchasePromptRequested" then
			self:_requestMarketplacePrompt(payload or {})
		elseif eventName == "PurchaseProcessed" then
			self._shopState.pendingMarketplacePrompt = nil
			self._shopState.lastPurchase = {
				itemId = payload and payload.itemId or "-",
				success = payload and payload.success == true,
				reason = payload and payload.reason or nil,
				requestId = payload and payload.requestId or nil,
			}
			self._shopState.lastMessage = payload and payload.success == true
				and "Pembelian berhasil diproses."
				or ("Pembelian gagal: " .. titleCaseToken(payload and payload.reason or "unknown"))
			local purchasedItem = findShopCatalogItem(self._shopState.catalog, payload and payload.itemId or nil)
			if payload and payload.success == true and type(purchasedItem) == "table" and purchasedItem.category == "Cosmetic" then
				self:_requestCosmeticSnapshot(true)
			end
		end
		if eventName ~= "ShopSnapshot" then
			self._windowDismissed.ShopUI = false
		end
		self:_refreshShopPanel()
	elseif remoteName == "CosmeticEvent" then
		self._uiState.ProfileUI.lastEvent = eventName
		self._profileState.lastEvent = eventName
		if type(payload) == "table" and type(payload.snapshot) == "table" then
			self:_applyCosmeticSnapshot(payload.snapshot)
		end
		if eventName == "CosmeticSnapshot" then
			self._profileState.lastCosmeticMessage = string.format(
				"Wardrobe sync %d owned • %d equipped.",
				countLookupEntries(self._profileState.ownedCosmeticIds),
				countLookupEntries(self._profileState.equippedCosmetics)
			)
		elseif eventName == "CosmeticRequestProcessed" then
			local success = payload and payload.success == true
			local action = tostring(payload and payload.action or "Cosmetic")
			if success then
				self._profileState.lastCosmeticMessage = action == "Unequip" or action == "UnequipCosmetic"
					and "Cosmetic dilepas dari slot."
					or "Cosmetic dipakai ke slot aktif."
			else
				self._profileState.lastCosmeticMessage = "Wardrobe gagal: " .. titleCaseToken(payload and payload.reason or "unknown")
			end
		end
		self:_refreshProfilePanel()
	elseif remoteName == "RoyalPassEvent" then
		self._uiState.RoyalPassUI.lastEvent = eventName
		self._uiState.RoyalPassUI.visible = true
		self._royalPassState.lastEvent = eventName
		self._royalPassState.lastSource = payload and payload.source or self._royalPassState.lastSource
		if payload and payload.amount ~= nil then
			self._royalPassState.lastAmount = math.max(0, math.floor(tonumber(payload.amount) or 0))
		end
		self:_applyRoyalPassSnapshot(payload and payload.snapshot or nil)
		if eventName == "RoyalPassTierUnlocked" or eventName == "RoyalPassPremiumUpdated" then
			if self._matchPhase == MATCH_PHASE.LOBBY then
				self._windowDismissed.RoyalPassUI = false
				self:_closeConflictingWindows("RoyalPassUI")
			else
				self._windowDismissed.RoyalPassUI = true
			end
		end
	elseif remoteName == "SanityEvent" then
		self._uiState.ProfileUI.lastEvent = eventName
		self._profileState.lastEvent = eventName
		self._profileState.sanity = tonumber((payload and payload.newSanity) or (payload and payload.sanity) or payload) or self._profileState.sanity
		if self._profileState.sanity <= 10 then
			self._profileState.status = "hunt_risk"
		elseif self._profileState.sanity <= 30 then
			self._profileState.status = "high_paranormal_activity"
		elseif self._profileState.sanity <= 50 then
			self._profileState.status = "unstable"
		else
			self._profileState.status = "safe"
		end
	end

	self:_applyVisibility()
end

function UISystem:_getPlayerGui()
	local player = Players.LocalPlayer
	if not player then
		return nil
	end
	return player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 5)
end

function UISystem:_applyVisibility()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return
	end
	for _, guiName in ipairs(BASIC_GUI_NAMES) do
		local gui = playerGui:FindFirstChild(guiName)
		local state = self._uiState[guiName]
		if gui and state then
			local shouldEnable = state.visible == true
			if LOBBY_ONLY_GUI_NAMES[guiName] == true then
				shouldEnable = shouldEnable and self._matchPhase == MATCH_PHASE.LOBBY
			end
			gui.Enabled = shouldEnable
		end
	end
	self:_syncMatchWindowVisibility()
	self:_syncAuxiliaryWindowVisibility()
	self:_syncLobbyAuxiliaryWindowVisibility()
	self:_syncLobbyPanelVisibility()
	self:_refreshAuxiliaryPanels()
	self:_refreshBasicLobbyPanel()
	self:_refreshBasicWindows()
	self:_layoutLobbyFloatRail()
end

function UISystem:SetState(state)
	self._uiStateManager.state = state
end

function UISystem:GetState()
	return self._uiStateManager.state
end

function UISystem:GetTextSize()
	return self._deviceProfile:GetTextSize()
end

function UISystem:GetButtonSize()
	return self._deviceProfile:GetButtonSize()
end

function UISystem:GetInputType()
	return self._deviceProfile:GetInputType()
end

function UISystem:_getBasicWindowState(guiName)
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return nil, nil, nil
	end

	local gui = playerGui:FindFirstChild(guiName)
	if not gui or not gui:IsA("ScreenGui") then
		return nil, nil, nil
	end

	local panel = gui:FindFirstChild("MainPanel")
	local floatButtonName = nil
	if guiName == "LeaderboardUI" then
		floatButtonName = "LeaderboardFloatButton"
	elseif guiName == "MainMenuUI" then
		floatButtonName = "MainMenuFloatButton"
	end

	local floatButton = floatButtonName and gui:FindFirstChild(floatButtonName) or nil
	return gui, panel, floatButton
end

function UISystem:_setBasicWindowPanelVisible(guiName, visible)
	local gui, panel, floatButton = self:_getBasicWindowState(guiName)
	if not gui then
		return false
	end

	local shouldShow = visible == true
	if panel and panel:IsA("GuiObject") then
		setAnimatedPanelVisible(panel, shouldShow, false)
	end
	if floatButton and floatButton:IsA("GuiObject") then
		floatButton.Visible = self._matchPhase == MATCH_PHASE.LOBBY and not shouldShow and not self:_isLobbyFloatRailBlocked()
	end
	return true
end

function UISystem:_isLobbyFloatRailBlocked()
	if self._matchPhase ~= MATCH_PHASE.LOBBY then
		return true
	end
	if self._roomBrowserVisible == true then
		return true
	end
	local lobby = self._uxWidgets and self._uxWidgets.lobby or nil
	local lobbyPanelVisible = lobby and lobby.BasicPanel and lobby.BasicPanel.Visible == true
	if self._lobbyPanelCollapsed ~= true or lobbyPanelVisible then
		return true
	end

	for _, guiName in ipairs(CONFLICT_BASIC_GUI_NAMES) do
		local _, panel = self:_getBasicWindowState(guiName)
		if panel and panel.Visible == true then
			return true
		end
	end

	for _, guiName in ipairs(AUXILIARY_UI_NAMES) do
		local widgets = self._uxWidgets
			and self._uxWidgets.windows
			and self._uxWidgets.windows[guiName]
		if widgets and widgets.Panel and widgets.Panel.Visible == true then
			return true
		end
	end

	return false
end

function UISystem:_closeConflictingWindows(activeWindowName)
	local activeName = tostring(activeWindowName or "")

	if activeName ~= "LobbyUI" and self._lobbyPanelCollapsed ~= true then
		self:_setLobbyPanelCollapsed(true)
	end

	if activeName ~= "RoomBrowser" then
		self._roomBrowserVisible = false
	end

	if activeName ~= "MatchUI" then
		self._matchWindowDismissed = true
	end

	for _, guiName in ipairs(AUXILIARY_UI_NAMES) do
		if guiName ~= activeName then
			self._windowDismissed[guiName] = true
		end
	end

	for _, guiName in ipairs(CONFLICT_BASIC_GUI_NAMES) do
		if guiName ~= activeName then
			self:_setBasicWindowPanelVisible(guiName, false)
		end
	end

	self:_updateRoomBrowserVisibility()
	self:_syncAuxiliaryWindowVisibility()
	self:_syncMatchWindowVisibility()
	self:_refreshBasicLobbyPanel()
	self:_refreshBasicWindows()
	self:_layoutLobbyFloatRail()
end

function UISystem:_closeTopmostWindow()
	if self._roomBrowserVisible == true then
		self:_setRoomBrowserVisible(false)
		return true
	end

	if self._uiState.MatchUI and self._uiState.MatchUI.visible == true and self._matchWindowDismissed ~= true then
		self:_setMatchWindowDismissed(true)
		return true
	end

	if self._matchPhase == MATCH_PHASE.LOBBY and self._lobbyPanelCollapsed ~= true then
		self:_setLobbyPanelCollapsed(true)
		return true
	end

	for _, guiName in ipairs(CONFLICT_BASIC_GUI_NAMES) do
		local _, panel = self:_getBasicWindowState(guiName)
		if panel and panel.Visible == true then
			self:_setBasicWindowVisible(guiName, false)
			return true
		end
	end

	for _, guiName in ipairs(AUXILIARY_UI_NAMES) do
		local widgets = self._uxWidgets and self._uxWidgets.windows and self._uxWidgets.windows[guiName]
		if widgets and widgets.Panel and widgets.Panel.Visible == true then
			self:_setAuxiliaryWindowDismissed(guiName, true)
			self:_applyVisibility()
			return true
		end
	end

	return false
end

function UISystem:_isMatchPanelOpen()
	local match = self._uxWidgets and self._uxWidgets.match or nil
	if match and match.BasicPanel and match.BasicPanel.Visible == true then
		return true
	end

	return self._uiState.MatchUI and self._uiState.MatchUI.visible == true and self._matchWindowDismissed ~= true
end

function UISystem:_syncRoomBrowserSuppressionFromMatchContext()
	local localPlayer = Players.LocalPlayer
	local inMatch = localPlayer and localPlayer:GetAttribute("InMatch") == true or false
	local suppressForPhase = self._matchPhase ~= nil and self._matchPhase ~= MATCH_PHASE.LOBBY

	self._roomBrowserSuppressed = inMatch or suppressForPhase
	if self._roomBrowserSuppressed then
		self._roomBrowserVisible = false
		if self._roomBrowserWidgets and self._roomBrowserWidgets.CountdownOverlay then
			self._roomBrowserWidgets.CountdownOverlay.Visible = false
		end
	end

	self:_updateRoomBrowserVisibility()
end

function UISystem:_forceCloseAllPanelsForTeleport()
	self._roomBrowserVisible = false
	self._roomBrowserSuppressed = true
	self._countdownDisplaySecond = nil
	self._lastCountdownAudioSecond = nil
	stopRuntimeUISound("CountdownTick")

	if self._roomBrowserGui then
		for _, childName in ipairs({ "RoomPanel", "ModeDropdown", "MapDropdown", "InviteDropdown", "PasswordModal", "KickNoticeModal", "CountdownOverlay" }) do
			local child = self._roomBrowserGui:FindFirstChild(childName, true)
			if child and child:IsA("GuiObject") then
				child.Visible = false
			end
		end
	end

	for _, guiName in ipairs(AUXILIARY_UI_NAMES) do
		if self._uiState[guiName] then
			self._uiState[guiName].visible = false
		end
		self._windowDismissed[guiName] = true
	end

	self._matchWindowDismissed = true

	for _, guiName in ipairs(CONFLICT_BASIC_GUI_NAMES) do
		self:_setBasicWindowPanelVisible(guiName, false)
	end

	self:_updateRoomBrowserVisibility()
	self:_syncMatchWindowVisibility()
	self:_syncAuxiliaryWindowVisibility()
	self:_refreshBasicLobbyPanel()
	self:_refreshBasicWindows()
end

function UISystem:_setBasicWindowVisible(guiName, visible)
	local shouldShow = visible == true
	if shouldShow then
		self:_closeConflictingWindows(guiName)
	end

	if not self:_setBasicWindowPanelVisible(guiName, shouldShow) then
		return
	end
	self:_refreshBasicLobbyPanel()
	self:_refreshBasicWindows()
	self:_syncAuxiliaryWindowVisibility()
	self:_syncMatchWindowVisibility()
	self:_updateRoomBrowserVisibility()
end

function UISystem:_toggleBasicWindow(guiName)
	local _, panel = self:_getBasicWindowState(guiName)
	if not panel or not panel:IsA("GuiObject") then
		return
	end
	self:_setBasicWindowVisible(guiName, not panel.Visible)
end

function UISystem:_syncAuxiliaryWindowVisibility()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return
	end
	local blockLobbyFloatRail = self:_isLobbyFloatRailBlocked()

	for _, guiName in ipairs(AUXILIARY_UI_NAMES) do
		local widgets = self._uxWidgets
			and self._uxWidgets.windows
			and self._uxWidgets.windows[guiName]
		local gui = playerGui:FindFirstChild(guiName)
		if widgets and gui and gui:IsA("ScreenGui") then
			local screenEnabled = gui.Enabled == true
			local dismissed = self._windowDismissed[guiName] == true
			local panelVisible = widgets.Panel and widgets.Panel.Visible == true
			if widgets.Panel then
				setAnimatedPanelVisible(widgets.Panel, screenEnabled and not dismissed, false)
			end
			if widgets.FloatButton then
				widgets.FloatButton.Visible = screenEnabled and (dismissed or not panelVisible) and not blockLobbyFloatRail
			end
		end
	end
end

function UISystem:_setAuxiliaryWindowDismissed(guiName, dismissed)
	self._windowDismissed[guiName] = dismissed == true
	self:_syncAuxiliaryWindowVisibility()
	self:_syncLobbyAuxiliaryWindowVisibility()
	self:_updateRoomBrowserVisibility()
	self:_refreshBasicLobbyPanel()
	self:_refreshBasicWindows()
	if dismissed == true then
		local widgets = self._uxWidgets
			and self._uxWidgets.windows
			and self._uxWidgets.windows[guiName]
		if widgets and widgets.FloatButton then
			widgets.FloatButton.Visible = not self:_isLobbyFloatRailBlocked()
		end
		self:_layoutLobbyFloatRail()
	end
end

function UISystem:_openAuxiliaryWindow(guiName)
	if not self._uiState[guiName] then
		return
	end
	if LOBBY_ONLY_GUI_NAMES[guiName] == true and guiName ~= "ShopUI" and self._matchPhase ~= MATCH_PHASE.LOBBY then
		return
	end
	self:_closeConflictingWindows(guiName)
	self._uiState[guiName].visible = true
	self:_setAuxiliaryWindowDismissed(guiName, false)
	if guiName == "ShopUI" then
		self:_requestShopSnapshot()
	elseif guiName == "ProfileUI" then
		self:_requestCosmeticSnapshot()
	end
	self:_applyVisibility()
end

function UISystem:_toggleAuxiliaryWindow(guiName)
	if not self._uiState[guiName] then
		return
	end
	if self._uiState[guiName].visible ~= true or self._windowDismissed[guiName] == true then
		self:_openAuxiliaryWindow(guiName)
		return
	end
	self:_setAuxiliaryWindowDismissed(guiName, not (self._windowDismissed[guiName] == true))
	self:_applyVisibility()
end

function UISystem:_syncLobbyAuxiliaryWindowVisibility()
	local lobbyVisible = self._matchPhase == MATCH_PHASE.LOBBY
		and self._uiState.LobbyUI
		and self._uiState.LobbyUI.visible == true
	local blockLobbyFloatRail = self:_isLobbyFloatRailBlocked()

	for _, guiName in ipairs({ "MainMenuUI", "LeaderboardUI" }) do
		local gui, panel, floatButton = self:_getBasicWindowState(guiName)
		if gui then
			gui.Enabled = lobbyVisible
			if not lobbyVisible then
				if panel and panel:IsA("GuiObject") then
					panel.Visible = false
				end
				if floatButton and floatButton:IsA("GuiObject") then
					floatButton.Visible = false
				end
			elseif floatButton and floatButton:IsA("GuiObject") then
				floatButton.Visible = (not blockLobbyFloatRail) and not (panel and panel.Visible == true)
			end
		end
	end
end

function UISystem:_syncLobbyPanelVisibility()
	local lobby = self._uxWidgets and self._uxWidgets.lobby or nil
	if not lobby then
		return
	end

	local collapsed = self._lobbyPanelCollapsed == true
	if lobby.BasicPanel then
		lobby.BasicPanel.Visible = not collapsed
	end
	if lobby.ToggleButton then
		lobby.ToggleButton.Text = collapsed and ">" or "<"
	end
end

function UISystem:_layoutLobbyFloatRail()
	local profile = self._deviceProfile or {}
	if self:_isLobbyFloatRailBlocked() then
		return
	end

	local rightRailButtons = {}
	local function pushButton(button)
		if button and button.Parent and button.Visible == true then
			table.insert(rightRailButtons, button)
		end
	end

	local basicWindows = self._uxWidgets and self._uxWidgets.basicWindows or nil
	local auxiliaryWindows = self._uxWidgets and self._uxWidgets.windows or nil
	local menuButton = basicWindows and basicWindows.MainMenuUI and basicWindows.MainMenuUI.FloatButton or nil
	local passButton = auxiliaryWindows and auxiliaryWindows.RoyalPassUI and auxiliaryWindows.RoyalPassUI.FloatButton or nil
	local roomsButton = self._roomBrowserWidgets and self._roomBrowserWidgets.FloatButton or nil
	local rankButton = basicWindows and basicWindows.LeaderboardUI and basicWindows.LeaderboardUI.FloatButton or nil
	local profileButton = auxiliaryWindows and auxiliaryWindows.ProfileUI and auxiliaryWindows.ProfileUI.FloatButton or nil
	local shopButton = auxiliaryWindows and auxiliaryWindows.ShopUI and auxiliaryWindows.ShopUI.FloatButton or nil

	if profile.isMobile then
		-- Keep the rail concise on phones/tablets: primary navigation only.
		pushButton(roomsButton)
		pushButton(passButton)
		pushButton(menuButton)
		pushButton(rankButton)
	else
		-- Desktop order is fixed top-to-bottom for deterministic scanning.
		pushButton(menuButton)
		pushButton(passButton)
		pushButton(roomsButton)
		pushButton(rankButton)
		pushButton(profileButton)
		pushButton(shopButton)
	end

	local topLeftInset, bottomRightInset = resolveSafeInsets()
	local railX = -(18 + bottomRightInset.X)
	local railTop = topLeftInset.Y + (profile.isMobile and 96 or 88)
	local gap = profile.isMobile and 12 or 10

	for _, button in ipairs(rightRailButtons) do
		local height = button.AbsoluteSize.Y
		if height <= 0 then
			height = button.Size.Y.Offset > 0 and button.Size.Y.Offset or (profile.isMobile and 68 or 60)
		end
		button.AnchorPoint = Vector2.new(1, 0)
		button.Position = UDim2.new(1, railX, 0, railTop)
		railTop += height + gap
	end
end

function UISystem:_setLobbyPanelCollapsed(collapsed)
	if collapsed ~= true then
		self:_closeConflictingWindows("LobbyUI")
	end
	self._lobbyPanelCollapsed = collapsed == true
	local player = Players.LocalPlayer
	if player then
		player:SetAttribute("LobbyPanelCollapsed", self._lobbyPanelCollapsed)
	end
	self:_syncLobbyPanelVisibility()
	self:_refreshBasicLobbyPanel()
	self:_syncAuxiliaryWindowVisibility()
	self:_syncLobbyAuxiliaryWindowVisibility()
	self:_updateRoomBrowserVisibility()
	self:_layoutLobbyFloatRail()
end

function UISystem:_toggleLobbyPanelCollapsed()
	self:_setLobbyPanelCollapsed(not (self._lobbyPanelCollapsed == true))
end

function UISystem:_getEvidenceToolsService()
	local registry = self._context and self._context.Registry or nil
	if not registry or type(registry.Get) ~= "function" then
		return nil
	end
	return registry:Get("EvidenceTools")
end

function UISystem:_ensureFieldKitToolStates()
	local journalState = self._journalState or {}
	local toolStates = journalState.toolStates
	if type(toolStates) ~= "table" then
		toolStates = createDefaultFieldKitToolStates()
		journalState.toolStates = toolStates
		self._journalState = journalState
	end
	for _, toolType in ipairs(FIELD_KIT_TOOL_ORDER) do
		if type(toolStates[toolType]) ~= "table" then
			toolStates[toolType] = createDefaultFieldKitToolState(toolType)
		end
	end
	return toolStates
end

function UISystem:_getFieldKitToolState(toolType)
	local states = self:_ensureFieldKitToolStates()
	return states and states[toolType] or nil
end

function UISystem:_resetFieldKitToolStates()
	local journalState = self._journalState or {}
	journalState.toolStates = createDefaultFieldKitToolStates()
	journalState.toolType = JOURNAL_TOOL_TYPE
	journalState.toolStatus = "Field kit siap."
	journalState.toolReason = "Scan jejak atau pasang utility sesuai situasi."
	journalState.toolSuccess = nil
	journalState.toolLastUsedAt = 0
	self._journalState = journalState
end

function UISystem:_applyFieldKitToolUpdate(toolType, success, reason, data, eventName)
	local toolState = self:_getFieldKitToolState(toolType)
	if not toolState then
		return
	end

	toolState.pending = false
	toolState.lastEvent = eventName or toolState.lastEvent
	toolState.lastReason = reason or toolState.lastReason
	toolState.lastSuccess = success ~= false
	toolState.lastUpdatedAt = os.clock()

	if type(data) == "table" then
		local usesRemaining = tonumber(data.usesRemaining)
		if usesRemaining ~= nil then
			toolState.usesRemaining = math.max(0, math.floor(usesRemaining))
		end

		local chargesRemaining = tonumber(data.chargesRemaining)
		if chargesRemaining ~= nil then
			toolState.chargesRemaining = math.max(0, math.floor(chargesRemaining))
		end

		local placementId = data.placementId
		if type(placementId) == "string" and placementId ~= "" then
			toolState.placementId = placementId
		end
		if data.visualPlaced ~= nil then
			toolState.visualPlaced = data.visualPlaced == true
		end
	end

	if eventName == "SaltPlaced" or eventName == "CrucifixPlaced" or eventName == "SmudgeActivated" then
		toolState.visualPlaced = true
	end

	if eventName == "CrucifixTriggered" then
		local chargesRemaining = tonumber(toolState.chargesRemaining)
		if chargesRemaining ~= nil and chargesRemaining <= 0 then
			toolState.visualPlaced = false
		end
	end

	if reason == "tool_out_of_stock" then
		toolState.usesRemaining = 0
	end

	if toolType == JOURNAL_TOOL_TYPE then
		toolState.visualPlaced = false
		toolState.placementId = nil
		toolState.chargesRemaining = nil
	end
end

function UISystem:_resolveFieldKitMeta(toolType, toolState)
	local config = FIELD_KIT_TOOL_CONFIG[toolType] or {}
	if not toolState then
		return "READY", false, string.upper(tostring(config.role or "UTILITY"))
	end

	local tools = self:_getEvidenceToolsService()
	local clientState = tools and type(tools.GetToolState) == "function" and tools:GetToolState(toolType) or nil
	local cooldownActive = clientState and tonumber(clientState.cooldownUntil) and clientState.cooldownUntil > os.clock()
	local usesRemaining = tonumber(toolState.usesRemaining)
	local chargesRemaining = tonumber(toolState.chargesRemaining)

	if toolState.pending then
		return "WAIT", false, "REQUEST"
	end
	if cooldownActive or toolState.lastReason == "tool_local_cooldown" or toolState.lastReason == "tool_cooldown" then
		return "COOLDOWN", false, "HOLD"
	end
	if toolType == "Salib" and chargesRemaining ~= nil and toolState.visualPlaced == true then
		return string.format("C%d", math.max(0, math.floor(chargesRemaining))), false, chargesRemaining > 0 and "GUARD" or "BURNT"
	end
	if toolState.visualPlaced == true then
		if toolType == "Garam" then
			return "AKTIF", false, "TRAP ON"
		elseif toolType == "Dupa" then
			return "AKTIF", false, "SMOKE ON"
		elseif toolType == "Salib" then
			return "AKTIF", false, "GUARD"
		end
	end
	if usesRemaining ~= nil and usesRemaining <= 0 then
		return "HABIS", true, "STOK 0"
	end
	if usesRemaining ~= nil then
		return string.format("x%d", math.max(0, math.floor(usesRemaining))), false, string.format("STOK %d", math.max(0, math.floor(usesRemaining)))
	end
	if toolType == JOURNAL_TOOL_TYPE then
		return "LIVE", false, "SCAN LOOP"
	end
	return "READY", false, string.upper(tostring(config.role or "UTILITY"))
end

function UISystem:_useInvestigationTool(toolType, options)
	local tools = self:_getEvidenceToolsService()
	local settings = options or {}
	local payload = type(settings.payload) == "table" and settings.payload or nil
	local openJournal = settings.openJournal == true
	local state = self._journalState or {}
	state.toolType = toolType
	state.toolLastUsedAt = os.clock()
	self._journalState = state

	local toolState = self:_getFieldKitToolState(toolType)
	if toolState then
		toolState.pending = true
		toolState.lastUpdatedAt = os.clock()
	end

	if not tools or type(tools.UseTool) ~= "function" then
		state.toolStatus = "Tool client tidak siap."
		state.toolReason = "EvidenceTools belum terdaftar di registry client."
		state.toolSuccess = false
		if toolState then
			toolState.pending = false
			toolState.lastSuccess = false
			toolState.lastReason = "client_not_ready"
			toolState.lastUpdatedAt = os.clock()
		end
		self._journalState = state
		self:_refreshJournalPanel()
		self:_refreshFieldKitPanel()
		self:_applyVisibility()
		return
	end

	local okCall, success, reason, response = pcall(function()
		return tools:UseTool(toolType, payload)
	end)
	if not okCall then
		state.toolStatus = (FIELD_KIT_TOOL_CONFIG[toolType] and FIELD_KIT_TOOL_CONFIG[toolType].label or "Tool") .. " gagal."
		state.toolReason = tostring(success)
		state.toolSuccess = false
		self:_applyFieldKitToolUpdate(toolType, false, tostring(success), nil, nil)
	else
		local responseData = type(response) == "table" and ((type(response.data) == "table" and response.data.result) or response.result or response.data) or nil
		local statusText, detailText = resolveToolFeedback(toolType, success == true, reason or (response and response.reason), responseData, nil)
		state.toolSuccess = success == true
		state.toolStatus = statusText
		state.toolReason = detailText
		self:_applyFieldKitToolUpdate(toolType, success == true, reason or (response and response.reason), responseData, nil)
	end

	self._journalState = state
	self:_refreshJournalPanel()
	self:_refreshFieldKitPanel()
	if openJournal then
		self._uiState.JournalUI.visible = true
		self._windowDismissed.JournalUI = false
		self:_closeConflictingWindows("JournalUI")
	end
	self:_applyVisibility()
end

function UISystem:_triggerJournalToolScan()
	self:_useInvestigationTool(JOURNAL_TOOL_TYPE, {
		openJournal = true,
	})
end

function UISystem:_refreshFieldKitPanel()
	local match = self._uxWidgets and self._uxWidgets.match or nil
	if not match or not match.FieldKitFrame then
		return
	end

	local screenEnabled = (match.BasicGui and match.BasicGui.Enabled == true)
		or (self._uiState.MatchUI and self._uiState.MatchUI.visible == true)
	local showFieldKit = screenEnabled and self._matchPhase ~= MATCH_PHASE.LOBBY and not self:_isMatchResultsPhase()
	match.FieldKitFrame.Visible = showFieldKit

	local state = self._journalState or {}
	local activeTool = FIELD_KIT_TOOL_CONFIG[state.toolType] and state.toolType or JOURNAL_TOOL_TYPE
	local activeConfig = FIELD_KIT_TOOL_CONFIG[activeTool] or FIELD_KIT_TOOL_CONFIG[JOURNAL_TOOL_TYPE]
	local detailText = tostring(state.toolReason or "Pilih tool untuk lanjut investigasi.")
	local statusText = tostring(state.toolStatus or "Field kit siap.")
	local isRecent = (os.clock() - (tonumber(state.toolLastUsedAt) or 0)) <= 4
	local toolStates = self:_ensureFieldKitToolStates()

	if match.FieldKitFrame then
		match.FieldKitFrame.BackgroundColor3 = activeConfig.accent:Lerp(Color3.fromRGB(14, 18, 26), 0.78)
	end
	if match.FieldKitTitle then
		match.FieldKitTitle.Text = "FIELD KIT"
		match.FieldKitTitle.TextColor3 = activeConfig.accent:Lerp(Color3.fromRGB(244, 246, 248), 0.26)
	end
	if match.FieldKitStatusLabel then
		match.FieldKitStatusLabel.Text = string.format("%s\n%s", statusText, detailText)
		match.FieldKitStatusLabel.TextColor3 = state.toolSuccess == false
			and Color3.fromRGB(244, 204, 204)
			or Color3.fromRGB(214, 222, 234)
	end
	if match.FieldKitButtons then
		for toolName, widget in pairs(match.FieldKitButtons) do
			local toolConfig = FIELD_KIT_TOOL_CONFIG[toolName]
			local button = widget and (widget.Button or widget) or nil
			local toolState = toolStates[toolName]
			if button and toolConfig and toolState then
				local metaText, metaDanger, footerText = self:_resolveFieldKitMeta(toolName, toolState)
				local selected = activeTool == toolName and (isRecent or toolState.pending or toolState.visualPlaced == true)
				local idleColor = toolConfig.accent:Lerp(Color3.fromRGB(34, 42, 56), 0.44)
				local fillColor = selected and toolConfig.accent or idleColor
				button.BackgroundColor3 = fillColor
				button.Text = ""

				local buttonStroke = button:FindFirstChildOfClass("UIStroke")
				if buttonStroke then
					buttonStroke.Color = metaDanger
						and Color3.fromRGB(184, 102, 102)
						or toolConfig.accent:Lerp(Color3.fromRGB(236, 232, 224), selected and 0.18 or 0.04)
					buttonStroke.Transparency = selected and 0.08 or 0.22
					buttonStroke.Thickness = selected and 1.6 or 1.2
				end
				if widget.GlyphPlate then
					widget.GlyphPlate.Position = UDim2.fromOffset(7, 6)
					widget.GlyphPlate.Size = UDim2.fromOffset(26, 20)
					widget.GlyphPlate.BackgroundColor3 = toolConfig.accent:Lerp(Color3.fromRGB(248, 244, 236), selected and 0.12 or 0.2)
					widget.GlyphPlate.BackgroundTransparency = selected and 0.08 or 0.18
				end
				if widget.GlyphLabel then
					widget.GlyphLabel.Size = UDim2.fromScale(1, 1)
					widget.GlyphLabel.Text = tostring(toolConfig.glyph or toolConfig.label)
					widget.GlyphLabel.TextColor3 = selected and Color3.fromRGB(18, 24, 30) or Color3.fromRGB(242, 238, 228)
				end
				if widget.ShortcutLabel then
					widget.ShortcutLabel.Position = UDim2.new(1, -32, 0, 6)
					widget.ShortcutLabel.Size = UDim2.fromOffset(26, 12)
					widget.ShortcutLabel.Text = string.format("[%s]", tostring(toolConfig.shortcut or "?"))
					widget.ShortcutLabel.TextColor3 = Color3.fromRGB(208, 214, 226)
				end
				if widget.TitleLabel then
					widget.TitleLabel.Position = UDim2.fromOffset(8, 28)
					widget.TitleLabel.Size = UDim2.new(1, -16, 0, 14)
					widget.TitleLabel.Text = tostring(toolConfig.label)
					widget.TitleLabel.TextColor3 = Color3.fromRGB(246, 246, 244)
					widget.TitleLabel.TextSize = self._deviceProfile and self._deviceProfile.isMobile and 11 or 10
				end
				if widget.MetaLabel then
					widget.MetaLabel.Position = UDim2.new(1, -54, 1, -18)
					widget.MetaLabel.Size = UDim2.fromOffset(48, 14)
					widget.MetaLabel.BackgroundColor3 = metaDanger
						and Color3.fromRGB(102, 58, 58)
						or toolConfig.accent:Lerp(Color3.fromRGB(20, 26, 36), 0.22)
					widget.MetaLabel.BackgroundTransparency = metaDanger and 0.04 or 0.08
					widget.MetaLabel.Text = metaText
					widget.MetaLabel.TextColor3 = metaDanger
						and Color3.fromRGB(252, 226, 226)
						or Color3.fromRGB(250, 246, 236)
				end
				if widget.FooterLabel then
					widget.FooterLabel.Position = UDim2.fromOffset(8, 43)
					widget.FooterLabel.Size = UDim2.new(1, -70, 0, 10)
					widget.FooterLabel.Text = footerText
					widget.FooterLabel.TextColor3 = metaDanger
						and Color3.fromRGB(244, 208, 208)
						or Color3.fromRGB(196, 206, 218)
					widget.FooterLabel.TextSize = self._deviceProfile and self._deviceProfile.isMobile and 9 or 8
				end
			end
		end
	end
end

function UISystem:_refreshBasicWindows()
	self:_refreshMainMenuPanel()
	self:_refreshLeaderboardPanel()
end

function UISystem:_isMatchResultsPhase()
	return self._matchPhase == MATCH_PHASE.RESULT or self._matchPhase == MATCH_PHASE.END
end

function UISystem:_syncMatchWindowVisibility()
	local match = self._uxWidgets and self._uxWidgets.match or nil
	if not match then
		return
	end

	local screenEnabled = (match.BasicGui and match.BasicGui.Enabled == true)
		or (self._uiState.MatchUI and self._uiState.MatchUI.visible == true)
	local showWindow = screenEnabled and not self._matchWindowDismissed
	local showResults = showWindow and self:_isMatchResultsPhase()

	if match.BasicPanel then
		match.BasicPanel.Visible = showWindow
	end
	if match.BasicFloatButton then
		match.BasicFloatButton.Visible = screenEnabled and self._matchWindowDismissed
	end
	if match.ResultsPanel then
		match.ResultsPanel.Visible = showResults
	end
	if self:_isMatchResultsPhase() and match.Gui then
		match.Gui.Enabled = screenEnabled
	end
	if self:_isMatchResultsPhase() and match.Layer then
		match.Layer.Visible = showResults
	end
end

function UISystem:_setMatchWindowDismissed(dismissed)
	if dismissed ~= true then
		self:_closeConflictingWindows("MatchUI")
	end
	self._matchWindowDismissed = dismissed == true
	self:_syncMatchWindowVisibility()
	self:_syncAuxiliaryWindowVisibility()
	self:_refreshBasicLobbyPanel()
	self:_refreshBasicWindows()
	self:_updateRoomBrowserVisibility()
end

function UISystem:_setSummaryValue(label, value)
	if not label then
		return
	end
	label.Text = tostring(value or "-")
end

function UISystem:_updateMatchSummaryRows(rowWidgets, viewState)
	if type(rowWidgets) ~= "table" then
		return
	end

	local result = self._matchResult or createDefaultMatchResult()
	local journalState = self._journalState or {}
	local discoveredEvidence = type(journalState.discoveredEvidence) == "table" and journalState.discoveredEvidence or {}
	local confirmedEvidence = type(journalState.confirmedEvidence) == "table" and journalState.confirmedEvidence or {}
	local candidateGhosts = type(journalState.candidates) == "table" and journalState.candidates or {}
	local hasResults = result.ghostType ~= "Unknown"
		or tonumber(result.matchDuration or 0) > 0
		or tonumber(result.evidenceCollected or 0) > 0
		or tonumber(result.playersSurvived or 0) > 0
		or tonumber(result.playersDead or 0) > 0

	if hasResults then
		self:_setSummaryValue(rowWidgets.status, result.correctGuess and "BERHASIL" or "GAGAL")
		self:_setSummaryValue(rowWidgets.ghostType, tostring(result.ghostType or "Unknown"))
		self:_setSummaryValue(rowWidgets.correctGuess, result.correctGuess and "BENAR" or "SALAH")
		self:_setSummaryValue(rowWidgets.evidenceCollected, tostring(tonumber(result.evidenceCollected or 0) or 0))
		self:_setSummaryValue(rowWidgets.playersSurvived, tostring(tonumber(result.playersSurvived or 0) or 0))
		self:_setSummaryValue(rowWidgets.playersDead, tostring(tonumber(result.playersDead or 0) or 0))
		self:_setSummaryValue(rowWidgets.matchDuration, formatMatchDuration(result.matchDuration))
		self:_setSummaryValue(rowWidgets.currencyReward, formatCurrencyAndPrestigeReward(result.currencyReward, result.ppReward))
		self:_setSummaryValue(rowWidgets.xpReward, tostring(math.floor(tonumber(result.xpReward or 0) or 0)))
	else
		local phaseSummary = {
			Lobby = "MENUNGGU",
			Preparation = "BRIEFING",
			Loading = "LOADING",
			Investigation = "LIVE",
			Hunt = "CRITICAL",
			Results = "RESULT",
		}
		local remaining = self._phaseDuration and math.max(0, self._phaseDuration - (tick() - (self._phaseStartTime or tick()))) or nil
		local evidenceSummary = string.format("%d disc / %d conf", #discoveredEvidence, #confirmedEvidence)
		local candidateSummary = #candidateGhosts > 0 and string.format("%d kandidat", #candidateGhosts) or "Belum dikunci"
		local survivalSummary = viewState == "Hunt" and "Prioritas survive" or "Semua aktif"
		local deathSummary = viewState == "Hunt" and "Hindari contact" or "Belum ada"
		local durationSummary = remaining and formatCountdown(remaining) or "Live"
		local rewardSummary = viewState == "Lobby" and "-" or "Pending"
		if viewState == "Hunt" then
			local huntSnapshot = getHuntStatusSnapshot()
			local nearestRefuge, alternateRefuge = getPreferredHuntRefugeInfo()
			local refugeHint = getRefugeHintText(nearestRefuge)
			local alternateHint = getRefugeHintText(alternateRefuge)
			local huntBadge = getHuntStatusBadge(huntSnapshot)
			local huntDistanceText = type(huntSnapshot.threatDistance) == "number"
				and string.format("%dst", math.max(0, math.floor(huntSnapshot.threatDistance + 0.5)))
				or "-"
			local zoneLabel = huntSnapshot.hideZoneId ~= ""
				and (resolveHideZoneLabel(huntSnapshot.hideZoneId, huntSnapshot.hideSpotType) or huntSnapshot.hideZoneId)
				or refugeHint
			local guidance = "Menuju " .. refugeHint
			if huntSnapshot.hideState == "Hidden" then
				guidance = zoneLabel
				deathSummary = "Diam sampai selesai"
			elseif huntSnapshot.threatState == "Sheltered" then
				guidance = "Tahan posisi"
				deathSummary = refugeHint
			elseif huntSnapshot.threatState == "Critical" or huntSnapshot.threatState == "Close" then
				guidance = "Putus LOS -> " .. refugeHint
				deathSummary = "Ghost " .. huntDistanceText
			elseif huntSnapshot.threatState == "Tracked" or huntSnapshot.threatState == "Warn" then
				guidance = "Rotasi -> " .. refugeHint
				deathSummary = "Ghost " .. huntDistanceText
				if type(nearestRefuge) == "table" and nearestRefuge.kind == "HideSpot" and type(alternateRefuge) == "table" then
					deathSummary = "Ghost " .. huntDistanceText .. " / ALT " .. alternateHint
				end
			else
				deathSummary = refugeHint
			end

			self:_setSummaryValue(rowWidgets.status, huntBadge)
			self:_setSummaryValue(rowWidgets.ghostType, "Mode berburu")
			self:_setSummaryValue(rowWidgets.correctGuess, guidance)
			self:_setSummaryValue(rowWidgets.evidenceCollected, evidenceSummary)
			self:_setSummaryValue(rowWidgets.playersSurvived, zoneLabel)
			self:_setSummaryValue(rowWidgets.playersDead, deathSummary)
			self:_setSummaryValue(rowWidgets.matchDuration, durationSummary)
			self:_setSummaryValue(rowWidgets.currencyReward, rewardSummary)
			self:_setSummaryValue(rowWidgets.xpReward, rewardSummary)
			survivalSummary = guidance
		else
			self:_setSummaryValue(rowWidgets.status, phaseSummary[viewState or "Lobby"] or "LIVE")
			self:_setSummaryValue(rowWidgets.ghostType, #confirmedEvidence > 0 and "Profil menyempit" or "Belum teridentifikasi")
			self:_setSummaryValue(rowWidgets.correctGuess, candidateSummary)
			self:_setSummaryValue(rowWidgets.evidenceCollected, evidenceSummary)
			self:_setSummaryValue(rowWidgets.playersSurvived, survivalSummary)
			self:_setSummaryValue(rowWidgets.playersDead, deathSummary)
			self:_setSummaryValue(rowWidgets.matchDuration, durationSummary)
			self:_setSummaryValue(rowWidgets.currencyReward, rewardSummary)
			self:_setSummaryValue(rowWidgets.xpReward, rewardSummary)
		end
	end

	local statusValue = rowWidgets.status and rowWidgets.status.Text or "-"
	local statusRow = rowWidgets.status and rowWidgets.status.Parent or nil
	if statusRow and statusRow:IsA("Frame") then
		if statusValue == "BERHASIL" then
			statusRow.BackgroundColor3 = Color3.fromRGB(34, 64, 48)
		elseif statusValue == "GAGAL" then
			statusRow.BackgroundColor3 = Color3.fromRGB(68, 40, 40)
		elseif statusValue == "CRITICAL" then
			statusRow.BackgroundColor3 = Color3.fromRGB(88, 46, 46)
		elseif statusValue == "TRACKED" then
			statusRow.BackgroundColor3 = Color3.fromRGB(94, 72, 44)
		elseif statusValue == "HUNT" then
			statusRow.BackgroundColor3 = Color3.fromRGB(78, 48, 48)
		elseif statusValue == "HIDDEN" or statusValue == "SHELTERED" then
			statusRow.BackgroundColor3 = Color3.fromRGB(34, 62, 74)
		elseif statusValue == "LIVE" then
			statusRow.BackgroundColor3 = Color3.fromRGB(30, 56, 44)
		elseif statusValue == "BRIEFING" or statusValue == "LOADING" then
			statusRow.BackgroundColor3 = Color3.fromRGB(38, 50, 68)
		else
			statusRow.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
		end
	end

	local evidenceRow = rowWidgets.evidenceCollected and rowWidgets.evidenceCollected.Parent or nil
	if evidenceRow and evidenceRow:IsA("Frame") then
		evidenceRow.BackgroundColor3 = #discoveredEvidence > 0 and Color3.fromRGB(28, 50, 62) or Color3.fromRGB(24, 30, 40)
	end

	local rewardRow = rowWidgets.currencyReward and rowWidgets.currencyReward.Parent or nil
	if rewardRow and rewardRow:IsA("Frame") then
		rewardRow.BackgroundColor3 = hasResults and Color3.fromRGB(54, 46, 30) or Color3.fromRGB(24, 30, 40)
	end

	local xpRow = rowWidgets.xpReward and rowWidgets.xpReward.Parent or nil
	if xpRow and xpRow:IsA("Frame") then
		xpRow.BackgroundColor3 = hasResults and Color3.fromRGB(32, 48, 60) or Color3.fromRGB(24, 30, 40)
	end
end

function UISystem:_refreshBasicMatchPanel(viewState, payload)
	local match = self._uxWidgets and self._uxWidgets.match or nil
	if not match or not match.BasicPanel then
		return
	end

	viewState = viewState or (
		self._matchPhase == MATCH_PHASE.PREPARING and "Preparation"
		or self._matchPhase == MATCH_PHASE.LOADING and "Loading"
		or self._matchPhase == MATCH_PHASE.BRIEFING and "Preparation"
		or self._matchPhase == MATCH_PHASE.INGAME and "Investigation"
		or self._matchPhase == MATCH_PHASE.ESCALATION and "Investigation"
		or self._matchPhase == MATCH_PHASE.HUNT and "Hunt"
		or self:_isMatchResultsPhase() and "Results"
		or "Lobby"
	)
	payload = payload or self._phasePayload

	local badgeText = "STATUS MATCH"
	local badgeColor = Color3.fromRGB(62, 80, 104)
	local phaseGlyphText = "LO"
	local primaryText = "Menunggu event match."
	local secondaryText = "Panel ini bisa ditutup jika menghalangi pandangan."
	local footerText = CLOSE_HINT_TEXT .. ". Tombol MATCH akan muncul di tepi layar."
	local timerVisible = false
	local timerText = "00:00"
	if self._phaseDuration then
		local remaining = math.max(0, self._phaseDuration - (tick() - (self._phaseStartTime or tick())))
		timerVisible = true
		timerText = formatCountdown(remaining)
	end

	if viewState == "Preparation" or viewState == "Loading" then
		badgeText = "PERSIAPAN"
		badgeColor = Color3.fromRGB(70, 96, 132)
		phaseGlyphText = "PR"
		primaryText = "Masuk ke lokasi..."
		secondaryText = timerVisible
			and ("Loading dan briefing aktif. Waktu fase: " .. timerText .. ".")
			or "Tunggu loading selesai, lalu mulai cari evidence."
	elseif viewState == "Investigation" then
		badgeText = "INVESTIGASI"
		badgeColor = Color3.fromRGB(58, 112, 90)
		phaseGlyphText = "IN"
		primaryText = "Investigasi aktif."
		secondaryText = timerVisible
			and ("Sisa waktu investigasi: " .. timerText .. ". Cari evidence, cek jurnal, dan tentukan ghost.")
			or "Cari evidence, cek jurnal, dan tentukan ghost yang benar."
		footerText = CLOSE_HINT_TEXT .. ". Gunakan Field Kit [1-4] untuk tool cepat dan EVIDENCE [J] untuk jurnal."
	elseif viewState == "Hunt" then
		badgeText = "HUNT"
		badgeColor = Color3.fromRGB(132, 56, 56)
		phaseGlyphText = "HU"
		primaryText = "Ghost sedang memburu."
		local huntObjective = getHuntObjectiveText()
		secondaryText = timerVisible
			and ("Sisa waktu hunt: " .. timerText .. ". " .. huntObjective)
			or huntObjective
		footerText = "Gunakan prompt pintu E/X/tap untuk rotasi. Putus line-of-sight dan cari ruang aman jika tersedia."
	elseif viewState == "Results" then
		local missionFailed = payload and (
			payload.success == false
			or payload.failed == true
			or payload.missionFailed == true
			or payload.correctGuess == false
		)
		if missionFailed == nil then
			local result = self._matchResult or createDefaultMatchResult()
			missionFailed = result.ghostType ~= "Unknown" and result.correctGuess ~= true
		end
		badgeText = missionFailed and "MISI GAGAL" or "MISI SELESAI"
		badgeColor = missionFailed and Color3.fromRGB(132, 56, 56) or Color3.fromRGB(56, 118, 82)
		phaseGlyphText = missionFailed and "FG" or "OK"
		primaryText = "Hasil investigasi sudah tersedia."
		secondaryText = "Ringkasan lengkap ada di bawah. Hadiah akan terisi saat server mengirim reward final."
		footerText = "Hasil akan tetap terlihat sampai kembali ke lobby. Anda tetap bisa menutup panel jika perlu."
	elseif viewState == "Lobby" then
		badgeText = "LOBBY"
		badgeColor = Color3.fromRGB(62, 80, 104)
		phaseGlyphText = "LO"
		primaryText = "Belum ada match aktif."
		secondaryText = "Panel akan terisi otomatis saat match dimulai."
	end

	local headerFill = badgeColor:Lerp(Color3.fromRGB(18, 22, 30), 0.72)
	local summaryFill = badgeColor:Lerp(Color3.fromRGB(20, 27, 36), 0.76)
	local actionFill = badgeColor:Lerp(Color3.fromRGB(34, 48, 64), 0.42)
	local hintFill = badgeColor:Lerp(Color3.fromRGB(18, 22, 30), 0.6)

	if match.BasicTitle then
		match.BasicTitle.Text = "PANEL MATCH"
	end
	if match.HeaderCard then
		match.HeaderCard.BackgroundColor3 = headerFill
	end
	if match.HeaderStroke then
		match.HeaderStroke.Color = badgeColor
	end
	if match.PhaseGlyph then
		match.PhaseGlyph.Text = phaseGlyphText
		match.PhaseGlyph.TextColor3 = badgeColor:Lerp(Color3.fromRGB(255, 244, 228), 0.28)
	end
	if match.BasicStateBadge then
		match.BasicStateBadge.Text = badgeText
		match.BasicStateBadge.BackgroundColor3 = badgeColor
	end
	if match.BasicPrimaryLabel then
		match.BasicPrimaryLabel.Text = primaryText
	end
	if match.BasicSecondaryLabel then
		match.BasicSecondaryLabel.Text = secondaryText
	end
	if match.BasicFooterLabel then
		match.BasicFooterLabel.Text = footerText
	end
	if match.SummaryFrame then
		match.SummaryFrame.BackgroundColor3 = summaryFill
	end
	if match.TimerLabel then
		match.TimerLabel.Visible = timerVisible and viewState ~= "Lobby" and not self:_isMatchResultsPhase()
		match.TimerLabel.Text = timerVisible and timerText or ""
		match.TimerLabel.BackgroundColor3 = headerFill
	end
	if match.TimerCaption then
		match.TimerCaption.Visible = match.TimerLabel and match.TimerLabel.Visible
		match.TimerCaption.Text = viewState == "Hunt" and "HUNT TIMER" or "PHASE TIMER"
		match.TimerCaption.TextColor3 = badgeColor:Lerp(Color3.fromRGB(232, 238, 246), 0.4)
	end
	if match.EvidenceQuickButton then
		match.EvidenceQuickButton.Visible = self._matchPhase ~= MATCH_PHASE.LOBBY and not self:_isMatchResultsPhase()
		match.EvidenceQuickButton.Text = self._windowDismissed.JournalUI == true and "EVIDENCE [J]" or "TUTUP EVIDENCE [J]"
		match.EvidenceQuickButton.BackgroundColor3 = actionFill
	end
	if match.ControlsHintBar then
		match.ControlsHintBar.Visible = self._matchPhase ~= MATCH_PHASE.LOBBY and not self:_isMatchResultsPhase()
		match.ControlsHintBar.BackgroundColor3 = hintFill
	end
	if match.ControlsHintLabel then
		match.ControlsHintLabel.Visible = self._matchPhase ~= MATCH_PHASE.LOBBY and not self:_isMatchResultsPhase()
		match.ControlsHintLabel.Text = viewState == "Hunt"
			and getHuntControlsHintText()
			or self._matchControlsHintText
	end
	if match.ObjectiveLabel then
		if viewState == "Hunt" then
			match.ObjectiveLabel.Text = getHuntObjectiveText()
			match.ObjectiveLabel.Visible = true
		elseif viewState == "Investigation" then
			match.ObjectiveLabel.Text = DEFAULT_MATCH_OBJECTIVE_TEXT
			match.ObjectiveLabel.Visible = true
		end
	end
	self:_updateMatchSummaryRows(match.BasicSummaryRows, viewState)
	self:_refreshFieldKitPanel()
	self:_syncMatchWindowVisibility()
end

function UISystem:_renderResultsPanel(payload)
	local match = self._uxWidgets and self._uxWidgets.match or nil
	if not match or not match.ResultsPanel then
		return
	end

	local missionFailed = payload and (
		payload.success == false
		or payload.failed == true
		or payload.missionFailed == true
		or payload.correctGuess == false
	)
	if missionFailed == nil then
		local result = self._matchResult or createDefaultMatchResult()
		missionFailed = result.ghostType ~= "Unknown" and result.correctGuess ~= true
	end

	if match.ResultsStatus then
		match.ResultsStatus.Text = missionFailed and "MISSION FAILED" or "MISSION COMPLETE"
		match.ResultsStatus.BackgroundColor3 = missionFailed and Color3.fromRGB(120, 48, 48) or Color3.fromRGB(50, 104, 72)
	end
	if match.ResultsSubtitle then
		match.ResultsSubtitle.Text = "Ghost: " .. tostring((self._matchResult and self._matchResult.ghostType) or "Unknown")
	end
	local remainingLock = math.max(0, math.ceil((self._resultsCloseUnlockAt or 0) - tick()))
	local closeUnlocked = remainingLock <= 0
	if match.ResultsCloseButton then
		match.ResultsCloseButton.Visible = closeUnlocked
		match.ResultsCloseButton.Active = closeUnlocked
		match.ResultsCloseButton.Selectable = closeUnlocked
		match.ResultsCloseButton.AutoButtonColor = closeUnlocked
	end
	if match.ResultsLockHint then
		match.ResultsLockHint.Visible = not closeUnlocked
		match.ResultsLockHint.Text = closeUnlocked
			and ""
			or string.format("Lanjut tersedia dalam %ds", remainingLock)
	end
	if match.ResultsFooter then
		match.ResultsFooter.Text = closeUnlocked
			and "Tekan tombol lanjut untuk kembali ke lobby flow. Ringkasan ini dipertahankan untuk E2E."
			or "Hasil match fullscreen dikunci 5 detik agar semua pemain sempat membaca hasil."
	end
	self:_updateMatchSummaryRows(match.ResultsSummaryRows, "Results")
	self:_syncMatchWindowVisibility()
end

function UISystem:_startResultsCloseLock(payload)
	self._resultsCloseUnlockAt = tick() + RESULTS_LOCK_SECONDS
	local unlockAt = self._resultsCloseUnlockAt
	task.spawn(function()
		while self._resultsCloseUnlockAt == unlockAt and tick() < unlockAt do
			self:_renderResultsPanel(payload)
			task.wait(0.1)
		end
		if self._resultsCloseUnlockAt == unlockAt then
			self:_renderResultsPanel(payload)
		end
	end)
end

function UISystem:_refreshBasicLobbyPanel()
	local lobby = self._uxWidgets and self._uxWidgets.lobby or nil
	if not lobby or not lobby.BasicPanel then
		return
	end

	local state = self:GetRoomBrowserState() or {}
	local rooms = type(state.rooms) == "table" and state.rooms or {}
	local currentRoom = type(state.currentRoom) == "table" and state.currentRoom or nil
	local badgeText = "LOBBY"
	local badgeColor = Color3.fromRGB(54, 116, 82)
	local glyphText = "LO"
	local primaryText = "Buka Room Browser, Profile, Shop, Royal Pass, Menu, atau Rank untuk lanjut test E2E."
	local selectedMode = tostring(state.selectedMode or "Classic")
	local selectedMap = tostring(state.selectedMap or MAPS[1] or "HauntedHouse")
	local secondaryText = string.format("Mode %s | Map %s | %d room aktif", selectedMode, selectedMap, #rooms)
	local hintText = "Shortcut: tekan M untuk Room Browser dan R untuk Royal Pass."

	if currentRoom and currentRoom.roomId then
		local playerCount = type(currentRoom.players) == "table" and #currentRoom.players or 0
		local roomMode = tostring(currentRoom.mode or selectedMode)
		local roomMap = tostring(currentRoom.mapId or selectedMap)
		badgeText = state.matchStarting == true and "COUNTDOWN" or "DALAM ROOM"
		badgeColor = state.matchStarting == true and Color3.fromRGB(126, 84, 48) or Color3.fromRGB(62, 96, 132)
		glyphText = state.matchStarting == true and "GO" or "RM"
		primaryText = string.format("Room #%s siap. Lanjutkan kontrol host atau ready dari Room Browser.", tostring(currentRoom.roomId))
		secondaryText = string.format("%s | %s | %d pemain", roomMode, roomMap, playerCount)
		if state.matchStarting == true then
			local countdown = state.countdownSecondsLeft or state.countdownTotal
			hintText = countdown and ("Countdown aktif: " .. formatCountdown(countdown)) or "Countdown aktif..."
		end
	elseif state.lastError then
		badgeText = "PERLU CEK"
		badgeColor = Color3.fromRGB(118, 74, 48)
		glyphText = "ER"
		hintText = "Status terakhir: " .. tostring(state.lastError)
	end

	local headerFill = badgeColor:Lerp(Color3.fromRGB(18, 26, 34), 0.72)
	local actionFill = badgeColor:Lerp(Color3.fromRGB(38, 56, 74), 0.42)

	if lobby.BasicTitle then
		lobby.BasicTitle.Text = "LOBBY PANEL"
	end
	if lobby.BasicHeaderCard then
		lobby.BasicHeaderCard.BackgroundColor3 = headerFill
	end
	if lobby.BasicHeaderStroke then
		lobby.BasicHeaderStroke.Color = badgeColor
	end
	if lobby.BasicLobbyGlyph then
		lobby.BasicLobbyGlyph.Text = glyphText
		lobby.BasicLobbyGlyph.TextColor3 = badgeColor:Lerp(Color3.fromRGB(255, 244, 228), 0.28)
	end
	if lobby.BasicStatusBadge then
		lobby.BasicStatusBadge.Text = badgeText
		lobby.BasicStatusBadge.BackgroundColor3 = badgeColor
	end
	if lobby.BasicPrimaryLabel then
		lobby.BasicPrimaryLabel.Text = primaryText
	end
	if lobby.BasicSecondaryLabel then
		lobby.BasicSecondaryLabel.Text = secondaryText
	end
	if lobby.BasicHintLabel then
		lobby.BasicHintLabel.Text = hintText
	end
	if lobby.BasicModePill then
		lobby.BasicModePill.Text = string.upper(selectedMode)
		lobby.BasicModePill.BackgroundColor3 = Color3.fromRGB(58, 92, 126)
	end
	if lobby.BasicMapPill then
		lobby.BasicMapPill.Text = tostring(currentRoom and currentRoom.mapId or selectedMap)
		lobby.BasicMapPill.BackgroundColor3 = Color3.fromRGB(70, 86, 64)
	end
	if lobby.BasicRoomPill then
		local roomText = currentRoom and string.format("ROOM #%s", tostring(currentRoom.roomId)) or string.format("%d ROOM", #rooms)
		lobby.BasicRoomPill.Text = roomText
		lobby.BasicRoomPill.BackgroundColor3 = Color3.fromRGB(96, 76, 48)
	end
	if lobby.BasicOpenRoomBrowserButton then
		lobby.BasicOpenRoomBrowserButton.Text = self._roomBrowserVisible and "TUTUP ROOM BROWSER" or "OPEN ROOM BROWSER"
		lobby.BasicOpenRoomBrowserButton.BackgroundColor3 = self._roomBrowserVisible
			and badgeColor:Lerp(Color3.fromRGB(72, 118, 160), 0.24)
			or actionFill
	end
	if lobby.BasicProfileButton then
		local profileOpen = self._uiState.ProfileUI and self._uiState.ProfileUI.visible == true and self._windowDismissed.ProfileUI ~= true
		lobby.BasicProfileButton.Text = profileOpen and "TUTUP PROFILE" or "PROFILE"
	end
	if lobby.BasicShopButton then
		local shopOpen = self._uiState.ShopUI and self._uiState.ShopUI.visible == true and self._windowDismissed.ShopUI ~= true
		lobby.BasicShopButton.Text = shopOpen and "TUTUP SHOP" or "SHOP"
	end
	if lobby.BasicRoyalPassButton then
		local royalPassOpen = self._uiState.RoyalPassUI and self._uiState.RoyalPassUI.visible == true and self._windowDismissed.RoyalPassUI ~= true
		lobby.BasicRoyalPassButton.Text = royalPassOpen and "TUTUP ROYAL PASS" or "ROYAL PASS"
	end
	if lobby.BasicMenuButton then
		local _, menuPanel = self:_getBasicWindowState("MainMenuUI")
		local menuOpen = menuPanel and menuPanel.Visible == true
		lobby.BasicMenuButton.Text = menuOpen and "TUTUP MENU" or "MENU"
	end
	if lobby.BasicRankButton then
		local _, rankPanel = self:_getBasicWindowState("LeaderboardUI")
		local rankOpen = rankPanel and rankPanel.Visible == true
		lobby.BasicRankButton.Text = rankOpen and "TUTUP RANK" or "RANK"
	end
end

function UISystem:_refreshMainMenuPanel()
	local window = self._uxWidgets and self._uxWidgets.basicWindows and self._uxWidgets.basicWindows.MainMenuUI
	if not window then
		return
	end

	local state = self:GetRoomBrowserState() or {}
	local rooms = type(state.rooms) == "table" and state.rooms or {}
	local currentRoom = type(state.currentRoom) == "table" and state.currentRoom or nil
	local selectedMode = tostring(state.selectedMode or "Classic")
	local selectedMap = tostring(state.selectedMap or MAPS[1] or "HauntedHouse")
	local statusText = "QUICK ACCESS"
	local badgeColor = Color3.fromRGB(60, 92, 132)
	local primaryText = "Panel navigasi cepat untuk test lobby flow tanpa mengandalkan hotkey."
	local secondaryText = string.format("Mode %s | Map %s | %d room aktif", selectedMode, selectedMap, #rooms)

	if currentRoom and currentRoom.roomId then
		local playerCount = type(currentRoom.players) == "table" and #currentRoom.players or 0
		statusText = state.matchStarting == true and "COUNTDOWN" or "ROOM ACTIVE"
		badgeColor = state.matchStarting == true and Color3.fromRGB(126, 84, 48) or Color3.fromRGB(54, 110, 86)
		primaryText = string.format("Room #%s aktif. Semua akses dasar lobby ada di panel ini.", tostring(currentRoom.roomId))
		secondaryText = string.format(
			"%s | %s | %d pemain",
			tostring(currentRoom.mode or selectedMode),
			tostring(currentRoom.mapId or selectedMap),
			playerCount
		)
	end

	if window.Title then
		window.Title.Text = "QUICK MENU"
	end
	if window.StatusBadge then
		window.StatusBadge.Text = statusText
		window.StatusBadge.BackgroundColor3 = badgeColor
	end
	if window.PrimaryLabel then
		window.PrimaryLabel.Text = primaryText
	end
	if window.SecondaryLabel then
		window.SecondaryLabel.Text = secondaryText
	end
	if window.FooterLabel then
		window.FooterLabel.Text = "Tombol di bawah benar-benar menggerakkan UI terkait. X untuk minimize ke float MENU."
	end

	local profileOpen = self._uiState.ProfileUI and self._uiState.ProfileUI.visible == true and self._windowDismissed.ProfileUI ~= true
	local shopOpen = self._uiState.ShopUI and self._uiState.ShopUI.visible == true and self._windowDismissed.ShopUI ~= true
	local _, rankPanel = self:_getBasicWindowState("LeaderboardUI")
	local rankOpen = rankPanel and rankPanel.Visible == true

	if window.RoomBrowserButton then
		window.RoomBrowserButton.Text = self._roomBrowserVisible and "TUTUP ROOM BROWSER" or "OPEN ROOM BROWSER"
		window.RoomBrowserButton.BackgroundColor3 = self._roomBrowserVisible
			and Color3.fromRGB(66, 104, 144)
			or Color3.fromRGB(46, 78, 114)
	end
	if window.ProfileButton then
		window.ProfileButton.Text = profileOpen and "TUTUP PROFILE" or "OPEN PROFILE"
		window.ProfileButton.BackgroundColor3 = profileOpen
			and Color3.fromRGB(78, 112, 82)
			or Color3.fromRGB(58, 84, 62)
	end
	if window.ShopButton then
		window.ShopButton.Text = shopOpen and "TUTUP SHOP" or "OPEN SHOP"
		window.ShopButton.BackgroundColor3 = shopOpen
			and Color3.fromRGB(126, 94, 56)
			or Color3.fromRGB(104, 78, 48)
	end
	if window.RankButton then
		window.RankButton.Text = rankOpen and "TUTUP RANK BOARD" or "OPEN RANK BOARD"
		window.RankButton.BackgroundColor3 = rankOpen
			and Color3.fromRGB(98, 104, 62)
			or Color3.fromRGB(78, 84, 50)
	end
end

function UISystem:_ensureLeaderboardWidgets(window)
	if not window or not window.ContentFrame then
		return nil
	end
	if window.LeaderboardWidgets then
		return window.LeaderboardWidgets
	end

	if window.ContentText then
		window.ContentText.Visible = false
	end

	local contentFrame = window.ContentFrame
	local deck = contentFrame:FindFirstChild("LeaderboardDeck")
	if deck and not deck:IsA("Frame") then
		deck:Destroy()
		deck = nil
	end
	if not deck then
		deck = Instance.new("Frame")
		deck.Name = "LeaderboardDeck"
		deck.Size = UDim2.new(1, -4, 0, 0)
		deck.AutomaticSize = Enum.AutomaticSize.Y
		deck.BackgroundTransparency = 1
		deck.Parent = contentFrame

		local deckLayout = Instance.new("UIListLayout")
		deckLayout.FillDirection = Enum.FillDirection.Vertical
		deckLayout.SortOrder = Enum.SortOrder.LayoutOrder
		deckLayout.Padding = UDim.new(0, 8)
		deckLayout.Parent = deck
	end

	local heroCard = Instance.new("Frame")
	heroCard.Name = "HeroCard"
	heroCard.Size = UDim2.new(1, 0, 0, 116)
	heroCard.BackgroundColor3 = Color3.fromRGB(28, 35, 46)
	heroCard.BorderSizePixel = 0
	heroCard.Parent = deck
	local heroCorner = Instance.new("UICorner")
	heroCorner.CornerRadius = UDim.new(0, 10)
	heroCorner.Parent = heroCard

	local heroStroke = Instance.new("UIStroke")
	heroStroke.Name = "HeroStroke"
	heroStroke.Thickness = 1.5
	heroStroke.Color = Color3.fromRGB(102, 116, 64)
	heroStroke.Transparency = 0.18
	heroStroke.Parent = heroCard

	local heroBadge = Instance.new("TextLabel")
	heroBadge.Name = "HeroBadge"
	heroBadge.Position = UDim2.fromOffset(12, 12)
	heroBadge.Size = UDim2.fromOffset(132, 20)
	heroBadge.BackgroundColor3 = Color3.fromRGB(92, 104, 60)
	heroBadge.BorderSizePixel = 0
	heroBadge.Font = Enum.Font.GothamBold
	heroBadge.TextSize = 10
	heroBadge.TextColor3 = Color3.fromRGB(248, 244, 234)
	heroBadge.Text = "LOCAL SNAPSHOT"
	heroBadge.Parent = heroCard
	local heroBadgeCorner = Instance.new("UICorner")
	heroBadgeCorner.CornerRadius = UDim.new(1, 0)
	heroBadgeCorner.Parent = heroBadge

	local heroTitle = Instance.new("TextLabel")
	heroTitle.Name = "HeroTitle"
	heroTitle.Position = UDim2.fromOffset(12, 38)
	heroTitle.Size = UDim2.new(1, -24, 0, 24)
	heroTitle.BackgroundTransparency = 1
	heroTitle.Font = Enum.Font.GothamBold
	heroTitle.TextSize = 18
	heroTitle.TextXAlignment = Enum.TextXAlignment.Left
	heroTitle.TextColor3 = Color3.fromRGB(244, 246, 250)
	heroTitle.Text = "PLAYER • RANK"
	heroTitle.Parent = heroCard

	local heroMeta = Instance.new("TextLabel")
	heroMeta.Name = "HeroMeta"
	heroMeta.Position = UDim2.fromOffset(12, 62)
	heroMeta.Size = UDim2.new(1, -24, 0, 18)
	heroMeta.BackgroundTransparency = 1
	heroMeta.Font = Enum.Font.Gotham
	heroMeta.TextSize = 12
	heroMeta.TextXAlignment = Enum.TextXAlignment.Left
	heroMeta.TextColor3 = Color3.fromRGB(192, 202, 214)
	heroMeta.Text = "Level • Match • Victory"
	heroMeta.Parent = heroCard

	local progressTrack = Instance.new("Frame")
	progressTrack.Name = "ProgressTrack"
	progressTrack.Position = UDim2.fromOffset(12, 82)
	progressTrack.Size = UDim2.new(1, -24, 0, 14)
	progressTrack.BackgroundColor3 = Color3.fromRGB(38, 46, 58)
	progressTrack.BorderSizePixel = 0
	progressTrack.Parent = heroCard
	local progressTrackCorner = Instance.new("UICorner")
	progressTrackCorner.CornerRadius = UDim.new(1, 0)
	progressTrackCorner.Parent = progressTrack

	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.fromScale(1, 1)
	progressFill.BackgroundColor3 = Color3.fromRGB(104, 148, 220)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressTrack
	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(1, 0)
	progressFillCorner.Parent = progressFill

	local progressCaption = Instance.new("TextLabel")
	progressCaption.Name = "ProgressCaption"
	progressCaption.Position = UDim2.fromOffset(12, 98)
	progressCaption.Size = UDim2.new(1, -24, 0, 16)
	progressCaption.BackgroundTransparency = 1
	progressCaption.Font = Enum.Font.Gotham
	progressCaption.TextSize = 11
	progressCaption.TextXAlignment = Enum.TextXAlignment.Left
	progressCaption.TextColor3 = Color3.fromRGB(184, 196, 210)
	progressCaption.Text = "Sanity live 100% • Status Safe"
	progressCaption.Parent = heroCard

	local tierList = Instance.new("Frame")
	tierList.Name = "TierList"
	tierList.Size = UDim2.new(1, 0, 0, 0)
	tierList.AutomaticSize = Enum.AutomaticSize.Y
	tierList.BackgroundTransparency = 1
	tierList.Parent = deck
	local tierLayout = Instance.new("UIListLayout")
	tierLayout.FillDirection = Enum.FillDirection.Vertical
	tierLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tierLayout.Padding = UDim.new(0, 6)
	tierLayout.Parent = tierList

	local rows = {}
	for index = 1, 4 do
		local row = createActionRow(tierList, "RankRow" .. tostring(index), "RANK", "-", "INFO")
		row.Button.Active = false
		row.Button.AutoButtonColor = false
		row.Button.Selectable = false
		table.insert(rows, row)
	end

	window.LeaderboardWidgets = {
		Deck = deck,
		HeroCard = heroCard,
		HeroStroke = heroStroke,
		HeroBadge = heroBadge,
		HeroTitle = heroTitle,
		HeroMeta = heroMeta,
		ProgressTrack = progressTrack,
		ProgressFill = progressFill,
		ProgressCaption = progressCaption,
		Rows = rows,
	}
	return window.LeaderboardWidgets
end

function UISystem:_refreshLeaderboardPanel()
	local window = self._uxWidgets and self._uxWidgets.basicWindows and self._uxWidgets.basicWindows.LeaderboardUI
	if not window then
		return
	end

	local player = Players.LocalPlayer
	local playerName = player and (player.DisplayName or player.Name) or "Player"
	local profile = self._profileState or {}
	local level = math.max(1, math.floor(tonumber(profile.level or 1) or 1))
	local totalGames = math.max(0, math.floor(tonumber(profile.totalGames or 0) or 0))
	local sanity = math.max(0, math.floor(tonumber(profile.sanity or 100) or 100))
	local rankName = tostring(profile.rank or "Bayi III")
	local victories = math.max(0, math.floor(tonumber(profile.victories or 0) or 0))
	local leaderboardLabel = string.match(string.lower(rankName), "^sang ahli")
		and string.format("Sang Ahli x%d", victories)
		or rankName
	local state = self:GetRoomBrowserState() or {}
	local rooms = type(state.rooms) == "table" and state.rooms or {}
	local currentRoom = type(state.currentRoom) == "table" and state.currentRoom or nil
	local badgeText = "LOCAL SNAPSHOT"
	local badgeColor = Color3.fromRGB(92, 104, 60)
	local secondaryText = string.format("Rank %s | Match %d | Snapshot Lokal", leaderboardLabel, totalGames)
	local roomLine = string.format("Room Browser %s | %d room terlihat", self._roomBrowserVisible and "terbuka" or "tertutup", #rooms)
	local roomMode = currentRoom and tostring(currentRoom.mode or state.selectedMode or "Classic") or tostring(state.selectedMode or "Classic")
	local roomModeLower = string.lower(roomMode)
	local playerCount = currentRoom and (type(currentRoom.players) == "table" and #currentRoom.players or 0) or 0
	local maxPlayers = currentRoom and math.max(playerCount, math.floor(tonumber(currentRoom.maxPlayers or 4) or 4)) or 4
	local statusToken = tostring(profile.status or "safe")
	local statusLabel = titleCaseToken(statusToken)
	local statusAccent = Color3.fromRGB(90, 122, 80)
	if statusToken == "hunt_risk" then
		statusAccent = Color3.fromRGB(132, 68, 68)
	elseif statusToken == "high_paranormal_activity" then
		statusAccent = Color3.fromRGB(130, 92, 54)
	elseif statusToken == "unstable" then
		statusAccent = Color3.fromRGB(82, 96, 128)
	end

	if currentRoom and currentRoom.roomId then
		badgeText = string.upper(roomMode) .. " ROOM"
		badgeColor = roomModeLower == "ranked"
			and Color3.fromRGB(132, 96, 52)
			or Color3.fromRGB(60, 96, 132)
		roomLine = string.format(
			"Room #%s | %s | %d pemain",
			tostring(currentRoom.roomId),
			tostring(currentRoom.mapId or state.selectedMap or MAPS[1] or "HauntedHouse"),
			playerCount
		)
	end

	if window.Title then
		window.Title.Text = "RANK BOARD"
	end
	if window.StatusBadge then
		window.StatusBadge.Text = badgeText
		window.StatusBadge.BackgroundColor3 = badgeColor
	end
	if window.PrimaryLabel then
		window.PrimaryLabel.Text = string.format("%s | %s", playerName, leaderboardLabel)
	end
	if window.SecondaryLabel then
		window.SecondaryLabel.Text = secondaryText
	end
	if window.FooterLabel then
		window.FooterLabel.Text = "Rank board ini sengaja tetap jujur: snapshot lokal yang nyaman dibaca, tanpa angka leaderboard server palsu."
	end

	local widgets = self:_ensureLeaderboardWidgets(window)
	if widgets then
		local roomBadgeText = currentRoom and (string.upper(roomMode) .. " ROOM") or "LOCAL SNAPSHOT"
		local roomBadgeColor = currentRoom and badgeColor or Color3.fromRGB(92, 104, 60)
		local roomGlyph = roomModeLower == "ranked" and "RK" or "CL"
		local victoryRate = totalGames > 0 and math.floor((victories / math.max(totalGames, 1)) * 100 + 0.5) or 0
		local sanityPercent = math.clamp(sanity / 100, 0.08, 1)
		local rows = widgets.Rows or {}
		local rankGlyph = string.match(string.upper(rankName), "^SANG AHLI") and "SA" or "RB"
		local roomSummary = currentRoom
			and string.format(
				"Room #%s • %s • %d/%d pemain",
				tostring(currentRoom.roomId),
				tostring(currentRoom.mapId or state.selectedMap or MAPS[1] or "HauntedHouse"),
				playerCount,
				maxPlayers
			)
			or string.format("Browser %s • %d room terlihat", self._roomBrowserVisible and "terbuka" or "tertutup", #rooms)

		widgets.HeroStroke.Color = roomBadgeColor
		widgets.HeroBadge.BackgroundColor3 = roomBadgeColor
		widgets.HeroBadge.Text = roomBadgeText
		widgets.HeroTitle.Text = string.format("%s • %s", playerName, leaderboardLabel)
		widgets.HeroMeta.Text = string.format("LV %d • %d match • %d victory", level, totalGames, victories)
		widgets.ProgressFill.BackgroundColor3 = statusAccent
		widgets.ProgressFill.Size = UDim2.fromScale(sanityPercent, 1)
		widgets.ProgressCaption.Text = string.format("Sanity live %d%% • Status %s • %s", sanity, statusLabel, roomSummary)

		local rowData = {
			{
				badge = "RANK",
				glyph = rankGlyph,
				title = "Tier status",
				meta = string.format("Rank aktif %s • raw tier %s", leaderboardLabel, rankName),
				pill = string.format("LV %d", level),
				button = "LOCAL",
				accent = roomBadgeColor,
				preview = roomModeLower == "ranked" and Color3.fromRGB(62, 48, 30) or Color3.fromRGB(40, 52, 70),
			},
			{
				badge = "MIND",
				glyph = "SN",
				title = "Pressure band",
				meta = string.format("Status %s • event %s", statusLabel, tostring(profile.lastEvent or "Idle")),
				pill = string.format("%d%%", sanity),
				button = sanity <= 35 and "RISK" or "SAFE",
				accent = statusAccent,
				preview = sanity <= 35 and Color3.fromRGB(62, 42, 42) or Color3.fromRGB(42, 56, 46),
			},
			{
				badge = roomModeLower == "ranked" and "MODE" or "ROOM",
				glyph = roomGlyph,
				title = currentRoom and "Live room pulse" or "Room browser pulse",
				meta = roomSummary,
				pill = currentRoom and string.format("%d/%d", playerCount, maxPlayers) or string.format("%d ROOM", #rooms),
				button = self._roomBrowserVisible and "OPEN" or "IDLE",
				accent = badgeColor,
				preview = roomModeLower == "ranked" and Color3.fromRGB(58, 46, 32) or Color3.fromRGB(38, 52, 70),
			},
			{
				badge = "WIN",
				glyph = "VG",
				title = "Mastery footprint",
				meta = string.format("Victory counter lokal %d • %d%% ratio snapshot", victories, victoryRate),
				pill = string.format("%d WIN", victories),
				button = totalGames > 0 and "TRACK" or "FRESH",
				accent = Color3.fromRGB(112, 84, 52),
				preview = Color3.fromRGB(50, 40, 32),
			},
		}

		for index, row in ipairs(rows) do
			local data = rowData[index]
			if data then
				row.Root.BackgroundColor3 = Color3.fromRGB(23, 29, 39)
				row.Accent.BackgroundColor3 = data.accent
				row.Preview.BackgroundColor3 = data.preview
				row.PreviewBadge.BackgroundColor3 = data.accent
				row.PreviewBadge.TextColor3 = Color3.fromRGB(247, 243, 236)
				row.PreviewBadge.Text = data.badge
				row.PreviewGlyph.TextColor3 = Color3.fromRGB(247, 243, 236)
				row.PreviewGlyph.Text = data.glyph
				row.Title.Text = data.title
				row.Meta.Text = data.meta
				applyPricePillVisual(row.PricePill, data.pill, data.accent, Color3.fromRGB(247, 243, 236))
				row.Button.BackgroundColor3 = data.preview
				row.Button.TextColor3 = Color3.fromRGB(242, 241, 236)
				row.Button.Text = data.button
			end
		end
	end

	local _, menuPanel = self:_getBasicWindowState("MainMenuUI")
	local menuOpen = menuPanel and menuPanel.Visible == true
	local profileOpen = self._uiState.ProfileUI and self._uiState.ProfileUI.visible == true and self._windowDismissed.ProfileUI ~= true
	if window.ProfileButton then
		window.ProfileButton.Text = profileOpen and "TUTUP PROFILE" or "PROFILE"
		window.ProfileButton.BackgroundColor3 = profileOpen
			and Color3.fromRGB(78, 112, 82)
			or Color3.fromRGB(58, 84, 62)
	end
	if window.RoomBrowserButton then
		window.RoomBrowserButton.Text = self._roomBrowserVisible and "TUTUP ROOMS" or "OPEN ROOMS"
		window.RoomBrowserButton.BackgroundColor3 = self._roomBrowserVisible
			and Color3.fromRGB(66, 104, 144)
			or Color3.fromRGB(46, 78, 114)
	end
	if window.MenuButton then
		window.MenuButton.Text = menuOpen and "TUTUP MENU" or "OPEN MENU"
		window.MenuButton.BackgroundColor3 = menuOpen
			and Color3.fromRGB(86, 96, 120)
			or Color3.fromRGB(58, 66, 84)
	end
end

function UISystem:_refreshAuxiliaryPanels()
	self:_refreshJournalPanel()
	self:_refreshProfilePanel()
	self:_refreshShopPanel()
	self:_refreshRoyalPassPanel()
	self:_refreshPasraPanel()
	self:_refreshSpectatorPanel()
	self:_syncAuxiliaryWindowVisibility()
end

function UISystem:_refreshWindowText(guiName, statusText, primaryText, secondaryText, contentText, footerText, badgeColor)
	local window = self._uxWidgets and self._uxWidgets.windows and self._uxWidgets.windows[guiName]
	if not window then
		return
	end

	local function resolveText(value)
		if value == nil then
			return ""
		end
		return tostring(value)
	end

	if window.StatusBadge then
		window.StatusBadge.Text = resolveText(statusText)
		if badgeColor then
			window.StatusBadge.BackgroundColor3 = badgeColor
		end
	end
	if window.PrimaryLabel then
		window.PrimaryLabel.Text = resolveText(primaryText)
	end
	if window.SecondaryLabel then
		window.SecondaryLabel.Text = resolveText(secondaryText)
	end
	if window.ContentText then
		window.ContentText.Text = resolveText(contentText)
		window.ContentText.Visible = contentText ~= nil and contentText ~= ""
	end
	if window.FooterLabel and footerText then
		window.FooterLabel.Text = resolveText(footerText)
	end
end

function UISystem:_layoutJournalWindow(window)
	if not window or not window.Panel then
		return
	end

	local viewportSize = Vector2.new(1280, 720)
	local camera = Workspace.CurrentCamera
	if camera then
		viewportSize = camera.ViewportSize
	end

	local lobbyVisible = false
	local lobby = self._uxWidgets and self._uxWidgets.lobby or nil
	if lobby and lobby.BasicPanel and lobby.BasicPanel.Visible == true then
		lobbyVisible = true
	end

	if viewportSize.X >= 1080 then
		window.Panel.Position = lobbyVisible and UDim2.fromOffset(372, 16) or UDim2.fromOffset(16, 104)
	else
		window.Panel.Position = UDim2.fromOffset(16, 104)
	end
end

function UISystem:_ensureJournalWidgets(window)
	if not window or not window.ContentFrame then
		return nil
	end
	if window.JournalWidgets then
		return window.JournalWidgets
	end

	if window.ContentText then
		window.ContentText.Visible = false
	end

	local contentFrame = window.ContentFrame
	local deck = contentFrame:FindFirstChild("JournalDeck")
	if deck and not deck:IsA("Frame") then
		deck:Destroy()
		deck = nil
	end
	if not deck then
		deck = Instance.new("Frame")
		deck.Name = "JournalDeck"
		deck.Size = UDim2.new(1, -4, 0, 0)
		deck.AutomaticSize = Enum.AutomaticSize.Y
		deck.BackgroundTransparency = 1
		deck.Parent = contentFrame

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 8)
		layout.Parent = deck
	end

	local heroCard = Instance.new("Frame")
	heroCard.Name = "HeroCard"
	heroCard.Size = UDim2.new(1, 0, 0, 104)
	heroCard.BackgroundColor3 = Color3.fromRGB(28, 38, 48)
	heroCard.BorderSizePixel = 0
	heroCard.Parent = deck

	local heroCorner = Instance.new("UICorner")
	heroCorner.CornerRadius = UDim.new(0, 12)
	heroCorner.Parent = heroCard

	local heroStroke = Instance.new("UIStroke")
	heroStroke.Name = "HeroStroke"
	heroStroke.Thickness = 1.5
	heroStroke.Color = Color3.fromRGB(56, 92, 128)
	heroStroke.Transparency = 0.16
	heroStroke.Parent = heroCard

	local heroBadge = Instance.new("TextLabel")
	heroBadge.Name = "HeroBadge"
	heroBadge.Position = UDim2.fromOffset(12, 10)
	heroBadge.Size = UDim2.fromOffset(118, 20)
	heroBadge.BackgroundColor3 = Color3.fromRGB(56, 92, 128)
	heroBadge.BorderSizePixel = 0
	heroBadge.Font = Enum.Font.GothamBold
	heroBadge.TextSize = 10
	heroBadge.TextColor3 = Color3.fromRGB(244, 244, 238)
	heroBadge.Text = "JOURNAL"
	heroBadge.Parent = heroCard

	local heroBadgeCorner = Instance.new("UICorner")
	heroBadgeCorner.CornerRadius = UDim.new(1, 0)
	heroBadgeCorner.Parent = heroBadge

	local heroTitle = Instance.new("TextLabel")
	heroTitle.Name = "HeroTitle"
	heroTitle.Position = UDim2.fromOffset(12, 38)
	heroTitle.Size = UDim2.new(1, -100, 0, 24)
	heroTitle.BackgroundTransparency = 1
	heroTitle.Font = Enum.Font.GothamBold
	heroTitle.TextSize = 16
	heroTitle.TextColor3 = Color3.fromRGB(244, 244, 238)
	heroTitle.TextWrapped = true
	heroTitle.TextXAlignment = Enum.TextXAlignment.Left
	heroTitle.TextYAlignment = Enum.TextYAlignment.Top
	heroTitle.Text = "Belum ada evidence."
	heroTitle.Parent = heroCard

	local heroMeta = Instance.new("TextLabel")
	heroMeta.Name = "HeroMeta"
	heroMeta.Position = UDim2.fromOffset(12, 66)
	heroMeta.Size = UDim2.new(1, -100, 0, 24)
	heroMeta.BackgroundTransparency = 1
	heroMeta.Font = Enum.Font.Gotham
	heroMeta.TextSize = 11
	heroMeta.TextColor3 = Color3.fromRGB(188, 199, 212)
	heroMeta.TextWrapped = true
	heroMeta.TextXAlignment = Enum.TextXAlignment.Left
	heroMeta.TextYAlignment = Enum.TextYAlignment.Top
	heroMeta.Text = "Confirmed 0 | Kandidat 0 | Event Idle"
	heroMeta.Parent = heroCard

	local heroGlyph = Instance.new("TextLabel")
	heroGlyph.Name = "HeroGlyph"
	heroGlyph.AnchorPoint = Vector2.new(1, 0)
	heroGlyph.Position = UDim2.new(1, -12, 0, 12)
	heroGlyph.Size = UDim2.fromOffset(84, 60)
	heroGlyph.BackgroundTransparency = 1
	heroGlyph.Font = Enum.Font.GothamBlack
	heroGlyph.TextSize = 44
	heroGlyph.TextColor3 = Color3.fromRGB(86, 118, 148)
	heroGlyph.TextTransparency = 0.28
	heroGlyph.TextXAlignment = Enum.TextXAlignment.Right
	heroGlyph.Text = "JN"
	heroGlyph.Parent = heroCard

	local statRow = Instance.new("Frame")
	statRow.Name = "StatRow"
	statRow.Size = UDim2.new(1, 0, 0, 56)
	statRow.BackgroundTransparency = 1
	statRow.Parent = deck

	local statLayout = Instance.new("UIListLayout")
	statLayout.FillDirection = Enum.FillDirection.Horizontal
	statLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statLayout.Padding = UDim.new(0, 8)
	statLayout.Parent = statRow

	local function createStatCard(name, title, tint)
		local card = Instance.new("Frame")
		card.Name = name
		card.Size = UDim2.new(0.3333, -6, 1, 0)
		card.BackgroundColor3 = tint
		card.BackgroundTransparency = 0.18
		card.BorderSizePixel = 0
		card.Parent = statRow

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 10)
		cardCorner.Parent = card

		local valueLabel = Instance.new("TextLabel")
		valueLabel.Name = "ValueLabel"
		valueLabel.Position = UDim2.fromOffset(10, 6)
		valueLabel.Size = UDim2.new(1, -20, 0, 22)
		valueLabel.BackgroundTransparency = 1
		valueLabel.Font = Enum.Font.GothamBold
		valueLabel.TextSize = 18
		valueLabel.TextColor3 = Color3.fromRGB(244, 244, 238)
		valueLabel.TextXAlignment = Enum.TextXAlignment.Left
		valueLabel.Text = "0"
		valueLabel.Parent = card

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Position = UDim2.fromOffset(10, 28)
		titleLabel.Size = UDim2.new(1, -20, 0, 16)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 10
		titleLabel.TextColor3 = Color3.fromRGB(228, 232, 236)
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Text = title
		titleLabel.Parent = card

		return valueLabel
	end

	local discoveredCount = createStatCard("DiscoveredCard", "DISCOVERED", Color3.fromRGB(52, 86, 118))
	local confirmedCount = createStatCard("ConfirmedCard", "CONFIRMED", Color3.fromRGB(58, 108, 86))
	local candidateCount = createStatCard("CandidateCard", "CANDIDATES", Color3.fromRGB(96, 78, 50))

	local function createSectionCard(name, title, tint)
		local card = Instance.new("Frame")
		card.Name = name
		card.Size = UDim2.new(1, 0, 0, 86)
		card.BackgroundColor3 = Color3.fromRGB(18, 26, 34)
		card.BorderSizePixel = 0
		card.Parent = deck

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 10)
		cardCorner.Parent = card

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Thickness = 1
		cardStroke.Color = tint
		cardStroke.Transparency = 0.2
		cardStroke.Parent = card

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "SectionTitle"
		titleLabel.Position = UDim2.fromOffset(12, 10)
		titleLabel.Size = UDim2.new(1, -24, 0, 16)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 11
		titleLabel.TextColor3 = tint:Lerp(Color3.fromRGB(244, 244, 238), 0.18)
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.Text = title
		titleLabel.Parent = card

		local bodyLabel = Instance.new("TextLabel")
		bodyLabel.Name = "BodyLabel"
		bodyLabel.Position = UDim2.fromOffset(12, 30)
		bodyLabel.Size = UDim2.new(1, -24, 1, -40)
		bodyLabel.BackgroundTransparency = 1
		bodyLabel.Font = Enum.Font.Gotham
		bodyLabel.TextSize = 12
		bodyLabel.TextColor3 = Color3.fromRGB(206, 214, 222)
		bodyLabel.TextWrapped = true
		bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
		bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
		bodyLabel.Text = "-"
		bodyLabel.Parent = card

		return bodyLabel
	end

	local discoveredBody = createSectionCard("DiscoveredSection", "DISCOVERED EVIDENCE", Color3.fromRGB(76, 118, 164))
	local confirmedBody = createSectionCard("ConfirmedSection", "CONFIRMED EVIDENCE", Color3.fromRGB(70, 132, 98))
	local candidateBody = createSectionCard("CandidateSection", "GHOST CANDIDATES", Color3.fromRGB(120, 96, 58))

	window.JournalWidgets = {
		Deck = deck,
		HeroCard = heroCard,
		HeroStroke = heroStroke,
		HeroBadge = heroBadge,
		HeroTitle = heroTitle,
		HeroMeta = heroMeta,
		HeroGlyph = heroGlyph,
		DiscoveredCount = discoveredCount,
		ConfirmedCount = confirmedCount,
		CandidateCount = candidateCount,
		DiscoveredBody = discoveredBody,
		ConfirmedBody = confirmedBody,
		CandidateBody = candidateBody,
	}

	return window.JournalWidgets
end

function UISystem:_refreshJournalPanel()
	local state = self._journalState or {}
	local discovered = state.discoveredEvidence or {}
	local confirmed = state.confirmedEvidence or {}
	local candidates = state.candidates or {}
	local hasConfirmed = #confirmed > 0
	local hasDiscovered = #discovered > 0
	local statusText = hasConfirmed and "CONFIRMED" or (hasDiscovered and "EVIDENCE" or "JOURNAL")
	local badgeColor = hasConfirmed and Color3.fromRGB(58, 116, 90) or Color3.fromRGB(56, 92, 128)
	local glyphText = hasConfirmed and "CF" or (hasDiscovered and "EV" or "JN")
	local primaryText = hasDiscovered
		and string.format("%d evidence tercatat. Gunakan ini untuk deduction cepat.", #discovered)
		or "Belum ada evidence tercatat."
	local secondaryText = string.format(
		"Confirmed %d | Kandidat %d | Event %s",
		#confirmed,
		#candidates,
		tostring(state.lastEvent or "Idle")
	)
	local contentText = table.concat({
		"Discovered Evidence",
		bulletList(discovered, "- Belum ada"),
		"",
		"Confirmed Evidence",
		bulletList(confirmed, "- Belum ada"),
		"",
		"Ghost Candidates",
		bulletList(candidates, "- Belum ada"),
		"",
		"Tool E2E",
		string.format("- Tool: %s", tostring(state.toolType or JOURNAL_TOOL_TYPE)),
		string.format("- Status: %s", tostring(state.toolStatus or "Belum dipakai")),
		string.format("- Detail: %s", tostring(state.toolReason or "-")),
	}, "\n")
	self:_refreshWindowText(
		"JournalUI",
		statusText,
		primaryText,
		secondaryText,
		contentText,
		"Shortcut: J. Gunakan Field Kit atau tombol SCAN JEJAK untuk uji tool investigasi end-to-end. " .. CLOSE_HINT_TEXT .. ".",
		badgeColor
	)

	local function summarizeList(values, emptyText, maxItems)
		if type(values) ~= "table" or #values == 0 then
			return emptyText
		end
		local limit = maxItems or 4
		local rows = {}
		for index, value in ipairs(values) do
			if index > limit then
				break
			end
			rows[#rows + 1] = "• " .. tostring(value)
		end
		if #values > limit then
			rows[#rows + 1] = string.format("+%d lainnya", #values - limit)
		end
		return table.concat(rows, "\n")
	end

	local window = self._uxWidgets and self._uxWidgets.windows and self._uxWidgets.windows.JournalUI
	if window then
		self:_layoutJournalWindow(window)
		local widgets = self:_ensureJournalWidgets(window)
		if widgets then
			widgets.HeroStroke.Color = badgeColor
			widgets.HeroBadge.Text = statusText
			widgets.HeroBadge.BackgroundColor3 = badgeColor
			widgets.HeroTitle.Text = hasConfirmed
				and "Evidence penting sudah terkunci. Saatnya persempit ghost."
				or (hasDiscovered
					and "Catatan evidence aktif. Review cepat sebelum investigasi lanjut."
					or "Belum ada evidence. Gunakan tool dan scan untuk mulai deduction.")
			widgets.HeroMeta.Text = secondaryText
			widgets.HeroGlyph.Text = glyphText
			widgets.HeroGlyph.TextColor3 = badgeColor:Lerp(Color3.fromRGB(244, 244, 238), 0.22)
			widgets.DiscoveredCount.Text = tostring(#discovered)
			widgets.ConfirmedCount.Text = tostring(#confirmed)
			widgets.CandidateCount.Text = tostring(#candidates)
			widgets.DiscoveredBody.Text = summarizeList(discovered, "Belum ada evidence tercatat.", 4)
			widgets.ConfirmedBody.Text = summarizeList(confirmed, "Belum ada evidence confirmed.", 3)
			widgets.CandidateBody.Text = summarizeList(candidates, "Belum ada kandidat ghost.", 4)
		end
	end

	if window and window.ToolStatusLabel then
		local statusLine = string.format(
			"SCAN STATUS\n%s\n%s",
			tostring(state.toolStatus or "Belum dipakai"),
			tostring(state.toolReason or "-")
		)
		window.ToolStatusLabel.Text = statusLine
		window.ToolStatusLabel.BackgroundColor3 = Color3.fromRGB(20, 28, 38)
		window.ToolStatusLabel.BackgroundTransparency = 0.06
		window.ToolStatusLabel.TextColor3 = Color3.fromRGB(196, 206, 220)
	end
	if window and window.ToolActionButton then
		window.ToolActionButton.Text = "SCAN JEJAK"
		window.ToolActionButton.BackgroundColor3 = badgeColor:Lerp(Color3.fromRGB(42, 62, 84), 0.24)
	end
	self:_refreshFieldKitPanel()
end

function UISystem:_ensureProfileWidgets(window)
	if not window or not window.ContentFrame then
		return nil
	end
	if window.ProfileWidgets then
		return window.ProfileWidgets
	end

	if window.ContentText then
		window.ContentText.Visible = false
	end

	local contentFrame = window.ContentFrame
	local deck = contentFrame:FindFirstChild("ProfileDeck")
	if deck and not deck:IsA("Frame") then
		deck:Destroy()
		deck = nil
	end
	if not deck then
		deck = Instance.new("Frame")
		deck.Name = "ProfileDeck"
		deck.Size = UDim2.new(1, -4, 0, 0)
		deck.AutomaticSize = Enum.AutomaticSize.Y
		deck.BackgroundTransparency = 1
		deck.Parent = contentFrame

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Vertical
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 8)
		layout.Parent = deck
	end

	local heroCard = Instance.new("Frame")
	heroCard.Name = "HeroCard"
	heroCard.Size = UDim2.new(1, 0, 0, 122)
	heroCard.BackgroundColor3 = Color3.fromRGB(28, 36, 42)
	heroCard.BorderSizePixel = 0
	heroCard.Parent = deck

	local heroCorner = Instance.new("UICorner")
	heroCorner.CornerRadius = UDim.new(0, 10)
	heroCorner.Parent = heroCard

	local heroStroke = Instance.new("UIStroke")
	heroStroke.Name = "HeroStroke"
	heroStroke.Thickness = 1.5
	heroStroke.Color = Color3.fromRGB(74, 96, 58)
	heroStroke.Transparency = 0.18
	heroStroke.Parent = heroCard

	local avatarGlyph = Instance.new("TextLabel")
	avatarGlyph.Name = "AvatarGlyph"
	avatarGlyph.Position = UDim2.fromOffset(12, 16)
	avatarGlyph.Size = UDim2.fromOffset(58, 58)
	avatarGlyph.BackgroundColor3 = Color3.fromRGB(62, 84, 70)
	avatarGlyph.BorderSizePixel = 0
	avatarGlyph.Font = Enum.Font.GothamBold
	avatarGlyph.TextSize = 24
	avatarGlyph.TextColor3 = Color3.fromRGB(244, 244, 238)
	avatarGlyph.Text = "P"
	avatarGlyph.Parent = heroCard

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(1, 0)
	avatarCorner.Parent = avatarGlyph

	local profileTitle = Instance.new("TextLabel")
	profileTitle.Name = "ProfileTitle"
	profileTitle.Position = UDim2.fromOffset(82, 16)
	profileTitle.Size = UDim2.new(1, -94, 0, 24)
	profileTitle.BackgroundTransparency = 1
	profileTitle.Font = Enum.Font.GothamBold
	profileTitle.TextSize = 18
	profileTitle.TextColor3 = Color3.fromRGB(244, 244, 238)
	profileTitle.TextXAlignment = Enum.TextXAlignment.Left
	profileTitle.Text = "PLAYER"
	profileTitle.Parent = heroCard

	local profileMeta = Instance.new("TextLabel")
	profileMeta.Name = "ProfileMeta"
	profileMeta.Position = UDim2.fromOffset(82, 42)
	profileMeta.Size = UDim2.new(1, -94, 0, 18)
	profileMeta.BackgroundTransparency = 1
	profileMeta.Font = Enum.Font.Gotham
	profileMeta.TextSize = 12
	profileMeta.TextColor3 = Color3.fromRGB(188, 199, 212)
	profileMeta.TextXAlignment = Enum.TextXAlignment.Left
	profileMeta.Text = "Rank • Level • Input"
	profileMeta.Parent = heroCard

	local statusPill = Instance.new("TextLabel")
	statusPill.Name = "StatusPill"
	statusPill.Position = UDim2.fromOffset(82, 66)
	statusPill.Size = UDim2.fromOffset(122, 18)
	statusPill.BackgroundColor3 = Color3.fromRGB(74, 96, 58)
	statusPill.BorderSizePixel = 0
	statusPill.Font = Enum.Font.GothamBold
	statusPill.TextSize = 9
	statusPill.TextColor3 = Color3.fromRGB(244, 244, 238)
	statusPill.Text = "SAFE"
	statusPill.Parent = heroCard

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(1, 0)
	statusCorner.Parent = statusPill

	local spotlight = Instance.new("TextLabel")
	spotlight.Name = "Spotlight"
	spotlight.Position = UDim2.fromOffset(12, 88)
	spotlight.Size = UDim2.new(1, -24, 0, 24)
	spotlight.BackgroundTransparency = 1
	spotlight.Font = Enum.Font.Gotham
	spotlight.TextSize = 11
	spotlight.TextColor3 = Color3.fromRGB(182, 194, 206)
	spotlight.TextXAlignment = Enum.TextXAlignment.Left
	spotlight.TextWrapped = true
	spotlight.Text = "Spotlight belum tersedia."
	spotlight.Parent = heroCard

	local actionButton = Instance.new("TextButton")
	actionButton.Name = "ActionButton"
	actionButton.AnchorPoint = Vector2.new(1, 0)
	actionButton.Position = UDim2.new(1, -12, 0, 16)
	actionButton.Size = UDim2.fromOffset(108, 30)
	styleButton(actionButton, "OPEN ROOMS")
	actionButton.BackgroundColor3 = Color3.fromRGB(58, 86, 122)
	actionButton.TextColor3 = Color3.fromRGB(245, 245, 240)
	actionButton.Parent = heroCard

	local actionCorner = Instance.new("UICorner")
	actionCorner.CornerRadius = UDim.new(0, 8)
	actionCorner.Parent = actionButton
	self:_setSelectableStyle(actionButton)

	local statList = Instance.new("Frame")
	statList.Name = "StatList"
	statList.Size = UDim2.new(1, 0, 0, 0)
	statList.AutomaticSize = Enum.AutomaticSize.Y
	statList.BackgroundTransparency = 1
	statList.Parent = deck

	local statLayout = Instance.new("UIListLayout")
	statLayout.FillDirection = Enum.FillDirection.Vertical
	statLayout.SortOrder = Enum.SortOrder.LayoutOrder
	statLayout.Padding = UDim.new(0, 6)
	statLayout.Parent = statList

	local wardrobeHeader = Instance.new("TextLabel")
	wardrobeHeader.Name = "WardrobeHeader"
	wardrobeHeader.Size = UDim2.new(1, 0, 0, 18)
	wardrobeHeader.BackgroundTransparency = 1
	wardrobeHeader.Font = Enum.Font.GothamBold
	wardrobeHeader.TextSize = 11
	wardrobeHeader.TextColor3 = Color3.fromRGB(214, 222, 232)
	wardrobeHeader.TextXAlignment = Enum.TextXAlignment.Left
	wardrobeHeader.Text = "WARDROBE"
	wardrobeHeader.Parent = deck

	local wardrobeEmpty = Instance.new("TextLabel")
	wardrobeEmpty.Name = "WardrobeEmpty"
	wardrobeEmpty.Size = UDim2.new(1, 0, 0, 38)
	wardrobeEmpty.BackgroundColor3 = Color3.fromRGB(23, 29, 39)
	wardrobeEmpty.BackgroundTransparency = 0.08
	wardrobeEmpty.BorderSizePixel = 0
	wardrobeEmpty.Font = Enum.Font.Gotham
	wardrobeEmpty.TextSize = 11
	wardrobeEmpty.TextColor3 = Color3.fromRGB(184, 196, 208)
	wardrobeEmpty.TextWrapped = true
	wardrobeEmpty.Text = "Belum ada cosmetic yang dimiliki. Beli cosmetic di Shop lalu pakai dari sini."
	wardrobeEmpty.Parent = deck

	local wardrobeEmptyCorner = Instance.new("UICorner")
	wardrobeEmptyCorner.CornerRadius = UDim.new(0, 8)
	wardrobeEmptyCorner.Parent = wardrobeEmpty

	local wardrobeList = Instance.new("Frame")
	wardrobeList.Name = "WardrobeList"
	wardrobeList.Size = UDim2.new(1, 0, 0, 0)
	wardrobeList.AutomaticSize = Enum.AutomaticSize.Y
	wardrobeList.BackgroundTransparency = 1
	wardrobeList.Parent = deck

	local wardrobeLayout = Instance.new("UIListLayout")
	wardrobeLayout.FillDirection = Enum.FillDirection.Vertical
	wardrobeLayout.SortOrder = Enum.SortOrder.LayoutOrder
	wardrobeLayout.Padding = UDim.new(0, 6)
	wardrobeLayout.Parent = wardrobeList

	local rows = {
		sanity = createActionRow(statList, "SanityRow", "SANITY", "-", "LIVE"),
		match = createActionRow(statList, "MatchRow", "MATCH", "-", "STAT"),
		favorite = createActionRow(statList, "FavoriteRow", "TOOL", "-", "LOAD"),
	}
	for _, row in pairs(rows) do
		row.Button.Active = false
		row.Button.AutoButtonColor = false
		row.Button.Selectable = false
	end

	if actionButton:GetAttribute("Bound") ~= true then
		actionButton:SetAttribute("Bound", true)
		connectButtonPress(actionButton, function()
			self:_toggleRoomBrowserVisible()
		end)
	end

	window.ProfileWidgets = {
		Deck = deck,
		HeroCard = heroCard,
		HeroStroke = heroStroke,
		AvatarGlyph = avatarGlyph,
		ProfileTitle = profileTitle,
		ProfileMeta = profileMeta,
		StatusPill = statusPill,
		Spotlight = spotlight,
		ActionButton = actionButton,
		Rows = rows,
		WardrobeHeader = wardrobeHeader,
		WardrobeEmpty = wardrobeEmpty,
		WardrobeList = wardrobeList,
		WardrobeRows = {},
	}
	return window.ProfileWidgets
end

function UISystem:_applyCosmeticSnapshot(snapshot)
	if type(snapshot) ~= "table" then
		return
	end
	self._profileState.ownedCosmeticIds = buildOwnedItemLookup(snapshot.ownedCosmeticIds)
	self._profileState.equippedCosmetics = type(snapshot.equippedCosmetics) == "table" and snapshot.equippedCosmetics or {}
	self._profileState.lastCosmeticSnapshotAt = tick()
end

function UISystem:_requestCosmeticSnapshot(force)
	local remote = self._remotes and self._remotes.CosmeticEvent or nil
	if not remote then
		return false
	end
	local now = tick()
	if force ~= true and (now - (self._profileState.lastCosmeticRequestAt or 0)) < 0.4 then
		return false
	end
	self._profileState.lastCosmeticRequestAt = now
	remote:FireServer({
		action = "RequestSnapshot",
	})
	return true
end

function UISystem:_requestEquipCosmetic(cosmeticId)
	local remote = self._remotes and self._remotes.CosmeticEvent or nil
	if not remote or type(cosmeticId) ~= "string" or cosmeticId == "" then
		return
	end
	self._profileState.lastCosmeticMessage = "Mengirim equip cosmetic..."
	remote:FireServer({
		action = "EquipCosmetic",
		cosmeticId = cosmeticId,
	})
end

function UISystem:_requestUnequipCosmetic(slot)
	local remote = self._remotes and self._remotes.CosmeticEvent or nil
	if not remote or type(slot) ~= "string" or slot == "" then
		return
	end
	self._profileState.lastCosmeticMessage = "Melepas cosmetic dari slot..."
	remote:FireServer({
		action = "UnequipCosmetic",
		cosmeticSlot = slot,
	})
end

function UISystem:_getOwnedCosmeticCatalogEntries()
	local ownedLookup = self._profileState and self._profileState.ownedCosmeticIds or {}
	local ownedItems = {}
	for _, item in ipairs(self._shopState and self._shopState.catalog or {}) do
		if type(item) == "table" and item.category == "Cosmetic" and ownedLookup[item.id] then
			table.insert(ownedItems, item)
		end
	end
	return ownedItems
end

function UISystem:_ensureProfileWardrobeRow(widgets, index)
	if not widgets or not widgets.WardrobeList then
		return nil
	end
	widgets.WardrobeRows = widgets.WardrobeRows or {}
	local existing = widgets.WardrobeRows[index]
	if existing and existing.Root and existing.Root.Parent then
		return existing
	end

	local row = createActionRow(widgets.WardrobeList, "WardrobeRow" .. tostring(index), "COSMETIC", "-", "PAKAI")
	row.Button.Size = UDim2.fromOffset(92, 32)
	row.PricePill.Size = UDim2.fromOffset(110, 16)
	row.Root:SetAttribute("CosmeticRowBound", true)
	if row.Button:GetAttribute("Bound") ~= true then
		row.Button:SetAttribute("Bound", true)
		connectButtonPress(row.Button, function()
			local cosmeticId = row.Root:GetAttribute("CosmeticId")
			local cosmeticSlot = row.Root:GetAttribute("CosmeticSlot")
			if type(cosmeticId) ~= "string" or cosmeticId == "" then
				return
			end
			local equipped = self._profileState and self._profileState.equippedCosmetics or {}
			if type(cosmeticSlot) == "string" and tostring(equipped[cosmeticSlot] or "") == cosmeticId then
				self:_requestUnequipCosmetic(cosmeticSlot)
			else
				self:_requestEquipCosmetic(cosmeticId)
			end
		end)
	end

	widgets.WardrobeRows[index] = row
	return row
end

function UISystem:_refreshProfileWardrobe(widgets)
	if not widgets or not widgets.WardrobeList then
		return
	end

	local ownedItems = self:_getOwnedCosmeticCatalogEntries()
	local equipped = self._profileState and self._profileState.equippedCosmetics or {}
	local ownedCount = #ownedItems
	local equippedCount = countLookupEntries(equipped)

	if widgets.WardrobeHeader then
		widgets.WardrobeHeader.Text = string.format("WARDROBE • %d OWNED • %d EQUIPPED", ownedCount, equippedCount)
	end
	if widgets.WardrobeEmpty then
		widgets.WardrobeEmpty.Visible = ownedCount == 0
	end
	if widgets.WardrobeList then
		widgets.WardrobeList.Visible = ownedCount > 0
	end

	for index, item in ipairs(ownedItems) do
		local row = self:_ensureProfileWardrobeRow(widgets, index)
		if row then
			local theme = resolveShopCategoryTheme(item)
			local accent = SHOP_RARITY_COLORS[tostring(item.rarity or "")] or theme.accent
			local slot = tostring(item.slot or "cosmetic")
			local isEquipped = tostring(equipped[slot] or "") == tostring(item.id)
			row.Root.Visible = true
			row.Root.LayoutOrder = index
			row.Root.BackgroundColor3 = Color3.fromRGB(23, 29, 39)
			row.Root:SetAttribute("CosmeticId", item.id)
			row.Root:SetAttribute("CosmeticSlot", slot)
			row.Accent.BackgroundColor3 = accent
			row.Preview.BackgroundColor3 = theme.preview
			row.PreviewBadge.BackgroundColor3 = theme.accent
			row.PreviewBadge.TextColor3 = theme.text
			row.PreviewBadge.Text = buildShopItemBadge(item)
			row.PreviewGlyph.TextColor3 = theme.text
			row.PreviewGlyph.Text = buildShopItemGlyph(item)
			row.Title.Text = tostring(item.name or item.id or ("Cosmetic " .. tostring(index)))
			row.Meta.Text = string.format(
				"%s • Slot %s • %s",
				buildShopItemMeta(item),
				string.upper(humanizeToken(slot)),
				isEquipped and "Equipped" or "Ready"
			)
			applyPricePillVisual(row.PricePill, isEquipped and "AKTIF" or string.upper(humanizeToken(slot)), accent, Color3.fromRGB(247, 243, 236))
			row.Button.Text = isEquipped and "LEPAS" or "PAKAI"
			row.Button.BackgroundColor3 = isEquipped and Color3.fromRGB(88, 70, 44) or theme.accent
			row.Button.TextColor3 = isEquipped and Color3.fromRGB(245, 234, 206) or Color3.fromRGB(244, 244, 240)
			row.Button.AutoButtonColor = true
		end
	end

	for index = ownedCount + 1, #(widgets.WardrobeRows or {}) do
		local row = widgets.WardrobeRows[index]
		if row and row.Root then
			row.Root.Visible = false
			row.Root:SetAttribute("CosmeticId", nil)
			row.Root:SetAttribute("CosmeticSlot", nil)
		end
	end
end

function UISystem:_refreshProfilePanel()
	local player = Players.LocalPlayer
	local profile = self._profileState or {}
	local playerName = player and (player.DisplayName or player.Name) or "Player"
	local sanity = math.floor(tonumber(profile.sanity or 100) or 100)
	local statusToken = tostring(profile.status or "safe")
	local badgeText = string.upper(statusToken:gsub("_", " "))
	local badgeColor = Color3.fromRGB(74, 96, 58)
	if statusToken == "hunt_risk" then
		badgeColor = Color3.fromRGB(124, 56, 56)
	elseif statusToken == "high_paranormal_activity" then
		badgeColor = Color3.fromRGB(126, 84, 48)
	elseif statusToken == "unstable" then
		badgeColor = Color3.fromRGB(82, 94, 126)
	end

	local contentLines = {
		string.format("Player: %s", playerName),
		string.format("UserId: %s", tostring(player and player.UserId or "-")),
		string.format("Level: %s", tostring(profile.level or 1)),
		string.format("Rank: %s", tostring(profile.rank or "Bayi III")),
		string.format("Sanity: %d", sanity),
		string.format("Total Match: %s", tostring(profile.totalGames or 0)),
		string.format("Favorite Tool: %s", tostring(profile.favoriteTool or "-")),
		string.format("Input: %s", tostring(self:GetInputType())),
		string.format("Last Event: %s", tostring(profile.lastEvent or "Idle")),
	}

	local featuredFlex = profile.featuredFlex
	if type(featuredFlex) == "table" then
		table.insert(contentLines, string.format("Flex Spotlight: %s", tostring(featuredFlex.displayName or "Player")))
		table.insert(contentLines, string.format("Spotlight Rank: %s | Lv %s", tostring(featuredFlex.rank or "Bayi III"), tostring(featuredFlex.level or 1)))
		table.insert(contentLines, string.format("Spotlight WR: %s%% | Match: %s", tostring(featuredFlex.winRate or 0), tostring(featuredFlex.totalMatches or 0)))
		table.insert(contentLines, string.format("Spotlight Show: %s", tostring(featuredFlex.showcaseSummary or formatJoinedValues(featuredFlex.featuredNames, "-"))))
		table.insert(contentLines, string.format("Flex Visitors: %s", tostring(featuredFlex.activeVisitorCount or 0)))
	end

	self:_refreshWindowText(
		"ProfileUI",
		badgeText,
		string.format("%s | Lv %s", playerName, tostring(profile.level or 1)),
		string.format("Rank %s | Sanity %d", tostring(profile.rank or "Bayi III"), sanity),
		nil,
		"Profile basic ini menampilkan data client yang tersedia tanpa asumsi server tambahan.",
		badgeColor
	)

	local window = self._uxWidgets and self._uxWidgets.windows and self._uxWidgets.windows.ProfileUI
	local widgets = self:_ensureProfileWidgets(window)
	if not widgets then
		return
	end

	local heroAccent = badgeColor
	widgets.HeroStroke.Color = heroAccent
	widgets.AvatarGlyph.BackgroundColor3 = heroAccent
	widgets.AvatarGlyph.Text = string.upper(string.sub(playerName, 1, 1))
	widgets.ProfileTitle.Text = string.format("%s  •  LV %s", playerName, tostring(profile.level or 1))
	widgets.ProfileMeta.Text = string.format(
		"%s • %s • %s",
		tostring(profile.rank or "Bayi III"),
		tostring(self:GetInputType()),
		tostring(player and player.UserId or "-")
	)
	widgets.StatusPill.BackgroundColor3 = heroAccent
	widgets.StatusPill.Text = badgeText
	widgets.Spotlight.Text = featuredFlex and string.format(
		"Spotlight %s • WR %s%% • %s match",
		tostring(featuredFlex.displayName or "Player"),
		tostring(featuredFlex.winRate or 0),
		tostring(featuredFlex.totalMatches or 0)
	) or tostring(profile.lastCosmeticMessage or "Belum ada spotlight. Profile ini memakai snapshot client yang aktif.")

	local rows = widgets.Rows or {}
	local statRows = {
		{
			key = "sanity",
			badge = "MIND",
			glyph = "SN",
			title = "Sanity monitor",
			meta = string.format("Status %s • event %s", titleCaseToken(statusToken), tostring(profile.lastEvent or "Idle")),
			pill = string.format("%d%%", sanity),
			button = sanity <= 35 and "RISK" or "SAFE",
			accent = sanity <= 35 and Color3.fromRGB(126, 72, 72) or heroAccent,
			preview = sanity <= 35 and Color3.fromRGB(62, 42, 42) or Color3.fromRGB(42, 56, 46),
		},
		{
			key = "match",
			badge = "RUN",
			glyph = "MM",
			title = "Match footprint",
			meta = string.format("Rank %s • input %s", tostring(profile.rank or "Bayi III"), tostring(self:GetInputType())),
			pill = string.format("%s GAME", tostring(profile.totalGames or 0)),
			button = "LIVE",
			accent = Color3.fromRGB(76, 96, 126),
			preview = Color3.fromRGB(40, 52, 68),
		},
		{
			key = "favorite",
			badge = "TOOL",
			glyph = "WR",
			title = "Wardrobe sync",
			meta = string.format(
				"%s • visitors %s",
				tostring(profile.lastCosmeticMessage or "Wardrobe belum sinkron."),
				tostring(featuredFlex and featuredFlex.activeVisitorCount or 0)
			),
			pill = string.format("%d OWNED", countLookupEntries(profile.ownedCosmeticIds)),
			button = string.format("%d EQ", countLookupEntries(profile.equippedCosmetics)),
			accent = Color3.fromRGB(118, 88, 52),
			preview = Color3.fromRGB(54, 44, 32),
		},
	}

	for _, data in ipairs(statRows) do
		local row = rows[data.key]
		if row then
			row.Root.BackgroundColor3 = Color3.fromRGB(23, 29, 39)
			row.Accent.BackgroundColor3 = data.accent
			row.Preview.BackgroundColor3 = data.preview
			row.PreviewBadge.BackgroundColor3 = data.accent
			row.PreviewBadge.TextColor3 = Color3.fromRGB(247, 243, 236)
			row.PreviewBadge.Text = data.badge
			row.PreviewGlyph.TextColor3 = Color3.fromRGB(247, 243, 236)
			row.PreviewGlyph.Text = data.glyph
			row.Title.Text = data.title
			row.Meta.Text = data.meta
			applyPricePillVisual(row.PricePill, data.pill, data.accent, Color3.fromRGB(247, 243, 236))
			row.Button.BackgroundColor3 = data.preview
			row.Button.TextColor3 = Color3.fromRGB(242, 241, 236)
			row.Button.Text = data.button
		end
	end

	self:_refreshProfileWardrobe(widgets)
end

function UISystem:_applyShopSnapshot(snapshot)
	if type(snapshot) ~= "table" then
		return
	end

	local wallet = type(snapshot.wallet) == "table" and snapshot.wallet or {}
	self._shopState.wallet = {
		MM = math.max(0, math.floor(tonumber(wallet.MM) or 0)),
		PP = math.max(0, math.floor(tonumber(wallet.PP) or 0)),
		Robux = math.max(0, math.floor(tonumber(wallet.Robux) or 0)),
	}
	self._shopState.ownedItemIds = buildOwnedItemLookup(snapshot.ownedItemIds)
	self._shopState.lastSnapshotAt = tick()
	self:_refreshShopPanel()
end

function UISystem:_requestShopSnapshot(force)
	local remote = self._remotes and self._remotes.PurchaseEvent or nil
	if not remote then
		return
	end

	local now = tick()
	if force ~= true and (now - (self._shopState.lastSnapshotRequestedAt or 0)) < 1.2 then
		return
	end

	local player = Players.LocalPlayer
	self._shopRequestSeq += 1
	self._shopState.lastSnapshotRequestedAt = now
	remote:FireServer({
		action = "RequestSnapshot",
		requestId = string.format(
			"shop-snapshot:%s:%d",
			tostring(player and player.UserId or 0),
			self._shopRequestSeq
		),
	})
end

function UISystem:_getShopCurrencyBalance(currency)
	local wallet = self._shopState and self._shopState.wallet or nil
	if type(wallet) ~= "table" then
		return 0
	end
	local key = tostring(currency or "MM")
	if key == "RBX" then
		key = "Robux"
	end
	return math.max(0, math.floor(tonumber(wallet[key]) or 0))
end

function UISystem:_isShopItemOwned(item)
	local itemId = type(item) == "table" and tostring(item.id or "") or ""
	if itemId == "" then
		return false
	end
	return self._shopState
		and type(self._shopState.ownedItemIds) == "table"
		and self._shopState.ownedItemIds[itemId] == true
end

function UISystem:_getShopItemPurchaseAvailability(item)
	if self:_isShopItemOwned(item) then
		return false, "already_owned"
	end

	local purchasable, blockedReason = isShopItemPurchasable(item)
	if not purchasable then
		return false, blockedReason
	end

	local currency = tostring(item and item.currency or "MM")
	if currency ~= "Robux" and self:_getShopCurrencyBalance(currency) < math.max(0, math.floor(tonumber(item and item.price) or 0)) then
		return false, "insufficient_currency"
	end

	return true, nil
end

function UISystem:_shopItemMatchesFilter(item)
	local filterKey = tostring(self._shopState and self._shopState.filterKey or "All")
	if filterKey == "All" then
		return true
	end
	if filterKey == "Owned" then
		return self:_isShopItemOwned(item)
	end

	local currency = tostring(item and item.currency or "MM")
	if currency == "RBX" then
		currency = "Robux"
	end
	return currency == filterKey
end

function UISystem:_setShopFilter(filterKey)
	self._shopState.filterKey = tostring(filterKey or "All")
	self:_refreshShopPanel()
end

function UISystem:_requestShopPurchase(itemId)
	local remote = self._remotes and self._remotes.PurchaseEvent or nil
	if not remote or not itemId then
		return
	end

	local player = Players.LocalPlayer
	self._shopRequestSeq += 1
	local requestId = string.format(
		"shop:%s:%d",
		tostring(player and player.UserId or 0),
		self._shopRequestSeq
	)
	self._shopState.lastMessage = "Mengirim request pembelian untuk " .. tostring(itemId) .. "..."
	self._shopState.lastPurchase = {
		itemId = itemId,
		success = nil,
		reason = "pending",
		requestId = requestId,
	}
	remote:FireServer({
		action = "PurchaseItem",
		itemId = itemId,
		requestId = requestId,
	})
	self:_openAuxiliaryWindow("ShopUI")
end

function UISystem:_applyShopRowVisual(row, item, index)
	if type(row) ~= "table" then
		return
	end

	local theme = resolveShopCategoryTheme(item)
	local rarityColor = SHOP_RARITY_COLORS[tostring(item and item.rarity or "")] or theme.accent
	local currency = tostring(item and item.currency or "MM")
	local currencyTheme = resolveShopCurrencyTheme(currency)
	local purchasable, blockedReason = self:_getShopItemPurchaseAvailability(item)
	local owned = self:_isShopItemOwned(item)
	local walletBalance = self:_getShopCurrencyBalance(currency)

	if row.Root then
		row.Root.BackgroundColor3 = theme.background
	end
	if row.Accent then
		row.Accent.BackgroundColor3 = rarityColor
	end
	if row.Preview then
		row.Preview.BackgroundColor3 = theme.preview
	end
	if row.PreviewBadge then
		row.PreviewBadge.BackgroundColor3 = theme.accent
		row.PreviewBadge.TextColor3 = theme.text
		row.PreviewBadge.Text = buildShopItemBadge(item)
	end
	if row.PreviewGlyph then
		row.PreviewGlyph.TextColor3 = theme.text
		row.PreviewGlyph.Text = buildShopItemGlyph(item)
	end
	if row.Title then
		row.Title.Text = item and tostring(item.name or item.id or ("Item " .. tostring(index))) or ("Item " .. tostring(index))
	end
	if row.Meta then
		local metaText = buildShopItemMeta(item)
		if owned then
			metaText = string.format("%s • Owned", tostring(metaText))
		elseif currency ~= "Robux" then
			metaText = string.format("%s • Wallet %d %s", tostring(metaText), walletBalance, currency)
		end
		row.Meta.Text = metaText
	end
	if row.PricePill then
		applyPricePillVisual(
			row.PricePill,
			string.format("%s %s", tostring(item and item.price or 0), currency),
			currencyTheme.background,
			currencyTheme.text
		)
	end
	if row.Button then
		row.Button.AutoButtonColor = purchasable == true
		row.Button:SetAttribute("ShopPurchasable", purchasable == true)
		row.Button:SetAttribute("ShopDisabledReason", blockedReason or "")
		if owned then
			row.Button.Text = "OWNED"
			row.Button.BackgroundColor3 = Color3.fromRGB(62, 98, 80)
			row.Button.TextColor3 = Color3.fromRGB(235, 245, 240)
		elseif purchasable == true then
			row.Button.Text = "BELI"
			row.Button.BackgroundColor3 = theme.accent
			row.Button.TextColor3 = Color3.fromRGB(245, 245, 245)
		elseif blockedReason == "insufficient_currency" then
			row.Button.Text = "KURANG"
			row.Button.BackgroundColor3 = Color3.fromRGB(86, 70, 44)
			row.Button.TextColor3 = Color3.fromRGB(242, 232, 204)
		elseif blockedReason == "marketplace_id_missing" then
			row.Button.Text = "SETUP"
			row.Button.BackgroundColor3 = Color3.fromRGB(78, 72, 48)
			row.Button.TextColor3 = Color3.fromRGB(238, 230, 192)
		else
			row.Button.Text = "LOCK"
			row.Button.BackgroundColor3 = Color3.fromRGB(70, 70, 78)
			row.Button.TextColor3 = Color3.fromRGB(216, 216, 224)
		end
	end
end

function UISystem:_refreshShopPanel()
	local window = self._uxWidgets and self._uxWidgets.windows and self._uxWidgets.windows.ShopUI
	if not window then
		return
	end

	local lastPurchase = self._shopState.lastPurchase
	local statusText = "STORE"
	local badgeColor = Color3.fromRGB(124, 92, 48)
	local secondaryText = self._shopState.lastMessage or "Pilih item untuk test shop."
	local walletSummary = formatShopWalletSummary(self._shopState.wallet)
	local ownedCount = 0
	for _ in pairs(self._shopState.ownedItemIds or {}) do
		ownedCount += 1
	end
	if lastPurchase and lastPurchase.success == true then
		statusText = "PURCHASE OK"
		badgeColor = Color3.fromRGB(58, 116, 90)
		secondaryText = string.format("Pembelian %s berhasil.", tostring(lastPurchase.itemId or "-"))
	elseif lastPurchase and lastPurchase.success == false then
		statusText = "PURCHASE FAIL"
		badgeColor = Color3.fromRGB(124, 56, 56)
		secondaryText = string.format(
			"%s gagal: %s",
			tostring(lastPurchase.itemId or "-"),
			titleCaseToken(lastPurchase.reason or "unknown")
		)
	elseif lastPurchase and lastPurchase.reason == "pending" then
		statusText = "PROCESSING"
		badgeColor = Color3.fromRGB(82, 94, 126)
	elseif lastPurchase and lastPurchase.reason == "prompting" then
		statusText = "PROMPT"
		badgeColor = Color3.fromRGB(82, 94, 126)
	end

	self:_refreshWindowText(
		"ShopUI",
		statusText,
		walletSummary,
		secondaryText,
		nil,
		string.format(
			"Owned %d item. Klik BELI untuk item aktif. Label KURANG berarti saldo belum cukup, SETUP berarti item Robux belum compliant atau marketplaceId belum diisi di Creator Hub.",
			ownedCount
		),
		badgeColor
	)

	if type(window.ShopFilterButtons) == "table" then
		local activeFilter = tostring(self._shopState.filterKey or "All")
		for _, filter in ipairs(SHOP_FILTERS) do
			local button = window.ShopFilterButtons[filter.key]
			if button then
				local selected = activeFilter == filter.key
				button.BackgroundColor3 = selected and Color3.fromRGB(92, 118, 156) or Color3.fromRGB(42, 54, 72)
				button.TextColor3 = selected and Color3.fromRGB(248, 248, 244) or Color3.fromRGB(224, 232, 240)
			end
		end
	end

	if window.ItemRows and type(window.ItemRows) == "table" then
		for index, row in ipairs(window.ItemRows) do
			local item = self._shopState.catalog[index]
			if row.Root then
				row.Root.Visible = item ~= nil and self:_shopItemMatchesFilter(item)
			end
			if item and self:_shopItemMatchesFilter(item) then
				self:_applyShopRowVisual(row, item, index)
			end
		end
	end
end

function UISystem:_applyRoyalPassSnapshot(snapshot)
	if type(snapshot) ~= "table" then
		return
	end

	local state = self._royalPassState or {}
	state.seasonId = tostring(snapshot.seasonId or state.seasonId or "S1")
	state.totalXP = math.max(0, math.floor(tonumber(snapshot.totalXP) or state.totalXP or 0))
	state.currentTier = math.max(1, math.floor(tonumber(snapshot.currentTier) or state.currentTier or 1))
	state.maxTier = math.max(state.currentTier, math.floor(tonumber(snapshot.maxTier) or state.maxTier or 50))
	state.xpPerTier = math.max(1, math.floor(tonumber(snapshot.xpPerTier) or state.xpPerTier or 200))
	state.currentTierXP = math.clamp(
		math.floor(tonumber(snapshot.currentTierXP) or state.currentTierXP or 0),
		0,
		state.xpPerTier
	)
	state.remainingXP = math.max(0, math.floor(tonumber(snapshot.remainingXP) or state.remainingXP or 0))
	state.progressPercent = math.clamp(
		tonumber(snapshot.progressPercent) or (state.xpPerTier > 0 and (state.currentTierXP / state.xpPerTier) or 0),
		0,
		1
	)
	state.premiumOwned = snapshot.premiumOwned == true
	state.nextTier = snapshot.nextTier and math.max(1, math.floor(tonumber(snapshot.nextTier) or state.nextTier or (state.currentTier + 1)))
		or nil

	local unlockedTiers = {}
	if type(snapshot.unlockedTiers) == "table" then
		for _, tierValue in ipairs(snapshot.unlockedTiers) do
			local numericTier = tonumber(tierValue)
			if numericTier and numericTier >= 1 then
				table.insert(unlockedTiers, math.floor(numericTier))
			end
		end
		table.sort(unlockedTiers)
	end
	state.unlockedTiers = unlockedTiers
	state.unlockedTierCount = math.max(0, math.floor(tonumber(snapshot.unlockedTierCount) or #unlockedTiers))

	if type(snapshot.nextReward) == "table" then
		state.nextReward = {
			currency = math.max(0, math.floor(tonumber(snapshot.nextReward.currency) or 0)),
			xp = math.max(0, math.floor(tonumber(snapshot.nextReward.xp) or 0)),
		}
	else
		state.nextReward = nil
	end

	self._royalPassState = state
end

function UISystem:_ensureRoyalPassWidgets(window)
	if not window or not window.ContentFrame then
		return nil
	end
	if window.RoyalPassWidgets then
		return window.RoyalPassWidgets
	end

	if window.ContentText then
		window.ContentText.Visible = false
	end

	local contentFrame = window.ContentFrame
	local deck = contentFrame:FindFirstChild("RoyalPassDeck")
	if deck and not deck:IsA("Frame") then
		deck:Destroy()
		deck = nil
	end
	if not deck then
		deck = Instance.new("Frame")
		deck.Name = "RoyalPassDeck"
		deck.Size = UDim2.new(1, -4, 0, 0)
		deck.AutomaticSize = Enum.AutomaticSize.Y
		deck.BackgroundTransparency = 1
		deck.Parent = contentFrame

		local deckLayout = Instance.new("UIListLayout")
		deckLayout.FillDirection = Enum.FillDirection.Vertical
		deckLayout.SortOrder = Enum.SortOrder.LayoutOrder
		deckLayout.Padding = UDim.new(0, 8)
		deckLayout.Parent = deck
	end

	local heroCard = Instance.new("Frame")
	heroCard.Name = "HeroCard"
	heroCard.LayoutOrder = 1
	heroCard.Size = UDim2.new(1, 0, 0, 130)
	heroCard.BackgroundColor3 = Color3.fromRGB(30, 37, 48)
	heroCard.BorderSizePixel = 0
	heroCard.Parent = deck
	local heroCorner = Instance.new("UICorner")
	heroCorner.CornerRadius = UDim.new(0, 10)
	heroCorner.Parent = heroCard

	local heroStroke = Instance.new("UIStroke")
	heroStroke.Name = "HeroStroke"
	heroStroke.Thickness = 1.5
	heroStroke.Color = Color3.fromRGB(126, 102, 58)
	heroStroke.Transparency = 0.18
	heroStroke.Parent = heroCard

	local heroBadge = Instance.new("TextLabel")
	heroBadge.Name = "HeroBadge"
	heroBadge.Position = UDim2.fromOffset(12, 12)
	heroBadge.Size = UDim2.fromOffset(112, 20)
	heroBadge.BackgroundColor3 = Color3.fromRGB(116, 88, 44)
	heroBadge.BorderSizePixel = 0
	heroBadge.Font = Enum.Font.GothamBold
	heroBadge.TextSize = 10
	heroBadge.TextColor3 = Color3.fromRGB(248, 242, 230)
	heroBadge.Text = "FREE TRACK"
	heroBadge.Parent = heroCard
	local heroBadgeCorner = Instance.new("UICorner")
	heroBadgeCorner.CornerRadius = UDim.new(1, 0)
	heroBadgeCorner.Parent = heroBadge

	local heroTitle = Instance.new("TextLabel")
	heroTitle.Name = "HeroTitle"
	heroTitle.Position = UDim2.fromOffset(12, 38)
	heroTitle.Size = UDim2.new(1, -24, 0, 24)
	heroTitle.BackgroundTransparency = 1
	heroTitle.Font = Enum.Font.GothamBold
	heroTitle.TextSize = 20
	heroTitle.TextXAlignment = Enum.TextXAlignment.Left
	heroTitle.TextColor3 = Color3.fromRGB(245, 240, 232)
	heroTitle.Text = "SEASON S1"
	heroTitle.Parent = heroCard

	local heroMeta = Instance.new("TextLabel")
	heroMeta.Name = "HeroMeta"
	heroMeta.Position = UDim2.fromOffset(12, 62)
	heroMeta.Size = UDim2.new(1, -24, 0, 18)
	heroMeta.BackgroundTransparency = 1
	heroMeta.Font = Enum.Font.Gotham
	heroMeta.TextSize = 12
	heroMeta.TextXAlignment = Enum.TextXAlignment.Left
	heroMeta.TextColor3 = Color3.fromRGB(194, 203, 216)
	heroMeta.Text = "Progress"
	heroMeta.Parent = heroCard

	local progressTrack = Instance.new("Frame")
	progressTrack.Name = "ProgressTrack"
	progressTrack.Position = UDim2.fromOffset(12, 86)
	progressTrack.Size = UDim2.new(1, -24, 0, 14)
	progressTrack.BackgroundColor3 = Color3.fromRGB(38, 46, 58)
	progressTrack.BorderSizePixel = 0
	progressTrack.Parent = heroCard
	local progressTrackCorner = Instance.new("UICorner")
	progressTrackCorner.CornerRadius = UDim.new(1, 0)
	progressTrackCorner.Parent = progressTrack

	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.fromScale(0.1, 1)
	progressFill.BackgroundColor3 = Color3.fromRGB(212, 168, 92)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressTrack
	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(1, 0)
	progressFillCorner.Parent = progressFill

	local progressCaption = Instance.new("TextLabel")
	progressCaption.Name = "ProgressCaption"
	progressCaption.Position = UDim2.fromOffset(12, 104)
	progressCaption.Size = UDim2.new(1, -148, 0, 18)
	progressCaption.BackgroundTransparency = 1
	progressCaption.Font = Enum.Font.Gotham
	progressCaption.TextSize = 11
	progressCaption.TextXAlignment = Enum.TextXAlignment.Left
	progressCaption.TextColor3 = Color3.fromRGB(186, 198, 214)
	progressCaption.Text = "0/200 XP"
	progressCaption.Parent = heroCard

	local premiumActionButton = Instance.new("TextButton")
	premiumActionButton.Name = "PremiumActionButton"
	premiumActionButton.AnchorPoint = Vector2.new(1, 1)
	premiumActionButton.Position = UDim2.new(1, -12, 1, -10)
	premiumActionButton.Size = UDim2.fromOffset(124, 34)
	styleButton(premiumActionButton, "LIHAT SHOP")
	premiumActionButton.BackgroundColor3 = Color3.fromRGB(116, 88, 44)
	premiumActionButton.TextColor3 = Color3.fromRGB(248, 242, 230)
	premiumActionButton.Parent = heroCard
	local premiumButtonCorner = Instance.new("UICorner")
	premiumButtonCorner.CornerRadius = UDim.new(0, 8)
	premiumButtonCorner.Parent = premiumActionButton
	self:_setSelectableStyle(premiumActionButton)

	local tierList = Instance.new("Frame")
	tierList.Name = "TierList"
	tierList.LayoutOrder = 5
	tierList.Size = UDim2.new(1, 0, 0, 0)
	tierList.AutomaticSize = Enum.AutomaticSize.Y
	tierList.BackgroundTransparency = 1
	tierList.Parent = deck
	local tierLayout = Instance.new("UIListLayout")
	tierLayout.FillDirection = Enum.FillDirection.Vertical
	tierLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tierLayout.Padding = UDim.new(0, 6)
	tierLayout.Parent = tierList

	local rows = {}
	for index = 1, 3 do
		local row = createActionRow(tierList, "TierRow" .. tostring(index), "TIER", "-", "INFO")
		row.Root.LayoutOrder = index
		row.Button.Active = false
		row.Button.AutoButtonColor = false
		row.Button.Selectable = false
		table.insert(rows, row)
	end

	local trackTabs = Instance.new("Frame")
	trackTabs.Name = "TrackTabs"
	trackTabs.LayoutOrder = 2
	trackTabs.Size = UDim2.new(1, 0, 0, 34)
	trackTabs.BackgroundTransparency = 1
	trackTabs.Parent = deck

	local rewardTab = Instance.new("TextButton")
	rewardTab.Name = "RewardTab"
	rewardTab.Position = UDim2.fromOffset(0, 0)
	rewardTab.Size = UDim2.new(0.5, -4, 1, 0)
	styleButton(rewardTab, "30 DAY REWARD")
	rewardTab.BackgroundColor3 = Color3.fromRGB(74, 92, 118)
	rewardTab.Parent = trackTabs
	local rewardTabCorner = Instance.new("UICorner")
	rewardTabCorner.CornerRadius = UDim.new(0, 10)
	rewardTabCorner.Parent = rewardTab
	self:_setSelectableStyle(rewardTab)

	local missionTab = Instance.new("TextButton")
	missionTab.Name = "MissionTab"
	missionTab.AnchorPoint = Vector2.new(1, 0)
	missionTab.Position = UDim2.new(1, 0, 0, 0)
	missionTab.Size = UDim2.new(0.5, -4, 1, 0)
	styleButton(missionTab, "30 DAY MISSION")
	missionTab.BackgroundColor3 = Color3.fromRGB(52, 62, 78)
	missionTab.Parent = trackTabs
	local missionTabCorner = Instance.new("UICorner")
	missionTabCorner.CornerRadius = UDim.new(0, 10)
	missionTabCorner.Parent = missionTab
	self:_setSelectableStyle(missionTab)

	local trackHint = Instance.new("TextLabel")
	trackHint.Name = "TrackHint"
	trackHint.LayoutOrder = 3
	trackHint.Size = UDim2.new(1, 0, 0, 18)
	trackHint.BackgroundTransparency = 1
	trackHint.Font = Enum.Font.Gotham
	trackHint.TextSize = 11
	trackHint.TextXAlignment = Enum.TextXAlignment.Left
	trackHint.TextColor3 = Color3.fromRGB(170, 184, 202)
	trackHint.Text = "Geser horizontal untuk melihat 30 hari. Hari ke-30 menampilkan placeholder hadiah karakter rarity 5."
	trackHint.Parent = deck

	local trackScroller = Instance.new("ScrollingFrame")
	trackScroller.Name = "TrackScroller"
	trackScroller.LayoutOrder = 4
	trackScroller.Size = UDim2.new(1, 0, 0, 178)
	trackScroller.BackgroundColor3 = Color3.fromRGB(18, 24, 32)
	trackScroller.BackgroundTransparency = 0.08
	trackScroller.BorderSizePixel = 0
	trackScroller.AutomaticCanvasSize = Enum.AutomaticSize.X
	trackScroller.CanvasSize = UDim2.fromOffset(0, 0)
	trackScroller.ScrollBarThickness = 5
	trackScroller.ScrollingDirection = Enum.ScrollingDirection.X
	trackScroller.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	trackScroller.HorizontalScrollBarInset = Enum.ScrollBarInset.ScrollBar
	trackScroller.Parent = deck
	local trackScrollerCorner = Instance.new("UICorner")
	trackScrollerCorner.CornerRadius = UDim.new(0, 10)
	trackScrollerCorner.Parent = trackScroller
	local trackScrollerStroke = Instance.new("UIStroke")
	trackScrollerStroke.Name = "TrackScrollerStroke"
	trackScrollerStroke.Thickness = 1
	trackScrollerStroke.Color = Color3.fromRGB(76, 95, 122)
	trackScrollerStroke.Transparency = 0.18
	trackScrollerStroke.Parent = trackScroller
	local trackScrollerPadding = Instance.new("UIPadding")
	trackScrollerPadding.PaddingLeft = UDim.new(0, 8)
	trackScrollerPadding.PaddingRight = UDim.new(0, 8)
	trackScrollerPadding.PaddingTop = UDim.new(0, 8)
	trackScrollerPadding.PaddingBottom = UDim.new(0, 8)
	trackScrollerPadding.Parent = trackScroller
	local trackLayout = Instance.new("UIListLayout")
	trackLayout.FillDirection = Enum.FillDirection.Horizontal
	trackLayout.SortOrder = Enum.SortOrder.LayoutOrder
	trackLayout.Padding = UDim.new(0, 8)
	trackLayout.Parent = trackScroller

	local trackCards = {}
	for index = 1, 30 do
		local card = Instance.new("Frame")
		card.Name = "DayCard" .. tostring(index)
		card.Size = UDim2.fromOffset(140, 156)
		card.BackgroundColor3 = Color3.fromRGB(26, 34, 44)
		card.BorderSizePixel = 0
		card.Parent = trackScroller
		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 12)
		cardCorner.Parent = card
		local cardStroke = Instance.new("UIStroke")
		cardStroke.Name = "CardStroke"
		cardStroke.Thickness = 1
		cardStroke.Color = Color3.fromRGB(82, 100, 126)
		cardStroke.Transparency = 0.16
		cardStroke.Parent = card

		local accent = Instance.new("Frame")
		accent.Name = "Accent"
		accent.Size = UDim2.new(1, 0, 0, 5)
		accent.BackgroundColor3 = Color3.fromRGB(90, 126, 188)
		accent.BorderSizePixel = 0
		accent.Parent = card

		local dayBadge = Instance.new("TextLabel")
		dayBadge.Name = "DayBadge"
		dayBadge.Position = UDim2.fromOffset(10, 12)
		dayBadge.Size = UDim2.fromOffset(78, 18)
		dayBadge.BackgroundColor3 = Color3.fromRGB(48, 62, 82)
		dayBadge.BorderSizePixel = 0
		dayBadge.Font = Enum.Font.GothamBlack
		dayBadge.TextSize = 10
		dayBadge.TextColor3 = Color3.fromRGB(242, 245, 248)
		dayBadge.Text = string.format("DAY %02d", index)
		dayBadge.Parent = card
		local dayBadgeCorner = Instance.new("UICorner")
		dayBadgeCorner.CornerRadius = UDim.new(1, 0)
		dayBadgeCorner.Parent = dayBadge

		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "Title"
		titleLabel.Position = UDim2.fromOffset(10, 40)
		titleLabel.Size = UDim2.new(1, -20, 0, 36)
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.GothamBold
		titleLabel.TextSize = 14
		titleLabel.TextWrapped = true
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextYAlignment = Enum.TextYAlignment.Top
		titleLabel.TextColor3 = Color3.fromRGB(244, 240, 232)
		titleLabel.Text = "TRACK"
		titleLabel.Parent = card

		local metaLabel = Instance.new("TextLabel")
		metaLabel.Name = "Meta"
		metaLabel.Position = UDim2.fromOffset(10, 78)
		metaLabel.Size = UDim2.new(1, -20, 0, 38)
		metaLabel.BackgroundTransparency = 1
		metaLabel.Font = Enum.Font.Gotham
		metaLabel.TextSize = 11
		metaLabel.TextWrapped = true
		metaLabel.TextXAlignment = Enum.TextXAlignment.Left
		metaLabel.TextYAlignment = Enum.TextYAlignment.Top
		metaLabel.TextColor3 = Color3.fromRGB(188, 198, 214)
		metaLabel.Text = "-"
		metaLabel.Parent = card

		local rewardPill = Instance.new("TextLabel")
		rewardPill.Name = "RewardPill"
		rewardPill.Position = UDim2.fromOffset(10, 120)
		rewardPill.Size = UDim2.new(1, -20, 0, 22)
		rewardPill.BackgroundColor3 = Color3.fromRGB(60, 88, 128)
		rewardPill.BorderSizePixel = 0
		rewardPill.Font = Enum.Font.GothamBold
		rewardPill.TextSize = 10
		rewardPill.TextColor3 = Color3.fromRGB(245, 245, 245)
		rewardPill.Text = "+"
		rewardPill.Parent = card
		local rewardPillCorner = Instance.new("UICorner")
		rewardPillCorner.CornerRadius = UDim.new(1, 0)
		rewardPillCorner.Parent = rewardPill

		local footerLabel = Instance.new("TextLabel")
		footerLabel.Name = "Footer"
		footerLabel.AnchorPoint = Vector2.new(1, 0)
		footerLabel.Position = UDim2.new(1, -10, 0, 14)
		footerLabel.Size = UDim2.fromOffset(36, 16)
		footerLabel.BackgroundTransparency = 1
		footerLabel.Font = Enum.Font.GothamBlack
		footerLabel.TextSize = 9
		footerLabel.TextColor3 = Color3.fromRGB(220, 226, 236)
		footerLabel.TextXAlignment = Enum.TextXAlignment.Right
		footerLabel.Text = "LOCK"
		footerLabel.Parent = card

		trackCards[index] = {
			Root = card,
			Accent = accent,
			Stroke = cardStroke,
			DayBadge = dayBadge,
			Title = titleLabel,
			Meta = metaLabel,
			RewardPill = rewardPill,
			Footer = footerLabel,
		}
	end

	if premiumActionButton:GetAttribute("Bound") ~= true then
		premiumActionButton:SetAttribute("Bound", true)
		connectButtonPress(premiumActionButton, function()
			self:_toggleAuxiliaryWindow("ShopUI")
		end)
	end
	if rewardTab:GetAttribute("Bound") ~= true then
		rewardTab:SetAttribute("Bound", true)
		connectButtonPress(rewardTab, function()
			self._royalPassState.viewMode = "Rewards"
			self:_refreshRoyalPassPanel()
		end)
	end
	if missionTab:GetAttribute("Bound") ~= true then
		missionTab:SetAttribute("Bound", true)
		connectButtonPress(missionTab, function()
			self._royalPassState.viewMode = "Missions"
			self:_refreshRoyalPassPanel()
		end)
	end

	window.RoyalPassWidgets = {
		Deck = deck,
		HeroCard = heroCard,
		HeroStroke = heroStroke,
		HeroBadge = heroBadge,
		HeroTitle = heroTitle,
		HeroMeta = heroMeta,
		ProgressTrack = progressTrack,
		ProgressFill = progressFill,
		ProgressCaption = progressCaption,
		PremiumActionButton = premiumActionButton,
		Rows = rows,
		TrackTabs = trackTabs,
		RewardTab = rewardTab,
		MissionTab = missionTab,
		TrackHint = trackHint,
		TrackScroller = trackScroller,
		TrackCards = trackCards,
	}
	return window.RoyalPassWidgets
end

function UISystem:_refreshRoyalPassPanel()
	local window = self._uxWidgets and self._uxWidgets.windows and self._uxWidgets.windows.RoyalPassUI
	if not window then
		return
	end

	local state = self._royalPassState or {}
	local currentTier = math.max(1, math.floor(tonumber(state.currentTier or 1) or 1))
	local maxTier = math.max(currentTier, math.floor(tonumber(state.maxTier or 50) or 50))
	local xpPerTier = math.max(1, math.floor(tonumber(state.xpPerTier or 200) or 200))
	local currentTierXP = math.clamp(math.floor(tonumber(state.currentTierXP or 0) or 0), 0, xpPerTier)
	local totalXP = math.max(0, math.floor(tonumber(state.totalXP or 0) or 0))
	local remainingXP = math.max(0, math.floor(tonumber(state.remainingXP or 0) or 0))
	local premiumOwned = state.premiumOwned == true
	local progressPercent = math.clamp(tonumber(state.progressPercent or 0) or 0, 0, 1)

	local badgeText = premiumOwned and "PREMIUM" or "FREE TRACK"
	local badgeColor = premiumOwned and Color3.fromRGB(136, 102, 48) or Color3.fromRGB(78, 92, 118)
	local primaryText = string.format("Season %s | Tier %d/%d", tostring(state.seasonId or "S1"), currentTier, maxTier)
	local secondaryText = string.format(
		"Progress %d/%d XP | Total %d XP",
		currentTierXP,
		xpPerTier,
		totalXP
	)

	local unlockedPreview = "-"
	if type(state.unlockedTiers) == "table" and #state.unlockedTiers > 0 then
		local recent = {}
		local startIndex = math.max(1, #state.unlockedTiers - 5)
		for index = startIndex, #state.unlockedTiers do
			table.insert(recent, tostring(state.unlockedTiers[index]))
		end
		unlockedPreview = table.concat(recent, ", ")
	end

	local nextRewardLine = "Next Reward: MAX TIER"
	if type(state.nextReward) == "table" then
		nextRewardLine = string.format(
			"Next Reward: %d MM + %d XP bonus",
			math.max(0, math.floor(tonumber(state.nextReward.currency) or 0)),
			math.max(0, math.floor(tonumber(state.nextReward.xp) or 0))
		)
	elseif state.nextTier then
		nextRewardLine = string.format("Next Reward: Tier %s reward belum tersedia.", tostring(state.nextTier))
	end

	local lastGainLine = "Last Gain: belum ada update runtime."
	if math.max(0, math.floor(tonumber(state.lastAmount or 0) or 0)) > 0 then
		lastGainLine = string.format(
			"Last Gain: +%d RP XP dari %s",
			math.max(0, math.floor(tonumber(state.lastAmount) or 0)),
			tostring(state.lastSource or "runtime")
		)
	elseif state.lastSource then
		lastGainLine = string.format("Last Update: %s", tostring(state.lastSource))
	end

	local contentText = table.concat({
		string.format("Track: %s", premiumOwned and "Premium aktif" or "Free only"),
		string.format("Tier saat ini: %d", currentTier),
		string.format("Sisa XP ke tier berikutnya: %d", remainingXP),
		string.format("Tier terbuka: %d", math.max(0, math.floor(tonumber(state.unlockedTierCount or 0) or 0))),
		string.format("Preview tier terbuka: %s", unlockedPreview),
		nextRewardLine,
		lastGainLine,
		string.format("Last Event: %s", tostring(state.lastEvent or "Idle")),
	}, "\n")

	local footerText = premiumOwned
		and "Premium track aktif. Reward premium mengikuti snapshot server yang sedang berjalan."
		or "Belum premium. Pembelian premium track tetap harus lewat purchase prompt Roblox resmi."

	self:_refreshWindowText(
		"RoyalPassUI",
		badgeText,
		primaryText,
		secondaryText,
		nil,
		footerText,
		badgeColor
	)

	local widgets = self:_ensureRoyalPassWidgets(window)
	if not widgets then
		return
	end
	state.viewMode = state.viewMode == "Missions" and "Missions" or "Rewards"

	local heroAccent = premiumOwned and Color3.fromRGB(126, 98, 52) or Color3.fromRGB(72, 94, 128)
	local heroBackground = premiumOwned and Color3.fromRGB(34, 31, 24) or Color3.fromRGB(28, 36, 48)

	widgets.HeroCard.BackgroundColor3 = heroBackground
	widgets.HeroStroke.Color = heroAccent
	widgets.HeroBadge.BackgroundColor3 = heroAccent
	widgets.HeroBadge.Text = premiumOwned and "PREMIUM ACTIVE" or "FREE TRACK"
	widgets.HeroTitle.Text = string.format("SEASON %s  •  TIER %02d", tostring(state.seasonId or "S1"), currentTier)
	widgets.HeroMeta.Text = string.format(
		"%d / %d XP on current tier  •  %d total XP",
		currentTierXP,
		xpPerTier,
		totalXP
	)
	widgets.ProgressFill.BackgroundColor3 = premiumOwned and Color3.fromRGB(220, 178, 92) or Color3.fromRGB(104, 148, 220)
	widgets.ProgressFill.Size = UDim2.fromScale(math.max(0.06, progressPercent), 1)
	widgets.ProgressCaption.Text = string.format(
		"%d XP to next tier  •  %d unlocked tier",
		remainingXP,
		math.max(0, math.floor(tonumber(state.unlockedTierCount or 0) or 0))
	)
	widgets.PremiumActionButton.BackgroundColor3 = premiumOwned and Color3.fromRGB(74, 108, 70) or heroAccent
	widgets.PremiumActionButton.Text = premiumOwned and "PREMIUM AKTIF" or "LIHAT SHOP"

	local unlockedPreview = "-"
	if type(state.unlockedTiers) == "table" and #state.unlockedTiers > 0 then
		local recent = {}
		local startIndex = math.max(1, #state.unlockedTiers - 3)
		for index = startIndex, #state.unlockedTiers do
			table.insert(recent, "T" .. tostring(state.unlockedTiers[index]))
		end
		unlockedPreview = table.concat(recent, ", ")
	end

	local nextRewardTitle = state.nextTier and ("Tier " .. tostring(state.nextTier) .. " reward") or "MAX TIER"
	local nextRewardMeta = state.nextReward
		and string.format(
			"%d MM + %d XP bonus menunggu di track berikutnya.",
			math.max(0, math.floor(tonumber(state.nextReward.currency) or 0)),
			math.max(0, math.floor(tonumber(state.nextReward.xp) or 0))
		)
		or "Semua tier utama sudah terbuka."

	local rows = widgets.Rows or {}
	local rowData = {
		{
			badge = premiumOwned and "PRM" or "FREE",
			glyph = string.format("T%02d", currentTier),
			title = "Tier aktif",
			meta = string.format("Track %s • %d/%d XP • event %s", premiumOwned and "premium" or "free", currentTierXP, xpPerTier, tostring(state.lastEvent or "Idle")),
			pill = string.format("%d XP", totalXP),
			button = "LIVE",
			accent = heroAccent,
			preview = premiumOwned and Color3.fromRGB(66, 54, 32) or Color3.fromRGB(46, 58, 78),
		},
		{
			badge = "NEXT",
			glyph = state.nextTier and string.format("T%02d", state.nextTier) or "MAX",
			title = nextRewardTitle,
			meta = nextRewardMeta,
			pill = state.nextReward and string.format("+%d MM", math.max(0, math.floor(tonumber(state.nextReward.currency) or 0))) or "CLEAR",
			button = state.nextReward and "READY" or "DONE",
			accent = Color3.fromRGB(118, 88, 46),
			preview = Color3.fromRGB(60, 50, 34),
		},
		{
			badge = "TRACK",
			glyph = premiumOwned and "RP" or "FT",
			title = premiumOwned and "Premium trajectory" or "Free trajectory",
			meta = string.format("Unlocked %d tier • preview %s", math.max(0, math.floor(tonumber(state.unlockedTierCount or 0) or 0)), unlockedPreview),
			pill = string.format("%d LEFT", remainingXP),
			button = premiumOwned and "OWNED" or "SHOP",
			accent = premiumOwned and Color3.fromRGB(90, 126, 88) or Color3.fromRGB(74, 92, 118),
			preview = premiumOwned and Color3.fromRGB(42, 58, 40) or Color3.fromRGB(38, 48, 62),
		},
	}

	for index, row in ipairs(rows) do
		local data = rowData[index]
		if data then
			row.Root.BackgroundColor3 = Color3.fromRGB(23, 29, 39)
			row.Accent.BackgroundColor3 = data.accent
			row.Preview.BackgroundColor3 = data.preview
			row.PreviewBadge.BackgroundColor3 = data.accent
			row.PreviewBadge.TextColor3 = Color3.fromRGB(247, 243, 236)
			row.PreviewBadge.Text = data.badge
			row.PreviewGlyph.TextColor3 = Color3.fromRGB(247, 243, 236)
			row.PreviewGlyph.Text = data.glyph
			row.Title.Text = data.title
			row.Meta.Text = data.meta
			applyPricePillVisual(row.PricePill, data.pill, data.accent, Color3.fromRGB(247, 243, 236))
			row.Button.Text = data.button
			row.Button.BackgroundColor3 = data.preview
			row.Button.TextColor3 = Color3.fromRGB(242, 241, 236)
		end
	end

	if widgets.RewardTab and widgets.MissionTab then
		local rewardsActive = state.viewMode ~= "Missions"
		widgets.RewardTab.BackgroundColor3 = rewardsActive and Color3.fromRGB(78, 108, 152) or Color3.fromRGB(50, 60, 78)
		widgets.MissionTab.BackgroundColor3 = rewardsActive and Color3.fromRGB(50, 60, 78) or Color3.fromRGB(92, 76, 126)
		widgets.RewardTab.TextColor3 = rewardsActive and Color3.fromRGB(246, 242, 234) or Color3.fromRGB(194, 204, 216)
		widgets.MissionTab.TextColor3 = rewardsActive and Color3.fromRGB(194, 204, 216) or Color3.fromRGB(246, 242, 234)
	end
	if widgets.TrackHint then
		widgets.TrackHint.Text = state.viewMode == "Missions"
			and "Geser horizontal untuk melihat 30 hari misi. Hari ke-30 menjaga placeholder hadiah karakter rarity 5."
			or "Geser horizontal untuk melihat 30 hari reward. Hari ke-30 menampilkan placeholder hadiah karakter rarity 5."
	end

	local trackCards = widgets.TrackCards or {}
	local unlockedDays = math.clamp(math.max(1, currentTier), 1, 30)
	local currentDay = math.min(unlockedDays, 30)
	for index, card in ipairs(trackCards) do
		local isFinalDay = index == 30
		local isCurrentDay = index == currentDay
		local isUnlocked = index < currentDay
		local isLocked = index > currentDay
		local accentColor = Color3.fromRGB(82, 104, 132)
		local strokeColor = Color3.fromRGB(78, 96, 122)
		local badgeColor = Color3.fromRGB(58, 72, 94)
		local footerText = isUnlocked and "DONE" or (isCurrentDay and "LIVE" or "LOCK")
		local titleText
		local metaText
		local rewardText
		local cardBackground = Color3.fromRGB(24, 32, 42)

		if state.viewMode == "Missions" then
			local missionTemplates = {
				"Menangkan 1 investigasi penuh",
				"Kumpulkan 2 evidence penting",
				"Selamat dari 1 hunt tanpa mati",
				"Gunakan tool investigasi 3 kali",
				"Bermain bersama 1 teman",
			}
			titleText = isFinalDay and "MISSION 30 • GRAND FINALE" or string.format("MISSION %02d", index)
			metaText = isFinalDay
				and "Selesaikan misi penutup season untuk membuka placeholder hadiah karakter rarity 5."
				or missionTemplates[((index - 1) % #missionTemplates) + 1]
			rewardText = isFinalDay and "R5 TOKEN" or string.format("+%d XP", 60 + (index * 5))
			accentColor = isFinalDay and Color3.fromRGB(210, 160, 86) or Color3.fromRGB(112, 84, 150)
			strokeColor = isFinalDay and Color3.fromRGB(232, 186, 104) or Color3.fromRGB(118, 90, 156)
			badgeColor = isFinalDay and Color3.fromRGB(108, 78, 46) or Color3.fromRGB(76, 58, 102)
			cardBackground = isFinalDay and Color3.fromRGB(40, 30, 22) or Color3.fromRGB(32, 28, 42)
		else
			titleText = isFinalDay and "DAY 30 • CHARACTER R5" or string.format("DAY %02d REWARD", index)
			metaText = isFinalDay
				and "Border placeholder untuk hadiah karakter rarity 5 di penghujung 30 hari season."
				or string.format("Claim harian untuk ritme login. Bonus tier mengikuti season %s.", tostring(state.seasonId or "S1"))
			rewardText = isFinalDay and "R5 BORDER" or string.format("+%d MM", 120 + ((index - 1) * 20))
			accentColor = isFinalDay and Color3.fromRGB(224, 170, 88) or (premiumOwned and Color3.fromRGB(126, 98, 52) or Color3.fromRGB(82, 110, 162))
			strokeColor = isFinalDay and Color3.fromRGB(244, 198, 112) or accentColor
			badgeColor = isFinalDay and Color3.fromRGB(118, 86, 42) or Color3.fromRGB(60, 82, 118)
			cardBackground = isFinalDay and Color3.fromRGB(42, 30, 20) or Color3.fromRGB(24, 32, 42)
		end

		if isCurrentDay then
			cardBackground = cardBackground:Lerp(Color3.fromRGB(52, 64, 82), 0.28)
			footerText = "TODAY"
		elseif isUnlocked then
			footerText = "DONE"
		elseif isLocked then
			footerText = "LOCK"
		end

		card.Root.BackgroundColor3 = cardBackground
		card.Accent.BackgroundColor3 = accentColor
		card.Stroke.Color = strokeColor
		card.Stroke.Thickness = isFinalDay and 2 or 1
		card.DayBadge.BackgroundColor3 = badgeColor
		card.DayBadge.Text = string.format("DAY %02d", index)
		card.Title.Text = titleText
		card.Meta.Text = metaText
		card.Footer.Text = footerText
		card.Footer.TextColor3 = isLocked
			and Color3.fromRGB(174, 182, 194)
			or (isFinalDay and Color3.fromRGB(244, 214, 146) or Color3.fromRGB(220, 230, 238))
		applyPricePillVisual(
			card.RewardPill,
			rewardText,
			accentColor,
			isFinalDay and Color3.fromRGB(248, 242, 230) or Color3.fromRGB(236, 240, 246)
		)
	end

	local focusKey = string.format(
		"%s:%s:%d:%d",
		tostring(state.seasonId or "S1"),
		tostring(state.viewMode or "Rewards"),
		currentDay,
		premiumOwned and 1 or 0
	)
	if self._royalPassTrackFocusKey ~= focusKey then
		self._royalPassTrackFocusKey = focusKey
		self:_focusRoyalPassTrackCard(widgets, currentDay)
	end
end

function UISystem:_focusRoyalPassTrackCard(widgets, targetIndex)
	if type(widgets) ~= "table" then
		return
	end

	local scroller = widgets.TrackScroller
	local cards = widgets.TrackCards
	local targetCard = type(cards) == "table" and cards[targetIndex] or nil
	local targetRoot = targetCard and targetCard.Root
	if not scroller or not targetRoot or not targetRoot.Parent then
		return
	end

	task.defer(function()
		if not scroller.Parent or not targetRoot.Parent then
			return
		end

		local visibleWidth = scroller.AbsoluteWindowSize.X
		local canvasWidth = scroller.AbsoluteCanvasSize.X
		if visibleWidth <= 0 or canvasWidth <= visibleWidth then
			scroller.CanvasPosition = Vector2.new(0, 0)
			return
		end

		local cardOffsetX = targetRoot.AbsolutePosition.X - scroller.AbsolutePosition.X + scroller.CanvasPosition.X
		local cardCenterX = cardOffsetX + (targetRoot.AbsoluteSize.X * 0.5)
		local desiredX = math.clamp(
			math.floor(cardCenterX - (visibleWidth * 0.5)),
			0,
			math.max(0, canvasWidth - visibleWidth)
		)
		scroller.CanvasPosition = Vector2.new(desiredX, 0)
	end)
end

function UISystem:_refreshPasraPanel()
	local result = self._matchResult or createDefaultMatchResult()
	local statusText = result.correctGuess and "SUCCESS" or "RESULT"
	local badgeColor = result.correctGuess and Color3.fromRGB(58, 116, 90) or Color3.fromRGB(58, 100, 88)
	local primaryText = self._pasraState.status or "Belum ada hasil match."
	local secondaryText = self._pasraState.subtitle or "Panel ini akan terisi saat match selesai."
	local contentText = table.concat({
		string.format("Ghost: %s", tostring(result.ghostType or "Unknown")),
		string.format("Tebakan: %s", result.correctGuess and "BENAR" or "BELUM / SALAH"),
		string.format("Evidence: %s", tostring(result.evidenceCollected or 0)),
		string.format("Pemain Selamat: %s", tostring(result.playersSurvived or 0)),
		string.format("Pemain Mati: %s", tostring(result.playersDead or 0)),
		string.format("Durasi: %s", formatMatchDuration(result.matchDuration)),
		string.format("Hadiah MM: %s", tostring(math.floor(tonumber(result.currencyReward or 0) or 0))),
		string.format("Hadiah PP: %s", tostring(math.floor(tonumber(result.ppReward or 0) or 0))),
		string.format("Hadiah XP: %s", tostring(math.floor(tonumber(result.xpReward or 0) or 0))),
		string.format("Last Event: %s", tostring(self._pasraState.lastEvent or "Idle")),
	}, "\n")
	self:_refreshWindowText(
		"PASRA_UI",
		statusText,
		primaryText,
		secondaryText,
		contentText,
		"Summary hasil ini basic, visual, dan cukup untuk test E2E return flow.",
		badgeColor
	)
end

function UISystem:_refreshSpectatorPanel()
	local spectator = self._spectatorState or {}
	local badgeText = spectator.mode == "dead" and "DEAD" or "NOTICE"
	local badgeColor = spectator.mode == "dead"
		and Color3.fromRGB(120, 52, 52)
		or Color3.fromRGB(94, 74, 48)
	local contentText = table.concat({
		tostring(spectator.subtitle or "-"),
		"",
		"Distortion Odds",
		"- Fake: 60%",
		"- Uncertain: 30%",
		"- Real: 10%",
		"",
		"Gunakan float VIEW untuk buka ulang panel ini jika ditutup.",
	}, "\n")
	self:_refreshWindowText(
		"SpectatorUI",
		badgeText,
		tostring(spectator.title or "Belum spectate."),
		string.format("Mode %s | Event %s", tostring(spectator.mode or "none"), tostring(spectator.lastEvent or "Idle")),
		contentText,
		"Pesan spectator basic ini mengikuti requirement visual death/spectator.",
		badgeColor
	)
end

function UISystem:_trackUXInstance(instance)
	table.insert(self._uxInstances, instance)
	return instance
end

function UISystem:_clearUXInstances()
	destroyAll(self._uxInstances)
	local matchWidgets = self._uxWidgets.match
	if matchWidgets and matchWidgets.PulseConnection then
		matchWidgets.PulseConnection:Disconnect()
		matchWidgets.PulseConnection = nil
	end
	if matchWidgets and matchWidgets.PulseTween then
		matchWidgets.PulseTween:Cancel()
		matchWidgets.PulseTween = nil
	end
end

function UISystem:_setSelectableStyle(guiObject)
	if not guiObject then
		return
	end
	guiObject.Selectable = true
	if guiObject:IsA("GuiButton") then
		bindButtonPolish(guiObject)
		return
	end
	local stroke = Instance.new("UIStroke")
	stroke.Name = "SelectionStroke"
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Thickness = 0
	stroke.Color = Color3.fromRGB(255, 220, 120)
	stroke.Parent = guiObject

	table.insert(self._uxConnections, guiObject.SelectionGained:Connect(function()
		stroke.Thickness = 3
	end))
	table.insert(self._uxConnections, guiObject.SelectionLost:Connect(function()
		stroke.Thickness = 0
	end))
end

function UISystem:_applyRoomBrowserSizing(profile, viewportSize, topLeftInset, bottomRightInset)
	local widgets = self._roomBrowserWidgets
	if not widgets or not widgets.RootPanel then
		return
	end

	local panel = widgets.RootPanel
	local title = widgets.HeaderTitle
	local titleGlow = widgets.HeaderTitleGlow
	local statusLabel = widgets.Status
	local closeButton = panel:FindFirstChild("CloseButton")
	local dragBar = panel:FindFirstChild("DragBar")
	local panelScale = panel:FindFirstChildOfClass("UIScale")
	local roomList = widgets.RoomList
	local roomPreviewPanel = widgets.RoomPreviewPanel
	local roomPreviewTitle = widgets.RoomPreviewTitle
	local roomPreviewInfo = widgets.RoomPreviewInfo
	local roomPreviewMap = widgets.RoomPreviewMap
	local roomPreviewPlayersList = widgets.RoomPreviewPlayersList
	local joinPassword = widgets.JoinPassword
	local refreshButton = widgets.RefreshButton
	local createRoomButton = widgets.CreateRoomButton
	local queueButton = widgets.QueueButton
	local quickClassicButton = widgets.QuickJoinClassicButton
	local quickRankedButton = widgets.QuickJoinRankedButton
	local roomPanel = widgets.RoomPanel
	local roomTitle = widgets.RoomTitle
	local roomHost = widgets.RoomHost
	local playersList = widgets.PlayersList
	local readyButton = widgets.ReadyButton
	local startButton = widgets.StartButton
	local cancelStartButton = widgets.CancelStartButton
	local modeSelector = widgets.ModeSelector
	local modeDropdown = widgets.ModeDropdown
	local mapSelector = widgets.MapSelector
	local mapDropdown = widgets.MapDropdown
	local rankedTierLabel = widgets.RankedTierLabel
	local mapPreview = widgets.MapPreview
	local setPasswordBox = widgets.SetPasswordBox
	local setPasswordButton = widgets.SetPasswordButton
	local inviteButton = widgets.InviteButton
	local inviteDropdown = widgets.InviteDropdown
	local kickNameBox = widgets.KickNameBox
	local kickButton = widgets.KickButton
	local floatButton = widgets.FloatButton
	local countdownOverlay = widgets.CountdownOverlay
	local countdownLabel = widgets.CountdownLabel
	local cancelCountdown = widgets.CancelCountdown

	local playersLabel = roomPanel and roomPanel:FindFirstChild("PlayersLabel")
	local mapPreviewTitle = mapPreview and mapPreview:FindFirstChild("Title")
	local mapPreviewLabel = mapPreview and mapPreview:FindFirstChild("Label")
	local mapPreviewImage = mapPreview and mapPreview:FindFirstChild("MapImagePlaceholder")
	local mapPreviewImageChip = mapPreviewImage and mapPreviewImage:FindFirstChild("MoodChip")
	local mapPreviewImageLabel = mapPreviewImage and mapPreviewImage:FindFirstChild("ImageLabel")
	local mapPreviewImageStats = mapPreviewImage and mapPreviewImage:FindFirstChild("Stats")
	local mapPreviewImageFooter = mapPreviewImage and mapPreviewImage:FindFirstChild("Footer")
	local roomPreviewPlayersTitle = roomPreviewPanel and roomPreviewPanel:FindFirstChild("PlayersTitle")
	local roomPreviewPlayersLayout = roomPreviewPlayersList and roomPreviewPlayersList:FindFirstChildOfClass("UIGridLayout")
	local playersListLayout = playersList and playersList:FindFirstChildOfClass("UIGridLayout")
	local modeClassicOption = modeDropdown and modeDropdown:FindFirstChild("ClassicOption")
	local modeRankedOption = modeDropdown and modeDropdown:FindFirstChild("RankedOption")
	local mapOptions = {}
	if mapDropdown then
		for _, child in ipairs(mapDropdown:GetChildren()) do
			if child:IsA("TextButton") and string.find(child.Name, "MapOption_", 1, true) == 1 then
				table.insert(mapOptions, child)
			end
		end
		table.sort(mapOptions, function(a, b)
			return a.Name < b.Name
		end)
	end

	local margin = profile.isMobile and 2 or 14
	local usableWidth = math.max(profile.isMobile and 320 or 360, viewportSize.X - (topLeftInset.X + bottomRightInset.X + margin * 2))
	local usableHeight = math.max(profile.isMobile and 520 or 420, viewportSize.Y - (topLeftInset.Y + bottomRightInset.Y + margin * 2))
	local forceCompact = ReplicatedStorage:GetAttribute(UI_FORCE_COMPACT_ATTR) == true
	-- Force compact layout for short viewports so room controls do not overlap
	-- host action buttons (Start/Leave) in the room detail panel.
	local isCompact = forceCompact or profile.isMobile or viewportSize.X <= 980 or usableHeight <= 700
	self._roomBrowserCompact = isCompact

	local panelWidth = isCompact and usableWidth or math.min(1080, usableWidth)
	local panelHeight = isCompact and usableHeight or math.min(668, usableHeight)
	if profile.isMobile then
		panelWidth = math.max(332, viewportSize.X - (topLeftInset.X + bottomRightInset.X))
		panelHeight = math.max(540, viewportSize.Y - (topLeftInset.Y + bottomRightInset.Y))
	end
	panel.Size = UDim2.fromOffset(panelWidth, panelHeight)
	panel.Position = UDim2.fromOffset(
		topLeftInset.X + margin + math.floor(panelWidth * 0.5),
		topLeftInset.Y + margin + math.floor(panelHeight * 0.5)
	)
	panel.BackgroundTransparency = profile.isMobile and 0.04 or (isCompact and 0.14 or 0.18)
	panel.ClipsDescendants = true
	if panelScale then
		panelScale.Scale = 1
	end

	local headerPadding = isCompact and 14 or 16
	local headerWidth = panelWidth - (headerPadding * 2) - 42
	if dragBar then
		setOffsetBounds(dragBar, 0, 0, panelWidth, isCompact and 52 or 44)
		dragBar.Active = not profile.isMobile
	end
	if closeButton then
		setOffsetBounds(closeButton, panelWidth - (profile.isMobile and 52 or 46), 10, profile.isMobile and 40 or 34, profile.isMobile and 32 or 28)
		closeButton.TextSize = profile.isMobile and 16 or (isCompact and 14 or 13)
	end
	if title then
		setOffsetBounds(title, headerPadding, 8, headerWidth, isCompact and 28 or 30)
		title.TextSize = profile.isMobile and 26 or (isCompact and 22 or 25)
	end
	if titleGlow and title then
		titleGlow.Position = title.Position + UDim2.fromOffset(2, 2)
		titleGlow.Size = title.Size
		titleGlow.TextSize = title.TextSize
	end
	if statusLabel then
		setOffsetBounds(statusLabel, headerPadding, isCompact and 40 or 44, panelWidth - headerPadding * 2, 24)
		statusLabel.TextSize = profile.isMobile and 14 or (isCompact and 13 or 12)
	end

	local controlsY = profile.isMobile and 78 or (isCompact and 72 or 74)
	local tabHeight = profile.isMobile and 40 or (isCompact and 36 or 30)
	local tabGap = 6
	local tabWidth = math.floor((panelWidth - headerPadding * 2 - (tabGap * 2)) / 3)
	setOffsetBounds(widgets.ClassicButton, headerPadding, controlsY, tabWidth, tabHeight)
	setOffsetBounds(widgets.AllModesButton, headerPadding + tabWidth + tabGap, controlsY, tabWidth, tabHeight)
	setOffsetBounds(widgets.RankedButton, headerPadding + (tabWidth + tabGap) * 2, controlsY, tabWidth, tabHeight)
	if widgets.ClassicButton then
		widgets.ClassicButton.TextSize = isCompact and 13 or 12
	end
	if widgets.AllModesButton then
		widgets.AllModesButton.TextSize = isCompact and 13 or 12
	end
	if widgets.RankedButton then
		widgets.RankedButton.TextSize = isCompact and 13 or 12
	end

	local previewMapTitle = roomPreviewMap and roomPreviewMap:FindFirstChild("MapTitle")
	local previewMapMood = roomPreviewMap and roomPreviewMap:FindFirstChild("Mood")
	local previewMapStats = roomPreviewMap and roomPreviewMap:FindFirstChild("Stats")
	local previewMapFooter = roomPreviewMap and roomPreviewMap:FindFirstChild("MapLabel")
	local previewMapAccent = roomPreviewMap and roomPreviewMap:FindFirstChild("Accent")
	local previewMapGradient = roomPreviewMap and roomPreviewMap:FindFirstChild("PreviewGradient")

	local contentTop = controlsY + tabHeight + 12
	local actionStackHeight = profile.isMobile and 154 or (isCompact and 130 or 128)
	if isCompact then
		local previewWidth = panelWidth - headerPadding * 2
		local previewHeight = math.clamp(math.floor(panelHeight * (profile.isMobile and 0.33 or 0.36)), profile.isMobile and 236 or 254, profile.isMobile and 304 or 320)
		local actionY = panelHeight - actionStackHeight
		local roomListY = contentTop + previewHeight + 12
		local roomListHeight = actionY - roomListY - 10
		if roomListHeight < (profile.isMobile and 156 or 140) then
			local deficit = (profile.isMobile and 156 or 140) - roomListHeight
			previewHeight = math.max(profile.isMobile and 212 or 224, previewHeight - deficit)
			roomListY = contentTop + previewHeight + 12
			roomListHeight = math.max(profile.isMobile and 156 or 140, actionY - roomListY - 10)
		end

		setOffsetBounds(roomPreviewPanel, headerPadding, contentTop, previewWidth, previewHeight)
		setOffsetBounds(roomList, headerPadding, roomListY, previewWidth, roomListHeight)
		setOffsetBounds(joinPassword, headerPadding, actionY - (profile.isMobile and 46 or 42), previewWidth, profile.isMobile and 38 or 34)
		setOffsetBounds(queueButton, headerPadding, actionY, previewWidth, profile.isMobile and 46 or 42)
		setOffsetBounds(quickClassicButton, headerPadding, actionY + (profile.isMobile and 50 or 46), math.floor((previewWidth - 6) * 0.5), profile.isMobile and 40 or 36)
		setOffsetBounds(quickRankedButton, headerPadding + math.floor((previewWidth - 6) * 0.5) + 6, actionY + (profile.isMobile and 50 or 46), math.floor((previewWidth - 6) * 0.5), profile.isMobile and 40 or 36)
		setOffsetBounds(refreshButton, headerPadding, actionY + (profile.isMobile and 94 or 86), math.floor((previewWidth - 6) * 0.5), profile.isMobile and 40 or 36)
		setOffsetBounds(createRoomButton, headerPadding + math.floor((previewWidth - 6) * 0.5) + 6, actionY + (profile.isMobile and 94 or 86), math.floor((previewWidth - 6) * 0.5), profile.isMobile and 40 or 36)

		local previewMapHeight = math.clamp(math.floor(previewHeight * (profile.isMobile and 0.43 or 0.45)), profile.isMobile and 120 or 112, profile.isMobile and 144 or 136)
		setOffsetBounds(roomPreviewTitle, 12, 10, previewWidth - 24, profile.isMobile and 20 or 18)
		setOffsetBounds(roomPreviewInfo, 12, profile.isMobile and 32 or 30, previewWidth - 24, profile.isMobile and 34 or 30)
		setOffsetBounds(roomPreviewMap, 12, profile.isMobile and 72 or 66, previewWidth - 24, previewMapHeight)
		setOffsetBounds(roomPreviewPlayersTitle, 12, (profile.isMobile and 72 or 66) + previewMapHeight + 10, previewWidth - 24, 16)
		setOffsetBounds(roomPreviewPlayersList, 12, (profile.isMobile and 72 or 66) + previewMapHeight + 30, previewWidth - 24, previewHeight - ((profile.isMobile and 72 or 66) + previewMapHeight + 40))
		if previewMapTitle then
			setOffsetBounds(previewMapTitle, 16, 8, previewWidth - 48, 14)
			previewMapTitle.TextSize = profile.isMobile and 11 or 10
		end
		if previewMapMood then
			setOffsetBounds(previewMapMood, previewWidth - 24 - 144, 8, 144, 18)
			previewMapMood.TextSize = profile.isMobile and 11 or 10
		end
		if previewMapFooter then
			setOffsetBounds(previewMapFooter, 16, 30, previewWidth - 48, 44)
			previewMapFooter.TextSize = profile.isMobile and 14 or 13
		end
		if previewMapStats then
			setOffsetBounds(previewMapStats, 16, previewMapHeight - 24, previewWidth - 48, 16)
			previewMapStats.TextSize = profile.isMobile and 11 or 10
		end
		if previewMapAccent then
			setOffsetBounds(previewMapAccent, 0, 0, 6, previewMapHeight)
		end
		if previewMapGradient then
			previewMapGradient.Rotation = 14
		end

		if roomPreviewPlayersLayout then
			roomPreviewPlayersLayout.FillDirectionMaxCells = 1
			roomPreviewPlayersLayout.CellSize = UDim2.fromOffset(previewWidth - 36, profile.isMobile and 82 or 74)
		end
	else
		local listWidth = math.clamp(math.floor(panelWidth * 0.39), 380, 432)
		local previewX = headerPadding + listWidth + 16
		local previewWidth = panelWidth - previewX - headerPadding
		local actionY = panelHeight - actionStackHeight
		local roomListHeight = actionY - contentTop - 10

		setOffsetBounds(roomList, headerPadding, contentTop, listWidth, roomListHeight)
		setOffsetBounds(roomPreviewPanel, previewX, contentTop, previewWidth, panelHeight - contentTop - headerPadding)
		setOffsetBounds(joinPassword, headerPadding, actionY - 40, listWidth, 30)
		setOffsetBounds(queueButton, headerPadding, actionY, listWidth, 40)
		setOffsetBounds(quickClassicButton, headerPadding, actionY + 44, math.floor((listWidth - 6) * 0.5), 38)
		setOffsetBounds(quickRankedButton, headerPadding + math.floor((listWidth - 6) * 0.5) + 6, actionY + 44, math.floor((listWidth - 6) * 0.5), 38)
		setOffsetBounds(refreshButton, headerPadding, actionY + 86, math.floor((listWidth - 6) * 0.5), 36)
		setOffsetBounds(createRoomButton, headerPadding + math.floor((listWidth - 6) * 0.5) + 6, actionY + 86, math.floor((listWidth - 6) * 0.5), 36)

		local previewHeight = panelHeight - contentTop - headerPadding
		local previewMapHeight = math.clamp(math.floor(previewHeight * 0.32), 112, 136)
		setOffsetBounds(roomPreviewTitle, 12, 10, previewWidth - 24, 20)
		setOffsetBounds(roomPreviewInfo, 12, 32, previewWidth - 24, 20)
		setOffsetBounds(roomPreviewMap, 12, 58, previewWidth - 24, previewMapHeight)
		setOffsetBounds(roomPreviewPlayersTitle, 12, 58 + previewMapHeight + 8, previewWidth - 24, 16)
		setOffsetBounds(roomPreviewPlayersList, 12, 58 + previewMapHeight + 28, previewWidth - 24, previewHeight - (58 + previewMapHeight + 40))
		if previewMapTitle then
			setOffsetBounds(previewMapTitle, 16, 8, previewWidth - 48, 14)
		end
		if previewMapMood then
			setOffsetBounds(previewMapMood, previewWidth - 24 - 148, 8, 148, 18)
		end
		if previewMapFooter then
			setOffsetBounds(previewMapFooter, 16, 30, previewWidth - 48, 46)
		end
		if previewMapStats then
			setOffsetBounds(previewMapStats, 16, previewMapHeight - 24, previewWidth - 48, 16)
		end
		if previewMapAccent then
			setOffsetBounds(previewMapAccent, 0, 0, 6, previewMapHeight)
		end
		if roomPreviewPlayersLayout then
			local cellWidth = math.max(186, math.floor((previewWidth - 38) * 0.5))
			roomPreviewPlayersLayout.FillDirectionMaxCells = 2
			roomPreviewPlayersLayout.CellSize = UDim2.fromOffset(cellWidth, 78)
		end
	end

	if roomPreviewPlayersList then
		roomPreviewPlayersList.ScrollBarThickness = isCompact and 6 or 4
	end
	if roomList then
		roomList.ScrollBarThickness = isCompact and 6 or 4
	end
	if joinPassword then
		joinPassword.TextSize = profile.isMobile and 15 or (isCompact and 14 or 12)
	end
	if refreshButton then
		refreshButton.TextSize = profile.isMobile and 14 or (isCompact and 13 or 12)
	end
	if createRoomButton then
		createRoomButton.TextSize = profile.isMobile and 14 or (isCompact and 13 or 12)
	end
	if queueButton then
		queueButton.TextSize = profile.isMobile and 15 or (isCompact and 14 or 12)
	end
	if quickClassicButton then
		quickClassicButton.TextSize = profile.isMobile and 14 or (isCompact and 13 or 11)
	end
	if quickRankedButton then
		quickRankedButton.TextSize = profile.isMobile and 14 or (isCompact and 13 or 11)
	end

	if roomPanel then
		roomPanel.Position = UDim2.fromOffset(0, 0)
		roomPanel.Size = UDim2.fromScale(1, 1)
		roomPanel.ScrollBarThickness = isCompact and 6 or 4
	end

	if isCompact then
		local contentWidth = panelWidth - headerPadding * 2
		local mapPreviewHeight = profile.isMobile and 188 or 176
		local playersY = 72 + mapPreviewHeight + 30
		local playersHeight = math.clamp(math.floor(panelHeight * (profile.isMobile and 0.25 or 0.24)), profile.isMobile and 160 or 150, profile.isMobile and 210 or 196)
		local controlsY = playersY + playersHeight + 12
		local mapSelectorY = controlsY + (profile.isMobile and 132 or 122)
		local setPasswordY = mapSelectorY + (profile.isMobile and 182 or 162)
		local kickRowY = setPasswordY + (profile.isMobile and 46 or 42)
		local inviteY = kickRowY + (profile.isMobile and 46 or 42)
		local readyY = inviteY + (profile.isMobile and 50 or 46)
		local leaveY = readyY + (profile.isMobile and 52 or 48)
		local roomCanvasHeight = leaveY + 54

		setOffsetBounds(roomTitle, headerPadding, 12, contentWidth, 24)
		setOffsetBounds(roomHost, headerPadding, 38, contentWidth, 18)
		setOffsetBounds(mapPreview, headerPadding, 72, contentWidth, mapPreviewHeight)
		if playersLabel then
			setOffsetBounds(playersLabel, headerPadding, playersY - 20, contentWidth, 18)
			playersLabel.TextSize = 13
		end
		setOffsetBounds(playersList, headerPadding, playersY, contentWidth, playersHeight)
		if playersListLayout then
			playersListLayout.FillDirectionMaxCells = 1
			playersListLayout.CellSize = UDim2.fromOffset(contentWidth - 16, profile.isMobile and 124 or 108)
		end
		setOffsetBounds(modeSelector, headerPadding, controlsY, contentWidth, profile.isMobile and 40 or 36)
		setOffsetBounds(modeDropdown, headerPadding, controlsY + (profile.isMobile and 44 or 40), contentWidth, profile.isMobile and 80 or 72)
		if modeClassicOption then
			setOffsetBounds(modeClassicOption, 8, 8, contentWidth - 16, 26)
			modeClassicOption.TextSize = 12
		end
		if modeRankedOption then
			setOffsetBounds(modeRankedOption, 8, 38, contentWidth - 16, 26)
			modeRankedOption.TextSize = 12
		end
		setOffsetBounds(mapSelector, headerPadding, mapSelectorY, contentWidth, profile.isMobile and 40 or 36)
		setOffsetBounds(rankedTierLabel, headerPadding, mapSelectorY, contentWidth, profile.isMobile and 40 or 36)
		setOffsetBounds(mapDropdown, headerPadding, mapSelectorY + (profile.isMobile and 44 or 40), contentWidth, profile.isMobile and 132 or 112)
		for index, option in ipairs(mapOptions) do
			setOffsetBounds(option, 8, 8 + (index - 1) * (profile.isMobile and 30 or 26), contentWidth - 16, profile.isMobile and 26 or 22)
			option.TextSize = profile.isMobile and 13 or 12
		end
		setOffsetBounds(setPasswordBox, headerPadding, setPasswordY, contentWidth - 122, profile.isMobile and 38 or 34)
		setOffsetBounds(setPasswordButton, headerPadding + contentWidth - 116, setPasswordY, 116, profile.isMobile and 38 or 34)
		setOffsetBounds(kickNameBox, headerPadding, kickRowY, contentWidth - 122, profile.isMobile and 38 or 34)
		setOffsetBounds(kickButton, headerPadding + contentWidth - 116, kickRowY, 116, profile.isMobile and 38 or 34)
		setOffsetBounds(inviteButton, headerPadding, inviteY, contentWidth, profile.isMobile and 40 or 36)
		setOffsetBounds(inviteDropdown, headerPadding, inviteY + (profile.isMobile and 44 or 40), contentWidth, profile.isMobile and 176 or 156)
		setOffsetBounds(readyButton, headerPadding, readyY, contentWidth, profile.isMobile and 46 or 42)
		setOffsetBounds(startButton, headerPadding, readyY, contentWidth, profile.isMobile and 46 or 42)
		setOffsetBounds(cancelStartButton, headerPadding, readyY + (profile.isMobile and 50 or 46), contentWidth, profile.isMobile and 38 or 34)
		setOffsetBounds(panel:FindFirstChild("RoomPanel"):FindFirstChild("LeaveRoomButton"), headerPadding, leaveY, contentWidth, profile.isMobile and 40 or 36)
		roomCanvasHeight = math.max(roomCanvasHeight, inviteY + (profile.isMobile and 224 or 204))
		local compactCanvasHeight = roomCanvasHeight + (profile.isMobile and (bottomRightInset.Y + 36) or 0)
		roomPanel.CanvasSize = UDim2.fromOffset(0, compactCanvasHeight)
	end

	if not isCompact then
		local leftWidth = math.clamp(math.floor((panelWidth - (headerPadding * 2) - 16) * 0.42), 392, 448)
		local rightX = headerPadding + leftWidth + 16
		local rightWidth = panelWidth - rightX - headerPadding
		local hostFooterY = panelHeight - 80

		setOffsetBounds(roomTitle, headerPadding, 12, leftWidth, 24)
		setOffsetBounds(roomHost, headerPadding, 38, leftWidth, 18)
		setOffsetBounds(mapPreview, headerPadding, 72, leftWidth, 208)
		if playersLabel then
			setOffsetBounds(playersLabel, rightX, 12, rightWidth, 16)
			playersLabel.TextSize = 12
		end
		setOffsetBounds(playersList, rightX, 34, rightWidth, panelHeight - 126)
		if playersListLayout then
			local playerCellWidth = math.max(180, math.floor((rightWidth - 18) * 0.5))
			playersListLayout.FillDirectionMaxCells = 2
			playersListLayout.CellSize = UDim2.fromOffset(playerCellWidth, 132)
		end
		setOffsetBounds(modeSelector, headerPadding, 292, leftWidth, 32)
		setOffsetBounds(modeDropdown, headerPadding, 328, leftWidth, 72)
		if modeClassicOption then
			setOffsetBounds(modeClassicOption, 8, 8, leftWidth - 16, 26)
		end
		if modeRankedOption then
			setOffsetBounds(modeRankedOption, 8, 38, leftWidth - 16, 26)
		end
		setOffsetBounds(mapSelector, headerPadding, 406, leftWidth, 32)
		setOffsetBounds(rankedTierLabel, headerPadding, 406, leftWidth, 32)
		setOffsetBounds(mapDropdown, headerPadding, 442, leftWidth, 112)
		for index, option in ipairs(mapOptions) do
			setOffsetBounds(option, 8, 8 + (index - 1) * 26, leftWidth - 16, 22)
		end
		setOffsetBounds(setPasswordBox, headerPadding, 562, leftWidth - 122, 32)
		setOffsetBounds(setPasswordButton, headerPadding + leftWidth - 116, 562, 116, 32)
		setOffsetBounds(kickNameBox, headerPadding, 600, leftWidth - 122, 30)
		setOffsetBounds(kickButton, headerPadding + leftWidth - 116, 600, 116, 30)
		setOffsetBounds(inviteButton, rightX, hostFooterY, rightWidth, 32)
		setOffsetBounds(inviteDropdown, rightX, math.max(220, hostFooterY - 224), rightWidth, 216)
		setOffsetBounds(readyButton, headerPadding, panelHeight - 80, leftWidth, 36)
		setOffsetBounds(startButton, headerPadding, panelHeight - 80, leftWidth, 36)
		setOffsetBounds(cancelStartButton, headerPadding, panelHeight - 40, leftWidth, 28)
		setOffsetBounds(panel:FindFirstChild("RoomPanel"):FindFirstChild("LeaveRoomButton"), headerPadding, panelHeight - 40, leftWidth, 28)
		roomPanel.CanvasSize = UDim2.fromOffset(0, panelHeight)
	end

	if mapPreviewTitle then
		setOffsetBounds(mapPreviewTitle, 10, 8, mapPreview.AbsoluteSize.X - 20, 14)
		mapPreviewTitle.TextSize = isCompact and 10 or 10
	end
	if mapPreviewLabel then
		setOffsetBounds(mapPreviewLabel, 10, 26, mapPreview.AbsoluteSize.X - 20, 16)
		mapPreviewLabel.TextSize = isCompact and 12 or 12
	end
	if mapPreviewImage then
		local imageWidth = math.min(math.floor((mapPreview.AbsoluteSize.X or 200) - 24), isCompact and 240 or 220)
		local imageHeight = isCompact and 126 or 150
		setOffsetBounds(mapPreviewImage, math.floor(((mapPreview.AbsoluteSize.X or imageWidth) - imageWidth) * 0.5), isCompact and 48 or 46, imageWidth, imageHeight)
	end
	if mapPreviewImageChip and mapPreviewImage then
		setOffsetBounds(mapPreviewImageChip, 12, 10, math.min(140, mapPreviewImage.AbsoluteSize.X - 24), 18)
		mapPreviewImageChip.TextSize = 10
	end
	if mapPreviewImageLabel and mapPreviewImage then
		setOffsetBounds(mapPreviewImageLabel, 12, 28, mapPreviewImage.AbsoluteSize.X - 24, isCompact and 58 or 76)
		mapPreviewImageLabel.TextSize = isCompact and 36 or 42
	end
	if mapPreviewImageStats and mapPreviewImage then
		setOffsetBounds(mapPreviewImageStats, 12, mapPreviewImage.AbsoluteSize.Y - 42, mapPreviewImage.AbsoluteSize.X - 24, 16)
		mapPreviewImageStats.TextSize = 10
	end
	if mapPreviewImageFooter and mapPreviewImage then
		setOffsetBounds(mapPreviewImageFooter, 12, mapPreviewImage.AbsoluteSize.Y - 24, mapPreviewImage.AbsoluteSize.X - 24, 18)
		mapPreviewImageFooter.TextSize = 12
	end
	if floatButton then
		local floatSize = profile.isConsole and 84 or (profile.isMobile and 72 or 68)
		floatButton.Size = UDim2.fromOffset(floatSize, floatSize)
		floatButton.Position = UDim2.new(1, -(16 + bottomRightInset.X), isCompact and 0.72 or 0.56, 0)
		floatButton.TextSize = profile.isMobile and 11 or 12
	end
	if countdownLabel then
		countdownLabel.TextSize = isCompact and 72 or 96
	end
	if cancelCountdown then
		cancelCountdown.Size = UDim2.fromOffset(isCompact and 240 or 220, isCompact and 42 or 38)
	end
	if countdownOverlay then
		countdownOverlay.ZIndex = 40
	end
end

function UISystem:_applyDeviceSizing()
	local profile = self._deviceProfile
	if not profile then
		return
	end
	local viewportSize = Vector2.new(1280, 720)
	local camera = Workspace.CurrentCamera
	if camera and typeof(camera.ViewportSize) == "Vector2" then
		viewportSize = camera.ViewportSize
	end
	local viewportOverrideX = tonumber(ReplicatedStorage:GetAttribute(UI_VIEWPORT_OVERRIDE_X_ATTR))
	local viewportOverrideY = tonumber(ReplicatedStorage:GetAttribute(UI_VIEWPORT_OVERRIDE_Y_ATTR))
	if viewportOverrideX and viewportOverrideY and viewportOverrideX > 0 and viewportOverrideY > 0 then
		viewportSize = Vector2.new(math.floor(viewportOverrideX), math.floor(viewportOverrideY))
	end
	local topLeftInset, bottomRightInset = resolveSafeInsets()
	local lobby = self._uxWidgets.lobby
	if lobby and lobby.PlayButton and lobby.FeedbackLabel then
		local buttonSize = profile:GetButtonSize()
		lobby.PlayButton.Size = UDim2.fromOffset(buttonSize.X, buttonSize.Y)
		lobby.PlayButton.TextSize = profile:GetTextSize()
		lobby.FeedbackLabel.TextSize = math.max(16, profile:GetTextSize() - 2)
	end
	if lobby and lobby.BasicOpenRoomBrowserButton and lobby.BasicPrimaryLabel then
		local lobbyWidth = (profile.isMobile or viewportSize.X <= 1280)
			and math.min(viewportSize.X - (profile.isMobile and 12 or 28), profile.isMobile and 408 or 396)
			or 340
		local lobbyHeight = profile.isMobile and 424 or ((viewportSize.X <= 1280) and 384 or 368)
		local panelWidth = math.max(profile.isMobile and 348 or 340, math.floor(lobbyWidth))
		local panelHeight = math.max(profile.isMobile and 404 or 368, math.floor(lobbyHeight))
		if lobby.BasicPanel then
			lobby.BasicPanel.Position = UDim2.fromOffset(12 + topLeftInset.X, 12 + topLeftInset.Y)
			lobby.BasicPanel.Size = UDim2.fromOffset(panelWidth, panelHeight)
		end
		if lobby.ToggleButton then
			lobby.ToggleButton.Position = UDim2.fromOffset(12 + topLeftInset.X + panelWidth + 8, 120 + topLeftInset.Y)
		end
		if lobby.BasicHeaderCard then
			lobby.BasicHeaderCard.Size = UDim2.new(1, -24, 0, profile.isMobile and 120 or 112)
		end
		local halfButtonWidth = math.floor((panelWidth - 36) * 0.5)
		local rightButtonX = 12 + halfButtonWidth + 12
		lobby.BasicOpenRoomBrowserButton.Size = UDim2.new(1, -24, 0, profile.isMobile and 50 or 42)
		if lobby.BasicProfileButton then
			lobby.BasicProfileButton.Position = UDim2.fromOffset(12, profile.isMobile and 222 or 214)
			lobby.BasicProfileButton.Size = UDim2.fromOffset(halfButtonWidth, profile.isMobile and 40 or 36)
		end
		if lobby.BasicShopButton then
			lobby.BasicShopButton.Position = UDim2.fromOffset(rightButtonX, profile.isMobile and 222 or 214)
			lobby.BasicShopButton.Size = UDim2.fromOffset(halfButtonWidth, profile.isMobile and 40 or 36)
		end
		if lobby.BasicRoyalPassButton then
			lobby.BasicRoyalPassButton.Position = UDim2.fromOffset(12, profile.isMobile and 272 or 262)
			lobby.BasicRoyalPassButton.Size = UDim2.new(1, -24, 0, profile.isMobile and 40 or 36)
		end
		if lobby.BasicMenuButton then
			lobby.BasicMenuButton.Position = UDim2.fromOffset(12, profile.isMobile and 320 or 304)
			lobby.BasicMenuButton.Size = UDim2.fromOffset(halfButtonWidth, profile.isMobile and 40 or 36)
		end
		if lobby.BasicRankButton then
			lobby.BasicRankButton.Position = UDim2.fromOffset(rightButtonX, profile.isMobile and 320 or 304)
			lobby.BasicRankButton.Size = UDim2.fromOffset(halfButtonWidth, profile.isMobile and 40 or 36)
		end
		if lobby.BasicHintLabel then
			lobby.BasicHintLabel.Position = UDim2.fromOffset(12, profile.isMobile and 370 or 348)
			lobby.BasicHintLabel.Size = UDim2.new(1, -24, 0, profile.isMobile and 28 or 22)
		end
		lobby.BasicOpenRoomBrowserButton.TextSize = profile.isMobile and math.max(15, profile:GetTextSize() - 1) or math.max(14, profile:GetTextSize() - 2)
		if lobby.BasicProfileButton then
			lobby.BasicProfileButton.TextSize = profile.isMobile and math.max(14, profile:GetTextSize() - 2) or math.max(13, profile:GetTextSize() - 4)
		end
		if lobby.BasicShopButton then
			lobby.BasicShopButton.TextSize = profile.isMobile and math.max(14, profile:GetTextSize() - 2) or math.max(13, profile:GetTextSize() - 4)
		end
		if lobby.BasicRoyalPassButton then
			lobby.BasicRoyalPassButton.TextSize = profile.isMobile and math.max(14, profile:GetTextSize() - 2) or math.max(13, profile:GetTextSize() - 4)
		end
		if lobby.BasicMenuButton then
			lobby.BasicMenuButton.TextSize = profile.isMobile and math.max(14, profile:GetTextSize() - 2) or math.max(13, profile:GetTextSize() - 4)
		end
		if lobby.BasicRankButton then
			lobby.BasicRankButton.TextSize = profile.isMobile and math.max(14, profile:GetTextSize() - 2) or math.max(13, profile:GetTextSize() - 4)
		end
		if lobby.BasicPrimaryLabel then
			lobby.BasicPrimaryLabel.TextSize = math.max(15, profile:GetTextSize() - 2)
		end
		if lobby.BasicSecondaryLabel then
			lobby.BasicSecondaryLabel.TextSize = math.max(12, profile:GetTextSize() - 5)
		end
		if lobby.BasicHintLabel then
			lobby.BasicHintLabel.TextSize = math.max(11, profile:GetTextSize() - 6)
		end
		if lobby.BasicStatusBadge then
			lobby.BasicStatusBadge.TextSize = math.max(11, profile:GetTextSize() - 7)
		end
	end

	local match = self._uxWidgets.match
	if match and match.MessageLabel and match.ObjectiveLabel then
		match.MessageLabel.TextSize = profile:GetTextSize() + 8
		match.ObjectiveLabel.TextSize = profile:GetTextSize()
	end
	if match and match.BasicPrimaryLabel and match.BasicSecondaryLabel then
		local matchCompact = profile.isMobile or viewportSize.X <= 960
		local panelWidth = matchCompact
			and math.min(viewportSize.X - (profile.isMobile and 12 or 28), profile.isMobile and 420 or 396)
			or 340
		local panelHeight = matchCompact
			and math.min(viewportSize.Y - (topLeftInset.Y + bottomRightInset.Y + 20), profile.isMobile and 544 or 500)
			or 454
		local resolvedPanelWidth = math.max(matchCompact and 320 or 340, math.floor(panelWidth))
		local resolvedPanelHeight = math.max(matchCompact and 428 or 454, math.floor(panelHeight))
		local bottomActionY = resolvedPanelHeight - (matchCompact and 50 or 58)
		local footerX = matchCompact and 12 or 166
		local footerWidth = matchCompact and (resolvedPanelWidth - 24) or (resolvedPanelWidth - 178)
		local summaryY = matchCompact and 182 or 168
		local summaryHeight = resolvedPanelHeight - summaryY - (matchCompact and 86 or 76)

		if match.BasicPanel then
			if matchCompact then
				match.BasicPanel.AnchorPoint = Vector2.new(0.5, 0)
				match.BasicPanel.Position = UDim2.new(0.5, 0, 0, 12 + topLeftInset.Y)
			else
				match.BasicPanel.AnchorPoint = Vector2.new(1, 0)
				match.BasicPanel.Position = UDim2.new(1, -(16 + bottomRightInset.X), 0, 16 + topLeftInset.Y)
			end
			match.BasicPanel.Size = UDim2.fromOffset(resolvedPanelWidth, resolvedPanelHeight)
		end
		if match.HeaderCard then
			match.HeaderCard.Position = UDim2.fromOffset(12, 42)
			match.HeaderCard.Size = UDim2.new(1, -24, 0, matchCompact and 130 or 118)
		end
		if match.PhaseGlyph then
			match.PhaseGlyph.Size = UDim2.fromOffset(matchCompact and 96 or 84, matchCompact and 82 or 74)
			match.PhaseGlyph.TextSize = matchCompact and 58 or 52
		end
		if match.BasicStateBadge then
			match.BasicStateBadge.Position = UDim2.fromOffset(14, 12)
			match.BasicStateBadge.Size = UDim2.fromOffset(matchCompact and 154 or 144, matchCompact and 28 or 26)
			match.BasicStateBadge.TextSize = math.max(11, profile:GetTextSize() - 3)
		end
		if match.BasicPrimaryLabel then
			match.BasicPrimaryLabel.Position = UDim2.fromOffset(14, matchCompact and 50 or 46)
			match.BasicPrimaryLabel.Size = UDim2.new(1, matchCompact and -122 or -112, 0, matchCompact and 38 or 32)
		end
		if match.BasicSecondaryLabel then
			match.BasicSecondaryLabel.Position = UDim2.fromOffset(14, matchCompact and 88 or 78)
			match.BasicSecondaryLabel.Size = UDim2.new(1, matchCompact and -122 or -112, 0, matchCompact and 34 or 30)
		end
		if match.SummaryFrame then
			match.SummaryFrame.Position = UDim2.fromOffset(12, summaryY)
			match.SummaryFrame.Size = UDim2.new(1, -24, 0, math.max(152, summaryHeight))
		end
		if match.BasicHideButton then
			match.BasicHideButton.Position = UDim2.fromOffset(12, bottomActionY)
			match.BasicHideButton.Size = UDim2.fromOffset(matchCompact and 156 or 144, matchCompact and 38 or 40)
			match.BasicHideButton.TextSize = math.max(12, profile:GetTextSize() - 4)
		end
		if match.BasicFooterLabel then
			match.BasicFooterLabel.Position = UDim2.fromOffset(footerX, bottomActionY)
			match.BasicFooterLabel.Size = UDim2.fromOffset(math.max(124, footerWidth), matchCompact and 38 or 40)
		end
		if match.BasicCloseButton then
			match.BasicCloseButton.Position = UDim2.new(1, -10, 0, 8)
			match.BasicCloseButton.Size = UDim2.fromOffset(matchCompact and 30 or 28, matchCompact and 30 or 28)
		end
		match.BasicPrimaryLabel.TextSize = math.max(16, profile:GetTextSize())
		match.BasicSecondaryLabel.TextSize = math.max(13, profile:GetTextSize() - 2)
		if match.BasicFooterLabel then
			match.BasicFooterLabel.TextSize = math.max(12, profile:GetTextSize() - 3)
		end
		if match.BasicStateBadge then
			match.BasicStateBadge.TextSize = math.max(11, profile:GetTextSize() - 4)
		end
		if match.BasicFloatButton then
			local floatSize = profile.isConsole and 74 or (profile.isMobile and 68 or 66)
			match.BasicFloatButton.Size = UDim2.fromOffset(floatSize, floatSize)
			match.BasicFloatButton.Position = UDim2.new(1, -(16 + bottomRightInset.X), matchCompact and 0.72 or 0.68, 0)
		end
	end
	if match and match.ResultsTitle and match.ResultsStatus then
		match.ResultsTitle.TextSize = math.max(22, profile:GetTextSize() + 6)
		match.ResultsStatus.TextSize = math.max(12, profile:GetTextSize() - 3)
		if match.ResultsSubtitle then
			match.ResultsSubtitle.TextSize = math.max(15, profile:GetTextSize() - 1)
		end
		if match.ResultsFooter then
			match.ResultsFooter.TextSize = math.max(13, profile:GetTextSize() - 2)
		end
	end
	if match and match.TimerLabel then
		local timerWidth = profile.isMobile and 148 or 126
		local timerHeight = profile.isMobile and 44 or 40
		match.TimerLabel.Size = UDim2.fromOffset(timerWidth, timerHeight)
		match.TimerLabel.Position = UDim2.new(0.5, 0, 0, 14 + topLeftInset.Y)
		match.TimerLabel.TextSize = profile.isMobile and 26 or 24
	end
	if match and match.TimerCaption then
		match.TimerCaption.Position = UDim2.new(0.5, 0, 0, (profile.isMobile and 60 or 58) + topLeftInset.Y)
		match.TimerCaption.Size = UDim2.fromOffset(profile.isMobile and 190 or 170, 18)
		match.TimerCaption.TextSize = profile.isMobile and 12 or 11
	end
	if match and match.EvidenceQuickButton then
		local quickWidth = profile.isMobile and math.min(viewportSize.X - 24, 188) or 142
		local quickHeight = profile.isMobile and 52 or 48
		match.EvidenceQuickButton.Size = UDim2.fromOffset(math.floor(quickWidth), quickHeight)
		match.EvidenceQuickButton.Position = UDim2.new(1, -(14 + bottomRightInset.X), 1, -(14 + bottomRightInset.Y))
		match.EvidenceQuickButton.TextSize = profile.isMobile and 13 or 12
	end
	if match and match.ControlsHintBar then
		local hintWidth = math.min(viewportSize.X - (profile.isMobile and 20 or 40), 620)
		match.ControlsHintBar.Size = UDim2.fromOffset(math.max(280, math.floor(hintWidth)), profile.isMobile and 40 or 34)
		match.ControlsHintBar.Position = UDim2.new(0.5, 0, 1, -(12 + bottomRightInset.Y))
	end
	if match and match.ControlsHintLabel then
		match.ControlsHintLabel.TextSize = profile.isMobile and 13 or 12
	end
	if match and match.FieldKitFrame then
		local kitWidth = profile.isMobile and math.min(viewportSize.X - 20, 420) or 356
		local kitHeight = profile.isMobile and 154 or 146
		match.FieldKitFrame.Size = UDim2.fromOffset(math.max(profile.isMobile and 316 or 332, math.floor(kitWidth)), kitHeight)
		if profile.isMobile then
			match.FieldKitFrame.AnchorPoint = Vector2.new(0.5, 1)
			match.FieldKitFrame.Position = UDim2.new(0.5, 0, 1, -(60 + bottomRightInset.Y))
		else
			match.FieldKitFrame.AnchorPoint = Vector2.new(0, 1)
			match.FieldKitFrame.Position = UDim2.new(0, 14 + topLeftInset.X, 1, -(58 + bottomRightInset.Y))
		end
	end
	if match and match.FieldKitTitle then
		match.FieldKitTitle.Position = UDim2.fromOffset(12, 10)
		match.FieldKitTitle.Size = UDim2.new(1, -24, 0, 18)
		match.FieldKitTitle.TextSize = profile.isMobile and 12 or 11
	end
	if match and match.FieldKitButtonsFrame then
		match.FieldKitButtonsFrame.Position = UDim2.fromOffset(12, 34)
		match.FieldKitButtonsFrame.Size = UDim2.new(1, -24, 0, profile.isMobile and 58 or 56)
	end
	if match and match.FieldKitGrid and match.FieldKitFrame then
		local availableWidth = math.max(280, match.FieldKitFrame.Size.X.Offset - 24)
		local toolCount = math.max(1, #FIELD_KIT_TOOL_ORDER)
		local cellPadding = profile.isMobile and 6 or 6
		local cellWidth = math.floor((availableWidth - (cellPadding * math.max(0, toolCount - 1))) / toolCount)
		local minCellWidth = toolCount >= 5 and 56 or (profile.isMobile and 72 or 76)
		match.FieldKitGrid.CellPadding = UDim2.fromOffset(cellPadding, 0)
		match.FieldKitGrid.CellSize = UDim2.fromOffset(math.max(minCellWidth, cellWidth), profile.isMobile and 58 or 56)
	end
	if match and match.FieldKitStatusLabel then
		match.FieldKitStatusLabel.Position = UDim2.fromOffset(12, profile.isMobile and 100 or 98)
		match.FieldKitStatusLabel.Size = UDim2.new(1, -24, 0, profile.isMobile and 40 or 36)
		match.FieldKitStatusLabel.TextSize = profile.isMobile and 12 or 11
	end
	if self._uxWidgets and self._uxWidgets.windows then
		for _, guiName in ipairs(AUXILIARY_UI_NAMES) do
			local window = self._uxWidgets.windows[guiName]
			if window then
				if window.Panel and (guiName == "RoyalPassUI" or guiName == "ProfileUI" or guiName == "ShopUI") then
					local width = guiName == "ShopUI" and 356 or 364
					local height = guiName == "ProfileUI" and 320 or 420
					if profile.isMobile then
						width = viewportSize.X - (topLeftInset.X + bottomRightInset.X)
						height = viewportSize.Y - (topLeftInset.Y + bottomRightInset.Y)
					elseif guiName == "RoyalPassUI" and viewportSize.X <= 1280 then
						width = math.min(viewportSize.X - 28, 436)
						height = math.min(viewportSize.Y - (topLeftInset.Y + bottomRightInset.Y + 36), 520)
					end
					window.Panel.Size = UDim2.fromOffset(
						math.max(profile.isMobile and 352 or width, math.floor(width)),
						math.max(profile.isMobile and 560 or height, math.floor(height))
					)
					window.Panel.BackgroundTransparency = profile.isMobile and 0.04 or 0.08
					if profile.isMobile then
						window.Panel.AnchorPoint = Vector2.new(0, 0)
						window.Panel.Position = UDim2.fromOffset(topLeftInset.X, topLeftInset.Y)
					elseif guiName == "RoyalPassUI" then
						window.Panel.AnchorPoint = Vector2.new(1, 0.5)
						window.Panel.Position = UDim2.new(1, -(16 + bottomRightInset.X), 0.5, 0)
					end
					if profile.isMobile and window.FooterLabel then
						window.FooterLabel.Position = UDim2.fromOffset(12, window.Panel.Size.Y.Offset - 48)
						window.FooterLabel.Size = UDim2.new(1, -24, 0, 36)
					end
				end
				if window.PrimaryLabel then
					window.PrimaryLabel.TextSize = math.max(15, profile:GetTextSize() - 1)
					if guiName == "RoyalPassUI" then
						window.PrimaryLabel.TextSize = math.max(window.PrimaryLabel.TextSize, 17)
					end
				end
				if window.SecondaryLabel then
					window.SecondaryLabel.TextSize = math.max(12, profile:GetTextSize() - 5)
					if guiName == "RoyalPassUI" then
						window.SecondaryLabel.TextSize = math.max(window.SecondaryLabel.TextSize, 13)
					end
				end
				if window.ContentText then
					window.ContentText.TextSize = math.max(12, profile:GetTextSize() - 5)
				end
				if window.FooterLabel then
					window.FooterLabel.TextSize = math.max(11, profile:GetTextSize() - 6)
				end
				if window.StatusBadge then
					window.StatusBadge.TextSize = math.max(11, profile:GetTextSize() - 7)
				end
				if window.FloatButton then
					local floatSize = profile.isConsole and 70 or (profile.isMobile and 64 or 60)
					window.FloatButton.Size = UDim2.fromOffset(floatSize, floatSize)
				end
				if guiName == "RoyalPassUI" and window.RoyalPassWidgets then
					local widgets = window.RoyalPassWidgets
					local passMobile = profile.isMobile or viewportSize.X <= 960
					local heroHeight = passMobile and 168 or 130
					local scrollerHeight = passMobile and 236 or 178
					local trackCardWidth = passMobile and 172 or 140
					local trackCardHeight = passMobile and 184 or 156

					if widgets.HeroCard then
						widgets.HeroCard.Size = UDim2.new(1, 0, 0, heroHeight)
					end
					if widgets.HeroBadge then
						widgets.HeroBadge.Size = UDim2.fromOffset(passMobile and 128 or 112, passMobile and 22 or 20)
						widgets.HeroBadge.TextSize = passMobile and 12 or 10
					end
					if widgets.HeroTitle then
						widgets.HeroTitle.Position = UDim2.fromOffset(12, 38)
						widgets.HeroTitle.Size = UDim2.new(1, -24, 0, passMobile and 32 or 24)
						widgets.HeroTitle.TextSize = passMobile and 24 or 20
					end
					if widgets.HeroMeta then
						widgets.HeroMeta.Position = UDim2.fromOffset(12, passMobile and 72 or 62)
						widgets.HeroMeta.Size = UDim2.new(1, -24, 0, passMobile and 22 or 18)
						widgets.HeroMeta.TextSize = passMobile and 13 or 12
					end
					if widgets.ProgressTrack then
						widgets.ProgressTrack.Position = UDim2.fromOffset(12, passMobile and 102 or 86)
						widgets.ProgressTrack.Size = UDim2.new(1, -24, 0, passMobile and 18 or 14)
					end
					if widgets.ProgressCaption then
						widgets.ProgressCaption.Position = UDim2.fromOffset(12, passMobile and 126 or 104)
						widgets.ProgressCaption.Size = UDim2.new(1, -(passMobile and 176 or 148), 0, passMobile and 22 or 18)
						widgets.ProgressCaption.TextSize = passMobile and 13 or 11
					end
					if widgets.PremiumActionButton then
						widgets.PremiumActionButton.Size = UDim2.fromOffset(passMobile and 148 or 124, passMobile and 40 or 34)
						widgets.PremiumActionButton.TextSize = passMobile and 14 or 12
					end
					if widgets.TrackTabs then
						widgets.TrackTabs.Size = UDim2.new(1, 0, 0, passMobile and 44 or 34)
					end
					if widgets.RewardTab then
						widgets.RewardTab.TextSize = passMobile and 14 or 12
					end
					if widgets.MissionTab then
						widgets.MissionTab.TextSize = passMobile and 14 or 12
					end
					if widgets.TrackHint then
						widgets.TrackHint.Size = UDim2.new(1, 0, 0, passMobile and 34 or 18)
						widgets.TrackHint.TextSize = passMobile and 12 or 11
						widgets.TrackHint.TextWrapped = passMobile
					end
					if widgets.TrackScroller then
						widgets.TrackScroller.Size = UDim2.new(1, 0, 0, scrollerHeight)
						widgets.TrackScroller.ScrollBarThickness = passMobile and 8 or 5
					end
					local totalCards = #(widgets.TrackCards or {})
					for index, card in ipairs(widgets.TrackCards or {}) do
						local cardWidth = (index == totalCards)
							and (trackCardWidth + (passMobile and 24 or 18))
							or trackCardWidth
						if card.Root then
							card.Root.Size = UDim2.fromOffset(cardWidth, trackCardHeight)
						end
						if card.Title then
							card.Title.TextSize = passMobile and 16 or 14
						end
						if card.Meta then
							card.Meta.TextSize = passMobile and 12 or 11
						end
						if card.RewardPill then
							card.RewardPill.TextSize = passMobile and 11 or 10
						end
						if card.Footer then
							card.Footer.TextSize = passMobile and 10 or 9
						end
					end
				end
				if window.ItemRows then
					for _, row in ipairs(window.ItemRows) do
						if row.Title then
							row.Title.TextSize = math.max(12, profile:GetTextSize() - 6)
						end
						if row.Meta then
							row.Meta.TextSize = math.max(10, profile:GetTextSize() - 8)
						end
						if row.Button then
							row.Button.TextSize = math.max(12, profile:GetTextSize() - 6)
						end
					end
				end
			end
		end
	end
	if self._uxWidgets and self._uxWidgets.basicWindows then
		for guiName, window in pairs(self._uxWidgets.basicWindows) do
			if window.PrimaryLabel then
				window.PrimaryLabel.TextSize = math.max(15, profile:GetTextSize() - 1)
			end
			if window.SecondaryLabel then
				window.SecondaryLabel.TextSize = math.max(12, profile:GetTextSize() - 5)
			end
			if window.ContentText then
				window.ContentText.TextSize = math.max(12, profile:GetTextSize() - 5)
			end
			if window.FooterLabel then
				window.FooterLabel.TextSize = math.max(11, profile:GetTextSize() - 6)
			end
			if window.StatusBadge then
				window.StatusBadge.TextSize = math.max(11, profile:GetTextSize() - 7)
			end
			if window.FloatButton then
				local floatSize = profile.isConsole and 70 or (profile.isMobile and 64 or 60)
				window.FloatButton.Size = UDim2.fromOffset(floatSize, floatSize)
			end
			if window.Panel and (guiName == "MainMenuUI" or guiName == "LeaderboardUI") and profile.isMobile then
				local isMenu = guiName == "MainMenuUI"
				local availableWidth = viewportSize.X - (topLeftInset.X + bottomRightInset.X)
				local availableHeight = viewportSize.Y - (topLeftInset.Y + bottomRightInset.Y)
				local panelWidth = math.max(352, math.floor(availableWidth))
				local panelHeight = isMenu and math.min(428, math.max(404, availableHeight)) or math.max(560, math.floor(availableHeight))
				window.Panel.AnchorPoint = Vector2.new(0, 0)
				window.Panel.Position = UDim2.fromOffset(topLeftInset.X, topLeftInset.Y)
				window.Panel.Size = UDim2.fromOffset(panelWidth, panelHeight)
				window.Panel.BackgroundTransparency = 0.04

				if window.Title then
					setOffsetBounds(window.Title, 12, 10, panelWidth - 60, 26)
					window.Title.TextSize = 20
				end
				if window.CloseButton then
					setOffsetBounds(window.CloseButton, panelWidth - 46, 10, 34, 30)
					window.CloseButton.TextSize = 16
				end
				if window.StatusBadge then
					setOffsetBounds(window.StatusBadge, 12, 44, 140, 24)
					window.StatusBadge.TextSize = 12
				end
				if window.PrimaryLabel then
					setOffsetBounds(window.PrimaryLabel, 12, 76, panelWidth - 24, 38)
				end
				if window.SecondaryLabel then
					setOffsetBounds(window.SecondaryLabel, 12, 118, panelWidth - 24, 34)
				end
				if isMenu then
					local buttonWidth = math.floor((panelWidth - 36) * 0.5)
					local buttonHeight = 54
					local rightX = 12 + buttonWidth + 12
					if window.RoomBrowserButton then
						setOffsetBounds(window.RoomBrowserButton, 12, 168, buttonWidth, buttonHeight)
					end
					if window.ProfileButton then
						setOffsetBounds(window.ProfileButton, rightX, 168, buttonWidth, buttonHeight)
					end
					if window.ShopButton then
						setOffsetBounds(window.ShopButton, 12, 232, buttonWidth, buttonHeight)
					end
					if window.RankButton then
						setOffsetBounds(window.RankButton, rightX, 232, buttonWidth, buttonHeight)
					end
					if window.FooterLabel then
						setOffsetBounds(window.FooterLabel, 12, panelHeight - 44, panelWidth - 24, 28)
					end
				else
					local contentHeight = math.max(260, panelHeight - 256)
					local actionY = panelHeight - 74
					local buttonWidth = math.floor((panelWidth - 36) / 3)
					if window.ContentFrame then
						setOffsetBounds(window.ContentFrame, 12, 156, panelWidth - 24, contentHeight)
						window.ContentFrame.ScrollBarThickness = 8
					end
					if window.ProfileButton then
						setOffsetBounds(window.ProfileButton, 12, actionY, buttonWidth, 42)
					end
					if window.RoomBrowserButton then
						setOffsetBounds(window.RoomBrowserButton, 18 + buttonWidth, actionY, buttonWidth, 42)
					end
					if window.MenuButton then
						setOffsetBounds(window.MenuButton, 24 + buttonWidth * 2, actionY, buttonWidth, 42)
					end
					if window.FooterLabel then
						setOffsetBounds(window.FooterLabel, 12, panelHeight - 26, panelWidth - 24, 18)
					end
				end
			end
			if window.ActionButtons then
				for _, button in ipairs(window.ActionButtons) do
					if button then
						button.TextSize = profile.isMobile and math.max(13, profile:GetTextSize() - 4) or math.max(12, profile:GetTextSize() - 5)
					end
				end
			end
		end
	end

	self:_applyRoomBrowserSizing(profile, viewportSize, topLeftInset, bottomRightInset)
	self:_layoutLobbyFloatRail()
end

function UISystem:_runPostTeleportLoadingFlow()
	if self._postTeleportFlowRunning then
		return
	end
	if self._hasPostTeleportLoaded then
		return
	end

	local player = Players.LocalPlayer
	if not player or player:GetAttribute("InMatch") ~= true then
		return
	end
	if self._matchPhase == MATCH_PHASE.INGAME or self._matchPhase == MATCH_PHASE.HUNT then
		self._hasPostTeleportLoaded = true
		self._awaitingPostTeleportFlow = false
		return
	end

	self._postTeleportFlowToken += 1
	local flowToken = self._postTeleportFlowToken
	self._postTeleportFlowRunning = true
	task.spawn(function()
		if self._postTeleportFlowToken ~= flowToken then
			return
		end
		self:_setPhase(MATCH_PHASE.LOADING)
		task.wait(2)

		if self._postTeleportFlowToken ~= flowToken then
			return
		end

		local currentPlayer = Players.LocalPlayer
		if not currentPlayer or currentPlayer:GetAttribute("InMatch") ~= true then
			self._postTeleportFlowRunning = false
			return
		end

		self:_setPhase(MATCH_PHASE.BRIEFING)
		task.wait(3)

		if self._postTeleportFlowToken ~= flowToken then
			return
		end

		currentPlayer = Players.LocalPlayer
		if currentPlayer and currentPlayer:GetAttribute("InMatch") == true then
			self._hasPostTeleportLoaded = true
			self._awaitingPostTeleportFlow = false
			if self._pendingInGamePayload then
				self:_setPhase(MATCH_PHASE.INGAME, self._pendingInGamePayload)
				self._pendingInGamePayload = nil
			end
		end

		self._postTeleportFlowRunning = false
	end)
end

function UISystem:_cancelPostTeleportLoadingFlow(markLoaded)
	self._postTeleportFlowToken += 1
	self._postTeleportFlowRunning = false
	self._awaitingPostTeleportFlow = false
	self._pendingInGamePayload = nil
	if markLoaded ~= nil then
		self._hasPostTeleportLoaded = markLoaded == true
	end
end

function UISystem:_onMarketplacePromptFinished(purchaseType, productId, wasPurchased)
	local pending = self._shopState.pendingMarketplacePrompt
	if type(pending) ~= "table" then
		return
	end
	if pending.purchaseType ~= purchaseType then
		return
	end
	if tonumber(pending.productId) ~= tonumber(productId) then
		return
	end
	if wasPurchased == true then
		self._shopState.lastMessage = "Pembelian dikirim. Menunggu konfirmasi server..."
		return
	end

	self._shopState.pendingMarketplacePrompt = nil
	self._shopState.lastPurchase = {
		itemId = pending.itemId,
		success = false,
		reason = "purchase_cancelled",
		requestId = pending.requestId,
	}
	self._shopState.lastMessage = "Prompt pembelian ditutup."
	self:_openAuxiliaryWindow("ShopUI")
end

function UISystem:_requestMarketplacePrompt(payload)
	local purchaseType = payload and payload.purchaseType
	local productId = tonumber(payload and payload.productId)
	local itemId = payload and payload.itemId
	if type(purchaseType) ~= "string" or not productId or productId <= 0 then
		self._shopState.lastPurchase = {
			itemId = itemId,
			success = false,
			reason = "marketplace_prompt_invalid",
			requestId = payload and payload.requestId or nil,
		}
		self._shopState.lastMessage = "Prompt Roblox tidak valid."
		return
	end

	self._shopState.pendingMarketplacePrompt = {
		itemId = itemId,
		purchaseType = purchaseType,
		productId = productId,
		requestId = payload and payload.requestId or nil,
	}
	self._shopState.lastPurchase = {
		itemId = itemId,
		success = nil,
		reason = "prompting",
		requestId = payload and payload.requestId or nil,
	}
	self._shopState.lastMessage = string.format("Membuka prompt %s untuk %s...", tostring(purchaseType), tostring(itemId or "-"))

	local ok, err = pcall(function()
		if purchaseType == "GamePass" then
			MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, productId)
		elseif purchaseType == "DeveloperProduct" then
			MarketplaceService:PromptProductPurchase(Players.LocalPlayer, productId)
		else
			error("unsupported_purchase_type")
		end
	end)

	if not ok then
		self._shopState.pendingMarketplacePrompt = nil
		self._shopState.lastPurchase = {
			itemId = itemId,
			success = false,
			reason = "marketplace_prompt_failed",
			requestId = payload and payload.requestId or nil,
		}
		self._shopState.lastMessage = "Gagal membuka prompt Roblox: " .. tostring(err)
	end

	self:_openAuxiliaryWindow("ShopUI")
end

function UISystem:_bindPostTeleportLoading()
	local player = Players.LocalPlayer
	if not player then
		return
	end

	table.insert(self._connections, player.CharacterAdded:Connect(function()
		if self._awaitingPostTeleportFlow or self._hasPostTeleportLoaded ~= true then
			self:_runPostTeleportLoadingFlow()
		end
	end))
end

function UISystem:_setPhase(newPhase, payload)
	payload = decoratePhasePayload(payload)
	local phaseChanged = self._matchPhase ~= newPhase
	self._matchPhase = newPhase
	self._phasePayload = payload
	self._phaseStartTime = (payload and payload._clientReceivedAt) or tick()
	self._phaseDuration = (payload and (payload.durationSeconds or payload.duration)) or nil
	if newPhase == MATCH_PHASE.LOADING then
		self._loadingStartTime = tick()
	end
	local localPlayer = Players.LocalPlayer
	if phaseChanged and localPlayer then
		localPlayer:SetAttribute("MatchPhase", newPhase)
	end

	self:_syncRoomBrowserSuppressionFromMatchContext()
	self:_renderPhase(newPhase, payload)
end

function UISystem:_ensureLoadingScreen()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return nil
	end

	local existing = playerGui:FindFirstChild("MatchLoadingUI")
	if existing and existing:IsA("ScreenGui") then
		return existing
	end

	local screen = Instance.new("ScreenGui")
	screen.Name = "MatchLoadingUI"
	screen.IgnoreGuiInset = true
	screen.ResetOnSpawn = false
	screen.DisplayOrder = 500
	screen.Enabled = false

	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(6, 9, 14)
	bg.BackgroundTransparency = 0.14
	bg.BorderSizePixel = 0
	bg.Parent = screen

	local shade = Instance.new("Frame")
	shade.Name = "Shade"
	shade.Size = UDim2.fromScale(1, 1)
	shade.BackgroundColor3 = Color3.new(0, 0, 0)
	shade.BackgroundTransparency = 0.38
	shade.BorderSizePixel = 0
	shade.Parent = bg

	local status = Instance.new("TextLabel")
	status.Name = "StatusLabel"
	status.AnchorPoint = Vector2.new(0.5, 0)
	status.Position = UDim2.fromScale(0.5, 0.14)
	status.Size = UDim2.fromOffset(280, 28)
	status.BackgroundTransparency = 1
	status.Text = "BERMAIN"
	status.TextColor3 = Color3.fromRGB(185, 198, 214)
	status.Font = Enum.Font.GothamSemibold
	status.TextSize = 18
	status.Parent = bg

	local title = Instance.new("TextLabel")
	title.Name = "TitleLabel"
	title.AnchorPoint = Vector2.new(0.5, 0)
	title.Position = UDim2.fromScale(0.5, 0.22)
	title.Size = UDim2.fromOffset(760, 64)
	title.BackgroundTransparency = 1
	title.Text = "Masuk ke lokasi..."
	title.TextColor3 = Color3.fromRGB(245, 245, 245)
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 38
	title.Parent = bg

	local mapName = Instance.new("TextLabel")
	mapName.Name = "MapNameLabel"
	mapName.AnchorPoint = Vector2.new(0.5, 0)
	mapName.Position = UDim2.fromScale(0.5, 0.33)
	mapName.Size = UDim2.fromOffset(760, 34)
	mapName.BackgroundTransparency = 1
	mapName.Text = "Lokasi: -"
	mapName.TextColor3 = Color3.fromRGB(202, 214, 228)
	mapName.Font = Enum.Font.GothamSemibold
	mapName.TextSize = 20
	mapName.Parent = bg

	local tip = Instance.new("TextLabel")
	tip.Name = "TipLabel"
	tip.AnchorPoint = Vector2.new(0.5, 0)
	tip.Position = UDim2.fromScale(0.5, 0.46)
	tip.Size = UDim2.fromOffset(860, 72)
	tip.BackgroundTransparency = 1
	tip.TextWrapped = true
	tip.Text = LOADING_TIPS[1]
	tip.TextColor3 = Color3.fromRGB(221, 229, 239)
	tip.Font = Enum.Font.Gotham
	tip.TextSize = 18
	tip.Parent = bg

	local progressTrack = Instance.new("Frame")
	progressTrack.Name = "ProgressTrack"
	progressTrack.AnchorPoint = Vector2.new(0.5, 0)
	progressTrack.Position = UDim2.fromScale(0.5, 0.66)
	progressTrack.Size = UDim2.fromOffset(520, 16)
	progressTrack.BackgroundColor3 = Color3.fromRGB(34, 42, 56)
	progressTrack.BorderSizePixel = 0
	progressTrack.Parent = bg

	local progressTrackCorner = Instance.new("UICorner")
	progressTrackCorner.CornerRadius = UDim.new(0, 999)
	progressTrackCorner.Parent = progressTrack

	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.fromScale(0.08, 1)
	progressFill.BackgroundColor3 = Color3.fromRGB(84, 142, 114)
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressTrack

	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(0, 999)
	progressFillCorner.Parent = progressFill

	local footer = Instance.new("TextLabel")
	footer.Name = "FooterLabel"
	footer.AnchorPoint = Vector2.new(0.5, 0)
	footer.Position = UDim2.fromScale(0.5, 0.72)
	footer.Size = UDim2.fromOffset(620, 28)
	footer.BackgroundTransparency = 1
	footer.Text = "Sinkronisasi match sedang berjalan..."
	footer.TextColor3 = Color3.fromRGB(168, 182, 202)
	footer.Font = Enum.Font.Gotham
	footer.TextSize = 15
	footer.Parent = bg

	screen.Parent = playerGui
	return screen
end

function UISystem:_ensureTeleportOverlay()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return nil, nil
	end

	local screen = playerGui:FindFirstChild(TELEPORT_OVERLAY_GUI_NAME)
	if screen and not screen:IsA("ScreenGui") then
		screen:Destroy()
		screen = nil
	end
	if not screen then
		screen = Instance.new("ScreenGui")
		screen.Name = TELEPORT_OVERLAY_GUI_NAME
		screen.IgnoreGuiInset = true
		screen.ResetOnSpawn = false
		screen.DisplayOrder = 10000
		screen.Enabled = false
		screen.Parent = playerGui
	end

	local overlay = screen:FindFirstChild(TELEPORT_OVERLAY_FRAME_NAME)
	if overlay and not overlay:IsA("Frame") then
		overlay:Destroy()
		overlay = nil
	end
	if not overlay then
		overlay = Instance.new("Frame")
		overlay.Name = TELEPORT_OVERLAY_FRAME_NAME
		overlay.Size = UDim2.fromScale(1, 1)
		overlay.BorderSizePixel = 0
		overlay.BackgroundColor3 = Color3.new(0, 0, 0)
		overlay.BackgroundTransparency = 0
		overlay.Active = false
		overlay.Selectable = false
		overlay.Parent = screen
	end

	return screen, overlay
end

function UISystem:_showTeleportOverlay(durationSeconds, options)
	local screen, overlay = self:_ensureTeleportOverlay()
	if not screen or not overlay then
		return
	end

	local overlayAlreadyVisible = screen.Enabled == true and overlay.BackgroundTransparency <= 0.05
	local suppressAudio = type(options) == "table" and options.suppressAudio == true
	local forceAudio = type(options) == "table" and options.forceAudio == true
	local dedupeWindowSeconds = tonumber(type(options) == "table" and options.dedupeWindowSeconds) or 4
	local now = tick()
	local recentlyPlayed = self._lastTeleportOverlaySoundAt and (now - self._lastTeleportOverlaySoundAt) < math.max(0, dedupeWindowSeconds)

	self._teleportOverlayToken = (self._teleportOverlayToken or 0) + 1
	local token = self._teleportOverlayToken

	if self._teleportOverlayTween then
		self._teleportOverlayTween:Cancel()
		self._teleportOverlayTween = nil
	end

	if not suppressAudio and ((forceAudio and not recentlyPlayed) or (not overlayAlreadyVisible and not recentlyPlayed)) then
		playRuntimeUISound("TeleportDrop", {
			VolumeScale = 1,
			PlaybackSpeed = 0.94,
			SingleInstance = true,
		})
		self._lastTeleportOverlaySoundAt = now
	end
	overlay.BackgroundTransparency = 0
	screen.Enabled = true

	task.spawn(function()
		task.wait(math.max(0, tonumber(durationSeconds) or TELEPORT_OVERLAY_HOLD_SECONDS))
		if self._teleportOverlayToken ~= token then
			return
		end

		local tween = TweenService:Create(
			overlay,
			TweenInfo.new(TELEPORT_OVERLAY_FADE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		)
		self._teleportOverlayTween = tween
		tween:Play()
		tween.Completed:Connect(function()
			if self._teleportOverlayToken ~= token then
				return
			end
			self._teleportOverlayTween = nil
			screen.Enabled = false
			overlay.BackgroundTransparency = 0
		end)
	end)
end

function UISystem:_setLoadingScreenContent(titleText, payload, progress, footerText)
	local screen = self:_ensureLoadingScreen()
	if not screen then
		return
	end

	local bg = screen:FindFirstChild("Background")
	if not bg or not bg:IsA("Frame") then
		return
	end

	local title = bg:FindFirstChild("TitleLabel")
	local status = bg:FindFirstChild("StatusLabel")
	local mapName = bg:FindFirstChild("MapNameLabel")
	local tip = bg:FindFirstChild("TipLabel")
	local progressTrack = bg:FindFirstChild("ProgressTrack")
	local footer = bg:FindFirstChild("FooterLabel")
	if title and title:IsA("TextLabel") then
		title.Text = titleText or "Masuk ke lokasi..."
	end
	if status and status:IsA("TextLabel") then
		status.Text = "BERMAIN"
	end
	if mapName and mapName:IsA("TextLabel") then
		mapName.Text = "Lokasi: " .. resolveMapDisplayName(payload)
	end
	if tip and tip:IsA("TextLabel") then
		local index = self._loadingTipIndex or 1
		tip.Text = LOADING_TIPS[index] or LOADING_TIPS[1]
	end
	if footer and footer:IsA("TextLabel") then
		footer.Text = footerText or "Sinkronisasi match sedang berjalan..."
	end
	if progressTrack and progressTrack:IsA("Frame") then
		local fill = progressTrack:FindFirstChild("ProgressFill")
		if fill and fill:IsA("Frame") then
			fill.Size = UDim2.fromScale(math.clamp(progress or 0.08, 0.08, 1), 1)
		end
	end
end

function UISystem:_startLoadingScreenLoop(payload)
	if self._loadingLoopRunning then
		return
	end

	local screen = self:_ensureLoadingScreen()
	if not screen then
		return
	end

	self._loadingLoopRunning = true
	self._loadingTipIndex = 1
	self._loadingStartTime = tick()
	screen.Enabled = true

	task.spawn(function()
		local startTime = tick()
		local tipSwapAt = startTime
		while self._loadingLoopRunning do
			local elapsed = tick() - startTime
			if tick() >= tipSwapAt + 1.8 then
				self._loadingTipIndex = (self._loadingTipIndex % #LOADING_TIPS) + 1
				tipSwapAt = tick()
			end

			local progress = 0.12 + math.min(elapsed / 3.2, 0.78)
			self:_setLoadingScreenContent("Masuk ke lokasi...", payload, progress, "Sinkronisasi match sedang berjalan...")
			task.wait(0.08)
		end
	end)
end

function UISystem:_stopLoadingScreenLoop()
	self._loadingLoopRunning = false
	self:_setLoadingScreenContent("Memulai investigasi...", self._phasePayload, 1, "Selesai dimuat.")
	task.wait(0.12)
	local screen = self:_ensureLoadingScreen()
	if screen then
		screen.Enabled = false
	end
end

function UISystem:_renderPhase(phase, payload)
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return
	end

	local lobbyUI = playerGui:FindFirstChild("LobbyUI")
	local roomUI = playerGui:FindFirstChild("RoomBrowserUI")
	local hud = playerGui:FindFirstChild("SensoryHorrorHUD") or playerGui:FindFirstChild("HorrorHUD")
	local loadingUI = playerGui:FindFirstChild("MatchLoadingUI")
	local matchUX = self._uxWidgets and self._uxWidgets.match or nil

	if not lobbyUI then
		return
	end

	-- Reset transient overlays before rendering a new phase.
	if loadingUI and loadingUI:IsA("ScreenGui") and phase ~= MATCH_PHASE.PREPARING and phase ~= MATCH_PHASE.LOADING and phase ~= MATCH_PHASE.INGAME then
		self:_stopLoadingScreenLoop()
	end
	if roomUI then
		local loadingLabel = roomUI:FindFirstChild("LoadingLabel")
		if loadingLabel and loadingLabel:IsA("TextLabel") then
			loadingLabel.Visible = false
		end
		local objectiveLabel = roomUI:FindFirstChild("ObjectiveLabel")
		if objectiveLabel and objectiveLabel:IsA("TextLabel") then
			objectiveLabel.Visible = false
		end
		local resultLabel = roomUI:FindFirstChild("ResultLabel")
		if resultLabel and resultLabel:IsA("TextLabel") then
			resultLabel.Visible = false
		end
	end
	if hud then
		local warning = hud:FindFirstChild("Warning")
		if warning then
			warning.Visible = false
		end
	end
	if matchUX and matchUX.MessageLabel and phase ~= MATCH_PHASE.PREPARING and phase ~= MATCH_PHASE.LOADING and phase ~= MATCH_PHASE.INGAME then
		matchUX.MessageLabel.Visible = false
		matchUX.MessageLabel.Text = ""
	end

	if not roomUI then
		return
	end

	if phase == MATCH_PHASE.LOBBY then
		lobbyUI.Enabled = true
		roomUI.Enabled = false
		if hud then
			hud.Enabled = false
		end
		self:_refreshBasicMatchPanel("Lobby", payload)
		return
	end

	if phase == MATCH_PHASE.PREPARING then
		lobbyUI.Enabled = false
		roomUI.Enabled = false
		if hud then
			hud.Enabled = false
		end
		if loadingUI and loadingUI:IsA("ScreenGui") then
			self:_startLoadingScreenLoop(payload)
			self:_setLoadingScreenContent("Preparing Investigation...", payload, 0.18, "Mempersiapkan sesi investigasi...")
		end
		if matchUX and matchUX.MessageLabel then
			matchUX.MessageLabel.Text = "Bermain"
			matchUX.MessageLabel.Visible = true
		end
		self:_refreshBasicMatchPanel("Preparation", payload)
		return
	end

	if phase == MATCH_PHASE.LOADING then
		lobbyUI.Enabled = false
		roomUI.Enabled = false
		if hud then
			hud.Enabled = false
		end
		if loadingUI and loadingUI:IsA("ScreenGui") then
			self:_startLoadingScreenLoop(payload)
			self:_setLoadingScreenContent("Masuk ke lokasi...", payload, 0.42, "Teleport pemain dan asset match sedang disiapkan...")
		end
		if matchUX and matchUX.MessageLabel then
			matchUX.MessageLabel.Text = "Bermain"
			matchUX.MessageLabel.Visible = true
		end

		self:_refreshBasicMatchPanel("Loading", payload)
		return
	end

	if phase == MATCH_PHASE.BRIEFING then
		lobbyUI.Enabled = false
		roomUI.Enabled = false
		if hud then
			hud.Enabled = false
		end
		if loadingUI and loadingUI:IsA("ScreenGui") then
			self:_startLoadingScreenLoop(payload)
			self:_setLoadingScreenContent("Briefing Investigasi", payload, 0.82, "Pelajari objective dan tips sebelum masuk.")
		end
		return
	end

	if phase == MATCH_PHASE.INGAME then
		local MIN_LOADING_TIME = 1.5
		local MAX_LOADING_WAIT = 2
		local elapsed = tick() - (self._loadingStartTime or 0)
		local waitTime = math.clamp(MIN_LOADING_TIME - elapsed, 0, MAX_LOADING_WAIT)
		if waitTime > 0 then
			task.wait(waitTime)
		end

		self:_stopLoadingScreenLoop()
		if matchUX and matchUX.MessageLabel then
			matchUX.MessageLabel.Visible = false
			matchUX.MessageLabel.Text = ""
		end

		lobbyUI.Enabled = false
		roomUI.Enabled = false

		if matchUX and matchUX.Gui then
			matchUX.Gui.Enabled = false
		end
		if matchUX and matchUX.Layer then
			matchUX.Layer.Visible = false
		end
		if self._uxReady == true then
			self:TransitionTo("Investigation", payload)
		end

		if hud then
			hud.Enabled = true
		end
		self:_refreshBasicMatchPanel("Investigation", payload)
		return
	end

	if phase == MATCH_PHASE.ESCALATION then
		if hud then
			hud.Enabled = true
		end
		self:_refreshBasicMatchPanel("Investigation", payload)
		return
	end

	if phase == MATCH_PHASE.HUNT then
		if hud then
			hud.Enabled = true
		end
		self:_refreshBasicMatchPanel("Hunt", payload)
		return
	end

	if phase == MATCH_PHASE.RESULT or phase == MATCH_PHASE.END then
		if hud then
			hud.Enabled = false
		end

		roomUI.Enabled = true
		local result = roomUI:FindFirstChild("ResultLabel")
		if result and result:IsA("TextLabel") then
			result.Visible = true
			local failed = payload and payload.missionFailed == true
			result.Text = failed and "MISSION FAILED" or "MISSION COMPLETE"
		end
		self:_refreshBasicMatchPanel("Results", payload)
	end
end

function UISystem:_routeMatchPhaseEvent(eventName, payload)
	payload = decoratePhasePayload(payload)
	if eventName == "MatchPreparing" then
		self:_forceCloseAllPanelsForTeleport()
		self._matchStartTransitionAudioArmed = true
		self:_showTeleportOverlay(TELEPORT_OVERLAY_HOLD_SECONDS, {
			suppressAudio = true,
			dedupeWindowSeconds = 4,
		})
		self._hasPostTeleportLoaded = false
		self._awaitingPostTeleportFlow = true
		self:_setPhase(MATCH_PHASE.PREPARING, payload)
	elseif eventName == "MatchStarted" then
		self:_forceCloseAllPanelsForTeleport()
		self:_showTeleportOverlay(TELEPORT_OVERLAY_HOLD_SECONDS, {
			suppressAudio = false,
			forceAudio = true,
			dedupeWindowSeconds = 4,
		})
		self._matchStartTransitionAudioArmed = false
		self._hasPostTeleportLoaded = false
		self._awaitingPostTeleportFlow = true
		self:_runPostTeleportLoadingFlow()
	elseif eventName == "PhaseChanged" then
		local resolvedPhase = resolvePhaseFromPayload(eventName, payload)
		if resolvedPhase == MATCH_PHASE.INGAME and (self._awaitingPostTeleportFlow or self._postTeleportFlowRunning) then
			self._pendingInGamePayload = payload
			return
		end
		if resolvedPhase then
			self:_setPhase(resolvedPhase, payload)
		end
	elseif eventName == "HuntStarted" or eventName == "GhostHuntStarted" then
		self:_cancelPostTeleportLoadingFlow(true)
		self:_setPhase(MATCH_PHASE.HUNT, payload)
	elseif eventName == "HuntEnded" or eventName == "GhostHuntEnded" then
		self:_cancelPostTeleportLoadingFlow(true)
		self:_setPhase(MATCH_PHASE.INGAME, payload)
	elseif eventName == "MatchEnded" or eventName == "MatchCompleted" then
		self._matchStartTransitionAudioArmed = false
		self._hasPostTeleportLoaded = false
		self._awaitingPostTeleportFlow = false
		local missionFailed = payload and (
			payload.success == false
			or payload.failed == true
			or payload.missionFailed == true
			or payload.correctGuess == false
		)
		self:_setPhase(MATCH_PHASE.RESULT, { duration = 5, missionFailed = missionFailed == true })
	elseif eventName == "RoomBrowserRoomLeft" or eventName == "ReturnedToLobby" then
		self:_forceCloseAllPanelsForTeleport()
		self._matchStartTransitionAudioArmed = false
		self:_showTeleportOverlay(TELEPORT_OVERLAY_HOLD_SECONDS)
		self._hasPostTeleportLoaded = false
		self._awaitingPostTeleportFlow = false
		if (self._resultsCloseUnlockAt or 0) > tick() and self:_isMatchResultsPhase() then
			local unlockAt = self._resultsCloseUnlockAt
			task.delay(math.max(unlockAt - tick(), 0), function()
				if self._resultsCloseUnlockAt == unlockAt and self:_isMatchResultsPhase() then
					self:_setPhase(MATCH_PHASE.LOBBY)
				end
			end)
			return
		end
		self:_setPhase(MATCH_PHASE.LOBBY)
	end
end

function UISystem:_startPhaseTimer()
	if self._phaseTimerRunning then
		return
	end

	self._phaseTimerRunning = true
	task.spawn(function()
		while self._phaseTimerRunning do
			task.wait(0.1)
			self:_refreshBasicMatchPanel()
			if not self._phaseDuration then
				continue
			end

			local elapsed = tick() - self._phaseStartTime
			if elapsed < self._phaseDuration then
				continue
			end

			if self._matchPhase == MATCH_PHASE.BRIEFING then
				self:_setPhase(MATCH_PHASE.INGAME)
			elseif self._matchPhase == MATCH_PHASE.HUNT then
				-- Server should end hunt; this only prevents repeated fallback transitions.
				self._phaseDuration = nil
			else
				self._phaseDuration = nil
			end
		end
	end)
end

function UISystem:_bindRoomBrowserMatchVisibility()
	local player = Players.LocalPlayer
	if not player then
		return
	end

	local function syncFromAttribute()
		self:_syncRoomBrowserSuppressionFromMatchContext()
	end

	table.insert(self._connections, player:GetAttributeChangedSignal("InMatch"):Connect(syncFromAttribute))
	syncFromAttribute()
end

function UISystem:_bindInputProfileUpdates()
	self._deviceProfile:Refresh(UserInputService:GetLastInputType())
	self:_applyDeviceSizing()

	table.insert(self._uxConnections, UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
		self._deviceProfile:Refresh(lastInputType)
		self:_applyDeviceSizing()
	end))

	table.insert(self._uxConnections, ReplicatedStorage:GetAttributeChangedSignal(UI_INPUT_PROFILE_OVERRIDE_ATTR):Connect(function()
		self._deviceProfile:Refresh(UserInputService:GetLastInputType())
		self:_applyDeviceSizing()
	end))

	table.insert(self._uxConnections, ReplicatedStorage:GetAttributeChangedSignal(UI_FORCE_COMPACT_ATTR):Connect(function()
		self:_applyDeviceSizing()
	end))

	table.insert(self._uxConnections, ReplicatedStorage:GetAttributeChangedSignal(UI_VIEWPORT_OVERRIDE_X_ATTR):Connect(function()
		self:_applyDeviceSizing()
	end))

	table.insert(self._uxConnections, ReplicatedStorage:GetAttributeChangedSignal(UI_VIEWPORT_OVERRIDE_Y_ATTR):Connect(function()
		self:_applyDeviceSizing()
	end))
end

function UISystem:_ensureUXLayers()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return false
	end

	local lobbyReady = playerGui:WaitForChild("LobbyUI", 10)
	if not lobbyReady then
		return false
	end

	local container = playerGui:FindFirstChild("UXLayer")
	if not container then
		container = Instance.new("Folder")
		container.Name = "UXLayer"
		container.Parent = playerGui
	end

	local topLeftInset, bottomRightInset = resolveSafeInsets()

	local function ensureSafeLayer(parentInstance, name)
		local layer = parentInstance:FindFirstChild(name)
		if not layer then
			layer = Instance.new("Frame")
			layer.Name = name
			layer.Visible = false
			layer.Active = false
			layer.Selectable = false
			layer.ZIndex = 1
			layer.BackgroundTransparency = 1
			layer.Size = UDim2.fromScale(1, 1)
			layer.Parent = parentInstance

			local padding = Instance.new("UIPadding")
			padding.Name = "SafePadding"
			padding.PaddingTop = UDim.new(0, topLeftInset.Y)
			padding.PaddingLeft = UDim.new(0, topLeftInset.X)
			padding.PaddingBottom = UDim.new(0, bottomRightInset.Y)
			padding.PaddingRight = UDim.new(0, bottomRightInset.X)
			padding.Parent = layer
		end
		return layer
	end

	local lobbyUXGui = container:FindFirstChild("LobbyUXGui")
	if not lobbyUXGui then
		lobbyUXGui = Instance.new("ScreenGui")
		lobbyUXGui.Name = "LobbyUXGui"
		lobbyUXGui.ResetOnSpawn = false
		lobbyUXGui.DisplayOrder = 1
		lobbyUXGui.IgnoreGuiInset = false
		lobbyUXGui.Enabled = false
		lobbyUXGui.Parent = container
	end

	local matchUXGui = container:FindFirstChild("MatchUXGui")
	if not matchUXGui then
		matchUXGui = Instance.new("ScreenGui")
		matchUXGui.Name = "MatchUXGui"
		matchUXGui.ResetOnSpawn = false
		matchUXGui.DisplayOrder = 1
		matchUXGui.IgnoreGuiInset = false
		matchUXGui.Enabled = false
		matchUXGui.Parent = container
	end

	local lobbyLayer = ensureSafeLayer(lobbyUXGui, "LobbyUXLayer")
	local matchLayer = ensureSafeLayer(matchUXGui, "MatchUXLayer")

	local lobbyFeedback = lobbyLayer:FindFirstChild("FeedbackLabel")
	if not lobbyFeedback then
		lobbyFeedback = Instance.new("TextLabel")
		lobbyFeedback.Name = "FeedbackLabel"
		lobbyFeedback.Visible = false
		lobbyFeedback.Active = false
		lobbyFeedback.Selectable = false
		lobbyFeedback.ZIndex = 1
		lobbyFeedback.BackgroundTransparency = 1
		lobbyFeedback.AnchorPoint = Vector2.new(0.5, 0)
		lobbyFeedback.Position = UDim2.fromScale(0.5, 0.06)
		lobbyFeedback.Size = UDim2.new(0.9, 0, 0, 60)
		lobbyFeedback.Font = Enum.Font.Gotham
		lobbyFeedback.TextColor3 = Color3.fromRGB(240, 244, 248)
		lobbyFeedback.TextWrapped = true
		lobbyFeedback.Text = "Lobby siap."
		lobbyFeedback.Parent = lobbyLayer
	end

	local playButton = lobbyLayer:FindFirstChild("PlayButton")
	if not playButton then
		playButton = Instance.new("TextButton")
		playButton.Name = "PlayButton"
		playButton.Visible = false
		playButton.Active = false
		playButton.Selectable = false
		playButton.ZIndex = 1
		playButton.AnchorPoint = Vector2.new(0.5, 1)
		playButton.Position = UDim2.fromScale(0.5, 0.92)
		playButton.BackgroundColor3 = Color3.fromRGB(45, 98, 72)
		playButton.TextColor3 = Color3.fromRGB(245, 245, 245)
		playButton.Font = Enum.Font.GothamBold
		playButton.Text = "PLAY"
		playButton.AutoButtonColor = true
		playButton.Parent = lobbyLayer
		self:_setSelectableStyle(playButton)

	end

	local matchMessage = matchLayer:FindFirstChild("StateMessage")
	if not matchMessage then
		matchMessage = Instance.new("TextLabel")
		matchMessage.Name = "StateMessage"
		matchMessage.BackgroundTransparency = 1
		matchMessage.Active = false
		matchMessage.Selectable = false
		matchMessage.ZIndex = 1
		matchMessage.AnchorPoint = Vector2.new(0.5, 0.5)
		matchMessage.Position = UDim2.fromScale(0.5, 0.5)
		matchMessage.Size = UDim2.new(0.8, 0, 0, 64)
		matchMessage.Font = Enum.Font.GothamBold
		matchMessage.TextColor3 = Color3.fromRGB(245, 245, 245)
		matchMessage.TextScaled = false
		matchMessage.Visible = false
		matchMessage.Parent = matchLayer
	end

	local objective = matchLayer:FindFirstChild("ObjectiveLabel")
	if not objective then
		objective = Instance.new("TextLabel")
		objective.Name = "ObjectiveLabel"
		objective.Active = false
		objective.Selectable = false
		objective.ZIndex = 1
		objective.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
		objective.BackgroundTransparency = 0.2
		objective.Position = UDim2.fromOffset(24, 24)
		objective.Size = UDim2.fromOffset(360, 54)
		objective.Font = Enum.Font.GothamSemibold
		objective.TextColor3 = Color3.fromRGB(235, 240, 245)
		objective.TextXAlignment = Enum.TextXAlignment.Left
		objective.TextWrapped = true
		objective.Visible = false
		objective.Parent = matchLayer
	end

	local overlay = matchLayer:FindFirstChild("HuntOverlay")
	if not overlay then
		overlay = Instance.new("Frame")
		overlay.Name = "HuntOverlay"
		overlay.Active = false
		overlay.Selectable = false
		overlay.ZIndex = 1
		overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		overlay.BackgroundTransparency = 0.6
		overlay.Size = UDim2.fromScale(1, 1)
		overlay.Visible = false
		overlay.Parent = matchLayer
	end

	local results = matchLayer:FindFirstChild("ResultsPanel")
	if not results then
		results = Instance.new("Frame")
		results.Name = "ResultsPanel"
		results.Active = true
		results.Selectable = true
		results.ZIndex = 3
		results.AnchorPoint = Vector2.new(0, 0)
		results.Position = UDim2.fromScale(0, 0)
		results.Size = UDim2.fromScale(1, 1)
		results.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
		results.BackgroundTransparency = 0.08
		results.Visible = false
		results.Parent = matchLayer

		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 1
		stroke.Color = Color3.fromRGB(82, 96, 120)
		stroke.Parent = results
	end

	local resultsCard = results:FindFirstChild("ResultsCard")
	if not resultsCard then
		resultsCard = Instance.new("Frame")
		resultsCard.Name = "ResultsCard"
		resultsCard.AnchorPoint = Vector2.new(0.5, 0.5)
		resultsCard.Position = UDim2.fromScale(0.5, 0.52)
		resultsCard.Size = UDim2.new(0.74, 0, 0, 438)
		resultsCard.BackgroundColor3 = Color3.fromRGB(16, 22, 30)
		resultsCard.BackgroundTransparency = 0.02
		resultsCard.BorderSizePixel = 0
		resultsCard.Parent = results

		local cardCorner = Instance.new("UICorner")
		cardCorner.CornerRadius = UDim.new(0, 16)
		cardCorner.Parent = resultsCard

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Thickness = 1
		cardStroke.Color = Color3.fromRGB(82, 96, 120)
		cardStroke.Parent = resultsCard
	end

	local resultsTitle = resultsCard:FindFirstChild("ResultsTitle")
	if not resultsTitle then
		resultsTitle = Instance.new("TextLabel")
		resultsTitle.Name = "ResultsTitle"
		resultsTitle.Position = UDim2.fromOffset(20, 18)
		resultsTitle.Size = UDim2.new(1, -168, 0, 36)
		resultsTitle.BackgroundTransparency = 1
		resultsTitle.Text = "HASIL INVESTIGASI"
		resultsTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
		resultsTitle.TextXAlignment = Enum.TextXAlignment.Left
		resultsTitle.Font = Enum.Font.GothamBlack
		resultsTitle.TextSize = 28
		resultsTitle.Parent = resultsCard
	end

	local resultsStatus = resultsCard:FindFirstChild("ResultsStatus")
	if not resultsStatus then
		resultsStatus = Instance.new("TextLabel")
		resultsStatus.Name = "ResultsStatus"
		resultsStatus.Position = UDim2.fromOffset(20, 58)
		resultsStatus.Size = UDim2.fromOffset(132, 26)
		resultsStatus.BackgroundColor3 = Color3.fromRGB(50, 104, 72)
		resultsStatus.TextColor3 = Color3.fromRGB(245, 245, 245)
		resultsStatus.Text = "MISSION COMPLETE"
		resultsStatus.Font = Enum.Font.GothamBold
		resultsStatus.TextSize = 12
		resultsStatus.Parent = resultsCard

		local statusCorner = Instance.new("UICorner")
		statusCorner.CornerRadius = UDim.new(0, 999)
		statusCorner.Parent = resultsStatus
	end

	local resultsClose = resultsCard:FindFirstChild("ResultsCloseButton")
	if not resultsClose then
		resultsClose = Instance.new("TextButton")
		resultsClose.Name = "ResultsCloseButton"
		resultsClose.AnchorPoint = Vector2.new(1, 0)
		resultsClose.Position = UDim2.new(1, -20, 0, 18)
		resultsClose.Size = UDim2.fromOffset(112, 30)
		styleButton(resultsClose, "TUTUP HASIL")
		resultsClose.BackgroundColor3 = Color3.fromRGB(48, 60, 78)
		resultsClose.Parent = resultsCard
		self:_setSelectableStyle(resultsClose)
	end

	local resultsSubtitle = resultsCard:FindFirstChild("ResultsSubtitle")
	if not resultsSubtitle then
		resultsSubtitle = Instance.new("TextLabel")
		resultsSubtitle.Name = "ResultsSubtitle"
		resultsSubtitle.Position = UDim2.fromOffset(164, 58)
		resultsSubtitle.Size = UDim2.new(1, -184, 0, 26)
		resultsSubtitle.BackgroundTransparency = 1
		resultsSubtitle.Text = "Ghost: Unknown"
		resultsSubtitle.TextColor3 = Color3.fromRGB(196, 210, 228)
		resultsSubtitle.TextXAlignment = Enum.TextXAlignment.Left
		resultsSubtitle.Font = Enum.Font.GothamSemibold
		resultsSubtitle.TextSize = 16
		resultsSubtitle.Parent = resultsCard
	end

	local resultsSummary = resultsCard:FindFirstChild("ResultsSummary")
	if resultsSummary and not resultsSummary:IsA("ScrollingFrame") then
		resultsSummary:Destroy()
		resultsSummary = nil
	end
	if not resultsSummary then
		resultsSummary = Instance.new("ScrollingFrame")
		resultsSummary.Name = "ResultsSummary"
		resultsSummary.Position = UDim2.fromOffset(20, 96)
		resultsSummary.Size = UDim2.new(1, -40, 0, 244)
		resultsSummary.BackgroundColor3 = Color3.fromRGB(20, 27, 36)
		resultsSummary.BackgroundTransparency = 0.06
		resultsSummary.BorderSizePixel = 0
		resultsSummary.ScrollBarThickness = 5
		resultsSummary.AutomaticCanvasSize = Enum.AutomaticSize.Y
		resultsSummary.CanvasSize = UDim2.fromOffset(0, 0)
		resultsSummary.ScrollingDirection = Enum.ScrollingDirection.Y
		resultsSummary.ElasticBehavior = Enum.ElasticBehavior.Never
		resultsSummary.ClipsDescendants = true
		resultsSummary.Parent = resultsCard

		local summaryCorner = Instance.new("UICorner")
		summaryCorner.CornerRadius = UDim.new(0, 10)
		summaryCorner.Parent = resultsSummary

		local summaryPadding = Instance.new("UIPadding")
		summaryPadding.PaddingTop = UDim.new(0, 10)
		summaryPadding.PaddingBottom = UDim.new(0, 10)
		summaryPadding.PaddingLeft = UDim.new(0, 10)
		summaryPadding.PaddingRight = UDim.new(0, 10)
		summaryPadding.Parent = resultsSummary

		local summaryLayout = Instance.new("UIListLayout")
		summaryLayout.FillDirection = Enum.FillDirection.Vertical
		summaryLayout.SortOrder = Enum.SortOrder.LayoutOrder
		summaryLayout.Padding = UDim.new(0, 6)
		summaryLayout.Parent = resultsSummary
	end

	local resultsFooter = resultsCard:FindFirstChild("ResultsFooter")
	if not resultsFooter then
		resultsFooter = Instance.new("TextLabel")
		resultsFooter.Name = "ResultsFooter"
		resultsFooter.Position = UDim2.fromOffset(20, 348)
		resultsFooter.Size = UDim2.new(1, -40, 0, 40)
		resultsFooter.BackgroundTransparency = 1
		resultsFooter.Text = "Ringkasan ini dibuat untuk test E2E. Tutup jika perlu melihat area sekitar."
		resultsFooter.TextColor3 = Color3.fromRGB(168, 182, 202)
		resultsFooter.TextWrapped = true
		resultsFooter.TextXAlignment = Enum.TextXAlignment.Left
		resultsFooter.TextYAlignment = Enum.TextYAlignment.Top
		resultsFooter.Font = Enum.Font.Gotham
		resultsFooter.TextSize = 13
		resultsFooter.Parent = resultsCard
	end

	local resultsLockHint = resultsCard:FindFirstChild("ResultsLockHint")
	if not resultsLockHint then
		resultsLockHint = Instance.new("TextLabel")
		resultsLockHint.Name = "ResultsLockHint"
		resultsLockHint.AnchorPoint = Vector2.new(0.5, 1)
		resultsLockHint.Position = UDim2.new(0.5, 0, 1, -18)
		resultsLockHint.Size = UDim2.new(1, -40, 0, 20)
		resultsLockHint.BackgroundTransparency = 1
		resultsLockHint.Text = "Hasil match dikunci beberapa detik..."
		resultsLockHint.TextColor3 = Color3.fromRGB(196, 210, 228)
		resultsLockHint.Font = Enum.Font.GothamSemibold
		resultsLockHint.TextSize = 13
		resultsLockHint.Parent = resultsCard
	end

	local function ensureResultSummaryValue(rowName, labelText)
		local row = resultsSummary:FindFirstChild(rowName)
		if row and row:IsA("Frame") then
			local value = row:FindFirstChild("Value")
			if value and value:IsA("TextLabel") then
				return value
			end
		end
		return createSummaryRow(resultsSummary, rowName, labelText)
	end

	local resultsSummaryRows = {
		status = ensureResultSummaryValue("StatusRow", "Status Misi"),
		ghostType = ensureResultSummaryValue("GhostRow", "Ghost"),
		correctGuess = ensureResultSummaryValue("GuessRow", "Tebakan"),
		evidenceCollected = ensureResultSummaryValue("EvidenceRow", "Evidence"),
		playersSurvived = ensureResultSummaryValue("SurvivedRow", "Pemain Selamat"),
		playersDead = ensureResultSummaryValue("DeadRow", "Pemain Mati"),
		matchDuration = ensureResultSummaryValue("DurationRow", "Durasi"),
		currencyReward = ensureResultSummaryValue("RewardRow", "Hadiah MM / PP"),
		xpReward = ensureResultSummaryValue("XpRow", "Hadiah XP"),
	}

	if resultsClose:GetAttribute("Bound") ~= true then
		resultsClose:SetAttribute("Bound", true)
		connectButtonPress(resultsClose, function()
			if (self._resultsCloseUnlockAt or 0) > tick() then
				return
			end
			self:_setMatchWindowDismissed(true)
		end)
	end

	self._uxWidgets.lobby.FeedbackLabel = lobbyFeedback
	self._uxWidgets.lobby.PlayButton = playButton
	self._uxWidgets.lobby.Gui = lobbyUXGui
	self._uxWidgets.lobby.Layer = lobbyLayer
	self._uxWidgets.match.MessageLabel = matchMessage
	self._uxWidgets.match.ObjectiveLabel = objective
	self._uxWidgets.match.HuntOverlay = overlay
	self._uxWidgets.match.ResultsPanel = results
	self._uxWidgets.match.ResultsCard = resultsCard
	self._uxWidgets.match.ResultsTitle = resultsTitle
	self._uxWidgets.match.ResultsStatus = resultsStatus
	self._uxWidgets.match.ResultsSubtitle = resultsSubtitle
	self._uxWidgets.match.ResultsSummaryRows = resultsSummaryRows
	self._uxWidgets.match.ResultsFooter = resultsFooter
	self._uxWidgets.match.ResultsLockHint = resultsLockHint
	self._uxWidgets.match.ResultsCloseButton = resultsClose
	self._uxWidgets.match.Gui = matchUXGui
	self._uxWidgets.match.Layer = matchLayer

	self:_applyDeviceSizing()
	return true
end

function UISystem:_clearMatchUX()
	local match = self._uxWidgets.match
	if not match then
		return
	end

	if match.PulseConnection then
		match.PulseConnection:Disconnect()
		match.PulseConnection = nil
	end
	if match.PulseTween then
		match.PulseTween:Cancel()
		match.PulseTween = nil
	end

	if match.MessageLabel then
		match.MessageLabel.Visible = false
		match.MessageLabel.Text = ""
	end
	if match.ObjectiveLabel then
		match.ObjectiveLabel.Visible = false
		match.ObjectiveLabel.Text = ""
	end
	if match.HuntOverlay then
		match.HuntOverlay.Visible = false
		match.HuntOverlay.BackgroundTransparency = 0.6
	end
	if match.ResultsPanel then
		match.ResultsPanel.Visible = false
	end
	self:_clearUXInstances()
end

function UISystem:_startHuntPulse()
	local match = self._uxWidgets.match
	if not match or not match.HuntOverlay then
		return
	end

	local overlay = match.HuntOverlay
	overlay.Visible = true

	local function pulseTo(transparencyTarget)
		if self:GetState() ~= "Hunt" then
			return
		end
		match.PulseTween = TweenService:Create(overlay, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			BackgroundTransparency = transparencyTarget,
		})
		match.PulseTween:Play()

		match.PulseConnection = match.PulseTween.Completed:Connect(function()
			if match.PulseConnection then
				match.PulseConnection:Disconnect()
				match.PulseConnection = nil
			end
			pulseTo(transparencyTarget <= 0.45 and 0.72 or 0.45)
		end)
	end

	pulseTo(0.45)
end

function UISystem:TransitionTo(state, payload)
	if self._uxReady ~= true then
		return
	end
	self:SetState(state)
	self:_clearMatchUX()

	local match = self._uxWidgets.match
	if not match then
		return
	end

	if match.Gui then
		match.Gui.Enabled = (state == "Preparation" or state == "Investigation" or state == "Hunt" or state == "Results")
	end
	if match.Layer then
		match.Layer.Visible = (state == "Preparation" or state == "Investigation" or state == "Hunt" or state == "Results")
	end

	if state == "Preparation" then
		match.MessageLabel.Text = "Masuk ke lokasi..."
		match.MessageLabel.Visible = true
		fadeGuiObject(match.MessageLabel, 0, 0.2)
	elseif state == "Investigation" then
		match.MessageLabel.Text = ""
		match.MessageLabel.Visible = false
		match.ObjectiveLabel.Text = DEFAULT_MATCH_OBJECTIVE_TEXT
		match.ObjectiveLabel.Visible = true
	elseif state == "Hunt" then
		match.MessageLabel.Text = "HUNT"
		match.MessageLabel.Visible = true
		match.ObjectiveLabel.Text = getHuntObjectiveText()
		match.ObjectiveLabel.Visible = true
		self:_startHuntPulse()
	elseif state == "Results" then
		self:_startResultsCloseLock(payload)
		self:_renderResultsPanel(payload)
	end
	self:_refreshBasicMatchPanel(state, payload)
end

function UISystem:_handleMatchUXEvent(eventName, payload)
	if self._uxReady ~= true then
		return
	end
	if eventName == "MatchStarted" then
		return
	end
	if eventName == "PhaseChanged" then
		local resolvedPhase = resolvePhaseFromPayload(eventName, payload)
		if resolvedPhase == MATCH_PHASE.PREPARING or resolvedPhase == MATCH_PHASE.LOADING or resolvedPhase == MATCH_PHASE.BRIEFING then
			self:TransitionTo("Preparation", payload)
		elseif resolvedPhase == MATCH_PHASE.INGAME or resolvedPhase == MATCH_PHASE.ESCALATION then
			self:TransitionTo("Investigation", payload)
		elseif resolvedPhase == MATCH_PHASE.HUNT then
			self:TransitionTo("Hunt", payload)
		elseif resolvedPhase == MATCH_PHASE.RESULT or resolvedPhase == MATCH_PHASE.END then
			self:TransitionTo("Results", payload)
		end
		return
	end
	if eventName == "HuntStarted" or eventName == "GhostHuntStarted" then
		self:TransitionTo("Hunt", payload)
		return
	end
	if eventName == "HuntEnded" or eventName == "GhostHuntEnded" then
		self:TransitionTo("Investigation", payload)
		return
	end
	if eventName == "MatchEnded" or eventName == "MatchCompleted" then
		if payload and type(payload) == "table" then
			self._matchResult.ghostType = payload.ghostType or self._matchResult.ghostType
		end
		self:TransitionTo("Results", payload)
	end
end

function UISystem:_handleLobbyUXEvent(eventName, payload)
	if self._uxReady ~= true then
		return
	end
	local lobby = self._uxWidgets.lobby
	if not lobby or not lobby.FeedbackLabel then
		return
	end

	if eventName == "RoomUpdated" or eventName == "RoomStateUpdate" then
		local roomId = payload and payload.room and payload.room.roomId or payload and payload.roomId
		if roomId then
			lobby.FeedbackLabel.Text = "Room diperbarui: #" .. tostring(roomId)
		else
			lobby.FeedbackLabel.Text = "Room diperbarui."
		end
	elseif eventName == "RoomInviteSendResult" then
		if payload and payload.ok then
			local total = tonumber(payload.invitedCount or 0) or 0
			if payload.broadcast == true then
				lobby.FeedbackLabel.Text = "Broadcast invite terkirim (" .. tostring(total) .. ")"
			else
				lobby.FeedbackLabel.Text = "Invite terkirim."
			end
		else
			lobby.FeedbackLabel.Text = "Invite gagal: " .. tostring(payload and (payload.err or payload.reason) or "-")
		end
	elseif eventName == "RoomInviteAccepted" then
		lobby.FeedbackLabel.Text = tostring(payload and payload.byName or "Player") .. " menerima invite."
	elseif eventName == "RoomInviteDeclined" then
		lobby.FeedbackLabel.Text = tostring(payload and payload.byName or "Player") .. " menolak invite."
	elseif eventName == "RoomInviteExpired" then
		lobby.FeedbackLabel.Text = "Invite kadaluarsa."
	elseif eventName == "MatchStarting" or eventName == "RoomMatchStarting" then
		lobby.FeedbackLabel.Text = "Match akan dimulai..."
	elseif eventName == "LobbyFlexSpotlightUpdated" then
		local spotlight = payload and payload.spotlight or {}
		local spotlightName = spotlight.displayName or spotlight.playerName or "Player"
		local spotlightShow = spotlight.showcaseSummary or formatJoinedValues(spotlight.featuredNames, "koleksi lobby")
		lobby.FeedbackLabel.Text = string.format("Flex aktif: %s menampilkan %s", tostring(spotlightName), tostring(spotlightShow))
	elseif eventName == "LobbyFlexSpotlightCleared" then
		lobby.FeedbackLabel.Text = "Flex zone kembali idle."
	else
		lobby.FeedbackLabel.Text = "Lobby event: " .. tostring(eventName)
	end

	lobby.FeedbackLabel.Visible = false
	if lobby.PlayButton then
		lobby.PlayButton.Visible = false
	end
end

function UISystem:_hideRoomInvitePopup()
	if self._roomBrowserWidgets and self._roomBrowserWidgets.InvitePopup then
		self._roomBrowserWidgets.InvitePopup.Visible = false
	end
	self._activeInviteId = nil
end

function UISystem:_showRoomInvitePopup(payload)
	if type(payload) ~= "table" or not self._roomBrowserWidgets then
		return
	end
	local popup = self._roomBrowserWidgets.InvitePopup
	local textLabel = self._roomBrowserWidgets.InvitePopupText
	if not popup or not textLabel then
		return
	end
	local inviteId = tostring(payload.inviteId or "")
	if inviteId == "" then
		return
	end
	self._activeInviteId = inviteId
	local inviterName = tostring(payload.fromDisplayName or payload.fromName or "Host")
	local roomId = tostring(payload.roomId or "?")
	local modeText = tostring(payload.mode or "Classic")
	textLabel.Text = string.format("%s mengundang kamu ke Room #%s (%s)", inviterName, roomId, modeText)
	popup.Visible = true
	task.delay(5, function()
		if self._activeInviteId == inviteId then
			self:RoomBrowserRespondRoomInvite(inviteId, false)
			self:_hideRoomInvitePopup()
		end
	end)
end

function UISystem:_ensureBasicUIs()
	local playerGui = self:_getPlayerGui()
	if not playerGui then
		return
	end

	for _, guiName in ipairs(BASIC_GUI_NAMES) do
		local gui = playerGui:FindFirstChild(guiName)
		if not gui then
			gui = Instance.new("ScreenGui")
			gui.Name = guiName
			gui.ResetOnSpawn = false
			gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			gui.Parent = playerGui
		end
		local panel = gui:FindFirstChild("MainPanel")
		if not panel then
			panel = Instance.new("Frame")
			panel.Name = "MainPanel"
			panel.AnchorPoint = Vector2.new(1, 0)
			panel.Position = UDim2.new(1, -16, 0, 16)
			panel.Size = UDim2.fromOffset(260, 320)
			panel.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
			panel.BorderSizePixel = 0
			panel.Parent = gui

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 10)
			corner.Parent = panel

			local title = Instance.new("TextLabel")
			title.Name = "Title"
			title.Position = UDim2.fromOffset(12, 10)
			title.Size = UDim2.fromOffset(236, 22)
			styleLabel(title, guiName, 16)
			title.Font = Enum.Font.GothamBold
			title.Parent = panel
		end

		if guiName == "LobbyUI" then
			panel.AnchorPoint = Vector2.new(0, 0)
			panel.Position = UDim2.fromOffset(16, 16)
			panel.Size = UDim2.fromOffset(340, 368)
			panel.BackgroundColor3 = Color3.fromRGB(18, 26, 34)
			panel.BackgroundTransparency = 0.08

			local title = panel:FindFirstChild("Title")
			if title and title:IsA("TextLabel") then
				title.Text = "LOBBY PANEL"
				title.TextColor3 = Color3.fromRGB(238, 243, 248)
				title.Size = UDim2.new(1, -24, 0, 24)
			end

			local statusBadge = panel:FindFirstChild("StatusBadge")
			if not statusBadge then
				statusBadge = Instance.new("TextLabel")
				statusBadge.Name = "StatusBadge"
				statusBadge.Position = UDim2.fromOffset(12, 42)
				statusBadge.Size = UDim2.fromOffset(108, 24)
				statusBadge.BackgroundColor3 = Color3.fromRGB(54, 116, 82)
				statusBadge.TextColor3 = Color3.fromRGB(245, 245, 245)
				statusBadge.Font = Enum.Font.GothamBold
				statusBadge.TextSize = 12
				statusBadge.Text = "LOBBY"
				statusBadge.Parent = panel

				local badgeCorner = Instance.new("UICorner")
				badgeCorner.CornerRadius = UDim.new(0, 999)
				badgeCorner.Parent = statusBadge
			end

			local primaryLabel = panel:FindFirstChild("PrimaryLabel")
			if not primaryLabel then
				primaryLabel = Instance.new("TextLabel")
				primaryLabel.Name = "PrimaryLabel"
				primaryLabel.Position = UDim2.fromOffset(12, 76)
				primaryLabel.Size = UDim2.new(1, -24, 0, 40)
				primaryLabel.BackgroundTransparency = 1
				primaryLabel.Font = Enum.Font.GothamBold
				primaryLabel.TextSize = 16
				primaryLabel.TextColor3 = Color3.fromRGB(242, 246, 250)
				primaryLabel.TextWrapped = true
				primaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				primaryLabel.TextYAlignment = Enum.TextYAlignment.Top
				primaryLabel.Text = "Buka Room Browser untuk mulai test flow lobby."
				primaryLabel.Parent = panel
			end

			local secondaryLabel = panel:FindFirstChild("SecondaryLabel")
			if not secondaryLabel then
				secondaryLabel = Instance.new("TextLabel")
				secondaryLabel.Name = "SecondaryLabel"
				secondaryLabel.Position = UDim2.fromOffset(12, 120)
				secondaryLabel.Size = UDim2.new(1, -24, 0, 32)
				secondaryLabel.BackgroundTransparency = 1
				secondaryLabel.Font = Enum.Font.Gotham
				secondaryLabel.TextSize = 13
				secondaryLabel.TextColor3 = Color3.fromRGB(182, 196, 216)
				secondaryLabel.TextWrapped = true
				secondaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				secondaryLabel.TextYAlignment = Enum.TextYAlignment.Top
				secondaryLabel.Text = "Mode Classic | Map HauntedHouse | 0 room aktif"
				secondaryLabel.Parent = panel
			end

			local panelStroke = panel:FindFirstChild("BrandStroke")
			if not panelStroke or not panelStroke:IsA("UIStroke") then
				panelStroke = Instance.new("UIStroke")
				panelStroke.Name = "BrandStroke"
				panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				panelStroke.Thickness = 1
				panelStroke.Transparency = 0.22
				panelStroke.Color = Color3.fromRGB(82, 116, 94)
				panelStroke.Parent = panel
			end

			local headerCard = panel:FindFirstChild("HeaderCard")
			if not headerCard then
				headerCard = Instance.new("Frame")
				headerCard.Name = "HeaderCard"
				headerCard.Position = UDim2.fromOffset(12, 42)
				headerCard.Size = UDim2.new(1, -24, 0, 112)
				headerCard.BackgroundColor3 = Color3.fromRGB(24, 34, 40)
				headerCard.BackgroundTransparency = 0.04
				headerCard.BorderSizePixel = 0
				headerCard.Parent = panel

				local headerCorner = Instance.new("UICorner")
				headerCorner.CornerRadius = UDim.new(0, 12)
				headerCorner.Parent = headerCard

				local headerStroke = Instance.new("UIStroke")
				headerStroke.Name = "HeaderStroke"
				headerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				headerStroke.Thickness = 1
				headerStroke.Transparency = 0.18
				headerStroke.Color = Color3.fromRGB(82, 116, 94)
				headerStroke.Parent = headerCard
			end

			local lobbyGlyph = headerCard:FindFirstChild("LobbyGlyph")
			if not lobbyGlyph then
				lobbyGlyph = Instance.new("TextLabel")
				lobbyGlyph.Name = "LobbyGlyph"
				lobbyGlyph.AnchorPoint = Vector2.new(1, 0)
				lobbyGlyph.Position = UDim2.new(1, -12, 0, 8)
				lobbyGlyph.Size = UDim2.fromOffset(84, 64)
				lobbyGlyph.BackgroundTransparency = 1
				lobbyGlyph.Font = Enum.Font.GothamBlack
				lobbyGlyph.TextSize = 46
				lobbyGlyph.TextColor3 = Color3.fromRGB(88, 122, 100)
				lobbyGlyph.TextTransparency = 0.38
				lobbyGlyph.TextXAlignment = Enum.TextXAlignment.Right
				lobbyGlyph.Text = "LO"
				lobbyGlyph.Parent = headerCard
			end

			statusBadge.Parent = headerCard
			statusBadge.Position = UDim2.fromOffset(12, 10)
			statusBadge.Size = UDim2.fromOffset(108, 24)
			statusBadge.Font = Enum.Font.GothamBlack
			statusBadge.TextSize = 11

			primaryLabel.Parent = headerCard
			primaryLabel.Position = UDim2.fromOffset(12, 40)
			primaryLabel.Size = UDim2.new(1, -110, 0, 24)
			primaryLabel.TextSize = 15

			secondaryLabel.Parent = headerCard
			secondaryLabel.Position = UDim2.fromOffset(12, 64)
			secondaryLabel.Size = UDim2.new(1, -110, 0, 20)
			secondaryLabel.TextSize = 12

			local function ensureHeaderPill(name, position, size, backgroundColor)
				local pill = headerCard:FindFirstChild(name)
				if not pill then
					pill = Instance.new("TextLabel")
					pill.Name = name
					pill.BackgroundColor3 = backgroundColor
					pill.BackgroundTransparency = 0.08
					pill.BorderSizePixel = 0
					pill.Font = Enum.Font.GothamBold
					pill.TextSize = 10
					pill.TextColor3 = Color3.fromRGB(242, 246, 250)
					pill.Text = "-"
					pill.Parent = headerCard

					local pillCorner = Instance.new("UICorner")
					pillCorner.CornerRadius = UDim.new(1, 0)
					pillCorner.Parent = pill
				end
				pill.Position = position
				pill.Size = size
				return pill
			end

			local modePill = ensureHeaderPill("ModePill", UDim2.fromOffset(12, 88), UDim2.fromOffset(70, 18), Color3.fromRGB(58, 92, 126))
			local mapPill = ensureHeaderPill("MapPill", UDim2.fromOffset(88, 88), UDim2.fromOffset(116, 18), Color3.fromRGB(70, 86, 64))
			local roomPill = ensureHeaderPill("RoomPill", UDim2.fromOffset(210, 88), UDim2.fromOffset(94, 18), Color3.fromRGB(96, 76, 48))

			local openRoomBrowserButton = panel:FindFirstChild("OpenRoomBrowserButton")
			if not openRoomBrowserButton then
				openRoomBrowserButton = Instance.new("TextButton")
				openRoomBrowserButton.Name = "OpenRoomBrowserButton"
				openRoomBrowserButton.Position = UDim2.fromOffset(12, 162)
				openRoomBrowserButton.Size = UDim2.new(1, -24, 0, 42)
				styleButton(openRoomBrowserButton, "OPEN ROOM BROWSER")
				openRoomBrowserButton.BackgroundColor3 = Color3.fromRGB(46, 78, 114)
				openRoomBrowserButton.Parent = panel
				self:_setSelectableStyle(openRoomBrowserButton)
			end

			local menuButton = panel:FindFirstChild("MenuButton")
			if not menuButton then
				menuButton = Instance.new("TextButton")
				menuButton.Name = "MenuButton"
				menuButton.Position = UDim2.fromOffset(12, 304)
				menuButton.Size = UDim2.fromOffset(152, 36)
				styleButton(menuButton, "MENU")
				menuButton.BackgroundColor3 = Color3.fromRGB(58, 66, 84)
				menuButton.Parent = panel
				self:_setSelectableStyle(menuButton)
			end

			local rankButton = panel:FindFirstChild("RankButton")
			if not rankButton then
				rankButton = Instance.new("TextButton")
				rankButton.Name = "RankButton"
				rankButton.Position = UDim2.fromOffset(176, 304)
				rankButton.Size = UDim2.fromOffset(152, 36)
				styleButton(rankButton, "RANK")
				rankButton.BackgroundColor3 = Color3.fromRGB(74, 82, 58)
				rankButton.Parent = panel
				self:_setSelectableStyle(rankButton)
			end

			local profileButton = panel:FindFirstChild("ProfileButton")
			if not profileButton then
				profileButton = Instance.new("TextButton")
				profileButton.Name = "ProfileButton"
				profileButton.Position = UDim2.fromOffset(12, 212)
				profileButton.Size = UDim2.fromOffset(152, 36)
				styleButton(profileButton, "PROFILE")
				profileButton.BackgroundColor3 = Color3.fromRGB(62, 88, 66)
				profileButton.Parent = panel
				self:_setSelectableStyle(profileButton)
			end

			local shopButton = panel:FindFirstChild("ShopButton")
			if not shopButton then
				shopButton = Instance.new("TextButton")
				shopButton.Name = "ShopButton"
				shopButton.Position = UDim2.fromOffset(176, 212)
				shopButton.Size = UDim2.fromOffset(152, 36)
				styleButton(shopButton, "SHOP")
				shopButton.BackgroundColor3 = Color3.fromRGB(108, 82, 48)
				shopButton.Parent = panel
				self:_setSelectableStyle(shopButton)
			end

			local royalPassButton = panel:FindFirstChild("RoyalPassButton")
			if not royalPassButton then
				royalPassButton = Instance.new("TextButton")
				royalPassButton.Name = "RoyalPassButton"
				royalPassButton.Position = UDim2.fromOffset(12, 258)
				royalPassButton.Size = UDim2.new(1, -24, 0, 36)
				styleButton(royalPassButton, "ROYAL PASS")
				royalPassButton.BackgroundColor3 = Color3.fromRGB(116, 88, 44)
				royalPassButton.Parent = panel
				self:_setSelectableStyle(royalPassButton)
			end

			local hintLabel = panel:FindFirstChild("HintLabel")
			if not hintLabel then
				hintLabel = Instance.new("TextLabel")
				hintLabel.Name = "HintLabel"
				hintLabel.Position = UDim2.fromOffset(12, 348)
				hintLabel.Size = UDim2.new(1, -24, 0, 16)
				hintLabel.BackgroundTransparency = 1
				hintLabel.Font = Enum.Font.Gotham
				hintLabel.TextSize = 11
				hintLabel.TextColor3 = Color3.fromRGB(156, 170, 192)
				hintLabel.TextWrapped = true
				hintLabel.TextXAlignment = Enum.TextXAlignment.Left
				hintLabel.Text = "Shortcut: tekan M untuk Room Browser."
				hintLabel.Parent = panel
			end

			local toggleBtn = gui:FindFirstChild("LobbyToggleButton")
			if not toggleBtn then
				toggleBtn = Instance.new("TextButton")
				toggleBtn.Name = "LobbyToggleButton"
				toggleBtn.AnchorPoint = Vector2.new(1, 0)
				toggleBtn.Position = UDim2.fromOffset(12, 120)
				toggleBtn.Size = UDim2.fromOffset(28, 78)
				styleButton(toggleBtn, ">")
				toggleBtn.BackgroundColor3 = Color3.fromRGB(44, 60, 82)
				toggleBtn.Parent = gui

				local toggleCorner = Instance.new("UICorner")
				toggleCorner.CornerRadius = UDim.new(0, 10)
				toggleCorner.Parent = toggleBtn

				self:_setSelectableStyle(toggleBtn)
			end

			if openRoomBrowserButton:GetAttribute("Bound") ~= true then
				openRoomBrowserButton:SetAttribute("Bound", true)
				connectButtonPress(openRoomBrowserButton, function()
					self:_toggleRoomBrowserVisible()
					self:_refreshBasicLobbyPanel()
				end)
			end
			if menuButton:GetAttribute("Bound") ~= true then
				menuButton:SetAttribute("Bound", true)
				connectButtonPress(menuButton, function()
					self:_toggleBasicWindow("MainMenuUI")
				end)
			end
			if profileButton:GetAttribute("Bound") ~= true then
				profileButton:SetAttribute("Bound", true)
				connectButtonPress(profileButton, function()
					self:_toggleAuxiliaryWindow("ProfileUI")
				end)
			end
			if shopButton:GetAttribute("Bound") ~= true then
				shopButton:SetAttribute("Bound", true)
				connectButtonPress(shopButton, function()
					self:_toggleAuxiliaryWindow("ShopUI")
				end)
			end
			if royalPassButton:GetAttribute("Bound") ~= true then
				royalPassButton:SetAttribute("Bound", true)
				connectButtonPress(royalPassButton, function()
					self:_toggleAuxiliaryWindow("RoyalPassUI")
				end)
			end
			if rankButton:GetAttribute("Bound") ~= true then
				rankButton:SetAttribute("Bound", true)
				connectButtonPress(rankButton, function()
					self:_toggleBasicWindow("LeaderboardUI")
				end)
			end
			if toggleBtn:GetAttribute("Bound") ~= true then
				toggleBtn:SetAttribute("Bound", true)
				connectButtonPress(toggleBtn, function()
					self:_toggleLobbyPanelCollapsed()
				end)
			end

			self._uxWidgets.lobby.BasicGui = gui
			self._uxWidgets.lobby.BasicPanel = panel
			self._uxWidgets.lobby.BasicHeaderCard = headerCard
			self._uxWidgets.lobby.BasicHeaderStroke = headerCard:FindFirstChild("HeaderStroke")
			self._uxWidgets.lobby.BasicLobbyGlyph = lobbyGlyph
			self._uxWidgets.lobby.BasicTitle = title
			self._uxWidgets.lobby.BasicStatusBadge = statusBadge
			self._uxWidgets.lobby.BasicPrimaryLabel = primaryLabel
			self._uxWidgets.lobby.BasicSecondaryLabel = secondaryLabel
			self._uxWidgets.lobby.BasicModePill = modePill
			self._uxWidgets.lobby.BasicMapPill = mapPill
			self._uxWidgets.lobby.BasicRoomPill = roomPill
			self._uxWidgets.lobby.BasicHintLabel = hintLabel
			self._uxWidgets.lobby.BasicOpenRoomBrowserButton = openRoomBrowserButton
			self._uxWidgets.lobby.BasicProfileButton = profileButton
			self._uxWidgets.lobby.BasicShopButton = shopButton
			self._uxWidgets.lobby.BasicRoyalPassButton = royalPassButton
			self._uxWidgets.lobby.BasicMenuButton = menuButton
			self._uxWidgets.lobby.BasicRankButton = rankButton
			self._uxWidgets.lobby.ToggleButton = toggleBtn
		end

		local auxiliaryConfig = AUXILIARY_WINDOW_CONFIG[guiName]
		if auxiliaryConfig then
			panel.AnchorPoint = auxiliaryConfig.panelAnchorPoint
			panel.Position = auxiliaryConfig.panelPosition
			panel.Size = UDim2.fromOffset(auxiliaryConfig.panelSize.X, auxiliaryConfig.panelSize.Y)
			panel.BackgroundColor3 = Color3.fromRGB(16, 22, 30)
			panel.BackgroundTransparency = 0.08

			local title = panel:FindFirstChild("Title")
			if title and title:IsA("TextLabel") then
				title.Text = auxiliaryConfig.title
				title.TextColor3 = Color3.fromRGB(238, 243, 248)
				title.Size = UDim2.new(1, -54, 0, 24)
			end

			local closeBtn = panel:FindFirstChild("CloseButton")
			if not closeBtn then
				closeBtn = Instance.new("TextButton")
				closeBtn.Name = "CloseButton"
				closeBtn.AnchorPoint = Vector2.new(1, 0)
				closeBtn.Position = UDim2.new(1, -10, 0, 8)
				closeBtn.Size = UDim2.fromOffset(28, 28)
				styleButton(closeBtn, "X")
				closeBtn.BackgroundColor3 = Color3.fromRGB(92, 42, 42)
				closeBtn.Parent = panel

				local closeCorner = Instance.new("UICorner")
				closeCorner.CornerRadius = UDim.new(1, 0)
				closeCorner.Parent = closeBtn

				self:_setSelectableStyle(closeBtn)
			end

			local statusBadge = panel:FindFirstChild("StatusBadge")
			if not statusBadge then
				statusBadge = Instance.new("TextLabel")
				statusBadge.Name = "StatusBadge"
				statusBadge.Position = UDim2.fromOffset(12, 42)
				statusBadge.Size = UDim2.fromOffset(128, 24)
				statusBadge.BackgroundColor3 = auxiliaryConfig.badgeColor
				statusBadge.TextColor3 = Color3.fromRGB(245, 245, 245)
				statusBadge.Font = Enum.Font.GothamBold
				statusBadge.TextSize = 12
				statusBadge.Text = auxiliaryConfig.badgeText
				statusBadge.Parent = panel

				local badgeCorner = Instance.new("UICorner")
				badgeCorner.CornerRadius = UDim.new(0, 999)
				badgeCorner.Parent = statusBadge
			end

			local primaryLabel = panel:FindFirstChild("PrimaryLabel")
			if not primaryLabel then
				primaryLabel = Instance.new("TextLabel")
				primaryLabel.Name = "PrimaryLabel"
				primaryLabel.Position = UDim2.fromOffset(12, 76)
				primaryLabel.Size = UDim2.new(1, -24, 0, 38)
				primaryLabel.BackgroundTransparency = 1
				primaryLabel.Font = Enum.Font.GothamBold
				primaryLabel.TextSize = 16
				primaryLabel.TextColor3 = Color3.fromRGB(242, 246, 250)
				primaryLabel.TextWrapped = true
				primaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				primaryLabel.TextYAlignment = Enum.TextYAlignment.Top
				primaryLabel.Text = auxiliaryConfig.title
				primaryLabel.Parent = panel
			end

			local secondaryLabel = panel:FindFirstChild("SecondaryLabel")
			if not secondaryLabel then
				secondaryLabel = Instance.new("TextLabel")
				secondaryLabel.Name = "SecondaryLabel"
				secondaryLabel.Position = UDim2.fromOffset(12, 118)
				secondaryLabel.Size = UDim2.new(1, -24, 0, 34)
				secondaryLabel.BackgroundTransparency = 1
				secondaryLabel.Font = Enum.Font.Gotham
				secondaryLabel.TextSize = 13
				secondaryLabel.TextColor3 = Color3.fromRGB(182, 196, 216)
				secondaryLabel.TextWrapped = true
				secondaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				secondaryLabel.TextYAlignment = Enum.TextYAlignment.Top
				secondaryLabel.Text = auxiliaryConfig.footer
				secondaryLabel.Parent = panel
			end

			local contentFrame = panel:FindFirstChild("ContentFrame")
			if contentFrame and not contentFrame:IsA("ScrollingFrame") then
				contentFrame:Destroy()
				contentFrame = nil
			end
			if not contentFrame then
				contentFrame = Instance.new("ScrollingFrame")
				contentFrame.Name = "ContentFrame"
				contentFrame.Position = UDim2.fromOffset(12, 156)
				contentFrame.Size = UDim2.new(1, -24, 1, -214)
				contentFrame.BackgroundColor3 = Color3.fromRGB(20, 27, 36)
				contentFrame.BackgroundTransparency = 0.06
				contentFrame.BorderSizePixel = 0
				contentFrame.ScrollBarThickness = 5
				contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
				contentFrame.CanvasSize = UDim2.fromOffset(0, 0)
				contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
				contentFrame.ElasticBehavior = Enum.ElasticBehavior.Never
				contentFrame.Parent = panel

				local contentCorner = Instance.new("UICorner")
				contentCorner.CornerRadius = UDim.new(0, 10)
				contentCorner.Parent = contentFrame

				local contentPadding = Instance.new("UIPadding")
				contentPadding.PaddingTop = UDim.new(0, 10)
				contentPadding.PaddingBottom = UDim.new(0, 10)
				contentPadding.PaddingLeft = UDim.new(0, 10)
				contentPadding.PaddingRight = UDim.new(0, 10)
				contentPadding.Parent = contentFrame
			end

			local contentText = contentFrame:FindFirstChild("ContentText")
			if not contentText then
				contentText = Instance.new("TextLabel")
				contentText.Name = "ContentText"
				contentText.Size = UDim2.new(1, -4, 0, 0)
				contentText.BackgroundTransparency = 1
				contentText.AutomaticSize = Enum.AutomaticSize.Y
				contentText.Font = Enum.Font.Gotham
				contentText.TextSize = 12
				contentText.TextColor3 = Color3.fromRGB(226, 234, 244)
				contentText.TextWrapped = true
				contentText.TextXAlignment = Enum.TextXAlignment.Left
				contentText.TextYAlignment = Enum.TextYAlignment.Top
				contentText.Text = ""
				contentText.Parent = contentFrame
			end

			local footerLabel = panel:FindFirstChild("FooterLabel")
			if not footerLabel then
				footerLabel = Instance.new("TextLabel")
				footerLabel.Name = "FooterLabel"
				footerLabel.Position = UDim2.fromOffset(12, auxiliaryConfig.panelSize.Y - 48)
				footerLabel.Size = UDim2.new(1, -24, 0, 36)
				footerLabel.BackgroundTransparency = 1
				footerLabel.Font = Enum.Font.Gotham
				footerLabel.TextSize = 11
				footerLabel.TextColor3 = Color3.fromRGB(162, 176, 198)
				footerLabel.TextWrapped = true
				footerLabel.TextXAlignment = Enum.TextXAlignment.Left
				footerLabel.TextYAlignment = Enum.TextYAlignment.Top
				footerLabel.Text = auxiliaryConfig.footer
				footerLabel.Parent = panel
			else
				footerLabel.Position = UDim2.fromOffset(12, auxiliaryConfig.panelSize.Y - 48)
				footerLabel.Size = UDim2.new(1, -24, 0, 36)
			end

			local toolActionButton = nil
			local toolStatusLabel = nil
			if guiName == "JournalUI" then
				contentFrame.Position = UDim2.fromOffset(12, 152)
				contentFrame.Size = UDim2.new(1, -24, 1, -262)

				toolActionButton = panel:FindFirstChild("ToolActionButton")
				if not toolActionButton then
					toolActionButton = Instance.new("TextButton")
					toolActionButton.Name = "ToolActionButton"
					toolActionButton.Position = UDim2.fromOffset(12, auxiliaryConfig.panelSize.Y - 102)
					toolActionButton.Size = UDim2.fromOffset(156, 40)
					styleButton(toolActionButton, "SCAN JEJAK")
					toolActionButton.BackgroundColor3 = Color3.fromRGB(56, 92, 128)
					toolActionButton.Parent = panel

					self:_setSelectableStyle(toolActionButton)
				end
				toolActionButton.Position = UDim2.fromOffset(12, auxiliaryConfig.panelSize.Y - 102)
				toolActionButton.Size = UDim2.fromOffset(156, 40)

				local toolCorner = toolActionButton:FindFirstChild("ButtonCorner")
				if not toolCorner or not toolCorner:IsA("UICorner") then
					toolCorner = Instance.new("UICorner")
					toolCorner.Name = "ButtonCorner"
					toolCorner.CornerRadius = UDim.new(0, 10)
					toolCorner.Parent = toolActionButton
				end

				toolStatusLabel = panel:FindFirstChild("ToolStatusLabel")
				if not toolStatusLabel then
					toolStatusLabel = Instance.new("TextLabel")
					toolStatusLabel.Name = "ToolStatusLabel"
					toolStatusLabel.Position = UDim2.fromOffset(176, auxiliaryConfig.panelSize.Y - 106)
					toolStatusLabel.Size = UDim2.new(1, -188, 0, 50)
					toolStatusLabel.BackgroundColor3 = Color3.fromRGB(20, 28, 38)
					toolStatusLabel.BackgroundTransparency = 0.06
					toolStatusLabel.BorderSizePixel = 0
					toolStatusLabel.Font = Enum.Font.Gotham
					toolStatusLabel.TextSize = 11
					toolStatusLabel.TextColor3 = Color3.fromRGB(178, 192, 214)
					toolStatusLabel.TextWrapped = true
					toolStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
					toolStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
					toolStatusLabel.Text = "SCAN STATUS"
					toolStatusLabel.Parent = panel
				end
				toolStatusLabel.Position = UDim2.fromOffset(176, auxiliaryConfig.panelSize.Y - 106)
				toolStatusLabel.Size = UDim2.new(1, -188, 0, 50)
				toolStatusLabel.BackgroundColor3 = Color3.fromRGB(20, 28, 38)
				toolStatusLabel.BackgroundTransparency = 0.06
				toolStatusLabel.BorderSizePixel = 0

				local statusCorner = toolStatusLabel:FindFirstChild("StatusCorner")
				if not statusCorner or not statusCorner:IsA("UICorner") then
					statusCorner = Instance.new("UICorner")
					statusCorner.Name = "StatusCorner"
					statusCorner.CornerRadius = UDim.new(0, 10)
					statusCorner.Parent = toolStatusLabel
				end

				local statusStroke = toolStatusLabel:FindFirstChild("StatusStroke")
				if not statusStroke or not statusStroke:IsA("UIStroke") then
					statusStroke = Instance.new("UIStroke")
					statusStroke.Name = "StatusStroke"
					statusStroke.Thickness = 1
					statusStroke.Color = Color3.fromRGB(58, 92, 128)
					statusStroke.Transparency = 0.24
					statusStroke.Parent = toolStatusLabel
				end

				local statusPadding = toolStatusLabel:FindFirstChild("StatusPadding")
				if not statusPadding or not statusPadding:IsA("UIPadding") then
					statusPadding = Instance.new("UIPadding")
					statusPadding.Name = "StatusPadding"
					statusPadding.PaddingLeft = UDim.new(0, 10)
					statusPadding.PaddingRight = UDim.new(0, 8)
					statusPadding.PaddingTop = UDim.new(0, 8)
					statusPadding.PaddingBottom = UDim.new(0, 6)
					statusPadding.Parent = toolStatusLabel
				end

				footerLabel.Position = UDim2.fromOffset(12, auxiliaryConfig.panelSize.Y - 50)
				footerLabel.Size = UDim2.new(1, -24, 0, 40)
			end

			local floatName = guiName .. "FloatButton"
			local floatBtn = gui:FindFirstChild(floatName)
			if not floatBtn then
				floatBtn = Instance.new("TextButton")
				floatBtn.Name = floatName
				floatBtn.AnchorPoint = Vector2.new(0.5, 0.5)
				floatBtn.Position = auxiliaryConfig.floatPosition
				floatBtn.Size = UDim2.fromOffset(60, 60)
				floatBtn.BackgroundColor3 = Color3.fromRGB(34, 46, 62)
				floatBtn.TextColor3 = Color3.fromRGB(245, 245, 245)
				floatBtn.Font = Enum.Font.GothamBold
				floatBtn.TextSize = 12
				floatBtn.TextWrapped = true
				floatBtn.Text = auxiliaryConfig.floatText
				floatBtn.Visible = false
				floatBtn.Parent = gui

				local floatCorner = Instance.new("UICorner")
				floatCorner.CornerRadius = UDim.new(1, 0)
				floatCorner.Parent = floatBtn

				local floatStroke = Instance.new("UIStroke")
				floatStroke.Thickness = 2
				floatStroke.Color = auxiliaryConfig.badgeColor
				floatStroke.Parent = floatBtn

				self:_setSelectableStyle(floatBtn)
			end
			styleFloatingButton(floatBtn, auxiliaryConfig.floatText, auxiliaryConfig.badgeColor)
			makeFloatingButtonDraggable(floatBtn)

			local itemRows = nil
			local shopFilterButtons = nil
			if guiName == "ShopUI" then
				contentText.Visible = false
				local filterBar = contentFrame:FindFirstChild("ShopFilterBar")
				if filterBar and not filterBar:IsA("Frame") then
					filterBar:Destroy()
					filterBar = nil
				end
				if not filterBar then
					filterBar = Instance.new("Frame")
					filterBar.Name = "ShopFilterBar"
					filterBar.Position = UDim2.fromOffset(0, 0)
					filterBar.Size = UDim2.new(1, -4, 0, 34)
					filterBar.BackgroundTransparency = 1
					filterBar.Parent = contentFrame

					local filterLayout = Instance.new("UIListLayout")
					filterLayout.FillDirection = Enum.FillDirection.Horizontal
					filterLayout.SortOrder = Enum.SortOrder.LayoutOrder
					filterLayout.Padding = UDim.new(0, 6)
					filterLayout.Parent = filterBar
				end
				local itemList = contentFrame:FindFirstChild("ItemList")
				if itemList and not itemList:IsA("Frame") then
					itemList:Destroy()
					itemList = nil
				end
				if not itemList then
					itemList = Instance.new("Frame")
					itemList.Name = "ItemList"
					itemList.Position = UDim2.fromOffset(0, 40)
					itemList.Size = UDim2.new(1, -4, 0, 0)
					itemList.BackgroundTransparency = 1
					itemList.AutomaticSize = Enum.AutomaticSize.Y
					itemList.Parent = contentFrame

					local itemLayout = Instance.new("UIListLayout")
					itemLayout.FillDirection = Enum.FillDirection.Vertical
					itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
					itemLayout.Padding = UDim.new(0, 6)
					itemLayout.Parent = itemList
				end
				shopFilterButtons = {}
				for _, filter in ipairs(SHOP_FILTERS) do
					local existingButton = filterBar:FindFirstChild("Filter" .. filter.key)
					if existingButton then
						existingButton:Destroy()
					end
					local filterButton = Instance.new("TextButton")
					filterButton.Name = "Filter" .. filter.key
					filterButton.Size = UDim2.fromOffset(filter.key == "Owned" and 78 or 54, 30)
					filterButton.BackgroundColor3 = Color3.fromRGB(42, 54, 72)
					filterButton.BorderSizePixel = 0
					filterButton.Text = filter.label
					filterButton.TextColor3 = Color3.fromRGB(236, 240, 244)
					filterButton.Font = Enum.Font.GothamBold
					filterButton.TextSize = 10
					filterButton.Parent = filterBar
					self:_setSelectableStyle(filterButton)

					local filterCorner = Instance.new("UICorner")
					filterCorner.CornerRadius = UDim.new(1, 0)
					filterCorner.Parent = filterButton

					local filterStroke = Instance.new("UIStroke")
					filterStroke.Thickness = 1
					filterStroke.Transparency = 0.18
					filterStroke.Color = Color3.fromRGB(92, 116, 150)
					filterStroke.Parent = filterButton

					if filterButton:GetAttribute("Bound") ~= true then
						filterButton:SetAttribute("Bound", true)
						connectButtonPress(filterButton, function()
							self:_setShopFilter(filter.key)
						end)
					end

					shopFilterButtons[filter.key] = filterButton
				end
				itemRows = {}
				local displayCount = #self._shopState.catalog
				for index = 1, displayCount do
					local existing = itemList:FindFirstChild("ItemRow" .. tostring(index))
					if existing then
						existing:Destroy()
					end
					local row = createActionRow(itemList, "ItemRow" .. tostring(index), "ITEM", "-", "BELI")
					self:_setSelectableStyle(row.Button)
					local item = self._shopState.catalog[index]
					if item then
						self:_applyShopRowVisual(row, item, index)
					end
					if row.Button:GetAttribute("Bound") ~= true then
						row.Button:SetAttribute("Bound", true)
						connectButtonPress(row.Button, function()
							local catalogItem = self._shopState.catalog[index]
							if catalogItem then
								local purchasable, blockedReason = self:_getShopItemPurchaseAvailability(catalogItem)
								if not purchasable then
									self._shopState.lastPurchase = {
										itemId = catalogItem.id,
										success = false,
										reason = blockedReason or "item_disabled",
									}
									self._shopState.lastMessage = describeShopPurchaseBlock(catalogItem, blockedReason)
									self:_openAuxiliaryWindow("ShopUI")
									return
								end
								self:_requestShopPurchase(catalogItem.id)
							end
						end)
					end
					table.insert(itemRows, row)
				end
			end

			if closeBtn:GetAttribute("Bound") ~= true then
				closeBtn:SetAttribute("Bound", true)
				connectButtonPress(closeBtn, function()
					self:_setAuxiliaryWindowDismissed(guiName, true)
				end)
			end
			if floatBtn:GetAttribute("Bound") ~= true then
				floatBtn:SetAttribute("Bound", true)
				connectButtonPress(floatBtn, function()
					self:_openAuxiliaryWindow(guiName)
				end)
			end
			if toolActionButton and toolActionButton:GetAttribute("Bound") ~= true then
				toolActionButton:SetAttribute("Bound", true)
				connectButtonPress(toolActionButton, function()
					self:_triggerJournalToolScan()
				end)
			end

			self._uxWidgets.windows[guiName] = {
				Gui = gui,
				Panel = panel,
				Title = title,
				StatusBadge = statusBadge,
				PrimaryLabel = primaryLabel,
				SecondaryLabel = secondaryLabel,
				ContentFrame = contentFrame,
				ContentText = contentText,
				FooterLabel = footerLabel,
				FloatButton = floatBtn,
				CloseButton = closeBtn,
				ShopFilterButtons = shopFilterButtons,
				ItemRows = itemRows,
				ToolActionButton = toolActionButton,
				ToolStatusLabel = toolStatusLabel,
			}
		end

		if guiName == "MatchUI" then
			panel.Size = UDim2.fromOffset(340, 454)
			panel.Position = UDim2.new(1, -16, 0, 16)
			panel.BackgroundColor3 = Color3.fromRGB(16, 22, 30)
			panel.BackgroundTransparency = 0.1

			local title = panel:FindFirstChild("Title")
			if title and title:IsA("TextLabel") then
				title.Text = "PANEL MATCH"
				title.TextColor3 = Color3.fromRGB(235, 240, 245)
				title.Size = UDim2.new(1, -54, 0, 24)
			end

			local closeBtn = panel:FindFirstChild("CloseButton")
			if not closeBtn then
				closeBtn = Instance.new("TextButton")
				closeBtn.Name = "CloseButton"
				closeBtn.AnchorPoint = Vector2.new(1, 0)
				closeBtn.Position = UDim2.new(1, -10, 0, 8)
				closeBtn.Size = UDim2.fromOffset(28, 28)
				styleButton(closeBtn, "X")
				closeBtn.BackgroundColor3 = Color3.fromRGB(92, 42, 42)
				closeBtn.Parent = panel

				local closeCorner = Instance.new("UICorner")
				closeCorner.CornerRadius = UDim.new(1, 0)
				closeCorner.Parent = closeBtn

				self:_setSelectableStyle(closeBtn)
			end

			local stateBadge = panel:FindFirstChild("StateBadge")
			if not stateBadge then
				stateBadge = Instance.new("TextLabel")
				stateBadge.Name = "StateBadge"
				stateBadge.Position = UDim2.fromOffset(12, 42)
				stateBadge.Size = UDim2.fromOffset(136, 24)
				stateBadge.BackgroundColor3 = Color3.fromRGB(62, 80, 104)
				stateBadge.TextColor3 = Color3.fromRGB(245, 245, 245)
				stateBadge.Font = Enum.Font.GothamBold
				stateBadge.TextSize = 12
				stateBadge.Text = "STATUS MATCH"
				stateBadge.Parent = panel

				local badgeCorner = Instance.new("UICorner")
				badgeCorner.CornerRadius = UDim.new(0, 999)
				badgeCorner.Parent = stateBadge
			end

			local primaryLabel = panel:FindFirstChild("PrimaryLabel")
			if not primaryLabel then
				primaryLabel = Instance.new("TextLabel")
				primaryLabel.Name = "PrimaryLabel"
				primaryLabel.Position = UDim2.fromOffset(12, 76)
				primaryLabel.Size = UDim2.new(1, -24, 0, 34)
				primaryLabel.BackgroundTransparency = 1
				primaryLabel.Font = Enum.Font.GothamBold
				primaryLabel.TextSize = 18
				primaryLabel.TextColor3 = Color3.fromRGB(242, 246, 250)
				primaryLabel.TextWrapped = true
				primaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				primaryLabel.Text = "Menunggu event match."
				primaryLabel.Parent = panel
			end

			local secondaryLabel = panel:FindFirstChild("SecondaryLabel")
			if not secondaryLabel then
				secondaryLabel = Instance.new("TextLabel")
				secondaryLabel.Name = "SecondaryLabel"
				secondaryLabel.Position = UDim2.fromOffset(12, 114)
				secondaryLabel.Size = UDim2.new(1, -24, 0, 48)
				secondaryLabel.BackgroundTransparency = 1
				secondaryLabel.Font = Enum.Font.Gotham
				secondaryLabel.TextSize = 14
				secondaryLabel.TextColor3 = Color3.fromRGB(182, 196, 216)
				secondaryLabel.TextWrapped = true
				secondaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				secondaryLabel.TextYAlignment = Enum.TextYAlignment.Top
				secondaryLabel.Text = "Panel ini bisa ditutup jika menghalangi pandangan."
				secondaryLabel.Parent = panel
			end

			local panelStroke = panel:FindFirstChild("BrandStroke")
			if not panelStroke or not panelStroke:IsA("UIStroke") then
				panelStroke = Instance.new("UIStroke")
				panelStroke.Name = "BrandStroke"
				panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				panelStroke.Thickness = 1
				panelStroke.Transparency = 0.24
				panelStroke.Color = Color3.fromRGB(84, 104, 132)
				panelStroke.Parent = panel
			end

			local headerCard = panel:FindFirstChild("HeaderCard")
			if not headerCard then
				headerCard = Instance.new("Frame")
				headerCard.Name = "HeaderCard"
				headerCard.Position = UDim2.fromOffset(12, 42)
				headerCard.Size = UDim2.new(1, -24, 0, 118)
				headerCard.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
				headerCard.BackgroundTransparency = 0.04
				headerCard.BorderSizePixel = 0
				headerCard.Parent = panel

				local headerCorner = Instance.new("UICorner")
				headerCorner.CornerRadius = UDim.new(0, 12)
				headerCorner.Parent = headerCard

				local headerStroke = Instance.new("UIStroke")
				headerStroke.Name = "HeaderStroke"
				headerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				headerStroke.Thickness = 1
				headerStroke.Transparency = 0.18
				headerStroke.Color = Color3.fromRGB(84, 104, 132)
				headerStroke.Parent = headerCard
			end

			local phaseGlyph = headerCard:FindFirstChild("PhaseGlyph")
			if not phaseGlyph then
				phaseGlyph = Instance.new("TextLabel")
				phaseGlyph.Name = "PhaseGlyph"
				phaseGlyph.AnchorPoint = Vector2.new(1, 0)
				phaseGlyph.Position = UDim2.new(1, -12, 0, 8)
				phaseGlyph.Size = UDim2.fromOffset(84, 74)
				phaseGlyph.BackgroundTransparency = 1
				phaseGlyph.Font = Enum.Font.GothamBlack
				phaseGlyph.TextSize = 52
				phaseGlyph.TextColor3 = Color3.fromRGB(88, 112, 148)
				phaseGlyph.TextTransparency = 0.38
				phaseGlyph.TextXAlignment = Enum.TextXAlignment.Right
				phaseGlyph.Text = "PR"
				phaseGlyph.Parent = headerCard
			end

			stateBadge.Parent = headerCard
			stateBadge.Position = UDim2.fromOffset(14, 12)
			stateBadge.Size = UDim2.fromOffset(144, 26)
			stateBadge.TextSize = 11
			stateBadge.Font = Enum.Font.GothamBlack

			primaryLabel.Parent = headerCard
			primaryLabel.Position = UDim2.fromOffset(14, 46)
			primaryLabel.Size = UDim2.new(1, -112, 0, 32)

			secondaryLabel.Parent = headerCard
			secondaryLabel.Position = UDim2.fromOffset(14, 78)
			secondaryLabel.Size = UDim2.new(1, -112, 0, 30)
			secondaryLabel.TextSize = 13

			local summaryFrame = panel:FindFirstChild("SummaryFrame")
			if summaryFrame and not summaryFrame:IsA("ScrollingFrame") then
				summaryFrame:Destroy()
				summaryFrame = nil
			end
			if not summaryFrame then
				summaryFrame = Instance.new("ScrollingFrame")
				summaryFrame.Name = "SummaryFrame"
				summaryFrame.Position = UDim2.fromOffset(12, 168)
				summaryFrame.Size = UDim2.new(1, -24, 0, 220)
				summaryFrame.BackgroundColor3 = Color3.fromRGB(20, 27, 36)
				summaryFrame.BackgroundTransparency = 0.06
				summaryFrame.BorderSizePixel = 0
				summaryFrame.ScrollBarThickness = 5
				summaryFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
				summaryFrame.CanvasSize = UDim2.fromOffset(0, 0)
				summaryFrame.ScrollingDirection = Enum.ScrollingDirection.Y
				summaryFrame.ElasticBehavior = Enum.ElasticBehavior.Never
				summaryFrame.ClipsDescendants = true
				summaryFrame.Parent = panel

				local summaryCorner = Instance.new("UICorner")
				summaryCorner.CornerRadius = UDim.new(0, 10)
				summaryCorner.Parent = summaryFrame

				local summaryStroke = Instance.new("UIStroke")
				summaryStroke.Name = "BrandStroke"
				summaryStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				summaryStroke.Thickness = 1
				summaryStroke.Transparency = 0.2
				summaryStroke.Color = Color3.fromRGB(80, 100, 126)
				summaryStroke.Parent = summaryFrame

				local summaryPadding = Instance.new("UIPadding")
				summaryPadding.PaddingTop = UDim.new(0, 10)
				summaryPadding.PaddingBottom = UDim.new(0, 10)
				summaryPadding.PaddingLeft = UDim.new(0, 10)
				summaryPadding.PaddingRight = UDim.new(0, 10)
				summaryPadding.Parent = summaryFrame

				local summaryLayout = Instance.new("UIListLayout")
				summaryLayout.FillDirection = Enum.FillDirection.Vertical
				summaryLayout.SortOrder = Enum.SortOrder.LayoutOrder
				summaryLayout.Padding = UDim.new(0, 6)
				summaryLayout.Parent = summaryFrame
			end

			local hideBtn = panel:FindFirstChild("HideButton")
			if not hideBtn then
				hideBtn = Instance.new("TextButton")
				hideBtn.Name = "HideButton"
				hideBtn.Position = UDim2.fromOffset(12, 396)
				hideBtn.Size = UDim2.fromOffset(144, 40)
				styleButton(hideBtn, "SEMBUNYIKAN")
				hideBtn.BackgroundColor3 = Color3.fromRGB(44, 58, 76)
				hideBtn.Parent = panel
				self:_setSelectableStyle(hideBtn)
			end

			local footerLabel = panel:FindFirstChild("FooterLabel")
			if not footerLabel then
				footerLabel = Instance.new("TextLabel")
				footerLabel.Name = "FooterLabel"
				footerLabel.Position = UDim2.fromOffset(166, 396)
				footerLabel.Size = UDim2.new(1, -178, 0, 40)
				footerLabel.BackgroundTransparency = 1
				footerLabel.Font = Enum.Font.Gotham
				footerLabel.TextSize = 12
				footerLabel.TextColor3 = Color3.fromRGB(162, 176, 198)
				footerLabel.TextWrapped = true
				footerLabel.TextXAlignment = Enum.TextXAlignment.Left
				footerLabel.TextYAlignment = Enum.TextYAlignment.Top
				footerLabel.Text = CLOSE_HINT_TEXT
				footerLabel.Parent = panel
			end

			local timerLabel = gui:FindFirstChild("MatchTimerLabel")
			if not timerLabel then
				timerLabel = Instance.new("TextLabel")
				timerLabel.Name = "MatchTimerLabel"
				timerLabel.AnchorPoint = Vector2.new(0.5, 0)
				timerLabel.Position = UDim2.new(0.5, 0, 0, 18)
				timerLabel.Size = UDim2.fromOffset(126, 40)
				timerLabel.BackgroundColor3 = Color3.fromRGB(16, 22, 30)
				timerLabel.BackgroundTransparency = 0.1
				timerLabel.TextColor3 = Color3.fromRGB(245, 245, 245)
				timerLabel.Font = Enum.Font.GothamBold
				timerLabel.TextSize = 24
				timerLabel.Text = "00:00"
				timerLabel.Visible = false
				timerLabel.Parent = gui

				local timerCorner = Instance.new("UICorner")
				timerCorner.CornerRadius = UDim.new(0, 12)
				timerCorner.Parent = timerLabel
			end

			local timerCaption = gui:FindFirstChild("MatchTimerCaption")
			if not timerCaption then
				timerCaption = Instance.new("TextLabel")
				timerCaption.Name = "MatchTimerCaption"
				timerCaption.AnchorPoint = Vector2.new(0.5, 0)
				timerCaption.Position = UDim2.new(0.5, 0, 0, 60)
				timerCaption.Size = UDim2.fromOffset(170, 18)
				timerCaption.BackgroundTransparency = 1
				timerCaption.TextColor3 = Color3.fromRGB(190, 204, 224)
				timerCaption.Font = Enum.Font.GothamSemibold
				timerCaption.TextSize = 11
				timerCaption.Text = "PHASE TIMER"
				timerCaption.Visible = false
				timerCaption.Parent = gui
			end

			local evidenceQuickButton = gui:FindFirstChild("EvidenceQuickButton")
			if not evidenceQuickButton then
				evidenceQuickButton = Instance.new("TextButton")
				evidenceQuickButton.Name = "EvidenceQuickButton"
				evidenceQuickButton.AnchorPoint = Vector2.new(1, 1)
				evidenceQuickButton.Position = UDim2.new(1, -18, 1, -18)
				evidenceQuickButton.Size = UDim2.fromOffset(142, 48)
				styleButton(evidenceQuickButton, "EVIDENCE [J]")
				evidenceQuickButton.BackgroundColor3 = Color3.fromRGB(52, 82, 118)
				evidenceQuickButton.Visible = false
				evidenceQuickButton.Parent = gui

				local evidenceCorner = Instance.new("UICorner")
				evidenceCorner.CornerRadius = UDim.new(0, 10)
				evidenceCorner.Parent = evidenceQuickButton

				self:_setSelectableStyle(evidenceQuickButton)
			end

			local controlsHintBar = gui:FindFirstChild("ControlsHintBar")
			if not controlsHintBar then
				controlsHintBar = Instance.new("Frame")
				controlsHintBar.Name = "ControlsHintBar"
				controlsHintBar.AnchorPoint = Vector2.new(0.5, 1)
				controlsHintBar.Position = UDim2.new(0.5, 0, 1, -14)
				controlsHintBar.Size = UDim2.fromOffset(620, 34)
				controlsHintBar.BackgroundColor3 = Color3.fromRGB(16, 22, 30)
				controlsHintBar.BackgroundTransparency = 0.12
				controlsHintBar.Visible = false
				controlsHintBar.Parent = gui

				local hintCorner = Instance.new("UICorner")
				hintCorner.CornerRadius = UDim.new(0, 10)
				hintCorner.Parent = controlsHintBar
			end

			local controlsHintLabel = controlsHintBar:FindFirstChild("Label")
			if not controlsHintLabel then
				controlsHintLabel = Instance.new("TextLabel")
				controlsHintLabel.Name = "Label"
				controlsHintLabel.Position = UDim2.fromOffset(10, 0)
				controlsHintLabel.Size = UDim2.new(1, -20, 1, 0)
				controlsHintLabel.BackgroundTransparency = 1
				controlsHintLabel.Font = Enum.Font.GothamSemibold
				controlsHintLabel.TextSize = 12
				controlsHintLabel.TextColor3 = Color3.fromRGB(224, 232, 242)
				controlsHintLabel.TextXAlignment = Enum.TextXAlignment.Center
				controlsHintLabel.Text = self._matchControlsHintText
				controlsHintLabel.Parent = controlsHintBar
			end

			local fieldKitFrame = gui:FindFirstChild("FieldKitFrame")
			if not fieldKitFrame then
				fieldKitFrame = Instance.new("Frame")
				fieldKitFrame.Name = "FieldKitFrame"
				fieldKitFrame.AnchorPoint = Vector2.new(0, 1)
				fieldKitFrame.Position = UDim2.new(0, 16, 1, -60)
				fieldKitFrame.Size = UDim2.fromOffset(356, 146)
				fieldKitFrame.BackgroundColor3 = Color3.fromRGB(16, 22, 30)
				fieldKitFrame.BackgroundTransparency = 0.08
				fieldKitFrame.BorderSizePixel = 0
				fieldKitFrame.Visible = false
				fieldKitFrame.Parent = gui

				local frameCorner = Instance.new("UICorner")
				frameCorner.CornerRadius = UDim.new(0, 12)
				frameCorner.Parent = fieldKitFrame

				local frameStroke = Instance.new("UIStroke")
				frameStroke.Name = "FrameStroke"
				frameStroke.Thickness = 1
				frameStroke.Color = Color3.fromRGB(88, 108, 132)
				frameStroke.Transparency = 0.18
				frameStroke.Parent = fieldKitFrame
			end

			local fieldKitTitle = fieldKitFrame:FindFirstChild("Title")
			if not fieldKitTitle then
				fieldKitTitle = Instance.new("TextLabel")
				fieldKitTitle.Name = "Title"
				fieldKitTitle.Position = UDim2.fromOffset(12, 10)
				fieldKitTitle.Size = UDim2.new(1, -24, 0, 18)
				fieldKitTitle.BackgroundTransparency = 1
				fieldKitTitle.Font = Enum.Font.GothamBold
				fieldKitTitle.TextSize = 11
				fieldKitTitle.TextColor3 = Color3.fromRGB(202, 214, 228)
				fieldKitTitle.TextXAlignment = Enum.TextXAlignment.Left
				fieldKitTitle.Text = "FIELD KIT"
				fieldKitTitle.Parent = fieldKitFrame
			end

			local fieldKitButtonsFrame = fieldKitFrame:FindFirstChild("Buttons")
			if not fieldKitButtonsFrame then
				fieldKitButtonsFrame = Instance.new("Frame")
				fieldKitButtonsFrame.Name = "Buttons"
				fieldKitButtonsFrame.Position = UDim2.fromOffset(12, 34)
				fieldKitButtonsFrame.Size = UDim2.new(1, -24, 0, 58)
				fieldKitButtonsFrame.BackgroundTransparency = 1
				fieldKitButtonsFrame.Parent = fieldKitFrame

				local fieldKitGrid = Instance.new("UIGridLayout")
				fieldKitGrid.Name = "Grid"
				fieldKitGrid.CellPadding = UDim2.fromOffset(6, 0)
				fieldKitGrid.CellSize = UDim2.fromOffset(79, 56)
				fieldKitGrid.FillDirection = Enum.FillDirection.Horizontal
				fieldKitGrid.FillDirectionMaxCells = 4
				fieldKitGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
				fieldKitGrid.SortOrder = Enum.SortOrder.LayoutOrder
				fieldKitGrid.VerticalAlignment = Enum.VerticalAlignment.Top
				fieldKitGrid.Parent = fieldKitButtonsFrame
			end

			local fieldKitStatusLabel = fieldKitFrame:FindFirstChild("StatusLabel")
			if not fieldKitStatusLabel then
				fieldKitStatusLabel = Instance.new("TextLabel")
				fieldKitStatusLabel.Name = "StatusLabel"
				fieldKitStatusLabel.Position = UDim2.fromOffset(12, 98)
				fieldKitStatusLabel.Size = UDim2.new(1, -24, 0, 36)
				fieldKitStatusLabel.BackgroundTransparency = 1
				fieldKitStatusLabel.Font = Enum.Font.Gotham
				fieldKitStatusLabel.TextSize = 11
				fieldKitStatusLabel.TextColor3 = Color3.fromRGB(208, 216, 228)
				fieldKitStatusLabel.TextWrapped = true
				fieldKitStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
				fieldKitStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
				fieldKitStatusLabel.Text = "Field kit siap.\nPilih tool untuk lanjut investigasi."
				fieldKitStatusLabel.Parent = fieldKitFrame
			end

			local fieldKitButtons = {}
			for order, toolType in ipairs(FIELD_KIT_TOOL_ORDER) do
				local definition = FIELD_KIT_TOOL_CONFIG[toolType]
				local buttonName = toolType .. "Button"
				local toolButton = fieldKitButtonsFrame:FindFirstChild(buttonName)
				if not toolButton then
					toolButton = Instance.new("TextButton")
					toolButton.Name = buttonName
					toolButton.LayoutOrder = order
					toolButton.Size = UDim2.fromOffset(79, 56)
					styleButton(toolButton, definition.label)
					toolButton.TextWrapped = true
					toolButton.BackgroundColor3 = definition.accent:Lerp(Color3.fromRGB(34, 42, 56), 0.44)
					toolButton.Parent = fieldKitButtonsFrame
					self:_setSelectableStyle(toolButton)
				end
				local fieldKitWidget = ensureFieldKitButtonVisuals(toolButton, definition)
				if toolButton:GetAttribute("Bound") ~= true then
					local boundToolType = toolType
					local boundOpenJournal = definition.openJournal == true
					toolButton:SetAttribute("Bound", true)
					connectButtonPress(toolButton, function()
						self:_useInvestigationTool(boundToolType, {
							openJournal = boundOpenJournal,
						})
					end)
				end
				fieldKitButtons[toolType] = fieldKitWidget
			end

			local floatBtn = gui:FindFirstChild("MatchFloatButton")
			if not floatBtn then
				floatBtn = Instance.new("TextButton")
				floatBtn.Name = "MatchFloatButton"
				floatBtn.AnchorPoint = Vector2.new(1, 0.5)
				floatBtn.Position = UDim2.new(1, -18, 0.68, 0)
				floatBtn.Size = UDim2.fromOffset(66, 66)
				floatBtn.BackgroundColor3 = Color3.fromRGB(34, 46, 62)
				floatBtn.TextColor3 = Color3.fromRGB(245, 245, 245)
				floatBtn.Font = Enum.Font.GothamBold
				floatBtn.TextSize = 12
				floatBtn.TextWrapped = true
				floatBtn.Text = "MATCH"
				floatBtn.Visible = false
				floatBtn.Parent = gui

				local floatCorner = Instance.new("UICorner")
				floatCorner.CornerRadius = UDim.new(1, 0)
				floatCorner.Parent = floatBtn

				local floatStroke = Instance.new("UIStroke")
				floatStroke.Thickness = 2
				floatStroke.Color = Color3.fromRGB(98, 122, 154)
				floatStroke.Parent = floatBtn

				self:_setSelectableStyle(floatBtn)
			end
			styleFloatingButton(floatBtn, "MATCH", Color3.fromRGB(98, 122, 154))
			makeFloatingButtonDraggable(floatBtn)

			local function ensureSummaryValue(rowName, labelText)
				local row = summaryFrame:FindFirstChild(rowName)
				if row and row:IsA("Frame") then
					local value = row:FindFirstChild("Value")
					if value and value:IsA("TextLabel") then
						return value
					end
				end
				return createSummaryRow(summaryFrame, rowName, labelText)
			end

			local summaryRows = {
				status = ensureSummaryValue("StatusRow", "Status Misi"),
				ghostType = ensureSummaryValue("GhostRow", "Ghost"),
				correctGuess = ensureSummaryValue("GuessRow", "Tebakan"),
				evidenceCollected = ensureSummaryValue("EvidenceRow", "Evidence"),
				playersSurvived = ensureSummaryValue("SurvivedRow", "Pemain Selamat"),
				playersDead = ensureSummaryValue("DeadRow", "Pemain Mati"),
				matchDuration = ensureSummaryValue("DurationRow", "Durasi"),
				currencyReward = ensureSummaryValue("RewardRow", "Hadiah MM / PP"),
				xpReward = ensureSummaryValue("XpRow", "Hadiah XP"),
			}

			if closeBtn:GetAttribute("Bound") ~= true then
				closeBtn:SetAttribute("Bound", true)
				connectButtonPress(closeBtn, function()
					self:_setMatchWindowDismissed(true)
				end)
			end
			if hideBtn:GetAttribute("Bound") ~= true then
				hideBtn:SetAttribute("Bound", true)
				connectButtonPress(hideBtn, function()
					self:_setMatchWindowDismissed(true)
				end)
			end
			if floatBtn:GetAttribute("Bound") ~= true then
				floatBtn:SetAttribute("Bound", true)
				connectButtonPress(floatBtn, function()
					self:_setMatchWindowDismissed(false)
				end)
			end
			if evidenceQuickButton:GetAttribute("Bound") ~= true then
				evidenceQuickButton:SetAttribute("Bound", true)
				connectButtonPress(evidenceQuickButton, function()
					self:_toggleAuxiliaryWindow("JournalUI")
				end)
			end

			self._uxWidgets.match.BasicGui = gui
			self._uxWidgets.match.BasicPanel = panel
			self._uxWidgets.match.HeaderCard = headerCard
			self._uxWidgets.match.HeaderStroke = headerCard:FindFirstChild("HeaderStroke")
			self._uxWidgets.match.PhaseGlyph = phaseGlyph
			self._uxWidgets.match.BasicTitle = title
			self._uxWidgets.match.BasicStateBadge = stateBadge
			self._uxWidgets.match.BasicPrimaryLabel = primaryLabel
			self._uxWidgets.match.BasicSecondaryLabel = secondaryLabel
			self._uxWidgets.match.BasicFooterLabel = footerLabel
			self._uxWidgets.match.SummaryFrame = summaryFrame
			self._uxWidgets.match.TimerLabel = timerLabel
			self._uxWidgets.match.TimerCaption = timerCaption
			self._uxWidgets.match.EvidenceQuickButton = evidenceQuickButton
			self._uxWidgets.match.ControlsHintBar = controlsHintBar
			self._uxWidgets.match.ControlsHintLabel = controlsHintLabel
			self._uxWidgets.match.FieldKitFrame = fieldKitFrame
			self._uxWidgets.match.FieldKitTitle = fieldKitTitle
			self._uxWidgets.match.FieldKitButtonsFrame = fieldKitButtonsFrame
			self._uxWidgets.match.FieldKitButtons = fieldKitButtons
			self._uxWidgets.match.FieldKitStatusLabel = fieldKitStatusLabel
			self._uxWidgets.match.FieldKitGrid = fieldKitButtonsFrame:FindFirstChild("Grid")
			self._uxWidgets.match.BasicSummaryRows = summaryRows
			self._uxWidgets.match.BasicFloatButton = floatBtn
			self._uxWidgets.match.BasicCloseButton = closeBtn
			self._uxWidgets.match.BasicHideButton = hideBtn
		end

		if guiName == "MainMenuUI" or guiName == "LeaderboardUI" then
			local config = guiName == "LeaderboardUI"
				and {
					title = "RANK BOARD",
					panelAnchorPoint = Vector2.new(0.5, 1),
					panelPosition = UDim2.new(0.5, 0, 1, -16),
					panelSize = Vector2.new(340, 448),
					panelColor = Color3.fromRGB(18, 25, 34),
					badgeColor = Color3.fromRGB(92, 104, 60),
					floatPosition = UDim2.new(1, -18, 0.64, 0),
					floatText = "RANK",
				}
				or {
					title = "QUICK MENU",
					panelAnchorPoint = Vector2.new(0.5, 0),
					panelPosition = UDim2.new(0.5, 0, 0, 16),
					panelSize = Vector2.new(340, 318),
					panelColor = Color3.fromRGB(18, 26, 34),
					badgeColor = Color3.fromRGB(60, 92, 132),
					floatPosition = UDim2.new(1, -18, 0.36, 0),
					floatText = "MENU",
				}
			panel.AnchorPoint = config.panelAnchorPoint
			panel.Position = config.panelPosition
			panel.Size = UDim2.fromOffset(config.panelSize.X, config.panelSize.Y)
			panel.BackgroundColor3 = config.panelColor
			panel.BackgroundTransparency = 0.08

			local title = panel:FindFirstChild("Title")
			if title and title:IsA("TextLabel") then
				title.Text = config.title
				title.Size = UDim2.new(1, -56, 0, 24)
				title.TextColor3 = Color3.fromRGB(238, 243, 248)
				title.Font = Enum.Font.GothamBold
			end

			local statusBadge = panel:FindFirstChild("StatusBadge")
			if not statusBadge then
				statusBadge = Instance.new("TextLabel")
				statusBadge.Name = "StatusBadge"
				statusBadge.Position = UDim2.fromOffset(12, 42)
				statusBadge.Size = UDim2.fromOffset(126, 24)
				statusBadge.BackgroundColor3 = config.badgeColor
				statusBadge.TextColor3 = Color3.fromRGB(245, 245, 245)
				statusBadge.Font = Enum.Font.GothamBold
				statusBadge.TextSize = 12
				statusBadge.Text = guiName == "LeaderboardUI" and "LOCAL SNAPSHOT" or "QUICK ACCESS"
				statusBadge.Parent = panel

				local badgeCorner = Instance.new("UICorner")
				badgeCorner.CornerRadius = UDim.new(0, 999)
				badgeCorner.Parent = statusBadge
			end

			local primaryLabel = panel:FindFirstChild("PrimaryLabel")
			if not primaryLabel then
				primaryLabel = Instance.new("TextLabel")
				primaryLabel.Name = "PrimaryLabel"
				primaryLabel.Position = UDim2.fromOffset(12, 76)
				primaryLabel.Size = UDim2.new(1, -24, 0, 38)
				primaryLabel.BackgroundTransparency = 1
				primaryLabel.Font = Enum.Font.GothamBold
				primaryLabel.TextSize = 16
				primaryLabel.TextColor3 = Color3.fromRGB(242, 246, 250)
				primaryLabel.TextWrapped = true
				primaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				primaryLabel.TextYAlignment = Enum.TextYAlignment.Top
				primaryLabel.Parent = panel
			end

			local secondaryLabel = panel:FindFirstChild("SecondaryLabel")
			if not secondaryLabel then
				secondaryLabel = Instance.new("TextLabel")
				secondaryLabel.Name = "SecondaryLabel"
				secondaryLabel.Position = UDim2.fromOffset(12, 118)
				secondaryLabel.Size = UDim2.new(1, -24, 0, 32)
				secondaryLabel.BackgroundTransparency = 1
				secondaryLabel.Font = Enum.Font.Gotham
				secondaryLabel.TextSize = 13
				secondaryLabel.TextColor3 = Color3.fromRGB(182, 196, 216)
				secondaryLabel.TextWrapped = true
				secondaryLabel.TextXAlignment = Enum.TextXAlignment.Left
				secondaryLabel.TextYAlignment = Enum.TextYAlignment.Top
				secondaryLabel.Parent = panel
			end

			local closeBtn = panel:FindFirstChild("CloseButton")
			if not closeBtn then
				closeBtn = Instance.new("TextButton")
				closeBtn.Name = "CloseButton"
				closeBtn.AnchorPoint = Vector2.new(1, 0)
				closeBtn.Position = UDim2.new(1, -8, 0, 8)
				closeBtn.Size = UDim2.fromOffset(24, 24)
				closeBtn.BackgroundColor3 = Color3.fromRGB(68, 36, 36)
				closeBtn.TextColor3 = Color3.fromRGB(245, 245, 245)
				closeBtn.Font = Enum.Font.GothamBold
				closeBtn.TextSize = 14
				closeBtn.Text = "[X]"
				closeBtn.Parent = panel
			end
			closeBtn.Text = "[X]"
			local closeCorner = closeBtn:FindFirstChildOfClass("UICorner")
			if not closeCorner then
				closeCorner = Instance.new("UICorner")
				closeCorner.Parent = closeBtn
			end
			closeCorner.CornerRadius = UDim.new(1, 0)

			local floatName = guiName == "LeaderboardUI" and "LeaderboardFloatButton" or "MainMenuFloatButton"
			local fallbackFloatName = guiName == "LeaderboardUI" and "MainMenuFloatButton" or "LeaderboardFloatButton"
			local floatBtn = gui:FindFirstChild(floatName) or gui:FindFirstChild(fallbackFloatName)
			if not floatBtn then
				floatBtn = Instance.new("TextButton")
				floatBtn.Name = floatName
				floatBtn.AnchorPoint = Vector2.new(1, 0.5)
				floatBtn.Position = config.floatPosition
				floatBtn.Size = UDim2.fromOffset(60, 60)
				floatBtn.BackgroundColor3 = Color3.fromRGB(44, 55, 74)
				floatBtn.TextColor3 = Color3.fromRGB(245, 245, 245)
				floatBtn.Font = Enum.Font.GothamBold
				floatBtn.TextSize = 12
				floatBtn.TextWrapped = true
				floatBtn.Text = config.floatText
				floatBtn.Visible = false
				floatBtn.Parent = gui

				local floatCorner = Instance.new("UICorner")
				floatCorner.CornerRadius = UDim.new(1, 0)
				floatCorner.Parent = floatBtn

				local floatStroke = Instance.new("UIStroke")
				floatStroke.Thickness = 2
				floatStroke.Color = Color3.fromRGB(115, 132, 160)
				floatStroke.Parent = floatBtn

				self:_setSelectableStyle(floatBtn)
			end
			floatBtn.Name = floatName
			floatBtn.Position = config.floatPosition
			floatBtn.Text = config.floatText
			styleFloatingButton(floatBtn, config.floatText, config.badgeColor)

			local footerLabel = panel:FindFirstChild("FooterLabel")
			if not footerLabel then
				footerLabel = Instance.new("TextLabel")
				footerLabel.Name = "FooterLabel"
				footerLabel.BackgroundTransparency = 1
				footerLabel.Font = Enum.Font.Gotham
				footerLabel.TextSize = 11
				footerLabel.TextColor3 = Color3.fromRGB(162, 176, 198)
				footerLabel.TextWrapped = true
				footerLabel.TextXAlignment = Enum.TextXAlignment.Left
				footerLabel.TextYAlignment = Enum.TextYAlignment.Top
				footerLabel.Parent = panel
			end

			local actionButtons = {}
			local roomBrowserButton = nil
			local profileButton = nil
			local shopButton = nil
			local rankButton = nil
			local contentFrame = nil
			local contentText = nil
			local menuButton = nil

			if guiName == "MainMenuUI" then
				local buttonWidth = 152
				local buttonHeight = 52
				local buttonDefinitions = {
					{
						name = "RoomBrowserButton",
						text = "OPEN ROOM BROWSER",
						position = UDim2.fromOffset(12, 162),
						color = Color3.fromRGB(46, 78, 114),
					},
					{
						name = "ProfileButton",
						text = "OPEN PROFILE",
						position = UDim2.fromOffset(176, 162),
						color = Color3.fromRGB(58, 84, 62),
					},
					{
						name = "ShopButton",
						text = "OPEN SHOP",
						position = UDim2.fromOffset(12, 222),
						color = Color3.fromRGB(104, 78, 48),
					},
					{
						name = "RankButton",
						text = "OPEN RANK BOARD",
						position = UDim2.fromOffset(176, 222),
						color = Color3.fromRGB(78, 84, 50),
					},
				}

				for _, definition in ipairs(buttonDefinitions) do
					local button = panel:FindFirstChild(definition.name)
					if not button then
						button = Instance.new("TextButton")
						button.Name = definition.name
						button.Position = definition.position
						button.Size = UDim2.fromOffset(buttonWidth, buttonHeight)
						styleButton(button, definition.text)
						button.BackgroundColor3 = definition.color
						button.TextWrapped = true
						button.Parent = panel

						local buttonCorner = Instance.new("UICorner")
						buttonCorner.CornerRadius = UDim.new(0, 10)
						buttonCorner.Parent = button

						self:_setSelectableStyle(button)
					else
						button.Position = definition.position
						button.Size = UDim2.fromOffset(buttonWidth, buttonHeight)
						button.BackgroundColor3 = definition.color
						button.TextWrapped = true
					end

					if definition.name == "RoomBrowserButton" then
						roomBrowserButton = button
					elseif definition.name == "ProfileButton" then
						profileButton = button
					elseif definition.name == "ShopButton" then
						shopButton = button
					elseif definition.name == "RankButton" then
						rankButton = button
					end
					table.insert(actionButtons, button)
				end

				footerLabel.Position = UDim2.fromOffset(12, 284)
				footerLabel.Size = UDim2.new(1, -24, 0, 24)
			else
				local contentFrameHeight = guiName == "LeaderboardUI" and 214 or 112
				local actionRowY = guiName == "LeaderboardUI" and 378 or 276
				local footerY = guiName == "LeaderboardUI" and 420 or 318
				local footerHeight = guiName == "LeaderboardUI" and 18 or 22
				contentFrame = panel:FindFirstChild("ContentFrame")
				if contentFrame and not contentFrame:IsA("ScrollingFrame") then
					contentFrame:Destroy()
					contentFrame = nil
				end
				if not contentFrame then
					contentFrame = Instance.new("ScrollingFrame")
					contentFrame.Name = "ContentFrame"
					contentFrame.Position = UDim2.fromOffset(12, 154)
					contentFrame.Size = UDim2.new(1, -24, 0, contentFrameHeight)
					contentFrame.BackgroundColor3 = Color3.fromRGB(20, 27, 36)
					contentFrame.BackgroundTransparency = 0.06
					contentFrame.BorderSizePixel = 0
					contentFrame.ScrollBarThickness = 5
					contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
					contentFrame.CanvasSize = UDim2.fromOffset(0, 0)
					contentFrame.ScrollingDirection = Enum.ScrollingDirection.Y
					contentFrame.ElasticBehavior = Enum.ElasticBehavior.Never
					contentFrame.Parent = panel

					local contentCorner = Instance.new("UICorner")
					contentCorner.CornerRadius = UDim.new(0, 10)
					contentCorner.Parent = contentFrame

					local contentPadding = Instance.new("UIPadding")
					contentPadding.PaddingTop = UDim.new(0, 10)
					contentPadding.PaddingBottom = UDim.new(0, 10)
					contentPadding.PaddingLeft = UDim.new(0, 10)
					contentPadding.PaddingRight = UDim.new(0, 10)
					contentPadding.Parent = contentFrame
				end
				contentFrame.Size = UDim2.new(1, -24, 0, contentFrameHeight)

				contentText = contentFrame:FindFirstChild("ContentText")
				if not contentText then
					contentText = Instance.new("TextLabel")
					contentText.Name = "ContentText"
					contentText.Size = UDim2.new(1, -4, 0, 0)
					contentText.BackgroundTransparency = 1
					contentText.AutomaticSize = Enum.AutomaticSize.Y
					contentText.Font = Enum.Font.Gotham
					contentText.TextSize = 12
					contentText.TextColor3 = Color3.fromRGB(226, 234, 244)
					contentText.TextWrapped = true
					contentText.TextXAlignment = Enum.TextXAlignment.Left
					contentText.TextYAlignment = Enum.TextYAlignment.Top
					contentText.Parent = contentFrame
				end

				local profileAction = panel:FindFirstChild("ProfileButton")
				if not profileAction then
					profileAction = Instance.new("TextButton")
					profileAction.Name = "ProfileButton"
					profileAction.Position = UDim2.fromOffset(12, actionRowY)
					profileAction.Size = UDim2.fromOffset(98, 36)
					styleButton(profileAction, "PROFILE")
					profileAction.BackgroundColor3 = Color3.fromRGB(58, 84, 62)
					profileAction.Parent = panel

					local buttonCorner = Instance.new("UICorner")
					buttonCorner.CornerRadius = UDim.new(0, 10)
					buttonCorner.Parent = profileAction

					self:_setSelectableStyle(profileAction)
				end
				profileAction.Position = UDim2.fromOffset(12, actionRowY)
				profileButton = profileAction

				local roomAction = panel:FindFirstChild("RoomBrowserButton")
				if not roomAction then
					roomAction = Instance.new("TextButton")
					roomAction.Name = "RoomBrowserButton"
					roomAction.Position = UDim2.fromOffset(120, actionRowY)
					roomAction.Size = UDim2.fromOffset(98, 36)
					styleButton(roomAction, "OPEN ROOMS")
					roomAction.BackgroundColor3 = Color3.fromRGB(46, 78, 114)
					roomAction.Parent = panel

					local buttonCorner = Instance.new("UICorner")
					buttonCorner.CornerRadius = UDim.new(0, 10)
					buttonCorner.Parent = roomAction

					self:_setSelectableStyle(roomAction)
				end
				roomAction.Position = UDim2.fromOffset(120, actionRowY)
				roomBrowserButton = roomAction

				local menuAction = panel:FindFirstChild("MenuButton")
				if not menuAction then
					menuAction = Instance.new("TextButton")
					menuAction.Name = "MenuButton"
					menuAction.Position = UDim2.fromOffset(228, actionRowY)
					menuAction.Size = UDim2.fromOffset(98, 36)
					styleButton(menuAction, "OPEN MENU")
					menuAction.BackgroundColor3 = Color3.fromRGB(58, 66, 84)
					menuAction.Parent = panel

					local buttonCorner = Instance.new("UICorner")
					buttonCorner.CornerRadius = UDim.new(0, 10)
					buttonCorner.Parent = menuAction

					self:_setSelectableStyle(menuAction)
				end
				menuAction.Position = UDim2.fromOffset(228, actionRowY)
				menuButton = menuAction
				actionButtons = { profileButton, roomBrowserButton, menuButton }

				footerLabel.Position = UDim2.fromOffset(12, footerY)
				footerLabel.Size = UDim2.new(1, -24, 0, footerHeight)
			end

			local initAttribute = guiName == "LeaderboardUI" and "LeaderboardInitDone" or "MainMenuInitDone"
			if gui:GetAttribute(initAttribute) ~= true then
				gui:SetAttribute(initAttribute, true)
				panel.Visible = false
				floatBtn.Visible = true
			end

			floatBtn.Visible = panel.Visible ~= true
			makeFloatingButtonDraggable(floatBtn)

			if closeBtn:GetAttribute("Bound") ~= true then
				closeBtn:SetAttribute("Bound", true)
				connectButtonPress(closeBtn, function()
					self:_setBasicWindowVisible(guiName, false)
				end)
			end

			if floatBtn:GetAttribute("Bound") ~= true then
				floatBtn:SetAttribute("Bound", true)
				connectButtonPress(floatBtn, function()
					self:_setBasicWindowVisible(guiName, true)
				end)
			end

			if roomBrowserButton and roomBrowserButton:GetAttribute("Bound") ~= true then
				roomBrowserButton:SetAttribute("Bound", true)
				connectButtonPress(roomBrowserButton, function()
					self:_toggleRoomBrowserVisible()
				end)
			end
			if profileButton and profileButton:GetAttribute("Bound") ~= true then
				profileButton:SetAttribute("Bound", true)
				connectButtonPress(profileButton, function()
					self:_toggleAuxiliaryWindow("ProfileUI")
				end)
			end
			if shopButton and shopButton:GetAttribute("Bound") ~= true then
				shopButton:SetAttribute("Bound", true)
				connectButtonPress(shopButton, function()
					self:_toggleAuxiliaryWindow("ShopUI")
				end)
			end
			if rankButton and rankButton:GetAttribute("Bound") ~= true then
				rankButton:SetAttribute("Bound", true)
				connectButtonPress(rankButton, function()
					self:_toggleBasicWindow("LeaderboardUI")
				end)
			end
			if menuButton and menuButton:GetAttribute("Bound") ~= true then
				menuButton:SetAttribute("Bound", true)
				connectButtonPress(menuButton, function()
					self:_toggleBasicWindow("MainMenuUI")
				end)
			end

			self._uxWidgets.basicWindows[guiName] = {
				Gui = gui,
				Panel = panel,
				Title = title,
				StatusBadge = statusBadge,
				PrimaryLabel = primaryLabel,
				SecondaryLabel = secondaryLabel,
				ContentFrame = contentFrame,
				ContentText = contentText,
				FooterLabel = footerLabel,
				FloatButton = floatBtn,
				CloseButton = closeBtn,
				ActionButtons = actionButtons,
				RoomBrowserButton = roomBrowserButton,
				ProfileButton = profileButton,
				ShopButton = shopButton,
				RankButton = rankButton,
				MenuButton = menuButton,
			}
		end
	end

	self:_refreshBasicLobbyPanel()
	self:_refreshBasicMatchPanel("Lobby")
	self:_applyVisibility()
end

function UISystem:_ensureRoomBrowserGui()
	local playerGui = self:_getPlayerGui()
	local player = Players.LocalPlayer
	if not playerGui or not player then
		return
	end

	if self._roomBrowserGui and self._roomBrowserGui.Parent == playerGui and self._roomBrowserWidgets and self._roomBrowserFloatGui and self._roomBrowserFloatGui.Parent == playerGui then
		return
	end

	if self._roomBrowserGui and self._roomBrowserGui.Parent ~= playerGui then
		self._roomBrowserGui = nil
		self._roomBrowserWidgets = nil
	end
	if self._roomBrowserFloatGui and self._roomBrowserFloatGui.Parent ~= playerGui then
		self._roomBrowserFloatGui = nil
	end

	local existingPrimary = playerGui:FindFirstChild("RoomBrowserUI")
	if existingPrimary and self._roomBrowserGui and existingPrimary ~= self._roomBrowserGui then
		existingPrimary:Destroy()
	elseif existingPrimary and not self._roomBrowserGui then
		existingPrimary:Destroy()
	end

	local lobbyUi = playerGui:FindFirstChild("LobbyUI")
	if not lobbyUi then
		lobbyUi = playerGui:WaitForChild("LobbyUI", 10)
	end
	if not lobbyUi then
		return
	end

	for _, guiName in ipairs({ "RoomBrowserUI", "RoomBrowserDebugUI", "RoomBrowserFloatUI" }) do
		local existing = playerGui:FindFirstChild(guiName)
		if existing then
			existing:Destroy()
		end
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "RoomBrowserUI"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 200
	gui.IgnoreGuiInset = true
	gui.Enabled = self._roomBrowserVisible
	gui.Parent = playerGui

	local floatGui = Instance.new("ScreenGui")
	floatGui.Name = "RoomBrowserFloatUI"
	floatGui.ResetOnSpawn = false
	floatGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	floatGui.DisplayOrder = 201
	floatGui.IgnoreGuiInset = true
	floatGui.Enabled = true
	floatGui.Parent = playerGui

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(920, 560)
	panel.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	panel.BackgroundTransparency = 0.5
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local panelScale = Instance.new("UIScale")
	panelScale.Parent = panel

	local function updateRoomBrowserPanelScale()
		panelScale.Scale = 1
	end
	updateRoomBrowserPanelScale()
	if Workspace.CurrentCamera then
		table.insert(self._connections, Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateRoomBrowserPanelScale))
	end

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(0, 8)
	title.Size = UDim2.new(1, -48, 0, 30)
	title.Text = "RUANG INVESTIGASI"
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Font = Enum.Font.GothamBlack
	title.TextSize = 25
	title.TextColor3 = Color3.fromRGB(210, 68, 68)
	title.ZIndex = 3
	title.Parent = panel
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Thickness = 1.4
	titleStroke.Color = Color3.fromRGB(35, 8, 8)
	titleStroke.Parent = title

	local titleGlow = Instance.new("TextLabel")
	titleGlow.Name = "TitleGlow"
	titleGlow.BackgroundTransparency = 1
	titleGlow.Position = UDim2.fromOffset(1, 10)
	titleGlow.Size = title.Size
	titleGlow.Text = title.Text
	titleGlow.TextXAlignment = Enum.TextXAlignment.Center
	titleGlow.Font = title.Font
	titleGlow.TextSize = 25
	titleGlow.TextColor3 = Color3.fromRGB(92, 22, 22)
	titleGlow.TextTransparency = 0.35
	titleGlow.ZIndex = 2
	titleGlow.Parent = panel

	local dragBar = Instance.new("Frame")
	dragBar.Name = "DragBar"
	dragBar.BackgroundTransparency = 1
	dragBar.Position = UDim2.fromOffset(0, 0)
	dragBar.Size = UDim2.new(1, 0, 0, 42)
	dragBar.Active = true
	dragBar.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "CloseButton"
	closeBtn.Position = UDim2.fromOffset(852, 8)
	closeBtn.Size = UDim2.fromOffset(34, 28)
	styleButton(closeBtn, "X")
	closeBtn.Parent = panel

	local floatButton = Instance.new("TextButton")
	floatButton.Name = "RoomBrowserFloatButton"
	floatButton.AnchorPoint = Vector2.new(1, 0.5)
	floatButton.Position = UDim2.new(1, -20, 0.56, 0)
	floatButton.Size = UDim2.fromOffset(72, 72)
	floatButton.BackgroundColor3 = Color3.fromRGB(38, 47, 62)
	floatButton.TextColor3 = Color3.fromRGB(245, 245, 245)
	floatButton.Font = Enum.Font.GothamBold
	floatButton.TextSize = 12
	floatButton.TextScaled = true
	floatButton.TextWrapped = true
	floatButton.Text = "RUANG\nINVESTIGASI"
	floatButton.ZIndex = 20
	floatButton.Parent = floatGui

	local floatCorner = Instance.new("UICorner")
	floatCorner.CornerRadius = UDim.new(1, 0)
	floatCorner.Parent = floatButton

	local floatStroke = Instance.new("UIStroke")
	floatStroke.Thickness = 2
	floatStroke.Color = Color3.fromRGB(95, 118, 150)
	floatStroke.Parent = floatButton
	styleFloatingButton(floatButton, "RUANG INVESTIGASI", Color3.fromRGB(95, 118, 150))
	makeFloatingButtonDraggable(floatButton)

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.BackgroundTransparency = 1
	statusLabel.Position = UDim2.fromOffset(16, 44)
	statusLabel.Size = UDim2.fromOffset(840, 22)
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 12
	statusLabel.TextColor3 = Color3.fromRGB(160, 175, 200)
	statusLabel.Text = "Memuat..."
	statusLabel.Parent = panel

	local classicBtn = Instance.new("TextButton")
	classicBtn.Name = "ClassicButton"
	classicBtn.Position = UDim2.fromOffset(16, 72)
	classicBtn.Size = UDim2.fromOffset(132, 30)
	styleButton(classicBtn, "Classic")
	classicBtn.Parent = panel

	local allModesBtn = Instance.new("TextButton")
	allModesBtn.Name = "AllModesButton"
	allModesBtn.Position = UDim2.fromOffset(154, 72)
	allModesBtn.Size = UDim2.fromOffset(132, 30)
	styleButton(allModesBtn, "SEMUA MODE")
	allModesBtn.Parent = panel

	local rankedBtn = Instance.new("TextButton")
	rankedBtn.Name = "RankedButton"
	rankedBtn.Position = UDim2.fromOffset(292, 72)
	rankedBtn.Size = UDim2.fromOffset(132, 30)
	styleButton(rankedBtn, "Ranked")
	rankedBtn.Parent = panel

	local roomList = Instance.new("ScrollingFrame")
	roomList.Name = "RoomList"
	roomList.Position = UDim2.fromOffset(16, 110)
	roomList.Size = UDim2.fromOffset(392, 250)
	roomList.BackgroundColor3 = Color3.fromRGB(26, 32, 42)
	roomList.BorderSizePixel = 0
	roomList.ScrollBarThickness = 4
	roomList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	roomList.CanvasSize = UDim2.fromOffset(0, 0)
	roomList.Parent = panel

	local roomListCorner = Instance.new("UICorner")
	roomListCorner.CornerRadius = UDim.new(0, 8)
	roomListCorner.Parent = roomList

	local roomListLayout = Instance.new("UIListLayout")
	roomListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	roomListLayout.Padding = UDim.new(0, 4)
	roomListLayout.Parent = roomList

	local roomListPadding = Instance.new("UIPadding")
	roomListPadding.PaddingTop = UDim.new(0, 6)
	roomListPadding.PaddingBottom = UDim.new(0, 6)
	roomListPadding.PaddingLeft = UDim.new(0, 6)
	roomListPadding.PaddingRight = UDim.new(0, 6)
	roomListPadding.Parent = roomList

	local roomPreviewPanel = Instance.new("Frame")
	roomPreviewPanel.Name = "RoomPreviewPanel"
	roomPreviewPanel.Position = UDim2.fromOffset(424, 110)
	roomPreviewPanel.Size = UDim2.fromOffset(480, 384)
	roomPreviewPanel.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
	roomPreviewPanel.BorderSizePixel = 0
	roomPreviewPanel.Parent = panel
	local roomPreviewCorner = Instance.new("UICorner")
	roomPreviewCorner.CornerRadius = UDim.new(0, 10)
	roomPreviewCorner.Parent = roomPreviewPanel
	local roomPreviewStroke = Instance.new("UIStroke")
	roomPreviewStroke.Thickness = 1
	roomPreviewStroke.Color = Color3.fromRGB(76, 95, 122)
	roomPreviewStroke.Parent = roomPreviewPanel

	local roomPreviewTitle = Instance.new("TextLabel")
	roomPreviewTitle.Name = "Title"
	roomPreviewTitle.BackgroundTransparency = 1
	roomPreviewTitle.Position = UDim2.fromOffset(12, 10)
	roomPreviewTitle.Size = UDim2.fromOffset(456, 24)
	roomPreviewTitle.TextXAlignment = Enum.TextXAlignment.Left
	roomPreviewTitle.Font = Enum.Font.GothamBold
	roomPreviewTitle.TextSize = 15
	roomPreviewTitle.TextColor3 = Color3.fromRGB(240, 245, 250)
	roomPreviewTitle.Text = "PREVIEW ROOM"
	roomPreviewTitle.Parent = roomPreviewPanel

	local roomPreviewInfo = Instance.new("TextLabel")
	roomPreviewInfo.Name = "Info"
	roomPreviewInfo.BackgroundTransparency = 1
	roomPreviewInfo.Position = UDim2.fromOffset(12, 34)
	roomPreviewInfo.Size = UDim2.fromOffset(456, 18)
	roomPreviewInfo.TextXAlignment = Enum.TextXAlignment.Left
	roomPreviewInfo.Font = Enum.Font.Gotham
	roomPreviewInfo.TextSize = 11
	roomPreviewInfo.TextColor3 = Color3.fromRGB(178, 194, 214)
	roomPreviewInfo.Text = "Klik room di daftar untuk lihat detail."
	roomPreviewInfo.Parent = roomPreviewPanel

	local roomPreviewMap = Instance.new("Frame")
	roomPreviewMap.Name = "MapPlaceholder"
	roomPreviewMap.Position = UDim2.fromOffset(12, 58)
	roomPreviewMap.Size = UDim2.fromOffset(456, 112)
	roomPreviewMap.BackgroundColor3 = Color3.fromRGB(18, 24, 32)
	roomPreviewMap.BorderSizePixel = 0
	roomPreviewMap.Parent = roomPreviewPanel
	local roomPreviewMapCorner = Instance.new("UICorner")
	roomPreviewMapCorner.CornerRadius = UDim.new(0, 8)
	roomPreviewMapCorner.Parent = roomPreviewMap
	local roomPreviewMapStroke = Instance.new("UIStroke")
	roomPreviewMapStroke.Thickness = 1
	roomPreviewMapStroke.Color = Color3.fromRGB(72, 90, 116)
	roomPreviewMapStroke.Parent = roomPreviewMap
	local roomPreviewMapGradient = Instance.new("UIGradient")
	roomPreviewMapGradient.Name = "PreviewGradient"
	roomPreviewMapGradient.Rotation = 18
	roomPreviewMapGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(36, 44, 58)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 18, 24)),
	})
	roomPreviewMapGradient.Parent = roomPreviewMap

	local roomPreviewMapAccent = Instance.new("Frame")
	roomPreviewMapAccent.Name = "Accent"
	roomPreviewMapAccent.Position = UDim2.fromOffset(0, 0)
	roomPreviewMapAccent.Size = UDim2.fromOffset(6, 112)
	roomPreviewMapAccent.BackgroundColor3 = Color3.fromRGB(86, 116, 152)
	roomPreviewMapAccent.BorderSizePixel = 0
	roomPreviewMapAccent.Parent = roomPreviewMap

	local roomPreviewMapMood = Instance.new("TextLabel")
	roomPreviewMapMood.Name = "Mood"
	roomPreviewMapMood.BackgroundColor3 = Color3.fromRGB(38, 52, 74)
	roomPreviewMapMood.BackgroundTransparency = 0.18
	roomPreviewMapMood.Position = UDim2.new(1, -164, 0, 8)
	roomPreviewMapMood.Size = UDim2.fromOffset(148, 18)
	roomPreviewMapMood.Font = Enum.Font.GothamBold
	roomPreviewMapMood.TextSize = 10
	roomPreviewMapMood.TextColor3 = Color3.fromRGB(236, 242, 250)
	roomPreviewMapMood.Text = "ATMOSPHERE"
	roomPreviewMapMood.BorderSizePixel = 0
	roomPreviewMapMood.Parent = roomPreviewMap
	local roomPreviewMapMoodCorner = Instance.new("UICorner")
	roomPreviewMapMoodCorner.CornerRadius = UDim.new(1, 0)
	roomPreviewMapMoodCorner.Parent = roomPreviewMapMood

	local roomPreviewMapTitle = Instance.new("TextLabel")
	roomPreviewMapTitle.Name = "MapTitle"
	roomPreviewMapTitle.BackgroundTransparency = 1
	roomPreviewMapTitle.Position = UDim2.fromOffset(16, 8)
	roomPreviewMapTitle.Size = UDim2.fromOffset(268, 16)
	roomPreviewMapTitle.TextXAlignment = Enum.TextXAlignment.Left
	roomPreviewMapTitle.Font = Enum.Font.GothamSemibold
	roomPreviewMapTitle.TextSize = 11
	roomPreviewMapTitle.TextColor3 = Color3.fromRGB(196, 210, 228)
	roomPreviewMapTitle.Text = "MAP ROOM"
	roomPreviewMapTitle.Parent = roomPreviewMap

	local roomPreviewMapLabel = Instance.new("TextLabel")
	roomPreviewMapLabel.Name = "MapLabel"
	roomPreviewMapLabel.BackgroundTransparency = 1
	roomPreviewMapLabel.Position = UDim2.fromOffset(16, 30)
	roomPreviewMapLabel.Size = UDim2.fromOffset(424, 46)
	roomPreviewMapLabel.TextXAlignment = Enum.TextXAlignment.Left
	roomPreviewMapLabel.TextYAlignment = Enum.TextYAlignment.Top
	roomPreviewMapLabel.Font = Enum.Font.GothamBold
	roomPreviewMapLabel.TextSize = 13
	roomPreviewMapLabel.TextWrapped = true
	roomPreviewMapLabel.TextColor3 = Color3.fromRGB(236, 242, 250)
	roomPreviewMapLabel.Text = "Pilih room untuk lihat detail map."
	roomPreviewMapLabel.Parent = roomPreviewMap

	local roomPreviewMapStats = Instance.new("TextLabel")
	roomPreviewMapStats.Name = "Stats"
	roomPreviewMapStats.BackgroundTransparency = 1
	roomPreviewMapStats.Position = UDim2.fromOffset(16, 84)
	roomPreviewMapStats.Size = UDim2.fromOffset(424, 18)
	roomPreviewMapStats.TextXAlignment = Enum.TextXAlignment.Left
	roomPreviewMapStats.Font = Enum.Font.Gotham
	roomPreviewMapStats.TextSize = 10
	roomPreviewMapStats.TextColor3 = Color3.fromRGB(196, 210, 228)
	roomPreviewMapStats.Text = "DETAIL MAP AKAN MUNCUL SAAT ROOM DIPILIH"
	roomPreviewMapStats.Parent = roomPreviewMap

	local roomPreviewPlayersTitle = Instance.new("TextLabel")
	roomPreviewPlayersTitle.Name = "PlayersTitle"
	roomPreviewPlayersTitle.BackgroundTransparency = 1
	roomPreviewPlayersTitle.Position = UDim2.fromOffset(12, 176)
	roomPreviewPlayersTitle.Size = UDim2.fromOffset(456, 16)
	roomPreviewPlayersTitle.TextXAlignment = Enum.TextXAlignment.Left
	roomPreviewPlayersTitle.Font = Enum.Font.GothamSemibold
	roomPreviewPlayersTitle.TextSize = 11
	roomPreviewPlayersTitle.TextColor3 = Color3.fromRGB(198, 214, 232)
	roomPreviewPlayersTitle.Text = "PLAYER DALAM ROOM"
	roomPreviewPlayersTitle.Parent = roomPreviewPanel

	local roomPreviewPlayersList = Instance.new("ScrollingFrame")
	roomPreviewPlayersList.Name = "PlayersList"
	roomPreviewPlayersList.Position = UDim2.fromOffset(12, 196)
	roomPreviewPlayersList.Size = UDim2.fromOffset(456, 176)
	roomPreviewPlayersList.BackgroundColor3 = Color3.fromRGB(19, 25, 34)
	roomPreviewPlayersList.BorderSizePixel = 0
	roomPreviewPlayersList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	roomPreviewPlayersList.CanvasSize = UDim2.fromOffset(0, 0)
	roomPreviewPlayersList.ScrollBarThickness = 4
	roomPreviewPlayersList.Parent = roomPreviewPanel
	local roomPreviewPlayersCorner = Instance.new("UICorner")
	roomPreviewPlayersCorner.CornerRadius = UDim.new(0, 8)
	roomPreviewPlayersCorner.Parent = roomPreviewPlayersList
	local roomPreviewPlayersPadding = Instance.new("UIPadding")
	roomPreviewPlayersPadding.PaddingTop = UDim.new(0, 6)
	roomPreviewPlayersPadding.PaddingBottom = UDim.new(0, 6)
	roomPreviewPlayersPadding.PaddingLeft = UDim.new(0, 6)
	roomPreviewPlayersPadding.PaddingRight = UDim.new(0, 6)
	roomPreviewPlayersPadding.Parent = roomPreviewPlayersList
	local roomPreviewPlayersLayout = Instance.new("UIGridLayout")
	roomPreviewPlayersLayout.CellSize = UDim2.fromOffset(220, 78)
	roomPreviewPlayersLayout.CellPadding = UDim2.fromOffset(8, 8)
	roomPreviewPlayersLayout.FillDirectionMaxCells = 2
	roomPreviewPlayersLayout.SortOrder = Enum.SortOrder.LayoutOrder
	roomPreviewPlayersLayout.Parent = roomPreviewPlayersList

	local joinPwdBox = Instance.new("TextBox")
	joinPwdBox.Name = "JoinPassword"
	joinPwdBox.Position = UDim2.fromOffset(16, 408)
	joinPwdBox.Size = UDim2.fromOffset(198, 30)
	joinPwdBox.PlaceholderText = "Password Join (4 digit)"
	joinPwdBox.Text = ""
	joinPwdBox.ClearTextOnFocus = false
	joinPwdBox.TextColor3 = Color3.fromRGB(235, 240, 245)
	joinPwdBox.Font = Enum.Font.Gotham
	joinPwdBox.TextSize = 12
	joinPwdBox.BackgroundColor3 = Color3.fromRGB(30, 36, 47)
	joinPwdBox.BorderSizePixel = 0
	joinPwdBox.Visible = false
	joinPwdBox.Parent = panel

	local joinPwdCorner = Instance.new("UICorner")
	joinPwdCorner.CornerRadius = UDim.new(0, 6)
	joinPwdCorner.Parent = joinPwdBox

	local passwordModal = Instance.new("Frame")
	passwordModal.Name = "PasswordModal"
	passwordModal.Size = UDim2.fromScale(1, 1)
	passwordModal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	passwordModal.BackgroundTransparency = 0.35
	passwordModal.ZIndex = 25
	passwordModal.Visible = false
	passwordModal.Parent = gui

	local passwordCard = Instance.new("Frame")
	passwordCard.Name = "PasswordCard"
	passwordCard.AnchorPoint = Vector2.new(0.5, 0.5)
	passwordCard.Position = UDim2.fromScale(0.5, 0.5)
	passwordCard.Size = UDim2.fromOffset(320, 180)
	passwordCard.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	passwordCard.BorderSizePixel = 0
	passwordCard.ZIndex = 26
	passwordCard.Parent = passwordModal
	local passwordCardCorner = Instance.new("UICorner")
	passwordCardCorner.CornerRadius = UDim.new(0, 10)
	passwordCardCorner.Parent = passwordCard

	local passwordTitle = Instance.new("TextLabel")
	passwordTitle.BackgroundTransparency = 1
	passwordTitle.Position = UDim2.fromOffset(12, 10)
	passwordTitle.Size = UDim2.fromOffset(296, 24)
	passwordTitle.Text = "Masukkan Password Room"
	passwordTitle.TextXAlignment = Enum.TextXAlignment.Left
	passwordTitle.Font = Enum.Font.GothamBold
	passwordTitle.TextSize = 16
	passwordTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
	passwordTitle.ZIndex = 27
	passwordTitle.Parent = passwordCard

	local passwordInput = Instance.new("TextBox")
	passwordInput.Name = "PasswordInput"
	passwordInput.Position = UDim2.fromOffset(12, 52)
	passwordInput.Size = UDim2.fromOffset(296, 36)
	passwordInput.PlaceholderText = "4 digit password"
	passwordInput.Text = ""
	passwordInput.ClearTextOnFocus = false
	passwordInput.Font = Enum.Font.Gotham
	passwordInput.TextSize = 14
	passwordInput.TextColor3 = Color3.fromRGB(235, 240, 245)
	passwordInput.BackgroundColor3 = Color3.fromRGB(30, 36, 47)
	passwordInput.BorderSizePixel = 0
	passwordInput.ZIndex = 27
	passwordInput.Parent = passwordCard
	local passwordInputCorner = Instance.new("UICorner")
	passwordInputCorner.CornerRadius = UDim.new(0, 8)
	passwordInputCorner.Parent = passwordInput

	local passwordJoinBtn = Instance.new("TextButton")
	passwordJoinBtn.Name = "JoinButton"
	passwordJoinBtn.Position = UDim2.fromOffset(12, 102)
	passwordJoinBtn.Size = UDim2.fromOffset(144, 34)
	styleButton(passwordJoinBtn, "JOIN ROOM")
	passwordJoinBtn.BackgroundColor3 = Color3.fromRGB(46, 112, 168)
	passwordJoinBtn.ZIndex = 27
	passwordJoinBtn.Parent = passwordCard

	local passwordCancelBtn = Instance.new("TextButton")
	passwordCancelBtn.Name = "CancelButton"
	passwordCancelBtn.Position = UDim2.fromOffset(164, 102)
	passwordCancelBtn.Size = UDim2.fromOffset(144, 34)
	styleButton(passwordCancelBtn, "BATAL")
	passwordCancelBtn.BackgroundColor3 = Color3.fromRGB(90, 40, 40)
	passwordCancelBtn.ZIndex = 27
	passwordCancelBtn.Parent = passwordCard

	local kickNoticeModal = Instance.new("Frame")
	kickNoticeModal.Name = "KickNoticeModal"
	kickNoticeModal.Size = UDim2.fromScale(1, 1)
	kickNoticeModal.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	kickNoticeModal.BackgroundTransparency = 0.35
	kickNoticeModal.ZIndex = 28
	kickNoticeModal.Visible = false
	kickNoticeModal.Parent = gui

	local kickNoticeCard = Instance.new("Frame")
	kickNoticeCard.AnchorPoint = Vector2.new(0.5, 0.5)
	kickNoticeCard.Position = UDim2.fromScale(0.5, 0.5)
	kickNoticeCard.Size = UDim2.fromOffset(320, 140)
	kickNoticeCard.BackgroundColor3 = Color3.fromRGB(24, 20, 20)
	kickNoticeCard.BorderSizePixel = 0
	kickNoticeCard.ZIndex = 29
	kickNoticeCard.Parent = kickNoticeModal
	local kickNoticeCorner = Instance.new("UICorner")
	kickNoticeCorner.CornerRadius = UDim.new(0, 10)
	kickNoticeCorner.Parent = kickNoticeCard

	local kickNoticeText = Instance.new("TextLabel")
	kickNoticeText.BackgroundTransparency = 1
	kickNoticeText.Position = UDim2.fromOffset(12, 20)
	kickNoticeText.Size = UDim2.fromOffset(296, 50)
	kickNoticeText.Text = "ANDA TELAH DI KICK"
	kickNoticeText.TextColor3 = Color3.fromRGB(255, 180, 180)
	kickNoticeText.Font = Enum.Font.GothamBold
	kickNoticeText.TextSize = 20
	kickNoticeText.TextWrapped = true
	kickNoticeText.ZIndex = 30
	kickNoticeText.Parent = kickNoticeCard

	local kickNoticeOk = Instance.new("TextButton")
	kickNoticeOk.Position = UDim2.fromOffset(88, 86)
	kickNoticeOk.Size = UDim2.fromOffset(144, 34)
	styleButton(kickNoticeOk, "OK")
	kickNoticeOk.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
	kickNoticeOk.ZIndex = 30
	kickNoticeOk.Parent = kickNoticeCard

	local refreshBtn = Instance.new("TextButton")
	refreshBtn.Name = "RefreshButton"
	refreshBtn.Position = UDim2.fromOffset(149, 456)
	refreshBtn.Size = UDim2.fromOffset(126, 38)
	styleButton(refreshBtn, "Refresh")
	refreshBtn.Parent = panel

	local createRoomBtn = Instance.new("TextButton")
	createRoomBtn.Name = "CreateRoomButton"
	createRoomBtn.Position = UDim2.fromOffset(282, 456)
	createRoomBtn.Size = UDim2.fromOffset(126, 38)
	styleButton(createRoomBtn, "Buat Room")
	createRoomBtn.BackgroundColor3 = Color3.fromRGB(50, 90, 140)
	createRoomBtn.Parent = panel

	local queueBtn = Instance.new("TextButton")
	queueBtn.Name = "QueueButton"
	queueBtn.Position = UDim2.fromOffset(16, 506)
	queueBtn.Size = UDim2.fromOffset(126, 38)
	styleButton(queueBtn, "JOIN")
	queueBtn.BackgroundColor3 = Color3.fromRGB(46, 112, 168)
	queueBtn.Parent = panel

	local quickClassicBtn = Instance.new("TextButton")
	quickClassicBtn.Name = "QuickJoinClassicButton"
	quickClassicBtn.Position = UDim2.fromOffset(149, 506)
	quickClassicBtn.Size = UDim2.fromOffset(126, 38)
	styleButton(quickClassicBtn, "QUICK CLASSIC")
	quickClassicBtn.BackgroundColor3 = Color3.fromRGB(70, 120, 84)
	quickClassicBtn.Parent = panel

	local quickRankedBtn = Instance.new("TextButton")
	quickRankedBtn.Name = "QuickJoinRankedButton"
	quickRankedBtn.Position = UDim2.fromOffset(282, 506)
	quickRankedBtn.Size = UDim2.fromOffset(126, 38)
	styleButton(quickRankedBtn, "QUICK RANKED")
	quickRankedBtn.BackgroundColor3 = Color3.fromRGB(108, 78, 132)
	quickRankedBtn.Parent = panel

	local roomPanel = Instance.new("ScrollingFrame")
	roomPanel.Name = "RoomPanel"
	roomPanel.Position = UDim2.fromOffset(0, 0)
	roomPanel.Size = UDim2.fromScale(1, 1)
	roomPanel.BackgroundColor3 = Color3.fromRGB(26, 32, 42)
	roomPanel.BackgroundTransparency = 0
	roomPanel.BorderSizePixel = 0
	roomPanel.AutomaticCanvasSize = Enum.AutomaticSize.None
	roomPanel.CanvasSize = UDim2.fromOffset(0, 0)
	roomPanel.ScrollBarThickness = 6
	roomPanel.ScrollingDirection = Enum.ScrollingDirection.Y
	roomPanel.Active = true
	roomPanel.Visible = false
	roomPanel.Parent = panel

	local roomPanelCorner = Instance.new("UICorner")
	roomPanelCorner.CornerRadius = UDim.new(0, 12)
	roomPanelCorner.Parent = roomPanel

	local roomTitle = Instance.new("TextLabel")
	roomTitle.Name = "RoomTitle"
	roomTitle.BackgroundTransparency = 1
	roomTitle.Position = UDim2.fromOffset(14, 12)
	roomTitle.Size = UDim2.fromOffset(420, 22)
	roomTitle.TextXAlignment = Enum.TextXAlignment.Left
	roomTitle.Font = Enum.Font.GothamBold
	roomTitle.TextSize = 17
	roomTitle.TextColor3 = Color3.fromRGB(245, 245, 245)
	roomTitle.Text = "RUANG"
	roomTitle.Parent = roomPanel

	local roomHost = Instance.new("TextLabel")
	roomHost.Name = "HostLabel"
	roomHost.BackgroundTransparency = 1
	roomHost.Position = UDim2.fromOffset(14, 36)
	roomHost.Size = UDim2.fromOffset(420, 18)
	roomHost.TextXAlignment = Enum.TextXAlignment.Left
	roomHost.Font = Enum.Font.Gotham
	roomHost.TextSize = 12
	roomHost.TextColor3 = Color3.fromRGB(160, 175, 200)
	roomHost.Text = "Host: -"
	roomHost.Parent = roomPanel

	local playersLabel = Instance.new("TextLabel")
	playersLabel.Name = "PlayersLabel"
	playersLabel.BackgroundTransparency = 1
	playersLabel.Position = UDim2.fromOffset(454, 12)
	playersLabel.Size = UDim2.fromOffset(420, 16)
	playersLabel.TextXAlignment = Enum.TextXAlignment.Left
	playersLabel.Font = Enum.Font.GothamSemibold
	playersLabel.TextSize = 12
	playersLabel.TextColor3 = Color3.fromRGB(200, 215, 235)
	playersLabel.Text = "Anggota Ruangan"
	playersLabel.Parent = roomPanel

	local playersList = Instance.new("ScrollingFrame")
	playersList.Name = "PlayersList"
	playersList.BackgroundColor3 = Color3.fromRGB(21, 27, 36)
	playersList.BorderSizePixel = 0
	playersList.Position = UDim2.fromOffset(454, 34)
	playersList.Size = UDim2.fromOffset(420, 408)
	playersList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	playersList.CanvasSize = UDim2.fromOffset(0, 0)
	playersList.ScrollBarThickness = 4
	playersList.Parent = roomPanel
	local playersListCorner = Instance.new("UICorner")
	playersListCorner.CornerRadius = UDim.new(0, 8)
	playersListCorner.Parent = playersList
	local playersListPadding = Instance.new("UIPadding")
	playersListPadding.PaddingTop = UDim.new(0, 4)
	playersListPadding.PaddingBottom = UDim.new(0, 4)
	playersListPadding.PaddingLeft = UDim.new(0, 6)
	playersListPadding.PaddingRight = UDim.new(0, 6)
	playersListPadding.Parent = playersList
	local playersListLayout = Instance.new("UIGridLayout")
	playersListLayout.CellSize = UDim2.fromOffset(202, 132)
	playersListLayout.CellPadding = UDim2.fromOffset(8, 8)
	playersListLayout.FillDirectionMaxCells = 2
	playersListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	playersListLayout.Parent = playersList

	local modeSelector = Instance.new("TextButton")
	modeSelector.Name = "ModeSelector"
	modeSelector.Position = UDim2.fromOffset(14, 348)
	modeSelector.Size = UDim2.fromOffset(380, 30)
	styleButton(modeSelector, "MODE: CLASSIC")
	modeSelector.Parent = roomPanel

	local modeDropdown = Instance.new("Frame")
	modeDropdown.Name = "ModeDropdown"
	modeDropdown.Position = UDim2.fromOffset(14, 382)
	modeDropdown.Size = UDim2.fromOffset(380, 72)
	modeDropdown.BackgroundColor3 = Color3.fromRGB(26, 33, 43)
	modeDropdown.BorderSizePixel = 0
	modeDropdown.Visible = false
	modeDropdown.Active = true
	modeDropdown.ZIndex = 24
	modeDropdown.Parent = roomPanel
	local modeDropdownCorner = Instance.new("UICorner")
	modeDropdownCorner.CornerRadius = UDim.new(0, 8)
	modeDropdownCorner.Parent = modeDropdown
	local modeDropdownStroke = Instance.new("UIStroke")
	modeDropdownStroke.Thickness = 1
	modeDropdownStroke.Color = Color3.fromRGB(78, 100, 128)
	modeDropdownStroke.Parent = modeDropdown

	local modeClassicBtn = Instance.new("TextButton")
	modeClassicBtn.Name = "ClassicOption"
	modeClassicBtn.Position = UDim2.fromOffset(8, 8)
	modeClassicBtn.Size = UDim2.fromOffset(364, 26)
	styleButton(modeClassicBtn, "CLASSIC")
	modeClassicBtn.ZIndex = 25
	modeClassicBtn.Parent = modeDropdown
	local modeClassicCorner = Instance.new("UICorner")
	modeClassicCorner.CornerRadius = UDim.new(0, 6)
	modeClassicCorner.Parent = modeClassicBtn

	local modeRankedBtn = Instance.new("TextButton")
	modeRankedBtn.Name = "RankedOption"
	modeRankedBtn.Position = UDim2.fromOffset(8, 38)
	modeRankedBtn.Size = UDim2.fromOffset(364, 26)
	styleButton(modeRankedBtn, "RANKED")
	modeRankedBtn.ZIndex = 25
	modeRankedBtn.Parent = modeDropdown
	local modeRankedCorner = Instance.new("UICorner")
	modeRankedCorner.CornerRadius = UDim.new(0, 6)
	modeRankedCorner.Parent = modeRankedBtn

	local mapSelector = Instance.new("TextButton")
	mapSelector.Name = "MapSelector"
	mapSelector.Position = UDim2.fromOffset(14, 422)
	mapSelector.Size = UDim2.fromOffset(380, 30)
	styleButton(mapSelector, "MAP: " .. tostring(MAPS[1]))
	mapSelector.Parent = roomPanel

	local mapDropdown = Instance.new("Frame")
	mapDropdown.Name = "MapDropdown"
	mapDropdown.Position = UDim2.fromOffset(14, 446)
	mapDropdown.Size = UDim2.fromOffset(380, 112)
	mapDropdown.BackgroundColor3 = Color3.fromRGB(26, 33, 43)
	mapDropdown.BorderSizePixel = 0
	mapDropdown.Visible = false
	mapDropdown.Active = true
	mapDropdown.ZIndex = 24
	mapDropdown.Parent = roomPanel
	local mapDropdownCorner = Instance.new("UICorner")
	mapDropdownCorner.CornerRadius = UDim.new(0, 8)
	mapDropdownCorner.Parent = mapDropdown
	local mapDropdownStroke = Instance.new("UIStroke")
	mapDropdownStroke.Thickness = 1
	mapDropdownStroke.Color = Color3.fromRGB(78, 100, 128)
	mapDropdownStroke.Parent = mapDropdown

	local mapOptionButtons = {}
	for idx, mapName in ipairs(MAPS) do
		local option = Instance.new("TextButton")
		option.Name = "MapOption_" .. tostring(idx)
		option.Position = UDim2.fromOffset(8, 8 + (idx - 1) * 26)
		option.Size = UDim2.fromOffset(364, 22)
		styleButton(option, mapName)
		option.TextSize = 12
		option.ZIndex = 25
		option.Parent = mapDropdown
		local optionCorner = Instance.new("UICorner")
		optionCorner.CornerRadius = UDim.new(0, 6)
		optionCorner.Parent = option
		mapOptionButtons[idx] = option
	end

	local rankedTierLabel = Instance.new("TextLabel")
	rankedTierLabel.Name = "RankedTierLabel"
	rankedTierLabel.BackgroundColor3 = Color3.fromRGB(31, 35, 48)
	rankedTierLabel.BorderSizePixel = 0
	rankedTierLabel.Position = UDim2.fromOffset(14, 422)
	rankedTierLabel.Size = UDim2.fromOffset(380, 30)
	rankedTierLabel.TextXAlignment = Enum.TextXAlignment.Left
	rankedTierLabel.Font = Enum.Font.GothamSemibold
	rankedTierLabel.TextSize = 12
	rankedTierLabel.TextColor3 = Color3.fromRGB(215, 224, 236)
	rankedTierLabel.Text = "TIER HOST: UNRANKED"
	rankedTierLabel.Visible = false
	rankedTierLabel.Parent = roomPanel
	local rankedTierCorner = Instance.new("UICorner")
	rankedTierCorner.CornerRadius = UDim.new(0, 6)
	rankedTierCorner.Parent = rankedTierLabel

	local mapPreview = Instance.new("Frame")
	mapPreview.Name = "MapPreview"
	mapPreview.Position = UDim2.fromOffset(14, 72)
	mapPreview.Size = UDim2.fromOffset(380, 208)
	mapPreview.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
	mapPreview.BorderSizePixel = 0
	mapPreview.Parent = roomPanel
	local mapPreviewCorner = Instance.new("UICorner")
	mapPreviewCorner.CornerRadius = UDim.new(0, 8)
	mapPreviewCorner.Parent = mapPreview
	local mapPreviewStroke = Instance.new("UIStroke")
	mapPreviewStroke.Thickness = 1
	mapPreviewStroke.Color = Color3.fromRGB(75, 92, 120)
	mapPreviewStroke.Parent = mapPreview

	local mapPreviewTitle = Instance.new("TextLabel")
	mapPreviewTitle.Name = "Title"
	mapPreviewTitle.BackgroundTransparency = 1
	mapPreviewTitle.Position = UDim2.fromOffset(10, 8)
	mapPreviewTitle.Size = UDim2.new(1, -20, 0, 14)
	mapPreviewTitle.TextXAlignment = Enum.TextXAlignment.Left
	mapPreviewTitle.Font = Enum.Font.GothamSemibold
	mapPreviewTitle.TextSize = 10
	mapPreviewTitle.TextColor3 = Color3.fromRGB(190, 205, 225)
	mapPreviewTitle.Text = "PREVIEW"
	mapPreviewTitle.Parent = mapPreview

	local mapPreviewLabel = Instance.new("TextLabel")
	mapPreviewLabel.Name = "Label"
	mapPreviewLabel.BackgroundTransparency = 1
	mapPreviewLabel.Position = UDim2.fromOffset(10, 26)
	mapPreviewLabel.Size = UDim2.new(1, -20, 0, 16)
	mapPreviewLabel.TextXAlignment = Enum.TextXAlignment.Left
	mapPreviewLabel.TextYAlignment = Enum.TextYAlignment.Top
	mapPreviewLabel.Font = Enum.Font.GothamBold
	mapPreviewLabel.TextSize = 12
	mapPreviewLabel.TextWrapped = true
	mapPreviewLabel.TextColor3 = Color3.fromRGB(235, 240, 245)
	mapPreviewLabel.Text = formatMapSummary(MAPS[1])
	mapPreviewLabel.Parent = mapPreview

	local mapPreviewImage = Instance.new("Frame")
	mapPreviewImage.Name = "MapImagePlaceholder"
	mapPreviewImage.AnchorPoint = Vector2.new(0.5, 0)
	mapPreviewImage.Position = UDim2.new(0.5, 0, 0, 46)
	mapPreviewImage.Size = UDim2.fromOffset(200, 150)
	mapPreviewImage.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
	mapPreviewImage.BorderSizePixel = 0
	mapPreviewImage.Parent = mapPreview
	local mapPreviewImageCorner = Instance.new("UICorner")
	mapPreviewImageCorner.CornerRadius = UDim.new(0, 6)
	mapPreviewImageCorner.Parent = mapPreviewImage
	local mapPreviewImageStroke = Instance.new("UIStroke")
	mapPreviewImageStroke.Thickness = 1
	mapPreviewImageStroke.Color = Color3.fromRGB(83, 101, 128)
	mapPreviewImageStroke.Parent = mapPreviewImage
	local mapPreviewImageGradient = Instance.new("UIGradient")
	mapPreviewImageGradient.Name = "PreviewGradient"
	mapPreviewImageGradient.Rotation = 18
	mapPreviewImageGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 54, 72)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 18, 24)),
	})
	mapPreviewImageGradient.Parent = mapPreviewImage

	local mapPreviewImageAccent = Instance.new("Frame")
	mapPreviewImageAccent.Name = "AccentBar"
	mapPreviewImageAccent.Position = UDim2.fromOffset(0, 0)
	mapPreviewImageAccent.Size = UDim2.fromOffset(8, 150)
	mapPreviewImageAccent.BackgroundColor3 = Color3.fromRGB(96, 128, 164)
	mapPreviewImageAccent.BorderSizePixel = 0
	mapPreviewImageAccent.Parent = mapPreviewImage

	local mapPreviewImageChip = Instance.new("TextLabel")
	mapPreviewImageChip.Name = "MoodChip"
	mapPreviewImageChip.BackgroundColor3 = Color3.fromRGB(38, 52, 74)
	mapPreviewImageChip.BackgroundTransparency = 0.12
	mapPreviewImageChip.Position = UDim2.fromOffset(12, 10)
	mapPreviewImageChip.Size = UDim2.fromOffset(128, 18)
	mapPreviewImageChip.Font = Enum.Font.GothamBold
	mapPreviewImageChip.TextSize = 10
	mapPreviewImageChip.TextColor3 = Color3.fromRGB(236, 242, 250)
	mapPreviewImageChip.Text = "ATMOSPHERE"
	mapPreviewImageChip.BorderSizePixel = 0
	mapPreviewImageChip.Parent = mapPreviewImage
	local mapPreviewImageChipCorner = Instance.new("UICorner")
	mapPreviewImageChipCorner.CornerRadius = UDim.new(1, 0)
	mapPreviewImageChipCorner.Parent = mapPreviewImageChip

	local mapPreviewImageLabel = Instance.new("TextLabel")
	mapPreviewImageLabel.Name = "ImageLabel"
	mapPreviewImageLabel.BackgroundTransparency = 1
	mapPreviewImageLabel.Position = UDim2.fromOffset(12, 26)
	mapPreviewImageLabel.Size = UDim2.new(1, -24, 0, 76)
	mapPreviewImageLabel.Font = Enum.Font.GothamBold
	mapPreviewImageLabel.TextSize = 42
	mapPreviewImageLabel.TextColor3 = Color3.fromRGB(228, 236, 246)
	mapPreviewImageLabel.TextWrapped = false
	mapPreviewImageLabel.TextYAlignment = Enum.TextYAlignment.Center
	mapPreviewImageLabel.TextXAlignment = Enum.TextXAlignment.Left
	mapPreviewImageLabel.Text = "HH"
	mapPreviewImageLabel.Parent = mapPreviewImage

	local mapPreviewImageStats = Instance.new("TextLabel")
	mapPreviewImageStats.Name = "Stats"
	mapPreviewImageStats.BackgroundTransparency = 1
	mapPreviewImageStats.Position = UDim2.fromOffset(12, 106)
	mapPreviewImageStats.Size = UDim2.new(1, -24, 0, 16)
	mapPreviewImageStats.Font = Enum.Font.GothamSemibold
	mapPreviewImageStats.TextSize = 10
	mapPreviewImageStats.TextColor3 = Color3.fromRGB(210, 220, 236)
	mapPreviewImageStats.TextXAlignment = Enum.TextXAlignment.Left
	mapPreviewImageStats.Text = "DETAIL"
	mapPreviewImageStats.Parent = mapPreviewImage

	local mapPreviewImageFooter = Instance.new("TextLabel")
	mapPreviewImageFooter.Name = "Footer"
	mapPreviewImageFooter.BackgroundTransparency = 1
	mapPreviewImageFooter.Position = UDim2.fromOffset(12, 122)
	mapPreviewImageFooter.Size = UDim2.new(1, -24, 0, 20)
	mapPreviewImageFooter.Font = Enum.Font.GothamBold
	mapPreviewImageFooter.TextSize = 12
	mapPreviewImageFooter.TextColor3 = Color3.fromRGB(236, 242, 250)
	mapPreviewImageFooter.TextXAlignment = Enum.TextXAlignment.Left
	mapPreviewImageFooter.Text = getMapDisplayName(MAPS[1])
	mapPreviewImageFooter.Parent = mapPreviewImage

	local setPwdBox = Instance.new("TextBox")
	setPwdBox.Name = "SetPasswordBox"
	setPwdBox.Position = UDim2.fromOffset(14, 184)
	setPwdBox.Size = UDim2.fromOffset(256, 32)
	setPwdBox.PlaceholderText = "Set Password (4 digit)"
	setPwdBox.Text = ""
	setPwdBox.ClearTextOnFocus = false
	setPwdBox.TextColor3 = Color3.fromRGB(235, 240, 245)
	setPwdBox.Font = Enum.Font.Gotham
	setPwdBox.TextSize = 12
	setPwdBox.BackgroundColor3 = Color3.fromRGB(30, 36, 47)
	setPwdBox.BorderSizePixel = 0
	setPwdBox.Parent = roomPanel

	local setPwdCorner = Instance.new("UICorner")
	setPwdCorner.CornerRadius = UDim.new(0, 6)
	setPwdCorner.Parent = setPwdBox

	local setPwdBtn = Instance.new("TextButton")
	setPwdBtn.Name = "SetPasswordButton"
	setPwdBtn.Position = UDim2.fromOffset(278, 184)
	setPwdBtn.Size = UDim2.fromOffset(116, 32)
	styleButton(setPwdBtn, "Set PWD")
	setPwdBtn.TextSize = 12
	setPwdBtn.Parent = roomPanel

	local readyBtn = Instance.new("TextButton")
	readyBtn.Name = "ReadyButton"
	readyBtn.Position = UDim2.fromOffset(14, 264)
	readyBtn.Size = UDim2.fromOffset(380, 36)
	styleButton(readyBtn, "READY")
	readyBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 60)
	readyBtn.Parent = roomPanel

	local startBtn = Instance.new("TextButton")
	startBtn.Name = "StartButton"
	startBtn.Position = UDim2.fromOffset(14, 264)
	startBtn.Size = UDim2.fromOffset(380, 36)
	styleButton(startBtn, "MULAI PERMAINAN")
	startBtn.BackgroundColor3 = Color3.fromRGB(180, 80, 30)
	startBtn.Visible = false
	startBtn.Parent = roomPanel

	local cancelStartBtn = Instance.new("TextButton")
	cancelStartBtn.Name = "CancelStartButton"
	cancelStartBtn.Position = UDim2.fromOffset(14, 272)
	cancelStartBtn.Size = UDim2.fromOffset(380, 28)
	styleButton(cancelStartBtn, "BATALKAN COUNTDOWN")
	cancelStartBtn.TextSize = 12
	cancelStartBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
	cancelStartBtn.Visible = false
	cancelStartBtn.Parent = roomPanel

	local leaveRoomBtn = Instance.new("TextButton")
	leaveRoomBtn.Name = "LeaveRoomButton"
	leaveRoomBtn.Position = UDim2.fromOffset(14, 302)
	leaveRoomBtn.Size = UDim2.fromOffset(380, 30)
	styleButton(leaveRoomBtn, "Keluar Room")
	leaveRoomBtn.TextSize = 12
	leaveRoomBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
	leaveRoomBtn.Parent = roomPanel

	local inviteBtn = Instance.new("TextButton")
	inviteBtn.Name = "InviteButton"
	inviteBtn.Position = UDim2.fromOffset(454, 446)
	inviteBtn.Size = UDim2.fromOffset(420, 30)
	styleButton(inviteBtn, "INVITE PLAYER")
	inviteBtn.TextSize = 12
	inviteBtn.BackgroundColor3 = Color3.fromRGB(52, 92, 128)
	inviteBtn.Visible = false
	inviteBtn.Parent = roomPanel

	local inviteDropdown = Instance.new("Frame")
	inviteDropdown.Name = "InviteDropdown"
	inviteDropdown.Position = UDim2.fromOffset(454, 220)
	inviteDropdown.Size = UDim2.fromOffset(420, 220)
	inviteDropdown.BackgroundColor3 = Color3.fromRGB(26, 33, 43)
	inviteDropdown.BorderSizePixel = 0
	inviteDropdown.Visible = false
	inviteDropdown.Active = true
	inviteDropdown.ZIndex = 24
	inviteDropdown.Parent = roomPanel
	local inviteDropdownCorner = Instance.new("UICorner")
	inviteDropdownCorner.CornerRadius = UDim.new(0, 8)
	inviteDropdownCorner.Parent = inviteDropdown
	local inviteDropdownStroke = Instance.new("UIStroke")
	inviteDropdownStroke.Thickness = 1
	inviteDropdownStroke.Color = Color3.fromRGB(78, 100, 128)
	inviteDropdownStroke.Parent = inviteDropdown

	local inviteList = Instance.new("ScrollingFrame")
	inviteList.Name = "InviteList"
	inviteList.Size = UDim2.new(1, -8, 1, -8)
	inviteList.Position = UDim2.fromOffset(4, 4)
	inviteList.BackgroundTransparency = 1
	inviteList.BorderSizePixel = 0
	inviteList.ScrollBarThickness = 4
	inviteList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	inviteList.CanvasSize = UDim2.fromOffset(0, 0)
	inviteList.ZIndex = 25
	inviteList.Parent = inviteDropdown
	local inviteListLayout = Instance.new("UIListLayout")
	inviteListLayout.Padding = UDim.new(0, 4)
	inviteListLayout.Parent = inviteList

	local kickNameBox = Instance.new("TextBox")
	kickNameBox.Name = "KickNameBox"
	kickNameBox.Position = UDim2.fromOffset(14, 272)
	kickNameBox.Size = UDim2.fromOffset(256, 28)
	kickNameBox.PlaceholderText = "Nama pemain untuk di-kick"
	kickNameBox.Text = ""
	kickNameBox.ClearTextOnFocus = false
	kickNameBox.TextColor3 = Color3.fromRGB(235, 240, 245)
	kickNameBox.Font = Enum.Font.Gotham
	kickNameBox.TextSize = 12
	kickNameBox.BackgroundColor3 = Color3.fromRGB(30, 36, 47)
	kickNameBox.BorderSizePixel = 0
	kickNameBox.Visible = false
	kickNameBox.Parent = roomPanel
	local kickNameCorner = Instance.new("UICorner")
	kickNameCorner.CornerRadius = UDim.new(0, 6)
	kickNameCorner.Parent = kickNameBox

	local kickBtn = Instance.new("TextButton")
	kickBtn.Name = "KickButton"
	kickBtn.Position = UDim2.fromOffset(278, 272)
	kickBtn.Size = UDim2.fromOffset(116, 28)
	styleButton(kickBtn, "KICK")
	kickBtn.TextSize = 12
	kickBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
	kickBtn.Visible = false
	kickBtn.Parent = roomPanel

	local countdownOverlay = Instance.new("Frame")
	countdownOverlay.Name = "CountdownOverlay"
	countdownOverlay.Size = UDim2.fromScale(1, 1)
	countdownOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	countdownOverlay.BackgroundTransparency = 0.4
	countdownOverlay.ZIndex = 10
	countdownOverlay.Visible = false
	countdownOverlay.Parent = gui

	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "CountdownLabel"
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	countdownLabel.Position = UDim2.fromScale(0.5, 0.45)
	countdownLabel.Size = UDim2.fromOffset(400, 120)
	countdownLabel.Text = "5"
	countdownLabel.Font = Enum.Font.GothamBold
	countdownLabel.TextSize = 96
	countdownLabel.TextColor3 = Color3.fromRGB(255, 80, 60)
	countdownLabel.ZIndex = 11
	countdownLabel.Parent = countdownOverlay

	local cancelCountdownBtn = Instance.new("TextButton")
	cancelCountdownBtn.Name = "CancelCountdown"
	cancelCountdownBtn.AnchorPoint = Vector2.new(0.5, 0.5)
	cancelCountdownBtn.Position = UDim2.fromScale(0.5, 0.70)
	cancelCountdownBtn.Size = UDim2.fromOffset(220, 38)
	styleButton(cancelCountdownBtn, "BATALKAN")
	cancelCountdownBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
	cancelCountdownBtn.ZIndex = 11
	cancelCountdownBtn.Visible = false
	cancelCountdownBtn.Parent = countdownOverlay

	local invitePopup = Instance.new("Frame")
	invitePopup.Name = "InvitePopup"
	invitePopup.AnchorPoint = Vector2.new(0.5, 0)
	invitePopup.Position = UDim2.new(0.5, 0, 0, 18)
	invitePopup.Size = UDim2.fromOffset(408, 66)
	invitePopup.BackgroundColor3 = Color3.fromRGB(20, 30, 40)
	invitePopup.BorderSizePixel = 0
	invitePopup.ZIndex = 12
	invitePopup.Visible = false
	invitePopup.Parent = gui
	local invitePopupScale = Instance.new("UIScale")
	invitePopupScale.Parent = invitePopup
	local invitePopupCorner = Instance.new("UICorner")
	invitePopupCorner.CornerRadius = UDim.new(0, 8)
	invitePopupCorner.Parent = invitePopup
	local invitePopupStroke = Instance.new("UIStroke")
	invitePopupStroke.Thickness = 1
	invitePopupStroke.Color = Color3.fromRGB(86, 128, 170)
	invitePopupStroke.Parent = invitePopup

	local invitePopupText = Instance.new("TextLabel")
	invitePopupText.Name = "Text"
	invitePopupText.BackgroundTransparency = 1
	invitePopupText.Position = UDim2.fromOffset(10, 7)
	invitePopupText.Size = UDim2.fromOffset(286, 50)
	invitePopupText.TextXAlignment = Enum.TextXAlignment.Left
	invitePopupText.TextYAlignment = Enum.TextYAlignment.Center
	invitePopupText.Font = Enum.Font.GothamSemibold
	invitePopupText.TextSize = 11
	invitePopupText.TextWrapped = true
	invitePopupText.TextColor3 = Color3.fromRGB(235, 240, 245)
	invitePopupText.Text = "Invite"
	invitePopupText.ZIndex = 13
	invitePopupText.Parent = invitePopup

	local inviteAcceptBtn = Instance.new("TextButton")
	inviteAcceptBtn.Name = "AcceptButton"
	inviteAcceptBtn.Position = UDim2.fromOffset(302, 9)
	inviteAcceptBtn.Size = UDim2.fromOffset(96, 22)
	styleButton(inviteAcceptBtn, "TERIMA")
	inviteAcceptBtn.TextSize = 11
	inviteAcceptBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 70)
	inviteAcceptBtn.ZIndex = 13
	inviteAcceptBtn.Parent = invitePopup

	local inviteDeclineBtn = Instance.new("TextButton")
	inviteDeclineBtn.Name = "DeclineButton"
	inviteDeclineBtn.Position = UDim2.fromOffset(302, 35)
	inviteDeclineBtn.Size = UDim2.fromOffset(96, 22)
	styleButton(inviteDeclineBtn, "TOLAK")
	inviteDeclineBtn.TextSize = 11
	inviteDeclineBtn.BackgroundColor3 = Color3.fromRGB(120, 46, 46)
	inviteDeclineBtn.ZIndex = 13
	inviteDeclineBtn.Parent = invitePopup

	local function updateInvitePopupLayout()
		local topLeftInset, _ = resolveSafeInsets()
		local viewport = Vector2.new(1920, 1080)
		local camera = Workspace.CurrentCamera
		if camera and typeof(camera.ViewportSize) == "Vector2" then
			viewport = camera.ViewportSize
		end
		local scaleX = (viewport.X - 24) / 408
		local scaleY = (viewport.Y - (topLeftInset.Y + 24)) / 66
		invitePopupScale.Scale = math.clamp(math.min(scaleX, scaleY), 0.68, 1)
		invitePopup.Position = UDim2.new(0.5, 0, 0, 10 + topLeftInset.Y)
	end
	updateInvitePopupLayout()
	if Workspace.CurrentCamera then
		table.insert(self._connections, Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateInvitePopupLayout))
	end

	local mapIndex = 1
	local currentRoomId = nil
	local selectedRoomId = nil
	local selectedPreviewRenderKey = nil
	local pendingPasswordRoomId = nil
	local dragging = false
	local dragStart = nil
	local panelStart = nil
	local dragInput = nil

	local function roomRowText(room)
		if room.inGame then
			return string.format("  Room %d | %s | %d/%d | IN GAME", room.roomId, room.hostName or "?", room.playerCount or 0, room.maxPlayers or 4)
		end
		if room.starting then
			return string.format("  Room %d | %s | %d/%d | COUNTDOWN", room.roomId, room.hostName or "?", room.playerCount or 0, room.maxPlayers or 4)
		end
		if (room.playerCount or 0) == 0 then
			return string.format("  Room %d | Kosong", room.roomId)
		end
		local lock = room.hasPassword and "[PWD] " or ""
		return string.format(
			"  %sRoom %d | Host: %s | %d/%d | %s | %s",
			lock,
			room.roomId,
			room.hostName or "?",
			room.playerCount or 0,
			room.maxPlayers or 4,
			room.mode or "Classic",
			room.difficulty or "-"
		)
	end

	local function resolveLocalTierText()
		local localPlayer = Players.LocalPlayer
		if not localPlayer then
			return "UNRANKED"
		end
		for _, attrName in ipairs({ "RankTier", "Tier", "RankedTier", "HostTier" }) do
			local value = localPlayer:GetAttribute(attrName)
			if value ~= nil and tostring(value) ~= "" then
				return string.upper(tostring(value))
			end
		end
		return "UNRANKED"
	end

	local function syncMapIndex(mapId)
		if type(mapId) ~= "string" or mapId == "" then
			return MAPS[mapIndex]
		end
		for idx, mapName in ipairs(MAPS) do
			if mapName == mapId then
				mapIndex = idx
				break
			end
		end
		return mapId
	end

	local function resolveEffectiveMapId(state, room)
		if type(room) == "table" and type(room.mapId) == "string" and room.mapId ~= "" then
			return syncMapIndex(room.mapId)
		end
		if type(state) == "table" and type(state.selectedMap) == "string" and state.selectedMap ~= "" then
			return syncMapIndex(state.selectedMap)
		end
		return syncMapIndex(MAPS[mapIndex])
	end

	local function updateMapPreview(modeText, mapName)
		modeText = modeText or "Classic"
		mapName = mapName or resolveEffectiveMapId(self:GetRoomBrowserState(), nil) or MAPS[mapIndex]
		local theme = resolveMapPreviewTheme(mapName, modeText)
		mapPreview.BackgroundColor3 = theme.background
		mapPreviewStroke.Color = theme.stroke
		mapPreviewImage.BackgroundColor3 = theme.background
		mapPreviewImageStroke.Color = theme.stroke
		mapPreviewImageAccent.BackgroundColor3 = theme.accent
		mapPreviewImageChip.BackgroundColor3 = theme.accentSoft
		mapPreviewImageChip.TextColor3 = theme.text
		mapPreviewImageLabel.TextColor3 = theme.text
		mapPreviewImageStats.TextColor3 = theme.muted
		mapPreviewImageFooter.TextColor3 = theme.text
		mapPreviewImageGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.accentSoft),
			ColorSequenceKeypoint.new(1, theme.background),
		})

		mapPreviewTitle.Text = modeText == "Ranked" and "RANKED DEPLOYMENT" or "MAP PREVIEW"
		mapPreviewLabel.Text = modeText == "Ranked"
			and string.format("%s\nHost Tier %s", formatMapSummary(mapName), resolveLocalTierText())
			or formatMapSummary(mapName)
		mapPreviewImageLabel.Text = buildMapPreviewGlyph(mapName, modeText)
		mapPreviewImageChip.Text = buildMapPreviewMood(mapName, modeText)
		mapPreviewImageStats.Text = buildMapPreviewStats(mapName)
		mapPreviewImageFooter.Text = modeText == "Ranked"
			and string.format("%s  |  TIER %s", getMapDisplayName(mapName), resolveLocalTierText())
			or getMapDisplayName(mapName)
	end

	local function renderRoomSelectionPreview(rooms)
		if not roomPreviewPanel or not roomPreviewTitle or not roomPreviewInfo or not roomPreviewMapLabel or not roomPreviewPlayersList then
			return
		end
		local selectedRoom = nil
		if selectedRoomId ~= nil then
			for _, room in ipairs(rooms or {}) do
				if tostring(room.roomId) == tostring(selectedRoomId) then
					selectedRoom = room
					break
				end
			end
		end

		local nextRenderKey = "none"
		if selectedRoom then
			local modeText = tostring(selectedRoom.mode or "Classic")
			local mapId = tostring(selectedRoom.mapId or "UnknownMap")
			local roomState = selectedRoom.inGame and "ingame" or (selectedRoom.starting and "starting" or "idle")
			local players = type(selectedRoom.players) == "table" and selectedRoom.players or {}
			local playerParts = {}
			for _, info in ipairs(players) do
				table.insert(playerParts, string.format("%s:%s:%s", tostring(info.userId), info.isReady and "1" or "0", info.isHost and "1" or "0"))
			end
			nextRenderKey = string.format(
				"%s|%s|%s|%s|%s|%s",
				tostring(selectedRoom.roomId),
				tostring(selectedRoom.hostName or "-"),
				modeText,
				mapId,
				roomState,
				table.concat(playerParts, ",")
			)
		end
		if selectedPreviewRenderKey == nextRenderKey then
			return
		end
		selectedPreviewRenderKey = nextRenderKey

		for _, child in ipairs(roomPreviewPlayersList:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end

		if not selectedRoom then
			roomPreviewTitle.Text = "PREVIEW ROOM"
			roomPreviewInfo.Text = "Klik room di daftar untuk lihat detail."
			roomPreviewMapLabel.Text = "Belum ada room dipilih."
			roomPreviewMapTitle.Text = "MAP ROOM"
			roomPreviewMapStats.Text = "DETAIL MAP AKAN MUNCUL SAAT ROOM DIPILIH"
			roomPreviewMapMood.Text = "ATMOSPHERE"
			roomPreviewMap.BackgroundColor3 = Color3.fromRGB(18, 24, 32)
			roomPreviewMapStroke.Color = Color3.fromRGB(72, 90, 116)
			roomPreviewMapAccent.BackgroundColor3 = Color3.fromRGB(86, 116, 152)
			roomPreviewMapMood.BackgroundColor3 = Color3.fromRGB(38, 52, 74)
			roomPreviewMapGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(36, 44, 58)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(14, 18, 24)),
			})
			local empty = Instance.new("TextLabel")
			empty.BackgroundTransparency = 1
			empty.Size = UDim2.new(1, -12, 1, 0)
			empty.TextXAlignment = Enum.TextXAlignment.Center
			empty.TextYAlignment = Enum.TextYAlignment.Center
			empty.Font = Enum.Font.Gotham
			empty.TextSize = 12
			empty.TextColor3 = Color3.fromRGB(182, 198, 216)
			empty.Text = "Belum ada room dipilih."
			empty.Parent = roomPreviewPlayersList
			return
		end

		local modeText = tostring(selectedRoom.mode or "Classic")
		local mapId = tostring(selectedRoom.mapId or "UnknownMap")
		local playerCount = selectedRoom.playerCount
		if playerCount == nil and type(selectedRoom.players) == "table" then
			playerCount = #selectedRoom.players
		end
		playerCount = playerCount or 0
		local maxPlayers = selectedRoom.maxPlayers or 4
		local roomState = selectedRoom.inGame and "IN GAME" or (selectedRoom.starting and "COUNTDOWN" or "MENUNGGU")

		roomPreviewTitle.Text = string.format("PREVIEW ROOM #%s", tostring(selectedRoom.roomId or "?"))
		roomPreviewInfo.Text = string.format(
			"Host: %s | Mode: %s | Player: %d/%d | Status: %s",
			tostring(selectedRoom.hostName or "-"),
			modeText,
			playerCount,
			maxPlayers,
			roomState
		)
		local theme = resolveMapPreviewTheme(mapId, modeText)
		roomPreviewMapTitle.Text = modeText == "Ranked" and "RANKED ROOM" or "MAP ROOM"
		roomPreviewMapLabel.Text = formatMapSummary(mapId)
		roomPreviewMapStats.Text = buildMapPreviewStats(mapId)
		roomPreviewMapMood.Text = buildMapPreviewMood(mapId, modeText)
		roomPreviewMap.BackgroundColor3 = theme.background
		roomPreviewMapStroke.Color = theme.stroke
		roomPreviewMapAccent.BackgroundColor3 = theme.accent
		roomPreviewMapMood.BackgroundColor3 = theme.accentSoft
		roomPreviewMapMood.TextColor3 = theme.text
		roomPreviewMapTitle.TextColor3 = theme.muted
		roomPreviewMapLabel.TextColor3 = theme.text
		roomPreviewMapStats.TextColor3 = theme.muted
		roomPreviewMapGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, theme.accentSoft),
			ColorSequenceKeypoint.new(1, theme.background),
		})

		local players = type(selectedRoom.players) == "table" and selectedRoom.players or {}
		if #players == 0 then
			local empty = Instance.new("TextLabel")
			empty.BackgroundTransparency = 1
			empty.Size = UDim2.new(1, -12, 1, 0)
			empty.TextXAlignment = Enum.TextXAlignment.Center
			empty.TextYAlignment = Enum.TextYAlignment.Center
			empty.Font = Enum.Font.Gotham
			empty.TextSize = 12
			empty.TextColor3 = Color3.fromRGB(182, 198, 216)
			empty.Text = "Data pemain belum tersedia."
			empty.Parent = roomPreviewPlayersList
			return
		end

		local compactPreview = self._roomBrowserCompact == true
		for _, info in ipairs(players) do
			local card = Instance.new("Frame")
			card.BackgroundColor3 = Color3.fromRGB(30, 36, 47)
			card.BorderSizePixel = 0
			card.Size = UDim2.fromOffset(compactPreview and 320 or 220, compactPreview and 74 or 78)
			card.Parent = roomPreviewPlayersList
			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 8)
			cardCorner.Parent = card
			local cardStroke = Instance.new("UIStroke")
			cardStroke.Thickness = info.isReady and 2 or 1
			cardStroke.Color = info.isReady and Color3.fromRGB(82, 179, 108) or Color3.fromRGB(74, 88, 112)
			cardStroke.Parent = card

			local preview = Instance.new("ViewportFrame")
			preview.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
			preview.BorderSizePixel = 0
			preview.Position = UDim2.fromOffset(6, 6)
			preview.Size = UDim2.fromOffset(compactPreview and 52 or 54, compactPreview and 62 or 66)
			preview.Parent = card
			local previewCorner = Instance.new("UICorner")
			previewCorner.CornerRadius = UDim.new(0, 6)
			previewCorner.Parent = preview
			renderCharacterPreview(preview, info.userId)

			local nameLabel = Instance.new("TextLabel")
			nameLabel.BackgroundTransparency = 1
			nameLabel.Position = UDim2.fromOffset(66, 7)
			nameLabel.Size = UDim2.fromOffset(compactPreview and 226 or 146, 32)
			nameLabel.TextXAlignment = Enum.TextXAlignment.Left
			nameLabel.TextYAlignment = Enum.TextYAlignment.Top
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextSize = compactPreview and 11 or 10
			nameLabel.TextWrapped = true
			nameLabel.TextColor3 = Color3.fromRGB(236, 240, 245)
			local roleTag = info.isHost and "[HOST]" or "[MEMBER]"
			nameLabel.Text = string.format("%s %s", roleTag, tostring(info.displayName or info.name or "?"))
			nameLabel.Parent = card

			local stateLabel = Instance.new("TextLabel")
			stateLabel.BackgroundTransparency = 1
			stateLabel.Position = UDim2.fromOffset(66, 44)
			stateLabel.Size = UDim2.fromOffset(compactPreview and 226 or 146, 20)
			stateLabel.TextXAlignment = Enum.TextXAlignment.Left
			stateLabel.Font = Enum.Font.GothamSemibold
			stateLabel.TextSize = compactPreview and 11 or 10
			stateLabel.TextColor3 = info.isReady and Color3.fromRGB(120, 220, 145) or Color3.fromRGB(255, 195, 120)
			stateLabel.Text = info.isReady and "READY" or "NOT READY"
			stateLabel.Parent = card
		end
	end

	local function renderRoomList(rooms)
		local compactRoomBrowser = self._roomBrowserCompact == true
		local roomIdSet = {}
		for _, room in ipairs(rooms or {}) do
			roomIdSet[tostring(room.roomId)] = true
		end
		if selectedRoomId and not roomIdSet[tostring(selectedRoomId)] then
			selectedRoomId = nil
		end

		for _, child in ipairs(roomList:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		for _, room in ipairs(rooms or {}) do
			local row = Instance.new("TextButton")
			row.Name = "Room_" .. tostring(room.roomId)
			row.Size = UDim2.new(1, -8, 0, compactRoomBrowser and 56 or 36)
			row.LayoutOrder = room.roomId
			row.BorderSizePixel = 0
			row.Font = Enum.Font.Gotham
			row.TextSize = compactRoomBrowser and 14 or 13
			row.TextXAlignment = Enum.TextXAlignment.Left
			row.TextYAlignment = Enum.TextYAlignment.Center
			row.TextWrapped = compactRoomBrowser
			row.Text = roomRowText(room)
			row:SetAttribute("RoomId", room.roomId)
			row:SetAttribute("InGame", room.inGame == true)
			row:SetAttribute("Starting", room.starting == true)
			row:SetAttribute("HasPassword", room.hasPassword == true)
			if row:GetAttribute("InGame") then
				row.BackgroundColor3 = Color3.fromRGB(35, 20, 20)
				row.TextColor3 = Color3.fromRGB(180, 80, 80)
				row.AutoButtonColor = false
			elseif row:GetAttribute("Starting") then
				row.BackgroundColor3 = Color3.fromRGB(50, 40, 20)
				row.TextColor3 = Color3.fromRGB(255, 200, 120)
				row.AutoButtonColor = false
			else
				row.BackgroundColor3 = Color3.fromRGB(38, 47, 62)
				row.TextColor3 = Color3.fromRGB(235, 240, 245)
			end
			if tostring(room.roomId) == tostring(selectedRoomId) then
				row.BackgroundColor3 = Color3.fromRGB(63, 92, 138)
			end
			local rowCorner = Instance.new("UICorner")
			rowCorner.CornerRadius = UDim.new(0, 6)
			rowCorner.Parent = row

			connectButtonPress(row, function()
				selectedRoomId = row:GetAttribute("RoomId")
				if row:GetAttribute("InGame") then
					statusLabel.Text = string.format("Room #%s sedang berlangsung.", tostring(selectedRoomId))
				elseif row:GetAttribute("Starting") then
					statusLabel.Text = string.format("Room #%s sedang countdown.", tostring(selectedRoomId))
				else
					statusLabel.Text = string.format("Room #%s dipilih. Klik JOIN untuk masuk.", tostring(selectedRoomId))
				end
				renderRoomSelectionPreview(rooms)
			end)
			self:_setSelectableStyle(row)
			row.Parent = roomList
		end
		renderRoomSelectionPreview(rooms)
	end
	logRoomClickConnected("JoinRoomButton(RoomRowActivated)")

	local function rebuildInviteList()
		for _, child in ipairs(inviteList:GetChildren()) do
			if child:IsA("TextButton") then
				child:Destroy()
			end
		end
		local state = self:GetRoomBrowserState() or {}
		local currentRoom = state.currentRoom or {}
		local inRoomByUserId = {}
		for _, info in ipairs(currentRoom.players or {}) do
			if info.userId ~= nil then
				inRoomByUserId[tostring(info.userId)] = true
			end
		end

		local inviteAllRow = Instance.new("TextButton")
		inviteAllRow.Name = "InviteAll"
		inviteAllRow.Size = UDim2.new(1, -4, 0, 24)
		inviteAllRow.BackgroundColor3 = Color3.fromRGB(58, 98, 136)
		inviteAllRow.BorderSizePixel = 0
		inviteAllRow.Font = Enum.Font.GothamBold
		inviteAllRow.TextSize = 12
		inviteAllRow.TextColor3 = Color3.fromRGB(245, 245, 245)
		inviteAllRow.Text = "INVITE ALL (BROADCAST)"
		inviteAllRow.ZIndex = 26
		inviteAllRow.Parent = inviteList
		local inviteAllCorner = Instance.new("UICorner")
		inviteAllCorner.CornerRadius = UDim.new(0, 6)
		inviteAllCorner.Parent = inviteAllRow
		connectButtonPress(inviteAllRow, function()
			self:RoomBrowserInviteBroadcastToRoom()
			statusLabel.Text = "Broadcast invite dikirim."
		end)
		self:_setSelectableStyle(inviteAllRow)

		for _, lobbyPlayer in ipairs(state.lobbyPlayers or {}) do
			local userId = lobbyPlayer.userId
			if userId ~= nil and not inRoomByUserId[tostring(userId)] then
				local nameText = tostring(lobbyPlayer.displayName or lobbyPlayer.name or ("User " .. tostring(userId)))
				local row = Instance.new("TextButton")
				row.Name = "Invite_" .. tostring(userId)
				row.Size = UDim2.new(1, -4, 0, 24)
				row.BackgroundColor3 = Color3.fromRGB(40, 52, 68)
				row.BorderSizePixel = 0
				row.Font = Enum.Font.Gotham
				row.TextSize = 12
				row.TextColor3 = Color3.fromRGB(230, 235, 245)
				row.TextXAlignment = Enum.TextXAlignment.Left
				row.Text = "  " .. nameText
				row.ZIndex = 26
				row.Parent = inviteList
				local rowCorner = Instance.new("UICorner")
				rowCorner.CornerRadius = UDim.new(0, 6)
				rowCorner.Parent = row
				connectButtonPress(row, function()
					self:RoomBrowserInvitePlayerToRoom(userId)
					statusLabel.Text = string.format("Invite terkirim ke %s.", nameText)
				end)
				self:_setSelectableStyle(row)
			end
		end
	end

	connectButtonPress(classicBtn, function()
		self._roomBrowserModeView = "Selected"
		self:RoomBrowserSelectMode("Classic")
		task.delay(0.1, function()
			if self._roomBrowser then
				self._roomBrowser:RequestSnapshot()
			end
		end)
	end)

	connectButtonPress(allModesBtn, function()
		self._roomBrowserModeView = "All"
		if self._roomBrowser then
			self._roomBrowser:RequestSnapshot()
			self._roomBrowser:RequestRoomList()
		end
	end)

	connectButtonPress(rankedBtn, function()
		self._roomBrowserModeView = "Selected"
		self:RoomBrowserSelectMode("Ranked")
		task.delay(0.1, function()
			if self._roomBrowser then
				self._roomBrowser:RequestSnapshot()
			end
		end)
	end)

	connectButtonPress(refreshBtn, function()
		if self._roomBrowser then
			self._roomBrowser:RequestSnapshot()
			self._roomBrowser:RequestRoomList()
		end
	end)

	connectButtonPress(createRoomBtn, function()
		self:RoomBrowserCreateRoom()
		if self._roomBrowser then
			task.delay(0.1, function()
				self._roomBrowser:RequestSnapshot()
				self._roomBrowser:RequestRoomList()
			end)
		end
	end)
	logRoomClickConnected("CreateRoomButton")

	connectButtonPress(queueBtn, function()
		local state = self:GetRoomBrowserState() or {}
		local rooms = state.rooms or {}
		local selectedRoom = nil
		for _, room in ipairs(rooms) do
			if tostring(room.roomId) == tostring(selectedRoomId) then
				selectedRoom = room
				break
			end
		end
		if not selectedRoom then
			statusLabel.Text = "Pilih room dulu, lalu klik JOIN."
			return
		end
		if selectedRoom.inGame or selectedRoom.starting then
			statusLabel.Text = "Room sedang berjalan/countdown."
			if self._roomBrowserWidgets and self._roomBrowserWidgets.KickNoticeModal then
				self._kickNoticeVisible = true
				self._roomBrowserWidgets.KickNoticeText.Text = "PERMAINAN SEDANG BERLANGSUNG"
				self._roomBrowserWidgets.KickNoticeModal.Visible = true
			end
			return
		end
		if selectedRoom.hasPassword then
			pendingPasswordRoomId = selectedRoom.roomId
			self._passwordJoinPendingRoomId = selectedRoom.roomId
			self._passwordJoinSubmitting = false
			passwordInput.Text = ""
			passwordModal.Visible = true
			statusLabel.Text = "Room butuh password."
			return
		end
		pendingPasswordRoomId = nil
		self._passwordJoinPendingRoomId = nil
		self._passwordJoinSubmitting = false
		self:RoomBrowserJoinRoom(selectedRoom.roomId, nil)
	end)

	connectButtonPress(passwordJoinBtn, function()
		if not pendingPasswordRoomId then
			passwordModal.Visible = false
			return
		end
		local value = tostring(passwordInput.Text or ""):gsub("%s+", "")
		if value == "" then
			statusLabel.Text = "Password belum diisi."
			return
		end
		self._passwordJoinSubmitting = true
		passwordModal.Visible = false
		self:RoomBrowserJoinRoom(pendingPasswordRoomId, value)
		pendingPasswordRoomId = nil
	end)

	connectButtonPress(passwordCancelBtn, function()
		passwordModal.Visible = false
		pendingPasswordRoomId = nil
		self._passwordJoinPendingRoomId = nil
		self._passwordJoinSubmitting = false
	end)

	connectButtonPress(kickNoticeOk, function()
		if self._roomBrowserWidgets and self._roomBrowserWidgets.KickNoticeModal then
			self._roomBrowserWidgets.KickNoticeModal.Visible = false
		end
		self._kickNoticeVisible = false
	end)

	connectButtonPress(quickClassicBtn, function()
		local state = self:GetRoomBrowserState() or {}
		local rooms = state.rooms or {}
		local bestRoom = nil
		for _, room in ipairs(rooms) do
			local modeName = tostring(room.mode or "Classic")
			if modeName:lower() == "classic" and room.inGame ~= true and room.starting ~= true and (room.playerCount or 0) < (room.maxPlayers or 4) and room.hasPassword ~= true then
				if not bestRoom then
					bestRoom = room
				else
					local currentCount = room.playerCount or 0
					local bestCount = bestRoom.playerCount or 0
					if currentCount > bestCount or (currentCount == bestCount and tonumber(room.roomId) < tonumber(bestRoom.roomId)) then
						bestRoom = room
					end
				end
			end
		end
		if not bestRoom then
			statusLabel.Text = "Tidak ada room Classic publik yang bisa di-quick join."
			return
		end
		selectedRoomId = bestRoom.roomId
		self:RoomBrowserJoinRoom(bestRoom.roomId, nil)
	end)

	connectButtonPress(quickRankedBtn, function()
		local state = self:GetRoomBrowserState() or {}
		local rooms = state.rooms or {}
		local bestRoom = nil
		for _, room in ipairs(rooms) do
			local modeName = tostring(room.mode or "")
			if modeName:lower() == "ranked" and room.inGame ~= true and room.starting ~= true and (room.playerCount or 0) < (room.maxPlayers or 4) and room.hasPassword ~= true then
				if not bestRoom then
					bestRoom = room
				else
					local currentCount = room.playerCount or 0
					local bestCount = bestRoom.playerCount or 0
					if currentCount > bestCount or (currentCount == bestCount and tonumber(room.roomId) < tonumber(bestRoom.roomId)) then
						bestRoom = room
					end
				end
			end
		end
		if not bestRoom then
			statusLabel.Text = "Tidak ada room Ranked publik yang bisa di-quick join."
			return
		end
		selectedRoomId = bestRoom.roomId
		self:RoomBrowserJoinRoom(bestRoom.roomId, nil)
	end)

	connectButtonPress(modeSelector, function()
		self._inviteDropdownOpen = false
		inviteDropdown.Visible = false
		self._roomModeDropdownOpen = not self._roomModeDropdownOpen
		self._roomMapDropdownOpen = false
		modeDropdown.Visible = self._roomModeDropdownOpen
		mapDropdown.Visible = false
	end)

	connectButtonPress(modeClassicBtn, function()
		self._roomModeDropdownOpen = false
		modeDropdown.Visible = false
		self._roomMapDropdownOpen = false
		mapDropdown.Visible = false
		self:RoomBrowserSelectMode("Classic")
		task.delay(0.08, function()
			if self._roomBrowser then
				self._roomBrowser:RequestSnapshot()
			end
		end)
	end)

	connectButtonPress(modeRankedBtn, function()
		self._roomModeDropdownOpen = false
		modeDropdown.Visible = false
		self._roomMapDropdownOpen = false
		mapDropdown.Visible = false
		self:RoomBrowserSelectMode("Ranked")
		task.delay(0.08, function()
			if self._roomBrowser then
				self._roomBrowser:RequestSnapshot()
			end
		end)
	end)

	connectButtonPress(mapSelector, function()
		self._inviteDropdownOpen = false
		inviteDropdown.Visible = false
		self._roomMapDropdownOpen = not self._roomMapDropdownOpen
		self._roomModeDropdownOpen = false
		modeDropdown.Visible = false
		mapDropdown.Visible = self._roomMapDropdownOpen
	end)

	for idx, btn in ipairs(mapOptionButtons) do
		connectButtonPress(btn, function()
			local selectedMapId = syncMapIndex(MAPS[idx])
			mapSelector.Text = "MAP: " .. tostring(selectedMapId)
			self._roomMapDropdownOpen = false
			mapDropdown.Visible = false
			if self._roomBrowser then
				self._roomBrowser:SelectMap(selectedMapId)
			end
			updateMapPreview("Classic", selectedMapId)
		end)
	end

	connectButtonPress(setPwdBtn, function()
		self:RoomBrowserSetPassword(setPwdBox.Text)
	end)

	connectButtonPress(readyBtn, function()
		local state = self:GetRoomBrowserState() or {}
		local room = state.currentRoom
		if not (room and room.roomId) then
			return
		end
		local players = type(room.players) == "table" and room.players or {}
		if #players == 0 then
			for _, listedRoom in ipairs(state.rooms or {}) do
				if tostring(listedRoom.roomId) == tostring(room.roomId) and type(listedRoom.players) == "table" then
					players = listedRoom.players
					break
				end
			end
		end
		local playerCount = room.playerCount
		if playerCount == nil then
			playerCount = #players
		end
		playerCount = tonumber(playerCount) or 0
		if playerCount <= 0 then
			statusLabel.Text = "Sinkronisasi room belum lengkap. Tunggu snapshot lalu coba lagi."
			return
		end
		local allReadyComputed = state.allReady == true
		if state.isHost == true and state.allReady == nil and #players > 0 then
			allReadyComputed = true
			for _, info in ipairs(players) do
				if not info.isHost and info.isReady ~= true then
					allReadyComputed = false
					break
				end
			end
		end

		if state.isHost == true then
			if state.matchStarting == true then
				self:RoomBrowserCancelHostStart()
				return
			end
			if playerCount == 1 or allReadyComputed == true then
				local roomMode = room.mode or state.selectedMode
				self:RoomBrowserHostStart(resolveEffectiveMapId(state, room), nil, roomMode)
			end
			return
		end
		self:RoomBrowserSetReady(not (state.isReady == true))
	end)
	logRoomClickConnected("ReadyButton")

	connectButtonPress(startBtn, function()
		local state = self:GetRoomBrowserState() or {}
		if state.isHost == true then
			self:RoomBrowserHostStart(resolveEffectiveMapId(state, state.currentRoom), nil, state.selectedMode)
		end
	end)
	logRoomClickConnected("StartButton")

	connectButtonPress(cancelStartBtn, function()
		self:RoomBrowserCancelHostStart()
	end)

	connectButtonPress(cancelCountdownBtn, function()
		self:RoomBrowserCancelHostStart()
	end)

	connectButtonPress(leaveRoomBtn, function()
		self:RoomBrowserLeaveRoom()
	end)

	connectButtonPress(inviteBtn, function()
		self._roomModeDropdownOpen = false
		modeDropdown.Visible = false
		self._roomMapDropdownOpen = false
		mapDropdown.Visible = false
		self._inviteDropdownOpen = not self._inviteDropdownOpen
		inviteDropdown.Visible = self._inviteDropdownOpen
		if self._inviteDropdownOpen then
			rebuildInviteList()
		end
	end)

	connectButtonPress(inviteAcceptBtn, function()
		local inviteId = self._activeInviteId
		if inviteId then
			self:RoomBrowserRespondRoomInvite(inviteId, true)
		end
		self:_hideRoomInvitePopup()
	end)

	connectButtonPress(inviteDeclineBtn, function()
		local inviteId = self._activeInviteId
		if inviteId then
			self:RoomBrowserRespondRoomInvite(inviteId, false)
		end
		self:_hideRoomInvitePopup()
	end)

	connectButtonPress(kickBtn, function()
		local state = self:GetRoomBrowserState() or {}
		if state.isHost ~= true then
			statusLabel.Text = "Hanya host yang bisa kick player."
			return
		end
		local targetToken = tostring(kickNameBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if targetToken == "" then
			statusLabel.Text = "Isi nama pemain yang ingin di-kick."
			return
		end
		local targetLower = targetToken:lower()
		local targetUserId = nil
		for _, info in ipairs((state.currentRoom and state.currentRoom.players) or {}) do
			local n1 = tostring(info.name or ""):lower()
			local n2 = tostring(info.displayName or ""):lower()
			if n1 == targetLower or n2 == targetLower then
				targetUserId = info.userId
				break
			end
		end
		if not targetUserId then
			statusLabel.Text = "Nama pemain tidak ditemukan di room."
			return
		end
		if self._roomBrowser then
			self._roomBrowser:KickPlayer(targetUserId)
		end
	end)

	local selectableButtons = {
		classicBtn,
		allModesBtn,
		rankedBtn,
		refreshBtn,
		createRoomBtn,
		queueBtn,
		quickClassicBtn,
		quickRankedBtn,
		modeSelector,
		modeClassicBtn,
		modeRankedBtn,
		mapSelector,
		setPwdBtn,
		inviteBtn,
		inviteAcceptBtn,
		inviteDeclineBtn,
		readyBtn,
		startBtn,
		cancelStartBtn,
		cancelCountdownBtn,
		leaveRoomBtn,
		closeBtn,
		floatButton,
	}
	for _, button in ipairs(selectableButtons) do
		self:_setSelectableStyle(button)
	end
	for _, optionButton in ipairs(mapOptionButtons) do
		self:_setSelectableStyle(optionButton)
	end

	connectButtonPress(closeBtn, function()
		self:_setRoomBrowserVisible(false)
	end)
	connectButtonPress(floatButton, function()
		self:_toggleRoomBrowserVisible()
	end)

	local function updateDrag(input)
		local delta = input.Position - dragStart
		panel.Position = UDim2.new(
			panelStart.X.Scale,
			panelStart.X.Offset + delta.X,
			panelStart.Y.Scale,
			panelStart.Y.Offset + delta.Y
		)
	end

	dragBar.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		dragInput = input
		dragStart = input.Position
		panelStart = panel.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
				dragInput = nil
			end
		end)
	end)

	dragBar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			updateDrag(input)
		end
	end))

	self._roomBrowserGui = gui
	self._roomBrowserFloatGui = floatGui
	self._roomBrowserWidgets = {
		RootPanel = panel,
		HeaderTitle = title,
		HeaderTitleGlow = titleGlow,
		Status = statusLabel,
		ClassicButton = classicBtn,
		AllModesButton = allModesBtn,
		RankedButton = rankedBtn,
		RoomList = roomList,
		RoomPreviewPanel = roomPreviewPanel,
		RoomPreviewTitle = roomPreviewTitle,
		RoomPreviewInfo = roomPreviewInfo,
		RoomPreviewMap = roomPreviewMap,
		RoomPreviewMapLabel = roomPreviewMapLabel,
		RoomPreviewPlayersList = roomPreviewPlayersList,
		JoinPassword = joinPwdBox,
		RefreshButton = refreshBtn,
		CreateRoomButton = createRoomBtn,
		QueueButton = queueBtn,
		QuickJoinClassicButton = quickClassicBtn,
		QuickJoinRankedButton = quickRankedBtn,
		RoomPanel = roomPanel,
		RoomTitle = roomTitle,
		RoomHost = roomHost,
		PlayersList = playersList,
		KickNameBox = kickNameBox,
		KickButton = kickBtn,
		ReadyButton = readyBtn,
		StartButton = startBtn,
		CancelStartButton = cancelStartBtn,
		ModeSelector = modeSelector,
		ModeDropdown = modeDropdown,
		MapDropdown = mapDropdown,
		RankedTierLabel = rankedTierLabel,
		MapSelector = mapSelector,
		MapPreview = mapPreview,
		MapPreviewTitle = mapPreviewTitle,
		MapPreviewLabel = mapPreviewLabel,
		SetPasswordBox = setPwdBox,
		SetPasswordButton = setPwdBtn,
		InviteButton = inviteBtn,
		InviteDropdown = inviteDropdown,
		RebuildInviteList = rebuildInviteList,
		InvitePopup = invitePopup,
		InvitePopupText = invitePopupText,
		CountdownOverlay = countdownOverlay,
		CountdownLabel = countdownLabel,
		CancelCountdown = cancelCountdownBtn,
		PasswordModal = passwordModal,
		PasswordInput = passwordInput,
		KickNoticeModal = kickNoticeModal,
		KickNoticeText = kickNoticeText,
		FloatButton = floatButton,
		RenderRoomList = renderRoomList,
		UpdateMapPreview = updateMapPreview,
		SetCurrentRoom = function(roomId)
			currentRoomId = roomId
		end,
		GetCurrentRoom = function()
			return currentRoomId
		end,
	}
	updateMapPreview()
	self:_applyDeviceSizing()
	self:_updateRoomBrowserVisibility()
end

function UISystem:_setButtonSelected(button, selected)
	if not button then
		return
	end
	button.BackgroundColor3 = selected and Color3.fromRGB(88, 121, 173) or Color3.fromRGB(46, 57, 73)
	button:SetAttribute("BrandSelected", selected == true)
	refreshButtonPolish(button, false)
end

function UISystem:_updateRoomBrowserVisibility()
	local playerGui = self:_getPlayerGui()
	if playerGui then
		self._roomBrowserGui = playerGui:FindFirstChild("RoomBrowserUI") or self._roomBrowserGui
		self._roomBrowserFloatGui = playerGui:FindFirstChild("RoomBrowserFloatUI") or self._roomBrowserFloatGui
	end

	local suppressed = self._roomBrowserSuppressed == true
	local blockLobbyFloatRail = self:_isLobbyFloatRailBlocked()
	local roomBrowserEnabled = (not suppressed) and self._roomBrowserVisible
	if self._roomBrowserGui then
		self._roomBrowserGui.Enabled = roomBrowserEnabled
		local rootPanel = self._roomBrowserGui:FindFirstChild("Panel")
		if rootPanel and rootPanel:IsA("GuiObject") then
			rootPanel.Visible = roomBrowserEnabled
		end
		if roomBrowserEnabled ~= true then
			for _, childName in ipairs({ "RoomPanel", "ModeDropdown", "MapDropdown", "InviteDropdown", "PasswordModal", "KickNoticeModal" }) do
				local child = self._roomBrowserGui:FindFirstChild(childName, true)
				if child and child:IsA("GuiObject") then
					child.Visible = false
				end
			end
		end
		local countdownOverlay = self._roomBrowserGui:FindFirstChild("CountdownOverlay")
		if countdownOverlay and countdownOverlay:IsA("GuiObject") and roomBrowserEnabled ~= true then
			countdownOverlay.Visible = false
		end
	end
	if self._roomBrowserFloatGui then
		self._roomBrowserFloatGui.Enabled = (not suppressed) and (not self._roomBrowserVisible) and (not blockLobbyFloatRail)
	end
	self:_layoutLobbyFloatRail()
end

function UISystem:_setRoomBrowserVisible(visible)
	if self._roomBrowserSuppressed == true and visible == true then
		return
	end
	if visible == true then
		self:_closeConflictingWindows("RoomBrowser")
	end
	self._roomBrowserVisible = visible == true
	self:_updateRoomBrowserVisibility()
	if self._roomBrowserVisible and self._roomBrowserWidgets and self._roomBrowserWidgets.RootPanel then
		animatePanelReveal(self._roomBrowserWidgets.RootPanel, false)
	end
	self:_syncAuxiliaryWindowVisibility()
	self:_syncLobbyAuxiliaryWindowVisibility()
	self:_refreshBasicLobbyPanel()
	self:_refreshBasicWindows()
end

function UISystem:_toggleRoomBrowserVisible()
	if self._roomBrowserSuppressed == true then
		return
	end
	self:_setRoomBrowserVisible(not self._roomBrowserVisible)
end

function UISystem:_bindRoomBrowserToggleInput()
	if self._roomBrowserInputBound then
		return
	end
	self._roomBrowserInputBound = true
	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		local isKeyboardToggle = input.KeyCode == ROOM_BROWSER_TOGGLE_KEY
		local isGamepadToggle = input.KeyCode == Enum.KeyCode.ButtonY
		if not isKeyboardToggle and not isGamepadToggle then
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		self:_toggleRoomBrowserVisible()
	end))
end

function UISystem:_bindAuxiliaryToggleInput()
	if self._auxiliaryInputBound then
		return
	end
	self._auxiliaryInputBound = true
	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if UserInputService:GetFocusedTextBox() then
			return
		end
		for guiName, keyCode in pairs(AUXILIARY_WINDOW_TOGGLE_KEYS) do
			if input.KeyCode == keyCode then
				if gameProcessed and self._matchPhase == MATCH_PHASE.LOBBY then
					return
				end
				self:_toggleAuxiliaryWindow(guiName)
				break
			end
		end
	end))
end

function UISystem:_bindMatchPanelToggleInput()
	if self._matchPanelToggleBound then
		return
	end
	self._matchPanelToggleBound = true
	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, _gameProcessed)
		if UserInputService:GetFocusedTextBox() then
			return
		end
		if input.KeyCode ~= MATCH_PANEL_TOGGLE_KEY then
			return
		end
		if self._uiState.MatchUI then
			self._uiState.MatchUI.visible = true
		end
		self:_setMatchWindowDismissed(not (self._matchWindowDismissed == true))
		self:_applyVisibility()
	end))
end

function UISystem:_bindMatchToolInput()
	if self._matchToolInputBound then
		return
	end
	self._matchToolInputBound = true
	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or UserInputService:GetFocusedTextBox() then
			return
		end
		if self._matchPhase == MATCH_PHASE.LOBBY or self:_isMatchResultsPhase() then
			return
		end

		for _, toolType in ipairs(FIELD_KIT_TOOL_ORDER) do
			local toolConfig = FIELD_KIT_TOOL_CONFIG[toolType]
			if toolConfig and input.KeyCode == toolConfig.keyCode then
				self:_useInvestigationTool(toolType, {
					openJournal = toolConfig.openJournal == true,
				})
				break
			end
		end
	end))
end

function UISystem:_bindWindowCloseInput()
	if self._windowCloseInputBound then
		return
	end
	self._windowCloseInputBound = true
	table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, _gameProcessed)
		if input.KeyCode ~= CLOSE_KEYBOARD_KEY and input.KeyCode ~= CLOSE_GAMEPAD_KEY then
			return
		end
		if input.KeyCode == CLOSE_KEYBOARD_KEY and self:_isMatchPanelOpen() then
			self:_setMatchWindowDismissed(true)
			return
		end
		if UserInputService:GetFocusedTextBox() then
			return
		end
		self:_closeTopmostWindow()
	end))
end

function UISystem:_refreshRoomBrowserView()
	if not self._roomBrowserGui or not self._roomBrowserGui.Parent then
		self._roomBrowserGui = nil
		self._roomBrowserWidgets = nil
		self:_ensureRoomBrowserGui()
	end

	if not self._roomBrowserWidgets then
		if self._roomBrowserMissingWidgetsLogged ~= true then
			self._roomBrowserMissingWidgetsLogged = true
		end
		return
	end
	self._roomBrowserMissingWidgetsLogged = false

	local state = self:GetRoomBrowserState() or {}
	local selectedMode = state.selectedMode or "Classic"
	local rooms = state.rooms or {}
	local viewMode = self._roomBrowserModeView or "Selected"
	local roomsForDisplay = rooms
	if viewMode == "Selected" then
		roomsForDisplay = {}
		for _, room in ipairs(rooms) do
			local modeName = tostring(room.mode or "Classic")
			if modeName == selectedMode then
				table.insert(roomsForDisplay, room)
			end
		end
	end
	local queueInfo = state.queue

	if state.currentRoom and state.currentRoom.roomId then
		self._roomBrowserWidgets.SetCurrentRoom(state.currentRoom.roomId)
	elseif state.pendingRoomTransition ~= true then
		self._roomBrowserWidgets.SetCurrentRoom(nil)
	end

	local statusModeText = selectedMode
	if viewMode == "All" then
		statusModeText = "SEMUA MODE"
	end
	local statusText = string.format("Mode: %s | Room: %d", statusModeText, #roomsForDisplay)
	local currentRoom = self._roomBrowserWidgets.GetCurrentRoom and self._roomBrowserWidgets.GetCurrentRoom() or nil
	if currentRoom then
		statusText = statusText .. " | InRoom: " .. tostring(currentRoom)
	end
	if state.matchStarting == true then
		statusText = statusText .. " | COUNTDOWN: " .. tostring(state.countdownSecondsLeft or state.countdownTotal or "...")
	end
	if state.lastError then
		statusText = statusText .. " | ERR: " .. tostring(state.lastError)
	elseif queueInfo then
		statusText = statusText .. " | Queue: " .. tostring(queueInfo.queueType or queueInfo.mode or "started")
	end
	self._roomBrowserWidgets.Status.Text = statusText

	self:_setButtonSelected(self._roomBrowserWidgets.AllModesButton, viewMode == "All")
	self:_setButtonSelected(self._roomBrowserWidgets.ClassicButton, viewMode ~= "All" and selectedMode == "Classic")
	self:_setButtonSelected(self._roomBrowserWidgets.RankedButton, viewMode ~= "All" and selectedMode == "Ranked")

	self._roomBrowserWidgets.RenderRoomList(roomsForDisplay)

	local panel = self._roomBrowserWidgets.RoomPanel
	local roomData = nil
	if currentRoom then
		for _, room in ipairs(roomsForDisplay) do
			if room.roomId == currentRoom then
				roomData = room
				break
			end
		end
		if not roomData and state.currentRoom and state.currentRoom.roomId == currentRoom then
			roomData = state.currentRoom
		end
	end

	local showRoomPanel = roomData ~= nil
	panel.Visible = showRoomPanel
	if self._roomBrowserWidgets.RootPanel then
		self._roomBrowserWidgets.RootPanel.BackgroundTransparency = showRoomPanel and 1 or 0.5
	end
	if self._roomBrowserWidgets.HeaderTitle then
		self._roomBrowserWidgets.HeaderTitle.Visible = not showRoomPanel
	end
	if self._roomBrowserWidgets.HeaderTitleGlow then
		self._roomBrowserWidgets.HeaderTitleGlow.Visible = not showRoomPanel
	end
	self._roomBrowserWidgets.Status.Visible = not showRoomPanel
	local canChangeMode = (not showRoomPanel) or (state.isHost == true)
	self._roomBrowserWidgets.ClassicButton.Visible = canChangeMode
	self._roomBrowserWidgets.AllModesButton.Visible = canChangeMode
	self._roomBrowserWidgets.RankedButton.Visible = canChangeMode
	self._roomBrowserWidgets.RoomList.Visible = not showRoomPanel
	self._roomBrowserWidgets.RoomPreviewPanel.Visible = not showRoomPanel
	self._roomBrowserWidgets.JoinPassword.Visible = false
	self._roomBrowserWidgets.RefreshButton.Visible = not showRoomPanel
	self._roomBrowserWidgets.CreateRoomButton.Visible = not showRoomPanel
	self._roomBrowserWidgets.QueueButton.Visible = not showRoomPanel
	self._roomBrowserWidgets.QuickJoinClassicButton.Visible = not showRoomPanel
	self._roomBrowserWidgets.QuickJoinRankedButton.Visible = not showRoomPanel
	self._roomBrowserWidgets.ModeSelector.Visible = false
	self._roomBrowserWidgets.RankedTierLabel.Visible = false
	self._roomBrowserWidgets.ModeDropdown.Visible = false
	self._roomBrowserWidgets.MapDropdown.Visible = false
	if self._passwordJoinPendingRoomId == nil then
		self._roomBrowserWidgets.PasswordModal.Visible = false
	end

	if showRoomPanel then
		local localUserId = Players.LocalPlayer and Players.LocalPlayer.UserId or nil
		local localName = Players.LocalPlayer and Players.LocalPlayer.Name or nil
		local hostCanControl = state.isHost == true
			or (roomData.hostUserId ~= nil and roomData.hostUserId == localUserId)
			or (localName ~= nil and tostring(roomData.hostName or "") == tostring(localName))
		if hostCanControl ~= true then
			self._roomModeDropdownOpen = false
			self._roomMapDropdownOpen = false
		end
		local roomPlayersData = type(roomData.players) == "table" and roomData.players or nil
		if (not roomPlayersData or #roomPlayersData == 0) and type(state.currentRoom) == "table" and type(state.currentRoom.players) == "table" then
			roomPlayersData = state.currentRoom.players
		end
		if (not roomPlayersData or #roomPlayersData == 0) then
			for _, listedRoom in ipairs(state.rooms or {}) do
				if tostring(listedRoom.roomId) == tostring(currentRoom) and type(listedRoom.players) == "table" then
					roomPlayersData = listedRoom.players
					break
				end
			end
		end
		roomPlayersData = roomPlayersData or {}

		self._roomBrowserWidgets.RoomTitle.Text = "RUANG #" .. tostring(roomData.roomId or currentRoom)
		self._roomBrowserWidgets.RoomHost.Text = "Host: " .. tostring(roomData.hostName or ((roomPlayersData[1] and (roomPlayersData[1].displayName or roomPlayersData[1].name)) or "-"))
		local roomMode = tostring(roomData.mode or selectedMode or "Classic")
		local roomMapId = (type(roomData.mapId) == "string" and roomData.mapId ~= "" and roomData.mapId)
			or (type(state.selectedMap) == "string" and state.selectedMap ~= "" and state.selectedMap)
			or MAPS[1]
		if roomMode == "Ranked" then
			self._roomMapDropdownOpen = false
		end
		self._roomBrowserWidgets.ModeSelector.Text = "MODE: " .. string.upper(roomMode)
		self._roomBrowserWidgets.MapSelector.Text = "MAP: " .. tostring(roomMapId)
		if roomMode == "Ranked" and hostCanControl then
			local tierText = "UNRANKED"
			local localPlayer = Players.LocalPlayer
			if localPlayer then
				for _, attrName in ipairs({ "RankTier", "Tier", "RankedTier", "HostTier" }) do
					local value = localPlayer:GetAttribute(attrName)
					if value ~= nil and tostring(value) ~= "" then
						tierText = string.upper(tostring(value))
						break
					end
				end
			end
			self._roomBrowserWidgets.RankedTierLabel.Text = "TIER HOST: " .. tierText
			self._roomBrowserWidgets.RankedTierLabel.Visible = true
		end
		self._roomBrowserWidgets.ModeSelector.Visible = hostCanControl
		self._roomBrowserWidgets.MapSelector.Visible = hostCanControl and roomMode ~= "Ranked"
		self._roomBrowserWidgets.ModeDropdown.Visible = hostCanControl and self._roomModeDropdownOpen == true
		self._roomBrowserWidgets.MapDropdown.Visible = hostCanControl and roomMode ~= "Ranked" and self._roomMapDropdownOpen == true
		if self._roomBrowserWidgets.UpdateMapPreview then
			self._roomBrowserWidgets.UpdateMapPreview(roomMode, roomMapId)
		end
		for _, child in ipairs(self._roomBrowserWidgets.PlayersList:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		for _, info in ipairs(roomPlayersData) do
			local card = Instance.new("Frame")
			card.BackgroundColor3 = Color3.fromRGB(30, 36, 47)
			card.BorderSizePixel = 0
			card.Size = UDim2.fromOffset(202, 132)
			card.Parent = self._roomBrowserWidgets.PlayersList
			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 8)
			cardCorner.Parent = card
			local cardStroke = Instance.new("UIStroke")
			cardStroke.Thickness = info.isReady and 2 or 1
			cardStroke.Color = info.isReady and Color3.fromRGB(82, 179, 108) or Color3.fromRGB(74, 88, 112)
			cardStroke.Parent = card

			local preview = Instance.new("ViewportFrame")
			preview.Name = "Preview"
			preview.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
			preview.BorderSizePixel = 0
			preview.Position = UDim2.fromOffset(6, 8)
			preview.Size = UDim2.fromOffset(84, 116)
			preview.Parent = card
			local previewCorner = Instance.new("UICorner")
			previewCorner.CornerRadius = UDim.new(0, 6)
			previewCorner.Parent = preview
			renderCharacterPreview(preview, info.userId)

			local displayNameLabel = Instance.new("TextLabel")
			displayNameLabel.BackgroundTransparency = 1
			displayNameLabel.Position = UDim2.fromOffset(96, 8)
			displayNameLabel.Size = UDim2.fromOffset(100, 30)
			displayNameLabel.TextXAlignment = Enum.TextXAlignment.Left
			displayNameLabel.Font = Enum.Font.GothamBold
			displayNameLabel.TextSize = 10
			displayNameLabel.TextColor3 = Color3.fromRGB(236, 240, 245)
			displayNameLabel.TextWrapped = true
			local roleTag = info.isHost and "[HOST]" or "[MEMBER]"
			displayNameLabel.Text = string.format("%s %s", roleTag, tostring(info.displayName or info.name or "?"))
			displayNameLabel.Parent = card

			local readyLabel = Instance.new("TextLabel")
			readyLabel.BackgroundTransparency = 1
			readyLabel.Position = UDim2.fromOffset(96, 40)
			readyLabel.Size = UDim2.fromOffset(100, 14)
			readyLabel.TextXAlignment = Enum.TextXAlignment.Left
			readyLabel.Font = Enum.Font.GothamSemibold
			readyLabel.TextSize = 10
			readyLabel.TextColor3 = info.isReady and Color3.fromRGB(120, 220, 145) or Color3.fromRGB(255, 195, 120)
			readyLabel.Text = info.isReady and "READY" or "NOT READY"
			readyLabel.Parent = card

			local canKickThis = state.isHost == true and info.userId ~= localUserId and state.matchStarting ~= true
			local kickInline = Instance.new("TextButton")
			kickInline.BackgroundColor3 = Color3.fromRGB(130, 44, 44)
			kickInline.BorderSizePixel = 0
			kickInline.Size = UDim2.fromOffset(18, 18)
			kickInline.Position = UDim2.new(1, -22, 0, 4)
			kickInline.Font = Enum.Font.GothamBlack
			kickInline.TextSize = 12
			kickInline.TextColor3 = Color3.fromRGB(245, 245, 245)
			kickInline.Text = "X"
			kickInline.Visible = canKickThis
			kickInline.Parent = card
			local kickCorner = Instance.new("UICorner")
			kickCorner.CornerRadius = UDim.new(1, 0)
			kickCorner.Parent = kickInline
			if canKickThis then
				connectButtonPress(kickInline, function()
					if self._roomBrowser then
						self._roomBrowser:KickPlayer(info.userId)
					end
				end)
			end
		end
		if #roomPlayersData == 0 then
			local emptyLabel = Instance.new("TextLabel")
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Size = UDim2.new(1, -12, 1, 0)
			emptyLabel.TextXAlignment = Enum.TextXAlignment.Center
			emptyLabel.TextYAlignment = Enum.TextYAlignment.Center
			emptyLabel.Font = Enum.Font.Gotham
			emptyLabel.TextSize = 12
			emptyLabel.TextColor3 = Color3.fromRGB(220, 230, 240)
			emptyLabel.Text = "Belum ada data anggota ruangan"
			emptyLabel.Parent = self._roomBrowserWidgets.PlayersList
		end
		local isReady = state.isReady == true
		local playerCount = roomData.playerCount
		if playerCount == nil then
			playerCount = #roomPlayersData
		end
		local allReadyComputed = state.allReady == true
		if state.isHost == true and state.allReady == nil and #roomPlayersData > 0 then
			allReadyComputed = true
			for _, info in ipairs(roomPlayersData) do
				if not info.isHost and info.isReady ~= true then
					allReadyComputed = false
					break
				end
			end
		end

		if state.isHost == true then
			if state.matchStarting == true then
				self._roomBrowserWidgets.ReadyButton.Text = "BATALKAN COUNTDOWN"
				self._roomBrowserWidgets.ReadyButton.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
				self._roomBrowserWidgets.ReadyButton.Active = true
				self._roomBrowserWidgets.ReadyButton.AutoButtonColor = true
			elseif (playerCount or 0) <= 1 then
				self._roomBrowserWidgets.ReadyButton.Text = "MULAI PERMAINAN"
				self._roomBrowserWidgets.ReadyButton.BackgroundColor3 = Color3.fromRGB(180, 80, 30)
				self._roomBrowserWidgets.ReadyButton.Active = true
				self._roomBrowserWidgets.ReadyButton.AutoButtonColor = true
			elseif allReadyComputed == true then
				self._roomBrowserWidgets.ReadyButton.Text = "MULAI PERMAINAN"
				self._roomBrowserWidgets.ReadyButton.BackgroundColor3 = Color3.fromRGB(180, 80, 30)
				self._roomBrowserWidgets.ReadyButton.Active = true
				self._roomBrowserWidgets.ReadyButton.AutoButtonColor = true
			else
				self._roomBrowserWidgets.ReadyButton.Text = "BELUM SIAP SEMUA"
				self._roomBrowserWidgets.ReadyButton.BackgroundColor3 = Color3.fromRGB(82, 82, 82)
				self._roomBrowserWidgets.ReadyButton.Active = false
				self._roomBrowserWidgets.ReadyButton.AutoButtonColor = false
			end
		else
			self._roomBrowserWidgets.ReadyButton.Text = isReady and "BATALKAN" or "SIAP"
			self._roomBrowserWidgets.ReadyButton.BackgroundColor3 = isReady and Color3.fromRGB(80, 80, 40) or Color3.fromRGB(40, 120, 60)
			self._roomBrowserWidgets.ReadyButton.Active = true
			self._roomBrowserWidgets.ReadyButton.AutoButtonColor = true
		end

		self._roomBrowserWidgets.StartButton.Visible = false
		self._roomBrowserWidgets.CancelStartButton.Visible = false
		self._roomBrowserWidgets.SetPasswordBox.Visible = false
		self._roomBrowserWidgets.SetPasswordButton.Visible = false
		local inviteEnabled = hostCanControl and state.matchStarting ~= true
		self._roomBrowserWidgets.InviteButton.Visible = inviteEnabled
		if inviteEnabled then
			self._roomBrowserWidgets.InviteDropdown.Visible = self._inviteDropdownOpen == true
			if self._inviteDropdownOpen == true and self._roomBrowserWidgets.RebuildInviteList then
				self._roomBrowserWidgets.RebuildInviteList()
			end
		else
			self._inviteDropdownOpen = false
			self._roomBrowserWidgets.InviteDropdown.Visible = false
		end
		self._roomBrowserWidgets.KickNameBox.Visible = false
		self._roomBrowserWidgets.KickButton.Visible = false
	else
		for _, child in ipairs(self._roomBrowserWidgets.PlayersList:GetChildren()) do
			if child:IsA("Frame") or child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		self._roomModeDropdownOpen = false
		self._roomMapDropdownOpen = false
		self._roomBrowserWidgets.ModeDropdown.Visible = false
		self._roomBrowserWidgets.MapDropdown.Visible = false
		self._roomBrowserWidgets.ModeSelector.Visible = false
		self._roomBrowserWidgets.MapSelector.Visible = false
		self._roomBrowserWidgets.RankedTierLabel.Visible = false
		self._inviteDropdownOpen = false
		if self._roomBrowserWidgets.InviteButton then
			self._roomBrowserWidgets.InviteButton.Visible = false
		end
		if self._roomBrowserWidgets.InviteDropdown then
			self._roomBrowserWidgets.InviteDropdown.Visible = false
		end
		self._roomBrowserWidgets.KickNameBox.Visible = false
		self._roomBrowserWidgets.KickButton.Visible = false
	end

	self:_updateRoomBrowserVisibility()
	self:_refreshBasicLobbyPanel()
end

function UISystem:_updateCountdownOverlay(state)
	if not self._roomBrowserWidgets then
		return
	end

	local overlay = self._roomBrowserWidgets.CountdownOverlay
	local label = self._roomBrowserWidgets.CountdownLabel
	local cancelButton = self._roomBrowserWidgets.CancelCountdown
	if not overlay or not label or not cancelButton then
		return
	end

	local countdownActive = type(state) == "table" and state.matchStarting == true
	local showCountdown = countdownActive and self._roomBrowserSuppressed ~= true
	overlay.Visible = showCountdown
	if not countdownActive then
		self._lastCountdownAudioSecond = nil
		self._countdownDisplaySecond = nil
		label.Text = ""
		stopRuntimeUISound("CountdownTick")
		cancelButton.Visible = false
		return
	end

	local hasAuthoritativeSecond = state.countdownSecondsLeft ~= nil
	local displayCountdown = math.max(0, math.floor(tonumber(state.countdownSecondsLeft or state.countdownTotal or 5) or 5))
	local countdownEndsAt = tonumber(state.countdownEndsAt)
	if not hasAuthoritativeSecond and countdownEndsAt then
		local remaining = countdownEndsAt - Workspace:GetServerTimeNow()
		if remaining > 0 then
			displayCountdown = math.max(1, math.ceil(remaining))
		elseif state.matchStarting == true then
			displayCountdown = 1
		end
	end
	label.Text = showCountdown and tostring(displayCountdown) or ""
	if not showCountdown then
		stopRuntimeUISound("CountdownTick")
	end

	if displayCountdown > 0 and self._countdownDisplaySecond ~= displayCountdown then
		self._countdownDisplaySecond = displayCountdown
		if showCountdown then
			self._lastCountdownAudioSecond = displayCountdown
			pulseCountdownLabel(label)
			playRuntimeUISound("CountdownTick", {
				VolumeScale = 1,
				PlaybackSpeed = 1,
				SingleInstance = true,
			})
		end
	elseif displayCountdown <= 0 then
		self._countdownDisplaySecond = displayCountdown
		stopRuntimeUISound("CountdownTick")
	end

	cancelButton.Visible = showCountdown and state.isHost == true
end

function UISystem:_startRoomBrowserLoop()
	if self._roomBrowserLoopRunning then
		return
	end
	self._roomBrowserLoopRunning = true
	task.spawn(function()
		while self._roomBrowserLoopRunning do
			if self._roomBrowserController then
				local state = self._roomBrowserController:GetState()
				if state then
					self:_syncRoomBrowserSuppressionFromMatchContext()
					self:_updateCountdownOverlay(state)
					self:_renderRoomUI(state)
				end
			end
			task.wait(0.1)
		end
	end)
end

function UISystem:_renderRoomUI(state)
	if type(state) ~= "table" then
		return
	end
	local renderKey = buildRoomBrowserRenderKey(state)
	if renderKey == self._roomBrowserRenderKey then
		return
	end
	self._roomBrowserRenderKey = renderKey
	self:_refreshRoomBrowserView()
end

function UISystem:_renderCountdown(state)
	local localPlayer = Players.LocalPlayer
	if not localPlayer then
		return
	end
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	local roomUI = playerGui:FindFirstChild("RoomBrowserUI")
	if not roomUI then
		return
	end

	local label = roomUI:FindFirstChild("CountdownLabel")
	if not label or not label:IsA("TextLabel") then
		return
	end

	if state and state.countdownSecondsLeft then
		label.Visible = true
		label.Text = "COUNTDOWN: " .. tostring(state.countdownSecondsLeft)
	else
		label.Visible = false
	end
end

function UISystem:_renderRoomPlayers(state)
	return state
end

function UISystem:Stop()
	self._phaseTimerRunning = false
	self._roomBrowserLoopRunning = false
	if self._lobbyConnection then
		self._lobbyConnection:Disconnect()
		self._lobbyConnection = nil
	end
	disconnectAll(self._uxConnections)
	disconnectAll(self._connections)
	self:_clearMatchUX()
	self:_clearUXInstances()
end

function UISystem:GetUIState(moduleName)
	return self._uiState[moduleName]
end

function UISystem:GetMatchResult()
	return self._matchResult
end

function UISystem:GetRoomBrowserState()
	if not self._roomBrowser then
		return nil
	end
	return self._roomBrowser:GetState()
end

function UISystem:RoomBrowserSelectMode(modeName)
	if self._roomBrowser then
		self._roomBrowser:SelectMode(modeName)
	end
end

function UISystem:RoomBrowserJoinRoom(roomId, password)
	if self._roomBrowser then
		self._roomBrowser:JoinRoom(roomId, password)
	end
end

function UISystem:RoomBrowserQueueSelected()
	if self._roomBrowser then
		self._roomBrowser:QueueSelected()
	end
end

function UISystem:RoomBrowserSetReady(isReady)
	if self._roomBrowser then
		self._roomBrowser:SetReady(isReady)
	end
end

function UISystem:RoomBrowserHostStart(mapId, difficulty, mode)
	if self._roomBrowser then
		self._roomBrowser:HostStart(mapId, difficulty, mode)
	end
end

function UISystem:RoomBrowserCancelHostStart()
	if self._roomBrowser then
		self._roomBrowser:CancelHostStart()
	end
end

function UISystem:RoomBrowserSetPassword(password)
	if self._roomBrowser then
		self._roomBrowser:SetPassword(password)
	end
end

function UISystem:RoomBrowserCreateRoom()
	if self._roomBrowser then
		self._roomBrowser:CreateRoom()
	end
end

function UISystem:RoomBrowserLeaveRoom()
	if self._roomBrowser then
		self._roomBrowser:LeaveRoom()
	end
end

function UISystem:RoomBrowserInvitePlayerToRoom(targetNameOrUserId)
	if self._roomBrowser then
		self._roomBrowser:InvitePlayerToRoom(targetNameOrUserId)
	end
end

function UISystem:RoomBrowserInviteBroadcastToRoom()
	if self._roomBrowser then
		self._roomBrowser:InviteBroadcastToRoom()
	end
end

function UISystem:RoomBrowserRespondRoomInvite(inviteId, accept)
	if self._roomBrowser then
		self._roomBrowser:RespondRoomInvite(inviteId, accept)
	end
end

return setmetatable({}, UISystem)

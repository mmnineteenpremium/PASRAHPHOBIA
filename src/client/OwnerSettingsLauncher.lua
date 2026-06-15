local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local OwnerSettingsLauncher = {}

local LOCAL_PLAYER = Players.LocalPlayer
local UI_ICON_ASSETS = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameData"):WaitForChild("UIIconAssets"))

local DEFAULTS = {
	graphicsQuality = "SEDANG",
	postProcessing = true,
	motionBlur = true,
	glitchIntensity = 50,
	masterVolume = 80,
	sfxVolume = 80,
	musicVolume = 70,
	binauralAudio = true,
	jumpscareWarning = false,
	mouseSensitivity = 50,
	showSanityBar = true,
	hardMode = false,
	language = "ID",
}

local QUALITY_MAP = {
	RENDAH = Enum.SavedQualitySetting.QualityLevel1,
	SEDANG = Enum.SavedQualitySetting.QualityLevel5,
	TINGGI = Enum.SavedQualitySetting.QualityLevel8,
	ULTRA = Enum.SavedQualitySetting.QualityLevel10,
}

local function findDescendant(root, name)
	if not root then
		return nil
	end
	return root:FindFirstChild(name, true)
end

local function applyIconImage(image, iconKey)
	if not (image and image:IsA("ImageLabel")) then
		return
	end
	local imageAsset = UI_ICON_ASSETS.getImage(iconKey)
	if not imageAsset then
		return
	end
	image.Image = imageAsset
	image.BackgroundTransparency = 1
	image.ScaleType = Enum.ScaleType.Fit
	image:SetAttribute("OwnerIconKey", tostring(iconKey))
end

local function applySettingsRowIcons(window)
	if not window then
		return
	end
	for rowName, iconKey in pairs(UI_ICON_ASSETS.SettingsRows) do
		local row = findDescendant(window, rowName)
		local rowIcon = row and row:FindFirstChild("OwnerRowIcon")
		applyIconImage(rowIcon, iconKey)
	end
end

local function applyToggleFrameIcon(toggleFrame, iconKey)
	if not (toggleFrame and toggleFrame:IsA("GuiObject")) then
		return
	end
	local icon = toggleFrame:FindFirstChild("StateIcon")
	if icon and icon:IsA("ImageLabel") then
		applyIconImage(icon, iconKey)
	end
end

local function getUserGameSettings()
	local ok, settings = pcall(function()
		return UserSettings():GetService("UserGameSettings")
	end)
	return ok and settings or nil
end

local function setToggle(row, enabled)
	if not row then
		return
	end
	for _, child in ipairs(row:GetChildren()) do
		if child.Name == "ToggleOn" then
			applyToggleFrameIcon(child, UI_ICON_ASSETS.ToggleStates.On)
			child.Visible = enabled == true
		elseif child.Name == "ToggleOff" then
			applyToggleFrameIcon(child, UI_ICON_ASSETS.ToggleStates.Off)
			child.Visible = enabled ~= true
		elseif child.Name == "ToggleDisabled" then
			applyToggleFrameIcon(child, UI_ICON_ASSETS.ToggleStates.Disabled)
			child.Visible = false
		end
	end
end

local function setOptionSelected(row, activeName)
	if not row then
		return
	end
	for _, child in ipairs(row:GetChildren()) do
		if child:IsA("TextButton") then
			local selected = child.Name == activeName
			child:SetAttribute("PasrahSettingsSelected", selected)
			child.BackgroundTransparency = selected and 0.08 or 0.28
		end
	end
end

local function setSlider(row, value)
	if not row then
		return
	end
	value = math.clamp(math.floor(tonumber(value) or 0), 0, 100)
	local label = row:FindFirstChild("SliderValue")
	if label and label:IsA("TextLabel") then
		label.Text = tostring(value) .. "%"
	end
	row:SetAttribute("PasrahSettingsValue", value)
end

local function bindButtonVisual(button)
	if not button or not button:IsA("GuiButton") then
		return
	end
	local baseSize = button.Size
	button.MouseEnter:Connect(function()
		button.Size = UDim2.new(baseSize.X.Scale, baseSize.X.Offset + 4, baseSize.Y.Scale, baseSize.Y.Offset + 4)
	end)
	button.MouseLeave:Connect(function()
		button.Size = baseSize
	end)
	button.MouseButton1Down:Connect(function()
		button.Size = UDim2.new(baseSize.X.Scale, baseSize.X.Offset + 2, baseSize.Y.Scale, baseSize.Y.Offset + 2)
	end)
	button.MouseButton1Up:Connect(function()
		button.Size = baseSize
	end)
end

local function applySettings(state)
	local userGameSettings = getUserGameSettings()
	if userGameSettings and QUALITY_MAP[state.graphicsQuality] then
		pcall(function()
			userGameSettings.SavedQualityLevel = QUALITY_MAP[state.graphicsQuality]
		end)
	end

	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("BlurEffect")
			or child:IsA("BloomEffect")
			or child:IsA("ColorCorrectionEffect")
			or child:IsA("DepthOfFieldEffect")
			or child:IsA("SunRaysEffect") then
			pcall(function()
				child.Enabled = state.postProcessing == true
			end)
		end
	end

	local masterVolume = math.clamp((tonumber(state.masterVolume) or 80) / 100, 0, 1)
	local sfxVolume = math.clamp((tonumber(state.sfxVolume) or 80) / 100, 0, 1)
	local musicVolume = math.clamp((tonumber(state.musicVolume) or 70) / 100, 0, 1)
	for _, child in ipairs(SoundService:GetChildren()) do
		if child:IsA("SoundGroup") then
			local token = string.lower(child.Name)
			if string.find(token, "music", 1, true) or string.find(token, "musik", 1, true) or string.find(token, "bgm", 1, true) then
				child.Volume = musicVolume
			elseif string.find(token, "sfx", 1, true) or string.find(token, "effect", 1, true) or string.find(token, "ui", 1, true) then
				child.Volume = sfxVolume
			else
				child.Volume = masterVolume
			end
		end
	end

	LOCAL_PLAYER:SetAttribute("PasrahSettingsGraphicsQuality", state.graphicsQuality)
	LOCAL_PLAYER:SetAttribute("PasrahSettingsPostProcessing", state.postProcessing == true)
	LOCAL_PLAYER:SetAttribute("PasrahSettingsMotionBlur", state.motionBlur == true)
	LOCAL_PLAYER:SetAttribute("PasrahSettingsGlitchIntensity", tonumber(state.glitchIntensity) or 0)
	LOCAL_PLAYER:SetAttribute("PasrahSettingsSFXVolume", tonumber(state.sfxVolume) or 80)
	LOCAL_PLAYER:SetAttribute("PasrahSettingsMusicVolume", tonumber(state.musicVolume) or 70)
	LOCAL_PLAYER:SetAttribute("PasrahSettingsBinauralAudio", state.binauralAudio == true)
	LOCAL_PLAYER:SetAttribute("PasrahSettingsJumpscareWarning", state.jumpscareWarning == true)
	LOCAL_PLAYER:SetAttribute("PasrahSettingsMouseSensitivity", tonumber(state.mouseSensitivity) or 50)
	LOCAL_PLAYER:SetAttribute("PasrahSettingsShowSanityBar", state.showSanityBar == true)
	LOCAL_PLAYER:SetAttribute("PasrahSettingsHardModeRequested", state.hardMode == true)
	LOCAL_PLAYER:SetAttribute("PasrahSettingsLanguage", tostring(state.language or "ID"))

	local playerGui = LOCAL_PLAYER:FindFirstChildOfClass("PlayerGui")
	local sanityGui = playerGui and playerGui:FindFirstChild("SanityHUDGui")
	if sanityGui and sanityGui:IsA("ScreenGui") then
		sanityGui.Enabled = state.showSanityBar == true
	end
end

local function renderSettings(window, state)
	applySettingsRowIcons(window)

	setOptionSelected(findDescendant(window, "KualitasGrafisRow"), tostring(state.graphicsQuality) .. "Option")
	setOptionSelected(findDescendant(window, "BahasaRow"), tostring(state.language) .. "Option")

	setToggle(findDescendant(window, "PostProcessingRow"), state.postProcessing)
	setToggle(findDescendant(window, "MotionBlurRow"), state.motionBlur)
	setToggle(findDescendant(window, "3DAudioBinauralRow"), state.binauralAudio)
	setToggle(findDescendant(window, "JumpScareWarningRow"), state.jumpscareWarning)
	setToggle(findDescendant(window, "TampilkanSanityBarRow"), state.showSanityBar)
	setToggle(findDescendant(window, "ModeSusahRow"), state.hardMode)

	setSlider(findDescendant(window, "GlitchEffectIntensityRow"), state.glitchIntensity)
	setSlider(findDescendant(window, "VolumeMasterRow"), state.masterVolume)
	setSlider(findDescendant(window, "VolumeSFXRow"), state.sfxVolume)
	setSlider(findDescendant(window, "VolumeMusikRow"), state.musicVolume)
	setSlider(findDescendant(window, "SensitivitasMouseRow"), state.mouseSensitivity)
end

local function bindOption(row, buttonName, callback)
	local button = row and row:FindFirstChild(buttonName)
	if button and button:IsA("TextButton") then
		button.Activated:Connect(callback)
	end
end

local function bindToggle(row, getterSetter)
	if not row then
		return
	end
	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			getterSetter()
		end
	end)
end

local function bindSlider(row, getterSetter)
	if not row then
		return
	end
	row.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			getterSetter()
		end
	end)
end

function OwnerSettingsLauncher.start(screenGui)
	local playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui")
	local referenceGui = playerGui:WaitForChild("PASRAHPHOBIA_BottomNavbar_Static", 10)
	if not referenceGui then
		warn("[OwnerSettingsLauncher] Missing PASRAHPHOBIA_BottomNavbar_Static")
		return
	end

	referenceGui.IgnoreGuiInset = false
	referenceGui.Enabled = true

	local bottomNav = referenceGui:FindFirstChild("BottomNav")
	if bottomNav and bottomNav:IsA("GuiObject") then
		bottomNav.Visible = false
	end
	local floatingUI = referenceGui:FindFirstChild("FloatingUI")
	if floatingUI and floatingUI:IsA("GuiObject") then
		floatingUI.Visible = false
	end

	local windows = referenceGui:FindFirstChild("Windows")
	local settingsWindow = windows and windows:FindFirstChild("SettingsWindow")
	if not (settingsWindow and settingsWindow:IsA("Frame")) then
		warn("[OwnerSettingsLauncher] Missing Windows.SettingsWindow")
		return
	end

	local launcherButton = screenGui:WaitForChild("SettingsFloatingButton", 10)
	if not launcherButton then
		warn("[OwnerSettingsLauncher] SettingsFloatingButton tidak ditemukan di ScreenGui — periksa hierarki UI")
		return
	end
	bindButtonVisual(launcherButton)

	local state = table.clone(DEFAULTS)

	local function setOpen(isOpen)
		settingsWindow.Visible = isOpen == true
	end

	local function update()
		renderSettings(settingsWindow, state)
		applySettings(state)
	end

	launcherButton.Activated:Connect(function()
		setOpen(not settingsWindow.Visible)
	end)

	local closeButton = settingsWindow:FindFirstChild("CloseButton", true)
	if closeButton and closeButton:IsA("GuiButton") then
		closeButton.Activated:Connect(function()
			setOpen(false)
		end)
	end

	local saveButton = settingsWindow:FindFirstChild("SaveButton", true)
	if saveButton and saveButton:IsA("GuiButton") then
		saveButton.Activated:Connect(function()
			update()
			setOpen(false)
		end)
	end

	local cancelButton = settingsWindow:FindFirstChild("CancelButton", true)
	if cancelButton and cancelButton:IsA("GuiButton") then
		cancelButton.Activated:Connect(function()
			setOpen(false)
		end)
	end

	local qualityRow = findDescendant(settingsWindow, "KualitasGrafisRow")
	for _, quality in ipairs({ "RENDAH", "SEDANG", "TINGGI", "ULTRA" }) do
		bindOption(qualityRow, quality .. "Option", function()
			state.graphicsQuality = quality
			update()
		end)
	end

	local languageRow = findDescendant(settingsWindow, "BahasaRow")
	for _, language in ipairs({ "ID", "EN" }) do
		bindOption(languageRow, language .. "Option", function()
			state.language = language
			update()
		end)
	end

	bindToggle(findDescendant(settingsWindow, "PostProcessingRow"), function()
		state.postProcessing = not state.postProcessing
		update()
	end)
	bindToggle(findDescendant(settingsWindow, "MotionBlurRow"), function()
		state.motionBlur = not state.motionBlur
		update()
	end)
	bindToggle(findDescendant(settingsWindow, "3DAudioBinauralRow"), function()
		state.binauralAudio = not state.binauralAudio
		update()
	end)
	bindToggle(findDescendant(settingsWindow, "JumpScareWarningRow"), function()
		state.jumpscareWarning = not state.jumpscareWarning
		update()
	end)
	bindToggle(findDescendant(settingsWindow, "TampilkanSanityBarRow"), function()
		state.showSanityBar = not state.showSanityBar
		update()
	end)
	bindToggle(findDescendant(settingsWindow, "ModeSusahRow"), function()
		state.hardMode = not state.hardMode
		update()
	end)

	bindSlider(findDescendant(settingsWindow, "GlitchEffectIntensityRow"), function()
		state.glitchIntensity = (state.glitchIntensity + 25) % 125
		update()
	end)
	bindSlider(findDescendant(settingsWindow, "VolumeMasterRow"), function()
		state.masterVolume = (state.masterVolume + 10) % 110
		update()
	end)
	bindSlider(findDescendant(settingsWindow, "VolumeSFXRow"), function()
		state.sfxVolume = (state.sfxVolume + 10) % 110
		update()
	end)
	bindSlider(findDescendant(settingsWindow, "VolumeMusikRow"), function()
		state.musicVolume = (state.musicVolume + 10) % 110
		update()
	end)
	bindSlider(findDescendant(settingsWindow, "SensitivitasMouseRow"), function()
		state.mouseSensitivity = (state.mouseSensitivity + 10) % 110
		update()
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape and settingsWindow.Visible then
			setOpen(false)
		end
	end)

	setOpen(false)
	update()
end

return OwnerSettingsLauncher

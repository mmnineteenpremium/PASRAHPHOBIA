local UISupport = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local STUDIO_TOUCH_MOBILE_MAX_VIEWPORT_X = 900
local STUDIO_TOUCH_MOBILE_MAX_VIEWPORT_Y = 430

function UISupport.disconnectAll(connections)
	for _, connection in ipairs(connections) do
		if connection then
			connection:Disconnect()
		end
	end
	table.clear(connections)
end

function UISupport.destroyAll(instances)
	for _, instance in ipairs(instances) do
		if instance and instance.Parent then
			instance:Destroy()
		end
	end
	table.clear(instances)
end

function UISupport.fadeGuiObject(guiObject, transparency, duration, tweenService)
	if not guiObject then
		return
	end
	local tweenInfo = TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	if guiObject:IsA("Frame") or guiObject:IsA("TextButton") or guiObject:IsA("TextBox") then
		tweenService:Create(guiObject, tweenInfo, { BackgroundTransparency = transparency }):Play()
	elseif guiObject:IsA("TextLabel") then
		tweenService:Create(guiObject, tweenInfo, { TextTransparency = transparency }):Play()
	elseif guiObject:IsA("ImageLabel") or guiObject:IsA("ImageButton") then
		tweenService:Create(guiObject, tweenInfo, { ImageTransparency = transparency }):Play()
	end
end

function UISupport.resolveSafeInsets(guiService)
	local ok, insetA, insetB = pcall(function()
		return guiService:GetSafeZoneInsets()
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

function UISupport.createDeviceProfile(replicationRoot, userInputService, overrideAttrName)
	local function resolveInputOverride()
		local raw = replicationRoot:GetAttribute(overrideAttrName)
		if type(raw) ~= "string" then
			local localPlayer = Players.LocalPlayer
			raw = localPlayer and localPlayer:GetAttribute(overrideAttrName) or nil
		end
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

		local camera = Workspace.CurrentCamera
		local viewport = camera and camera.ViewportSize or Vector2.zero
		local studioTouchLandscapePreview = RunService:IsStudio()
			and userInputService.TouchEnabled == true
			and viewport.X > viewport.Y
			and viewport.X <= STUDIO_TOUCH_MOBILE_MAX_VIEWPORT_X
			and viewport.Y <= STUDIO_TOUCH_MOBILE_MAX_VIEWPORT_Y
		if studioTouchLandscapePreview then
			self.isMobile = true
			self.isConsole = false
			self.isPC = false
			self._inputType = "Mobile"
			return
		end

		local inputName = lastInputType and tostring(lastInputType) or ""
		local usingTouch = inputName == tostring(Enum.UserInputType.Touch)
		local usingGamepad = string.find(inputName, "Gamepad", 1, true) ~= nil
		local usingKeyboardMouse = inputName == tostring(Enum.UserInputType.MouseButton1)
			or inputName == tostring(Enum.UserInputType.MouseMovement)
			or inputName == tostring(Enum.UserInputType.Keyboard)

		self.isMobile = userInputService.TouchEnabled and (usingTouch or (not usingGamepad and not usingKeyboardMouse))
		self.isConsole = userInputService.GamepadEnabled and (usingGamepad or (not userInputService.KeyboardEnabled and not userInputService.TouchEnabled))
		self.isPC = userInputService.KeyboardEnabled and not self.isMobile and not self.isConsole

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

	profile:Refresh(userInputService:GetLastInputType())
	return profile
end

return UISupport

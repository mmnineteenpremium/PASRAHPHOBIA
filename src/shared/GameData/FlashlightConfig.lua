local FlashlightConfig = {
	assetId = 516522664,
	handle = {
		size = Vector3.new(0.5, 0.5, 2),
		color = Color3.fromRGB(44, 46, 50),
		material = Enum.Material.SmoothPlastic,
		meshId = "rbxassetid://115955313",
		textureId = "rbxassetid://115955343",
		meshScale = Vector3.new(0.7, 0.7, 0.7),
		gripCFrame = CFrame.new(0.1, -0.4, 0),
		fallbackMountCFrame = CFrame.new(0.1, -0.28, -0.08),
		lensOffset = CFrame.new(0, 0, -1.14),
	},
	sound = {
		soundId = "rbxassetid://140513388846872",
		volume = 0.32,
		playbackSpeed = 1,
		rollOffMinDistance = 4,
		rollOffMaxDistance = 30,
	},
	lens = {
		size = Vector3.new(0.2, 0.2, 0.05),
		onColor = Color3.fromRGB(255, 232, 186),
		offColor = Color3.fromRGB(120, 132, 148),
		onTransparency = 0.04,
		offTransparency = 0.34,
	},
	localLight = {
		brightness = 1.35,
		range = 12,
		angle = 24,
		offBrightness = 0,
		offRange = 2,
		offAngle = 12,
		fadeInSpeed = 10,
		fadeOutSpeed = 7,
		color = Color3.fromRGB(255, 244, 214),
	},
	remoteLight = {
		-- Tuned for multi-client parity: reduce overbright + mobile GPU pressure.
		range = 32,
		angle = 26,
		brightness = 3.6,
		boostRange = 16,
		boostAngle = 42,
		boostBrightness = 1.8,
		fillRange = 8,
		fillBrightness = 0.6,
		-- Aim sync tuning for parity: higher speed/lower interval reduces remote lag.
		aimUpdateMinInterval = 1 / 45,
		aimSmoothSpeed = 8,
		aimMaxAlpha = 0.45,
		color = Color3.fromRGB(255, 250, 230),
	},
	viewmodel = {
		baseOffset = CFrame.new(0, -0.52, -1.0) * CFrame.Angles(math.rad(-8), 0, 0),
		partScale = 0.62,
		flashlightMountCFrame = CFrame.new(0.24, -0.02, -0.28),
		handsOnly = true,
		armMaterial = Enum.Material.SmoothPlastic,
		armBrightnessScale = 0.62,
		handBrightnessScale = 0.52,
		armMinChannel = 0.12,
		armMaxChannel = 0.62,
		segmentLayouts = {
			FPV_LeftUpperArm = {
				position = Vector3.new(-0.72, -0.06, -0.16),
				rotation = Vector3.new(-6, -8, 42),
			},
			FPV_LeftLowerArm = {
				position = Vector3.new(-0.9, -0.34, -0.24),
				rotation = Vector3.new(-14, -10, 18),
			},
			FPV_LeftHand = {
				position = Vector3.new(-0.92, -0.56, -0.42),
				rotation = Vector3.new(-12, 180, 18),
			},
			FPV_RightUpperArm = {
				position = Vector3.new(0.72, -0.06, -0.16),
				rotation = Vector3.new(-6, 8, -42),
			},
			FPV_RightLowerArm = {
				position = Vector3.new(0.9, -0.34, -0.24),
				rotation = Vector3.new(-14, 10, -18),
			},
			FPV_RightHand = {
				position = Vector3.new(0.92, -0.56, -0.42),
				rotation = Vector3.new(-12, 180, -18),
			},
			FPV_LeftArm = {
				position = Vector3.new(-0.82, -0.42, -0.3),
				rotation = Vector3.new(-12, 180, 18),
			},
			FPV_RightArm = {
				position = Vector3.new(0.82, -0.42, -0.3),
				rotation = Vector3.new(-12, 180, -18),
			},
		},
	},
	motion = {
		walkSpeedReference = 14,
		cursorUnlockedBobScale = 0.18,
		idleBreathAmplitude = 0.018,
		idleBreathSpeed = 1.35,
		cameraLagAlpha = 0.15,
		lookSwayX = 0.035,
		lookSwayY = 0.024,
		moveSwayScale = 0.5,
		flashlightCarryOffset = Vector3.new(0.04, -0.015, -0.045),
		flashlightCarryRoll = -2.5,
	},
}

return FlashlightConfig

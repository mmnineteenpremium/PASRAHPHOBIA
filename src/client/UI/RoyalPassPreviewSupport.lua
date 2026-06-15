local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GraphicsSupport = require(script.Parent.GraphicsSupport)

local RoyalPassPreviewSupport = {}

local function getModelsFolder()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	return models and models:FindFirstChild("RoyalPass")
end

local function findModelRoot(model)
	if not model or not model:IsA("Model") then
		return nil
	end
	if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
		return model.PrimaryPart
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end
	return nil
end

local function stripScripts(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BaseScript") then
			descendant:Destroy()
		end
	end
end

local function styleViewport(viewportFrame, accentColor)
	local accent = typeof(accentColor) == "Color3" and accentColor or Color3.fromRGB(112, 126, 152)
	viewportFrame.BackgroundColor3 = accent:Lerp(Color3.fromRGB(18, 24, 34), 0.8)
	viewportFrame.BackgroundTransparency = 0.04
	viewportFrame.Ambient = accent:Lerp(Color3.fromRGB(220, 226, 236), 0.24)
	viewportFrame.LightColor = accent:Lerp(Color3.fromRGB(255, 246, 232), 0.18)
	viewportFrame.LightDirection = Vector3.new(-0.6, -1, -0.35)
end

local function makePart(parent, name, size, cframe, color, material, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Shape = shape or Enum.PartType.Block
	part.Parent = parent
	return part
end

local function buildFallbackRewardModel(rewardId, rewardInfo, accentColor)
	local accent = typeof(accentColor) == "Color3" and accentColor or Color3.fromRGB(112, 126, 152)
	local model = Instance.new("Model")
	model.Name = tostring(rewardId or "RoyalPassReward")

	local kind = "Currency"
	if type(rewardInfo) == "table" then
		if rewardInfo.exclusiveEmoteId then
			kind = "Emote"
		elseif rewardInfo.seasonBadgeId then
			kind = "Badge"
		elseif rewardInfo.cosmeticId then
			kind = "Cosmetic"
		end
	end

	local pedestalColor = accent:Lerp(Color3.fromRGB(24, 28, 36), 0.18)
	makePart(model, "Pedestal", Vector3.new(1.9, 0.22, 1.9), CFrame.new(0, -0.92, 0), pedestalColor, Enum.Material.SmoothPlastic)
	makePart(model, "PedestalRing", Vector3.new(1.3, 0.08, 1.3), CFrame.new(0, -0.77, 0), accent:Lerp(Color3.fromRGB(250, 246, 236), 0.18), Enum.Material.Neon, Enum.PartType.Cylinder)
	makePart(model, "GlowRing", Vector3.new(2.05, 0.06, 2.05), CFrame.new(0, -0.84, 0), accent:Lerp(Color3.fromRGB(255, 248, 236), 0.1), Enum.Material.Neon, Enum.PartType.Cylinder)
	makePart(model, "GlowCore", Vector3.new(0.58, 0.58, 0.58), CFrame.new(0, 0.12, 0), accent:Lerp(Color3.fromRGB(255, 242, 216), 0.06), Enum.Material.Neon, Enum.PartType.Ball)

	if kind == "Cosmetic" then
		makePart(model, "GiftBox", Vector3.new(1.05, 1.05, 1.05), CFrame.new(0, -0.05, 0), accent:Lerp(Color3.fromRGB(70, 82, 102), 0.18), Enum.Material.SmoothPlastic)
		makePart(model, "RibbonVertical", Vector3.new(0.18, 1.2, 1.12), CFrame.new(0, 0.03, 0), accent, Enum.Material.Neon)
		makePart(model, "RibbonHorizontal", Vector3.new(1.12, 0.18, 1.12), CFrame.new(0, 0.06, 0), accent:Lerp(Color3.fromRGB(255, 250, 240), 0.08), Enum.Material.Neon)
		makePart(model, "CrownBar", Vector3.new(0.7, 0.12, 0.32), CFrame.new(0, 0.82, 0), accent:Lerp(Color3.fromRGB(248, 222, 132), 0.06), Enum.Material.SmoothPlastic)
		makePart(model, "CrownLeft", Vector3.new(0.14, 0.28, 0.14), CFrame.new(-0.26, 0.96, 0), accent:Lerp(Color3.fromRGB(248, 222, 132), 0.1), Enum.Material.Neon, Enum.PartType.Ball)
		makePart(model, "CrownCenter", Vector3.new(0.18, 0.4, 0.18), CFrame.new(0, 1.02, 0), accent:Lerp(Color3.fromRGB(250, 236, 180), 0.02), Enum.Material.Neon, Enum.PartType.Ball)
		makePart(model, "CrownRight", Vector3.new(0.14, 0.28, 0.14), CFrame.new(0.26, 0.96, 0), accent:Lerp(Color3.fromRGB(248, 222, 132), 0.1), Enum.Material.Neon, Enum.PartType.Ball)
	elseif kind == "Badge" then
		makePart(model, "ShieldBody", Vector3.new(1.0, 1.26, 0.18), CFrame.new(0, 0.08, 0), accent:Lerp(Color3.fromRGB(52, 58, 72), 0.24), Enum.Material.SmoothPlastic)
		makePart(model, "ShieldTop", Vector3.new(0.76, 0.18, 0.2), CFrame.new(0, 0.88, 0), accent:Lerp(Color3.fromRGB(250, 224, 154), 0.12), Enum.Material.Neon)
		makePart(model, "ShieldMedal", Vector3.new(0.52, 0.52, 0.2), CFrame.new(0, 0.12, 0.12), accent:Lerp(Color3.fromRGB(255, 242, 214), 0.03), Enum.Material.Neon, Enum.PartType.Ball)
		makePart(model, "ShieldRibbon", Vector3.new(0.18, 0.58, 0.18), CFrame.new(0, -0.58, 0), accent:Lerp(Color3.fromRGB(232, 160, 72), 0.08), Enum.Material.SmoothPlastic)
	elseif kind == "Emote" then
		makePart(model, "Head", Vector3.new(0.32, 0.32, 0.32), CFrame.new(0, 0.6, 0), accent:Lerp(Color3.fromRGB(250, 244, 232), 0.1), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
		makePart(model, "Torso", Vector3.new(0.36, 0.72, 0.22), CFrame.new(0, 0.02, 0), accent:Lerp(Color3.fromRGB(88, 100, 126), 0.2), Enum.Material.SmoothPlastic)
		makePart(model, "ArmLeft", Vector3.new(0.12, 0.56, 0.12), CFrame.new(-0.33, 0.18, 0.02) * CFrame.Angles(0, 0, math.rad(-18)), accent:Lerp(Color3.fromRGB(250, 244, 232), 0.2), Enum.Material.SmoothPlastic)
		makePart(model, "ArmRight", Vector3.new(0.12, 0.56, 0.12), CFrame.new(0.33, 0.18, 0.02) * CFrame.Angles(0, 0, math.rad(18)), accent:Lerp(Color3.fromRGB(250, 244, 232), 0.2), Enum.Material.SmoothPlastic)
		makePart(model, "LegLeft", Vector3.new(0.12, 0.62, 0.12), CFrame.new(-0.15, -0.68, 0.01) * CFrame.Angles(0, 0, math.rad(-8)), accent:Lerp(Color3.fromRGB(88, 100, 126), 0.14), Enum.Material.SmoothPlastic)
		makePart(model, "LegRight", Vector3.new(0.12, 0.62, 0.12), CFrame.new(0.15, -0.68, 0.01) * CFrame.Angles(0, 0, math.rad(8)), accent:Lerp(Color3.fromRGB(88, 100, 126), 0.14), Enum.Material.SmoothPlastic)
		makePart(model, "MotionArc", Vector3.new(0.1, 1.3, 0.1), CFrame.new(0.72, 0.1, -0.02) * CFrame.Angles(0, 0, math.rad(42)), accent:Lerp(Color3.fromRGB(248, 222, 132), 0.06), Enum.Material.Neon)
	else
		makePart(model, "CoinStackA", Vector3.new(0.42, 0.18, 0.42), CFrame.new(-0.18, -0.05, 0), accent:Lerp(Color3.fromRGB(248, 220, 124), 0.06), Enum.Material.Neon, Enum.PartType.Cylinder)
		makePart(model, "CoinStackB", Vector3.new(0.5, 0.18, 0.5), CFrame.new(0.12, 0.12, 0), accent:Lerp(Color3.fromRGB(250, 236, 164), 0.1), Enum.Material.Neon, Enum.PartType.Cylinder)
		makePart(model, "CoinStackC", Vector3.new(0.58, 0.18, 0.58), CFrame.new(0.34, 0.28, 0), accent:Lerp(Color3.fromRGB(236, 198, 84), 0.06), Enum.Material.Neon, Enum.PartType.Cylinder)
		makePart(model, "XPCrystal", Vector3.new(0.42, 0.9, 0.42), CFrame.new(-0.5, 0.05, 0) * CFrame.Angles(0, math.rad(28), math.rad(14)), accent:Lerp(Color3.fromRGB(204, 232, 255), 0.08), Enum.Material.Glass, Enum.PartType.Block)
	end

	local root = findModelRoot(model)
	if root then
		model.PrimaryPart = root
	end
	return model
end

local function prepareModel(model)
	if not model or not model:IsA("Model") then
		return false
	end
	stripScripts(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanQuery = false
			descendant.CanTouch = false
			descendant.CastShadow = false
		end
	end
	local root = findModelRoot(model)
	if not root then
		return false
	end
	model.PrimaryPart = root
	return true
end

function RoyalPassPreviewSupport.render(viewportFrame, rewardId, rewardInfo, accentColor, previewState)
	if not viewportFrame or not viewportFrame:IsA("ViewportFrame") then
		return false
	end

	styleViewport(viewportFrame, accentColor)

	if not GraphicsSupport.shouldUseHighCostViewportPreview() then
		GraphicsSupport.renderPreviewFallback(
			viewportFrame,
			tostring(rewardId or "REWARD"),
			typeof(accentColor) == "Color3" and accentColor or Color3.fromRGB(112, 126, 152),
			string.upper(tostring(previewState or "VIEW"))
		)
		viewportFrame.Visible = true
		return true
	end

	local rewardKey = tostring(rewardId or "")
	local previewSignature = string.format(
		"%s|%s|%s",
		rewardKey,
		tostring(previewState or "view"),
		tostring(type(rewardInfo) == "table" and (rewardInfo.cosmeticId or rewardInfo.seasonBadgeId or rewardInfo.exclusiveEmoteId or rewardInfo.mm or rewardInfo.pp or rewardInfo.xp or "reward") or "reward")
	)
	if viewportFrame:GetAttribute("PreviewSignature") == previewSignature then
		local worldModel = viewportFrame:FindFirstChild("PreviewWorld")
		local currentModel = worldModel and worldModel:IsA("WorldModel") and worldModel:FindFirstChildWhichIsA("Model") or nil
		if currentModel then
			viewportFrame.Visible = true
			return true
		end
	end

	for _, child in ipairs(viewportFrame:GetChildren()) do
		if not child:IsA("UICorner") and not child:IsA("UIStroke") then
			child:Destroy()
		end
	end

	local camera = Instance.new("Camera")
	camera.Name = "PreviewCamera"
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	local worldModel = Instance.new("WorldModel")
	worldModel.Name = "PreviewWorld"
	worldModel.Parent = viewportFrame

	local modelsFolder = getModelsFolder()
	local template = modelsFolder and modelsFolder:FindFirstChild(rewardKey) or nil
	local model = nil
	if template and template:IsA("Model") then
		model = template:Clone()
	elseif template and template:IsA("BasePart") then
		model = Instance.new("Model")
		local clone = template:Clone()
		clone.Parent = model
	end
	if not model then
		model = buildFallbackRewardModel(rewardKey, rewardInfo, accentColor)
	end
	if not prepareModel(model) then
		GraphicsSupport.renderPreviewFallback(
			viewportFrame,
			tostring(rewardId or "REWARD"),
			typeof(accentColor) == "Color3" and accentColor or Color3.fromRGB(112, 126, 152),
			string.upper(tostring(previewState or "VIEW"))
		)
		viewportFrame.Visible = true
		return false
	end

	model.Parent = worldModel

	local size = model:GetExtentsSize()
	local center = model:GetPivot().Position
	local distance = math.max(size.X, size.Y, size.Z) * 1.9 + 1.9
	local cameraOffset = Vector3.new(0.28, 0.2, distance)
	if tostring(previewState or "") == "Premium" then
		cameraOffset = Vector3.new(0.42, 0.3, distance)
	elseif tostring(previewState or "") == "Free" then
		cameraOffset = Vector3.new(0.2, 0.18, distance)
	end

	camera.CFrame = CFrame.new(center + cameraOffset, center + Vector3.new(0, size.Y * 0.06, 0))
	viewportFrame:SetAttribute("PreviewSignature", previewSignature)
	viewportFrame.Visible = true
	return true
end

return RoyalPassPreviewSupport

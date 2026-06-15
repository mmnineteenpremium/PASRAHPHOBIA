local GraphicsSupport = require(script.Parent.GraphicsSupport)

local ShopPreviewSupport = {}

local function collectShopItemTags(item)
	local tags = {}
	if type(item) ~= "table" or type(item.tags) ~= "table" then
		return tags
	end
	for _, tag in ipairs(item.tags) do
		tags[string.lower(tostring(tag))] = true
	end
	return tags
end

local function resolveShopDisplayCategoryKey(item)
	if type(item) ~= "table" then
		return "Character"
	end

	local category = tostring(item.category or "")
	if category == "Cosmetic" then
		return "Character"
	end
	if category == "Equipment" then
		return "InvestigationTool"
	end
	if category == "Entitlement" then
		return "Pass"
	end
	if category == "CurrencyPack" then
		return "CurrencyPack"
	end
	if category == "Character" or category == "Pet" or category == "InvestigationTool" or category == "Pass" then
		return category
	end

	local tags = collectShopItemTags(item)
	if tags.pet then
		return "Pet"
	end
	if tags.uv or tags.spiritbox or tags.sanity or tags.tool then
		return "InvestigationTool"
	end
	if tags.class or tags.pass or tags.lifetime then
		return "Pass"
	end
	if tags.emote or tags.accessory or tags.mask or tags.veil or tags.charm or tags.bundle or tags.outfit or tags.body or tags.head then
		return "Character"
	end
	return "Character"
end

local function resolveShopPreviewGlyph(item)
	local tags = collectShopItemTags(item)
	if tags.uv then
		return "UV"
	end
	if tags.spiritbox then
		return "SB"
	end
	if tags.sanity then
		return "SP"
	end
	if tags.class then
		return "CL"
	end
	if tags.pass then
		return "PS"
	end
	if tags.lifetime then
		return "LT"
	end
	if tags.bundle then
		return "BD"
	end
	if tags.emote then
		return "EM"
	end
	if tags.lantern then
		return "LN"
	end
	if tags.mask then
		return "MK"
	end
	if tags.veil then
		return "VL"
	end
	if tags.charm then
		return "CH"
	end
	if tags.pet then
		return "PT"
	end

	local categoryKey = resolveShopDisplayCategoryKey(item)
	if categoryKey == "Character" then
		return "CHAR"
	end
	if categoryKey == "Pet" then
		return "PET"
	end
	if categoryKey == "InvestigationTool" then
		return "TOOL"
	end
	if categoryKey == "Pass" then
		return "PASS"
	end
	if categoryKey == "CurrencyPack" then
		local currency = tostring(type(item) == "table" and (item.grantCurrency or item.currency) or "")
		if currency == "MM" or currency == "PP" then
			return currency
		end
		return "PACK"
	end

	local source = tostring(type(item) == "table" and (item.name or item.id) or "IT")
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

local function stripScripts(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BaseScript") then
			descendant:Destroy()
		end
	end
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

local function styleViewport(viewportFrame, accentColor)
	local accent = typeof(accentColor) == "Color3" and accentColor or Color3.fromRGB(112, 126, 152)
	viewportFrame.BackgroundColor3 = accent:Lerp(Color3.fromRGB(18, 24, 34), 0.8)
	viewportFrame.BackgroundTransparency = 0.04
	viewportFrame.Ambient = accent:Lerp(Color3.fromRGB(220, 226, 236), 0.24)
	viewportFrame.LightColor = accent:Lerp(Color3.fromRGB(255, 246, 232), 0.18)
	viewportFrame.LightDirection = Vector3.new(-0.6, -1, -0.35)
end

local function buildBasePlatform(model, accent)
	local pedestalColor = accent:Lerp(Color3.fromRGB(24, 28, 36), 0.18)
	makePart(model, "Pedestal", Vector3.new(1.9, 0.22, 1.9), CFrame.new(0, -0.92, 0), pedestalColor, Enum.Material.SmoothPlastic)
	makePart(model, "PedestalRing", Vector3.new(1.3, 0.08, 1.3), CFrame.new(0, -0.77, 0), accent:Lerp(Color3.fromRGB(250, 246, 236), 0.18), Enum.Material.Neon, Enum.PartType.Cylinder)
	makePart(model, "GlowRing", Vector3.new(2.05, 0.06, 2.05), CFrame.new(0, -0.84, 0), accent:Lerp(Color3.fromRGB(255, 248, 236), 0.1), Enum.Material.Neon, Enum.PartType.Cylinder)
	makePart(model, "GlowCore", Vector3.new(0.58, 0.58, 0.58), CFrame.new(0, 0.12, 0), accent:Lerp(Color3.fromRGB(255, 242, 216), 0.06), Enum.Material.Neon, Enum.PartType.Ball)
end

local function buildCharacterModel(model, accent)
	makePart(model, "Head", Vector3.new(0.34, 0.34, 0.34), CFrame.new(0, 0.62, 0), accent:Lerp(Color3.fromRGB(250, 244, 232), 0.08), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	makePart(model, "Torso", Vector3.new(0.42, 0.8, 0.28), CFrame.new(0, 0.08, 0), accent:Lerp(Color3.fromRGB(88, 100, 126), 0.2), Enum.Material.SmoothPlastic)
	makePart(model, "ArmLeft", Vector3.new(0.12, 0.6, 0.12), CFrame.new(-0.35, 0.2, 0.02) * CFrame.Angles(0, 0, math.rad(-16)), accent:Lerp(Color3.fromRGB(250, 244, 232), 0.16), Enum.Material.SmoothPlastic)
	makePart(model, "ArmRight", Vector3.new(0.12, 0.6, 0.12), CFrame.new(0.35, 0.2, 0.02) * CFrame.Angles(0, 0, math.rad(16)), accent:Lerp(Color3.fromRGB(250, 244, 232), 0.16), Enum.Material.SmoothPlastic)
	makePart(model, "LegLeft", Vector3.new(0.12, 0.68, 0.12), CFrame.new(-0.16, -0.7, 0.01) * CFrame.Angles(0, 0, math.rad(-6)), accent:Lerp(Color3.fromRGB(88, 100, 126), 0.12), Enum.Material.SmoothPlastic)
	makePart(model, "LegRight", Vector3.new(0.12, 0.68, 0.12), CFrame.new(0.16, -0.7, 0.01) * CFrame.Angles(0, 0, math.rad(6)), accent:Lerp(Color3.fromRGB(88, 100, 126), 0.12), Enum.Material.SmoothPlastic)
	makePart(model, "Aura", Vector3.new(0.9, 0.06, 0.9), CFrame.new(0, 1.0, 0), accent:Lerp(Color3.fromRGB(255, 242, 236), 0.05), Enum.Material.Neon, Enum.PartType.Cylinder)
end

local function buildPetModel(model, accent)
	makePart(model, "Body", Vector3.new(0.84, 0.72, 0.84), CFrame.new(0, 0.12, 0), accent:Lerp(Color3.fromRGB(240, 246, 236), 0.18), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	makePart(model, "Head", Vector3.new(0.46, 0.46, 0.46), CFrame.new(0.34, 0.34, 0), accent:Lerp(Color3.fromRGB(250, 244, 232), 0.1), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	makePart(model, "EarLeft", Vector3.new(0.08, 0.24, 0.08), CFrame.new(0.18, 0.56, 0.1) * CFrame.Angles(0, 0, math.rad(-20)), accent:Lerp(Color3.fromRGB(244, 238, 224), 0.08), Enum.Material.SmoothPlastic)
	makePart(model, "EarRight", Vector3.new(0.08, 0.24, 0.08), CFrame.new(0.5, 0.56, -0.1) * CFrame.Angles(0, 0, math.rad(20)), accent:Lerp(Color3.fromRGB(244, 238, 224), 0.08), Enum.Material.SmoothPlastic)
	makePart(model, "Tail", Vector3.new(0.08, 0.5, 0.08), CFrame.new(-0.46, -0.08, 0.14) * CFrame.Angles(0, 0, math.rad(28)), accent:Lerp(Color3.fromRGB(255, 248, 236), 0.14), Enum.Material.Neon)
	makePart(model, "Collar", Vector3.new(0.38, 0.08, 0.38), CFrame.new(0.24, 0.12, 0), accent:Lerp(Color3.fromRGB(248, 220, 124), 0.08), Enum.Material.Neon, Enum.PartType.Cylinder)
end

local function buildToolModel(model, accent, item)
	local tags = collectShopItemTags(item)
	if tags.spiritbox then
		makePart(model, "BoxBody", Vector3.new(0.8, 0.68, 0.52), CFrame.new(0, 0.02, 0), accent:Lerp(Color3.fromRGB(72, 84, 104), 0.2), Enum.Material.SmoothPlastic)
		makePart(model, "Antenna", Vector3.new(0.06, 0.42, 0.06), CFrame.new(0.22, 0.52, 0) * CFrame.Angles(0, 0, math.rad(-12)), accent:Lerp(Color3.fromRGB(248, 224, 154), 0.08), Enum.Material.Neon)
		makePart(model, "Speaker", Vector3.new(0.14, 0.14, 0.14), CFrame.new(-0.22, 0.04, 0.18), accent:Lerp(Color3.fromRGB(250, 246, 236), 0.08), Enum.Material.Neon, Enum.PartType.Ball)
		makePart(model, "Dial", Vector3.new(0.16, 0.16, 0.16), CFrame.new(0.08, -0.08, 0.22), accent:Lerp(Color3.fromRGB(248, 220, 124), 0.04), Enum.Material.Neon, Enum.PartType.Ball)
	elseif tags.uv then
		makePart(model, "Grip", Vector3.new(0.24, 0.9, 0.24), CFrame.new(-0.1, -0.02, 0), accent:Lerp(Color3.fromRGB(76, 92, 126), 0.18), Enum.Material.SmoothPlastic)
		makePart(model, "Body", Vector3.new(0.18, 0.74, 0.18), CFrame.new(0.12, 0.18, 0), accent:Lerp(Color3.fromRGB(245, 248, 252), 0.16), Enum.Material.SmoothPlastic)
		makePart(model, "Lens", Vector3.new(0.24, 0.24, 0.24), CFrame.new(0.12, 0.56, 0), accent:Lerp(Color3.fromRGB(248, 220, 124), 0.02), Enum.Material.Neon, Enum.PartType.Ball)
		makePart(model, "Beam", Vector3.new(0.08, 0.82, 0.08), CFrame.new(0.12, 1.08, 0), accent:Lerp(Color3.fromRGB(255, 250, 220), 0.08), Enum.Material.Neon)
	elseif tags.sanity then
		makePart(model, "Bottle", Vector3.new(0.44, 0.82, 0.44), CFrame.new(0, 0.08, 0), accent:Lerp(Color3.fromRGB(226, 232, 240), 0.14), Enum.Material.SmoothPlastic)
		makePart(model, "Cap", Vector3.new(0.26, 0.12, 0.26), CFrame.new(0, 0.56, 0), accent:Lerp(Color3.fromRGB(246, 210, 124), 0.06), Enum.Material.Neon)
		makePart(model, "Label", Vector3.new(0.34, 0.16, 0.06), CFrame.new(0, 0.02, 0.22), accent:Lerp(Color3.fromRGB(255, 244, 232), 0.08), Enum.Material.Neon)
	else
		makePart(model, "Handle", Vector3.new(0.18, 0.9, 0.18), CFrame.new(-0.1, 0, 0), accent:Lerp(Color3.fromRGB(92, 104, 128), 0.18), Enum.Material.SmoothPlastic)
		makePart(model, "Head", Vector3.new(0.24, 0.48, 0.24), CFrame.new(0.12, 0.34, 0) * CFrame.Angles(0, 0, math.rad(12)), accent:Lerp(Color3.fromRGB(250, 244, 234), 0.1), Enum.Material.SmoothPlastic)
		makePart(model, "Tip", Vector3.new(0.08, 0.32, 0.08), CFrame.new(0.28, 0.62, 0), accent:Lerp(Color3.fromRGB(248, 220, 124), 0.06), Enum.Material.Neon)
	end
end

local function buildPassModel(model, accent)
	makePart(model, "BadgeBody", Vector3.new(0.92, 1.16, 0.18), CFrame.new(0, 0.06, 0), accent:Lerp(Color3.fromRGB(52, 58, 72), 0.22), Enum.Material.SmoothPlastic)
	makePart(model, "BadgeTop", Vector3.new(0.74, 0.16, 0.2), CFrame.new(0, 0.86, 0), accent:Lerp(Color3.fromRGB(250, 224, 154), 0.12), Enum.Material.Neon)
	makePart(model, "Medal", Vector3.new(0.52, 0.52, 0.2), CFrame.new(0, 0.1, 0.12), accent:Lerp(Color3.fromRGB(255, 242, 214), 0.04), Enum.Material.Neon, Enum.PartType.Ball)
	makePart(model, "RibbonLeft", Vector3.new(0.16, 0.54, 0.16), CFrame.new(-0.22, -0.58, 0) * CFrame.Angles(0, 0, math.rad(-10)), accent:Lerp(Color3.fromRGB(232, 160, 72), 0.08), Enum.Material.SmoothPlastic)
	makePart(model, "RibbonRight", Vector3.new(0.16, 0.54, 0.16), CFrame.new(0.22, -0.58, 0) * CFrame.Angles(0, 0, math.rad(10)), accent:Lerp(Color3.fromRGB(232, 160, 72), 0.08), Enum.Material.SmoothPlastic)
end

local function buildCurrencyModel(model, accent, item)
	local grantCurrency = tostring(type(item) == "table" and (item.grantCurrency or item.currency) or "")
	local coinColor = accent:Lerp(Color3.fromRGB(248, 220, 124), 0.08)
	if grantCurrency == "PP" then
		coinColor = accent:Lerp(Color3.fromRGB(248, 198, 108), 0.05)
	elseif grantCurrency == "MM" then
		coinColor = accent:Lerp(Color3.fromRGB(204, 236, 255), 0.06)
	end
	makePart(model, "CoinStackA", Vector3.new(0.42, 0.18, 0.42), CFrame.new(-0.18, -0.04, 0), coinColor, Enum.Material.Neon, Enum.PartType.Cylinder)
	makePart(model, "CoinStackB", Vector3.new(0.5, 0.18, 0.5), CFrame.new(0.12, 0.12, 0), accent:Lerp(Color3.fromRGB(250, 236, 164), 0.1), Enum.Material.Neon, Enum.PartType.Cylinder)
	makePart(model, "CoinStackC", Vector3.new(0.58, 0.18, 0.58), CFrame.new(0.34, 0.28, 0), accent:Lerp(Color3.fromRGB(236, 198, 84), 0.06), Enum.Material.Neon, Enum.PartType.Cylinder)
	makePart(model, "Crystal", Vector3.new(0.42, 0.9, 0.42), CFrame.new(-0.5, 0.06, 0) * CFrame.Angles(0, math.rad(28), math.rad(14)), accent:Lerp(Color3.fromRGB(204, 232, 255), 0.08), Enum.Material.Glass, Enum.PartType.Block)
end

local function buildFallbackShopModel(item, accentColor)
	local accent = typeof(accentColor) == "Color3" and accentColor or Color3.fromRGB(112, 126, 152)
	local model = Instance.new("Model")
	model.Name = tostring(type(item) == "table" and (item.id or item.name or "ShopPreview") or "ShopPreview")

	buildBasePlatform(model, accent)

	local categoryKey = resolveShopDisplayCategoryKey(item)
	if categoryKey == "Character" then
		buildCharacterModel(model, accent)
	elseif categoryKey == "Pet" then
		buildPetModel(model, accent)
	elseif categoryKey == "InvestigationTool" then
		buildToolModel(model, accent, item)
	elseif categoryKey == "Pass" then
		buildPassModel(model, accent)
	elseif categoryKey == "CurrencyPack" then
		buildCurrencyModel(model, accent, item)
	else
		buildCharacterModel(model, accent)
	end

	local root = findModelRoot(model)
	if root then
		model.PrimaryPart = root
	end
	return model
end

local function clearViewport(viewportFrame)
	for _, child in ipairs(viewportFrame:GetChildren()) do
		if not child:IsA("UICorner") and not child:IsA("UIStroke") then
			child:Destroy()
		end
	end
end

function ShopPreviewSupport.render(viewportFrame, item, accentColor, previewState)
	if not viewportFrame or not viewportFrame:IsA("ViewportFrame") then
		return false
	end

	local categoryKey = resolveShopDisplayCategoryKey(item)
	local accent = typeof(accentColor) == "Color3" and accentColor or Color3.fromRGB(112, 126, 152)
	styleViewport(viewportFrame, accent)

	local previewId = tostring(type(item) == "table" and (item.id or item.name or "") or "")
	local previewCurrency = tostring(type(item) == "table" and (item.currency or "") or "")
	local previewRarity = tostring(type(item) == "table" and (item.rarity or "") or "")
	local signature = string.format("%s|%s|%s|%s|%s", previewId, categoryKey, previewCurrency, previewRarity, tostring(previewState or "view"))

	if not GraphicsSupport.shouldUseHighCostViewportPreview() then
		local flatSignature = signature .. "|flat"
		if viewportFrame:GetAttribute("PreviewSignature") ~= flatSignature then
			GraphicsSupport.renderPreviewFallback(
				viewportFrame,
				resolveShopPreviewGlyph(item),
				accent,
				string.upper(tostring(type(item) == "table" and (item.name or item.id or categoryKey) or categoryKey))
			)
			viewportFrame:SetAttribute("PreviewSignature", flatSignature)
		end
		viewportFrame.Visible = true
		return true
	end

	if viewportFrame:GetAttribute("PreviewSignature") == signature then
		local worldModel = viewportFrame:FindFirstChild("PreviewWorld")
		local currentModel = worldModel and worldModel:IsA("WorldModel") and worldModel:FindFirstChildWhichIsA("Model") or nil
		if currentModel then
			viewportFrame.Visible = true
			return true
		end
	end

	clearViewport(viewportFrame)

	local camera = Instance.new("Camera")
	camera.Name = "PreviewCamera"
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	local worldModel = Instance.new("WorldModel")
	worldModel.Name = "PreviewWorld"
	worldModel.Parent = viewportFrame

	local model = buildFallbackShopModel(item, accent)
	if not model then
		GraphicsSupport.renderPreviewFallback(
			viewportFrame,
			resolveShopPreviewGlyph(item),
			accent,
			string.upper(tostring(type(item) == "table" and (item.name or item.id or categoryKey) or categoryKey))
		)
		viewportFrame:SetAttribute("PreviewSignature", signature .. "|fallback")
		viewportFrame.Visible = true
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
		GraphicsSupport.renderPreviewFallback(
			viewportFrame,
			resolveShopPreviewGlyph(item),
			accent,
			string.upper(tostring(type(item) == "table" and (item.name or item.id or categoryKey) or categoryKey))
		)
		viewportFrame:SetAttribute("PreviewSignature", signature .. "|fallback")
		viewportFrame.Visible = true
		return false
	end

	model.PrimaryPart = root
	model.Parent = worldModel

	local extents = model:GetExtentsSize()
	local pivot = model:GetPivot().Position
	local distance = math.max(extents.X, extents.Y, extents.Z) * 1.85 + 1.9
	local cameraOffset = Vector3.new(0.25, extents.Y * 0.1 + 0.2, distance)
	if categoryKey == "Pet" then
		cameraOffset = Vector3.new(0.16, extents.Y * 0.12 + 0.1, distance * 0.86)
	elseif categoryKey == "InvestigationTool" then
		cameraOffset = Vector3.new(0.22, extents.Y * 0.16 + 0.18, distance * 1.02)
	elseif categoryKey == "CurrencyPack" then
		cameraOffset = Vector3.new(0.12, extents.Y * 0.14 + 0.16, distance * 0.96)
	end

	camera.CFrame = CFrame.new(pivot + cameraOffset, pivot + Vector3.new(0, extents.Y * 0.12, 0))
	viewportFrame:SetAttribute("PreviewSignature", signature)
	viewportFrame.Visible = true
	return true
end

return ShopPreviewSupport

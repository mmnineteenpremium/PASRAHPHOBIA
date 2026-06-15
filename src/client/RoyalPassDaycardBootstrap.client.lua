local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local RoyalPassPreviewSupport = require(script.Parent.UI.RoyalPassPreviewSupport)

local RoyalPassConfig = nil
do
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local configFolder = shared and shared:FindFirstChild("Config")
	local configModule = configFolder and configFolder:FindFirstChild("RoyalPassConfig")
	if configModule and configModule:IsA("ModuleScript") then
		local ok, result = pcall(require, configModule)
		if ok and type(result) == "table" then
			RoyalPassConfig = result
		end
	end
end

local AssetIdConfig = nil
do
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local configFolder = shared and shared:FindFirstChild("Config")
	local generatedFolder = configFolder and configFolder:FindFirstChild("Generated")
	local configModule = generatedFolder and generatedFolder:FindFirstChild("AssetIdConfig")
	if configModule and configModule:IsA("ModuleScript") then
		local ok, result = pcall(require, configModule)
		if ok and type(result) == "table" then
			AssetIdConfig = result
		end
	end
end

local TOTAL_TIERS = (type(RoyalPassConfig) == "table" and tonumber(RoyalPassConfig.TOTAL_TIERS)) or 60
local TIER_XP = (type(RoyalPassConfig) == "table" and tonumber(RoyalPassConfig.XP_PER_TIER)) or 1000

local function getNumberAttribute(name, fallback)
	local value = LocalPlayer:GetAttribute(name)
	value = tonumber(value)
	if value == nil then
		return fallback
	end
	return value
end

local function getBoolAttribute(name)
	return LocalPlayer:GetAttribute(name) == true
end

local function getRoyalPassTierData(index)
	if type(RoyalPassConfig) ~= "table" or type(RoyalPassConfig.TIERS) ~= "table" then
		return nil
	end
	return RoyalPassConfig.TIERS[index]
end

local function rewardToText(reward)
	if type(reward) ~= "table" then
		return "-"
	end
	local parts = {}
	if tonumber(reward.mm) and tonumber(reward.mm) > 0 then
		table.insert(parts, "+" .. tostring(math.floor(tonumber(reward.mm) or 0)) .. " MM")
	end
	if tonumber(reward.pp) and tonumber(reward.pp) > 0 then
		table.insert(parts, "+" .. tostring(math.floor(tonumber(reward.pp) or 0)) .. " PP")
	end
	if tonumber(reward.xp) and tonumber(reward.xp) > 0 then
		table.insert(parts, "+" .. tostring(math.floor(tonumber(reward.xp) or 0)) .. " XP")
	end
	if tonumber(reward.gachaTickets) and tonumber(reward.gachaTickets) > 0 then
		table.insert(parts, tostring(math.floor(tonumber(reward.gachaTickets) or 0)) .. " TICKET")
	end
	if reward.cosmeticId then
		table.insert(parts, "COSMETIC")
	end
	if reward.seasonBadgeId then
		table.insert(parts, "BADGE")
	end
	if reward.exclusiveEmoteId then
		table.insert(parts, "EMOTE")
	end
	if #parts == 0 then
		return "-"
	end
	return table.concat(parts, " + ")
end

local function makeCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = parent
	return corner
end

local function makeStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0
	stroke.Parent = parent
	return stroke
end

local function makeLabel(parent, name, props)
	local label = Instance.new(props.className or "TextLabel")
	label.Name = name
	label.BackgroundTransparency = props.backgroundTransparency ~= nil and props.backgroundTransparency or 1
	label.BorderSizePixel = 0
	label.Font = props.font or Enum.Font.Gotham
	label.TextSize = props.textSize or 12
	label.TextColor3 = props.textColor3 or Color3.fromRGB(240, 240, 236)
	label.TextWrapped = props.textWrapped == true
	label.TextXAlignment = props.textXAlignment or Enum.TextXAlignment.Left
	label.TextYAlignment = props.textYAlignment or Enum.TextYAlignment.Center
	label.RichText = props.richText == true
	label.Parent = parent
	if props.position then
		label.Position = props.position
	end
	if props.size then
		label.Size = props.size
	end
	if props.backgroundColor3 then
		label.BackgroundColor3 = props.backgroundColor3
	end
	if props.text ~= nil then
		label.Text = props.text
	end
	return label
end

local function makeLane(card, laneName, yOffset, index, premiumOwned, currentTier)
	local lane = Instance.new("Frame")
	lane.Name = laneName
	lane.Position = UDim2.fromOffset(8, yOffset)
	lane.Size = UDim2.new(1, -16, 0, 124)
	lane.BackgroundColor3 = laneName == "Premium" and Color3.fromRGB(32, 30, 34) or Color3.fromRGB(24, 32, 42)
	lane.BorderSizePixel = 0
	lane.Parent = card
	makeCorner(lane, UDim.new(0, 12))
	makeStroke(lane, laneName == "Premium" and Color3.fromRGB(116, 88, 54) or Color3.fromRGB(82, 110, 162), 1, 0.16)

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.new(1, 0, 0, 5)
	accent.BackgroundColor3 = laneName == "Premium" and (premiumOwned and Color3.fromRGB(210, 166, 84) or Color3.fromRGB(116, 88, 54)) or Color3.fromRGB(82, 110, 162)
	accent.BorderSizePixel = 0
	accent.Parent = lane

	local rarityTemplate = Instance.new("ImageLabel")
	rarityTemplate.Name = "RarityTemplate"
	rarityTemplate.BackgroundTransparency = 1
	rarityTemplate.Size = UDim2.fromScale(1, 1)
	rarityTemplate.ImageTransparency = 0.22
	rarityTemplate.ZIndex = 2
	rarityTemplate.Parent = lane

	local preview = Instance.new("ViewportFrame")
	preview.Name = "CosmeticPreview"
	preview.BackgroundColor3 = Color3.fromRGB(18, 24, 34)
	preview.BackgroundTransparency = 0.04
	preview.BorderSizePixel = 0
	preview.Position = UDim2.fromOffset(14, 32)
	preview.Size = UDim2.new(1, -28, 0, 34)
	preview.ZIndex = 3
	preview.Parent = lane

	local dayBadge = makeLabel(lane, "DayBadge", {
		className = "TextLabel",
		position = UDim2.fromOffset(10, 8),
		size = UDim2.fromOffset(78, 18),
		backgroundTransparency = 0,
		backgroundColor3 = laneName == "Premium" and (premiumOwned and Color3.fromRGB(210, 166, 84) or Color3.fromRGB(116, 88, 54)) or Color3.fromRGB(60, 82, 118),
		text = string.format("%s %02d", laneName == "Premium" and "PREM" or "FREE", index),
		font = Enum.Font.GothamBlack,
		textSize = 10,
	})
	makeCorner(dayBadge, UDim.new(1, 0))

	local title = makeLabel(lane, "Title", {
		position = UDim2.fromOffset(10, 30),
		size = UDim2.new(1, -20, 0, 22),
		text = laneName == "Premium" and "PREMIUM TRACK" or "FREE TRACK",
		font = Enum.Font.GothamBold,
		textSize = 14,
		textWrapped = true,
		textColor3 = Color3.fromRGB(244, 240, 232),
	})

	local meta = makeLabel(lane, "Meta", {
		position = UDim2.fromOffset(10, 52),
		size = UDim2.new(1, -20, 0, 24),
		text = laneName == "Premium" and "Premium lane terkunci jika belum berlangganan." or "Free lane selalu tersedia untuk player biasa.",
		textSize = 11,
		textWrapped = true,
		textColor3 = Color3.fromRGB(188, 198, 214),
	})

	local rewardPill = makeLabel(lane, "RewardPill", {
		position = UDim2.fromOffset(10, 84),
		size = UDim2.new(1, -20, 0, 18),
		backgroundTransparency = 0,
		backgroundColor3 = laneName == "Premium" and Color3.fromRGB(94, 74, 42) or Color3.fromRGB(60, 88, 128),
		text = "-",
		font = Enum.Font.GothamBold,
		textSize = 10,
	})
	makeCorner(rewardPill, UDim.new(1, 0))

	local footer = makeLabel(lane, "Footer", {
		position = UDim2.new(1, -10, 0, 10),
		size = UDim2.fromOffset(42, 14),
		backgroundTransparency = 1,
		textXAlignment = Enum.TextXAlignment.Right,
		font = Enum.Font.GothamBlack,
		textSize = 9,
		text = "LOCK",
	})

	local tierData = getRoyalPassTierData(index)
	local reward = tierData and (laneName == "Premium" and tierData.premium or tierData.free) or nil
	local current = math.max(1, math.floor(currentTier or 1))
	local isUnlocked = index < current
	local isLive = index == current
	local canClaim = laneName == "Free" and (isUnlocked or isLive) or (laneName == "Premium" and premiumOwned == true and (isUnlocked or isLive))
	local statusText = isUnlocked and "DONE" or (canClaim and "CLAIM" or "LOCK")

	footer.Text = statusText
	title.Text = laneName == "Premium" and (premiumOwned and "PREMIUM / CLAIM" or "PREMIUM / LOCKED") or "FREE / CLAIM"
	meta.Text = laneName == "Premium"
		and (premiumOwned and "Premium active. Claim slot premium tersedia di tier yang sudah unlock." or "Premium lane terkunci untuk player biasa.")
		or "Free lane bisa di-claim oleh player biasa."
	rewardPill.Text = rewardToText(reward)

	local previewRewardId = nil
	if type(reward) == "table" then
		previewRewardId = reward.cosmeticId or reward.seasonBadgeId or reward.exclusiveEmoteId
	end
	if not previewRewardId then
		previewRewardId = string.format("royal_%s_tier_%02d", string.lower(laneName), index)
	end
	RoyalPassPreviewSupport.render(preview, previewRewardId, reward, accent.BackgroundColor3, laneName)

	return lane
end

local function buildRoyalPassCards(scroller)
	local premiumOwned = getBoolAttribute("PasrahRoyalPassPremiumOwned")
	local currentTier = getNumberAttribute("PasrahRoyalPassCurrentTier", 1)
	local unlockedTierCount = getNumberAttribute("PasrahRoyalPassUnlockedTierCount", currentTier)

	for _, child in ipairs(scroller:GetChildren()) do
		if child.Name:match("^RoyalPassDayCard%d+$") then
			child:Destroy()
		end
	end

	local cardWidth = 172
	local cardGap = 8
	local laneSpacing = 12
	local cardHeight = 336
	local canvasWidth = (TOTAL_TIERS * 180) + 16
	scroller.ScrollingDirection = Enum.ScrollingDirection.X
	scroller.AutomaticCanvasSize = Enum.AutomaticSize.None
	scroller.CanvasSize = UDim2.fromOffset(canvasWidth, cardHeight + 24)
	scroller.Size = UDim2.new(1, 0, 0, 360)

	for index = 1, TOTAL_TIERS do
		local card = Instance.new("Frame")
		card.Name = "RoyalPassDayCard" .. tostring(index)
		card.Position = UDim2.fromOffset(8 + ((index - 1) * 180), 8)
		card.Size = UDim2.fromOffset(cardWidth, cardHeight)
		card.BackgroundColor3 = Color3.fromRGB(20, 26, 36)
		card.BorderSizePixel = 0
		card.ClipsDescendants = true
		card.Parent = scroller
		makeCorner(card, UDim.new(0, 12))
		makeStroke(card, Color3.fromRGB(82, 100, 126), 1, 0.16)

		local accent = Instance.new("Frame")
		accent.Name = "Accent"
		accent.Size = UDim2.new(1, 0, 0, 5)
		accent.BackgroundColor3 = Color3.fromRGB(90, 126, 188)
		accent.BorderSizePixel = 0
		accent.Parent = card

		makeLabel(card, "DayBadge", {
			position = UDim2.fromOffset(10, 12),
			size = UDim2.fromOffset(78, 18),
			backgroundTransparency = 0,
			backgroundColor3 = Color3.fromRGB(48, 62, 82),
			text = string.format("DAY %02d", index),
			font = Enum.Font.GothamBlack,
			textSize = 10,
		})

		makeLabel(card, "Title", {
			position = UDim2.fromOffset(10, 40),
			size = UDim2.new(1, -20, 0, 24),
			text = "ROYAL PASS",
			font = Enum.Font.GothamBold,
			textSize = 13,
			textWrapped = true,
			textColor3 = Color3.fromRGB(244, 240, 232),
		})

		makeLabel(card, "Meta", {
			position = UDim2.fromOffset(10, 60),
			size = UDim2.new(1, -20, 0, 16),
			text = "Free row di atas, Premium row di bawah.",
			font = Enum.Font.Gotham,
			textSize = 10,
			textColor3 = Color3.fromRGB(188, 198, 214),
		})

		local freeLane = makeLane(card, "Free", 82, index, premiumOwned, currentTier)
		local premiumLane = makeLane(card, "Premium", 212, index, premiumOwned, currentTier)
		freeLane.LayoutOrder = (index * 2) - 1
		premiumLane.LayoutOrder = index * 2

		if unlockedTierCount < index then
			local dim = Instance.new("Frame")
			dim.Name = "LockedMask"
			dim.BackgroundColor3 = Color3.fromRGB(10, 12, 16)
			dim.BackgroundTransparency = 0.88
			dim.BorderSizePixel = 0
			dim.Size = UDim2.fromScale(1, 1)
			dim.Parent = card
		end
	end
end

local function attachRoyalPassUI()
	local playerGui = LocalPlayer:WaitForChild("PlayerGui")
	local royalPassGui = playerGui:WaitForChild("RoyalPassUI", 20)
	if not royalPassGui then
		return
	end

	local mainPanel = royalPassGui:WaitForChild("MainPanel", 20)
	local contentFrame = mainPanel and mainPanel:WaitForChild("ContentFrame", 20)
	local deck = contentFrame and contentFrame:WaitForChild("RoyalPassDeck", 20)
	local scroller = deck and deck:WaitForChild("TrackScroller", 20)
	if not scroller then
		return
	end

	local template = scroller:FindFirstChild("DayCardTemplate")
	if template and template:IsA("GuiObject") then
		template.Visible = false
	end

	buildRoyalPassCards(scroller)

	local attributes = {
		"PasrahRoyalPassPremiumOwned",
		"PasrahRoyalPassCurrentTier",
		"PasrahRoyalPassUnlockedTierCount",
		"PasrahRoyalPassTotalXP",
		"PasrahRoyalPassCurrentTierXP",
		"PasrahRoyalPassRemainingXP",
		"PasrahRoyalPassProgressPercent",
		"PasrahRoyalPassSeasonId",
		"PasrahRoyalPassLastEvent",
	}

	local refreshQueued = false
	local function refresh()
		if refreshQueued then
			return
		end
		refreshQueued = true
		task.defer(function()
			refreshQueued = false
			if scroller.Parent then
				buildRoyalPassCards(scroller)
			end
		end)
	end

	for _, attributeName in ipairs(attributes) do
		LocalPlayer:GetAttributeChangedSignal(attributeName):Connect(refresh)
	end
	royalPassGui.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			return
		end
		refresh()
	end)
	scroller.ChildAdded:Connect(function(child)
		if child.Name == "DayCardTemplate" then
			child.Visible = false
		end
	end)
end

task.spawn(function()
	attachRoyalPassUI()
end)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GraphicsSupport = {}

GraphicsSupport.MODE_ATTR = "PasrahGraphicsMode"
GraphicsSupport.SOURCE_ATTR = "PasrahGraphicsModeSource"
GraphicsSupport.APPLIED_AT_ATTR = "PasrahGraphicsAppliedAt"
GraphicsSupport.MODE_ORDER = { "Performance", "Balanced", "Quality" }
GraphicsSupport.MODE_META = {
	Performance = {
		label = "RINGAN",
		footer = "3D preview hemat",
		buttonColor = Color3.fromRGB(86, 94, 112),
		atmosphereDensityScale = 0.42,
		atmosphereHazeScale = 0.34,
	},
	Balanced = {
		label = "SEIMBANG",
		footer = "Default mobile",
		buttonColor = Color3.fromRGB(74, 102, 126),
		atmosphereDensityScale = 0.7,
		atmosphereHazeScale = 0.64,
	},
	Quality = {
		label = "DETAIL",
		footer = "Visual penuh",
		buttonColor = Color3.fromRGB(96, 120, 82),
		atmosphereDensityScale = 1,
		atmosphereHazeScale = 1,
	},
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

local function loadPlatformVisualConfig()
	local shared = ReplicatedStorage:FindFirstChild("Shared") or ReplicatedStorage:FindFirstChild("shared")
	if not shared then
		return {
			UiScale = {},
			PerformanceTier = {},
		}
	end
	local gameDataFolder = shared:FindFirstChild("GameData")
	if not gameDataFolder then
		return {
			UiScale = {},
			PerformanceTier = {},
		}
	end
	local cfg = safeRequire(gameDataFolder:FindFirstChild("GlobalOperationsConfig"))
	local platform = type(cfg) == "table" and type(cfg.Platform) == "table" and cfg.Platform or {}
	return {
		UiScale = type(platform.UiScale) == "table" and platform.UiScale or {},
		PerformanceTier = type(platform.PerformanceTier) == "table" and platform.PerformanceTier or {},
	}
end

GraphicsSupport.PlatformVisualConfig = loadPlatformVisualConfig()

local warnedPreviewContracts = {}

local function warnPreviewContract(message)
	if warnedPreviewContracts[message] then
		return
	end
	warnedPreviewContracts[message] = true
	warn(message)
end

local function resolveVisualTemplate(path)
	local node = ReplicatedStorage
	for _, segment in ipairs(path) do
		if typeof(node) ~= "Instance" then
			return nil
		end
		node = node:FindFirstChild(segment)
	end
	return node
end

local function cloneFlatPreviewTemplate(viewportFrame)
	local template = resolveVisualTemplate({ "Assets", "VisualTemplates", "UI", "FlatPreviewFallbackTemplate" })
	if not (template and template:IsA("Folder")) then
		warnPreviewContract("[GraphicsSupport] Missing authored visual template: UI.FlatPreviewFallbackTemplate")
		return nil, nil
	end

	local title
	local detail
	for _, child in ipairs(template:GetChildren()) do
		local existing = viewportFrame:FindFirstChild(child.Name)
		if existing then
			existing:Destroy()
		end
		local clone = child:Clone()
		clone.Parent = viewportFrame
		if clone.Name == "FlatPreviewTitle" and clone:IsA("TextLabel") then
			title = clone
		elseif clone.Name == "FlatPreviewDetail" and clone:IsA("TextLabel") then
			detail = clone
		end
	end

	if not (title and detail) then
		warnPreviewContract("[GraphicsSupport] Authored UI.FlatPreviewFallbackTemplate contract mismatch.")
		return nil, nil
	end

	return title, detail
end

function GraphicsSupport.normalizeMode(rawMode)
	local token = tostring(rawMode or "")
	if GraphicsSupport.MODE_META[token] then
		return token
	end
	return nil
end

function GraphicsSupport.getModeMeta(rawMode)
	return GraphicsSupport.MODE_META[GraphicsSupport.normalizeMode(rawMode) or "Balanced"]
end

function GraphicsSupport.getNextMode(rawMode)
	local current = GraphicsSupport.normalizeMode(rawMode) or "Balanced"
	for index, modeName in ipairs(GraphicsSupport.MODE_ORDER) do
		if modeName == current then
			return GraphicsSupport.MODE_ORDER[(index % #GraphicsSupport.MODE_ORDER) + 1]
		end
	end
	return GraphicsSupport.MODE_ORDER[1]
end

function GraphicsSupport.resolveAppliedMode(player)
	player = player or Players.LocalPlayer
	local mode = player and GraphicsSupport.normalizeMode(player:GetAttribute(GraphicsSupport.MODE_ATTR)) or nil
	return mode or "Balanced"
end

function GraphicsSupport.shouldUseHighCostViewportPreview(player)
	return GraphicsSupport.resolveAppliedMode(player) ~= "Performance"
end

function GraphicsSupport.renderPreviewFallback(viewportFrame, titleText, accentColor, detailText)
	if not viewportFrame or not viewportFrame:IsA("ViewportFrame") then
		return false
	end

	for _, child in ipairs(viewportFrame:GetChildren()) do
		if not child:IsA("UICorner") and not child:IsA("UIStroke") then
			child:Destroy()
		end
	end
	viewportFrame.CurrentCamera = nil
	local previewAccent = typeof(accentColor) == "Color3" and accentColor or Color3.fromRGB(96, 108, 126)
	viewportFrame.BackgroundColor3 = previewAccent:Lerp(Color3.fromRGB(18, 24, 34), 0.78)
	viewportFrame.BackgroundTransparency = 0.03

	local title, detail = cloneFlatPreviewTemplate(viewportFrame)
	if not (title and detail) then
		return false
	end

	title.Size = UDim2.new(1, -8, 0, math.max(18, math.floor(viewportFrame.AbsoluteSize.Y * 0.55)))
	title.Position = UDim2.fromOffset(4, 4)
	title.Text = string.upper(tostring(titleText or "LOW"))

	detail.Position = UDim2.new(0.5, 0, 1, -4)
	detail.Size = UDim2.new(1, -8, 0, math.max(10, math.floor(viewportFrame.AbsoluteSize.Y * 0.2)))
	detail.Text = string.upper(tostring(detailText or "3D OFF"))

	return true
end

return GraphicsSupport

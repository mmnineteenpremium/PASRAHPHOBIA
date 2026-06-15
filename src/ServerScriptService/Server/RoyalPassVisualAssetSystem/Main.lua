local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoyalPassVisualAssetSystem = {}
RoyalPassVisualAssetSystem.__index = RoyalPassVisualAssetSystem

local function parseAssetId(value)
	if type(value) ~= "number" and type(value) ~= "string" then
		return nil
	end
	return tonumber(tostring(value):match("%d+"))
end

local function requireAssetConfig()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local configRoot = shared and shared:FindFirstChild("Config")
	local generated = configRoot and configRoot:FindFirstChild("Generated")
	local moduleScript = generated and generated:FindFirstChild("AssetIdConfig")
	if not moduleScript then
		return nil
	end
	local ok, config = pcall(require, moduleScript)
	if ok and type(config) == "table" then
		return config
	end
	return nil
end

local function resolveRoyalPassFolder()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		assets = Instance.new("Folder")
		assets.Name = "Assets"
		assets.Parent = ReplicatedStorage
	end

	local models = assets:FindFirstChild("Models")
	if not models then
		models = Instance.new("Folder")
		models.Name = "Models"
		models.Parent = assets
	end

	local royalPassFolder = models:FindFirstChild("RoyalPass")
	if not royalPassFolder then
		royalPassFolder = Instance.new("Folder")
		royalPassFolder.Name = "RoyalPass"
		royalPassFolder.Parent = models
	end

	return royalPassFolder
end

local function pickAssetModel(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Model") then
			return child
		end
	end
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("BasePart") then
			local model = Instance.new("Model")
			child.Parent = model
			return model
		end
	end
	return nil
end

local function loadModelFromAsset(assetId)
	local ok, containerOrError = pcall(function()
		return InsertService:LoadAsset(assetId)
	end)
	if not ok or not containerOrError then
		return nil, tostring(containerOrError)
	end

	local model = pickAssetModel(containerOrError)
	if not model then
		containerOrError:Destroy()
		return nil, "asset contains no model or basepart"
	end

	model.Parent = nil
	containerOrError:Destroy()
	return model, nil
end

local function replaceTemplate(parentFolder, rewardId, model, assetId)
	local existing = parentFolder:FindFirstChild(rewardId)
	if existing then
		existing:Destroy()
	end
	local replacement = model:Clone()
	replacement.Name = rewardId
	replacement:SetAttribute("PasrahSecondAccountModelAssetId", tostring(assetId))
	replacement:SetAttribute("PasrahRoyalPassRewardId", rewardId)
	replacement.Parent = parentFolder
end

function RoyalPassVisualAssetSystem.new()
	return setmetatable({}, RoyalPassVisualAssetSystem)
end

function RoyalPassVisualAssetSystem:Init()
	return true
end

function RoyalPassVisualAssetSystem:Start()
	local assetConfig = requireAssetConfig()
	local royalPass = assetConfig and assetConfig.RoyalPassCosmetics or nil
	if type(royalPass) ~= "table" then
		return true
	end

	local royalPassFolder = resolveRoyalPassFolder()
	local refreshed = 0
	for rewardId, assetValue in pairs(royalPass) do
		local assetId = parseAssetId(assetValue)
		local isModelReward = type(rewardId) == "string"
			and (rewardId:match("^royal_") ~= nil or rewardId == "outfit_sang_ahli_season_exclusive")
		if assetId and isModelReward then
			local ok, modelOrError = pcall(function()
				return loadModelFromAsset(assetId)
			end)
			local model = ok and modelOrError or nil
			if model then
				replaceTemplate(royalPassFolder, rewardId, model, assetId)
				model:Destroy()
				refreshed += 1
			else
				warn(string.format("[RoyalPassVisualAssetSystem] Failed to refresh %s from asset %s: %s", tostring(rewardId), tostring(assetId), tostring(modelOrError)))
			end
		end
	end

	ReplicatedStorage:SetAttribute("PasrahRoyalPassVisualAssetRefreshCount", refreshed)
	return true
end

function RoyalPassVisualAssetSystem:Shutdown()
	return true
end

return RoyalPassVisualAssetSystem

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolVisualAssetSystem = {}
ToolVisualAssetSystem.__index = ToolVisualAssetSystem

local function parseAssetId(value)
	if type(value) ~= "string" then
		return nil
	end
	return tonumber(value:match("%d+"))
end

local function requireToolVisualConfig()
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local gameData = shared and shared:FindFirstChild("GameData")
	local moduleScript = gameData and gameData:FindFirstChild("ToolVisualConfig")
	if not moduleScript then
		return nil
	end
	local ok, config = pcall(require, moduleScript)
	if ok and type(config) == "table" and type(config.tools) == "table" then
		return config.tools
	end
	return nil
end

local function resolveToolsFolder()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local models = assets and assets:FindFirstChild("Models")
	return models and models:FindFirstChild("Tools")
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

local function loadModelFromAsset(toolName, assetId)
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
	model.Name = toolName
	model:SetAttribute("PasrahSecondAccountModelAssetId", tostring(assetId))
	model:SetAttribute("PasrahToolType", toolName)
	return model, nil
end

local function replaceToolTemplate(toolsFolder, toolName, model)
	local old = toolsFolder:FindFirstChild(toolName)
	local replacement = model:Clone()
	replacement.Name = toolName
	replacement.Parent = toolsFolder
	if old then
		old:Destroy()
	end
end

function ToolVisualAssetSystem.new()
	return setmetatable({}, ToolVisualAssetSystem)
end

function ToolVisualAssetSystem:Init()
	return true
end

function ToolVisualAssetSystem:Start()
	local toolsFolder = resolveToolsFolder()
	local toolConfig = requireToolVisualConfig()
	if not toolsFolder or not toolConfig then
		return true
	end

	local refreshed = 0
	for toolName, config in pairs(toolConfig) do
		local assetId = parseAssetId(type(config) == "table" and config.inventoryModelAssetId or nil)
		if assetId then
			local model, errorMessage = loadModelFromAsset(toolName, assetId)
			if model then
				replaceToolTemplate(toolsFolder, toolName, model)
				model:Destroy()
				refreshed += 1
			else
				warn(string.format("[ToolVisualAssetSystem] Failed to refresh %s from asset %s: %s", tostring(toolName), tostring(assetId), tostring(errorMessage)))
			end
		end
	end

	ReplicatedStorage:SetAttribute("PasrahToolVisualAssetRefreshCount", refreshed)
	return true
end

function ToolVisualAssetSystem:Shutdown()
	return true
end

return ToolVisualAssetSystem

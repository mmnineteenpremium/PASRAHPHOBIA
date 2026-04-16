local inputPath = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\DOCUMENTATION\SOURCE OF TRUTH\PEMBUATAN ASSET MODEL\asset model\HauntedHouse.rbxm]]
local outputPath = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\.codex\hauntedhouse_import.rbxl]]

local roots = remodel.readModelFile(inputPath)
local sourceRoot = assert(roots[1], "Missing root model in HauntedHouse.rbxm")

local function collectByClass(instance, classes, out)
	for _, child in ipairs(instance:GetChildren()) do
		if classes[child.ClassName] then
			table.insert(out, child)
		end
		collectByClass(child, classes, out)
	end
end

local function scrubImportedModel(model)
	model.Name = "HauntedHouse"

	local removable = {}
	collectByClass(model, {
		Script = true,
		LocalScript = true,
		ModuleScript = true,
	}, removable)

	for _, instance in ipairs(removable) do
		instance:Destroy()
	end
end

local importRoot = sourceRoot:Clone()
scrubImportedModel(importRoot)

local place = Instance.new("DataModel")

local replicatedStorage = Instance.new("ReplicatedStorage")
replicatedStorage.Parent = place

local replicatedMaps = Instance.new("Folder")
replicatedMaps.Name = "Maps"
replicatedMaps.Parent = replicatedStorage

local replicatedContainer = Instance.new("Folder")
replicatedContainer.Name = "HauntedHouse"
replicatedContainer.Parent = replicatedMaps

importRoot.Parent = replicatedContainer

local serverStorage = Instance.new("ServerStorage")
serverStorage.Parent = place

local serverMaps = Instance.new("Folder")
serverMaps.Name = "Maps"
serverMaps.Parent = serverStorage

local serverContainer = Instance.new("Folder")
serverContainer.Name = "HauntedHouse"
serverContainer.Parent = serverMaps

importRoot:Clone().Parent = serverContainer

remodel.writePlaceFile(outputPath, place)
print("wrote", outputPath)

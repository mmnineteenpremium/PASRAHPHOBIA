local inputPath = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\DOCUMENTATION\SOURCE OF TRUTH\PEMBUATAN ASSET MODEL\asset model\HauntedHouse.rbxm]]
local outputPath = ...

assert(type(outputPath) == "string" and outputPath ~= "", "Output path argument is required")

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

local importRoot = sourceRoot:Clone()
importRoot.Name = "HauntedHouse"

local removable = {}
collectByClass(importRoot, {
	Script = true,
	LocalScript = true,
	ModuleScript = true,
}, removable)

for _, instance in ipairs(removable) do
	instance:Destroy()
end

remodel.writeModelFile(outputPath, importRoot)
print("wrote", outputPath)

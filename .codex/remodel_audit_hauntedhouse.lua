local inputPath = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\DOCUMENTATION\SOURCE OF TRUTH\PEMBUATAN ASSET MODEL\asset model\HauntedHouse.rbxm]]

local roots = remodel.readModelFile(inputPath)
local root = roots[1]

local classCounts = {}
local scriptHits = {}
local total = 0

local function visit(instance, path)
	total = total + 1
	classCounts[instance.ClassName] = (classCounts[instance.ClassName] or 0) + 1

	if instance.ClassName == "Script" or instance.ClassName == "LocalScript" or instance.ClassName == "ModuleScript" then
		table.insert(scriptHits, path)
	end

	for _, child in ipairs(instance:GetChildren()) do
		visit(child, path .. "." .. child.Name)
	end
end

visit(root, root.Name)

print("rootName", root.Name)
print("totalDescendantsInclusive", total)

local classes = {}
for className, count in pairs(classCounts) do
	table.insert(classes, { className = className, count = count })
end

table.sort(classes, function(a, b)
	if a.count == b.count then
		return a.className < b.className
	end
	return a.count > b.count
end)

for i = 1, math.min(#classes, 20) do
	local item = classes[i]
	print("class", item.className, item.count)
end

print("scriptCount", #scriptHits)
for _, path in ipairs(scriptHits) do
	print("script", path)
end

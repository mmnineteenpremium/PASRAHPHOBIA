local path = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\DOCUMENTATION\SOURCE OF TRUTH\PEMBUATAN ASSET MODEL\asset model\HauntedHouse.rbxm]]

local model = remodel.readModelFile(path)

print("rootType", type(model))
for key, value in pairs(model) do
	print("key", key, type(value))
end

local root = model[1]
if root then
	print("rootClassName", root.ClassName)
	print("rootName", root.Name)
	local children = root:GetChildren()
	print("rootChildCount", #children)
	for i, child in ipairs(children) do
		print("child", i, child.ClassName, child.Name)
	end
end

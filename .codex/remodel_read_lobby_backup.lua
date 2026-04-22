local path = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\PASRAHPHOBIA_lobby_backup.rbxl]]

local place = remodel.readPlaceFile(path)

print("placeClass", place.ClassName)

local function listChildren(parent, label)
	local children = parent:GetChildren()
	print(label .. "_childCount", #children)
	for i, child in ipairs(children) do
		print(label .. "_child", i, child.ClassName, child.Name)
	end
end

listChildren(place, "root")

local workspace = place:FindFirstChild("Workspace")
if workspace then
	listChildren(workspace, "workspace")
	local maps = workspace:FindFirstChild("Maps")
	if maps then
		listChildren(maps, "workspace_maps")
	end
end

local replicatedStorage = place:FindFirstChild("ReplicatedStorage")
if replicatedStorage then
	listChildren(replicatedStorage, "replicated")
	local maps = replicatedStorage:FindFirstChild("Maps")
	if maps then
		listChildren(maps, "replicated_maps")
	end
end

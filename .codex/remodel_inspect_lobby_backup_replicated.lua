local path = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\PASRAHPHOBIA_lobby_backup.rbxl]]

local place = remodel.readPlaceFile(path)
local replicatedStorage = assert(place:FindFirstChild("ReplicatedStorage"), "ReplicatedStorage missing")
local maps = assert(replicatedStorage:FindFirstChild("Maps"), "ReplicatedStorage.Maps missing")
local lobbyContainer = assert(maps:FindFirstChild("LobbySocialHub"), "ReplicatedStorage.Maps.LobbySocialHub missing")

print("containerClass", lobbyContainer.ClassName)
print("containerName", lobbyContainer.Name)

local children = lobbyContainer:GetChildren()
print("childCount", #children)
for i, child in ipairs(children) do
	print("child", i, child.ClassName, child.Name)
	local grandChildren = child:GetChildren()
	print("grandChildCount", child.Name, #grandChildren)
	for j, grandChild in ipairs(grandChildren) do
		print("grandChild", j, grandChild.ClassName, grandChild.Name)
	end
end

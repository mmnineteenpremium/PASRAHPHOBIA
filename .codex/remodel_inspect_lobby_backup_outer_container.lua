local path = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\PASRAHPHOBIA_lobby_backup.rbxl]]

local place = remodel.readPlaceFile(path)
local workspace = assert(place:FindFirstChild("Workspace"), "Workspace missing")
local maps = assert(workspace:FindFirstChild("Maps"), "Workspace.Maps missing")
local lobbyContainer = assert(maps:FindFirstChild("LobbySocialHub"), "Workspace.Maps.LobbySocialHub missing")

print("containerClass", lobbyContainer.ClassName)
print("containerName", lobbyContainer.Name)

local children = lobbyContainer:GetChildren()
print("childCount", #children)
local seen = {}
for i, child in ipairs(children) do
	seen[child.Name] = (seen[child.Name] or 0) + 1
	print("child", i, child.ClassName, child.Name)
end

for name, count in pairs(seen) do
	if count > 1 then
		print("duplicate", name, count)
	end
end

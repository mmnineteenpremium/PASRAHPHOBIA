local path = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\PASRAHPHOBIA_lobby_backup.rbxl]]

local place = remodel.readPlaceFile(path)
local workspace = assert(place:FindFirstChild("Workspace"), "Workspace missing")
local maps = assert(workspace:FindFirstChild("Maps"), "Workspace.Maps missing")
local lobbyContainer = assert(maps:FindFirstChild("LobbySocialHub"), "Workspace.Maps.LobbySocialHub missing")
local lobby = lobbyContainer
if lobbyContainer.ClassName == "Folder" then
	lobby = assert(lobbyContainer:FindFirstChild("LobbySocialHub"), "Nested LobbySocialHub model missing")
end

print("lobbyClass", lobby.ClassName)
print("lobbyName", lobby.Name)

local children = lobby:GetChildren()
print("lobbyChildCount", #children)
for i, child in ipairs(children) do
	print("child", i, child.ClassName, child.Name)
end

local function findDescendant(parent, name)
	if parent.Name == name then
		return parent
	end
	for _, child in ipairs(parent:GetChildren()) do
		local hit = findDescendant(child, name)
		if hit then
			return hit
		end
	end
	return nil
end

for _, targetName in ipairs({
	"SpawnPoints",
	"PlayerSpawn_1",
	"PlayerSpawn_2",
	"PlayerSpawn_3",
	"PlayerSpawn_4",
	"Room_MainHubPlaza",
	"Prop_MainHubPlaza",
	"BoundaryReference",
	"Floor_1_Main",
}) do
	local hit = findDescendant(lobby, targetName)
	if hit then
		local pos = "n/a"
		local size = "n/a"
		local okPos, posValue = pcall(function()
			return hit.Position
		end)
		local okSize, sizeValue = pcall(function()
			return hit.Size
		end)
		if okPos and posValue then
			pos = string.format("%.1f,%.1f,%.1f", posValue.X, posValue.Y, posValue.Z)
		end
		if okSize and sizeValue then
			size = string.format("%.1f,%.1f,%.1f", sizeValue.X, sizeValue.Y, sizeValue.Z)
		end
		print("target", targetName, hit.ClassName, pos, size)
	else
		print("target", targetName, "MISSING")
	end
end

local path = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\PASRAHPHOBIA_lobby_backup.rbxl]]

local place = remodel.readPlaceFile(path)
local workspace = assert(place:FindFirstChild("Workspace"), "Workspace missing")
local maps = assert(workspace:FindFirstChild("Maps"), "Workspace.Maps missing")
local lobbyContainer = assert(maps:FindFirstChild("LobbySocialHub"), "Workspace.Maps.LobbySocialHub missing")
local lobby = lobbyContainer
if lobbyContainer.ClassName == "Folder" then
	lobby = assert(lobbyContainer:FindFirstChild("LobbySocialHub"), "Nested LobbySocialHub model missing")
end

local function walk(instance, pathLabel)
	local seen = {}
	for _, child in ipairs(instance:GetChildren()) do
		local key = child.Name
		seen[key] = (seen[key] or 0) + 1
	end
	for name, count in pairs(seen) do
		if count > 1 then
			print("duplicate", pathLabel, name, count)
		end
	end
	for _, child in ipairs(instance:GetChildren()) do
		walk(child, pathLabel .. "/" .. child.Name)
	end
end

walk(lobby, "LobbySocialHub")

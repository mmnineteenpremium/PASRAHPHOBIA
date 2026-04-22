local inputPath = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\PASRAHPHOBIA_lobby_backup.rbxl]]
local outputPath = ...

assert(type(outputPath) == "string" and outputPath ~= "", "Output path argument is required")

local place = remodel.readPlaceFile(inputPath)
local workspace = assert(place:FindFirstChild("Workspace"), "Workspace missing")
local maps = assert(workspace:FindFirstChild("Maps"), "Workspace.Maps missing")
local lobbyContainer = assert(maps:FindFirstChild("LobbySocialHub"), "Workspace.Maps.LobbySocialHub missing")

local lobbyRoot = lobbyContainer
if lobbyContainer.ClassName == "Folder" then
	lobbyRoot = assert(lobbyContainer:FindFirstChild("LobbySocialHub"), "Nested LobbySocialHub model missing")
end

remodel.writeModelFile(outputPath, lobbyRoot)
print("wrote", outputPath)

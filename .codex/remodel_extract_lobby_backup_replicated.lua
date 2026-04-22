local inputPath = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\PASRAHPHOBIA_lobby_backup.rbxl]]
local outputPath = ...

assert(type(outputPath) == "string" and outputPath ~= "", "Output path argument is required")

local place = remodel.readPlaceFile(inputPath)
local replicatedStorage = assert(place:FindFirstChild("ReplicatedStorage"), "ReplicatedStorage missing")
local maps = assert(replicatedStorage:FindFirstChild("Maps"), "ReplicatedStorage.Maps missing")
local lobbyRoot = assert(maps:FindFirstChild("LobbySocialHub"), "ReplicatedStorage.Maps.LobbySocialHub missing")

remodel.writeModelFile(outputPath, lobbyRoot)
print("wrote", outputPath)

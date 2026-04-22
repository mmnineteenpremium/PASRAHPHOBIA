local path = ...

assert(type(path) == "string" and path ~= "", "Place path argument is required")

local place = remodel.readPlaceFile(path)
local workspace = assert(place:FindFirstChild("Workspace"), "Workspace missing")
local replicatedStorage = assert(place:FindFirstChild("ReplicatedStorage"), "ReplicatedStorage missing")

local function findChild(parent, name)
	local child = parent:FindFirstChild(name)
	assert(child, string.format("Missing %s under %s", name, parent.Name))
	return child
end

local function countDescendants(instance)
	local count = 0
	for _, _ in ipairs(instance:GetDescendants()) do
		count = count + 1
	end
	return count
end

local maps = findChild(workspace, "Maps")
local workspaceLobbyContainer = findChild(maps, "LobbySocialHub")
local workspaceLobby = workspaceLobbyContainer:FindFirstChild("LobbySocialHub") or workspaceLobbyContainer

print("workspaceContainerClass", workspaceLobbyContainer.ClassName)
print("workspaceLobbyClass", workspaceLobby.ClassName)
print("workspaceLobbyName", workspaceLobby.Name)
print("workspaceLobbyChildCount", #workspaceLobby:GetChildren())
print("workspaceLobbyDescendants", countDescendants(workspaceLobby))

for i, child in ipairs(workspaceLobby:GetChildren()) do
	print("workspaceLobbyChild", i, child.ClassName, child.Name, #child:GetChildren(), countDescendants(child))
end

local replicatedMaps = findChild(replicatedStorage, "Maps")
local replicatedLobby = findChild(replicatedMaps, "LobbySocialHub")
print("replicatedLobbyClass", replicatedLobby.ClassName)
print("replicatedLobbyChildCount", #replicatedLobby:GetChildren())
print("replicatedLobbyDescendants", countDescendants(replicatedLobby))

for i, child in ipairs(replicatedLobby:GetChildren()) do
	print("replicatedLobbyChild", i, child.ClassName, child.Name, #child:GetChildren(), countDescendants(child))
end

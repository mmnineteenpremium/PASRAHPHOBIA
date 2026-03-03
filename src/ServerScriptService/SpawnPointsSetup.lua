--!strict

local Workspace = game:GetService("Workspace")

local SpawnPointsSetup = {}

function SpawnPointsSetup.Setup(mapModel: Model)
	assert(mapModel and mapModel:IsA("Model"), "[SpawnPointsSetup] Invalid map model")

	local playerSpawns = {}
	local ghostSpawns = {}

	-- Player spawns
	local spawnFolder = mapModel:FindFirstChild("SpawnPoints")
	if spawnFolder then
		for _, obj in ipairs(spawnFolder:GetChildren()) do
			if obj:IsA("BasePart") then
				table.insert(playerSpawns, obj.CFrame)
			end
		end
	end

	-- Ghost spawns
	local ghostFolder = mapModel:FindFirstChild("GhostSpawnPoints")
	if ghostFolder then
		for _, obj in ipairs(ghostFolder:GetChildren()) do
			if obj:IsA("BasePart") then
				table.insert(ghostSpawns, obj.CFrame)
			end
		end
	end

	return playerSpawns, ghostSpawns
end

return SpawnPointsSetup
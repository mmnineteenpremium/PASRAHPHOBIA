local inputPath = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\.codex\historical\PASRAHPHOBIA_4f1fb1c.rbxlx]]

local roots = remodel.readPlaceFile(inputPath)
local gameRoot = roots[1]

local function findPath(root, path)
	local current = root
	for segment in string.gmatch(path, "[^%.]+") do
		if segment ~= "game" then
			current = current and current:FindFirstChild(segment)
		end
	end
	return current
end

local function countBaseParts(root)
	local count = 0
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant.ClassName == "Part"
			or descendant.ClassName == "MeshPart"
			or descendant.ClassName == "UnionOperation"
			or descendant.ClassName == "SpawnLocation"
			or descendant.ClassName == "WedgePart"
			or descendant.ClassName == "CornerWedgePart"
			or descendant.ClassName == "TrussPart"
		then
			count = count + 1
		end
	end
	return count
end

local targets = {
	"ReplicatedStorage.Maps.HauntedHouse.HauntedHouse",
	"ReplicatedStorage.Maps.StudioMMNineteen.StudioMMNineteen",
	"ReplicatedStorage.Maps.EmptyBuilding.EmptyBuilding",
	"ReplicatedStorage.Maps.AbandonedPalace.AbandonedPalace",
	"ServerStorage.Maps.HauntedHouse.HauntedHouse",
	"ServerStorage.Maps.StudioMMNineteen.StudioMMNineteen",
	"ServerStorage.Maps.EmptyBuilding.EmptyBuilding",
	"ServerStorage.Maps.AbandonedPalace.AbandonedPalace",
}

for _, path in ipairs(targets) do
	local inst = findPath(gameRoot, path)
	if not inst then
		print(path .. " => MISSING")
	else
		print(path .. " => " .. inst.ClassName .. " children=" .. tostring(#inst:GetChildren()) .. " baseparts=" .. tostring(countBaseParts(inst)))
		local folderNames = {
			"SpawnPoints",
			"SafeZones",
			"Doors",
			"GhostSpawns",
			"EvidenceSpawnNodes",
			"Lights",
			"Props",
			"Electronics",
			"Windows",
		}
		for _, folderName in ipairs(folderNames) do
			local folder = inst:FindFirstChild(folderName)
			if folder then
				print("  " .. folderName .. " => " .. folder.ClassName .. " children=" .. tostring(#folder:GetChildren()) .. " baseparts=" .. tostring(countBaseParts(folder)))
			else
				print("  " .. folderName .. " => MISSING")
			end
		end
	end
end

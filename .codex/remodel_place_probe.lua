local ok, placeOrErr = pcall(function()
	return Instance.new("DataModel")
end)

print("dataModelNew", ok, type(placeOrErr))

if ok then
	local place = placeOrErr
	local replicatedStorage = Instance.new("ReplicatedStorage")
	replicatedStorage.Parent = place

	local folder = Instance.new("Folder")
	folder.Name = "ProbeFolder"
	folder.Parent = replicatedStorage

	remodel.writePlaceFile([[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\.codex\probe.rbxlx]], place)
end
print("done")

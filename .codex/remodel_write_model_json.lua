local inputPath = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\DOCUMENTATION\SOURCE OF TRUTH\PEMBUATAN ASSET MODEL\asset model\HauntedHouse.rbxm]]
local outputPath = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\.codex\hauntedhouse_probe.model.json]]

local roots = remodel.readModelFile(inputPath)
remodel.writeModelFile(outputPath, roots[1])
print("wrote", outputPath)

local path = [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\.codex\backup\20260418_lobby_wrong_rbxm\LobbySocialHub.rbxm]]
local model = remodel.readModelFile(path)
local root = model[1]
print('root', root.ClassName, root.Name)
for _, child in ipairs(root:GetChildren()) do
    print('child', child.ClassName, child.Name)
end
print('descendants', #root:GetDescendants())

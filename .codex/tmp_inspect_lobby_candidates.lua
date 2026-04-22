local paths = {
  [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\.codex\lobby_backup_workspace.rbxm]],
  [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\.codex\lobby_backup_replicated.rbxm]],
  [[C:\Projects\ROBLOX\PASRAHPHOBIA\.codex\worktrees\final-source-of-truth\.codex\backup\20260418_lobby_wrong_rbxm\LobbySocialHub.rbxm]],
}
for _, path in ipairs(paths) do
  print('PATH', path)
  local ok, model = pcall(remodel.readModelFile, path)
  if not ok then
    print('read_error', model)
  else
    local root = model[1]
    print('root', root.ClassName, root.Name)
    local children = root:GetChildren()
    print('childCount', #children)
    for i, child in ipairs(children) do
      if i > 20 then break end
      print('child', i, child.ClassName, child.Name)
    end
    print('descendants', #root:GetDescendants())
  end
end

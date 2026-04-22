local path = [[C:\Projects\ROBLOX\PASRAHPHOBIA\PEMBUATAN ASSET MODEL\asset model\Property LobbySocialHub.rbxm]]
local model = remodel.readModelFile(path)
local root = model[1]
local function walk(node, depth)
    if depth > 3 then return end
    local indent = string.rep('  ', depth)
    print(indent .. node.ClassName .. ' ' .. node.Name)
    local children = node:GetChildren()
    table.sort(children, function(a,b) return a.Name < b.Name end)
    for _, child in ipairs(children) do
        walk(child, depth + 1)
    end
end
walk(root, 0)
print('descendants', #root:GetDescendants())

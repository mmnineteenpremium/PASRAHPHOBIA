local path = [[C:\Projects\ROBLOX\PASRAHPHOBIA\PEMBUATAN ASSET MODEL\asset model\Property LobbySocialHub.rbxm]]
local model = remodel.readModelFile(path)
local root = model[1]
local names = {}
for _, inst in ipairs(root:GetDescendants()) do
    local n = tostring(inst.Name or '')
    if n ~= '' and (#names < 120) then
        if n:find('Store') or n:find('Shop') or n:find('Sign') or n:find('Terminal') or n:find('Door') or n:find('Spawn') or n:find('Room') then
            table.insert(names, inst.ClassName .. ' ' .. n)
        end
    end
end
for _, line in ipairs(names) do print(line) end

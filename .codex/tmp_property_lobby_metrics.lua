local path = [[C:\Projects\ROBLOX\PASRAHPHOBIA\PEMBUATAN ASSET MODEL\asset model\Property LobbySocialHub.rbxm]]
local model = remodel.readModelFile(path)
local root = model[1]
local basePartClasses = {
  Part=true, MeshPart=true, WedgePart=true, CornerWedgePart=true,
  UnionOperation=true, TrussPart=true, SpawnLocation=true, Seat=true, VehicleSeat=true
}
local minX,minY,minZ = math.huge, math.huge, math.huge
local maxX,maxY,maxZ = -math.huge, -math.huge, -math.huge
local partCount, lightCount, decalCount, textureCount, spawnLike, roomLike = 0,0,0,0,0,0
for _, inst in ipairs(root:GetDescendants()) do
  local name = inst.Name or ''
  local className = inst.ClassName or ''
  if basePartClasses[className] then
    local okP, p = pcall(function() return inst.Position end)
    local okS, s = pcall(function() return inst.Size end)
    if okP and okS then
      partCount = partCount + 1
      minX = math.min(minX, p.X - s.X/2)
      minY = math.min(minY, p.Y - s.Y/2)
      minZ = math.min(minZ, p.Z - s.Z/2)
      maxX = math.max(maxX, p.X + s.X/2)
      maxY = math.max(maxY, p.Y + s.Y/2)
      maxZ = math.max(maxZ, p.Z + s.Z/2)
      local lower = string.lower(name)
      if string.find(lower, 'spawn', 1, true) then spawnLike = spawnLike + 1 end
      if string.find(lower, 'room', 1, true) then roomLike = roomLike + 1 end
    end
  elseif string.find(className, 'Light', 1, true) then
    lightCount = lightCount + 1
  elseif className == 'Decal' then
    decalCount = decalCount + 1
  elseif className == 'Texture' then
    textureCount = textureCount + 1
  end
end
print('partCount', partCount)
print('lightCount', lightCount)
print('decalCount', decalCount)
print('textureCount', textureCount)
print('boundsMin', minX, minY, minZ)
print('boundsMax', maxX, maxY, maxZ)
print('size', maxX-minX, maxY-minY, maxZ-minZ)
print('spawnLikeCount', spawnLike)
print('roomLikeCount', roomLike)

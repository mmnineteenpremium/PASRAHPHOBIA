local path = ...

assert(type(path) == "string" and path ~= "", "Path argument is required")

local model = remodel.readModelFile(path)
local root = model[1]
assert(root, "No root instance found")

local function countDescendants(instance)
	local count = 0
	for _, child in ipairs(instance:GetDescendants()) do
		count = count + 1
	end
	return count
end

print("rootClass", root.ClassName)
print("rootName", root.Name)
print("rootChildren", #root:GetChildren())
print("rootDescendants", countDescendants(root))

for i, child in ipairs(root:GetChildren()) do
	print("child", i, child.ClassName, child.Name, #child:GetChildren(), countDescendants(child))
end

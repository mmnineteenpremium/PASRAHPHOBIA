local main = script:FindFirstChild("Main") or script.Parent:FindFirstChild("Main")
assert(main and main:IsA("ModuleScript"), "Missing Main module for " .. script.Name)
return require(main)

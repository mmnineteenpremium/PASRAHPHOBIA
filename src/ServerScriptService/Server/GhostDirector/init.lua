local main = script.Parent:FindFirstChild("Main")
assert(main, "Missing Main module")
return require(main)

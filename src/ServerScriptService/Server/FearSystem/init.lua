local main = script:FindFirstChild("Main") or script.Parent:FindFirstChild("Main")
assert(main, "Missing Main module")
return require(main)

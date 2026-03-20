local mainModule = script.Parent:FindFirstChild("Main")
if mainModule and mainModule:IsA("ModuleScript") then
    return require(mainModule)
end
error("Missing Main module in " .. script.Parent.Name)

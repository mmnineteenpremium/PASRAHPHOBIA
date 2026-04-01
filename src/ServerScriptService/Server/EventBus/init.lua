local mainModule = script:FindFirstChild("Main") or script.Parent:FindFirstChild("Main")
if mainModule and mainModule:IsA("ModuleScript") then
    return require(mainModule)
end
error("Missing Main module for " .. script.Name)

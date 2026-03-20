local mainModule = script:FindFirstChild("Main")
if mainModule then
    return require(mainModule)
end
return {}

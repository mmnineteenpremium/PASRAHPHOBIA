local function safeRequire(moduleScript)
    if not moduleScript then
        return nil
    end
    local ok, result = pcall(require, moduleScript)
    if ok then
        return result
    end
    return nil
end

local function resolveMapsFolder()
    if script.Parent == nil then
        return nil
    end
    local localFolder = script.Parent:FindFirstChild("Maps")
    if localFolder then
        return localFolder
    end
    local success, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if success and replicatedStorage then
        local shared = replicatedStorage:FindFirstChild("Shared") or replicatedStorage:FindFirstChild("shared")
        if shared then
            local gameData = shared:FindFirstChild("GameData")
            if gameData then
                return gameData:FindFirstChild("Maps")
            end
        end
    end
    return nil
end

local function buildDatabase()
    local folder = resolveMapsFolder()
    if not folder then
        return {}
    end
    local out = {}
    for _, moduleScript in ipairs(folder:GetChildren()) do
        if moduleScript:IsA("ModuleScript") then
            local value = safeRequire(moduleScript)
            if type(value) == "table" then
                out[moduleScript.Name] = value
            end
        end
    end
    return out
end

return buildDatabase()

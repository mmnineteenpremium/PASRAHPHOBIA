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

local function resolveGhostsFolder()
    local folder = script.Parent:FindFirstChild("Ghosts")
    if folder then
        return folder
    end
    return nil
end

local function buildDatabase()
    local folder = resolveGhostsFolder()
    if not folder then
        return {}
    end
    local out = {}
    for _, child in ipairs(folder:GetChildren()) do
        if child:IsA("ModuleScript") then
            local moduleData = safeRequire(child)
            if type(moduleData) == "table" then
                local ghostKey = moduleData.ghostName or child.Name
                out[ghostKey] = moduleData
            end
        end
    end
    return out
end

return buildDatabase()

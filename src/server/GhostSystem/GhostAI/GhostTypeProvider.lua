local GhostTypeProvider = {}
GhostTypeProvider.__index = GhostTypeProvider

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

function GhostTypeProvider.new(deps)
    local self = setmetatable({}, GhostTypeProvider)
    self._deps = deps or {}
    return self
end

function GhostTypeProvider:ResolveGhostTypes()
    if type(self._deps.GhostTypes) == "table" then
        return self._deps.GhostTypes
    end

    local sharedDataTypes = self._deps.SharedDataTypes
    if type(sharedDataTypes) == "table" and type(sharedDataTypes.GhostTypes) == "table" then
        return sharedDataTypes.GhostTypes
    end

    local moduleScript = self._deps.GhostTypesModule
    local resolved = safeRequire(moduleScript)
    if type(resolved) == "table" then
        return resolved
    end

    return {}
end

return GhostTypeProvider

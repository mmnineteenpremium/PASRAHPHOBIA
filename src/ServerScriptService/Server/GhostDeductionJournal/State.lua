local State = {}
State.__index = State

local function loadGhostEvidenceMap()
    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if not ok or typeof(replicatedStorage) ~= "Instance" then
        return {}
    end

    local shared = replicatedStorage:FindFirstChild("Shared") or replicatedStorage:FindFirstChild("shared")
    local dataTypes = shared and shared:FindFirstChild("DataTypes")
    local evidence = dataTypes and dataTypes:FindFirstChild("Evidence")
    local mapFolder = evidence and evidence:FindFirstChild("EvidenceGhostMap")
    local moduleScript = mapFolder and mapFolder:FindFirstChild("ModuleScript")
    if not moduleScript or not moduleScript:IsA("ModuleScript") then
        return {}
    end

    local loaded, map = pcall(require, moduleScript)
    if not loaded or type(map) ~= "table" then
        return {}
    end
    return map
end

local DEFAULT_STATE = {
    playerJournalData = {},
    ghostCandidatesByPlayer = {},
    activeMatchId = nil,
    ghostEvidenceMap = loadGhostEvidenceMap(),
}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for key, nested in pairs(value) do
        out[key] = deepCopy(nested)
    end
    return out
end

function State.new()
    local self = setmetatable({}, State)
    self._data = deepCopy(DEFAULT_STATE)
    return self
end

function State:Get(key)
    return self._data[key]
end

function State:Set(key, value)
    self._data[key] = value
end

function State:Clear()
    self._data = deepCopy(DEFAULT_STATE)
end

return State

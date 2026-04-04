local State = {}
State.__index = State

function State.new(initial)
    local self = setmetatable({}, State)
    self._data = {
        dataStoreName = initial and initial.dataStoreName or "InventorySystemStore",
        autosaveIntervalSeconds = initial and initial.autosaveIntervalSeconds or 60,
        allowStudioDataStore = initial and initial.allowStudioDataStore or false,
        profileSchemaVersion = initial and initial.profileSchemaVersion or 2,
    }
    for key, value in pairs(initial or {}) do
        self._data[key] = value
    end
    return self
end

function State:Get(key)
    return self._data[key]
end

function State:Set(key, value)
    self._data[key] = value
end

return State

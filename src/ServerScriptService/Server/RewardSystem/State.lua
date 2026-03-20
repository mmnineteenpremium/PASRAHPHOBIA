local State = {}
State.__index = State

function State.new(initial)
    local self = setmetatable({}, State)
    self._data = {
        processedMatchIds = initial and initial.processedMatchIds or {},
        processedContractKeys = initial and initial.processedContractKeys or {},
        processedMissionKeys = initial and initial.processedMissionKeys or {},
    }
    return self
end

function State:Get(key)
    return self._data[key]
end

function State:Set(key, value)
    self._data[key] = value
end

function State:Clear()
    table.clear(self._data)
end

return State

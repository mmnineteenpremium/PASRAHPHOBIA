local State = {}
State.__index = State

function State.new(initial)
    local self = setmetatable({}, State)
    self._data = {
        violationsByUserId = initial and initial.violationsByUserId or {},
        violationScoreByUserId = initial and initial.violationScoreByUserId or {},
        remoteCallsByUserId = initial and initial.remoteCallsByUserId or {},
        matchParticipationByUserId = initial and initial.matchParticipationByUserId or {},
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

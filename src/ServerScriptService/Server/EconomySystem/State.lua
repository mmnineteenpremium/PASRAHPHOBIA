local State = {}
State.__index = State

function State.new()

    local self = setmetatable({}, State)

    self._data = {}

    return self
end


function State:RegisterKey(key, defaultValue)

    if type(key) ~= "string" then
        error("RegisterKey key must be string")
    end

    local value = defaultValue

    if type(defaultValue) == "function" then
        value = defaultValue()
    end

    if type(value) ~= "number" then
        value = 0
    end

    if self._data[key] == nil then
        self._data[key] = value
    end

    return self._data[key]

end


function State:Get(key)

    return self._data[key]

end


function State:Set(key, value)

    self._data[key] = value

end


return State

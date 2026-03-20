local Service = {}
Service.__index = Service

local MAX_EVENTS_PER_DRAIN = 2000

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._queue = {}
    self._queueHead = 1
    self._queueTail = 0
    self._dispatching = false
    return self
end

function Service:Init()
    self._state:Set('subscribers', {})
    self._queue = {}
    self._queueHead = 1
    self._queueTail = 0
    self._dispatching = false
end

function Service:Start()
    -- EventBus is ready once initialized.
end

function Service:Stop()
    self._state:Clear()
    self._queue = {}
    self._queueHead = 1
    self._queueTail = 0
    self._dispatching = false
end

function Service:_enqueue(eventName, payload)
    self._queueTail += 1
    self._queue[self._queueTail] = {
        eventName = eventName,
        payload = payload,
    }
end

function Service:_dequeue()
    if self._queueHead > self._queueTail then
        return nil
    end
    local entry = self._queue[self._queueHead]
    self._queue[self._queueHead] = nil
    self._queueHead += 1
    return entry
end

function Service:Publish(eventName, payload)
    if type(eventName) ~= "string" or eventName == "" then
        return
    end

    self:_enqueue(eventName, payload)
    if self._dispatching then
        return
    end

    self._dispatching = true
    local processed = 0
    while self._dispatching do
        local entry = self:_dequeue()
        if not entry then
            break
        end

        processed += 1
        if processed > MAX_EVENTS_PER_DRAIN then
            warn(string.format("[EventBus] Dropping queued events after %d dispatches. Last event: %s", MAX_EVENTS_PER_DRAIN, tostring(entry.eventName)))
            self._queue = {}
            self._queueHead = 1
            self._queueTail = 0
            break
        end

        local subscribers = self._state:Get('subscribers') or {}
        local callbacks = subscribers[entry.eventName]
        if callbacks then
            local callbackList = {}
            for callback in pairs(callbacks) do
                table.insert(callbackList, callback)
            end
            for _, callback in ipairs(callbackList) do
                local ok, err = pcall(callback, entry.payload)
                if not ok then
                    warn(string.format("[EventBus] Callback error for event '%s': %s", entry.eventName, tostring(err)))
                end
            end
        end
    end
    if self._queueHead > self._queueTail then
        self._queue = {}
        self._queueHead = 1
        self._queueTail = 0
    end
    self._dispatching = false
end

function Service:Subscribe(eventName, callback)
    if type(eventName) ~= "string" or eventName == "" or type(callback) ~= "function" then
        return
    end
    local subscribers = self._state:Get('subscribers') or {}
    subscribers[eventName] = subscribers[eventName] or {}
    subscribers[eventName][callback] = true
    self._state:Set('subscribers', subscribers)
end

function Service:Unsubscribe(eventName, callback)
    if type(eventName) ~= "string" or eventName == "" or type(callback) ~= "function" then
        return
    end
    local subscribers = self._state:Get('subscribers') or {}
    local callbacks = subscribers[eventName]
    if not callbacks then
        return
    end

    callbacks[callback] = nil
    if next(callbacks) == nil then
        subscribers[eventName] = nil
    end

    self._state:Set('subscribers', subscribers)
end

return Service

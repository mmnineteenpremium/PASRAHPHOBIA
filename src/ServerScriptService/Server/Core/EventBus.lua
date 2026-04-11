-- EventBus.lua
-- PASRAHPHOBIA Core Infrastructure
-- DO NOT MODIFY without understanding full dependency chain
-- Tier 1 System - all systems depend on this contract

local EventBus = {}

EventBus._listeners = {}
EventBus._onceListeners = {}
EventBus._eventLog = {}
EventBus._nextListenerId = 0
EventBus.DEBUG_MODE = false

EventBus.EVENTS = {
    -- Match lifecycle
    MATCH_STARTED = "MatchStarted",
    MATCH_ENDED = "MatchEnded",
    HUNT_TRIGGERED = "HuntTriggered",
    HUNT_ENDED = "HuntEnded",
    RESULTS_CALCULATED = "ResultsCalculated",

    -- Player
    PLAYER_DIED = "PlayerDied",
    PLAYER_SANITY_CHANGED = "PlayerSanityChanged",
    CURRENCY_EARNED = "CurrencyEarned",
    REWARD_GRANTED = "RewardGranted",

    -- Evidence
    EVIDENCE_COLLECTED = "EvidenceCollected",

    -- Ghost
    GHOST_SPAWNED = "GhostSpawned",

    -- Economy
    ECONOMY_GRANT = "EconomyGrant",
    PROGRESSION_GRANT = "ProgressionGrant",
    RANK_UPDATE = "RankUpdate",
    DATA_SAVE_REQUEST = "DataSaveRequest",
}

local KNOWN_EVENT_LOOKUP = {}
for _, eventName in pairs(EventBus.EVENTS) do
    KNOWN_EVENT_LOOKUP[eventName] = true
end

local function assertEventName(methodName, eventName)
    assert(type(eventName) == "string" and eventName ~= "", string.format("EventBus:%s - eventName must be a non-empty string", methodName))
end

local function ensureBucket(container, eventName)
    local bucket = container[eventName]
    if not bucket then
        bucket = {}
        container[eventName] = bucket
    end
    return bucket
end

local function cloneArray(source)
    local clone = {}
    for index, value in ipairs(source or {}) do
        clone[index] = value
    end
    return clone
end

local function removeMatchingListener(listeners, matcher)
    if type(listeners) ~= "table" then
        return false
    end

    local removed = false
    for index = #listeners, 1, -1 do
        if matcher(listeners[index]) then
            table.remove(listeners, index)
            removed = true
        end
    end
    return removed
end

function EventBus:IsKnownEvent(eventName)
    return KNOWN_EVENT_LOOKUP[eventName] == true
end

function EventBus:SetDebugMode(enabled)
    self.DEBUG_MODE = enabled == true
end

function EventBus:_nextId(eventName)
    self._nextListenerId += 1
    return string.format("%s_%d", tostring(eventName), self._nextListenerId)
end

function EventBus:Subscribe(eventName, callback, tag)
    assertEventName("Subscribe", eventName)
    assert(type(callback) == "function", "EventBus:Subscribe - callback must be a function")

    local listener = {
        id = self:_nextId(eventName),
        callback = callback,
        tag = type(tag) == "string" and tag ~= "" and tag or "untagged",
    }

    table.insert(ensureBucket(self._listeners, eventName), listener)

    if self.DEBUG_MODE then
        print(string.format("[EventBus] Subscribed: %s | tag=%s | id=%s", eventName, listener.tag, listener.id))
    end

    return listener.id
end

function EventBus:SubscribeOnce(eventName, callback, tag)
    assertEventName("SubscribeOnce", eventName)
    assert(type(callback) == "function", "EventBus:SubscribeOnce - callback must be a function")

    local listener = {
        id = self:_nextId(eventName),
        callback = callback,
        tag = type(tag) == "string" and tag ~= "" and tag or "once_untagged",
    }

    table.insert(ensureBucket(self._onceListeners, eventName), listener)

    if self.DEBUG_MODE then
        print(string.format("[EventBus] Subscribed once: %s | tag=%s | id=%s", eventName, listener.tag, listener.id))
    end

    return listener.id
end

function EventBus:Unsubscribe(eventName, listenerIdOrCallback)
    assertEventName("Unsubscribe", eventName)

    if listenerIdOrCallback == nil then
        return false
    end

    local matcher
    if type(listenerIdOrCallback) == "function" then
        matcher = function(listener)
            return listener.callback == listenerIdOrCallback
        end
    else
        matcher = function(listener)
            return listener.id == listenerIdOrCallback
        end
    end

    local removedRegular = removeMatchingListener(self._listeners[eventName], matcher)
    local removedOnce = removeMatchingListener(self._onceListeners[eventName], matcher)
    local removed = removedRegular or removedOnce

    if removed and self.DEBUG_MODE then
        print(string.format("[EventBus] Unsubscribed: %s", eventName))
    end

    return removed
end

function EventBus:Publish(eventName, payload)
    assertEventName("Publish", eventName)

    if self.DEBUG_MODE and not self:IsKnownEvent(eventName) then
        warn(string.format("[EventBus] Publishing non-canonical event '%s'", eventName))
    end

    table.insert(self._eventLog, {
        event = eventName,
        timestamp = os.clock(),
        payload = payload,
    })
    if #self._eventLog > 200 then
        table.remove(self._eventLog, 1)
    end

    if self.DEBUG_MODE then
        print(string.format("[EventBus] Published: %s", eventName))
    end

    for _, listener in ipairs(cloneArray(self._listeners[eventName])) do
        local ok, err = pcall(listener.callback, payload)
        if not ok then
            warn(string.format("[EventBus] ERROR in listener '%s' for event '%s': %s", listener.tag, eventName, tostring(err)))
        end
    end

    local toFire = cloneArray(self._onceListeners[eventName])
    self._onceListeners[eventName] = nil
    for _, listener in ipairs(toFire) do
        local ok, err = pcall(listener.callback, payload)
        if not ok then
            warn(string.format("[EventBus] ERROR in once-listener '%s' for event '%s': %s", listener.tag, eventName, tostring(err)))
        end
    end
end

function EventBus:GetListenerReport()
    local report = {}

    for eventName, listeners in pairs(self._listeners) do
        report[eventName] = (report[eventName] or 0) + #listeners
    end

    for eventName, listeners in pairs(self._onceListeners) do
        report[eventName] = (report[eventName] or 0) + #listeners
    end

    return report
end

function EventBus:GetRecentLog(count)
    count = math.max(1, math.floor(tonumber(count) or 20))

    local log = {}
    local startIndex = math.max(1, #self._eventLog - count + 1)
    for index = startIndex, #self._eventLog do
        table.insert(log, self._eventLog[index])
    end
    return log
end

function EventBus:Reset()
    table.clear(self._listeners)
    table.clear(self._onceListeners)
    table.clear(self._eventLog)
    self._nextListenerId = 0
end

function EventBus.emit(eventName, payload)
    return EventBus:Publish(eventName, payload)
end

function EventBus.publish(eventName, payload)
    return EventBus:Publish(eventName, payload)
end

function EventBus.subscribe(eventName, callback, tag)
    return EventBus:Subscribe(eventName, callback, tag)
end

function EventBus.subscribeOnce(eventName, callback, tag)
    return EventBus:SubscribeOnce(eventName, callback, tag)
end

function EventBus.unsubscribe(eventName, listenerIdOrCallback)
    return EventBus:Unsubscribe(eventName, listenerIdOrCallback)
end

return EventBus

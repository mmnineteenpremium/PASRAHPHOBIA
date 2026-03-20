local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local function resolveEventBus(deps)
	local eventBus = Services.Get(deps, "EventBus")
	if type(eventBus) ~= "table" then
		return nil
	end
	if type(eventBus.Publish) == "function" then
		return eventBus
	end
	if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then
		return eventBus.Service
	end
	return nil
end

local function trimHistory(list, limit)
	while #list > limit do
		table.remove(list, 1)
	end
end

function Service.new(state, deps)
	local self = setmetatable({}, Service)
	self._state = state
	self._deps = deps or {}
	self._eventBus = nil
	self._dependencies = {}
	self._maxErrorLogs = 250
	return self
end

function Service:Create()
	self._eventBus = resolveEventBus(self._deps)
	self._dependencies = {
		MatchSystem = Services.Get(self._deps, "MatchSystem"),
		ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
		DataPersistenceService = Services.Get(self._deps, "DataPersistenceService"),
		LobbySocialHub = Services.Get(self._deps, "LobbySocialHub"),
	}
end

function Service:Init()
	self._state:Set("errorLogs", self._state:Get("errorLogs") or {})
	self._state:Set("errorCounters", self._state:Get("errorCounters") or {})
	self._state:Set("systemContext", self._state:Get("systemContext") or {})
end

function Service:Start()
	-- Event-driven.
end

function Service:Stop()
	self._state:Clear()
end

function Service:_publish(eventName, payload)
	if self._eventBus then
		self._eventBus:Publish(eventName, payload)
	end
end

function Service:SetContext(key, value)
	local context = self._state:Get("systemContext") or {}
	context[key] = value
	self._state:Set("systemContext", context)
end

function Service:CaptureError(sourceSystem, message, stackTrace, extraContext)
	local systemName = sourceSystem or "UnknownSystem"
	local errorMessage = tostring(message or "Unknown error")

	local counters = self._state:Get("errorCounters") or {}
	counters[systemName] = (counters[systemName] or 0) + 1
	self._state:Set("errorCounters", counters)

	local logs = self._state:Get("errorLogs") or {}
	local record = {
		system = systemName,
		message = errorMessage,
		stackTrace = stackTrace,
		context = extraContext,
		at = os.time(),
	}
	table.insert(logs, record)
	trimHistory(logs, self._maxErrorLogs)
	self._state:Set("errorLogs", logs)

	self:_publish("SystemErrorDetected", {
		system = systemName,
		message = errorMessage,
		stackTrace = stackTrace,
		context = extraContext,
		count = counters[systemName],
	})

	self:_publish("ErrorReportGenerated", {
		system = systemName,
		totalForSystem = counters[systemName],
		lastErrorAt = record.at,
	})
end

function Service:MonitorCall(sourceSystem, fn, ...)
	if type(fn) ~= "function" then
		self:CaptureError(sourceSystem, "MonitorCall expected function", debug.traceback(), nil)
		return false
	end
	local args = { ... }
	local ok, resultOrError = xpcall(function()
		return fn(unpack(args))
	end, function(err)
		return err .. "\n" .. debug.traceback()
	end)
	if not ok then
		self:CaptureError(sourceSystem, resultOrError, debug.traceback(), nil)
		return false, resultOrError
	end
	return true, resultOrError
end

function Service:OnSystemException(payload)
	payload = payload or {}
	self:CaptureError(
		payload.system,
		payload.message or payload.error,
		payload.stackTrace,
		payload.context
	)
end

function Service:OnServiceFailure(payload)
	payload = payload or {}
	self:CaptureError(
		payload.serviceName or payload.system,
		payload.reason or payload.message,
		payload.stackTrace,
		payload.context
	)
end

return Service

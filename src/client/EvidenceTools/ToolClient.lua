local ToolClient = {}
ToolClient.__index = ToolClient

function ToolClient.new(evidenceTools, toolType, defaults)
	local self = setmetatable({}, ToolClient)
	self._evidenceTools = evidenceTools
	self._toolType = toolType
	self._defaults = defaults or {}
	return self
end

local function merge(defaults, payload)
	local out = {}
	for key, value in pairs(defaults or {}) do
		out[key] = value
	end
	for key, value in pairs(payload or {}) do
		out[key] = value
	end
	return out
end

function ToolClient:Use(payload)
	local requestPayload = merge(self._defaults, payload)
	requestPayload.toolType = self._toolType
	return self._evidenceTools:_requestTool(self._toolType, requestPayload)
end

return ToolClient

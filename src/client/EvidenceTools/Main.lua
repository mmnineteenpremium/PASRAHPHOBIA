local EvidenceTools = {}
EvidenceTools.__index = EvidenceTools

local ToolModules = {
	JejakEnergi = require(script.Parent.JejakEnergi.Main),
	KotakArwah = require(script.Parent.KotakArwah.Main),
	SuhuMembeku = require(script.Parent.SuhuMembeku.Main),
	BukuTerkutuk = require(script.Parent.BukuTerkutuk.Main),
	BolaArwah = require(script.Parent.BolaArwah.Main),
	GerakanGaib = require(script.Parent.GerakanGaib.Main),
}

function EvidenceTools:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._evidenceEvent = self._remotes.EvidenceEvent
	self._connections = {}
	self._toolStates = {}
	self._requestCounter = 0
	self._toolAdapters = {}

	for toolType in pairs(ToolModules) do
		self._toolStates[toolType] = {
			lastFeedback = nil,
			lastUsedAt = 0,
			lastReason = nil,
			cooldownUntil = 0,
		}
		self._toolAdapters[toolType] = ToolModules[toolType].new(self, toolType)
	end
end

function EvidenceTools:Start()
	if self._evidenceEvent and self._evidenceEvent.OnClientEvent then
		table.insert(self._connections, self._evidenceEvent.OnClientEvent:Connect(function(payload)
			self:_onEvidenceEvent(payload)
		end))
	end
end

function EvidenceTools:Stop()
	for _, connection in ipairs(self._connections or {}) do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

function EvidenceTools:_onEvidenceEvent(payload)
	local eventName = payload and payload.eventName
	local toolType = payload and (payload.toolType or payload.evidenceType)
	if not eventName or not toolType or not self._toolStates[toolType] then
		return
	end
	self._toolStates[toolType].lastFeedback = payload
	self._toolStates[toolType].lastReason = payload.reason
	self._toolStates[toolType].lastUsedAt = os.clock()
	if payload.success == false then
		self._toolStates[toolType].cooldownUntil = os.clock() + 0.25
	end
end

function EvidenceTools:_requestTool(toolType, payload)
	if not self._toolStates[toolType] then
		return false, "invalid_tool"
	end
	if not self._evidenceEvent or not self._evidenceEvent.FireServer then
		return false, "missing_remote"
	end
	local now = os.clock()
	if now < (self._toolStates[toolType].cooldownUntil or 0) then
		return false, "tool_local_cooldown"
	end

	self._requestCounter += 1
	self._toolStates[toolType].lastUsedAt = now
	self._evidenceEvent:FireServer({
		action = "UseEvidenceTool",
		requestId = tostring(self._requestCounter),
		toolType = toolType,
		payload = payload or {},
	})
	return true
end

function EvidenceTools:UseTool(toolType, payload)
	local adapter = self._toolAdapters[toolType]
	if not adapter then
		return false, "invalid_tool"
	end
	return adapter:Use(payload)
end

function EvidenceTools:GetToolState(toolType)
	return self._toolStates[toolType]
end

return setmetatable({}, EvidenceTools)

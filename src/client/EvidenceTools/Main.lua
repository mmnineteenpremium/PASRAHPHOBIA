local EvidenceTools = {}
EvidenceTools.__index = EvidenceTools

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TOOL_REQUEST_TYPES = {
	JejakEnergi = "JejakEnergiScan",
	KotakArwah = "KotakArwahQuestion",
	SuhuMembeku = "SuhuReading",
	BukuTerkutuk = "BukuTerkutukCheck",
	BolaArwah = "TounDetection",
	GerakanGaib = "PenggangguCheck",
	Garam = "SaltPlacement",
	Salib = "CrucifixPlacement",
	Dupa = "SmudgeIgnite",
}

local ToolModules = {
	JejakEnergi = require(script.Parent.JejakEnergi.Main),
	KotakArwah = require(script.Parent.KotakArwah.Main),
	SuhuMembeku = require(script.Parent.SuhuMembeku.Main),
	BukuTerkutuk = require(script.Parent.BukuTerkutuk.Main),
	BolaArwah = require(script.Parent.BolaArwah.Main),
	GerakanGaib = require(script.Parent.GerakanGaib.Main),
	Garam = require(script.Parent.Garam.Main),
	Salib = require(script.Parent.Salib.Main),
	Dupa = require(script.Parent.Dupa.Main),
}

function EvidenceTools:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._evidenceEvent = self._remotes.EvidenceEvent
	self._evidenceRequest = self._remotes.EvidenceRequest
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
	self:_ensureEvidenceRequest()
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
	self:_ensureEvidenceRequest()
	if not self._evidenceRequest or not self._evidenceRequest.InvokeServer then
		return false, "missing_remote_function"
	end
	local now = os.clock()
	if now < (self._toolStates[toolType].cooldownUntil or 0) then
		return false, "tool_local_cooldown"
	end

	self._requestCounter += 1
	self._toolStates[toolType].lastUsedAt = now
	local okInvoke, response = pcall(function()
		return self._evidenceRequest:InvokeServer({
			requestType = TOOL_REQUEST_TYPES[toolType] or "ToolScan",
			requestId = tostring(self._requestCounter),
			toolType = toolType,
			payload = payload or {},
		})
	end)
	if not okInvoke then
		self._toolStates[toolType].lastReason = "invoke_failed"
		self._toolStates[toolType].cooldownUntil = os.clock() + 0.25
		return false, "invoke_failed"
	end
	if type(response) == "table" then
		self._toolStates[toolType].lastFeedback = response
		self._toolStates[toolType].lastReason = response.reason
		if response.success == false then
			self._toolStates[toolType].cooldownUntil = os.clock() + 0.25
		end
		return response.success == true, response.reason, response
	end
	return false, "invalid_gateway_response"
end

function EvidenceTools:_ensureEvidenceRequest()
	if self._evidenceRequest and self._evidenceRequest:IsA("RemoteFunction") then
		return self._evidenceRequest
	end
	local remoteFunctions = ReplicatedStorage:FindFirstChild("RemoteFunctions")
	self._evidenceRequest = remoteFunctions and remoteFunctions:FindFirstChild("EvidenceRequest") or nil
	return self._evidenceRequest
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

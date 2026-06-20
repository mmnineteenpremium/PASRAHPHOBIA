local EvidenceTools = {}
EvidenceTools.__index = EvidenceTools

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local TOOL_EQUIPPED_ATTRIBUTE = "PasrahEquippedToolType"
local TOOL_USE_STAMP_ATTRIBUTE = "PasrahToolUseStamp"
local TOOL_LAST_EVENT_ATTRIBUTE = "PasrahToolLastEvent"
local TOOL_LAST_SUCCESS_ATTRIBUTE = "PasrahToolLastSuccess"
local USE_NATIVE_BACKPACK_TOOLS = false

local TOOL_REQUEST_TYPES = {
	JejakEnergi = "JejakEnergiScan",
	KotakArwah = "KotakArwahQuestion",
	SuhuMembeku = "SuhuReading",
	BukuTerkutuk = "BukuTerkutukCheck",
	BolaArwah = "TounDetection",
	GerakanGaib = "PenggangguCheck",
	Garam = "SaltPlacement",
	PilSanity = "SanityPillUse",
	Salib = "CrucifixPlacement",
	Dupa = "SmudgeIgnite",
}
local NATIVE_TOOL_ORDER = {
	"JejakEnergi",
	"Garam",
	"Salib",
	"Dupa",
	"KotakArwah",
	"SuhuMembeku",
	"BukuTerkutuk",
	"BolaArwah",
	"GerakanGaib",
	"PilSanity",
}
local NATIVE_TOOL_LABELS = {
	JejakEnergi = "EMF Scanner",
	Garam = "Garam",
	Salib = "Salib",
	Dupa = "Dupa",
	KotakArwah = "Spirit Box",
	SuhuMembeku = "Thermometer",
	BukuTerkutuk = "Ghost Writing",
	BolaArwah = "Kamera TOUN",
	GerakanGaib = "Motion Sensor",
	PilSanity = "Pil Sanity",
}

local CAMERA_SCAN_GHOST_ATTR = "PasrahCameraScanGhostType"
local CAMERA_SCAN_CANDIDATES_ATTR = "PasrahCameraScanCandidates"
local CAMERA_SCAN_EVIDENCE_ATTR = "PasrahCameraScanEvidence"
local CAMERA_SCAN_REASON_ATTR = "PasrahCameraScanReason"
local CAMERA_SCAN_STAMP_ATTR = "PasrahCameraScanStamp"

local ToolModules = {
	JejakEnergi = require(script.Parent.JejakEnergi.Main),
	KotakArwah = require(script.Parent.KotakArwah.Main),
	SuhuMembeku = require(script.Parent.SuhuMembeku.Main),
	BukuTerkutuk = require(script.Parent.BukuTerkutuk.Main),
	BolaArwah = require(script.Parent.BolaArwah.Main),
	GerakanGaib = require(script.Parent.GerakanGaib.Main),
	Garam = require(script.Parent.Garam.Main),
	PilSanity = require(script.Parent.PilSanity.Main),
	Salib = require(script.Parent.Salib.Main),
	Dupa = require(script.Parent.Dupa.Main),
}

local function stampToolRuntime(toolType, success, eventName)
	if not localPlayer then
		return
	end
	if type(toolType) == "string" and toolType ~= "" then
		localPlayer:SetAttribute(TOOL_EQUIPPED_ATTRIBUTE, toolType)
	end
	if eventName ~= nil then
		localPlayer:SetAttribute(TOOL_LAST_EVENT_ATTRIBUTE, tostring(eventName))
	end
	if type(success) == "boolean" then
		localPlayer:SetAttribute(TOOL_LAST_SUCCESS_ATTRIBUTE, success)
	end
	localPlayer:SetAttribute(TOOL_USE_STAMP_ATTRIBUTE, os.clock())
end

local function stampCameraScanRuntime(payload)
	if not localPlayer or type(payload) ~= "table" then
		return
	end
	local possibleGhosts = type(payload.possibleGhosts) == "table" and payload.possibleGhosts or {}
	local evidenceType = type(payload.evidenceType) == "string" and payload.evidenceType or ""
	local scanReason = type(payload.reason) == "string" and payload.reason or ""
	local resolvedGhostType = ""
	if #possibleGhosts == 1 then
		resolvedGhostType = tostring(possibleGhosts[1])
	end
	local hasMeaningfulScan = resolvedGhostType ~= "" or #possibleGhosts > 0 or evidenceType ~= "" or scanReason ~= ""
	if not hasMeaningfulScan then
		return
	end

	localPlayer:SetAttribute(CAMERA_SCAN_GHOST_ATTR, resolvedGhostType ~= "" and resolvedGhostType or nil)
	localPlayer:SetAttribute(CAMERA_SCAN_CANDIDATES_ATTR, #possibleGhosts > 0 and table.concat(possibleGhosts, ", ") or nil)
	localPlayer:SetAttribute(CAMERA_SCAN_EVIDENCE_ATTR, evidenceType ~= "" and evidenceType or nil)
	localPlayer:SetAttribute(CAMERA_SCAN_REASON_ATTR, scanReason ~= "" and scanReason or nil)
	localPlayer:SetAttribute(CAMERA_SCAN_STAMP_ATTR, os.clock())
end

local function isLocalToolEvent(payload, eventName)
	if eventName == "EvidenceToolResult" then
		return true
	end
	if not localPlayer or type(payload) ~= "table" then
		return false
	end
	local payloadPlayer = payload.player
	if typeof(payloadPlayer) == "Instance" and payloadPlayer:IsA("Player") then
		return payloadPlayer == localPlayer
	end
	local userId = tonumber(payload.userId or payload.playerId)
	return userId ~= nil and userId == localPlayer.UserId
end

function EvidenceTools:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._evidenceEvent = self._remotes.EvidenceEvent
	self._evidenceRequest = self._remotes.EvidenceRequest
	self._connections = {}
	self._toolStates = {}
	self._requestCounter = 0
	self._toolAdapters = {}
	self._nativeToolByType = {}
	self._nativeToolConnections = {}
	self._runtimeConnections = {}
	self._nativeBackpackActive = false

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
	self:_bindRuntimeSignals()
	self:_refreshNativeBackpackTools()
end

function EvidenceTools:Stop()
	for _, connection in ipairs(self._connections or {}) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	for _, connection in ipairs(self._runtimeConnections or {}) do
		connection:Disconnect()
	end
	table.clear(self._runtimeConnections)
	self:_clearNativeBackpackTools()
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
	if isLocalToolEvent(payload, eventName) then
		stampToolRuntime(toolType, payload.success ~= false, eventName)
		if toolType == "BolaArwah" then
			stampCameraScanRuntime(payload)
		end
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
	stampToolRuntime(toolType, nil, "ClientToolRequest")

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
		stampToolRuntime(toolType, false, "ClientInvokeFailed")
		return false, "invoke_failed"
	end
	if type(response) == "table" then
		self._toolStates[toolType].lastFeedback = response
		self._toolStates[toolType].lastReason = response.reason
		if response.success == false then
			self._toolStates[toolType].cooldownUntil = os.clock() + 0.25
		end
		stampToolRuntime(toolType, response.success == true, "ClientGatewayResponse")
		if toolType == "BolaArwah" then
			stampCameraScanRuntime(response)
		end
		return response.success == true, response.reason, response
	end
	stampToolRuntime(toolType, false, "ClientGatewayInvalid")
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

function EvidenceTools:SubmitJournalGuess(payload)
	self:_ensureEvidenceRequest()
	if not self._evidenceRequest or not self._evidenceRequest.InvokeServer then
		return false, "missing_remote_function"
	end
	self._requestCounter += 1
	local okInvoke, response = pcall(function()
		return self._evidenceRequest:InvokeServer({
			action = "SubmitJournalGuess",
			requestType = "SubmitJournalGuess",
			requestId = tostring(self._requestCounter),
			payload = payload or {},
		})
	end)
	if not okInvoke then
		stampToolRuntime("Journal", false, "JournalSubmitInvokeFailed")
		return false, "invoke_failed"
	end
	if type(response) ~= "table" then
		stampToolRuntime("Journal", false, "JournalSubmitInvalid")
		return false, "invalid_gateway_response"
	end
	stampToolRuntime("Journal", response.success == true, "JournalSubmitResponse")
	return response.success == true, response.reason, response
end

function EvidenceTools:EndInvestigation(payload)
	self:_ensureEvidenceRequest()
	if not self._evidenceRequest or not self._evidenceRequest.InvokeServer then
		return false, "missing_remote_function"
	end
	self._requestCounter += 1
	local okInvoke, response = pcall(function()
		return self._evidenceRequest:InvokeServer({
			action = "EndInvestigation",
			requestType = "EndInvestigation",
			requestId = tostring(self._requestCounter),
			payload = payload or {},
		})
	end)
	if not okInvoke then
		stampToolRuntime("Journal", false, "JournalEndInvokeFailed")
		return false, "invoke_failed"
	end
	if type(response) ~= "table" then
		stampToolRuntime("Journal", false, "JournalEndInvalid")
		return false, "invalid_gateway_response"
	end
	stampToolRuntime("Journal", response.success == true, "JournalEndResponse")
	return response.success == true, response.reason, response
end

function EvidenceTools:UseTool(toolType, payload)
	local adapter = self._toolAdapters[toolType]
	if not adapter then
		return false, "invalid_tool"
	end
	return adapter:Use(payload)
end

function EvidenceTools:EquipTool(toolType)
	if type(toolType) ~= "string" or toolType == "" then
		return false, "invalid_tool"
	end
	if toolType == "Flashlight" then
		stampToolRuntime(toolType, true, "ClientToolEquipped")
		return true, "equipped_local"
	end
	if not self._toolStates[toolType] then
		return false, "invalid_tool"
	end
	self:_ensureEvidenceRequest()
	if not self._evidenceRequest or not self._evidenceRequest.InvokeServer then
		stampToolRuntime(toolType, false, "ClientToolEquipMissingRemote")
		return false, "missing_remote_function"
	end

	self._requestCounter += 1
	local okInvoke, response = pcall(function()
		return self._evidenceRequest:InvokeServer({
			action = "EquipInvestigationTool",
			requestType = "EquipInvestigationTool",
			requestId = tostring(self._requestCounter),
			toolType = toolType,
			payload = {
				toolType = toolType,
			},
		})
	end)
	if not okInvoke then
		stampToolRuntime(toolType, false, "ClientToolEquipInvokeFailed")
		return false, "invoke_failed"
	end
	if type(response) ~= "table" then
		stampToolRuntime(toolType, false, "ClientToolEquipInvalid")
		return false, "invalid_gateway_response"
	end
	stampToolRuntime(toolType, response.success == true, "ClientToolEquipped")
	return response.success == true, response.reason, response
end

function EvidenceTools:UnequipTool(toolType)
	if type(toolType) ~= "string" or toolType == "" then
		return false, "invalid_tool"
	end
	if toolType == "Flashlight" then
		if localPlayer then
			localPlayer:SetAttribute(TOOL_EQUIPPED_ATTRIBUTE, nil)
			localPlayer:SetAttribute("PasrahFlashlightEnabled", false)
			localPlayer:SetAttribute(TOOL_LAST_EVENT_ATTRIBUTE, "ClientToolUnequipped")
			localPlayer:SetAttribute(TOOL_LAST_SUCCESS_ATTRIBUTE, true)
			localPlayer:SetAttribute(TOOL_USE_STAMP_ATTRIBUTE, os.clock())
		end
		return true, "unequipped_local"
	end
	if not self._toolStates[toolType] then
		return false, "invalid_tool"
	end
	self:_ensureEvidenceRequest()
	if not self._evidenceRequest or not self._evidenceRequest.InvokeServer then
		stampToolRuntime(toolType, false, "ClientToolUnequipMissingRemote")
		return false, "missing_remote_function"
	end

	self._requestCounter += 1
	local okInvoke, response = pcall(function()
		return self._evidenceRequest:InvokeServer({
			action = "UnequipInvestigationTool",
			requestType = "UnequipInvestigationTool",
			requestId = tostring(self._requestCounter),
			toolType = toolType,
			payload = {
				toolType = toolType,
			},
		})
	end)
	if not okInvoke then
		stampToolRuntime(toolType, false, "ClientToolUnequipInvokeFailed")
		return false, "invoke_failed"
	end
	if type(response) ~= "table" then
		stampToolRuntime(toolType, false, "ClientToolUnequipInvalid")
		return false, "invalid_gateway_response"
	end
	if response.success == true and localPlayer then
		if localPlayer:GetAttribute(TOOL_EQUIPPED_ATTRIBUTE) == toolType then
			localPlayer:SetAttribute(TOOL_EQUIPPED_ATTRIBUTE, nil)
		end
	end
	stampToolRuntime(toolType, response.success == true, "ClientToolUnequipped")
	return response.success == true, response.reason, response
end

function EvidenceTools:GetToolState(toolType)
	return self._toolStates[toolType]
end

function EvidenceTools:_bindRuntimeSignals()
	if not localPlayer then
		return
	end
	table.insert(self._runtimeConnections, localPlayer:GetAttributeChangedSignal("InMatch"):Connect(function()
		self:_refreshNativeBackpackTools()
	end))
	table.insert(self._runtimeConnections, localPlayer:GetAttributeChangedSignal("MatchLifecyclePhase"):Connect(function()
		self:_refreshNativeBackpackTools()
	end))
	table.insert(self._runtimeConnections, localPlayer.CharacterAdded:Connect(function()
		self:_refreshNativeBackpackTools()
	end))
end

function EvidenceTools:_isNativeBackpackEnabled()
	if USE_NATIVE_BACKPACK_TOOLS ~= true then
		return false
	end
	if not localPlayer then
		return false
	end
	if localPlayer:GetAttribute("InMatch") ~= true then
		return false
	end
	local lifecyclePhase = tostring(localPlayer:GetAttribute("MatchLifecyclePhase") or ""):gsub("[%s_%-]+", ""):lower()
	return lifecyclePhase ~= "preparationphase"
end

function EvidenceTools:_refreshNativeBackpackTools()
	local shouldEnable = self:_isNativeBackpackEnabled()
	if shouldEnable then
		self:_ensureNativeBackpackTools()
	else
		self:_clearNativeBackpackTools()
	end
	self._nativeBackpackActive = shouldEnable
end

function EvidenceTools:_ensureNativeBackpackTools()
	if not localPlayer then
		return
	end
	local backpack = localPlayer:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	for slot, toolType in ipairs(NATIVE_TOOL_ORDER) do
		if self._toolAdapters[toolType] then
			local tool = self._nativeToolByType[toolType]
			if not tool or not tool.Parent then
				tool = self:_createNativeTool(toolType, slot)
				if tool then
					self._nativeToolByType[toolType] = tool
				end
			end
			if tool and tool.Parent ~= backpack then
				tool.Parent = backpack
			end
		end
	end
end

function EvidenceTools:_createNativeTool(toolType, slot)
	local tool = Instance.new("Tool")
	local label = NATIVE_TOOL_LABELS[toolType] or toolType
	tool.Name = string.format("[%d] %s", slot, label)
	tool.ToolTip = string.format("Pasrah Tool: %s", label)
	tool.CanBeDropped = false
	tool.RequiresHandle = false

	local equippedConnection = tool.Equipped:Connect(function()
		if localPlayer then
			localPlayer:SetAttribute(TOOL_EQUIPPED_ATTRIBUTE, toolType)
		end
	end)
	local activatedConnection = tool.Activated:Connect(function()
		self:UseTool(toolType, {
			source = "NativeBackpack",
		})
	end)

	self._nativeToolConnections[tool] = {
		equippedConnection,
		activatedConnection,
	}
	return tool
end

function EvidenceTools:_clearNativeBackpackTools()
	for toolType, tool in pairs(self._nativeToolByType) do
		local connections = self._nativeToolConnections[tool]
		if connections then
			for _, connection in ipairs(connections) do
				connection:Disconnect()
			end
			self._nativeToolConnections[tool] = nil
		end
		if tool and tool.Parent then
			tool:Destroy()
		end
		self._nativeToolByType[toolType] = nil
	end
end

return setmetatable({}, EvidenceTools)

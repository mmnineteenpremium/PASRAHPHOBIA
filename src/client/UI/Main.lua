local UISystem = {}
UISystem.__index = UISystem

local UI_MODULES = {
	"JournalUI",
	"LobbyUI",
	"MatchUI",
	"ProfileUI",
	"ShopUI",
}

function UISystem:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._connections = {}
	self._uiState = {}

	for _, moduleName in ipairs(UI_MODULES) do
		self._uiState[moduleName] = {
			lastEvent = nil,
			visible = false,
		}
	end
end

function UISystem:Start()
	for _, remoteName in ipairs({ "MatchEvent", "LobbyEvent", "EvidenceEvent", "PurchaseEvent", "SanityEvent" }) do
		local remote = self._remotes[remoteName]
		if remote and remote.OnClientEvent then
			table.insert(self._connections, remote.OnClientEvent:Connect(function(payload)
				self:_onServerEvent(remoteName, payload)
			end))
		end
	end
end

function UISystem:_onServerEvent(remoteName, payload)
	local eventName = payload and payload.eventName or "UnknownEvent"

	if remoteName == "EvidenceEvent" then
		self._uiState.JournalUI.lastEvent = eventName
		self._uiState.JournalUI.visible = true
	elseif remoteName == "LobbyEvent" then
		self._uiState.LobbyUI.lastEvent = eventName
		self._uiState.LobbyUI.visible = true
	elseif remoteName == "MatchEvent" then
		self._uiState.MatchUI.lastEvent = eventName
		self._uiState.MatchUI.visible = true
	elseif remoteName == "PurchaseEvent" then
		self._uiState.ShopUI.lastEvent = eventName
		self._uiState.ShopUI.visible = true
	elseif remoteName == "SanityEvent" then
		self._uiState.ProfileUI.lastEvent = eventName
		self._uiState.ProfileUI.visible = true
	end
end

function UISystem:GetUIState(moduleName)
	return self._uiState[moduleName]
end

return setmetatable({}, UISystem)

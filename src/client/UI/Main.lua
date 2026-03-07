local UISystem = {}
UISystem.__index = UISystem

local UI_MODULES = {
	"JournalUI",
	"LobbyUI",
	"MatchUI",
	"ProfileUI",
	"ShopUI",
	"PASRA_UI",
	"SpectatorUI",
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

	self._matchResult = {
		ghostType = "Unknown",
		correctGuess = false,
		evidenceCollected = 0,
		playersSurvived = 0,
		playersDead = 0,
		matchDuration = 0,
		currencyReward = 0,
		xpReward = 0,
	}
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
		if eventName == "PlayerKilled" and payload and payload.localPlayerKilled == true then
			self._uiState.SpectatorUI.lastEvent = eventName
			self._uiState.SpectatorUI.visible = true
		elseif eventName == "MatchEnded" then
			self._uiState.PASRA_UI.lastEvent = eventName
			self._uiState.PASRA_UI.visible = true
			self._uiState.SpectatorUI.visible = false
			self._uiState.MatchUI.visible = false
			self._matchResult = {
				ghostType = payload.ghostType or "Unknown",
				correctGuess = payload.correctGuess == true,
				evidenceCollected = payload.evidenceCollected or 0,
				playersSurvived = payload.playersSurvived or 0,
				playersDead = payload.playersDead or 0,
				matchDuration = payload.matchDuration or 0,
				currencyReward = payload.currencyReward or 0,
				xpReward = payload.xpReward or 0,
			}
		elseif eventName == "MatchStarted" then
			self._uiState.PASRA_UI.visible = false
			self._uiState.MatchUI.visible = true
			self._uiState.SpectatorUI.visible = false
		end
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

function UISystem:GetMatchResult()
	return self._matchResult
end

return setmetatable({}, UISystem)

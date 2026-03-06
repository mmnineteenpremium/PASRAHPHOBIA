local SoundSystem = {}
SoundSystem.__index = SoundSystem

local EVENT_TO_CATEGORY = {
	AmbientAudioTriggered = "AmbientAudio",
	EnvironmentalAudioTriggered = "EnvironmentalAudio",
	FearAudioTriggered = "FearAudio",
	GhostAudioTriggered = "GhostAudio",
	HuntAudioTriggered = "HuntAudio",
}

function SoundSystem:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._connections = {}
	self._lastAudioByCategory = {}
end

function SoundSystem:Start()
	local matchEvent = self._remotes.MatchEvent
	if matchEvent and matchEvent.OnClientEvent then
		table.insert(self._connections, matchEvent.OnClientEvent:Connect(function(payload)
			self:_onAudioEvent(payload)
		end))
	end
end

function SoundSystem:_onAudioEvent(payload)
	local eventName = payload and payload.eventName
	local category = EVENT_TO_CATEGORY[eventName]
	if not category then
		return
	end
	self._lastAudioByCategory[category] = payload
end

function SoundSystem:GetLastAudio(category)
	return self._lastAudioByCategory[category]
end

return setmetatable({}, SoundSystem)

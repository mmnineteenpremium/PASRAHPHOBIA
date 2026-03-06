local GhostRenderer = {}
GhostRenderer.__index = GhostRenderer

function GhostRenderer:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._connections = {}
	self._ghostState = {
		isManifesting = false,
		sanity = 100,
		isSpectator = false,
		distortion = 0,
	}
end

function GhostRenderer:Start()
	local matchEvent = self._remotes.MatchEvent
	local sanityEvent = self._remotes.SanityEvent

	if matchEvent and matchEvent.OnClientEvent then
		table.insert(self._connections, matchEvent.OnClientEvent:Connect(function(payload)
			self:_onMatchEvent(payload)
		end))
	end

	if sanityEvent and sanityEvent.OnClientEvent then
		table.insert(self._connections, sanityEvent.OnClientEvent:Connect(function(payload)
			self:_onSanityEvent(payload)
		end))
	end
end

function GhostRenderer:SetSpectatorMode(enabled)
	self._ghostState.isSpectator = enabled == true
	self:_updateDistortion()
end

function GhostRenderer:_onMatchEvent(payload)
	local eventName = payload and payload.eventName
	if eventName == "GhostManifest" then
		self._ghostState.isManifesting = true
	elseif eventName == "GhostManifestEnd" then
		self._ghostState.isManifesting = false
	end
	self:_updateDistortion()
end

function GhostRenderer:_onSanityEvent(payload)
	if type(payload and payload.newSanity) == "number" then
		self._ghostState.sanity = payload.newSanity
		self:_updateDistortion()
	end
end

function GhostRenderer:_updateDistortion()
	local sanityFactor = 1 - math.clamp((self._ghostState.sanity or 100) / 100, 0, 1)
	local spectatorFactor = self._ghostState.isSpectator and 0.35 or 0
	local manifestFactor = self._ghostState.isManifesting and 0.45 or 0
	self._ghostState.distortion = math.clamp(sanityFactor + spectatorFactor + manifestFactor, 0, 1)
end

function GhostRenderer:GetRenderState()
	return self._ghostState
end

return setmetatable({}, GhostRenderer)

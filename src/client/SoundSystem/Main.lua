local AudioController = require(script.Parent.Parent.Controllers.Sensory.AudioController)
local VFXController = require(script.Parent.Parent.Controllers.Sensory.VFXController)

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
	self._managedControllers = {}
	self:_registerSensoryController("AudioController", AudioController, context)
	self:_registerSensoryController("VFXController", VFXController, context)
end

function SoundSystem:Stop()
	for _, controller in ipairs(self._managedControllers) do
		if type(controller.Stop) == "function" then
			controller:Stop()
		end
	end
	for _, conn in ipairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self._connections)
end

function SoundSystem:_registerSensoryController(name, module, context)
	if not context or not context.Registry then
		return
	end
	if context.Registry:Has(name) then
		return
	end
	context.Registry:Register(name, module)
	table.insert(self._managedControllers, module)
	if type(module.Init) == "function" then
		module:Init(context)
	end
end

function SoundSystem:Start()
	local matchEvent = self._remotes.MatchEvent
	if matchEvent and matchEvent.OnClientEvent then
		table.insert(self._connections, matchEvent.OnClientEvent:Connect(function(payload)
			self:_onAudioEvent(payload)
		end))
	end
	for _, controller in ipairs(self._managedControllers) do
		if type(controller.Start) == "function" then
			controller:Start(self._context)
		end
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

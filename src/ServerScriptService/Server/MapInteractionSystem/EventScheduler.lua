local EventScheduler = {}
EventScheduler.__index = EventScheduler

local EVENT_TYPES = {
	"LightFlicker",
	"DoorSlam",
	"ObjectThrow",
	"RadioNoise",
	"ShadowMovement",
}

local function clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	end
	if value > maxValue then
		return maxValue
	end
	return value
end

function EventScheduler.new(rng, config)
	local self = setmetatable({}, EventScheduler)
	self._rng = rng or Random.new()
	self._config = config or {}
	return self
end

function EventScheduler:ComputeInterval(session)
	local baseMin = self._config.MinSchedulerIntervalSeconds or 6
	local baseMax = self._config.MaxSchedulerIntervalSeconds or 16
	local tensionFactor = clamp((session.tension or 0) / 100, 0, 1)
	local fearFactor = clamp((session.fearLevel or 0) / 100, 0, 1)
	local personalityFrequency = session.personality and session.personality.eventFrequency or 1
	local freq = clamp(personalityFrequency, 0.3, 2.0)

	local minInterval = baseMin - (tensionFactor * 2.0) - (fearFactor * 1.5)
	local maxInterval = baseMax - (tensionFactor * 3.0) - (fearFactor * 2.0)
	minInterval = clamp(minInterval / freq, 2.0, baseMax)
	maxInterval = clamp(maxInterval / freq, minInterval + 0.5, baseMax + 2.0)
	return self._rng:NextNumber(minInterval, maxInterval)
end

function EventScheduler:ComputeChance(session)
	local base = self._config.BaseSchedulerChance or 0.12
	local tensionFactor = clamp((session.tension or 0) / 100, 0, 1)
	local fearFactor = clamp((session.fearLevel or 0) / 100, 0, 1)
	local personalityFrequency = session.personality and session.personality.eventFrequency or 1
	local freq = clamp(personalityFrequency, 0.3, 2.0)
	local chance = base + (tensionFactor * 0.28) + (fearFactor * 0.2) + ((freq - 1) * 0.1)
	return clamp(chance, 0.04, 0.85)
end

function EventScheduler:PickEventType(session)
	local personality = session.personality and session.personality.name
	local tension = session.tension or 0
	local fear = session.fearLevel or 0

	if personality == "Trickster" then
		return self._rng:NextNumber() <= 0.5 and "RadioNoise" or "ShadowMovement"
	end
	if personality == "Poltergeist" then
		return self._rng:NextNumber() <= 0.6 and "ObjectThrow" or "DoorSlam"
	end
	if personality == "Demon" and tension >= 60 then
		return self._rng:NextNumber() <= 0.5 and "DoorSlam" or "ShadowMovement"
	end
	if personality == "Shade" and fear < 45 then
		return "LightFlicker"
	end
	if tension >= 70 then
		return self._rng:NextNumber() <= 0.5 and "ShadowMovement" or "DoorSlam"
	end
	if fear >= 65 then
		return self._rng:NextNumber() <= 0.5 and "RadioNoise" or "ObjectThrow"
	end
	return EVENT_TYPES[self._rng:NextInteger(1, #EVENT_TYPES)]
end

function EventScheduler:ShouldTrigger(session, now)
	local currentTime = now or os.clock()
	if currentTime < (session.nextScheduledAt or 0) then
		return false
	end

	local chance = self:ComputeChance(session)
	local hit = self._rng:NextNumber() <= chance
	session.nextScheduledAt = currentTime + self:ComputeInterval(session)
	return hit
end

return EventScheduler

local EventRegistry = {}
EventRegistry.__index = EventRegistry

local DEFAULT_REGISTRY = {
	LightFlicker = {
		eventType = "LightFlicker",
		cooldown = 8,
		probability = 0.4,
		duration = 2.5,
		roomConstraints = {
			allowSafeZone = false,
		},
	},
	DoorSlam = {
		eventType = "DoorSlam",
		cooldown = 10,
		probability = 0.35,
		duration = 1.0,
		roomConstraints = {
			allowSafeZone = false,
		},
	},
	ObjectThrow = {
		eventType = "ObjectThrow",
		cooldown = 12,
		probability = 0.28,
		duration = 2.0,
		roomConstraints = {
			allowSafeZone = false,
		},
	},
	RadioNoise = {
		eventType = "RadioNoise",
		cooldown = 9,
		probability = 0.38,
		duration = 3.0,
		roomConstraints = {
			requireElectronics = true,
		},
	},
	ShadowMovement = {
		eventType = "ShadowMovement",
		cooldown = 14,
		probability = 0.22,
		duration = 2.2,
		roomConstraints = {
			allowSafeZone = false,
			preferNearGhost = true,
		},
	},
}

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, nestedValue in pairs(value) do
		copy[key] = deepCopy(nestedValue)
	end
	return copy
end

local function mergeTable(base, override)
	local merged = deepCopy(base)
	for key, value in pairs(override or {}) do
		if type(value) == "table" and type(merged[key]) == "table" then
			merged[key] = mergeTable(merged[key], value)
		else
			merged[key] = value
		end
	end
	return merged
end

function EventRegistry.new(config)
	local self = setmetatable({}, EventRegistry)
	self._registry = mergeTable(DEFAULT_REGISTRY, config or {})
	return self
end

function EventRegistry:Get(eventType)
	return self._registry[eventType]
end

function EventRegistry:GetAll()
	return self._registry
end

return EventRegistry

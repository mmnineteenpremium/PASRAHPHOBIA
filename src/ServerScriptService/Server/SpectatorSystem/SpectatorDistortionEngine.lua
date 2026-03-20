local SpectatorDistortionEngine = {}
SpectatorDistortionEngine.__index = SpectatorDistortionEngine

local DEFAULT_CONFIG = {
	BaseWeights = {
		fake = 60,
		uncertain = 30,
		real = 10,
	},
	NearGhostWeights = {
		fake = 50,
		uncertain = 40,
		real = 10,
	},
	CooldownMinSeconds = 5,
	CooldownMaxSeconds = 10,
	RealMinSeconds = 2,
	RealMaxSeconds = 4,
}

local function shallowCopy(source)
	local target = {}
	for key, value in pairs(source) do
		target[key] = value
	end
	return target
end

local function getNow(now)
	return now or os.clock()
end

function SpectatorDistortionEngine.new(deps, config)
	local self = setmetatable({}, SpectatorDistortionEngine)
	self._deps = deps or {}
	self._rng = self._deps.Random or Random.new()
	self._config = shallowCopy(DEFAULT_CONFIG)

	for key, value in pairs(config or {}) do
		self._config[key] = value
	end

	return self
end

function SpectatorDistortionEngine:IsOnCooldown(lastDistortionAt, now)
	local currentTime = getNow(now)
	local lastTime = lastDistortionAt or 0
	return currentTime < lastTime
end

function SpectatorDistortionEngine:_chooseWeights(isNearGhost)
	if isNearGhost then
		return self._config.NearGhostWeights
	end
	return self._config.BaseWeights
end

function SpectatorDistortionEngine:_rollOutcome(weights)
	print("[SpectatorDistortionEngine] Distortion roll")
	local roll = self._rng:NextInteger(1, 100)
	print("[SpectatorDistortionEngine] roll =", roll)
	local fakeLimit = weights.fake
	local uncertainLimit = fakeLimit + weights.uncertain

	if roll <= fakeLimit then
		return "fake", roll
	end
	if roll <= uncertainLimit then
		return "uncertain", roll
	end
	return "real", roll
end

function SpectatorDistortionEngine:_nextCooldown(now)
	local currentTime = getNow(now)
	local cooldown = self._rng:NextNumber(
		self._config.CooldownMinSeconds,
		self._config.CooldownMaxSeconds
	)
	return currentTime + cooldown, cooldown
end

function SpectatorDistortionEngine:_nextRealDuration()
	return self._rng:NextNumber(
		self._config.RealMinSeconds,
		self._config.RealMaxSeconds
	)
end

function SpectatorDistortionEngine:BuildDecision(context)
	local now = getNow(context and context.now)
	local lastDistortionAt = context and context.lastDistortionAt or 0
	if self:IsOnCooldown(lastDistortionAt, now) then
		return nil, "cooldown"
	end

	local isNearGhost = context and context.isNearGhost == true or false
	local weights = self:_chooseWeights(isNearGhost)
	local outcome, roll = self:_rollOutcome(weights)

	local nextAllowedAt, cooldownSeconds = self:_nextCooldown(now)
	local realDuration = nil
	if outcome == "real" then
		realDuration = self:_nextRealDuration()
	end

	return {
		outcome = outcome,
		roll = roll,
		weights = weights,
		nextAllowedAt = nextAllowedAt,
		cooldownSeconds = cooldownSeconds,
		realDurationSeconds = realDuration,
	}, nil
end


function SpectatorDistortionEngine:DistortEvidence(realData, evidenceTypes)
    local roll = math.random(1, 100)
    if roll <= 10 then
        return {
            outcome = "real",
            payload = realData,
            roll = roll,
        }
    elseif roll <= 40 then
        return {
            outcome = "uncertain",
            payload = {
                type = nil,
                message = "Sinyal tidak jelas...",
            },
            roll = roll,
        }
    end

    local list = {}
    for _, evidenceType in pairs(evidenceTypes or {}) do
        if type(evidenceType) == "string" then
            table.insert(list, evidenceType)
        end
    end
    local fakeType = list[math.max(1, math.random(1, math.max(#list, 1)))]

    return {
        outcome = "fake",
        payload = {
            type = fakeType,
            message = "Terdeteksi: " .. tostring(fakeType),
        },
        roll = roll,
    }
end

function SpectatorDistortionEngine:DistortGhostSighting(realPosition)
    local roll = math.random(1, 100)
    if roll <= 10 then
        return {
            outcome = "real",
            position = realPosition,
            roll = roll,
        }
    elseif roll <= 40 then
        return {
            outcome = "uncertain",
            position = nil,
            roll = roll,
        }
    end

    if typeof(realPosition) ~= "Vector3" then
        return {
            outcome = "fake",
            position = nil,
            roll = roll,
        }
    end

    local offset = Vector3.new(
        math.random(-20, 20),
        0,
        math.random(-20, 20)
    )

    return {
        outcome = "fake",
        position = realPosition + offset,
        roll = roll,
    }
end
return SpectatorDistortionEngine

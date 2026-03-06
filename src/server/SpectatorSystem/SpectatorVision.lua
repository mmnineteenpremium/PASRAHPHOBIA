local SpectatorVision = {}
SpectatorVision.__index = SpectatorVision

local function getNow(now)
	return now or os.clock()
end

function SpectatorVision.new(deps, config)
	local self = setmetatable({}, SpectatorVision)
	self._deps = deps or {}
	self._config = config or {}
	return self
end

function SpectatorVision:BuildVisionState(context)
	local now = getNow(context and context.now)
	local spectatorPlayer = context and context.spectator and context.spectator.player
	local followTargetUserId = context and context.spectator and context.spectator.targetUserId
	local generatedSignal = context and context.generatedSignal
	local decision = context and context.decision
	local activityPayload = context and context.activityPayload or {}
	local ghostState = context and context.ghostState or {}

	if not spectatorPlayer or not generatedSignal or not decision then
		return nil, "invalid_context"
	end

	local huntActive = ghostState.huntActive == true or activityPayload.activityType == "hunt_started"
	local visibilityEndsAt = now + (generatedSignal.durationSeconds or 0)
	local outcome = decision.outcome

	if huntActive and outcome == "real" then
		-- Real ghost visibility must terminate when hunt begins.
		outcome = "uncertain"
		generatedSignal.type = "UncertainGhost"
		generatedSignal.isReliable = false
		generatedSignal.durationSeconds = 0.75
		visibilityEndsAt = now + generatedSignal.durationSeconds
	end

	return {
		matchId = context.matchId,
		spectatorUserId = spectatorPlayer.UserId,
		followTargetUserId = followTargetUserId,
		outcome = outcome,
		ghostSignal = generatedSignal,
		reliability = generatedSignal.isReliable and "high" or "low",
		nextDecisionAllowedAt = decision.nextAllowedAt,
		createdAt = now,
		visibilityEndsAt = visibilityEndsAt,
	}, nil
end

function SpectatorVision:BuildEndedRealVisionState(context)
	local spectatorPlayer = context and context.spectator and context.spectator.player
	if not spectatorPlayer then
		return nil, "missing_spectator"
	end

	local now = getNow(context and context.now)
	return {
		matchId = context.matchId,
		spectatorUserId = spectatorPlayer.UserId,
		followTargetUserId = context.spectator.targetUserId,
		outcome = "real_ended",
		ghostSignal = {
			type = "RealGhostEnded",
			reason = context.reason or "hunt_started",
			durationSeconds = 0,
			isReliable = false,
			generatedAt = now,
		},
		reliability = "low",
		nextDecisionAllowedAt = nil,
		createdAt = now,
		visibilityEndsAt = now,
	}, nil
end

return SpectatorVision

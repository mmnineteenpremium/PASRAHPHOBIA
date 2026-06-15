local GhostHuntController = {}
GhostHuntController.__index = GhostHuntController

function GhostHuntController.new(config, rng)
	local self = setmetatable({}, GhostHuntController)
	self._config = {
		HuntDuration = config.HuntDuration or 20,
		HuntCooldown = config.HuntCooldown or 30,
		DoorLockDuration = config.DoorLockDuration or 3,
	}
	self._rng = rng
	return self
end

function GhostHuntController:CanStartHunt(session, snapshot, now, aggressionModel)
	if session.hunt.active then
		return false
	end
	if snapshot and snapshot.huntAllowed == false then
		return false
	end
	local huntGraceUntil = snapshot and tonumber(snapshot.huntGraceUntil)
	if huntGraceUntil and now < huntGraceUntil then
		return false
	end
	if now < (session.nextHuntAllowedAt or 0) then
		return false
	end
	if session.currentState == "Retreat" or session.currentState == "Cooldown" then
		return false
	end
	if not aggressionModel:CanAttemptHunt(session, snapshot) then
		return false
	end

	local chance = aggressionModel:ComputeHuntChance(session, snapshot)
	return self._rng:NextNumber() <= chance
end

function GhostHuntController:StartHunt(matchOrSession, targetPlayer, now)
	local session = matchOrSession
	-- Extract session if caller passed a match object with a ghost field
	if type(matchOrSession) == "table" and matchOrSession.ghost then
		session = matchOrSession.session or matchOrSession
	end
	if not session then
		return
	end
	-- Always set hunt active on the session object
	session.hunt.active = true
	session.hunt.startedAt = now
	session.hunt.endsAt = now + self._config.HuntDuration
	session.hunt.targetUserId = targetPlayer and targetPlayer.userId or nil
	session.hunt.doorsLocked = true
	session.hunt.exitsDisabled = true
	session.hunt.doorUnlockAt = now + self._config.DoorLockDuration
	session.hunt.navigationPath = nil
	-- Update ghost state machine if available (match object path)
	if type(matchOrSession) == "table" and matchOrSession.ghost then
		local ghost = matchOrSession.ghost
		local stateMachine = ghost and ghost.stateMachine
		if stateMachine and type(stateMachine.SetState) == "function" then
			stateMachine:SetState("Hunt")
		end
	end
end

function GhostHuntController:EndHunt(session, now)
	session.hunt.active = false
	session.hunt.targetUserId = nil
	session.hunt.lastEndedAt = now
	session.nextHuntAllowedAt = now + self._config.HuntCooldown
	session.hunt.doorsLocked = false
	session.hunt.exitsDisabled = false
	session.hunt.navigationPath = nil
end

function GhostHuntController:Update(session, snapshot, now, targeting)
	if not session.hunt.active then
		return "inactive"
	end

	if now >= (session.hunt.endsAt or now) then
		self:EndHunt(session, now)
		return "ended"
	end

	local currentTarget = session.hunt.targetUserId
	local targetStillValid = false
	local players = snapshot.players or {}
	for _, playerData in ipairs(players) do
		if playerData.userId == currentTarget and playerData.isAlive ~= false then
			targetStillValid = true
			break
		end
	end

	if not targetStillValid then
		local nextTarget = targeting:SelectTarget(session, snapshot, session.hunt.strategy, self._rng)
		session.hunt.targetUserId = nextTarget and nextTarget.userId or nil
	end

	if session.hunt.doorsLocked and now >= (session.hunt.doorUnlockAt or now) then
		session.hunt.doorsLocked = false
	end

	local navPaths = snapshot.navPaths
	if type(navPaths) == "table" and session.hunt.targetUserId then
		local directPath = navPaths[session.hunt.targetUserId]
		if type(directPath) == "table" then
			session.hunt.navigationPath = directPath
		end
	end

	return "active"
end

return GhostHuntController

local InvestigationState = require(script.Parent.InvestigationState)

local InvestigationDirector = {}
InvestigationDirector.__index = InvestigationDirector

local DEFAULT_SANITY_INTERVAL = 5
local activeMatches = {}
local boundGhostSystem = nil

local function resolveGhostSystem(deps)
	local ghostSystem = nil
	if type(deps) == "table" then
		local services = deps.Services or deps.ServiceRegistry
		if type(services) == "table" then
			local get = services.Get or services.GetService
			if type(get) == "function" then
				ghostSystem = get(services, "GhostSystem")
			end
		end
		if not ghostSystem and type(deps.GhostSystem) == "table" then
			ghostSystem = deps.GhostSystem
		end
	end
	if type(ghostSystem) ~= "table" then
		return nil
	end
	return ghostSystem
end

local function getMatchId(match)
	return match and (match.matchId or match.id)
end

local function computeAverageSanity(match)
	local total = 0
	local count = 0

	for _, entry in pairs(match and match.playersByUserId or {}) do
		local sanity = tonumber(entry.sanity)
		if sanity then
			total += sanity
			count += 1
		end
	end

	if count == 0 then
		return nil
	end
	return total / count
end

local function resolveNextState(averageSanity)
	if averageSanity == nil then
		return nil
	end
	if averageSanity < 25 then
		return InvestigationState.Hunt
	end
	if averageSanity < 50 then
		return InvestigationState.EvidenceCollection
	end
	return InvestigationState.Exploration
end

local function triggerHunt(ghostSystem, match)
	if not ghostSystem or not match then
		return
	end
	if type(ghostSystem.TriggerHunt) == "function" then
		ghostSystem:TriggerHunt(match)
		return
	end

	local matchId = getMatchId(match)
	if not matchId then
		return
	end
	if type(ghostSystem.StartHunt) == "function" then
		ghostSystem:StartHunt(matchId, match.snapshot or {}, os.clock())
		return
	end
	if type(ghostSystem.Service) == "table" and type(ghostSystem.Service.StartHunt) == "function" then
		ghostSystem.Service:StartHunt(matchId, match.snapshot or {}, os.clock())
	end
end

function InvestigationDirector.Bind(deps)
	boundGhostSystem = resolveGhostSystem(deps) or boundGhostSystem
	return boundGhostSystem
end

function InvestigationDirector.Start(match)
	if not match then
		return
	end

	local matchId = getMatchId(match)
	if not matchId then
		return
	end

	local existing = activeMatches[matchId]
	if existing and existing.running then
		return
	end

	local entry = {
		running = true,
		lastState = match.investigationState,
		ghostSystem = boundGhostSystem,
	}
	activeMatches[matchId] = entry

	task.spawn(function()
		while entry.running do
			if match.investigationState ~= InvestigationState.InvestigationComplete then
				local average = computeAverageSanity(match)
				local nextState = resolveNextState(average)
				if nextState then
					local previousState = entry.lastState or match.investigationState
					if match.investigationState ~= nextState then
						match.investigationState = nextState
					end
					if nextState == InvestigationState.Hunt and previousState ~= InvestigationState.Hunt then
						triggerHunt(entry.ghostSystem, match)
					end
					entry.lastState = nextState
				end
			end
			task.wait(DEFAULT_SANITY_INTERVAL)
		end
	end)
end

function InvestigationDirector.Stop(match)
	if not match then
		return
	end
	local matchId = getMatchId(match)
	if not matchId then
		return
	end
	local entry = activeMatches[matchId]
	if entry then
		entry.running = false
		activeMatches[matchId] = nil
	end
end

return InvestigationDirector

local MatchTeleport = {}
MatchTeleport.__index = MatchTeleport

local function resolveTeleportService(deps)
	local service = deps.TeleportService
	if type(service) == "table" then
		return service
	end
	return nil
end

function MatchTeleport.new(deps, config)
	local self = setmetatable({}, MatchTeleport)
	self._deps = deps or {}
	self._config = config or {}
	self._teleportService = resolveTeleportService(self._deps)
	return self
end

function MatchTeleport:_teleport(player, placeId, options)
	if self._teleportService and type(self._teleportService.TeleportAsync) == "function" then
		local ok, err = pcall(function()
			self._teleportService:TeleportAsync(placeId, { player }, options)
		end)
		if not ok then
			return false, err
		end
	end
	return true
end

function MatchTeleport:TeleportPlayers(match)
	local teleported = {}
	local placeId = match.mapReference or self._config.MatchPlaceId

	for _, player in ipairs(match.players) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			local ok = true
			if placeId then
				ok = self:_teleport(player, placeId, nil)
			end
			if ok then
				table.insert(teleported, player)
			end
		end
	end

	return teleported
end

function MatchTeleport:ReturnPlayersToLobby(match)
	local teleported = {}
	local lobbyPlaceId = self._config.LobbyPlaceId

	for _, player in ipairs(match.players) do
		if typeof(player) == "Instance" and player:IsA("Player") then
			local ok = true
			if lobbyPlaceId then
				ok = self:_teleport(player, lobbyPlaceId, nil)
			end
			if ok then
				table.insert(teleported, player)
			end
		end
	end

	return teleported
end

return MatchTeleport

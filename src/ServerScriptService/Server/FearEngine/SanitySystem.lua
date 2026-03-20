local SanitySystem = {}

SanitySystem.players = {}

function SanitySystem.setPlayer(player)
	SanitySystem.players[player] = 100
end

function SanitySystem.reduce(player, amount)
	if SanitySystem.players[player] then
		SanitySystem.players[player] = math.max(0, SanitySystem.players[player] - amount)
	end
end

function SanitySystem.get(player)
	return SanitySystem.players[player] or 100
end

return SanitySystem

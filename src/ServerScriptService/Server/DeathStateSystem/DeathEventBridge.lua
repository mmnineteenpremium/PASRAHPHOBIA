local Players = game:GetService("Players")

local DeathEventBridge = {}

function DeathEventBridge.Start(deathService)
	local function hookCharacter(player, character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			print("[DeathEventBridge] Player died:", player.Name)
			local matchId = deathService._state:Get("activeMatchId")
			deathService:HandleEvent("PlayerDied", {
				matchId = matchId,
				userId = player.UserId,
			})
		end)
	end

	local function hookPlayer(player)
		if player.Character then
			hookCharacter(player, player.Character)
		end

		player.CharacterAdded:Connect(function(character)
			hookCharacter(player, character)
		end)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		hookPlayer(player)
	end

	Players.PlayerAdded:Connect(hookPlayer)
end

return DeathEventBridge


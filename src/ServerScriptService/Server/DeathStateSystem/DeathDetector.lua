local Players = game:GetService("Players")

local DeathDetector = {}

function DeathDetector.Start(eventBus)
	local function hookCharacter(player, character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			if eventBus then
				eventBus:Publish("PlayerDied", {
					player = player,
					userId = player.UserId,
				})
			end
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			hookCharacter(player, character)
		end)
	end)
end

return DeathDetector

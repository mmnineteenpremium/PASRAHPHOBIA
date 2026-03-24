local Players = game:GetService("Players")

local DeathEventBridge = {}

-- ✅ ADD: Debounce tracking
local DEATH_DEBOUNCE_SECONDS = 1
local lastDeathTime = {}

function DeathEventBridge.Start(deathService)
	local function hookCharacter(player, character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			print("[DeathEventBridge] Player died:", player.Name)
			
			-- ✅ ADD: Check spawn protection BEFORE firing event
			local isProtected = player:GetAttribute("SpawnProtected") == true
			if isProtected then
				local protectUntil = player:GetAttribute("SpawnProtectedUntil")
				if type(protectUntil) == "number" and protectUntil > os.clock() then
					warn("[DeathEventBridge] 🛡️ BLOCKED death for", player.Name, "- spawn protected")
					return
				end
			end
			
			-- ✅ ADD: Debounce rapid deaths
			local userId = player.UserId
			local now = os.clock()
			local lastDeath = lastDeathTime[userId]
			if lastDeath and (now - lastDeath) < DEATH_DEBOUNCE_SECONDS then
				warn("[DeathEventBridge] ⚡ BLOCKED rapid death for", player.Name, "- too soon")
				return
			end
			lastDeathTime[userId] = now
			
			-- ✅ NOW safe to fire event
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
	
	-- ✅ ADD: Cleanup on player leave
	Players.PlayerRemoving:Connect(function(player)
		lastDeathTime[player.UserId] = nil
	end)
end

return DeathEventBridge

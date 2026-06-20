--[[
    MAP INTERACTION FALLBACK
    Thin module: tracks ProximityPromptService visible prompt count.
    Used by CrosshairInteraction.client.lua to gate crosshair dispatch.

    All world interactions (light switches, doors, tools) now go through:
    - ProximityPrompt for ProximityPrompt-native interactions
    - CrosshairInteraction for crosshair-aim + left-click dispatch
    - Main.lua for tool hotkeys (1-3, F, E = tool use)

    This file intentionally does NOT handle E-key or world interaction dispatch.
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local LOCAL_PLAYER = Players.LocalPlayer

local anyPromptVisibleCount = 0

ProximityPromptService.PromptShown:Connect(function()
	anyPromptVisibleCount = anyPromptVisibleCount + 1
end)

ProximityPromptService.PromptHidden:Connect(function()
	anyPromptVisibleCount = math.max(0, anyPromptVisibleCount - 1)
end)

return {
	getPromptVisibleCount = function()
		return anyPromptVisibleCount
	end,
}

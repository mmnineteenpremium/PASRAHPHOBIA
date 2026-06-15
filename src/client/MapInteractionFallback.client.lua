local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LOCAL_PLAYER = Players.LocalPlayer
local REMOTE_NAME = "MapInteractionEvent"
local LIGHT_SWITCH_PROMPT_NAME = "LightSwitchPrompt"
local LIGHT_SWITCH_DISTANCE = 8.5
local LOCAL_COOLDOWN_SECONDS = 0.35

local visibleLightPrompts = {}
local lastRequestAt = 0
local anyPromptVisibleCount = 0

local function getRemote()
	local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	return folder and folder:FindFirstChild(REMOTE_NAME)
end

local function isVisibleLightPrompt(prompt)
	return prompt
		and prompt:IsA("ProximityPrompt")
		and prompt.Name == LIGHT_SWITCH_PROMPT_NAME
		and prompt.Enabled == true
		and prompt.Parent
		and prompt.Parent:GetAttribute("PasrahLightSwitchObjectId") ~= nil
end

ProximityPromptService.PromptShown:Connect(function(prompt)
	if isVisibleLightPrompt(prompt) then
		visibleLightPrompts[prompt] = true
	end
	anyPromptVisibleCount = anyPromptVisibleCount + 1
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	visibleLightPrompts[prompt] = nil
	anyPromptVisibleCount = math.max(0, anyPromptVisibleCount - 1)
end)

local function hasVisibleLightPrompt()
	for prompt in pairs(visibleLightPrompts) do
		if isVisibleLightPrompt(prompt) then
			return true
		end
		visibleLightPrompts[prompt] = nil
	end
	return false
end

local function getMatchRoot()
	local matchId = LOCAL_PLAYER:GetAttribute("MatchId")
	if type(matchId) ~= "string" or matchId == "" then
		return nil
	end
	local activeMatches = Workspace:FindFirstChild("ActiveMatches")
	return activeMatches and activeMatches:FindFirstChild("Match_" .. matchId)
end

local function findNearestSwitch()
	local character = LOCAL_PLAYER.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return nil
	end
	local matchRoot = getMatchRoot()
	if not matchRoot then
		return nil
	end

	local bestSwitch = nil
	local bestDistance = LIGHT_SWITCH_DISTANCE
	for _, descendant in ipairs(matchRoot:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("PasrahLightSwitchObjectId") ~= nil then
			local prompt = descendant:FindFirstChild(LIGHT_SWITCH_PROMPT_NAME)
			if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled == true then
				local distance = (root.Position - descendant.Position).Magnitude
				if distance <= bestDistance then
					bestSwitch = descendant
					bestDistance = distance
				end
			end
		end
	end
	return bestSwitch
end

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode ~= Enum.KeyCode.E then
		return
	end
	if UserInputService:GetFocusedTextBox() then
		return
	end
	if LOCAL_PLAYER:GetAttribute("InMatch") ~= true
		or tostring(LOCAL_PLAYER:GetAttribute("MatchLifecyclePhase") or "") ~= "InvestigationPhase" then
		return
	end
	if anyPromptVisibleCount > 0 then
		return
	end
	if hasVisibleLightPrompt() then
		return
	end

	local now = os.clock()
	if now - lastRequestAt < LOCAL_COOLDOWN_SECONDS then
		return
	end
	local switch = findNearestSwitch()
	if not switch then
		return
	end
	local objectId = switch:GetAttribute("PasrahLightSwitchObjectId")
	if type(objectId) ~= "string" or objectId == "" then
		return
	end

	local remote = getRemote()
	if remote and remote:IsA("RemoteEvent") then
		lastRequestAt = now
		remote:FireServer({
			action = "ToggleLight",
			objectId = objectId,
		})
	end
end)

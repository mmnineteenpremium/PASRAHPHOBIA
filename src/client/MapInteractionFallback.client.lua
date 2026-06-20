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
local PREPARATION_PENDING_TOOL_ATTR = "PasrahPreparationToolPendingToolType"
local PREPARATION_PENDING_LABEL_ATTR = "PasrahPreparationToolPendingToolLabel"
local PREPARATION_PENDING_SOURCE_ATTR = "PasrahPreparationToolPendingToolSource"
local PREPARATION_PENDING_RESPONSE_ATTR = "PasrahPreparationToolPendingResponse"

local visibleLightPrompts = {}
local lastRequestAt = 0
local anyPromptVisibleCount = 0
local preparationPromptState = {
	visible = false,
	toolType = "",
	toolLabel = "",
	source = "",
}
local preparationPromptGui = nil
local preparationPromptTitle = nil
local preparationPromptBody = nil
local preparationPromptYes = nil
local preparationPromptNo = nil

local function getRemote()
	local folder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	return folder and folder:FindFirstChild(REMOTE_NAME)
end

local function getPlayerGui()
	return LOCAL_PLAYER:FindFirstChildOfClass("PlayerGui")
end

local function hidePreparationPrompt()
	preparationPromptState.visible = false
	preparationPromptState.toolType = ""
	preparationPromptState.toolLabel = ""
	preparationPromptState.source = ""
	if preparationPromptGui then
		preparationPromptGui.Enabled = false
	end
end

local function sendPreparationPromptResponse(response)
	local toolType = tostring(preparationPromptState.toolType or "")
	if toolType == "" then
		return
	end
	local remote = getRemote()
	if remote and remote:IsA("RemoteEvent") then
		remote:FireServer({
			action = "PreparationToolResponse",
			response = response,
			toolType = toolType,
		})
	end
end

local function ensurePreparationPromptGui()
	if preparationPromptGui and preparationPromptGui.Parent then
		return preparationPromptGui
	end

	local playerGui = getPlayerGui()
	if not playerGui then
		return nil
	end

	local gui = playerGui:FindFirstChild("PreparationToolPromptUI")
	if gui and not gui:IsA("ScreenGui") then
		gui:Destroy()
		gui = nil
	end
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "PreparationToolPromptUI"
		gui.IgnoreGuiInset = true
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 280
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Enabled = false
		gui.Parent = playerGui
	end

	local root = gui:FindFirstChild("Root")
	if not (root and root:IsA("Frame")) then
		if root then
			root:Destroy()
		end
		root = Instance.new("Frame")
		root.Name = "Root"
		root.AnchorPoint = Vector2.new(0.5, 0.5)
		root.Position = UDim2.fromScale(0.5, 0.5)
		root.Size = UDim2.fromScale(0.42, 0.25)
		root.BackgroundColor3 = Color3.fromRGB(14, 16, 22)
		root.BackgroundTransparency = 0.1
		root.BorderSizePixel = 0
		root.Parent = gui

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(124, 176, 255)
		stroke.Thickness = 2
		stroke.Transparency = 0.15
		stroke.Parent = root

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 14)
		corner.Parent = root

		local title = Instance.new("TextLabel")
		title.Name = "Title"
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromScale(0.08, 0.12)
		title.Size = UDim2.fromScale(0.84, 0.22)
		title.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
		title.TextColor3 = Color3.fromRGB(240, 245, 255)
		title.TextScaled = true
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = "Tambahkan Tool?"
		title.Parent = root

		local body = Instance.new("TextLabel")
		body.Name = "Body"
		body.BackgroundTransparency = 1
		body.Position = UDim2.fromScale(0.08, 0.34)
		body.Size = UDim2.fromScale(0.84, 0.28)
		body.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
		body.TextColor3 = Color3.fromRGB(204, 214, 230)
		body.TextScaled = true
		body.TextWrapped = true
		body.TextXAlignment = Enum.TextXAlignment.Left
		body.TextYAlignment = Enum.TextYAlignment.Top
		body.Text = "Pilih YES untuk menambahkan tool ke loadout preparation."
		body.Parent = root

		local buttonRow = Instance.new("Frame")
		buttonRow.Name = "Buttons"
		buttonRow.BackgroundTransparency = 1
		buttonRow.AnchorPoint = Vector2.new(0.5, 1)
		buttonRow.Position = UDim2.fromScale(0.5, 0.9)
		buttonRow.Size = UDim2.fromScale(0.84, 0.24)
		buttonRow.Parent = root

		local function makeButton(name, color, posX)
			local button = Instance.new("TextButton")
			button.Name = name
			button.AnchorPoint = Vector2.new(0.5, 0.5)
			button.Position = UDim2.fromScale(posX, 0.5)
			button.Size = UDim2.fromScale(0.42, 0.92)
			button.BackgroundColor3 = color
			button.BorderSizePixel = 0
			button.AutoButtonColor = true
			button.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
			button.TextScaled = true
			button.Text = name
			local buttonCorner = Instance.new("UICorner")
			buttonCorner.CornerRadius = UDim.new(0, 10)
			buttonCorner.Parent = button
			button.Parent = buttonRow
			return button
		end

		preparationPromptYes = makeButton("YES", Color3.fromRGB(64, 156, 110), 0.25)
		preparationPromptNo = makeButton("NO", Color3.fromRGB(170, 82, 82), 0.75)

		preparationPromptYes.MouseButton1Click:Connect(function()
			sendPreparationPromptResponse("confirm")
			hidePreparationPrompt()
		end)
		preparationPromptNo.MouseButton1Click:Connect(function()
			sendPreparationPromptResponse("cancel")
			hidePreparationPrompt()
		end)

		preparationPromptTitle = title
		preparationPromptBody = body
	else
		preparationPromptTitle = root:FindFirstChild("Title")
		preparationPromptBody = root:FindFirstChild("Body")
		local buttons = root:FindFirstChild("Buttons")
		preparationPromptYes = buttons and buttons:FindFirstChild("YES") or preparationPromptYes
		preparationPromptNo = buttons and buttons:FindFirstChild("NO") or preparationPromptNo
	end

	preparationPromptGui = gui
	return gui
end

local function refreshPreparationPrompt()
	local toolType = tostring(LOCAL_PLAYER:GetAttribute(PREPARATION_PENDING_TOOL_ATTR) or "")
	local toolLabel = tostring(LOCAL_PLAYER:GetAttribute(PREPARATION_PENDING_LABEL_ATTR) or "")
	local source = tostring(LOCAL_PLAYER:GetAttribute(PREPARATION_PENDING_SOURCE_ATTR) or "")
	local response = tostring(LOCAL_PLAYER:GetAttribute(PREPARATION_PENDING_RESPONSE_ATTR) or "")
	local inMatch = LOCAL_PLAYER:GetAttribute("InMatch") == true
	local phase = tostring(LOCAL_PLAYER:GetAttribute("MatchLifecyclePhase") or "")

	if not inMatch or phase ~= "PreparationPhase" or toolType == "" or source ~= "WorldToolStation" then
		hidePreparationPrompt()
		return
	end
	if response:lower():match("^confirm") or response:lower():match("^cancel") then
		hidePreparationPrompt()
		return
	end
	if response ~= "" then
		return
	end

	local gui = ensurePreparationPromptGui()
	if not gui then
		return
	end

	preparationPromptState.visible = true
	preparationPromptState.toolType = toolType
	preparationPromptState.toolLabel = toolLabel
	preparationPromptState.source = source

	if preparationPromptTitle then
		preparationPromptTitle.Text = string.format("Tambahkan %s untuk investigasi?", toolLabel ~= "" and toolLabel or toolType)
	end
	if preparationPromptBody then
		preparationPromptBody.Text = "YES akan menambahkan tool ini ke loadout preparation. NO membatalkan tanpa mengubah loadout."
	end
	gui.Enabled = true
	if preparationPromptYes then
		preparationPromptYes.Active = true
		preparationPromptYes.AutoButtonColor = true
	end
	if preparationPromptNo then
		preparationPromptNo.Active = true
		preparationPromptNo.AutoButtonColor = true
	end
end

task.spawn(function()
	local playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui")
	local existing = playerGui:FindFirstChild("PreparationToolPromptUI")
	if existing and existing:IsA("ScreenGui") then
		preparationPromptGui = existing
	end
	refreshPreparationPrompt()
	LOCAL_PLAYER:GetAttributeChangedSignal(PREPARATION_PENDING_TOOL_ATTR):Connect(refreshPreparationPrompt)
	LOCAL_PLAYER:GetAttributeChangedSignal(PREPARATION_PENDING_LABEL_ATTR):Connect(refreshPreparationPrompt)
	LOCAL_PLAYER:GetAttributeChangedSignal(PREPARATION_PENDING_SOURCE_ATTR):Connect(refreshPreparationPrompt)
	LOCAL_PLAYER:GetAttributeChangedSignal(PREPARATION_PENDING_RESPONSE_ATTR):Connect(refreshPreparationPrompt)
	LOCAL_PLAYER:GetAttributeChangedSignal("InMatch"):Connect(refreshPreparationPrompt)
	LOCAL_PLAYER:GetAttributeChangedSignal("MatchLifecyclePhase"):Connect(refreshPreparationPrompt)
end)

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

local function hasActiveToolSelection()
	local equippedTool = tostring(LOCAL_PLAYER:GetAttribute("PasrahEquippedToolType") or "")
	if equippedTool ~= "" then
		return true
	end
	local focusTool = tostring(LOCAL_PLAYER:GetAttribute("PreparationFocusTool") or "")
	if focusTool ~= "" then
		return true
	end
	return false
end

local function hasVisibleJournalPanel()
	local playerGui = LOCAL_PLAYER:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return false
	end

	local journalGui = playerGui:FindFirstChild("JournalUI")
	if not (journalGui and journalGui:IsA("ScreenGui")) then
		return false
	end

	local mainPanel = journalGui:FindFirstChild("MainPanel")
	if mainPanel and mainPanel:IsA("GuiObject") and mainPanel.Visible == true then
		return true
	end

	return false
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.KeyCode ~= Enum.KeyCode.E then
		return
	end
	if gameProcessed then
		return
	end
	if UserInputService:GetFocusedTextBox() then
		return
	end
	if hasVisibleJournalPanel() then
		return
	end
	if LOCAL_PLAYER:GetAttribute("InMatch") ~= true
		or tostring(LOCAL_PLAYER:GetAttribute("MatchLifecyclePhase") or "") ~= "InvestigationPhase" then
		return
	end
	if hasActiveToolSelection() then
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

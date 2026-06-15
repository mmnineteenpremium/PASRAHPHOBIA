local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NpcDialogueService = {}
NpcDialogueService.__index = NpcDialogueService

local SCAN_INTERVAL_SECONDS = 5

local function ensureRemoteEvent()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	if not remoteFolder then
		remoteFolder = Instance.new("Folder")
		remoteFolder.Name = "RemoteEvents"
		remoteFolder.Parent = ReplicatedStorage
	end

	local remote = remoteFolder:FindFirstChild("NpcDialogueEvent")
	if remote and not remote:IsA("RemoteEvent") then
		warn("[NpcDialogueService] RemoteEvents.NpcDialogueEvent exists but is not a RemoteEvent")
		return nil
	end

	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = "NpcDialogueEvent"
		remote.Parent = remoteFolder
	end

	if remote then
		print("[NpcDialogueService] RemoteEvent ready:", remote:GetFullName())
	else
		warn("[NpcDialogueService] RemoteEvent GAGAL dibuat")
	end
	return remote
end

local function isReadyPrompt(prompt)
	if not prompt or not prompt:IsA("ProximityPrompt") then
		return false
	end
	if prompt.Name ~= "DialoguePrompt" then
		return false
	end
	local npc = prompt:FindFirstAncestorWhichIsA("Model")
	return npc ~= nil and npc:GetAttribute("DialogueReady") == true
end

local function getPromptProfile(npc)
	local role = npc and npc:GetAttribute("PasrahLobbyNpcRole")
	if role == "ShopKeeper" then
		return "Penjaga Toko", 6, "shopkeeper_root"
	elseif role == "Investigator" then
		return "Investigator", 7, "investigator_root"
	elseif role == "Guide" then
		return "Panduan Lobby", 7, "guide_root"
	elseif role == "TrainingGuide" then
		return "Training Zone", 7, "training_root"
	elseif role == "GardenKeeper" then
		return "Penjaga Taman", 7, "garden_root"
	elseif role == "Dukun" then
		return "Dukun", 8, "dukun_root"
	end
	return npc and npc.Name or "NPC", 8, "guide_root"
end

local function ensureDialoguePromptForNpc(npc)
	if not npc or not npc:IsA("Model") then
		return nil
	end
	if npc:GetAttribute("DialogueReady") ~= true then
		return nil
	end

	local dialogueId = npc:GetAttribute("PasrahNpcDialogueId")
	if type(dialogueId) ~= "string" or dialogueId == "" then
		local _, _, fallbackDialogueId = getPromptProfile(npc)
		dialogueId = fallbackDialogueId
	end

	local rootPart = npc.PrimaryPart or npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart", true)
	local pivotCFrame = npc:GetPivot()

	local promptParent = npc:FindFirstChild("DialogueTrigger")
	if not (promptParent and promptParent:IsA("BasePart")) then
		if promptParent then
			promptParent:Destroy()
		end
		promptParent = Instance.new("Part")
		promptParent.Name = "DialogueTrigger"
		promptParent.Anchored = false
		promptParent.CanCollide = false
		promptParent.CanTouch = false
		promptParent.CanQuery = false
		promptParent.Transparency = 1
		promptParent.Size = Vector3.new(2, 3, 2)
		promptParent.Massless = true
		promptParent.Anchored = rootPart == nil
		promptParent.CFrame = rootPart and rootPart.CFrame or pivotCFrame
		promptParent.Parent = npc

		if rootPart then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = promptParent
			weld.Part1 = rootPart
			weld.Parent = promptParent
		end
	end

	local prompt = promptParent:FindFirstChild("DialoguePrompt")
	if not (prompt and prompt:IsA("ProximityPrompt")) then
		if prompt then
			prompt:Destroy()
		end
		local objectText, maxActivationDistance = getPromptProfile(npc)
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "DialoguePrompt"
		prompt.ActionText = "Bicara"
		prompt.ObjectText = objectText
		prompt.MaxActivationDistance = maxActivationDistance
		prompt.Exclusivity = Enum.ProximityPromptExclusivity.OneGlobally
		prompt.RequiresLineOfSight = false
		prompt.HoldDuration = 0
		prompt.Parent = promptParent
	end

	prompt:SetAttribute("PasrahNpcDialogueId", dialogueId)
	npc:SetAttribute("PasrahNpcDialogueId", dialogueId)
	npc:SetAttribute("DialogueReady", true)
	prompt:SetAttribute("NpcDialogueBound", true)
	return prompt
end

function NpcDialogueService.new(deps)
	local self = setmetatable({}, NpcDialogueService)
	self._deps = deps or {}
	self._remoteEvent = nil
	self._connections = {}
	self._boundPrompts = {}
	self._started = false
	return self
end

function NpcDialogueService:_bindPrompt(prompt)
	if self._boundPrompts[prompt] then
		return
	end

	local dialogueId = prompt:GetAttribute("PasrahNpcDialogueId")
	if type(dialogueId) ~= "string" or dialogueId == "" then
		return
	end
	if prompt:GetAttribute("NpcDialogueBound") == true then
		return
	end

	self._boundPrompts[prompt] = true
	table.insert(self._connections, prompt.Triggered:Connect(function(player)
		if not player or not player:IsA("Player") then
			warn("[NpcDialogueService] Triggered tapi player invalid")
			return
		end

		self._remoteEvent = self._remoteEvent or ensureRemoteEvent()

		if not self._remoteEvent then
			warn("[NpcDialogueService] RemoteEvent nil, FireClient dibatalkan")
			return
		end

		local npc = prompt:FindFirstAncestorWhichIsA("Model")
		if not npc then
			warn("[NpcDialogueService] NPC Model tidak ditemukan dari prompt")
			return
		end

		-- Log konfirmasi
		print("[NpcDialogueService] FireClient OPEN →",
			player.Name, dialogueId, npc.Name)

		self._remoteEvent:FireClient(player, "OPEN", dialogueId, npc)
	end))
end

function NpcDialogueService:_scanForPrompts()
	for prompt in pairs(self._boundPrompts) do
		if not prompt or prompt.Parent == nil then
			self._boundPrompts[prompt] = nil
		end
	end

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Model") and descendant:GetAttribute("DialogueReady") == true then
			local prompt = ensureDialoguePromptForNpc(descendant)
			if prompt then
				self:_bindPrompt(prompt)
			end
		end
	end

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and isReadyPrompt(descendant) then
			self:_bindPrompt(descendant)
		end
	end
end

function NpcDialogueService:_startScanLoop()
	task.spawn(function()
		while self._started == true do
			self:_scanForPrompts()
			task.wait(SCAN_INTERVAL_SECONDS)
		end
	end)
end

function NpcDialogueService:Init()
	self._remoteEvent = ensureRemoteEvent()
	self:_scanForPrompts()
end

function NpcDialogueService:Start()
	if self._started then
		return
	end
	self._started = true
	self:_scanForPrompts()
	self:_startScanLoop()

	if not self._workspaceConnection then
		self._workspaceConnection = Workspace.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("ProximityPrompt") and isReadyPrompt(descendant) then
				self:_bindPrompt(descendant)
			end
		end)
	end

	if self._remoteEvent and not self._closeConnection then
		self._closeConnection = self._remoteEvent.OnServerEvent:Connect(function(player, action)
			if action == "CLOSE" then
				return
			end
			if action == "OPEN" then
				return
			end
		end)
	end
end

function NpcDialogueService:Stop()
	self._started = false
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	if self._closeConnection then
		self._closeConnection:Disconnect()
		self._closeConnection = nil
	end
	if self._workspaceConnection then
		self._workspaceConnection:Disconnect()
		self._workspaceConnection = nil
	end
	table.clear(self._boundPrompts)
end

return NpcDialogueService

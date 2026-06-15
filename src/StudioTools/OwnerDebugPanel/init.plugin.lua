-- DEV TOOL - REMOVE BEFORE PRODUCTION
-- Checklist:
-- - Ghost size editor (scale X/Y/Z via PivotTo)
-- - 7 animation buttons (GhostIdle/Roam/Hunt/Manifest/Attack/Jumpscare/Cooldown)
-- - Transparency slider (0.0-1.0, apply to all BasePart)
-- - Ghost state override buttons
-- - Ghost movement debug display (readonly)
-- - Ghost type selector + spawn/despawn
-- - Audio SFX preview per ghost type
-- - Preparation spawn points visualization (4 titik)
-- - Ghost position (X/Y/Z) readout

local RunService = game:GetService("RunService")
if not RunService:IsEdit() then
	return
end

local Selection = game:GetService("Selection")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local InsertService = game:GetService("InsertService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")

local shared = ReplicatedStorage:WaitForChild("Shared")
local configFolder = shared:WaitForChild("Config")
local OwnerCheatConfig = require(configFolder:WaitForChild("OwnerCheatConfig"))

local ghostAnimationRoot = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Animations"):WaitForChild("Ghosts")
local ghostAudioRoot = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Audio"):WaitForChild("Ghost")
local ghostModelsRoot = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Models"):WaitForChild("Ghosts")
local canonicalGhostModels = nil
pcall(function()
	canonicalGhostModels = require(ghostModelsRoot:WaitForChild("CanonicalGhostModels"))
end)

local pluginName = "OwnerDebugPanel"
local TOOLBAR_NAME = "Pasrah Studio Tools"
local WIDGET_ID = "OwnerDebugPanelDockWidget_v1"
local WORKSPACE_ROOT = "__OwnerDebugPanel"
local SPAWN_VISUAL_ROOT = "__OwnerDebugPanelSpawnPoints"

local GHOST_STATES = { "Idle", "Roaming", "Hunting", "Manifestation", "Cooldown" }
local GHOST_ANIMS = {
	"GhostIdle",
	"GhostRoam",
	"GhostHunt",
	"GhostManifest",
	"GhostAttack",
	"GhostJumpscare",
	"GhostCooldown",
}

local COLORS = {
	bg = Color3.fromRGB(24, 27, 34),
	panel = Color3.fromRGB(32, 36, 45),
	panel2 = Color3.fromRGB(40, 45, 56),
	rail = Color3.fromRGB(59, 64, 77),
	accent = Color3.fromRGB(196, 61, 87),
	ok = Color3.fromRGB(84, 170, 113),
	warn = Color3.fromRGB(212, 160, 72),
	text = Color3.fromRGB(243, 245, 248),
	muted = Color3.fromRGB(174, 181, 192),
}

local function round(n)
	return math.floor((n * 100) + 0.5) / 100
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
	return c
end

local function stroke(parent, color)
	local s = Instance.new("UIStroke")
	s.Color = color or COLORS.rail
	s.Thickness = 1
	s.Parent = parent
	return s
end

local function pad(parent, all)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, all or 8)
	p.PaddingBottom = UDim.new(0, all or 8)
	p.PaddingLeft = UDim.new(0, all or 8)
	p.PaddingRight = UDim.new(0, all or 8)
	p.Parent = parent
	return p
end

local function textLabel(parent, text, size, bold, color)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	label.TextSize = size or 13
	label.TextColor3 = color or COLORS.text
	label.Text = text or ""
	label.Parent = parent
	return label
end

local function button(parent, text)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = true
	b.BackgroundColor3 = COLORS.panel2
	b.Font = Enum.Font.GothamBold
	b.TextSize = 12
	b.TextColor3 = COLORS.text
	b.Text = text
	corner(b, 6)
	stroke(b)
	b.Parent = parent
	return b
end

local function box(parent, placeholder)
	local tb = Instance.new("TextBox")
	tb.ClearTextOnFocus = false
	tb.BackgroundColor3 = COLORS.bg
	tb.Font = Enum.Font.Gotham
	tb.TextSize = 12
	tb.TextColor3 = COLORS.text
	tb.PlaceholderColor3 = COLORS.muted
	tb.PlaceholderText = placeholder or ""
	tb.Text = ""
	corner(tb, 6)
	stroke(tb)
	tb.Parent = parent
	return tb
end

local function listLayout(parent, padding)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, padding or 6)
	layout.Parent = parent
	return layout
end

local function findSelectedModel()
	for _, inst in ipairs(Selection:Get()) do
		if inst:IsA("Model") then
			return inst
		end
		local ancestor = inst:FindFirstAncestorOfClass("Model")
		if ancestor then
			return ancestor
		end
	end
	local root = Workspace:FindFirstChild(WORKSPACE_ROOT)
	if root then
		for _, child in ipairs(root:GetChildren()) do
			if child:IsA("Model") then
				return child
			end
		end
	end
	return nil
end

local function ensureWorkspaceRoot()
	local root = Workspace:FindFirstChild(WORKSPACE_ROOT)
	if not root then
		root = Instance.new("Folder")
		root.Name = WORKSPACE_ROOT
		root.Parent = Workspace
	end
	return root
end

local function ensureSpawnRoot()
	local root = Workspace:FindFirstChild(SPAWN_VISUAL_ROOT)
	if not root then
		root = Instance.new("Folder")
		root.Name = SPAWN_VISUAL_ROOT
		root.Parent = Workspace
	end
	return root
end

local function vectorFromModel(model)
	if not model or not model:IsA("Model") then
		return nil
	end
	local ok, pivot = pcall(function()
		return model:GetPivot()
	end)
	if ok and typeof(pivot) == "CFrame" then
		return pivot.Position
	end
	return nil
end

local function ensureGhostPrimaryPart(model)
	if not (model and model:IsA("Model")) then
		return nil
	end
	local primaryPart = model.PrimaryPart
	if primaryPart and primaryPart:IsDescendantOf(model) and primaryPart:IsA("BasePart") then
		return primaryPart
	end
	local root = model:FindFirstChild("HumanoidRootPart", true)
	if root and root:IsA("BasePart") then
		model.PrimaryPart = root
		return root
	end
	local firstBasePart = model:FindFirstChildWhichIsA("BasePart", true)
	if firstBasePart then
		model.PrimaryPart = firstBasePart
		return firstBasePart
	end
	return nil
end

local function ensureGhostRig(model)
	if not (model and model:IsA("Model")) then
		return nil
	end

	local rootPart = ensureGhostPrimaryPart(model)
	if not rootPart then
		rootPart = Instance.new("Part")
		rootPart.Name = "HumanoidRootPart"
		rootPart.Anchored = true
		rootPart.CanCollide = false
		rootPart.CanTouch = false
		rootPart.CanQuery = false
		rootPart.CastShadow = false
		rootPart.Transparency = 1
		rootPart.Size = Vector3.new(2, 2, 1)
		rootPart.Parent = model
		model.PrimaryPart = rootPart
	end

	return getAnimator(model)
end

local function hasRiggedGhostSurface(model)
	if not (model and model:IsA("Model")) then
		return false
	end
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("Bone") or descendant:IsA("AnimationController") then
			return true
		end
		if descendant:IsA("MeshPart") then
			local ok, hasSkinnedMesh = pcall(function()
				return descendant.HasSkinnedMesh
			end)
			if ok and hasSkinnedMesh == true then
				return true
			end
		end
	end
	return false
end

local function scaleModelWithPivot(model, scale)
	if not model or not model:IsA("Model") then
		return false, "no model"
	end

	local pivot = model:GetPivot()
	local position = pivot.Position
	local _, _, _, r00, r01, r02, r10, r11, r12, r20, r21, r22 = pivot:GetComponents()
	local rotation = CFrame.new(0, 0, 0, r00, r01, r02, r10, r11, r12, r20, r21, r22)

	local useUniformScale = hasRiggedGhostSurface(model)
	if useUniformScale and type(model.ScaleTo) == "function" then
		local uniformScale = math.max((scale.X * scale.Y * scale.Z) ^ (1 / 3), 0.001)
		if uniformScale > 0 then
			local ok = pcall(function()
				model:ScaleTo(uniformScale)
			end)
			if ok then
				model:PivotTo(CFrame.new(position) * rotation)
				return true
			end
		end
	end

	local rootPart = ensureGhostPrimaryPart(model)
	if not rootPart then
		return false, "no basepart"
	end
	local parts = {}
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	local rootPos = rootPart.Position
	for _, part in ipairs(parts) do
		local offset = part.Position - rootPos
		local scaled = Vector3.new(offset.X * scale.X, offset.Y * scale.Y, offset.Z * scale.Z)
		local _, _, _, a00, a01, a02, a10, a11, a12, a20, a21, a22 = part.CFrame:GetComponents()
		local partRotation = CFrame.new(0, 0, 0, a00, a01, a02, a10, a11, a12, a20, a21, a22)
		part.CFrame = CFrame.new(rootPos + scaled) * partRotation
		part.Size = Vector3.new(part.Size.X * scale.X, part.Size.Y * scale.Y, part.Size.Z * scale.Z)
	end
	model:PivotTo(CFrame.new(position) * rotation)
	return true
end

local function applyTransparency(model, alpha)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant.Name ~= "HumanoidRootPart" then
			descendant.Transparency = alpha
		end
	end
end

local function setStateAttributes(model, stateName)
	model:SetAttribute("RuntimeGhostState", stateName)
	model:SetAttribute("RuntimeGhostStateOverride", stateName)
end

local function isLoopedAnim(animName)
	return animName == "GhostIdle" or animName == "GhostRoam" or animName == "GhostHunt"
end

local function first(list, fallback)
	return type(list) == "table" and list[1] or fallback
end

local function collectAnimationContainer(ghostType)
	local folder = ghostAnimationRoot:FindFirstChild(ghostType)
	if folder then
		return folder
	end
	return nil
end

local function resolveAudioSource(ghostType, stateName)
	local candidates = {
		ghostType .. "_SFX",
		ghostType .. "_SFX.model.json",
		ghostType .. ".model.json",
		stateName .. "_01",
		"GhostManifest_01",
		"GhostWhisper_01",
		"HuntStart_01",
	}
	for _, child in ipairs(ghostAudioRoot:GetChildren()) do
		if child.Name == candidates[1] then
			return child
		end
	end
	for _, name in ipairs(candidates) do
		local found = ghostAudioRoot:FindFirstChild(name)
		if found then
			return found
		end
	end
	return nil
end

local function soundIdFromAudioInstance(audioInst)
	if not audioInst then
		return nil
	end
	if audioInst:IsA("Sound") then
		return tostring(audioInst.SoundId or "")
	end
	if audioInst:IsA("Folder") or audioInst:IsA("Model") then
		local sound = audioInst:FindFirstChildWhichIsA("Sound", true)
		if sound then
			return tostring(sound.SoundId or sound:GetAttribute("AudioContent") or "")
		end
	end
	return tostring(audioInst:GetAttribute("AudioContent") or "")
end

local function resolveGhostTemplate(ghostType)
	local folder = ghostModelsRoot:FindFirstChild(ghostType)
	if folder then
		return folder
	end
	if canonicalGhostModels and type(canonicalGhostModels.ghosts) == "table" then
		local assetId = canonicalGhostModels.ghosts[ghostType]
		if type(assetId) == "string" and assetId ~= "" then
			return assetId
		end
	end
	return nil
end

local function cloneGhostTemplate(ghostType)
	local template = resolveGhostTemplate(ghostType)
	local function normalizeClone(instance)
		if typeof(instance) ~= "Instance" then
			return nil
		end
		if instance:IsA("Model") then
			ensureGhostRig(instance)
			return instance
		end
		local wrapper = Instance.new("Model")
		wrapper.Name = tostring(ghostType or "Ghost") .. "_Template"
		instance.Parent = wrapper
		ensureGhostRig(wrapper)
		return wrapper
	end
	if typeof(template) == "Instance" then
		return normalizeClone(template:Clone())
	end
	if type(template) == "string" and template ~= "" then
		local ok, assetModel = pcall(function()
			return InsertService:LoadAsset(tonumber(template:match("%d+")) or 0)
		end)
		if ok and assetModel then
			local child = assetModel:FindFirstChildWhichIsA("Model", true) or assetModel:FindFirstChildWhichIsA("BasePart", true)
			if child then
				local clone = normalizeClone(child:Clone())
				assetModel:Destroy()
				return clone
			end
			local clone = normalizeClone(assetModel)
			return clone or assetModel
		end
	end
	local model = Instance.new("Model")
	model.Name = ghostType .. "_Placeholder"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.Size = Vector3.new(2, 2, 1)
	root.Color = Color3.fromRGB(80, 80, 90)
	root.Parent = model
	model.PrimaryPart = root
	ensureGhostRig(model)
	model.Parent = nil
	return model
end

local function getAnimator(model)
	local humanoid = model and model:FindFirstChildWhichIsA("Humanoid", true)
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			return animator
		end
		animator = Instance.new("Animator")
		animator.Parent = humanoid
		return animator
	end
	local controller = model and model:FindFirstChildWhichIsA("AnimationController", true)
	if controller then
		local animator = controller:FindFirstChildOfClass("Animator")
		if animator then
			return animator
		end
		animator = Instance.new("Animator")
		animator.Parent = controller
		return animator
	end
	if typeof(model) == "Instance" and model:IsA("Model") then
		controller = Instance.new("AnimationController")
		controller.Name = "GhostAnimationController"
		controller.Parent = model
		local animator = Instance.new("Animator")
		animator.Parent = controller
		return animator
	end
	return nil
end

local OwnerDebugPanel = {}
OwnerDebugPanel.__index = OwnerDebugPanel

function OwnerDebugPanel.new()
	local self = setmetatable({}, OwnerDebugPanel)
	self.plugin = plugin
	self.selectedGhostType = first(OwnerCheatConfig.CANONICAL_GHOSTS, "Pocong")
	self.selectedAnimation = "GhostIdle"
	self.selectedState = "Idle"
	self.selectedModel = nil
	self.scale = Vector3.new(1, 1, 1)
	self.transparency = 0.35
	self.connections = {}
	self.currentAudio = nil
	self.currentWidget = nil
	self.toolbar = nil
	self.root = nil
	return self
end

function OwnerDebugPanel:_connect(signal, fn)
	local conn = signal:Connect(fn)
	table.insert(self.connections, conn)
	return conn
end

function OwnerDebugPanel:_clearConnections()
	for _, conn in ipairs(self.connections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	table.clear(self.connections)
end

function OwnerDebugPanel:_setStatus(text, color)
	if self.statusLabel then
		self.statusLabel.Text = tostring(text or "")
		self.statusLabel.TextColor3 = color or COLORS.muted
	end
end

function OwnerDebugPanel:_refreshSelection()
	self.selectedModel = findSelectedModel()
	local model = self.selectedModel
	if model then
		self._modelLabel.Text = ("Selected: %s"):format(model:GetFullName())
	else
		self._modelLabel.Text = "Selected: none"
	end
	local pos = vectorFromModel(model)
	if pos then
		self._positionLabel.Text = ("Ghost position: X %.2f | Y %.2f | Z %.2f"):format(pos.X, pos.Y, pos.Z)
	else
		self._positionLabel.Text = "Ghost position: n/a"
	end
	if model then
		local target = model:GetAttribute("TargetPosition")
		self._targetLabel.Text = "Target Position: " .. tostring(target or "n/a")
		self._speedLabel.Text = "Move Speed: " .. tostring(model:GetAttribute("MoveSpeed") or "n/a")
		self._navLabel.Text = "Navigation Mode: " .. tostring(model:GetAttribute("NavigationMode") or "n/a")
		self._motionLabel.Text = "Motion State: " .. tostring(model:GetAttribute("MotionState") or "n/a")
	else
		self._targetLabel.Text = "Target Position: n/a"
		self._speedLabel.Text = "Move Speed: n/a"
		self._navLabel.Text = "Navigation Mode: n/a"
		self._motionLabel.Text = "Motion State: n/a"
	end
end

function OwnerDebugPanel:_applyTransparency()
	local model = self.selectedModel
	if not model then
		self:_setStatus("No model selected", COLORS.warn)
		return
	end
	applyTransparency(model, self.transparency)
	self:_setStatus(("Transparency %.2f applied"):format(self.transparency), COLORS.ok)
end

function OwnerDebugPanel:_applyScale()
	local model = self.selectedModel
	if not model then
		self:_setStatus("No model selected", COLORS.warn)
		return
	end
	ensureGhostRig(model)
	local ok, err = scaleModelWithPivot(model, self.scale)
	if ok then
		self:_setStatus(("Scale applied %.2f %.2f %.2f"):format(self.scale.X, self.scale.Y, self.scale.Z), COLORS.ok)
	else
		self:_setStatus("Scale failed: " .. tostring(err), COLORS.warn)
	end
end

function OwnerDebugPanel:_applyState(stateName)
	local model = self.selectedModel
	if not model then
		self:_setStatus("No model selected", COLORS.warn)
		return
	end
	setStateAttributes(model, stateName)
	self.selectedState = stateName
	self:_setStatus("State set to " .. stateName, COLORS.ok)
	self:_refreshSelection()
end

function OwnerDebugPanel:_playAnimation(animName)
	local model = self.selectedModel
	if not model then
		self:_setStatus("No model selected", COLORS.warn)
		return
	end
	ensureGhostRig(model)
	local animator = getAnimator(model)
	if not animator then
		self:_setStatus("Animator not found", COLORS.warn)
		return
	end
	local folder = collectAnimationContainer(self.selectedGhostType)
	if not folder then
		self:_setStatus("Animation folder missing for " .. self.selectedGhostType, COLORS.warn)
		return
	end
	local anim = folder:FindFirstChild(animName)
	if not anim then
		self:_setStatus("Animation missing: " .. animName, COLORS.warn)
		return
	end
	local track = animator:LoadAnimation(anim)
	track.Looped = isLoopedAnim(animName)
	track:Play()
	self:_setStatus(("Played %s for %s"):format(animName, self.selectedGhostType), COLORS.ok)
end

function OwnerDebugPanel:_previewAudio(ghostType)
	local source = resolveAudioSource(ghostType, self.selectedAnimation)
	local soundId = soundIdFromAudioInstance(source)
	if not soundId or soundId == "" then
		self:_setStatus("No SFX source for " .. ghostType, COLORS.warn)
		return
	end
	if self.currentAudio then
		pcall(function()
			self.currentAudio:Destroy()
		end)
	end
	local sound = Instance.new("Sound")
	sound.Name = "OwnerDebugPanelGhostPreview"
	sound.SoundId = soundId
	sound.Volume = 0.75
	sound.Parent = SoundService
	sound:Play()
	self.currentAudio = sound
	self:_setStatus(("Previewed audio for %s"):format(ghostType), COLORS.ok)
end

function OwnerDebugPanel:_spawnGhost()
	local root = ensureWorkspaceRoot()
	local model = cloneGhostTemplate(self.selectedGhostType)
	model.Name = "OwnerDebugPanel_" .. self.selectedGhostType
	model.Parent = root
	self.selectedModel = model
	self:_applyTransparency()
	self:_applyScale()
	self:_applyState(self.selectedState)
	self:_refreshSelection()
	self:_setStatus("Spawned " .. self.selectedGhostType, COLORS.ok)
end

function OwnerDebugPanel:_despawnGhost()
	local root = Workspace:FindFirstChild(WORKSPACE_ROOT)
	if not root then
		return
	end
	local selectedModel = self.selectedModel
	pcall(function()
		root:ClearAllChildren()
	end)
	if selectedModel and selectedModel.Parent then
		pcall(function()
			selectedModel:Destroy()
		end)
	end
	self.selectedModel = nil
	self:_refreshSelection()
	self:_setStatus("Despawned ghost placeholders", COLORS.ok)
end

function OwnerDebugPanel:_visualizeSpawnPoints()
	local root = ensureSpawnRoot()
	root:ClearAllChildren()
	for index, record in ipairs(OwnerCheatConfig.GHOST_SPAWN_LOCATIONS or {}) do
		local part = Instance.new("Part")
		part.Name = "SpawnPoint_" .. tostring(record.id or index)
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Material = Enum.Material.Neon
		part.Color = Color3.fromRGB(180, 90, 255)
		part.Size = Vector3.new(0.75, 0.75, 0.75)
		part.Transparency = 0.25
		part.Parent = root
		local label = Instance.new("BillboardGui")
		label.AlwaysOnTop = true
		label.Size = UDim2.new(0, 160, 0, 38)
		label.StudsOffset = Vector3.new(0, 2, 0)
		label.Parent = part
		textLabel(label, tostring(record.label or record.id or "spawn"), 12, true, COLORS.text).Size = UDim2.new(1, 0, 1, 0)
		part.Position = Vector3.new(index * 5, 4, 0)
	end
	self:_setStatus("Spawn indicators refreshed", COLORS.ok)
end

function OwnerDebugPanel:_buildSlider(container, title, initial, minValue, maxValue, onChanged)
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 0, 54)
	frame.Parent = container

	local titleRow = Instance.new("Frame")
	titleRow.BackgroundTransparency = 1
	titleRow.Size = UDim2.new(1, 0, 0, 20)
	titleRow.Parent = frame

	local titleLabel = textLabel(titleRow, title, 12, true)
	titleLabel.Size = UDim2.new(0.55, 0, 1, 0)

	local valueLabel = textLabel(titleRow, tostring(round(initial)), 12, true, COLORS.muted)
	valueLabel.TextXAlignment = Enum.TextXAlignment.Right
	valueLabel.Position = UDim2.new(0.55, 0, 0, 0)
	valueLabel.Size = UDim2.new(0.45, 0, 1, 0)

	local rail = Instance.new("Frame")
	rail.Name = title .. "Rail"
	rail.BackgroundColor3 = COLORS.rail
	rail.BorderSizePixel = 0
	rail.Position = UDim2.new(0, 0, 0, 28)
	rail.Size = UDim2.new(1, 0, 0, 10)
	rail.Parent = frame
	corner(rail, 5)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = COLORS.accent
	fill.BorderSizePixel = 0
	fill.Size = UDim2.new(0, 0, 1, 0)
	fill.Parent = rail
	corner(fill, 5)

	local knob = Instance.new("TextButton")
	knob.Text = ""
	knob.AutoButtonColor = false
	knob.BackgroundColor3 = COLORS.text
	knob.Size = UDim2.new(0, 16, 0, 16)
	knob.Parent = rail
	corner(knob, 8)

	local dragging = false
	local value = initial

	local function clampValue(v)
		v = math.clamp(v, minValue, maxValue)
		return v
	end

	local function setValue(v, fire)
		value = clampValue(v)
		local alpha = (value - minValue) / math.max((maxValue - minValue), 0.0001)
		fill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, -8, 0.5, -8)
		valueLabel.Text = tostring(round(value))
		if fire and onChanged then
			onChanged(value)
		end
	end

	local function updateFromX(x)
		local alpha = math.clamp((x - rail.AbsolutePosition.X) / math.max(rail.AbsoluteSize.X, 1), 0, 1)
		setValue(minValue + (maxValue - minValue) * alpha, true)
	end

	self:_connect(rail.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			updateFromX(input.Position.X)
		end
	end)
	self:_connect(rail.InputEnded, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	self:_connect(UserInputService.InputChanged, function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			updateFromX(input.Position.X)
		end
	end)
	setValue(initial, false)
	return frame, function() return value end, setValue
end

function OwnerDebugPanel:_build()
	if self.currentWidget then
		self.currentWidget.Enabled = true
		print("[OwnerDebugPanel] widget reopened")
		return
	end

	local widgetInfo = DockWidgetPluginGuiInfo.new(
		Enum.InitialDockState.Right,
		false,
		false,
		420,
		720,
		320,
		480
	)
	local widget = self.plugin:CreateDockWidgetPluginGuiAsync(WIDGET_ID, widgetInfo)
	widget.Title = "OwnerDebugPanel"
	widget.Enabled = false
	widget.Name = "OwnerDebugPanel"
	self.currentWidget = widget
	print("[OwnerDebugPanel] widget created")

	local root = Instance.new("Frame")
	root.BackgroundColor3 = COLORS.bg
	root.Size = UDim2.new(1, 0, 1, 0)
	root.Parent = widget
	pad(root, 10)
	listLayout(root, 10)

	local header = Instance.new("Frame")
	header.BackgroundTransparency = 1
	header.Size = UDim2.new(1, 0, 0, 54)
	header.Parent = root
	listLayout(header, 4)

	textLabel(header, "OwnerDebugPanel", 20, true).Size = UDim2.new(1, 0, 0, 26)
	textLabel(header, "DEV TOOL - REMOVE BEFORE PRODUCTION", 11, true, COLORS.warn).Size = UDim2.new(1, 0, 0, 18)

	local modelCard = Instance.new("Frame")
	modelCard.BackgroundColor3 = COLORS.panel
	modelCard.Size = UDim2.new(1, 0, 0, 96)
	modelCard.Parent = root
	corner(modelCard, 8)
	stroke(modelCard)
	pad(modelCard, 10)
	listLayout(modelCard, 4)
	self._modelLabel = textLabel(modelCard, "Selected: none", 12, true)
	self._positionLabel = textLabel(modelCard, "Ghost position: n/a", 12, false)
	self._targetLabel = textLabel(modelCard, "Target Position: n/a", 12, false)
	self._speedLabel = textLabel(modelCard, "Move Speed: n/a", 12, false)
	self._navLabel = textLabel(modelCard, "Navigation Mode: n/a", 12, false)
	self._motionLabel = textLabel(modelCard, "Motion State: n/a", 12, false)

	local configCard = Instance.new("Frame")
	configCard.BackgroundColor3 = COLORS.panel
	configCard.Size = UDim2.new(1, 0, 0, 188)
	configCard.Parent = root
	corner(configCard, 8)
	stroke(configCard)
	pad(configCard, 10)
	listLayout(configCard, 8)

	textLabel(configCard, "Ghost Type", 13, true).Size = UDim2.new(1, 0, 0, 18)
	local typeButton = button(configCard, self.selectedGhostType)
	typeButton.Size = UDim2.new(1, 0, 0, 30)
	typeButton.MouseButton1Click:Connect(function()
		local ghosts = OwnerCheatConfig.CANONICAL_GHOSTS
		local index = table.find(ghosts, self.selectedGhostType) or 1
		index = index % #ghosts + 1
		self.selectedGhostType = ghosts[index]
		typeButton.Text = self.selectedGhostType
	end)

	local actionRow = Instance.new("Frame")
	actionRow.BackgroundTransparency = 1
	actionRow.Size = UDim2.new(1, 0, 0, 32)
	actionRow.Parent = configCard
	listLayout(actionRow, 6)
	local spawnBtn = button(actionRow, "Spawn")
	spawnBtn.Size = UDim2.new(0.5, -3, 1, 0)
	spawnBtn.MouseButton1Click:Connect(function()
		self:_spawnGhost()
	end)
	local despawnBtn = button(actionRow, "Despawn")
	despawnBtn.Size = UDim2.new(0.5, -3, 1, 0)
	despawnBtn.MouseButton1Click:Connect(function()
		self:_despawnGhost()
	end)

	textLabel(configCard, "Ghost State Override", 13, true).Size = UDim2.new(1, 0, 0, 18)
	local stateRow = Instance.new("Frame")
	stateRow.BackgroundTransparency = 1
	stateRow.Size = UDim2.new(1, 0, 0, 72)
	stateRow.Parent = configCard
	local stateGrid = Instance.new("UIGridLayout")
	stateGrid.CellSize = UDim2.new(0.5, -3, 0, 32)
	stateGrid.CellPadding = UDim2.new(0, 6, 0, 6)
	stateGrid.SortOrder = Enum.SortOrder.LayoutOrder
	stateGrid.Parent = stateRow
	for _, stateName in ipairs(GHOST_STATES) do
		local btn = button(stateRow, stateName)
		btn.MouseButton1Click:Connect(function()
			self:_applyState(stateName)
		end)
	end

	local sliderCard = Instance.new("Frame")
	sliderCard.BackgroundColor3 = COLORS.panel
	sliderCard.Size = UDim2.new(1, 0, 0, 220)
	sliderCard.Parent = root
	corner(sliderCard, 8)
	stroke(sliderCard)
	pad(sliderCard, 10)
	listLayout(sliderCard, 8)
	textLabel(sliderCard, "Ghost Size Editor", 13, true).Size = UDim2.new(1, 0, 0, 18)

	local _, getScaleX, setScaleX = self:_buildSlider(sliderCard, "Scale X", self.scale.X, 0.1, 4, function(v)
		self.scale = Vector3.new(v, self.scale.Y, self.scale.Z)
	end)
	local _, getScaleY, setScaleY = self:_buildSlider(sliderCard, "Scale Y", self.scale.Y, 0.1, 4, function(v)
		self.scale = Vector3.new(self.scale.X, v, self.scale.Z)
	end)
	local _, getScaleZ, setScaleZ = self:_buildSlider(sliderCard, "Scale Z", self.scale.Z, 0.1, 4, function(v)
		self.scale = Vector3.new(self.scale.X, self.scale.Y, v)
	end)
	local applyScaleBtn = button(sliderCard, "Apply Scale")
	applyScaleBtn.Size = UDim2.new(1, 0, 0, 30)
	applyScaleBtn.MouseButton1Click:Connect(function()
		self:_applyScale()
	end)

	textLabel(sliderCard, "Transparency", 13, true).Size = UDim2.new(1, 0, 0, 18)
	local _, getTrans, setTrans = self:_buildSlider(sliderCard, "Alpha", self.transparency, 0, 1, function(v)
		self.transparency = v
	end)
	local applyTransBtn = button(sliderCard, "Apply Transparency")
	applyTransBtn.Size = UDim2.new(1, 0, 0, 30)
	applyTransBtn.MouseButton1Click:Connect(function()
		self:_applyTransparency()
	end)

	local animCard = Instance.new("Frame")
	animCard.BackgroundColor3 = COLORS.panel
	animCard.Size = UDim2.new(1, 0, 0, 252)
	animCard.Parent = root
	corner(animCard, 8)
	stroke(animCard)
	pad(animCard, 10)
	listLayout(animCard, 8)
	textLabel(animCard, "Animation Preview", 13, true).Size = UDim2.new(1, 0, 0, 18)
	for _, animName in ipairs(GHOST_ANIMS) do
		local animBtn = button(animCard, animName)
		animBtn.Size = UDim2.new(1, 0, 0, 28)
		animBtn.MouseButton1Click:Connect(function()
			self.selectedAnimation = animName
			self:_playAnimation(animName)
		end)
	end

	local sfxCard = Instance.new("Frame")
	sfxCard.BackgroundColor3 = COLORS.panel
	sfxCard.Size = UDim2.new(1, 0, 0, 280)
	sfxCard.Parent = root
	corner(sfxCard, 8)
	stroke(sfxCard)
	pad(sfxCard, 10)
	listLayout(sfxCard, 8)
	textLabel(sfxCard, "Audio Preview", 13, true).Size = UDim2.new(1, 0, 0, 18)
	local previewRow = Instance.new("Frame")
	previewRow.BackgroundTransparency = 1
	previewRow.Size = UDim2.new(1, 0, 0, 210)
	previewRow.Parent = sfxCard
	local previewGrid = Instance.new("UIGridLayout")
	previewGrid.CellSize = UDim2.new(0.5, -3, 0, 26)
	previewGrid.CellPadding = UDim2.new(0, 6, 0, 6)
	previewGrid.SortOrder = Enum.SortOrder.LayoutOrder
	previewGrid.Parent = previewRow
	for _, ghostType in ipairs(OwnerCheatConfig.CANONICAL_GHOSTS) do
		local sfxBtn = button(previewRow, ghostType)
		sfxBtn.MouseButton1Click:Connect(function()
			self.selectedGhostType = ghostType
			typeButton.Text = ghostType
			self:_previewAudio(ghostType)
		end)
	end

	local footerCard = Instance.new("Frame")
	footerCard.BackgroundColor3 = COLORS.panel
	footerCard.Size = UDim2.new(1, 0, 0, 104)
	footerCard.Parent = root
	corner(footerCard, 8)
	stroke(footerCard)
	pad(footerCard, 10)
	listLayout(footerCard, 8)
	textLabel(footerCard, "Preparation Spawn Points", 13, true).Size = UDim2.new(1, 0, 0, 18)
	local visualizeBtn = button(footerCard, "Refresh Spawn Visuals")
	visualizeBtn.Size = UDim2.new(1, 0, 0, 30)
	visualizeBtn.MouseButton1Click:Connect(function()
		self:_visualizeSpawnPoints()
	end)

	self.statusLabel = textLabel(root, "", 12, true, COLORS.muted)
	self.statusLabel.Size = UDim2.new(1, 0, 0, 20)

	self:_connect(Selection.SelectionChanged, function()
		self:_refreshSelection()
	end)
	self:_connect(widget:GetPropertyChangedSignal("Enabled"), function()
		if widget.Enabled then
			self:_refreshSelection()
		end
	end)
	self:_refreshSelection()
	self:_visualizeSpawnPoints()
	self:_setStatus("Plugin ready", COLORS.ok)
	task.defer(function()
		if self.currentWidget then
			self.currentWidget.Enabled = true
			print("[OwnerDebugPanel] widget enabled")
		end
	end)
end

function OwnerDebugPanel:Start()
	local toolbar = self.plugin:CreateToolbar(TOOLBAR_NAME)
	local btn = toolbar:CreateButton("OwnerDebugPanel", "Open OwnerDebugPanel", "")
	btn.ClickableWhenViewportHidden = true
	btn.Click:Connect(function()
		self:_build()
		if self.currentWidget then
			self.currentWidget.Enabled = not self.currentWidget.Enabled
		end
	end)
	self.toolbar = toolbar
	self:_build()
	print("[OwnerDebugPanel] loaded")
	self:_setStatus("OwnerDebugPanel loaded", COLORS.ok)
end

local panel = OwnerDebugPanel.new()
panel:Start()

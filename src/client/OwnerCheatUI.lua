local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local OwnerCheatConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("OwnerCheatConfig"))

local OwnerCheatUI = {}
OwnerCheatUI.__index = OwnerCheatUI

local LOCAL_PLAYER = Players.LocalPlayer
local REMOTE_WAIT = 20

local COLORS = {
	bg = Color3.fromRGB(20, 22, 27),
	panel = Color3.fromRGB(31, 34, 42),
	rail = Color3.fromRGB(42, 46, 56),
	accent = Color3.fromRGB(182, 38, 61),
	text = Color3.fromRGB(238, 240, 244),
	muted = Color3.fromRGB(164, 171, 184),
	ok = Color3.fromRGB(63, 148, 98),
	warn = Color3.fromRGB(194, 143, 54),
}

local function styleText(instance, size, bold)
	instance.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
	instance.TextSize = size or 13
	instance.TextColor3 = COLORS.text
	instance.TextWrapped = true
end

local function corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 6)
	c.Parent = parent
end

local function stroke(parent, color)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(67, 72, 84)
	s.Thickness = 1
	s.Parent = parent
end

local function makeButton(parent, text, size)
	local button = Instance.new("TextButton")
	button.Name = text:gsub("%W+", "") .. "Button"
	button.Size = size or UDim2.new(1, 0, 0, 34)
	button.BackgroundColor3 = COLORS.rail
	button.AutoButtonColor = true
	button.Text = text
	styleText(button, 12, true)
	corner(button, 5)
	stroke(button)
	button.Parent = parent
	return button
end

local function makeLabel(parent, text, size, height)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(1, 0, 0, height or 24)
	label.Text = text
	label.TextXAlignment = Enum.TextXAlignment.Left
	styleText(label, size or 13, true)
	label.Parent = parent
	return label
end

local function makeBox(parent, placeholder)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, 32)
	box.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
	box.PlaceholderText = placeholder or ""
	box.Text = ""
	box.ClearTextOnFocus = false
	styleText(box, 12, false)
	corner(box, 5)
	stroke(box)
	box.Parent = parent
	return box
end

local function addListLayout(parent, padding)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, padding or 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

local function clearChildren(frame)
	for _, child in ipairs(frame:GetChildren()) do
		if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
			child:Destroy()
		end
	end
end

local function firstValue(list, fallback)
	return type(list) == "table" and list[1] or fallback
end

function OwnerCheatUI:Init(context)
	self._context = context or {}
	self._registry = self._context.Registry
	self._remotes = self._context.Remotes or {}
	self._remote = self._remotes.OwnerCheatEvent
	self._connections = {}
	self._authorized = false
	self._isOwner = false
	self._role = OwnerCheatConfig.ROLES.NONE
	self._ownerUserId = OwnerCheatConfig.DEFAULT_OWNER_USER_ID
	self._qaUserIds = {}
	self._catalog = {
		ghosts = OwnerCheatConfig.CANONICAL_GHOSTS,
		animations = OwnerCheatConfig.GHOST_ANIMATIONS,
		spawnLocations = OwnerCheatConfig.GHOST_SPAWN_LOCATIONS,
		items = {},
		sfxByGhost = {},
		maps = {},
	}
	self._selectedMapId = nil
	self._selectedGhost = firstValue(self._catalog.ghosts, "Pocong")
	self._selectedArea = "Default"
	self._selectedAnimation = firstValue(self._catalog.animations, "GhostIdle")
	self._selectedSpawnLocation = firstValue(self._catalog.spawnLocations, { id = "in_place" }).id
	self._selectedItemId = nil
	self._scale = { x = 1, y = 1, z = 1 }
end

function OwnerCheatUI:Start(context)
	if context then
		self._context = context
		self._registry = context.Registry or self._registry
		self._remotes = context.Remotes or self._remotes
	end
	self._remote = self._remote or self._remotes.OwnerCheatEvent or self:_waitForRemote()
	if not self._remote then
		return
	end
	table.insert(self._connections, self._remote.OnClientEvent:Connect(function(payload)
		self:_onRemote(payload)
	end))
	self:_send("RequestAuth", {})
end

function OwnerCheatUI:_waitForRemote()
	local folder = ReplicatedStorage:WaitForChild("RemoteEvents", REMOTE_WAIT)
	if not folder then
		return nil
	end
	local remote = folder:WaitForChild("OwnerCheatEvent", REMOTE_WAIT)
	return remote and remote:IsA("RemoteEvent") and remote or nil
end

function OwnerCheatUI:_send(action, payload)
	if not self._remote then
		return
	end
	self._remote:FireServer({
		action = action,
		requestId = tostring(os.clock()),
		payload = payload or {},
	})
end

function OwnerCheatUI:_setStatus(text, ok)
	if self._statusLabel then
		self._statusLabel.Text = tostring(text or "")
		self._statusLabel.TextColor3 = ok == false and COLORS.warn or COLORS.muted
	end
end

function OwnerCheatUI:_onRemote(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.eventName == "OwnerCheatSnapshot" then
		self._authorized = payload.authorized == true
		self._isOwner = payload.isOwner == true
		self._role = payload.role or OwnerCheatConfig.ROLES.NONE
		self._ownerUserId = tonumber(payload.ownerUserId) or self._ownerUserId
		self._qaUserIds = type(payload.qaUserIds) == "table" and payload.qaUserIds or self._qaUserIds
		if type(payload.catalog) == "table" then
			self._catalog = payload.catalog
			if type(self._catalog.maps) == "table" and #self._catalog.maps > 0 and not self._selectedMapId then
				self._selectedMapId = self._catalog.maps[1].id
			end
			self._selectedGhost = self._selectedGhost or firstValue(self._catalog.ghosts, "Pocong")
			self._selectedSpawnLocation = self._selectedSpawnLocation or firstValue(self._catalog.spawnLocations, { id = "in_place" }).id
			if type(self._catalog.items) == "table" and self._catalog.items[1] then
				self._selectedItemId = self._selectedItemId or self._catalog.items[1].id
			end
		end
		if self._authorized then
			self:_build()
		elseif self._gui then
			self._gui:Destroy()
			self._gui = nil
		end
	elseif payload.eventName == "OwnerCheatAck" then
		self:_setStatus((payload.ok and "OK: " or "DITOLAK: ") .. tostring(payload.result), payload.ok)
		if type(payload.catalog) == "table" then
			self._catalog = payload.catalog
		end
	end
end

function OwnerCheatUI:_build()
	if self._gui then
		self:_renderRoleBadge()
		return
	end
	local playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "UICheatOwner"
	gui.IgnoreGuiInset = false
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	self._gui = gui

	local toggle = Instance.new("TextButton")
	toggle.Name = "CheatToggleButton"
	toggle.AnchorPoint = Vector2.new(0.5, 0)
	toggle.Position = UDim2.new(0.5, 0, 0, 12)
	toggle.Size = UDim2.new(0, 150, 0, 28)
	toggle.BackgroundColor3 = COLORS.bg
	toggle.BackgroundTransparency = 0.7
	toggle.AutoButtonColor = true
	toggle.Text = "CHEAT"
	styleText(toggle, 12, true)
	corner(toggle, 7)
	stroke(toggle, COLORS.accent)
	toggle.Parent = gui
	self._toggleButton = toggle

	local launcher = Instance.new("Frame")
	launcher.Name = "Launcher"
	launcher.AnchorPoint = Vector2.new(1, 0)
	launcher.Position = UDim2.new(1, -16, 0, 90)
	launcher.Size = UDim2.new(0, 178, 0, 246)
	launcher.BackgroundColor3 = COLORS.bg
	corner(launcher, 8)
	stroke(launcher, COLORS.accent)
	launcher.Parent = gui
	launcher.Visible = false
	self._launcher = launcher
	addListLayout(launcher, 8)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = launcher

	self._roleBadge = makeLabel(launcher, "", 12, 26)
	self:_renderRoleBadge()

	makeButton(launcher, "GHOST").Activated:Connect(function()
		self:_openWindow("GHOST")
	end)
	makeButton(launcher, "HADIAH / LOADOUT").Activated:Connect(function()
		self:_openWindow("LOADOUT")
	end)
	makeButton(launcher, "ROLE").Activated:Connect(function()
		self:_openWindow("ROLE")
	end)
	makeButton(launcher, "CHEAT LAINNYA").Activated:Connect(function()
		self:_openWindow("OTHER")
	end)

	self._statusLabel = makeLabel(launcher, "OwnerCheat siap", 11, 42)
	self._statusLabel.TextColor3 = COLORS.muted

	local window = Instance.new("Frame")
	window.Name = "Window"
	window.AnchorPoint = Vector2.new(1, 0)
	window.Position = UDim2.new(1, -208, 0, 90)
	window.Size = UDim2.new(0, 420, 0, 520)
	window.BackgroundColor3 = COLORS.panel
	corner(window, 8)
	stroke(window)
	window.Parent = gui
	window.Visible = false
	self._window = window

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.new(1, -20, 1, -20)
	content.Position = UDim2.new(0, 10, 0, 10)
	content.Parent = window
	addListLayout(content, 8)
	self._content = content

	toggle.Activated:Connect(function()
		local shouldShow = not launcher.Visible
		launcher.Visible = shouldShow
		if not shouldShow then
			window.Visible = false
			self._activeTab = nil
		end
	end)
end

function OwnerCheatUI:_renderRoleBadge()
	if self._roleBadge then
		self._roleBadge.Text = "UICheatOwner - " .. tostring(self._role)
		self._roleBadge.TextColor3 = self._isOwner and COLORS.ok or COLORS.text
	end
end

function OwnerCheatUI:_openWindow(tab)
	if not self._window or not self._content then
		return
	end
	if self._launcher and not self._launcher.Visible then
		self._launcher.Visible = true
	end
	if self._activeTab == tab and self._window.Visible then
		self._window.Visible = false
		return
	end
	self._activeTab = tab
	self._window.Visible = true
	clearChildren(self._content)
	if tab == "GHOST" then
		self:_renderGhost()
	elseif tab == "LOADOUT" then
		self:_renderLoadout()
	elseif tab == "ROLE" then
		self:_renderRole()
	else
		self:_renderOther()
	end
end

function OwnerCheatUI:_cycleButton(parent, label, values, current, callback)
	makeLabel(parent, label, 12, 18)
	local index = 1
	for i, value in ipairs(values or {}) do
		if value == current then
			index = i
			break
		end
	end
	local button = makeButton(parent, tostring(values[index] or current or "None"))
	button.Activated:Connect(function()
		if #(values or {}) == 0 then
			return
		end
		index = (index % #values) + 1
		button.Text = tostring(values[index])
		callback(values[index])
	end)
	return button
end

function OwnerCheatUI:_cycleRecordButton(parent, label, records, currentId, callback)
	local options = {}
	local byLabel = {}
	for _, record in ipairs(records or {}) do
		local display = tostring(record.label or record.id or "Item")
		table.insert(options, display)
		byLabel[display] = record
	end
	if #options == 0 then
		makeLabel(parent, label, 12, 18)
		return makeLabel(parent, "Tidak ada opsi", 11, 20)
	end
	local selectedLabel = options[1]
	for _, record in ipairs(records or {}) do
		if record.id == currentId then
			selectedLabel = tostring(record.label or record.id)
			break
		end
	end
	local button = self:_cycleButton(parent, label, options, selectedLabel, function(display)
		local record = byLabel[display]
		if record then
			callback(record)
		end
	end)
	local record = byLabel[selectedLabel]
	if record then
		callback(record)
	end
	return button
end

function OwnerCheatUI:_renderGhost()
	makeLabel(self._content, "GHOST", 16, 26)
	self:_cycleRecordButton(self._content, "Map", self._catalog.maps or {}, self._selectedMapId, function(record)
		self._selectedMapId = record.id
		local areas = type(record.areas) == "table" and record.areas or {}
		if #areas > 0 then
			self._selectedArea = areas[1]
		end
	end)
	self:_cycleButton(self._content, "Jenis", self._catalog.ghosts or OwnerCheatConfig.CANONICAL_GHOSTS, self._selectedGhost, function(value)
		self._selectedGhost = value
	end)
	local areaRecords = {}
	local seenAreas = {}
	for _, mapRecord in ipairs(self._catalog.maps or {}) do
		for _, area in ipairs(type(mapRecord.areas) == "table" and mapRecord.areas or {}) do
			if type(area) == "string" and area ~= "" and not seenAreas[area] then
				seenAreas[area] = true
				table.insert(areaRecords, { id = area, label = area })
			end
		end
	end
	if #areaRecords == 0 then
		table.insert(areaRecords, { id = self._selectedArea, label = self._selectedArea or "Default" })
	end
	self:_cycleRecordButton(self._content, "Area", areaRecords, self._selectedArea, function(record)
		self._selectedArea = record.id
	end)

	local row = Instance.new("Frame")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, 36)
	row.Parent = self._content
	local grid = Instance.new("UIGridLayout")
	grid.CellPadding = UDim2.new(0, 6, 0, 0)
	grid.CellSize = UDim2.new(0.5, -3, 1, 0)
	grid.Parent = row
	makeButton(row, "SPAWN").Activated:Connect(function()
		self:_send("GhostSpawn", {
			ghostType = self._selectedGhost,
			area = self._selectedArea,
			spawnMode = self._selectedSpawnLocation,
		})
	end)
	makeButton(row, "DESPAWN").Activated:Connect(function()
		self:_send("GhostDespawn", {})
	end)

	self:_cycleRecordButton(self._content, "Lokasi", self._catalog.spawnLocations or OwnerCheatConfig.GHOST_SPAWN_LOCATIONS, self._selectedSpawnLocation, function(record)
		self._selectedSpawnLocation = record.id
	end)
	self:_cycleButton(self._content, "Animasi", self._catalog.animations or OwnerCheatConfig.GHOST_ANIMATIONS, self._selectedAnimation, function(value)
		self._selectedAnimation = value
	end)
	makeButton(self._content, "PLAY ANIMASI").Activated:Connect(function()
		local pipeline = self._registry and self._registry:Get("GhostAnimationPipeline")
		if pipeline and type(pipeline.Play) == "function" then
			pipeline:Play(self._selectedAnimation, self._selectedGhost)
		end
		self:_send("GhostAnimation", { ghostType = self._selectedGhost, animation = self._selectedAnimation })
	end)
	makeButton(self._content, "PREVIEW SFX").Activated:Connect(function()
		self:_previewSFX(self._selectedGhost)
		self:_send("PreviewGhostSFX", { ghostType = self._selectedGhost })
	end)

	local toggles = Instance.new("Frame")
	toggles.BackgroundTransparency = 1
	toggles.Size = UDim2.new(1, 0, 0, 36)
	toggles.Parent = self._content
	local toggleGrid = Instance.new("UIGridLayout")
	toggleGrid.CellPadding = UDim2.new(0, 6, 0, 0)
	toggleGrid.CellSize = UDim2.new(0.5, -3, 1, 0)
	toggleGrid.Parent = toggles
	makeButton(toggles, "CHASE ON/OFF").Activated:Connect(function()
		self._chase = not self._chase
		self:_send("GhostChase", { enabled = self._chase })
	end)
	makeButton(toggles, "IDLE / FREEZE").Activated:Connect(function()
		self._freeze = not self._freeze
		self:_send("GhostFreeze", { enabled = self._freeze })
	end)

	for _, axis in ipairs({ "x", "y", "z" }) do
		local b = makeButton(self._content, ("Scale %s: %.1f"):format(axis:upper(), self._scale[axis]))
		b.Activated:Connect(function()
			self._scale[axis] += 0.25
			if self._scale[axis] > 2.5 then
				self._scale[axis] = 0.5
			end
			b.Text = ("Scale %s: %.1f"):format(axis:upper(), self._scale[axis])
		end)
	end
	makeButton(self._content, "SYNC UKURAN SEMESTINYA").Activated:Connect(function()
		self:_send("GhostScale", { scale = self._scale })
	end)
	makeButton(self._content, "RESET SCALE").Activated:Connect(function()
		self._scale = { x = 1, y = 1, z = 1 }
		self:_send("GhostResetScale", {})
	end)
end

function OwnerCheatUI:_previewSFX(ghostType)
	local soundId = self._catalog.sfxByGhost and self._catalog.sfxByGhost[ghostType]
	if type(soundId) ~= "string" or soundId == "" then
		return
	end
	local sound = Instance.new("Sound")
	sound.Name = "OwnerCheatGhostSFXPreview"
	sound.SoundId = soundId
	sound.Volume = 0.75
	sound.Parent = SoundService
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	sound:Play()
	task.delay(8, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

function OwnerCheatUI:_renderLoadout()
	makeLabel(self._content, "HADIAH / LOADOUT", 16, 26)
	local itemLabels = {}
	local itemByLabel = {}
	for _, item in ipairs(self._catalog.items or {}) do
		local label = ("%s [%s]"):format(tostring(item.label or item.id), tostring(item.category or item.source or "Item"))
		table.insert(itemLabels, label)
		itemByLabel[label] = item
	end
	if #itemLabels == 0 then
		makeLabel(self._content, "Catalog kosong", 12, 28)
		return
	end
	local selectedLabel = itemLabels[1]
	self:_cycleButton(self._content, "Item test", itemLabels, selectedLabel, function(label)
		local item = itemByLabel[label]
		self._selectedItemId = item and item.id
	end)
	self._selectedItemId = self._selectedItemId or itemByLabel[selectedLabel].id
	makeButton(self._content, "GRANT TEST").Activated:Connect(function()
		self:_send("GrantTestItem", { itemId = self._selectedItemId })
	end)
	makeButton(self._content, "EQUIP TEST").Activated:Connect(function()
		self:_send("EquipTestItem", { itemId = self._selectedItemId })
	end)
	makeButton(self._content, "REFRESH CATALOG").Activated:Connect(function()
		self:_send("GetCatalogSnapshot", {})
	end)
end

function OwnerCheatUI:_renderRole()
	makeLabel(self._content, "ROLE", 16, 26)
	makeLabel(self._content, "Current role: " .. tostring(self._role), 12, 20)
	makeLabel(self._content, "Owner: " .. tostring(self._ownerUserId), 11, 18)
	local qaLine = "QA: none"
	if type(self._qaUserIds) == "table" then
		local qaText = {}
		for _, userId in ipairs(self._qaUserIds) do
			table.insert(qaText, tostring(userId))
		end
		if #qaText > 0 then
			qaLine = "QA: " .. table.concat(qaText, ", ")
		end
	end
	makeLabel(self._content, qaLine, 11, 34)
	if not self._isOwner then
		makeLabel(self._content, "Owner only", 13, 32)
		return
	end
	local targetBox = makeBox(self._content, "Username atau UserId")
	makeButton(self._content, "ADD QA").Activated:Connect(function()
		self:_send("AddQA", { username = targetBox.Text, userId = targetBox.Text })
	end)
	makeButton(self._content, "REMOVE QA").Activated:Connect(function()
		self:_send("RemoveQA", { username = targetBox.Text, userId = targetBox.Text })
	end)
	makeButton(self._content, "TRANSFER OWNER").Activated:Connect(function()
		self:_send("TransferOwner", { username = targetBox.Text, userId = targetBox.Text })
	end)
	makeButton(self._content, "INSPECT ROLE").Activated:Connect(function()
		self:_send("InspectRoleState", {})
	end)
end

function OwnerCheatUI:_renderOther()
	makeLabel(self._content, "CHEAT LAINNYA", 16, 26)
	local mapBox = makeBox(self._content, "MapId")
	mapBox.Text = "HauntedHouse"
	makeButton(self._content, "START SOLO MATCH").Activated:Connect(function()
		self:_send("StartSoloMatch", { mapId = mapBox.Text })
	end)
	makeButton(self._content, "END MATCH").Activated:Connect(function()
		self:_send("EndMatch", {})
	end)
	makeButton(self._content, "ADVANCE INVESTIGATION").Activated:Connect(function()
		self:_send("AdvanceInvestigationPhase", { phase = "InvestigationPhase" })
	end)
	makeButton(self._content, "FORCE MANIFEST").Activated:Connect(function()
		self:_send("ForceManifest", {})
	end)
	makeButton(self._content, "FORCE HUNT").Activated:Connect(function()
		self:_send("ForceHunt", {})
	end)
	makeButton(self._content, "TRIGGER JUMPSCARE").Activated:Connect(function()
		self:_send("TriggerJumpscare", { ghostType = self._selectedGhost })
	end)
	makeButton(self._content, "TRIGGER GHOST AUDIO").Activated:Connect(function()
		self:_send("TriggerGhostAudio", { ghostType = self._selectedGhost })
	end)
	makeButton(self._content, "CLEANUP OWNER TEST").Activated:Connect(function()
		self:_send("CleanupOwnerTestState", {})
	end)
end

return setmetatable({}, OwnerCheatUI)

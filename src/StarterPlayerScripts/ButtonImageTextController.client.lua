local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LOCAL_PLAYER = Players.LocalPlayer

local IMAGE_TEXT_SCALE = {
	idle = 1,
	hover = 1.15,
	active = 1.1,
}

local SCALE_TWEEN_INFO = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local IMAGE_TEXT_STATES = {
	active = { idle = "119893364681680", hover = "103511682438962", active = "133568679810222" },
	batal = { idle = "72304416615357", hover = "91444456070241", active = "97774322066947" },
	batalkan = { idle = "89007767469101", hover = "92255968205675", active = "74356456014592" },
	batalkan_countdown = { idle = "73412200516577", hover = "90025550503883", active = "99098707302919" },
	buat_room = { idle = "78265579903979", hover = "91383658246484", active = "118305236485541" },
	classic = { idle = "117760951401524", hover = "129015288351024", active = "138617081838094" },
	close_x = { idle = "90895017189874", hover = "115151774523039", active = "127340669403158" },
	daily = { idle = "91316576845536", hover = "96825362275947", active = "82227324051324" },
	en = { idle = "72874112411604", hover = "106537932473563", active = "103268233098031" },
	evidence_j = { idle = "76661174366790", hover = "71133090906987", active = "113787734161193" },
	free_cursor_alt = { idle = "92060683504611", hover = "98204424974505", active = "81285506892525" },
	id = { idle = "129796813561337", hover = "86296711459938", active = "107260627864416" },
	idle = { idle = "95774596939688", hover = "117499371608925", active = "75654724905306" },
	invite_player = { idle = "75642756888914", hover = "117728586453608", active = "111443138456845" },
	join_room = { idle = "117884429780350", hover = "83549950348202", active = "104471513845706" },
	kick = { idle = "140602269367161", hover = "90835359324112", active = "123718222101364" },
	koleksi = { idle = "138104347169386", hover = "92582946322328", active = "112977326396191" },
	leave_room = { idle = "80580476454562", hover = "139034140988266", active = "134523480660036" },
	main_menu = { idle = "100188914682058", hover = "135944631095139", active = "86180351762194" },
	menu = { idle = "81840234190758", hover = "100554800720547", active = "109153271232438" },
	missions_q = { idle = "74146227961542", hover = "95903306810711", active = "98565884123985" },
	mulai_permainan = { idle = "105040736629114", hover = "78774287520098", active = "95317412796782" },
	ok = { idle = "131131528442725", hover = "92932938836672", active = "122482912193368" },
	open_profile = { idle = "105816021457823", hover = "138336629404370", active = "108485786723336" },
	open_rank_board = { idle = "70851175896471", hover = "113137045182913", active = "111395627991278" },
	open_room_browser = { idle = "121806831769566", hover = "114260638652413", active = "132315129687773" },
	open_rooms = { idle = "87917822445882", hover = "86582438290826", active = "86337699956144" },
	open_shop = { idle = "123823941129089", hover = "138578045095503", active = "140390986903081" },
	persiapan = { idle = "122961573879784", hover = "72835993341884", active = "77333574657841" },
	play = { idle = "97619808744728", hover = "101162595389006", active = "124031181308180" },
	profile = { idle = "138788536092713", hover = "101195397941386", active = "92364485405672" },
	quick_classic = { idle = "103126601492249", hover = "118376821868501", active = "139918432832626" },
	quick_ranked = { idle = "73702891169263", hover = "118855711808942", active = "77299506660222" },
	rank = { idle = "132541994193262", hover = "78308952430777", active = "137424967951840" },
	ranked = { idle = "92776029802346", hover = "86043176432101", active = "136947178671971" },
	ready = { idle = "80162729234441", hover = "123954565032294", active = "131702435873347" },
	refresh = { idle = "122710253904259", hover = "134969787978908", active = "84361805930072" },
	rendah = { idle = "95274965608918", hover = "125082924781174", active = "132991450299147" },
	royal_pass = { idle = "74154323194225", hover = "92445570105509", active = "88526438006690" },
	scan_jejak = { idle = "71874610051324", hover = "128303976874326", active = "109151429365319" },
	sedang = { idle = "94913337057550", hover = "107952674217542", active = "104814729311590" },
	sembunyikan = { idle = "106449517363306", hover = "107558671055493", active = "94285208092044" },
	semua_mode = { idle = "75636362660244", hover = "97893505198837", active = "71250727262939" },
	senter_off = { idle = "106996620986201", hover = "128353838297791", active = "75271688724464" },
	set_pwd = { idle = "115749597829280", hover = "115927030315826", active = "104382602356120" },
	settings = { idle = "89537724886773", hover = "130532745688521", active = "80626213294091" },
	shop = { idle = "133173197641907", hover = "88732046094994", active = "91837126977915" },
	simpan = { idle = "137625844137204", hover = "108891557892147", active = "128898918499055" },
	story = { idle = "137489635851687", hover = "98503217158561", active = "77447453584064" },
	terima = { idle = "136849137495432", hover = "138886948030082", active = "128366030117614" },
	tinggi = { idle = "105304300351595", hover = "105304300351595", active = "105304300351595" },
	tolak = { idle = "128216406160776", hover = "130577615241706", active = "89722983867546" },
	tracker = { idle = "103489183789899", hover = "99269259836629", active = "110126978866737" },
	tutup_hasil = { idle = "86629151641022", hover = "124686987761499", active = "94234777851234" },
	ultra = { idle = "102177609283146", hover = "117578464869913", active = "130828088372612" },
	weekly = { idle = "136762040893669", hover = "127247448482612", active = "128898766382265" },
}

local BUTTON_NAME_ALIASES = {
	CreateRoomButton = "buat_room",
	QueueButton = "join_room",
	JoinButton = "join_room",
	QuickJoinClassicButton = "quick_classic",
	QuickJoinRankedButton = "quick_ranked",
	AllModesButton = "semua_mode",
	CancelStartButton = "batalkan_countdown",
	CancelCountdown = "batalkan",
	LeaveRoomButton = "leave_room",
	SetPasswordButton = "set_pwd",
	StartButton = "mulai_permainan",
	ToolActionButton = "scan_jejak",
	EvidenceQuickButton = "evidence_j",
	ResultsCloseButton = "tutup_hasil",
	CursorToggleButton = "free_cursor_alt",
	ToggleButton = "senter_off",
	OpenRoomBrowserButton = "open_room_browser",
	RoomBrowserButton = "open_room_browser",
	ProfileButton = "profile",
	RankButton = "rank",
	RoyalPassButton = "royal_pass",
	ShopButton = "shop",
	MainMenuButton = "main_menu",
	KoleksiButton = "koleksi",
	PersiapanButton = "persiapan",
	SettingsButton = "settings",
	GraphicsButton = "settings",
	FilterTemplate = "semua_mode",
	KickInline = "close_x",
	ENOption = "en",
	IDOption = "id",
	RENDAHOption = "rendah",
	SEDANGOption = "sedang",
	TINGGIOption = "tinggi",
	ULTRAOption = "ultra",
	CancelButton = "batal",
	SaveButton = "simpan",
	AcceptButton = "terima",
	DeclineButton = "tolak",
	OkButton = "ok",
	ReadyButton = "ready",
	KickButton = "kick",
	InviteButton = "invite_player",
	HideButton = "sembunyikan",
	PlayButton = "play",
	MissionTab = "daily",
	RewardTab = "daily",
	DAILYTab = "daily",
	STORYTab = "story",
	WEEKLYTab = "weekly",
	CollapseButton = "close_x",
	ReopenButton = "tracker",
	OpenButton = "missions_q",
	MenuButton = "menu",
	CloseButton = "close_x",
	BottomNavTriggerButton = "menu",
}

local BUTTON_TEXT_ALIASES = {
	["DAY 01"] = "daily",
	INV = "invite_player",
	["OPEN ROOMS"] = "open_rooms",
	SAFE = "idle",
	CLAIM = "ok",
	LIVE = "active",
	SHOP = "shop",
	BELI = "ok",
	KURANG = "batal",
	FRESH = "refresh",
	LOCAL = "idle",
	TRACK = "tracker",
	PAKAI = "active",
	INFO = "ok",
	["LIHAT SHOP"] = "open_shop",
	PENDING = "idle",
	["OPEN PROFILE"] = "open_profile",
	["OPEN RANK BOARD"] = "open_rank_board",
	["OPEN ROOM BROWSER"] = "open_room_browser",
	["OPEN SHOP"] = "open_shop",
	ALL = "semua_mode",
	X = "close_x",
	["[X]"] = "close_x",
}

local BOUND_ATTRIBUTE = "PasrahImageTextBound"
local DISABLED_ATTRIBUTE = "PasrahDisableGlobalImageTextController"

local function isManagedByPrimaryUi(button)
	return button:GetAttribute(DISABLED_ATTRIBUTE) == true
		or button:GetAttribute("PasrahButtonInputProxy") == true
		or button:GetAttribute("BrandFeedbackBound") == true
end

local function normalize(text)
	text = tostring(text or "")
	text = string.gsub(text, "%b[]", "")
	text = string.gsub(text, "[^%w]+", "_")
	text = string.gsub(text, "^_+", "")
	text = string.gsub(text, "_+$", "")
	return string.lower(text)
end

local function normalizeName(name)
	name = tostring(name or "")
	name = string.gsub(name, "Button$", "")
	name = string.gsub(name, "Option$", "")
	name = string.gsub(name, "Tab$", "")
	return normalize(name)
end

local function toAsset(assetId)
	return string.format("rbxassetid://%s", tostring(assetId))
end

local function setImageTextScale(image, stateName)
	local scale = image:FindFirstChild("BrandTextImageStateScale")
	if not (scale and scale:IsA("UIScale")) then
		scale = Instance.new("UIScale")
		scale.Name = "BrandTextImageStateScale"
		scale.Parent = image
	end
	local targetScale = IMAGE_TEXT_SCALE[stateName or "idle"] or IMAGE_TEXT_SCALE.idle
	local tween = TweenService:Create(scale, SCALE_TWEEN_INFO, { Scale = targetScale })
	tween:Play()
end

local function setImagePassthrough(image)
	if not (image and (image:IsA("ImageLabel") or image:IsA("ImageButton"))) then
		return
	end
	if image:IsA("ImageButton") then
		image.AutoButtonColor = false
	end
	image.Active = false
	image.Selectable = false
	pcall(function()
		image.Interactable = false
	end)
end

local function resolveBase(button)
	if button:IsA("TextButton") then
		local text = tostring(button.Text or "")
		if BUTTON_TEXT_ALIASES[text] then
			return BUTTON_TEXT_ALIASES[text]
		end

		local normalizedText = normalize(text)
		if IMAGE_TEXT_STATES[normalizedText] then
			return normalizedText
		end
	end

	if BUTTON_NAME_ALIASES[button.Name] then
		return BUTTON_NAME_ALIASES[button.Name]
	end

	local normalizedName = normalizeName(button.Name)
	if IMAGE_TEXT_STATES[normalizedName] then
		return normalizedName
	end

	return nil
end

local function ensureImageButton(button)
	local image = button:FindFirstChild("BrandTextImage")
	if image and image:IsA("ImageLabel") then
		return image
	end

	if image and (image:IsA("ImageLabel") or image:IsA("ImageButton")) then
		local replacement = Instance.new("ImageLabel")
		replacement.Name = "BrandTextImage"
		replacement.Size = image.Size
		replacement.Position = image.Position
		replacement.AnchorPoint = image.AnchorPoint
		replacement.ZIndex = image.ZIndex
		replacement.Visible = image.Visible
		image:Destroy()
		replacement.Parent = button
		return replacement
	end

	image = Instance.new("ImageLabel")
	image.Name = "BrandTextImage"
	image.Parent = button
	return image
end

local function configureImage(button, image, states, stateName)
	local idle = states.idle or states.active or states.hover
	local hover = states.hover or idle
	local active = states.active or hover
	local current = states[stateName] or idle

	image.BackgroundTransparency = 1
	image.BorderSizePixel = 0
	setImagePassthrough(image)
	image.ScaleType = Enum.ScaleType.Fit
	image.AnchorPoint = Vector2.new(0.5, 0.5)
	image.Position = UDim2.fromScale(0.5, 0.5)
	image.Size = UDim2.new(1, -8, 1, -8)
	image.ZIndex = button.ZIndex + 3
	image.Visible = true
	image.Image = toAsset(current)
	if image:IsA("ImageButton") then
		image.HoverImage = toAsset(hover)
		image.PressedImage = toAsset(active)
	end
	setImageTextScale(image, stateName)
	image:SetAttribute("PasrahImageTextIdle", idle)
	image:SetAttribute("PasrahImageTextHover", hover)
	image:SetAttribute("PasrahImageTextActive", active)
end

local function applyButton(button, stateName)
	if not button:IsA("GuiButton") or button.Name == "BrandTextImage" then
		return false
	end
	if isManagedByPrimaryUi(button) then
		return false
	end

	local base = resolveBase(button)
	local states = base and IMAGE_TEXT_STATES[base] or nil
	if not states then
		return false
	end

	local image = ensureImageButton(button)
	configureImage(button, image, states, stateName or "idle")
	button:SetAttribute("PasrahImageTextBase", base)
	button:SetAttribute("PasrahImageTextApplied", true)

	if button:IsA("TextButton") then
		button.TextTransparency = 1
	end

	return true
end

local function isPrimaryPress(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
		or input.KeyCode == Enum.KeyCode.ButtonA
end

local function bindButton(button)
	if not applyButton(button, "idle") or button:GetAttribute(BOUND_ATTRIBUTE) == true then
		return
	end

	button:SetAttribute(BOUND_ATTRIBUTE, true)
	local hovered = false
	button.MouseEnter:Connect(function()
		if isManagedByPrimaryUi(button) then
			return
		end
		hovered = true
		applyButton(button, "hover")
	end)
	button.MouseLeave:Connect(function()
		if isManagedByPrimaryUi(button) then
			return
		end
		hovered = false
		applyButton(button, "idle")
	end)
	button.InputBegan:Connect(function(input)
		if isManagedByPrimaryUi(button) then
			return
		end
		if isPrimaryPress(input) then
			applyButton(button, "active")
		end
	end)
	button.InputEnded:Connect(function(input)
		if isManagedByPrimaryUi(button) then
			return
		end
		if isPrimaryPress(input) then
			applyButton(button, hovered and "hover" or "idle")
		end
	end)

	if button:IsA("TextButton") then
		button:GetPropertyChangedSignal("Text"):Connect(function()
			if isManagedByPrimaryUi(button) then
				return
			end
			applyButton(button, "idle")
		end)
	end
end

local function bindTree(root)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("GuiButton") then
			bindButton(descendant)
		end
	end
end

local playerGui = LOCAL_PLAYER:WaitForChild("PlayerGui")
bindTree(playerGui)

playerGui.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("GuiButton") then
		task.defer(bindButton, descendant)
	end
end)

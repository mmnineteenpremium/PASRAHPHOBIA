     1→local Players = game:GetService("Players")
     2→local ContextActionService = game:GetService("ContextActionService")
     3→local RunService = game:GetService("RunService")
     4→local ReplicatedStorage = game:GetService("ReplicatedStorage")
     5→local Workspace = game:GetService("Workspace")
     6→local UserInputService = game:GetService("UserInputService")
     7→local TweenService = game:GetService("TweenService")
     8→
     9→local DialogueData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NpcDialogue"):WaitForChild("DialogueData"))
    10→
    11→local NpcDialogueController = {}
    12→NpcDialogueController.__index = NpcDialogueController
    13→
    14→local UI_NAME = "NpcDialogueUI"
    15→local DIALOGUE_INPUT_ACTION = "PasrahNpcDialogueInputLock"
    16→local DIALOGUE_CURSOR_TOGGLE_ACTION = "PasrahNpcDialogueCursorToggle"
    17→local DIALOGUE_CLOSE_ACTION = "PasrahNpcDialogueClose"
    18→local DIALOGUE_CAMERA_BIND_NAME = "PasrahNpcDialogueCamera"
    19→local DIALOGUE_LOCK_BIND_NAME = "PasrahNpcDialogueLock"
    20→local DIALOGUE_CAMERA_TWEEN_DURATION = 1.5
    21→local DIALOGUE_PLAYER_EMOTE_INTERVAL = 15
    22→local DIALOGUE_NPC_GESTURE_INTERVAL = 5
    23→local DEFAULT_WALKSPEED = 16
    24→local DEFAULT_JUMPPOWER = 50
    25→local NPC_GESTURE_ANIMATION_ID = "rbxassetid://507771019"
    26→
    27→local function resolveRemoteEvent(context)
    28→	local remotes = context and context.Remotes
    29→	if remotes and remotes.NpcDialogueEvent then
    30→		return remotes.NpcDialogueEvent
    31→	end
    32→
    33→	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    34→	return remoteFolder and remoteFolder:FindFirstChild("NpcDialogueEvent") or nil
    35→end
    36→
    37→local function buildTreeIndex()
    38→	local index = {}
    39→	for npcId, tree in pairs(DialogueData) do
    40→		if type(tree) == "table" and type(tree.root) == "string" then
    41→			index[tree.root] = npcId
    42→		end
    43→	end
    44→	return index
    45→end
    46→
    47→local function getDialogueTree(npcId)
    48→	local tree = DialogueData[npcId]
    49→	if type(tree) ~= "table" then
    50→		return nil
    51→	end
    52→	return tree
    53→end
    54→
    55→local function getCharacterRoot(character)
    56→	if not character then
    57→		return nil
    58→	end
    59→	return character:FindFirstChild("HumanoidRootPart")
    60→		or character:WaitForChild("HumanoidRootPart", 3)
    61→end
    62→
    63→local function getModelRoot(model)
    64→	if not model then
    65→		return nil
    66→	end
    67→	if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
    68→		return model.PrimaryPart
    69→	end
    70→	local root = model:FindFirstChild("HumanoidRootPart")
    71→	if root and root:IsA("BasePart") then
    72→		return root
    73→	end
    74→	return model:FindFirstChildWhichIsA("BasePart", true)
    75→end
    76→
    77→local function getAnimator(humanoid)
    78→	if not humanoid then
    79→		return nil
    80→	end
    81→	local animator = humanoid:FindFirstChildOfClass("Animator")
    82→	if not animator then
    83→		animator = Instance.new("Animator")
    84→		animator.Parent = humanoid
    85→	end
    86→	return animator
    87→end
    88→
    89→local function stopTrack(track)
    90→	if track and track.IsPlaying then
    91→		pcall(function()
    92→			track:Stop()
    93→		end)
    94→	end
    95→end
    96→
    97→local function normalizeQuestionText(text)
    98→	local normalized = tostring(text or ""):lower()
    99→	normalized = normalized:gsub("[%z\1-\31\127]", " ")
   100→	normalized = normalized:gsub("[%p]", " ")
   101→	normalized = normalized:gsub("%s+", " ")
   102→	return normalized
   103→end
   104→
   105→local function resolveDukunAnswer(tree, questionText)
   106→	local responses = type(tree) == "table" and tree.responses or nil
   107→	local normalized = normalizeQuestionText(questionText)
   108→	if normalized == "" then
   109→		return "Aku belum menangkap pertanyaannya. Coba tulis ulang dengan kata kunci seperti tool, ghost, match, shop, reward, training, event, atau class."
   110→	end
   111→
   112→	if type(responses) == "table" then
   113→		for _, response in ipairs(responses) do
   114→			if type(response) == "table" and type(response.keywords) == "table" then
   115→				for _, keyword in ipairs(response.keywords) do
   116→					local needle = normalizeQuestionText(keyword)
   117→					if needle ~= "" and normalized:find(needle, 1, true) then
   118→						return tostring(response.text or "")
   119→					end
   120→				end
   121→			end
   122→		end
   123→	end
   124→
   125→	return "Aku belum yakin topiknya. Coba kata kunci: tool, ghost, match, shop, reward, training, event, class, party, atau lobby."
   126→end
   127→
   128→function NpcDialogueController.new()
   129→	local self = setmetatable({}, NpcDialogueController)
   130→	self._remoteEvent = nil
   131→	self._remoteConnection = nil
   132→	self._characterConnection = nil
   133→	self._connections = {}
   134→	self._ui = nil
   135→	self._mainFrame = nil
   136→	self._npcNameLabel = nil
   137→	self._dialogueText = nil
   138→	self._questionFrame = nil
   139→	self._questionBox = nil
   140→	self._questionSendButton = nil
   141→	self._questionHint = nil
   142→	self._choicesFrame = nil
   143→	self._closeButton = nil
   144→	self._choiceButtons = {}
   145→	self._currentChoices = {}
   146→	self._rootIndex = buildTreeIndex()
   147→	self._currentNpcId = nil
   148→	self._currentNodeId = nil
   149→	self._isOpen = false
   150→	self._freezeSnapshot = nil
   151→	self._cameraSnapshot = nil
   152→	self._currentNpcModel = nil
   153→	self._currentNpcRoot = nil
   154→	self._currentNpcHumanoid = nil
   155→	self._currentNpcPivot = nil
   156→	self._npcGestureTrack = nil
   157→	self._playerEmoteLoopToken = 0
   158→	self._npcGestureLoopToken = 0
   159→	self._dialogueInputLocked = false
   160→	self._dialogueCursorUnlocked = false
   161→	self._previousMouseBehavior = nil
   162→	self._previousMouseIconEnabled = nil
   163→	self._controls = nil
   164→	self._cameraStepBound = false
   165→	self._dialogueLockStepBound = false
   166→	self._cameraMode = nil
   167→	self._cameraStartTime = nil
   168→	self._cameraOpenStartCFrame = nil
   169→	self._cameraOpenTargetCFrame = nil
   170→	self._cameraCloseStartCFrame = nil
   171→	self._cameraCloseTargetCFrame = nil
   172→	self._cameraRestoreType = nil
   173→	self._cameraRestoreSubject = nil
   174→	self._currentDialogueId = nil
   175→	self._dialogueOverrideText = nil
   176→	self._dialogueQuestionMode = false
   177→	return self
   178→end
   179→
   180→function NpcDialogueController:_getPlayer()
   181→	return Players.LocalPlayer
   182→end
   183→
   184→function NpcDialogueController:_getHumanoid()
   185→	local player = self:_getPlayer()
   186→	if not player then return nil end
   187→	local character = player.Character
   188→	if not character then return nil end
   189→	return character:FindFirstChildOfClass("Humanoid")
   190→		or character:WaitForChild("Humanoid", 3)
   191→end
   192→
   193→function NpcDialogueController:_resolveControls()
   194→	if self._controls then
   195→		return self._controls
   196→	end
   197→
   198→	local player = self:_getPlayer()
   199→	local playerScripts = player and (player:FindFirstChild("PlayerScripts") or player:WaitForChild("PlayerScripts", 5))
   200→	local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")
   201→	if not playerModule then
   202→		return nil
   203→	end
   204→
   205→	local ok, module = pcall(require, playerModule)
   206→	if not ok or type(module) ~= "table" then
   207→		return nil
   208→	end
   209→
   210→	local controls = nil
   211→	if type(module.GetControls) == "function" then
   212→		local okControls, resolved = pcall(function()
   213→			return module:GetControls()
   214→		end)
   215→		if okControls then
   216→			controls = resolved
   217→		end
   218→	end
   219→
   220→	self._controls = controls
   221→	return self._controls
   222→end
   223→
   224→function NpcDialogueController:_getNpcFromPrompt(dialogueId, preferredNpc)
   225→	if preferredNpc and preferredNpc:IsA("Model") and preferredNpc.Parent and preferredNpc:GetAttribute("PasrahNpcDialogueId") == dialogueId then
   226→		return preferredNpc
   227→	end
   228→
   229→	local player = self:_getPlayer()
   230→	local character = player and player.Character
   231→	local characterRoot = getCharacterRoot(character)
   232→	local nearestNpc = nil
   233→	local nearestDistance = math.huge
   234→
   235→	for _, descendant in ipairs(Workspace:GetDescendants()) do
   236→		if descendant:IsA("ProximityPrompt") and descendant.Name == "DialoguePrompt" then
   237→			local npc = descendant:FindFirstAncestorWhichIsA("Model")
   238→			if npc and npc.Parent and npc:GetAttribute("PasrahNpcDialogueId") == dialogueId then
   239→				local root = getModelRoot(npc)
   240→				if root then
   241→					local distance = 0
   242→					if characterRoot then
   243→						distance = (root.Position - characterRoot.Position).Magnitude
   244→					end
   245→					if distance < nearestDistance then
   246→						nearestDistance = distance
   247→						nearestNpc = npc
   248→					end
   249→				end
   250→			end
   251→		end
   252→	end
   253→
   254→	return nearestNpc
   255→end
   256→
   257→function NpcDialogueController:_freezePlayer()
   258→	local humanoid = self:_getHumanoid()
   259→	if not humanoid then
   260→		warn("[NpcDialogue] Humanoid nil saat freeze, retry dalam 1 detik")
   261→		task.delay(1, function()
   262→			local hum = self:_getHumanoid()
   263→			if hum and self._isOpen then
   264→				hum.WalkSpeed = 0
   265→				hum.JumpPower = 0
   266→				hum.AutoRotate = false
   267→			end
   268→		end)
   269→		return
   270→	end
   271→
   272→	local player = self:_getPlayer()
   273→	if player then
   274→		player:SetAttribute("PasrahNpcDialogueActive", true)
   275→	end
   276→
   277→	if not self._freezeSnapshot then
   278→		local character = player and player.Character
   279→		local rootPart = getCharacterRoot(character)
   280→		self._freezeSnapshot = {
   281→			WalkSpeed = humanoid.WalkSpeed,
   282→			JumpPower = humanoid.JumpPower,
   283→			JumpHeight = humanoid.JumpHeight,
   284→			UseJumpPower = humanoid.UseJumpPower,
   285→			AutoRotate = humanoid.AutoRotate,
   286→			RootPart = rootPart,
   287→			RootAnchored = rootPart and rootPart:IsA("BasePart") and rootPart.Anchored or nil,
   288→		}
   289→	end
   290→
   291→	humanoid.WalkSpeed = 0
   292→	if humanoid.UseJumpPower then
   293→		humanoid.JumpPower = 0
   294→	else
   295→		humanoid.JumpHeight = 0
   296→	end
   297→	humanoid.AutoRotate = false
   298→
   299→	local rootPart = self._freezeSnapshot and self._freezeSnapshot.RootPart
   300→	if rootPart and rootPart:IsA("BasePart") then
   301→		rootPart.AssemblyLinearVelocity = Vector3.zero
   302→		rootPart.AssemblyAngularVelocity = Vector3.zero
   303→		rootPart.Anchored = true
   304→	end
   305→
   306→	local controls = self:_resolveControls()
   307→	if controls and type(controls.Disable) == "function" then
   308→		pcall(function()
   309→			controls:Disable()
   310→		end)
   311→	end
   312→end
   313→
   314→function NpcDialogueController:_unfreezePlayer()
   315→	local snapshot = self._freezeSnapshot
   316→	self._freezeSnapshot = nil
   317→	local humanoid = self:_getHumanoid()
   318→	if not humanoid then
   319→		return
   320→	end
   321→
   322→	if snapshot then
   323→		humanoid.WalkSpeed = snapshot.WalkSpeed or DEFAULT_WALKSPEED
   324→		humanoid.UseJumpPower = snapshot.UseJumpPower ~= false
   325→		if snapshot.UseJumpPower ~= false then
   326→			humanoid.JumpPower = snapshot.JumpPower or DEFAULT_JUMPPOWER
   327→		else
   328→			humanoid.JumpHeight = snapshot.JumpHeight or humanoid.JumpHeight
   329→		end
   330→		humanoid.AutoRotate = snapshot.AutoRotate ~= false
   331→	else
   332→		humanoid.WalkSpeed = DEFAULT_WALKSPEED
   333→		humanoid.JumpPower = DEFAULT_JUMPPOWER
   334→		humanoid.AutoRotate = true
   335→	end
   336→
   337→	local rootPart = snapshot and snapshot.RootPart
   338→	if rootPart and rootPart:IsA("BasePart") then
   339→		rootPart.AssemblyLinearVelocity = Vector3.zero
   340→		rootPart.AssemblyAngularVelocity = Vector3.zero
   341→		rootPart.Anchored = snapshot.RootAnchored == true
   342→	end
   343→
   344→	local controls = self._resolveControls()
   345→	if controls and type(controls.Enable) == "function" then
   346→		pcall(function()
   347→			controls:Enable()
   348→		end)
   349→	end
   350→end
   351→
   352→function NpcDialogueController:_lockDialogueInput()
   353→	if self._dialogueInputLocked then
   354→		return
   355→	end
   356→	self._dialogueInputLocked = true
   357→	self._dialogueCursorUnlocked = false
   358→
   359→	self._previousMouseBehavior = UserInputService.MouseBehavior
   360→	self._previousMouseIconEnabled = UserInputService.MouseIconEnabled
   361→
   362→	self:_applyDialogueMouseState()
   363→
   364→	ContextActionService:BindAction(
   365→		DIALOGUE_INPUT_ACTION,
   366→		function()
   367→			return Enum.ContextActionResult.Sink
   368→		end,
   369→		false,
   370→		unpack(Enum.PlayerActions:GetEnumItems())
   371→	)
   372→	ContextActionService:BindAction(
   373→		DIALOGUE_CURSOR_TOGGLE_ACTION,
   374→		function(_, inputState)
   375→			if inputState ~= Enum.UserInputState.Begin then
   376→				return Enum.ContextActionResult.Sink
   377→			end
   378→
   379→			self:_setDialogueCursorUnlocked(not self._dialogueCursorUnlocked)
   380→			return Enum.ContextActionResult.Sink
   381→		end,
   382→		false,
   383→		Enum.KeyCode.LeftAlt,
   384→		Enum.KeyCode.Backquote
   385→	)
   386→	ContextActionService:BindAction(
   387→		DIALOGUE_CLOSE_ACTION,
   388→		function()
   389→			self:_closeDialogue()
   390→			return Enum.ContextActionResult.Sink
   391→		end,
   392→		false,
   393→		Enum.KeyCode.Escape,
   394→		Enum.KeyCode.Backspace,
   395→		Enum.KeyCode.X
   396→	)
   397→end
   398→
   399→function NpcDialogueController:_unlockDialogueInput()
   400→	if not self._dialogueInputLocked then
   401→		return
   402→	end
   403→	self._dialogueInputLocked = false
   404→	pcall(function()
   405→		ContextActionService:UnbindAction(DIALOGUE_INPUT_ACTION)
   406→	end)
   407→	pcall(function()
   408→		ContextActionService:UnbindAction(DIALOGUE_CURSOR_TOGGLE_ACTION)
   409→	end)
   410→	pcall(function()
   411→		ContextActionService:UnbindAction(DIALOGUE_CLOSE_ACTION)
   412→	end)
   413→
   414→	if self._previousMouseBehavior ~= nil then
   415→		UserInputService.MouseBehavior = self._previousMouseBehavior
   416→	end
   417→	if self._previousMouseIconEnabled ~= nil then
   418→		UserInputService.MouseIconEnabled = self._previousMouseIconEnabled
   419→	end
   420→	self._previousMouseBehavior = nil
   421→	self._previousMouseIconEnabled = nil
   422→	self._dialogueCursorUnlocked = false
   423→end
   424→
   425→function NpcDialogueController:_playOwnedEmote(humanoid)
   426→	if not humanoid then
   427→		return
   428→	end
   429→
   430→	local humanoidDescription = humanoid:FindFirstChildOfClass("HumanoidDescription")
   431→	if not humanoidDescription then
   432→		pcall(function()
   433→			humanoid:PlayEmote("wave")
   434→		end)
   435→		return
   436→	end
   437→
   438→	local validEmotes = {}
   439→	local ok, equippedEmotes = pcall(function()
   440→		return humanoidDescription:GetEquippedEmotes()
   441→	end)
   442→	if ok and type(equippedEmotes) == "table" then
   443→		for _, dataEmote in pairs(equippedEmotes) do
   444→			if dataEmote.Name and dataEmote.Name ~= "" then
   445→				table.insert(validEmotes, dataEmote.Name)
   446→			end
   447→		end
   448→	end
   449→
   450→	local selectedEmote = validEmotes[1]
   451→	if #validEmotes > 1 then
   452→		selectedEmote = validEmotes[math.random(1, #validEmotes)]
   453→	end
   454→	if not selectedEmote or selectedEmote == "" then
   455→		selectedEmote = "wave"
   456→	end
   457→
   458→	pcall(function()
   459→		humanoid:PlayEmote(selectedEmote)
   460→	end)
   461→end
   462→
   463→function NpcDialogueController:_playNpcGesture(npcHumanoid)
   464→	if not npcHumanoid then
   465→		return
   466→	end
   467→
   468→	if self._npcGestureTrack and self._npcGestureTrack.IsPlaying then
   469→		return
   470→	end
   471→
   472→	local animator = getAnimator(npcHumanoid)
   473→	if not animator then
   474→		return
   475→	end
   476→
   477→	local gestureAnimation = Instance.new("Animation")
   478→	gestureAnimation.AnimationId = NPC_GESTURE_ANIMATION_ID
   479→	local ok, track = pcall(function()
   480→		return animator:LoadAnimation(gestureAnimation)
   481→	end)
   482→	if ok and track then
   483→		self._npcGestureTrack = track
   484→		track.Priority = Enum.AnimationPriority.Action
   485→		track:Play()
   486→		return
   487→	end
   488→
   489→	pcall(function()
   490→		npcHumanoid:PlayEmote("wave")
   491→	end)
   492→end
   493→
   494→function NpcDialogueController:_bindDialogueLockStep()
   495→	if self._dialogueLockStepBound then
   496→		return
   497→	end
   498→	self._dialogueLockStepBound = true
   499→
   500→	RunService:BindToRenderStep(DIALOGUE_LOCK_BIND_NAME, Enum.RenderPriority.First.Value, function()
   501→		if not self._isOpen then
   502→			return
   503→		end
   504→
   505→		local player = self:_getPlayer()
   506→		local humanoid = self:_getHumanoid()
   507→		local camera = Workspace.CurrentCamera
   508→
   509→		if player then
   510→			player:SetAttribute("PasrahNpcDialogueActive", true)
   511→		end
   512→
   513→		if humanoid then
   514→			humanoid.WalkSpeed = 0
   515→			if humanoid.UseJumpPower then
   516→				humanoid.JumpPower = 0
   517→			else
   518→				humanoid.JumpHeight = 0
   519→			end
   520→			humanoid.AutoRotate = false
   521→			humanoid:Move(Vector3.zero, false)
   522→		end
   523→
   524→		if player and player.Character then
   525→			local rootPart = getCharacterRoot(player.Character)
   526→			if rootPart and rootPart:IsA("BasePart") then
   527→				rootPart.AssemblyLinearVelocity = Vector3.zero
   528→				rootPart.AssemblyAngularVelocity = Vector3.zero
   529→				rootPart.Anchored = true
   530→			end
   531→		end
   532→
   533→		local controls = self:_resolveControls()
   534→		if controls and type(controls.Disable) == "function" then
   535→			pcall(function()
   536→				controls:Disable()
   537→			end)
   538→		end
   539→
   540→		self:_applyDialogueMouseState()
   541→
   542→		if camera then
   543→			camera.CameraType = Enum.CameraType.Scriptable
   544→		end
   545→	end)
   546→end
   547→
   548→function NpcDialogueController:_unbindDialogueLockStep()
   549→	if not self._dialogueLockStepBound then
   550→		return
   551→	end
   552→	self._dialogueLockStepBound = false
   553→	pcall(function()
   554→		RunService:UnbindFromRenderStep(DIALOGUE_LOCK_BIND_NAME)
   555→	end)
   556→end
   557→
   558→function NpcDialogueController:_startPlayerEmoteLoop()
   559→	self._playerEmoteLoopToken = (self._playerEmoteLoopToken or 0) + 1
   560→	local token = self._playerEmoteLoopToken
   561→	task.spawn(function()
   562→		while self._isOpen and self._playerEmoteLoopToken == token do
   563→			local humanoid = self:_getHumanoid()
   564→			self:_playOwnedEmote(humanoid)
   565→			task.wait(DIALOGUE_PLAYER_EMOTE_INTERVAL)
   566→		end
   567→	end)
   568→end
   569→
   570→function NpcDialogueController:_stopPlayerEmoteLoop()
   571→	self._playerEmoteLoopToken = (self._playerEmoteLoopToken or 0) + 1
   572→end
   573→
   574→function NpcDialogueController:_startNpcGestureLoop()
   575→	self._npcGestureLoopToken = (self._npcGestureLoopToken or 0) + 1
   576→	local token = self._npcGestureLoopToken
   577→	task.spawn(function()
   578→		while self._isOpen and self._npcGestureLoopToken == token do
   579→			local npcHumanoid = self._currentNpcHumanoid
   580→			if not (npcHumanoid and npcHumanoid.Parent) then
   581→				break
   582→			end
   583→			self:_playNpcGesture(npcHumanoid)
   584→			task.wait(DIALOGUE_NPC_GESTURE_INTERVAL)
   585→		end
   586→	end)
   587→end
   588→
   589→function NpcDialogueController:_stopNpcGestureLoop()
   590→	self._npcGestureLoopToken = (self._npcGestureLoopToken or 0) + 1
   591→	if self._npcGestureTrack then
   592→		stopTrack(self._npcGestureTrack)
   593→		self._npcGestureTrack = nil
   594→	end
   595→end
   596→
   597→function NpcDialogueController:_startNpcFacingLoop()
   598→	self._npcFacingLoopToken = (self._npcFacingLoopToken or 0) + 1
   599→	local token = self._npcFacingLoopToken
   600→	if self._npcFacingConnection then
   601→		self._npcFacingConnection:Disconnect()
   602→		self._npcFacingConnection = nil
   603→	end
   604→
   605→	self._npcFacingConnection = RunService.Heartbeat:Connect(function()
   606→		if not self._isOpen or self._npcFacingLoopToken ~= token then
   607→			return
   608→		end
   609→
   610→		local npcModel = self._currentNpcModel
   611→		local player = self:_getPlayer()
   612→		local character = player and player.Character
   613→		local characterRoot = getCharacterRoot(character)
   614→		if not (npcModel and characterRoot and npcModel.Parent) then
   615→			return
   616→		end
   617→
   618→		local npcPivot = npcModel:GetPivot()
   619→		local target = Vector3.new(characterRoot.Position.X, npcPivot.Position.Y, characterRoot.Position.Z)
   620→		pcall(function()
   621→			npcModel:PivotTo(CFrame.lookAt(npcPivot.Position, target))
   622→		end)
   623→	end)
   624→end
   625→
   626→function NpcDialogueController:_stopNpcFacingLoop()
   627→	self._npcFacingLoopToken = (self._npcFacingLoopToken or 0) + 1
   628→	if self._npcFacingConnection then
   629→		self._npcFacingConnection:Disconnect()
   630→		self._npcFacingConnection = nil
   631→	end
   632→end
   633→
   634→function NpcDialogueController:_bindDialogueCameraStep()
   635→	if self._cameraStepBound then
   636→		return
   637→	end
   638→	self._cameraStepBound = true
   639→
   640→	RunService:BindToRenderStep(DIALOGUE_CAMERA_BIND_NAME, Enum.RenderPriority.Last.Value, function()
   641→		local camera = Workspace.CurrentCamera
   642→		if not camera then
   643→			return
   644→		end
   645→
   646→		if self._cameraMode == "opening" then
   647→			local startCFrame = self._cameraOpenStartCFrame
   648→			local targetCFrame = self._cameraOpenTargetCFrame
   649→			local startTime = self._cameraStartTime or 0
   650→			if not (startCFrame and targetCFrame) then
   651→				return
   652→			end
   653→
   654→			local alpha = math.clamp((time() - startTime) / DIALOGUE_CAMERA_TWEEN_DURATION, 0, 1)
   655→			local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
   656→			camera.CameraType = Enum.CameraType.Scriptable
   657→			camera.CFrame = startCFrame:Lerp(targetCFrame, eased)
   658→			if alpha >= 1 then
   659→				camera.CFrame = targetCFrame
   660→				self._cameraMode = "open"
   661→				camera.CameraType = Enum.CameraType.Scriptable
   662→			end
   663→			return
   664→		end
   665→
   666→		if self._cameraMode == "open" then
   667→			if self._cameraOpenTargetCFrame then
   668→				camera.CameraType = Enum.CameraType.Scriptable
   669→				camera.CFrame = self._cameraOpenTargetCFrame
   670→			end
   671→			return
   672→		end
   673→
   674→		if self._cameraMode == "closing" then
   675→			local startCFrame = self._cameraCloseStartCFrame
   676→			local targetCFrame = self._cameraCloseTargetCFrame
   677→			local startTime = self._cameraStartTime or 0
   678→			if not (startCFrame and targetCFrame) then
   679→				self._cameraMode = nil
   680→				return
   681→			end
   682→
   683→			local alpha = math.clamp((time() - startTime) / DIALOGUE_CAMERA_TWEEN_DURATION, 0, 1)
   684→			local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
   685→			camera.CameraType = Enum.CameraType.Scriptable
   686→			camera.CFrame = startCFrame:Lerp(targetCFrame, eased)
   687→			if alpha >= 1 then
   688→				camera.CFrame = targetCFrame
   689→				camera.CameraType = self._cameraRestoreType or Enum.CameraType.Custom
   690→				camera.CameraSubject = self._cameraRestoreSubject
   691→				self._cameraMode = nil
   692→				self._cameraSnapshot = nil
   693→				self._cameraOpenStartCFrame = nil
   694→				self._cameraOpenTargetCFrame = nil
   695→				self._cameraCloseStartCFrame = nil
   696→				self._cameraCloseTargetCFrame = nil
   697→				self._cameraRestoreType = nil
   698→				self._cameraRestoreSubject = nil
   699→				pcall(function()
   700→					RunService:UnbindFromRenderStep(DIALOGUE_CAMERA_BIND_NAME)
   701→				end)
   702→				self._cameraStepBound = false
   703→				self._unlockDialogueInput()
   704→				self:_unfreezePlayer()
   705→				local player = self:_getPlayer()
   706→				if player then
   707→					player:SetAttribute("PasrahNpcDialogueActive", false)
   708→				end
   709→			end
   710→		end
   711→	end)
   712→end
   713→
   714→function NpcDialogueController:_startDialogueCamera(npcModel)
   715→	local camera = Workspace.CurrentCamera
   716→	local player = self:_getPlayer()
   717→	local character = player and player.Character
   718→	local characterRoot = getCharacterRoot(character)
   719→	local npcRoot = getModelRoot(npcModel)
   720→	if not camera then
   721→		warn("[NpcDialogue] Camera tidak ditemukan")
   722→		return
   723→	end
   724→	if not npcModel or not npcModel.Parent then
   725→		warn("[NpcDialogue] npcModel nil saat camera tween")
   726→		return
   727→	end
   728→	if not characterRoot then
   729→		warn("[NpcDialogue] characterRoot nil saat camera tween")
   730→		return
   731→	end
   732→
   733→	self._cameraRestoreType = camera.CameraType
   734→	self._cameraRestoreSubject = camera.CameraSubject
   735→	self._cameraSnapshot = {
   736→		CameraType = camera.CameraType,
   737→		CameraSubject = camera.CameraSubject,
   738→		CFrame = camera.CFrame,
   739→	}
   740→	self._cameraOpenStartCFrame = camera.CFrame
   741→	self._cameraStartTime = time()
   742→
   743→	local npcPivot = npcModel:GetPivot()
   744→	local npcPosition = npcRoot and npcRoot.Position or npcPivot.Position
   745→	self._currentNpcPivot = npcPivot
   746→	local faceTarget = Vector3.new(characterRoot.Position.X, npcPivot.Position.Y, characterRoot.Position.Z)
   747→	npcModel:PivotTo(CFrame.lookAt(npcPivot.Position, faceTarget))
   748→
   749→	npcPivot = npcModel:GetPivot()
   750→	local midpoint = (characterRoot.Position + npcPosition) * 0.5
   751→	local side = npcPivot.RightVector
   752→	if side.Magnitude < 0.1 then
   753→		side = characterRoot.CFrame.RightVector
   754→	end
   755→	if side.Magnitude < 0.1 then
   756→		side = Vector3.new(1, 0, 0)
   757→	end
   758→	side = side.Unit
   759→	local distance = math.clamp((characterRoot.Position - npcPosition).Magnitude * 0.7 + 3, 6, 10)
   760→	local cameraPosition = midpoint + side * distance + Vector3.new(0, 2.8, 0)
   761→	local cameraTarget = midpoint + Vector3.new(0, 1.8, 0)
   762→	self._cameraOpenTargetCFrame = CFrame.lookAt(cameraPosition, cameraTarget)
   763→
   764→	self._cameraMode = "opening"
   765→	camera.CameraType = Enum.CameraType.Scriptable
   766→	self:_bindDialogueCameraStep()
   767→end
   768→
   769→function NpcDialogueController:_stopDialogueCamera()
   770→	local camera = Workspace.CurrentCamera
   771→	if not camera then
   772→		self._cameraMode = nil
   773→		self._unlockDialogueInput()
   774→		self:_unfreezePlayer()
   775→		local player = self:_getPlayer()
   776→		if player then
   777→			player:SetAttribute("PasrahNpcDialogueActive", false)
   778→		end
   779→		return
   780→	end
   781→
   782→	local currentCFrame = camera.CFrame
   783→	self._cameraCloseStartCFrame = currentCFrame
   784→	self._cameraCloseTargetCFrame = self._cameraSnapshot and self._cameraSnapshot.CFrame or currentCFrame
   785→	self._cameraStartTime = time()
   786→	self._cameraMode = "closing"
   787→	camera.CameraType = Enum.CameraType.Scriptable
   788→	self:_bindDialogueCameraStep()
   789→
   790→	if self._currentNpcModel and self._currentNpcPivot then
   791→		pcall(function()
   792→			self._currentNpcModel:PivotTo(self._currentNpcPivot)
   793→		end)
   794→	end
   795→	self._currentNpcPivot = nil
   796→end
   797→
   798→function NpcDialogueController:_ensureUi()
   799→	local player = self:_getPlayer()
   800→	if not player then
   801→		return nil
   802→	end
   803→
   804→	local playerGui = player:WaitForChild("PlayerGui")
   805→	local gui = playerGui:FindFirstChild(UI_NAME)
   806→	if not gui then
   807→		gui = Instance.new("ScreenGui")
   808→		gui.Name = UI_NAME
   809→		gui.IgnoreGuiInset = true
   810→		gui.ResetOnSpawn = false
   811→		gui.DisplayOrder = 250
   812→		gui.Enabled = false
   813→		gui.Parent = playerGui
   814→	end
   815→
   816→	local mainFrame = gui:FindFirstChild("MainFrame")
   817→	if not mainFrame then
   818→		mainFrame = Instance.new("Frame")
   819→		mainFrame.Name = "MainFrame"
   820→		mainFrame.AnchorPoint = Vector2.new(0.5, 1)
   821→		mainFrame.Position = UDim2.new(0.5, 0, 0.96, 0)
   822→		mainFrame.Size = UDim2.new(0.6, 0, 0.25, 0)
   823→		mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
   824→		mainFrame.BackgroundTransparency = 0.3
   825→		mainFrame.BorderSizePixel = 0
   826→		mainFrame.ClipsDescendants = true
   827→		mainFrame.Parent = gui
   828→
   829→		local mainCorner = Instance.new("UICorner")
   830→		mainCorner.CornerRadius = UDim.new(0, 12)
   831→		mainCorner.Parent = mainFrame
   832→
   833→		local stroke = Instance.new("UIStroke")
   834→		stroke.Color = Color3.fromRGB(84, 84, 84)
   835→		stroke.Transparency = 0.2
   836→		stroke.Thickness = 1
   837→		stroke.Parent = mainFrame
   838→
   839→		local npcNameLabel = Instance.new("TextLabel")
   840→		npcNameLabel.Name = "NpcNameLabel"
   841→		npcNameLabel.BackgroundTransparency = 1
   842→		npcNameLabel.Size = UDim2.new(1, -60, 0, 24)
   843→		npcNameLabel.Position = UDim2.new(0, 16, 0, 10)
   844→		npcNameLabel.Font = Enum.Font.GothamBold
   845→		npcNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
   846→		npcNameLabel.TextSize = 18
   847→		npcNameLabel.TextXAlignment = Enum.TextXAlignment.Left
   848→		npcNameLabel.Text = "NPC"
   849→		npcNameLabel.Parent = mainFrame
   850→
   851→		local closeButton = Instance.new("TextButton")
   852→		closeButton.Name = "CloseButton"
   853→		closeButton.AnchorPoint = Vector2.new(1, 0)
   854→		closeButton.Position = UDim2.new(1, -12, 0, 10)
   855→		closeButton.Size = UDim2.new(0, 28, 0, 28)
   856→		closeButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
   857→		closeButton.BorderSizePixel = 0
   858→		closeButton.Font = Enum.Font.GothamBold
   859→		closeButton.Text = "X"
   860→		closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
   861→		closeButton.TextSize = 18
   862→		closeButton.Parent = mainFrame
   863→		local closeCorner = Instance.new("UICorner")
   864→		closeCorner.CornerRadius = UDim.new(0, 8)
   865→		closeCorner.Parent = closeButton
   866→
   867→		local dialogueText = Instance.new("TextLabel")
   868→		dialogueText.Name = "DialogueText"
   869→		dialogueText.BackgroundTransparency = 1
   870→		dialogueText.Position = UDim2.new(0, 16, 0, 38)
   871→		dialogueText.Size = UDim2.new(1, -32, 0, 44)
   872→		dialogueText.Font = Enum.Font.Gotham
   873→		dialogueText.TextColor3 = Color3.fromRGB(255, 255, 255)
   874→		dialogueText.TextSize = 16
   875→		dialogueText.TextWrapped = true
   876→		dialogueText.TextXAlignment = Enum.TextXAlignment.Left
   877→		dialogueText.TextYAlignment = Enum.TextYAlignment.Top
   878→		dialogueText.Text = ""
   879→		dialogueText.Parent = mainFrame
   880→
   881→		local choicesFrame = Instance.new("Frame")
   882→		choicesFrame.Name = "ChoicesFrame"
   883→		choicesFrame.BackgroundTransparency = 1
   884→		choicesFrame.Position = UDim2.new(0, 16, 0, 88)
   885→		choicesFrame.Size = UDim2.new(1, -32, 1, -98)
   886→		choicesFrame.Parent = mainFrame
   887→
   888→		local questionFrame = Instance.new("Frame")
   889→		questionFrame.Name = "QuestionFrame"
   890→		questionFrame.BackgroundTransparency = 1
   891→		questionFrame.Position = UDim2.new(0, 16, 0, 88)
   892→		questionFrame.Size = UDim2.new(1, -32, 1, -98)
   893→		questionFrame.Visible = false
   894→		questionFrame.Parent = mainFrame
   895→
   896→		local questionBox = Instance.new("TextBox")
   897→		questionBox.Name = "QuestionBox"
   898→		questionBox.AnchorPoint = Vector2.new(0, 0)
   899→		questionBox.Position = UDim2.new(0, 0, 0, 0)
   900→		questionBox.Size = UDim2.new(1, -86, 0, 30)
   901→		questionBox.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
   902→		questionBox.BorderSizePixel = 0
   903→		questionBox.Font = Enum.Font.Gotham
   904→		questionBox.PlaceholderText = "Ketik pertanyaanmu di sini..."
   905→		questionBox.Text = ""
   906→		questionBox.TextColor3 = Color3.fromRGB(255, 255, 255)
   907→		questionBox.TextSize = 14
   908→		questionBox.TextXAlignment = Enum.TextXAlignment.Left
   909→		questionBox.ClearTextOnFocus = false
   910→		questionBox.Parent = questionFrame
   911→		local questionBoxCorner = Instance.new("UICorner")
   912→		questionBoxCorner.CornerRadius = UDim.new(0, 6)
   913→		questionBoxCorner.Parent = questionBox
   914→		local questionBoxStroke = Instance.new("UIStroke")
   915→		questionBoxStroke.Color = Color3.fromRGB(90, 90, 90)
   916→		questionBoxStroke.Transparency = 0.35
   917→		questionBoxStroke.Thickness = 1
   918→		questionBoxStroke.Parent = questionBox
   919→
   920→		local questionSendButton = Instance.new("TextButton")
   921→		questionSendButton.Name = "QuestionSendButton"
   922→		questionSendButton.AnchorPoint = Vector2.new(1, 0)
   923→		questionSendButton.Position = UDim2.new(1, 0, 0, 0)
   924→		questionSendButton.Size = UDim2.new(0, 76, 0, 30)
   925→		questionSendButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
   926→		questionSendButton.BorderSizePixel = 0
   927→		questionSendButton.Font = Enum.Font.GothamBold
   928→		questionSendButton.Text = "Tanya"
   929→		questionSendButton.TextColor3 = Color3.fromRGB(255, 255, 255)
   930→		questionSendButton.TextSize = 14
   931→		questionSendButton.Parent = questionFrame
   932→		local questionButtonCorner = Instance.new("UICorner")
   933→		questionButtonCorner.CornerRadius = UDim.new(0, 6)
   934→		questionButtonCorner.Parent = questionSendButton
   935→		local questionButtonStroke = Instance.new("UIStroke")
   936→		questionButtonStroke.Color = Color3.fromRGB(90, 90, 90)
   937→		questionButtonStroke.Transparency = 0.35
   938→		questionButtonStroke.Thickness = 1
   939→		questionButtonStroke.Parent = questionSendButton
   940→
   941→		local questionHint = Instance.new("TextLabel")
   942→		questionHint.Name = "QuestionHint"
   943→		questionHint.BackgroundTransparency = 1
   944→		questionHint.Position = UDim2.new(0, 0, 0, 36)
   945→		questionHint.Size = UDim2.new(1, 0, 0, 36)
   946→		questionHint.Font = Enum.Font.Gotham
   947→		questionHint.TextColor3 = Color3.fromRGB(208, 208, 208)
   948→		questionHint.TextSize = 13
   949→		questionHint.TextWrapped = true
   950→		questionHint.TextXAlignment = Enum.TextXAlignment.Left
   951→		questionHint.TextYAlignment = Enum.TextYAlignment.Top
   952→		questionHint.Text = "Gunakan kata kunci seperti tool, ghost, match, reward, training, event, class, atau lobby."
   953→		questionHint.Parent = questionFrame
   954→
   955→		local layout = Instance.new("UIListLayout")
   956→		layout.Padding = UDim.new(0, 4)
   957→		layout.SortOrder = Enum.SortOrder.LayoutOrder
   958→		layout.Parent = choicesFrame
   959→
   960→		for _, suffix in ipairs({ "A", "B", "C", "D", "E", "F" }) do
   961→			local button = Instance.new("TextButton")
   962→			button.Name = "ChoiceButton_" .. suffix
   963→			button.Size = UDim2.new(1, 0, 0, 24)
   964→			button.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
   965→			button.BorderSizePixel = 0
   966→			button.Font = Enum.Font.Gotham
   967→			button.Text = ""
   968→			button.TextColor3 = Color3.fromRGB(255, 255, 255)
   969→			button.TextSize = 14
   970→			button.TextWrapped = true
   971→			button.TextXAlignment = Enum.TextXAlignment.Left
   972→			button.Visible = false
   973→			button.Parent = choicesFrame
   974→
   975→			local buttonCorner = Instance.new("UICorner")
   976→			buttonCorner.CornerRadius = UDim.new(0, 6)
   977→			buttonCorner.Parent = button
   978→
   979→			local buttonStroke = Instance.new("UIStroke")
   980→			buttonStroke.Color = Color3.fromRGB(90, 90, 90)
   981→			buttonStroke.Transparency = 0.4
   982→			buttonStroke.Thickness = 1
   983→			buttonStroke.Parent = button
   984→
   985→			self._choiceButtons[suffix] = button
   986→		end
   987→	end
   988→
   989→	self._ui = gui
   990→	self._mainFrame = mainFrame
   991→	self._npcNameLabel = mainFrame:FindFirstChild("NpcNameLabel")
   992→	self._dialogueText = mainFrame:FindFirstChild("DialogueText")
   993→	self._questionFrame = mainFrame:FindFirstChild("QuestionFrame")
   994→	self._questionBox = self._questionFrame and self._questionFrame:FindFirstChild("QuestionBox")
   995→	self._questionSendButton = self._questionFrame and self._questionFrame:FindFirstChild("QuestionSendButton")
   996→	self._questionHint = self._questionFrame and self._questionFrame:FindFirstChild("QuestionHint")
   997→	self._choicesFrame = mainFrame:FindFirstChild("ChoicesFrame")
   998→	self._closeButton = mainFrame:FindFirstChild("CloseButton")
   999→	return gui
  1000→end
  1001→
  1002→function NpcDialogueController:_setUiVisible(visible)
  1003→	if self._ui then
  1004→		self._ui.Enabled = visible == true
  1005→	end
  1006→end
  1007→
  1008→function NpcDialogueController:_clearChoices()
  1009→	for _, button in pairs(self._choiceButtons) do
  1010→		button.Visible = false
  1011→		button.Text = ""
  1012→	end
  1013→end
  1014→
  1015→function NpcDialogueController:_renderChoices(choices)
  1016→	self._currentChoices = choices or {}
  1017→	self:_clearChoices()
  1018→	for index, choice in ipairs(self._currentChoices) do
  1019→		local suffix = string.char(string.byte("A") + index - 1)
  1020→		local button = self._choiceButtons[suffix]
  1021→		if button then
  1022→			button.Visible = true
  1023→			button.Text = "  " .. tostring(choice.label or suffix)
  1024→		end
  1025→	end
  1026→end
  1027→
  1028→function NpcDialogueController:_setQuestionMode(visible, placeholderText)
  1029→	if self._questionFrame then
  1030→		self._questionFrame.Visible = visible == true
  1031→	end
  1032→	if self._choicesFrame then
  1033→		self._choicesFrame.Visible = visible ~= true
  1034→	end
  1035→	if self._questionBox then
  1036→		self._questionBox.PlaceholderText = placeholderText or "Ketik pertanyaanmu di sini..."
  1037→		if visible == true then
  1038→			self._questionBox.Text = ""
  1039→		end
  1040→	end
  1041→	self._dialogueQuestionMode = visible == true
  1042→	if visible == true then
  1043→		self:_setDialogueCursorUnlocked(true)
  1044→		task.defer(function()
  1045→			if self._questionBox and self._questionBox.Parent then
  1046→				pcall(function()
  1047→					self._questionBox:CaptureFocus()
  1048→				end)
  1049→			end
  1050→		end)
  1051→	end
  1052→end
  1053→
  1054→function NpcDialogueController:_applyDialogueMouseState()
  1055→	if not self._dialogueInputLocked then
  1056→		return
  1057→	end
  1058→
  1059→	if self._dialogueCursorUnlocked then
  1060→		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
  1061→		UserInputService.MouseIconEnabled = true
  1062→	else
  1063→		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
  1064→		UserInputService.MouseIconEnabled = false
  1065→	end
  1066→end
  1067→
  1068→function NpcDialogueController:_setDialogueCursorUnlocked(unlocked)
  1069→	if not self._dialogueInputLocked then
  1070→		self._dialogueCursorUnlocked = false
  1071→		return
  1072→	end
  1073→
  1074→	self._dialogueCursorUnlocked = unlocked == true
  1075→	self:_applyDialogueMouseState()
  1076→end
  1077→
  1078→function NpcDialogueController:_showNode(nodeId)
  1079→	if not self._currentNpcId then
  1080→		return
  1081→	end
  1082→
  1083→	local tree = getDialogueTree(self._currentNpcId)
  1084→	if not tree then
  1085→		return
  1086→	end
  1087→
  1088→	local node = tree[nodeId]
  1089→	if type(node) ~= "table" then
  1090→		return
  1091→	end
  1092→
  1093→	self._currentNodeId = nodeId
  1094→	self._dialogueOverrideText = nil
  1095→	if self._npcNameLabel then
  1096→		self._npcNameLabel.Text = tostring(tree.displayName or self._currentNpcId)
  1097→	end
  1098→	if self._dialogueText then
  1099→		self._dialogueText.Text = tostring(node.text or "")
  1100→	end
  1101→
  1102→	if node.inputMode == "freeform" then
  1103→		self:_setQuestionMode(true, node.inputPlaceholder)
  1104→	else
  1105→		self:_setQuestionMode(false)
  1106→	end
  1107→	self:_renderChoices(node.choices or {})
  1108→end
  1109→
  1110→function NpcDialogueController:_submitDialogueQuestion()
  1111→	if not self._isOpen or self._currentNpcId ~= "dukun" then
  1112→		return
  1113→	end
  1114→	if not self._questionBox then
  1115→		return
  1116→	end
  1117→
  1118→	local tree = getDialogueTree(self._currentNpcId)
  1119→	local question = self._questionBox.Text
  1120→	local answer = resolveDukunAnswer(tree, question)
  1121→	self._dialogueOverrideText = answer
  1122→	self._currentNodeId = "dukun_answer"
  1123→	if self._npcNameLabel then
  1124→		self._npcNameLabel.Text = tostring(tree and tree.displayName or self._currentNpcId)
  1125→	end
  1126→	if self._dialogueText then
  1127→		self._dialogueText.Text = answer
  1128→	end
  1129→	self:_setQuestionMode(false)
  1130→	self:_renderChoices({
  1131→		{ label = "A: Tanya lagi", next = "dukun_ask" },
  1132→		{ label = "B: Topik cepat", next = "dukun_topics" },
  1133→		{ label = "C: Tutup", next = "CLOSE" },
  1134→	})
  1135→end
  1136→
  1137→function NpcDialogueController:_closeDialogue(skipRemote)
  1138→	if not self._isOpen then
  1139→		return
  1140→	end
  1141→
  1142→	self._isOpen = false
  1143→	self._currentNpcId = nil
  1144→	self._currentNodeId = nil
  1145→	self._currentNpcHumanoid = nil
  1146→	self._currentNpcRoot = nil
  1147→	self:_clearChoices()
  1148→	self._currentChoices = {}
  1149→	self._dialogueOverrideText = nil
  1150→	self._dialogueQuestionMode = false
  1151→	if self._questionFrame then
  1152→		self._questionFrame.Visible = false
  1153→	end
  1154→	if self._choicesFrame then
  1155→		self._choicesFrame.Visible = true
  1156→	end
  1157→	if self._questionBox then
  1158→		self._questionBox.Text = ""
  1159→	end
  1160→	self:_stopPlayerEmoteLoop()
  1161→	self:_stopNpcGestureLoop()
  1162→	self:_stopNpcFacingLoop()
  1163→	self:_stopDialogueCamera()
  1164→	self:_unbindDialogueLockStep()
  1165→	self:_unlockDialogueInput()
  1166→	self:_unfreezePlayer()
  1167→	local player = self:_getPlayer()
  1168→	if player then
  1169→		player:SetAttribute("PasrahNpcDialogueActive", false)
  1170→	end
  1171→	self:_setUiVisible(false)
  1172→
  1173→	if self._remoteEvent and not skipRemote then
  1174→		self._remoteEvent:FireServer("CLOSE", self._currentDialogueId)
  1175→	end
  1176→	self._currentDialogueId = nil
  1177→	self._currentNpcModel = nil
  1178→end
  1179→
  1180→function NpcDialogueController:_openDialogue(dialogueId, npcModel)
  1181→	-- Tunggu character fully loaded sebelum apapun
  1182→	local player = self:_getPlayer()
  1183→	if not player then return end
  1184→
  1185→	local character = player.Character
  1186→		or player.CharacterAdded:Wait()
  1187→
  1188→	-- Tunggu HumanoidRootPart max 5 detik
  1189→	local hrp = character:FindFirstChild("HumanoidRootPart")
  1190→		or character:WaitForChild("HumanoidRootPart", 5)
  1191→	if not hrp then
  1192→		warn("[NpcDialogue] HumanoidRootPart tidak ditemukan, abort dialogue")
  1193→		return
  1194→	end
  1195→
  1196→	local humanoid = character:FindFirstChildOfClass("Humanoid")
  1197→		or character:WaitForChild("Humanoid", 5)
  1198→	if not humanoid then
  1199→		warn("[NpcDialogue] Humanoid tidak ditemukan, abort dialogue")
  1200→		return
  1201→	end
  1202→
  1203→	-- Validasi NPC model
  1204→	if not npcModel or not npcModel.Parent then
  1205→		warn("[NpcDialogue] npcModel tidak valid, abort dialogue")
  1206→		return
  1207→	end
  1208→
  1209→	local npcHumanoid = npcModel:FindFirstChildOfClass("Humanoid")
  1210→	if not npcHumanoid then
  1211→		warn("[NpcDialogue] NPC tidak punya Humanoid, abort dialogue")
  1212→		return
  1213→	end
  1214→
  1215→	local npcId = self._rootIndex[dialogueId]
  1216→	if not npcId then
  1217→		warn("[NpcDialogue] dialogueId tidak ditemukan di rootIndex:", dialogueId)
  1218→		return
  1219→	end
  1220→
  1221→	local resolvedNpc = npcModel
  1222→	local npcRoot = getModelRoot(resolvedNpc)
  1223→
  1224→	if self._isOpen then
  1225→		self:_closeDialogue()
  1226→	end
  1227→	if self._cameraRestoreTween then
  1228→		pcall(function()
  1229→			self._cameraRestoreTween:Cancel()
  1230→		end)
  1231→		self._cameraRestoreTween = nil
  1232→	end
  1233→
  1234→	self._currentNpcId = npcId
  1235→	self._currentDialogueId = dialogueId
  1236→	self._currentNpcModel = npcModel
  1237→	self._currentNpcRoot = npcRoot
  1238→	self._currentNpcHumanoid = npcHumanoid
  1239→	self._currentChoices = {}
  1240→	self._dialogueOverrideText = nil
  1241→	self._dialogueQuestionMode = false
  1242→	self._isOpen = true
  1243→	self:_setUiVisible(true)
  1244→	local player = self:_getPlayer()
  1245→	if player then
  1246→		player:SetAttribute("PasrahNpcDialogueActive", true)
  1247→	end
  1248→	self:_bindDialogueLockStep()
  1249→	self:_lockDialogueInput()
  1250→	self:_freezePlayer()
  1251→	self:_startDialogueCamera(resolvedNpc)
  1252→	self:_startNpcFacingLoop()
  1253→	self:_startNpcGestureLoop()
  1254→	self:_startPlayerEmoteLoop()
  1255→	self:_showNode(dialogueId)
  1256→end
  1257→
  1258→function NpcDialogueController:_bindUiEvents()
  1259→	if not self._ui then
  1260→		return
  1261→	end
  1262→
  1263→	if self._closeButton and not self._closeButton:GetAttribute("NpcDialogueBound") then
  1264→		self._closeButton:SetAttribute("NpcDialogueBound", true)
  1265→		table.insert(self._connections, self._closeButton.Activated:Connect(function()
  1266→			self:_closeDialogue()
  1267→		end))
  1268→	end
  1269→
  1270→	if self._questionSendButton and not self._questionSendButton:GetAttribute("NpcDialogueBound") then
  1271→		self._questionSendButton:SetAttribute("NpcDialogueBound", true)
  1272→		table.insert(self._connections, self._questionSendButton.Activated:Connect(function()
  1273→			self:_submitDialogueQuestion()
  1274→		end))
  1275→	end
  1276→
  1277→	if self._questionBox and not self._questionBox:GetAttribute("NpcDialogueBound") then
  1278→		self._questionBox:SetAttribute("NpcDialogueBound", true)
  1279→		table.insert(self._connections, self._questionBox.FocusLost:Connect(function(enterPressed)
  1280→			if enterPressed then
  1281→				self:_submitDialogueQuestion()
  1282→			end
  1283→		end))
  1284→	end
  1285→
  1286→	for suffix, button in pairs(self._choiceButtons) do
  1287→		if button and not button:GetAttribute("NpcDialogueBound") then
  1288→			button:SetAttribute("NpcDialogueBound", true)
  1289→			table.insert(self._connections, button.Activated:Connect(function()
  1290→				if not self._isOpen or not self._currentNpcId then
  1291→					return
  1292→				end
  1293→				local tree = getDialogueTree(self._currentNpcId)
  1294→				local choices = self._currentChoices or {}
  1295→				local index = string.byte(suffix) - string.byte("A") + 1
  1296→				local choice = choices[index]
  1297→				if not choice then
  1298→					return
  1299→				end
  1300→
  1301→				local nextNode = choice.next
  1302→				if nextNode == "CLOSE" then
  1303→					self:_closeDialogue()
  1304→				elseif nextNode == "ROOT" then
  1305→					if tree then
  1306→						self:_showNode(tree.root)
  1307→					end
  1308→				else
  1309→					self:_showNode(nextNode)
  1310→				end
  1311→			end))
  1312→		end
  1313→	end
  1314→end
  1315→
  1316→function NpcDialogueController:Init(context)
  1317→	self._context = context or {}
  1318→	self._connections = self._connections or {}
  1319→	self._choiceButtons = self._choiceButtons or {}
  1320→	self._remoteEvent = resolveRemoteEvent(context)
  1321→	self:_ensureUi()
  1322→	self:_bindUiEvents()
  1323→	if self._ui then
  1324→		self._ui.Enabled = false
  1325→	end
  1326→end
  1327→
  1328→function NpcDialogueController:Start(context)
  1329→	self._context = context or self._context or {}
  1330→	local function bindRemote(remoteEvent)
  1331→		if not remoteEvent or self._remoteConnection then
  1332→			return
  1333→		end
  1334→		self._remoteConnection = remoteEvent.OnClientEvent:Connect(function(action, dialogueId, npcModel)
  1335→			if action == "OPEN" then
  1336→				self:_openDialogue(dialogueId, npcModel)
  1337→			elseif action == "CLOSE" then
  1338→				self:_closeDialogue(true)
  1339→			end
  1340→		end)
  1341→	end
  1342→
  1343→	self._remoteEvent = self._remoteEvent or resolveRemoteEvent(self._context)
  1344→	if self._remoteEvent then
  1345→		bindRemote(self._remoteEvent)
  1346→	elseif not self._remoteRetryTask then
  1347→		self._remoteRetryTask = task.spawn(function()
  1348→			local deadline = time() + 15
  1349→			while not self._remoteEvent and time() < deadline do
  1350→				self._remoteEvent = resolveRemoteEvent(self._context)
  1351→				if self._remoteEvent then
  1352→					bindRemote(self._remoteEvent)
  1353→					break
  1354→				end
  1355→				task.wait(0.5)
  1356→			end
  1357→			self._remoteRetryTask = nil
  1358→		end)
  1359→	end
  1360→
  1361→	if self._characterConnection then
  1362→		self._characterConnection:Disconnect()
  1363→	end
  1364→	local player = self:_getPlayer()
  1365→	if player then
  1366→		self._characterConnection = player.CharacterAdded:Connect(function()
  1367→			if self._isOpen then
  1368→				task.defer(function()
  1369→					self:_freezePlayer()
  1370→				end)
  1371→			end
  1372→		end)
  1373→	end
  1374→
  1375→	self:_setUiVisible(false)
  1376→
  1377→	if UserInputService.InputBegan then
  1378→		table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
  1379→			if gameProcessed then
  1380→				return
  1381→			end
  1382→			if UserInputService:GetFocusedTextBox() then
  1383→				return
  1384→			end
  1385→			if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.X then
  1386→				self:_closeDialogue()
  1387→			end
  1388→		end))
  1389→	end
  1390→end
  1391→
  1392→function NpcDialogueController:Stop()
  1393→	if self._remoteConnection then
  1394→		self._remoteConnection:Disconnect()
  1395→		self._remoteConnection = nil
  1396→	end
  1397→	if self._characterConnection then
  1398→		self._characterConnection:Disconnect()
  1399→		self._characterConnection = nil
  1400→	end
  1401→	for _, connection in ipairs(self._connections) do
  1402→		connection:Disconnect()
  1403→	end
  1404→	table.clear(self._connections)
  1405→	self:_closeDialogue(true)
  1406→	if self._cameraStepBound then
  1407→		pcall(function()
  1408→			RunService:UnbindFromRenderStep(DIALOGUE_CAMERA_BIND_NAME)
  1409→		end)
  1410→		self._cameraStepBound = false
  1411→	end
  1412→	self:_unbindDialogueLockStep()
  1413→	self:_unlockDialogueInput()
  1414→	self:_unfreezePlayer()
  1415→	local player = self:_getPlayer()
  1416→	if player then
  1417→		player:SetAttribute("PasrahNpcDialogueActive", false)
  1418→	end
  1419→	if self._ui then
  1420→		self._ui:Destroy()
  1421→		self._ui = nil
  1422→	end
  1423→	self._mainFrame = nil
  1424→	self._npcNameLabel = nil
  1425→	self._dialogueText = nil
  1426→	self._questionFrame = nil
  1427→	self._questionBox = nil
  1428→	self._questionSendButton = nil
  1429→	self._questionHint = nil
  1430→	self._choicesFrame = nil
  1431→	self._closeButton = nil
  1432→end
  1433→
  1434→local controller = NpcDialogueController.new()
  1435→controller.new = NpcDialogueController.new
  1436→return controller
  1437→

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local DialogueData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("NpcDialogue"):WaitForChild("DialogueData"))

local NpcDialogueController = {}
NpcDialogueController.__index = NpcDialogueController

local UI_NAME = "NpcDialogueUI"
local DIALOGUE_INPUT_ACTION = "PasrahNpcDialogueInputLock"
local DIALOGUE_CURSOR_TOGGLE_ACTION = "PasrahNpcDialogueCursorToggle"
local DIALOGUE_CLOSE_ACTION = "PasrahNpcDialogueClose"
local DIALOGUE_CAMERA_BIND_NAME = "PasrahNpcDialogueCamera"
local DIALOGUE_LOCK_BIND_NAME = "PasrahNpcDialogueLock"
local DIALOGUE_CAMERA_TWEEN_DURATION = 1.5
local DIALOGUE_PLAYER_EMOTE_INTERVAL = 15
local DIALOGUE_NPC_GESTURE_INTERVAL = 5
local DEFAULT_WALKSPEED = 16
local DEFAULT_JUMPPOWER = 50
local NPC_GESTURE_ANIMATION_ID = "rbxassetid://507771019"

local function resolveRemoteEvent(context)
local remotes = context and context.Remotes
if remotes and remotes.NpcDialogueEvent then
return remotes.NpcDialogueEvent
end

local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
return remoteFolder and remoteFolder:FindFirstChild("NpcDialogueEvent") or nil
end

local function buildTreeIndex()
local index = {}
for npcId, tree in pairs(DialogueData) do
if type(tree) == "table" and type(tree.root) == "string" then
index[tree.root] = npcId
end
end
return index
end

local function getDialogueTree(npcId)
local tree = DialogueData[npcId]
if type(tree) ~= "table" then
return nil
end
return tree
end

local function getCharacterRoot(character)
if not character then
return nil
end
return character:FindFirstChild("HumanoidRootPart")
or character:WaitForChild("HumanoidRootPart", 3)
end

local function getModelRoot(model)
if not model then
return nil
end
if model.PrimaryPart and model.PrimaryPart:IsA("BasePart") then
return model.PrimaryPart
end
local root = model:FindFirstChild("HumanoidRootPart")
if root and root:IsA("BasePart") then
return root
end
return model:FindFirstChildWhichIsA("BasePart", true)
end

local function getAnimator(humanoid)
if not humanoid then
return nil
end
local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then
animator = Instance.new("Animator")
animator.Parent = humanoid
end
return animator
end

local function stopTrack(track)
if track and track.IsPlaying then
pcall(function()
track:Stop()
end)
end
end

local function normalizeQuestionText(text)
local normalized = tostring(text or ""):lower()
normalized = normalized:gsub("[%z\1-\31\127]", " ")
normalized = normalized:gsub("[%p]", " ")
normalized = normalized:gsub("%s+", " ")
return normalized
end

local function resolveDukunAnswer(tree, questionText)
local responses = type(tree) == "table" and tree.responses or nil
local normalized = normalizeQuestionText(questionText)
if normalized == "" then
return "Aku belum menangkap pertanyaannya. Coba tulis ulang dengan kata kunci seperti tool, ghost, match, shop, reward, training, event, atau class."
end

if type(responses) == "table" then
for _, response in ipairs(responses) do
if type(response) == "table" and type(response.keywords) == "table" then
for _, keyword in ipairs(response.keywords) do
local needle = normalizeQuestionText(keyword)
if needle ~= "" and normalized:find(needle, 1, true) then
return tostring(response.text or "")
end
end
end
end
end

return "Aku belum yakin topiknya. Coba kata kunci: tool, ghost, match, shop, reward, training, event, class, party, atau lobby."
end

function NpcDialogueController.new()
local self = setmetatable({}, NpcDialogueController)
self._remoteEvent = nil
self._remoteConnection = nil
self._characterConnection = nil
self._connections = {}
self._ui = nil
self._mainFrame = nil
self._npcNameLabel = nil
self._dialogueText = nil
self._questionFrame = nil
self._questionBox = nil
self._questionSendButton = nil
self._questionHint = nil
self._choicesFrame = nil
self._closeButton = nil
self._choiceButtons = {}
self._currentChoices = {}
self._rootIndex = buildTreeIndex()
self._currentNpcId = nil
self._currentNodeId = nil
self._isOpen = false
self._freezeSnapshot = nil
self._cameraSnapshot = nil
self._currentNpcModel = nil
self._currentNpcRoot = nil
self._currentNpcHumanoid = nil
self._currentNpcPivot = nil
self._npcGestureTrack = nil
self._playerEmoteLoopToken = 0
self._npcGestureLoopToken = 0
self._dialogueInputLocked = false
self._dialogueCursorUnlocked = false
self._previousMouseBehavior = nil
self._previousMouseIconEnabled = nil
self._controls = nil
self._cameraStepBound = false
self._dialogueLockStepBound = false
self._cameraMode = nil
self._cameraStartTime = nil
self._cameraOpenStartCFrame = nil
self._cameraOpenTargetCFrame = nil
self._cameraCloseStartCFrame = nil
self._cameraCloseTargetCFrame = nil
self._cameraRestoreType = nil
self._cameraRestoreSubject = nil
self._currentDialogueId = nil
self._dialogueOverrideText = nil
self._dialogueQuestionMode = false
return self
end

function NpcDialogueController:_getPlayer()
return Players.LocalPlayer
end

function NpcDialogueController:_getHumanoid()
local player = self:_getPlayer()
if not player then return nil end
local character = player.Character
if not character then return nil end
return character:FindFirstChildOfClass("Humanoid")
or character:WaitForChild("Humanoid", 3)
end

function NpcDialogueController:_resolveControls()
if self._controls then
return self._controls
end

local player = self:_getPlayer()
local playerScripts = player and (player:FindFirstChild("PlayerScripts") or player:WaitForChild("PlayerScripts", 5))
local playerModule = playerScripts and playerScripts:FindFirstChild("PlayerModule")
if not playerModule then
return nil
end

local ok, module = pcall(require, playerModule)
if not ok or type(module) ~= "table" then
return nil
end

local controls = nil
if type(module.GetControls) == "function" then
local okControls, resolved = pcall(function()
return module:GetControls()
end)
if okControls then
controls = resolved
end
end

self._controls = controls
return self._controls
end

function NpcDialogueController:_getNpcFromPrompt(dialogueId, preferredNpc)
if preferredNpc and preferredNpc:IsA("Model") and preferredNpc.Parent and preferredNpc:GetAttribute("PasrahNpcDialogueId") == dialogueId then
return preferredNpc
end

local player = self:_getPlayer()
local character = player and player.Character
local characterRoot = getCharacterRoot(character)
local nearestNpc = nil
local nearestDistance = math.huge

for _, descendant in ipairs(Workspace:GetDescendants()) do
if descendant:IsA("ProximityPrompt") and descendant.Name == "DialoguePrompt" then
local npc = descendant:FindFirstAncestorWhichIsA("Model")
if npc and npc.Parent and npc:GetAttribute("PasrahNpcDialogueId") == dialogueId then
local root = getModelRoot(npc)
if root then
local distance = 0
if characterRoot then
distance = (root.Position - characterRoot.Position).Magnitude
end
if distance < nearestDistance then
nearestDistance = distance
nearestNpc = npc
end
end
end
end
end

return nearestNpc
end

function NpcDialogueController:_freezePlayer()
local humanoid = self:_getHumanoid()
if not humanoid then
warn("[NpcDialogue] Humanoid nil saat freeze, retry dalam 1 detik")
task.delay(1, function()
local hum = self:_getHumanoid()
if hum and self._isOpen then
hum.WalkSpeed = 0
hum.JumpPower = 0
hum.AutoRotate = false
end
end)
return
end

local player = self:_getPlayer()
if player then
player:SetAttribute("PasrahNpcDialogueActive", true)
end

if not self._freezeSnapshot then
local character = player and player.Character
local rootPart = getCharacterRoot(character)
self._freezeSnapshot = {
WalkSpeed = humanoid.WalkSpeed,
JumpPower = humanoid.JumpPower,
JumpHeight = humanoid.JumpHeight,
UseJumpPower = humanoid.UseJumpPower,
AutoRotate = humanoid.AutoRotate,
RootPart = rootPart,
RootAnchored = rootPart and rootPart:IsA("BasePart") and rootPart.Anchored or nil,
}
end

humanoid.WalkSpeed = 0
if humanoid.UseJumpPower then
humanoid.JumpPower = 0
else
humanoid.JumpHeight = 0
end
humanoid.AutoRotate = false

local rootPart = self._freezeSnapshot and self._freezeSnapshot.RootPart
if rootPart and rootPart:IsA("BasePart") then
rootPart.AssemblyLinearVelocity = Vector3.zero
rootPart.AssemblyAngularVelocity = Vector3.zero
rootPart.Anchored = true
end

local controls = self:_resolveControls()
if controls and type(controls.Disable) == "function" then
pcall(function()
controls:Disable()
end)
end
end

function NpcDialogueController:_unfreezePlayer()
local snapshot = self._freezeSnapshot
self._freezeSnapshot = nil
local humanoid = self:_getHumanoid()
if not humanoid then
return
end

if snapshot then
humanoid.WalkSpeed = snapshot.WalkSpeed or DEFAULT_WALKSPEED
humanoid.UseJumpPower = snapshot.UseJumpPower ~= false
if snapshot.UseJumpPower ~= false then
humanoid.JumpPower = snapshot.JumpPower or DEFAULT_JUMPPOWER
else
humanoid.JumpHeight = snapshot.JumpHeight or humanoid.JumpHeight
end
humanoid.AutoRotate = snapshot.AutoRotate ~= false
else
humanoid.WalkSpeed = DEFAULT_WALKSPEED
humanoid.JumpPower = DEFAULT_JUMPPOWER
humanoid.AutoRotate = true
end

local rootPart = snapshot and snapshot.RootPart
if rootPart and rootPart:IsA("BasePart") then
rootPart.AssemblyLinearVelocity = Vector3.zero
rootPart.AssemblyAngularVelocity = Vector3.zero
rootPart.Anchored = snapshot.RootAnchored == true
end

local controls = self:_resolveControls()
if controls and type(controls.Enable) == "function" then
pcall(function()
controls:Enable()
end)
end
end

function NpcDialogueController:_lockDialogueInput()
if self._dialogueInputLocked then
return
end
self._dialogueInputLocked = true
self._dialogueCursorUnlocked = false

self._previousMouseBehavior = UserInputService.MouseBehavior
self._previousMouseIconEnabled = UserInputService.MouseIconEnabled

self:_applyDialogueMouseState()

ContextActionService:BindAction(
DIALOGUE_INPUT_ACTION,
function()
return Enum.ContextActionResult.Sink
end,
false,
unpack(Enum.PlayerActions:GetEnumItems())
)
ContextActionService:BindAction(
DIALOGUE_CURSOR_TOGGLE_ACTION,
function(_, inputState)
if inputState ~= Enum.UserInputState.Begin then
return Enum.ContextActionResult.Sink
end

self:_setDialogueCursorUnlocked(not self._dialogueCursorUnlocked)
return Enum.ContextActionResult.Sink
end,
false,
Enum.KeyCode.LeftAlt,
Enum.KeyCode.Backquote
)
ContextActionService:BindAction(
DIALOGUE_CLOSE_ACTION,
function()
self:_closeDialogue()
return Enum.ContextActionResult.Sink
end,
false,
Enum.KeyCode.Escape,
Enum.KeyCode.Backspace,
Enum.KeyCode.X
)
end

function NpcDialogueController:_unlockDialogueInput()
if not self._dialogueInputLocked then
return
end
self._dialogueInputLocked = false
pcall(function()
ContextActionService:UnbindAction(DIALOGUE_INPUT_ACTION)
end)
pcall(function()
ContextActionService:UnbindAction(DIALOGUE_CURSOR_TOGGLE_ACTION)
end)
pcall(function()
ContextActionService:UnbindAction(DIALOGUE_CLOSE_ACTION)
end)

if self._previousMouseBehavior ~= nil then
UserInputService.MouseBehavior = self._previousMouseBehavior
end
if self._previousMouseIconEnabled ~= nil then
UserInputService.MouseIconEnabled = self._previousMouseIconEnabled
end
self._previousMouseBehavior = nil
self._previousMouseIconEnabled = nil
self._dialogueCursorUnlocked = false
end

function NpcDialogueController:_playOwnedEmote(humanoid)
if not humanoid then
return
end

local humanoidDescription = humanoid:FindFirstChildOfClass("HumanoidDescription")
if not humanoidDescription then
pcall(function()
humanoid:PlayEmote("wave")
end)
return
end

local validEmotes = {}
local ok, equippedEmotes = pcall(function()
return humanoidDescription:GetEquippedEmotes()
end)
if ok and type(equippedEmotes) == "table" then
for _, dataEmote in pairs(equippedEmotes) do
if dataEmote.Name and dataEmote.Name ~= "" then
table.insert(validEmotes, dataEmote.Name)
end
end
end

local selectedEmote = validEmotes[1]
if #validEmotes > 1 then
selectedEmote = validEmotes[math.random(1, #validEmotes)]
end
if not selectedEmote or selectedEmote == "" then
selectedEmote = "wave"
end

pcall(function()
humanoid:PlayEmote(selectedEmote)
end)
end

function NpcDialogueController:_playNpcGesture(npcHumanoid)
if not npcHumanoid then
return
end

if self._npcGestureTrack and self._npcGestureTrack.IsPlaying then
return
end

local animator = getAnimator(npcHumanoid)
if not animator then
return
end

local gestureAnimation = Instance.new("Animation")
gestureAnimation.AnimationId = NPC_GESTURE_ANIMATION_ID
local ok, track = pcall(function()
return animator:LoadAnimation(gestureAnimation)
end)
if ok and track then
self._npcGestureTrack = track
track.Priority = Enum.AnimationPriority.Action
track:Play()
return
end

pcall(function()
npcHumanoid:PlayEmote("wave")
end)
end

function NpcDialogueController:_bindDialogueLockStep()
if self._dialogueLockStepBound then
return
end
self._dialogueLockStepBound = true

RunService:BindToRenderStep(DIALOGUE_LOCK_BIND_NAME, Enum.RenderPriority.First.Value, function()
if not self._isOpen then
return
end

local player = self:_getPlayer()
local humanoid = self:_getHumanoid()
local camera = Workspace.CurrentCamera

if player then
player:SetAttribute("PasrahNpcDialogueActive", true)
end

if humanoid then
humanoid.WalkSpeed = 0
if humanoid.UseJumpPower then
humanoid.JumpPower = 0
else
humanoid.JumpHeight = 0
end
humanoid.AutoRotate = false
humanoid:Move(Vector3.zero, false)
end

if player and player.Character then
local rootPart = getCharacterRoot(player.Character)
if rootPart and rootPart:IsA("BasePart") then
rootPart.AssemblyLinearVelocity = Vector3.zero
rootPart.AssemblyAngularVelocity = Vector3.zero
rootPart.Anchored = true
end
end

local controls = self:_resolveControls()
if controls and type(controls.Disable) == "function" then
pcall(function()
controls:Disable()
end)
end

self:_applyDialogueMouseState()

if camera then
camera.CameraType = Enum.CameraType.Scriptable
end
end)
end

function NpcDialogueController:_unbindDialogueLockStep()
if not self._dialogueLockStepBound then
return
end
self._dialogueLockStepBound = false
pcall(function()
RunService:UnbindFromRenderStep(DIALOGUE_LOCK_BIND_NAME)
end)
end

function NpcDialogueController:_startPlayerEmoteLoop()
self._playerEmoteLoopToken = (self._playerEmoteLoopToken or 0) + 1
local token = self._playerEmoteLoopToken
task.spawn(function()
while self._isOpen and self._playerEmoteLoopToken == token do
local humanoid = self:_getHumanoid()
self:_playOwnedEmote(humanoid)
task.wait(DIALOGUE_PLAYER_EMOTE_INTERVAL)
end
end)
end

function NpcDialogueController:_stopPlayerEmoteLoop()
self._playerEmoteLoopToken = (self._playerEmoteLoopToken or 0) + 1
end

function NpcDialogueController:_startNpcGestureLoop()
self._npcGestureLoopToken = (self._npcGestureLoopToken or 0) + 1
local token = self._npcGestureLoopToken
task.spawn(function()
while self._isOpen and self._npcGestureLoopToken == token do
local npcHumanoid = self._currentNpcHumanoid
if not (npcHumanoid and npcHumanoid.Parent) then
break
end
self:_playNpcGesture(npcHumanoid)
task.wait(DIALOGUE_NPC_GESTURE_INTERVAL)
end
end)
end

function NpcDialogueController:_stopNpcGestureLoop()
self._npcGestureLoopToken = (self._npcGestureLoopToken or 0) + 1
if self._npcGestureTrack then
stopTrack(self._npcGestureTrack)
self._npcGestureTrack = nil
end
end

function NpcDialogueController:_startNpcFacingLoop()
self._npcFacingLoopToken = (self._npcFacingLoopToken or 0) + 1
local token = self._npcFacingLoopToken
if self._npcFacingConnection then
self._npcFacingConnection:Disconnect()
self._npcFacingConnection = nil
end

self._npcFacingConnection = RunService.Heartbeat:Connect(function()
if not self._isOpen or self._npcFacingLoopToken ~= token then
return
end

local npcModel = self._currentNpcModel
local player = self:_getPlayer()
local character = player and player.Character
local characterRoot = getCharacterRoot(character)
if not (npcModel and characterRoot and npcModel.Parent) then
return
end

local npcPivot = npcModel:GetPivot()
local target = Vector3.new(characterRoot.Position.X, npcPivot.Position.Y, characterRoot.Position.Z)
pcall(function()
npcModel:PivotTo(CFrame.lookAt(npcPivot.Position, target))
end)
end)
end

function NpcDialogueController:_stopNpcFacingLoop()
self._npcFacingLoopToken = (self._npcFacingLoopToken or 0) + 1
if self._npcFacingConnection then
self._npcFacingConnection:Disconnect()
self._npcFacingConnection = nil
end
end

function NpcDialogueController:_bindDialogueCameraStep()
if self._cameraStepBound then
return
end
self._cameraStepBound = true

RunService:BindToRenderStep(DIALOGUE_CAMERA_BIND_NAME, Enum.RenderPriority.Last.Value, function()
local camera = Workspace.CurrentCamera
if not camera then
return
end

if self._cameraMode == "opening" then
local startCFrame = self._cameraOpenStartCFrame
local targetCFrame = self._cameraOpenTargetCFrame
local startTime = self._cameraStartTime or 0
if not (startCFrame and targetCFrame) then
return
end

local alpha = math.clamp((time() - startTime) / DIALOGUE_CAMERA_TWEEN_DURATION, 0, 1)
local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = startCFrame:Lerp(targetCFrame, eased)
if alpha >= 1 then
camera.CFrame = targetCFrame
self._cameraMode = "open"
camera.CameraType = Enum.CameraType.Scriptable
end
return
end

if self._cameraMode == "open" then
if self._cameraOpenTargetCFrame then
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = self._cameraOpenTargetCFrame
end
return
end

if self._cameraMode == "closing" then
local startCFrame = self._cameraCloseStartCFrame
local targetCFrame = self._cameraCloseTargetCFrame
local startTime = self._cameraStartTime or 0
if not (startCFrame and targetCFrame) then
self._cameraMode = nil
return
end

local alpha = math.clamp((time() - startTime) / DIALOGUE_CAMERA_TWEEN_DURATION, 0, 1)
local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = startCFrame:Lerp(targetCFrame, eased)
if alpha >= 1 then
camera.CFrame = targetCFrame
camera.CameraType = self._cameraRestoreType or Enum.CameraType.Custom
camera.CameraSubject = self._cameraRestoreSubject
self._cameraMode = nil
self._cameraSnapshot = nil
self._cameraOpenStartCFrame = nil
self._cameraOpenTargetCFrame = nil
self._cameraCloseStartCFrame = nil
self._cameraCloseTargetCFrame = nil
self._cameraRestoreType = nil
self._cameraRestoreSubject = nil
pcall(function()
RunService:UnbindFromRenderStep(DIALOGUE_CAMERA_BIND_NAME)
end)
self._cameraStepBound = false
self:_unlockDialogueInput()
self:_unfreezePlayer()
local player = self:_getPlayer()
if player then
player:SetAttribute("PasrahNpcDialogueActive", false)
end
end
end
end)
end

function NpcDialogueController:_startDialogueCamera(npcModel)
local camera = Workspace.CurrentCamera
local player = self:_getPlayer()
local character = player and player.Character
local characterRoot = getCharacterRoot(character)
local npcRoot = getModelRoot(npcModel)
if not camera then
warn("[NpcDialogue] Camera tidak ditemukan")
return
end
if not npcModel or not npcModel.Parent then
warn("[NpcDialogue] npcModel nil saat camera tween")
return
end
if not characterRoot then
warn("[NpcDialogue] characterRoot nil saat camera tween")
return
end

self._cameraRestoreType = camera.CameraType
self._cameraRestoreSubject = camera.CameraSubject
self._cameraSnapshot = {
CameraType = camera.CameraType,
CameraSubject = camera.CameraSubject,
CFrame = camera.CFrame,
}
self._cameraOpenStartCFrame = camera.CFrame
self._cameraStartTime = time()

local npcPivot = npcModel:GetPivot()
local npcPosition = npcRoot and npcRoot.Position or npcPivot.Position
self._currentNpcPivot = npcPivot
local faceTarget = Vector3.new(characterRoot.Position.X, npcPivot.Position.Y, characterRoot.Position.Z)
npcModel:PivotTo(CFrame.lookAt(npcPivot.Position, faceTarget))

npcPivot = npcModel:GetPivot()
local midpoint = (characterRoot.Position + npcPosition) * 0.5
local side = npcPivot.RightVector
if side.Magnitude < 0.1 then
side = characterRoot.CFrame.RightVector
end
if side.Magnitude < 0.1 then
side = Vector3.new(1, 0, 0)
end
side = side.Unit
local distance = math.clamp((characterRoot.Position - npcPosition).Magnitude * 0.7 + 3, 6, 10)
local cameraPosition = midpoint + side * distance + Vector3.new(0, 2.8, 0)
local cameraTarget = midpoint + Vector3.new(0, 1.8, 0)
self._cameraOpenTargetCFrame = CFrame.lookAt(cameraPosition, cameraTarget)

self._cameraMode = "opening"
camera.CameraType = Enum.CameraType.Scriptable
self:_bindDialogueCameraStep()
end

function NpcDialogueController:_stopDialogueCamera()
local camera = Workspace.CurrentCamera
if not camera then
self._cameraMode = nil
		self:_unlockDialogueInput()
self:_unfreezePlayer()
local player = self:_getPlayer()
if player then
player:SetAttribute("PasrahNpcDialogueActive", false)
end
return
end

local currentCFrame = camera.CFrame
self._cameraCloseStartCFrame = currentCFrame
self._cameraCloseTargetCFrame = self._cameraSnapshot and self._cameraSnapshot.CFrame or currentCFrame
self._cameraStartTime = time()
self._cameraMode = "closing"
camera.CameraType = Enum.CameraType.Scriptable
self:_bindDialogueCameraStep()

if self._currentNpcModel and self._currentNpcPivot then
pcall(function()
self._currentNpcModel:PivotTo(self._currentNpcPivot)
end)
end
self._currentNpcPivot = nil
end

function NpcDialogueController:_ensureUi()
local player = self:_getPlayer()
if not player then
return nil
end

local playerGui = player:WaitForChild("PlayerGui")
local gui = playerGui:FindFirstChild(UI_NAME)
if not gui then
gui = Instance.new("ScreenGui")
gui.Name = UI_NAME
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 250
gui.Enabled = false
gui.Parent = playerGui
end

local mainFrame = gui:FindFirstChild("MainFrame")
if not mainFrame then
mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 1)
mainFrame.Position = UDim2.new(0.5, 0, 0.96, 0)
mainFrame.Size = UDim2.new(0.6, 0, 0.25, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0.3
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(84, 84, 84)
stroke.Transparency = 0.2
stroke.Thickness = 1
stroke.Parent = mainFrame

local npcNameLabel = Instance.new("TextLabel")
npcNameLabel.Name = "NpcNameLabel"
npcNameLabel.BackgroundTransparency = 1
npcNameLabel.Size = UDim2.new(1, -60, 0, 24)
npcNameLabel.Position = UDim2.new(0, 16, 0, 10)
npcNameLabel.Font = Enum.Font.GothamBold
npcNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
npcNameLabel.TextSize = 18
npcNameLabel.TextXAlignment = Enum.TextXAlignment.Left
npcNameLabel.Text = "NPC"
npcNameLabel.Parent = mainFrame

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -12, 0, 10)
closeButton.Size = UDim2.new(0, 28, 0, 28)
closeButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextSize = 18
closeButton.Parent = mainFrame
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

local dialogueText = Instance.new("TextLabel")
dialogueText.Name = "DialogueText"
dialogueText.BackgroundTransparency = 1
dialogueText.Position = UDim2.new(0, 16, 0, 38)
dialogueText.Size = UDim2.new(1, -32, 0, 44)
dialogueText.Font = Enum.Font.Gotham
dialogueText.TextColor3 = Color3.fromRGB(255, 255, 255)
dialogueText.TextSize = 16
dialogueText.TextWrapped = true
dialogueText.TextXAlignment = Enum.TextXAlignment.Left
dialogueText.TextYAlignment = Enum.TextYAlignment.Top
dialogueText.Text = ""
dialogueText.Parent = mainFrame

local choicesFrame = Instance.new("Frame")
choicesFrame.Name = "ChoicesFrame"
choicesFrame.BackgroundTransparency = 1
choicesFrame.Position = UDim2.new(0, 16, 0, 88)
choicesFrame.Size = UDim2.new(1, -32, 1, -98)
choicesFrame.Parent = mainFrame

local questionFrame = Instance.new("Frame")
questionFrame.Name = "QuestionFrame"
questionFrame.BackgroundTransparency = 1
questionFrame.Position = UDim2.new(0, 16, 0, 88)
questionFrame.Size = UDim2.new(1, -32, 1, -98)
questionFrame.Visible = false
questionFrame.Parent = mainFrame

local questionBox = Instance.new("TextBox")
questionBox.Name = "QuestionBox"
questionBox.AnchorPoint = Vector2.new(0, 0)
questionBox.Position = UDim2.new(0, 0, 0, 0)
questionBox.Size = UDim2.new(1, -86, 0, 30)
questionBox.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
questionBox.BorderSizePixel = 0
questionBox.Font = Enum.Font.Gotham
questionBox.PlaceholderText = "Ketik pertanyaanmu di sini..."
questionBox.Text = ""
questionBox.TextColor3 = Color3.fromRGB(255, 255, 255)
questionBox.TextSize = 14
questionBox.TextXAlignment = Enum.TextXAlignment.Left
questionBox.ClearTextOnFocus = false
questionBox.Parent = questionFrame
local questionBoxCorner = Instance.new("UICorner")
questionBoxCorner.CornerRadius = UDim.new(0, 6)
questionBoxCorner.Parent = questionBox
local questionBoxStroke = Instance.new("UIStroke")
questionBoxStroke.Color = Color3.fromRGB(90, 90, 90)
questionBoxStroke.Transparency = 0.35
questionBoxStroke.Thickness = 1
questionBoxStroke.Parent = questionBox

local questionSendButton = Instance.new("TextButton")
questionSendButton.Name = "QuestionSendButton"
questionSendButton.AnchorPoint = Vector2.new(1, 0)
questionSendButton.Position = UDim2.new(1, 0, 0, 0)
questionSendButton.Size = UDim2.new(0, 76, 0, 30)
questionSendButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
questionSendButton.BorderSizePixel = 0
questionSendButton.Font = Enum.Font.GothamBold
questionSendButton.Text = "Tanya"
questionSendButton.TextColor3 = Color3.fromRGB(255, 255, 255)
questionSendButton.TextSize = 14
questionSendButton.Parent = questionFrame
local questionButtonCorner = Instance.new("UICorner")
questionButtonCorner.CornerRadius = UDim.new(0, 6)
questionButtonCorner.Parent = questionSendButton
local questionButtonStroke = Instance.new("UIStroke")
questionButtonStroke.Color = Color3.fromRGB(90, 90, 90)
questionButtonStroke.Transparency = 0.35
questionButtonStroke.Thickness = 1
questionButtonStroke.Parent = questionSendButton

local questionHint = Instance.new("TextLabel")
questionHint.Name = "QuestionHint"
questionHint.BackgroundTransparency = 1
questionHint.Position = UDim2.new(0, 0, 0, 36)
questionHint.Size = UDim2.new(1, 0, 0, 36)
questionHint.Font = Enum.Font.Gotham
questionHint.TextColor3 = Color3.fromRGB(208, 208, 208)
questionHint.TextSize = 13
questionHint.TextWrapped = true
questionHint.TextXAlignment = Enum.TextXAlignment.Left
questionHint.TextYAlignment = Enum.TextYAlignment.Top
questionHint.Text = "Gunakan kata kunci seperti tool, ghost, match, reward, training, event, class, atau lobby."
questionHint.Parent = questionFrame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = choicesFrame

for _, suffix in ipairs({ "A", "B", "C", "D", "E", "F" }) do
local button = Instance.new("TextButton")
button.Name = "ChoiceButton_" .. suffix
button.Size = UDim2.new(1, 0, 0, 24)
button.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
button.BorderSizePixel = 0
button.Font = Enum.Font.Gotham
button.Text = ""
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextSize = 14
button.TextWrapped = true
button.TextXAlignment = Enum.TextXAlignment.Left
button.Visible = false
button.Parent = choicesFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 6)
buttonCorner.Parent = button

local buttonStroke = Instance.new("UIStroke")
buttonStroke.Color = Color3.fromRGB(90, 90, 90)
buttonStroke.Transparency = 0.4
buttonStroke.Thickness = 1
buttonStroke.Parent = button

self._choiceButtons[suffix] = button
end
end

self._ui = gui
self._mainFrame = mainFrame
self._npcNameLabel = mainFrame:FindFirstChild("NpcNameLabel")
self._dialogueText = mainFrame:FindFirstChild("DialogueText")
self._questionFrame = mainFrame:FindFirstChild("QuestionFrame")
self._questionBox = self._questionFrame and self._questionFrame:FindFirstChild("QuestionBox")
self._questionSendButton = self._questionFrame and self._questionFrame:FindFirstChild("QuestionSendButton")
self._questionHint = self._questionFrame and self._questionFrame:FindFirstChild("QuestionHint")
self._choicesFrame = mainFrame:FindFirstChild("ChoicesFrame")
self._closeButton = mainFrame:FindFirstChild("CloseButton")
return gui
end

function NpcDialogueController:_setUiVisible(visible)
if self._ui then
self._ui.Enabled = visible == true
end
end

function NpcDialogueController:_clearChoices()
for _, button in pairs(self._choiceButtons) do
button.Visible = false
button.Text = ""
end
end

function NpcDialogueController:_renderChoices(choices)
self._currentChoices = choices or {}
self:_clearChoices()
for index, choice in ipairs(self._currentChoices) do
local suffix = string.char(string.byte("A") + index - 1)
local button = self._choiceButtons[suffix]
if button then
button.Visible = true
button.Text = "  " .. tostring(choice.label or suffix)
end
end
end

function NpcDialogueController:_setQuestionMode(visible, placeholderText)
if self._questionFrame then
self._questionFrame.Visible = visible == true
end
if self._choicesFrame then
self._choicesFrame.Visible = visible ~= true
end
if self._questionBox then
self._questionBox.PlaceholderText = placeholderText or "Ketik pertanyaanmu di sini..."
if visible == true then
self._questionBox.Text = ""
end
end
self._dialogueQuestionMode = visible == true
if visible == true then
self:_setDialogueCursorUnlocked(true)
task.defer(function()
if self._questionBox and self._questionBox.Parent then
pcall(function()
self._questionBox:CaptureFocus()
end)
end
end)
end
end

function NpcDialogueController:_applyDialogueMouseState()
if not self._dialogueInputLocked then
return
end

if self._dialogueCursorUnlocked then
UserInputService.MouseBehavior = Enum.MouseBehavior.Default
UserInputService.MouseIconEnabled = true
else
UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
UserInputService.MouseIconEnabled = false
end
end

function NpcDialogueController:_setDialogueCursorUnlocked(unlocked)
if not self._dialogueInputLocked then
self._dialogueCursorUnlocked = false
return
end

self._dialogueCursorUnlocked = unlocked == true
self:_applyDialogueMouseState()
end

function NpcDialogueController:_showNode(nodeId)
if not self._currentNpcId then
return
end

local tree = getDialogueTree(self._currentNpcId)
if not tree then
return
end

local node = tree[nodeId]
if type(node) ~= "table" then
return
end

self._currentNodeId = nodeId
self._dialogueOverrideText = nil
if self._npcNameLabel then
self._npcNameLabel.Text = tostring(tree.displayName or self._currentNpcId)
end
if self._dialogueText then
self._dialogueText.Text = tostring(node.text or "")
end

if node.inputMode == "freeform" then
self:_setQuestionMode(true, node.inputPlaceholder)
else
self:_setQuestionMode(false)
end
self:_renderChoices(node.choices or {})
end

function NpcDialogueController:_submitDialogueQuestion()
if not self._isOpen or self._currentNpcId ~= "dukun" then
return
end
if not self._questionBox then
return
end

local tree = getDialogueTree(self._currentNpcId)
local question = self._questionBox.Text
local answer = resolveDukunAnswer(tree, question)
self._dialogueOverrideText = answer
self._currentNodeId = "dukun_answer"
if self._npcNameLabel then
self._npcNameLabel.Text = tostring(tree and tree.displayName or self._currentNpcId)
end
if self._dialogueText then
self._dialogueText.Text = answer
end
self:_setQuestionMode(false)
self:_renderChoices({
{ label = "A: Tanya lagi", next = "dukun_ask" },
{ label = "B: Topik cepat", next = "dukun_topics" },
{ label = "C: Tutup", next = "CLOSE" },
})
end

function NpcDialogueController:_closeDialogue(skipRemote)
if not self._isOpen then
return
end

self._isOpen = false
self._currentNpcId = nil
self._currentNodeId = nil
self._currentNpcHumanoid = nil
self._currentNpcRoot = nil
self:_clearChoices()
self._currentChoices = {}
self._dialogueOverrideText = nil
self._dialogueQuestionMode = false
if self._questionFrame then
self._questionFrame.Visible = false
end
if self._choicesFrame then
self._choicesFrame.Visible = true
end
if self._questionBox then
self._questionBox.Text = ""
end
self:_stopPlayerEmoteLoop()
self:_stopNpcGestureLoop()
self:_stopNpcFacingLoop()
self:_stopDialogueCamera()
self:_unbindDialogueLockStep()
self:_unlockDialogueInput()
self:_unfreezePlayer()
local player = self:_getPlayer()
if player then
player:SetAttribute("PasrahNpcDialogueActive", false)
end
self:_setUiVisible(false)

if self._remoteEvent and not skipRemote then
self._remoteEvent:FireServer("CLOSE", self._currentDialogueId)
end
self._currentDialogueId = nil
self._currentNpcModel = nil
end

function NpcDialogueController:_openDialogue(dialogueId, npcModel)
	-- Tunggu character fully loaded sebelum apapun
	local player = self:_getPlayer()
	if not player then return end

	if self._isOpen and self._currentDialogueId == dialogueId and self._currentNpcModel == npcModel then
		return
	end

	local character = player.Character
		or player.CharacterAdded:Wait()

-- Tunggu HumanoidRootPart max 5 detik
local hrp = character:FindFirstChild("HumanoidRootPart")
or character:WaitForChild("HumanoidRootPart", 5)
if not hrp then
warn("[NpcDialogue] HumanoidRootPart tidak ditemukan, abort dialogue")
return
end

local humanoid = character:FindFirstChildOfClass("Humanoid")
or character:WaitForChild("Humanoid", 5)
if not humanoid then
warn("[NpcDialogue] Humanoid tidak ditemukan, abort dialogue")
return
end

-- Validasi NPC model
if not npcModel or not npcModel.Parent then
warn("[NpcDialogue] npcModel tidak valid, abort dialogue")
return
end

local npcHumanoid = npcModel:FindFirstChildOfClass("Humanoid")
if not npcHumanoid then
warn("[NpcDialogue] NPC tidak punya Humanoid, abort dialogue")
return
end

local npcId = self._rootIndex[dialogueId]
if not npcId then
warn("[NpcDialogue] dialogueId tidak ditemukan di rootIndex:", dialogueId)
return
end

local resolvedNpc = npcModel
local npcRoot = getModelRoot(resolvedNpc)

if self._isOpen then
self:_closeDialogue()
end
if self._cameraRestoreTween then
pcall(function()
self._cameraRestoreTween:Cancel()
end)
self._cameraRestoreTween = nil
end

self._currentNpcId = npcId
self._currentDialogueId = dialogueId
self._currentNpcModel = npcModel
self._currentNpcRoot = npcRoot
self._currentNpcHumanoid = npcHumanoid
self._currentChoices = {}
self._dialogueOverrideText = nil
self._dialogueQuestionMode = false
self._isOpen = true
self:_setUiVisible(true)
local player = self:_getPlayer()
if player then
player:SetAttribute("PasrahNpcDialogueActive", true)
end
self:_bindDialogueLockStep()
self:_lockDialogueInput()
self:_freezePlayer()
self:_startDialogueCamera(resolvedNpc)
self:_startNpcFacingLoop()
self:_startNpcGestureLoop()
self:_startPlayerEmoteLoop()
self:_showNode(dialogueId)
end

function NpcDialogueController:_bindUiEvents()
if not self._ui then
return
end

if self._closeButton and not self._closeButton:GetAttribute("NpcDialogueBound") then
self._closeButton:SetAttribute("NpcDialogueBound", true)
table.insert(self._connections, self._closeButton.Activated:Connect(function()
self:_closeDialogue()
end))
end

if self._questionSendButton and not self._questionSendButton:GetAttribute("NpcDialogueBound") then
self._questionSendButton:SetAttribute("NpcDialogueBound", true)
table.insert(self._connections, self._questionSendButton.Activated:Connect(function()
self:_submitDialogueQuestion()
end))
end

if self._questionBox and not self._questionBox:GetAttribute("NpcDialogueBound") then
self._questionBox:SetAttribute("NpcDialogueBound", true)
table.insert(self._connections, self._questionBox.FocusLost:Connect(function(enterPressed)
if enterPressed then
self:_submitDialogueQuestion()
end
end))
end

for suffix, button in pairs(self._choiceButtons) do
if button and not button:GetAttribute("NpcDialogueBound") then
button:SetAttribute("NpcDialogueBound", true)
table.insert(self._connections, button.Activated:Connect(function()
if not self._isOpen or not self._currentNpcId then
return
end
local tree = getDialogueTree(self._currentNpcId)
local choices = self._currentChoices or {}
local index = string.byte(suffix) - string.byte("A") + 1
local choice = choices[index]
if not choice then
return
end

local nextNode = choice.next
if nextNode == "CLOSE" then
self:_closeDialogue()
elseif nextNode == "ROOT" then
if tree then
self:_showNode(tree.root)
end
else
self:_showNode(nextNode)
end
end))
end
end
end

function NpcDialogueController:Init(context)
self._context = context or {}
self._connections = self._connections or {}
self._choiceButtons = self._choiceButtons or {}
self._remoteEvent = resolveRemoteEvent(context)
self:_ensureUi()
self:_bindUiEvents()
if self._ui then
self._ui.Enabled = false
end
end

function NpcDialogueController:Start(context)
self._context = context or self._context or {}
local function bindRemote(remoteEvent)
if not remoteEvent or self._remoteConnection then
return
end
self._remoteConnection = remoteEvent.OnClientEvent:Connect(function(action, dialogueId, npcModel)
if action == "OPEN" then
self:_openDialogue(dialogueId, npcModel)
elseif action == "CLOSE" then
self:_closeDialogue(true)
end
end)
end

self._remoteEvent = self._remoteEvent or resolveRemoteEvent(self._context)
if self._remoteEvent then
bindRemote(self._remoteEvent)
elseif not self._remoteRetryTask then
self._remoteRetryTask = task.spawn(function()
local deadline = time() + 15
while not self._remoteEvent and time() < deadline do
self._remoteEvent = resolveRemoteEvent(self._context)
if self._remoteEvent then
bindRemote(self._remoteEvent)
break
end
task.wait(0.5)
end
self._remoteRetryTask = nil
end)
end

if self._characterConnection then
self._characterConnection:Disconnect()
end
local player = self:_getPlayer()
if player then
self._characterConnection = player.CharacterAdded:Connect(function()
if self._isOpen then
task.defer(function()
self:_freezePlayer()
end)
end
end)
end

self:_setUiVisible(false)

if UserInputService.InputBegan then
table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
if gameProcessed then
return
end
if UserInputService:GetFocusedTextBox() then
return
end
if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.X then
self:_closeDialogue()
end
end))
end
end

function NpcDialogueController:Stop()
if self._remoteConnection then
self._remoteConnection:Disconnect()
self._remoteConnection = nil
end
if self._characterConnection then
self._characterConnection:Disconnect()
self._characterConnection = nil
end
for _, connection in ipairs(self._connections) do
connection:Disconnect()
end
table.clear(self._connections)
self:_closeDialogue(true)
if self._cameraStepBound then
pcall(function()
RunService:UnbindFromRenderStep(DIALOGUE_CAMERA_BIND_NAME)
end)
self._cameraStepBound = false
end
self:_unbindDialogueLockStep()
self:_unlockDialogueInput()
self:_unfreezePlayer()
local player = self:_getPlayer()
if player then
player:SetAttribute("PasrahNpcDialogueActive", false)
end
if self._ui then
self._ui:Destroy()
self._ui = nil
end
self._mainFrame = nil
self._npcNameLabel = nil
self._dialogueText = nil
self._questionFrame = nil
self._questionBox = nil
self._questionSendButton = nil
self._questionHint = nil
self._choicesFrame = nil
self._closeButton = nil
end

local controller = NpcDialogueController.new()
controller.new = NpcDialogueController.new
return controller



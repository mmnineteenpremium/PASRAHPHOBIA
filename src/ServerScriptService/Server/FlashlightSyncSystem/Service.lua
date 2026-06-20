local Services = require(script.Parent.Parent.Core.Services)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Service = {}
Service.__index = Service

local REMOTE_SPOTLIGHT_NAME = "FlashlightRemoteSpotLight"
local REMOTE_BOOST_NAME = "FlashlightRemoteBoost"
local REMOTE_FILL_NAME = "FlashlightRemoteFill"
local REMOTE_BEAM_NAME = "FlashlightRemoteBeam"
local REMOTE_BEAM_START = "FlashlightRemoteBeamStart"
local REMOTE_BEAM_END = "FlashlightRemoteBeamEnd"
local REMOTE_AIM_ATTACHMENT = "FlashlightRemoteAim"
local REMOTE_HANDLE_NAME = "FlashlightHandle"
local TOGGLE_SOUND_NAME = "FlashlightToggleClick"
local REMOTE_SPOTLIGHT_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldEffects", "WorldSpotLightTemplate" }
local REMOTE_POINT_LIGHT_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldEffects", "WorldPointLightTemplate" }
local REMOTE_BEAM_TEMPLATE_PATH = { "Assets", "VisualTemplates", "WorldEffects", "WorldBeamTemplate" }

local DEFAULT_AIM_UPDATE_MIN_INTERVAL = 1 / 30
local DEFAULT_AIM_SMOOTH_SPEED = 3 -- lower = more delay/lag
local DEFAULT_AIM_MAX_ALPHA = 0.2

local function safeRequire(moduleScript)
    if not moduleScript then
        return nil
    end
    local ok, result = pcall(require, moduleScript)
    if ok then
        return result
    end
    return nil
end

local function resolveFlashlightConfig()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local shared = replicatedStorage:FindFirstChild("Shared") or replicatedStorage:FindFirstChild("shared")
    local gameData = shared and shared:FindFirstChild("GameData")
    return safeRequire(gameData and gameData:FindFirstChild("FlashlightConfig")) or {}
end

local FLASHLIGHT_CONFIG = resolveFlashlightConfig()
local HANDLE_CONFIG = FLASHLIGHT_CONFIG.handle or {}
local SOUND_CONFIG = FLASHLIGHT_CONFIG.sound or {}
local REMOTE_LIGHT_CONFIG = FLASHLIGHT_CONFIG.remoteLight or {}
local AIM_UPDATE_MIN_INTERVAL = math.clamp(
    tonumber(REMOTE_LIGHT_CONFIG.aimUpdateMinInterval) or DEFAULT_AIM_UPDATE_MIN_INTERVAL,
    1 / 120,
    1 / 10
)
local AIM_SMOOTH_SPEED = math.max(0.1, tonumber(REMOTE_LIGHT_CONFIG.aimSmoothSpeed) or DEFAULT_AIM_SMOOTH_SPEED)
local AIM_MAX_ALPHA = math.clamp(tonumber(REMOTE_LIGHT_CONFIG.aimMaxAlpha) or DEFAULT_AIM_MAX_ALPHA, 0.05, 1)
local FLASHLIGHT_RANGE = tonumber(REMOTE_LIGHT_CONFIG.range) or 50
local FLASHLIGHT_ANGLE = tonumber(REMOTE_LIGHT_CONFIG.angle) or 30
local FLASHLIGHT_BRIGHTNESS = tonumber(REMOTE_LIGHT_CONFIG.brightness) or 8
local BOOST_RANGE = tonumber(REMOTE_LIGHT_CONFIG.boostRange) or 25
local BOOST_ANGLE = tonumber(REMOTE_LIGHT_CONFIG.boostAngle) or 55
local BOOST_BRIGHTNESS = tonumber(REMOTE_LIGHT_CONFIG.boostBrightness) or 8
local FILL_RANGE = tonumber(REMOTE_LIGHT_CONFIG.fillRange) or 13
local FILL_BRIGHTNESS = tonumber(REMOTE_LIGHT_CONFIG.fillBrightness) or 3
local FLASHLIGHT_BATTERY_ATTR = "PasrahFlashlightBattery"
local FLASHLIGHT_NEEDS_RELOAD_ATTR = "PasrahFlashlightNeedsReload"
local FLASHLIGHT_BATTERY_SECONDS = math.max(30, tonumber(FLASHLIGHT_CONFIG.batterySeconds) or 150)
local FLASHLIGHT_DRAIN_PER_SECOND = 100 / FLASHLIGHT_BATTERY_SECONDS

local function toUserId(player)
    if typeof(player) == "Instance" and player:IsA("Player") then
        return player.UserId
    end
    if type(player) == "number" then
        return player
    end
    return nil
end

local function stampRemoteFlashlightInstance(instance, channel, data, player)
    if not instance then
        return
    end
    local userId = toUserId(player)
    instance:SetAttribute("PasrahFlashlightOwner", "FlashlightSyncSystem")
    instance:SetAttribute("PasrahFlashlightChannel", tostring(channel or instance.Name))
    instance:SetAttribute("PasrahFlashlightEnabled", data and data.flashlightOn == true or false)
    instance:SetAttribute("PasrahFlashlightUserId", userId)
end

local function stampRemoteFlashlightRuntime(data, player)
    if not data then
        return
    end
    stampRemoteFlashlightInstance(data.flashlightHandle, "RemoteHandle", data, player)
    stampRemoteFlashlightInstance(data.aimAttachment, "RemoteAimAttachment", data, player)
    stampRemoteFlashlightInstance(data.beamStart, "RemoteBeamStart", data, player)
    stampRemoteFlashlightInstance(data.beamEnd, "RemoteBeamEnd", data, player)
    stampRemoteFlashlightInstance(data.spotlight, "RemoteSpotLight", data, player)
    stampRemoteFlashlightInstance(data.boost, "RemoteBoostLight", data, player)
    stampRemoteFlashlightInstance(data.fill, "RemoteFillLight", data, player)
    stampRemoteFlashlightInstance(data.beam, "RemoteBeam", data, player)
    stampRemoteFlashlightInstance(data.toggleSound, "RemoteToggleSound", data, player)
    if data.toggleSound then
        data.toggleSound:SetAttribute("PasrahFlashlightSoundId", tostring(data.toggleSound.SoundId or ""))
    end
    if typeof(player) == "Instance" and player:IsA("Player") then
        player:SetAttribute("PasrahFlashlightRemoteAttached", data.flashlightHandle ~= nil and data.flashlightHandle.Parent ~= nil)
        player:SetAttribute("PasrahFlashlightRemoteEnabled", data.flashlightOn == true)
        player:SetAttribute("PasrahFlashlightRemoteSoundId", data.toggleSound and tostring(data.toggleSound.SoundId or "") or nil)
        player:SetAttribute("PasrahFlashlightRemoteHandlePath", data.flashlightHandle and data.flashlightHandle:GetFullName() or nil)
        player:SetAttribute(FLASHLIGHT_BATTERY_ATTR, math.clamp(tonumber(data.battery) or 100, 0, 100))
        player:SetAttribute(FLASHLIGHT_NEEDS_RELOAD_ATTR, (tonumber(data.battery) or 100) <= 0)
    end
end

local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
    if type(eventBus) ~= "table" then
        return nil
    end
    if type(eventBus.Publish) == "function" then
        return eventBus
    end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then
        return eventBus.Service
    end
    return nil
end

local function getHead(character)
    if not character then
        return nil
    end
    local head = character:FindFirstChild("Head")
    if head then
        return head
    end
    head = character:WaitForChild("Head", 5)
    return head
end

local function getRightHand(character)
    if not character then
        return nil
    end

    for _, partName in ipairs({ "RightHand", "Right Arm", "RightLowerArm" }) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            return part
        end
    end

    return nil
end

local function getFlashlightMountCFrame(part)
    if not part then
        return HANDLE_CONFIG.fallbackMountCFrame or CFrame.new(0.1, -0.28, -0.08)
    end

    local gripCFrame = HANDLE_CONFIG.gripCFrame or CFrame.new(0.1, -0.4, 0)
    for _, attachmentName in ipairs({ "RightGripAttachment", "GripAttachment", "ToolGrip" }) do
        local attachment = part:FindFirstChild(attachmentName)
        if attachment and attachment:IsA("Attachment") then
            return attachment.CFrame * gripCFrame
        end
    end

    if part.Name == "RightHand" and HANDLE_CONFIG.rightHandMountCFrame then
        return HANDLE_CONFIG.rightHandMountCFrame
    end
    if part.Name == "RightLowerArm" and HANDLE_CONFIG.rightLowerArmMountCFrame then
        return HANDLE_CONFIG.rightLowerArmMountCFrame
    end
    if part.Name == "Right Arm" and HANDLE_CONFIG.rightArmMountCFrame then
        return HANDLE_CONFIG.rightArmMountCFrame
    end

    return HANDLE_CONFIG.fallbackMountCFrame or CFrame.new(0.1, -0.28, -0.08)
end

local function resolveChildPath(root, path)
    local node = root
    for _, segment in ipairs(path) do
        if typeof(node) ~= "Instance" then
            return nil
        end
        node = node:FindFirstChild(segment)
    end
    return node
end

local function cloneVisualTemplate(path, name, className)
    local template = resolveChildPath(ReplicatedStorage, path)
    if template and template:IsA(className) then
        local clone = template:Clone()
        clone.Name = name
        return clone
    end
    return nil
end

local function findOrCreateAttachment(parent, name)
    local existing = parent:FindFirstChild(name)
    if existing and existing:IsA("Attachment") then
        return existing
    end
    if existing then
        existing:Destroy()
    end
    local attachment = Instance.new("Attachment")
    attachment.Name = name
    attachment.Parent = parent
    return attachment
end

local function findOrCreateHandleMesh(parent)
    local existing = parent:FindFirstChild("Mesh")
    if existing and existing:IsA("SpecialMesh") then
        existing.MeshType = Enum.MeshType.FileMesh
        existing.MeshId = tostring(HANDLE_CONFIG.meshId or "")
        existing.TextureId = tostring(HANDLE_CONFIG.textureId or "")
        existing.Scale = HANDLE_CONFIG.meshScale or Vector3.new(0.7, 0.7, 0.7)
        return existing
    end
    if existing then
        existing:Destroy()
    end

    local mesh = Instance.new("SpecialMesh")
    mesh.Name = "Mesh"
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = tostring(HANDLE_CONFIG.meshId or "")
    mesh.TextureId = tostring(HANDLE_CONFIG.textureId or "")
    mesh.Scale = HANDLE_CONFIG.meshScale or Vector3.new(0.7, 0.7, 0.7)
    mesh.Parent = parent
    return mesh
end

local function findOrCreateToggleSound(parent)
    if not parent then
        return nil
    end

    local existing = parent:FindFirstChild(TOGGLE_SOUND_NAME)
    if existing and existing:IsA("Sound") then
        existing.SoundId = tostring(SOUND_CONFIG.soundId or "")
        existing.Volume = tonumber(SOUND_CONFIG.volume) or 0.32
        existing.PlaybackSpeed = tonumber(SOUND_CONFIG.playbackSpeed) or 1
        existing.RollOffMode = Enum.RollOffMode.Linear
        existing.RollOffMinDistance = tonumber(SOUND_CONFIG.rollOffMinDistance) or 4
        existing.RollOffMaxDistance = tonumber(SOUND_CONFIG.rollOffMaxDistance) or 30
        existing.Looped = false
        return existing
    end
    if existing then
        existing:Destroy()
    end

    local sound = Instance.new("Sound")
    sound.Name = TOGGLE_SOUND_NAME
    sound.SoundId = tostring(SOUND_CONFIG.soundId or "")
    sound.Volume = tonumber(SOUND_CONFIG.volume) or 0.32
    sound.PlaybackSpeed = tonumber(SOUND_CONFIG.playbackSpeed) or 1
    sound.RollOffMode = Enum.RollOffMode.Linear
    sound.RollOffMinDistance = tonumber(SOUND_CONFIG.rollOffMinDistance) or 4
    sound.RollOffMaxDistance = tonumber(SOUND_CONFIG.rollOffMaxDistance) or 30
    sound.Looped = false
    sound.Parent = parent
    return sound
end

local function findOrCreateHandle(character)
    if not character then
        return nil
    end

    local existing = character:FindFirstChild(REMOTE_HANDLE_NAME)
    if existing and existing:IsA("BasePart") then
        existing.Size = HANDLE_CONFIG.size or Vector3.new(0.5, 0.5, 2)
        existing.Material = HANDLE_CONFIG.material or Enum.Material.SmoothPlastic
        existing.Color = HANDLE_CONFIG.color or Color3.fromRGB(44, 46, 50)
        existing.CanCollide = false
        existing.CanTouch = false
        existing.CanQuery = false
        existing.CastShadow = false
        existing.Massless = true
        existing.Anchored = false
        findOrCreateHandleMesh(existing)
        findOrCreateToggleSound(existing)
        return existing
    end
    if existing then
        existing:Destroy()
    end

    local handle = Instance.new("Part")
    handle.Name = REMOTE_HANDLE_NAME
    handle.Size = HANDLE_CONFIG.size or Vector3.new(0.5, 0.5, 2)
    handle.CanCollide = false
    handle.CanTouch = false
    handle.CanQuery = false
    handle.CastShadow = false
    handle.Massless = true
    handle.Anchored = false
    handle.Material = HANDLE_CONFIG.material or Enum.Material.SmoothPlastic
    handle.Color = HANDLE_CONFIG.color or Color3.fromRGB(44, 46, 50)
    handle.Parent = character
    findOrCreateHandleMesh(handle)
    findOrCreateToggleSound(handle)
    return handle
end

local function findOrCreateSpotLight(parent)
    local existing = parent:FindFirstChild(REMOTE_SPOTLIGHT_NAME)
    if existing and existing:IsA("SpotLight") then
        existing.Shadows = true
        return existing
    end
    if existing then
        existing:Destroy()
    end
    local spotlight = cloneVisualTemplate(REMOTE_SPOTLIGHT_TEMPLATE_PATH, REMOTE_SPOTLIGHT_NAME, "SpotLight")
    if not spotlight then
        warn("[FlashlightSyncSystem] Missing authored visual template: WorldEffects.WorldSpotLightTemplate")
        return nil
    end
    spotlight.Name = REMOTE_SPOTLIGHT_NAME
    spotlight.Face = Enum.NormalId.Front
    spotlight.Brightness = FLASHLIGHT_BRIGHTNESS
    spotlight.Range = FLASHLIGHT_RANGE
    spotlight.Angle = FLASHLIGHT_ANGLE
    spotlight.Color = REMOTE_LIGHT_CONFIG.color or Color3.fromRGB(255, 250, 230)
    spotlight.Shadows = true
    spotlight.Enabled = false
    spotlight.Parent = parent
    return spotlight
end

local function findOrCreateBoostLight(parent)
    local existing = parent:FindFirstChild(REMOTE_BOOST_NAME)
    if existing and existing:IsA("SpotLight") then
        existing.Brightness = BOOST_BRIGHTNESS
        existing.Range = BOOST_RANGE
        existing.Angle = BOOST_ANGLE
        existing.Color = Color3.fromRGB(255, 250, 230)
        existing.Shadows = false
        return existing
    end
    if existing then
        existing:Destroy()
    end
    local spotlight = cloneVisualTemplate(REMOTE_SPOTLIGHT_TEMPLATE_PATH, REMOTE_BOOST_NAME, "SpotLight")
    if not spotlight then
        warn("[FlashlightSyncSystem] Missing authored visual template: WorldEffects.WorldSpotLightTemplate")
        return nil
    end
    spotlight.Name = REMOTE_BOOST_NAME
    spotlight.Face = Enum.NormalId.Front
    spotlight.Brightness = BOOST_BRIGHTNESS
    spotlight.Range = BOOST_RANGE
    spotlight.Angle = BOOST_ANGLE
    spotlight.Color = REMOTE_LIGHT_CONFIG.color or Color3.fromRGB(255, 250, 230)
    spotlight.Shadows = false
    spotlight.Enabled = false
    spotlight.Parent = parent
    return spotlight
end

local function findOrCreateFillLight(parent)
    local existing = parent:FindFirstChild(REMOTE_FILL_NAME)
    if existing and existing:IsA("PointLight") then
        existing.Brightness = FILL_BRIGHTNESS
        existing.Range = FILL_RANGE
        existing.Color = Color3.fromRGB(255, 250, 230)
        existing.Shadows = false
        return existing
    end
    if existing then
        existing:Destroy()
    end
    local light = cloneVisualTemplate(REMOTE_POINT_LIGHT_TEMPLATE_PATH, REMOTE_FILL_NAME, "PointLight")
    if not light then
        warn("[FlashlightSyncSystem] Missing authored visual template: WorldEffects.WorldPointLightTemplate")
        return nil
    end
    light.Name = REMOTE_FILL_NAME
    light.Brightness = FILL_BRIGHTNESS
    light.Range = FILL_RANGE
    light.Color = REMOTE_LIGHT_CONFIG.color or Color3.fromRGB(255, 250, 230)
    light.Shadows = false
    light.Enabled = false
    light.Parent = parent
    return light
end

local function findOrCreateBeam(parent, attachment0, attachment1)
    local existing = parent:FindFirstChild(REMOTE_BEAM_NAME)
    if existing and existing:IsA("Beam") then
        existing.Attachment0 = attachment0
        existing.Attachment1 = attachment1
        return existing
    end
    if existing then
        existing:Destroy()
    end
    local beam = cloneVisualTemplate(REMOTE_BEAM_TEMPLATE_PATH, REMOTE_BEAM_NAME, "Beam")
    if not beam then
        warn("[FlashlightSyncSystem] Missing authored visual template: WorldEffects.WorldBeamTemplate")
        return nil
    end
    beam.Name = REMOTE_BEAM_NAME
    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Transparency = NumberSequence.new(0.5)
    beam.Width0 = 0.35
    beam.Width1 = 1.8
    beam.Color = ColorSequence.new(REMOTE_LIGHT_CONFIG.color or Color3.fromRGB(255, 250, 230))
    beam.FaceCamera = true
    beam.Enabled = false
    beam.Parent = parent
    return beam
end

local function ensureAttachments(head)
    local aimAttachment = findOrCreateAttachment(head, REMOTE_AIM_ATTACHMENT)
    local beamStart = findOrCreateAttachment(head, REMOTE_BEAM_START)
    local beamEnd = findOrCreateAttachment(head, REMOTE_BEAM_END)
    return aimAttachment, beamStart, beamEnd
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._heartbeatConn = nil
    return self
end

function Service:Init()
    self._state:Set("players", {})
end

function Service:Start()
    if self._heartbeatConn then
        self._heartbeatConn:Disconnect()
    end
    self._heartbeatConn = RunService.Heartbeat:Connect(function(deltaTime)
        self:_updateBattery(deltaTime)
    end)
end

function Service:Stop()
    if self._heartbeatConn then
        self._heartbeatConn:Disconnect()
        self._heartbeatConn = nil
    end
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_storePlayer(userId, data)
    local players = self._state:Get("players") or {}
    players[userId] = data
    self._state:Set("players", players)
end

function Service:_removePlayer(userId)
    local players = self._state:Get("players") or {}
    players[userId] = nil
    self._state:Set("players", players)
end

function Service:_getPlayerState(userId)
    local players = self._state:Get("players") or {}
    return players[userId]
end

function Service:_setBattery(data, player, battery)
    if not data then
        return
    end
    data.battery = math.clamp(tonumber(battery) or 0, 0, 100)
    if typeof(player) == "Instance" and player:IsA("Player") then
        player:SetAttribute(FLASHLIGHT_BATTERY_ATTR, data.battery)
        player:SetAttribute(FLASHLIGHT_NEEDS_RELOAD_ATTR, data.battery <= 0)
    end
end

local function isInLobbyPhase(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return true
    end
    local phase = tostring(player:GetAttribute("MatchLifecyclePhase") or player:GetAttribute("PasrahMatchPhase") or "")
    return phase == "Lobby" or phase == "" or phase == nil
end

function Service:_isPreparationReloadAllowed(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return false
    end
    local phase = tostring(player:GetAttribute("MatchLifecyclePhase") or player:GetAttribute("PasrahMatchPhase") or "")
    return phase == "PreparationPhase"
        or phase == "Preparing"
        or phase == "Briefing"
        or player:GetAttribute("InMatch") ~= true
end

function Service:_reloadBattery(player, data)
    if not data then
        return false
    end
    self:_setBattery(data, player, 100)
    if data.flashlightOn ~= true then
        self:_setEnabled(data, false)
    end
    self:_publish("FlashlightBatteryReloaded", {
        player = player,
        userId = toUserId(player),
        battery = data.battery,
    })
    return true
end

function Service:_updateBattery(deltaTime)
    local players = self._state:Get("players") or {}
    local delta = math.max(0, tonumber(deltaTime) or 0)
    for userId, data in pairs(players) do
        if type(data) == "table" and data.flashlightOn == true then
            local player = data.player
            local current = tonumber(data.battery)
                or (typeof(player) == "Instance" and player:IsA("Player") and tonumber(player:GetAttribute(FLASHLIGHT_BATTERY_ATTR)))
                or 100
            local nextBattery = math.max(0, current - (FLASHLIGHT_DRAIN_PER_SECOND * delta))
            self:_setBattery(data, player, nextBattery)
            if nextBattery <= 0 then
                data.flashlightOn = false
                self:_setEnabled(data, false)
                if typeof(player) == "Instance" and player:IsA("Player") then
                    player:SetAttribute("PasrahFlashlightEnabled", false)
                    player:SetAttribute("PasrahFlashlightRemoteEnabled", false)
                    player:SetAttribute("PasrahFlashlightBatteryDepletedAt", os.clock())
                end
                self:_publish("FlashlightBatteryDepleted", {
                    player = player,
                    userId = userId,
                    battery = 0,
                })
            end
            players[userId] = data
        end
    end
    self._state:Set("players", players)
end

function Service:_ensureFlashlightAttached(player, userId)
    local data = userId and self:_getPlayerState(userId) or nil
    local character = typeof(player) == "Instance" and player:IsA("Player") and player.Character or nil
    if not character then
        return data
    end

    local handle = data and data.flashlightHandle
    local aimAttachment = data and data.aimAttachment
    local liveHandle = character:FindFirstChild(REMOTE_HANDLE_NAME)
    if typeof(player) == "Instance" and player:IsA("Player") then
        player:SetAttribute("PasrahFlashlightRemoteLiveHandle", liveHandle ~= nil)
        player:SetAttribute("PasrahFlashlightRemoteCacheHandle", handle ~= nil)
        player:SetAttribute("PasrahFlashlightRemoteHandleMatchesCache", liveHandle ~= nil and handle == liveHandle or false)
    end
    local needsAttach = data == nil
        or data.character ~= character
        or not (handle and handle.Parent == character)
        or handle ~= liveHandle
        or not (aimAttachment and aimAttachment.Parent)

    if needsAttach then
        self:AttachFlashlight(player, character)
        if typeof(player) == "Instance" and player:IsA("Player") then
            player:SetAttribute("PasrahFlashlightRemoteRecovered", true)
            player:SetAttribute("PasrahFlashlightRemoteAttachNeeded", true)
        end
        return userId and self:_getPlayerState(userId) or data
    end

    if typeof(player) == "Instance" and player:IsA("Player") then
        player:SetAttribute("PasrahFlashlightRemoteAttachNeeded", false)
    end

    return data
end

function Service:OnPlayerAdded(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return
    end
    local userId = toUserId(player)
    if not userId then
        return
    end

    local data = self:_getPlayerState(userId) or {}
    data.player = player
    data.battery = math.clamp(tonumber(player:GetAttribute(FLASHLIGHT_BATTERY_ATTR)) or tonumber(data.battery) or 100, 0, 100)
    player:SetAttribute(FLASHLIGHT_BATTERY_ATTR, data.battery)
    player:SetAttribute(FLASHLIGHT_NEEDS_RELOAD_ATTR, data.battery <= 0)

    if data.characterConn then
        data.characterConn:Disconnect()
        data.characterConn = nil
    end

    data.characterConn = player.CharacterAdded:Connect(function(character)
        if not isInLobbyPhase(player) then
            self:AttachFlashlight(player, character)
        end
    end)

    if player.Character and not isInLobbyPhase(player) then
        self:AttachFlashlight(player, player.Character)
    end

    self:_storePlayer(userId, data)
end

function Service:OnPlayerRemoving(player)
    local userId = toUserId(player)
    if not userId then
        return
    end
    local data = self:_getPlayerState(userId)
    if data and data.characterConn then
        data.characterConn:Disconnect()
    end
    self:_removePlayer(userId)
end

function Service:AttachFlashlight(player, character)
    local userId = toUserId(player)
    if not userId then
        return
    end

    if isInLobbyPhase(player) then
        return
    end

    local head = getHead(character)
    local mountPart = getRightHand(character) or head
    if not mountPart then
        return
    end
    local flashlightHandle = findOrCreateHandle(character)
    if not flashlightHandle then
        return
    end

    local aimAttachment, beamStart, beamEnd = ensureAttachments(flashlightHandle)
    local spotlight = findOrCreateSpotLight(aimAttachment)
    local boost = findOrCreateBoostLight(aimAttachment)
    local fill = findOrCreateFillLight(aimAttachment)
    local beam = findOrCreateBeam(flashlightHandle, beamStart, beamEnd)
    local toggleSound = findOrCreateToggleSound(flashlightHandle)
    local mountCFrame = getFlashlightMountCFrame(mountPart)
    local worldMount = mountPart.CFrame * mountCFrame
    flashlightHandle.CFrame = CFrame.lookAt(worldMount.Position, worldMount.Position + mountPart.CFrame.LookVector, mountPart.CFrame.UpVector)

    local data = self:_getPlayerState(userId) or {}
    data.player = player
    data.character = character
    data.head = head
    data.mountPart = mountPart
    data.mountCFrame = mountCFrame
    data.flashlightHandle = flashlightHandle
    data.aimAttachment = aimAttachment
    data.beamStart = beamStart
    data.beamEnd = beamEnd
    data.spotlight = spotlight
    data.boost = boost
    data.fill = fill
    data.beam = beam
    data.toggleSound = toggleSound
    data.lastUpdate = data.lastUpdate or 0
    data.lastAimAt = data.lastAimAt or 0
    data.currentLook = data.currentLook or nil
    data.battery = math.clamp(tonumber(player:GetAttribute(FLASHLIGHT_BATTERY_ATTR)) or tonumber(data.battery) or 100, 0, 100)
    aimAttachment.CFrame = CFrame.new()
    beamStart.CFrame = CFrame.new()
    beamEnd.CFrame = CFrame.new(0, 0, -FLASHLIGHT_RANGE)
    stampRemoteFlashlightRuntime(data, player)
    player:SetAttribute("PasrahFlashlightRemoteAttached", true)
    player:SetAttribute("PasrahFlashlightRemoteHandlePath", flashlightHandle:GetFullName())
    player:SetAttribute("PasrahFlashlightRemoteSoundId", toggleSound and tostring(toggleSound.SoundId or "") or nil)
    player:SetAttribute("PasrahFlashlightRemoteMountPart", mountPart.Name)
    player:SetAttribute("PasrahFlashlightRemoteMountHand", string.find(mountPart.Name, "Right", 1, true) and "Right" or "Fallback")

    self:_storePlayer(userId, data)
end

function Service:_applyLookVector(lookVector, data)
    if not data then
        return
    end

    local mountPart = data.mountPart or data.head
    local flashlightHandle = data.flashlightHandle
    local aimAttachment = data.aimAttachment
    local beamStart = data.beamStart
    local beamEnd = data.beamEnd
    local mountCFrame = data.mountCFrame or CFrame.new()

    if not (mountPart and flashlightHandle and aimAttachment and beamStart and beamEnd) then
        return
    end

    local unit = lookVector.Unit
    if unit.Magnitude <= 0 then
        return
    end

    local worldPosition = (mountPart.CFrame * mountCFrame).Position
    flashlightHandle.CFrame = CFrame.lookAt(worldPosition, worldPosition + unit, mountPart.CFrame.UpVector)
    aimAttachment.CFrame = CFrame.new()
    beamStart.CFrame = CFrame.new()
    beamEnd.CFrame = CFrame.new(0, 0, -FLASHLIGHT_RANGE)
end

function Service:_setEnabled(data, enabled)
    if not data then
        return
    end
    if data.spotlight then
        data.spotlight.Enabled = enabled
    end
    if data.boost then
        data.boost.Enabled = enabled
    end
    if data.fill then
        data.fill.Enabled = enabled
    end
    if data.beam then
        data.beam.Enabled = enabled
    end
    stampRemoteFlashlightRuntime(data, data.player)
end

function Service:_playToggleSound(data)
    if not data then
        return
    end

    local sound = data.toggleSound
    if not (sound and sound.Parent and tostring(sound.SoundId or "") ~= "") then
        return
    end

    sound.TimePosition = 0
    sound:Play()
    stampRemoteFlashlightRuntime(data, data.player)
end

function Service:HandleRemote(player, payload)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return
    end
    if type(payload) ~= "table" then
        return
    end

    local userId = toUserId(player)
    if not userId then
        return
    end

    local data = self:_ensureFlashlightAttached(player, userId)
    if not data then
        return
    end

    local action = payload.action
    player:SetAttribute("PasrahFlashlightRemoteLastAction", tostring(action or ""))
    if action == "Reload" or action == "ReloadAtPreparation" then
        if self:_isPreparationReloadAllowed(player) then
            self:_reloadBattery(player, data)
            self:_storePlayer(userId, data)
        else
            player:SetAttribute("PasrahFlashlightReloadRejected", true)
        end
        return
    end

    if action == "Toggle" then
        if isInLobbyPhase(player) then
            player:SetAttribute("PasrahFlashlightToggleRejected", "in_lobby")
            return
        end
        local enabled = payload.enabled == true
        data.battery = math.clamp(tonumber(data.battery) or tonumber(player:GetAttribute(FLASHLIGHT_BATTERY_ATTR)) or 100, 0, 100)
        if enabled and data.battery <= 0 then
            data.flashlightOn = false
            self:_setEnabled(data, false)
            player:SetAttribute("PasrahFlashlightEnabled", false)
            player:SetAttribute("PasrahFlashlightRemoteEnabled", false)
            player:SetAttribute(FLASHLIGHT_NEEDS_RELOAD_ATTR, true)
            player:SetAttribute("PasrahFlashlightToggleRejected", "battery_empty")
            self:_storePlayer(userId, data)
            self:_publish("FlashlightToggleRejected", {
                player = player,
                userId = userId,
                reason = "battery_empty",
            })
            return
        end
        local wasEnabled = data.flashlightOn == true
        data.flashlightOn = enabled
        self:_setEnabled(data, enabled)
        if wasEnabled ~= enabled then
            self:_playToggleSound(data)
        end
        stampRemoteFlashlightRuntime(data, player)
        player:SetAttribute("PasrahFlashlightRemoteEnabled", enabled)
        player:SetAttribute("PasrahFlashlightRemoteAttached", data.flashlightHandle ~= nil and data.flashlightHandle.Parent ~= nil)
        player:SetAttribute("PasrahFlashlightRemoteHandlePath", data.flashlightHandle and data.flashlightHandle:GetFullName() or nil)
        player:SetAttribute("PasrahFlashlightRemoteSoundId", data.toggleSound and tostring(data.toggleSound.SoundId or "") or nil)
        self:_storePlayer(userId, data)
        self:_publish("FlashlightToggled", {
            player = player,
            userId = userId,
            enabled = enabled,
        })
        return
    end

    if action == "Aim" then
        local lookVector = payload.lookVector
        if typeof(lookVector) ~= "Vector3" then
            return
        end

        local now = os.clock()
        if data.lastUpdate and (now - data.lastUpdate) < AIM_UPDATE_MIN_INTERVAL then
            return
        end

        data.lastUpdate = now
        local target = lookVector.Unit
        local dt = now - (data.lastAimAt or now)
        data.lastAimAt = now

        if data.currentLook then
            local alpha = 1 - math.exp(-AIM_SMOOTH_SPEED * math.max(dt, 0))
            alpha = math.clamp(alpha, 0, AIM_MAX_ALPHA)
            data.currentLook = data.currentLook:Lerp(target, alpha).Unit
        else
            data.currentLook = target
        end

        self:_applyLookVector(data.currentLook, data)
        stampRemoteFlashlightRuntime(data, player)
        self:_storePlayer(userId, data)
        return
    end
end

return Service

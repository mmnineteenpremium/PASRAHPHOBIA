local Services = require(script.Parent.Parent.Core.Services)

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

local FLASHLIGHT_RANGE = 50
local FLASHLIGHT_ANGLE = 30
local FLASHLIGHT_BRIGHTNESS = 8
local BOOST_RANGE = 25
local BOOST_ANGLE = 55
local BOOST_BRIGHTNESS = 8
local FILL_RANGE = 13
local FILL_BRIGHTNESS = 3
local AIM_UPDATE_MIN_INTERVAL = 1 / 30
local AIM_SMOOTH_SPEED = 3 -- lower = more delay/lag
local AIM_MAX_ALPHA = 0.2

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

local function toUserId(player)
    if typeof(player) == "Instance" and player:IsA("Player") then
        return player.UserId
    end
    if type(player) == "number" then
        return player
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

local function getFlashlightMountPosition(part)
    if not part then
        return Vector3.new(0, -0.1, -0.35)
    end

    for _, attachmentName in ipairs({ "RightGripAttachment", "GripAttachment", "ToolGrip" }) do
        local attachment = part:FindFirstChild(attachmentName)
        if attachment and attachment:IsA("Attachment") then
            return attachment.Position
        end
    end

    return Vector3.new(0, -0.15, -(part.Size.Z * 0.5 + 0.2))
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

local function findOrCreateHandle(character)
    if not character then
        return nil
    end

    local existing = character:FindFirstChild(REMOTE_HANDLE_NAME)
    if existing and existing:IsA("BasePart") then
        return existing
    end
    if existing then
        existing:Destroy()
    end

    local handle = Instance.new("Part")
    handle.Name = REMOTE_HANDLE_NAME
    handle.Size = Vector3.new(0.24, 0.24, 0.8)
    handle.CanCollide = false
    handle.CanTouch = false
    handle.CanQuery = false
    handle.CastShadow = false
    handle.Massless = true
    handle.Anchored = true
    handle.Material = Enum.Material.Metal
    handle.Color = Color3.fromRGB(48, 56, 68)
    handle.Parent = character
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
    local spotlight = Instance.new("SpotLight")
    spotlight.Name = REMOTE_SPOTLIGHT_NAME
    spotlight.Face = Enum.NormalId.Front
    spotlight.Brightness = FLASHLIGHT_BRIGHTNESS
    spotlight.Range = FLASHLIGHT_RANGE
    spotlight.Angle = FLASHLIGHT_ANGLE
    spotlight.Color = Color3.fromRGB(255, 250, 230)
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
    local spotlight = Instance.new("SpotLight")
    spotlight.Name = REMOTE_BOOST_NAME
    spotlight.Face = Enum.NormalId.Front
    spotlight.Brightness = BOOST_BRIGHTNESS
    spotlight.Range = BOOST_RANGE
    spotlight.Angle = BOOST_ANGLE
    spotlight.Color = Color3.fromRGB(255, 250, 230)
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
    local light = Instance.new("PointLight")
    light.Name = REMOTE_FILL_NAME
    light.Brightness = FILL_BRIGHTNESS
    light.Range = FILL_RANGE
    light.Color = Color3.fromRGB(255, 250, 230)
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
    local beam = Instance.new("Beam")
    beam.Name = REMOTE_BEAM_NAME
    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.LightEmission = 1
    beam.LightInfluence = 0
    beam.Transparency = NumberSequence.new(0.5)
    beam.Width0 = 0.35
    beam.Width1 = 1.8
    beam.Color = ColorSequence.new(Color3.fromRGB(255, 250, 230))
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
    return self
end

function Service:Init()
    self._state:Set("players", {})
end

function Service:Start()
    -- Event-driven system.
end

function Service:Stop()
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

    if data.characterConn then
        data.characterConn:Disconnect()
        data.characterConn = nil
    end

    data.characterConn = player.CharacterAdded:Connect(function(character)
        self:AttachFlashlight(player, character)
    end)

    if player.Character then
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
    local mountPosition = getFlashlightMountPosition(mountPart)
    local worldPosition = mountPart.CFrame:PointToWorldSpace(mountPosition)
    flashlightHandle.CFrame = CFrame.lookAt(worldPosition, worldPosition + mountPart.CFrame.LookVector)

    local data = self:_getPlayerState(userId) or {}
    data.player = player
    data.character = character
    data.head = head
    data.mountPart = mountPart
    data.mountPosition = mountPosition
    data.flashlightHandle = flashlightHandle
    data.aimAttachment = aimAttachment
    data.beamStart = beamStart
    data.beamEnd = beamEnd
    data.spotlight = spotlight
    data.boost = boost
    data.fill = fill
    data.beam = beam
    data.lastUpdate = data.lastUpdate or 0
    data.lastAimAt = data.lastAimAt or 0
    data.currentLook = data.currentLook or nil
    aimAttachment.CFrame = CFrame.new()
    beamStart.CFrame = CFrame.new()
    beamEnd.CFrame = CFrame.new(0, 0, -FLASHLIGHT_RANGE)

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
    local mountPosition = data.mountPosition or Vector3.new()

    if not (mountPart and flashlightHandle and aimAttachment and beamStart and beamEnd) then
        return
    end

    local unit = lookVector.Unit
    if unit.Magnitude <= 0 then
        return
    end

    local worldPosition = mountPart.CFrame:PointToWorldSpace(mountPosition)
    flashlightHandle.CFrame = CFrame.lookAt(worldPosition, worldPosition + unit)
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

    local data = self:_getPlayerState(userId)
    if not data then
        return
    end

    local action = payload.action
    if action == "Toggle" then
        local enabled = payload.enabled == true
        data.flashlightOn = enabled
        self:_setEnabled(data, enabled)
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
        self:_storePlayer(userId, data)
        return
    end
end

return Service

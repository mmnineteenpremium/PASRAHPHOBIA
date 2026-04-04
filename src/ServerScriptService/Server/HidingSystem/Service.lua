local Services = require(script.Parent.Parent.Core.Services)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Service = {}
Service.__index = Service

local SAFE_ZONE_VISUAL_TRANSPARENCY = 0.82
local SAFE_ZONE_VISUAL_COLOR = Color3.fromRGB(78, 126, 162)
local SAFE_ZONE_VISUAL_MATERIAL = Enum.Material.ForceField
local SAFE_ZONE_TICK_INTERVAL = 0.35
local SAFE_ZONE_MARKER_FOLDER_NAME = "SafeZoneRuntimeMarker"
local SAFE_ZONE_MARKER_OUTLINE_NAME = "Outline"
local SAFE_ZONE_MARKER_LABEL_NAME = "Billboard"
local SAFE_ZONE_MARKER_HIGHLIGHT_NAME = "Highlight"
local SAFE_ZONE_MARKER_OUTLINE_COLOR = Color3.fromRGB(138, 205, 255)
local SAFE_ZONE_MARKER_PANEL_COLOR = Color3.fromRGB(9, 18, 28)
local SAFE_ZONE_MARKER_PANEL_STROKE = Color3.fromRGB(110, 186, 244)
local SAFE_ZONE_MARKER_TITLE_COLOR = Color3.fromRGB(235, 248, 255)
local SAFE_ZONE_MARKER_SUBTITLE_COLOR = Color3.fromRGB(170, 208, 237)
local SAFE_ZONE_MARKER_TITLE_TEXT = "SAFE ZONE"
local SAFE_ZONE_MARKER_SUBTITLE_TEXT = "Diam di sini saat hunt"
local SAFE_ZONE_MARKER_STUDS_OFFSET = 2.6

local function createMarkerTextLabel(name, font, textSize, textColor, text, height, position)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.Position = position
    label.Size = UDim2.new(1, -18, 0, height)
    label.Font = font
    label.Text = text
    label.TextColor3 = textColor
    label.TextSize = textSize
    label.TextTransparency = 0
    label.TextStrokeTransparency = 0.82
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    return label
end

local function ensureSafeZoneMarker(record)
    if type(record) ~= "table" then
        return
    end

    local zone = record.part
    if not zone or zone.Parent == nil then
        return
    end

    local markerFolder = record.markerFolder
    if typeof(markerFolder) ~= "Instance" or markerFolder.Parent ~= zone then
        markerFolder = zone:FindFirstChild(SAFE_ZONE_MARKER_FOLDER_NAME)
        if not (markerFolder and markerFolder:IsA("Folder")) then
            if markerFolder then
                markerFolder:Destroy()
            end
            markerFolder = Instance.new("Folder")
            markerFolder.Name = SAFE_ZONE_MARKER_FOLDER_NAME
            markerFolder.Parent = zone
        end
        record.markerFolder = markerFolder
    end

    local outline = markerFolder:FindFirstChild(SAFE_ZONE_MARKER_OUTLINE_NAME)
    if not (outline and outline:IsA("BoxHandleAdornment")) then
        if outline then
            outline:Destroy()
        end
        outline = Instance.new("BoxHandleAdornment")
        outline.Name = SAFE_ZONE_MARKER_OUTLINE_NAME
        outline.Parent = markerFolder
    end
    outline.Adornee = zone
    outline.AlwaysOnTop = true
    outline.Color3 = SAFE_ZONE_MARKER_OUTLINE_COLOR
    outline.Size = zone.Size + Vector3.new(0.18, 0.18, 0.18)
    outline.Transparency = 0.25
    outline.ZIndex = 6
    outline.Visible = false
    record.markerOutline = outline

    local highlight = markerFolder:FindFirstChild(SAFE_ZONE_MARKER_HIGHLIGHT_NAME)
    if not (highlight and highlight:IsA("Highlight")) then
        if highlight then
            highlight:Destroy()
        end
        highlight = Instance.new("Highlight")
        highlight.Name = SAFE_ZONE_MARKER_HIGHLIGHT_NAME
        highlight.Parent = markerFolder
    end
    highlight.Adornee = zone
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = SAFE_ZONE_MARKER_PANEL_STROKE
    highlight.FillTransparency = 0.9
    highlight.OutlineColor = SAFE_ZONE_MARKER_OUTLINE_COLOR
    highlight.OutlineTransparency = 0.16
    highlight.Enabled = false
    record.markerHighlight = highlight

    local labelGui = markerFolder:FindFirstChild(SAFE_ZONE_MARKER_LABEL_NAME)
    if not (labelGui and labelGui:IsA("BillboardGui")) then
        if labelGui then
            labelGui:Destroy()
        end
        labelGui = Instance.new("BillboardGui")
        labelGui.Name = SAFE_ZONE_MARKER_LABEL_NAME
        labelGui.Parent = markerFolder
    end
    labelGui.Active = false
    labelGui.Adornee = zone
    labelGui.AlwaysOnTop = true
    labelGui.Brightness = 2
    labelGui.ClipsDescendants = false
    labelGui.Enabled = false
    labelGui.LightInfluence = 0
    labelGui.MaxDistance = 90
    labelGui.ResetOnSpawn = false
    labelGui.Size = UDim2.fromOffset(184, 46)
    labelGui.StudsOffsetWorldSpace = Vector3.new(0, zone.Size.Y * 0.5 + SAFE_ZONE_MARKER_STUDS_OFFSET, 0)
    record.markerBillboard = labelGui

    local panel = labelGui:FindFirstChild("Panel")
    if not (panel and panel:IsA("Frame")) then
        if panel then
            panel:Destroy()
        end
        panel = Instance.new("Frame")
        panel.Name = "Panel"
        panel.Parent = labelGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = panel

        local stroke = Instance.new("UIStroke")
        stroke.Name = "Stroke"
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = SAFE_ZONE_MARKER_PANEL_STROKE
        stroke.Transparency = 0.15
        stroke.Thickness = 1.4
        stroke.Parent = panel

        local accent = Instance.new("Frame")
        accent.Name = "Accent"
        accent.AnchorPoint = Vector2.new(0, 0.5)
        accent.BackgroundColor3 = SAFE_ZONE_MARKER_PANEL_STROKE
        accent.BorderSizePixel = 0
        accent.Position = UDim2.new(0, 10, 0.5, 0)
        accent.Size = UDim2.fromOffset(3, 26)
        accent.Parent = panel

        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(1, 0)
        accentCorner.Parent = accent

        createMarkerTextLabel(
            "Title",
            Enum.Font.GothamBold,
            13,
            SAFE_ZONE_MARKER_TITLE_COLOR,
            SAFE_ZONE_MARKER_TITLE_TEXT,
            18,
            UDim2.new(0, 20, 0, 7)
        ).Parent = panel

        createMarkerTextLabel(
            "Subtitle",
            Enum.Font.GothamMedium,
            11,
            SAFE_ZONE_MARKER_SUBTITLE_COLOR,
            SAFE_ZONE_MARKER_SUBTITLE_TEXT,
            16,
            UDim2.new(0, 20, 0, 23)
        ).Parent = panel
    end
    panel.BackgroundColor3 = SAFE_ZONE_MARKER_PANEL_COLOR
    panel.BackgroundTransparency = 0.14
    panel.BorderSizePixel = 0
    panel.Size = UDim2.fromScale(1, 1)
    record.markerPanel = panel
end

local function cleanupSafeZoneMarker(record)
    if type(record) ~= "table" then
        return
    end

    local markerFolder = record.markerFolder
    if typeof(markerFolder) == "Instance" and markerFolder.Parent ~= nil then
        markerFolder:Destroy()
    end
    record.markerFolder = nil
    record.markerOutline = nil
    record.markerBillboard = nil
    record.markerPanel = nil
end

local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
    if type(eventBus) ~= "table" then return nil end
    if type(eventBus.Publish) == "function" then return eventBus end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then return eventBus.Service end
    return nil
end
local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then return playerOrUserId end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then return playerOrUserId.UserId end
    return nil
end

local function getLiveMatch(matchSystem, matchId)
    if type(matchSystem) ~= "table" or type(matchId) ~= "string" or matchId == "" then
        return nil
    end
    if type(matchSystem.GetLiveMatch) == "function" then
        return matchSystem:GetLiveMatch(matchId)
    end
    if type(matchSystem.Service) == "table" and type(matchSystem.Service.GetLiveMatch) == "function" then
        return matchSystem.Service:GetLiveMatch(matchId)
    end
    return nil
end

local function getRuntimeMapModel(matchSystem, matchId)
    local liveMatch = getLiveMatch(matchSystem, matchId)
    if type(liveMatch) ~= "table" then
        return nil
    end

    local container = liveMatch.container
    if typeof(container) ~= "Instance" then
        return nil
    end

    for _, expectedName in ipairs({ liveMatch.mapId, liveMatch.map }) do
        if type(expectedName) == "string" and expectedName ~= "" then
            local exact = container:FindFirstChild(expectedName)
            if exact then
                return exact
            end
        end
    end

    for _, child in ipairs(container:GetChildren()) do
        if (child:IsA("Model") or child:IsA("Folder")) and not child.Name:match("^GhostPlaceholder_") and not child.Name:match("^Ghost_") then
            return child
        end
    end

    return nil
end

local function getCharacterRoot(player)
    local character = typeof(player) == "Instance" and player:IsA("Player") and player.Character or nil
    if not character then
        return nil
    end
    return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart
end

local function isPointInsidePart(part, worldPosition)
    if not part or not part:IsA("BasePart") or typeof(worldPosition) ~= "Vector3" then
        return false
    end

    local localPosition = part.CFrame:PointToObjectSpace(worldPosition)
    local half = part.Size * 0.5
    return math.abs(localPosition.X) <= half.X
        and math.abs(localPosition.Y) <= half.Y
        and math.abs(localPosition.Z) <= half.Z
end

local function applyHideAttributes(player, state, spotType, zoneId)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return
    end

    player:SetAttribute("PasrahHideState", state)
    player:SetAttribute("PasrahHideSpotType", spotType)
    player:SetAttribute("PasrahHideZoneId", zoneId)
end

local function applyDebugAttributes(player, trace, matchId, zoneCount, playerCount)
    if not RunService:IsStudio() then
        return
    end
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return
    end

    player:SetAttribute("PasrahDebugHidingTrace", trace or "")
    player:SetAttribute("PasrahDebugHidingMatchId", matchId or "")
    player:SetAttribute("PasrahDebugHidingZoneCount", tonumber(zoneCount) or 0)
    player:SetAttribute("PasrahDebugHidingPlayerCount", tonumber(playerCount) or 0)
    player:SetAttribute("PasrahDebugHidingTickAt", os.clock())
end

local function applyDebugAttributesForPlayers(players, trace, matchId, zoneCount, playerCount)
    if not RunService:IsStudio() then
        return
    end
    for _, player in ipairs(players or {}) do
        applyDebugAttributes(player, trace, matchId, zoneCount, playerCount)
    end
end

local function setStudioRuntimeAttribute(name, value)
    if not RunService:IsStudio() then
        return
    end
    ReplicatedStorage:SetAttribute(name, value)
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {}
    self._safeZonesByMatchId = {}
    self._running = false
    self._lastDebugPhase = nil
    return self
end

function Service:_traceStudio(phase, ...)
    if not RunService:IsStudio() then
        return
    end
    if phase ~= nil and self._lastDebugPhase == phase then
        return
    end
    self._lastDebugPhase = phase
    print("[HidingSystem][Debug]", phase, ...)
end
function Service:Init()
    self._dependencies = {
        GhostSystem = Services.Get(self._deps, "GhostSystem"),
        InvestigationSystem = Services.Get(self._deps, "InvestigationSystem"),
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
        EconomySystem = Services.Get(self._deps, "EconomySystem"),
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
    }
end
function Service:Start()
    if self._running then
        return
    end

    self._running = true
    setStudioRuntimeAttribute("PasrahHidingReady", true)
    self:_traceStudio("service:start")
    task.spawn(function()
        while self._running do
            self:_tickSafeZones()
            task.wait(SAFE_ZONE_TICK_INTERVAL)
        end
    end)
end
function Service:Stop()
    self._running = false
    setStudioRuntimeAttribute("PasrahHidingReady", nil)
    setStudioRuntimeAttribute("PasrahHidingActiveMatchId", nil)
    setStudioRuntimeAttribute("PasrahHidingRegisteredMatchId", nil)
    setStudioRuntimeAttribute("PasrahHidingZoneCount", nil)
    self:_cleanupAllSafeZones()
    self._state:Clear()
end
function Service:_publish(eventName, payload)
    if self._eventBus then self._eventBus:Publish(eventName, payload) end
end
function Service:_setSafeZoneVisualState(matchId, isVisible)
    local safeZoneState = self._safeZonesByMatchId[matchId]
    if type(safeZoneState) ~= "table" then
        return
    end

    for _, record in ipairs(safeZoneState.records or {}) do
        local zone = record.part
        if zone and zone.Parent ~= nil then
            ensureSafeZoneMarker(record)
            if isVisible then
                zone.Transparency = SAFE_ZONE_VISUAL_TRANSPARENCY
                zone.Color = SAFE_ZONE_VISUAL_COLOR
                zone.Material = SAFE_ZONE_VISUAL_MATERIAL
                zone.CanTouch = false
            else
                zone.Transparency = record.originalTransparency
                zone.Color = record.originalColor
                zone.Material = record.originalMaterial
            end
        end

        if record.markerOutline then
            record.markerOutline.Visible = isVisible == true
        end
        if record.markerHighlight then
            record.markerHighlight.Enabled = isVisible == true
        end
        if record.markerBillboard then
            record.markerBillboard.Enabled = isVisible == true
        end
    end
end
function Service:_registerSafeZones(matchId)
    if type(matchId) ~= "string" or matchId == "" then
        return
    end

    local mapModel = getRuntimeMapModel(self._dependencies.MatchSystem, matchId)
    local safeZonesFolder = mapModel and mapModel:FindFirstChild("SafeZones", true)
    if not safeZonesFolder then
        self._safeZonesByMatchId[matchId] = nil
        return
    end

    local records = {}
    for _, child in ipairs(safeZonesFolder:GetChildren()) do
        if child:IsA("BasePart") then
            table.insert(records, {
                id = child.Name,
                part = child,
                originalTransparency = child.Transparency,
                originalColor = child.Color,
                originalMaterial = child.Material,
            })
            child.CanQuery = true
            child.CanTouch = false
            ensureSafeZoneMarker(records[#records])
        end
    end

    self._safeZonesByMatchId[matchId] = {
        mapModel = mapModel,
        folder = safeZonesFolder,
        records = records,
        huntVisible = false,
    }
    setStudioRuntimeAttribute("PasrahHidingRegisteredMatchId", matchId)
    setStudioRuntimeAttribute("PasrahHidingZoneCount", #records)
    self:_traceStudio("register_safe_zones:" .. matchId, #records)
    self:_setSafeZoneVisualState(matchId, false)
end
function Service:_cleanupSafeZones(matchId)
    local safeZoneState = self._safeZonesByMatchId[matchId]
    if type(safeZoneState) == "table" then
        for _, record in ipairs(safeZoneState.records or {}) do
            local zone = record.part
            if zone and zone.Parent ~= nil then
                zone.Transparency = record.originalTransparency
                zone.Color = record.originalColor
                zone.Material = record.originalMaterial
            end
            cleanupSafeZoneMarker(record)
        end
    end
    self._safeZonesByMatchId[matchId] = nil
end
function Service:_cleanupAllSafeZones()
    for matchId in pairs(self._safeZonesByMatchId) do
        self:_cleanupSafeZones(matchId)
    end
end
function Service:_tickSafeZones()
    local matchId = self._state:Get("activeMatchId")
    if type(matchId) ~= "string" or matchId == "" then
        self:_traceStudio("tick:no_match")
        applyDebugAttributesForPlayers(Players:GetPlayers(), "idle:no_match", "", 0, 0)
        return
    end

    local liveMatch = getLiveMatch(self._dependencies.MatchSystem, matchId)
    if type(liveMatch) ~= "table" then
        self:_traceStudio("tick:no_live_match:" .. matchId)
        applyDebugAttributesForPlayers(Players:GetPlayers(), "wait:no_live_match", matchId, 0, 0)
        return
    end

    if not self._safeZonesByMatchId[matchId] then
        self:_registerSafeZones(matchId)
    end
    local safeZoneState = self._safeZonesByMatchId[matchId]
    if type(safeZoneState) ~= "table" or type(safeZoneState.records) ~= "table" or #safeZoneState.records == 0 then
        self:_traceStudio("tick:no_safe_zones:" .. matchId)
        applyDebugAttributesForPlayers(liveMatch.players or Players:GetPlayers(), "wait:no_safe_zones", matchId, 0, 0)
        return
    end

    local hidden = self._state:Get("hiddenPlayers") or {}
    local playersByUserId = liveMatch.playersByUserId or {}
    local playerCount = 0
    for _ in pairs(playersByUserId) do
        playerCount += 1
    end
    for userId, playerState in pairs(playersByUserId) do
        local player = playerState and playerState.player or Players:GetPlayerByUserId(tonumber(userId) or 0)
        local root = getCharacterRoot(player)
        local activeZoneId = nil
        if root then
            for _, record in ipairs(safeZoneState.records) do
                if isPointInsidePart(record.part, root.Position) then
                    activeZoneId = record.id
                    break
                end
            end
        end

        applyDebugAttributes(
            player,
            activeZoneId and ("tracking:inside:" .. activeZoneId) or "tracking:outside",
            matchId,
            #safeZoneState.records,
            playerCount
        )

        local hiddenEntry = hidden[userId]
        if activeZoneId ~= nil then
            if type(hiddenEntry) == "table" and hiddenEntry.spotType ~= "SafeZone" then
                applyHideAttributes(player, "Hidden", hiddenEntry.spotType or "Unknown", hiddenEntry.zoneId or "")
            elseif type(hiddenEntry) ~= "table" or hiddenEntry.spotType ~= "SafeZone" or hiddenEntry.zoneId ~= activeZoneId then
                hidden[userId] = {
                    spotType = "SafeZone",
                    zoneId = activeZoneId,
                    noise = 0,
                    movement = 0,
                    enteredAt = os.clock(),
                }
                self._state:Set("hiddenPlayers", hidden)
                self:_traceStudio("tick:enter_zone:" .. tostring(activeZoneId))
                applyHideAttributes(player, "Hidden", "SafeZone", activeZoneId)
                self:_publish("PlayerHid", {
                    userId = userId,
                    player = player,
                    spotType = "SafeZone",
                    zoneId = activeZoneId,
                    matchId = matchId,
                })
            else
                applyHideAttributes(player, "Hidden", "SafeZone", activeZoneId)
            end
        elseif type(hiddenEntry) == "table" and hiddenEntry.spotType == "SafeZone" then
            hidden[userId] = nil
            self._state:Set("hiddenPlayers", hidden)
            self:_traceStudio("tick:exit_zone")
            applyHideAttributes(player, "Exposed", "None", "")
            self:_publish("PlayerRevealed", {
                userId = userId,
                player = player,
                matchId = matchId,
            })
        elseif type(hiddenEntry) == "table" then
            applyHideAttributes(player, "Hidden", hiddenEntry.spotType or "Unknown", hiddenEntry.zoneId or "")
        else
            applyHideAttributes(player, "Exposed", "None", "")
        end
    end
end
function Service:HandleEvent(eventName, payload)
    if eventName == "MatchStarted" then self._state:Set("activeMatchId", payload and payload.matchId)
    elseif eventName == "MatchEnded" then self._state:Set("activeMatchId", nil) end
    if eventName == "MatchStarted" then
        setStudioRuntimeAttribute("PasrahHidingActiveMatchId", payload and payload.matchId or "")
        self:_traceStudio("event:match_started:" .. tostring(payload and payload.matchId or "nil"))
        self._state:Set("hiddenPlayers", {})
        self._state:Set("detectedPlayers", {})
        applyDebugAttributesForPlayers(payload and payload.players, "event:match_started", payload and payload.matchId, 0, 0)
        self:_registerSafeZones(payload and payload.matchId)
    elseif eventName == "HuntStarted" then
        local matchId = payload and payload.matchId or self._state:Get("activeMatchId")
        if type(matchId) == "string" then
            self:_setSafeZoneVisualState(matchId, true)
        end
    elseif eventName == "HuntEnded" then
        local matchId = payload and payload.matchId or self._state:Get("activeMatchId")
        if type(matchId) == "string" then
            self:_setSafeZoneVisualState(matchId, false)
        end
    elseif eventName == "PlayerAttemptHide" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        if userId then
            local hidden = self._state:Get("hiddenPlayers") or {}
            hidden[userId] = { spotType = payload.spotType or "Unknown", zoneId = payload.zoneId, noise = tonumber(payload.noiseLevel) or 0, movement = tonumber(payload.movementLevel) or 0, enteredAt = os.clock() }
            self._state:Set("hiddenPlayers", hidden)
            applyHideAttributes(payload.player, "Hidden", hidden[userId].spotType, hidden[userId].zoneId or "")
            self:_publish("PlayerHid", { userId = userId, player = payload.player, spotType = hidden[userId].spotType, zoneId = hidden[userId].zoneId, matchId = self._state:Get("activeMatchId") })
        end
    elseif eventName == "PlayerExitHide" then
        local userId = toUserId(payload and (payload.player or payload.userId))
        local hidden = self._state:Get("hiddenPlayers") or {}
        if userId then
            hidden[userId] = nil
            self._state:Set("hiddenPlayers", hidden)
            applyHideAttributes(payload.player, "Exposed", "None", "")
            self:_publish("PlayerRevealed", { userId = userId, player = payload.player, matchId = self._state:Get("activeMatchId") })
        end
    elseif eventName == "GhostInteraction" and payload and payload.action == "GhostNearHidingSpot" then
        local hidden = self._state:Get("hiddenPlayers") or {}
        for userId, data in pairs(hidden) do
            local score = (tonumber(data.noise) or 0) + (tonumber(data.movement) or 0) + (tonumber(payload.proximity) or 0)
            if score >= 1.5 then
                local detected = self._state:Get("detectedPlayers") or {}
                detected[userId] = true
                self._state:Set("detectedPlayers", detected)
                self:_publish("PlayerHidingDetected", { userId = userId, matchId = self._state:Get("activeMatchId") })
            end
        end
    elseif eventName == "MatchEnded" then
        setStudioRuntimeAttribute("PasrahHidingActiveMatchId", nil)
        local hidden = self._state:Get("hiddenPlayers") or {}
        for userId in pairs(hidden) do
            local player = Players:GetPlayerByUserId(tonumber(userId) or 0)
            applyHideAttributes(player, "Exposed", "None", "")
        end
        self:_cleanupSafeZones(payload and payload.matchId)
    end
end
return Service

local function resolveNamedModule(container, childName)
    local fallbackMainModule = nil

    for _, child in ipairs(container:GetChildren()) do
        if child.Name == childName then
            if child:IsA("ModuleScript") then
                return child
            end

            if child:IsA("Folder") then
                local mainModule = child:FindFirstChild("Main")
                if mainModule and mainModule:IsA("ModuleScript") then
                    fallbackMainModule = mainModule
                end
            end
        end
    end

    return fallbackMainModule
end

local function requireNamedModule(container, childName)
    local moduleScript = resolveNamedModule(container, childName)
    if not moduleScript then
        error(string.format("[LobbyService] Missing module child: %s", childName))
    end

    return require(moduleScript)
end

local LobbyPlayerManager = requireNamedModule(script.Parent, "LobbyPlayerManager")
local LobbyZoneManager = requireNamedModule(script.Parent, "LobbyZoneManager")
local LobbyInteraction = requireNamedModule(script.Parent, "LobbyInteraction")
local PartySystem = requireNamedModule(script.Parent, "PartySystem")
local LobbyPopulationController = requireNamedModule(script.Parent, "LobbyPopulationController")
local LobbyLocator = require(script.Parent.Parent.Core.LobbyLocator)
local Services = require(script.Parent.Parent.Core.Services)

local LOBBY_COSMETIC_FOLDER_NAME = "LobbyCosmeticVisuals"
local LOBBY_COSMETIC_GUI_NAME = "LobbyCosmeticBillboard"
local FLEX_SPOTLIGHT_PARTICIPANT_LIMIT = 4
local LOBBY_ZONE_GUIDE_FOLDER_NAME = "LobbyZoneGuideRuntime"
local LOBBY_ZONE_GUIDE_BILLBOARD_NAME = "Billboard"
local LOBBY_ZONE_GUIDE_HIGHLIGHT_NAME = "Highlight"
local LOBBY_ZONE_ENTRY_GUIDE_FOLDER_NAME = "LobbyZoneEntryGuideRuntime"
local LOBBY_ZONE_ENTRY_GUIDE_BILLBOARD_NAME = "Billboard"
local LOBBY_ZONE_ENTRY_GUIDE_HIGHLIGHT_NAME = "Highlight"
local LOBBY_ZONE_ENTRY_GUIDE_ACCENT_NAME = "AccentBar"
local LOBBY_ZONE_ENTRY_GUIDE_LIGHT_NAME = "AccentLight"
local LOBBY_ZONE_ENTRY_GUIDE_FRAME_TOP_NAME = "FrameTop"
local LOBBY_ZONE_ENTRY_GUIDE_FRAME_LEFT_NAME = "FrameLeft"
local LOBBY_ZONE_ENTRY_GUIDE_FRAME_RIGHT_NAME = "FrameRight"
local LOBBY_ZONE_ENTRY_GUIDE_HEADER_NAME = "HeaderBand"
local LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_BOARD_NAME = "ContractBoard"
local LOBBY_ZONE_ENTRY_GUIDE_TOOLS_BOARD_NAME = "ToolsBoard"
local LOBBY_ZONE_ENTRY_GUIDE_BOARD_BILLBOARD_NAME = "BoardBillboard"
local LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_STAND_NAME = "ContractStand"
local LOBBY_ZONE_ENTRY_GUIDE_TOOLS_STAND_NAME = "ToolsStand"
local LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_BASE_NAME = "ContractBase"
local LOBBY_ZONE_ENTRY_GUIDE_TOOLS_BASE_NAME = "ToolsBase"
local LOBBY_ZONE_ENTRY_GUIDE_CANOPY_NAME = "FacadeCanopy"
local LOBBY_ZONE_ENTRY_GUIDE_APRON_NAME = "FacadeApron"
local LOBBY_ZONE_ENTRY_GUIDE_WING_LEFT_NAME = "FacadeWingLeft"
local LOBBY_ZONE_ENTRY_GUIDE_WING_RIGHT_NAME = "FacadeWingRight"
local LOBBY_ZONE_GUIDES_ENABLED = false
local LOBBY_ZONE_ENTRY_GUIDES_ENABLED = true
local LOBBY_LOGIC_VOLUME_TRANSPARENCY = 1
local LOBBY_LOGIC_VOLUME_FOLDER_NAMES = {
	"Rooms",
	"SafeZones",
	"InteractionPoints",
	"NavigationNodes",
	"SpawnPoints",
}
local LOBBY_MAINHUB_VISUAL_PATCH = {
	Roof_MainHubPlaza = {
		transparency = 0.72,
		color = Color3.fromRGB(88, 96, 108),
		castShadow = false,
	},
	Floor_1_Main = {
		color = Color3.fromRGB(68, 78, 92),
	},
	Wall_MainHubPlaza_North = {
		color = Color3.fromRGB(92, 102, 116),
	},
	Wall_MainHubPlaza_South = {
		color = Color3.fromRGB(92, 102, 116),
	},
	Wall_MainHubPlaza_East = {
		color = Color3.fromRGB(92, 102, 116),
	},
	Wall_MainHubPlaza_West = {
		color = Color3.fromRGB(92, 102, 116),
	},
}
local LOBBY_ZONE_FEEDBACK = {
    SpawnPlaza = {
        title = "Lobby plaza aktif.",
        hint = "Semua panel utama tetap bisa diakses dari quick menu tanpa harus menyentuh bangunan tertentu.",
    },
    MatchmakingZone = {
        title = "Area contract & evidence aktif.",
        hint = "Gunakan PLAY atau Room Browser untuk membuat room, lalu pakai bangunan utara sebagai anchor contract board dan training evidence.",
    },
    ShopZone = {
        title = "Area shop aktif.",
        hint = "Buka SHOP untuk melihat item MM/PP/Robux yang memang visible dan compliant.",
    },
    PartyZone = {
        title = "Area party aktif.",
        hint = "Gunakan Room Browser untuk invite, ready, dan kontrol room tanpa sentuhan UI yang membingungkan.",
    },
    FlexZone = {
        title = "Area flex aktif.",
        hint = "Spotlight flex tetap hidup untuk kosmetik lobby, tetapi tidak memaksa panel lain terbuka.",
    },
    DailyRewardZone = {
        title = "Area social garden aktif.",
        hint = "Zona ini dipakai sebagai anchor reward/social sampai pass restruktur visual final selesai.",
    },
}

local LOBBY_ZONE_GUIDE_STYLE = {
    SpawnPlaza = {
        color = Color3.fromRGB(110, 186, 244),
        subtitle = "Hub utama dan quick access",
    },
    MatchmakingZone = {
        color = Color3.fromRGB(132, 186, 255),
        subtitle = "Contract board, evidence training, start match",
    },
    ShopZone = {
        color = Color3.fromRGB(255, 196, 118),
        subtitle = "MM / PP / Robux yang visible",
    },
    PartyZone = {
        color = Color3.fromRGB(142, 214, 198),
        subtitle = "Invite, ready, dan kontrol room",
    },
    FlexZone = {
        color = Color3.fromRGB(214, 146, 255),
        subtitle = "Spotlight kosmetik lobby",
    },
    DailyRewardZone = {
        color = Color3.fromRGB(138, 228, 178),
        subtitle = "Reward dan social anchor",
    },
}

local LOBBY_ZONE_ENTRY_COPY = {
    MatchmakingZone = {
        title = "PLAY",
        subtitle = "Contract board & start match",
        meta = "TOOLS TRAINING • CONTRACT",
    },
    ShopZone = {
        title = "SHOP",
        subtitle = "Masuk ke toko",
    },
    PartyZone = {
        title = "PARTY",
        subtitle = "Masuk ke room party",
    },
    DailyRewardZone = {
        title = "GARDEN",
        subtitle = "Masuk ke social garden",
    },
    FlexZone = {
        title = "FLEX",
        subtitle = "Masuk ke spotlight kosmetik",
    },
}

local LOBBY_ZONE_ENTRY_ANCHORS = {
    MatchmakingZone = { "Door_NorthEvidenceBuilding", "Interact_NorthEvidenceBuilding" },
    ShopZone = { "Door_EastShopBuilding", "Interact_EastShopBuilding" },
    PartyZone = { "Door_WestPartyZone", "Interact_WestPartyZone" },
    DailyRewardZone = { "Door_SouthSocialGarden", "Interact_SouthSocialGarden" },
    FlexZone = { "Door_SouthEastFlexZone", "Interact_SouthEastFlexZone" },
}

local SLOT_DISPLAY_ORDER = {
    outfit = 1,
    body = 2,
    head = 3,
    accessory = 4,
    emote = 5,
}

local RARITY_COLORS = {
    R1 = Color3.fromRGB(150, 189, 255),
    R2 = Color3.fromRGB(118, 232, 196),
    R3 = Color3.fromRGB(255, 183, 112),
    R4 = Color3.fromRGB(255, 130, 130),
    R5 = Color3.fromRGB(214, 146, 255),
    Common = Color3.fromRGB(150, 189, 255),
    Rare = Color3.fromRGB(118, 232, 196),
    Epic = Color3.fromRGB(255, 183, 112),
    Legendary = Color3.fromRGB(255, 130, 130),
    Mythic = Color3.fromRGB(214, 146, 255),
}

local LobbyService = {}
LobbyService.__index = LobbyService

local function resolveEventBus(deps)
    local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus")) or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus")) or (deps and deps.EventBus or nil)
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

local function getByPath(root, path)
    local node = root
    for _, segment in ipairs(path or {}) do
        if typeof(node) ~= "Instance" then
            return nil
        end
        node = node:FindFirstChild(segment)
        if not node then
            return nil
        end
    end
    return node
end

local function resolveShopCatalogModule()
    local pathOptions = {
        { "shared", "DataTypes", "ShopCatalog" },
        { "Shared", "DataTypes", "ShopCatalog" },
    }

    local cursor = script
    while cursor do
        for _, path in ipairs(pathOptions) do
            local moduleScript = getByPath(cursor, path)
            if moduleScript then
                return moduleScript
            end
        end
        cursor = cursor.Parent
    end

    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if ok and typeof(replicatedStorage) == "Instance" then
        for _, path in ipairs(pathOptions) do
            local moduleScript = getByPath(replicatedStorage, path)
            if moduleScript then
                return moduleScript
            end
        end
    end

    return nil
end

local function toUserId(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return nil
    end
    return player.UserId
end

local function cloneMap(source)
    local result = {}
    if type(source) ~= "table" then
        return result
    end
    for key, value in pairs(source) do
        result[key] = value
    end
    return result
end

local function cloneArray(source)
    local result = {}
    if type(source) ~= "table" then
        return result
    end
    for index, value in ipairs(source) do
        result[index] = value
    end
    return result
end

local function removeArrayValue(source, targetValue)
    if type(source) ~= "table" then
        return
    end
    for index = #source, 1, -1 do
        if source[index] == targetValue then
            table.remove(source, index)
        end
    end
end

local function sanitizeEquippedCosmetics(equippedCosmetics)
    local sanitized = {}
    if type(equippedCosmetics) ~= "table" then
        return sanitized
    end
    for slot, cosmeticId in pairs(equippedCosmetics) do
        if type(slot) == "string" and slot ~= "" and type(cosmeticId) == "string" and cosmeticId ~= "" then
            sanitized[slot] = cosmeticId
        end
    end
    return sanitized
end

local function titleCaseToken(token)
    if token == "" then
        return token
    end
    if #token <= 3 and string.match(token, "^%u+$") then
        return token
    end
    return string.upper(string.sub(token, 1, 1)) .. string.lower(string.sub(token, 2))
end

local function humanizeCosmeticId(cosmeticId)
    local cleaned = tostring(cosmeticId or "")
        :gsub("^cos_", "")
        :gsub("^eq_", "")
        :gsub("^cosmetic_", "")
        :gsub("_", " ")

    local words = {}
    for token in string.gmatch(cleaned, "%S+") do
        table.insert(words, titleCaseToken(token))
    end

    if #words == 0 then
        return "Cosmetic"
    end
    return table.concat(words, " ")
end

local function getCharacterPart(character, partNames)
    if not character then
        return nil
    end
    for _, partName in ipairs(partNames or {}) do
        local candidate = character:FindFirstChild(partName)
        if candidate and candidate:IsA("BasePart") then
            return candidate
        end
    end
    return nil
end

local function createVisualFolder(character)
    local folder = Instance.new("Folder")
    folder.Name = LOBBY_COSMETIC_FOLDER_NAME
    folder.Parent = character
    return folder
end

local function createWeldedVisual(folder, anchorPart, name, props)
    if not folder or not anchorPart then
        return nil
    end

    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = false
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Massless = true
    part.Locked = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Material = props.material or Enum.Material.SmoothPlastic
    part.Transparency = props.transparency or 0
    part.Color = props.color or Color3.fromRGB(255, 255, 255)
    part.Size = props.size or Vector3.new(1, 1, 1)
    part.Shape = props.shape or Enum.PartType.Block
    part.CFrame = anchorPart.CFrame * (props.offset or CFrame.new())
    part.Parent = folder

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = anchorPart
    weld.Part1 = part
    weld.Parent = part

    return part
end

local function chooseRarityColor(rarity, fallback)
    if type(rarity) == "string" and RARITY_COLORS[rarity] then
        return RARITY_COLORS[rarity]
    end
    return fallback
end

local function isLobbyCharacter(player, character)
    return player
        and character
        and player:GetAttribute("InLobby") == true
        and player:GetAttribute("InMatch") ~= true
end

local function clampDisplayNames(entries)
    local names = {}
    for _, entry in ipairs(entries) do
        table.insert(names, entry.name)
        if #names >= 3 then
            break
        end
    end
    return names
end

local function ensureNeonGuidePart(parent, name)
    local part = parent:FindFirstChild(name)
    if not (part and part:IsA("Part")) then
        if part then
            part:Destroy()
        end
        part = Instance.new("Part")
        part.Name = name
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.CastShadow = false
        part.Locked = true
        part.Material = Enum.Material.Neon
        part.Parent = parent
    end
    return part
end

local function ensureGuidePanelPart(parent, name)
    local part = parent:FindFirstChild(name)
    if not (part and part:IsA("Part")) then
        if part then
            part:Destroy()
        end
        part = Instance.new("Part")
        part.Name = name
        part.Anchored = true
        part.CanCollide = false
        part.CanQuery = false
        part.CanTouch = false
        part.CastShadow = false
        part.Locked = true
        part.Material = Enum.Material.SmoothPlastic
        part.Parent = parent
    end
    return part
end

local function ensureGuideBoardBillboard(parent, titleText, subtitleText, accentColor)
    local billboard = parent:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_BOARD_BILLBOARD_NAME)
    if not (billboard and billboard:IsA("BillboardGui")) then
        if billboard then
            billboard:Destroy()
        end
        billboard = Instance.new("BillboardGui")
        billboard.Name = LOBBY_ZONE_ENTRY_GUIDE_BOARD_BILLBOARD_NAME
        billboard.Parent = parent
    end

    billboard.Active = false
    billboard.Adornee = parent
    billboard.AlwaysOnTop = true
    billboard.Brightness = 2
    billboard.LightInfluence = 0
    billboard.MaxDistance = 90
    billboard.ResetOnSpawn = false
    billboard.Size = UDim2.fromOffset(148, 70)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 0.1, 0)

    local panel = billboard:FindFirstChild("Panel")
    if not (panel and panel:IsA("Frame")) then
        if panel then
            panel:Destroy()
        end
        panel = Instance.new("Frame")
        panel.Name = "Panel"
        panel.Parent = billboard

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = panel

        local stroke = Instance.new("UIStroke")
        stroke.Name = "Stroke"
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Thickness = 1
        stroke.Parent = panel

        local accent = Instance.new("Frame")
        accent.Name = "Accent"
        accent.AnchorPoint = Vector2.new(0, 0.5)
        accent.BorderSizePixel = 0
        accent.Position = UDim2.new(0, 8, 0.5, 0)
        accent.Size = UDim2.fromOffset(3, 36)
        accent.Parent = panel

        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(1, 0)
        accentCorner.Parent = accent

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.BackgroundTransparency = 1
        title.BorderSizePixel = 0
        title.Font = Enum.Font.GothamBold
        title.Text = titleText
        title.TextColor3 = Color3.fromRGB(245, 248, 252)
        title.TextSize = 11
        title.TextTransparency = 0
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextYAlignment = Enum.TextYAlignment.Center
        title.Position = UDim2.new(0, 18, 0, 10)
        title.Size = UDim2.new(1, -28, 0, 16)
        title.Parent = panel

        local subtitle = Instance.new("TextLabel")
        subtitle.Name = "Subtitle"
        subtitle.BackgroundTransparency = 1
        subtitle.BorderSizePixel = 0
        subtitle.Font = Enum.Font.GothamMedium
        subtitle.Text = subtitleText
        subtitle.TextColor3 = accentColor:Lerp(Color3.fromRGB(245, 248, 252), 0.25)
        subtitle.TextSize = 9
        subtitle.TextTransparency = 0
        subtitle.TextWrapped = true
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.TextYAlignment = Enum.TextYAlignment.Top
        subtitle.Position = UDim2.new(0, 18, 0, 28)
        subtitle.Size = UDim2.new(1, -28, 0, 32)
        subtitle.Parent = panel
    end

    panel.Size = UDim2.fromScale(1, 1)
    panel.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
    panel.BackgroundTransparency = 0.12
    panel.BorderSizePixel = 0

    local stroke = panel:FindFirstChild("Stroke")
    if stroke and stroke:IsA("UIStroke") then
        stroke.Color = accentColor
        stroke.Transparency = 0.22
    end
    local accent = panel:FindFirstChild("Accent")
    if accent and accent:IsA("Frame") then
        accent.BackgroundColor3 = accentColor
    end
    local title = panel:FindFirstChild("Title")
    if title and title:IsA("TextLabel") then
        title.Text = titleText
    end
    local subtitle = panel:FindFirstChild("Subtitle")
    if subtitle and subtitle:IsA("TextLabel") then
        subtitle.Text = subtitleText
        subtitle.TextColor3 = accentColor:Lerp(Color3.fromRGB(245, 248, 252), 0.25)
    end

    return billboard
end

local function createGuideTextLabel(name, font, textSize, textColor, text, height, position)
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
    label.TextStrokeTransparency = 0.84
    label.TextWrapped = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    return label
end

local function sanitizeLobbyLogicPart(part)
	if not (part and part:IsA("BasePart")) then
		return false
	end

	local changed = false
	if part.Transparency ~= LOBBY_LOGIC_VOLUME_TRANSPARENCY then
		part.Transparency = LOBBY_LOGIC_VOLUME_TRANSPARENCY
		changed = true
	end
	if part.CanCollide then
		part.CanCollide = false
		changed = true
	end
	if part.CanTouch then
		part.CanTouch = false
		changed = true
	end
	if part.CanQuery ~= true then
		part.CanQuery = true
		changed = true
	end
	if part.CastShadow then
		part.CastShadow = false
		changed = true
	end
	return changed
end

local function sanitizeLobbyLogicVolumes()
	local lobbyRoot = LobbyLocator.ResolveRoot("LobbySocialHub", workspace)
	if not lobbyRoot then
		return false
	end

	local changed = false
	for _, folderName in ipairs(LOBBY_LOGIC_VOLUME_FOLDER_NAMES) do
		local folder = lobbyRoot:FindFirstChild(folderName, true)
		if folder then
			for _, descendant in ipairs(folder:GetDescendants()) do
				if descendant:IsA("BasePart") then
					changed = sanitizeLobbyLogicPart(descendant) or changed
				end
			end
		end
	end
	return changed
end

local function applyMainHubVisualPatch()
	local lobbyRoot = LobbyLocator.ResolveRoot("LobbySocialHub", workspace)
	if not lobbyRoot then
		return false
	end

	local changed = false
	for partName, patch in pairs(LOBBY_MAINHUB_VISUAL_PATCH) do
		local part = lobbyRoot:FindFirstChild(partName, true)
		if part and part:IsA("BasePart") then
			if patch.color and part.Color ~= patch.color then
				part.Color = patch.color
				changed = true
			end
			if type(patch.transparency) == "number" and part.Transparency ~= patch.transparency then
				part.Transparency = patch.transparency
				changed = true
			end
			if type(patch.castShadow) == "boolean" and part.CastShadow ~= patch.castShadow then
				part.CastShadow = patch.castShadow
				changed = true
			end
		end
	end

	return changed
end

function LobbyService.new(state, deps)
    local self = setmetatable({}, LobbyService)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)

    self._playerManager = LobbyPlayerManager.new(self._deps, self._deps.LobbyPlayerManagerConfig)
    self._zoneManager = LobbyZoneManager.new(self._deps, self._deps.LobbyZoneManagerConfig)
    self._interaction = LobbyInteraction.new(self._deps, self._deps.LobbyInteractionConfig)
    self._partySystem = PartySystem.new(self._deps, self._deps.PartySystemConfig)
    self._population = LobbyPopulationController.new(self._state, self._deps, self._deps.LobbyPopulationConfig)
    self._characterConnections = {}
    self._cosmeticCatalogById = {}
    self._dependencies = {}
    return self
end

function LobbyService:_loadCosmeticCatalog()
    local catalog = safeRequire(resolveShopCatalogModule()) or {}
    local catalogById = {}

    for _, entry in pairs(catalog) do
        if type(entry) == "table" and type(entry.id) == "string" and entry.id ~= "" then
            catalogById[entry.id] = entry
        end
    end

    self._cosmeticCatalogById = catalogById
end

function LobbyService:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function LobbyService:_getAppliedCosmeticsStore()
    local store = self._state:Get("appliedCosmeticsByUserId")
    if type(store) ~= "table" then
        store = {}
        self._state:Set("appliedCosmeticsByUserId", store)
    end
    return store
end

function LobbyService:_getAppliedCosmetics(player)
    local userId = toUserId(player)
    if not userId then
        return {}
    end

    local store = self:_getAppliedCosmeticsStore()
    return cloneMap(store[userId] or {})
end

function LobbyService:_setAppliedCosmetics(player, equippedCosmetics)
    local userId = toUserId(player)
    if not userId then
        return {}
    end

    local store = self:_getAppliedCosmeticsStore()
    local snapshot = sanitizeEquippedCosmetics(equippedCosmetics)
    store[userId] = snapshot
    self._state:Set("appliedCosmeticsByUserId", store)
    return snapshot
end

function LobbyService:_disconnectCharacterConnection(userId)
    local connection = self._characterConnections[userId]
    if connection then
        connection:Disconnect()
        self._characterConnections[userId] = nil
    end
end

function LobbyService:_clearCosmeticVisuals(character)
    if not character then
        return
    end

    local visuals = character:FindFirstChild(LOBBY_COSMETIC_FOLDER_NAME)
    if visuals then
        visuals:Destroy()
    end

    character:SetAttribute("LobbyEquippedEmote", nil)
end

function LobbyService:_buildDisplayEntries(equippedCosmetics)
    local entries = {}

    for slot, cosmeticId in pairs(equippedCosmetics or {}) do
        local catalogEntry = self._cosmeticCatalogById[cosmeticId]
        table.insert(entries, {
            slot = slot,
            cosmeticId = cosmeticId,
            name = (type(catalogEntry) == "table" and type(catalogEntry.name) == "string" and catalogEntry.name ~= "")
                    and catalogEntry.name
                or humanizeCosmeticId(cosmeticId),
            rarity = type(catalogEntry) == "table" and catalogEntry.rarity or nil,
        })
    end

    table.sort(entries, function(left, right)
        local leftOrder = SLOT_DISPLAY_ORDER[left.slot] or 99
        local rightOrder = SLOT_DISPLAY_ORDER[right.slot] or 99
        if leftOrder == rightOrder then
            return left.name < right.name
        end
        return leftOrder < rightOrder
    end)

    return entries
end

function LobbyService:_getFlexState()
    local flexState = self._state:Get("flexZoneState")
    if type(flexState) ~= "table" then
        flexState = {}
    end

    if type(flexState.participantsByUserId) ~= "table" then
        flexState.participantsByUserId = {}
    end
    if type(flexState.rotationOrder) ~= "table" then
        flexState.rotationOrder = {}
    end
    if type(flexState.spotlightUserId) ~= "number" then
        flexState.spotlightUserId = nil
    end

    self._state:Set("flexZoneState", flexState)
    return flexState
end

function LobbyService:_getPlayerProfileSystem()
    local profileSystem = self._dependencies.PlayerProfileSystem
    if profileSystem ~= nil then
        return profileSystem
    end

    profileSystem = Services.Get(self._deps, "PlayerProfileSystem")
    self._dependencies.PlayerProfileSystem = profileSystem
    return profileSystem
end

function LobbyService:_getPublicProfile(player)
    local profileSystem = self:_getPlayerProfileSystem()
    if type(profileSystem) ~= "table" then
        return nil
    end

    local profile = safeCall(profileSystem, "GetPublicProfile", player)
    if profile == nil and type(profileSystem.Service) == "table" then
        profile = safeCall(profileSystem.Service, "GetPublicProfile", player)
    end
    if profile ~= nil then
        return profile
    end

    profile = safeCall(profileSystem, "RefreshProfile", player)
    if profile == nil and type(profileSystem.Service) == "table" then
        profile = safeCall(profileSystem.Service, "RefreshProfile", player)
    end
    return profile
end

function LobbyService:_summarizeFlexShowcase(entry)
    local featuredNames = clampDisplayNames(entry and entry.showcaseItems or {})
    if #featuredNames == 0 then
        return "-"
    end
    return table.concat(featuredNames, ", ")
end

function LobbyService:_buildFlexParticipant(player)
    local userId = toUserId(player)
    if not userId then
        return nil
    end

    local profile = self:_getPublicProfile(player)
    local equippedCosmetics = self:_getAppliedCosmetics(player)
    if next(equippedCosmetics) == nil and type(profile) == "table" then
        equippedCosmetics = sanitizeEquippedCosmetics(profile.equippedCosmetics)
    end

    local displayEntries = self:_buildDisplayEntries(equippedCosmetics)
    local showcaseItems = {}
    for _, entry in ipairs(displayEntries) do
        table.insert(showcaseItems, {
            slot = entry.slot,
            cosmeticId = entry.cosmeticId,
            name = entry.name,
            rarity = entry.rarity,
        })
        if #showcaseItems >= FLEX_SPOTLIGHT_PARTICIPANT_LIMIT then
            break
        end
    end

    return {
        userId = userId,
        playerName = player.Name,
        displayName = player.DisplayName or player.Name,
        playerLevel = math.max(1, math.floor(tonumber(profile and profile.playerLevel) or 1)),
        rankTier = tostring(profile and profile.rankTier or "Bayi III"),
        winRate = math.max(0, math.floor(tonumber(profile and profile.winRate) or 0)),
        totalMatches = math.max(0, math.floor(tonumber(profile and profile.totalMatches) or 0)),
        totalWins = math.max(0, math.floor(tonumber(profile and profile.totalWins) or 0)),
        flexGallery = cloneArray(profile and profile.flexGallery or {}),
        equippedCosmetics = sanitizeEquippedCosmetics(equippedCosmetics),
        showcaseItems = showcaseItems,
        spotlightSummary = self:_summarizeFlexShowcase({
            showcaseItems = showcaseItems,
        }),
        updatedAt = os.time(),
    }
end

function LobbyService:_buildFlexParticipantSummary(entry)
    if type(entry) ~= "table" then
        return nil
    end
    return {
        userId = entry.userId,
        displayName = entry.displayName,
        playerName = entry.playerName,
        playerLevel = entry.playerLevel,
        rankTier = entry.rankTier,
        winRate = entry.winRate,
        totalMatches = entry.totalMatches,
        totalWins = entry.totalWins,
        showcaseSummary = entry.spotlightSummary,
        featuredNames = clampDisplayNames(entry.showcaseItems or {}),
    }
end

function LobbyService:_buildFlexSpotlight(entry)
    if type(entry) ~= "table" then
        return nil
    end
    return {
        userId = entry.userId,
        displayName = entry.displayName,
        playerName = entry.playerName,
        playerLevel = entry.playerLevel,
        rankTier = entry.rankTier,
        winRate = entry.winRate,
        totalMatches = entry.totalMatches,
        totalWins = entry.totalWins,
        showcaseSummary = entry.spotlightSummary,
        featuredNames = clampDisplayNames(entry.showcaseItems or {}),
        showcaseItems = cloneArray(entry.showcaseItems),
        flexGallery = cloneArray(entry.flexGallery),
        equippedCosmetics = cloneMap(entry.equippedCosmetics),
        updatedAt = entry.updatedAt,
    }
end

function LobbyService:_buildFlexParticipantsList(flexState)
    local participants = {}
    local participantsByUserId = flexState.participantsByUserId or {}

    for _, userId in ipairs(flexState.rotationOrder or {}) do
        local summary = self:_buildFlexParticipantSummary(participantsByUserId[userId])
        if summary then
            table.insert(participants, summary)
        end
        if #participants >= FLEX_SPOTLIGHT_PARTICIPANT_LIMIT then
            break
        end
    end

    return participants
end

function LobbyService:_publishFlexSpotlight(flexState, reason)
    local spotlight = flexState and flexState.participantsByUserId and flexState.participantsByUserId[flexState.spotlightUserId] or nil
    local payload = {
        eventName = spotlight and "LobbyFlexSpotlightUpdated" or "LobbyFlexSpotlightCleared",
        source = "LobbySocialHub",
        zoneName = "FlexZone",
        reason = reason or "updated",
        spotlight = self:_buildFlexSpotlight(spotlight),
        participants = self:_buildFlexParticipantsList(flexState or self:_getFlexState()),
        activeVisitorCount = #(flexState and flexState.rotationOrder or {}),
        updatedAt = os.time(),
        recipients = self:GetLobbyPlayers(),
    }
    flexState.lastPayload = payload
    flexState.lastUpdatedAt = payload.updatedAt
    self._state:Set("flexZoneState", flexState)
    self:_publish(payload.eventName, payload)
end

function LobbyService:_activateFlexSpotlight(player, reason)
    local participant = self:_buildFlexParticipant(player)
    if not participant then
        return
    end

    local flexState = self:_getFlexState()
    flexState.participantsByUserId[participant.userId] = participant
    removeArrayValue(flexState.rotationOrder, participant.userId)
    table.insert(flexState.rotationOrder, 1, participant.userId)
    flexState.spotlightUserId = participant.userId
    self:_publishFlexSpotlight(flexState, reason or "zone_entered")
end

function LobbyService:_removeFlexParticipant(player)
    local userId = toUserId(player)
    if not userId then
        return
    end

    local flexState = self:_getFlexState()
    if flexState.participantsByUserId[userId] == nil then
        return
    end

    flexState.participantsByUserId[userId] = nil
    removeArrayValue(flexState.rotationOrder, userId)

    if flexState.spotlightUserId == userId then
        flexState.spotlightUserId = flexState.rotationOrder[1]
        self:_publishFlexSpotlight(flexState, "spotlight_left")
        return
    end

    if flexState.spotlightUserId ~= nil then
        self:_publishFlexSpotlight(flexState, "participant_left")
        return
    end

    self._state:Set("flexZoneState", flexState)
end

function LobbyService:_refreshFlexParticipant(player, reason)
    local userId = toUserId(player)
    if not userId then
        return
    end

    local flexState = self:_getFlexState()
    if flexState.participantsByUserId[userId] == nil then
        return
    end

    local participant = self:_buildFlexParticipant(player)
    if not participant then
        return
    end

    flexState.participantsByUserId[userId] = participant
    if flexState.spotlightUserId == userId then
        self:_publishFlexSpotlight(flexState, reason or "spotlight_refreshed")
        return
    end

    self._state:Set("flexZoneState", flexState)
end

function LobbyService:_createBillboard(folder, head, equippedCosmetics)
    if not folder or not head then
        return
    end

    local entries = self:_buildDisplayEntries(equippedCosmetics)
    local emoteName = nil
    local flexEntries = {}

    for _, entry in ipairs(entries) do
        if entry.slot == "emote" and emoteName == nil then
            emoteName = entry.name
        else
            table.insert(flexEntries, entry)
        end
    end

    local primaryNames = clampDisplayNames(flexEntries)
    local primaryText = #primaryNames > 0 and table.concat(primaryNames, " | ") or "Lobby Flex Active"
    local secondaryText = emoteName and ("Emote: " .. emoteName) or "Cosmetics visible in lobby"

    local billboard = Instance.new("BillboardGui")
    billboard.Name = LOBBY_COSMETIC_GUI_NAME
    billboard.Adornee = head
    billboard.AlwaysOnTop = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 80
    billboard.Size = UDim2.fromOffset(240, 56)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
    billboard.Parent = folder

    local primaryLabel = Instance.new("TextLabel")
    primaryLabel.Name = "Primary"
    primaryLabel.BackgroundTransparency = 1
    primaryLabel.Font = Enum.Font.GothamBold
    primaryLabel.TextColor3 = Color3.fromRGB(255, 244, 212)
    primaryLabel.TextScaled = true
    primaryLabel.TextStrokeTransparency = 0.5
    primaryLabel.TextWrapped = true
    primaryLabel.Size = UDim2.new(1, 0, 0.58, 0)
    primaryLabel.Text = primaryText
    primaryLabel.Parent = billboard

    local secondaryLabel = Instance.new("TextLabel")
    secondaryLabel.Name = "Secondary"
    secondaryLabel.BackgroundTransparency = 1
    secondaryLabel.Font = Enum.Font.Gotham
    secondaryLabel.TextColor3 = Color3.fromRGB(196, 232, 255)
    secondaryLabel.TextScaled = true
    secondaryLabel.TextStrokeTransparency = 0.65
    secondaryLabel.TextWrapped = true
    secondaryLabel.Position = UDim2.new(0, 0, 0.58, 0)
    secondaryLabel.Size = UDim2.new(1, 0, 0.42, 0)
    secondaryLabel.Text = secondaryText
    secondaryLabel.Parent = billboard
end

function LobbyService:_applyHeadVisual(folder, character, rarity)
    local head = getCharacterPart(character, { "Head" })
    if not head then
        return
    end

    createWeldedVisual(folder, head, "HeadVisual", {
        size = Vector3.new(1.5, 1.15, 0.18),
        offset = CFrame.new(0, 0, -0.5),
        color = chooseRarityColor(rarity, Color3.fromRGB(214, 224, 255)),
        transparency = 0.1,
        material = Enum.Material.SmoothPlastic,
    })

    createWeldedVisual(folder, head, "HeadSeal", {
        size = Vector3.new(0.55, 0.2, 0.14),
        offset = CFrame.new(0, -0.1, -0.6),
        color = chooseRarityColor(rarity, Color3.fromRGB(255, 244, 212)),
        transparency = 0,
        material = Enum.Material.Neon,
    })
end

function LobbyService:_applyBodyVisual(folder, character, rarity)
    local torso = getCharacterPart(character, { "UpperTorso", "Torso" })
    if not torso then
        return
    end

    createWeldedVisual(folder, torso, "BodyVisual", {
        size = Vector3.new(2.1, 2.35, 0.18),
        offset = CFrame.new(0, 0, -0.6),
        color = chooseRarityColor(rarity, Color3.fromRGB(112, 170, 255)),
        transparency = 0.15,
        material = Enum.Material.Fabric,
    })
end

function LobbyService:_applyOutfitVisual(folder, character, rarity)
    local torso = getCharacterPart(character, { "UpperTorso", "Torso" })
    if not torso then
        return
    end

    createWeldedVisual(folder, torso, "OutfitFront", {
        size = Vector3.new(2.25, 2.7, 0.16),
        offset = CFrame.new(0, -0.05, -0.58),
        color = chooseRarityColor(rarity, Color3.fromRGB(205, 128, 96)),
        transparency = 0.08,
        material = Enum.Material.Fabric,
    })

    createWeldedVisual(folder, torso, "OutfitBack", {
        size = Vector3.new(2, 2.8, 0.14),
        offset = CFrame.new(0, -0.2, 0.56),
        color = chooseRarityColor(rarity, Color3.fromRGB(82, 34, 34)),
        transparency = 0.2,
        material = Enum.Material.Fabric,
    })
end

function LobbyService:_applyAccessoryVisual(folder, character, rarity)
    local anchor = getCharacterPart(character, { "RightHand", "RightLowerArm", "Right Arm", "UpperTorso", "Torso" })
    if not anchor then
        return
    end

    local accessory = createWeldedVisual(folder, anchor, "AccessoryVisual", {
        size = Vector3.new(0.45, 0.45, 0.45),
        offset = CFrame.new(0.45, -0.2, -0.15),
        color = chooseRarityColor(rarity, Color3.fromRGB(255, 221, 145)),
        material = Enum.Material.Neon,
        shape = Enum.PartType.Ball,
    })

    if accessory then
        local charm = createWeldedVisual(folder, accessory, "AccessoryCharm", {
            size = Vector3.new(0.18, 0.6, 0.18),
            offset = CFrame.new(0, -0.45, 0),
            color = Color3.fromRGB(255, 244, 212),
            material = Enum.Material.Metal,
        })
        if charm then
            charm.Shape = Enum.PartType.Cylinder
            charm.CFrame = accessory.CFrame * CFrame.new(0, -0.45, 0) * CFrame.Angles(0, 0, math.rad(90))
        end
    end
end

function LobbyService:_renderLobbyCosmetics(player, character, equippedCosmetics)
    self:_clearCosmeticVisuals(character)

    if not isLobbyCharacter(player, character) then
        return true
    end

    local sanitized = sanitizeEquippedCosmetics(equippedCosmetics)
    if next(sanitized) == nil then
        return true
    end

    local head = getCharacterPart(character, { "Head" })
    local folder = createVisualFolder(character)

    for slot, cosmeticId in pairs(sanitized) do
        local catalogEntry = self._cosmeticCatalogById[cosmeticId]
        local rarity = type(catalogEntry) == "table" and catalogEntry.rarity or nil

        if slot == "head" then
            self:_applyHeadVisual(folder, character, rarity)
        elseif slot == "body" then
            self:_applyBodyVisual(folder, character, rarity)
        elseif slot == "outfit" then
            self:_applyOutfitVisual(folder, character, rarity)
        elseif slot == "accessory" then
            self:_applyAccessoryVisual(folder, character, rarity)
        elseif slot == "emote" then
            character:SetAttribute("LobbyEquippedEmote", humanizeCosmeticId(cosmeticId))
        end
    end

    self:_createBillboard(folder, head, sanitized)
    return true
end

function LobbyService:_ensureCharacterConnection(player)
    local userId = toUserId(player)
    if not userId then
        return
    end

    self:_disconnectCharacterConnection(userId)
    self._characterConnections[userId] = player.CharacterAdded:Connect(function(character)
        task.defer(function()
            task.wait()
            self:_renderLobbyCosmetics(player, character, self:_getAppliedCosmetics(player))
        end)
    end)
end

function LobbyService:_refreshPopulation()
    local playerCount = self._playerManager:GetLobbyPlayerCount()
    self._population:OnLobbyPlayerCountChanged(playerCount)
end

function LobbyService:_clearZoneGuides()
    local zoneParts = self._zoneManager and self._zoneManager:GetZoneParts() or {}
    for _, zonePart in pairs(zoneParts) do
        if typeof(zonePart) == "Instance" and zonePart:IsA("BasePart") then
            local folder = zonePart:FindFirstChild(LOBBY_ZONE_GUIDE_FOLDER_NAME)
            if folder then
                folder:Destroy()
            end
        end
    end
end

function LobbyService:_clearZoneEntryGuides()
    local lobbyRoot = LobbyLocator.ResolveRoot("LobbySocialHub", workspace)
    if not lobbyRoot then
        return
    end

    for _, descendant in ipairs(lobbyRoot:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local folder = descendant:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_FOLDER_NAME)
            if folder then
                folder:Destroy()
            end
        end
    end
end

function LobbyService:_ensureZoneGuide(zoneName, zonePart)
	if typeof(zonePart) ~= "Instance" or not zonePart:IsA("BasePart") or zonePart.Parent == nil then
		return false
	end
    if LOBBY_ZONE_GUIDES_ENABLED ~= true then
        local existingFolder = zonePart:FindFirstChild(LOBBY_ZONE_GUIDE_FOLDER_NAME)
        if existingFolder then
            existingFolder:Destroy()
        end
        return false
	end

	local feedback = LOBBY_ZONE_FEEDBACK[zoneName]
    local style = LOBBY_ZONE_GUIDE_STYLE[zoneName]
    if type(feedback) ~= "table" or type(style) ~= "table" then
        return false
    end

    local titleText = tostring(feedback.title or zoneName):gsub("%.$", "")
    local subtitleText = tostring(style.subtitle or feedback.hint or "")

    local folder = zonePart:FindFirstChild(LOBBY_ZONE_GUIDE_FOLDER_NAME)
    if not (folder and folder:IsA("Folder")) then
        if folder then
            folder:Destroy()
        end
        folder = Instance.new("Folder")
        folder.Name = LOBBY_ZONE_GUIDE_FOLDER_NAME
        folder.Parent = zonePart
    end

    local highlight = folder:FindFirstChild(LOBBY_ZONE_GUIDE_HIGHLIGHT_NAME)
    if not (highlight and highlight:IsA("Highlight")) then
        if highlight then
            highlight:Destroy()
        end
        highlight = Instance.new("Highlight")
        highlight.Name = LOBBY_ZONE_GUIDE_HIGHLIGHT_NAME
        highlight.Parent = folder
    end
    highlight.Adornee = zonePart
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = style.color
    highlight.FillTransparency = 0.92
    highlight.OutlineColor = style.color:Lerp(Color3.fromRGB(255, 255, 255), 0.24)
    highlight.OutlineTransparency = 0.18
    highlight.Enabled = true

    local billboard = folder:FindFirstChild(LOBBY_ZONE_GUIDE_BILLBOARD_NAME)
    if not (billboard and billboard:IsA("BillboardGui")) then
        if billboard then
            billboard:Destroy()
        end
        billboard = Instance.new("BillboardGui")
        billboard.Name = LOBBY_ZONE_GUIDE_BILLBOARD_NAME
        billboard.Parent = folder
    end
    billboard.Active = false
    billboard.Adornee = zonePart
    billboard.AlwaysOnTop = true
    billboard.Brightness = 2
    billboard.ClipsDescendants = false
    billboard.Enabled = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 120
    billboard.ResetOnSpawn = false
    billboard.Size = UDim2.fromOffset(228, 58)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, zonePart.Size.Y * 0.5 + 3.2, 0)

    local panel = billboard:FindFirstChild("Panel")
    if not (panel and panel:IsA("Frame")) then
        if panel then
            panel:Destroy()
        end
        panel = Instance.new("Frame")
        panel.Name = "Panel"
        panel.Parent = billboard

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = panel

        local stroke = Instance.new("UIStroke")
        stroke.Name = "Stroke"
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = style.color
        stroke.Transparency = 0.14
        stroke.Thickness = 1.4
        stroke.Parent = panel

        local accent = Instance.new("Frame")
        accent.Name = "Accent"
        accent.AnchorPoint = Vector2.new(0, 0.5)
        accent.BackgroundColor3 = style.color
        accent.BorderSizePixel = 0
        accent.Position = UDim2.new(0, 10, 0.5, 0)
        accent.Size = UDim2.fromOffset(3, 30)
        accent.Parent = panel

        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(1, 0)
        accentCorner.Parent = accent

        createGuideTextLabel(
            "Title",
            Enum.Font.GothamBold,
            13,
            Color3.fromRGB(245, 248, 252),
            titleText,
            18,
            UDim2.new(0, 20, 0, 6)
        ).Parent = panel

        createGuideTextLabel(
            "Subtitle",
            Enum.Font.GothamMedium,
            11,
            style.color:Lerp(Color3.fromRGB(240, 244, 248), 0.25),
            subtitleText,
            18,
            UDim2.new(0, 20, 0, 24)
        ).Parent = panel
    end

    panel.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
    panel.BackgroundTransparency = 0.12
    panel.BorderSizePixel = 0
    panel.Size = UDim2.fromScale(1, 1)
    return true
end

function LobbyService:_resolveZoneEntryAnchor(zoneName)
    local candidates = LOBBY_ZONE_ENTRY_ANCHORS[zoneName]
    if type(candidates) ~= "table" or #candidates == 0 then
        return nil
    end

    local lobbyRoot = LobbyLocator.ResolveRoot("LobbySocialHub", workspace)
    if not lobbyRoot then
        return nil
    end

    for _, candidateName in ipairs(candidates) do
        local candidate = lobbyRoot:FindFirstChild(candidateName, true)
        if candidate and candidate:IsA("BasePart") then
            return candidate
        end
    end

    return nil
end

function LobbyService:_ensureZoneEntryGuide(zoneName)
    local anchorPart = self:_resolveZoneEntryAnchor(zoneName)
    if not anchorPart then
        return false
    end
    if LOBBY_ZONE_ENTRY_GUIDES_ENABLED ~= true then
        local existingFolder = anchorPart:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_FOLDER_NAME)
        if existingFolder then
            existingFolder:Destroy()
        end
        return false
    end

    local style = LOBBY_ZONE_GUIDE_STYLE[zoneName]
    local copy = LOBBY_ZONE_ENTRY_COPY[zoneName]
    if type(style) ~= "table" or type(copy) ~= "table" then
        return false
    end

    local folder = anchorPart:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_FOLDER_NAME)
    if not (folder and folder:IsA("Folder")) then
        if folder then
            folder:Destroy()
        end
        folder = Instance.new("Folder")
        folder.Name = LOBBY_ZONE_ENTRY_GUIDE_FOLDER_NAME
        folder.Parent = anchorPart
    end

    local highlight = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_HIGHLIGHT_NAME)
    if not (highlight and highlight:IsA("Highlight")) then
        if highlight then
            highlight:Destroy()
        end
        highlight = Instance.new("Highlight")
        highlight.Name = LOBBY_ZONE_ENTRY_GUIDE_HIGHLIGHT_NAME
        highlight.Parent = folder
    end
    highlight.Adornee = anchorPart
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = style.color
    highlight.FillTransparency = 1
    highlight.OutlineColor = style.color
    highlight.OutlineTransparency = 1
    highlight.Enabled = false

    local billboard = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_BILLBOARD_NAME)
    if not (billboard and billboard:IsA("BillboardGui")) then
        if billboard then
            billboard:Destroy()
        end
        billboard = Instance.new("BillboardGui")
        billboard.Name = LOBBY_ZONE_ENTRY_GUIDE_BILLBOARD_NAME
        billboard.Parent = folder
    end
    billboard.Active = false
    billboard.Adornee = anchorPart
    billboard.AlwaysOnTop = true
    billboard.Brightness = 2
    billboard.ClipsDescendants = false
    billboard.Enabled = true
    billboard.LightInfluence = 0
    billboard.MaxDistance = 100
    billboard.ResetOnSpawn = false
    billboard.Size = UDim2.fromOffset(184, type(copy.meta) == "string" and copy.meta ~= "" and 64 or 46)
    billboard.StudsOffsetWorldSpace = Vector3.new(0, anchorPart.Size.Y * 0.5 + 2.8, 0)

    local accentBar = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_ACCENT_NAME)
    if not (accentBar and accentBar:IsA("Part")) then
        if accentBar then
            accentBar:Destroy()
        end
        accentBar = Instance.new("Part")
        accentBar.Name = LOBBY_ZONE_ENTRY_GUIDE_ACCENT_NAME
        accentBar.Anchored = true
        accentBar.CanCollide = false
        accentBar.CanQuery = false
        accentBar.CanTouch = false
        accentBar.CastShadow = false
        accentBar.Locked = true
        accentBar.Material = Enum.Material.Neon
        accentBar.Parent = folder
    end
    accentBar.Color = style.color
    accentBar.Transparency = 0.12
    accentBar.Size = Vector3.new(math.max(anchorPart.Size.X, anchorPart.Size.Z) + 1.6, 0.28, 0.28)
    accentBar.CFrame = anchorPart.CFrame * CFrame.new(0, anchorPart.Size.Y * 0.5 + 0.95, 0)

    local accentLight = accentBar:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_LIGHT_NAME)
    if not (accentLight and accentLight:IsA("PointLight")) then
        if accentLight then
            accentLight:Destroy()
        end
        accentLight = Instance.new("PointLight")
        accentLight.Name = LOBBY_ZONE_ENTRY_GUIDE_LIGHT_NAME
        accentLight.Parent = accentBar
    end
    accentLight.Color = style.color
    accentLight.Brightness = 0.8
    accentLight.Range = 10
    accentLight.Shadows = false

    local doorWidth = math.max(anchorPart.Size.X, anchorPart.Size.Z)
    local frameDepth = math.min(anchorPart.Size.X, anchorPart.Size.Z) + 0.14
    local isWideOnX = anchorPart.Size.X >= anchorPart.Size.Z
    local sideOffset = (doorWidth * 0.5) + 0.42
    local topY = anchorPart.Size.Y * 0.5 + 0.42

    local frameTop = ensureNeonGuidePart(folder, LOBBY_ZONE_ENTRY_GUIDE_FRAME_TOP_NAME)
    local frameLeft = ensureNeonGuidePart(folder, LOBBY_ZONE_ENTRY_GUIDE_FRAME_LEFT_NAME)
    local frameRight = ensureNeonGuidePart(folder, LOBBY_ZONE_ENTRY_GUIDE_FRAME_RIGHT_NAME)
    for _, framePart in ipairs({ frameTop, frameLeft, frameRight }) do
        framePart.Color = style.color
        framePart.Transparency = 0.2
    end

    local headerBand = ensureNeonGuidePart(folder, LOBBY_ZONE_ENTRY_GUIDE_HEADER_NAME)
    headerBand.Color = style.color
    headerBand.Transparency = 0.08

    if isWideOnX then
        frameTop.Size = Vector3.new(anchorPart.Size.X + 0.9, 0.18, frameDepth)
        frameTop.CFrame = anchorPart.CFrame * CFrame.new(0, topY, 0)
        frameLeft.Size = Vector3.new(0.18, anchorPart.Size.Y + 0.2, frameDepth)
        frameLeft.CFrame = anchorPart.CFrame * CFrame.new(-sideOffset, 0, 0)
        frameRight.Size = Vector3.new(0.18, anchorPart.Size.Y + 0.2, frameDepth)
        frameRight.CFrame = anchorPart.CFrame * CFrame.new(sideOffset, 0, 0)
        headerBand.Size = Vector3.new(anchorPart.Size.X + 2.2, 1.55, frameDepth + 0.12)
        headerBand.CFrame = anchorPart.CFrame * CFrame.new(0, topY - 0.48, 0)
    else
        frameTop.Size = Vector3.new(frameDepth, 0.18, anchorPart.Size.Z + 0.9)
        frameTop.CFrame = anchorPart.CFrame * CFrame.new(0, topY, 0)
        frameLeft.Size = Vector3.new(frameDepth, anchorPart.Size.Y + 0.2, 0.18)
        frameLeft.CFrame = anchorPart.CFrame * CFrame.new(0, 0, -sideOffset)
        frameRight.Size = Vector3.new(frameDepth, anchorPart.Size.Y + 0.2, 0.18)
        frameRight.CFrame = anchorPart.CFrame * CFrame.new(0, 0, sideOffset)
        headerBand.Size = Vector3.new(frameDepth + 0.12, 1.55, anchorPart.Size.Z + 2.2)
        headerBand.CFrame = anchorPart.CFrame * CFrame.new(0, topY - 0.48, 0)
    end

    local contractBoard = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_BOARD_NAME)
    local toolsBoard = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_TOOLS_BOARD_NAME)
    local contractStand = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_STAND_NAME)
    local toolsStand = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_TOOLS_STAND_NAME)
    local contractBase = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_BASE_NAME)
    local toolsBase = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_TOOLS_BASE_NAME)
    local facadeCanopy = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_CANOPY_NAME)
    local facadeApron = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_APRON_NAME)
    local facadeWingLeft = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_WING_LEFT_NAME)
    local facadeWingRight = folder:FindFirstChild(LOBBY_ZONE_ENTRY_GUIDE_WING_RIGHT_NAME)
    if zoneName == "MatchmakingZone" then
        contractBoard = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_BOARD_NAME)
        toolsBoard = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_TOOLS_BOARD_NAME)
        contractStand = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_STAND_NAME)
        toolsStand = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_TOOLS_STAND_NAME)
        contractBase = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CONTRACT_BASE_NAME)
        toolsBase = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_TOOLS_BASE_NAME)
        facadeCanopy = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_CANOPY_NAME)
        facadeApron = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_APRON_NAME)
        facadeWingLeft = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_WING_LEFT_NAME)
        facadeWingRight = ensureGuidePanelPart(folder, LOBBY_ZONE_ENTRY_GUIDE_WING_RIGHT_NAME)
        for _, board in ipairs({ contractBoard, toolsBoard }) do
            board.Color = Color3.fromRGB(18, 26, 38)
            board.Transparency = 0.08
        end
        for _, standPart in ipairs({ contractStand, toolsStand }) do
            standPart.Color = Color3.fromRGB(26, 34, 48)
            standPart.Transparency = 0.04
            standPart.Material = Enum.Material.Metal
        end
        for _, basePart in ipairs({ contractBase, toolsBase }) do
            basePart.Color = Color3.fromRGB(38, 48, 64)
            basePart.Transparency = 0.02
            basePart.Material = Enum.Material.Slate
        end
        for _, facadePart in ipairs({ facadeCanopy, facadeApron, facadeWingLeft, facadeWingRight }) do
            facadePart.Color = Color3.fromRGB(24, 32, 46)
            facadePart.Transparency = 0.02
        end
        facadeCanopy.Material = Enum.Material.Metal
        facadeApron.Material = Enum.Material.Slate
        facadeWingLeft.Material = Enum.Material.SmoothPlastic
        facadeWingRight.Material = Enum.Material.SmoothPlastic
        if isWideOnX then
            contractBoard.Size = Vector3.new(4.4, 3.4, frameDepth + 0.06)
            contractBoard.CFrame = anchorPart.CFrame * CFrame.new(-sideOffset - 3.2, 0.2, 0)
            toolsBoard.Size = Vector3.new(4.4, 3.4, frameDepth + 0.06)
            toolsBoard.CFrame = anchorPart.CFrame * CFrame.new(sideOffset + 3.2, 0.2, 0)
            contractStand.Size = Vector3.new(0.48, 2.3, 0.48)
            contractStand.CFrame = contractBoard.CFrame * CFrame.new(0, -2.75, 0)
            toolsStand.Size = Vector3.new(0.48, 2.3, 0.48)
            toolsStand.CFrame = toolsBoard.CFrame * CFrame.new(0, -2.75, 0)
            contractBase.Size = Vector3.new(2.4, 0.28, 1.8)
            contractBase.CFrame = contractStand.CFrame * CFrame.new(0, -1.28, 0.15)
            toolsBase.Size = Vector3.new(2.4, 0.28, 1.8)
            toolsBase.CFrame = toolsStand.CFrame * CFrame.new(0, -1.28, 0.15)
            facadeCanopy.Size = Vector3.new(anchorPart.Size.X + 6.8, 0.62, 3.8)
            facadeCanopy.CFrame = anchorPart.CFrame * CFrame.new(0, topY - 0.1, 1.9)
            facadeApron.Size = Vector3.new(anchorPart.Size.X + 9.4, 0.28, 8.8)
            facadeApron.CFrame = anchorPart.CFrame * CFrame.new(0, (-anchorPart.Size.Y * 0.5) + 0.15, 4.2)
            facadeWingLeft.Size = Vector3.new(1.25, anchorPart.Size.Y + 1.2, 3.2)
            facadeWingLeft.CFrame = anchorPart.CFrame * CFrame.new(-sideOffset - 1.7, 0, 1.55)
            facadeWingRight.Size = Vector3.new(1.25, anchorPart.Size.Y + 1.2, 3.2)
            facadeWingRight.CFrame = anchorPart.CFrame * CFrame.new(sideOffset + 1.7, 0, 1.55)
        else
            contractBoard.Size = Vector3.new(frameDepth + 0.06, 3.4, 4.4)
            contractBoard.CFrame = anchorPart.CFrame * CFrame.new(0, 0.2, -sideOffset - 3.2)
            toolsBoard.Size = Vector3.new(frameDepth + 0.06, 3.4, 4.4)
            toolsBoard.CFrame = anchorPart.CFrame * CFrame.new(0, 0.2, sideOffset + 3.2)
            contractStand.Size = Vector3.new(0.48, 2.3, 0.48)
            contractStand.CFrame = contractBoard.CFrame * CFrame.new(0, -2.75, 0)
            toolsStand.Size = Vector3.new(0.48, 2.3, 0.48)
            toolsStand.CFrame = toolsBoard.CFrame * CFrame.new(0, -2.75, 0)
            contractBase.Size = Vector3.new(1.8, 0.28, 2.4)
            contractBase.CFrame = contractStand.CFrame * CFrame.new(0.15, -1.28, 0)
            toolsBase.Size = Vector3.new(1.8, 0.28, 2.4)
            toolsBase.CFrame = toolsStand.CFrame * CFrame.new(0.15, -1.28, 0)
            facadeCanopy.Size = Vector3.new(3.8, 0.62, anchorPart.Size.Z + 6.8)
            facadeCanopy.CFrame = anchorPart.CFrame * CFrame.new(1.9, topY - 0.1, 0)
            facadeApron.Size = Vector3.new(8.8, 0.28, anchorPart.Size.Z + 9.4)
            facadeApron.CFrame = anchorPart.CFrame * CFrame.new(4.2, (-anchorPart.Size.Y * 0.5) + 0.15, 0)
            facadeWingLeft.Size = Vector3.new(3.2, anchorPart.Size.Y + 1.2, 1.25)
            facadeWingLeft.CFrame = anchorPart.CFrame * CFrame.new(1.55, 0, -sideOffset - 1.7)
            facadeWingRight.Size = Vector3.new(3.2, anchorPart.Size.Y + 1.2, 1.25)
            facadeWingRight.CFrame = anchorPart.CFrame * CFrame.new(1.55, 0, sideOffset + 1.7)
        end
        ensureGuideBoardBillboard(contractBoard, "CONTRACT", "Room • Mode • Start", style.color)
        ensureGuideBoardBillboard(toolsBoard, "TOOLS", "EMF • UV • BOX", style.color)
    else
        if contractBoard then
            contractBoard:Destroy()
        end
        if toolsBoard then
            toolsBoard:Destroy()
        end
        if contractStand then
            contractStand:Destroy()
        end
        if toolsStand then
            toolsStand:Destroy()
        end
        if contractBase then
            contractBase:Destroy()
        end
        if toolsBase then
            toolsBase:Destroy()
        end
        if facadeCanopy then
            facadeCanopy:Destroy()
        end
        if facadeApron then
            facadeApron:Destroy()
        end
        if facadeWingLeft then
            facadeWingLeft:Destroy()
        end
        if facadeWingRight then
            facadeWingRight:Destroy()
        end
    end

    local panel = billboard:FindFirstChild("Panel")
    if not (panel and panel:IsA("Frame")) then
        if panel then
            panel:Destroy()
        end
        panel = Instance.new("Frame")
        panel.Name = "Panel"
        panel.Parent = billboard

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = panel

        local stroke = Instance.new("UIStroke")
        stroke.Name = "Stroke"
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Color = style.color
        stroke.Transparency = 0.18
        stroke.Thickness = 1.2
        stroke.Parent = panel

        local accent = Instance.new("Frame")
        accent.Name = "Accent"
        accent.AnchorPoint = Vector2.new(0, 0.5)
        accent.BackgroundColor3 = style.color
        accent.BorderSizePixel = 0
        accent.Position = UDim2.new(0, 10, 0.5, 0)
        accent.Size = UDim2.fromOffset(3, 24)
        accent.Parent = panel

        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(1, 0)
        accentCorner.Parent = accent

        createGuideTextLabel(
            "Title",
            Enum.Font.GothamBold,
            13,
            Color3.fromRGB(245, 248, 252),
            copy.title,
            18,
            UDim2.new(0, 20, 0, 6)
        ).Parent = panel

        createGuideTextLabel(
            "Subtitle",
            Enum.Font.GothamMedium,
            10,
            style.color:Lerp(Color3.fromRGB(240, 244, 248), 0.25),
            copy.subtitle,
            16,
            UDim2.new(0, 20, 0, 23)
        ).Parent = panel

        if type(copy.meta) == "string" and copy.meta ~= "" then
            createGuideTextLabel(
                "Meta",
                Enum.Font.GothamBold,
                9,
                style.color:Lerp(Color3.fromRGB(255, 255, 255), 0.45),
                copy.meta,
                14,
                UDim2.new(0, 20, 0, 39)
            ).Parent = panel
        end
    end

    panel.BackgroundColor3 = Color3.fromRGB(12, 18, 28)
    panel.BackgroundTransparency = 0.14
    panel.BorderSizePixel = 0
    panel.Size = UDim2.fromScale(1, 1)
    return true
end

function LobbyService:_syncZoneGuides()
    self:_clearZoneGuides()
    self:_clearZoneEntryGuides()
    if LOBBY_ZONE_GUIDES_ENABLED ~= true and LOBBY_ZONE_ENTRY_GUIDES_ENABLED ~= true then
        return
    end
    local zoneParts = self._zoneManager and self._zoneManager:GetZoneParts() or {}
    for zoneName, zonePart in pairs(zoneParts) do
        if LOBBY_ZONE_GUIDES_ENABLED == true then
            self:_ensureZoneGuide(zoneName, zonePart)
        end
        if LOBBY_ZONE_ENTRY_GUIDES_ENABLED == true then
            self:_ensureZoneEntryGuide(zoneName)
        end
    end
end

function LobbyService:Init()
    self._state:Set("lobbyStatus", "initialized")
    self._dependencies.PlayerProfileSystem = Services.Get(self._deps, "PlayerProfileSystem")
    self._state:Set("flexZoneState", self:_getFlexState())
    self:_loadCosmeticCatalog()
    self._playerManager:Init()
    self._zoneManager:Init()
    self._interaction:Init()
    self._partySystem:Init()
    self._population:Init()

    self._zoneManager:SetZoneEnteredCallback(function(player, zoneName)
        self:OnPlayerEnteredZone(player, zoneName)
    end)
    self._partySystem:SetCallbacks({
        onPlayerJoinedParty = function(player, party)
            self:_publish("PlayerJoinedParty", {
                player = player,
                partyId = party.partyId,
                leader = party.leader,
                members = party.members,
            })
        end,
    })
end

function LobbyService:Start()
    self._state:Set("lobbyStatus", "running")
    self._playerManager:Start()
    self._zoneManager:Start()
    sanitizeLobbyLogicVolumes()
    applyMainHubVisualPatch()
    self:_syncZoneGuides()
    self._interaction:Start()
    self._partySystem:Start()
    self._population:Start()
end

function LobbyService:Stop()
    self._state:Set("lobbyStatus", "stopped")
    self:_clearZoneGuides()
    self:_clearZoneEntryGuides()
    self._zoneManager:Stop()
    self._interaction:Stop()
    self._partySystem:Stop()
    self._playerManager:Stop()
    self._population:Stop()
    self._state:Set("flexZoneState", {
        participantsByUserId = {},
        rotationOrder = {},
        spotlightUserId = nil,
    })

    for userId in pairs(self._characterConnections) do
        self:_disconnectCharacterConnection(userId)
    end
end

function LobbyService:RegisterPlayer(player)
    local alreadyInLobby = self._playerManager:IsInLobby(player)
    local ok, reason = self._playerManager:RegisterPlayer(player)
    if not ok then
        return false, reason
    end
    if alreadyInLobby then
        return true
    end

    self:_ensureCharacterConnection(player)
    self:_publish("PlayerEnteredLobby", {
        player = player,
    })
    local flexState = self:_getFlexState()
    if type(flexState.lastPayload) == "table" and type(flexState.lastPayload.eventName) == "string" then
        local replayPayload = cloneMap(flexState.lastPayload)
        replayPayload.recipients = { player }
        self:_publish(replayPayload.eventName, replayPayload)
    end
    self:_refreshPopulation()
    task.defer(function()
        self:_renderLobbyCosmetics(player, player.Character, self:_getAppliedCosmetics(player))
    end)
    return true
end

function LobbyService:RemovePlayer(player)
    if not self._playerManager:IsInLobby(player) then
        return true
    end

    local ok, reason = self._playerManager:RemovePlayer(player)
    if not ok then
        return false, reason
    end

    self:_disconnectCharacterConnection(player.UserId)
    self:_clearCosmeticVisuals(player.Character)
    self:_removeFlexParticipant(player)
    self._partySystem:LeaveParty(player)
    self:_refreshPopulation()
    return true
end

function LobbyService:GetLobbyPlayers()
    return self._playerManager:GetLobbyPlayers()
end

function LobbyService:CreateParty(player)
    return self._partySystem:CreateParty(player)
end

function LobbyService:InvitePlayer(partyId, player)
    return self._partySystem:InvitePlayer(partyId, player)
end

function LobbyService:DisbandParty(partyId)
    return self._partySystem:DisbandParty(partyId)
end

function LobbyService:PrepareGroupMatchmaking(player)
    return self._partySystem:PrepareGroupMatchmaking(player)
end

function LobbyService:StartMatchmaking(player, payload)
    local matchmakingPackage, reason = self._partySystem:PrepareGroupMatchmaking(player)
    if not matchmakingPackage then
        return false, reason
    end

    self:_publish("MatchmakingStarted", {
        partyId = matchmakingPackage.partyId,
        leader = matchmakingPackage.leader,
        players = matchmakingPackage.players,
        queueType = matchmakingPackage.queueType,
        mapId = payload and payload.mapId or nil,
        difficulty = payload and payload.difficulty or nil,
        mode = payload and (payload.mode or payload.gameMode) or "Classic",
        gameMode = payload and (payload.gameMode or payload.mode) or "Classic",
        averageRankScore = payload and payload.averageRankScore or nil,
        playerRankScores = payload and payload.playerRankScores or nil,
        rankedDifficulty = payload and payload.rankedDifficulty or nil,
    })
    return true
end

function LobbyService:OnPlayerEnteredZone(player, zoneName)
    if not self._playerManager:IsInLobby(player) then
        return
    end

    self._interaction:HandleZoneEntry(player, zoneName)
    local zoneFeedback = LOBBY_ZONE_FEEDBACK[zoneName]
    local zoneStyle = LOBBY_ZONE_GUIDE_STYLE[zoneName]
    local zoneEntryCopy = LOBBY_ZONE_ENTRY_COPY[zoneName]
    if type(zoneFeedback) == "table" then
        self:_publish("LobbyZoneFocused", {
            eventName = "LobbyZoneFocused",
            zoneName = zoneName,
            title = zoneFeedback.title,
            hint = zoneFeedback.hint,
            badge = type(zoneEntryCopy) == "table" and zoneEntryCopy.title or zoneName,
            subtitle = type(zoneStyle) == "table" and zoneStyle.subtitle or "",
            accentColor = type(zoneStyle) == "table" and zoneStyle.color or nil,
            recipients = { player },
        })
    end

    if zoneName == "FlexZone" then
        self:_activateFlexSpotlight(player, "zone_entered")
    end
end

function LobbyService:HandlePlayerTeleported(payload)
    local player = payload and payload.player
    local mapId = payload and payload.mapId
    if not player then
        return
    end

    if mapId == "Lobby" then
        self:RegisterPlayer(player)
    else
        self:RemovePlayer(player)
    end
end

function LobbyService:ApplyCosmetics(player, equippedCosmetics)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end

    local snapshot = self:_setAppliedCosmetics(player, equippedCosmetics)
    self:_renderLobbyCosmetics(player, player.Character, snapshot)

    self:_publish("LobbyCosmeticApplied", {
        player = player,
        userId = userId,
        equipped = snapshot,
    })
    self:_refreshFlexParticipant(player, "cosmetics_updated")
    return true
end

function LobbyService:ApplyCosmetic(player, cosmeticId, category)
    local slot = category
    if (type(slot) ~= "string" or slot == "") and type(cosmeticId) == "string" then
        local catalogEntry = self._cosmeticCatalogById[cosmeticId]
        slot = type(catalogEntry) == "table" and catalogEntry.slot or nil
    end
    if type(slot) ~= "string" or slot == "" then
        return false, "invalid_slot"
    end

    local equipped = self:_getAppliedCosmetics(player)
    if type(cosmeticId) == "string" and cosmeticId ~= "" then
        equipped[slot] = cosmeticId
    else
        equipped[slot] = nil
    end

    return self:ApplyCosmetics(player, equipped)
end

return LobbyService


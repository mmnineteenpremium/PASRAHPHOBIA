-- SecurityValidator.lua
-- PASRAHPHOBIA anti-exploit foundation
-- Use this in every OnServerEvent / OnServerInvoke handler

local SecurityValidator = {}

local LIMITS = {
    -- Canonical movement is 10 walk / 14 sprint / 32 jump power.
    -- Clamp slightly above runtime targets to avoid false positives while
    -- still keeping the server authoritative.
    MAX_WALK_SPEED = 16,
    MAX_JUMP_POWER = 32,
    MAX_PURCHASE_PER_MIN = 10,
    MAX_REMOTE_PER_SEC = 20,
    VALID_ITEM_IDS = {},
    VALID_TOOL_IDS = {
        "Senter",
        "Detektor MEDOK",
        "DetektorMEDOK",
        "Termometer Suhu",
        "TermometerSuhu",
        "Kotak Suara",
        "KotakSuara",
        "Kamera To'un",
        "KameraToUn",
        "Buku Terkutuk Kosong",
        "BukuTerkutukKosong",
        "Sensor Pengganggu",
        "SensorPengganggu",
        "Garam",
        "Salib",
        "Dupa",
        -- Runtime aliases used by the current evidence gateway.
        "JejakEnergi",
        "KotakArwah",
        "SuhuMembeku",
        "BukuTerkutuk",
        "BolaArwah",
        "GerakanGaib",
        "PilSanity",
    },
}

SecurityValidator.LIMITS = LIMITS

local _rateLimits = {}
local _validToolLookup = {}

local function normalizeToken(value)
    if type(value) ~= "string" then
        return nil
    end

    return value:lower():gsub("[%s%p_]+", "")
end

for _, toolId in ipairs(LIMITS.VALID_TOOL_IDS) do
    local normalized = normalizeToken(toolId)
    if normalized then
        _validToolLookup[normalized] = true
    end
end

local function getRateKey(player, category)
    return string.format("%s_%s", tostring(player and player.UserId or "unknown"), tostring(category))
end

function SecurityValidator:CheckRateLimit(player, category, maxPerWindow, windowSeconds)
    assert(type(category) == "string" and category ~= "", "SecurityValidator:CheckRateLimit - category must be a non-empty string")

    local allowedEvents = math.max(1, math.floor(tonumber(maxPerWindow) or LIMITS.MAX_REMOTE_PER_SEC))
    local window = math.max(0.05, tonumber(windowSeconds) or 1)
    local key = getRateKey(player, category)
    local now = os.clock()

    if not _rateLimits[key] then
        _rateLimits[key] = {
            count = 0,
            windowStart = now,
        }
    end

    local rateLimit = _rateLimits[key]
    if (now - rateLimit.windowStart) > window then
        rateLimit.count = 0
        rateLimit.windowStart = now
    end

    rateLimit.count += 1

    if rateLimit.count > allowedEvents then
        warn(string.format("[SecurityValidator] RATE LIMIT EXCEEDED: player=%s category=%s count=%d", tostring(player and player.Name or "unknown"), category, rateLimit.count))
        return false
    end

    return true
end

function SecurityValidator:ValidatePlayer(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return false, "invalid player instance"
    end
    if not player.Parent then
        return false, "player not in game"
    end
    if not player.Character then
        return false, "missing character"
    end
    if not player.Character:FindFirstChild("HumanoidRootPart") then
        return false, "missing HumanoidRootPart"
    end
    return true, "ok"
end

function SecurityValidator:ValidateToolId(toolId)
    local normalized = normalizeToken(toolId)
    if normalized and _validToolLookup[normalized] == true then
        return true
    end

    warn(string.format("[SecurityValidator] Invalid toolId: %s", tostring(toolId)))
    return false
end

function SecurityValidator:ValidateAndSetSpeed(player, requestedSpeed)
    local validPlayer, reason = self:ValidatePlayer(player)
    if not validPlayer then
        return nil, reason
    end

    local safeSpeed = math.clamp(tonumber(requestedSpeed) or 10, 0, LIMITS.MAX_WALK_SPEED)
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = safeSpeed
    end
    return safeSpeed
end

function SecurityValidator:RegisterValidItems(itemTable)
    if type(itemTable) ~= "table" then
        return
    end

    for key, value in pairs(itemTable) do
        local itemId = nil

        if type(value) == "string" then
            itemId = value
        elseif type(value) == "table" then
            itemId = value.id or value.itemId
        elseif type(key) == "string" and value == true then
            itemId = key
        end

        if type(itemId) == "string" and itemId ~= "" then
            LIMITS.VALID_ITEM_IDS[itemId] = true
        end
    end
end

function SecurityValidator:ValidatePurchase(player, itemId, serverPriceDB)
    local validPlayer = self:ValidatePlayer(player)
    if not validPlayer then
        return false, nil
    end

    if type(serverPriceDB) ~= "table" then
        warn("[SecurityValidator] serverPriceDB missing or invalid")
        return false, nil
    end

    local itemKey = tostring(itemId)
    local itemData = serverPriceDB[itemKey]
    if not itemData then
        warn(string.format("[SecurityValidator] Invalid purchase attempt: player=%s itemId=%s", player.Name, itemKey))
        return false, nil
    end

    if not self:CheckRateLimit(player, "purchase", LIMITS.MAX_PURCHASE_PER_MIN, 60) then
        return false, nil
    end

    return true, itemData
end

function SecurityValidator:ValidateRemote(player, category, maxPerWindow, windowSeconds)
    local validPlayer, reason = self:ValidatePlayer(player)
    if not validPlayer then
        return false, reason
    end

    if not self:CheckRateLimit(player, category, maxPerWindow, windowSeconds) then
        return false, "rate_limit_exceeded"
    end

    return true, "ok"
end

function SecurityValidator:CleanupPlayer(player)
    if not player or type(player.UserId) ~= "number" then
        return
    end

    local prefix = string.format("%d_", player.UserId)
    for key in pairs(_rateLimits) do
        if key:sub(1, #prefix) == prefix then
            _rateLimits[key] = nil
        end
    end
end

function SecurityValidator:CleanupAll()
    table.clear(_rateLimits)
end

return SecurityValidator

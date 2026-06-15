local AudioErrorGuard = {}

local PLACEHOLDER_TOKEN = "YOUR_NEW_SOUND"
local SANITIZED_ATTRIBUTE = "PasrahAudioSanitized"
local BROKEN_IDS = {
    ["412892754"] = true,
    ["188608071"] = true,
    ["3225480278"] = true,
    ["510111269"] = true,
    ["1013366831"] = true,
    -- Kuntilanak SFX uploaded ID returns 403 in Studio; use the routed fallback asset instead.
    ["118652624478186"] = true,
}

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function extractAssetId(soundId)
    if type(soundId) ~= "string" then
        return nil
    end
    local raw = trim(soundId)
    local prefix = "rbxassetid://"
    if raw:sub(1, #prefix) ~= prefix then
        return nil
    end
    return raw:sub(#prefix + 1)
end

local function isInvalidSoundId(soundId)
    if type(soundId) ~= "string" then
        return true
    end
    local raw = trim(soundId)
    if raw == "" then
        return true
    end
    if string.find(string.upper(raw), PLACEHOLDER_TOKEN, 1, true) then
        return true
    end
    local assetId = extractAssetId(raw)
    if assetId and BROKEN_IDS[assetId] then
        return true
    end
    return false
end

local function disableSound(sound)
    warn("[AUDIO GUARD] Broken sound detected")
    warn(string.format("[AUDIO GUARD] Disabled: %s", sound:GetFullName()))
    sound.SoundId = ""
    sound:Stop()
    sound:SetAttribute(SANITIZED_ATTRIBUTE, true)
end

local function isIntentionalSourcePlaceholder(sound)
    local replicatedStorage = game:FindFirstChild("ReplicatedStorage")
    if not replicatedStorage then
        return false
    end
    local assets = replicatedStorage:FindFirstChild("Assets")
    local audio = assets and assets:FindFirstChild("Audio")
    if not audio then
        return false
    end
    return sound:IsDescendantOf(audio) and sound.SoundId == ""
end

function AudioErrorGuard.Scan()
    local contentProvider = game:GetService("ContentProvider")
    for _, instance in ipairs(game:GetDescendants()) do
        if instance:IsA("Sound") then
            if instance:GetAttribute(SANITIZED_ATTRIBUTE) == true then
                continue
            end
            if isIntentionalSourcePlaceholder(instance) then
                continue
            end
            if isInvalidSoundId(instance.SoundId) then
                disableSound(instance)
            else
                local ok = pcall(function()
                    contentProvider:PreloadAsync({ instance })
                end)
                if not ok then
                    disableSound(instance)
                end
            end
        end
    end
end

return AudioErrorGuard

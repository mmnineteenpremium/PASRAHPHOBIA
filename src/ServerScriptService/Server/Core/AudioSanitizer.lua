local AudioSanitizer = {}

local PLACEHOLDER_TOKEN = "YOUR_NEW_SOUND"
local SANITIZED_ATTRIBUTE = "PasrahAudioSanitized"
local BROKEN_IDS = {
    ["1234567890"] = true,
    ["9125962736"] = true,
    ["1837467338"] = true,
    ["1843529608"] = true,
    ["9125710681"] = true,
    ["1837829568"] = true,
    -- Documented map audio 403s from the owner visual checklist.
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

local function isAllowedBuiltInSoundId(soundId)
    return soundId:sub(1, #"rbxasset://sounds/") == "rbxasset://sounds/"
end

local function shouldReplace(soundId)
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

    if isAllowedBuiltInSoundId(raw) then
        return false
    end

    local prefix = "rbxassetid://"
    if raw:sub(1, #prefix) ~= prefix then
        return true
    end

    local assetId = raw:sub(#prefix + 1)
    if BROKEN_IDS[assetId] then
        return true
    end

    return false
end

local function disableSound(sound)
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

local function summarizeInvalidSounds(invalidPaths)
    if #invalidPaths == 0 then
        return
    end

    table.sort(invalidPaths)
    local preview = {}
    local previewCount = math.min(#invalidPaths, 6)
    for index = 1, previewCount do
        table.insert(preview, invalidPaths[index])
    end

    warn(string.format("[AUDIO SANITIZER] Disabled %d invalid sounds", #invalidPaths))
    warn(table.concat(preview, "\n"))
    if #invalidPaths > previewCount then
        warn(string.format("[AUDIO SANITIZER] ... and %d more", #invalidPaths - previewCount))
    end
end

function AudioSanitizer.Scan()
    local invalidPaths = {}
    for _, instance in ipairs(game:GetDescendants()) do
        if instance:IsA("Sound") then
            if instance:GetAttribute(SANITIZED_ATTRIBUTE) == true then
                continue
            end
            if isIntentionalSourcePlaceholder(instance) then
                continue
            end
            if shouldReplace(instance.SoundId) then
                table.insert(invalidPaths, instance:GetFullName())
                disableSound(instance)
            end
        end
    end
    summarizeInvalidSounds(invalidPaths)
end

return AudioSanitizer

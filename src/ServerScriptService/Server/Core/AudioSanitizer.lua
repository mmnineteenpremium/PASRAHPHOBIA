local AudioSanitizer = {}

local VALID_SOUND_ID = "rbxassetid://10576163165"
local PLACEHOLDER_TOKEN = "YOUR_NEW_SOUND"
local BROKEN_IDS = {
    ["1234567890"] = true,
    ["9125962736"] = true,
    ["1837467338"] = true,
    ["1843529608"] = true,
    ["9125710681"] = true,
    ["1837829568"] = true,
}

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
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

local function replaceSound(sound)
    sound.SoundId = VALID_SOUND_ID
    print("[AUDIO SANITIZER] Replaced sound")
    print(sound:GetFullName())
end

function AudioSanitizer.Scan()
    for _, instance in ipairs(game:GetDescendants()) do
        if instance:IsA("Sound") then
            if shouldReplace(instance.SoundId) then
                replaceSound(instance)
            end
        end
    end
end

return AudioSanitizer

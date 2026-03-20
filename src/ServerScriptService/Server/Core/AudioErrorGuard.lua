local AudioErrorGuard = {}

local PLACEHOLDER_TOKEN = "YOUR_NEW_SOUND"

local function isInvalidSoundId(soundId)
    if type(soundId) ~= "string" then
        return true
    end
    if soundId == "" or soundId:match("^%s*$") then
        return true
    end
    if string.find(string.upper(soundId), PLACEHOLDER_TOKEN, 1, true) then
        return true
    end
    return false
end

local function disableSound(sound)
    warn("[AUDIO GUARD] Broken sound detected")
    warn(string.format("[AUDIO GUARD] Disabled: %s", sound:GetFullName()))
    sound.SoundId = ""
    sound:Stop()
end

function AudioErrorGuard.Scan()
    local contentProvider = game:GetService("ContentProvider")
    for _, instance in ipairs(game:GetDescendants()) do
        if instance:IsA("Sound") then
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

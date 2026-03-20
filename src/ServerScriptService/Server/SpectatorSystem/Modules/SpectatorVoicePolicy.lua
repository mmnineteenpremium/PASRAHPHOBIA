local SpectatorVoicePolicy = {}
SpectatorVoicePolicy.__index = SpectatorVoicePolicy

function SpectatorVoicePolicy.new(config)
    local self = setmetatable({}, SpectatorVoicePolicy)
    self._config = config or {
        voiceChannel = "RobloxVoice",
        allowSpectatorToLiving = true,
        allowTextHintToLiving = false,
    }
    return self
end

function SpectatorVoicePolicy:GetPolicy()
    return {
        voiceChannel = self._config.voiceChannel,
        allowSpectatorToLiving = self._config.allowSpectatorToLiving == true,
        allowTextHintToLiving = self._config.allowTextHintToLiving == true,
    }
end

function SpectatorVoicePolicy:CanSendHintToLiving()
    return self._config.allowTextHintToLiving == true
end

return SpectatorVoicePolicy

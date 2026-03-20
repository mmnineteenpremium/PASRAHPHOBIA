local RewardPayload = {}

function RewardPayload.BuildId(userId, kind, context)
    if type(userId) ~= "number" then
        return nil
    end
    local contextTable = type(context) == "table" and context or {}
    local suffix = contextTable.matchId
        or contextTable.contractId
        or contextTable.missionId
        or contextTable.day
        or contextTable.date
        or "generic"
    local category = kind or "reward"
    return string.format("%s:%s:%s", tostring(category), tostring(suffix), tostring(userId))
end

function RewardPayload.Apply(payload, opts)
    if type(payload) ~= "table" then
        return payload
    end
    opts = opts or {}
    if opts.sourceSystem and not payload.sourceSystem then
        payload.sourceSystem = opts.sourceSystem
    end
    if opts.rewardId and not payload.rewardId then
        payload.rewardId = opts.rewardId
    end

    local defaults = {
        cash = 0,
        xp = 0,
        evidenceBonus = 0,
        survivalBonus = 0,
        difficultyMultiplier = 0,
        contractBonus = 0,
    }
    for key, value in pairs(defaults) do
        if payload[key] == nil then
            payload[key] = value
        end
    end

    return payload
end

return RewardPayload

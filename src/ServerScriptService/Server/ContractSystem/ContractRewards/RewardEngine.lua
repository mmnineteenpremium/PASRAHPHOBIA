local RewardEngine = {}
RewardEngine.__index = RewardEngine

local function toResultPlayers(payload)
    local players = {}
    local seen = {}
    local results = payload and payload.results or {}

    for _, entry in ipairs(results.playerResults or {}) do
        local player = entry.player
        local userId = entry.userId or (player and player.UserId)
        if userId and not seen[userId] then
            seen[userId] = true
            table.insert(players, { player = player, userId = userId })
        end
    end

    return players
end

local function toCosmeticDropId(rng)
    return string.format("ContractDrop_%d", rng:NextInteger(1000, 99999))
end

function RewardEngine.new(deps, rng)
    local self = setmetatable({}, RewardEngine)
    self._deps = deps or {}
    self._rng = rng or Random.new()
    return self
end

function RewardEngine:Grant(contract, matchPayload, systems)
    local reward = (contract and contract.reward) or {}
    local players = toResultPlayers(matchPayload)
    local grants = {}

    for _, entry in ipairs(players) do
        local player = entry.player or entry.userId
        local userId = entry.userId
        local granted = {
            currency = {
                type = reward.currency or "MM",
                amount = math.floor(tonumber(reward.amount) or 0),
            },
            experience = math.floor(tonumber(reward.experience) or 0),
            rankProgress = math.floor(tonumber(reward.rankProgress) or 0),
            cosmeticDrop = nil,
        }

        if systems and systems.economy and granted.currency.amount > 0 then
            systems.economy:AddCurrency(player, granted.currency.type, granted.currency.amount, "contract_completed")
        end
        if systems and systems.profile and granted.experience > 0 then
            systems.profile:AddExperience(player, granted.experience)
        end
        if systems and systems.ranked and granted.rankProgress > 0 then
            for _ = 1, granted.rankProgress do
                systems.ranked:AddStar(player)
            end
        end

        local dropChance = tonumber(reward.cosmeticDropChance) or 0
        if dropChance > 0 and self._rng:NextNumber() <= dropChance then
            granted.cosmeticDrop = {
                rewardType = "CosmeticDrop",
                dropId = toCosmeticDropId(self._rng),
            }
        end

        table.insert(grants, {
            player = entry.player,
            userId = userId,
            reward = granted,
        })
    end

    return grants
end

return RewardEngine

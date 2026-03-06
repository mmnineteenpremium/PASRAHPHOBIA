local ContractRewards = {}
ContractRewards.__index = ContractRewards

function ContractRewards.new(deps)
    local self = setmetatable({}, ContractRewards)
    self._deps = deps or {}
    self._rewardDefaults = self._deps.ContractRewardTypes or {
        MM = 1000,
        EXP = 250,
    }
    return self
end

function ContractRewards:BuildReward(contract)
    local reward = contract and contract.reward or {}
    return {
        MM = reward.MM or self._rewardDefaults.MM,
        EXP = reward.EXP or self._rewardDefaults.EXP,
    }
end

function ContractRewards:Grant(player, contract)
    local reward = self:BuildReward(contract)
    return {
        player = player,
        reward = reward,
    }
end

return ContractRewards

local Service = {}
Service.__index = Service

local STARTUP_ORDER = {
    'EventBus',
    'SecuritySystem',
    'GamePhaseSystem',
    'MatchSystem',
    'MapInteractionSystem',
    'GhostSystem',
    'GhostPersonalitySystem',
    'GhostDirector',
    'EvidenceSystem',
    'InvestigationSystem',
    'SpectatorSystem',
    'HorrorDirector',
    'FearSystem',
    'SanitySystem',
    'AggressionSystem',
    'ProfileSystem',
    'InventorySystem',
    'RewardSystem',
    'EconomySystem',
    'ProgressionSystem',
    'RankSystem',
    'RankedSystem',
    'LobbySocialHub',
    'CosmeticSystem',
    'ShopSystem',
    'ContractSystem',
}

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    return self
end

function Service:Init()
    self._state:Set('startupOrder', STARTUP_ORDER)
    self._state:Set('initialized', false)
end

function Service:Start()
    self._state:Set('initialized', true)
end

function Service:Stop()
    self._state:Set('initialized', false)
end

function Service:GetStartupOrder()
    return self._state:Get('startupOrder')
end

function Service:IsInitialized()
    return self._state:Get('initialized') == true
end

return Service

local SystemLoader = {}
SystemLoader.__index = SystemLoader

local SYSTEM_MODULE_NAMES = {
    EventBus = "EventBus",
    ConfigLoader = "ConfigLoader",
    GameConfigSystem = "GameConfigSystem",
    GhostDatabaseSystem = "GhostDatabaseSystem",
    MapConfigSystem = "MapConfigSystem",
    EvidenceConfigSystem = "EvidenceConfigSystem",
    DifficultyConfigSystem = "DifficultyConfigSystem",
    ContractConfigSystem = "ContractConfigSystem",
    DataPersistence = "DataPersistence",
    DataPersistenceService = "DataPersistenceService",
    SecuritySystem = "SecuritySystem",
    ProfileSystem = "ProfileSystem",
    ProgressionSystem = "ProgressionSystem",
    RankSystem = "RankSystem",
    InventorySystem = "InventorySystem",
    EconomySystem = "EconomySystem",
    RewardSystem = "RewardSystem",
    RankedSystem = "RankedSystem",
    GamePhaseSystem = "GamePhaseSystem",
    MatchSystem = "MatchSystem",
    MapInteractionSystem = "MapInteractionSystem",
    ToolInteractionSystem = "ToolInteractionSystem",
    ToolSignalProcessingSystem = "ToolSignalProcessingSystem",
    EvidenceToolSystem = "EvidenceToolSystem",
    GhostSystem = "GhostSystem",
    GhostPersonalitySystem = "GhostPersonalitySystem",
    GhostDirector = "GhostDirector",
    EvidenceSystem = "EvidenceSystem",
    InvestigationSystem = "InvestigationSystem",
    JournalSystem = "JournalSystem",
    EvidenceJournalSystem = "EvidenceJournalSystem",
    GhostDeductionJournal = "GhostDeductionJournal",
    SpectatorSystem = "SpectatorSystem",
    HorrorDirector = "HorrorDirector",
    FearSystem = "FearSystem",
    SanitySystem = "SanitySystem",
    AggressionSystem = "AggressionSystem",
    LobbySocialHub = "LobbySocialHub",
    CosmeticSystem = "CosmeticSystem",
    ShopSystem = "ShopSystem",
    ContractSystem = "ContractSystem",
    ContractRewardSystem = "ContractRewardSystem",
}

local function tryRequire(moduleScript)
    if not moduleScript then
        return nil
    end
    local ok, result = pcall(require, moduleScript)
    if ok then
        return result
    end
    return nil
end

function SystemLoader.new(deps)
    local self = setmetatable({}, SystemLoader)
    self._deps = deps or {}
    self._factories = {}
    return self
end

function SystemLoader:BuildDefaultFactories()
    local serverRoot = script.Parent.Parent.Parent.Parent
    for systemName, folderName in pairs(SYSTEM_MODULE_NAMES) do
        if self._factories[systemName] == nil then
            local folder = serverRoot:FindFirstChild(folderName)
            local mainModule = folder and folder:FindFirstChild("Main")
            local mainFactory = tryRequire(mainModule)
            if type(mainFactory) == "table" and type(mainFactory.new) == "function" then
                self._factories[systemName] = function(factoryDeps)
                    return mainFactory.new(factoryDeps)
                end
            end
        end
    end
    return self._factories
end

function SystemLoader:GetFactory(systemName)
    if not self._factories[systemName] then
        self:BuildDefaultFactories()
    end
    return self._factories[systemName]
end

return SystemLoader

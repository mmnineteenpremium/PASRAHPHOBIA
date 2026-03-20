local ContractGenerator = require(script.Parent.ContractGenerator.Generator)
local ContractBoard = require(script.Parent.ContractBoard.Board)
local MissionProgress = require(script.Parent.ContractObjectives.MissionProgress)
local RewardEngine = require(script.Parent.ContractRewards.RewardEngine)

local ContractService = {}
ContractService.__index = ContractService

local DEFAULT_CONFIG = {
    BoardSize = 3,
    DefaultLobbyId = "lobby_main",
}

local function resolveEventBus(deps)
    local eventBus = deps.EventBus
    if type(eventBus) ~= "table" then
        return nil
    end
    if type(eventBus.Publish) == "function" then
        return eventBus
    end
    if type(eventBus.Service) == "table" and type(eventBus.Service.Publish) == "function" then
        return eventBus.Service
    end
    return nil
end

local function resolveEconomyService(deps)
    local economy = deps.EconomySystem
    if type(economy) ~= "table" then
        return nil
    end
    if type(economy.AddCurrency) == "function" then
        return economy
    end
    if type(economy.Service) == "table" and type(economy.Service.AddCurrency) == "function" then
        return economy.Service
    end
    return nil
end

local function resolveProfileService(deps)
    local profile = deps.ProfileSystem
    if type(profile) ~= "table" then
        return nil
    end
    if type(profile.AddExperience) == "function" then
        return profile
    end
    if type(profile.Service) == "table" and type(profile.Service.AddExperience) == "function" then
        return profile.Service
    end
    return nil
end

local function resolveRankedService(deps)
    local ranked = deps.RankedSystem
    if type(ranked) ~= "table" then
        return nil
    end
    if type(ranked.AddStar) == "function" then
        return ranked
    end
    if type(ranked.Service) == "table" and type(ranked.Service.AddStar) == "function" then
        return ranked.Service
    end
    return nil
end

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, nestedValue in pairs(value) do
        copy[key] = deepCopy(nestedValue)
    end
    return copy
end

local function resolveUserId(player)
    if type(player) == "number" then
        return player
    end
    if type(player) == "table" and type(player.userId) == "number" then
        return player.userId
    end
    if typeof(player) == "Instance" and player:IsA("Player") then
        return player.UserId
    end
    return nil
end

function ContractService.new(state, deps)
    local self = setmetatable({}, ContractService)
    self._state = state
    self._deps = deps or {}
    self._config = self._deps.ContractConfig or DEFAULT_CONFIG
    self._eventBus = resolveEventBus(self._deps)
    self._economyService = resolveEconomyService(self._deps)
    self._profileService = resolveProfileService(self._deps)
    self._rankedService = resolveRankedService(self._deps)
    self._rng = self._deps.Random or Random.new()

    self._generator = ContractGenerator.new(self._deps, self._config, self._rng)
    self._board = ContractBoard.new()
    self._objectives = MissionProgress.new()
    self._rewards = RewardEngine.new(self._deps, self._rng)
    return self
end

function ContractService:Init()
    self._state:Set("contractsById", {})
    self._state:Set("boardByLobbyId", {})
    self._state:Set("selectedByPartyId", {})
    self._state:Set("matchSessions", {})
    self._state:Set("nextContractId", 1)
    self:GenerateBoard(self._config.DefaultLobbyId or "lobby_main", self._config.BoardSize or 3)
end

function ContractService:Start()
    -- Event-driven orchestration only.
end

function ContractService:Stop()
    self._state:Clear()
end

function ContractService:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function ContractService:_nextContractId()
    local nextId = self._state:Get("nextContractId") or 1
    self._state:Set("nextContractId", nextId + 1)
    return string.format("contract_%d", nextId)
end

function ContractService:_contractsById()
    return self._state:Get("contractsById") or {}
end

function ContractService:_setContractsById(contractsById)
    self._state:Set("contractsById", contractsById)
end

function ContractService:_boardByLobbyId()
    return self._state:Get("boardByLobbyId") or {}
end

function ContractService:_setBoardByLobbyId(boardByLobbyId)
    self._state:Set("boardByLobbyId", boardByLobbyId)
end

function ContractService:_selectedByPartyId()
    return self._state:Get("selectedByPartyId") or {}
end

function ContractService:_setSelectedByPartyId(selectedByPartyId)
    self._state:Set("selectedByPartyId", selectedByPartyId)
end

function ContractService:_matchSessions()
    return self._state:Get("matchSessions") or {}
end

function ContractService:_setMatchSessions(matchSessions)
    self._state:Set("matchSessions", matchSessions)
end

function ContractService:_sanitizeForBoard(contract)
    local copy = deepCopy(contract)
    copy.ghostType = nil
    copy.ghostHidden = true
    return copy
end

function ContractService:GenerateBoard(lobbyId, count, payload)
    local targetLobbyId = lobbyId or self._config.DefaultLobbyId or "lobby_main"
    local boardCount = math.max(1, math.floor(tonumber(count) or self._config.BoardSize or 3))

    local boardIds = {}
    local contractsById = self:_contractsById()
    for _ = 1, boardCount do
        local contract = self._generator:Generate(payload or {})
        contract.contractId = self:_nextContractId()
        contract.createdAt = payload and payload.now or os.clock()

        contractsById[contract.contractId] = contract
        table.insert(boardIds, contract.contractId)

        self:_publish("ContractGenerated", {
            lobbyId = targetLobbyId,
            contractId = contract.contractId,
            mapId = contract.mapId,
            difficulty = contract.difficulty,
            objectives = contract.objectives,
            reward = contract.reward,
            ghostHidden = true,
        })
    end
    self:_setContractsById(contractsById)

    local boardByLobbyId = self:_boardByLobbyId()
    boardByLobbyId[targetLobbyId] = {
        contractIds = self._board:Replace(boardIds),
        generatedAt = payload and payload.now or os.clock(),
    }
    self:_setBoardByLobbyId(boardByLobbyId)

    return self:GetBoardContracts(targetLobbyId)
end

function ContractService:GetBoardContracts(lobbyId)
    local targetLobbyId = lobbyId or self._config.DefaultLobbyId or "lobby_main"
    local boardByLobbyId = self:_boardByLobbyId()
    local contractsById = self:_contractsById()

    local board = boardByLobbyId[targetLobbyId]
    if not board then
        return self:GenerateBoard(targetLobbyId, self._config.BoardSize or 3)
    end

    local list = {}
    for _, contractId in ipairs(board.contractIds or {}) do
        local contract = contractsById[contractId]
        if contract then
            table.insert(list, self:_sanitizeForBoard(contract))
        end
    end

    return list
end

function ContractService:SelectContract(partyId, contractId, selector)
    if not partyId or not contractId then
        return false, "invalid_arguments"
    end

    local contractsById = self:_contractsById()
    local contract = contractsById[contractId]
    if not contract then
        return false, "contract_not_found"
    end

    local selectedByPartyId = self:_selectedByPartyId()
    selectedByPartyId[partyId] = contractId
    self:_setSelectedByPartyId(selectedByPartyId)

    self:_publish("ContractSelected", {
        partyId = partyId,
        contractId = contractId,
        selectedBy = selector,
    })

    return true, nil, self:_sanitizeForBoard(contract)
end

function ContractService:BindMatchFromParties(matchId, partyIds)
    if not matchId then
        return nil
    end

    local selectedByPartyId = self:_selectedByPartyId()
    local selectedContractId = nil
    for _, partyId in ipairs(partyIds or {}) do
        if selectedByPartyId[partyId] then
            selectedContractId = selectedByPartyId[partyId]
            break
        end
    end

    if not selectedContractId then
        return nil
    end

    local matchSessions = self:_matchSessions()
    local session = matchSessions[matchId] or {}
    session.contractId = selectedContractId
    session.partyIds = partyIds or {}
    matchSessions[matchId] = session
    self:_setMatchSessions(matchSessions)
    return selectedContractId
end

function ContractService:StartMatchSession(matchId, payload)
    if not matchId then
        return nil, "invalid_arguments"
    end

    local matchSessions = self:_matchSessions()
    local session = matchSessions[matchId] or {}

    local contractId = payload and payload.contractId or session.contractId
    if not contractId then
        local boardContracts = self:GetBoardContracts(self._config.DefaultLobbyId)
        local first = boardContracts[1]
        if first then
            contractId = first.contractId
        end
    end

    local contract = self:_contractsById()[contractId]
    if not contract then
        return nil, "missing_contract"
    end

    session.matchId = matchId
    session.contractId = contractId
    session.players = payload and payload.players or session.players or {}
    session.mapId = payload and payload.mapId or contract.mapId
    session.difficulty = payload and payload.difficulty or contract.difficulty
    session.ghostRoomId = session.ghostRoomId
    session.startedAt = payload and payload.now or os.clock()
    session.completed = false
    session.contract = contract
    session.objectives = self._objectives:CreateProgress(contract.objectives)
    session.runtime = {
        evidenceSet = {},
        huntStarted = false,
        huntCompleted = false,
    }

    matchSessions[matchId] = session
    self:_setMatchSessions(matchSessions)
    return session
end

function ContractService:SetGhostRoom(matchId, roomId)
    if not matchId or not roomId then
        return
    end
    local matchSessions = self:_matchSessions()
    local session = matchSessions[matchId]
    if not session then
        return
    end
    session.ghostRoomId = roomId
end

function ContractService:ProcessSignal(matchId, signalType, payload)
    local session = self:_matchSessions()[matchId]
    if not session or session.completed then
        return nil
    end

    local completed = self._objectives:ApplySignal(session, signalType, payload or {})
    local totalObjectives = #(session.objectives or {})
    local completedCount = 0
    for _, objective in ipairs(session.objectives or {}) do
        if objective.completed == true then
            completedCount += 1
        end
    end

    self:_publish("ContractProgressUpdated", {
        matchId = matchId,
        contractId = session.contractId,
        signalType = signalType,
        completedCount = completedCount,
        totalCount = totalObjectives,
        progress = totalObjectives > 0 and (completedCount / totalObjectives) or 0,
        completedObjectives = completed,
        now = payload and payload.now,
    })

    for _, objective in ipairs(completed) do
        self:_publish("ObjectiveCompleted", {
            matchId = matchId,
            contractId = session.contractId,
            objectiveId = objective.id,
            objectiveType = objective.objectiveType,
            description = objective.description,
            now = payload and payload.now,
        })
        local emitted = false
        for _, player in ipairs(session.players or {}) do
            emitted = true
            self:_publish("MissionCompleted", {
                matchId = matchId,
                contractId = session.contractId,
                player = player,
                userId = resolveUserId(player),
                objectiveId = objective.id,
                objectiveType = objective.objectiveType,
                description = objective.description,
                now = payload and payload.now,
            })
        end
        if not emitted then
            self:_publish("MissionCompleted", {
                matchId = matchId,
                contractId = session.contractId,
                objectiveId = objective.id,
                objectiveType = objective.objectiveType,
                description = objective.description,
                now = payload and payload.now,
            })
        end
    end

    local allCompleted = self._objectives:AreAllCompleted(session.objectives)
    if allCompleted and not session.completed then
        session.completed = true
        local reward = (session.contract and session.contract.reward) or {}
        self:_publish("ContractCompleted", {
            matchId = matchId,
            contractId = session.contractId,
            players = session.players or {},
            completedObjectives = completedCount,
            totalObjectives = totalObjectives,
            currencyType = reward.currency or "MM",
            mmAmount = math.floor(tonumber(reward.amount) or 0),
            xpAmount = math.floor(tonumber(reward.experience) or 0),
            rankProgress = math.floor(tonumber(reward.rankProgress) or 0),
            cosmeticDropChance = tonumber(reward.cosmeticDropChance) or 0,
            completedAt = payload and payload.now or os.clock(),
        })
    end

    return {
        completedObjectives = completed,
        contractCompleted = allCompleted,
    }
end

function ContractService:EndMatchSession(matchId, payload)
    local matchSessions = self:_matchSessions()
    local session = matchSessions[matchId]
    if not session then
        return nil, "missing_match_session"
    end

    self:ProcessSignal(matchId, "match_ended", payload or {})

    local result = {
        matchId = matchId,
        contractId = session.contractId,
        completed = session.completed == true,
        rewards = {},
    }

    local hasCentralRewardSystem = self._deps and self._deps.RewardSystem ~= nil
    if session.completed and not hasCentralRewardSystem then
        local granted = self._rewards:Grant(
            session.contract,
            payload or {},
            {
                economy = self._economyService,
                profile = self._profileService,
                ranked = self._rankedService,
            }
        )

        result.rewards = granted
        for _, rewardEntry in ipairs(granted) do
            self:_publish("RewardGranted", {
                matchId = matchId,
                contractId = session.contractId,
                player = rewardEntry.player,
                userId = rewardEntry.userId,
                reward = rewardEntry.reward,
            })
        end
    elseif session.completed then
        result.rewardsQueued = true
    end

    matchSessions[matchId] = nil
    self:_setMatchSessions(matchSessions)
    return result
end

return ContractService

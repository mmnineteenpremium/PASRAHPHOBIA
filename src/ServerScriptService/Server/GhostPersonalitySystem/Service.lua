local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local function resolveEventBus(deps)
    local eventBus = Services.Get(deps, "EventBus")
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

local function appendHistory(history, entry, maxSize)
    table.insert(history, entry)
    if #history > (maxSize or 200) then
        table.remove(history, 1)
    end
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    self._rng = self._deps.Random or Random.new()
    return self
end

function Service:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        GhostSystem = Services.Get(self._deps, "GhostSystem"),
        AggressionSystem = Services.Get(self._deps, "AggressionSystem"),
        SanitySystem = Services.Get(self._deps, "SanitySystem"),
        HorrorDirector = Services.Get(self._deps, "HorrorDirector"),
        MatchSystem = Services.Get(self._deps, "MatchSystem"),
    }
end

function Service:Init()
    self._state:Set("ghostTraits", self._state:Get("ghostTraits") or {})
    self._state:Set("traitHistory", self._state:Get("traitHistory") or {})
end

function Service:Start()
    -- Event-driven system.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_traitDefinitions()
    return self._state:Get("traitDefinitions") or {}
end

function Service:_pickRandomTrait()
    local definitions = self:_traitDefinitions()
    local names = {}
    for traitName in pairs(definitions) do
        table.insert(names, traitName)
    end
    if #names == 0 then
        return nil
    end
    return names[self._rng:NextInteger(1, #names)]
end

function Service:GetTrait(ghostId)
    local traits = self._state:Get("ghostTraits") or {}
    return traits[ghostId]
end

function Service:AssignPersonality(ghostId, requestedTrait)
    if type(ghostId) ~= "string" or ghostId == "" then
        return nil, "invalid_ghost_id"
    end

    local definitions = self:_traitDefinitions()
    local selectedTrait = requestedTrait
    if type(selectedTrait) ~= "string" or definitions[selectedTrait] == nil then
        selectedTrait = self:_pickRandomTrait()
    end
    if type(selectedTrait) ~= "string" then
        return nil, "no_trait_available"
    end

    local traits = self._state:Get("ghostTraits") or {}
    local previousTrait = traits[ghostId]
    traits[ghostId] = selectedTrait
    self._state:Set("ghostTraits", traits)

    local history = self._state:Get("traitHistory") or {}
    appendHistory(history, {
        at = os.time(),
        matchId = self._state:Get("activeMatchId"),
        ghostId = ghostId,
        previousTrait = previousTrait,
        trait = selectedTrait,
    })
    self._state:Set("traitHistory", history)

    local payload = {
        matchId = self._state:Get("activeMatchId"),
        ghostId = ghostId,
        trait = selectedTrait,
        modifiers = definitions[selectedTrait],
    }

    self:_publish("GhostPersonalityAssigned", payload)
    self:_publish("GhostTraitModified", payload)

    return selectedTrait
end

function Service:ApplyTraitEffects(ghostId)
    local trait = self:GetTrait(ghostId)
    if not trait then
        return nil, "trait_not_found"
    end

    local modifiers = self:_traitDefinitions()[trait]
    if type(modifiers) ~= "table" then
        return nil, "trait_definition_not_found"
    end

    local payload = {
        matchId = self._state:Get("activeMatchId"),
        ghostId = ghostId,
        trait = trait,
        modifiers = modifiers,
    }
    self:_publish("GhostTraitModified", payload)
    return payload
end

function Service:OnMatchStarted(payload)
    local matchId = payload and payload.matchId
    if not matchId then
        return
    end
    self._state:ResetForMatch(matchId)
end

function Service:OnGhostSpawned(payload)
    local matchId = payload and payload.matchId
    local activeMatchId = self._state:Get("activeMatchId")
    if not matchId or (activeMatchId and activeMatchId ~= matchId) then
        return nil
    end

    local ghostId = payload.ghostId or payload.id
    if type(ghostId) ~= "string" then
        return nil
    end

    local trait = self:AssignPersonality(ghostId, payload.trait)
    if trait then
        self:ApplyTraitEffects(ghostId)
    end
    return trait
end

function Service:OnParanormalEvent(payload)
    if type(payload) ~= "table" then
        return
    end
    local ghostId = payload.ghostId
    if type(ghostId) ~= "string" then
        return
    end
    if payload.intensity and payload.intensity >= 0.9 then
        self:AssignPersonality(ghostId, "Aggressive")
    end
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    local activeMatchId = self._state:Get("activeMatchId")
    if activeMatchId and matchId and activeMatchId ~= matchId then
        return
    end
    self._state:Set("activeMatchId", nil)
    self._state:Set("ghostTraits", {})
end

return Service

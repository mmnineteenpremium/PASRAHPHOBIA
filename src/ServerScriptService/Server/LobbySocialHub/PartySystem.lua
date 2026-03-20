local PartySystem = {}
PartySystem.__index = PartySystem

local MAX_PARTY_SIZE = 4

local function isPlayer(player)
    return typeof(player) == "Instance" and player:IsA("Player")
end

function PartySystem.new(deps, config)
    local self = setmetatable({}, PartySystem)
    self._deps = deps or {}
    self._config = config or {}
    self._maxPartySize = self._config.MaxPartySize or MAX_PARTY_SIZE
    self._nextPartyId = 1
    self._partyById = {}
    self._partyIdByUserId = {}
    self._callbacks = {
        onPlayerJoinedParty = nil,
    }
    return self
end

function PartySystem:SetCallbacks(callbacks)
    callbacks = callbacks or {}
    self._callbacks.onPlayerJoinedParty = callbacks.onPlayerJoinedParty
end

function PartySystem:Init()
    -- Runtime is event-driven.
end

function PartySystem:Start()
    -- Runtime is event-driven.
end

function PartySystem:Stop()
    table.clear(self._partyById)
    table.clear(self._partyIdByUserId)
end

function PartySystem:_newPartyId()
    local id = "party_" .. tostring(self._nextPartyId)
    self._nextPartyId += 1
    return id
end

function PartySystem:_getPartyByPlayer(player)
    if not isPlayer(player) then
        return nil
    end
    local partyId = self._partyIdByUserId[player.UserId]
    if not partyId then
        return nil
    end
    return self._partyById[partyId]
end

function PartySystem:CreateParty(player)
    if not isPlayer(player) then
        return nil, "invalid_player"
    end

    local existing = self:_getPartyByPlayer(player)
    if existing then
        return existing
    end

    local party = {
        partyId = self:_newPartyId(),
        leader = player,
        members = { player },
    }
    self._partyById[party.partyId] = party
    self._partyIdByUserId[player.UserId] = party.partyId
    return party
end

function PartySystem:InvitePlayer(partyId, player)
    if not isPlayer(player) then
        return false, "invalid_player"
    end

    local party = self._partyById[partyId]
    if not party then
        return false, "missing_party"
    end
    if self._partyIdByUserId[player.UserId] then
        return false, "already_in_party"
    end
    if #party.members >= self._maxPartySize then
        return false, "party_full"
    end

    table.insert(party.members, player)
    self._partyIdByUserId[player.UserId] = partyId

    if self._callbacks.onPlayerJoinedParty then
        self._callbacks.onPlayerJoinedParty(player, party)
    end
    return true
end

function PartySystem:LeaveParty(player)
    if not isPlayer(player) then
        return false, "invalid_player"
    end

    local party = self:_getPartyByPlayer(player)
    if not party then
        return false, "missing_party"
    end

    local userId = player.UserId
    self._partyIdByUserId[userId] = nil
    for index, member in ipairs(party.members) do
        if member.UserId == userId then
            table.remove(party.members, index)
            break
        end
    end

    if #party.members == 0 then
        self._partyById[party.partyId] = nil
        return true
    end

    if party.leader and party.leader.UserId == userId then
        party.leader = party.members[1]
    end
    return true
end

function PartySystem:DisbandParty(partyId)
    local party = self._partyById[partyId]
    if not party then
        return false, "missing_party"
    end

    for _, member in ipairs(party.members) do
        self._partyIdByUserId[member.UserId] = nil
    end
    self._partyById[partyId] = nil
    return true
end

function PartySystem:GetPartyByPlayer(player)
    return self:_getPartyByPlayer(player)
end

function PartySystem:GetPartyMembers(player)
    local party = self:_getPartyByPlayer(player)
    if not party then
        return {}
    end
    local members = {}
    for _, member in ipairs(party.members) do
        table.insert(members, member)
    end
    return members
end

function PartySystem:PrepareGroupMatchmaking(player)
    if not isPlayer(player) then
        return nil, "invalid_player"
    end

    local party = self:_getPartyByPlayer(player)
    if not party then
        return {
            partyId = "solo:" .. tostring(player.UserId),
            leader = player,
            players = { player },
            queueType = "solo",
        }
    end

    return {
        partyId = party.partyId,
        leader = party.leader,
        players = party.members,
        queueType = "party",
    }
end

return PartySystem

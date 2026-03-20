local Services = require(script.Parent.Parent.Core.Services)

local Service = {}
Service.__index = Service

local DEFAULT_MAX_PLAYERS = 4

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

local function toUserId(playerOrUserId)
    if type(playerOrUserId) == "number" then
        return playerOrUserId
    end
    if typeof(playerOrUserId) == "Instance" and playerOrUserId:IsA("Player") then
        return playerOrUserId.UserId
    end
    return nil
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = nil
    self._dependencies = {}
    self._idCounter = 1
    return self
end

function Service:Create()
    self._eventBus = resolveEventBus(self._deps)
    self._dependencies = {
        LobbySocialHub = Services.Get(self._deps, "LobbySocialHub"),
        ProfileSystem = Services.Get(self._deps, "ProfileSystem"),
        InventorySystem = Services.Get(self._deps, "InventorySystem"),
        CosmeticSystem = Services.Get(self._deps, "CosmeticSystem"),
        DataPersistenceService = Services.Get(self._deps, "DataPersistenceService"),
    }
end

function Service:Init()
    self._state:Set("activeParties", self._state:Get("activeParties") or {})
    self._state:Set("playerParty", self._state:Get("playerParty") or {})
    self._state:Set("partyInvites", self._state:Get("partyInvites") or {})
end

function Service:Start()
    -- Event-driven service.
end

function Service:Stop()
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_newPartyId()
    local partyId = string.format("party_%d", self._idCounter)
    self._idCounter += 1
    return partyId
end

function Service:_getPartyIdForUser(userId)
    local playerParty = self._state:Get("playerParty") or {}
    return playerParty[userId]
end

function Service:_getPartyForUser(userId)
    local partyId = self:_getPartyIdForUser(userId)
    if not partyId then
        return nil, nil
    end
    local activeParties = self._state:Get("activeParties") or {}
    return partyId, activeParties[partyId]
end

function Service:_removeMemberFromParty(party, userId)
    for i = #party.members, 1, -1 do
        if party.members[i] == userId then
            table.remove(party.members, i)
            break
        end
    end
end

function Service:CreateParty(player, maxPlayers)
    local leaderId = toUserId(player)
    if not leaderId then
        return false, "invalid_player"
    end

    local existingPartyId = self:_getPartyIdForUser(leaderId)
    if existingPartyId then
        return false, "already_in_party"
    end

    local activeParties = self._state:Get("activeParties") or {}
    local playerParty = self._state:Get("playerParty") or {}

    local partyId = self:_newPartyId()
    activeParties[partyId] = {
        partyId = partyId,
        partyLeader = leaderId,
        members = { leaderId },
        maxPlayers = math.max(2, math.floor(tonumber(maxPlayers) or DEFAULT_MAX_PLAYERS)),
    }
    playerParty[leaderId] = partyId

    self._state:Set("activeParties", activeParties)
    self._state:Set("playerParty", playerParty)

    self:_publish("PartyCreated", {
        partyId = partyId,
        leader = leaderId,
        members = { leaderId },
        maxPlayers = activeParties[partyId].maxPlayers,
    })

    return true, nil, partyId
end

function Service:InvitePlayer(fromPlayer, toPlayer)
    local fromId = toUserId(fromPlayer)
    local toId = toUserId(toPlayer)
    if not fromId or not toId then
        return false, "invalid_player"
    end
    if fromId == toId then
        return false, "cannot_invite_self"
    end

    local partyId, party = self:_getPartyForUser(fromId)
    if not partyId then
        local ok, _, newPartyId = self:CreateParty(fromPlayer)
        if not ok then
            return false, "create_party_failed"
        end
        partyId = newPartyId
        local activeParties = self._state:Get("activeParties") or {}
        party = activeParties[partyId]
    end

    if party.partyLeader ~= fromId then
        return false, "not_party_leader"
    end

    if self:_getPartyIdForUser(toId) then
        return false, "target_already_in_party"
    end

    if #party.members >= party.maxPlayers then
        return false, "party_full"
    end

    local partyInvites = self._state:Get("partyInvites") or {}
    partyInvites[toId] = partyInvites[toId] or {}
    partyInvites[toId][partyId] = {
        fromUserId = fromId,
        at = os.time(),
    }
    self._state:Set("partyInvites", partyInvites)

    self:_publish("PartyInviteSent", {
        partyId = partyId,
        fromUserId = fromId,
        toUserId = toId,
    })

    self:_publish("NotificationSent", {
        toUserId = toId,
        type = "PartyInvite",
        message = "Party invite received",
        payload = {
            partyId = partyId,
            fromUserId = fromId,
        },
    })

    return true
end

function Service:JoinParty(player, partyId)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end
    if type(partyId) ~= "string" or partyId == "" then
        return false, "invalid_party"
    end

    if self:_getPartyIdForUser(userId) then
        return false, "already_in_party"
    end

    local activeParties = self._state:Get("activeParties") or {}
    local party = activeParties[partyId]
    if not party then
        return false, "party_not_found"
    end

    local partyInvites = self._state:Get("partyInvites") or {}
    local invites = partyInvites[userId] or {}
    if not invites[partyId] then
        return false, "invite_not_found"
    end

    if #party.members >= party.maxPlayers then
        return false, "party_full"
    end

    table.insert(party.members, userId)
    activeParties[partyId] = party

    local playerParty = self._state:Get("playerParty") or {}
    playerParty[userId] = partyId

    invites[partyId] = nil
    partyInvites[userId] = invites

    self._state:Set("activeParties", activeParties)
    self._state:Set("playerParty", playerParty)
    self._state:Set("partyInvites", partyInvites)

    self:_publish("PartyJoined", {
        partyId = partyId,
        userId = userId,
        members = party.members,
    })

    return true
end

function Service:LeaveParty(player)
    local userId = toUserId(player)
    if not userId then
        return false, "invalid_player"
    end

    local partyId, party = self:_getPartyForUser(userId)
    if not partyId or not party then
        return false, "not_in_party"
    end

    local activeParties = self._state:Get("activeParties") or {}
    local playerParty = self._state:Get("playerParty") or {}

    self:_removeMemberFromParty(party, userId)
    playerParty[userId] = nil

    if #party.members == 0 then
        activeParties[partyId] = nil
        self:_publish("PartyDisbanded", {
            partyId = partyId,
            reason = "empty",
        })
    else
        if party.partyLeader == userId then
            party.partyLeader = party.members[1]
        end
        activeParties[partyId] = party
        self:_publish("PartyLeft", {
            partyId = partyId,
            userId = userId,
            leader = party.partyLeader,
            members = party.members,
        })
    end

    self._state:Set("activeParties", activeParties)
    self._state:Set("playerParty", playerParty)
    return true
end

function Service:DisbandParty(leaderOrPartyId)
    local partyId = nil

    if type(leaderOrPartyId) == "string" then
        partyId = leaderOrPartyId
    else
        local leaderId = toUserId(leaderOrPartyId)
        if leaderId then
            partyId = self:_getPartyIdForUser(leaderId)
        end
    end

    if not partyId then
        return false, "party_not_found"
    end

    local activeParties = self._state:Get("activeParties") or {}
    local party = activeParties[partyId]
    if not party then
        return false, "party_not_found"
    end

    local playerParty = self._state:Get("playerParty") or {}
    for _, memberId in ipairs(party.members) do
        playerParty[memberId] = nil
    end

    activeParties[partyId] = nil
    self._state:Set("activeParties", activeParties)
    self._state:Set("playerParty", playerParty)

    self:_publish("PartyDisbanded", {
        partyId = partyId,
        leader = party.partyLeader,
        members = party.members,
    })

    return true
end

function Service:OnPlayerLeftLobby(payload)
    local player = payload and payload.player or payload
    if player then
        self:LeaveParty(player)
    end
end

return Service

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

local function toUserId(player)
    if type(player) == "number" then
        return player
    end
    if typeof(player) == "Instance" and player:IsA("Player") then
        return player.UserId
    end
    return nil
end

local function addUnique(list, value)
    for _, item in ipairs(list) do
        if item == value then
            return
        end
    end
    table.insert(list, value)
end

local function copyList(list)
    local out = {}
    for _, item in ipairs(list or {}) do
        table.insert(out, item)
    end
    return out
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)
    self._evidenceRemote = nil
    self._evidenceStateSubscription = nil
    return self
end

function Service:Init()
    self._state:Set("playerJournalData", {})
    self._state:Set("activeMatchId", nil)
    self._evidenceRemote = self:_resolveEvidenceRemote()
end

function Service:Start()
    if self._eventBus and not self._evidenceStateSubscription then
        self._evidenceStateSubscription = function(state)
            if type(state) ~= "table" then
                return
            end
            -- forward to journal UI sync
            self:_emitUIEvent("UIEvidenceStateUpdated", {
                evidenceState = state,
            })
        end
        self._eventBus:Subscribe("EvidenceStateUpdated", self._evidenceStateSubscription)
    end
end

function Service:Stop()
    if self._eventBus and self._evidenceStateSubscription then
        self._eventBus:Unsubscribe("EvidenceStateUpdated", self._evidenceStateSubscription)
        self._evidenceStateSubscription = nil
    end
    self._state:Clear()
end

function Service:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function Service:_resolveEvidenceRemote()
    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if not ok then
        return nil
    end
    local remoteFolder = replicatedStorage:FindFirstChild("RemoteEvents")
    local remote = remoteFolder and remoteFolder:FindFirstChild("EvidenceEvent")
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
end

function Service:_emitUIEvent(eventName, payload)
    self:_publish(eventName, payload)
    if not self._evidenceRemote then
        return
    end
    local message = {
        eventName = eventName,
    }
    for key, value in pairs(payload or {}) do
        message[key] = value
    end
    if payload and payload.player and typeof(payload.player) == "Instance" and payload.player:IsA("Player") then
        self._evidenceRemote:FireClient(payload.player, message)
        return
    end
    self._evidenceRemote:FireAllClients(message)
end

function Service:_getOrCreatePlayerState(userId)
    local all = self._state:Get("playerJournalData") or {}
    all[userId] = all[userId] or {
        confirmedEvidence = {},
        lastUpdatedAt = 0,
    }
    self._state:Set("playerJournalData", all)
    return all[userId]
end

function Service:OnMatchStarted(payload)
    if type(payload) ~= "table" then
        return
    end
    self._state:Set("activeMatchId", payload.matchId)
    self._state:Set("playerJournalData", {})
end

function Service:OnMatchEnded(payload)
    local matchId = payload and payload.matchId
    local activeMatchId = self._state:Get("activeMatchId")
    if activeMatchId ~= nil and matchId ~= nil and activeMatchId ~= matchId then
        return
    end
    self._state:Set("activeMatchId", nil)
    self._state:Set("playerJournalData", {})
end

function Service:OnEvidenceLogged(payload)
    if type(payload) ~= "table" then
        return
    end
    local userId = toUserId(payload.player or payload.userId)
    local evidenceType = payload.evidenceType
    if not userId or type(evidenceType) ~= "string" or evidenceType == "" then
        return
    end

    local playerData = self:_getOrCreatePlayerState(userId)
    addUnique(playerData.confirmedEvidence, evidenceType)
    playerData.lastUpdatedAt = os.clock()

    self:_publish("JournalUpdated", {
        userId = userId,
        matchId = payload.matchId or self._state:Get("activeMatchId"),
        journalData = {
            userId = userId,
            confirmedEvidence = copyList(playerData.confirmedEvidence),
            lastUpdatedAt = playerData.lastUpdatedAt,
        },
    })
    self:_emitUIEvent("UIEvidenceUpdated", {
        userId = userId,
        matchId = payload.matchId or self._state:Get("activeMatchId"),
        confirmedEvidence = copyList(playerData.confirmedEvidence),
    })
end

return Service

local LobbyPlayerManager = require(script.Parent.LobbyPlayerManager)
local LobbyZoneManager = require(script.Parent.LobbyZoneManager)
local LobbyInteraction = require(script.Parent.LobbyInteraction)
local PartySystem = require(script.Parent.PartySystem)
local LobbyPopulationController = require(script.Parent.LobbyPopulationController)
local RoomManager = require(script.Parent.RoomManager)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LOBBY_REMOTE_NAME = "LobbyEvent"
local COUNTDOWN_SECONDS = 5
local ROOM_INVITE_TIMEOUT = 5
local TIER_ORDER = {
    UNRANKED = 1,
    BRONZE = 2,
    SILVER = 3,
    GOLD = 4,
    PLATINUM = 5,
    DIAMOND = 6,
    MASTER = 7,
    GRANDMASTER = 8,
}

local LobbyService = {}
LobbyService.__index = LobbyService

local function resolveEventBus(deps)
    local eventBus = (type(deps) == "table" and type(deps.Services) == "table" and type(deps.Services.Get) == "function" and deps.Services:Get("EventBus"))
        or (type(deps) == "table" and type(deps.ServiceRegistry) == "table" and type(deps.ServiceRegistry.Get) == "function" and deps.ServiceRegistry:Get("EventBus"))
        or (deps and deps.EventBus or nil)
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

local function resolveLobbyRemote()
    local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if not remoteFolder then
        return nil
    end
    local remote = remoteFolder:FindFirstChild(LOBBY_REMOTE_NAME)
    if remote and remote:IsA("RemoteEvent") then
        return remote
    end
    return nil
end

local function resolveTierTextFromPlayer(player)
    if not player then
        return "UNRANKED"
    end
    for _, attrName in ipairs({ "RankTier", "Tier", "RankedTier", "HostTier" }) do
        local value = player:GetAttribute(attrName)
        if value ~= nil and tostring(value) ~= "" then
            return string.upper(tostring(value))
        end
    end
    return "UNRANKED"
end

function LobbyService.new(state, deps)
    local self = setmetatable({}, LobbyService)
    self._state = state
    self._deps = deps or {}
    self._eventBus = resolveEventBus(self._deps)

    self._playerManager = LobbyPlayerManager.new(self._deps, self._deps.LobbyPlayerManagerConfig)
    self._zoneManager = LobbyZoneManager.new(self._deps, self._deps.LobbyZoneManagerConfig)
    self._interaction = LobbyInteraction.new(self._deps, self._deps.LobbyInteractionConfig)
    self._partySystem = PartySystem.new(self._deps, self._deps.PartySystemConfig)
    self._population = LobbyPopulationController.new(self._state, self._deps, self._deps.LobbyPopulationConfig)
    self._roomManager = RoomManager.new()
    self._playerSelections = {}
    self._pendingRoomInvites = {}
    self._nextRoomInviteId = 1
    self._lobbyRemote = resolveLobbyRemote()
    return self
end

function LobbyService:_findLobbyPlayerByTarget(target)
    if target == nil then
        return nil
    end
    local asNumber = tonumber(target)
    if asNumber then
        for _, lobbyPlayer in ipairs(self._playerManager:GetLobbyPlayers()) do
            if lobbyPlayer.UserId == asNumber then
                return lobbyPlayer
            end
        end
        return nil
    end

    local query = tostring(target):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if query == "" then
        return nil
    end

    local partialMatch = nil
    for _, lobbyPlayer in ipairs(self._playerManager:GetLobbyPlayers()) do
        local nameLower = tostring(lobbyPlayer.Name or ""):lower()
        local displayLower = tostring(lobbyPlayer.DisplayName or ""):lower()
        if nameLower == query or displayLower == query then
            return lobbyPlayer
        end
        if string.find(nameLower, query, 1, true) == 1 or string.find(displayLower, query, 1, true) == 1 then
            partialMatch = partialMatch or lobbyPlayer
        end
    end
    return partialMatch
end

function LobbyService:_publish(eventName, payload)
    if self._eventBus then
        self._eventBus:Publish(eventName, payload)
    end
end

function LobbyService:_refreshPopulation()
    local playerCount = self._playerManager:GetLobbyPlayerCount()
    self._population:OnLobbyPlayerCountChanged(playerCount)
end

function LobbyService:_sendToPlayer(player, eventName, payload)
    if not player then
        return
    end
    local remote = self._lobbyRemote or resolveLobbyRemote()
    self._lobbyRemote = remote
    if not remote then
        return
    end
    local message = payload or {}
    message.eventName = eventName
    remote:FireClient(player, message)
end

function LobbyService:_sendToRoom(room, eventName, payload)
    if not room then
        return
    end
    for _, roomPlayer in ipairs(room.players) do
        self:_sendToPlayer(roomPlayer, eventName, payload)
    end
end

function LobbyService:_serializeRoom(room)
    return self._roomManager:SerializeRoom(room)
end

function LobbyService:_getSelection(userId)
    local selection = self._playerSelections[userId]
    if selection then
        return selection
    end
    selection = {
        mode = "Classic",
        difficulty = "Mudah",
    }
    self._playerSelections[userId] = selection
    return selection
end

function LobbyService:_sendRoomList(player)
    local rooms = {}
    for _, room in ipairs(self._roomManager:GetRooms()) do
        table.insert(rooms, self:_serializeRoom(room))
    end
    self:_sendToPlayer(player, "RoomBrowserRoomList", {
        rooms = rooms,
        lobbyPlayers = (function()
            local payload = {}
            for _, lobbyPlayer in ipairs(self._playerManager:GetLobbyPlayers()) do
                table.insert(payload, {
                    userId = lobbyPlayer.UserId,
                    name = lobbyPlayer.Name,
                    displayName = lobbyPlayer.DisplayName,
                    tier = resolveTierTextFromPlayer(lobbyPlayer),
                })
            end
            return payload
        end)(),
    })
end

function LobbyService:_broadcastRoomList()
    for _, lobbyPlayer in ipairs(self._playerManager:GetLobbyPlayers()) do
        self:_sendRoomList(lobbyPlayer)
    end
end

function LobbyService:_emitRoomState(room)
    if not room then
        return
    end
    local roomData = self:_serializeRoom(room)
    local allReady = self._roomManager:AreAllReady(room)
    for _, roomPlayer in ipairs(room.players) do
        self:_sendToPlayer(roomPlayer, "RoomStateUpdate", {
            room = roomData,
            isHost = room.host == roomPlayer,
            isReady = self._roomManager:GetReadyState(room, roomPlayer),
            allReady = allReady,
            countdownSecondsLeft = room.state == "Countdown" and room.countdownSecondsLeft or nil,
        })
    end
end

function LobbyService:_startCountdown(room, options)
    if not room then
        return
    end
    local token = room.countdownToken
    local secondsTotal = COUNTDOWN_SECONDS

    room.countdownSecondsLeft = secondsTotal
    self:_sendToRoom(room, "RoomMatchStarting", {
        roomId = room.roomId,
        countdownSeconds = secondsTotal,
    })
    self:_emitRoomState(room)

    task.spawn(function()
        for secondsLeft = secondsTotal, 1, -1 do
            if room.state ~= "Countdown" or room.countdownToken ~= token then
                return
            end
            room.countdownSecondsLeft = secondsLeft
            self:_sendToRoom(room, "CountdownTick", {
                roomId = room.roomId,
                secondsLeft = secondsLeft,
                totalSeconds = secondsTotal,
            })
            self:_sendToRoom(room, "RoomMatchCountdown", {
                roomId = room.roomId,
                secondsLeft = secondsLeft,
                totalSeconds = secondsTotal,
            })
            self:_emitRoomState(room)
            task.wait(1)
        end

        if room.state ~= "Countdown" or room.countdownToken ~= token then
            return
        end

        self._roomManager:MarkInGame(room, options and options.mapId or nil, options and options.difficulty or nil, options and options.mode or nil)
        room.countdownSecondsLeft = nil
        self:_sendToRoom(room, "RoomMatchCountdownCompleted", {
            roomId = room.roomId,
        })
        self:_sendToRoom(room, "MatchStarted", {
            roomId = room.roomId,
        })
        self:_emitRoomState(room)
        self:_broadcastRoomList()
    end)
end

function LobbyService:Init()
    self._state:Set("lobbyStatus", "initialized")
    self._playerManager:Init()
    self._zoneManager:Init()
    self._interaction:Init()
    self._partySystem:Init()
    self._population:Init()

    self._zoneManager:SetZoneEnteredCallback(function(player, zoneName)
        self:OnPlayerEnteredZone(player, zoneName)
    end)
    self._partySystem:SetCallbacks({
        onPlayerJoinedParty = function(player, party)
            self:_publish("PlayerJoinedParty", {
                player = player,
                partyId = party.partyId,
                leader = party.leader,
                members = party.members,
            })
        end,
    })
end

function LobbyService:Start()
    self._state:Set("lobbyStatus", "running")
    self._playerManager:Start()
    self._zoneManager:Start()
    self._interaction:Start()
    self._partySystem:Start()
    self._population:Start()
end

function LobbyService:Stop()
    self._state:Set("lobbyStatus", "stopped")
    self._zoneManager:Stop()
    self._interaction:Stop()
    self._partySystem:Stop()
    self._playerManager:Stop()
    self._population:Stop()
end

function LobbyService:RegisterPlayer(player)
    local alreadyInLobby = self._playerManager:IsInLobby(player)
    local ok, reason = self._playerManager:RegisterPlayer(player)
    if not ok then
        return false, reason
    end
    if alreadyInLobby then
        return true
    end

    self:_publish("PlayerEnteredLobby", {
        player = player,
    })
    self:_getSelection(player.UserId)
    self:_sendRoomList(player)
    self:_refreshPopulation()
    return true
end

function LobbyService:RemovePlayer(player)
    if not self._playerManager:IsInLobby(player) then
        return true
    end

    local previousRoom = self._roomManager:GetRoomByPlayer(player)
    local wasCountdown = previousRoom and previousRoom.state == "Countdown"
    local updatedRoom = nil
    if previousRoom then
        updatedRoom = self._roomManager:LeaveRoom(player)
        self:_sendToPlayer(player, "RoomBrowserRoomLeft", {
            roomId = previousRoom.roomId,
        })
    end

    local ok, reason = self._playerManager:RemovePlayer(player)
    if not ok then
        return false, reason
    end

    self._partySystem:LeaveParty(player)
    self._playerSelections[player.UserId] = nil
    for inviteId, invite in pairs(self._pendingRoomInvites) do
        if invite and (invite.toUserId == player.UserId or invite.fromUserId == player.UserId) then
            self._pendingRoomInvites[inviteId] = nil
        end
    end
    if previousRoom then
        self:_broadcastRoomList()
        if updatedRoom then
            self:_emitRoomState(updatedRoom)
            if wasCountdown then
                self:_sendToRoom(updatedRoom, "RoomMatchCountdownCancelled", {
                    roomId = previousRoom.roomId,
                    reason = "player_left",
                })
            end
        end
    end
    self:_refreshPopulation()
    return true
end

function LobbyService:GetLobbyPlayers()
    return self._playerManager:GetLobbyPlayers()
end

function LobbyService:CreateParty(player)
    return self._partySystem:CreateParty(player)
end

function LobbyService:InvitePlayer(partyId, player)
    return self._partySystem:InvitePlayer(partyId, player)
end

function LobbyService:DisbandParty(partyId)
    return self._partySystem:DisbandParty(partyId)
end

function LobbyService:PrepareGroupMatchmaking(player)
    return self._partySystem:PrepareGroupMatchmaking(player)
end

function LobbyService:StartMatchmaking(player, payload)
    local matchmakingPackage, reason = self._partySystem:PrepareGroupMatchmaking(player)
    if not matchmakingPackage then
        return false, reason
    end

    self:_publish("MatchmakingStarted", {
        partyId = matchmakingPackage.partyId,
        leader = matchmakingPackage.leader,
        players = matchmakingPackage.players,
        queueType = matchmakingPackage.queueType,
        mapId = payload and payload.mapId or nil,
        difficulty = payload and payload.difficulty or nil,
        gameMode = payload and payload.gameMode or "Standard",
    })
    return true
end

function LobbyService:OnPlayerEnteredZone(player, zoneName)
    if not self._playerManager:IsInLobby(player) then
        return
    end

    self._interaction:HandleZoneEntry(player, zoneName)

    if zoneName == "MatchmakingZone" then
        self:_publish("PlayerEnteredMatchmaking", {
            player = player,
        })
        self:StartMatchmaking(player)
    end
end

function LobbyService:HandlePlayerTeleported(payload)
    local player = payload and payload.player
    local mapId = payload and payload.mapId
    if not player then
        return
    end

    if mapId == "Lobby" then
        self:RegisterPlayer(player)
    else
        self:RemovePlayer(player)
    end
end

function LobbyService:ApplyCosmetic(player, cosmeticId, category)
    self:_publish("LobbyCosmeticApplied", {
        player = player,
        cosmeticId = cosmeticId,
        category = category,
    })
    return true
end

function LobbyService:QueueFromRoomBrowser(player, request)
    if not player then
        return false, "player_required"
    end
    if type(request) ~= "table" then
        return false, "invalid_request"
    end

    local action = request.action
    local selection = self:_getSelection(player.UserId)

    if action == "RequestRoomBrowserSnapshot" then
        self:_sendToPlayer(player, "RoomBrowserSnapshot", {
            snapshot = {
                modes = { "Classic", "Ranked" },
                classicDifficulties = { "Mudah", "Lumayan", "Angker", "Uji Nyali" },
                selectedMode = selection.mode,
                selectedDifficulty = selection.difficulty,
                rooms = (function()
                    local rooms = {}
                    for _, room in ipairs(self._roomManager:GetRooms()) do
                        table.insert(rooms, self:_serializeRoom(room))
                    end
                    return rooms
                end)(),
                lobbyPlayers = (function()
                    local payload = {}
                    for _, lobbyPlayer in ipairs(self._playerManager:GetLobbyPlayers()) do
                        table.insert(payload, {
                            userId = lobbyPlayer.UserId,
                            name = lobbyPlayer.Name,
                            displayName = lobbyPlayer.DisplayName,
                            tier = resolveTierTextFromPlayer(lobbyPlayer),
                        })
                    end
                    return payload
                end)(),
            },
        })
        return true
    end

    if action == "RequestRoomList" then
        self:_sendRoomList(player)
        return true
    end

    if action == "SelectMode" then
        selection.mode = request.mode or selection.mode
        self:_sendToPlayer(player, "RoomBrowserSelectionConfirmed", {
            selection = {
                mode = selection.mode,
                difficulty = selection.difficulty,
            },
        })
        return true
    end

    if action == "SelectDifficulty" then
        selection.difficulty = request.difficulty or selection.difficulty
        self:_sendToPlayer(player, "RoomBrowserSelectionConfirmed", {
            selection = {
                mode = selection.mode,
                difficulty = selection.difficulty,
            },
        })
        return true
    end

    if action == "CreateRoom" then
        local room, err = self._roomManager:CreateRoom(player, {
            mode = selection.mode,
            difficulty = selection.difficulty,
            mapId = request.mapId,
        })
        if not room then
            self:_sendToPlayer(player, "CreateRoomResult", {
                ok = false,
                err = err,
            })
            return false, err
        end
        self:_sendToPlayer(player, "CreateRoomResult", {
            ok = true,
            roomId = room.roomId,
        })
        self:_sendToPlayer(player, "RoomBrowserRoomJoined", {
            roomId = room.roomId,
        })
        self:_emitRoomState(room)
        self:_broadcastRoomList()
        return true
    end

    if action == "JoinRoom" then
        local roomId = request.roomId
        local room, err = self._roomManager:JoinRoom(player, roomId)
        if not room then
            self:_sendToPlayer(player, "RoomBrowserRoomJoinFailed", {
                reason = err,
                roomId = roomId,
            })
            return false, err
        end
        self:_sendToPlayer(player, "RoomBrowserRoomJoined", {
            roomId = room.roomId,
        })
        self:_emitRoomState(room)
        self:_broadcastRoomList()
        return true
    end

    if action == "LeaveRoom" then
        local previousRoom = self._roomManager:GetRoomByPlayer(player)
        local wasCountdown = previousRoom and previousRoom.state == "Countdown"
        local room, err = self._roomManager:LeaveRoom(player)
        if previousRoom then
            self:_sendToPlayer(player, "RoomBrowserRoomLeft", {
                roomId = previousRoom.roomId,
            })
            if wasCountdown and room then
                self:_sendToRoom(room, "RoomMatchCountdownCancelled", {
                    roomId = previousRoom.roomId,
                    reason = "player_left",
                })
            end
        end
        if err then
            return false, err
        end
        if room then
            self:_emitRoomState(room)
        end
        self:_broadcastRoomList()
        return true
    end

    if action == "SetReady" or action == "ToggleReady" then
        local requestedReady = request.isReady
        if action == "ToggleReady" and requestedReady == nil then
            requestedReady = nil
        end
        local room, err = self._roomManager:SetReady(player, requestedReady)
        if not room then
            self:_sendToPlayer(player, "RoomReadyResult", {
                ok = false,
                err = err,
            })
            return false, err
        end
        self:_sendToPlayer(player, "RoomReadyResult", {
            ok = true,
            isReady = self._roomManager:GetReadyState(room, player),
        })
        self:_emitRoomState(room)
        self:_broadcastRoomList()
        return true
    end

    if action == "InvitePlayerToRoom" then
        local hostRoom = self._roomManager:GetRoomByPlayer(player)
        if not hostRoom then
            self:_sendToPlayer(player, "RoomInviteSendResult", {
                ok = false,
                err = "not_in_room",
            })
            return false, "not_in_room"
        end
        if hostRoom.host ~= player then
            self:_sendToPlayer(player, "RoomInviteSendResult", {
                ok = false,
                err = "not_host",
            })
            return false, "not_host"
        end

        local targetPlayer = self:_findLobbyPlayerByTarget(request.targetUserId or request.target or request.targetName)
        if not targetPlayer then
            self:_sendToPlayer(player, "RoomInviteSendResult", {
                ok = false,
                err = "target_not_found",
            })
            return false, "target_not_found"
        end
        if targetPlayer == player then
            self:_sendToPlayer(player, "RoomInviteSendResult", {
                ok = false,
                err = "cannot_invite_self",
            })
            return false, "cannot_invite_self"
        end
        if self._roomManager:GetRoomByPlayer(targetPlayer) then
            self:_sendToPlayer(player, "RoomInviteSendResult", {
                ok = false,
                err = "target_already_in_room",
            })
            return false, "target_already_in_room"
        end

        local inviteId = tostring(self._nextRoomInviteId)
        self._nextRoomInviteId += 1
        local inviteData = {
            inviteId = inviteId,
            roomId = hostRoom.roomId,
            fromUserId = player.UserId,
            fromName = player.DisplayName or player.Name,
            toUserId = targetPlayer.UserId,
            expiresAt = os.clock() + ROOM_INVITE_TIMEOUT,
        }
        self._pendingRoomInvites[inviteId] = inviteData

        self:_sendToPlayer(targetPlayer, "RoomInviteReceived", {
            inviteId = inviteId,
            roomId = hostRoom.roomId,
            fromUserId = player.UserId,
            fromName = player.DisplayName or player.Name,
            mode = hostRoom.mode,
            mapId = hostRoom.mapId,
            difficulty = hostRoom.difficulty,
            expiresIn = ROOM_INVITE_TIMEOUT,
        })
        self:_sendToPlayer(player, "RoomInviteSendResult", {
            ok = true,
            inviteId = inviteId,
            toUserId = targetPlayer.UserId,
            toName = targetPlayer.DisplayName or targetPlayer.Name,
            roomId = hostRoom.roomId,
        })

        task.delay(ROOM_INVITE_TIMEOUT + 0.1, function()
            local pending = self._pendingRoomInvites[inviteId]
            if not pending then
                return
            end
            if pending.expiresAt <= os.clock() then
                self._pendingRoomInvites[inviteId] = nil
                local inviter = Players:GetPlayerByUserId(pending.fromUserId)
                if inviter then
                    self:_sendToPlayer(inviter, "RoomInviteExpired", {
                        inviteId = inviteId,
                        roomId = pending.roomId,
                        toUserId = pending.toUserId,
                    })
                end
            end
        end)

        return true
    end

    if action == "InviteBroadcastToRoom" then
        local hostRoom = self._roomManager:GetRoomByPlayer(player)
        if not hostRoom then
            self:_sendToPlayer(player, "RoomInviteSendResult", {
                ok = false,
                err = "not_in_room",
            })
            return false, "not_in_room"
        end
        if hostRoom.host ~= player then
            self:_sendToPlayer(player, "RoomInviteSendResult", {
                ok = false,
                err = "not_host",
            })
            return false, "not_host"
        end

        local hostTierText = resolveTierTextFromPlayer(player)
        local hostTierIndex = TIER_ORDER[hostTierText] or TIER_ORDER.UNRANKED
        local isRankedRoom = string.lower(tostring(hostRoom.mode or "Classic")) == "ranked"
        local invitedCount = 0

        for _, lobbyPlayer in ipairs(self._playerManager:GetLobbyPlayers()) do
            if lobbyPlayer ~= player and self._roomManager:GetRoomByPlayer(lobbyPlayer) == nil then
                local allow = true
                if isRankedRoom then
                    local targetTierText = resolveTierTextFromPlayer(lobbyPlayer)
                    local targetTierIndex = TIER_ORDER[targetTierText] or TIER_ORDER.UNRANKED
                    allow = math.abs(targetTierIndex - hostTierIndex) <= 1
                end
                if allow then
                    local inviteId = tostring(self._nextRoomInviteId)
                    self._nextRoomInviteId += 1
                    self._pendingRoomInvites[inviteId] = {
                        inviteId = inviteId,
                        roomId = hostRoom.roomId,
                        fromUserId = player.UserId,
                        fromName = player.DisplayName or player.Name,
                        toUserId = lobbyPlayer.UserId,
                        expiresAt = os.clock() + ROOM_INVITE_TIMEOUT,
                    }
                    self:_sendToPlayer(lobbyPlayer, "RoomInviteReceived", {
                        inviteId = inviteId,
                        roomId = hostRoom.roomId,
                        fromUserId = player.UserId,
                        fromName = player.DisplayName or player.Name,
                        mode = hostRoom.mode,
                        mapId = hostRoom.mapId,
                        difficulty = hostRoom.difficulty,
                        expiresIn = ROOM_INVITE_TIMEOUT,
                        broadcast = true,
                    })
                    invitedCount += 1

                    task.delay(ROOM_INVITE_TIMEOUT + 0.1, function()
                        local pending = self._pendingRoomInvites[inviteId]
                        if not pending then
                            return
                        end
                        if pending.expiresAt <= os.clock() then
                            self._pendingRoomInvites[inviteId] = nil
                        end
                    end)
                end
            end
        end

        self:_sendToPlayer(player, "RoomInviteSendResult", {
            ok = invitedCount > 0,
            broadcast = true,
            invitedCount = invitedCount,
            err = invitedCount > 0 and nil or "no_valid_targets",
        })
        return invitedCount > 0, invitedCount > 0 and nil or "no_valid_targets"
    end

    if action == "RespondRoomInvite" then
        local inviteId = tostring(request.inviteId or "")
        local accept = request.accept == true
        local inviteData = self._pendingRoomInvites[inviteId]
        if not inviteData then
            self:_sendToPlayer(player, "RoomInviteResponseResult", {
                ok = false,
                err = "invite_not_found",
            })
            return false, "invite_not_found"
        end
        if inviteData.toUserId ~= player.UserId then
            self:_sendToPlayer(player, "RoomInviteResponseResult", {
                ok = false,
                err = "invite_not_for_player",
            })
            return false, "invite_not_for_player"
        end
        if inviteData.expiresAt <= os.clock() then
            self._pendingRoomInvites[inviteId] = nil
            self:_sendToPlayer(player, "RoomInviteResponseResult", {
                ok = false,
                err = "invite_expired",
            })
            return false, "invite_expired"
        end

        self._pendingRoomInvites[inviteId] = nil
        local inviter = Players:GetPlayerByUserId(inviteData.fromUserId)
        if not accept then
            self:_sendToPlayer(player, "RoomInviteResponseResult", {
                ok = true,
                accepted = false,
            })
            if inviter then
                self:_sendToPlayer(inviter, "RoomInviteDeclined", {
                    inviteId = inviteId,
                    byUserId = player.UserId,
                    byName = player.DisplayName or player.Name,
                    roomId = inviteData.roomId,
                })
            end
            return true
        end

        local room, err = self._roomManager:JoinRoom(player, inviteData.roomId)
        if not room then
            self:_sendToPlayer(player, "RoomInviteResponseResult", {
                ok = false,
                err = err,
            })
            if inviter then
                self:_sendToPlayer(inviter, "RoomInviteFailed", {
                    inviteId = inviteId,
                    byUserId = player.UserId,
                    byName = player.DisplayName or player.Name,
                    err = err,
                })
            end
            return false, err
        end

        self:_sendToPlayer(player, "RoomInviteResponseResult", {
            ok = true,
            accepted = true,
            roomId = room.roomId,
        })
        self:_sendToPlayer(player, "RoomBrowserRoomJoined", {
            roomId = room.roomId,
        })
        if inviter then
            self:_sendToPlayer(inviter, "RoomInviteAccepted", {
                inviteId = inviteId,
                byUserId = player.UserId,
                byName = player.DisplayName or player.Name,
                roomId = room.roomId,
            })
        end
        self:_emitRoomState(room)
        self:_broadcastRoomList()
        return true
    end

    if action == "HostStart" or action == "StartMatch" then
        local room, err = self._roomManager:BeginCountdown(player)
        if not room then
            self:_sendToPlayer(player, "HostStartResult", {
                ok = false,
                err = err,
            })
            return false, err
        end
        self:_sendToPlayer(player, "HostStartResult", {
            ok = true,
        })
        self:_broadcastRoomList()
        self:_startCountdown(room, {
            mapId = request.mapId,
            difficulty = request.difficulty or selection.difficulty,
            mode = request.mode or selection.mode,
        })
        return true
    end

    if action == "CancelHostStart" or action == "CancelStart" then
        local room, err = self._roomManager:CancelCountdown(player)
        if not room then
            self:_sendToPlayer(player, "CancelHostStartResult", {
                ok = false,
                err = err,
            })
            return false, err
        end
        self:_sendToPlayer(player, "CancelHostStartResult", {
            ok = true,
        })
        self:_sendToRoom(room, "RoomMatchCountdownCancelled", {
            roomId = room.roomId,
            reason = "host_cancelled",
        })
        self:_emitRoomState(room)
        self:_broadcastRoomList()
        return true
    end

    if action == "QueueFromRoomBrowser" then
        self:_sendToPlayer(player, "RoomBrowserQueueFailed", {
            reason = "queue_not_implemented",
        })
        return false, "queue_not_implemented"
    end

    if action == "SetPassword" then
        self:_sendToPlayer(player, "SetPasswordResult", {
            ok = false,
            err = "set_password_not_implemented",
        })
        return false, "set_password_not_implemented"
    end

    if action == "KickPlayer" then
        self:_sendToPlayer(player, "KickPlayerResult", {
            ok = false,
            err = "kick_not_implemented",
        })
        return false, "kick_not_implemented"
    end

    return false, "unsupported_action:" .. tostring(action)
end

return LobbyService

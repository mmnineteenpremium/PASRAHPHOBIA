local LobbyPopulationController = {}
LobbyPopulationController.__index = LobbyPopulationController

local DEFAULT_CONFIG = {
    NpcCountWhenEmpty = 6,
}

function LobbyPopulationController.new(state, deps, config)
    local self = setmetatable({}, LobbyPopulationController)
    self._state = state
    self._deps = deps or {}
    self._config = {}
    for key, value in pairs(DEFAULT_CONFIG) do
        self._config[key] = value
    end
    for key, value in pairs(config or {}) do
        self._config[key] = value
    end
    return self
end

function LobbyPopulationController:Init()
    self._state:Set("lobbyNpcInvestigators", 0)
end

function LobbyPopulationController:Start()
    -- Runtime is event-driven.
end

function LobbyPopulationController:Stop()
    self._state:Set("lobbyNpcInvestigators", 0)
end

function LobbyPopulationController:OnLobbyPlayerCountChanged(playerCount)
    local npcCount = 0
    if playerCount <= 0 then
        npcCount = self._config.NpcCountWhenEmpty
    end
    self._state:Set("lobbyNpcInvestigators", npcCount)
    return npcCount
end

function LobbyPopulationController:GetNpcCount()
    return self._state:Get("lobbyNpcInvestigators") or 0
end

return LobbyPopulationController

local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)
local DataPersistenceSystem = require(script.Parent.Parent.DataPersistenceService.Main)

local InventorySystem = {}
InventorySystem.__index = InventorySystem

function InventorySystem.new(deps)
    local self = setmetatable({}, InventorySystem)
    self._deps = deps or {}
    self.State = State.new()

    self._dataPersistenceSystem = DataPersistenceSystem.new({
        Players = self._deps.Players,
        DataPersistenceState = self._deps.DataPersistenceState,
    })
    self._deps.PersistenceService = self._dataPersistenceSystem.Service

    self.Service = Service.new(self.State, self._deps)
    self.Service:SetPersistenceService(self._dataPersistenceSystem.Service)
    self._dataPersistenceSystem.Service:SetInventoryService(self.Service)

    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function InventorySystem:Init()
    self._dataPersistenceSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function InventorySystem:Start()
    self._dataPersistenceSystem:Start()
    self.Service:Start()
    self.Controller:RegisterEventHandlers()
end

function InventorySystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self._dataPersistenceSystem:Stop()
    self.Service:Stop()
end

return InventorySystem

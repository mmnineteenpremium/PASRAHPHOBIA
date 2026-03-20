local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)
local Services = require(script.Parent.Parent.Core.Services)

local InventorySystem = {}
InventorySystem.__index = InventorySystem

function InventorySystem.new(deps)
    local self = setmetatable({}, InventorySystem)
    self._deps = deps or {}
    self.State = State.new()

    self._dataPersistenceSystem = Services.Get(self._deps, "DataPersistenceService")
        or Services.Get(self._deps, "DataPersistenceSystem")

    self.Service = Service.new(self.State, self._deps)
    if self._dataPersistenceSystem then
        local persistenceService = self._dataPersistenceSystem.Service or self._dataPersistenceSystem
        self.Service:SetPersistenceService(persistenceService)
        if type(persistenceService) == "table" and type(persistenceService.SetInventoryService) == "function" then
            persistenceService:SetInventoryService(self.Service)
        end
    end

    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function InventorySystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function InventorySystem:Start()
    self.Service:Start()
    self.Controller:RegisterEventHandlers()
end

function InventorySystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function InventorySystem:Shutdown()
    self:Stop()
end

return InventorySystem

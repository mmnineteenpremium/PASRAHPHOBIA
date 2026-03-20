local State = require(script.Parent.State)
local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)

local DataPersistenceService = {}
DataPersistenceService.__index = DataPersistenceService

function DataPersistenceService.new(deps)
    local self = setmetatable({}, DataPersistenceService)
    self._deps = deps or {}
    self.State = State.new(self._deps.DataPersistenceState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function DataPersistenceService:Init()
    self.Service:Init()
    self.Controller:Init()
end

function DataPersistenceService:Start()
    self.Service:Start()
    self.Controller:RegisterEventHandlers()
end

function DataPersistenceService:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function DataPersistenceService:Shutdown()
    self:Stop()
end

return DataPersistenceService

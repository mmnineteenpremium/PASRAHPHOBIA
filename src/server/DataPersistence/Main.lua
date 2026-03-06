local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local DataPersistence = {}
DataPersistence.__index = DataPersistence

function DataPersistence.new(deps)
    local self = setmetatable({}, DataPersistence)
    self._deps = deps or {}
    self.State = State.new(self._deps.DataPersistenceState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function DataPersistence.Create(deps)
    return DataPersistence.new(deps)
end

function DataPersistence:Init()
    self.Service:Init()
    self.Controller:Init()
end

function DataPersistence:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function DataPersistence:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return DataPersistence

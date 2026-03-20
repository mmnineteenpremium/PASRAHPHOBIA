local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local ContractCompletionSystem = {}
ContractCompletionSystem.__index = ContractCompletionSystem

function ContractCompletionSystem.new(deps)
    local self = setmetatable({}, ContractCompletionSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function ContractCompletionSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function ContractCompletionSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function ContractCompletionSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function ContractCompletionSystem:Shutdown()
    -- lifecycle stub to satisfy SystemRegistry contract
end

return ContractCompletionSystem


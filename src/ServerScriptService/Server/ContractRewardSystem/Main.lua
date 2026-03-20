local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local ContractRewardSystem = {}
ContractRewardSystem.__index = ContractRewardSystem

function ContractRewardSystem.new(deps)
    local self = setmetatable({}, ContractRewardSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.ContractRewardState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function ContractRewardSystem.Create(deps)
    local instance = ContractRewardSystem.new(deps)
    instance:Initialize()
    return instance
end

function ContractRewardSystem:Initialize()
    if self._initialized then
        return
    end
    self._initialized = true
end

function ContractRewardSystem:Init()
    self:Initialize()
    self.Service:Init()
    self.Controller:Init()
end

function ContractRewardSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function ContractRewardSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function ContractRewardSystem:Shutdown()
    self:Stop()
end

return ContractRewardSystem


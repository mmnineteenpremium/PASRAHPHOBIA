local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local ShopSystem = {}
ShopSystem.__index = ShopSystem

function ShopSystem.new(deps)
    local self = setmetatable({}, ShopSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.ShopState or {})
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function ShopSystem.Create(deps)
    return ShopSystem.new(deps)
end

function ShopSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function ShopSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function ShopSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return ShopSystem

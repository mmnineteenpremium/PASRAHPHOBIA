local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local CosmeticSystem = {}
CosmeticSystem.__index = CosmeticSystem

local function getRegistry(deps)
    if type(deps) ~= "table" then
        return nil
    end
    return deps.Services or deps.ServiceRegistry
end

local function hasService(registry, name)
    if type(registry) ~= "table" then
        return false
    end
    if type(registry.GetService) == "function" then
        return registry:GetService(name) ~= nil
    end
    if type(registry.Get) == "function" then
        return registry:Get(name) ~= nil
    end
    if type(registry.HasService) == "function" then
        return registry:HasService(name)
    end
    if type(registry.Has) == "function" then
        return registry:Has(name)
    end
    return false
end

local function registerService(registry, name, service)
    if type(registry) ~= "table" then
        return false
    end
    if type(registry.RegisterService) == "function" then
        return registry:RegisterService(name, service)
    end
    if type(registry.Register) == "function" then
        return registry:Register(name, service)
    end
    return false
end

function CosmeticSystem.new(deps)
    local self = setmetatable({}, CosmeticSystem)
    self._deps = deps or {}
    self._created = false
    self.State = State.new(self._deps.CosmeticState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function CosmeticSystem:Create()
    if self._created then
        return
    end
    self._created = true

    if type(self.Service.Create) == "function" then
        self.Service:Create()
    end
    if type(self.Controller.Create) == "function" then
        self.Controller:Create()
    end

    local registry = getRegistry(self._deps)
    if registry and not hasService(registry, "CosmeticSystem") then
        registerService(registry, "CosmeticSystem", self)
    end
end

function CosmeticSystem:Init()
    self:Create()
    self.Service:Init()
    self.Controller:Init()
end

function CosmeticSystem:Start()
    if type(self.Controller.Start) == "function" then
        self.Controller:Start()
    else
        self.Controller:RegisterEventHandlers()
    end
    self.Service:Start()
end

function CosmeticSystem:Stop()
    if type(self.Controller.Stop) == "function" then
        self.Controller:Stop()
    else
        self.Controller:UnregisterEventHandlers()
    end
    self.Service:Stop()
end

function CosmeticSystem:EquipCosmetic(player, cosmeticId)
    return self.Service:EquipCosmetic(player, cosmeticId)
end

function CosmeticSystem:UnequipCosmetic(player, cosmeticSlot)
    return self.Service:UnequipCosmetic(player, cosmeticSlot)
end

function CosmeticSystem:ValidateOwnership(player, cosmeticId)
    return self.Service:ValidateOwnership(player, cosmeticId)
end

function CosmeticSystem:ApplyCosmetic(player)
    return self.Service:ApplyCosmetic(player)
end

return CosmeticSystem

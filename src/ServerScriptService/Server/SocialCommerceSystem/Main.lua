local function resolveModule(container, childName)
    local direct = container:FindFirstChild(childName)
    if direct and direct:IsA("ModuleScript") then
        return direct
    end

    for _, candidateName in ipairs({
        childName .. ".Lua",
        childName .. ".lua",
    }) do
        local candidate = container:FindFirstChild(candidateName)
        if candidate and candidate:IsA("ModuleScript") then
            return candidate
        end
    end

    error(string.format("[SocialCommerceSystem] Missing module child: %s", tostring(childName)))
end

local Controller = require(resolveModule(script.Parent, "Controller"))
local Service = require(resolveModule(script.Parent, "Service"))
local State = require(resolveModule(script.Parent, "State"))

local SocialCommerceSystem = {}
SocialCommerceSystem.__index = SocialCommerceSystem

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

function SocialCommerceSystem.new(deps)
    local self = setmetatable({}, SocialCommerceSystem)
    self._deps = deps or {}
    self._created = false
    self.State = State.new(self._deps.SocialCommerceState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function SocialCommerceSystem:Initialize()
    if self._created then
        return
    end
    self._created = true

    local registry = getRegistry(self._deps)
    if registry and not hasService(registry, "SocialCommerceSystem") then
        registerService(registry, "SocialCommerceSystem", self)
    end
end

function SocialCommerceSystem:Init()
    self:Initialize()
    self.Service:Init()
    self.Controller:Init()
end

function SocialCommerceSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function SocialCommerceSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

function SocialCommerceSystem:ProcessGiftPurchase(payload)
    return self.Service:ProcessGiftPurchase(payload)
end

return SocialCommerceSystem

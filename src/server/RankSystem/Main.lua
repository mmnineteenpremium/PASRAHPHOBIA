local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local RankSystem = {}
RankSystem.__index = RankSystem

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

function RankSystem.new(deps)
    local self = setmetatable({}, RankSystem)
    self._deps = deps or {}
    self._created = false
    self.State = State.new(self._deps.RankState or {})
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function RankSystem:Create()
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
    if registry and not hasService(registry, "RankSystem") then
        registerService(registry, "RankSystem", self)
    end
end

function RankSystem:Init()
    self:Create()
    self.Service:Init()
    self.Controller:Init()
end

function RankSystem:Start()
    if type(self.Controller.Start) == "function" then
        self.Controller:Start()
    else
        self.Controller:RegisterEventHandlers()
    end
    self.Service:Start()
end

function RankSystem:Stop()
    if type(self.Controller.Stop) == "function" then
        self.Controller:Stop()
    else
        self.Controller:UnregisterEventHandlers()
    end
    self.Service:Stop()
end

function RankSystem:GetPlayerRank(player)
    return self.Service:GetPlayerRank(player)
end

function RankSystem:UpdateStars(player, stars)
    return self.Service:UpdateStars(player, stars)
end

function RankSystem:CheckPromotion(player)
    return self.Service:CheckPromotion(player)
end

function RankSystem:CheckDemotion(player)
    return self.Service:CheckDemotion(player)
end

function RankSystem:CalculateRank(player, levelHint)
    return self.Service:CalculateRank(player, levelHint)
end

return RankSystem
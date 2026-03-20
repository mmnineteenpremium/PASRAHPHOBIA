local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local HorrorDirector = {}
HorrorDirector.__index = HorrorDirector

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

function HorrorDirector.new(deps)
    local self = setmetatable({}, HorrorDirector)
    self._deps = deps or {}
    self._created = false
    self.State = State.new(self._deps.HorrorDirectorState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end


function HorrorDirector.Create(deps)
    local instance = HorrorDirector.new(deps)
    instance:Initialize()
    return instance
end
function HorrorDirector:Initialize()
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
    if registry and not hasService(registry, "HorrorDirector") then
        registerService(registry, "HorrorDirector", self)
    end
end

function HorrorDirector:Init()
    self:Initialize()
    self.Service:Init()
    self.Controller:Init()
end

function HorrorDirector:Start()
    if type(self.Controller.Start) == "function" then
        self.Controller:Start()
    else
        self.Controller:RegisterEventHandlers()
    end
    self.Service:Start()
end

function HorrorDirector:Stop()
    if type(self.Controller.Stop) == "function" then
        self.Controller:Stop()
    else
        self.Controller:UnregisterEventHandlers()
    end
    self.Service:Stop()
end

function HorrorDirector:EvaluateTension(matchId)
    if self.State:Get("activeMatchId") ~= matchId then
        return self.State:Get("currentTension")
    end
    return self.Service:UpdateTension(0, "external_evaluate")
end

function HorrorDirector:ScheduleEvent(matchId)
    if self.State:Get("activeMatchId") ~= matchId then
        return nil
    end
    return self.Service:TriggerEvent()
end

function HorrorDirector:AdjustHuntProbability(matchId)
    if self.State:Get("activeMatchId") ~= matchId then
        return 0
    end
    local tension = self.State:Get("currentTension") or 0
    if tension < 60 then
        return 0.1
    end
    if tension < 90 then
        return 0.35
    end
    return 0.65
end

return HorrorDirector



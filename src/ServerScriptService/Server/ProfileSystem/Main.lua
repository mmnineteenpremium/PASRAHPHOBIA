local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local ProfileSystem = {}
ProfileSystem.__index = ProfileSystem

function ProfileSystem.new(deps)
    local self = setmetatable({}, ProfileSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function ProfileSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function ProfileSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function ProfileSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function ProfileSystem:Shutdown()
    self:Stop()
end

return ProfileSystem

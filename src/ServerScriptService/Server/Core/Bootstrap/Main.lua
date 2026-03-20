local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local Bootstrap = {}
Bootstrap.__index = Bootstrap

function Bootstrap.new(deps)
    local self = setmetatable({}, Bootstrap)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    self.Services = self._deps.Services or self._deps.ServiceRegistry or nil
    return self
end

function Bootstrap:Init()
    self.Service:Init()
    self.Controller:Init()
    local bootOk, bootErr = self.Controller:BootstrapSystems()
    if not bootOk then
        warn(string.format("[Bootstrap] BootstrapSystems failed: %s", tostring(bootErr)))
    end
    local initOk, initErr = self.Controller:InitSystems()
    if not initOk then
        warn(string.format("[Bootstrap] InitSystems failed: %s", tostring(initErr)))
    end
    self.Services = self._deps.Services or self._deps.ServiceRegistry or self.Services
end

function Bootstrap:Start()
    self.Controller:RegisterEventHandlers()
    local ok, err = self.Controller:StartSystems()
    if not ok then
        warn(string.format("[Bootstrap] StartSystems failed: %s", tostring(err)))
    end
    self.Service:Start()
end

function Bootstrap:Stop()
    self.Controller:UnregisterEventHandlers()
    local ok, err = self.Controller:StopSystems()
    if not ok then
        warn(string.format("[Bootstrap] StopSystems encountered issues: %s", tostring(err)))
    end
    self.Service:Stop()
end

function Bootstrap:RestartSystem(systemName)
    return self.Controller:RestartSystem(systemName)
end

function Bootstrap:GetSystemSupervisor()
    return self._deps and self._deps.SystemSupervisor or nil
end

function Bootstrap:GetSystemFactory()
    return self._deps and self._deps.SystemFactory or nil
end

function Bootstrap:GetServices()
    return self.Services or (self._deps and (self._deps.Services or self._deps.ServiceRegistry)) or nil
end

return Bootstrap

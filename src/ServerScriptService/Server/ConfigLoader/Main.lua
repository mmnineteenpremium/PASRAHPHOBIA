local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local ConfigLoaderSystem = {}
ConfigLoaderSystem.__index = ConfigLoaderSystem

function ConfigLoaderSystem.new(deps)
    local self = setmetatable({}, ConfigLoaderSystem)
    self._deps = deps or {}
    self.State = State.new(self._deps.ConfigLoaderState)
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function ConfigLoaderSystem.Create(deps)
    local instance = ConfigLoaderSystem.new(deps)
    instance:Initialize()
    return instance
end

function ConfigLoaderSystem:Initialize()
    if self._initialized then
        return
    end
    self._initialized = true
end

function ConfigLoaderSystem:Init()
    self:Initialize()
    self.Service:Init()
    self.Controller:Init()
end

function ConfigLoaderSystem:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function ConfigLoaderSystem:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return ConfigLoaderSystem


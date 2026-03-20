local Service = {}
Service.__index = Service

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedConfigLoader = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ConfigLoader"):WaitForChild("ConfigLoader"))

local function resolveRegistry(deps)
    if type(deps) ~= "table" then
        return nil
    end
    return deps.Services or deps.ServiceRegistry
end

local function registerAlias(registry, name, service)
    if type(registry) ~= "table" then
        return
    end
    if type(registry.GetService) == "function" and registry:GetService(name) ~= nil then
        return
    end
    if type(registry.Get) == "function" and registry:Get(name) ~= nil then
        return
    end
    if type(registry.RegisterService) == "function" then
        registry:RegisterService(name, service)
        return
    end
    if type(registry.Register) == "function" then
        registry:Register(name, service)
    end
end

function Service.new(state, deps)
    local self = setmetatable({}, Service)
    self._state = state
    self._deps = deps or {}
    self._registry = resolveRegistry(self._deps)
    return self
end

function Service:Init()
    self._state:Set("cache", self._state:Get("cache") or {})
    registerAlias(self._registry, "ConfigLoader", self)
end

function Service:Start()
    -- Config loader is stateless at runtime.
end

function Service:Stop()
    self._state:Clear()
end

function Service:LoadConfig(configName)
    local cache = self._state:Get("cache") or {}
    if cache[configName] ~= nil then
        return cache[configName]
    end
    local data = SharedConfigLoader.GetConfig and SharedConfigLoader.GetConfig(configName)
    if data == nil and type(SharedConfigLoader.loadConfig) == "function" then
        data = SharedConfigLoader.loadConfig(configName)
    end
    cache[configName] = data
    self._state:Set("cache", cache)
    return data
end

function Service:GetConfig(configName)
    local cache = self._state:Get("cache") or {}
    return cache[configName]
end

function Service:ReloadConfig(configName)
    local cache = self._state:Get("cache") or {}
    cache[configName] = nil
    self._state:Set("cache", cache)
    return self:LoadConfig(configName)
end

return Service

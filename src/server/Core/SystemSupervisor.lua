local ServiceRegistry = require(script.Parent.Bootstrap.ServiceRegistry)
local SystemLoader = require(script.Parent.Bootstrap.SystemLoader.Main)

local SystemSupervisor = {}
SystemSupervisor.__index = SystemSupervisor

local function defaultLogger(message)
	warn(message)
end

function SystemSupervisor.new(deps)
	local self = setmetatable({}, SystemSupervisor)
	self._deps = deps or {}
	self._registry = self._deps.Services or self._deps.ServiceRegistry or ServiceRegistry.new()
	self._loader = self._deps.SystemLoader or SystemLoader.new(self._deps)
	self._systemFactories = self._deps.SystemFactories or {}
	self._startedByName = {}
	self._initializedByName = {}
	self._log = self._deps.LogWarning or defaultLogger
	return self
end

function SystemSupervisor:GetRegistry()
	return self._registry
end

function SystemSupervisor:_buildFactoryDeps()
	local combined = {}
	for key, value in pairs(self._deps) do
		combined[key] = value
	end

	for name, system in pairs(self:_getServicesByName()) do
		combined[name] = system
	end
	combined.Services = self._registry
	combined.ServiceRegistry = self._registry
	return combined
end

function SystemSupervisor:_getService(systemName)
	if type(self._registry.GetService) == "function" then
		return self._registry:GetService(systemName)
	end
	if type(self._registry.Get) == "function" then
		return self._registry:Get(systemName)
	end
	return nil
end

function SystemSupervisor:_registerService(systemName, service)
	if type(self._registry.RegisterService) == "function" then
		return self._registry:RegisterService(systemName, service)
	end
	if type(self._registry.Register) == "function" then
		return self._registry:Register(systemName, service)
	end
	return false
end

function SystemSupervisor:_getServicesByName()
	if type(self._registry.GetServicesByName) == "function" then
		return self._registry:GetServicesByName()
	end
	if type(self._registry.GetAll) == "function" then
		return self._registry:GetAll()
	end
	return {}
end

function SystemSupervisor:_resolveFactory(systemName)
	local factory = self._systemFactories[systemName]
	if factory then
		return factory
	end
	return self._loader:GetFactory(systemName)
end

function SystemSupervisor:RegisterSystem(systemName)
	if type(systemName) ~= "string" or systemName == "" then
		return false, "invalid_system_name"
	end

	local existing = self:_getService(systemName)
	if existing then
		return true, existing
	end

	local factory = self:_resolveFactory(systemName)
	if type(factory) ~= "function" then
		return false, "missing_factory"
	end

	local ok, result = pcall(factory, self:_buildFactoryDeps())
	if not ok or type(result) ~= "table" then
		self._log(string.format("[SystemSupervisor] Failed creating system '%s': %s", systemName, tostring(result)))
		return false, "factory_failed"
	end

	if type(result.Stop) ~= "function" then
		self._log(string.format("[SystemSupervisor] System '%s' is missing Stop(); loops/listeners may leak on shutdown.", systemName))
	end

	self:_registerService(systemName, result)
	return true, result
end

function SystemSupervisor:RegisterSystems(startupOrder)
	for _, systemName in ipairs(startupOrder or {}) do
		local ok, err = self:RegisterSystem(systemName)
		if not ok and err ~= "missing_factory" then
			return false, string.format("register_failed:%s", systemName)
		end
	end
	return true
end

function SystemSupervisor:InitSystems(startupOrder)
	for _, systemName in ipairs(startupOrder or {}) do
		local system = self:_getService(systemName)
		if system and self._initializedByName[systemName] ~= true and type(system.Init) == "function" then
			local ok, err = pcall(function()
				system:Init()
			end)
			if not ok then
				self._log(string.format("[SystemSupervisor] Init failed for '%s': %s", systemName, tostring(err)))
				return false, string.format("init_failed:%s", systemName)
			end
			self._initializedByName[systemName] = true
		end
	end
	return true
end

function SystemSupervisor:StartSystems(startupOrder)
	for _, systemName in ipairs(startupOrder or {}) do
		local system = self:_getService(systemName)
		if system and self._startedByName[systemName] ~= true and type(system.Start) == "function" then
			local ok, err = pcall(function()
				system:Start()
			end)
			if not ok then
				self._log(string.format("[SystemSupervisor] Start failed for '%s': %s", systemName, tostring(err)))
				return false, string.format("start_failed:%s", systemName)
			end
			self._startedByName[systemName] = true
		end
	end
	return true
end

function SystemSupervisor:StopSystems(startupOrder)
	local order = startupOrder or {}
	for i = #order, 1, -1 do
		local systemName = order[i]
		local system = self:_getService(systemName)
		if system and self._startedByName[systemName] == true and type(system.Stop) == "function" then
			local ok, err = pcall(function()
				system:Stop()
			end)
			if not ok then
				self._log(string.format("[SystemSupervisor] Stop failed for '%s': %s", systemName, tostring(err)))
			end
		end
		self._startedByName[systemName] = nil
		self._initializedByName[systemName] = nil
	end
	return true
end

function SystemSupervisor:RestartSystem(systemName)
	local system = self:_getService(systemName)
	if not system then
		local ok = self:RegisterSystem(systemName)
		if not ok then
			return false, "missing_system"
		end
		system = self:_getService(systemName)
	end

	if self._startedByName[systemName] == true and type(system.Stop) == "function" then
		local stopOk, stopErr = pcall(function()
			system:Stop()
		end)
		if not stopOk then
			self._log(string.format("[SystemSupervisor] Restart stop failed for '%s': %s", systemName, tostring(stopErr)))
			return false, "restart_stop_failed"
		end
		self._startedByName[systemName] = nil
	end

	if type(system.Init) == "function" then
		local initOk, initErr = pcall(function()
			system:Init()
		end)
		if not initOk then
			self._log(string.format("[SystemSupervisor] Restart init failed for '%s': %s", systemName, tostring(initErr)))
			return false, "restart_init_failed"
		end
		self._initializedByName[systemName] = true
	end

	if type(system.Start) == "function" then
		local startOk, startErr = pcall(function()
			system:Start()
		end)
		if not startOk then
			self._log(string.format("[SystemSupervisor] Restart start failed for '%s': %s", systemName, tostring(startErr)))
			return false, "restart_start_failed"
		end
		self._startedByName[systemName] = true
	end

	return true
end

return SystemSupervisor

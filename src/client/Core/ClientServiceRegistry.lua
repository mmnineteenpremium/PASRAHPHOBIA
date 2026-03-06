local ClientServiceRegistry = {}
ClientServiceRegistry.__index = ClientServiceRegistry

function ClientServiceRegistry.new()
	local self = setmetatable({}, ClientServiceRegistry)
	self._services = {}
	return self
end

function ClientServiceRegistry:Register(name, service)
	if type(name) ~= "string" or name == "" then
		error("ClientServiceRegistry:Register requires a valid name")
	end
	if self._services[name] then
		error(("ClientServiceRegistry:Register duplicate service '%s'"):format(name))
	end
	self._services[name] = service
	return service
end

function ClientServiceRegistry:Get(name)
	return self._services[name]
end

function ClientServiceRegistry:Has(name)
	return self._services[name] ~= nil
end

function ClientServiceRegistry:GetAll()
	return self._services
end

return ClientServiceRegistry

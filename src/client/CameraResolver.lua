local Workspace = game:GetService("Workspace")

local CameraResolver = {}

local DEFAULT_TIMEOUT_SECONDS = 8
local WAIT_STEP_SECONDS = 0.05

function CameraResolver.Resolve(timeoutSeconds)
	local current = Workspace.CurrentCamera
	if current then
		return current
	end

	local timeout = tonumber(timeoutSeconds) or DEFAULT_TIMEOUT_SECONDS
	local deadline = os.clock() + math.max(0, timeout)
	local resolved = nil
	local connection = nil

	connection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		local nextCamera = Workspace.CurrentCamera
		if nextCamera then
			resolved = nextCamera
		end
	end)

	while not resolved and os.clock() < deadline do
		task.wait(WAIT_STEP_SECONDS)
	end

	if connection then
		connection:Disconnect()
	end

	return resolved or Workspace.CurrentCamera
end

function CameraResolver.ResolveOrFallback(timeoutSeconds, fallbackCamera)
	return CameraResolver.Resolve(timeoutSeconds) or fallbackCamera
end

return CameraResolver

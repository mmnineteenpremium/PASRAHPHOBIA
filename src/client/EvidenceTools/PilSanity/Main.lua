local ToolClient = require(script.Parent.Parent.ToolClient)

local PilSanity = {}

function PilSanity.new(evidenceTools, toolType)
	return ToolClient.new(evidenceTools, toolType, {
		activity = 0,
	})
end

return PilSanity

local ToolClient = require(script.Parent.Parent.ToolClient)

local KotakArwah = {}

function KotakArwah.new(evidenceTools, toolType)
	return ToolClient.new(evidenceTools, toolType, {
		activity = 2,
		nearGhostRoom = true,
	})
end

return KotakArwah

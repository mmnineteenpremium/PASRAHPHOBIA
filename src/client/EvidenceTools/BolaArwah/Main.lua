local ToolClient = require(script.Parent.Parent.ToolClient)

local BolaArwah = {}

function BolaArwah.new(evidenceTools, toolType)
	return ToolClient.new(evidenceTools, toolType, {
		activity = 2,
		nearGhostRoom = true,
	})
end

return BolaArwah

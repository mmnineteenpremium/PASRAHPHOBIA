local ToolClient = require(script.Parent.Parent.ToolClient)

local JejakEnergi = {}

function JejakEnergi.new(evidenceTools, toolType)
	return ToolClient.new(evidenceTools, toolType, {
		activity = 2,
		nearGhostRoom = true,
	})
end

return JejakEnergi

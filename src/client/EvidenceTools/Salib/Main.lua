local ToolClient = require(script.Parent.Parent.ToolClient)

local Salib = {}

function Salib.new(evidenceTools, toolType)
	return ToolClient.new(evidenceTools, toolType, {
		nearGhostRoom = true,
	})
end

return Salib

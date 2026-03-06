local ToolClient = require(script.Parent.Parent.ToolClient)

local GerakanGaib = {}

function GerakanGaib.new(evidenceTools, toolType)
	return ToolClient.new(evidenceTools, toolType, {
		activity = 2,
		nearGhostRoom = true,
	})
end

return GerakanGaib

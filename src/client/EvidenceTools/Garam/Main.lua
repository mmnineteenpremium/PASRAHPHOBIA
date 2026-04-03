local ToolClient = require(script.Parent.Parent.ToolClient)

local Garam = {}

function Garam.new(evidenceTools, toolType)
	return ToolClient.new(evidenceTools, toolType, {
		activity = 1,
	})
end

return Garam

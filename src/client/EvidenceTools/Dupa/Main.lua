local ToolClient = require(script.Parent.Parent.ToolClient)

local Dupa = {}

function Dupa.new(evidenceTools, toolType)
	return ToolClient.new(evidenceTools, toolType, {})
end

return Dupa

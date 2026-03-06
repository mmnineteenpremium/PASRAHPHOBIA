local ToolClient = require(script.Parent.Parent.ToolClient)

local SuhuMembeku = {}

function SuhuMembeku.new(evidenceTools, toolType)
	return ToolClient.new(evidenceTools, toolType, {
		activity = 1,
		nearGhostRoom = true,
	})
end

return SuhuMembeku

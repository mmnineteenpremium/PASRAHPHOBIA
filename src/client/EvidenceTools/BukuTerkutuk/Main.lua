local ToolClient = require(script.Parent.Parent.ToolClient)

local BukuTerkutuk = {}

function BukuTerkutuk.new(evidenceTools, toolType)
	return ToolClient.new(evidenceTools, toolType, {
		activity = 1,
		nearGhostRoom = true,
	})
end

return BukuTerkutuk

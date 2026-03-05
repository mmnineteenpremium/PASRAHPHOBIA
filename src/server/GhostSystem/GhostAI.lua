local GhostAI = {}

GhostAI.state = "Idle"

function GhostAI.setState(newState)
	GhostAI.state = newState
	print("Ghost state changed to:", newState)
end

function GhostAI.update()
	print("Ghost AI running in state:", GhostAI.state)
end

return GhostAI

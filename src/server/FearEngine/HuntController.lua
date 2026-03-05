local HuntController = {}

function HuntController.tryStartHunt(aggression)
	local chance = aggression * 0.05
	if math.random() < chance then
		print("Ghost hunt triggered")
	end
end

return HuntController

local AggressionSystem = {}

AggressionSystem.level = 0

function AggressionSystem.increase(amount)
	AggressionSystem.level = AggressionSystem.level + amount
	print("Ghost aggression level:", AggressionSystem.level)
end

function AggressionSystem.get()
	return AggressionSystem.level
end

return AggressionSystem

local EventBus = {}

function EventBus.emit(event, data)
	print("Event:", event)
end

return EventBus

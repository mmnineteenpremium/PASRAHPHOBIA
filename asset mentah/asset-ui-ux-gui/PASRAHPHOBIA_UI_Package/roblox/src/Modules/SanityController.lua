local UIConfig = require(script.Parent.Parent.Shared.UIConfig)

local SanityController = {}
SanityController.__index = SanityController

function SanityController.new(dependencies)
    dependencies = dependencies or {}
    local self = setmetatable({}, SanityController)

    self.Remotes = dependencies.remotes or {}
    self.Value = 100
    self.State = UIConfig.GetSanityState(self.Value)
    self.Connections = {}
    self.Events = {
        Changed = Instance.new("BindableEvent"),
        StateChanged = Instance.new("BindableEvent"),
        ThresholdCrossed = Instance.new("BindableEvent"),
    }

    self:_bindRemotes()
    return self
end

function SanityController:_bindRemotes()
    local remote = self.Remotes[UIConfig.RemoteNames.SanityUpdate]
    if remote then
        self.Connections.SanityUpdate = remote.OnClientEvent:Connect(function(value)
            self:SetValue(value, "RemoteSync")
        end)
    end
end

function SanityController:GetValue()
    return self.Value
end

function SanityController:GetState()
    return self.State
end

function SanityController:SetValue(value, reason)
    local previousValue = self.Value
    local nextValue = math.clamp(tonumber(value) or previousValue, 0, 100)
    if nextValue == previousValue then
        return
    end

    self.Value = nextValue
    self.Events.Changed:Fire(nextValue, previousValue, reason or "SetValue")

    local previousState = self.State
    local nextState = UIConfig.GetSanityState(nextValue)
    if nextState ~= previousState then
        self.State = nextState
        self.Events.StateChanged:Fire(nextState, previousState, nextValue)
        self.Events.ThresholdCrossed:Fire({
            PreviousState = previousState,
            CurrentState = nextState,
            Value = nextValue,
            Reason = reason or "SetValue",
        })
    end
end

function SanityController:Add(amount, reason)
    self:SetValue(self.Value + (tonumber(amount) or 0), reason or "Add")
end

function SanityController:Remove(amount, reason)
    self:SetValue(self.Value - (tonumber(amount) or 0), reason or "Remove")
end

function SanityController:ObserveValue(callback)
    callback(self.Value, self.Value, "Initial")
    return self.Events.Changed.Event:Connect(callback)
end

function SanityController:ObserveState(callback)
    callback(self.State, self.State, self.Value)
    return self.Events.StateChanged.Event:Connect(callback)
end

function SanityController:Destroy()
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    for _, eventObject in pairs(self.Events) do
        eventObject:Destroy()
    end
end

return SanityController

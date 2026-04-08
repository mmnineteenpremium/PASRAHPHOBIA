local ContextActionService = game:GetService("ContextActionService")

local UIConfig = require(script.Parent.Parent.Shared.UIConfig)

local MinimapController = {}
MinimapController.__index = MinimapController

function MinimapController.new(dependencies)
    dependencies = dependencies or {}
    local self = setmetatable({}, MinimapController)

    self.Refs = dependencies.refs or {}
    self.Remotes = dependencies.remotes or {}
    self.Connections = {}
    self.Rooms = {}
    self.ExploredRooms = {}
    self.RoomWidgets = {}
    self.PlayerDirection = Vector3.zAxis
    self.PlayerPosition = Vector3.zero
    self.Expanded = false

    self:_bindInputs()
    self:_bindRemotes()
    return self
end

function MinimapController:_bindInputs()
    ContextActionService:BindAction("PasrahMapToggle", function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            self:ToggleExpanded()
        end
    end, false, Enum.KeyCode.M)

    local minimapButton = self.Refs.MinimapFrame
    if minimapButton then
        self.Connections.MinimapTap = minimapButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                self:ToggleExpanded()
            end
        end)
    end
end

function MinimapController:_bindRemotes()
    local remote = self.Remotes[UIConfig.RemoteNames.MapSync]
    if remote then
        self.Connections.MapSync = remote.OnClientEvent:Connect(function(payload)
            if payload.Rooms then
                self:SetRooms(payload.Rooms)
            end
            if payload.Explored then
                for _, roomId in ipairs(payload.Explored) do
                    self:RevealRoom(roomId)
                end
            end
            if payload.PlayerPosition then
                self:SetPlayerPose(payload.PlayerPosition, payload.PlayerDirection)
            end
            if payload.CurrentRoom then
                self:SetCurrentRoom(payload.CurrentRoom)
            end
        end)
    end
end

function MinimapController:_createRoomWidget(parent, room)
    local frame = Instance.new("Frame")
    frame.Name = room.Id
    frame.BorderSizePixel = 0
    frame.BackgroundColor3 = UIConfig.Theme.Colors.FearBlue
    frame.BackgroundTransparency = 0.9
    frame.Position = UDim2.fromScale(room.X, room.Y)
    frame.Size = UDim2.fromScale(room.Width, room.Height)
    frame.Visible = false
    frame.Parent = parent
    return frame
end

function MinimapController:SetRooms(rooms)
    self.Rooms = rooms or {}
    self.RoomWidgets = {}

    local containers = {
        self.Refs.MinimapCanvas,
        self.Refs.FullMapCanvas,
    }

    for _, container in ipairs(containers) do
        if container then
            for _, child in ipairs(container:GetChildren()) do
                if child:IsA("Frame") and child.Name ~= "PlayerMarker" then
                    child:Destroy()
                end
            end
            self.RoomWidgets[container] = {}
            for _, room in ipairs(self.Rooms) do
                self.RoomWidgets[container][room.Id] = self:_createRoomWidget(container, room)
            end
        end
    end
end

function MinimapController:RevealRoom(roomId)
    self.ExploredRooms[roomId] = true
    for _, widgets in pairs(self.RoomWidgets) do
        local roomWidget = widgets[roomId]
        if roomWidget then
            roomWidget.Visible = true
            roomWidget.BackgroundTransparency = 0.82
        end
    end
end

function MinimapController:SetCurrentRoom(roomId)
    self.CurrentRoomId = roomId
    if self.Refs.RoomNameLabel then
        self.Refs.RoomNameLabel.Text = roomId or "UNKNOWN"
    end
    for _, widgets in pairs(self.RoomWidgets) do
        for id, roomWidget in pairs(widgets) do
            if self.ExploredRooms[id] then
                roomWidget.BackgroundTransparency = id == roomId and 0.72 or 0.82
            end
        end
    end
end

function MinimapController:SetPlayerPose(worldPosition, direction)
    self.PlayerPosition = worldPosition or self.PlayerPosition
    self.PlayerDirection = direction or self.PlayerDirection

    local markers = {
        self.Refs.MinimapPlayer,
        self.Refs.FullMapPlayer,
    }

    local x = self.PlayerPosition.X or 0
    local z = self.PlayerPosition.Z or 0
    local angle = math.atan2(-(self.PlayerDirection.Z or 0), self.PlayerDirection.X or 1)

    for _, marker in ipairs(markers) do
        if marker then
            marker.Position = UDim2.fromScale(x, z)
            marker.Rotation = math.deg(angle)
        end
    end
end

function MinimapController:ToggleExpanded()
    self.Expanded = not self.Expanded
    if self.Refs.FullMapFrame then
        self.Refs.FullMapFrame.Visible = self.Expanded
    end
end

function MinimapController:Destroy()
    ContextActionService:UnbindAction("PasrahMapToggle")
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
end

return MinimapController

local UIConfig = require(script.Parent.Parent.Shared.UIConfig)

local InventoryController = {}
InventoryController.__index = InventoryController

function InventoryController.new(dependencies)
    dependencies = dependencies or {}
    local self = setmetatable({}, InventoryController)

    self.Refs = dependencies.refs or {}
    self.Remotes = dependencies.remotes or {}
    self.Connections = {}
    self.Items = table.create(30)
    self.Filter = "ALL"
    self.SelectedIndex = 1
    self.DragSourceIndex = nil

    self:_bindRemotes()
    self:_bindControls()
    return self
end

function InventoryController:_bindRemotes()
    local remote = self.Remotes[UIConfig.RemoteNames.InventorySnapshot]
    if remote then
        self.Connections.InventorySnapshot = remote.OnClientEvent:Connect(function(snapshot)
            self:SetItems(snapshot.Items or snapshot)
            if snapshot.SelectedIndex then
                self:SelectSlot(snapshot.SelectedIndex)
            end
        end)
    end
end

function InventoryController:_bindControls()
    local filterButtons = self.Refs.FilterButtons or {}
    for filterName, button in pairs(filterButtons) do
        self.Connections["Filter_" .. filterName] = button.Activated:Connect(function()
            self.Filter = filterName
            self:Render()
        end)
    end

    local actionButtons = self.Refs.ActionButtons or {}
    if actionButtons.Equip then
        self.Connections.Equip = actionButtons.Equip.Activated:Connect(function()
            self:EquipSelected()
        end)
    end
    if actionButtons.Drop then
        self.Connections.Drop = actionButtons.Drop.Activated:Connect(function()
            self:DropSelected()
        end)
    end
    if actionButtons.Inspect then
        self.Connections.Inspect = actionButtons.Inspect.Activated:Connect(function()
            self:InspectSelected()
        end)
    end
end

function InventoryController:SetItems(items)
    self.Items = table.create(30)
    for index = 1, 30 do
        self.Items[index] = items[index]
    end
    self:Render()
end

function InventoryController:_passesFilter(item)
    if not item or self.Filter == "ALL" then
        return true
    end
    return string.upper(item.Type or "") == self.Filter
end

function InventoryController:_createSlot(parent, index)
    local button = Instance.new("TextButton")
    button.Name = "Slot_" .. index
    button.Text = ""
    button.AutoButtonColor = false
    button.BorderSizePixel = 0
    button.BackgroundColor3 = UIConfig.Theme.Colors.DeepPanel
    button.BackgroundTransparency = 0.15
    button.Size = UDim2.fromScale(0.155, 0.18)
    button.Parent = parent

    local label = Instance.new("TextLabel")
    label.Name = "ItemLabel"
    label.BackgroundTransparency = 1
    label.Size = UDim2.fromScale(1, 0.26)
    label.Position = UDim2.fromScale(0, 0.72)
    label.TextScaled = true
    label.TextColor3 = UIConfig.Theme.Colors.TextPrimary
    label.Text = "-"
    label.Parent = button

    local stackLabel = Instance.new("TextLabel")
    stackLabel.Name = "StackLabel"
    stackLabel.BackgroundTransparency = 1
    stackLabel.AnchorPoint = Vector2.new(1, 0)
    stackLabel.Position = UDim2.fromScale(0.96, 0.05)
    stackLabel.Size = UDim2.fromScale(0.3, 0.18)
    stackLabel.TextScaled = true
    stackLabel.TextColor3 = UIConfig.Theme.Colors.TextPrimary
    stackLabel.Parent = button

    local durability = Instance.new("Frame")
    durability.Name = "Durability"
    durability.BorderSizePixel = 0
    durability.BackgroundColor3 = UIConfig.Theme.Colors.StaminaAmber
    durability.Position = UDim2.fromScale(0.04, 0.92)
    durability.Size = UDim2.fromScale(0.92, 0.04)
    durability.Parent = button

    self.Connections["Slot_" .. index] = button.Activated:Connect(function()
        self:SelectSlot(index)
        if self.DragSourceIndex and self.DragSourceIndex ~= index then
            self:MoveSlot(self.DragSourceIndex, index)
            self.DragSourceIndex = nil
        end
    end)

    self.Connections["SlotBegin_" .. index] = button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            self.DragSourceIndex = index
        end
    end)

    self.Connections["SlotEnd_" .. index] = button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if self.DragSourceIndex == index then
                self.DragSourceIndex = nil
            end
        end
    end)

    return button
end

function InventoryController:Render()
    local grid = self.Refs.Grid
    if not grid then
        return
    end

    for _, child in ipairs(grid:GetChildren()) do
        if child:IsA("GuiButton") then
            child:Destroy()
        end
    end

    for index = 1, 30 do
        local slot = self:_createSlot(grid, index)
        local item = self.Items[index]

        if item and self:_passesFilter(item) then
            slot.ItemLabel.Text = item.Name or item.Id or "ITEM"
            slot.StackLabel.Text = item.Stack and ("x" .. item.Stack) or ""
            local rarity = UIConfig.Rarities[item.Rarity or "Common"] or UIConfig.Rarities.Common
            slot.BackgroundColor3 = rarity.Color
            slot.Durability.Size = UDim2.fromScale(math.clamp((item.Durability or 100) / 100, 0, 1), 0.04)
        else
            slot.ItemLabel.Text = item and "FILTERED" or "-"
            slot.StackLabel.Text = ""
            slot.BackgroundColor3 = UIConfig.Theme.Colors.DeepPanel
            slot.Durability.Size = UDim2.fromScale(0, 0.04)
        end

        if index == self.SelectedIndex then
            slot.BackgroundTransparency = 0.02
        end
    end

    self:_renderDetail()
    self:_renderWeight()
end

function InventoryController:_renderDetail()
    local item = self.Items[self.SelectedIndex]
    if self.Refs.DetailName then
        self.Refs.DetailName.Text = item and (item.Name or item.Id or "UNKNOWN") or "EMPTY SLOT"
    end
    if self.Refs.DetailDescription then
        self.Refs.DetailDescription.Text = item and (item.Description or "Recovered field item.") or "No item selected."
    end
    if self.Refs.DetailWeight then
        self.Refs.DetailWeight.Text = string.format("%.1f KG", item and (item.Weight or 0) or 0)
    end
    if self.Refs.DetailRarity then
        self.Refs.DetailRarity.Text = string.upper(item and (item.Rarity or "Common") or "None")
    end
end

function InventoryController:_renderWeight()
    local totalWeight = 0
    for _, item in ipairs(self.Items) do
        if item then
            totalWeight += item.Weight or 0
        end
    end
    local maxWeight = 50
    if self.Refs.WeightLabel then
        self.Refs.WeightLabel.Text = string.format("%.1f / %.1f KG", totalWeight, maxWeight)
    end
    if self.Refs.WeightFill then
        self.Refs.WeightFill.Size = UDim2.new(math.clamp(totalWeight / maxWeight, 0, 1), 0, 1, 0)
    end
end

function InventoryController:SelectSlot(index)
    self.SelectedIndex = math.clamp(index, 1, 30)
    self:Render()
end

function InventoryController:MoveSlot(fromIndex, toIndex)
    self.Items[fromIndex], self.Items[toIndex] = self.Items[toIndex], self.Items[fromIndex]
    self.SelectedIndex = toIndex
    self:Render()

    local remote = self.Remotes[UIConfig.RemoteNames.InventoryAction]
    if remote then
        remote:FireServer("Move", { From = fromIndex, To = toIndex })
    end
end

function InventoryController:EquipSelected()
    local item = self.Items[self.SelectedIndex]
    local remote = self.Remotes[UIConfig.RemoteNames.InventoryAction]
    if item and remote then
        remote:FireServer("Equip", item.Id or self.SelectedIndex)
    end
end

function InventoryController:InspectSelected()
    local item = self.Items[self.SelectedIndex]
    if item and self.Refs.DetailDescription then
        self.Refs.DetailDescription.Text = item.Lore or item.Description or "No deeper inspection data."
    end
end

function InventoryController:DropSelected()
    local item = self.Items[self.SelectedIndex]
    local remote = self.Remotes[UIConfig.RemoteNames.InventoryAction]
    if item and remote then
        remote:FireServer("Drop", item.Id or self.SelectedIndex)
    end
end

function InventoryController:Destroy()
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
end

return InventoryController

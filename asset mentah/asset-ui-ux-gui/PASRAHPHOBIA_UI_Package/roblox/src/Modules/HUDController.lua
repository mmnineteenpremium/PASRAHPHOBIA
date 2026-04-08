local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local UIConfig = require(script.Parent.Parent.Shared.UIConfig)

local HUDController = {}
HUDController.__index = HUDController

function HUDController.new(dependencies)
    dependencies = dependencies or {}
    local self = setmetatable({}, HUDController)

    self.Refs = dependencies.refs or {}
    self.Remotes = dependencies.remotes or {}
    self.SanityController = dependencies.sanityController
    self.Animations = dependencies.animations
    self.Connections = {}
    self.Events = {
        InventoryRequested = Instance.new("BindableEvent"),
        MapRequested = Instance.new("BindableEvent"),
        QuickslotRequested = Instance.new("BindableEvent"),
    }

    self.Quickslots = table.create(UIConfig.HUD.QuickslotCount)
    self.ActiveQuickslot = 1
    self.TypewriterHandle = nil
    self.LowSanityFlicker = nil

    self:_bindSanity()
    self:_bindRemotes()
    self:_bindInputs()
    self:_applyTenFootAdjustments()
    return self
end

function HUDController:_applyTenFootAdjustments()
    if GuiService:IsTenFootInterface() and self.Refs.RootScale then
        self.Refs.RootScale.Scale = 1.18
    end
end

function HUDController:_bindSanity()
    if self.SanityController then
        self.Connections.Sanity = self.SanityController:ObserveValue(function(value)
            self:SetSanity(value)
        end)
    end
end

function HUDController:_bindRemotes()
    local objectiveRemote = self.Remotes[UIConfig.RemoteNames.ObjectiveUpdate]
    if objectiveRemote then
        self.Connections.ObjectiveUpdate = objectiveRemote.OnClientEvent:Connect(function(text)
            self:SetObjective(text)
        end)
    end

    local hudRemote = self.Remotes[UIConfig.RemoteNames.HUDSnapshot]
    if hudRemote then
        self.Connections.HUDSnapshot = hudRemote.OnClientEvent:Connect(function(snapshot)
            self:ApplySnapshot(snapshot)
        end)
    end
end

function HUDController:_bindInputs()
    ContextActionService:BindAction("PasrahOpenInventory", function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            self.Events.InventoryRequested:Fire()
        end
    end, false, Enum.KeyCode.I, Enum.KeyCode.ButtonY)

    ContextActionService:BindAction("PasrahToggleMap", function(_, inputState)
        if inputState == Enum.UserInputState.Begin then
            self.Events.MapRequested:Fire()
        end
    end, false, Enum.KeyCode.M, Enum.KeyCode.ButtonSelect)

    local quickslotKeys = {
        Enum.KeyCode.One,
        Enum.KeyCode.Two,
        Enum.KeyCode.Three,
        Enum.KeyCode.Four,
    }

    for index = 1, UIConfig.HUD.QuickslotCount do
        local keyCode = quickslotKeys[index]
        if keyCode then
            ContextActionService:BindAction("PasrahQuickslot" .. index, function(_, inputState)
                if inputState == Enum.UserInputState.Begin then
                    self:SetActiveQuickslot(index)
                    self.Events.QuickslotRequested:Fire(index)
                end
            end, false, keyCode)
        end
    end

    local inventoryButton = self.Refs.InventoryButton
    if inventoryButton then
        self.Connections.InventoryButton = inventoryButton.Activated:Connect(function()
            self.Events.InventoryRequested:Fire()
        end)
    end

    local minimapButton = self.Refs.MinimapButton or self.Refs.MinimapFrame
    if minimapButton then
        self.Connections.MinimapButton = minimapButton.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                self.Events.MapRequested:Fire()
            end
        end)
    end

    if UserInputService.TouchEnabled and self.Refs.TouchHint then
        self.Refs.TouchHint.Visible = true
    end
end

function HUDController:ApplySnapshot(snapshot)
    if not snapshot then
        return
    end
    if snapshot.Sanity ~= nil then
        self:SetSanity(snapshot.Sanity)
    end
    if snapshot.Stamina ~= nil then
        self:SetStamina(snapshot.Stamina)
    end
    if snapshot.Objective then
        self:SetObjective(snapshot.Objective)
    end
    if snapshot.Interaction then
        self:ShowInteraction(snapshot.Interaction.ActionText, snapshot.Interaction.KeyText)
    else
        self:HideInteraction()
    end
    if snapshot.Quickslots then
        self:SetQuickslots(snapshot.Quickslots, snapshot.ActiveQuickslot)
    end
end

function HUDController:_setBar(fillObject, percent, color)
    if not fillObject then
        return
    end
    fillObject.Size = UDim2.new(math.clamp(percent / 100, 0, 1), 0, 1, 0)
    if color then
        fillObject.BackgroundColor3 = color
    end
end

function HUDController:SetSanity(value)
    local clamped = math.clamp(tonumber(value) or 0, 0, 100)
    local alpha = clamped / 100
    local color = UIConfig.Theme.Colors.DangerRed:Lerp(UIConfig.Theme.Colors.SanityGreen, alpha)

    self:_setBar(self.Refs.SanityFill, clamped, color)
    if self.Refs.SanityValue then
        self.Refs.SanityValue.Text = string.format("%d%%", math.floor(clamped + 0.5))
    end
    if self.Refs.FearVignette then
        self.Refs.FearVignette.ImageTransparency = 0.9 - ((1 - alpha) * 0.5)
    end

    if clamped < UIConfig.HUD.LowSanityThreshold then
        if self.Refs.SanityFrame and not self.LowSanityFlicker then
            self.LowSanityFlicker = self.Animations.Flicker(self.Refs.SanityFrame, 0.25, 1 / 60)
        end
    elseif self.LowSanityFlicker then
        self.LowSanityFlicker:Stop()
        self.LowSanityFlicker = nil
    end
end

function HUDController:SetStamina(value)
    local clamped = math.clamp(tonumber(value) or 0, 0, 100)
    self:_setBar(self.Refs.StaminaFill, clamped, UIConfig.Theme.Colors.StaminaAmber)
    if self.Refs.StaminaValue then
        self.Refs.StaminaValue.Text = string.format("%d%%", math.floor(clamped + 0.5))
    end
end

function HUDController:SetObjective(text)
    if not self.Refs.ObjectiveText then
        return
    end
    if self.TypewriterHandle then
        self.TypewriterHandle:Stop()
    end
    self.TypewriterHandle = self.Animations.TypeText(self.Refs.ObjectiveText, text or "", 28)
end

function HUDController:ShowInteraction(actionText, keyText)
    if self.Refs.InteractionFrame then
        self.Refs.InteractionFrame.Visible = true
    end
    if self.Refs.InteractionLabel then
        self.Refs.InteractionLabel.Text = actionText or "INTERACT"
    end
    if self.Refs.InteractionKey then
        self.Refs.InteractionKey.Text = keyText or (UserInputService.TouchEnabled and "TAP" or "E")
    end
end

function HUDController:HideInteraction()
    if self.Refs.InteractionFrame then
        self.Refs.InteractionFrame.Visible = false
    end
end

function HUDController:SetQuickslots(items, activeIndex)
    self.Quickslots = items or self.Quickslots
    self.ActiveQuickslot = activeIndex or self.ActiveQuickslot

    local slotRefs = self.Refs.QuickslotFrames or {}
    for index, slot in ipairs(slotRefs) do
        local item = self.Quickslots[index]
        if slot:FindFirstChild("Label") then
            slot.Label.Text = item and (item.Name or item.Id or "ITEM") or "-"
        end
        slot.BackgroundColor3 = index == self.ActiveQuickslot and UIConfig.Theme.Colors.FearBlue or UIConfig.Theme.Colors.DeepPanel
        slot.BackgroundTransparency = index == self.ActiveQuickslot and 0.2 or 0.35
    end
end

function HUDController:SetActiveQuickslot(index)
    self.ActiveQuickslot = math.clamp(index, 1, UIConfig.HUD.QuickslotCount)
    self:SetQuickslots(self.Quickslots, self.ActiveQuickslot)
end

function HUDController:Destroy()
    ContextActionService:UnbindAction("PasrahOpenInventory")
    ContextActionService:UnbindAction("PasrahToggleMap")
    for index = 1, UIConfig.HUD.QuickslotCount do
        ContextActionService:UnbindAction("PasrahQuickslot" .. index)
    end
    if self.TypewriterHandle then
        self.TypewriterHandle:Stop()
    end
    if self.LowSanityFlicker then
        self.LowSanityFlicker:Stop()
    end
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
    for _, eventObject in pairs(self.Events) do
        eventObject:Destroy()
    end
end

return HUDController

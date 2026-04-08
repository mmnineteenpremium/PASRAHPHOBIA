local UIConfig = require(script.Parent.Parent.Shared.UIConfig)

local EffectsController = {}
EffectsController.__index = EffectsController

function EffectsController.new(dependencies)
    dependencies = dependencies or {}
    local self = setmetatable({}, EffectsController)

    self.Refs = dependencies.refs or {}
    self.Remotes = dependencies.remotes or {}
    self.SanityController = dependencies.sanityController
    self.Animations = dependencies.animations
    self.Connections = {}
    self.ActiveHandles = {}
    self.GhostProximity = 0

    self:_bindSanity()
    self:_bindRemotes()
    self:_applyState("Stable", 100)
    return self
end

function EffectsController:_bindSanity()
    if not self.SanityController then
        return
    end

    self.Connections.SanityState = self.SanityController:ObserveState(function(state, _, value)
        self:_applyState(state, value)
    end)
    self.Connections.SanityValue = self.SanityController:ObserveValue(function(value)
        self:_applyValue(value)
    end)
end

function EffectsController:_bindRemotes()
    local remote = self.Remotes[UIConfig.RemoteNames.EffectsEvent]
    if remote then
        self.Connections.EffectsEvent = remote.OnClientEvent:Connect(function(eventName, payload)
            if eventName == "Jumpscare" then
                self:TriggerJumpscare()
            elseif eventName == "GhostProximity" then
                self:SetGhostProximity(payload or 0)
            elseif eventName == "PasrahFlash" then
                self:FlashPasrah()
            end
        end)
    end
end

function EffectsController:_stopHandle(name)
    local handle = self.ActiveHandles[name]
    if handle and handle.Stop then
        handle:Stop()
    end
    self.ActiveHandles[name] = nil
end

function EffectsController:_applyValue(value)
    local fearRatio = 1 - math.clamp((value or 100) / 100, 0, 1)

    if self.Refs.Vignette then
        self.Refs.Vignette.ImageTransparency = 0.92 - (fearRatio * 0.42)
    end
    if self.Refs.Noise then
        self.Refs.Noise.ImageTransparency = UIConfig.Theme.Transparencies.NoiseIdle - (fearRatio * 0.25)
    end
    if self.Refs.MinimapCorrupt then
        self.Refs.MinimapCorrupt.ImageTransparency = 0.95 - (fearRatio * 0.3) - (self.GhostProximity * 0.25)
    end
end

function EffectsController:_applyState(state, value)
    self:_applyValue(value)

    if state == "Stable" then
        self:_stopHandle("Vibration")
        if self.Refs.GlitchOverlay then
            self.Refs.GlitchOverlay.ImageTransparency = 1
        end
    elseif state == "Uneasy" then
        if self.Refs.GlitchOverlay then
            self.Refs.GlitchOverlay.ImageTransparency = 0.92
        end
    elseif state == "Scared" then
        if self.Refs.GlitchOverlay then
            self.Refs.GlitchOverlay.ImageTransparency = 0.78
        end
        if self.Refs.Root then
            self.ActiveHandles.Vibration = self.Animations.Shake(self.Refs.Root, 0.0012, 0.18)
        end
    elseif state == "Breaking" then
        if self.Refs.GlitchOverlay then
            self.Refs.GlitchOverlay.ImageTransparency = 0.55
        end
        if self.Refs.Root then
            self.ActiveHandles.Vibration = self.Animations.Shake(self.Refs.Root, 0.0025, 0.35)
        end
        if self.Refs.PasrahText then
            self.Refs.PasrahText.Visible = true
        end
    end
end

function EffectsController:SetGhostProximity(amount)
    self.GhostProximity = math.clamp(tonumber(amount) or 0, 0, 1)
    if self.Refs.GlitchOverlay then
        self.Refs.GlitchOverlay.ImageTransparency = math.max(0.4, 0.9 - (self.GhostProximity * 0.45))
    end
    self:_applyValue(self.SanityController and self.SanityController:GetValue() or 100)
end

function EffectsController:TriggerJumpscare()
    if self.Refs.Root then
        self.ActiveHandles.JumpscareShake = self.Animations.Shake(self.Refs.Root, 0.004, 0.2)
    end
    if self.Refs.WhiteFlash then
        self.Refs.WhiteFlash.Visible = true
        self.Refs.WhiteFlash.BackgroundTransparency = 0
        self.Animations.Tween(self.Refs.WhiteFlash, "Quick", { BackgroundTransparency = 1 })
        task.delay(0.05, function()
            if self.Refs.WhiteFlash then
                self.Refs.WhiteFlash.Visible = false
            end
        end)
    end
    if self.Refs.GlitchOverlay then
        self.Refs.GlitchOverlay.ImageTransparency = 0.2
        task.delay(0.8, function()
            if self.Refs.GlitchOverlay then
                self.Refs.GlitchOverlay.ImageTransparency = 0.75
            end
        end)
    end
end

function EffectsController:FlashPasrah()
    if not self.Refs.PasrahText then
        return
    end
    self.Refs.PasrahText.Visible = true
    task.delay(0.4, function()
        if self.Refs.PasrahText then
            self.Refs.PasrahText.Visible = false
        end
    end)
end

function EffectsController:Destroy()
    for _, handle in pairs(self.ActiveHandles) do
        if handle.Stop then
            handle:Stop()
        end
    end
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
end

return EffectsController

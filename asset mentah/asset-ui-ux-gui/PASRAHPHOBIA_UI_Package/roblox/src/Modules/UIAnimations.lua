local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local UIAnimations = {}

UIAnimations.Presets = {
    Quick = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Soft = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Panel = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Slow = TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
}

function UIAnimations.Tween(instance, presetName, properties, overrideTweenInfo)
    local tweenInfo = overrideTweenInfo or UIAnimations.Presets[presetName] or UIAnimations.Presets.Soft
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

function UIAnimations.Flicker(guiObject, duration, interval)
    local handle = { Active = true }
    local startTime = os.clock()
    local originalVisible = guiObject.Visible
    local cadence = interval or (1 / 30)
    local elapsed = 0

    handle.Connection = RunService.RenderStepped:Connect(function(deltaTime)
        if not handle.Active or not guiObject.Parent then
            return
        end

        elapsed += deltaTime
        if elapsed >= cadence then
            elapsed = 0
            guiObject.Visible = not guiObject.Visible
        end

        if os.clock() - startTime >= (duration or 0.25) then
            guiObject.Visible = originalVisible
            handle:Stop()
        end
    end)

    function handle:Stop()
        self.Active = false
        if self.Connection then
            self.Connection:Disconnect()
            self.Connection = nil
        end
        if guiObject.Parent then
            guiObject.Visible = originalVisible
        end
    end

    return handle
end

function UIAnimations.TypeText(label, text, charactersPerSecond)
    local handle = { Active = true }
    local sourceText = text or ""
    local cps = math.max(1, charactersPerSecond or 24)
    local elapsed = 0
    local shown = 0

    label.Text = ""
    handle.Connection = RunService.Heartbeat:Connect(function(deltaTime)
        if not handle.Active or not label.Parent then
            return
        end

        elapsed += deltaTime
        local nextCount = math.floor(elapsed * cps)
        if nextCount ~= shown then
            shown = math.min(#sourceText, nextCount)
            label.Text = string.sub(sourceText, 1, shown)
        end

        if shown >= #sourceText then
            handle:Stop()
        end
    end)

    function handle:Stop()
        self.Active = false
        if self.Connection then
            self.Connection:Disconnect()
            self.Connection = nil
        end
        if label.Parent then
            label.Text = sourceText
        end
    end

    return handle
end

function UIAnimations.Shake(guiObject, amplitudeScale, duration)
    local handle = { Active = true }
    local basePosition = guiObject.Position
    local amplitude = amplitudeScale or 0.003
    local finishAt = os.clock() + (duration or 0.2)

    handle.Connection = RunService.RenderStepped:Connect(function()
        if not handle.Active or not guiObject.Parent then
            return
        end

        if os.clock() >= finishAt then
            guiObject.Position = basePosition
            handle:Stop()
            return
        end

        local xOffset = (math.random() - 0.5) * amplitude
        local yOffset = (math.random() - 0.5) * amplitude
        guiObject.Position = UDim2.new(
            basePosition.X.Scale + xOffset,
            basePosition.X.Offset,
            basePosition.Y.Scale + yOffset,
            basePosition.Y.Offset
        )
    end)

    function handle:Stop()
        self.Active = false
        if self.Connection then
            self.Connection:Disconnect()
            self.Connection = nil
        end
        if guiObject.Parent then
            guiObject.Position = basePosition
        end
    end

    return handle
end

return UIAnimations

local UIConfig = require(script.Parent.Parent.Shared.UIConfig)

local RoyalPassController = {}
RoyalPassController.__index = RoyalPassController

function RoyalPassController.new(dependencies)
    dependencies = dependencies or {}
    local self = setmetatable({}, RoyalPassController)

    self.Refs = dependencies.refs or {}
    self.Remotes = dependencies.remotes or {}
    self.Connections = {}
    self.Season = {
        Number = 1,
        Name = "Whispers Of The Void",
        TimeRemaining = "30D",
        Level = 1,
        XP = 0,
        XPToNext = 100,
        PremiumOwned = false,
        Rewards = {},
    }

    self:_bindRemotes()
    self:_bindControls()
    return self
end

function RoyalPassController:_bindRemotes()
    local remote = self.Remotes[UIConfig.RemoteNames.RoyalPassSync]
    if remote then
        self.Connections.RoyalPassSync = remote.OnClientEvent:Connect(function(snapshot)
            self:SetSeason(snapshot)
        end)
    end
end

function RoyalPassController:_bindControls()
    if self.Refs.BuyButton then
        self.Connections.Buy = self.Refs.BuyButton.Activated:Connect(function()
            self:PurchasePremium()
        end)
    end
end

function RoyalPassController:SetSeason(snapshot)
    if not snapshot then
        return
    end
    for key, value in pairs(snapshot) do
        self.Season[key] = value
    end
    self:Render()
end

function RoyalPassController:_createNode(parent, reward)
    local tile = Instance.new("TextButton")
    tile.Name = string.format("%s_%d", reward.Track or "Free", reward.Level or 1)
    tile.AutoButtonColor = false
    tile.BorderSizePixel = 0
    tile.BackgroundColor3 = (UIConfig.Rarities[reward.Rarity or "Common"] or UIConfig.Rarities.Common).Color
    tile.BackgroundTransparency = reward.Claimed and 0.45 or 0.12
    tile.Size = UDim2.fromScale(0.12, 0.8)
    tile.TextScaled = true
    tile.TextWrapped = true
    tile.TextColor3 = UIConfig.Theme.Colors.TextPrimary
    tile.Text = reward.Name or ("LV " .. tostring(reward.Level))
    tile.Parent = parent

    tile.Activated:Connect(function()
        self:ClaimReward(reward.Level, reward.Track)
    end)

    return tile
end

function RoyalPassController:Render()
    if self.Refs.SeasonLabel then
        self.Refs.SeasonLabel.Text = string.format("SEASON %d  %s", self.Season.Number or 1, self.Season.Name or "")
    end
    if self.Refs.TimeRemainingLabel then
        self.Refs.TimeRemainingLabel.Text = tostring(self.Season.TimeRemaining or "0D")
    end
    if self.Refs.LevelLabel then
        self.Refs.LevelLabel.Text = string.format("LEVEL %d", self.Season.Level or 1)
    end
    if self.Refs.ProgressFill then
        local percent = (self.Season.XPToNext or 0) > 0 and ((self.Season.XP or 0) / self.Season.XPToNext) or 0
        self.Refs.ProgressFill.Size = UDim2.new(math.clamp(percent, 0, 1), 0, 1, 0)
    end
    if self.Refs.BuyButton then
        self.Refs.BuyButton.Visible = not self.Season.PremiumOwned
    end

    local premiumLane = self.Refs.PremiumLane
    local freeLane = self.Refs.FreeLane
    if premiumLane then
        premiumLane:ClearAllChildren()
    end
    if freeLane then
        freeLane:ClearAllChildren()
    end

    for _, reward in ipairs(self.Season.Rewards or {}) do
        if reward.Track == "Premium" and premiumLane then
            self:_createNode(premiumLane, reward)
        elseif freeLane then
            self:_createNode(freeLane, reward)
        end
    end
end

function RoyalPassController:ClaimReward(level, track)
    local remote = self.Remotes[UIConfig.RemoteNames.RoyalPassClaim]
    if remote then
        remote:FireServer(level, track)
    end
end

function RoyalPassController:PurchasePremium()
    local remote = self.Remotes[UIConfig.RemoteNames.RoyalPassPurchase]
    if remote then
        remote:FireServer()
    end
end

function RoyalPassController:Destroy()
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
end

return RoyalPassController

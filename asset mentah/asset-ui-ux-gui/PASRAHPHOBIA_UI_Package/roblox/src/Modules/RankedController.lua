local UIConfig = require(script.Parent.Parent.Shared.UIConfig)

local RankedController = {}
RankedController.__index = RankedController

function RankedController.new(dependencies)
    dependencies = dependencies or {}
    local self = setmetatable({}, RankedController)

    self.Refs = dependencies.refs or {}
    self.Remotes = dependencies.remotes or {}
    self.Connections = {}
    self.TotalStars = 0
    self.RP = 0
    self.History = {}
    self.Stats = {
        Matches = 0,
        Wins = 0,
        Losses = 0,
        WinRate = 0,
        Streak = 0,
    }

    self:_bindRemotes()
    return self
end

function RankedController:_bindRemotes()
    local remote = self.Remotes[UIConfig.RemoteNames.RankedSync]
    if remote then
        self.Connections.RankedSync = remote.OnClientEvent:Connect(function(snapshot)
            self:SetSnapshot(snapshot)
        end)
    end
end

function RankedController:SetSnapshot(snapshot)
    if not snapshot then
        return
    end
    self.TotalStars = snapshot.TotalStars or self.TotalStars
    self.RP = snapshot.RP or self.RP
    self.History = snapshot.History or self.History
    self.Stats = snapshot.Stats or self.Stats
    self:Render()
end

function RankedController:ApplyMatchResult(result)
    self.RP += result.RPDelta or 0
    self.TotalStars = math.max(0, self.TotalStars + (result.StarDelta or 0))
    table.insert(self.History, 1, result)
    if #self.History > 5 then
        table.remove(self.History)
    end
    self:Render()
end

function RankedController:_renderStars(tier)
    local container = self.Refs.StarContainer
    if not container then
        return
    end
    container:ClearAllChildren()

    local starsIntoTier = tier.Final and tier.StarsRequired or (tier.CumulativeStars - self.TotalStars)
    local active = math.clamp(tier.StarsRequired - starsIntoTier, 0, tier.StarsRequired)

    for index = 1, tier.StarsRequired do
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Size = UDim2.fromScale(1 / tier.StarsRequired, 1)
        label.Position = UDim2.fromScale((index - 1) / tier.StarsRequired, 0)
        label.TextScaled = true
        label.Text = index <= active and "★" or "☆"
        label.TextColor3 = index <= active and UIConfig.Theme.Colors.FearBlue or UIConfig.Theme.Colors.TextGhost
        label.Parent = container
    end
end

function RankedController:_renderTierGrid(currentTier)
    local container = self.Refs.TierGrid
    if not container then
        return
    end
    container:ClearAllChildren()

    for index, tier in ipairs(UIConfig.RankTiers) do
        local tile = Instance.new("TextLabel")
        tile.Name = tier.Id
        tile.BorderSizePixel = 0
        tile.Size = UDim2.fromScale(0.19, 0.13)
        tile.Position = UDim2.fromScale(((index - 1) % 5) * 0.2, math.floor((index - 1) / 5) * 0.14)
        tile.TextWrapped = true
        tile.TextScaled = true
        tile.Text = tier.Name
        tile.TextColor3 = UIConfig.Theme.Colors.TextPrimary
        tile.BackgroundColor3 = tier.Id == currentTier.Id and UIConfig.Theme.Colors.FearBlue or UIConfig.Theme.Colors.DeepPanel
        tile.BackgroundTransparency = tier.Id == currentTier.Id and 0.08 or 0.28
        tile.Parent = container
    end
end

function RankedController:_renderHistory()
    local container = self.Refs.HistoryList
    if not container then
        return
    end
    container:ClearAllChildren()

    for index, entry in ipairs(self.History) do
        local row = Instance.new("TextLabel")
        row.BackgroundTransparency = 1
        row.Size = UDim2.fromScale(1, 0.18)
        row.Position = UDim2.fromScale(0, (index - 1) * 0.19)
        row.TextXAlignment = Enum.TextXAlignment.Left
        row.TextScaled = true
        row.TextColor3 = (entry.RPDelta or 0) >= 0 and UIConfig.Theme.Colors.SanityGreen or UIConfig.Theme.Colors.DangerRed
        row.Text = string.format("%s  RP %+d", entry.Result or "MATCH", entry.RPDelta or 0)
        row.Parent = container
    end
end

function RankedController:Render()
    local tier = UIConfig.GetRankTier(self.TotalStars)

    if self.Refs.CurrentRankLabel then
        self.Refs.CurrentRankLabel.Text = tier.Name
    end
    if self.Refs.CurrentBadgeLabel then
        self.Refs.CurrentBadgeLabel.Text = tier.Badge
    end
    if self.Refs.RPLabel then
        self.Refs.RPLabel.Text = string.format("%d RP", self.RP)
    end
    if self.Refs.RPFill then
        self.Refs.RPFill.Size = UDim2.new(math.clamp((self.RP % 100) / 100, 0, 1), 0, 1, 0)
    end
    if self.Refs.StatsLabel then
        self.Refs.StatsLabel.Text = string.format(
            "M %d  W %d  L %d  WR %d%%  STREAK %d",
            self.Stats.Matches or 0,
            self.Stats.Wins or 0,
            self.Stats.Losses or 0,
            self.Stats.WinRate or 0,
            self.Stats.Streak or 0
        )
    end

    self:_renderStars(tier)
    self:_renderTierGrid(tier)
    self:_renderHistory()
end

function RankedController:Destroy()
    for _, connection in pairs(self.Connections) do
        connection:Disconnect()
    end
end

return RankedController

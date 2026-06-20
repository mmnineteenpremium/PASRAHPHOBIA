local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GhostRenderer = {}
GhostRenderer.__index = GhostRenderer

local REFRESH_SECONDS = 0.35
local HIGHLIGHT_NAME = "PasrahGhostVisibilityHighlight"
local LIGHT_NAME = "PasrahGhostVisibilityLight"

local FILL_COLOR = Color3.fromRGB(214, 255, 238)
local OUTLINE_COLOR = Color3.fromRGB(52, 92, 108)
local LIGHT_COLOR = Color3.fromRGB(198, 255, 234)

local function stampGhostRenderState(player, ghostState)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return
	end
	local state = type(ghostState) == "table" and ghostState or {}
	player:SetAttribute("PasrahGhostRenderManifesting", state.isManifesting == true)
	player:SetAttribute("PasrahGhostRenderSpectator", state.isSpectator == true)
	player:SetAttribute("PasrahGhostRenderSanity", tonumber(state.sanity))
	player:SetAttribute("PasrahGhostRenderDistortion", tonumber(state.distortion))
end

local function resolveWorkspacePath(path)
	if type(path) ~= "string" or path == "" then
		return nil
	end
	local cleaned = path:gsub("^game%.", ""):gsub("^Workspace%.", ""):gsub("^workspace%.", "")
	local current = Workspace
	for segment in string.gmatch(cleaned, "[^%.]+") do
		current = current and current:FindFirstChild(segment)
		if not current then
			return nil
		end
	end
	return current
end

local function getMatchRoot(player)
	local matchId = player and player:GetAttribute("MatchId")
	if type(matchId) ~= "string" or matchId == "" then
		return nil
	end
	local activeMatches = Workspace:FindFirstChild("ActiveMatches")
	return activeMatches and activeMatches:FindFirstChild("Match_" .. matchId) or nil
end

local function findGhostModel(player)
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return nil
	end

	local path = player:GetAttribute("PasrahGhostModelPath")
	local model = resolveWorkspacePath(path)
	if model and model:IsA("Model") then
		return model
	end

	local matchRoot = getMatchRoot(player)
	if not matchRoot then
		return nil
	end

	local expectedName = tostring(player:GetAttribute("PasrahGhostModelName") or "")
	local expectedType = tostring(player:GetAttribute("PasrahGhostType") or "")
	for _, descendant in ipairs(matchRoot:GetDescendants()) do
		if descendant:IsA("Model") then
			local ghostType = tostring(descendant:GetAttribute("GhostType") or descendant:GetAttribute("VisualGhostType") or "")
			local runtimeState = tostring(descendant:GetAttribute("RuntimeGhostState") or "")
			local nameMatches = expectedName ~= "" and descendant.Name == expectedName
				or expectedType ~= "" and descendant.Name == ("Ghost_" .. expectedType)
				or descendant.Name:match("^Ghost[_%-]") ~= nil
			local attrMatches = ghostType ~= "" and (
				ghostType == expectedType
				or ghostType == ("Ghost_" .. expectedType)
				or runtimeState ~= ""
			)
			if nameMatches or attrMatches then
				return descendant
			end
		end
	end

	return nil
end

local function getGhostHost(ghostModel)
	if ghostModel and ghostModel:IsA("Model") then
		if ghostModel.PrimaryPart and ghostModel.PrimaryPart:IsA("BasePart") then
			return ghostModel.PrimaryPart
		end
		for _, descendant in ipairs(ghostModel:GetDescendants()) do
			if descendant:IsA("BasePart") then
				return descendant
			end
		end
	end
	return nil
end

local function ensureHighlight(parent)
	local highlight = parent and parent:FindFirstChild(HIGHLIGHT_NAME)
	if highlight and highlight:IsA("Highlight") then
		return highlight
	end
	highlight = Instance.new("Highlight")
	highlight.Name = HIGHLIGHT_NAME
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = FILL_COLOR
	highlight.OutlineColor = OUTLINE_COLOR
	highlight.FillTransparency = 0
	highlight.OutlineTransparency = 0
	highlight.Parent = parent
	return highlight
end

local function ensureLight(parent)
	local light = parent and parent:FindFirstChild(LIGHT_NAME)
	if light and light:IsA("PointLight") then
		return light
	end
	light = Instance.new("PointLight")
	light.Name = LIGHT_NAME
	light.Color = LIGHT_COLOR
	light.Brightness = 6
	light.Range = 32
	light.Shadows = false
	light.Parent = parent
	return light
end

function GhostRenderer:Init(context)
	self._context = context
	self._remotes = context.Remotes
	self._player = Players.LocalPlayer
	self._connections = {}
	self._ghostState = {
		isManifesting = false,
		sanity = 100,
		isSpectator = false,
		distortion = 0,
	}
	self._refreshAccumulator = 0
	self._currentGhostModel = nil
	self._highlight = nil
	self._light = nil
	if self._player then
		self._player:SetAttribute("PasrahGhostRendererActive", true)
	end
	stampGhostRenderState(self._player, self._ghostState)
end

function GhostRenderer:Start()
	local matchEvent = self._remotes.MatchEvent
	local sanityEvent = self._remotes.SanityEvent

	if matchEvent and matchEvent.OnClientEvent then
		table.insert(self._connections, matchEvent.OnClientEvent:Connect(function(payload)
			self:_onMatchEvent(payload)
		end))
	end

	if sanityEvent and sanityEvent.OnClientEvent then
		table.insert(self._connections, sanityEvent.OnClientEvent:Connect(function(payload)
			self:_onSanityEvent(payload)
		end))
	end

	table.insert(self._connections, RunService.Heartbeat:Connect(function(dt)
		self._refreshAccumulator = (self._refreshAccumulator or 0) + dt
		if self._refreshAccumulator >= REFRESH_SECONDS then
			self._refreshAccumulator = 0
			self:_syncVisuals()
		end
	end))

	self:_updateDistortion()
	self:_syncVisuals()
end

function GhostRenderer:Stop()
	for _, connection in ipairs(self._connections) do
		if connection and connection.Disconnect then
			connection:Disconnect()
		end
	end
	self._connections = {}
	if self._highlight and self._highlight.Parent then
		self._highlight:Destroy()
	end
	if self._light and self._light.Parent then
		self._light:Destroy()
	end
	self._currentGhostModel = nil
	self._highlight = nil
	self._light = nil
end

function GhostRenderer:SetSpectatorMode(enabled)
	self._ghostState.isSpectator = enabled == true
	self:_updateDistortion()
	self:_syncVisuals()
end

function GhostRenderer:_onMatchEvent(payload)
	local eventName = payload and payload.eventName
	if eventName == "GhostManifest" then
		self._ghostState.isManifesting = true
	elseif eventName == "GhostManifestEnd" then
		self._ghostState.isManifesting = false
	end
	self:_updateDistortion()
	self:_syncVisuals()
end

function GhostRenderer:_onSanityEvent(payload)
	if type(payload and payload.newSanity) == "number" then
		self._ghostState.sanity = payload.newSanity
		self:_updateDistortion()
	end
end

function GhostRenderer:_updateDistortion()
	local sanityFactor = 1 - math.clamp((self._ghostState.sanity or 100) / 100, 0, 1)
	local spectatorFactor = self._ghostState.isSpectator and 0.35 or 0
	local manifestFactor = self._ghostState.isManifesting and 0.45 or 0
	self._ghostState.distortion = math.clamp(sanityFactor + spectatorFactor + manifestFactor, 0, 1)
	stampGhostRenderState(self._player, self._ghostState)
end

function GhostRenderer:_shouldShowVisuals()
	if RunService:IsStudio() then
		return true
	end
	return self._ghostState.isManifesting == true or self._ghostState.isSpectator == true
end

function GhostRenderer:_syncVisuals()
	local ghostModel = findGhostModel(self._player)
	if ghostModel ~= self._currentGhostModel then
		if self._highlight and self._highlight.Parent then
			self._highlight:Destroy()
		end
		if self._light and self._light.Parent then
			self._light:Destroy()
		end
		self._currentGhostModel = ghostModel
		self._highlight = nil
		self._light = nil
	end

	if not ghostModel then
		return
	end

	local visible = self:_shouldShowVisuals()
	self._highlight = ensureHighlight(ghostModel)
	self._highlight.Adornee = ghostModel
	self._highlight.Enabled = visible

	local host = getGhostHost(ghostModel)
	if host then
		self._light = ensureLight(host)
		self._light.Enabled = visible
	end
end

function GhostRenderer:GetRenderState()
	return self._ghostState
end

return setmetatable({}, GhostRenderer)

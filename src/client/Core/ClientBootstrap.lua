local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientServiceRegistry = require(script.Parent.ClientServiceRegistry)

local EvidenceTools = require(script.Parent.Parent.EvidenceTools.Main)
local GhostRenderer = require(script.Parent.Parent.GhostRenderer.Main)
local SpectatorSystem = require(script.Parent.Parent.SpectatorSystem.Main)
local SoundSystem = require(script.Parent.Parent.SoundSystem.Main)
local UISystem = require(script.Parent.Parent.UI.Main)

local ClientBootstrap = {}
ClientBootstrap.__index = ClientBootstrap

local SYSTEMS = {
	{ name = "EvidenceTools", module = EvidenceTools },
	{ name = "GhostRenderer", module = GhostRenderer },
	{ name = "SpectatorSystem", module = SpectatorSystem },
	{ name = "SoundSystem", module = SoundSystem },
	{ name = "UI", module = UISystem },
}

local REMOTE_NAMES = {
	"EvidenceEvent",
	"LobbyEvent",
	"MatchEvent",
	"PurchaseEvent",
	"SanityEvent",
}

local function resolveRemotes()
	local remoteFolder = ReplicatedStorage:FindFirstChild("RemoteEvents")
	local remotes = {}
	for _, remoteName in ipairs(REMOTE_NAMES) do
		remotes[remoteName] = remoteFolder and remoteFolder:FindFirstChild(remoteName) or nil
	end
	return remotes
end

function ClientBootstrap.new(deps)
	local self = setmetatable({}, ClientBootstrap)
	self._deps = deps or {}
	self._registry = ClientServiceRegistry.new()
	self._remotes = resolveRemotes()
	self._initialized = false
	self._started = false
	return self
end

function ClientBootstrap:Init()
	if self._initialized then
		return
	end

	local context = {
		Registry = self._registry,
		Remotes = self._remotes,
	}

	for _, entry in ipairs(SYSTEMS) do
		local service = self._registry:Register(entry.name, entry.module)
		if type(service.Init) == "function" then
			service:Init(context)
		end
	end

	self._initialized = true
end

function ClientBootstrap:Start()
	if self._started then
		return
	end
	if not self._initialized then
		self:Init()
	end

	local context = {
		Registry = self._registry,
		Remotes = self._remotes,
	}

	for _, entry in ipairs(SYSTEMS) do
		local service = self._registry:Get(entry.name)
		if service and type(service.Start) == "function" then
			service:Start(context)
		end
	end

	self._started = true
end

return ClientBootstrap

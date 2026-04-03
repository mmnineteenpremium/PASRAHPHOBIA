local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientServiceRegistry = require(script.Parent.ClientServiceRegistry)

local function findModule(path)
	local node = script.Parent.Parent
	for _, segment in ipairs(path) do
		if typeof(node) ~= "Instance" then
			return nil
		end
		node = node:FindFirstChild(segment)
		if not node then
			return nil
		end
	end
	return node
end

local function safeRequire(moduleScript, name)
	if not moduleScript then
		warn(("[ClientBootstrap] Missing module: %s"):format(tostring(name)))
		return nil
	end
	local ok, result = pcall(require, moduleScript)
	if not ok then
		warn(("[ClientBootstrap] Failed to require %s: %s"):format(tostring(name), tostring(result)))
		return nil
	end
	return result
end

local EvidenceTools = safeRequire(findModule({ "EvidenceTools", "Main" }), "EvidenceTools")
local GhostAnimationPipeline = safeRequire(findModule({ "GhostAnimationPipeline", "Main" }), "GhostAnimationPipeline")
local GhostRenderer = safeRequire(findModule({ "GhostRenderer", "Main" }), "GhostRenderer")
local SpectatorSystem = safeRequire(findModule({ "SpectatorSystem", "Main" }), "SpectatorSystem")
local SpectatorEffects = safeRequire(findModule({ "SpectatorEffects", "Main" }), "SpectatorEffects")
local SoundSystem = safeRequire(findModule({ "SoundSystem", "Main" }), "SoundSystem")
local UISystem = safeRequire(findModule({ "UI", "Main" }), "UI")
local InvestigationUISystem = safeRequire(findModule({ "InvestigationUISystem", "Main" }), "InvestigationUISystem")
local EvidenceBoardSystem = safeRequire(findModule({ "EvidenceBoardSystem", "Main" }), "EvidenceBoardSystem")
local GhostPredictionSystem = safeRequire(findModule({ "GhostPredictionSystem", "Main" }), "GhostPredictionSystem")

local ClientBootstrap = {}
ClientBootstrap.__index = ClientBootstrap

local SYSTEMS = {}

local function addSystem(name, module)
	if module then
		table.insert(SYSTEMS, { name = name, module = module })
	else
		warn(("[ClientBootstrap] System disabled: %s"):format(tostring(name)))
	end
end

addSystem("EvidenceTools", EvidenceTools)
addSystem("GhostAnimationPipeline", GhostAnimationPipeline)
addSystem("GhostRenderer", GhostRenderer)
addSystem("SpectatorSystem", SpectatorSystem)
addSystem("SpectatorEffects", SpectatorEffects)
addSystem("SoundSystem", SoundSystem)
addSystem("UI", UISystem)
addSystem("InvestigationUISystem", InvestigationUISystem)
addSystem("EvidenceBoardSystem", EvidenceBoardSystem)
addSystem("GhostPredictionSystem", GhostPredictionSystem)

local REMOTE_NAMES = {
	"EvidenceEvent",
	"LobbyEvent",
	"MatchEvent",
	"PurchaseEvent",
	"RoyalPassEvent",
	"SanityEvent",
}

local REMOTE_WAIT_TIMEOUT_SECONDS = 12

local function waitForChild(parent, childName, timeoutSeconds)
	if not parent then
		return nil
	end

	local child = parent:FindFirstChild(childName)
	if child then
		return child
	end

	local ok, waitedChild = pcall(function()
		return parent:WaitForChild(childName, timeoutSeconds)
	end)
	if ok then
		return waitedChild
	end
	return nil
end

local function resolveRemotes()
	local remoteFolder = waitForChild(ReplicatedStorage, "RemoteEvents", REMOTE_WAIT_TIMEOUT_SECONDS)
	local remoteFunctionsFolder = waitForChild(ReplicatedStorage, "RemoteFunctions", REMOTE_WAIT_TIMEOUT_SECONDS)
	local remotes = {}
	for _, remoteName in ipairs(REMOTE_NAMES) do
		remotes[remoteName] = waitForChild(remoteFolder, remoteName, REMOTE_WAIT_TIMEOUT_SECONDS)
	end
	remotes.EvidenceRequest = waitForChild(remoteFunctionsFolder, "EvidenceRequest", REMOTE_WAIT_TIMEOUT_SECONDS)
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
			local ok, err = pcall(service.Init, service, context)
			if not ok then
				warn(("[ClientBootstrap] Init failed for %s: %s"):format(entry.name, tostring(err)))
			end
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

	if not self._remotes or not self._remotes.LobbyEvent then
		self._remotes = resolveRemotes()
	end

	local context = {
		Registry = self._registry,
		Remotes = self._remotes,
	}

	for _, entry in ipairs(SYSTEMS) do
		local service = self._registry:Get(entry.name)
		if service and type(service.Start) == "function" then
			local ok, err = pcall(service.Start, service, context)
			if not ok then
				warn(("[ClientBootstrap] Start failed for %s: %s"):format(entry.name, tostring(err)))
			end
		end
	end

	self._started = true
end

return ClientBootstrap

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local FootstepController = {}
FootstepController.__index = FootstepController

local FOOTSTEP_PROBE_REQUEST_ATTR = "PasrahFootstepProbeRequested"
local FOOTSTEP_PROBE_COUNT_ATTR = "PasrahFootstepProbePlayCount"
local FOOTSTEP_PROBE_TEMPLATE_ATTR = "PasrahFootstepProbeLastTemplate"
local FOOTSTEP_PROBE_MATERIAL_ATTR = "PasrahFootstepProbeLastMaterial"
local FOOTSTEP_PROBE_SOUND_ID_ATTR = "PasrahFootstepProbeLastSoundId"

local DEFAULT_TEMPLATE_NAME = "ConcreteStep_01"
local MATERIAL_TEMPLATE_NAMES = {
	[Enum.Material.Wood] = "Woodstep_01",
	[Enum.Material.WoodPlanks] = "Woodstep_01",
	[Enum.Material.Metal] = "MetalStep_01",
	[Enum.Material.CorrodedMetal] = "MetalStep_01",
	[Enum.Material.DiamondPlate] = "MetalStep_01",
	[Enum.Material.Foil] = "MetalStep_01",
	[Enum.Material.Concrete] = "ConcreteStep_01",
	[Enum.Material.Asphalt] = "ConcreteStep_01",
	[Enum.Material.Brick] = "ConcreteStep_01",
	[Enum.Material.Cobblestone] = "ConcreteStep_01",
	[Enum.Material.Pavement] = "ConcreteStep_01",
	[Enum.Material.Rock] = "ConcreteStep_01",
	[Enum.Material.Slate] = "ConcreteStep_01",
	[Enum.Material.Grass] = "GrassStep_01",
	[Enum.Material.LeafyGrass] = "GrassStep_01",
	[Enum.Material.Ground] = "GrassStep_01",
	[Enum.Material.Sand] = "GrassStep_01",
	[Enum.Material.Snow] = "SnowStep_01",
	[Enum.Material.Ice] = "SnowStep_01",
	[Enum.Material.Glacier] = "SnowStep_01",
}

local function resolveFootstepFolder()
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local audioFolder = assets and assets:FindFirstChild("Audio")
	return audioFolder and audioFolder:FindFirstChild("Footsteps")
end

local function resolveTemplateName(material)
	if typeof(material) ~= "EnumItem" then
		return DEFAULT_TEMPLATE_NAME
	end
	return MATERIAL_TEMPLATE_NAMES[material] or DEFAULT_TEMPLATE_NAME
end

local function stringifyMaterial(material)
	if typeof(material) == "EnumItem" then
		return material.Name
	end
	return tostring(material)
end

function FootstepController:Init(context)
	self._context = context or {}
	self._player = Players.LocalPlayer
	self._connections = {}
	self._templates = {}
	self._random = Random.new()
	self._humanoid = nil
	self._rootPart = nil
	self._lastProbeToken = nil
	self._lastStepAt = 0
	self._enabled = false

	local folder = resolveFootstepFolder()
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Sound") then
				self._templates[child.Name] = child
			end
		end
	end

	self._player:SetAttribute(FOOTSTEP_PROBE_COUNT_ATTR, 0)
	self._player:SetAttribute(FOOTSTEP_PROBE_TEMPLATE_ATTR, "")
	self._player:SetAttribute(FOOTSTEP_PROBE_MATERIAL_ATTR, "")
	self._player:SetAttribute(FOOTSTEP_PROBE_SOUND_ID_ATTR, "")
end

function FootstepController:Start()
	table.insert(self._connections, self._player.CharacterAdded:Connect(function(character)
		self:_bindCharacter(character)
	end))
	table.insert(self._connections, self._player:GetAttributeChangedSignal(FOOTSTEP_PROBE_REQUEST_ATTR):Connect(function()
		self:_handleProbeRequest()
	end))
	table.insert(self._connections, RunService.Heartbeat:Connect(function()
		self:_update()
	end))

	if self._player.Character then
		self:_bindCharacter(self._player.Character)
	end
	self:_handleProbeRequest()
end

function FootstepController:Stop()
	for _, connection in ipairs(self._connections) do
		connection:Disconnect()
	end
	table.clear(self._connections)
	self._humanoid = nil
	self._rootPart = nil
	self._enabled = false
end

function FootstepController:_bindCharacter(character)
	if typeof(character) ~= "Instance" then
		self._humanoid = nil
		self._rootPart = nil
		self._enabled = false
		return
	end

	self._humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
	self._rootPart = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
	self._enabled = self._humanoid ~= nil and self._rootPart ~= nil
	self._lastStepAt = 0
end

function FootstepController:_getTemplateForMaterial(material)
	local templateName = resolveTemplateName(material)
	local template = self._templates[templateName]
	if template and tostring(template.SoundId or template:GetAttribute("AudioContent") or "") ~= "" then
		return templateName, template
	end

	local fallback = self._templates[DEFAULT_TEMPLATE_NAME]
	if fallback and tostring(fallback.SoundId or fallback:GetAttribute("AudioContent") or "") ~= "" then
		return DEFAULT_TEMPLATE_NAME, fallback
	end
	return templateName, nil
end

function FootstepController:_playStep(material, volumeScale)
	if not self._rootPart then
		return false
	end

	local templateName, template = self:_getTemplateForMaterial(material)
	if not template then
		return false
	end

	local runtimeSound = template:Clone()
	runtimeSound.Name = "LocalFootstepRuntime"
	runtimeSound.Looped = false
	runtimeSound.Parent = self._rootPart
	runtimeSound.RollOffMinDistance = 5
	runtimeSound.RollOffMaxDistance = 24
	runtimeSound.Volume = math.clamp((tonumber(runtimeSound.Volume) or 0.24) * (volumeScale or 1), 0.05, 0.6)
	runtimeSound.PlaybackSpeed = math.clamp((tonumber(runtimeSound.PlaybackSpeed) or 1) * self._random:NextNumber(0.94, 1.06), 0.86, 1.12)
	runtimeSound.TimePosition = 0
	runtimeSound:SetAttribute("PasrahFootstepTemplate", templateName)
	runtimeSound:Play()
	Debris:AddItem(runtimeSound, math.max(2, runtimeSound.TimeLength + 0.25))

	self._player:SetAttribute(FOOTSTEP_PROBE_TEMPLATE_ATTR, templateName)
	self._player:SetAttribute(FOOTSTEP_PROBE_MATERIAL_ATTR, stringifyMaterial(material))
	self._player:SetAttribute(FOOTSTEP_PROBE_SOUND_ID_ATTR, tostring(runtimeSound.SoundId or runtimeSound:GetAttribute("AudioContent") or ""))
	self._player:SetAttribute(FOOTSTEP_PROBE_COUNT_ATTR, (tonumber(self._player:GetAttribute(FOOTSTEP_PROBE_COUNT_ATTR)) or 0) + 1)
	return true
end

function FootstepController:_handleProbeRequest()
	local token = self._player:GetAttribute(FOOTSTEP_PROBE_REQUEST_ATTR)
	if token == nil or token == self._lastProbeToken then
		return
	end
	self._lastProbeToken = token

	local material = self._humanoid and self._humanoid.FloorMaterial or Enum.Material.Concrete
	self:_playStep(material, 1)
end

function FootstepController:_update()
	if not self._enabled or not self._humanoid or not self._rootPart then
		return
	end
	if self._player:GetAttribute("InMatch") ~= true then
		return
	end
	if self._humanoid.Health <= 0 then
		return
	end
	if self._humanoid.FloorMaterial == Enum.Material.Air then
		return
	end
	if self._humanoid.MoveDirection.Magnitude <= 0.05 then
		return
	end

	local now = os.clock()
	local walkSpeed = math.max(8, tonumber(self._humanoid.WalkSpeed) or 16)
	local interval = math.clamp(0.5 - math.clamp((walkSpeed - 12) * 0.014, 0, 0.2), 0.22, 0.5)
	if (now - self._lastStepAt) < interval then
		return
	end
	self._lastStepAt = now

	local speedScale = math.clamp(walkSpeed / 16, 0.85, 1.2)
	self:_playStep(self._humanoid.FloorMaterial, 0.9 * speedScale)
end

return setmetatable({}, FootstepController)

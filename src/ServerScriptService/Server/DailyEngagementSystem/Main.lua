local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local DailyEngagementSystem = {}
DailyEngagementSystem.__index = DailyEngagementSystem

local ALIASES = {
	"DailyCheckinSystem",
	"DailyMissionSystem",
	"RoyalPassSystem",
}

local function getRegistry(deps)
	if type(deps) ~= "table" then
		return nil
	end
	return deps.Services or deps.ServiceRegistry
end

local function hasService(registry, name)
	if type(registry) ~= "table" then
		return false
	end
	if type(registry.GetService) == "function" then
		return registry:GetService(name) ~= nil
	end
	if type(registry.Get) == "function" then
		return registry:Get(name) ~= nil
	end
	if type(registry.HasService) == "function" then
		return registry:HasService(name)
	end
	if type(registry.Has) == "function" then
		return registry:Has(name)
	end
	return false
end

local function registerService(registry, name, service)
	if type(registry) ~= "table" then
		return false
	end
	if type(registry.RegisterService) == "function" then
		return registry:RegisterService(name, service)
	end
	if type(registry.Register) == "function" then
		return registry:Register(name, service)
	end
	return false
end

function DailyEngagementSystem.new(deps)
	local self = setmetatable({}, DailyEngagementSystem)
	self._deps = deps or {}
	self._created = false
	self.State = State.new(self._deps.DailyEngagementState or {})
	self.Service = Service.new(self.State, self._deps)
	self.Controller = Controller.new(self.State, self.Service, self._deps)
	return self
end

function DailyEngagementSystem.Create(deps)
	local instance = DailyEngagementSystem.new(deps)
	instance:Initialize()
	return instance
end

function DailyEngagementSystem:Initialize()
	if self._created then
		return
	end
	self._created = true

	if type(self.Service.Create) == "function" then
		self.Service:Create()
	end
	if type(self.Controller.Create) == "function" then
		self.Controller:Create()
	end

	local registry = getRegistry(self._deps)
	if registry then
		for _, aliasName in ipairs(ALIASES) do
			if not hasService(registry, aliasName) then
				registerService(registry, aliasName, self)
			end
		end
	end
end

function DailyEngagementSystem:Init()
	self:Initialize()
	self.Service:Init()
	self.Controller:Init()
end

function DailyEngagementSystem:Start()
	print(">>> DailyEngagementSystem:Start() CALLED BY REGISTRY <<<")
	if type(self.Controller.Start) == "function" then
		print(">>> DailyEngagementSystem calling Controller:Start() now <<<")
		self.Controller:Start()
	end
	self.Service:Start()
	print(">>> DailyEngagementSystem:Start() COMPLETE <<<")
end

function DailyEngagementSystem:Stop()
	if type(self.Controller.Stop) == "function" then
		self.Controller:Stop()
	end
	self.Service:Stop()
end

function DailyEngagementSystem:Shutdown()
	self:Stop()
end

function DailyEngagementSystem:AddXP(...)
	return self.Service:AddXP(...)
end

function DailyEngagementSystem:SetPremiumOwnership(...)
	return self.Service:SetPremiumOwnership(...)
end

function DailyEngagementSystem:GetPlayerSnapshot(...)
	return self.Service:GetPlayerSnapshot(...)
end

function DailyEngagementSystem:ClaimDailyReward(...)
	return self.Service:HandleCheckin(...)
end

function DailyEngagementSystem:GenerateDailyMissions(...)
	return self.Service:ResetDailyIfNeeded(...)
end

function DailyEngagementSystem:GetDailyMissions(...)
	return self.Service:GetDailyMissions(...)
end

function DailyEngagementSystem:UpdateMissionProgress(...)
	return self.Service:UpdateMissionProgress(...)
end

function DailyEngagementSystem:CompleteMission(player, missionId)
	return self.Service:ClaimMissionReward(player, missionId)
end

function DailyEngagementSystem:PullGacha(...)
	return self.Service:PullGacha(...)
end

function DailyEngagementSystem:RefreshQuestRuntime(player)
	return self.Service:RefreshQuestRuntime(player)
end

function DailyEngagementSystem:RefreshAllQuestRuntime()
	return self.Service:RefreshAllQuestRuntime()
end

return DailyEngagementSystem

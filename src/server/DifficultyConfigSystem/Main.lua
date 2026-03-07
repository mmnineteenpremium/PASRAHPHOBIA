local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local DifficultyConfigSystem = {}
DifficultyConfigSystem.__index = DifficultyConfigSystem

function DifficultyConfigSystem.new(deps)
    local self = setmetatable({}, DifficultyConfigSystem)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function DifficultyConfigSystem:Init()
    self.Service:Init()
    self.Controller:Init()
end

function DifficultyConfigSystem:Start()
    self.Controller:Start()
    self.Service:Start()
end

function DifficultyConfigSystem:Stop()
    self.Controller:Stop()
    self.Service:Stop()
end

function DifficultyConfigSystem:GetDifficultyConfigs()
    return self.Service:GetDifficultyConfigs()
end

function DifficultyConfigSystem:GetDifficultyConfig(difficultyName)
    return self.Service:GetDifficultyConfig(difficultyName)
end

return DifficultyConfigSystem

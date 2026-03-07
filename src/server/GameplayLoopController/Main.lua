local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)

local GameplayLoopController = {}
GameplayLoopController.__index = GameplayLoopController

function GameplayLoopController.new(deps)
    local self = setmetatable({}, GameplayLoopController)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    return self
end

function GameplayLoopController:Init()
    self.Service:Init()
    self.Controller:Init()
end

function GameplayLoopController:Start()
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function GameplayLoopController:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

return GameplayLoopController

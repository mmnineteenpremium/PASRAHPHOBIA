local Service = require(script.Parent.Service)
local Controller = require(script.Parent.Controller)
local State = require(script.Parent.State)
local LobbyLocator = require(script.Parent.Parent.Core.LobbyLocator)

local function resolveGeometry()
    local geometry = LobbyLocator.ResolveGeometry("LobbySocialHub", workspace)
    return geometry
end

local LobbySocialHub = {}
LobbySocialHub.__index = LobbySocialHub

function LobbySocialHub.new(deps)
    local self = setmetatable({}, LobbySocialHub)
    self._deps = deps or {}
    self.State = State.new()
    self.Service = Service.new(self.State, self._deps)
    self.Controller = Controller.new(self.State, self.Service, self._deps)
    self.Geometry = nil
    self._warnedMissingGeometry = false
    return self
end

function LobbySocialHub:_refreshGeometry()
    local geometry = resolveGeometry()
    self.Geometry = geometry

    if geometry then
        self._warnedMissingGeometry = false
        return geometry
    end

    if not self._warnedMissingGeometry then
        warn("[LobbySocialHub] Geometry folder missing")
        self._warnedMissingGeometry = true
    end

    return nil
end

function LobbySocialHub:Init()
    self:_refreshGeometry()
    self.Service:Init()
    self.Controller:Init()
end

function LobbySocialHub:Start()
    if not self.Geometry then
        self:_refreshGeometry()
    end
    self.Controller:RegisterEventHandlers()
    self.Service:Start()
end

function LobbySocialHub:Stop()
    self.Controller:UnregisterEventHandlers()
    self.Service:Stop()
end

function LobbySocialHub:Shutdown()
    self:Stop()
end

return LobbySocialHub

local Players = game:GetService("Players")

local QuestJournal = require(script.Parent.QuestJournal)

local QuestUIController = {}
QuestUIController.__index = QuestUIController
QuestUIController._sharedInstance = nil

function QuestUIController.new()
	local self = setmetatable({}, QuestUIController)
	self._initialized = false
	self._journal = nil
	return self
end

function QuestUIController.shared()
	if QuestUIController._sharedInstance then
		return QuestUIController._sharedInstance
	end

	QuestUIController._sharedInstance = QuestUIController.new()
	return QuestUIController._sharedInstance
end

function QuestUIController:Init()
	if self._initialized then
		return
	end

	local player = Players.LocalPlayer
	if not player then
		return
	end

	local playerGui = player:WaitForChild("PlayerGui", 10)
	if not playerGui then
		return
	end

	local trackerGui = playerGui:FindFirstChild("QuestTrackerGui")
	if trackerGui and trackerGui:IsA("ScreenGui") then
		trackerGui.Enabled = false
		trackerGui:Destroy()
	end

	self._journal = QuestJournal.new(playerGui)
	self._initialized = true
end

function QuestUIController:Start()
	if not self._initialized then
		self:Init()
	end
end

return QuestUIController

local Players = game:GetService("Players")

local GraphicsSupport = require(script.Parent.GraphicsSupport)

local CharacterPreviewSupport = {}

local function findPlayerByUserId(userId)
	local target = tonumber(userId)
	if not target then
		return nil
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.UserId == target then
			return plr
		end
	end
	return nil
end

local function stripScripts(root)
	for _, child in ipairs(root:GetDescendants()) do
		if child:IsA("BaseScript") then
			child:Destroy()
		end
	end
end

function CharacterPreviewSupport.buildPreviewCharacterModel(userId)
	local livePlayer = findPlayerByUserId(userId)
	if livePlayer and livePlayer.Character then
		local okClone, clone = pcall(function()
			return livePlayer.Character:Clone()
		end)
		if okClone and clone then
			stripScripts(clone)
			for _, descendant in ipairs(clone:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.Anchored = true
					descendant.CanCollide = false
				end
			end
			return clone
		end
	end

	local numeric = tonumber(userId)
	if numeric then
		local okModel, model = pcall(function()
			return Players:CreateHumanoidModelFromUserId(numeric)
		end)
		if okModel and model then
			for _, descendant in ipairs(model:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.Anchored = true
					descendant.CanCollide = false
				end
			end
			return model
		end
	end

	return nil
end

function CharacterPreviewSupport.render(viewportFrame, userId)
	for _, child in ipairs(viewportFrame:GetChildren()) do
		child:Destroy()
	end

	if not GraphicsSupport.shouldUseHighCostViewportPreview() then
		GraphicsSupport.renderPreviewFallback(viewportFrame, "PLAYER", Color3.fromRGB(108, 126, 152), "3D OFF")
		return true
	end

	local cam = Instance.new("Camera")
	cam.Name = "PreviewCamera"
	cam.Parent = viewportFrame
	viewportFrame.CurrentCamera = cam

	local model = CharacterPreviewSupport.buildPreviewCharacterModel(userId)
	if not model then
		local fallback = Instance.new("Part")
		fallback.Anchored = true
		fallback.CanCollide = false
		fallback.Size = Vector3.new(2.4, 4.8, 1.6)
		fallback.Color = Color3.fromRGB(122, 134, 164)
		fallback.Material = Enum.Material.SmoothPlastic
		fallback.Name = "PreviewFallbackPart"
		fallback.Parent = viewportFrame
		cam.CFrame = CFrame.new(Vector3.new(0, 2.1, 8), Vector3.new(0, 2.1, 0))
		return false
	end

	model.Name = "PreviewCharacter"
	model.Parent = viewportFrame

	local pivotCFrame, size = model:GetBoundingBox()
	local center = pivotCFrame.Position
	local maxSize = math.max(size.X, size.Y, size.Z)
	local distance = maxSize * 1.85 + 2.4
	local cameraOffset = Vector3.new(0, size.Y * 0.15, distance)
	cam.CFrame = CFrame.new(center + cameraOffset, center + Vector3.new(0, size.Y * 0.12, 0))

	return true
end

return CharacterPreviewSupport

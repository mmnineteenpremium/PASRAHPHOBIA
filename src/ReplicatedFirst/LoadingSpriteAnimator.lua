local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")

local LoadingSpriteAnimator = {}

local function readPositiveNumber(value, fallback)
	local numberValue = tonumber(value)
	if numberValue and numberValue > 0 then
		return numberValue
	end
	return fallback
end

local function isAssetUri(value)
	return type(value) == "string" and value:match("^rbxassetid://%d+$") ~= nil
end

function LoadingSpriteAnimator.hasAtlases(config)
	if type(config) ~= "table" or type(config.Atlases) ~= "table" then
		return false
	end

	for _, atlasUri in ipairs(config.Atlases) do
		if isAssetUri(atlasUri) then
			return true
		end
	end

	return false
end

function LoadingSpriteAnimator.preload(config)
	if not LoadingSpriteAnimator.hasAtlases(config) then
		return false, "no_atlases"
	end

	local assets = {}
	for _, atlasUri in ipairs(config.Atlases) do
		if isAssetUri(atlasUri) then
			table.insert(assets, atlasUri)
		end
	end

	if #assets == 0 then
		return false, "no_assets"
	end

	local ok, err = pcall(function()
		ContentProvider:PreloadAsync(assets)
	end)
	if not ok then
		return false, err
	end

	return true
end

function LoadingSpriteAnimator.start(imageLabel, config)
	if not imageLabel or not imageLabel:IsA("ImageLabel") then
		return nil, "invalid_label"
	end
	if not LoadingSpriteAnimator.hasAtlases(config) then
		return nil, "no_atlases"
	end

	local atlases = config.Atlases
	local columns = math.max(1, math.floor(readPositiveNumber(config.Columns, 4)))
	local rows = math.max(1, math.floor(readPositiveNumber(config.Rows, 4)))
	local framesPerAtlas = columns * rows
	local frameWidth = math.floor(readPositiveNumber(config.FrameWidth, 256))
	local frameHeight = math.floor(readPositiveNumber(config.FrameHeight, 144))
	local maxFrames = #atlases * framesPerAtlas
	local totalFrames = math.min(math.floor(readPositiveNumber(config.TotalFrames, maxFrames)), maxFrames)
	local durationSeconds = readPositiveNumber(config.DurationSeconds, nil)
	local frameRate = readPositiveNumber(config.FrameRate, durationSeconds and (totalFrames / durationSeconds) or 30)
	local shouldLoop = config.Loop == true
	if not durationSeconds then
		durationSeconds = totalFrames / frameRate
	end

	if totalFrames <= 0 then
		return nil, "no_frames"
	end

	local screenGui = imageLabel:FindFirstAncestorWhichIsA("ScreenGui")
	local currentAtlasIndex = nil
	local currentFrame = -1
	local elapsed = 0
	local connection = nil

	local function applyFrame(frameIndex)
		local atlasIndex = math.floor(frameIndex / framesPerAtlas) + 1
		local atlasUri = atlases[atlasIndex]
		if not isAssetUri(atlasUri) then
			return
		end

		if currentAtlasIndex ~= atlasIndex then
			imageLabel.Image = atlasUri
			currentAtlasIndex = atlasIndex
		end

		local frameInAtlas = frameIndex % framesPerAtlas
		local column = frameInAtlas % columns
		local row = math.floor(frameInAtlas / columns)

		imageLabel.ImageRectSize = Vector2.new(frameWidth, frameHeight)
		imageLabel.ImageRectOffset = Vector2.new(column * frameWidth, row * frameHeight)
	end

	applyFrame(0)

	connection = RunService.RenderStepped:Connect(function(deltaTime)
		if not imageLabel.Parent then
			connection:Disconnect()
			connection = nil
			return
		end

		if screenGui and not screenGui.Enabled then
			return
		end

		elapsed += deltaTime
		local nextFrame
		if shouldLoop then
			nextFrame = math.floor(elapsed * frameRate) % totalFrames
		else
			nextFrame = math.min(totalFrames - 1, math.floor((elapsed / durationSeconds) * totalFrames))
		end
		if nextFrame == currentFrame then
			if not shouldLoop and elapsed >= durationSeconds and connection then
				connection:Disconnect()
				connection = nil
			end
			return
		end

		currentFrame = nextFrame
		applyFrame(nextFrame)
		if not shouldLoop and elapsed >= durationSeconds and connection then
			connection:Disconnect()
			connection = nil
		end
	end)

	return function()
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end
end

return LoadingSpriteAnimator

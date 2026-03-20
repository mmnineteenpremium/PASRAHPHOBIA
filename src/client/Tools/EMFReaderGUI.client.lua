--[[
    EMF READER INTERACTIVE GUI
    Updates screen display based on electromagnetic readings

    Tool Structure Required:
    - EMFReader/Handle (PrimaryPart)
    - EMFReader/Screen (Part with SurfaceGui)
    - EMFReader/Screen/SurfaceGui/Frame/ReadingLabel

    Based on: CANONICAL_SPECIFICATIONS_v2.md Phase 7.3
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Wait for EMF Reader tool
local emfReader = character:WaitForChild("EMFReader", 10) -- 10 second timeout
if not emfReader then
    warn("[EMFReaderGUI] EMFReader tool not found in character")
    return
end

local screen = emfReader:FindFirstChild("Screen")
if not screen then
    warn("[EMFReaderGUI] Screen part not found in EMFReader")
    return
end

local surfaceGui = screen:FindFirstChild("SurfaceGui")
if not surfaceGui then
    warn("[EMFReaderGUI] SurfaceGui not found on Screen")
    return
end

local readingLabel = surfaceGui.Frame:FindFirstChild("ReadingLabel")
if not readingLabel then
    warn("[EMFReaderGUI] ReadingLabel not found in SurfaceGui")
    return
end

-- LED indicator (optional)
local ledIndicator = emfReader:FindFirstChild("LEDIndicator")

-- Update EMF reading display
local function updateEMFReading(level)
    readingLabel.Text = tostring(level)

    -- Color coding
    if level >= 4 then
        readingLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Red (danger)
        if ledIndicator then
            ledIndicator.Color = Color3.fromRGB(255, 0, 0)
        end
    elseif level >= 2 then
        readingLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Yellow (warning)
        if ledIndicator then
            ledIndicator.Color = Color3.fromRGB(255, 255, 0)
        end
    else
        readingLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Green (safe)
        if ledIndicator then
            ledIndicator.Color = Color3.fromRGB(0, 255, 0)
        end
    end
end

-- Listen for EMF reading updates from server
-- (EvidenceToolSystem will fire RemoteEvent with reading value)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local emfUpdateEvent = remoteEvents:WaitForChild("EMFUpdate", 5)

if emfUpdateEvent then
    emfUpdateEvent.OnClientEvent:Connect(function(level)
        updateEMFReading(level)
    end)
    print("[EMFReaderGUI] Listening for EMF updates")
else
    warn("[EMFReaderGUI] EMFUpdate RemoteEvent not found")
    -- Default to level 0
    updateEMFReading(0)
end

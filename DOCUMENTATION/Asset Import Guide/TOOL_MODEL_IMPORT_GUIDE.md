# TOOL MODEL IMPORT GUIDE — PASRAHPHOBIA

**Priority Tools:** Senter (Flashlight), Detektor MEDOK (EMF Reader), Termometer Suhu  
**Timeline:** Phase 7.3  
**Difficulty:** Easy-Medium (mostly Creator Store search)

---

## DEFAULT LOADOUT TOOLS (IMPLEMENT FIRST)

### 1. Senter (Flashlight) — ALREADY IMPLEMENTED
- **Status:** ✅ Code complete (FlashlightController.client.lua) but not stable, kedua tangan nyala seperti flashlight
- **Visual:** Optional 3D flashlight model in player hand
- **Note:** Currently uses invisible SpotLight + Beam
- **Enhancement:** Add handheld flashlight model for immersion

### 2. Detektor MEDOK (EMF Reader)
- **Type:** Handheld electronic device
- **Size:** ~1-2 studs (handheld scale)
- **Features:**
  - Screen display (SurfaceGui)
  - LED indicator (Neon part)
  - Reading text (1-5 scale)
- **Reference:** Real EMF detectors, K-II meters

### 3. Termometer Suhu (Thermometer)
- **Type:** Digital handheld thermometer
- **Size:** ~1-1.5 studs
- **Features:**
  - Digital display (SurfaceGui)
  - Temperature readout (Celsius)
- **Reference:** Infrared thermometers, digital probes

---

## METHOD 1: CREATOR STORE (RECOMMENDED)

### Search Strategy

**1. Open Toolbox in Studio**
- View → Toolbox (Alt+T)
- Creator Store tab

**2. Search Terms:**
- "EMF detector"
- "EMF reader"
- "handheld device"
- "scanner tool"
- "thermometer"
- "digital thermometer"
- "flashlight model"
- "tactical flashlight"
- "investigation tool"

**3. Filter:**
- **Models** (with Tool or Model type)
- **Free** (easier) or **Paid** (higher quality)
- Check preview before inserting

### Evaluation Criteria

**Good tool models have:**
- ✅ Appropriate size (handheld, 1-3 studs)
- ✅ Handle part (player grips this)
- ✅ Screen/display part (for SurfaceGui)
- ✅ Clean geometry (not too many parts)
- ✅ PrimaryPart set (usually Handle)

**Avoid models with:**
- ❌ Too large/small (not handheld scale)
- ❌ No handle (can't be held properly)
- ❌ Overly complex (100+ parts = lag)
- ❌ Scripts already attached (conflicts with our code)

---

## METHOD 2: CREATE SIMPLE MODELS IN STUDIO

### If Creator Store doesn't have what you need:

### EMF Reader (Simple Build)

```lua
-- Build script (run in Command Bar)
local tool = Instance.new("Tool")
tool.Name = "EMFReader"
tool.RequiresHandle = true
tool.Parent = game.ReplicatedStorage.Assets.Tools

-- Handle (main body)
local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(0.5, 1.5, 0.3)
handle.Material = Enum.Material.Plastic
handle.BrickColor = BrickColor.new("Dark grey")
handle.CanCollide = false
handle.Parent = tool

-- Screen (for SurfaceGui)
local screen = Instance.new("Part")
screen.Name = "Screen"
screen.Size = Vector3.new(0.45, 0.6, 0.05)
screen.Material = Enum.Material.SmoothPlastic
screen.BrickColor = BrickColor.new("Black")
screen.CanCollide = false
screen.Parent = tool

-- Position screen on handle
local weld = Instance.new("WeldConstraint")
weld.Part0 = handle
weld.Part1 = screen
weld.Parent = handle
screen.CFrame = handle.CFrame * CFrame.new(0, 0.3, 0.15)

-- SurfaceGui for display
local surfaceGui = Instance.new("SurfaceGui")
surfaceGui.Parent = screen
surfaceGui.Face = Enum.NormalId.Front
surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
surfaceGui.PixelsPerStud = 100

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Parent = surfaceGui

local readingLabel = Instance.new("TextLabel")
readingLabel.Name = "ReadingLabel"
readingLabel.Size = UDim2.new(0.8, 0, 0.6, 0)
readingLabel.Position = UDim2.new(0.1, 0, 0.2, 0)
readingLabel.BackgroundTransparency = 1
readingLabel.Text = "0"
readingLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
readingLabel.TextScaled = true
readingLabel.Font = Enum.Font.Code
readingLabel.Parent = frame

-- LED Indicator
local led = Instance.new("Part")
led.Name = "LEDIndicator"
led.Size = Vector3.new(0.1, 0.1, 0.05)
led.Shape = Enum.PartType.Cylinder
led.Material = Enum.Material.Neon
led.Color = Color3.fromRGB(0, 255, 0)
led.CanCollide = false
led.Parent = tool

local ledWeld = Instance.new("WeldConstraint")
ledWeld.Part0 = handle
ledWeld.Part1 = led
ledWeld.Parent = handle
led.CFrame = handle.CFrame * CFrame.new(0, -0.6, 0.15)

-- Set PrimaryPart
tool.PrimaryPart = handle

print("EMF Reader created in ReplicatedStorage.Assets.Tools")
```

**Run this in Command Bar to auto-generate EMF Reader model.**

### Thermometer (Simple Build)

```lua
-- Build script
local tool = Instance.new("Tool")
tool.Name = "Thermometer"
tool.RequiresHandle = true
tool.Parent = game.ReplicatedStorage.Assets.Tools

-- Handle (thermometer body)
local handle = Instance.new("Part")
handle.Name = "Handle"
handle.Size = Vector3.new(0.3, 1.2, 0.3)
handle.Material = Enum.Material.Plastic
handle.BrickColor = BrickColor.new("White")
handle.CanCollide = false
handle.Parent = tool

-- Screen
local screen = Instance.new("Part")
screen.Name = "Screen"
screen.Size = Vector3.new(0.25, 0.4, 0.05)
screen.Material = Enum.Material.SmoothPlastic
screen.BrickColor = BrickColor.new("Black")
screen.CanCollide = false
screen.Parent = tool

local weld = Instance.new("WeldConstraint")
weld.Part0 = handle
weld.Part1 = screen
weld.Parent = handle
screen.CFrame = handle.CFrame * CFrame.new(0, 0.3, 0.15)

-- SurfaceGui
local surfaceGui = Instance.new("SurfaceGui")
surfaceGui.Parent = screen
surfaceGui.Face = Enum.NormalId.Front

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Parent = surfaceGui

local tempLabel = Instance.new("TextLabel")
tempLabel.Name = "TemperatureLabel"
tempLabel.Size = UDim2.new(0.9, 0, 0.7, 0)
tempLabel.Position = UDim2.new(0.05, 0, 0.15, 0)
tempLabel.BackgroundTransparency = 1
tempLabel.Text = "20°C"
tempLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
tempLabel.TextScaled = true
tempLabel.Font = Enum.Font.Code
tempLabel.Parent = frame

tool.PrimaryPart = handle

print("Thermometer created in ReplicatedStorage.Assets.Tools")
```

---

## TOOL STRUCTURE (RECOMMENDED)

```
ReplicatedStorage
└── Assets
    └── Tools
        ├── EMFReader (Tool)
        │   ├── Handle (Part, PrimaryPart)
        │   ├── Screen (Part with SurfaceGui)
        │   │   └── SurfaceGui
        │   │       └── Frame
        │   │           └── ReadingLabel (TextLabel)
        │   └── LEDIndicator (Part, Neon)
        │
        ├── Thermometer (Tool)
        │   ├── Handle (Part, PrimaryPart)
        │   └── Screen (Part with SurfaceGui)
        │       └── SurfaceGui
        │           └── Frame
        │               └── TemperatureLabel (TextLabel)
        │
        └── Flashlight (Tool) — Optional 3D model
            ├── Handle (Part, PrimaryPart)
            └── LightEnd (Part for SpotLight attachment)
```

---

## ADDING INTERACTIVE GUI (ALREADY CODED)

### EMF Reader GUI Script

**File:** `EMFReaderGUI.client.lua` (Already created in Phase 7 delivery)

**Location:** StarterPlayer/StarterPlayerScripts/Tools/

**This script:**
- Waits for EMFReader tool in character
- Finds Screen → SurfaceGui → ReadingLabel
- Updates text based on server RemoteEvent
- Changes color (green safe, yellow warning, red danger)

**Setup:**
1. Place tool in StarterPack or give via server script
2. Script auto-detects and hooks up GUI
3. Server fires `RemoteEvents/EMFUpdate` with reading value

### Test Script (Server)

```lua
-- ServerScriptService test script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Give EMF Reader to player on spawn
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        task.wait(2) -- Wait for character load
        
        -- Clone tool to player
        local emfTool = ReplicatedStorage.Assets.Tools.EMFReader:Clone()
        emfTool.Parent = player.Backpack
        
        print("[ToolTest] Gave EMFReader to", player.Name)
        
        -- Test EMF reading update
        task.wait(5)
        local emfUpdate = ReplicatedStorage.RemoteEvents:FindFirstChild("EMFUpdate")
        if emfUpdate then
            emfUpdate:FireClient(player, 3) -- Send reading: 3
            print("[ToolTest] Sent EMF reading: 3")
        end
    end)
end)
```

---

## TOOL FUNCTIONALITY INTEGRATION

### Connect to EvidenceSystem

**In EvidenceSystem (server-side):**

```lua
-- Detect when player uses EMF Reader near evidence node
local function checkEMFReading(player, position)
    local nearestEvidence = findNearestEvidenceNode(position, 10) -- 10 stud range
    
    if nearestEvidence and nearestEvidence.Type == "MEDOK" then
        -- Ghost nearby → High EMF reading
        local reading = 5 -- Max EMF
        local emfUpdate = ReplicatedStorage.RemoteEvents.EMFUpdate
        emfUpdate:FireClient(player, reading)
        
        print("[EvidenceSystem] EMF Reading:", reading)
    else
        -- No ghost → Low reading
        local emfUpdate = ReplicatedStorage.RemoteEvents.EMFUpdate
        emfUpdate:FireClient(player, 1)
    end
end

-- Hook to tool activation
local function onToolActivated(player, tool)
    if tool.Name == "EMFReader" then
        local character = player.Character
        if character then
            local position = character.HumanoidRootPart.Position
            checkEMFReading(player, position)
        end
    end
end
```

---

## VISUAL ENHANCEMENTS (OPTIONAL)

### Add Particle Effects to Tools

**EMF Reader (scanning effect):**
```lua
-- Add to EMFReader/Handle
local particleEmitter = Instance.new("ParticleEmitter")
particleEmitter.Parent = handle
particleEmitter.Texture = "rbxassetid://6490035152" -- Electric spark
particleEmitter.Rate = 10
particleEmitter.Lifetime = NumberRange.new(0.5, 1)
particleEmitter.Speed = NumberRange.new(0, 1)
particleEmitter.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
particleEmitter.Transparency = NumberSequence.new(0.5)
particleEmitter.Enabled = false -- Enable when scanning
```

### Add Sound Effects

**EMF Reader beep:**
```lua
-- Add to tool
local beepSound = Instance.new("Sound")
beepSound.Parent = handle
beepSound.SoundId = "rbxassetid://YOUR_BEEP_SOUND_ID"
beepSound.Volume = 0.5
-- Play when reading changes
```

---

## TESTING CHECKLIST

**For each tool:**

- [ ] Model exists in ReplicatedStorage/Assets/Tools
- [ ] Tool has Handle (PrimaryPart set)
- [ ] Tool has Screen with SurfaceGui
- [ ] SurfaceGui has correct hierarchy (Frame → Label)
- [ ] Tool can be equipped from Backpack
- [ ] Tool appears in player's hand correctly
- [ ] GUI updates when server fires RemoteEvent
- [ ] Text/LED color changes based on reading value

---

## QUICK START: AUTO-GENERATE TOOLS

**Run these commands in Studio Command Bar:**

1. **Create EMF Reader:**
```lua
loadstring(game:HttpGet("https://pastebin.com/raw/YOUR_EMF_SCRIPT"))()
```
*(Or copy-paste the EMF Reader build script from above)*

2. **Create Thermometer:**
```lua
loadstring(game:HttpGet("https://pastebin.com/raw/YOUR_THERM_SCRIPT"))()
```
*(Or copy-paste the Thermometer build script)*

3. **Test in game:**
- Press F5
- Check Backpack for tools
- Equip and verify GUI visible

---

## INTEGRATION WORKFLOW

**Week 1: Basic Tools**
- Create/import EMF Reader model
- Hook up existing EMFReaderGUI.client.lua
- Test with server RemoteEvent

**Week 2: Thermometer**
- Create/import Thermometer model
- Create ThermometerGUI.client.lua (similar to EMF)
- Test temperature updates

**Week 3: Flashlight Enhancement**
- Find/create 3D flashlight model (optional)
- Attach to existing FlashlightController
- Add toggle animation

**Week 4: Additional Tools**
- UV Flashlight (for fingerprints)
- Spirit Box (voice detector)
- Motion Sensor (tripod device)

---

## TROUBLESHOOTING

**Issue:** "Tool doesn't appear in hand"
- **Fix:** Verify PrimaryPart = Handle
- **Fix:** Check Handle is named exactly "Handle"
- **Fix:** Ensure Tool.RequiresHandle = true

**Issue:** "SurfaceGui not visible"
- **Fix:** Check SurfaceGui.Face matches Part face
- **Fix:** Verify PixelsPerStud set (100 recommended)
- **Fix:** Increase Part size if too small

**Issue:** "Text not updating"
- **Fix:** Verify RemoteEvent exists (RemoteEvents/EMFUpdate)
- **Fix:** Check client script running (EMFReaderGUI.client.lua)
- **Fix:** Console check for errors

**Issue:** "Tool too big/small"
- **Fix:** Scale all parts uniformly
- **Fix:** Recommended Handle size: 0.5-1 studs width, 1-2 studs length

---

**END OF TOOL MODEL IMPORT GUIDE**

**Estimated Time:** 1-2 hours (Creator Store) or 30 minutes (auto-generate scripts)

**Miftah, auto-generate scripts = fastest route. Creator Store = better visuals.** ✅

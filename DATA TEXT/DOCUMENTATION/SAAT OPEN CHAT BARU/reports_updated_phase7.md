# PASRAHPHOBIA PROJECT REPORT

Last Updated: 2026-03-17 | Session 5 Complete — Phase 7 Roadmap Added

---

# ROADMAP GLOBAL

| Phase   | Fokus                           | Output                                      | Status      |
| ------- | ------------------------------- | ------------------------------------------- | ----------- |
| Phase 1 | Architecture Foundation         | Boot, SystemRegistry, EventBus              | ✅ DONE     |
| Phase 2 | Core Gameplay Systems           | Match pipeline + teleport                   | ✅ DONE     |
| Phase 3 | Lobby Integration               | Room, ready, queue                          | ✅ DONE     |
| Phase 4 | Gameplay Validation             | Ghost + evidence tuning                     | ✅ DONE     |
| Phase 5 | Meta Systems                    | Economy, rewards, rank                      | ✅ DONE     |
| Phase 6 | Performance & Security          | Profiling + anti-cheat                      | ✅ DONE     |
| Phase 7 | Visual & Atmospheric Integration| 3D Assets, Horror Lighting, VFX/SFX         | ⏳ **NEXT** |
| Phase 8 | Launch Preparation              | Playtest + polish                           | ⏳ FUTURE   |
| Phase 9 | Publish                         | Release + live ops                          | ⏳ FUTURE   |

---

# PROJECT COMPLETION

## Architecture Completion

```
Server Architecture      ███████████████████ 100%
Match System             ███████████████████ 100%
Lobby Integration        ███████████████████ 100%
Gameplay Validation      ████████████████░░░  85%
Ghost AI                 ████████████████░░░  85%
Evidence System          ████████████████░░░  85%
Spectator Distortion     ████████████████░░░  85%
Economy System           ████████████████░░░  85%
Progression System       ████████████████░░░  85%
LiveOps Pipeline         ████████████░░░░░░░  65%
```

## Visual & Atmospheric Completion

```
Visual & Environment     ░░░░░░░░░░░░░░░░░░░   0%
3D Model Integration     ░░░░░░░░░░░░░░░░░░░   0%
Atmospheric Lighting     ░░░░░░░░░░░░░░░░░░░   0%
VFX/SFX Pipeline         ░░░░░░░░░░░░░░░░░░░   0%
Player Movement System   ░░░░░░░░░░░░░░░░░░░   0%
Camera System (FPV Lock) ░░░░░░░░░░░░░░░░░░░   0%
RoyalPass Assets         ░░░░░░░░░░░░░░░░░░░   0%
```

## OVERALL PROJECT PROGRESS

```
████████████████████░░░░░░░░
```

**Estimated Completion: 70%**

> Boot validation: ✅ COMPLETE (84ms, 0 failed)  
> UI Systems: ✅ COMPLETE (RoomBrowser, Queue, Performance Dashboard)  
> Phase 7: ⏳ Visual & Atmospheric Integration — NEXT

---

# EXECUTION PIPELINE (REVISED)

| Phase | Name                              | Status      |
| ----- | --------------------------------- | ----------- |
| 1     | Architecture foundation           | ✅ COMPLETED |
| 2     | Core gameplay systems             | ✅ COMPLETED |
| 3     | Match pipeline                    | ✅ COMPLETED |
| 4     | Lobby and room systems            | ✅ COMPLETED |
| 5     | Gameplay validation               | ✅ COMPLETED |
| 6     | Meta systems                      | ✅ COMPLETED |
| 7     | **Visual & Atmospheric Integration** | ⏳ **NEXT** |
| 8     | Launch preparation                | ⏳ PENDING   |
| 9     | Publish & live ops                | ⏳ PENDING   |

---

# PHASE 7: VISUAL & ATMOSPHERIC INTEGRATION (DETAILED)

**Fokus:** Transformasi sistem backend menjadi pengalaman horor visual yang imersif.

**Duration Estimate:** 3-6 weeks (parallel with code polish)

**Priority:** CRITICAL — Defines player experience quality

---

## 7.1 Environment & Lighting Foundation

**Timeline:** Week 1-2  
**Priority:** CRITICAL

### Deliverables:

#### ⏳ Atmospheric Master
- **Future Lighting Setup**
  - Set `Lighting.Technology = Future`
  - Configure global ambient: `Color3.fromRGB(15, 20, 30)` (dark blue-grey)
  - Set brightness: `0.15` (very dark)
  - Enable `GlobalShadows = true`
  - Configure shadow softness: `ShadowSoftness = 0.2`

- **ColorCorrection**
  - Brightness: `-0.1` (slightly darker)
  - Contrast: `0.2` (sharper shadows)
  - Saturation: `-0.3` (desaturated horror look)
  - TintColor: `Color3.fromRGB(200, 210, 255)` (slight blue tint)

- **Atmosphere**
  - Density: `0.4` (fog visible)
  - Offset: `0.25`
  - Color: `Color3.fromRGB(150, 160, 180)` (misty blue)
  - Decay: `Color3.fromRGB(100, 110, 130)`
  - Glare: `0`
  - Haze: `2`

#### ⏳ Modular Map Kit
- **Asset Sources:**
  - Creator Store (Toolbox): Search "Horror Props", "Modular House", "Abandoned Building"
  - Custom modeling: Blender for unique pieces
  - Priority items:
    - Wall modules (damaged, blood-stained variants)
    - Floor types (wood, concrete, tile with cracks)
    - Doors (creaky, broken, locked variants)
    - Furniture (beds, chairs, tables — abandoned aesthetic)

- **Material Setup:**
  - Use `Enum.Material.Wood` for floors (realistic sound)
  - Use `Enum.Material.Concrete` for walls
  - Apply surface textures via Texture/Decal for detail
  - Enable `CastShadow = true` on all static meshes

#### ⏳ Global Darkness Tech: Flashlight System

**Priority:** CRITICAL (80% of horror feel)

**Implementation:**
```lua
-- StarterPlayer/StarterCharacterScripts/FlashlightController.client.lua

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local head = character:WaitForChild("Head")

-- Flashlight components
local spotlight = Instance.new("SpotLight")
spotlight.Parent = head
spotlight.Face = Enum.NormalId.Front
spotlight.Brightness = 5
spotlight.Range = 50
spotlight.Angle = 45
spotlight.Color = Color3.fromRGB(255, 250, 230) -- Warm white
spotlight.Shadows = true
spotlight.Enabled = false

local beam = Instance.new("Beam")
beam.Parent = head
beam.LightEmission = 1
beam.LightInfluence = 0
beam.Transparency = NumberSequence.new(0.5)
beam.Width0 = 0.5
beam.Width1 = 3
beam.Color = ColorSequence.new(Color3.fromRGB(255, 250, 230))
beam.FaceCamera = true
-- Attach points for beam (head → forward raycast point)

local flashlightOn = false

-- Toggle flashlight
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.F then
        flashlightOn = not flashlightOn
        spotlight.Enabled = flashlightOn
        beam.Enabled = flashlightOn
    end
end)

-- Update beam endpoint (raycast forward from head)
RunService.RenderStepped:Connect(function()
    if flashlightOn then
        local ray = Ray.new(head.Position, head.CFrame.LookVector * spotlight.Range)
        local hit, position = workspace:FindPartOnRay(ray, character)
        -- Update beam Attachment1 position to 'position'
    end
end)
```

**Features:**
- Toggle with `F` key
- SpotLight for illumination
- Beam for visible flashlight cone
- Dynamic beam endpoint (hits walls/objects)
- Battery drain (optional Phase 8 feature)

---

## 7.2 Ghost & Entity Visuals

**Timeline:** Week 2-3  
**Priority:** HIGH

### Deliverables:

#### ⏳ Ghost Rigging & Models

**Ghost Types (Priority Order):**
1. **Pocong** (Shrouded ghost, floating)
2. **Kuntilanak** (Female ghost, long hair)
3. **Genderuwo** (Shadow figure, muscular)

**Model Requirements:**
- Rigged for animation (R15 or custom rig)
- Transparent material: `Transparency = 0.3` (base), `0.0` (manifestation), `1.0` (dematerialization)
- Humanoid-compatible for pathfinding
- LOD (Level of Detail) models for performance

**Asset Sources:**
- Creator Store: Search "Ghost Rig", "Horror Character"
- Custom: Blender modeling + Roblox rigging

#### ⏳ Manifestation VFX

**Effect Components:**
- **Particle Emitter (Mist/Smoke)**
  - `Texture = rbxasset://textures/particles/smoke_main.dds`
  - `Rate = 50` (during manifestation)
  - `Lifetime = NumberRange.new(1, 2)`
  - `Speed = NumberRange.new(0, 2)`
  - `Color = ColorSequence.new(Color3.fromRGB(200, 200, 255))` (ghostly blue)
  - `Transparency = NumberSequence.new({0.5, 1})` (fade out)

- **TweenService (Transparency Fade)**
  ```lua
  local TweenService = game:GetService("TweenService")
  local ghostModel = workspace.ActiveMatches.Match_123.Ghost.Model
  
  -- Manifestation (0.3 → 0.0 over 2 seconds)
  local manifestTween = TweenService:Create(
      ghostModel.PrimaryPart,
      TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
      {Transparency = 0}
  )
  manifestTween:Play()
  ```

- **Sound Effect**
  - Whoosh + static noise during manifestation
  - Attach to ghost HumanoidRootPart
  - `Sound.RollOffMode = Enum.RollOffMode.InverseTapered`
  - `Sound.MaxDistance = 100`

#### ⏳ Hunt Animation Set

**Required Animations:**
- **Walk (Idle/Roaming):** Slow, eerie movement
- **Run (Hunt):** Fast, aggressive sprint
- **Attack (Jumpscare):** Lunge forward with scream
- **Dematerialization:** Fade out while backing away

**Animation Sources:**
- Roblox Animation Editor (custom keyframes)
- Creator Store: Search "Horror Animation"
- Blender + Roblox Animation plugin

**Implementation:**
```lua
-- GhostSystem animation controller
local animator = ghost.Humanoid:WaitForChild("Animator")
local walkAnim = animator:LoadAnimation(ghostAnimations.Walk)
local runAnim = animator:LoadAnimation(ghostAnimations.Run)

-- State-based playback
if ghostState == "Roaming" then
    walkAnim:Play()
elseif ghostState == "Hunting" then
    runAnim:Play()
end
```

---

## 7.3 Tool & Equipment Meshes

**Timeline:** Week 1-2 (Parallel)  
**Priority:** HIGH

### Deliverables:

#### ⏳ 3D Tool Assets

**Replace Placeholder Parts with 3D Models:**

**Tool List:**
1. **EMF Reader**
   - Handheld device (smartphone size)
   - Screen display (SurfaceGui with TextLabel showing 1-5)
   - LED indicator (Neon part, color changes with reading)

2. **Spirit Box**
   - Walkie-talkie style
   - Antenna, speaker grille
   - Screen with waveform (animated Decal)

3. **UV Flashlight**
   - Tactical flashlight body
   - Purple cone light (SpotLight with purple color)
   - UV beam (Beam with purple tint)

4. **Thermometer**
   - Digital display device
   - Screen showing temperature (SurfaceGui TextLabel)
   - Celsius/Fahrenheit toggle

5. **Camera**
   - Instant camera (Polaroid-style)
   - Flash bulb (PointLight burst on use)
   - Viewfinder (camera UI overlay)

6. **Motion Sensor**
   - Tripod-mounted device
   - Radar dish or sensor array
   - Blinking LED (Neon part with script loop)

**Asset Sources:**
- Creator Store: Search "Handheld Device", "Flashlight", "Camera Model"
- Blender: Custom modeling for unique look

#### ⏳ Interactive GUI (Tool Screens)

**Implementation Pattern:**
```lua
-- Example: EMF Reader screen
local emfTool = player.Character:FindFirstChild("EMFReader")
local screen = emfTool:FindFirstChild("Screen") -- Part with SurfaceGui

local surfaceGui = screen:FindFirstChild("SurfaceGui")
local readingLabel = surfaceGui.Frame.ReadingLabel

-- Update reading (called from EvidenceToolSystem)
local function updateEMFReading(level)
    readingLabel.Text = tostring(level)
    readingLabel.TextColor3 = level >= 4 and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 0)
end
```

#### ⏳ ViewModel System (First-Person Hands)

**Priority:** MEDIUM (Phase 8 if time-constrained)

**Features:**
- First-person hand models holding tools
- Animations (idle sway, use tool, toggle flashlight)
- Camera-relative rendering (not affected by character rotation)

**Implementation:**
- Use Camera CFrame to position hand models
- Separate rig for hands (attached to CurrentCamera)
- Tool equip/unequip animations

**Asset Sources:**
- Creator Store: Search "First Person Arms", "FPS Viewmodel"
- Blender: Custom hand models with R15 rig

---

## 7.4 Sensory & Feedback (Audio/Visual)

**Timeline:** Week 3-4  
**Priority:** CRITICAL

### Deliverables:

#### ⏳ 3D Spatial Audio

**Implementation:**
```lua
-- All in-game sounds use SoundService.RespectFilteringEnabled = false
-- Attach sounds to 3D parts for spatial audio

-- Example: Ghost footsteps
local ghostFootstep = Instance.new("Sound")
ghostFootstep.Parent = ghost.HumanoidRootPart
ghostFootstep.SoundId = "rbxassetid://YOUR_FOOTSTEP_ID"
ghostFootstep.RollOffMode = Enum.RollOffMode.InverseTapered
ghostFootstep.RollOffMinDistance = 10
ghostFootstep.RollOffMaxDistance = 100
ghostFootstep.Volume = 0.5
ghostFootstep:Play()
```

**Material-Based Footsteps:**
```lua
-- Detect floor material and play appropriate sound
local raycast = workspace:Raycast(character.HumanoidRootPart.Position, Vector3.new(0, -5, 0))
if raycast then
    local material = raycast.Instance.Material
    local footstepSound = footstepSounds[material] or footstepSounds.Default
    footstepSound:Play()
end
```

**Reverb by Room:**
- Use `SoundGroup` with `ReverbSoundEffect`
- Assign different reverb presets per room type:
  - Large hall: High reverb (Decay = 5s)
  - Small room: Low reverb (Decay = 1s)
  - Outdoor: No reverb (Decay = 0.2s)

#### ⏳ Sanity Visual FX

**Effect Components:**

**Vignette (Edge Darkening):**
```lua
-- StarterGui/ScreenGui/VignetteFrame
local vignetteFrame = Instance.new("Frame")
vignetteFrame.Name = "Vignette"
vignetteFrame.Size = UDim2.new(1, 0, 1, 0)
vignetteFrame.Position = UDim2.new(0, 0, 0, 0)
vignetteFrame.BackgroundTransparency = 1
vignetteFrame.ZIndex = 10

local vignetteImage = Instance.new("ImageLabel")
vignetteImage.Parent = vignetteFrame
vignetteImage.Size = UDim2.new(1, 0, 1, 0)
vignetteImage.Image = "rbxassetid://YOUR_VIGNETTE_TEXTURE"
vignetteImage.ImageTransparency = 0.5 -- Changes based on sanity
vignetteImage.BackgroundTransparency = 1

-- Update based on sanity
local function updateVignette(sanity)
    local intensity = 1 - (sanity / 100) -- 0 sanity = full vignette
    vignetteImage.ImageTransparency = 1 - intensity
end
```

**Blur Effect:**
```lua
-- Lighting/BlurEffect
local blurEffect = Instance.new("BlurEffect")
blurEffect.Parent = game.Lighting
blurEffect.Size = 0 -- Default

-- Update based on sanity
local function updateBlur(sanity)
    blurEffect.Size = (100 - sanity) / 10 -- 0 sanity = 10 blur
end
```

**Color Desaturation:**
```lua
-- Lighting/ColorCorrectionEffect
local colorCorrection = game.Lighting:FindFirstChild("ColorCorrectionEffect")

local function updateSaturation(sanity)
    colorCorrection.Saturation = -0.5 + (sanity / 200) -- 0 sanity = -0.5, 100 sanity = 0
end
```

**Heartbeat Sound:**
```lua
-- Players/LocalPlayer/PlayerGui/ScreenGui/HeartbeatSound
local heartbeatSound = Instance.new("Sound")
heartbeatSound.Parent = player.PlayerGui
heartbeatSound.SoundId = "rbxassetid://YOUR_HEARTBEAT_ID"
heartbeatSound.Looped = true
heartbeatSound.Volume = 0

-- Update based on sanity
local function updateHeartbeat(sanity)
    if sanity < 50 then
        heartbeatSound.Volume = (50 - sanity) / 50 -- Volume increases as sanity drops
        heartbeatSound.PlaybackSpeed = 1 + ((50 - sanity) / 100) -- Faster at low sanity
        if not heartbeatSound.IsPlaying then
            heartbeatSound:Play()
        end
    else
        heartbeatSound:Stop()
    end
end
```

#### ⏳ Evidence Visuals

**Freezing Temperature (Cold Breath):**
```lua
-- ParticleEmitter attached to player Head
local coldBreath = Instance.new("ParticleEmitter")
coldBreath.Parent = character.Head
coldBreath.Texture = "rbxasset://textures/particles/smoke_main.dds"
coldBreath.Rate = 10
coldBreath.Lifetime = NumberRange.new(0.5, 1)
coldBreath.Speed = NumberRange.new(1, 3)
coldBreath.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
coldBreath.Transparency = NumberSequence.new({0.3, 1})
coldBreath.Size = NumberSequence.new({0.2, 0.5})
coldBreath.Enabled = false

-- Enable when room temp < 5°C
if roomTemperature < 5 then
    coldBreath.Enabled = true
else
    coldBreath.Enabled = false
end
```

**UV Fingerprints (Decals):**
```lua
-- Spawn Decal on surface when UV light hits evidence node
local fingerprint = Instance.new("Decal")
fingerprint.Parent = evidenceNode.Part
fingerprint.Face = Enum.NormalId.Top -- Or wall face
fingerprint.Texture = "rbxassetid://YOUR_FINGERPRINT_TEXTURE"
fingerprint.Transparency = 1 -- Hidden by default

-- Reveal with UV light
local uvLight = player.Character:FindFirstChild("UVFlashlight")
if uvLight and uvLight.Enabled then
    local distance = (uvLight.Position - fingerprint.Parent.Position).Magnitude
    if distance < 10 then
        fingerprint.Transparency = 0 -- Visible under UV
    end
else
    fingerprint.Transparency = 1 -- Hidden
end
```

**Ghost Orb (Floating Light):**
```lua
-- Create orb part with PointLight
local orb = Instance.new("Part")
orb.Parent = workspace.ActiveMatches.Match_123.Evidence
orb.Size = Vector3.new(0.5, 0.5, 0.5)
orb.Shape = Enum.PartType.Ball
orb.Material = Enum.Material.Neon
orb.BrickColor = BrickColor.new("Cyan")
orb.Transparency = 0.5
orb.CanCollide = false
orb.Anchored = true

local orbLight = Instance.new("PointLight")
orbLight.Parent = orb
orbLight.Brightness = 2
orbLight.Range = 10
orbLight.Color = Color3.fromRGB(0, 255, 255)

-- Float animation (sine wave)
local RunService = game:GetService("RunService")
local startY = orb.Position.Y
RunService.Heartbeat:Connect(function()
    orb.Position = orb.Position + Vector3.new(0, math.sin(tick() * 2) * 0.01, 0)
end)
```

---

## 7.5 Player Movement & Camera System

**Timeline:** Week 1 (Parallel)  
**Priority:** CRITICAL

### Deliverables:

#### ⏳ Realistic Player Movement

**StarterPlayer Configuration:**
```lua
-- Set in StarterPlayer properties (Studio)
StarterPlayer.CharacterWalkSpeed = 10 -- Realistic human walk (was 16)
StarterPlayer.CharacterJumpPower = 32 -- Realistic jump height (was 50)
StarterPlayer.CharacterUseJumpPower = true -- Enable JumpPower (not JumpHeight)
```

**Script-based fine-tuning:**
```lua
-- StarterPlayer/StarterCharacterScripts/MovementController.client.lua
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Movement speeds
local WALK_SPEED = 10 -- studs/s (normal walk)
local SPRINT_SPEED = 14 -- studs/s (sprint with Shift)
local CROUCH_SPEED = 5 -- studs/s (crouch with Ctrl)

humanoid.WalkSpeed = WALK_SPEED

-- Sprint toggle
local UserInputService = game:GetService("UserInputService")
local sprinting = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.LeftShift then
        sprinting = true
        humanoid.WalkSpeed = SPRINT_SPEED
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        sprinting = false
        humanoid.WalkSpeed = WALK_SPEED
    end
end)
```

#### ⏳ First-Person View Lock (IN-GAME ONLY)

**Critical Rule:** FPV locked during investigation, TPV allowed in LobbySocialHub

**Implementation:**
```lua
-- StarterPlayer/StarterCharacterScripts/CameraController.client.lua
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local FPV_LOCKED = false -- Set to true when match starts

-- Detect map (if in investigation map → lock FPV)
player.CharacterAdded:Connect(function(character)
    local currentMap = character:FindFirstAncestorOfClass("Folder") -- Match folder
    if currentMap and currentMap.Name:match("Match_") then
        FPV_LOCKED = true
        camera.CameraType = Enum.CameraType.Custom
        player.CameraMode = Enum.CameraMode.LockFirstPerson
    else
        FPV_LOCKED = false
        player.CameraMode = Enum.CameraMode.Classic -- Allow zoom in lobby
    end
end)
```

#### ⏳ Head Bobbing (Camera Sway)

**Effect:** Camera moves slightly up/down and side-to-side when walking

**Implementation:**
```lua
-- StarterPlayer/StarterCharacterScripts/HeadBob.client.lua
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

local bobFrequency = 2 -- Bob cycles per second
local bobAmplitude = 0.1 -- Vertical bob amount (studs)
local swayAmplitude = 0.05 -- Horizontal sway amount (studs)

local bobOffset = Vector3.new(0, 0, 0)

RunService.RenderStepped:Connect(function(deltaTime)
    if humanoid.MoveDirection.Magnitude > 0 then
        -- Walking - apply bob
        local time = tick()
        local verticalBob = math.sin(time * bobFrequency * 2 * math.pi) * bobAmplitude
        local horizontalSway = math.sin(time * bobFrequency * math.pi) * swayAmplitude
        
        bobOffset = Vector3.new(horizontalSway, verticalBob, 0)
    else
        -- Standing still - reduce bob
        bobOffset = bobOffset:Lerp(Vector3.new(0, 0, 0), deltaTime * 5)
    end
    
    -- Apply offset to camera
    camera.CFrame = camera.CFrame * CFrame.new(bobOffset)
end)
```

---

## 7.6 RoyalPass Asset Planning

**Timeline:** Week 4-5 (Design phase)  
**Priority:** LOW (Monetization, can be Phase 8)

### Deliverables:

#### ⏳ RoyalPass Tier Structure

**System Design:**
- **Free Pass:** Basic rewards every 5 levels
- **Premium Pass:** Enhanced rewards + exclusive cosmetics every level

**Tier Table (100 levels):**
| Level | Free Reward          | Premium Reward               |
|-------|----------------------|------------------------------|
| 1     | 500 Currency         | 1000 Currency + Ghost Sticker|
| 5     | Common Tool Skin     | Rare Tool Skin               |
| 10    | 1000 Currency        | 2000 Currency + Emote        |
| 15    | Evidence Journal Skin| Premium Journal Skin         |
| 20    | Avatar Hat           | Premium Avatar Outfit        |
| 25    | Flashlight Skin      | Animated Flashlight Skin     |
| 50    | Legendary Emote      | Legendary Avatar Set         |
| 100   | Ultimate Badge       | Ultimate Ghost Pet           |

#### ⏳ Cosmetic Asset Types

**Priority Asset Categories:**

1. **Tool Skins** (HIGH)
   - EMF Reader skins (colors, decals)
   - Flashlight skins (tactical, vintage, neon)
   - Spirit Box skins (modern, retro)
   - Camera skins (Polaroid colors)

2. **Avatar Cosmetics** (MEDIUM)
   - Investigator outfits (jackets, vests, uniforms)
   - Hats (caps, helmets, bandanas)
   - Backpacks (equipment bags)
   - Accessories (badges, watches)

3. **UI Themes** (LOW)
   - Evidence journal skins (leather, digital, ancient)
   - HUD color schemes (blue, red, green, neon)
   - Kill feed icons

4. **Emotes** (MEDIUM)
   - Scared reaction
   - Confident pose
   - Team celebration
   - Ghost taunt

5. **Ghost Pets** (LOW - PREMIUM)
   - Miniature ghosts that follow player in lobby
   - Cosmetic only (no gameplay effect)
   - Animated (floating, glowing)

#### ⏳ Monetization Strategy

**Pricing:**
- Premium RoyalPass: 499 Robux (30-day season)
- Individual cosmetics: 99-299 Robux
- Bundles: 699 Robux (outfit + tool skins + emote)

**Reward Balance:**
- Free pass: ~10,000 currency total (enough to buy 2-3 items)
- Premium pass: ~30,000 currency + 10 exclusive cosmetics

**Progression:**
- 1 level = 1000 XP
- Average match grants 500-800 XP
- Daily missions grant 1000 XP
- Weekly challenges grant 5000 XP

---

## 7.7 Asset Integration Checklist

**Week 5-6: Final Integration & Testing**

### ⏳ Asset Import Workflow

1. **3D Models:**
   - Export from Blender as `.fbx`
   - Import to Roblox Studio
   - Apply materials and textures
   - Set CollisionFidelity (PreciseConvexDecomposition for complex models)
   - Anchor static meshes
   - Test performance (aim for <50k total triangles per map)

2. **Audio:**
   - Upload to Roblox (get Asset IDs)
   - Update AudioSanitizer whitelist
   - Configure Sound properties (Volume, RollOff, Looped)
   - Test spatial audio (3D positioning)

3. **VFX:**
   - Create ParticleEmitters in Studio
   - Configure textures, rates, lifetimes
   - Script enable/disable triggers
   - Test performance (max 200 active particles)

4. **GUI:**
   - Create ScreenGui hierarchy
   - Import UI images as ImageLabels
   - Configure layouts (UIListLayout, UIPadding)
   - Script interactions (buttons, sliders)
   - Test on different screen resolutions

### ⏳ Performance Validation

**Target Metrics:**
- FPS: >60 on medium-end devices
- Memory: <600 MB
- Ping: <100ms (server-dependent)
- Load time: <10 seconds

**Optimization Techniques:**
- Use LOD (Level of Detail) for distant objects
- Limit active ParticleEmitters
- Use StreamingEnabled for large maps
- Compress textures (1024x1024 max for most)
- Reduce shadow-casting lights (<50 per map)

### ⏳ Quality Assurance Checklist

- [ ] All 3D models load without errors
- [ ] Audio plays correctly (no HTTP 403 errors)
- [ ] VFX triggers at correct game events
- [ ] Lighting creates horror atmosphere
- [ ] Player movement feels realistic
- [ ] FPV lock works in investigation maps
- [ ] TPV works in lobby
- [ ] Flashlight illuminates properly
- [ ] Sanity effects visible and impactful
- [ ] Evidence visuals (fingerprints, orbs) render correctly
- [ ] Ghost models animate smoothly
- [ ] No performance drops (<60 FPS)
- [ ] UI responsive on all resolutions

---

# PROJECT STATUS (AI SOURCE OF TRUTH)

This section is the **authoritative progress tracker**.

AI must never rebuild systems marked as **COMPLETED**.

| System                              | Status      | Notes                                                      |
| ----------------------------------- | ----------- | ---------------------------------------------------------- |
| Boot Pipeline                       | COMPLETED   | ServerBootstrap + Boot.server.lua stabilized               |
| Server Boot Pipeline                | COMPLETED   | boot 62-84ms stable, diagnostics verified                  |
| SystemRegistry                      | COMPLETED   | deterministic load + lifecycle guard                       |
| SystemRegistry Lifecycle Validation | COMPLETED   | shutdown no-op compatibility                               |
| Audio Error Handling                | COMPLETED   | runtime guard + sanitizer active                           |
| EventBus                            | COMPLETED   | lifecycle validated                                        |
| MatchQueue                          | COMPLETED   | queue join + leave working                                 |
| MatchBuilder                        | COMPLETED   | match instance creation                                    |
| MatchLifecycle                      | COMPLETED   | match start pipeline                                       |
| MatchTeleport                       | COMPLETED   | teleport to map working                                    |
| MatchService                        | COMPLETED   | full queue → match flow                                    |
| Dev.Match command                   | COMPLETED   | backend match testing                                      |
| Room System                         | COMPLETED   | host control + ready countdown                             |
| Match Container                     | COMPLETED   | Workspace.ActiveMatches                                    |
| Investigation State Machine         | COMPLETED   | investigation flow                                         |
| Ghost initialization                | COMPLETED   | match scoped ghost                                         |
| Evidence Trigger Testing            | COMPLETED   | trigger flow verified                                      |
| Lobby Map Geometry Access           | COMPLETED   | LobbySocialHub geometry path fixed                         |
| LobbySystem                         | COMPLETED   | MatchQueue nil guard + controller wired                    |
| Reward pipeline                     | COMPLETED   | DifficultyMultiplier applied, validation log added         |
| GhostSystem                         | COMPLETED   | valid transitions, difficulty-scaled, janitor cleanup      |
| Ghost AI                            | COMPLETED   | dual-condition hunt, cooldown 25-45s, task.wait() clean    |
| EvidenceSystem                      | COMPLETED   | clarity multiplier, difficulty count, deduction pipeline   |
| Evidence Pipeline                   | COMPLETED   | controller subscriptions + tool validation complete        |
| Sanity system                       | COMPLETED   | difficulty drain, critical guard, hunt double-drain        |
| HuntSystem                          | COMPLETED   | legacy removed, per-match state, aggression+sanity wired   |
| Ghost Hunt Trigger                  | COMPLETED   | bidirectional pipeline verified                            |
| Spectator distortion                | COMPLETED   | 10/30/60 split, ghost sighting offset, controller wired    |
| Economy system                      | COMPLETED   | wallet cap, multiplier, CurrencyEarned + XPGranted         |
| Progression system                  | COMPLETED   | XP_TABLE 100 levels, AddXP loop, session persistence       |
| Live Ops pipeline                   | COMPLETED   | 6 capture points, EventBus wired, lifecycle stubs          |
| _G.SystemRegistry access            | COMPLETED   | exposed in ServerBootstrap line 18                         |
| TelemetrySystem registration        | COMPLETED   | added to LiveServiceSystems, Main.lua created              |
| RemoteEvent Security Layer          | COMPLETED   | null check, payload guard, rate limit 10/5s                |
| Performance Profiling               | COMPLETED   | timing hooks Ghost/Evidence/Hunt, 100ms warn threshold     |
| Anti-Cheat Layer                    | COMPLETED   | evidence whitelist, node check, bounds check, server matchId|
| RankSystem                          | COMPLETED   | RankTiers loaded, promo/demotion, floor guard, EventBus    |
| UI Systems (RoomBrowser, Queue)     | COMPLETED   | Toggle fixed, queue spam prevented, performance optimized  |
| Debugging Tools                     | COMPLETED   | RoomBrowserDebugger, DevTestCommands, PerformanceDashboard |

---

# KNOWN ISSUES (Non-Blocking)

| Issue                              | Severity | Resolution                              |
| ---------------------------------- | -------- | --------------------------------------- |
| TelemetrySystem silent in boot log | LOW      | Main.lua + registration done. Parked.  |
| rbxassetid://10576163165 HTTP 403  | LOW      | Invalid audio asset. Fix in Phase 7.   |
| SystemDiagnostics Loaded: 0        | LOW      | Counter not synced to SR. Cosmetic.    |

---

# PHASE 7 STRATEGIC GUIDANCE

## Recommended Workflow

**Week 1-2: Foundation**
1. Set up Lighting (Future, Atmosphere, ColorCorrection)
2. Implement Flashlight system (PRIORITY 1)
3. Configure player movement (WalkSpeed, JumpPower, FPV lock)
4. Source modular map assets from Creator Store

**Week 2-3: Ghost Visuals**
1. Import/create ghost models (Pocong, Kuntilanak, Genderuwo)
2. Rig for animation
3. Implement manifestation VFX (particles, transparency tweens)
4. Add hunt animations

**Week 3-4: Tools & Evidence**
1. Replace placeholder tools with 3D models
2. Add interactive GUI (EMF screen, thermometer display)
3. Implement evidence visuals (fingerprints, orbs, cold breath)
4. Script tool interactions

**Week 4-5: Audio & Atmosphere**
1. Upload all audio assets (ghost sounds, footsteps, ambient)
2. Configure 3D spatial audio
3. Add material-based footstep sounds
4. Implement sanity audio/visual effects

**Week 5-6: Integration & Polish**
1. Import all assets to game
2. Hook up VFX/SFX to game events
3. Test full game loop with visuals
4. Performance optimization (LOD, particle limits)
5. QA checklist validation

## Critical Success Factors

1. **Flashlight is KING** — 80% of horror atmosphere comes from lighting. Get this right first.
2. **Use Creator Store** — Don't build everything from scratch. Speed matters.
3. **Test on Low-End Devices** — Ensure FPS >60 on budget hardware.
4. **Audio Matters** — Spatial 3D audio makes ghosts feel real. Prioritize this.
5. **Sanity Effects** — Vignette + blur + heartbeat = player fear. Must be impactful.

## Parallel Track with Code Polish

While you handle Phase 7 visuals, AI can work on:
- Remaining bug fixes
- Balance tuning (ghost difficulty, sanity rates)
- Performance profiling
- Code documentation
- Edge case testing

**Total Phase 7 Duration:** 4-6 weeks (depending on asset complexity)

---

# CHANGELOG

## 2026-03-17 (Session 5 - Phase 7 Roadmap Added)

### Major Updates
- ✅ Added Phase 7: Visual & Atmospheric Integration to ROADMAP GLOBAL
- ✅ Detailed breakdown of all 7 sub-phases (7.1 - 7.7)
- ✅ Player movement specs integrated (WalkSpeed: 10, JumpPower: 32)
- ✅ FPV lock system designed (IN-GAME only, TPV in lobby)
- ✅ Head bobbing camera system planned
- ✅ RoyalPass asset planning added (cosmetics, monetization strategy)
- ✅ Asset integration workflow documented
- ✅ Performance targets set (>60 FPS, <600MB memory)

### Technical Specifications Added
- Future Lighting configuration
- Flashlight system (SpotLight + Beam)
- Ghost manifestation VFX (particles, tweens)
- Sanity visual effects (vignette, blur, heartbeat)
- Evidence visuals (fingerprints, orbs, cold breath)
- 3D spatial audio setup
- Material-based footstep sounds

### Asset Requirements Defined
- 3D Models: Ghost rigs, tools, props, furniture
- Audio: Ghost sounds, footsteps, ambient, UI
- VFX: Particles, lighting effects, post-processing
- GUI: Tool screens, HUD elements, menus

### RoyalPass System Designed
- 100-level progression
- Free vs Premium tiers
- Cosmetic categories (tool skins, avatar items, emotes)
- Monetization pricing (499 Robux pass, 99-299 individual items)

### Timeline Estimate
- Phase 7: 4-6 weeks (parallel with code polish)
- Phase 8: 1-2 weeks (playtest + final polish)
- Phase 9: 2-4 weeks (publish + live ops)
- **Total to Launch:** 7-12 weeks from now

---

## Previous Session Logs

(Session 1-5 logs preserved from original reports.md — see lines 174-606 of original file)

---

# NEXT IMMEDIATE ACTION

**Phase 7.1: Environment & Lighting Foundation**

**Task 1: Set up Future Lighting**
1. Open Studio
2. Select Lighting in Explorer
3. Set Technology = Future
4. Configure properties per Phase 7.1 spec
5. Test in dark room

**Task 2: Implement Flashlight System**
1. Create FlashlightController.client.lua
2. Add SpotLight + Beam to player Head
3. Test toggle with F key
4. Verify illumination range

**Task 3: Configure Player Movement**
1. Set StarterPlayer.CharacterWalkSpeed = 10
2. Set StarterPlayer.CharacterJumpPower = 32
3. Test realistic movement feel
4. Add sprint (Shift) if desired

**Estimated Time:** 2-3 hours for all three tasks

**After Task 1-3 Complete:**
→ Screenshot results
→ Report feel/performance
→ Proceed to Task 4: Source map assets from Creator Store

---

**Miftah, siap mulai Phase 7? Atau ada yang perlu direvisi dari roadmap ini?** 🚀

---

## 2026-03-19 (Progress Append - Match Teleport)

### Status
- Match teleport pipeline is working again.
- Current runtime source is fallback `ReplicatedStorage.Maps` because `ServerStorage.Maps` is still missing at runtime.

### Latest Verified Log
- `00:18:35.927 [MatchTeleport] [TECH DEBT] ServerStorage.Maps missing. Falling back to ReplicatedStorage.Maps`
- `00:18:35.927 [MatchTeleport] Using map template: EmptyBuilding from ReplicatedStorage.Maps`
- `00:18:35.933 [MatchTeleport] Teleported players to map EmptyBuilding`

### Note
- Keep fallback temporary only; finalize by making `ServerStorage.Maps` available and then remove fallback.

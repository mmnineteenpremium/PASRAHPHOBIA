# GHOST MODEL IMPORT GUIDE — PASRAHPHOBIA

**Priority Ghost Models:** Pocong, Kuntilanak, Genderuwo  
**Timeline:** Phase 7.2-7.7  
**Difficulty:** Medium (requires Creator Store search OR Blender modeling)

---

## PRIORITY GHOSTS (IMPLEMENT FIRST)

### 1. Pocong (Indonesian Shrouded Ghost)
- **Type:** Floating, shrouded figure
- **Visual:** White cloth wrapping, bound at head/feet
- **Height:** ~5-6 studs
- **Transparency:** 0.3 base (semi-transparent)
- **Animation Needs:** Float idle, slow drift, manifestation

### 2. Kuntilanak (Female Banshee)
- **Type:** Female spirit with long hair
- **Visual:** White dress, long black hair covering face
- **Height:** ~5-6 studs
- **Transparency:** 0.3 base
- **Animation Needs:** Walk (slow), hair sway, scream pose

### 3. Genderuwo (Shadow Figure)
- **Type:** Muscular dark shadow
- **Visual:** Humanoid shape, dark/black color, muscular build
- **Height:** ~6-7 studs (tall)
- **Transparency:** 0.5-0.7 (very dark shadow)
- **Animation Needs:** Walk (aggressive), crouch, charge

---

## METHOD 1: CREATOR STORE (EASIEST)

### Step 1: Search for Models

1. Open Roblox Studio
2. Open Toolbox (View → Toolbox or Alt+T)
3. Click "Creator Store"
4. Search terms to try:
   - "ghost model"
   - "horror character"
   - "shrouded ghost" (for Pocong)
   - "female ghost" (for Kuntilanak)
   - "shadow figure" (for Genderuwo)
   - "phantom rig"
   - "specter model"

5. Filter by:
   - **Models** (not just meshes)
   - **Free** (recommended) or **Paid**
   - **Rigged** (has animations)

6. Preview models:
   - Click model to see preview
   - Check if it has:
     - Humanoid (for AI pathfinding)
     - Animations folder
     - PrimaryPart set

### Step 2: Insert & Configure

1. Select suitable ghost model
2. Click "+" or drag into Workspace
3. Move to `ReplicatedStorage > Assets > GhostModels`
4. Create folder structure:
```
ReplicatedStorage
└── Assets
    └── GhostModels
        ├── Pocong
        │   ├── Model (the actual model)
        │   ├── Animations (folder)
        │   └── Config (ModuleScript)
        ├── Kuntilanak
        └── Genderuwo
```

### Step 3: Configure Model Properties

**For each ghost model:**

1. **Set PrimaryPart:**
   - Select model
   - In Properties, find "PrimaryPart"
   - Set to HumanoidRootPart or Torso

2. **Adjust Transparency:**
   - Select all BaseParts in model
   - Set Transparency = 0.3 (semi-transparent ghost)

3. **Material:**
   - For Pocong/Kuntilanak: Material = SmoothPlastic or Fabric
   - For Genderuwo: Material = ForceField or Neon (shadow effect)

4. **Color:**
   - Pocong: White (255, 255, 255)
   - Kuntilanak: White dress, black hair
   - Genderuwo: Very dark grey or black (10, 10, 10)

### Step 4: Add Config ModuleScript

**Create:** `ReplicatedStorage/Assets/GhostModels/Pocong/Config`

```lua
-- Ghost Configuration Module
return {
    Name = "Pocong",
    DisplayName = "Pocong",
    Description = "Indonesian shrouded ghost that floats",
    
    -- Visual Properties
    BaseTransparency = 0.3,
    ManifestTransparency = 0.0,
    DematerializeTransparency = 1.0,
    
    -- AI Behavior (from CANONICAL_SPEC)
    AggressionBase = 30, -- Low aggression (20-40 range)
    RoamingSpeed = 8, -- Slow floating
    HuntSpeed = 12, -- Faster when hunting
    
    -- Evidence Types (3 required)
    EvidenceTypes = {"MEDOK", "Suhu", "Buku Terkutuk"},
    
    -- Animation IDs (replace with actual animation IDs)
    Animations = {
        Idle = 0, -- TODO: Create/find idle animation
        Walk = 0, -- TODO: Float animation
        Run = 0, -- TODO: Fast float for hunt
        Attack = 0 -- TODO: Jumpscare animation
    },
    
    -- Audio (replace with actual sound IDs)
    Sounds = {
        Ambient = "rbxassetid://0", -- Background ghost sound
        Manifestation = "rbxassetid://0", -- Appears sound
        Hunt = "rbxassetid://0", -- Chase sound
        Kill = "rbxassetid://0" -- Jumpscare sound
    }
}
```

**Repeat for Kuntilanak & Genderuwo with appropriate values.**

---

## METHOD 2: BLENDER (CUSTOM MODELS)

### Requirements:
- Blender 3.0+ (free download)
- Roblox Studio
- Basic 3D modeling knowledge

### Step 1: Create Model in Blender

1. **Open Blender** → New Project
2. **Model ghost:**
   - Pocong: Cylinder → Edit → Shape into shroud
   - Kuntilanak: Human base → Add dress/hair
   - Genderuwo: Human base → Scale up (muscular)

3. **Keep poly count LOW:**
   - Target: <5000 triangles per model
   - Use subdivision surface modifier sparingly

4. **UV Unwrap:**
   - Select model → U → Smart UV Project
   - Create texture in Image Editor

5. **Rig for animation:**
   - Add Armature (skeleton)
   - Parent mesh to armature (Automatic Weights)
   - Test rig with pose mode

### Step 2: Export to Roblox

1. **File → Export → FBX (.fbx)**
2. Settings:
   - Scale: 1.00
   - Apply Scalings: FBX All
   - Forward: Y Forward
   - Up: Z Up
   - Include: Armature, Mesh, Animation

3. **Save as:** `Pocong.fbx`

### Step 3: Import to Roblox Studio

1. **Avatar → 3D Importer** (or Plugins → Import 3D)
2. Select `Pocong.fbx`
3. Import settings:
   - Rig Type: R15 or Custom
   - Scale: Adjust to ~5-6 studs height
4. Click "Import"

5. **Result:** Model appears in Workspace with rig

6. **Move to:** `ReplicatedStorage/Assets/GhostModels/Pocong/`

---

## METHOD 3: HIRE ARTIST (OPTIONAL)

If you want high-quality custom models:

1. **Fiverr/Upwork:**
   - Search: "Roblox 3D modeler"
   - Budget: $20-50 per model
   - Provide reference images (Pinterest "Pocong ghost")

2. **Roblox Developer Forum:**
   - Post in "Collaboration" → "Portfolios"
   - Many artists offer free/cheap models for credit

3. **Commission Artists:**
   - Provide specifications from this guide
   - Request rigged model with animations
   - Delivery: FBX file for Roblox import

---

## ANIMATION SETUP

### Option A: Roblox Animation Editor

1. **Open Animation Editor:**
   - Plugins → Animation Editor
   - Load ghost rig

2. **Create animations:**
   - **Idle:** Slight float up/down (loop)
   - **Walk:** Forward drift with sway
   - **Run:** Fast forward movement
   - **Attack:** Lunge toward camera

3. **Publish animations:**
   - File → Publish to Roblox
   - Get Animation ID
   - Add to Config ModuleScript

### Option B: Use Existing Animations

**Search Creator Store:**
- "ghost animation"
- "floating animation"
- "horror character animation"

**Load animation:**
```lua
-- In GhostSystem
local animator = ghost.Humanoid:FindFirstChild("Animator")
local walkAnim = Instance.new("Animation")
walkAnim.AnimationId = "rbxassetid://YOUR_ANIMATION_ID"
local walkTrack = animator:LoadAnimation(walkAnim)
walkTrack:Play()
```

---

## TESTING GHOST MODELS

### Test Script (ServerScriptService)

```lua
-- Ghost Model Test Script
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ghostModels = ReplicatedStorage.Assets.GhostModels

-- Test spawn Pocong
local pocongModel = ghostModels.Pocong.Model:Clone()
pocongModel.Parent = workspace
pocongModel:MoveTo(Vector3.new(0, 5, 0))

print("Pocong spawned at:", pocongModel.PrimaryPart.Position)

-- Test transparency
for _, part in ipairs(pocongModel:GetDescendants()) do
    if part:IsA("BasePart") then
        part.Transparency = 0.3
    end
end

-- Test manifestation VFX
local ManifestationVFX = require(game.ServerScriptService.GhostSystem.ManifestationVFX)
task.wait(2)
ManifestationVFX.Manifest(pocongModel, 2)
```

**Expected:**
- Ghost spawns in Workspace
- Semi-transparent appearance
- Manifestation effect plays (mist particles + fade in)

---

## INTEGRATION WITH GHOSTSYSTEM

### Hook up to existing GhostSystem:

**In GhostSystem/Main.lua (or wherever ghost spawns):**

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ghostModels = ReplicatedStorage.Assets.GhostModels

-- Spawn random ghost for match
local function spawnGhost(matchId, ghostType)
    ghostType = ghostType or "Pocong" -- Default
    
    local ghostFolder = ghostModels:FindFirstChild(ghostType)
    if not ghostFolder then
        warn("[GhostSystem] Ghost type not found:", ghostType)
        return nil
    end
    
    local ghostModel = ghostFolder.Model:Clone()
    local ghostConfig = require(ghostFolder.Config)
    
    -- Set up ghost instance
    ghostModel.Name = "Ghost_" .. matchId
    ghostModel.Parent = workspace.ActiveMatches[matchId]
    ghostModel:MoveTo(Vector3.new(0, 5, 0)) -- Spawn position
    
    -- Apply config
    for _, part in ipairs(ghostModel:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Transparency = ghostConfig.BaseTransparency
        end
    end
    
    -- Trigger manifestation VFX
    local ManifestationVFX = require(game.ServerScriptService.GhostSystem.ManifestationVFX)
    ManifestationVFX.Manifest(ghostModel, 2)
    
    return {
        model = ghostModel,
        config = ghostConfig,
        state = "Idle"
    }
end
```

---

## QUICK START CHECKLIST

**For each ghost (Pocong, Kuntilanak, Genderuwo):**

- [ ] Find/create 3D model (Creator Store or Blender)
- [ ] Set PrimaryPart (HumanoidRootPart or Torso)
- [ ] Adjust transparency (0.3 base)
- [ ] Set material & color (appropriate to ghost type)
- [ ] Create Config ModuleScript with stats
- [ ] Find/create animations (idle, walk, run, attack)
- [ ] Add to ReplicatedStorage/Assets/GhostModels/
- [ ] Test spawn with test script
- [ ] Verify manifestation VFX works
- [ ] Integrate with GhostSystem spawn logic

---

## RECOMMENDED WORKFLOW

**Week 1:** Pocong only (simplest model)
- Use Creator Store model as placeholder
- Configure transparency & basic setup
- Test spawn + manifestation VFX

**Week 2:** Kuntilanak (medium complexity)
- Find/create female ghost model
- Add hair/dress details
- Animate

**Week 3:** Genderuwo (most complex)
- Shadow figure with muscular build
- Dark materials (ForceField/Neon)
- Aggressive animations

**Week 4:** Polish & integrate all three
- Fine-tune transparency, colors
- Add custom sounds
- Full GhostSystem integration

---

## TROUBLESHOOTING

**Issue:** "Model has no PrimaryPart"
- **Fix:** Select model → Properties → PrimaryPart → Set to HumanoidRootPart

**Issue:** "Ghost not transparent"
- **Fix:** Script to set transparency on all BaseParts to 0.3

**Issue:** "Animations not playing"
- **Fix:** Verify Humanoid + Animator exist in model
- **Fix:** Check Animation ID is correct

**Issue:** "Ghost falls through floor"
- **Fix:** Set all BaseParts to CanCollide = false (ghosts should float)
- **Fix:** Or use custom movement system (not Humanoid walking)

---

**END OF GHOST MODEL IMPORT GUIDE**

**Estimated Time:** 2-4 hours per ghost (Creator Store) or 1-2 days (Blender custom)

**Miftah, prioritas: Pocong first (paling simple), lalu Kuntilanak, lalu Genderuwo.** ✅

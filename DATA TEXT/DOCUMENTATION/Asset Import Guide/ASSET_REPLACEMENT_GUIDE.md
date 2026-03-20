# ASSET REPLACEMENT GUIDE — PASRAHPHOBIA PHASE 7

**Purpose:** Replace all placeholder `rbxassetid://0` with actual Roblox asset IDs

**Files Affected:**
- SanityVFX.client.lua (2 placeholders)
- EvidenceVFX.client.lua (1 placeholder)
- AudioManager.client.lua (4 placeholders)

---

## REQUIRED ASSETS

### Audio Assets (5 total)

**1. Heartbeat Sound** (for SanityVFX)
- **Use:** Low sanity anxiety effect
- **Type:** Looping heartbeat sound
- **Recommended Search:** Roblox Creator Store "heartbeat sound"
- **Free Options:**
  - Search Toolbox: "heartbeat loop"
  - Or use: `rbxassetid://9113678627` (example heartbeat - test first)

**2. Wood Footstep Sound** (for AudioManager)
- **Use:** Ghost/player footsteps on wood floors
- **Type:** Single footstep impact
- **Recommended:** Toolbox "wood footstep"
- **Example:** `rbxassetid://9112784368` (test first)

**3. Concrete Footstep Sound** (for AudioManager)
- **Use:** Ghost/player footsteps on concrete
- **Type:** Single footstep impact
- **Recommended:** Toolbox "concrete footstep"
- **Example:** `rbxassetid://9112784368` (test first)

**4. Metal Footstep Sound** (for AudioManager)
- **Use:** Ghost/player footsteps on metal surfaces
- **Type:** Single footstep impact
- **Recommended:** Toolbox "metal footstep"
- **Example:** `rbxassetid://9112784368` (test first)

**5. Default Footstep Sound** (for AudioManager)
- **Use:** Fallback for unlisted materials
- **Type:** Generic footstep
- **Recommended:** Use wood or concrete sound as default

### Image/Texture Assets (2 total)

**6. Vignette Texture** (for SanityVFX)
- **Use:** Screen edge darkening effect
- **Type:** Radial gradient image (dark edges, transparent center)
- **Options:**
  - A) Create in Photoshop/GIMP (1024x1024, radial gradient)
  - B) Search Toolbox: "vignette overlay"
  - C) Use pre-made: `rbxassetid://5198491447` (test first)

**7. Fingerprint Texture** (for EvidenceVFX)
- **Use:** UV light reveals handprint on surfaces
- **Type:** Fingerprint/handprint image
- **Recommended:**
  - Search Toolbox: "handprint texture" or "fingerprint decal"
  - Example: `rbxassetid://7229442422` (test first)

---

## HOW TO FIND ASSETS IN ROBLOX

### Method 1: Creator Store (Toolbox)

1. Open Roblox Studio
2. Go to `View` → `Toolbox` (or press Alt+T)
3. Click "Creator Store" tab
4. Search for asset (e.g., "heartbeat sound")
5. Filter by:
   - **Audio** for sounds
   - **Decals** for textures
   - **Free** (recommended)
6. Click asset to preview
7. Right-click → "Copy Asset ID" or check Properties panel
8. Note the Asset ID number

### Method 2: Upload Custom Assets

**For Audio:**
1. Prepare audio file (.mp3 or .ogg, <10MB)
2. Go to [Roblox Creator Dashboard](https://create.roblox.com/dashboard/creations)
3. Click "Audio" → "Upload"
4. Upload file, add name/description
5. Wait for moderation approval (usually 1-2 hours)
6. Copy Asset ID from dashboard

**For Images:**
1. Prepare image file (.png, 1024x1024 recommended)
2. Go to Creator Dashboard → "Decals" → "Upload"
3. Upload file
4. Wait for approval
5. Copy Asset ID

### Method 3: Use Provided Examples (Quick Test)

I've provided example Asset IDs in this guide. You can:
1. Use them temporarily to test functionality
2. Replace later with your own uploads for uniqueness

---

## REPLACEMENT INSTRUCTIONS

### File 1: SanityVFX.client.lua

**Location:** StarterPlayer/StarterPlayerScripts/SanityVFX

**Line 31 - Vignette Texture:**
```lua
-- BEFORE:
vignetteImage.Image = "rbxassetid://0" -- Placeholder

-- AFTER:
vignetteImage.Image = "rbxassetid://5198491447" -- Example vignette (or your uploaded ID)
```

**Line 58 - Heartbeat Sound:**
```lua
-- BEFORE:
heartbeatSound.SoundId = "rbxassetid://0" -- Placeholder

-- AFTER:
heartbeatSound.SoundId = "rbxassetid://9113678627" -- Example heartbeat (or your uploaded ID)
```

---

### File 2: EvidenceVFX.client.lua

**Location:** StarterPlayer/StarterPlayerScripts/EvidenceVFX

**Line 65 - Fingerprint Texture:**
```lua
-- BEFORE:
fingerprint.Texture = "rbxassetid://0" -- Placeholder

-- AFTER:
fingerprint.Texture = "rbxassetid://7229442422" -- Example fingerprint (or your uploaded ID)
```

---

### File 3: AudioManager.client.lua

**Location:** StarterPlayer/StarterPlayerScripts/AudioManager

**Lines 24-27 - Footstep Sounds:**
```lua
-- BEFORE:
AudioManager.FootstepSounds = {
    [Enum.Material.Wood] = "rbxassetid://0", -- Placeholder
    [Enum.Material.Concrete] = "rbxassetid://0", -- Placeholder
    [Enum.Material.Metal] = "rbxassetid://0", -- Placeholder
    Default = "rbxassetid://0" -- Placeholder
}

-- AFTER (using examples):
AudioManager.FootstepSounds = {
    [Enum.Material.Wood] = "rbxassetid://9112784368", -- Wood footstep
    [Enum.Material.Concrete] = "rbxassetid://9112784368", -- Concrete footstep
    [Enum.Material.Metal] = "rbxassetid://9112784368", -- Metal footstep
    Default = "rbxassetid://9112784368" -- Default footstep
}
```

**Note:** Example IDs may be the same initially. Replace with unique sounds for variety.

---

## TESTING AFTER REPLACEMENT

### Test SanityVFX:
1. Press F5 in Studio
2. Use server script to fire sanity update:
```lua
-- Test script (ServerScriptService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
    task.wait(5) -- Wait for client to load
    local sanityEvent = ReplicatedStorage.RemoteEvents:FindFirstChild("SanityUpdate")
    if sanityEvent then
        -- Test low sanity (triggers heartbeat + vignette)
        sanityEvent:FireClient(player, 20)
        print("Fired sanity update: 20")
    end
end)
```
3. Check if:
   - Vignette appears (dark edges)
   - Heartbeat sound plays
   - Blur effect visible

### Test EvidenceVFX:
1. Spawn in game with UV flashlight tool (if available)
2. Look at surfaces near evidence nodes
3. Fingerprints should appear under UV light

### Test AudioManager:
1. Walk on different floor materials (wood, concrete, metal)
2. Footstep sounds should play with 3D positioning
3. Sound volume should decrease with distance

---

## QUICK START: COPY-PASTE READY CODE

### For Quick Testing (All Example IDs)

**SanityVFX.client.lua (Lines 31 & 58):**
```lua
vignetteImage.Image = "rbxassetid://5198491447"
heartbeatSound.SoundId = "rbxassetid://9113678627"
```

**EvidenceVFX.client.lua (Line 65):**
```lua
fingerprint.Texture = "rbxassetid://7229442422"
```

**AudioManager.client.lua (Lines 24-27):**
```lua
AudioManager.FootstepSounds = {
    [Enum.Material.Wood] = "rbxassetid://9112784368",
    [Enum.Material.Concrete] = "rbxassetid://9112784368",
    [Enum.Material.Metal] = "rbxassetid://9112784368",
    Default = "rbxassetid://9112784368"
}
```

**Save → Press F5 → Test**

---

## TROUBLESHOOTING

**Issue:** "Failed to load asset"
- Asset ID might be invalid or content deleted
- Try different Asset ID from Toolbox
- Or upload your own asset

**Issue:** "Sound not playing"
- Check audio is not muted in Studio
- Verify Asset ID is for audio file (not image)
- Check SoundService.RespectFilteringEnabled setting

**Issue:** "Vignette not visible"
- Asset might be wrong type (needs to be image)
- Try example ID: `rbxassetid://5198491447`
- Or create custom vignette in image editor

**Issue:** "Footstep sounds all the same"
- This is expected if using example IDs (placeholder)
- Upload/find unique sounds for each material
- Or use different Asset IDs from Toolbox

---

## RECOMMENDED FREE ASSET SOURCES

**Roblox Creator Store (Toolbox):**
- Search: "heartbeat loop", "footstep sound", "vignette"
- Filter: Audio/Decals, Free
- Most reliable source for Roblox-compatible assets

**External Audio (Requires Upload):**
- [Freesound.org](https://freesound.org) — Free sound effects
- [Zapsplat.com](https://zapsplat.com) — Free SFX library
- Download → Upload to Roblox → Get Asset ID

**Image Creation:**
- Photoshop/GIMP — Create custom vignette (radial gradient)
- [Pixlr.com](https://pixlr.com) — Free online editor
- Export PNG → Upload to Roblox

---

## FINAL CHECKLIST

Before considering Phase 7.4 complete:

- [ ] SanityVFX vignette texture replaced & tested
- [ ] SanityVFX heartbeat sound replaced & tested
- [ ] EvidenceVFX fingerprint texture replaced & tested
- [ ] AudioManager wood footstep replaced & tested
- [ ] AudioManager concrete footstep replaced & tested
- [ ] AudioManager metal footstep replaced & tested
- [ ] AudioManager default footstep replaced & tested
- [ ] All assets play/render correctly in-game
- [ ] No "Failed to load asset" errors in console

---

**END OF ASSET REPLACEMENT GUIDE**

**Estimated Time:** 30-60 minutes (finding + testing assets)

**Miftah, use example IDs for quick test, then replace with custom assets for production.** ✅

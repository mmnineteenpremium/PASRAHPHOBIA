You are a senior Roblox game UI/UX designer, technical artist, and Lua developer with deep expertise in Roblox Studio, ScreenGui systems, and mobile-first game design.

Your task is to generate a COMPLETE Roblox UI/UX system for a psychological horror game called "PASRAHPHOBIA" by MM NINETEEN STUDIOS derived from the provided branding images.

use tools figma, if you need anityhing else, download automatically from plugins vscode.


## input
- photo references for visual direction (color palette, mood, typography)
- html document with detailed UI/UX specifications for all components, screens, and effects (should be like a design brief for a full Figma file, in in the html because thats my 'BRANDING')

folder structure:

  -/
  - Figma file: PASRAHPHOBIA_UI.figma
  - Roblox Assets:
    - Icons/
    - RarityCards/
    - Screens/
    - Effects/



---

## BRANDING REFERENCE
- Game name: PASRAHPHOBIA
- Studio: MM NINETEEN STUDIOS
- Theme: Psychological horror, supernatural, dark atmosphere
- Visual tone: Cold blue-black palette, glowing eyes, fog, silhouettes
- Primary color: Deep void black (#020408) with cold blue glow (#00AAFF)
- Secondary: Danger red (#FF0033), sanity green (#00FF88), stamina amber (#FFAA00)
- Typography style: Distressed horror display font (title) + mono/tech font (UI)
- Mood keywords: fear, isolation, paranoia, tension, unknown

---

## SCOPE: FULL ROBLOX UI/UX SYSTEM

### 1. ICON & ASSET SYSTEM
Generate a complete icon set spec for Roblox (PNG, 2D flat-horror style):
- All HUD icons: sanity heart, stamina boot, flashlight, key, medkit, document, inventory bag, map pin, objective arrow
- Inventory item icons per rarity tier (1 base icon + rarity frame)
- Rank badge icons: Bronze Shield, Silver Sword, Gold Trophy, Platinum Crystal, Diamond Gem, Oni Mask, Dragon Head, Legend Star, Master Fist, Pasrah Skull
- Royal Pass icons: coin, soul token, ticket, chest, glow particles
- UI accent icons: lock, checkmark, arrow, close X, gear, warning, glitch indicator
- All icons: 256x256px, transparent background, dark horror aesthetic
- Roblox-optimized: max 100KB per icon, no gradients that cause aliasing

### 2. RARITY SYSTEM (5 tiers)
Each rarity must have a card component with:
- Background: dark panel with rarity-specific inner glow
- Border: 2px solid + outer glow layer
- Corner ornaments: faction/horror motif
- Glow intensity scales with rarity
- Animation: Legendary gets looping shimmer + particle emitter suggestion

Tiers:
1. COMMON    — #5A6472 gray, no glow, plain border
2. UNCOMMON  — #1FA862 green, soft glow
3. RARE      — #1470D4 blue, medium glow + border pulse
4. EPIC      — #8820E0 purple, strong glow + floating particles concept
5. LEGENDARY — #D4920A gold, intense shimmer + animated border + screen edge glow

### 3. HUD (In-game overlay)
Design for 16:9 and mobile 9:16. All elements semi-transparent, diegetic where possible.

Components:
- SANITY METER: top-left, horizontal bar, green→red gradient as drops, flickers below 30%
- STAMINA METER: below sanity, amber bar, depletes on sprint
- OBJECTIVE TEXT: top-right, minimal, letter-by-letter typewriter animation
- INTERACTION PROMPT: center-bottom, key icon + action text, pulse animation
- QUICKSLOT BAR: bottom-right, 4 slots, active slot highlighted with blue glow
- FEAR VIGNETTE: full-screen radial dark overlay, intensifies as sanity drops
- GLITCH OVERLAY: random screen corruption sprites, triggered by ghost proximity

### 4. MINIMAP (Resident Evil 4 style)
- Bottom-left corner, square frame with horror border ornament
- Shows: rooms as rectangles, doors as gaps, player as glowing dot with direction arrow
- Explored rooms: visible with dim fill | Unexplored: hidden (fog of war)
- Room name label: appears on hover or when entering room
- Toggle to FULL MAP: press M or tap minimap
- Full Map panel: full-screen overlay, shows all floors, location names, player dot, zoom in/out, drag to pan, floor selector tabs
- Style: dark blueprint aesthetic, cold blue lines on black, no color except player dot (bright cyan)

### 5. INVENTORY (PUBG style)
- Grid layout: 6 columns × 5 rows = 30 slots
- Each slot: item icon + rarity border + stack count + durability bar (bottom edge)
- Selected slot: highlighted with blue outer glow
- Right panel: item detail card (icon large, name, rarity badge, description, stats, weight)
- Bottom panel: action buttons — EQUIP / INSPECT / DROP
- Character panel: 4 equip slots (Head, Body, Left Hand, Right Hand) shown as silhouette
- Filter tabs: ALL / WEAPON / ITEM / KEY / DOCUMENT / QUEST
- Weight bar: top-right of panel, current/max
- Drag and drop support spec

### 6. RANKED SYSTEM (Mobile Legends style) but HORROR THEMED
- RP (Rank Points) system with gain/loss after each match
9 Rank tiers with unique badge per tier:

1.    — #8FA8B8  — Sword icon  
2.    — #1FA862  — Shield icon
3.      — #D4A820  — Trophy icon
4.  — #40C8E0  — Crystal icon
5.  — #40A0FF  — Gem icon
6.      — #E04020  — Oni mask icon
7.   — #20E080  — Dragon head icon
8.    — #E0C040  — Star burst icon
9.   — #E080FF  — Fist icon
10.  — #FFFFFF  — Skull icon (Top 10 Server only)

RANK TIER STRUCTURE

BAYI RANK

Bayi 3
Requirement: 3 Stars

Bayi 2
Requirement: 3 Stars

Bayi 1
Requirement: 3 Stars

BALITA RANK

Balita 3
Requirement: 3 Stars

Balita 2
Requirement: 3 Stars

Balita 1
Requirement: 3 Stars

ANAK-ANAK RANK

Anak-Anak 3
Requirement: 3 Stars

Anak-Anak 2
Requirement: 3 Stars

Anak-Anak 1
Requirement: 3 Stars

REMAJA RANK

Remaja 4
Requirement: 4 Stars

Remaja 3
Requirement: 4 Stars

Remaja 2
Requirement: 4 Stars

Remaja 1
Requirement: 4 Stars

DEWASA RANK

Dewasa 5
Requirement: 5 Stars

Dewasa 4
Requirement: 5 Stars

Dewasa 3
Requirement: 5 Stars

Dewasa 2
Requirement: 5 Stars

Dewasa 1
Requirement: 5 Stars

PROFESIONAL RANK

Profesional 5
Requirement: 5 Stars

Profesional 4
Requirement: 5 Stars

Profesional 3
Requirement: 5 Stars

Profesional 2
Requirement: 5 Stars

Profesional 1
Requirement: 5 Stars

DETEKTIVE RANK

Detektive 5
Requirement: 5 Stars

Detektive 4
Requirement: 5 Stars

Detektive 3
Requirement: 5 Stars

Detektive 2
Requirement: 5 Stars

Detektive 1
Requirement: 5 Stars

SANG AHLI RANK

Final Rank Tier

Sang Ahli

Progression System:
50 Stars total

Ranked screen includes:
- Current rank badge (large hexagonal frame)
- Star progress (3 stars per tier)
- RP progress bar with shine animation
- Season stats: matches / wins / losses / win rate / streak
- All rank tiers grid (unlocked dimmed, current highlighted, locked with lock icon)
- Match history: last 5 results with RP gain/loss

### 7. ROYAL PASS (Mobile Legends Battle Pass style)
- Season header: season number, season name, time remaining, current level progress
- Dual track reward display:
  - PREMIUM track (top row): requires purchase, blue themed
  - FREE track (bottom row): available to all, dimmed theme
- 50 reward nodes, each showing: icon, item name, rarity tier badge
- Claimed rewards: checkmark overlay + dimmed
- Current reward: highlighted with animated glow ring
- Buy button: prominent CTA with price
- Reward cards use the full rarity card system from section 2

### 8. GAME SCREENS
Generate full layout specs for:

A. MAIN MENU
- Animated fog background (LoopingAnimations)
- PASRAHPHOBIA logo with flicker animation
- Menu buttons: START / CONTINUE / RANKED / ROYAL PASS / SETTINGS / QUIT
- Atmospheric silhouette background (ghost figure + haunted house)
- Studio branding bottom-left
- Version number bottom-right

B. GAME OVER
- Full black background, blood red vignette
- "PASRAH" text in horror font, glitch animation
- Flavor text: randomized horror quotes
- Session stats: survive time / clues found / final sanity / ghost encounters
- Buttons: TRY AGAIN / MAIN MENU

C. LOADING SCREEN
- Black background, logo centered
- Atmospheric quote text (random each load)
- Loading bar: thin line, cold blue, with scan line animation
- Tip text: horror-flavored gameplay hints

D. SETTINGS
- Graphics: quality presets, post processing toggle, motion blur, glitch intensity slider
- Audio: master / SFX / music / 3D binaural toggle / jumpscare warning toggle
- Gameplay: mouse sensitivity, show sanity bar toggle, hard mode toggle
- Language: ID / EN toggle
- Save / Cancel buttons

### 9. SANITY VISUAL EFFECT SYSTEM
Dynamic UI degradation based on sanity level:

100–70% STABLE:
- UI normal, no distortion
- Subtle vignette only

70–40% UNEASY:
- Vignette darkens
- Objective text occasionally flickers
- Stamina bar pulses slightly
- Ambient hum audio suggestion

40–20% SCARED:
- Strong vignette pulsing
- UI elements randomly desync by 2–4px
- Sanity bar itself starts glitching
- Screen edge gets chromatic aberration
- Ghost silhouette appears briefly at screen edges

20–0% BREAKING:
- Full screen glitch frames (every 3–5 seconds)
- UI text becomes partially corrupted (letters replaced randomly)
- Minimap flickers off/on
- All UI elements vibrate at 100ms intervals
- Color inversion flash (50ms) every 15 seconds
- "PASRAH" text appears and disappears at screen center

### 10. HORROR EFFECT SYSTEM (UI)
- Jumpscare UI disruption: screen shake 200ms, white flash 50ms, then glitch for 800ms
- Ghost proximity indicator: minimap corrupts, vignette spikes, UI flickers
- Noise overlay: static grain texture over all UI, 5% opacity normally, 30% during scare
- Scanline effect: subtle CRT scanline on all panels
- Flicker timing: 16ms on, 16ms off (one frame each at 60fps)
- Chromatic aberration: R channel +3px, B channel -3px during fear state

---

## FIGMA DELIVERABLE STRUCTURE
Create pages:
- Page 1 "🎨 Visual Direction" — color palette, mood board, font specimens, icon style guide
- Page 2 "🔧 Design System" — color tokens, spacing scale, border radius, shadow styles, animation timing
- Page 3 "🧩 Components" — all UI components with auto layout + variants (state: default / hover / active / disabled / locked)
- Page 4 "🖼 Game Screens" — all 7 full screens at 1920×1080 and 390×844 (mobile)
- Page 5 "✨ Effects & Animation" — glitch frames, sanity states, vignette overlays, transition specs
- Page 6 "🎮 Icon & Asset Sheet" — all icons organized by category, exportable at 256px

Figma rules:
- Use Auto Layout everywhere
- Components + Variants for all interactive states
- Local color styles (not raw hex values)
- Local text styles
- All assets export-ready at 1x, 2x, 3x
- Frame names in English (for Roblox ImageLabel AssetId mapping)

---

## ROBLOX TECHNICAL REQUIREMENTS
- All UI built with ScreenGui + LocalScript
- Resolution target: 1920×1080 (scale for mobile)
- GuiService:IsTenFootInterface() check for console
- UDim2 for all sizing (no pixel-only values)
- ImageLabel for all icons (use AssetId placeholders)
- TweenService for all animations (no wait() loops)
- Use Roact or standard Instance-based UI
- Performance: max 50 ImageLabels visible at once
- All icons: PNG, power-of-2 resolution (256x256 or 512x512)
- No external HTTP assets in production (upload all to Roblox CDN)
- ZIndex layering:
  - Background: 1–10
  - HUD elements: 11–50  
  - Panels (Inventory/Map): 51–100
  - Overlays (Fullmap/Settings): 101–150
  - Effects (Vignette/Glitch): 151–200
  - Critical overlays (Game Over): 201+

---

## ROBLOX LUA SCRIPTS TO GENERATE

1. SanityController.lua — manages sanity value, fires events on threshold cross
2. HUDController.lua — updates all HUD bars, objective text, quickslots
3. MinimapController.lua — draws minimap rooms, tracks player position
4. InventoryController.lua — manages 30-slot grid, drag/drop, item data
5. RankedController.lua — RP tracking, rank tier logic, badge display
6. RoyalPassController.lua — level tracking, reward claiming, pass purchase check
7. EffectsController.lua — sanity visual effects, glitch triggers, vignette
8. UIAnimations.lua — shared TweenService helpers for all UI transitions

Each script must:
- Use ModuleScript pattern
- Fire/listen to RemoteEvents for server sync where needed
- Be clean, commented, no deprecated methods
- Work on mobile (TouchInputService) and PC (UserInputService)

---

## OUTPUT FORMAT
1. Complete icon asset list with specs
2. Rarity card system design
3. All UI component specs with measurements
4. All screen layout descriptions
5. Sanity effect system breakdown
6. Figma file structure
7. Roblox Lua scripts (all 8)
8. Roblox Studio setup notes

---

## STYLE RULES — NON NEGOTIABLE
- Prioritize immersion over clarity
- Avoid clean/sterile UI — everything feels slightly broken
- Use imperfection intentionally (misaligned pixels, grain, flicker)
- Every panel must feel like it could malfunction
- Mobile-first but scales to PC
- Horror tone must be consistent from main menu to game over
- No pay-to-win — cosmetic-only Royal Pass
- All UI text supports Bahasa Indonesia (ID) and English (EN)

---

## DO NOT
- Do not ask for more assets
- Do not generate Unity code
- Do not use UIStroke pixel values over 3px
- Do not use bright white (#FFFFFF) except for PASRAH rank
- Do not use gradients that won't render in Roblox ImageLabel
- Do not hardcode pixel sizes — always use UDim2 or UDim


## output 
- See attached Figma file for all visual assets, component designs, and screen layouts.
- cc by-0 priority, rekomended to make all assets available on vscode using tools like figma
- tabel | y/n for assets that are ready for Roblox upload vs those that need optimization or recreation.

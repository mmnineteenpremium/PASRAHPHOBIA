# PASRAHPHOBIA Roblox UI/UX System

## 1. Project Intent

PASRAHPHOBIA needs a mobile-first Roblox UI that feels unstable, oppressive, and slightly malfunctioning. The supplied references establish the core look:
- Void-black base with cold cyan bloom.
- Fog, silhouette horror, glowing eyes, and distressed title treatment.
- Mono/tech UI typography under a more theatrical horror display font.
- Controlled red, green, and amber for danger, sanity, and stamina.

Primary references:
- `Branding.png`: hero key art with lone spirit silhouette, cyan fog bloom, and distressed logo.
- `branding-icon.png`: compact square avatar icon with three silhouettes, useful for iconography and loading identity.
- `contoh-royalpass-30d.png`: lane-based reward track reference for Royal Pass pacing and CTA hierarchy.
- `acuan-visual-ui-ux-gui-pasrahphobia-ui.html`: existing interactive style guide and screen prototype.

Core visual tokens:

| Token | Value | Usage |
| --- | --- | --- |
| Void Black | `#020408` | page backgrounds, negative space |
| Deep Panel | `#081016` with 88-92% alpha | cards, modals, HUD plates |
| Fear Blue | `#00AAFF` | highlights, active states, player marker |
| Danger Red | `#FF0033` | damage, failure, game over |
| Sanity Green | `#00FF88` | high-sanity state |
| Stamina Amber | `#FFAA00` | sprint and exertion |
| Text Primary | `#C8DDE8` | body and label text |
| Text Ghost | `rgba(180,210,230,0.2-0.5)` | secondary copy, disabled states |

Typography:
- Title/display: distressed horror face matching the reference mood.
- UI headings: condensed grotesk or bold semi-condensed sans.
- Labels/data: mono/tech font similar to Share Tech Mono.

Motion:
- Favor brief flickers, scan sweeps, shimmer passes, and low-amplitude desync.
- Avoid playful easing. Motions should feel mechanical or haunted.

## 2. Asset Inventory And Readiness

### 2.1 Complete Icon Asset List

All icon exports target transparent PNG, `256x256`, 1x/2x/3x export, and under `100 KB` per final Roblox upload asset.

| Category | Asset | Style note |
| --- | --- | --- |
| HUD | Sanity Heart | cracked anatomical heart with thin cyan pulse vein |
| HUD | Stamina Boot | worn boot sole with scratch-cut silhouette |
| HUD | Flashlight | narrow cone flashlight with chipped casing |
| HUD | Key | iron key with occult notch |
| HUD | Medkit | taped field kit with subtle blood mark |
| HUD | Document | folded evidence page with torn corner |
| HUD | Inventory Bag | ragged satchel silhouette |
| HUD | Map Pin | cold-blue locator pin with sharp tail |
| HUD | Objective Arrow | fractured directional chevron |
| UI Accent | Lock | heavy latch icon, asymmetrical |
| UI Accent | Checkmark | distorted angular confirm mark |
| UI Accent | Arrow | thin shard-like navigation arrow |
| UI Accent | Close X | scratched double-stroke X |
| UI Accent | Gear | damaged gear with missing tooth |
| UI Accent | Warning | triangle sigil with glitch nick |
| UI Accent | Glitch Indicator | split-channel burst glyph |
| Inventory Base | Weapon | silhouette-only item base |
| Inventory Base | Item | generic consumable silhouette |
| Inventory Base | Key Item | ceremonial key silhouette |
| Inventory Base | Document Item | folder-sheet silhouette |
| Inventory Base | Quest Item | cursed relic silhouette |
| Ranked Badge | Bronze Shield | low-tier guard crest |
| Ranked Badge | Silver Sword | long blade badge |
| Ranked Badge | Gold Trophy | horned trophy cup |
| Ranked Badge | Platinum Crystal | cyan shard cluster |
| Ranked Badge | Diamond Gem | sharp gem eye |
| Ranked Badge | Oni Mask | red-orange demonic mask |
| Ranked Badge | Dragon Head | green spectral dragon profile |
| Ranked Badge | Legend Star | fractured starburst |
| Ranked Badge | Master Fist | glowing clenched fist |
| Ranked Badge | Pasrah Skull | white spectral skull |
| Royal Pass | Coin | cold-metal coin with occult stamp |
| Royal Pass | Soul Token | ghostly token with cyan center |
| Royal Pass | Ticket | torn pass stub |
| Royal Pass | Chest | iron chest with blue seam |
| Royal Pass | Glow Particles | sprite particle sheet |

### 2.2 Asset Readiness Table

`Y` means the source can be optimized and uploaded after size checks. `N` means the asset still needs recreation, slicing, or proper export packaging.

| Asset / Group | Current source | Ready for Roblox upload | Action |
| --- | --- | --- | --- |
| `Branding.png` hero art | provided PNG | N | keep as mood reference; recreate menu/loading background slices |
| `branding-icon.png` square art | provided PNG | N | crop and optimize to `512x512` and export smaller variants |
| `contoh-royalpass-30d.png` reward track | provided PNG | N | reference only; recreate with PASRAHPHOBIA styling |
| HTML prototype screens | provided HTML | N | translate into Figma frames and Roblox GUI hierarchy |
| HUD icon set | not exported yet | N | create full 256px set |
| Inventory rarity frames | not exported yet | N | create 5 final card shells |
| Ranked badges | not exported yet | N | create 10 export-ready badges |
| Royal Pass icons | not exported yet | N | create export set and particle sprites |
| Screen backplates | not exported yet | N | recreate menu, loading, game over, settings illustrations |
| Fear/glitch overlays | not exported yet | N | generate screen-space PNGs or procedural overlays |
| Minimap ornaments | not exported yet | N | design vector frame and tabs |
| Reference logo treatment | derived from provided art | Y | usable after manual glow cleanup and compression |

## 3. Rarity System

Each rarity card uses the same physical shell so item recognition stays fast while the glow language shifts with tier.

| Tier | Color | Border | Glow | Motion |
| --- | --- | --- | --- | --- |
| Common | `#5A6472` | 2px matte steel | none | static |
| Uncommon | `#1FA862` | 2px oxidized green | low inner glow | idle breathing |
| Rare | `#1470D4` | 2px cyan-blue | medium outer glow | 2.4s border pulse |
| Epic | `#8820E0` | 2px violet | strong halo | slow particle drift |
| Legendary | `#D4920A` | 2px gold with secondary trim | intense halo and corner bloom | looping shimmer |

Card anatomy:
- Size reference: `280x360` in Figma.
- Background plate: dark panel with grime texture.
- Inner panel inset: `4%` from frame bounds.
- Corner ornaments: thorn, sigil, or claw motif; increase detail with rarity.
- Label strip: lower `16%` of card height for name, tier, and stack count.
- Durability strip: `2.5%` height at bottom edge.

Animation rules:
- Rare: border pulse from 25% to 60% glow every `2.4s`.
- Epic: 3-5 low-opacity particles drifting upward over `4s`.
- Legendary: `1.8s` shimmer sweep plus optional edge flare on acquisition.

## 4. Component Specs

Measurements below give Figma references and Roblox scale intent.

### 4.1 HUD

| Component | Desktop reference | Mobile reference | Roblox placement |
| --- | --- | --- | --- |
| Sanity meter | `300x26` at `32,32` | `170x18` at `16,20` | `Position = 0.017, 0.03`, `Size = 0.156, 0.024` |
| Stamina meter | `300x18` below sanity | `170x14` below sanity | `Position = 0.017, 0.064`, `Size = 0.156, 0.016` |
| Objective block | `380x70` top-right | `220x54` top-right | `Position = 0.785, 0.03`, `Size = 0.198, 0.065` |
| Interaction prompt | `360x54` bottom center | `240x46` bottom center | `AnchorPoint = 0.5,1`, `Position = 0.5,0.93`, `Size = 0.188,0.05` |
| Quickslot cluster | `292x80` bottom-right | `220x64` bottom-center/right | `Position = 0.81,0.885`, `Size = 0.152,0.074` |
| Minimap | `214x214` bottom-left | `148x148` bottom-left | `Position = 0.02,0.77`, `Size = 0.112,0.198` |
| Fear vignette | full frame | full frame | `Size = 1,1`, `ZIndex = 160` |
| Glitch overlay | full frame | full frame | `Size = 1,1`, `ZIndex = 175` |

HUD notes:
- Sanity fill shifts green to red as the value falls.
- Under `30%`, add intermittent alpha jitter and channel offset.
- Objective text uses typewriter reveal at 20-30 characters per second.
- Quickslot active state gets a blue glow ring and slight lift.

### 4.2 Minimap And Full Map

Minimap:
- Square frame with inward bevel and blueprint ornament corners.
- Player marker is a cyan dot with a thin forward arrow.
- Explored rooms fill at `15%` opacity blue; current room at `28%`.
- Unexplored rooms remain hidden until entered.

Full map overlay:
- Desktop: centered panel `1420x860`.
- Mobile: sheet overlay `358x714`.
- Controls: tap/click minimap to expand, `M` for keyboard, drag to pan, plus/minus zoom.

### 4.3 Inventory

Layout:
- Overall desktop panel: `1560x860`.
- Left grid zone: `910x720`.
- Right detail zone: `500x720`.
- Bottom action band: `74` height reference.

Slot spec:
- Slot size: `132x132` desktop, `92x92` mobile.
- Grid: 6 columns x 5 rows.
- Layer order: shadow plate, rarity frame, icon, stack number, durability bar, selected outline.

Supporting elements:
- Weight bar: `220x16` desktop, `160x12` mobile.
- Filter tabs: `ALL`, `WEAPON`, `ITEM`, `KEY`, `DOCUMENT`, `QUEST`.
- Character silhouette panel: four equipment sockets aligned around torso.

### 4.4 Ranked

Current-rank hero panel:
- Large badge frame `240x240`.
- Rank label block below badge `300x72`.
- RP bar `520x20`.
- Star row 3/4/5 stars depending on ladder segment.

Rank grid:
- Use a 5-column desktop matrix and 2-column mobile matrix.
- Each tile `180x120` desktop, `160x104` mobile.
- Locked tiers use 35% opacity and a latch icon.
- Current tier gets full cyan glow.

### 4.5 Royal Pass

Reward track:
- Horizontal lane with 50 nodes.
- Premium track on top, free track on bottom.
- Each node tile `132x132` desktop, `96x96` mobile.
- Current node gets animated ring and spotlight beam.
- Claimed rewards add a distorted check overlay and dim to 55%.

### 4.6 Menu, Loading, Game Over, Settings

Main menu:
- Logo centered upper-middle.
- Vertical button stack `220x48` desktop, `188x44` mobile.
- Studio label bottom-left, version label bottom-right.

Loading:
- Logo centered.
- Thin loading line `340x6` desktop, `220x6` mobile.
- Quote above the bar and tip line below.

Game over:
- Title centered, oversized and distressed.
- Stats block beneath with 4 data pairs.
- Two CTAs horizontal on desktop and vertical on mobile.

Settings:
- Left navigation rail for `Graphics`, `Audio`, `Gameplay`, `Language`.
- Right pane containing toggles, sliders, and save/cancel.

## 5. Screen Layout Descriptions

### Main Menu
- Full-bleed fog background with haunted house silhouette and one large ghost figure behind the logo.
- `PASRAHPHOBIA` logo uses cold cyan bloom and slight flicker.
- Buttons: `START`, `CONTINUE`, `RANKED`, `ROYAL PASS`, `SETTINGS`, `QUIT`.

### In-Game HUD
- Left stack owns survival info only: sanity, stamina, minimap.
- Right side owns objective, quickslots, and contextual feedback.
- Center remains clear except for interaction prompts and jumpscare interruptions.

### Inventory
- PUBG-inspired density, but stylized as a broken field dossier.
- Right detail panel shows item icon, rarity badge, description, stat bars, and weight.

### Ranked
- Mobile Legends pacing with horror-themed hierarchy.
- Show current rank, stars, RP, season stats, ladder grid, and recent match results.
- Ladder names follow the explicit Indonesian progression from `Bayi 3` through `Sang Ahli`.

### Royal Pass
- Two-lane scrolling reward track with premium emphasis on the top lane.
- The supplied battle-pass reference informs pacing only. Final visuals stay blue-black horror.
- Rewards are cosmetic only.

### Game Over
- Mostly black screen with red vignette and interference lines.
- Large `PASRAH` title glitches between clean and corrupted states.

### Loading
- Slow scanline, single progress bar, and atmospheric quote.

### Settings
- Broken-terminal styling rather than generic sliders on clean cards.
- Glitch intensity and jumpscare warning are explicit accessibility controls.

## 6. Sanity And Horror Effect System

| Sanity band | State | UI behavior |
| --- | --- | --- |
| `100-70` | Stable | low vignette, no corruption, normal bar updates |
| `69-40` | Uneasy | stronger vignette, occasional objective flicker, stamina bar breathes |
| `39-20` | Scared | random 2-4px UI desync, stronger channel split, silhouette edge pops |
| `19-0` | Breaking | full glitch bursts every 3-5s, text corruption, minimap outage, vibration, PASRAH flash |

Global effects:
- Noise overlay: `5%` opacity idle, up to `30%` during scare.
- Scanlines: always on but subtle.
- Jumpscare disruption: `200 ms` shake, `50 ms` flash, `800 ms` glitch tail.
- Chromatic aberration: red `+3 px`, blue `-3 px` during fear spikes.

## 7. Figma Deliverable Structure

Required pages:
1. `Visual Direction`
2. `Design System`
3. `Components`
4. `Game Screens`
5. `Effects & Animation`
6. `Icon & Asset Sheet`

Frame set:
- Desktop frames at `1920x1080`.
- Mobile frames at `390x844`.
- Components should use auto layout and variants for `default`, `hover`, `active`, `disabled`, and `locked`.

Naming:
- Use English frame and component names for direct Roblox `ImageLabel` mapping.
- Export assets as `Pasrah_Icon_SanityHeart_256`, `Pasrah_Rarity_LegendaryCard_512`, `Pasrah_Screen_MenuFog_A`, and similar.

## 8. Roblox ModuleScripts Included

Generated scripts:
- `SanityController.lua`
- `HUDController.lua`
- `MinimapController.lua`
- `InventoryController.lua`
- `RankedController.lua`
- `RoyalPassController.lua`
- `EffectsController.lua`
- `UIAnimations.lua`

Support module:
- `UIConfig.lua`

## 9. Roblox Studio Setup Notes

Folder plan:
- `ReplicatedStorage/PasrahUI/Shared/UIConfig`
- `ReplicatedStorage/PasrahUI/Modules/*`
- `ReplicatedStorage/PasrahUI/Remotes/*`
- `StarterGui/PasrahUI`

Recommended remotes:
- `SanityUpdate`
- `ObjectiveUpdate`
- `HUDSnapshot`
- `MapSync`
- `InventorySnapshot`
- `InventoryAction`
- `RankedSync`
- `RoyalPassSync`
- `RoyalPassClaim`
- `RoyalPassPurchase`
- `EffectsEvent`

Implementation notes:
- Use `ScreenGui.IgnoreGuiInset = true`.
- Gate console adjustments with `GuiService:IsTenFootInterface()`.
- Use `UIScale` and scale-based `UDim2`.
- Keep visible `ImageLabel` count under `50`.
- Upload all final PNG assets to Roblox CDN before live integration.

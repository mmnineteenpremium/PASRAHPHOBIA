# TOOL MODEL IMPORT GUIDE  PASRAHPHOBIA

## Default Loadout Tools (Implement First):
1. **Senter (Flashlight)**  Already implemented in 7.1.2
2. **Detektor MEDOK (EMF Reader)**  Handheld device with screen
3. **Termometer Suhu (Thermometer)**  Digital display device

## Tool Model Requirements:
- **Size:** Handheld scale (1-3 studs max dimension)
- **Anchored:** false (player will hold)
- **CanCollide:** false (prevent physics glitches)
- **Material:** Plastic or SmoothPlastic for devices
- **PrimaryPart:** Set for proper positioning

## Asset Sources:
1. **Creator Store:** Search "Handheld Device", "Flashlight", "Scanner"
2. **Blender Custom:** Model realistic investigation tools
3. **Placeholder:** Use basic Parts with Neon screens temporarily

## Tool Structure (Example - EMF Reader):
```
EMFReader (Tool)
 Handle (Part, PrimaryPart)
 Screen (Part with SurfaceGui)
    SurfaceGui
        Frame
            ReadingLabel (TextLabel)
 LEDIndicator (Part, Material: Neon)
 Script (Tool functionality)
```

## Interactive GUI Implementation:
- Use **SurfaceGui** on tool parts for screens
- TextLabel shows dynamic readings (EMF level 1-5)
- LED color changes based on reading (green = safe, red = danger)

## Next Steps:
- Import tool models from Creator Store or create in Blender
- Attach SurfaceGui to screen parts
- Hook up to EvidenceToolSystem (server-side validation)

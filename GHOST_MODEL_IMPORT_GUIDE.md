# GHOST MODEL IMPORT GUIDE  PASRAHPHOBIA

## Priority Ghost Models (Phase 7.2)

### HIGH PRIORITY (Implement First):
1. **Pocong** (Shrouded ghost, floating)
2. **Kuntilanak** (Female ghost, long hair)
3. **Genderuwo** (Shadow figure, muscular)

## Model Requirements:
- **Rig:** R15 or custom humanoid rig (for Roblox pathfinding compatibility)
- **Transparency:** Base 0.3, Manifestation 0.0, Dematerialization 1.0
- **LOD:** Level of Detail models for performance (optional Phase 8)

## Asset Sources:
1. **Creator Store:** Search "Ghost Rig", "Horror Character"
2. **Blender Custom:** Model + export as .fbx  Import to Roblox Studio
3. **Placeholder:** Use simple Part with Neon material temporarily

## Import Steps:
1. Open Roblox Studio
2. Go to Home  Toolbox  Creator Store
3. Search "Ghost" or "Horror Character"
4. Insert model into Workspace
5. Move to ReplicatedStorage/Assets/GhostModels/
6. Configure transparency and material properties

## Ghost Model Structure (Example):
```
GhostModels/
 Pocong/
    Model (Tool or Model instance)
    Animations/
       Walk
       Run
       Attack
       Dematerialize
    Config (ModuleScript with ghost stats)
 Kuntilanak/
 Genderuwo/
```

## Next Steps:
- After importing models, proceed to Task 7.2.2 (Manifestation VFX)
- Hook up animations in GhostSystem (server-side)

# Mode + Difficulty Pipeline Audit
Date: 2026-03-13

**Scope**
This audit covers the end-to-end mode and difficulty selection pipeline, plus explicit difficulty, sanity, and hunt formulas for validation.

**Pipeline Flow (End-to-End)**
1. UI triggers selection and queue requests via `LobbyEvent`.
2. Client `RoomBrowserController` sends `SelectMode` and `SelectDifficulty`.
3. `LobbySystem.Controller` routes requests to `LobbySystem.Service`.
4. `LobbySystem.Service` normalizes selection and builds queue payload.
5. `MatchSystem.Service` sanitizes payload and resolves difficulty profile.
6. `MatchQueue` forms matches and `MatchBuilder` builds `MatchInstance`.
7. `MatchLifecycle` starts match and `MatchTeleport` moves players.

**Key Files**
1. `src/client/UI/Main.lua`
2. `src/client/UI/RoomBrowserController.lua`
3. `src/server/LobbySystem/Controller.lua`
4. `src/server/LobbySystem/Service.lua`
5. `src/server/MatchSystem/MatchService.lua`
6. `src/server/MatchSystem/MatchQueue.lua`
7. `src/server/MatchSystem/MatchBuilder.lua`

**Likely Failure Points**
1. Reward difficulty multiplier mismatch: `RewardCalculationSystem` expects difficulty strings `Easy/Normal/Hard/Nightmare`, while match difficulty names are `Mudah/Lumayan/Angker/Uji Nyali`, so non-numeric difficulty values default to `1.2`. See `src/server/RewardCalculationSystem/Service.lua` and `src/shared/GameData/ModeDifficultyConfig.lua`.
2. Ranked difficulty requires MMR data; if `averageMMR` is missing, Ranked difficulty falls back to `DefaultRankedDifficulty` (`Lumayan`). See `src/server/LobbySystem/Service.lua` and `src/server/MatchSystem/MatchService.lua`.
3. Config drift risk: there are defaults in `ModeDifficultyConfig.lua`, `LobbySystem/ModeSelectionConfig.lua`, and `MatchService.lua`. If any diverge, client/server selection can be inconsistent.
4. MatchQueue difficulty resolution for Classic uses selected difficulty from queue entries; mixed party selections could lead to a non-obvious chosen difficulty. See `src/server/MatchSystem/MatchQueue.lua`.

**Difficulty Table (Classic)**
Source: `src/shared/GameData/ModeDifficultyConfig.lua`

| Difficulty | EvidenceCount | GhostAggression | HuntFrequency | EvidenceClarity | SanityDrain | DifficultyMode | RewardMultiplier |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Mudah | 4 | 0.85 | 0.8 | 1.2 | 0.8 | Easy | 1.0 |
| Lumayan | 3 | 1.0 | 1.0 | 1.0 | 1.0 | Normal | 1.2 |
| Angker | 3 | 1.4 | 1.3 | 0.8 | 1.2 | Hard | 1.45 |
| Uji Nyali | 2 | 1.65 | 1.5 | 0.65 | 1.4 | Hard | 1.7 |

**Difficulty Profile Resolution**
Source: `src/server/MatchSystem/MatchService.lua`
1. Resolve mode to `Classic` or `Ranked`.
2. Resolve difficulty name from Classic selection or Ranked MMR band.
3. Build `difficultyProfile` from `ModeDifficultyConfig` values.
4. Merge legacy profile from `DifficultyConfigSystem` if available.

**Sanity Drain Formulas**
Source: `src/server/SanitySystem/Service.lua`

Per snapshot:
```text
drain =
  (BaseDarkDrainPerSecond * dt, if inDark)
  + (GhostProximityDrainPerSecond * dt, if nearGhost)
  + (AloneDrainPerSecond * dt, if alone)

restore =
  (LightRecoveryPerSecond * dt, if inLight)
  + (TeammateRecoveryPerSecond * dt, if nearTeammates)
  + (LeaveGhostRoomRecoveryPerSecond * dt, if leftGhostRoom)

sanity = clamp(sanity - (drain * SanityDrainMultiplier) + restore, MinSanity, MaxSanity)
```

Difficulty multiplier source:
1. `difficultyProfile.SanityDrainMultiplier` if present
2. `difficultyProfile.SanityDrain` (from `ModeDifficultyConfig`)
3. Default `1.0`

Event drains:
1. Manifestation drain: `6`
2. Hunt start drain: `10`
3. Environmental event drain: `0.5`
4. Ghost event drain: `1.0 * intensity`
5. Hunt pressure drain: `1.5 + pressure`

**Hunt Trigger Logic (Threshold-Based)**
Source: `src/server/HuntSystem/Service.lua`

Hunt request allowed when:
1. `averageSanity <= 45`
2. `aggression >= 75`
3. `escalationStage` in `{ Aggressive, Hunting }`
4. No active hunt, no pending hunt, and cooldown expired

**Hunt Intensity and Duration (HuntSystem)**
Source: `src/server/HuntSystem/Service.lua`

```text
sanityFactor = clamp((100 - averageSanity) / 100, 0, 1)
aggressionFactor = clamp(aggression / 100, 0, 1)
escalationBonus = 0.2 if escalationStage is eligible, else 0

intensity = clamp((sanityFactor * 0.5) + (aggressionFactor * 0.4) + escalationBonus, 0.35, 1)
duration = clamp(BaseDurationSeconds + floor(intensity * 24), MinDurationSeconds, MaxDurationSeconds)
speedMultiplier = clamp(1.15 + (intensity * 0.85), 1.15, 2)
```

**Adaptive Hunt Intensity (AdaptiveHuntSystem)**
Source: `src/server/AdaptiveHuntSystem/Service.lua`

```text
intensity =
  clamp(
    (((100 - averageSanity) * 0.45) + (aggression * 0.40) + (playerNoise * 0.15))
    * personalityHuntMultiplier,
    0,
    100
  )

durationSeconds = clamp(20 + (intensity * 0.25), 18, 50)
cooldownSeconds = clamp(65 - (intensity * 0.4), 20, 75)
```


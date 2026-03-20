# PHASE 6 PERFORMANCE PROFILING - EXECUTION PROMPT WITH RAG

## CONTEXT

Session 5 completed UI fixes and debugging infrastructure. Step 3 validation pending. Next phase: Performance & Security verification per roadmap.

**From reports.md:**
- Performance Profiling: COMPLETED (timing hooks Ghost/Evidence/Hunt, 100ms warn threshold)
- Anti-Cheat Layer: COMPLETED (evidence whitelist, node check, bounds check)

**Mission:** Verify existing profiling works, add missing instrumentation, optimize bottlenecks.

---

## RAG CAPABILITY ENABLED

**Claude Code: You have access to project knowledge search.**

Use RAG to find existing implementations before creating new code:

```
BEFORE writing ANY profiling code:
1. Search for "PerformanceProfiler" or "profiling" in project
2. Search for "timing hooks" or "100ms warn"
3. Search for existing Ghost/Evidence/Hunt instrumentation
4. Verify what exists vs what's missing
```

**Search queries to run:**
- "performance profiling system timing hooks"
- "GhostSystem performance measurement"
- "EvidenceSystem performance measurement"
- "HuntSystem performance measurement"
- "100ms warn threshold bottleneck"
- "frame time monitoring FPS"

**RAG Output Format:**
```markdown
## RAG SEARCH RESULTS

### Query: "performance profiling system"
**Found:** [Yes/No]
**Location:** [File path + line numbers]
**Summary:** [What exists]
**Gaps:** [What's missing]

### Query: "GhostSystem performance"
...
```

---

## YOUR MISSION

Audit and enhance performance profiling infrastructure:
1. **Search existing** (via RAG) - find what's already implemented
2. **Identify gaps** - what's missing from 100% coverage
3. **Add instrumentation** - fill gaps with minimal overhead
4. **Create dashboard** - real-time performance monitoring UI
5. **Optimize bottlenecks** - if any found during profiling

---

## FILES IN SCOPE (After RAG Search)

**EXPECTED LOCATIONS (verify via RAG first):**
- `src/server/PerformanceProfiler/` or similar (search first)
- `src/server/GhostSystem/Main.lua` (timing hooks)
- `src/server/EvidenceSystem/Main.lua` (timing hooks)
- `src/server/HuntSystem/Main.lua` (timing hooks)

**NEW FILES (if gaps found):**
- `src/server/PerformanceMonitor/Main.lua` (if not exists)
- `src/client/PerformanceDashboard.client.lua` (real-time UI)
- `PERFORMANCE_REPORT.md` (profiling results)

---

## EXECUTION STEPS

### PHASE 1: RAG DISCOVERY (MANDATORY FIRST STEP)

**1.1 Search Existing Profiling System**
```
Query 1: "PerformanceProfiler performance profiling timing"
Query 2: "100ms warn threshold bottleneck detection"
Query 3: "frame time FPS monitoring system"

For each query:
- Document what exists
- Note file locations
- Identify implementation patterns
```

**1.2 Search System-Level Instrumentation**
```
Query 4: "GhostSystem performance timing hooks measurement"
Query 5: "EvidenceSystem performance timing hooks measurement"
Query 6: "HuntSystem performance timing hooks measurement"

For each:
- Is timing instrumentation present?
- Where are the hooks? (Init, Update, specific methods?)
- What threshold is used? (100ms confirmed?)
```

**1.3 Search Anti-Cheat Performance Impact**
```
Query 7: "anti-cheat performance overhead validation check"
Query 8: "RemoteEvent security rate limit performance"

Verify:
- Does anti-cheat layer add significant overhead?
- Are rate limits causing false positives?
```

**1.4 Generate Gap Analysis**
```markdown
## PROFILING GAP ANALYSIS

### Systems WITH Instrumentation:
- [List systems found with timing hooks]

### Systems WITHOUT Instrumentation:
- [List systems missing profiling]

### Missing Features:
- Real-time dashboard? [Yes/No]
- Memory profiling? [Yes/No]
- Network profiling? [Yes/No]
- Client-side FPS monitoring? [Yes/No]
```

---

### PHASE 2: INSTRUMENTATION AUDIT

**2.1 Verify Existing Hooks**
For each system found with profiling:
```lua
-- Expected pattern:
local startTime = tick()
-- ... system logic ...
local elapsed = (tick() - startTime) * 1000
if elapsed > 100 then
    warn(string.format("[Perf] %s took %.2fms", systemName, elapsed))
end
```

**Verify:**
- ✓ Timing measurement accurate?
- ✓ Threshold configurable?
- ✓ Logging consistent format?
- ✓ No performance overhead from profiling itself?

**2.2 Identify Bottlenecks**
If profiling logs exist in reports.md or prior sessions:
```
Search for:
- Warnings over 100ms
- Repeated slow operations
- Memory spikes
- Frame drops
```

---

### PHASE 3: FILL GAPS (Based on RAG Findings)

**3.1 Add Missing System Instrumentation**

**IF GhostSystem missing hooks:**
```lua
-- Add to GhostSystem/Main.lua critical paths:
function GhostSystem:UpdateGhostState(matchId)
    local perfStart = tick()
    
    -- existing logic here
    
    local elapsed = (tick() - perfStart) * 1000
    if elapsed > 100 then
        warn(string.format("[Perf:Ghost] UpdateState took %.2fms (match:%s)", 
            elapsed, matchId))
    end
end
```

**IF EvidenceSystem missing hooks:**
```lua
-- Add to EvidenceSystem/Main.lua:
function EvidenceSystem:SpawnEvidence(matchId, evidenceType)
    local perfStart = tick()
    
    -- existing spawn logic
    
    local elapsed = (tick() - perfStart) * 1000
    if elapsed > 100 then
        warn(string.format("[Perf:Evidence] SpawnEvidence(%s) took %.2fms", 
            evidenceType, elapsed))
    end
end
```

**IF HuntSystem missing hooks:**
```lua
-- Add to HuntSystem/Main.lua:
function HuntSystem:ProcessHunt(matchId)
    local perfStart = tick()
    
    -- existing hunt logic
    
    local elapsed = (tick() - perfStart) * 1000
    if elapsed > 100 then
        warn(string.format("[Perf:Hunt] ProcessHunt took %.2fms (match:%s)", 
            elapsed, matchId))
    end
end
```

**3.2 Create Performance Dashboard (if missing)**

**FILE: `src/client/PerformanceDashboard.client.lua`**
```lua
-- Real-time performance monitoring UI
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PerformanceDashboard = {}

local gui = nil
local metrics = {
    fps = 0,
    ping = 0,
    memoryMB = 0,
    lastUpdate = 0,
}

function PerformanceDashboard:Init()
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create minimal performance overlay
    gui = Instance.new("ScreenGui")
    gui.Name = "PerformanceDashboard"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 100
    gui.Enabled = false  -- Toggle with _G.PerfDash:Toggle()
    gui.Parent = playerGui
    
    local panel = Instance.new("Frame")
    panel.Name = "Panel"
    panel.AnchorPoint = Vector2.new(1, 0)
    panel.Position = UDim2.new(1, -10, 0, 10)
    panel.Size = UDim2.fromOffset(200, 100)
    panel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    panel.BackgroundTransparency = 0.3
    panel.BorderSizePixel = 0
    panel.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = panel
    
    local label = Instance.new("TextLabel")
    label.Name = "MetricsLabel"
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(0, 255, 100)
    label.Font = Enum.Font.Code
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Top
    label.Text = "Performance Dashboard"
    label.Parent = panel
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingLeft = UDim.new(0, 8)
    padding.Parent = label
    
    self.gui = gui
    self.label = label
    
    -- Update loop
    RunService.Heartbeat:Connect(function()
        self:Update()
    end)
end

function PerformanceDashboard:Update()
    local now = tick()
    if now - metrics.lastUpdate < 0.5 then return end
    metrics.lastUpdate = now
    
    -- FPS
    metrics.fps = math.floor(1 / RunService.Heartbeat:Wait())
    
    -- Memory
    local stats = game:GetService("Stats")
    metrics.memoryMB = math.floor(stats:GetTotalMemoryUsageMb())
    
    -- Ping (if available)
    local player = Players.LocalPlayer
    if player then
        metrics.ping = math.floor(player:GetNetworkPing() * 1000)
    end
    
    -- Update label
    self.label.Text = string.format(
        "FPS: %d\nPing: %dms\nMemory: %dMB",
        metrics.fps,
        metrics.ping,
        metrics.memoryMB
    )
    
    -- Color code FPS
    if metrics.fps >= 55 then
        self.label.TextColor3 = Color3.fromRGB(0, 255, 100)  -- Green
    elseif metrics.fps >= 30 then
        self.label.TextColor3 = Color3.fromRGB(255, 200, 0)  -- Yellow
    else
        self.label.TextColor3 = Color3.fromRGB(255, 50, 50)  -- Red
    end
end

function PerformanceDashboard:Toggle()
    if self.gui then
        self.gui.Enabled = not self.gui.Enabled
        print(string.format("[PerfDash] Dashboard %s", 
            self.gui.Enabled and "shown" or "hidden"))
    end
end

function PerformanceDashboard:Start()
    self:Init()
    print("[PerfDash] Performance dashboard ready. Use _G.PerfDash:Toggle()")
end

-- Expose globally
_G.PerfDash = PerformanceDashboard
PerformanceDashboard:Start()

return PerformanceDashboard
```

**3.3 Create Performance Report Template**

**FILE: `PERFORMANCE_REPORT.md`**
```markdown
# PERFORMANCE PROFILING REPORT

**Session:** [Number]  
**Date:** [YYYY-MM-DD]  
**Tested By:** [Name]  
**Build:** [Studio/Live]

---

## TEST CONFIGURATION

**Match Settings:**
- Players: [1/2/3/4]
- Map: [MapName]
- Difficulty: [Mudah/Lumayan/Angker/Uji Nyali]
- Duration: [Minutes]

**Hardware:**
- CPU: [Model]
- RAM: [GB]
- GPU: [Model]

---

## PERFORMANCE METRICS

### Server-Side (from Output logs)

**GhostSystem:**
| Operation | Average (ms) | Peak (ms) | Warnings |
|-----------|--------------|-----------|----------|
| UpdateState | - | - | 0 |
| ProcessHunt | - | - | 0 |

**EvidenceSystem:**
| Operation | Average (ms) | Peak (ms) | Warnings |
|-----------|--------------|-----------|----------|
| SpawnEvidence | - | - | 0 |
| TriggerEvidence | - | - | 0 |

**HuntSystem:**
| Operation | Average (ms) | Peak (ms) | Warnings |
|-----------|--------------|-----------|----------|
| StartHunt | - | - | 0 |
| EndHunt | - | - | 0 |

**MatchSystem:**
| Operation | Average (ms) | Peak (ms) | Warnings |
|-----------|--------------|-----------|----------|
| BuildMatch | - | - | 0 |
| TeleportPlayers | - | - | 0 |

### Client-Side (from PerformanceDashboard)

**Frame Rate:**
- Average FPS: [XX]
- Minimum FPS: [XX]
- Drops below 30: [Yes/No]

**Network:**
- Average Ping: [XXms]
- Spike Count: [X]

**Memory:**
- Starting Memory: [XXX MB]
- Peak Memory: [XXX MB]
- Memory Leak: [Yes/No]

---

## BOTTLENECKS IDENTIFIED

**Critical (>100ms):**
- [None] or [List with timestamps]

**Warning (50-100ms):**
- [None] or [List with timestamps]

**Minor (<50ms but notable):**
- [None] or [List]

---

## OPTIMIZATION RECOMMENDATIONS

1. [If bottlenecks found, list specific optimizations]
2. [If no issues, state "No optimization needed"]

---

## CONCLUSION

**Overall Performance:** EXCELLENT / GOOD / ACCEPTABLE / POOR  
**Ready for Phase 7:** YES / NO  
**Action Items:** [List if any]
```

---

### PHASE 4: VERIFICATION & REPORTING

**4.1 Run Performance Tests**
```
1. Start local server with 2 players
2. Complete full match flow (queue → match → end)
3. Enable PerformanceDashboard (_G.PerfDash:Toggle())
4. Monitor Output for [Perf] warnings
5. Document all metrics in PERFORMANCE_REPORT.md
```

**4.2 Analyze Results**
```
Check for:
- Any operations >100ms?
- Any memory leaks?
- Any FPS drops below 30?
- Any network spikes?
```

**4.3 Generate Recommendations**
```
IF bottlenecks found:
  - Identify root cause
  - Propose optimization
  - Estimate impact

IF no issues:
  - Confirm system ready for Phase 7
```

---

## OUTPUT

### DELIVERABLE 1: RAG Discovery Report
```markdown
## PROFILING INFRASTRUCTURE AUDIT

### Existing Systems:
[List what was found via RAG]

### Missing Components:
[List gaps identified]

### Implementation Status:
[What was added this session]
```

### DELIVERABLE 2: Enhanced Files
- Modified system files with timing hooks (if gaps found)
- `src/client/PerformanceDashboard.client.lua` (if created)
- `PERFORMANCE_REPORT.md` (template)

### DELIVERABLE 3: Performance Baseline
- Completed PERFORMANCE_REPORT.md with actual test data
- Identified bottlenecks (if any)
- Optimization recommendations (if needed)

---

## AFTER EXECUTION

Update reports.md:
```markdown
## 2026-03-17 (Session 5 - Performance Profiling)

### Completed
- RAG search for existing profiling: [Results]
- Performance instrumentation audit: [Systems checked]
- Gap filling: [What was added]
- PerformanceDashboard created: real-time FPS/Ping/Memory
- Performance baseline test: [Results]

### Performance Metrics
- Server-side operations: [All <100ms / Issues found]
- Client-side FPS: [Average XX, Min XX]
- Memory usage: [Peak XXX MB, no leaks]
- Network latency: [Average XXms ping]

### Bottlenecks Identified
- [None] OR [List with severity]

### Files Created/Modified
- [List]

### Next Action
- Phase 7: Launch Preparation (if no bottlenecks)
- OR: Performance optimization (if issues found)
```

---

## CRITICAL RULES

**RAG USAGE:**
✅ ALWAYS search before creating new code
✅ Document all RAG findings
✅ Reuse existing patterns
✅ Only fill actual gaps

**PERFORMANCE:**
✅ Minimal profiling overhead (<1ms)
✅ Configurable thresholds
✅ Non-blocking logging
✅ Production-safe instrumentation

**DO NOT:**
❌ Create duplicate profiling systems
❌ Add heavy instrumentation (>5% overhead)
❌ Block game logic for profiling
❌ Spam logs with non-critical metrics

**MAX ITERATIONS:** 2 (3rd = RCA mandatory)

---

## BEGIN EXECUTION

**STEP 1:** Run RAG searches (mandatory first)  
**STEP 2:** Audit existing profiling  
**STEP 3:** Fill gaps if found  
**STEP 4:** Run performance baseline test  
**STEP 5:** Document results  

**GO! 🚀**

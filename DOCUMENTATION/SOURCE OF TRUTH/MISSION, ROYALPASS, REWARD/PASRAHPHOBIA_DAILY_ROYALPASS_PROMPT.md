=======================================================================
PASRAHPHOBIA — TASK: DAILY ENGAGEMENT & ROYAL PASS SYSTEM
EXECUTOR: Claude Code
AUTHORITY: CANONICAL_SPECIFICATIONS_v2.md + DOC_INDEX.md
ROBLOX: task.wait() only | no string.split() | no deprecated API
APPROACH: EXTEND existing systems — jangan overwrite DataPersistenceService,
          EconomySystem, ProgressionSystem, EventBus yang sudah berjalan
=======================================================================

⚠️  CANONICAL RULES (dari CANONICAL_SPECIFICATIONS_v2.md — wajib dipatuhi):
    - No owner ganda: satu sistem = satu owner untuk satu set field data
    - No duplikasi source: jangan subscribe ke event yang sudah di-handle sistem lain
    - No drift antar-lane: jangan buat jalur tulis data paralel
    - DailyEngagementService adalah SATU-SATUNYA owner untuk:
        data.daily.*  |  data.royalPass.*  |  data.gacha  |  data.gachaTickets
    - Sistem lama (DailyCheckinSystem, DailyMissionSystem, RoyalPassSystem)
      harus DINONAKTIFKAN dari jalur yang diambil alih SEBELUM lane baru aktif.

=======================================================================
## PRE-FLIGHT (WAJIB SEBELUM MULAI — JANGAN SKIP SATUPUN)
=======================================================================

```bash
# 1. Konfirmasi branch
git branch --show-current

# 2. Baca fungsi existing yang akan kita extend
grep -n "function\|daily\|checkin\|royalPass\|mission" \
  src/ServerScriptService/Server/DailyCheckinSystem/Service.lua 2>/dev/null | head -40
grep -n "function\|daily\|checkin\|royalPass\|mission" \
  src/ServerScriptService/Server/DailyMissionSystem/Service.lua 2>/dev/null | head -40
grep -n "function\|daily\|checkin\|royalPass\|mission" \
  src/ServerScriptService/Server/RoyalPassSystem/Service.lua 2>/dev/null | head -40

# 3. Cek schema player data — field apa saja yang sudah ada
grep -n "daily\|royalPass\|checkin\|mission\|gacha\|gachaTickets" \
  src/ServerScriptService/Server/DataPersistenceService/Service.lua | head -30

# 4. Cek EconomySystem — method Grant dan Deduct yang ada
grep -n "function.*Grant\|function.*Deduct\|function.*Add\|MM\|PP" \
  src/ServerScriptService/Server/EconomySystem/Service.lua | head -20

# ── SAFETY CHECK: OWNERSHIP AUDIT (WAJIB) ────────────────────────────
# 5a. Cek EventBus subscriptions EXISTING di sistem yang akan di-extend
#     Tujuan: temukan event yang sudah di-handle → HARUS dinonaktifkan dulu
grep -n "Subscribe\|:on\|:Listen\|:Connect" \
  src/ServerScriptService/Server/DailyCheckinSystem/Service.lua 2>/dev/null
grep -n "Subscribe\|:on\|:Listen\|:Connect" \
  src/ServerScriptService/Server/DailyMissionSystem/Service.lua 2>/dev/null
grep -n "Subscribe\|:on\|:Listen\|:Connect" \
  src/ServerScriptService/Server/RoyalPassSystem/Service.lua 2>/dev/null

# 5b. Cek PlayerAdded handler di sistem lama
#     Tujuan: jika ada, perlu dikonfirmasi tidak overlap dengan Start() baru
grep -n "PlayerAdded\|PlayerRemoving" \
  src/ServerScriptService/Server/DailyCheckinSystem/Service.lua 2>/dev/null
grep -n "PlayerAdded\|PlayerRemoving" \
  src/ServerScriptService/Server/DailyMissionSystem/Service.lua 2>/dev/null

# 5c. Cek semua EventBus:Publish yang ada di game → verifikasi nama event aktual
grep -rn "Publish\|:Emit\|:Fire" \
  src/ServerScriptService/Server/ \
  --include="*.lua" | grep -v DailyEngagement | grep -v "--" | head -50

# 6. Cek SystemRegistry — urutan load dan grup yang ada
grep -n "DailyCheckin\|DailyMission\|RoyalPass\|LiveService\|Economy\|Progression" \
  src/ServerScriptService/Server/Core/SystemRegistry.lua | head -30
```

⚠️  SETELAH membaca output Pre-flight 5a & 5b:
    - Jika DailyCheckinSystem/DailyMissionSystem/RoyalPassSystem SUDAH punya
      EventBus subscription untuk event yang sama (MatchEnded, HuntSurvived, dll),
      kamu WAJIB comment-out atau remove subscription lama tersebut sebelum
      DailyEngagementService subscribe ke event yang sama.
    - Jika sistem lama punya PlayerAdded handler yang menulis ke data.daily.*
      atau data.royalPass.*, comment-out handler lama tersebut.
    - Dokumentasikan semua yang di-disable di LOGS/IMPLEMENTATION_LOG.md.
    - Sesuaikan nama event di Start() dengan nama aktual dari output Pre-flight 5c.

=======================================================================
## ARSITEKTUR SISTEM (BACA DULU, JANGAN LANGSUNG KODE)
=======================================================================

### Hierarki sistem yang akan dibuat/diextend:

```
DailyEngagementSystem (NEW — orchestrator, single owner data.daily.* & data.royalPass.*)
├── DailyCheckinSystem  (EXTEND existing — nonaktifkan PlayerAdded & data write lama)
│   ├── 7-Day Login Streak
│   └── 30-Day Milestone
├── DailyMissionSystem  (EXTEND existing — nonaktifkan EventBus subscription lama)
│   ├── 3 Task Harian
│   └── 1 Bonus Challenge
├── RoyalPassSystem     (EXTEND existing — nonaktifkan tier-up logic lama jika ada)
│   ├── Free Track (60 tier)
│   └── Premium Track (60 tier)
└── GachaSystem         (NEW — standalone, owner data.gacha & data.gachaTickets)
    └── Pity System
```

### Event flow (pakai EventBus yang sudah ada):
```
GameEvent terjadi
→ EventBus:Publish("<EventName>", payload)
→ DailyEngagementService listen → update progress
→ jika complete → DailyEngagementService:OnMissionComplete()
→ grant reward via EconomySystem + ProgressionSystem yang sudah ada
→ FireClient ke UI
```

### Schema fields baru yang akan ditambahkan ke DataPersistenceService:
Sebelum Task 5, tambahkan default values berikut ke schema DataPersistenceService:
```lua
-- Tambahkan ke default player data template:
daily = {
    lastResetDate        = "",
    lastCheckinDate      = "",
    lastCheckinTimestamp = 0,
    streakCount          = 0,
    totalLoginDays       = 0,
    missions             = {},
},
royalPass = {
    owned  = false,
    xp     = 0,
    tier   = 0,
    season = 1,
},
gacha = {
    pityCount     = 0,
    epicPityCount = 0,
    history       = {},
},
gachaTickets = 0,
```

=======================================================================
## TASK 1 — CONFIG: DailyMissionConfig.lua
=======================================================================

**File:** `src/ReplicatedStorage/Shared/Config/DailyMissionConfig.lua`

Cek dulu apakah sudah ada. Jika ada, BACA dulu sebelum extend.

```lua
-- DailyMissionConfig.lua
-- PASRAHPHOBIA Daily Mission Configuration
-- Ref: CANONICAL_SPECIFICATIONS_v2.md
-- ATURAN: Semua misi harus bisa diselesaikan player casual dalam 1 sesi
-- ATURAN: Bonus Challenge boleh lebih susah tapi tetap achievable

local DailyMissionConfig = {}

-- ── MISSION POOL (dirotasi setiap hari via seed tanggal) ──────
-- Setiap hari: 3 dari pool DAILY dipilih + 1 dari pool CHALLENGE
-- Seed = os.date("%Y%m%d") sehingga semua player dapat misi yang sama

DailyMissionConfig.DAILY_POOL = {

    -- ── MATCH BASED ─────────────────────────────────────────
    {
        id           = "dm_play_match",
        title        = "Ikut Investigasi",
        desc         = "Selesaikan {target} match apapun.",
        type         = "MATCH_COMPLETE",
        targets      = { 1, 2, 3 },           -- difficulty variants
        xpReward     = { 50, 80, 120 },
        mmReward     = { 100, 160, 240 },
        category     = "MATCH",
        icon         = "🔦",
    },
    {
        id           = "dm_survive_hunt",
        title        = "Lari dari Bayangan",
        desc         = "Selamat dari {target} hunt tanpa mati.",
        type         = "SURVIVE_HUNT",
        targets      = { 1, 2, 3 },
        xpReward     = { 80, 130, 200 },
        mmReward     = { 150, 240, 380 },
        category     = "SURVIVAL",
        icon         = "👁️",
    },
    {
        id           = "dm_identify_ghost",
        title        = "Kenali Sosok Itu",
        desc         = "Identifikasi ghost dengan benar {target} kali.",
        type         = "GHOST_IDENTIFIED",
        targets      = { 1, 2, 3 },
        xpReward     = { 100, 160, 240 },
        mmReward     = { 200, 320, 480 },
        category     = "INVESTIGATION",
        icon         = "📖",
    },
    {
        id           = "dm_collect_evidence",
        title        = "Kumpulkan Bukti",
        desc         = "Kumpulkan {target} evidence dalam 1 match.",
        type         = "EVIDENCE_COLLECTED",
        targets      = { 1, 2, 3 },
        xpReward     = { 60, 100, 160 },
        mmReward     = { 120, 200, 320 },
        category     = "INVESTIGATION",
        icon         = "🔍",
        singleMatch  = true,               -- harus dalam 1 match
    },

    -- ── SOCIAL / PARTY ───────────────────────────────────────
    {
        id           = "dm_play_with_party",
        title        = "Pergi Bersama",
        desc         = "Selesaikan match dengan minimal {target} teman.",
        type         = "MATCH_WITH_PARTY",
        targets      = { 1, 2, 3 },
        xpReward     = { 70, 120, 180 },
        mmReward     = { 140, 240, 360 },
        category     = "SOCIAL",
        icon         = "👥",
    },
    {
        id           = "dm_host_room",
        title        = "Jadi Pemimpin",
        desc         = "Buat room dan host {target} match.",
        type         = "HOST_MATCH",
        targets      = { 1, 1, 2 },
        xpReward     = { 60, 60, 110 },
        mmReward     = { 120, 120, 220 },
        category     = "SOCIAL",
        icon         = "🏠",
    },

    -- ── EXPLORATION / SKILL ──────────────────────────────────
    {
        id           = "dm_use_tool",
        title        = "Ahli Peralatan",
        desc         = "Gunakan tool sebanyak {target} kali.",
        type         = "TOOL_USED",
        targets      = { 5, 10, 20 },
        xpReward     = { 40, 70, 120 },
        mmReward     = { 80, 140, 240 },
        category     = "SKILL",
        icon         = "🔧",
    },
    {
        id           = "dm_hide_closet",
        title        = "Sembunyi!",
        desc         = "Berhasil bersembunyi {target} kali saat hunt.",
        type         = "HIDE_SUCCESS",
        targets      = { 1, 2, 4 },
        xpReward     = { 70, 120, 200 },
        mmReward     = { 140, 240, 400 },
        category     = "SKILL",
        icon         = "🚪",
    },
    {
        id           = "dm_sanity_managed",
        title        = "Tetap Tenang",
        desc         = "Selesaikan match dengan sanity di atas 50.",
        type         = "FINISH_HIGH_SANITY",
        targets      = { 1, 2, 3 },
        xpReward     = { 80, 140, 210 },
        mmReward     = { 160, 280, 420 },
        category     = "SKILL",
        icon         = "🧠",
        threshold    = 50,
    },
    {
        id           = "dm_no_death",
        title        = "Tidak Tersentuh",
        desc         = "Selesaikan {target} match tanpa mati sekali pun.",
        type         = "MATCH_NO_DEATH",
        targets      = { 1, 1, 2 },
        xpReward     = { 120, 120, 220 },
        mmReward     = { 240, 240, 440 },
        category     = "SKILL",
        icon         = "💀",
    },

    -- ── MAP / MODE SPECIFIC ──────────────────────────────────
    {
        id           = "dm_play_haunted",
        title        = "Masuk ke Rumah Itu",
        desc         = "Mainkan match di HauntedHouse sebanyak {target} kali.",
        type         = "MATCH_ON_MAP",
        targets      = { 1, 2, 3 },
        xpReward     = { 60, 110, 170 },
        mmReward     = { 120, 220, 340 },
        category     = "EXPLORATION",
        icon         = "🏚️",
        mapId        = "HauntedHouse",
    },
    {
        id           = "dm_play_ranked",
        title        = "Buktikan Dirimu",
        desc         = "Main {target} match Ranked.",
        type         = "RANKED_MATCH",
        targets      = { 1, 2, 3 },
        xpReward     = { 100, 170, 260 },
        mmReward     = { 200, 340, 520 },
        category     = "RANKED",
        icon         = "🏆",
        requiresUnlock = "Ranked",
    },
}

-- ── BONUS CHALLENGE POOL ──────────────────────────────────────
-- Lebih susah, reward lebih besar, tapi TETAP achievable casual
DailyMissionConfig.CHALLENGE_POOL = {
    {
        id       = "dc_nightmare_survivor",
        title    = "Mimpi Buruk",
        desc     = "Selesaikan 1 match di difficulty Hard atau Nightmare.",
        type     = "MATCH_DIFFICULTY",
        target   = 1,
        xpReward = 300,
        mmReward = 600,
        ppReward = 2,           -- PP kecil sebagai bonus
        icon     = "💀",
        minDifficulty = "Hard",
    },
    {
        id       = "dc_perfect_investigation",
        title    = "Detektif Sempurna",
        desc     = "Identifikasi ghost dengan benar DAN semua player selamat dalam 1 match.",
        type     = "PERFECT_MATCH",
        target   = 1,
        xpReward = 350,
        mmReward = 700,
        ppReward = 2,
        icon     = "⭐",
    },
    {
        id       = "dc_all_evidence",
        title    = "Tiga Bukti",
        desc     = "Kumpulkan semua 3 evidence dalam 1 match.",
        type     = "ALL_EVIDENCE_IN_MATCH",
        target   = 1,
        xpReward = 280,
        mmReward = 560,
        ppReward = 1,
        icon     = "🔬",
    },
    {
        id       = "dc_streak_match",
        title    = "Tak Tertaklukkan",
        desc     = "Menangkan 3 match berturut-turut tanpa kalah.",
        type     = "WIN_STREAK",
        target   = 3,
        xpReward = 400,
        mmReward = 800,
        ppReward = 3,
        icon     = "🔥",
    },
    {
        id       = "dc_ghost_whisperer",
        title    = "Pendengar Bisikan",
        desc     = "Gunakan 5 jenis tool berbeda dalam 1 match.",
        type     = "TOOLS_VARIETY",
        target   = 5,
        xpReward = 260,
        mmReward = 520,
        ppReward = 1,
        icon     = "🎯",
    },
    {
        id       = "dc_solo_survivor",
        title    = "Sendiri di Kegelapan",
        desc     = "Selesaikan 1 match solo (tanpa party) di map apapun.",
        type     = "SOLO_MATCH_COMPLETE",
        target   = 1,
        xpReward = 320,
        mmReward = 640,
        ppReward = 2,
        icon     = "🕯️",
    },
}

-- ── MISSION SELECTION LOGIC ───────────────────────────────────
-- Dipanggil server saat reset harian, bukan client
function DailyMissionConfig.GetTodaysMissions(dateString)
    -- dateString = "20260520" (format os.date("%Y%m%d"))
    local seed = 0
    for i = 1, #dateString do
        seed = seed + string.byte(dateString, i) * i
    end

    -- Pilih 3 dari daily pool (deterministik, sama untuk semua player)
    local pool = DailyMissionConfig.DAILY_POOL
    local chosen = {}
    local used = {}
    local rng = seed

    for _ = 1, 3 do
        local attempts = 0
        repeat
            rng = (rng * 1103515245 + 12345) % 2147483648
            local idx = (rng % #pool) + 1
            attempts = attempts + 1
            if not used[idx] then
                used[idx] = true
                -- Pilih difficulty variant (1=easy, 2=med, 3=hard)
                -- Rotasi: hari ganjil lebih mudah, hari genap lebih susah
                local dayNum = tonumber(dateString:sub(7, 8)) or 1
                local diffIdx = (dayNum % 3) + 1
                local mission = pool[idx]
                table.insert(chosen, {
                    id      = mission.id,
                    title   = mission.title,
                    desc    = mission.desc:gsub("{target}",
                              tostring(mission.targets[diffIdx] or mission.targets[1])),
                    type    = mission.type,
                    target  = mission.targets[diffIdx] or mission.targets[1],
                    xp      = mission.xpReward[diffIdx] or mission.xpReward[1],
                    mm      = mission.mmReward[diffIdx] or mission.mmReward[1],
                    icon    = mission.icon,
                    category= mission.category,
                    singleMatch = mission.singleMatch or false,
                    mapId   = mission.mapId,
                    threshold = mission.threshold,
                })
                break
            end
        until attempts > 20
    end

    -- Pilih 1 challenge
    rng = (rng * 1103515245 + 12345) % 2147483648
    local challengeIdx = (rng % #DailyMissionConfig.CHALLENGE_POOL) + 1
    local c = DailyMissionConfig.CHALLENGE_POOL[challengeIdx]
    table.insert(chosen, {
        id          = c.id,
        title       = c.title,
        desc        = c.desc,
        type        = c.type,
        target      = c.target,
        xp          = c.xpReward,
        mm          = c.mmReward,
        pp          = c.ppReward or 0,
        icon        = c.icon,
        isChallenge = true,
        minDifficulty = c.minDifficulty,
    })

    return chosen
end

return DailyMissionConfig
```

=======================================================================
## TASK 2 — CONFIG: CheckinRewardConfig.lua
=======================================================================

**File:** `src/ReplicatedStorage/Shared/Config/CheckinRewardConfig.lua`

```lua
-- CheckinRewardConfig.lua
-- PASRAHPHOBIA Daily Check-in & Login Milestone Config
-- 7-Day Streak: reward kecil harian + bonus di hari 7
-- 30-Day Milestone: reward besar, tidak harus streak (kumulatif)

local CheckinRewardConfig = {}

-- ── 7-DAY STREAK REWARDS ─────────────────────────────────────
-- Reset jika player tidak login 1 hari
-- Hari 7 = reward terbesar untuk motivasi pertahankan streak
CheckinRewardConfig.STREAK_7 = {
    [1] = { mm = 100,  xp = 50,   pp = 0, title = "Hari 1 — Selamat Datang!",     icon = "🕯️" },
    [2] = { mm = 150,  xp = 70,   pp = 0, title = "Hari 2 — Kamu Kembali",        icon = "👁️" },
    [3] = { mm = 200,  xp = 100,  pp = 0, title = "Hari 3 — Setengah Jalan",      icon = "🔦" },
    [4] = { mm = 250,  xp = 120,  pp = 1, title = "Hari 4 — Makin Berani",        icon = "🗝️" },
    [5] = { mm = 300,  xp = 150,  pp = 1, title = "Hari 5 — Hampir Sampai",       icon = "📖" },
    [6] = { mm = 400,  xp = 200,  pp = 1, title = "Hari 6 — Satu Lagi",           icon = "🔮" },
    [7] = { mm = 800,  xp = 400,  pp = 5,
            cosmeticId = "title_investigator_setia",
            title = "Hari 7 — Kamu Bertahan!",
            icon  = "⭐",
            isStreakBonus = true },
}

-- ── 30-DAY MILESTONE REWARDS ─────────────────────────────────
-- Kumulatif total hari login (tidak harus berturut-turut)
-- Dirancang agar player casual bisa dapat semua dalam ~45 hari
CheckinRewardConfig.MILESTONE_30 = {
    [5]  = { mm = 500,   xp = 250,  pp = 0,
             title = "5 Hari — Mulai Terasa",    icon = "🕯️" },
    [10] = { mm = 1000,  xp = 500,  pp = 2,
             cosmeticId = "border_haunted_frame",
             title = "10 Hari — Sudah Terbiasa", icon = "🔦" },
    [15] = { mm = 1500,  xp = 750,  pp = 3,
             title = "15 Hari — Setengah Bulan", icon = "👁️" },
    [20] = { mm = 2000,  xp = 1000, pp = 5,
             cosmeticId = "emote_pasrah_bow",
             title = "20 Hari — Hampir Sebulan", icon = "🔮" },
    [25] = { mm = 2500,  xp = 1200, pp = 5,
             title = "25 Hari — Nyaris Sampai",  icon = "🗝️" },
    [30] = { mm = 5000,  xp = 2500, pp = 15,
             cosmeticId = "title_penyintas_sejati",
             gachaTickets = 3,
             title = "30 Hari — Penyintas Sejati!",
             icon  = "🏆",
             isMilestoneBonus = true },
}

-- ── STREAK BONUS MULTIPLIER ──────────────────────────────────
-- Setelah streak 7 berlanjut ke 14, 21, 28 dst
-- Multiplier XP untuk match saat streak aktif
CheckinRewardConfig.STREAK_MULTIPLIER = {
    [7]  = 1.10,   -- +10% XP saat streak 7+
    [14] = 1.20,   -- +20% XP saat streak 14+
    [21] = 1.30,   -- +30% XP saat streak 21+
    [28] = 1.50,   -- +50% XP saat streak 28+
}

-- Waktu reset check-in (jam UTC)
CheckinRewardConfig.RESET_HOUR_UTC = 0   -- midnight UTC

return CheckinRewardConfig
```

=======================================================================
## TASK 3 — CONFIG: RoyalPassConfig.lua
=======================================================================

**File:** `src/ReplicatedStorage/Shared/Config/RoyalPassConfig.lua`

```lua
-- RoyalPassConfig.lua
-- PASRAHPHOBIA Royal Pass Season Configuration
-- Season Duration: 60 hari (2 bulan)
-- Free Track: 60 tier, reward setiap tier
-- Premium Track: reward TAMBAHAN di tier yang sama (bukan ganti)
-- Filosofi: Free track harus terasa rewarding, bukan frustrating

local RoyalPassConfig = {}

RoyalPassConfig.SEASON_DURATION_DAYS = 60
RoyalPassConfig.TOTAL_TIERS          = 60
RoyalPassConfig.PREMIUM_PRICE_ROBUX  = 299  -- sesuaikan kebijakan monetisasi
RoyalPassConfig.XP_PER_TIER          = 1000  -- XP untuk naik 1 tier Royal Pass

-- ── XP SUMBER UNTUK ROYAL PASS ──────────────────────────────
-- Royal Pass XP = earned dari aktivitas game, tidak double dengan XP progression
-- CATATAN: Semua konstanta XP harus dibaca dari sini, JANGAN hardcode di Service
RoyalPassConfig.XP_SOURCES = {
    MATCH_COMPLETE     = 100,
    GHOST_IDENTIFIED   = 150,
    DAILY_MISSION_DONE = 200,   -- per task biasa selesai + klaim
    CHALLENGE_DONE     = 350,   -- bonus challenge selesai + klaim
    ALL_3_TASKS_BONUS  = 150,   -- bonus jika selesaikan semua 3 task dalam 1 hari
    RANKED_WIN         = 180,
    CHECKIN            = 150,   -- setiap check-in harian
}

-- ── TIER REWARDS ─────────────────────────────────────────────
-- Format: { free = {...}, premium = {...} }
-- premium = reward TAMBAHAN jika punya Royal Pass
-- Setiap 5 tier: cosmetic milestone
-- Setiap 10 tier: reward signifikan

RoyalPassConfig.TIERS = {}

-- Helper untuk generate tier
local function tier(t, freeReward, premReward)
    RoyalPassConfig.TIERS[t] = {
        tier    = t,
        free    = freeReward,
        premium = premReward,
    }
end

-- Tier 1-10: Warmup
tier(1,  { mm=100 },              { mm=200,  xp=50 })
tier(2,  { xp=100 },              { xp=200,  mm=100 })
tier(3,  { mm=150 },              { mm=300,  pp=1 })
tier(4,  { xp=150 },              { xp=300,  mm=150 })
tier(5,  { mm=200, cosmeticId="border_dim_light" },
         { mm=400, cosmeticId="title_penyelidik_muda", pp=2 })
tier(6,  { mm=150 },              { mm=300,  xp=100 })
tier(7,  { xp=200 },              { xp=400,  mm=150 })
tier(8,  { mm=200 },              { mm=400,  pp=1 })
tier(9,  { xp=200 },              { xp=400,  mm=200 })
tier(10, { mm=500, gachaTickets=1 },
         { mm=1000, gachaTickets=2, pp=5, cosmeticId="emote_tenang" })

-- Tier 11-20: Building Up
tier(11, { mm=200 },              { mm=400, xp=150 })
tier(12, { xp=250 },              { xp=500, mm=200 })
tier(13, { mm=250 },              { mm=500, pp=2 })
tier(14, { xp=250 },              { xp=500, mm=250 })
tier(15, { mm=400, cosmeticId="accessory_senter_kuno" },
         { mm=800, pp=5, cosmeticId="title_pemburu_arwah" })
tier(16, { mm=250 },              { mm=500, xp=200 })
tier(17, { xp=300 },              { xp=600, mm=250 })
tier(18, { mm=300 },              { mm=600, pp=2 })
tier(19, { xp=300 },              { xp=600, mm=300 })
tier(20, { mm=800, gachaTickets=2, cosmeticId="border_ghost_glow" },
         { mm=1600, gachaTickets=3, pp=8, cosmeticId="emote_selidik" })

-- Tier 21-30: Midpoint
tier(21, { mm=300 },              { mm=600, xp=200 })
tier(22, { xp=350 },              { xp=700, mm=300 })
tier(23, { mm=350 },              { mm=700, pp=3 })
tier(24, { xp=350 },              { xp=700, mm=350 })
tier(25, { mm=600, cosmeticId="title_mata_ketiga" },
         { mm=1200, pp=8, cosmeticId="accessory_jimat_pelindung", gachaTickets=1 })
tier(26, { mm=350 },              { mm=700, xp=250 })
tier(27, { xp=400 },              { xp=800, mm=350 })
tier(28, { mm=400 },              { mm=800, pp=3 })
tier(29, { xp=400 },              { xp=800, mm=400 })
tier(30, { mm=1200, gachaTickets=3, cosmeticId="border_ritual_mark" },
         { mm=2400, gachaTickets=5, pp=12, cosmeticId="emote_pasrah_ritual" })

-- Tier 31-40: Getting Serious
tier(31, { mm=400 },              { mm=800, xp=300 })
tier(32, { xp=450 },              { xp=900, mm=400 })
tier(33, { mm=450 },              { mm=900, pp=4 })
tier(34, { xp=450 },              { xp=900, mm=450 })
tier(35, { mm=800, cosmeticId="accessory_mahkota_arwah" },
         { mm=1600, pp=10, cosmeticId="title_detektif_sejati", gachaTickets=2 })
tier(36, { mm=450 },              { mm=900, xp=300 })
tier(37, { xp=500 },              { xp=1000, mm=450 })
tier(38, { mm=500 },              { mm=1000, pp=4 })
tier(39, { xp=500 },              { xp=1000, mm=500 })
tier(40, { mm=1500, gachaTickets=3, cosmeticId="emote_ketakutan_palsu" },
         { mm=3000, gachaTickets=6, pp=15, cosmeticId="border_abyss_crack" })

-- Tier 41-50: Endgame Push
tier(41, { mm=500 },              { mm=1000, xp=350 })
tier(42, { xp=550 },              { xp=1100, mm=500 })
tier(43, { mm=550 },              { mm=1100, pp=5 })
tier(44, { xp=550 },              { xp=1100, mm=550 })
tier(45, { mm=1000, cosmeticId="title_sang_pasrah" },
         { mm=2000, pp=12, cosmeticId="accessory_jubah_kegelapan", gachaTickets=2 })
tier(46, { mm=550 },              { mm=1100, xp=400 })
tier(47, { xp=600 },              { xp=1200, mm=550 })
tier(48, { mm=600 },              { mm=1200, pp=5 })
tier(49, { xp=600 },              { xp=1200, mm=600 })
tier(50, { mm=2000, gachaTickets=5, cosmeticId="border_sang_detektif" },
         { mm=4000, gachaTickets=8, pp=20, cosmeticId="emote_victory_pasrah" })

-- Tier 51-60: Final Stretch (reward besar untuk motivasi)
tier(51, { mm=700 },              { mm=1400, xp=500 })
tier(52, { xp=700 },              { xp=1400, mm=700 })
tier(53, { mm=800 },              { mm=1600, pp=6 })
tier(54, { xp=800 },              { xp=1600, mm=800 })
tier(55, { mm=1500, cosmeticId="title_penguasa_kegelapan" },
         { mm=3000, pp=15, cosmeticId="accessory_mahkota_teror", gachaTickets=3 })
tier(56, { mm=800 },              { mm=1600, xp=500 })
tier(57, { xp=800 },              { xp=1600, mm=800 })
tier(58, { mm=1000 },             { mm=2000, pp=8 })
tier(59, { xp=1000, gachaTickets=2 },
         { xp=2000, gachaTickets=4, mm=1000, pp=10 })
tier(60, -- GRAND FINALE
    { mm=5000, gachaTickets=5,
      cosmeticId = "title_legenda_pasrahphobia",
      seasonBadgeId = "badge_season_complete_free" },
    { mm=10000, gachaTickets=10, pp=50,
      cosmeticId = "outfit_sang_ahli_season_exclusive",
      seasonBadgeId = "badge_season_complete_premium",
      exclusiveEmoteId = "emote_pasrah_ascend" })

return RoyalPassConfig
```

=======================================================================
## TASK 4 — CONFIG: GachaConfig.lua
=======================================================================

**File:** `src/ReplicatedStorage/Shared/Config/GachaConfig.lua`

```lua
-- GachaConfig.lua
-- PASRAHPHOBIA Gacha System — Pity Model
-- Filosofi: COSMETIC ONLY, tidak ada pay-to-win
-- Pity: guaranteed legendary setelah 50 pull (soft pity mulai 40)
-- Ticket sumber: Royal Pass, Daily Mission, login milestone, MM purchase

local GachaConfig = {}

-- ── PITY SYSTEM ──────────────────────────────────────────────
GachaConfig.SOFT_PITY_START    = 40   -- mulai 40 pull: rate up naik drastis
GachaConfig.HARD_PITY          = 50   -- pull ke-50: guaranteed Legendary
GachaConfig.GUARANTEED_EPIC    = 10   -- setiap 10 pull: guaranteed minimum Epic

-- ── BASE RATES ───────────────────────────────────────────────
GachaConfig.BASE_RATES = {
    LEGENDARY = 0.02,   -- 2% base
    EPIC      = 0.08,   -- 8% base
    RARE      = 0.25,   -- 25% base
    COMMON    = 0.65,   -- 65% base
}

-- Soft pity multiplier (mulai pull 40, rate LEGENDARY naik per pull)
GachaConfig.SOFT_PITY_MULTIPLIER = 0.08  -- +8% per pull setelah pull 40

-- ── TICKET COST ──────────────────────────────────────────────
GachaConfig.SINGLE_PULL_MM     = 1500   -- 1 pull = 1500 MM
GachaConfig.TEN_PULL_MM        = 13500  -- 10 pull = 13500 MM (10% diskon)
GachaConfig.SINGLE_PULL_TICKET = 1      -- 1 ticket = 1 pull
GachaConfig.TEN_PULL_TICKET    = 10

-- ── POOL: COSMETIC ONLY ──────────────────────────────────────
-- Semua item adalah cosmetic, TIDAK ADA stat boost

GachaConfig.POOL = {

    -- ── LEGENDARY (2% base) ──────────────────────────────────
    {
        id       = "gacha_leg_outfit_kuntilanak",
        name     = "Busana Kuntilanak",
        rarity   = "LEGENDARY",
        type     = "outfit",
        desc     = "Kostum eksklusif terinspirasi dari Kuntilanak.",
        season   = 1,
    },
    {
        id       = "gacha_leg_emote_float_spirit",
        name     = "Emote: Mengambang Jiwa",
        rarity   = "LEGENDARY",
        type     = "emote",
        desc     = "Animasi unik: karakter melayang seperti arwah.",
        season   = 1,
    },
    {
        id       = "gacha_leg_title_sang_legenda",
        name     = "Title: Sang Legenda",
        rarity   = "LEGENDARY",
        type     = "title",
        desc     = "Gelar yang hanya dimiliki sedikit orang.",
        season   = 1,
    },
    {
        id       = "gacha_leg_border_genderuwo_aura",
        name     = "Border: Aura Genderuwo",
        rarity   = "LEGENDARY",
        type     = "border",
        desc     = "Bingkai profil dengan efek aura menyeramkan.",
        season   = 1,
    },

    -- ── EPIC (8% base) ────────────────────────────────────────
    {
        id       = "gacha_epic_outfit_pocong_shroud",
        name     = "Jubah Pocong",
        rarity   = "EPIC",
        type     = "outfit",
        season   = 1,
    },
    {
        id       = "gacha_epic_emote_ghost_laugh",
        name     = "Emote: Tawa Hantu",
        rarity   = "EPIC",
        type     = "emote",
        season   = 1,
    },
    {
        id       = "gacha_epic_title_arwah_penasaran",
        name     = "Title: Arwah Penasaran",
        rarity   = "EPIC",
        type     = "title",
        season   = 1,
    },
    {
        id       = "gacha_epic_border_ritual_circle",
        name     = "Border: Lingkaran Ritual",
        rarity   = "EPIC",
        type     = "border",
        season   = 1,
    },
    {
        id       = "gacha_epic_accessory_ghost_lantern",
        name     = "Aksesoris: Lentera Arwah",
        rarity   = "EPIC",
        type     = "accessory",
        season   = 1,
    },

    -- ── RARE (25% base) ──────────────────────────────────────
    {
        id     = "gacha_rare_title_pemberani",
        name   = "Title: Si Pemberani",
        rarity = "RARE", type = "title", season = 1,
    },
    {
        id     = "gacha_rare_border_misty_fog",
        name   = "Border: Kabut Malam",
        rarity = "RARE", type = "border", season = 1,
    },
    {
        id     = "gacha_rare_emote_scared_hop",
        name   = "Emote: Lompat Kaget",
        rarity = "RARE", type = "emote", season = 1,
    },
    {
        id     = "gacha_rare_accessory_ghost_charm",
        name   = "Aksesoris: Jimat Hantu",
        rarity = "RARE", type = "accessory", season = 1,
    },
    {
        id     = "gacha_rare_title_pencari_tanda",
        name   = "Title: Pencari Tanda",
        rarity = "RARE", type = "title", season = 1,
    },

    -- ── COMMON (65% base) ────────────────────────────────────
    {
        id     = "gacha_com_mm_100",
        name   = "100 M-Money",
        rarity = "COMMON", type = "currency",
        mm     = 100, season = 1,
    },
    {
        id     = "gacha_com_mm_200",
        name   = "200 M-Money",
        rarity = "COMMON", type = "currency",
        mm     = 200, season = 1,
    },
    {
        id     = "gacha_com_xp_boost",
        name   = "XP Boost 30 menit",
        rarity = "COMMON", type = "boost",
        boostType = "xp", duration = 1800, season = 1,
    },
    {
        id     = "gacha_com_title_penyelidik",
        name   = "Title: Penyelidik",
        rarity = "COMMON", type = "title", season = 1,
    },
    {
        id     = "gacha_com_border_basic_dark",
        name   = "Border: Gelap Dasar",
        rarity = "COMMON", type = "border", season = 1,
    },
}

-- Lookup by ID
GachaConfig.ByID = {}
for _, item in ipairs(GachaConfig.POOL) do
    GachaConfig.ByID[item.id] = item
end

-- Lookup by rarity
GachaConfig.ByRarity = { LEGENDARY = {}, EPIC = {}, RARE = {}, COMMON = {} }
for _, item in ipairs(GachaConfig.POOL) do
    table.insert(GachaConfig.ByRarity[item.rarity], item)
end

return GachaConfig
```

=======================================================================
## TASK 5 — SERVER: DailyEngagementService.lua
=======================================================================

**File:** `src/ServerScriptService/Server/DailyEngagementSystem/Service.lua`

Cek dulu:
```bash
find src/ServerScriptService/Server/DailyCheckinSystem -name "*.lua" | sort
find src/ServerScriptService/Server/DailyMissionSystem -name "*.lua" | sort
find src/ServerScriptService/Server/RoyalPassSystem    -name "*.lua" | sort
```

Jika sistem lama sudah punya Service.lua → baca dulu sebelum melanjutkan.
Jika sistem lama punya EventBus subscription atau PlayerAdded handler yang
overlap dengan DailyEngagementService → NONAKTIFKAN dulu sebelum menulis kode baru.

```lua
-- DailyEngagementService.lua
-- PASRAHPHOBIA — Orchestrator untuk semua sistem daily engagement
-- Tier: LiveServiceSystem (load setelah EconomySystem dan ProgressionSystem)
-- OWNERSHIP: Satu-satunya owner untuk data.daily.*, data.royalPass.*,
--            data.gacha, data.gachaTickets
-- PENTING: Semua reward harus lewat EconomySystem dan ProgressionSystem
--          yang sudah ada — JANGAN direct mutate data selain field di atas

local DailyEngagementService = {}
DailyEngagementService.__index = DailyEngagementService

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ── LAZY-LOAD CONFIGS (hindari circular require) ───────────────
-- Pola penamaan: get<NamaFileLengkap>() untuk konsistensi
local function getCheckinRewardConfig()
    return require(ReplicatedStorage:WaitForChild("Shared", 10)
        :WaitForChild("Config", 10)
        :WaitForChild("CheckinRewardConfig", 10))
end

local function getDailyMissionConfig()
    return require(ReplicatedStorage:WaitForChild("Shared", 10)
        :WaitForChild("Config", 10)
        :WaitForChild("DailyMissionConfig", 10))
end

local function getRoyalPassConfig()
    return require(ReplicatedStorage:WaitForChild("Shared", 10)
        :WaitForChild("Config", 10)
        :WaitForChild("RoyalPassConfig", 10))
end

local function getGachaConfig()
    return require(ReplicatedStorage:WaitForChild("Shared", 10)
        :WaitForChild("Config", 10)
        :WaitForChild("GachaConfig", 10))
end

-- ── INIT ─────────────────────────────────────────────────────
function DailyEngagementService.new(state, deps)
    local self = setmetatable({}, DailyEngagementService)
    self._state = state
    self._deps  = deps or {}
    return self
end

function DailyEngagementService:Init()
    -- [EXECUTOR: sesuaikan cara resolve deps dengan pola aktual codebase]
    -- Contoh jika pakai Services.Get:
    local Services    = require(script.Parent.Parent.Core.Services)
    self._economy     = Services.Get(self._deps, "EconomySystem")
    self._progression = Services.Get(self._deps, "ProgressionSystem")
    self._data        = Services.Get(self._deps, "DataPersistenceService")
    self._inventory   = Services.Get(self._deps, "InventorySystem")  -- cache di Init
    self._eventBus    = Services.Get(self._deps, "EventBus")

    -- [EXECUTOR: sesuaikan path RemoteBridge dengan pola aktual codebase]
    local remoteBridgePath = script.Parent.Parent.Core.RemoteBridge
    self._remotes = remoteBridgePath and require(remoteBridgePath) or nil

    print("[DailyEngagementService] Initialized")
end

-- ── RESET HARIAN ─────────────────────────────────────────────
function DailyEngagementService:GetTodayDateString()
    return os.date("%Y%m%d")
end

function DailyEngagementService:ResetDailyIfNeeded(player)
    local data = self._data and self._data:GetData(player)
    if not data then return end

    local today = self:GetTodayDateString()
    if not data.daily then data.daily = {} end

    -- Sudah reset hari ini → skip
    if data.daily.lastResetDate == today then return end

    -- Generate misi baru untuk hari ini
    local MissionConfig = getDailyMissionConfig()
    local newMissions = MissionConfig.GetTodaysMissions(today)

    -- Reset progress misi (reward claim state direset, target fresh)
    data.daily.lastResetDate = today
    data.daily.missions = {}
    for i, mission in ipairs(newMissions) do
        data.daily.missions[i] = {
            id          = mission.id,
            title       = mission.title,
            desc        = mission.desc,
            type        = mission.type,
            target      = mission.target,
            xp          = mission.xp,
            mm          = mission.mm,
            pp          = mission.pp or 0,
            icon        = mission.icon,
            progress    = 0,
            claimed     = false,
            isChallenge = mission.isChallenge or false,
        }
    end

    self._data:MarkDirty(player)
    self:_syncToClient(player)
    print(string.format("[DailyEngagement] Reset harian untuk %s (%s)",
        player.Name, today))
end

-- ── CHECK-IN ─────────────────────────────────────────────────
function DailyEngagementService:HandleCheckin(player)
    local data = self._data and self._data:GetData(player)
    if not data then return false, "no_data" end

    local today = self:GetTodayDateString()
    local checkin = data.daily
    if not checkin then data.daily = {} checkin = data.daily end

    -- Sudah check-in hari ini
    if checkin.lastCheckinDate == today then
        return false, "already_checked_in"
    end

    local now = os.time()
    local CheckinConfig = getCheckinRewardConfig()

    -- Hitung streak
    local lastTs     = checkin.lastCheckinTimestamp or 0
    local hoursSince = (now - lastTs) / 3600

    if hoursSince <= 48 then
        -- Masih dalam window streak (toleransi 48 jam)
        checkin.streakCount = (checkin.streakCount or 0) + 1
    else
        -- Streak putus
        checkin.streakCount = 1
    end

    local streakDay = ((checkin.streakCount - 1) % 7) + 1
    local totalDays = (checkin.totalLoginDays or 0) + 1

    checkin.lastCheckinDate      = today
    checkin.lastCheckinTimestamp = now
    checkin.totalLoginDays       = totalDays

    -- Reward streak harian
    local streakReward = CheckinConfig.STREAK_7[streakDay]
    if streakReward then
        self:_grantReward(player, streakReward, "checkin_streak_day"..streakDay)
    end

    -- Cek milestone 30 hari
    local milestone = CheckinConfig.MILESTONE_30[totalDays]
    if milestone then
        self:_grantReward(player, milestone, "checkin_milestone_"..totalDays)
    end

    -- Grant Royal Pass XP dari check-in (baca dari config, JANGAN hardcode)
    self:_grantRoyalPassXP(player, getRoyalPassConfig().XP_SOURCES.CHECKIN)

    -- XP Multiplier berdasarkan streak
    self:_updateStreakMultiplier(player, checkin.streakCount)

    self._data:MarkDirty(player)
    self:_syncToClient(player)

    return true, {
        streakDay   = streakDay,
        streakCount = checkin.streakCount,
        totalDays   = totalDays,
        reward      = streakReward,
        milestone   = milestone,
    }
end

-- ── MISSION PROGRESS ─────────────────────────────────────────
function DailyEngagementService:UpdateMissionProgress(player, eventType, amount, metadata)
    local data = self._data and self._data:GetData(player)
    if not data or not data.daily or not data.daily.missions then return end

    local updated = false
    for _, mission in ipairs(data.daily.missions) do
        if mission.claimed then continue end
        if mission.type ~= eventType then continue end

        -- Cek kondisi khusus
        if mission.mapId and metadata and metadata.mapId ~= mission.mapId then
            continue
        end
        if mission.threshold and metadata
            and (metadata.finalSanity or 0) < mission.threshold then
            continue
        end
        if mission.minDifficulty and metadata
            and not self:_meetsMinDifficulty(metadata.difficulty, mission.minDifficulty) then
            continue
        end

        -- Update progress
        local increment = amount or 1
        if mission.singleMatch and metadata and not metadata.sameMatch then
            -- Reset jika beda match
            mission.progress = 0
        end

        mission.progress = math.min(
            mission.progress + increment,
            mission.target
        )

        if mission.progress >= mission.target then
            -- Mission complete — notify, player harus klik claim di UI
            if self._eventBus then
                self._eventBus:Publish("DailyMissionComplete", {
                    player  = player,
                    mission = mission,
                })
            end
        end

        updated = true
    end

    if updated then
        self._data:MarkDirty(player)
        self:_syncToClient(player)
    end
end

-- Helper: cek apakah difficulty payload memenuhi minimum difficulty misi
function DailyEngagementService:_meetsMinDifficulty(actual, minimum)
    local rank = { Easy = 1, Normal = 2, Hard = 3, Nightmare = 4 }
    return (rank[actual] or 0) >= (rank[minimum] or 0)
end

-- ── CLAIM MISSION REWARD ─────────────────────────────────────
function DailyEngagementService:ClaimMissionReward(player, missionId)
    local data = self._data and self._data:GetData(player)
    if not data or not data.daily then return false, "no_data" end

    local RoyalConfig = getRoyalPassConfig()

    for _, mission in ipairs(data.daily.missions or {}) do
        if mission.id == missionId then
            if mission.claimed then
                return false, "already_claimed"
            end
            if mission.progress < mission.target then
                return false, "not_complete"
            end

            mission.claimed = true

            -- Grant reward
            self:_grantReward(player, {
                xp = mission.xp,
                mm = mission.mm,
                pp = mission.pp or 0,
            }, "mission_claim_"..missionId)

            -- Grant Royal Pass XP — baca dari config, jangan hardcode
            local royalXp = mission.isChallenge
                and RoyalConfig.XP_SOURCES.CHALLENGE_DONE
                or  RoyalConfig.XP_SOURCES.DAILY_MISSION_DONE
            self:_grantRoyalPassXP(player, royalXp)

            -- Cek bonus ALL_3_TASKS: jika semua 3 non-challenge sudah claimed
            local regularClaimed = 0
            for _, m in ipairs(data.daily.missions) do
                if not m.isChallenge and m.claimed then
                    regularClaimed = regularClaimed + 1
                end
            end
            if regularClaimed == 3 then
                self:_grantRoyalPassXP(player, RoyalConfig.XP_SOURCES.ALL_3_TASKS_BONUS)
            end

            self._data:MarkDirty(player)
            self:_syncToClient(player)
            return true, mission
        end
    end

    return false, "mission_not_found"
end

-- ── ROYAL PASS PROGRESS ──────────────────────────────────────
function DailyEngagementService:_grantRoyalPassXP(player, amount)
    local data = self._data and self._data:GetData(player)
    if not data then return end

    if not data.royalPass then
        data.royalPass = { owned = false, xp = 0, tier = 0, season = 1 }
    end

    local RoyalConfig = getRoyalPassConfig()
    data.royalPass.xp = (data.royalPass.xp or 0) + amount

    -- Cek tier up
    while data.royalPass.tier < RoyalConfig.TOTAL_TIERS do
        if data.royalPass.xp >= RoyalConfig.XP_PER_TIER then
            data.royalPass.xp   = data.royalPass.xp - RoyalConfig.XP_PER_TIER
            data.royalPass.tier = data.royalPass.tier + 1
            self:_claimTierReward(player, data.royalPass.tier, data.royalPass.owned)
        else
            break
        end
    end

    self._data:MarkDirty(player)
end

function DailyEngagementService:_claimTierReward(player, tier, hasPremium)
    local RoyalConfig = getRoyalPassConfig()
    local tierData = RoyalConfig.TIERS[tier]
    if not tierData then return end

    -- Grant free reward
    if tierData.free then
        self:_grantReward(player, tierData.free, "royalpass_free_tier"..tier)
    end

    -- Grant premium reward jika punya pass
    if hasPremium and tierData.premium then
        self:_grantReward(player, tierData.premium, "royalpass_prem_tier"..tier)
    end

    if self._eventBus then
        self._eventBus:Publish("RoyalPassTierUp", {
            player     = player,
            tier       = tier,
            hasPremium = hasPremium,
        })
    end
end

-- ── GACHA ─────────────────────────────────────────────────────
function DailyEngagementService:PullGacha(player, pullCount)
    pullCount = pullCount or 1
    assert(pullCount == 1 or pullCount == 10, "pullCount harus 1 atau 10")

    local data = self._data and self._data:GetData(player)
    if not data then return false, "no_data" end

    -- Gunakan lazy loader (konsisten dengan config lainnya)
    local GachaCfg = getGachaConfig()

    -- Inisialisasi gacha state jika belum ada
    if not data.gacha then
        data.gacha = { pityCount = 0, epicPityCount = 0, history = {} }
    end

    local results = {}
    for i = 1, pullCount do
        local item = self:_doPull(data.gacha, GachaCfg)
        table.insert(results, item)
        self:_grantGachaItem(player, item)
    end

    self._data:MarkDirty(player)

    -- Notify client
    if self._remotes then
        self._remotes:FireClient(player, "GachaResult", results)
    end

    return true, results
end

function DailyEngagementService:_doPull(gachaState, GachaCfg)
    gachaState.pityCount     = (gachaState.pityCount or 0) + 1
    gachaState.epicPityCount = (gachaState.epicPityCount or 0) + 1

    local roll = math.random()
    local rarity

    -- Hard pity: guaranteed legendary
    if gachaState.pityCount >= GachaCfg.HARD_PITY then
        rarity = "LEGENDARY"
        gachaState.pityCount = 0

    -- Soft pity: rate naik drastis
    elseif gachaState.pityCount >= GachaCfg.SOFT_PITY_START then
        local pullsIntoSoftPity = gachaState.pityCount - GachaCfg.SOFT_PITY_START
        local boostedRate = GachaCfg.BASE_RATES.LEGENDARY
            + (pullsIntoSoftPity * GachaCfg.SOFT_PITY_MULTIPLIER)
        if roll < boostedRate then
            rarity = "LEGENDARY"
            gachaState.pityCount = 0
        end

    -- Epic pity: guaranteed epic setiap 10 pull
    elseif gachaState.epicPityCount >= GachaCfg.GUARANTEED_EPIC then
        rarity = "EPIC"
        gachaState.epicPityCount = 0
    end

    -- Normal roll jika belum ditentukan
    if not rarity then
        local rates = GachaCfg.BASE_RATES
        if roll < rates.LEGENDARY then
            rarity = "LEGENDARY"
            gachaState.pityCount = 0
        elseif roll < rates.LEGENDARY + rates.EPIC then
            rarity = "EPIC"
            gachaState.epicPityCount = 0
        elseif roll < rates.LEGENDARY + rates.EPIC + rates.RARE then
            rarity = "RARE"
        else
            rarity = "COMMON"
        end
    end

    -- Pilih item random dari rarity
    local pool = GachaCfg.ByRarity[rarity]
    local item = pool[math.random(#pool)]

    -- Catat history (max 50)
    table.insert(gachaState.history, {
        id     = item.id,
        rarity = rarity,
        t      = os.time(),
    })
    if #gachaState.history > 50 then
        table.remove(gachaState.history, 1)
    end

    return item
end

-- ── GRANT REWARD (delegate ke sistem yang sudah ada) ──────────
function DailyEngagementService:_grantReward(player, reward, reason)
    if not reward then return end

    -- MM via EconomySystem
    if reward.mm and reward.mm > 0 and self._economy then
        local econService = self._economy.Service or self._economy
        if type(econService.Grant) == "function" then
            econService:Grant(player, "MM", reward.mm, reason)
        end
    end

    -- PP via EconomySystem
    if reward.pp and reward.pp > 0 and self._economy then
        local econService = self._economy.Service or self._economy
        if type(econService.Grant) == "function" then
            econService:Grant(player, "PP", reward.pp, reason)
        end
    end

    -- XP via ProgressionSystem
    if reward.xp and reward.xp > 0 and self._progression then
        local progService = self._progression.Service or self._progression
        if type(progService.GrantXP) == "function" then
            progService:GrantXP(player, reward.xp, reason)
        end
    end

    -- Cosmetic via InventorySystem (cached dari Init)
    if reward.cosmeticId and self._inventory then
        local invService = self._inventory.Service or self._inventory
        if type(invService.GrantItem) == "function" then
            invService:GrantItem(player, reward.cosmeticId)
        end
    end

    -- Gacha tickets (simpan ke player data — field owned DailyEngagementService)
    if reward.gachaTickets and reward.gachaTickets > 0 then
        local data = self._data:GetData(player)
        if data then
            data.gachaTickets = (data.gachaTickets or 0) + reward.gachaTickets
            self._data:MarkDirty(player)
        end
    end
end

function DailyEngagementService:_grantGachaItem(player, item)
    if item.type == "currency" and item.mm then
        self:_grantReward(player, { mm = item.mm }, "gacha_"..item.id)
    elseif item.type ~= "currency" then
        self:_grantReward(player, { cosmeticId = item.id }, "gacha_"..item.id)
    end
end

function DailyEngagementService:_updateStreakMultiplier(player, streakCount)
    local data = self._data and self._data:GetData(player)
    if not data then return end
    local CheckinConfig = getCheckinRewardConfig()

    local multiplier = 1.0
    for threshold, mult in pairs(CheckinConfig.STREAK_MULTIPLIER) do
        if streakCount >= threshold then
            multiplier = math.max(multiplier, mult)
        end
    end

    -- Simpan ke attribute player untuk dibaca ProgressionSystem
    player:SetAttribute("PasrahXPMultiplier", multiplier)
end

-- ── SYNC KE CLIENT ────────────────────────────────────────────
function DailyEngagementService:_syncToClient(player)
    local data = self._data and self._data:GetData(player)
    if not data then return end

    if self._remotes then
        self._remotes:FireClient(player, "DailyEngagementSync", {
            missions     = data.daily and data.daily.missions or {},
            checkin      = {
                streakCount = data.daily and data.daily.streakCount or 0,
                totalDays   = data.daily and data.daily.totalLoginDays or 0,
                lastDate    = data.daily and data.daily.lastCheckinDate or "",
            },
            royalPass    = data.royalPass,
            gachaTickets = data.gachaTickets or 0,
        })
    end
end

-- ── START ─────────────────────────────────────────────────────
function DailyEngagementService:Start()
    local Players = game:GetService("Players")

    Players.PlayerAdded:Connect(function(player)
        task.wait(2) -- beri waktu data load
        self:ResetDailyIfNeeded(player)
        self:_syncToClient(player)
    end)

    if not self._eventBus then return end

    -- ── MATCH EVENTS ─────────────────────────────────────────
    -- [EXECUTOR: verifikasi nama event aktual dari output Pre-flight 5c]
    self._eventBus:Subscribe("MatchEnded", function(payload)
        if not payload or not payload.player then return end
        local p = payload.player

        -- MATCH_COMPLETE
        if payload.completed then
            self:UpdateMissionProgress(p, "MATCH_COMPLETE", 1, payload)
            -- Royal Pass XP dari selesaikan match (baca dari config)
            self:_grantRoyalPassXP(p, getRoyalPassConfig().XP_SOURCES.MATCH_COMPLETE)
        end

        -- GHOST_IDENTIFIED
        if payload.ghostIdentified then
            self:UpdateMissionProgress(p, "GHOST_IDENTIFIED", 1, payload)
            self:_grantRoyalPassXP(p, getRoyalPassConfig().XP_SOURCES.GHOST_IDENTIFIED)
        end

        -- MATCH_NO_DEATH
        if payload.completed and not payload.died then
            self:UpdateMissionProgress(p, "MATCH_NO_DEATH", 1, payload)
        end

        -- FINISH_HIGH_SANITY
        if payload.finalSanity then
            self:UpdateMissionProgress(p, "FINISH_HIGH_SANITY", 1, payload)
        end

        -- MATCH_ON_MAP (mapId wajib ada di payload)
        if payload.completed and payload.mapId then
            self:UpdateMissionProgress(p, "MATCH_ON_MAP", 1, payload)
        end

        -- MATCH_DIFFICULTY
        if payload.completed and payload.difficulty then
            self:UpdateMissionProgress(p, "MATCH_DIFFICULTY", 1, payload)
        end

        -- PERFECT_MATCH (semua player selamat + ghost identified)
        if payload.completed and payload.ghostIdentified and payload.allSurvived then
            self:UpdateMissionProgress(p, "PERFECT_MATCH", 1, payload)
        end

        -- ALL_EVIDENCE_IN_MATCH
        if payload.allEvidenceCollected then
            self:UpdateMissionProgress(p, "ALL_EVIDENCE_IN_MATCH", 1, payload)
        end

        -- SOLO_MATCH_COMPLETE
        if payload.completed and payload.isSolo then
            self:UpdateMissionProgress(p, "SOLO_MATCH_COMPLETE", 1, payload)
        end

        -- MATCH_WITH_PARTY
        if payload.completed and payload.partySize and payload.partySize > 0 then
            self:UpdateMissionProgress(p, "MATCH_WITH_PARTY", 1, payload)
        end

        -- RANKED_MATCH + Royal Pass XP dari ranked win
        if payload.completed and payload.isRanked then
            self:UpdateMissionProgress(p, "RANKED_MATCH", 1, payload)
            if payload.isWin then
                self:_grantRoyalPassXP(p, getRoyalPassConfig().XP_SOURCES.RANKED_WIN)
            end
        end

    end, "DailyEngagement_MatchEnded")   -- tag = nama event + prefix

    -- ── WIN STREAK ───────────────────────────────────────────
    -- [EXECUTOR: jika game punya event khusus win streak, gunakan itu]
    -- Jika tidak ada, WIN_STREAK bisa di-track dari consecutive MatchEnded wins
    -- di sisi DailyEngagementService sendiri (tidak di sini — tambahkan _winStreakTracker)

    -- ── HUNT / SURVIVAL ──────────────────────────────────────
    self._eventBus:Subscribe("HuntSurvived", function(payload)
        if payload and payload.player then
            self:UpdateMissionProgress(payload.player, "SURVIVE_HUNT", 1, payload)
        end
    end, "DailyEngagement_HuntSurvived")

    -- ── EVIDENCE ─────────────────────────────────────────────
    self._eventBus:Subscribe("EvidenceCollected", function(payload)
        if payload and payload.player then
            self:UpdateMissionProgress(payload.player, "EVIDENCE_COLLECTED", 1, payload)
        end
    end, "DailyEngagement_EvidenceCollected")

    -- ── HIDE ─────────────────────────────────────────────────
    self._eventBus:Subscribe("HideSuccess", function(payload)
        if payload and payload.player then
            self:UpdateMissionProgress(payload.player, "HIDE_SUCCESS", 1, payload)
        end
    end, "DailyEngagement_HideSuccess")

    -- ── TOOL ─────────────────────────────────────────────────
    self._eventBus:Subscribe("ToolUsed", function(payload)
        if payload and payload.player then
            self:UpdateMissionProgress(payload.player, "TOOL_USED", 1, payload)
            -- TOOLS_VARIETY: di-track via metadata.toolId unik per match
            if payload.toolId then
                self:UpdateMissionProgress(payload.player, "TOOLS_VARIETY", 1, payload)
            end
        end
    end, "DailyEngagement_ToolUsed")

    -- ── HOST MATCH ───────────────────────────────────────────
    -- [EXECUTOR: verifikasi nama event HostMatch dari Pre-flight 5c]
    self._eventBus:Subscribe("HostMatch", function(payload)
        if payload and payload.player then
            self:UpdateMissionProgress(payload.player, "HOST_MATCH", 1, payload)
        end
    end, "DailyEngagement_HostMatch")

    print("[DailyEngagementService] Started")
end

function DailyEngagementService:Stop() end
function DailyEngagementService:Shutdown() self:Stop() end

return DailyEngagementService
```

=======================================================================
## TASK 6 — REGISTER KE SYSTEMREGISTRY
=======================================================================

**File:** `src/ServerScriptService/Server/Core/SystemRegistry.lua`
**Action:** EXTEND — tambah DailyEngagementSystem ke load list

```bash
# Cek bagaimana LiveServiceSystems didefinisikan
grep -n "DailyCheckinSystem\|DailyMissionSystem\|RoyalPassSystem\|LiveService" \
  src/ServerScriptService/Server/Core/SystemRegistry.lua | head -20
```

Tambahkan `DailyEngagementSystem = true` ke `SYSTEMS_BY_GROUP.LiveServiceSystems`
jika belum ada. Pastikan load order SETELAH EconomySystem, ProgressionSystem,
InventorySystem.

=======================================================================
## TASK 7 — REMOTE EVENTS
=======================================================================

Buat file-file berikut di `src/ReplicatedStorage/RemoteEvents/`:

```bash
# Cek format file RemoteEvent yang sudah ada
cat src/ReplicatedStorage/RemoteEvents/ShowResults.model.json
```

Buat dengan format yang sama:
- `DailyEngagementSync.model.json`
- `DailyCheckinRequest.model.json`
- `DailyMissionClaimRequest.model.json`
- `GachaPullRequest.model.json`
- `GachaResult.model.json`
- `RoyalPassTierUp.model.json`

=======================================================================
## TASK 8 — VERIFIKASI
=======================================================================

```bash
echo "=== VERIFIKASI DAILY ENGAGEMENT ==="

# 1. Semua config ada
find src/ReplicatedStorage/Shared/Config -name "*.lua" | sort
# Expected: DailyMissionConfig.lua, CheckinRewardConfig.lua,
#           RoyalPassConfig.lua, GachaConfig.lua

# 2. DailyEngagementSystem terdaftar
grep "DailyEngagementSystem" \
  src/ServerScriptService/Server/Core/SystemRegistry.lua

# 3. Remote events ada
ls src/ReplicatedStorage/RemoteEvents/ | grep -i "daily\|gacha\|royal"

# 4. Tidak ada wait() deprecated
grep -rn "\bwait(" \
  src/ServerScriptService/Server/DailyEngagementSystem/ \
  --include="*.lua" | grep -v "task.wait" | grep -v "--"
# Expected: KOSONG

# 5. Tidak ada direct DataStore call
grep -rn "DataStoreService" \
  src/ServerScriptService/Server/DailyEngagementSystem/ \
  --include="*.lua"
# Expected: KOSONG — semua lewat DataPersistenceService

# 6. Tidak ada hardcode nilai XP Royal Pass (harus lewat getRoyalPassConfig())
grep -n "and 350 or 200\|and 200 or 350\|royalXp = [0-9]" \
  src/ServerScriptService/Server/DailyEngagementSystem/Service.lua
# Expected: KOSONG

# 7. OWNERSHIP CHECK: tidak ada sistem lama yang masih nulis ke data.daily.*
#    Jika ada → sudah di-disable di Pre-flight (dan terdokumentasi di log)
grep -rn "data\.daily\|data\.royalPass\|data\.gacha" \
  src/ServerScriptService/Server/DailyCheckinSystem/ \
  src/ServerScriptService/Server/DailyMissionSystem/ \
  src/ServerScriptService/Server/RoyalPassSystem/ \
  --include="*.lua" 2>/dev/null | grep -v "^\s*--"
# Expected: KOSONG atau hanya read (tidak ada assignment)

echo "=== VERIFIKASI SELESAI ==="
```

=======================================================================
## WAJIB DI AKHIR: APPEND LOG
=======================================================================

```bash
mkdir -p LOGS

# PENTING: gunakan heredoc tanpa quote ('EOF' → EOF)
# agar $(date) dan $(git ...) dievaluasi saat dijalankan
cat >> LOGS/IMPLEMENTATION_LOG.md << EOF

---
## DAILY ENGAGEMENT SYSTEM IMPLEMENTATION
**Tanggal:** $(date '+%Y-%m-%d %H:%M')
**Branch:** $(git branch --show-current)

### Task Status:
- [x/o] TASK 1 — DailyMissionConfig.lua
- [x/o] TASK 2 — CheckinRewardConfig.lua
- [x/o] TASK 3 — RoyalPassConfig.lua (60 tier, 60 hari)
- [x/o] TASK 4 — GachaConfig.lua (pity 50, soft pity 40)
- [x/o] TASK 5 — DailyEngagementService.lua
- [x/o] TASK 6 — SystemRegistry extended
- [x/o] TASK 7 — Remote Events dibuat
- [x/o] TASK 8 — Verifikasi: PASS / FAIL

### Ownership Audit (Pre-flight hasil):
- Sistem lama yang dinonaktifkan (EventBus/PlayerAdded): [tulis di sini]
- Field data.daily.* sebelumnya ditulis oleh: [tulis di sini]
- Field data.royalPass.* sebelumnya ditulis oleh: [tulis di sini]

### Konfirmasi Integrasi:
- Reward lewat EconomySystem existing: [YES/NO]
- XP lewat ProgressionSystem existing: [YES/NO]
- Tidak ada DataStore direct call: [YES/NO]
- EventBus subscription terpasang: [YES/NO]
- Tidak ada hardcode nilai config: [YES/NO]

### Issues:
- [tulis di sini]

EOF

git add -A && git commit -m "feat: Daily Engagement System — DailyMission, Checkin, RoyalPass 60-tier, Gacha pity"
```

=======================================================================
EXECUTOR: JANGAN SENTUH EconomySystem, ProgressionSystem,
DataPersistenceService, atau EventBus yang sudah berjalan.
Semua reward HARUS delegate ke sistem yang ada.
Baca file existing SEBELUM menulis kode.
Nonaktifkan jalur lama SEBELUM mengaktifkan jalur baru.
Jangan berhenti sebelum Task 8 verifikasi PASS.
=======================================================================

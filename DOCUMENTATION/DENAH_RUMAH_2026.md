# Denah Rumah — PasrahPhobia

Tanggal: 2026-06-15
Sumber: Studio Luau execution (Edit Mode)

---

## DENAH RUMAH (HauntedHouse) — Floor Plan

```
Z = -454 (belakang / back) ─────────────────────────────── Z = -526 (depan / front)
X=149                                                            X=239
┌──────────────────────────────────────────────────────────────────────────┐
│  FLOOR 1 (Y = -1)                                                  │
│                                                                     │
│  [Garage]──[BackPatio]──[LivingRoom]──[Bathroom2]──[BonusRoom]      │
│     │             │            │              │            │         │
│     │             │      [Door_LR]      [Door_Bath2]  [Door_Bonus]  │
│     │             │            │              │            │         │
│  [Door_Garage]    │       [Door_BP]    [Door_Bath4]  [Door_Bed3]    │
│                    │            │              │            │         │
│  [LaundryRoom]──[LinenCloset]──[Bedroom2]──[ClosetB]──[Bathroom4]  │
│     │               │             │             │            │         │
│  [Door_Laundry] [Door_Linen] [Door_Bed2]   [Door_ClosetB] [Door_B4] │
│     │               │             │             │            │         │
│  [Pantry]──[Bathroom1]──[Bedroom1]──[ClosetA]──[Bathroom3]          │
│     │             │             │             │            │           │
│  [Door_Pantry] [Door_Bath1] [Door_Bed1] [Door_ClosetA] [Door_Bath3] │
│                    │             │             │                       │
│               [DiningRoom]──────────[Door_Dining]                    │
│                    │                                                  │
│              [Door_FrontEntry] ←────────────────┐                  │
│               X=195, Y=-2, Z=-526                │                  │
│                                                  │                  │
│  FLOOR 2 (Y = 11)                                 │                  │
│  [Bedroom3]──[Bathroom3]──[ClosetA_F2]──[Bedroom1_F2]               │
│                                                                     │
│  ────────────────────────────────────────────────────────────────    │
│  PREPARATION STAGING AREA (Y = -3 s/d -4)                          │
│                                                                     │
│  [Spawn_1] X=223,Z=-573  [Spawn_2] X=223,Z=-574                    │
│  [Spawn_3] X=219,Z=-575  [Spawn_4] X=216,Z=-574                     │
│                                                                     │
│       [ToolTable] X=218, Y=-3, Z=-562                               │
│       (Top: 11x0x3 studs)                                          │
│                                                                     │
│  [BreachTarget_1] X=212, Z=-561  ← pilih tool di sini              │
│  [BreachTarget_2] X=214, Z=-563                                     │
│  [BreachTarget_3] X=216, Z=-562                                     │
│  [BreachTarget_4] X=218, Z=-561                                     │
│                                                                     │
│  [GateBlocker] X=195, Y=-1, Z=-535 ← di DEPAN Door_FrontEntry!       │
│  [RoadsideSign]                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Preparation Staging Area — Detail

**Tool Stations (di PreparationStagingRuntime):**
| Station | Tool | Posisi |
|---------|------|--------|
| ToolStation_FLASHLIGHT | Flashlight | X=220, Y=-2, Z=-561 |
| ToolStation_EMF | JejakEnergi | X=220, Y=-2, Z=-561 |
| ToolStation_THERMO | SuhuMembeku | X=216, Y=-2, Z=-561 |
| ToolStation_UV | BolaArwah | X=218, Y=-2, Z=-561 |
| ToolStation_BOX | KotakArwah | X=220, Y=-2, Z=-563 |
| ToolStation_WRITING | BukuTerkutuk | X=218, Y=-2, Z=-563 |
| ToolStation_SENSOR | GerakanGaib | X=216, Y=-2, Z=-563 |
| ToolStation_GARAM | Garam | (dari PreparationToolsTable) |
| ToolStation_SALIB | Salib | (dari PreparationToolsTable) |
| ToolStation_DUPA | Dupa | (dari PreparationToolsTable) |
| ToolStation_PIL | PilSanity | (dari PreparationToolsTable) |

**PreparationToolsTable (PreparationToolsTable model):**
- Top: X=218, Y=-3, Z=-562 (11×0×3 studs)
- Legs: X=213/223, Y=-4, Z=-560/-563

**Spawn Points:**
- PreparationSpawn_1: X=223, Y=-4, Z=-573
- PreparationSpawn_2: X=223, Y=-3, Z=-574
- PreparationSpawn_3: X=219, Y=-3, Z=-575
- PreparationSpawn_4: X=216, Y=-3, Z=-574

**Gate Blocker:**
- PreparationToolGateBlocker: X=195, Y=-1, Z=-535 (14×6×1 studs)
- Posisi: langsung di depan Door_FrontEntry (X=195, Z=-526)
- Ini adalah "exit preparation" yang membuka pintu depan dan teleport player ke InvestigationPhase

---

## Bug yang Ditemukan

### 1. Gate Blocker di Depan Front Door
`PreparationToolGateBlocker` ada di X=195, Z=-535 — langsung di depan `Door_FrontEntry` (X=195, Z=-526).
Ini membuat player tidak bisa melihat/mendekati front door dengan jelas saat preparation.
**Konsekuensi:** Prompt pintu depan (E key) mungkin ter-trigger dari area preparation.

### 2. Tool Table Posisi
`PreparationToolsTable` ada di X=218, Y=-3, Z=-562 — antara spawn points (Z=-573~-575) dan gate blocker (Z=-535).
Ini sudah relatif benar (di antara spawn dan gate), tapi perlu dipindahkan agar lebih dekat dengan area breach targets (Z=-561~-565).

### 3. Roblox Default Inventory
Tidak ada kode yang menonaktifkan `StarterPlayer.CharacterSpawnDirection` atau `StarterGear`.
Roblox default inventory mungkin aktif dan menyebabkan tool muncul di backpack player.

### 4. Tool UI Loads Semua Tools
Dari analisis kode, `getLocalFieldKitLoadoutToolTypes()` mengembalikan SEMUA tools dari `FIELD_KIT_TOOL_ORDER` jika `PasrahLoadoutToolCount == 0` (PreparationPhase belum dimulai).
Ini menyebabkan semua tool terlihat di UI sebelum player memilih tool.

### 5. Flashlight Bug
- Server-side flashlight handle (`FlashlightHandle`) di-spawn ke character dengan `Anchored = true` → seharusnya `Anchored = false`
- Flashlight toggle (F key) tidak di-blok saat door interaction (E key) aktif karena `gameProcessed = false` untuk ProximityPrompt
- `MapInteractionFallback.client.lua` E key handler tidak guard terhadap flashlight toggle

### 6. Door Exit Preparation Teleport
`Door_FrontEntry` memiliki attribute `PasrahPreparationAdvanceDoor = true`.
Saat player membuka pintu ini saat PreparationPhase, `requestAdvancePhase("InvestigationPhase")` dipanggil.
**Masalah:** Jika player approaching dari luar rumah (Z>-526), membuka pintu akan trigger teleport ke investigation — ini sudah benar sebenarnya.
Tapi perlu dicek apakah proximity prompt terlihat dari luar.

---

## Koordinat Penting (Ringkasan)

| Objek | X | Y | Z |
|-------|---|---|---|
| Door_FrontEntry | 195 | -2 | -526 |
| GateBlocker | 195 | -1 | -535 |
| ToolTable Top | 218 | -3 | -562 |
| BreachTarget_1 | 212 | -2 | -561 |
| Spawn_1 | 223 | -4 | -573 |
| Garage Door | 149 | -1 | -454 |
| BackPatio Door | 178 | -2 | -461 |
| LivingRoom Door | 215 | -1 | -481 |
| DiningRoom Door | 219 | -1 | -513 |
| Bedroom1 Door | 189 | 11 | -500 |

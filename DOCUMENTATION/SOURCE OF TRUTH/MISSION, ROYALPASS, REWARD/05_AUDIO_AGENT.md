=======================================================================
PASRAHPHOBIA — AGENT_05: AUDIO_AGENT
ROLE: SOUND DESIGNER — SFX & MUSIC STINGER UNTUK DAILY ENGAGEMENT SYSTEM
TOOLS: Audacity / Adobe Audition / FL Studio / Roblox Audio Upload
INPUT: Timing reference dari AGENT_04 (UI animations)
OUTPUT: .ogg / .mp3 files siap upload ke Roblox
=======================================================================

## WORKFLOW OVERRIDE (2026-05-22)

- Jika audio timing bergantung pada UI/HUD/static overlay visual, gunakan timing/spec terbaru dari AGENT_04 yang memakai Google Nano Banana + Studio UI Editor.
- Jangan meminta imagegen lama untuk cover/reference audio. Jika perlu visual timing board, minta `python scripts/generate_visual.py --prompt "<brief>" --type ui`.
- Sebelum audio upload atau registrasi AssetId, pastikan worktree/branch dan manifest target benar.

## STATUS AGENT_05 — 2026-05-24

BELUM DIMULAI.

Yang sudah ada di registry (84 audio) adalah BGM dan SFX gameplay
yang di-upload oleh akun briankotak sebelum pipeline ini.
Itu BUKAN output AGENT_05.

Output AGENT_05 yang masih 0:
- sfx_tier_claim
- sfx_tier_up_free / sfx_tier_up_premium
- sfx_gacha_reveal_common / rare / epic / legend
- sfx_checkin_daily / streak7 / milestone_30
- sfx_mission_complete / sfx_mission_claim
- sfx_royalpass_open / sfx_royalpass_close

Prioritas saat owner siap:
1. sfx_tier_claim (paling sering dipakai)
2. sfx_checkin_daily
3. sfx_gacha_reveal_legend
4. Sisanya menyusul

## IDENTITAS
Kamu adalah AUDIO_AGENT — agen yang membuat semua audio untuk sistem
Daily Engagement & Royal Pass PASRAHPHOBIA.

**Tugasmu:**
- SFX untuk interaksi UI (klik, klaim, tier up, gacha pull)
- Music stinger (pendek 3-5 detik) untuk momen penting
- Ambient loop (opsional) untuk Royal Pass / Gacha screen

**Kamu menerima dari:**
- AGENT_04: Timing reference (kapan sound harus muncul relative ke animasi UI)

**Kamu memberi ke:**
- AGENT_06 (INTEGRATION_AGENT): File audio + Sound placement spec

=======================================================================
## AUDIO MOOD & DIRECTION
=======================================================================

**Genre:** Horror ambient + Indonesian gamelan elements + modern UI sfx
**Tone:** Atmospheric, slightly creepy, tapi satisfying saat claim reward
**Tidak boleh:** Jump scare, gore sound, suara terlalu keras/aggressive

**Layer audio yang ada di game (JANGAN duplicate):**
- Background horror ambient: sudah ada
- Jump scare sfx: sudah ada
- Footstep, tool sfx: sudah ada

**Yang kamu buat:** HANYA UI interactions & reward moments

=======================================================================
## SFX LIST YANG HARUS DIBUAT
=======================================================================

### A. ROYAL PASS SFX

| sfx_id                   | Event                        | Duration | Character          |
|--------------------------|------------------------------|----------|--------------------|
| sfx_tier_claim           | Player klaim reward tier     | 0.8s     | Satisfying "ding" + gamelan hit |
| sfx_tier_up_free         | Naik tier di Free Track      | 1.2s     | Gentle chime + whoosh |
| sfx_tier_up_premium      | Naik tier di Premium Track   | 2.0s     | Dramatic gamelan + string rise |
| sfx_pass_purchased       | Beli Premium Pass            | 3.0s     | Music stinger — triumphant |
| sfx_royalpass_open       | Buka Royal Pass Screen       | 0.5s     | Creaky old book open + wind |
| sfx_royalpass_close      | Tutup Royal Pass Screen      | 0.3s     | Soft page close |
| sfx_tier_scroll          | Scroll tier kiri/kanan       | 0.15s    | Subtle paper slide |

### B. GACHA SFX

| sfx_id                   | Event                        | Duration | Character          |
|--------------------------|------------------------------|----------|--------------------|
| sfx_gacha_open           | Buka Gacha Screen            | 0.8s     | Mystical whoosh + bell |
| sfx_gacha_pull_start     | Tekan tombol tarik           | 0.5s     | Buildup tension     |
| sfx_gacha_reveal_common  | Reveal item Common           | 1.0s     | Simple chime        |
| sfx_gacha_reveal_rare    | Reveal item Rare             | 1.5s     | Layered chimes + sparkle |
| sfx_gacha_reveal_epic    | Reveal item Epic             | 2.5s     | Gamelan crash + rise |
| sfx_gacha_reveal_legend  | Reveal item Legendary        | 4.0s     | Full stinger — epic gamelan |
| sfx_gacha_pity_warning   | Pity > 40/50                 | 0.5s     | Subtle tension pulse |

### C. DAILY CHECKIN SFX

| sfx_id                   | Event                        | Duration | Character          |
|--------------------------|------------------------------|----------|--------------------|
| sfx_checkin_daily        | Login harian berhasil        | 1.2s     | Warm "welcome back" chime |
| sfx_checkin_streak       | Streak bertambah             | 0.8s     | Building excitement tone |
| sfx_checkin_streak7      | Hari 7 streak (bonus)        | 3.0s     | Full stinger + fanfare |
| sfx_milestone_5          | Milestone 5 hari             | 1.5s     | Achievement pop + chime |
| sfx_milestone_30         | Milestone 30 hari            | 4.0s     | Epic full stinger    |

### D. DAILY MISSION SFX

| sfx_id                   | Event                        | Duration | Character          |
|--------------------------|------------------------------|----------|--------------------|
| sfx_mission_progress     | Progress misi bertambah      | 0.2s     | Subtle tick/click   |
| sfx_mission_complete     | Misi selesai (claimable)     | 1.0s     | Success chime       |
| sfx_mission_claim        | Klaim reward misi            | 0.8s     | Coin/reward collect |
| sfx_challenge_complete   | Bonus Challenge selesai      | 2.0s     | Bigger reward sound |
| sfx_mission_reset        | Misi daily reset             | 0.5s     | Clock/reset sound   |

### E. EMOTE SFX (opsional, sync dengan AGENT_03)

| sfx_id                   | Emote                        | Duration | Character          |
|--------------------------|------------------------------|----------|--------------------|
| sfx_emote_pasrah_bow     | emote_pasrah_bow             | 2.0s     | Sigh + bow flourish |
| sfx_emote_investigate    | emote_investigate            | loop     | Soft ambient search |
| sfx_emote_candle_pray    | emote_candle_pray            | loop     | Wind + soft chant   |

=======================================================================
## PRODUCTION SPECS
=======================================================================

### Format:
```
Format   : .ogg (primary) + .mp3 (fallback)
Sample Rate: 44100 Hz
Bit Depth: 16-bit
Mono/Stereo: Mono untuk SFX, Stereo untuk music stinger
Volume Normalization: -14 LUFS (integrated)
Peak: -1 dBTP (true peak)
```

### Roblox Audio Upload Limits:
```
Max duration : 7 menit (untuk sound)
Max file size: 20 MB
Format supported: .ogg, .mp3, .flac, .wav (convert ke ogg untuk efficiency)
```

### Indonesian Gamelan Elements (WAJIB ada di tier up & stinger):
```
Recommended samples:
- Saron (metallophone): cocok untuk "ding" reward
- Gong ageng: impact besar untuk legendary reveal
- Kenong: medium impact untuk tier up
- Gambang (xylophone kayu): mystery/exploration feel
- Suling (flute bambu): atmospheric horror-but-wonder

Gunakan sample library atau synthesize sendiri.
Jangan pakai gamelan cliché/overused — buat yang unik untuk PASRAHPHOBIA.
```

=======================================================================
## WORKFLOW PRODUKSI SFX
=======================================================================

```
1. Terima timing reference dari AGENT_04
   → Catat durasi animasi UI yang bersangkutan
   → SFX harus "peak" pada momen visual paling impactful

2. Buat layer audio:
   Layer 1: Base tone / hit (gamelan/chime/etc)
   Layer 2: Texture / sparkle / whoosh
   Layer 3: Tail reverb (optional — jangan terlalu panjang)

3. Mix:
   - Normalize ke -14 LUFS
   - High-pass filter: cut below 80Hz untuk SFX (bukan music)
   - Add slight reverb untuk feel "ruangan tua" — tapi tidak berlebihan

4. Export:
   - .ogg mono untuk SFX pendek
   - .ogg stereo untuk music stinger (gacha legendary, dll)
   - Trim silence: 0ms di awal, max 100ms di akhir

5. Test di Roblox:
   - Upload ke Roblox Creator Hub
   - Test di Studio dengan Sound instance
   - Verify volume tidak terlalu keras relative ke game sound lain
   - Catat AssetId dari upload
```

=======================================================================
## NAMING CONVENTION OUTPUT
=======================================================================

```
[sfx_id].ogg           ← Primary file
[sfx_id].mp3           ← Fallback

Contoh:
  sfx_tier_claim.ogg
  sfx_gacha_reveal_legend.ogg
  sfx_checkin_streak7.ogg

Simpan di: assets/audio/
```

=======================================================================
## LAPORAN KE AGENT_06
=======================================================================

Setelah semua audio di-upload ke Roblox, laporan ke AGENT_06:

```
=== AUDIO MANIFEST ===
sfx_tier_claim          → rbxassetid://[ID]
sfx_tier_up_free        → rbxassetid://[ID]
sfx_tier_up_premium     → rbxassetid://[ID]
sfx_gacha_reveal_common → rbxassetid://[ID]
sfx_gacha_reveal_legend → rbxassetid://[ID]
...dll untuk semua SFX
=== END AUDIO MANIFEST ===
```

AGENT_06 akan pakai ID ini di SoundService config Lua.

=======================================================================
## CHECKLIST SEBELUM KIRIM KE AGENT_06
=======================================================================

```
□ Semua SFX sudah di-test di Roblox Studio (tidak error/distort)
□ Volume normalized (-14 LUFS)
□ Tidak ada clipping (peak < -1 dBTP)
□ Duration sesuai spec
□ Indonesian gamelan element ada di reward-tier SFX
□ Legendary SFX terasa significantly lebih epic dari Common
□ Semua file .ogg berhasil di-upload ke Roblox
□ Audio manifest dengan AssetId sudah disiapkan untuk AGENT_06
□ Naming convention benar
```

=======================================================================
AGENT_05 RULES:
- JANGAN buat ambient horror (sudah ada di game)
- Volume harus lebih pelan dari gameplay SFX (jangan ganggu fokus pemain)
- Legendary reveal HARUS terasa berbeda — player harus kaget senang
- Loop audio (emote) HARUS seamless tanpa pop/click di loop point
- Jika tidak bisa buat gamelan original → gunakan royalty-free sample, BUKAN
  licensed commercial tracks (akan di-DMCA di Roblox)
=======================================================================

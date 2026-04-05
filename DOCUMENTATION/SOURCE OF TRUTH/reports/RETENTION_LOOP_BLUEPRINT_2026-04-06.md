# Retention Loop Blueprint 2026-04-06

## Tujuan

Menjawab pertanyaan inti:

- pemain install
- pemain enjoy
- lalu besok kenapa harus balik lagi

Blueprint ini sengaja tidak langsung mengubah code. Fokusnya adalah lane retention yang kompatibel dengan arsitektur PASRAHPHOBIA saat ini.

## Prinsip

- `Ranked` harus tetap fair, jadi tidak ada item beli yang memberi keunggulan kemenangan langsung
- `MM` dan `PP` tetap currency in-game, bukan lintas game
- loop retention harus memberi alasan kembali tanpa memaksa pay-to-win
- reward utama retention diarahkan ke:
  - kosmetik
  - title / border / banner
  - VFX / emote / voice line cosmetic
  - lore unlock
  - prestige/profile flex

## North Star

Target retention PASRAHPHOBIA bukan “grind tanpa arah”, tetapi:

1. pemain ingin menyelesaikan target harian singkat
2. pemain ingin membuka cosmetic/status baru
3. pemain ingin mengejar mastery dan prestige
4. pemain ingin melihat variasi horror yang berbeda setiap run
5. pemain ingin punya alasan sosial untuk balik

## Loop 1 - Daily Quest / Streak

Owner system:

- `DailyOpsSystem` baru

Cadence:

- reset harian
- maksimal 3 quest aktif per hari
- 1 quest mudah, 1 menengah, 1 situasional

Contoh quest:

- selesaikan 1 match `Classic`
- survive 1 hunt
- identifikasi ghost dengan benar
- kumpulkan 2 evidence
- finish 1 match dengan teman

Reward source:

- `MM`
- sedikit `PP`
- streak token khusus kosmetik

Anti-exploit baseline:

- progress hanya dihitung dari `match completed`, bukan sekadar join/leave
- satu akun tidak boleh spam room kosong untuk tick quest palsu
- quest berbasis tim harus valid bila match memenuhi durasi minimum dan fase minimum

## Loop 2 - Meta Progression

Owner system:

- `PlayerProgressionSystem`

Cadence:

- progress permanen
- naik per match selesai, performa, survive, dan objective

Lane progression:

- `Account Level`
- `Investigator Path`
- `Ghost Archive Completion`
- `Prestige Track`

Reward source:

- title
- profile banner
- lobby flex item
- emote cosmetic
- journal skin
- flashlight skin / UI skin

Anti-exploit baseline:

- progress hanya dari reward server-authoritative
- `Ranked` dan `Classic` memberi progression berbeda, tapi bukan power
- tidak ada node skill tree yang menaikkan peluang menang di `Ranked`

## Loop 3 - Social Pressure

Owner system:

- `SocialSeasonSystem`

Cadence:

- board harian ringan
- board mingguan utama
- spotlight season bulanan

Surface:

- `Leaderboard`
- `Lobby Flex`
- `Profile Inspect`

Metric yang aman:

- extraction streak
- correct guess streak
- clean investigation count
- weekly ghost hunter score
- cosmetic prestige showcase

Jangan pakai:

- membeli item sebagai faktor rank sosial
- total spend sebagai surface publik

Anti-exploit baseline:

- board hanya pakai data hasil match yang selesai
- suspicious outlier harus bisa di-flag dari server
- metric leaderboard tidak boleh mudah difarm via room private kosong

## Loop 4 - Content Rotation

Owner system:

- `RotationEventSystem`

Cadence:

- daily modifier ringan
- weekly haunted contract
- monthly featured ghost/map/event

Contoh modifier:

- `Cold House Week`
- `Silent Hunt`
- `Fast Setup`
- `Limited Evidence`

Reward source:

- badge event
- seasonal cosmetic token
- title sementara / permanen
- lore page event

Anti-exploit baseline:

- modifier hanya mengubah ruleset match, bukan memberi item beli unggul
- reward event harus tetap bisa didapat tanpa transaksi Robux

## Loop 5 - Horror Replayability

Owner system:

- `ReplayVariationSystem`

Target:

- tiap run tidak terasa copy-paste

Mekanik:

- room seed yang berubah
- evidence bias per contract
- event table berbeda per map
- roaming / manifestation cadence bervariasi
- rare anomaly chance yang tetap fair

Mode tambahan:

- `Speedrun Contract`
- `No-Light Challenge`
- `Perfect Investigation`

Anti-exploit baseline:

- seed random tetap server-authoritative
- variasi tidak boleh membuat deduction mustahil
- `Ranked` variation harus dibatasi agar tetap adil

## Loop 6 - Achievement Hunting

Owner system:

- `AchievementSystem`

Kategori:

- survival
- deduction
- map mastery
- ghost mastery
- social/co-op
- seasonal

Reward source:

- profile badge
- title
- banner frame
- lore fragment
- emote / inspect pose cosmetic

Anti-exploit baseline:

- achievement penting hanya unlock pada match valid
- repeatable farm achievement harus dibatasi per cadence

## Loop 7 - Lore Unlock

Owner system:

- `LoreArchiveSystem`

Cadence:

- unlock per ghost discovery
- unlock per contract completion
- unlock per event mingguan

Format reward:

- journal page
- audio log
- map incident report
- ghost family archive

Nilai retention:

- memberi motivasi jangka panjang selain win/lose
- cocok untuk horror karena memperluas misteri

Anti-exploit baseline:

- lore gated by milestone nyata, bukan transaksi
- duplicate lore convert ke token kosmetik kecil

## Prioritas Implementasi

Urutan paling aman:

1. `DailyOpsSystem`
2. `AchievementSystem`
3. `LoreArchiveSystem`
4. `SocialSeasonSystem`
5. `RotationEventSystem`
6. `PlayerProgressionSystem`
7. `ReplayVariationSystem`

Alasan:

- daily + achievement + lore memberi alasan balik paling cepat
- risikonya lebih rendah daripada langsung membuat sistem sosial/event besar

## Definition of Success

Blueprint retention ini dianggap siap dieksekusi jika:

- setiap loop punya owner system yang jelas
- reward source tidak merusak fairness `Ranked`
- semua lane bisa dijalankan bertahap tanpa refactor besar arsitektur runtime inti

## Catatan Publish

- retention loop bukan alasan untuk menambah monetization agresif
- `Robux` tetap untuk cosmetic/status/value yang tidak pay-to-win
- sebelum implementasi live, setiap lane retention harus lewat audit fairness dan exploit review

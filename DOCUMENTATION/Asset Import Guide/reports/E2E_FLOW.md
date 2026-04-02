# E2E Flow PASRAHPHOBIA (Versi Orang Awam)

Dokumen ini diringkas dari pembacaan:
- seluruh `GamePhaseSystem`
- seluruh `GhostSystem`
- seluruh file `*Controller.lua` (157 file)

Catatan penting: tidak semua controller aktif saat game jalan. Yang aktif ditentukan oleh `SystemRegistry`.

## 1) Apa yang terjadi dari lobby sampai match selesai?

1. Pemain masuk **Lobby**.
2. Pemain buka **Room Browser**: bisa buat room, join room, pilih mode, pilih map, pilih difficulty, lalu ready.
3. Host tekan **Start** -> ada countdown.
4. Room dikirim ke sistem matchmaking internal (event `MatchmakingStarted`) lalu dibuat **match baru**.
5. Server clone map ke `Workspace/ActiveMatches/Match_<id>`, teleport pemain ke spawn map.
6. Match masuk urutan fase otomatis:
   - `PreparationPhase` (15 detik)
   - `InvestigationPhase` (180 detik)
   - `HuntPhase` (45 detik)
   - `EndgamePhase` (15 detik)
7. Selama match, ghost AI jalan terus: roaming, manifest, interaksi, hunt, spawn evidence.
8. Jika kondisi akhir terpenuhi (misalnya semua player mati, atau extraction selesai), match ditutup.
9. Pemain dipulangkan ke lobby, map match dibersihkan, hasil match dikirim ke client.

## 2) Apa yang bisa dilakukan player di setiap fase?

### Lobby
- Buat/join/leave room
- Set ready
- Host start/cancel start
- Pilih mode, map, difficulty
- Set password room, kick player

### Preparation
- Masuk map dan siap-siap tim (fase transisi awal)
- Pintu di map bisa interaksi dengan prompt `[E] Buka Pintu` / `[E] Tutup Pintu`

### Investigation
- Gunakan tool evidence
- Kumpulkan evidence
- Tebak jenis ghost (journal/guess flow)
- Pindah ruangan dan eksplor map

### Hunt
- Fokus bertahan hidup
- Bisa mati jika diserang ghost
- Kalau ghost sudah teridentifikasi, pemain hidup bisa ekstraksi lewat extraction zone

### Endgame
- Fase penutupan singkat
- Menunggu hasil match dan balik lobby

## 3) Kondisi menang dan kalah

### Menang (utama)
- `extraction_complete`: semua pemain yang masih hidup berhasil ekstraksi.
- Secara sistem hasil, tim juga bisa dianggap sukses dari `contractSuccess` (tergantung objective + identifikasi ghost + ekstraksi).

### Kalah (utama)
- `team_eliminated`: semua pemain yang masih hidup menjadi mati.
- `ghost_spawn_failed`: ghost gagal spawn saat match mulai.

### Match berakhir karena timeout/alur
- `endgame_timer_elapsed`: timer endgame habis.
- Bisa juga ada end karena event progres lain seperti `all_evidence_discovered`.

## 4) Apa yang sudah implemented vs belum/parsial?

## Sudah jalan
- Flow lobby -> room -> queue -> start match
- Teleport ke map aktif per match + cleanup setelah match
- Urutan fase match berbasis timer
- Ghost AI (state machine, hunt, roaming, evidence trigger)
- Evidence pipeline (spawn, validasi, collect, ghost guess)
- Health/death flow + event spectator
- Match result aggregation
- Interaksi pintu `[E] Buka/Tutup Pintu` + prompt proximity
- Door punya `PathfindingModifier` `PassThrough=true` (membantu ghost path melewati doorway)

## Belum/parsial
- Visual ghost masih ada fallback **placeholder model** (`GhostPlaceholder_*`), belum final asset karakter ghost.
- `ResultsPhase` di `GamePhaseSystem/Phases/ResultsPhase.lua` masih minimal (belum logic hasil yang kaya).
- Ada beberapa loop fase lain (`GameplayLoopController`, `HuntPhaseController`) yang terlihat seperti layer lama/duplikat, bukan sumber utama fase match.
- Beberapa sistem sengaja **dinonaktifkan di runtime** oleh `SystemRegistry`:
  - `MatchmakingSystem`
  - `ServerQueueSystem`
  - `EvidenceJournalSystem`
  - `EvidenceToolSystem`
  - `ToolSignalProcessingSystem`
  - `ToolInteractionSystem`
- `HuntEscapeSystem` register extraction zone dari `Workspace.Maps`, sementara map match aktif di-clone ke `Workspace.ActiveMatches`; ini berpotensi bikin binding extraction tidak selalu sinkron di runtime tertentu.


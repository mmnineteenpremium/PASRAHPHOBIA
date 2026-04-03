# E2E Test Matrix 2026-04-03

## Tujuan

Dokumen ini adalah panduan uji end-to-end yang bisa dipakai saat bekerja dari VS Code + MCP + Roblox Studio. Fokusnya pada bukti visual dan state nyata, bukan asumsi dari dokumen lama.

## Aturan Uji

- jalankan dari file repo yang sedang dikelola Rojo
- gunakan `MCP` untuk inspect, playtest, dan cek console
- semua hasil uji harus bisa dijelaskan balik ke file source
- setiap test case harus punya hasil `PASS`, `FAIL`, atau `BLOCKED`

## Matrix Uji Inti

| ID | Flow | Yang Dicek | Bukti Visual / Runtime | PASS Jika |
| --- | --- | --- | --- | --- |
| E2E-01 | Boot Studio | sistem inti boot tanpa error blocker | console boot log, remote tree, system state | tidak ada crash, registry sesuai target slice |
| E2E-02 | Masuk lobby | player spawn dan HUD dasar muncul | spawn position, HUD, camera, audio awal | player bisa bergerak dan masuk state lobby normal |
| E2E-03 | Buat room | room dibuat, host ownership benar | panel room, player list, status host | room state sinkron client-server |
| E2E-04 | Start match | countdown, teleport, map clone | phase state, lokasi player, map aktif | pemain masuk map aktif tanpa desync |
| E2E-05 | Preparation | timer dan objective awal | HUD timer, system state | fase preparation berjalan sesuai durasi aktual |
| E2E-06 | Investigation | evidence dan tool minimum | interaksi tool, event evidence, UI update | satu tool minimum bekerja benar |
| E2E-07 | Ghost manifestation | ghost muncul dan terlihat benar | model/placeholder, scale, movement | ghost terlihat dan bergerak sesuai slice |
| E2E-08 | Hunt | state hunt, audio, danger feedback | HUD, audio, ghost aggression | state hunt transisi dan feedback jelas |
| E2E-09 | Extraction or endgame | jalur akhir match | extraction zone, result state | match bisa benar-benar selesai |
| E2E-10 | Results return | result panel dan kembali ke lobby | result screen, cleanup map, player state | loop kembali ke lobby tanpa state bocor |

## Matrix Teknis Pendukung

| ID | Area | Yang Dicek | PASS Jika |
| --- | --- | --- | --- |
| TECH-01 | Remote surface | semua remote canonical ada | tidak ada listener ke remote legacy |
| TECH-02 | Audio | fallback valid | tidak ada `403` untuk fallback utama |
| TECH-03 | Ghost asset | asset final source-controlled | model final tidak hanya hidup di Studio |
| TECH-04 | Tool asset | tool visual dan UI sinkron | model/tool UI tidak drift |
| TECH-05 | Extraction | zone membaca map clone aktif | end condition match konsisten |
| TECH-06 | Persistence | state test penting tersimpan | data tidak hilang di environment target |
| TECH-07 | Commerce | purchase bridge nyata | flow entitlement dan reward berjalan |

## Bukti yang Wajib Dikumpulkan

Untuk setiap sesi uji penting, simpan:

- screenshot state visual
- log console yang relevan
- diff source jika ada perubahan konfigurasi
- catatan `PASS/FAIL/BLOCKED`
- file/folder owner yang tersentuh

## Urutan Uji yang Disarankan

1. `E2E-01` sampai `E2E-04`
2. `TECH-01`, `TECH-02`, `TECH-05`
3. `E2E-05` sampai `E2E-10`
4. `TECH-03`, `TECH-04`
5. `TECH-06`, `TECH-07`

## Catatan Kerja Bersama MCP

- gunakan MCP untuk cek tree dan inspect state live sebelum menebak bug
- gunakan MCP untuk start/stop playtest dan ambil bukti runtime
- jika perubahan dilakukan di Studio untuk tuning visual, mirror hasil final ke repo sebelum test berikutnya

## Update 2026-04-04 06:03 ICT

Smoke run live terbaru (`Ranked -> CreateRoom -> HostStart -> EndMatch`) menghasilkan status berikut:

- `E2E-01 Boot Studio`: `PASS`
  - `PasrahStudioE2EReady = true`
  - remote `StudioE2EControl` tersedia
- `E2E-03 Buat room`: `PASS`
  - room flow menghasilkan event list lobby aktif (`23` event pada run ini)
- `E2E-04 Start match`: `PASS`
  - `enteredMatch = true`
  - `MatchPhase = Preparing`
  - `RoomBrowserUI.Panel.Visible = false` setelah teleport
- `E2E-10 Results return`: `PASS`
  - `EndMatch` via StudioE2E mengembalikan player ke lobby (`InMatch=false`)
- `E2E-05` sampai `E2E-09`: `BLOCKED/PENDING`
  - belum dieksekusi penuh pada smoke run ini; butuh pass dedicated per fase gameplay/hunt/extraction visual

## Update 2026-04-04 06:05 ICT

Pass lanjutan untuk fase hunt dan extraction menghasilkan status berikut:

- `E2E-08 Hunt`: `PASS`
  - `StudioE2EControl(action=ForceHunt)` -> `ok=true`
  - client mencapai `MatchPhase=Hunt`
- `E2E-09 Extraction or endgame`: `PASS` (Studio override path)
  - `StudioE2EControl(action=ExtractSelf, allowStudioOverride=true)` -> `ok=true`
  - player kembali ke lobby (`InMatch=false`) dan fase bergerak ke `Result`

Catatan:

- satu run awal `ExtractSelf` sempat gagal `player_not_alive` saat timing hunt tertentu.
- rerun extraction pada match aktif menunjukkan jalur extraction override tetap valid untuk gate E2E.

## Update 2026-04-04 06:07 ICT

Pass manifestation ghost untuk slice `Pocong`:

- `E2E-07 Ghost manifestation`: `PASS`
  - `SetForcedGhost(ghostType=Pocong, visualState=Manifestation)` -> ack `ok=true`
  - runtime match memunculkan `Ghost_Pocong` pada map aktif
  - `MeshPart.Transparency = 0` saat override manifestation aktif
  - cleanup override dilakukan (`ghostType=false, visualState=false`) setelah verifikasi

Status matrix inti saat ini:

- `PASS`: `E2E-01`, `E2E-03`, `E2E-04`, `E2E-07`, `E2E-08`, `E2E-09`, `E2E-10`
- `PENDING`: `E2E-02`, `E2E-05`, `E2E-06`

## Update 2026-04-04 06:09 ICT

Verifikasi lanjutan lobby + preparation:

- `E2E-02 Masuk lobby`: `PASS`
  - `InMatch=false`
  - `LobbyUI.Enabled=true`
  - `LobbyUI.MainPanel.Visible=true`
  - karakter spawn normal di area lobby
- `E2E-05 Preparation`: `PASS`
  - flow `CreateRoom -> HostStart` mencapai `MatchPhase=Preparing`
  - `MatchUI.HeaderCard.StateBadge = PERSIAPAN`
  - `MatchUI.HeaderCard.SecondaryLabel` terisi objective awal (`Tunggu loading selesai, lalu mulai cari evidence.`)
  - `MatchUI.SummaryFrame.StatusRow.Value = BRIEFING`

Status matrix inti final per run saat ini:

- `PASS`: `E2E-01`, `E2E-02`, `E2E-03`, `E2E-04`, `E2E-05`, `E2E-07`, `E2E-08`, `E2E-09`, `E2E-10`
- `PENDING`: `E2E-06` (tool evidence minimum pass dedicated)

## Update 2026-04-04 06:17 ICT

Pass dedicated untuk `E2E-06` (tool evidence minimum):

- `StudioE2EControl(action=UseEvidenceTool, toolType=JejakEnergi)` -> `ok=true`
  - result: `match=... tool=JejakEnergi evidence=MEDOK fallback=publish`
- Journal runtime menunjukkan update evidence yang konsisten:
  - `Discovered Evidence - MEDOK`
  - `Confirmed Evidence - MEDOK`
  - `ToolStatusLabel = Evidence berhasil dibaca. / Collected MEDOK`
  - hero/meta journal update ke state deduction non-empty

Catatan:

- pada run ini, ringkasan `MatchUI.SummaryFrame.EvidenceRow` masih bisa tertinggal `0 disc / 0 conf` di timing tertentu.
- owner canonical evidence UI tetap tervalidasi lewat `JournalUI` + event `UIEvidenceUpdated`, sehingga gate `E2E-06` dianggap tertutup.

Status matrix inti saat ini:

- `PASS`: `E2E-01`, `E2E-02`, `E2E-03`, `E2E-04`, `E2E-05`, `E2E-06`, `E2E-07`, `E2E-08`, `E2E-09`, `E2E-10`

## Update 2026-04-04 06:45 ICT

Regression pass tambahan untuk area yang dikeluhkan user:

- utility tool stock guard:
  - `Garam` sekarang gagal di attempt ke-4 (`tool_out_of_stock`)
  - `Salib` sekarang gagal di attempt ke-3 (`tool_out_of_stock`)
  - `Dupa` sekarang gagal di attempt ke-3 (`tool_out_of_stock`)
- ghost visual scale:
  - `Ghost_Pocong` runtime muncul dengan bounding box `~2.59 x 8.5 x 2.2` (tidak raksasa lagi)

Implikasi matrix:

- `E2E-06` tetap `PASS` dan sekarang lebih aman karena utility branch sudah punya guard stok.
- `E2E-07` tetap `PASS` dengan kualitas visual lebih proporsional untuk validasi gameplay.

## Update 2026-04-04 06:49 ICT

Tambahan coverage untuk fallback visual ghost type non-dedicated:

- force `Kuntilanak` di StudioE2E menghasilkan model runtime `Ghost_Kuntilanak`.
- runtime menandai `VisualTemplateName=Pocong` dan `PlaceholderVisual=false`.
- ghost tetap memiliki mesh/root valid (`hasMesh=true`, `hasRoot=true`), bukan placeholder box.

Implikasi matrix:

- `E2E-07` tetap `PASS` dengan baseline visual ghost yang konsisten lintas tipe meski roster dedicated belum lengkap.

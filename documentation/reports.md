# Reports

- Timestamp: 2026-03-19 08:52
- Scope: RoomBrowser + Lobby room flow stabilization (server-authoritative countdown/cancel, password room, sync state).

## Completed
- Host start flow diubah menjadi server-authoritative countdown 5 detik sebelum queue/match start.
- Host sekarang bisa cancel countdown via CancelHostStart (server-side, bukan sekadar hide UI).
- Queue dari host start sekarang dieksekusi sekali per room (menghilangkan pola multi-queue per member).
- Room state broadcast diperluas agar list/status semua player sinkron setelah join/leave/ready/start/cancel.
- Join room sekarang mendukung password (client prompt + payload password ke server).
- Password room divalidasi server sebagai 4 digit (atau kosong untuk menonaktifkan).
- UI room list menandai status COUNTDOWN vs IN GAME dan tetap blok join saat inGame.

## Files Updated
- src/ServerScriptService/Server/LobbySystem/RoomManager.lua
- src/ServerScriptService/Server/LobbySystem/Service.lua
- src/ServerScriptService/Server/LobbySystem/Controller.lua
- src/client/UI/RoomBrowserController.lua
- src/client/UI/Main.lua
- documentation/codex.md

## Validation
- rojo build default.project.json sukses.

## Follow-up Manual Test (Studio)
- 2 player: Host create room -> kedua player ready -> Host start -> countdown tampil di semua client -> cancel oleh host -> state kembali normal.
- 2 player: Host start tanpa cancel -> match pipeline lanjut normal.
- Password: host set 4 digit -> player lain wajib input benar untuk join.

---

- Timestamp: 2026-03-31 11:40
- Scope: E2E UI/UX critical fixes (lobby toggle, in-game close guidance, match timer, evidence quick access) + FPV/viewmodel flashlight correction.

## Completed
- Lobby panel utama sekarang default tertutup dan bisa di-toggle dari tombol tepi `>` / `<` tanpa mematikan `LobbyUI`.
- Match panel sekarang memberi hint close yang eksplisit (`Esc` / `B` / `X`) dan quick access `EVIDENCE [J]` di kanan bawah.
- Client sekarang memproses `PhaseChanged` payload dari match system dan merender countdown fase dari `durationSeconds` yang sudah dikirim server.
- Journal/Evidence panel mendapat jalur E2E minimal untuk `JejakEnergi`: buka panel, tekan `SCAN JEJAK`, lihat status/result, lalu tutup kembali.
- Window manager tetap dipakai: membuka Room Browser / Match / auxiliary window akan menutup panel konflik yang lain.
- FPV viewmodel dipindah ke anchor midpoint dua tangan agar posisi idle lebih simetris, bukan lagi bertumpu di satu tangan.
- Clone tangan FPV sekarang dipaksa non-emissive (`SmoothPlastic`, tanpa reflectance), dan flashlight prop lokal memakai lens non-Neon dengan `SpotLight` ringan pada tool, bukan membuat tangan tampak menyala.

## Files Updated
- src/client/UI/Main.lua
- src/client/CameraController.client.lua
- documentation/reports.md

## Validation
- Belum ada parser/test otomatis yang bisa dijalankan dari environment ini karena tool Luau/Studio tidak tersedia.
- Audit statis sudah dilakukan untuk memastikan patch masuk ke jalur state/UI yang memang sudah ada, bukan menambah sistem paralel baru.

## Follow-up Manual Test (Studio)
- Lobby: masuk beranda -> panel kiri harus default tertutup -> klik toggle tepi untuk buka/tutup -> state tidak mengganggu Room Browser.
- In-match: panel MATCH harus bisa ditutup via tombol `X`, tombol `SEMBUNYIKAN`, `Esc`, dan `ButtonB`.
- Timer: saat `Preparation`, `Investigation`, dan `Hunt`, timer harus muncul di atas dan terus berkurang.
- Evidence: saat match aktif, tekan `J` atau klik `EVIDENCE [J]` -> panel Journal muncul -> tekan `SCAN JEJAK` -> status tool berubah sesuai response backend -> tutup panel via `X` atau `Esc`.
- Single-window: buka Journal lalu Room Browser/Menu/Profile -> panel sebelumnya harus dismiss, tidak overlap aktif bersamaan.
- FPV: masuk first person -> tangan harus berada di kiri bawah / kanan bawah secara lebih simetris, tidak terbalik, dan flashlight tool terlihat di tangan kanan tanpa efek glow pada tangan.

---

- Timestamp: 2026-03-31 12:20
- Scope: E2E blocker fixes for lobby selector stability, in-game keybind hints, flashlight emissive bug, ghost visibility, and journal hotkey reliability.

## Completed
- Issue 1: RoomBrowser/lobby selector sekarang tidak lagi di-repaint buta setiap 0.1 detik; refresh dibatasi oleh render key state sehingga tombol `Classic`, `Ranked`, dan `Map` tidak terus berkedip saat state tidak berubah.
- Issue 1: Style tombol dibikin stabil dengan `AutoButtonColor = false` sebagai baseline sehingga visual press tidak bentrok dengan refresh warna runtime.
- Issue 2: HUD hint bar persistent ditambahkan di in-game UI untuk keybind yang memang sudah ada: `J`, `F`, `Shift`, `Esc`, plus petunjuk akses panel MATCH via tombol.
- Issue 3: Flashlight server tidak lagi menaruh light/beam langsung pada part tangan. Sekarang dibuat `FlashlightHandle` terpisah dan seluruh `SpotLight` / `PointLight` / `Beam` diparent ke handle itu.
- Issue 3: Tangan FPV client tetap dipaksa non-emissive, dan flashlight lens/tool tetap menjadi sumber cahaya lokal di viewmodel.
- Issue 4: Ghost server tidak lagi spawn sebagai core transparan saja. Sekarang ada placeholder rig visible di Workspace dengan nama `GhostPlaceholder_<GhostType>`.
- Issue 5: Toggle `J` dibuat lebih toleran saat in-game FPV; jika input sudah ditandai `gameProcessed` tetapi player sedang in-match dan menekan `J`, journal tetap bisa ditoggle selama tidak sedang fokus ke textbox.

## Files Updated
- src/client/UI/Main.lua
- src/ServerScriptService/Server/FlashlightSyncSystem/Service.lua
- src/ServerScriptService/Server/GhostSystem/Service.lua
- documentation/reports.md

## Root Cause Notes
- Issue 1: tombol lobby/map selector dipukul terus oleh render loop 10Hz walau state tidak berubah, sehingga visual state dan input terasa glitchy.
- Issue 3: flashlight remote light sebelumnya ditempel langsung ke attachment pada tangan kanan, sehingga secara visual sumber glow mengikuti mesh tangan.
- Issue 4: ghost backend memang hidup, tetapi visual server yang dibuat hanya `Part` transparan sebagai primary root tanpa badan yang bisa dilihat player.
- Issue 5: binding `J` ada, tetapi terlalu patuh pada `gameProcessed`, yang di FPV/in-match bisa membuat toggle journal terasa mati.

## Validation
- Belum ada playtest Studio atau parser Luau dari environment ini.
- Verifikasi yang dilakukan masih statis melalui pembacaan code path dan diff hasil patch.

## Follow-up Manual Test (Studio)
- Issue 1: buka RoomBrowser -> tap `Classic`, `Ranked`, `MapSelector`, dan pilihan map berkali-kali; tombol harus stabil, tidak blink, dan satu klik memberi satu response.
- Issue 2: saat in-match FPV, hint bar bawah harus selalu terlihat tanpa buka menu apa pun.
- Issue 3: flashlight ON/OFF -> tangan tidak boleh glow; sumber sinar harus berasal dari flashlight handle/tool.
- Issue 4: saat ghost spawn atau hunt, model placeholder ghost harus terlihat di Workspace dan mudah dicari lewat explorer.
- Issue 5: tekan `J` saat in-match dan saat cursor lock; journal harus toggle konsisten.

## Notes
- [TECH DEBT RISK] Visual ghost saat ini masih placeholder rig server-side untuk unblock E2E, bukan pipeline visual ghost final. Ini sengaja dibuat sederhana supaya visibility/debugging jalan dulu.

---

- Timestamp: 2026-03-31 13:15
- Scope: E2E lanjutan issues 1-7 (viewmodel pose/emissive, lobby toggle placement, teleport/loading transition, fullscreen results gate, runtime door interaction, in-game keybind responsiveness, evidence journal toggle).

## Completed
- Issue 1: viewmodel tangan sekarang dipaksa non-emissive dan light anak pada clone tangan dibersihkan. Base offset FPV diturunkan/ditarik menjauh dari kamera, lalu setiap segmen lengan diberi layout lokal baru agar idle pose lebih simetris, lebih rendah, dan tidak lagi menghadap ke bahu.
- Issue 2: tombol hide/collapse panel lobby dipindah ke sisi kiri panel agar sesuai posisi panel di kiri layar.
- Issue 3: teleport in-game sekarang melewati loading screen yang lebih kaya: label `BERMAIN`, nama map, tips rotasi, progress bar sederhana, dan flow loading tetap menahan pemain selama fase preparing/loading/briefing sebelum fade ke in-game.
- Issue 3: label `Bermain` juga dikembalikan sebagai state message saat preparing/loading.
- Issue 4: hasil match sekarang fullscreen dengan kartu ringkasan terpusat, tombol close disembunyikan selama 5 detik pertama, dan countdown unlock ditampilkan sebelum tombol lanjut muncul.
- Issue 4: jika event `ReturnedToLobby` datang terlalu cepat, layar hasil tetap dipertahankan sampai lock 5 detik selesai agar pemain sempat membaca hasil.
- Issue 5: pintu map sekarang mendapat runtime `ProximityPrompt` `[E]`, bisa buka/tutup, dan terbuka secara fisik dengan collision nonaktif saat open sehingga player/ghost tidak lagi tertahan oleh door collider yang tertutup.
- Issue 5: runtime door juga didaftarkan ke `MapInteractionSystem` dan mendengar event `MapObjectInteracted`, jadi ghost/director event yang menyentuh pintu bisa ikut menggerakkan pintu yang sama.
- Issue 6: input `J`, `B`, `Esc`, dan `ButtonB` tidak lagi kalah total oleh `gameProcessed` saat in-game/FPV; `K` sekarang jadi shortcut keyboard eksplisit untuk buka/tutup panel MATCH agar hint bar punya aksi yang benar-benar ada.
- Issue 7: tombol `EVIDENCE [J]` dan key `J` sekarang lewat jalur toggle journal yang sama, jadi evidence panel minimal bisa dibuka, dibaca, lalu ditutup kembali secara konsisten.

## Files Updated
- src/client/CameraController.client.lua
- src/client/UI/Main.lua
- src/ServerScriptService/Server/MatchSystem/DoorRuntime.lua
- src/ServerScriptService/Server/MatchSystem/MatchTeleport.lua
- documentation/reports.md

## Validation
- Belum ada parser Luau, stylua, Rojo CLI, atau playtest Studio yang bisa dijalankan dari environment ini.
- Verifikasi yang dilakukan masih statis dengan membaca code path yang aktif dan audit diff patch.

## Follow-up Manual Test (Studio)
- Issue 1: masuk FPV idle -> tangan harus lebih kecil, lebih rendah, lebih ke pojok bawah kiri/kanan, tidak glow, dan telapak tidak lagi menghadap bahu.
- Issue 2: di lobby, tombol collapse panel harus berada di sisi kiri panel dan tetap bekerja buka/tutup.
- Issue 3: saat countdown selesai -> harus ada loading fullscreen dengan nama map, tips yang berganti, progress bar, dan label `BERMAIN`, lalu baru masuk ke map.
- Issue 4: selesai match -> kembali lobby -> hasil match tetap fullscreen selama 5 detik pertama, tanpa tombol skip; setelah itu tombol lanjut muncul.
- Issue 5: dekati pintu -> prompt `[E]` muncul -> tekan `E` untuk buka -> tekan lagi untuk tutup -> ghost/player tidak tertahan saat pintu sedang terbuka.
- Issue 6: saat in-game FPV, tekan `J`, `K`, `B`, `Esc`, dan `ButtonB` untuk memastikan semua aksi di hint/UI benar-benar merespons.
- Issue 7: klik `EVIDENCE [J]` atau tekan `J` -> Journal/Evidence panel harus terbuka, isi evidence tampil, `SCAN JEJAK` tetap bisa dijalankan, lalu panel bisa ditutup lagi.

## Notes
- [TECH DEBT RISK] Runtime pintu saat ini memakai prompt + swing/open logic generik berbasis ukuran part karena asset map belum punya rig hinge/constraint khusus. Ini cukup untuk unblock E2E, tetapi masih perlu diganti kalau nanti pintu memakai model dengan hinge artistik atau animasi spesifik per-map.
- [TECH DEBT RISK] Shortcut `K` untuk panel MATCH ditambahkan sebagai binding eksplisit agar HUD hint dan test keyboard punya jalur yang benar-benar bisa dipakai. Jika nanti project punya keybind manager terpusat, binding ini sebaiknya dipindahkan ke sana.
- [TECH DEBT RISK] Shop panel sekarang bisa ditoggle via `B` juga saat in-match demi konsistensi key test saat FPV. Kalau desain final tidak mengizinkan shop di match, gate ini perlu dipindah ke policy yang lebih tegas dan hint bar harus ikut disesuaikan.

---

- Timestamp: 2026-03-31 18:32
- Scope: E2E lanjutan issues 1-4 (viewmodel spacing+no glow, keyboard close/toggle panel match, force-close panels on teleport, 5s dark teleport placeholder).

## Completed
- Issue 1: Viewmodel tangan diperlebar (kiri lebih ke kiri, kanan lebih ke kanan) dan Z offset didorong lebih jauh ke depan lewat layout segment baru di `CameraController`.
- Issue 1: Sanitasi clone tangan diperketat: material dipaksa `Plastic`, reflectance tetap 0, dan pembersihan descendant sekarang menghapus `PointLight`/`SpotLight`/`SurfaceLight` serta efek visual lain yang bisa memicu kesan emissive.
- Issue 2: Keyboard close untuk Panel Match dipaksa deterministic: saat panel match terbuka, `Esc` selalu menutup panel match lebih dulu (tidak menunggu stack window lain).
- Issue 2: Toggle `K` untuk Panel Match dipertahankan sebagai open/close yang langsung memicu refresh visibility sehingga konsisten dengan hint bar `[K] Panel Match`.
- Issue 3: Ditambahkan jalur `force close` semua panel/transient UI saat transisi teleport (masuk game dan kembali lobby), termasuk auxiliary windows, room browser, panel match (dismiss), dan basic conflict windows.
- Issue 4: Ditambahkan overlay placeholder hitam fullscreen `TeleportScreen` + `LoadingOverlay` (DisplayOrder tinggi, tanpa teks), tampil 5 detik lalu fade out otomatis.
- Issue 4: Overlay dipanggil saat trigger teleport masuk (`MatchPreparing`) dan saat flow balik lobby (`RoomBrowserRoomLeft`/`ReturnedToLobby`/`LobbyEntered` sesuai phase).

## Files Updated
- src/client/CameraController.client.lua
- src/client/UI/Main.lua
- documentation/reports.md

## Validation
- Belum ada test otomatis Luau/Studio yang bisa dijalankan dari environment ini.
- Verifikasi dilakukan secara audit statis pada jalur event `MatchEvent`/`LobbyEvent`, binding input, dan helper viewmodel sanitization.

## Follow-up Manual Test (Studio)
- Issue 1: masuk FPV, cek jarak tangan harus lebih renggang kiri/kanan, posisi sedikit lebih maju, dan tidak ada glow walau flashlight ON/OFF.
- Issue 2: buka Panel Match lalu tekan `Esc` (dengan/ tanpa fokus input lain) harus selalu close; tekan `K` harus toggle buka/tutup konsisten.
- Issue 3: saat teleport masuk game dan saat kembali lobby, pastikan semua panel (Journal/Evidence/Shop/Match/RoomBrowser/dll) sudah tertutup sebelum UI dunia terlihat lagi.
- Issue 4: saat teleport masuk + keluar, layar harus hitam penuh 5 detik lalu fade out; tidak ada teks pada overlay.

## Notes
- [TECH DEBT RISK] Offset viewmodel tangan saat ini masih tuning angka statis per segment; aman untuk E2E, tetapi mungkin perlu kalibrasi per rig/avatar jika pipeline karakter berubah.
- [TECH DEBT RISK] Penutupan panel via `Esc` untuk Panel Match dibuat sebagai jalur prioritas langsung di handler input; bila nanti ada input manager terpusat, logic ini sebaiknya dipindahkan agar tidak duplikasi policy.
- [TECH DEBT RISK] `force close` teleport saat ini berbasis client-side state sweep (`_forceCloseAllPanelsForTeleport`) dan bukan registry UI global; jika jenis panel bertambah, daftar ini harus ikut dirawat.
- [TECH DEBT RISK] Overlay teleport hitam 5 detik masih placeholder generik client-side; saat artwork/fade pipeline final siap, helper `TeleportScreen` perlu diintegrasikan ke sistem transition resmi.

---

- Timestamp: 2026-03-31 21:20
- Scope: E2E unblock for match phase duration retune and runtime re-enable of evidence/tool support systems.

## Completed
- Issue 1: durasi fase match di sumber timer `GamePhaseSystem` diubah ke target baru: `PreparationPhase=30`, `InvestigationPhase=480`, `HuntPhase=60`, `EndgamePhase=30`.
- Issue 1: payload countdown fase dari `MatchSystem` disamakan ke angka yang sama agar UI client tidak menampilkan timer lama saat transisi server sudah memakai durasi baru.
- Issue 2: `EvidenceJournalSystem`, `EvidenceToolSystem`, `ToolSignalProcessingSystem`, dan `ToolInteractionSystem` dihapus dari daftar runtime-disabled pada `SystemRegistry`.
- Issue 2: conflict guard minimal ditambahkan di `EvidenceJournalSystem` agar saat aktif dia tidak lagi menganggap setiap `EvidenceLogged` sebagai evidence confirmed, dan payload `UIEvidenceUpdated`/`JournalUpdated` tetap membawa `discoveredEvidence` + `confirmedEvidence` yang kompatibel dengan UI aktif.
- `MatchmakingSystem` dan `ServerQueueSystem` tetap tidak di-enable sesuai batasan task.

## Files Updated
- src/ServerScriptService/Server/GamePhaseSystem/Service.lua
- src/ServerScriptService/Server/MatchSystem/MatchService.lua
- src/ServerScriptService/Server/Core/SystemRegistry.lua
- src/ServerScriptService/Server/EvidenceJournalSystem/Service.lua
- documentation/reports.md

## Validation
- Audit statis memastikan konstanta durasi baru aktif di dua jalur yang relevan: scheduler fase server dan payload countdown ke client.
- Audit statis memastikan empat sistem target tidak lagi diblokir oleh `DISABLED_RUNTIME_SYSTEM_NAMES`.
- `git diff --check` tidak bisa dipakai sebagai sinyal bersih repo karena worktree sudah memiliki banyak temuan lama yang tidak terkait patch ini.
- Belum ada playtest Studio atau parser Luau yang bisa dijalankan dari environment ini.

## Follow-up Manual Test (Studio)
- Start satu match dan ukur fase: preparation 30 dtk, investigation 8 menit, hunt 60 dtk, endgame 30 dtk.
- Periksa HUD timer client saat setiap fase berubah; angka harus sinkron dengan transisi server, tidak lagi berhenti di 15/180/45/15.
- Gunakan flow evidence/journal selama match dan pastikan board/journal tidak kehilangan `discoveredEvidence` saat sistem registry baru aktif.
- Verifikasi empat sistem target muncul di boot log registry tanpa crash, sementara `MatchmakingSystem` tetap tidak ikut boot.

## Notes
- [TECH DEBT RISK] `EvidenceJournalSystem` sekarang dijaga supaya kompatibel dengan `JournalSystem` yang masih menjadi producer journal utama. Ini workaround untuk mencegah duplicate pipeline lama menimpa state UI dengan payload yang lebih miskin; idealnya ownership journal akhirnya disatukan ke satu jalur authoritative.


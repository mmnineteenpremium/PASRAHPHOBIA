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


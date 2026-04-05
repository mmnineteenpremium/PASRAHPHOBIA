# QA Multiplayer Manual Checklist 2026-04-06

## Tujuan

Checklist ini menutup sisa `Phase 17 QA dan perf gate` yang memang tidak bisa dituntaskan penuh oleh harness single-client Studio. Fokusnya adalah smoke test dua client nyata tepat sebelum publish.

## Prasyarat

- buka project dari file kerja repo yang sedang tersambung Rojo
- pastikan build source terbaru sudah masuk ke Studio
- gunakan minimal `2` client Roblox nyata
- pastikan salah satu client menjadi host room

## Checklist

1. Boot kedua client tanpa warning/error blocker di console.
2. Pastikan kedua client spawn normal di lobby dan HUD dasar muncul.
3. Buat room dari host, lalu client kedua join ke room yang sama.
4. Verifikasi player list, host badge, mode, dan map sinkron di dua client.
5. Start match dari host.
6. Verifikasi countdown, teleport, dan `RoomBrowser` tertutup benar di dua client.
7. Di `Preparation`, cek objective/timer dan route HUD konsisten di dua client.
8. Di `Investigation`, pakai minimal satu tool di host lalu cek event UI/client kedua tidak crash.
9. Trigger hunt, lalu cek:
   - HUD hunt muncul di dua client
   - audio danger tidak double liar
   - hide/refuge prompt tetap responsif
10. Selesaikan match atau force end.
11. Pastikan result panel muncul di dua client lalu kembali ke lobby tanpa state bocor.

## PASS Jika

- join room, start match, hunt, result, dan return to lobby sinkron di dua client
- tidak ada warning/error blocker baru
- tidak ada stuck state UI/match yang hanya muncul pada client kedua

## BLOCKED Jika

- tidak ada client kedua nyata
- akun/test environment Roblox tidak siap
- Rojo/Studio session tidak stabil untuk run dua client

## Catatan

- checklist ini sengaja manual agar sesuai gate publish nyata, bukan simulasi harness tunggal
- jika checklist ini belum dijalankan, status QA publish adalah `pass_with_manual_multiplayer`, bukan `full_pass`

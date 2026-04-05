# Persistence Manual Checklist 2026-04-06

## Tujuan

Menutup gap terakhir antara persistence mock Studio dan persistence target yang benar-benar siap publish.

## Prasyarat

- environment target sudah mengizinkan DataStore
- schema profile terbaru sudah aktif
- build source terbaru sudah masuk

## Checklist

1. Masuk ke environment target yang memakai DataStore nyata.
2. Verifikasi diagnostics persistence menunjukkan `mode=datastore`, bukan `mock`.
3. Buat perubahan profile yang mudah diverifikasi:
   - currency `MM`
   - currency `PP`
   - inventory item
   - cosmetic equip
4. Keluar dari sesi.
5. Masuk ulang dengan akun yang sama.
6. Pastikan empat perubahan tadi tetap ada.
7. Jalankan satu match selesai.
8. Pastikan hasil match ikut tersimpan setelah reconnect kedua.

## PASS Jika

- load awal sukses
- save sukses
- reconnect kedua memuat state yang sama
- tidak ada rollback profile diam-diam

## FAIL Jika

- diagnostics masih `mock`
- wallet / inventory / cosmetic / reward hilang saat reconnect
- schema load/save tidak sinkron

## Catatan

- checklist ini wajib sebelum publish publik
- jangan menilai persistence siap publish hanya dari Studio mock

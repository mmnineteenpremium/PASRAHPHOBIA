# Quest Journal Weekly/Story/Daily Report

Date: 2026-06-11

## Summary

Quest Journal sekarang menampilkan daily, weekly, dan story di client setelah restart play dan verifikasi screenshot.

Root cause yang diperbaiki:
- UI `QuestJournal` memang sudah punya tab dan template, tetapi ukuran hasil clone dari template membuat card tidak terlihat di viewport.
- `DailyEngagementSystem.Service` adalah writer runtime yang stabil untuk `PasrahQuestData`.
- `DailyEngagementSystem.Controller` dan `DailyEngagementSystem.Main` sebelumnya masih membawa print debug startup yang sudah dibersihkan.

## Source of Truth

Source of truth yang dipakai sekarang:
- `src/ServerScriptService/Server/DailyEngagementSystem/Service.lua`

Catatan penting:
- Jangan anggap `DailyMissionSystem` sebagai writer utama untuk quest journal.
- Merge yang stabil adalah `DailyEngagementSystem` yang membangun payload quest dengan `active`, `completed`, `weekly`, dan `story`.
- Jika dokumentasi lama menyebut alur terpisah, dokumentasi itu yang perlu disesuaikan, bukan membatalkan merge stabil yang sudah bekerja di client.

## Verified Client Result

Hasil screenshot dan inspeksi live client:
- Panel Quest Journal tampil normal
- Tab `DAILY`, `WEEKLY`, dan `STORY` bisa dibuka
- Card mission muncul di viewport

## Mission Content

### Daily

1. `Tetap Tenang`
   - Id: `dm_sanity_managed`
   - Progress: `0 / 2`
2. `Ikut Investigasi`
   - Id: `dm_play_match`
   - Progress: `0 / 2`
3. `Pergi Bersama`
   - Id: `dm_play_with_party`
   - Progress: `0 / 2`
4. `Tiga Bukti`
   - Id: `dc_all_evidence`
   - Progress: `0 / 1`

### Weekly

1. `Selesaikan Investigasi`
   - Id: `complete_investigations`
   - Progress: `0 / 10`
2. `Bertahan dari Hunt`
   - Id: `survive_hunts_weekly`
   - Progress: `0 / 6`
3. `Kuasai Bukti`
   - Id: `evidence_mastery`
   - Progress: `0 / 24`
4. `Identifikasi Hantu`
   - Id: `identify_ghosts_weekly`
   - Progress: `0 / 8`

### Story

1. `Awal yang Gelap`
   - Id: `chapter_1_act_1`
   - Progress: `0 / 3`
2. `Mengenal Lawsuit`
   - Id: `chapter_1_act_2`
   - Progress: `0 / 2`
3. `Di Balik Pintu`
   - Id: `chapter_2_act_1`
   - Progress: `0 / 10`

## Cleanup

Debug startup prints yang dibersihkan:
- `src/ServerScriptService/Server/DailyEngagementSystem/Controller.lua`
- `src/ServerScriptService/Server/DailyEngagementSystem/Main.lua`

## Notes For Future Changes

- Kalau ada revisi dokumentasi quest, update referensi terhadap writer stabil `DailyEngagementSystem.Service`.
- Jangan menulis ulang payload quest dari sistem lain tanpa alasan yang jelas.
- Weekly, story, dan daily harus tetap diverifikasi di client, bukan hanya dari log runtime.

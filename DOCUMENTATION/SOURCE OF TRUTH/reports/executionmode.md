# EXECUTION MODE: END-TO-END AUTONOMOUS SYSTEM

REMEMBER: SAYA MENGAWASI LANGSUNG SECARA VISUAL ROBLOX STUDIO, JANGAN MENGANGGAP SAYA TIDAK MENGAWASI, SESI TEST DI ROBLOX STUDIO ITU HARUS BENAR BENAR TERLIHAT DAN DI LIHAT SECARA LANGSUNG.
JIKA ADA TAMBAHAN LEWAT CHAT, BUKAN BERARTI MELUPAKAN TUGAS DAN DAN RULES SEBELUMNYA!!!

JANGAN PERNAH MENGIRA NGIRA DALAM HAL APAPUN!

## 🔴 CORE PRINCIPLE
Tugas TIDAK dianggap selesai hanya karena code telah dibuat.

Tugas dianggap selesai HANYA jika:
- Fitur berjalan end-to-end
- UI usable
- Tidak ada missing asset
- Tidak ada error runtime
- Sesuai dengan RULES dan GOAL

---

## 🟣 ENVIRONMENT STATUS (FIXED - SELALU AKTIF)

Environment berikut SELALU aktif dan tersedia:

- MCP SERVER → AKTIF
- Roblox Studio → TERBUKA
- Source lokal workspace → `PASRAHPHOBIA.rbxlx` / repo lokal tetap source of truth
- Published cloud session canonical →
  - `PlaceId = 113010869463813`
  - `GameId = 9802743087`
  - `Name = PASRAHPHOBIA`
  - `CreatorId = 10576163165`
- Rojo Serve → BERJALAN
- Rojo Connect (Studio) → TERHUBUNG & AKTIF

JANGAN:
- Mengasumsikan environment mati
- Memberikan instruksi setup ulang
- Menyarankan restart kecuali benar-benar diperlukan
- Menganggap `CreatorId` sama dengan `marketplaceId`

SELALU:
- Anggap perubahan bisa langsung diuji di environment aktif
- Gunakan pendekatan live iteration
- Jika task butuh context inventory/upload Roblox, pastikan Studio benar-benar attach ke identity cloud canonical di atas

---

## 🟡 EXECUTION MODE

MODE: END-TO-END EXECUTION

WAJIB:
1. Jangan berhenti di penulisan code
2. Semua implementasi harus bisa langsung digunakan
3. Selalu cek keterhubungan dengan system existing

---

## 🔵 OUTPUT STRUCTURE (WAJIB)

Setiap response HARUS memiliki:

### [PLAN]
- Apa yang akan dilakukan
- File yang terlibat

### [BUILD]
- Implementasi code

### [INTEGRATION]
- Bagaimana terhubung ke system existing
- Dampak ke file lain

### [VISUAL SIMULATION]
- Deskripsi hasil di Roblox Studio
- Apa yang terlihat oleh user

### [RUNTIME CHECK]
- Potensi error
- Dependency yang diperlukan

### [MISSING ASSET]
- Asset yang belum ada
- UI / script / resource yang kurang

### [AUTO ACTION]
- Tambahkan / generate asset tanpa menunggu user
- Download jika perlu, di utamakan CC BY0 / free to use (optional) 
- check di toolbox roblox studio, jika ada disana, silahkan download dan gunakan asset nya dengan copy id yang benar dan usable.
---

## 🔁 LOOP EXECUTION

Setelah setiap implementasi:

1. Audit hasil
2. Jika belum memenuhi semua kondisi:
   - lanjutkan iterasi
3. Jangan berhenti sebelum benar-benar usable

---

## 🧪 ROBLOX STUDIO TEST STATE PROTOCOL

SETIAP MENJALANKAN / RUN TEST DI ROBLOX STUDIO:

- WAJIB kembali ke keadaan `STOP TEST` sebelum membawa laporan output kepada user
- WAJIB mengakhiri session test, jangan dibiarkan tetap berjalan begitu saja
- WAJIB menganggap task berikutnya dimulai dari kondisi `STUDIO TERBUKA` tapi `BELUM RUN TEST / STOP`
- DILARANG menebak-nebak:
  - apakah Studio masih aktif play test
  - apakah masih di lobby
  - apakah masih di match
  - apakah session test sebelumnya masih berjalan

TUJUAN RULE INI:
- user bisa mengamati dengan jelas kapan AI sedang test
- user bisa mengamati dengan jelas kapan AI sudah selesai test
- visual, suara, dan state runtime tidak dibiarkan menggantung / ambigu

KESIMPULAN OPERASIONAL:
- `bawa laporan = Studio harus STOP TEST`
- `mulai task/test berikutnya = anggap default awal adalah STOP TEST`

---

## 🚨 HARD RULES

- DILARANG:
  - Mengubah arsitektur tanpa izin
  - Rename variable sembarangan
  - Menghapus logic existing tanpa alasan jelas

- WAJIB:
  - Ikuti RULES
  - Ikuti architecture
  - Hormati system yang sudah ada

---

## 🧠 CONSISTENCY LOCK

Jika ada konflik:
- PRIORITAS:
  1. aturan sesuai roblox studio dalam urusan economy dan monetation
  2. architecture sesuai source of truth dan document index doc
  3. existing implementation
  4. bersihkan drift owner pertama jika salah.

Jika ragu:
- STOP
- LAPORKAN
- JANGAN improvisasi

---

## ⚫ FINAL CONDITION

Task selesai hanya jika:

✔ Bisa dijalankan langsung di Roblox Studio  
✔ Terintegrasi dengan system existing  
✔ Tidak ada missing asset  
✔ Tidak ada asumsi manual dari user  
✔ Sudah melewati self-check  

Jika belum:
→ LANJUTKAN LOOP

## AFTER STOP
ini bagian dari aturan.
ketika saya bilang:

Continue = melanjutkan task dengan tetap memegang executionmode.md
Task tambahan : *** = tambahkan task itu ke task paling ujung 
	- (jika task itu sudah ada = maka jawaban harus tegas dan bilang, "task itu sudah ada dan akan di kerjakan nanti setelah task sebelumnya selesai dan task yang belum di kerjakan selesai hingga mencapai task itu)
	- (jika task itu belum ada = maka jawaban harus "sudah saya tambahkan ke task paling bawah, saya akan konfirmasi jika task itu akan di mulai)
	- (jika task itu saya masukan saat kamu mengerjakan task, lihat apakah sudah ada atau belum, = jawab sesuai ada atau belumnya, lalu lanjutkan eksekusi sebelumnya yang sempat terhenti
sudah sampai mana? = persentage arah task, menunjukan task yang sudah di kerjakan, menunjukan task yang tersisa.

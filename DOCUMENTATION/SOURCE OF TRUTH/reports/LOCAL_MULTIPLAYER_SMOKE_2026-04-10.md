# LOCAL_MULTIPLAYER_SMOKE_2026-04-10

## Tujuan

Dokumen ini mencatat precheck multiplayer lokal yang dijalankan lewat `Test -> Server + 2 Clients` di Roblox Studio pada `2026-04-10`.

Status dokumen ini bukan pengganti gate publish manual `2` client nyata. Fungsinya hanya untuk membuktikan bahwa flow dasar room browser dan transisi masuk match masih sehat di build lokal aktif.

## Setup

- Studio source: `PASRAHPHOBIA.rbxlx` lokal
- Mode test: `Server + 2 Clients`
- Harness Studio-only ditambahkan di `src/StarterPlayerScripts/StudioRoomSmoke.client.lua`
- Harness aktif hanya jika:
  - `RunService:IsStudio()`
  - `ReplicatedStorage.PasrahAutoRoomSmoke == true`
- Trace opsional memakai `ReplicatedStorage.PasrahRoomTrace`

## Flow Harness

- `Player1`:
  - request snapshot + room list
  - `SelectMode("Classic")`
  - `SelectMap("HauntedHouse")`
  - `CreateRoom()`
  - jika `allReady == true`, kirim `HostStart(...)`
- `Player2`:
  - request snapshot + room list
  - cari room dengan `playerCount >= 1`
  - `JoinRoom(roomId)`
  - `SetReady(true)` setelah join

Harness tidak aktif di runtime publish/non-Studio.

## Hasil Observasi

- Spawn `Server + 2 Clients` berhasil setelah relaunch clean.
- Kedua client test berhasil masuk ke match interior yang sama tanpa input UI manual tambahan.
- Bukti visual lokal yang diambil selama run:
  - `.codex/client_8988_after_smoke_wait.png`
  - `.codex/client_26936_after_smoke_wait.png`
  - `.codex/server_10152_after_smoke_wait.png`
- Capture client menunjukkan:
  - kedua client sudah keluar dari lobby
  - kedua client sudah berada di interior map yang sama
  - satu client melihat avatar client lain di posisi yang sinkron
- Probe runtime tambahan:
  - `get_console_output` tidak menunjukkan fatal error baru pada boot/run lokal ini
  - `DataPersistenceService` tetap mock/in-memory seperti expected untuk Studio lokal

## Interpretasi

- Flow lokal berikut dinyatakan sehat:
  - create room
  - join room
  - ready state
  - host start
  - transisi dua client dari lobby ke match
- Dokumen ini belum menutup gate publish manual karena belum mencakup:
  - `2` Roblox client nyata di luar Studio local simulation
  - checklist multiplayer penuh end-to-end hasil/result panel
  - persistence target non-mock

## Result

- `LOCAL MULTIPLAYER SMOKE PRECHECK: PASS`
- `FINAL MULTIPLAYER PUBLISH GATE: STILL PENDING`

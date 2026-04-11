# Respawn Guard And Forced Reset Fix 2026-04-11

## Trigger

Setelah run multiplayer `2` client nyata, owner melaporkan `2` blocker in-game yang tidak tercakup oleh flow core sebelumnya:

1. selama match aktif, reset/respawn bawaan Roblox masih tersedia padahal harus dimatikan
2. ketika forced respawn dipicu pada kondisi pemain terakhir masih hidup, hasilnya bisa jatuh ke `falling loop` alih-alih menutup match dan masuk hasil investigasi dengan benar

## Root Cause

### Client

- tidak ada guard yang mematikan `StarterGui:SetCore("ResetButtonCallback", false)` saat `InMatch`
- akibatnya pemain masih bisa memicu reset bawaan Roblox dari menu sistem

### Server

- `DeathEventBridge` sebelumnya memanggil `DeathStateSystem:HandleEvent("PlayerDied", ...)` secara langsung
- jalur itu memang cukup untuk state lokal `spectator/death`, tetapi **bukan** jalur kanonik `EventBus`
- akibatnya system lain yang memang subscribe ke `PlayerDied`, terutama:
  - `PlayerDeathSystem`
  - `MatchSystem`
  tidak selalu menerima forced reset sebagai eliminasi penuh
- dampak praktisnya: spectator bisa aktif, tetapi match tidak selalu ditutup sebagai `team_eliminated`, sehingga karakter baru bisa jatuh ke loop tidak valid

## Code Changes

### Client

- file baru:
  - `src/client/RespawnGuard/Main.lua`
- bootstrap:
  - `src/client/Core/ClientBootstrap.lua`

Perilaku baru:

- saat `InMatch=true` atau `MatchId` masih ada:
  - `ResetButtonCallback` di-set ke `false`
- saat player sudah keluar dari match:
  - reset bawaan Roblox di-enable kembali
- runtime stamp:
  - `PasrahResetGuardOwner`
  - `PasrahResetGuardDisabled`
  - `PasrahResetGuardSetCoreReady`

### Server

- `src/ServerScriptService/Server/DeathStateSystem/Service.lua`
  - tambah `PublishPlayerDied(payload)` untuk publish event kanonik ke `EventBus`
- `src/ServerScriptService/Server/DeathStateSystem/DeathEventBridge.lua`
  - `Humanoid.Died` sekarang publish `PlayerDied` lewat jalur kanonik, bukan hanya panggil `HandleEvent(...)` lokal

Perilaku baru:

- forced reset / character death dari bridge sekarang masuk ke:
  - `DeathStateSystem`
  - `PlayerDeathSystem`
  - `MatchSystem`
  secara konsisten melalui event yang sama

## Studio Verification

Environment yang diverifikasi:

- cloud canonical Studio session
  - `PlaceId = 113010869463813`
  - `GameId = 9802743087`

Verifikasi live:

- `RespawnGuard` muncul di live Studio tree:
  - `game.StarterPlayer.StarterPlayerScripts.Client.RespawnGuard.Main`
- `ClientBootstrap` live sudah register `RespawnGuard`
- `DeathEventBridge` live sudah memakai `PublishPlayerDied(...)`
- playtest dijalankan lalu **dikembalikan ke `STOP TEST`**

Probe client saat play:

- bootstrap:
  - `PasrahClientBootstrapStage = started`
- sebelum mock in-match:
  - `PasrahResetGuardOwner = RespawnGuard`
  - `PasrahResetGuardSetCoreReady = true`
- saat `InMatch=true` dan `MatchId` di-set:
  - `PasrahResetGuardDisabled = true`
- saat keluar dari match:
  - `PasrahResetGuardDisabled = false`

## Roblox Reference

- `StarterGui:SetCore("ResetButtonCallback", ...)` mendukung boolean untuk menjaga atau mematikan perilaku default reset button
- doc juga menegaskan `SetCore()` kadang perlu dipanggil ulang dengan `pcall()` sampai core script siap

Reference:

- https://robloxapi.github.io/ref/class/StarterGui.html

## Status

- reset guard client: `PASS`
- canonical forced-death routing in source: `PASS`
- cloud Studio sync verification: `PASS`
- final real `2`-client forced-reset retest: `PENDING`

## Conclusion

- bug sekarang sudah dipatch pada akar masalah client dan server
- tetapi lane multiplayer manual harus dianggap **reopened untuk edge-case forced reset** sampai ada rerun real-client yang memastikan:
  - reset bawaan Roblox memang tidak tersedia selama match
  - jika reset paksa tetap lolos karena kondisi platform tertentu, match berakhir benar dan tidak masuk `falling loop`

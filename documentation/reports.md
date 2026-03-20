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


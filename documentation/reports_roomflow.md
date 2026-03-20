# Reports Room Flow

## Technical Notes
- Countdown source of truth sekarang di server (LobbySystem/Controller + LobbySystem/Service).
- BeginHostStart hanya lock room/start countdown; CommitHostStart baru enqueue party.
- RoomManager:SetInGame(roomId, value, preserveReady) dipakai untuk cancel aman tanpa menghapus ready state.
- Client countdown digerakkan event (RoomMatchCountdown) agar sinkron antar player.

## Edge Cases Handled
- Leave/disconnect saat countdown: countdown dihentikan dan room unlock.
- Host start saat belum all-ready: ditolak server.
- Password bukan 4 digit: ditolak server.

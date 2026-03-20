local SpectatorUIMessageCatalog = {}

SpectatorUIMessageCatalog.Spectator = {
    center = {
        title = "PLAYER DEAD - SPECTATOR",
        subtitle = "Kematian menipumu, yang kamu lihat belum tentu benar.",
        durationSeconds = 5,
    },
    pinned = {
        anchor = "left",
        title = "PLAYER DEAD - SPECTATOR",
        subtitle = "Kematian menipumu, yang kamu lihat belum tentu benar.",
        persistUntil = "endgame",
    },
}

SpectatorUIMessageCatalog.Living = {
    center = {
        title = "",
        subtitle = "Jangan terlalu percaya orang mati. Gunakan instingmu.",
        durationSeconds = 5,
    },
}

function SpectatorUIMessageCatalog:GetForSpectator()
    return self.Spectator
end

function SpectatorUIMessageCatalog:GetForLiving()
    return self.Living
end

return SpectatorUIMessageCatalog

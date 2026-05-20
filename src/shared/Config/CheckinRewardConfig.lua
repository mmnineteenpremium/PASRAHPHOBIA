local CheckinRewardConfig = {}

CheckinRewardConfig.STREAK_7 = {
	[1] = { mm = 100, xp = 50, pp = 0, title = "Hari 1 - Selamat Datang", icon = "candle" },
	[2] = { mm = 150, xp = 70, pp = 0, title = "Hari 2 - Kamu Kembali", icon = "eye" },
	[3] = { mm = 200, xp = 100, pp = 0, title = "Hari 3 - Setengah Jalan", icon = "flashlight" },
	[4] = { mm = 250, xp = 120, pp = 1, title = "Hari 4 - Makin Berani", icon = "key" },
	[5] = { mm = 300, xp = 150, pp = 1, title = "Hari 5 - Hampir Sampai", icon = "journal" },
	[6] = { mm = 400, xp = 200, pp = 1, title = "Hari 6 - Satu Lagi", icon = "orb" },
	[7] = {
		mm = 800,
		xp = 400,
		pp = 5,
		cosmeticId = "title_investigator_setia",
		title = "Hari 7 - Kamu Bertahan",
		icon = "star",
		isStreakBonus = true,
	},
}

CheckinRewardConfig.MILESTONE_30 = {
	[5] = { mm = 500, xp = 250, pp = 0, title = "5 Hari - Mulai Terasa", icon = "candle" },
	[10] = {
		mm = 1000,
		xp = 500,
		pp = 2,
		cosmeticId = "border_haunted_frame",
		title = "10 Hari - Sudah Terbiasa",
		icon = "flashlight",
	},
	[15] = { mm = 1500, xp = 750, pp = 3, title = "15 Hari - Setengah Bulan", icon = "eye" },
	[20] = {
		mm = 2000,
		xp = 1000,
		pp = 5,
		cosmeticId = "emote_pasrah_bow",
		title = "20 Hari - Hampir Sebulan",
		icon = "orb",
	},
	[25] = { mm = 2500, xp = 1200, pp = 5, title = "25 Hari - Nyaris Sampai", icon = "key" },
	[30] = {
		mm = 5000,
		xp = 2500,
		pp = 15,
		cosmeticId = "title_penyintas_sejati",
		gachaTickets = 3,
		title = "30 Hari - Penyintas Sejati",
		icon = "trophy",
		isMilestoneBonus = true,
	},
}

CheckinRewardConfig.STREAK_MULTIPLIER = {
	[7] = 1.10,
	[14] = 1.20,
	[21] = 1.30,
	[28] = 1.50,
}

CheckinRewardConfig.RESET_HOUR_UTC = 0

return CheckinRewardConfig

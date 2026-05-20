local DailyMissionConfig = {}

DailyMissionConfig.DAILY_POOL = {
	{
		id = "dm_play_match",
		title = "Ikut Investigasi",
		desc = "Selesaikan {target} match apapun.",
		type = "MATCH_COMPLETE",
		targets = { 1, 2, 3 },
		xpReward = { 50, 80, 120 },
		mmReward = { 100, 160, 240 },
		category = "MATCH",
		icon = "flashlight",
	},
	{
		id = "dm_survive_hunt",
		title = "Lari dari Bayangan",
		desc = "Selamat dari {target} hunt tanpa mati.",
		type = "SURVIVE_HUNT",
		targets = { 1, 2, 3 },
		xpReward = { 80, 130, 200 },
		mmReward = { 150, 240, 380 },
		category = "SURVIVAL",
		icon = "eye",
	},
	{
		id = "dm_identify_ghost",
		title = "Kenali Sosok Itu",
		desc = "Identifikasi ghost dengan benar {target} kali.",
		type = "GHOST_IDENTIFIED",
		targets = { 1, 2, 3 },
		xpReward = { 100, 160, 240 },
		mmReward = { 200, 320, 480 },
		category = "INVESTIGATION",
		icon = "journal",
	},
	{
		id = "dm_collect_evidence",
		title = "Kumpulkan Bukti",
		desc = "Kumpulkan {target} evidence dalam 1 match.",
		type = "EVIDENCE_COLLECTED",
		targets = { 1, 2, 3 },
		xpReward = { 60, 100, 160 },
		mmReward = { 120, 200, 320 },
		category = "INVESTIGATION",
		icon = "search",
		singleMatch = true,
	},
	{
		id = "dm_play_with_party",
		title = "Pergi Bersama",
		desc = "Selesaikan match dengan minimal {target} teman.",
		type = "MATCH_WITH_PARTY",
		targets = { 1, 2, 3 },
		xpReward = { 70, 120, 180 },
		mmReward = { 140, 240, 360 },
		category = "SOCIAL",
		icon = "party",
	},
	{
		id = "dm_host_room",
		title = "Jadi Pemimpin",
		desc = "Buat room dan host {target} match.",
		type = "HOST_MATCH",
		targets = { 1, 1, 2 },
		xpReward = { 60, 60, 110 },
		mmReward = { 120, 120, 220 },
		category = "SOCIAL",
		icon = "home",
	},
	{
		id = "dm_use_tool",
		title = "Ahli Peralatan",
		desc = "Gunakan tool sebanyak {target} kali.",
		type = "TOOL_USED",
		targets = { 5, 10, 20 },
		xpReward = { 40, 70, 120 },
		mmReward = { 80, 140, 240 },
		category = "SKILL",
		icon = "tool",
	},
	{
		id = "dm_hide_closet",
		title = "Sembunyi",
		desc = "Berhasil bersembunyi {target} kali saat hunt.",
		type = "HIDE_SUCCESS",
		targets = { 1, 2, 4 },
		xpReward = { 70, 120, 200 },
		mmReward = { 140, 240, 400 },
		category = "SKILL",
		icon = "door",
	},
	{
		id = "dm_sanity_managed",
		title = "Tetap Tenang",
		desc = "Selesaikan match dengan sanity di atas 50.",
		type = "FINISH_HIGH_SANITY",
		targets = { 1, 2, 3 },
		xpReward = { 80, 140, 210 },
		mmReward = { 160, 280, 420 },
		category = "SKILL",
		icon = "sanity",
		threshold = 50,
	},
	{
		id = "dm_no_death",
		title = "Tidak Tersentuh",
		desc = "Selesaikan {target} match tanpa mati sekali pun.",
		type = "MATCH_NO_DEATH",
		targets = { 1, 1, 2 },
		xpReward = { 120, 120, 220 },
		mmReward = { 240, 240, 440 },
		category = "SKILL",
		icon = "skull",
	},
	{
		id = "dm_play_haunted",
		title = "Masuk ke Rumah Itu",
		desc = "Mainkan match di HauntedHouse sebanyak {target} kali.",
		type = "MATCH_ON_MAP",
		targets = { 1, 2, 3 },
		xpReward = { 60, 110, 170 },
		mmReward = { 120, 220, 340 },
		category = "EXPLORATION",
		icon = "map",
		mapId = "HauntedHouse",
	},
	{
		id = "dm_play_ranked",
		title = "Buktikan Dirimu",
		desc = "Main {target} match Ranked.",
		type = "RANKED_MATCH",
		targets = { 1, 2, 3 },
		xpReward = { 100, 170, 260 },
		mmReward = { 200, 340, 520 },
		category = "RANKED",
		icon = "trophy",
		requiresUnlock = "Ranked",
	},
}

DailyMissionConfig.CHALLENGE_POOL = {
	{
		id = "dc_nightmare_survivor",
		title = "Mimpi Buruk",
		desc = "Selesaikan 1 match di difficulty Hard atau Nightmare.",
		type = "MATCH_DIFFICULTY",
		target = 1,
		xpReward = 300,
		mmReward = 600,
		ppReward = 2,
		icon = "skull",
		minDifficulty = "Hard",
	},
	{
		id = "dc_perfect_investigation",
		title = "Detektif Sempurna",
		desc = "Identifikasi ghost dengan benar dan semua player selamat dalam 1 match.",
		type = "PERFECT_MATCH",
		target = 1,
		xpReward = 350,
		mmReward = 700,
		ppReward = 2,
		icon = "star",
	},
	{
		id = "dc_all_evidence",
		title = "Tiga Bukti",
		desc = "Kumpulkan semua 3 evidence dalam 1 match.",
		type = "ALL_EVIDENCE_IN_MATCH",
		target = 1,
		xpReward = 280,
		mmReward = 560,
		ppReward = 1,
		icon = "lab",
	},
	{
		id = "dc_streak_match",
		title = "Tak Tertaklukkan",
		desc = "Menangkan 3 match berturut-turut tanpa kalah.",
		type = "WIN_STREAK",
		target = 3,
		xpReward = 400,
		mmReward = 800,
		ppReward = 3,
		icon = "streak",
	},
	{
		id = "dc_ghost_whisperer",
		title = "Pendengar Bisikan",
		desc = "Gunakan 5 jenis tool berbeda dalam 1 match.",
		type = "TOOLS_VARIETY",
		target = 5,
		xpReward = 260,
		mmReward = 520,
		ppReward = 1,
		icon = "target",
	},
	{
		id = "dc_solo_survivor",
		title = "Sendiri di Kegelapan",
		desc = "Selesaikan 1 match solo di map apapun.",
		type = "SOLO_MATCH_COMPLETE",
		target = 1,
		xpReward = 320,
		mmReward = 640,
		ppReward = 2,
		icon = "candle",
	},
}

function DailyMissionConfig.GetTodaysMissions(dateString)
	local seed = 0
	for i = 1, #dateString do
		seed += string.byte(dateString, i) * i
	end

	local pool = DailyMissionConfig.DAILY_POOL
	local chosen = {}
	local used = {}
	local rng = seed

	for _ = 1, 3 do
		local attempts = 0
		repeat
			rng = (rng * 1103515245 + 12345) % 2147483648
			local idx = (rng % #pool) + 1
			attempts += 1
			if not used[idx] then
				used[idx] = true
				local dayNum = tonumber(dateString:sub(7, 8)) or 1
				local diffIdx = (dayNum % 3) + 1
				local mission = pool[idx]
				local target = mission.targets[diffIdx] or mission.targets[1]
				table.insert(chosen, {
					id = mission.id,
					title = mission.title,
					desc = mission.desc:gsub("{target}", tostring(target)),
					type = mission.type,
					target = target,
					xp = mission.xpReward[diffIdx] or mission.xpReward[1],
					mm = mission.mmReward[diffIdx] or mission.mmReward[1],
					icon = mission.icon,
					category = mission.category,
					singleMatch = mission.singleMatch or false,
					mapId = mission.mapId,
					threshold = mission.threshold,
					requiresUnlock = mission.requiresUnlock,
				})
				break
			end
		until attempts > 20
	end

	rng = (rng * 1103515245 + 12345) % 2147483648
	local challengeIdx = (rng % #DailyMissionConfig.CHALLENGE_POOL) + 1
	local c = DailyMissionConfig.CHALLENGE_POOL[challengeIdx]
	table.insert(chosen, {
		id = c.id,
		title = c.title,
		desc = c.desc,
		type = c.type,
		target = c.target,
		xp = c.xpReward,
		mm = c.mmReward,
		pp = c.ppReward or 0,
		icon = c.icon,
		isChallenge = true,
		minDifficulty = c.minDifficulty,
	})

	return chosen
end

return DailyMissionConfig

local RoyalPassConfig = {}

RoyalPassConfig.SEASON_DURATION_DAYS = 60
RoyalPassConfig.TOTAL_TIERS = 60
RoyalPassConfig.PREMIUM_PRICE_ROBUX = 299
RoyalPassConfig.XP_PER_TIER = 1000
RoyalPassConfig.SEASON_ID = "S1"

RoyalPassConfig.XP_SOURCES = {
	MATCH_COMPLETE = 100,
	GHOST_IDENTIFIED = 150,
	DAILY_MISSION_DONE = 200,
	CHALLENGE_DONE = 350,
	ALL_3_TASKS_BONUS = 150,
	RANKED_WIN = 180,
	CHECKIN = 150,
}

RoyalPassConfig.TIERS = {}

local function rewardForTier(tierIndex)
	local free = {}
	local premium = {}

	if tierIndex % 2 == 0 then
		free.xp = 80 + (tierIndex * 10)
		premium.xp = free.xp * 2
		premium.mm = 100 + (tierIndex * 25)
	else
		free.mm = 80 + (tierIndex * 25)
		premium.mm = free.mm * 2
		premium.xp = 40 + (tierIndex * 10)
	end

	if tierIndex % 5 == 0 then
		free.cosmeticId = "royal_free_tier_" .. tostring(tierIndex)
		premium.cosmeticId = "royal_premium_tier_" .. tostring(tierIndex)
		premium.pp = math.floor(tierIndex / 5) + 1
	end

	if tierIndex % 10 == 0 then
		free.mm = (free.mm or 0) + (tierIndex * 60)
		free.gachaTickets = math.floor(tierIndex / 10)
		premium.mm = (premium.mm or 0) + (tierIndex * 120)
		premium.gachaTickets = math.floor(tierIndex / 5)
		premium.pp = (premium.pp or 0) + math.floor(tierIndex / 2)
	end

	if tierIndex == RoyalPassConfig.TOTAL_TIERS then
		free.mm = 5000
		free.gachaTickets = 5
		free.cosmeticId = "title_legenda_pasrahphobia"
		free.seasonBadgeId = "badge_season_complete_free"
		premium.mm = 10000
		premium.gachaTickets = 10
		premium.pp = 50
		premium.cosmeticId = "outfit_sang_ahli_season_exclusive"
		premium.seasonBadgeId = "badge_season_complete_premium"
		premium.exclusiveEmoteId = "emote_pasrah_ascend"
	end

	return free, premium
end

for tierIndex = 1, RoyalPassConfig.TOTAL_TIERS do
	local freeReward, premiumReward = rewardForTier(tierIndex)
	RoyalPassConfig.TIERS[tierIndex] = {
		tier = tierIndex,
		free = freeReward,
		premium = premiumReward,
	}
end

return RoyalPassConfig

local GachaConfig = {}

GachaConfig.SOFT_PITY_START = 40
GachaConfig.HARD_PITY = 50
GachaConfig.GUARANTEED_EPIC = 10

GachaConfig.BASE_RATES = {
	LEGENDARY = 0.02,
	EPIC = 0.08,
	RARE = 0.25,
	COMMON = 0.65,
}

GachaConfig.SOFT_PITY_MULTIPLIER = 0.08

GachaConfig.SINGLE_PULL_MM = 1500
GachaConfig.TEN_PULL_MM = 13500
GachaConfig.SINGLE_PULL_TICKET = 1
GachaConfig.TEN_PULL_TICKET = 10

GachaConfig.POOL = {
	{
		id = "gacha_leg_outfit_kuntilanak",
		name = "Busana Kuntilanak",
		rarity = "LEGENDARY",
		type = "outfit",
		desc = "Kostum eksklusif terinspirasi dari Kuntilanak.",
		season = 1,
	},
	{
		id = "gacha_leg_emote_float_spirit",
		name = "Emote: Mengambang Jiwa",
		rarity = "LEGENDARY",
		type = "emote",
		season = 1,
	},
	{
		id = "gacha_leg_title_sang_legenda",
		name = "Title: Sang Legenda",
		rarity = "LEGENDARY",
		type = "title",
		season = 1,
	},
	{
		id = "gacha_leg_border_genderuwo_aura",
		name = "Border: Aura Genderuwo",
		rarity = "LEGENDARY",
		type = "border",
		season = 1,
	},
	{ id = "gacha_epic_outfit_pocong_shroud", name = "Jubah Pocong", rarity = "EPIC", type = "outfit", season = 1 },
	{ id = "gacha_epic_emote_ghost_laugh", name = "Emote: Tawa Hantu", rarity = "EPIC", type = "emote", season = 1 },
	{ id = "gacha_epic_title_arwah_penasaran", name = "Title: Arwah Penasaran", rarity = "EPIC", type = "title", season = 1 },
	{ id = "gacha_epic_border_ritual_circle", name = "Border: Lingkaran Ritual", rarity = "EPIC", type = "border", season = 1 },
	{ id = "gacha_epic_accessory_ghost_lantern", name = "Aksesoris: Lentera Arwah", rarity = "EPIC", type = "accessory", season = 1 },
	{ id = "gacha_rare_title_pemberani", name = "Title: Si Pemberani", rarity = "RARE", type = "title", season = 1 },
	{ id = "gacha_rare_border_misty_fog", name = "Border: Kabut Malam", rarity = "RARE", type = "border", season = 1 },
	{ id = "gacha_rare_emote_scared_hop", name = "Emote: Lompat Kaget", rarity = "RARE", type = "emote", season = 1 },
	{ id = "gacha_rare_accessory_ghost_charm", name = "Aksesoris: Jimat Hantu", rarity = "RARE", type = "accessory", season = 1 },
	{ id = "gacha_rare_title_pencari_tanda", name = "Title: Pencari Tanda", rarity = "RARE", type = "title", season = 1 },
	{ id = "gacha_com_mm_100", name = "100 M-Money", rarity = "COMMON", type = "currency", mm = 100, season = 1 },
	{ id = "gacha_com_mm_200", name = "200 M-Money", rarity = "COMMON", type = "currency", mm = 200, season = 1 },
	{ id = "gacha_com_title_penyelidik", name = "Title: Penyelidik", rarity = "COMMON", type = "title", season = 1 },
	{ id = "gacha_com_border_basic_dark", name = "Border: Gelap Dasar", rarity = "COMMON", type = "border", season = 1 },
}

GachaConfig.ByID = {}
for _, item in ipairs(GachaConfig.POOL) do
	GachaConfig.ByID[item.id] = item
end

GachaConfig.ByRarity = { LEGENDARY = {}, EPIC = {}, RARE = {}, COMMON = {} }
for _, item in ipairs(GachaConfig.POOL) do
	table.insert(GachaConfig.ByRarity[item.rarity], item)
end

return GachaConfig

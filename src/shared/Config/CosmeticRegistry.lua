local CosmeticRegistry = {}

local RAW_ENTRIES = {
	{
		rewardId = "royal_free_tier_5",
		type = "cosmetic",
		track = "FREE",
		sourceKey = "cosmeticId",
		tier = 5,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_free_tier_5_concept.png",
			icon_png = "assets/icons/royal_free_tier_5_icon.png",
			model_fbx = "assets/models/fbx/royal_free_tier_5_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_free_tier_5_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_free_tier_5_diffuse.png",
		},
	},
	{
		rewardId = "royal_premium_tier_5",
		type = "cosmetic",
		track = "PREMIUM",
		sourceKey = "cosmeticId",
		tier = 5,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_premium_tier_5_concept.png",
			icon_png = "assets/icons/royal_premium_tier_5_icon.png",
			model_fbx = "assets/models/fbx/royal_premium_tier_5_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_premium_tier_5_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_premium_tier_5_diffuse.png",
		},
	},
	{
		rewardId = "royal_free_tier_10",
		type = "cosmetic",
		track = "FREE",
		sourceKey = "cosmeticId",
		tier = 10,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_free_tier_10_concept.png",
			icon_png = "assets/icons/royal_free_tier_10_icon.png",
			model_fbx = "assets/models/fbx/royal_free_tier_10_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_free_tier_10_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_free_tier_10_diffuse.png",
		},
	},
	{
		rewardId = "royal_premium_tier_10",
		type = "cosmetic",
		track = "PREMIUM",
		sourceKey = "cosmeticId",
		tier = 10,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_premium_tier_10_concept.png",
			icon_png = "assets/icons/royal_premium_tier_10_icon.png",
			model_fbx = "assets/models/fbx/royal_premium_tier_10_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_premium_tier_10_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_premium_tier_10_diffuse.png",
		},
	},
	{
		rewardId = "royal_free_tier_15",
		type = "cosmetic",
		track = "FREE",
		sourceKey = "cosmeticId",
		tier = 15,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_free_tier_15_concept.png",
			icon_png = "assets/icons/royal_free_tier_15_icon.png",
			model_fbx = "assets/models/fbx/royal_free_tier_15_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_free_tier_15_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_free_tier_15_diffuse.png",
		},
	},
	{
		rewardId = "royal_premium_tier_15",
		type = "cosmetic",
		track = "PREMIUM",
		sourceKey = "cosmeticId",
		tier = 15,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_premium_tier_15_concept.png",
			icon_png = "assets/icons/royal_premium_tier_15_icon.png",
			model_fbx = "assets/models/fbx/royal_premium_tier_15_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_premium_tier_15_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_premium_tier_15_diffuse.png",
		},
	},
	{
		rewardId = "royal_free_tier_20",
		type = "cosmetic",
		track = "FREE",
		sourceKey = "cosmeticId",
		tier = 20,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_free_tier_20_concept.png",
			icon_png = "assets/icons/royal_free_tier_20_icon.png",
			model_fbx = "assets/models/fbx/royal_free_tier_20_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_free_tier_20_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_free_tier_20_diffuse.png",
		},
	},
	{
		rewardId = "royal_premium_tier_20",
		type = "cosmetic",
		track = "PREMIUM",
		sourceKey = "cosmeticId",
		tier = 20,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_premium_tier_20_concept.png",
			icon_png = "assets/icons/royal_premium_tier_20_icon.png",
			model_fbx = "assets/models/fbx/royal_premium_tier_20_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_premium_tier_20_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_premium_tier_20_diffuse.png",
		},
	},
	{
		rewardId = "royal_free_tier_25",
		type = "cosmetic",
		track = "FREE",
		sourceKey = "cosmeticId",
		tier = 25,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_free_tier_25_concept.png",
			icon_png = "assets/icons/royal_free_tier_25_icon.png",
			model_fbx = "assets/models/fbx/royal_free_tier_25_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_free_tier_25_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_free_tier_25_diffuse.png",
		},
	},
	{
		rewardId = "royal_premium_tier_25",
		type = "cosmetic",
		track = "PREMIUM",
		sourceKey = "cosmeticId",
		tier = 25,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_premium_tier_25_concept.png",
			icon_png = "assets/icons/royal_premium_tier_25_icon.png",
			model_fbx = "assets/models/fbx/royal_premium_tier_25_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_premium_tier_25_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_premium_tier_25_diffuse.png",
		},
	},
	{
		rewardId = "royal_free_tier_30",
		type = "cosmetic",
		track = "FREE",
		sourceKey = "cosmeticId",
		tier = 30,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_free_tier_30_concept.png",
			icon_png = "assets/icons/royal_free_tier_30_icon.png",
			model_fbx = "assets/models/fbx/royal_free_tier_30_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_free_tier_30_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_free_tier_30_diffuse.png",
		},
	},
	{
		rewardId = "royal_premium_tier_30",
		type = "cosmetic",
		track = "PREMIUM",
		sourceKey = "cosmeticId",
		tier = 30,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_premium_tier_30_concept.png",
			icon_png = "assets/icons/royal_premium_tier_30_icon.png",
			model_fbx = "assets/models/fbx/royal_premium_tier_30_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_premium_tier_30_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_premium_tier_30_diffuse.png",
		},
	},
	{
		rewardId = "royal_free_tier_35",
		type = "cosmetic",
		track = "FREE",
		sourceKey = "cosmeticId",
		tier = 35,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_free_tier_35_concept.png",
			icon_png = "assets/icons/royal_free_tier_35_icon.png",
			model_fbx = "assets/models/fbx/royal_free_tier_35_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_free_tier_35_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_free_tier_35_diffuse.png",
		},
	},
	{
		rewardId = "royal_premium_tier_35",
		type = "cosmetic",
		track = "PREMIUM",
		sourceKey = "cosmeticId",
		tier = 35,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_premium_tier_35_concept.png",
			icon_png = "assets/icons/royal_premium_tier_35_icon.png",
			model_fbx = "assets/models/fbx/royal_premium_tier_35_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_premium_tier_35_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_premium_tier_35_diffuse.png",
		},
	},
	{
		rewardId = "royal_free_tier_40",
		type = "cosmetic",
		track = "FREE",
		sourceKey = "cosmeticId",
		tier = 40,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_free_tier_40_concept.png",
			icon_png = "assets/icons/royal_free_tier_40_icon.png",
			model_fbx = "assets/models/fbx/royal_free_tier_40_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_free_tier_40_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_free_tier_40_diffuse.png",
		},
	},
	{
		rewardId = "royal_premium_tier_40",
		type = "cosmetic",
		track = "PREMIUM",
		sourceKey = "cosmeticId",
		tier = 40,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_premium_tier_40_concept.png",
			icon_png = "assets/icons/royal_premium_tier_40_icon.png",
			model_fbx = "assets/models/fbx/royal_premium_tier_40_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_premium_tier_40_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_premium_tier_40_diffuse.png",
		},
	},
	{
		rewardId = "royal_free_tier_45",
		type = "cosmetic",
		track = "FREE",
		sourceKey = "cosmeticId",
		tier = 45,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_free_tier_45_concept.png",
			icon_png = "assets/icons/royal_free_tier_45_icon.png",
			model_fbx = "assets/models/fbx/royal_free_tier_45_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_free_tier_45_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_free_tier_45_diffuse.png",
		},
	},
	{
		rewardId = "royal_premium_tier_45",
		type = "cosmetic",
		track = "PREMIUM",
		sourceKey = "cosmeticId",
		tier = 45,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_premium_tier_45_concept.png",
			icon_png = "assets/icons/royal_premium_tier_45_icon.png",
			model_fbx = "assets/models/fbx/royal_premium_tier_45_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_premium_tier_45_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_premium_tier_45_diffuse.png",
		},
	},
	{
		rewardId = "royal_free_tier_50",
		type = "cosmetic",
		track = "FREE",
		sourceKey = "cosmeticId",
		tier = 50,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_free_tier_50_concept.png",
			icon_png = "assets/icons/royal_free_tier_50_icon.png",
			model_fbx = "assets/models/fbx/royal_free_tier_50_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_free_tier_50_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_free_tier_50_diffuse.png",
		},
	},
	{
		rewardId = "royal_premium_tier_50",
		type = "cosmetic",
		track = "PREMIUM",
		sourceKey = "cosmeticId",
		tier = 50,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_premium_tier_50_concept.png",
			icon_png = "assets/icons/royal_premium_tier_50_icon.png",
			model_fbx = "assets/models/fbx/royal_premium_tier_50_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_premium_tier_50_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_premium_tier_50_diffuse.png",
		},
	},
	{
		rewardId = "royal_free_tier_55",
		type = "cosmetic",
		track = "FREE",
		sourceKey = "cosmeticId",
		tier = 55,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_free_tier_55_concept.png",
			icon_png = "assets/icons/royal_free_tier_55_icon.png",
			model_fbx = "assets/models/fbx/royal_free_tier_55_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_free_tier_55_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_free_tier_55_diffuse.png",
		},
	},
	{
		rewardId = "royal_premium_tier_55",
		type = "cosmetic",
		track = "PREMIUM",
		sourceKey = "cosmeticId",
		tier = 55,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/royal_premium_tier_55_concept.png",
			icon_png = "assets/icons/royal_premium_tier_55_icon.png",
			model_fbx = "assets/models/fbx/royal_premium_tier_55_model.fbx",
			model_rbxm = "assets/models/rbxm/royal_premium_tier_55_model.rbxm",
			diffuse_texture = "assets/models/fbx/royal_premium_tier_55_diffuse.png",
		},
	},
	{
		rewardId = "title_legenda_pasrahphobia",
		type = "title",
		track = "FREE",
		sourceKey = "cosmeticId",
		tier = 60,
		assetStatus = "PENDING",
		files = {
			title_png = "assets/ui/title_legenda_pasrahphobia_title.png",
			icon_png = "assets/icons/title_legenda_pasrahphobia_icon.png",
			roblox_asset_id = nil,
		},
	},
	{
		rewardId = "badge_season_complete_free",
		type = "cosmetic",
		track = "FREE",
		sourceKey = "seasonBadgeId",
		tier = 60,
		assetStatus = "PENDING",
		files = {
			badge_png = "assets/ui/badge_season_complete_free_badge.png",
			icon_png = "assets/icons/badge_season_complete_free_icon.png",
			roblox_asset_id = nil,
		},
	},
	{
		rewardId = "outfit_sang_ahli_season_exclusive",
		type = "cosmetic",
		track = "PREMIUM",
		sourceKey = "cosmeticId",
		tier = 60,
		assetStatus = "PENDING",
		files = {
			concept_art = "assets/concept/outfit_sang_ahli_season_exclusive_concept.png",
			icon_png = "assets/icons/outfit_sang_ahli_season_exclusive_icon.png",
			model_fbx = "assets/models/fbx/outfit_sang_ahli_season_exclusive_model.fbx",
			model_rbxm = "assets/models/rbxm/outfit_sang_ahli_season_exclusive_model.rbxm",
			diffuse_texture = "assets/models/fbx/outfit_sang_ahli_season_exclusive_diffuse.png",
		},
	},
	{
		rewardId = "badge_season_complete_premium",
		type = "cosmetic",
		track = "PREMIUM",
		sourceKey = "seasonBadgeId",
		tier = 60,
		assetStatus = "PENDING",
		files = {
			badge_png = "assets/ui/badge_season_complete_premium_badge.png",
			icon_png = "assets/icons/badge_season_complete_premium_icon.png",
			roblox_asset_id = nil,
		},
	},
	{
		rewardId = "emote_pasrah_ascend",
		type = "emote",
		track = "PREMIUM",
		sourceKey = "exclusiveEmoteId",
		tier = 60,
		assetStatus = "PENDING",
		files = {
			storyboard_png = "assets/concept/emote_pasrah_ascend_emote_board.png",
			icon_png = "assets/icons/emote_pasrah_ascend_icon.png",
			rbxanim = "assets/animations/rbxanim/emote_pasrah_ascend_emote.rbxanim",
			roblox_animation_id = nil,
		},
	},
}

local function cloneArray(values)
	local result = {}
	for index, value in ipairs(values or {}) do
		result[index] = value
	end
	return result
end

local function cloneTable(value)
	local result = {}
	for key, nested in pairs(value or {}) do
		result[key] = nested
	end
	return result
end

CosmeticRegistry.ALL = {}
CosmeticRegistry.ORDERED = {}
CosmeticRegistry.BY_TIER = {}
CosmeticRegistry.BY_SOURCE_KEY = {}

for _, raw in ipairs(RAW_ENTRIES) do
	local record = {
		rewardId = raw.rewardId,
		type = raw.type,
		track = raw.track,
		sourceKey = raw.sourceKey,
		tier = raw.tier,
		season = "S1",
		assetStatus = raw.assetStatus,
		files = cloneTable(raw.files),
	}

	CosmeticRegistry.ALL[record.rewardId] = record
	table.insert(CosmeticRegistry.ORDERED, record.rewardId)

	local tierBucket = CosmeticRegistry.BY_TIER[record.tier]
	if not tierBucket then
		tierBucket = { FREE = {}, PREMIUM = {} }
		CosmeticRegistry.BY_TIER[record.tier] = tierBucket
	end
	table.insert(tierBucket[record.track], record.rewardId)

	local sourceBucket = CosmeticRegistry.BY_SOURCE_KEY[record.sourceKey]
	if not sourceBucket then
		sourceBucket = {}
		CosmeticRegistry.BY_SOURCE_KEY[record.sourceKey] = sourceBucket
	end
	table.insert(sourceBucket, record.rewardId)
end

function CosmeticRegistry.Get(rewardId)
	return CosmeticRegistry.ALL[rewardId]
end

function CosmeticRegistry.GetByTier(tier)
	return CosmeticRegistry.BY_TIER[tonumber(tier) or tier]
end

function CosmeticRegistry.GetBySourceKey(sourceKey)
	return CosmeticRegistry.BY_SOURCE_KEY[sourceKey]
end

function CosmeticRegistry.GetAllRewardIds()
	return cloneArray(CosmeticRegistry.ORDERED)
end

function CosmeticRegistry.GetSourceKeys()
	local keys = {}
	for sourceKey in pairs(CosmeticRegistry.BY_SOURCE_KEY) do
		table.insert(keys, sourceKey)
	end
	table.sort(keys)
	return keys
end

return CosmeticRegistry

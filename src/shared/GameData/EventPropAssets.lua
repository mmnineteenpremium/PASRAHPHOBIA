local EventPropAssets = {}

local THROWABLE_POOL = {
	{
		key = "Prop_Kursi_Poltergeist",
		meshId = "106414675698612",
		size = Vector3.new(1.4, 1.5, 1.2),
		color = Color3.fromRGB(118, 91, 65),
	},
	{
		key = "Prop_Meja_Kecil",
		meshId = "132898476213224",
		size = Vector3.new(1.8, 1.0, 1.4),
		color = Color3.fromRGB(108, 82, 57),
	},
	{
		key = "Prop_Buku_Horor",
		meshId = "77770008155624",
		size = Vector3.new(1.1, 0.18, 0.75),
		color = Color3.fromRGB(70, 52, 42),
	},
	{
		key = "Prop_Piring",
		meshId = "77210392862922",
		size = Vector3.new(0.9, 0.12, 0.9),
		color = Color3.fromRGB(214, 208, 190),
	},
	{
		key = "Prop_Gelas",
		meshId = "108713179228728",
		size = Vector3.new(0.38, 0.65, 0.38),
		color = Color3.fromRGB(185, 204, 214),
	},
	{
		key = "Prop_Botol",
		meshId = "125589045259696",
		size = Vector3.new(0.35, 0.95, 0.35),
		color = Color3.fromRGB(64, 92, 78),
	},
	{
		key = "Prop_Bingkai_Foto",
		meshId = "125466475939741",
		size = Vector3.new(1.1, 0.8, 0.12),
		color = Color3.fromRGB(98, 74, 48),
	},
	{
		key = "Prop_Boneka_Kutukan",
		meshId = "72614621456230",
		size = Vector3.new(0.75, 1.0, 0.45),
		color = Color3.fromRGB(145, 122, 104),
	},
	{
		key = "Prop_Kotak_Kayu",
		meshId = "89110299907345",
		size = Vector3.new(1.45, 1.1, 1.2),
		color = Color3.fromRGB(96, 78, 58),
	},
}

local DIRECT_BY_TOKEN = {
	book = THROWABLE_POOL[3],
	buku = THROWABLE_POOL[3],
	plate = THROWABLE_POOL[4],
	piring = THROWABLE_POOL[4],
	glass = THROWABLE_POOL[5],
	gelas = THROWABLE_POOL[5],
	bottle = THROWABLE_POOL[6],
	botol = THROWABLE_POOL[6],
	frame = THROWABLE_POOL[7],
	foto = THROWABLE_POOL[7],
	photo = THROWABLE_POOL[7],
	doll = THROWABLE_POOL[8],
	boneka = THROWABLE_POOL[8],
	crate = THROWABLE_POOL[9],
	kotak = THROWABLE_POOL[9],
	box = THROWABLE_POOL[9],
	chair = THROWABLE_POOL[1],
	kursi = THROWABLE_POOL[1],
	table = THROWABLE_POOL[2],
	meja = THROWABLE_POOL[2],
	tv = {
		key = "Prop_TV_Kuno",
		meshId = "81407689737506",
		packageId = "81856851350753",
		size = Vector3.new(2.4, 1.5, 0.35),
		color = Color3.fromRGB(34, 36, 42),
	},
	television = {
		key = "Prop_TV_Kuno",
		meshId = "81407689737506",
		packageId = "81856851350753",
		size = Vector3.new(2.4, 1.5, 0.35),
		color = Color3.fromRGB(34, 36, 42),
	},
	window = {
		key = "Prop_Jendela_Knock",
		meshId = "136365079137720",
		size = Vector3.new(2.1, 1.55, 0.18),
		color = Color3.fromRGB(88, 76, 64),
	},
	jendela = {
		key = "Prop_Jendela_Knock",
		meshId = "136365079137720",
		size = Vector3.new(2.1, 1.55, 0.18),
		color = Color3.fromRGB(88, 76, 64),
	},
	door = {
		key = "Prop_Pintu_Slam",
		meshId = "110675870287526",
		size = Vector3.new(1.4, 2.6, 0.22),
		color = Color3.fromRGB(90, 65, 44),
	},
	pintu = {
		key = "Prop_Pintu_Slam",
		meshId = "110675870287526",
		size = Vector3.new(1.4, 2.6, 0.22),
		color = Color3.fromRGB(90, 65, 44),
	},
	lamp = {
		key = "Prop_Lampu_Gantung",
		meshId = "89304787152305",
		size = Vector3.new(1.0, 1.15, 1.0),
		color = Color3.fromRGB(178, 145, 86),
	},
	lampu = {
		key = "Prop_Lampu_Gantung",
		meshId = "89304787152305",
		size = Vector3.new(1.0, 1.15, 1.0),
		color = Color3.fromRGB(178, 145, 86),
	},
	curtain = {
		key = "Prop_Tirai_Kain",
		meshId = "123243345613605",
		size = Vector3.new(1.8, 2.2, 0.18),
		color = Color3.fromRGB(88, 69, 76),
	},
	tirai = {
		key = "Prop_Tirai_Kain",
		meshId = "123243345613605",
		size = Vector3.new(1.8, 2.2, 0.18),
		color = Color3.fromRGB(88, 69, 76),
	},
}

local function normalizeToken(value)
	if type(value) ~= "string" then
		return ""
	end
	return value:gsub("[%s_%-%.]+", ""):lower()
end

local function cloneSpec(spec)
	if type(spec) ~= "table" then
		return nil
	end
	local out = {}
	for key, value in pairs(spec) do
		out[key] = value
	end
	return out
end

local function hashToken(value)
	local token = normalizeToken(value)
	local hash = 0
	for index = 1, #token do
		hash = (hash + string.byte(token, index) * index) % 9973
	end
	return hash
end

function EventPropAssets.ResolveForGenerated(kind, objectId)
	local token = normalizeToken(tostring(objectId or "") .. " " .. tostring(kind or ""))
	for matchToken, spec in pairs(DIRECT_BY_TOKEN) do
		if string.find(token, matchToken, 1, true) then
			return cloneSpec(spec)
		end
	end

	local generatedKind = normalizeToken(kind)
	if generatedKind == "tv" then
		return cloneSpec(DIRECT_BY_TOKEN.tv)
	end
	if generatedKind == "propcrate" then
		return cloneSpec(DIRECT_BY_TOKEN.crate)
	end
	if generatedKind == "propbox" then
		local index = (hashToken(objectId) % #THROWABLE_POOL) + 1
		return cloneSpec(THROWABLE_POOL[index])
	end
	return nil
end

EventPropAssets.throwablePool = THROWABLE_POOL
EventPropAssets.byToken = DIRECT_BY_TOKEN

return EventPropAssets

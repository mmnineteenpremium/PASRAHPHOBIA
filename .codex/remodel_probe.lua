local candidates = {
	"readModelFile",
	"readPlaceFile",
	"writeModelFile",
	"writePlaceFile",
	"readExistingModelAsset",
	"writeExistingModelAsset",
	"getRawProperty",
	"setRawProperty",
}

for _, key in ipairs(candidates) do
	local ok, value = pcall(function()
		return remodel[key]
	end)
	print(key, ok, type(value))
end

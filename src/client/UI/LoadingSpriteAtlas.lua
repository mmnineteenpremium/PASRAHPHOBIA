local LoadingSpriteAtlas = {}

LoadingSpriteAtlas.SourceManifest = ".codex/asset-imports/20260510-loading-sprite-atlas/manifest.json"
LoadingSpriteAtlas.Columns = 4
LoadingSpriteAtlas.Rows = 4
LoadingSpriteAtlas.FrameWidth = 256
LoadingSpriteAtlas.FrameHeight = 144
LoadingSpriteAtlas.TotalFrames = 150
LoadingSpriteAtlas.DurationSeconds = 10
LoadingSpriteAtlas.FrameRate = LoadingSpriteAtlas.TotalFrames / LoadingSpriteAtlas.DurationSeconds
LoadingSpriteAtlas.Loop = false
LoadingSpriteAtlas.FramesPerAtlas = LoadingSpriteAtlas.Columns * LoadingSpriteAtlas.Rows

LoadingSpriteAtlas.Atlases = {
	"rbxassetid://120195828971120",
	"rbxassetid://71115960670643",
	"rbxassetid://113145814516477",
	"rbxassetid://126579627246641",
	"rbxassetid://105684106355950",
	"rbxassetid://123461780382960",
	"rbxassetid://81763998969333",
	"rbxassetid://123346751070718",
	"rbxassetid://108370081988216",
	"rbxassetid://124934813669537",
}

return LoadingSpriteAtlas

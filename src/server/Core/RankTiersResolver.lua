local RankTiersResolver = {}

local FALLBACK_RANK_TIERS = {
    { level = 1, name = "Rookie", xpRequired = 0 },
}

local function safeRequire(moduleScript)
    if not moduleScript then
        return nil
    end
    local ok, result = pcall(require, moduleScript)
    if ok then
        return result
    end
    return nil
end

local function getByPath(root, path)
    local node = root
    for _, segment in ipairs(path) do
        if typeof(node) ~= "Instance" then
            return nil
        end
        node = node:FindFirstChild(segment)
        if not node then
            return nil
        end
    end
    return node
end

local function normalize(raw)
    local normalized = {}
    for _, entry in ipairs(raw or {}) do
        if type(entry) == "table" and type(entry.name) == "string" then
            table.insert(normalized, {
                level = math.max(math.floor(tonumber(entry.level) or (#normalized + 1)), 1),
                name = entry.name,
                xpRequired = math.max(math.floor(tonumber(entry.xpRequired) or 0), 0),
            })
        end
    end
    table.sort(normalized, function(a, b)
        if a.level == b.level then
            return a.xpRequired < b.xpRequired
        end
        return a.level < b.level
    end)
    if #normalized == 0 then
        return FALLBACK_RANK_TIERS
    end
    return normalized
end

local function resolveFromTree()
    local cursor = script
    while cursor do
        local shared = cursor:FindFirstChild("shared") or cursor:FindFirstChild("Shared")
        if shared then
            local candidatePaths = {
                { "DataTypes", "Ranks", "RankTiers" },
                { "DataTypes", "RankTiers" },
            }
            for _, path in ipairs(candidatePaths) do
                local rankTiersModule = getByPath(shared, path)
                local rankTiers = safeRequire(rankTiersModule)
                if type(rankTiers) == "table" then
                    return rankTiers
                end
            end
        end
        cursor = cursor.Parent
    end
    return nil
end

local function resolveFromReplicatedStorage()
    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if not ok or typeof(replicatedStorage) ~= "Instance" then
        return nil
    end

    local shared = replicatedStorage:FindFirstChild("shared") or replicatedStorage:FindFirstChild("Shared")
    if not shared then
        return nil
    end
    local candidatePaths = {
        { "DataTypes", "Ranks", "RankTiers" },
        { "DataTypes", "RankTiers" },
    }
    for _, path in ipairs(candidatePaths) do
        local rankTiersModule = getByPath(shared, path)
        local rankTiers = safeRequire(rankTiersModule)
        if type(rankTiers) == "table" then
            return rankTiers
        end
    end
    return nil
end

function RankTiersResolver.Resolve(deps)
    local source = deps or {}
    if type(source.RankTiers) == "table" then
        return normalize(source.RankTiers)
    end
    if type(source.SharedDataTypes) == "table" and type(source.SharedDataTypes.RankTiers) == "table" then
        return normalize(source.SharedDataTypes.RankTiers)
    end

    local fromTree = resolveFromTree()
    if type(fromTree) == "table" then
        return normalize(fromTree)
    end

    local fromReplicatedStorage = resolveFromReplicatedStorage()
    if type(fromReplicatedStorage) == "table" then
        return normalize(fromReplicatedStorage)
    end

    return FALLBACK_RANK_TIERS
end

return RankTiersResolver

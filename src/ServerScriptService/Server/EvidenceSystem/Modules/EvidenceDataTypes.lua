local EvidenceDataTypes = {}

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

local function resolveSharedDataTypesFromTree()
	local cursor = script
	while cursor do
		local shared = cursor:FindFirstChild("shared") or cursor:FindFirstChild("Shared")
		if shared then
			local evidenceRoot = getByPath(shared, { "DataTypes", "Evidence" })
			if evidenceRoot then
				local evidenceTypesModule = getByPath(evidenceRoot, { "EvidenceTypes", "ModuleScript" })
				local evidenceRulesModule = getByPath(evidenceRoot, { "EvidenceRules", "ModuleScript" })
				local evidenceGhostMapModule = getByPath(evidenceRoot, { "EvidenceGhostMap", "ModuleScript" })
				return {
					EvidenceTypes = safeRequire(evidenceTypesModule),
					EvidenceRules = safeRequire(evidenceRulesModule),
					EvidenceGhostMap = safeRequire(evidenceGhostMapModule),
				}
			end
		end
		cursor = cursor.Parent
	end
	return {}
end

local function resolveSharedDataTypesFromReplicatedStorage()
	local ok, replicatedStorage = pcall(function()
		return game:GetService("ReplicatedStorage")
	end)
	if not ok or typeof(replicatedStorage) ~= "Instance" then
		return {}
	end

	local shared = replicatedStorage:FindFirstChild("shared") or replicatedStorage:FindFirstChild("Shared")
	if not shared then
		return {}
	end

	local evidenceRoot = getByPath(shared, { "DataTypes", "Evidence" })
	if not evidenceRoot then
		return {}
	end

	local evidenceTypesModule = getByPath(evidenceRoot, { "EvidenceTypes", "ModuleScript" })
	local evidenceRulesModule = getByPath(evidenceRoot, { "EvidenceRules", "ModuleScript" })
	local evidenceGhostMapModule = getByPath(evidenceRoot, { "EvidenceGhostMap", "ModuleScript" })
	return {
		EvidenceTypes = safeRequire(evidenceTypesModule),
		EvidenceRules = safeRequire(evidenceRulesModule),
		EvidenceGhostMap = safeRequire(evidenceGhostMapModule),
	}
end

function EvidenceDataTypes.Resolve(deps)
	local source = deps or {}
	local sharedDataTypes = source.SharedDataTypes
	local resolved = {
		EvidenceTypes = source.EvidenceTypes,
		EvidenceRules = source.EvidenceRules,
		EvidenceGhostMap = source.EvidenceGhostMap or source.GhostEvidenceMap,
	}

	if type(sharedDataTypes) == "table" then
		resolved.EvidenceTypes = resolved.EvidenceTypes or sharedDataTypes.EvidenceTypes
		resolved.EvidenceRules = resolved.EvidenceRules or sharedDataTypes.EvidenceRules
		resolved.EvidenceGhostMap = resolved.EvidenceGhostMap or sharedDataTypes.EvidenceGhostMap
	end

	if
		resolved.EvidenceTypes == nil
		or resolved.EvidenceRules == nil
		or resolved.EvidenceGhostMap == nil
	then
		local treeResolved = resolveSharedDataTypesFromTree()
		resolved.EvidenceTypes = resolved.EvidenceTypes or treeResolved.EvidenceTypes
		resolved.EvidenceRules = resolved.EvidenceRules or treeResolved.EvidenceRules
		resolved.EvidenceGhostMap = resolved.EvidenceGhostMap or treeResolved.EvidenceGhostMap

		if
			resolved.EvidenceTypes == nil
			or resolved.EvidenceRules == nil
			or resolved.EvidenceGhostMap == nil
		then
			local rsResolved = resolveSharedDataTypesFromReplicatedStorage()
			resolved.EvidenceTypes = resolved.EvidenceTypes or rsResolved.EvidenceTypes
			resolved.EvidenceRules = resolved.EvidenceRules or rsResolved.EvidenceRules
			resolved.EvidenceGhostMap = resolved.EvidenceGhostMap or rsResolved.EvidenceGhostMap
		end
	end

	return resolved
end

return EvidenceDataTypes

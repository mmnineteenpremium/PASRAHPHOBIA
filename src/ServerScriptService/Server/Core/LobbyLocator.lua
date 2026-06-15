local Workspace = game:GetService("Workspace")

local LobbyLocator = {}

local DEFAULT_LOBBY_NAME = "LobbySocialHub"
local FLOOR_REFERENCE_CANDIDATE_NAMES = {
    "Floor_1_Main",
    "DirectoryPad",
    "GardenBayFloor",
    "ShopBayFloor",
    "FlexBayFloor",
    "PartyBayFloor",
    "NorthBayFloor",
}

local function normalizeLobbyName(lobbyName)
    if type(lobbyName) == "string" and lobbyName ~= "" then
        return lobbyName
    end
    return DEFAULT_LOBBY_NAME
end

local function normalizeWorkspace(workspaceInstance)
    if typeof(workspaceInstance) == "Instance" and workspaceInstance:IsA("Workspace") then
        return workspaceInstance
    end
    return Workspace
end

local function unwrapLobbyRoot(container, lobbyName)
    if not container then
        return nil
    end

    if container:IsA("Model") then
        return container
    end

    local namedChild = container:FindFirstChild(lobbyName)
    if namedChild and namedChild:IsA("Model") then
        return namedChild
    end

    if container:IsA("Folder") and namedChild then
        local nestedNamedChild = namedChild:FindFirstChild(lobbyName)
        if nestedNamedChild and nestedNamedChild:IsA("Model") then
            return nestedNamedChild
        end

        local nestedFirstModel = namedChild:FindFirstChildWhichIsA("Model")
        if nestedFirstModel then
            return nestedFirstModel
        end
    end

    local firstModel = container:FindFirstChildWhichIsA("Model")
    if firstModel then
        return firstModel
    end

    return container
end

function LobbyLocator.ResolveContainer(lobbyName, workspaceInstance)
    local resolvedLobbyName = normalizeLobbyName(lobbyName)
    local resolvedWorkspace = normalizeWorkspace(workspaceInstance)

    local direct = resolvedWorkspace:FindFirstChild(resolvedLobbyName)
    if direct then
        return direct
    end

    local mapsFolder = resolvedWorkspace:FindFirstChild("Maps")
    if mapsFolder then
        local nested = mapsFolder:FindFirstChild(resolvedLobbyName)
        if nested then
            return nested
        end
    end

    local currentMap = resolvedWorkspace:FindFirstChild("CurrentMap")
    if currentMap then
        if currentMap.Name == resolvedLobbyName then
            return currentMap
        end

        local nestedCurrent = currentMap:FindFirstChild(resolvedLobbyName)
        if nestedCurrent then
            return nestedCurrent
        end
    end

    return nil
end

function LobbyLocator.ResolveRoot(lobbyName, workspaceInstance)
    local resolvedLobbyName = normalizeLobbyName(lobbyName)
    local container = LobbyLocator.ResolveContainer(resolvedLobbyName, workspaceInstance)
    return unwrapLobbyRoot(container, resolvedLobbyName)
end

function LobbyLocator.ResolveGeometry(lobbyName, workspaceInstance)
    local root = LobbyLocator.ResolveRoot(lobbyName, workspaceInstance)
    if not root then
        return nil, nil
    end

    local geometry = root:FindFirstChild("Geometry", true)
    if geometry and geometry:IsA("Folder") then
        return geometry, root
    end

    return nil, root
end

function LobbyLocator.ResolveSpawnFolder(lobbyName, workspaceInstance)
    local root = LobbyLocator.ResolveRoot(lobbyName, workspaceInstance)
    if not root then
        return nil, nil
    end

    local spawnFolder = root:FindFirstChild("SpawnPoints", true)
    if spawnFolder and (spawnFolder:IsA("Folder") or spawnFolder:IsA("Model")) then
        return spawnFolder, root
    end

    return nil, root
end

function LobbyLocator.ResolvePrimaryFloor(lobbyName, workspaceInstance)
    local root = LobbyLocator.ResolveRoot(lobbyName, workspaceInstance)
    if not root then
        return nil, nil
    end

    for _, name in ipairs(FLOOR_REFERENCE_CANDIDATE_NAMES) do
        local preferredFloor = root:FindFirstChild(name, true)
        if preferredFloor and preferredFloor:IsA("BasePart") then
            return preferredFloor, root
        end
    end

    local bestPart = nil
    local bestArea = 0
    for _, descendant in ipairs(root:GetDescendants()) do
        if descendant:IsA("BasePart") then
            local lowerName = descendant.Name:lower()
            if lowerName:find("floor", 1, true) or lowerName:find("pad", 1, true) then
                local area = descendant.Size.X * descendant.Size.Z
                if area > bestArea then
                    bestArea = area
                    bestPart = descendant
                end
            end
        end
    end

    return bestPart, root
end

function LobbyLocator.ResolveReferencePosition(lobbyName, workspaceInstance)
    local root = LobbyLocator.ResolveRoot(lobbyName, workspaceInstance)
    if not root then
        return nil, nil
    end

    local boundaryReference = root:FindFirstChild("BoundaryReference", true)
    if boundaryReference and boundaryReference:IsA("BasePart") then
        return boundaryReference.Position, root
    end

    local primaryFloor = LobbyLocator.ResolvePrimaryFloor(lobbyName, workspaceInstance)
    if primaryFloor and primaryFloor:IsA("BasePart") then
        return primaryFloor.Position, root
    end

    if root:IsA("Model") then
        local ok, pivot = pcall(function()
            return root:GetPivot().Position
        end)
        if ok and typeof(pivot) == "Vector3" then
            return pivot, root
        end
    end

    local firstPart = root:FindFirstChildWhichIsA("BasePart", true)
    if firstPart then
        return firstPart.Position, root
    end

    return nil, root
end

return LobbyLocator

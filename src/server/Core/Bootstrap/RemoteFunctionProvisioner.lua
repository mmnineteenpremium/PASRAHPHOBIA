local RemoteFunctionProvisioner = {}

local REQUIRED_REMOTE_FUNCTIONS = {
    "EvidenceRequest",
    "GhostInteractionRequest",
}

function RemoteFunctionProvisioner.Ensure()
    local ok, replicatedStorage = pcall(function()
        return game:GetService("ReplicatedStorage")
    end)
    if not ok or typeof(replicatedStorage) ~= "Instance" then
        return false
    end

    local remoteFunctions = replicatedStorage:FindFirstChild("RemoteFunctions")
    if not remoteFunctions then
        remoteFunctions = Instance.new("Folder")
        remoteFunctions.Name = "RemoteFunctions"
        remoteFunctions.Parent = replicatedStorage
    end

    for _, remoteName in ipairs(REQUIRED_REMOTE_FUNCTIONS) do
        local existing = remoteFunctions:FindFirstChild(remoteName)
        if not (existing and existing:IsA("RemoteFunction")) then
            local remote = Instance.new("RemoteFunction")
            remote.Name = remoteName
            remote.Parent = remoteFunctions
        end
    end

    return true
end

return RemoteFunctionProvisioner

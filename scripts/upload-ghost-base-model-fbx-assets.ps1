param(
    [string]$PlanPath = ".codex/asset-imports/20260513-ghost-base-reexport/roblox-base-model-upload-plan.json",
    [string]$OutputPath = ".codex/asset-imports/20260513-ghost-base-reexport/roblox-base-model-upload-results.json",
    [string]$CreatorGroupId = "407883270",
    [string]$CreatorUserId = "",
    [int]$PollIntervalSeconds = 3,
    [int]$MaxPollAttempts = 120,
    [int]$MaxCreateAttempts = 3,
    [int]$CreateRetryDelaySeconds = 5,
    [string[]]$OnlyKey = @(),
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Net.Http

function Get-OpenCloudApiKey {
    $fromUser = [Environment]::GetEnvironmentVariable("ROBLOX_OPEN_CLOUD_API_KEY", "User")
    if (-not [string]::IsNullOrWhiteSpace($fromUser)) {
        return $fromUser.Trim()
    }

    $fromProcess = [Environment]::GetEnvironmentVariable("ROBLOX_OPEN_CLOUD_API_KEY", "Process")
    if (-not [string]::IsNullOrWhiteSpace($fromProcess)) {
        return $fromProcess.Trim()
    }

    throw "ROBLOX_OPEN_CLOUD_API_KEY was not found in User/Process env."
}

function Invoke-CurlJson {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Args
    )

    $raw = & curl.exe @Args 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "curl failed (exit=$exitCode): $raw"
    }

    $text = ($raw | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    try {
        return $text | ConvertFrom-Json
    } catch {
        throw "Response was not valid JSON: $text"
    }
}

function Invoke-OpenCloudCreateAsset {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApiKey,
        [Parameter(Mandatory = $true)]
        [string]$RequestBody,
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string]$MimeType
    )

    $client = [System.Net.Http.HttpClient]::new()
    $multipart = [System.Net.Http.MultipartFormDataContent]::new()
    $requestContent = [System.Net.Http.StringContent]::new($RequestBody, [System.Text.Encoding]::UTF8, "application/json")
    $fileStream = [System.IO.File]::OpenRead($FilePath)
    $fileContent = [System.Net.Http.StreamContent]::new($fileStream)
    $fileContent.Headers.ContentType = [System.Net.Http.Headers.MediaTypeHeaderValue]::Parse($MimeType)

    try {
        $client.DefaultRequestHeaders.Add("x-api-key", $ApiKey)
        $multipart.Add($requestContent, "request")
        $multipart.Add($fileContent, "fileContent", [System.IO.Path]::GetFileName($FilePath))

        $response = $client.PostAsync("https://apis.roblox.com/assets/v1/assets", $multipart).GetAwaiter().GetResult()
        $text = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if ([string]::IsNullOrWhiteSpace($text)) {
            return $null
        }
        return $text | ConvertFrom-Json
    } finally {
        $fileContent.Dispose()
        $fileStream.Dispose()
        $requestContent.Dispose()
        $multipart.Dispose()
        $client.Dispose()
    }
}

function Invoke-OpenCloudGetOperation {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApiKey,
        [Parameter(Mandatory = $true)]
        [string]$OperationId
    )

    $client = [System.Net.Http.HttpClient]::new()
    try {
        $client.DefaultRequestHeaders.Add("x-api-key", $ApiKey)
        $response = $client.GetAsync("https://apis.roblox.com/assets/v1/operations/$OperationId").GetAwaiter().GetResult()
        $text = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if ([string]::IsNullOrWhiteSpace($text)) {
            return $null
        }
        return $text | ConvertFrom-Json
    } finally {
        $client.Dispose()
    }
}

function Resolve-AssetId($obj) {
    if ($null -eq $obj) {
        return $null
    }

    if ($obj.PSObject.Properties.Name -contains "assetId" -and $obj.assetId) {
        return [string]$obj.assetId
    }

    if ($obj.PSObject.Properties.Name -contains "response" -and $obj.response) {
        $response = $obj.response
        if ($response.PSObject.Properties.Name -contains "assetId" -and $response.assetId) {
            return [string]$response.assetId
        }
        if ($response.PSObject.Properties.Name -contains "path" -and $response.path -match "assets/(\d+)") {
            return $Matches[1]
        }
    }

    if ($obj.PSObject.Properties.Name -contains "path" -and $obj.path -match "assets/(\d+)") {
        return $Matches[1]
    }

    return $null
}

function New-CreationContext([string]$groupId, [string]$userId) {
    $hasGroup = -not [string]::IsNullOrWhiteSpace($groupId)
    $hasUser = -not [string]::IsNullOrWhiteSpace($userId)

    if ($hasGroup -eq $hasUser) {
        throw "Provide exactly one creator id: CreatorGroupId or CreatorUserId."
    }

    if ($hasGroup) {
        return @{
            creator = @{
                groupId = [string]$groupId
            }
        }
    }

    return @{
        creator = @{
            userId = [string]$userId
        }
    }
}

function Get-ModelMimeType([string]$filePath) {
    $extension = [System.IO.Path]::GetExtension($filePath).ToLowerInvariant()
    switch ($extension) {
        ".fbx" { return "model/fbx" }
        ".gltf" { return "model/gltf+json" }
        ".glb" { return "model/gltf-binary" }
        ".obj" { return "model/obj" }
        default { throw "Unsupported model upload file extension '$extension': $filePath" }
    }
}

if (-not (Test-Path -LiteralPath $PlanPath)) {
    throw "Plan file was not found: $PlanPath"
}

$planItems = Get-Content -LiteralPath $PlanPath -Raw | ConvertFrom-Json
if ($null -eq $planItems) {
    throw "Plan file is empty: $PlanPath"
}
if ($planItems -isnot [System.Collections.IEnumerable] -or $planItems -is [string]) {
    $planItems = @($planItems)
}
if ($OnlyKey.Count -gt 0) {
    $allowedKeys = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($key in $OnlyKey) {
        [void]$allowedKeys.Add($key)
    }
    $planItems = @($planItems | Where-Object { $allowedKeys.Contains([string]$_.key) })
}

$creationContext = New-CreationContext -groupId $CreatorGroupId -userId $CreatorUserId
$apiKey = $null
if (-not $DryRun) {
    $apiKey = Get-OpenCloudApiKey
}

$outputDirectory = Split-Path -Parent ([System.IO.Path]::GetFullPath($OutputPath))
if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
}

$results = New-Object System.Collections.Generic.List[object]

foreach ($item in $planItems) {
    $key = [string]$item.key
    $displayName = [string]$item.displayName
    $filePath = [System.IO.Path]::GetFullPath([string]$item.filePath)

    try {
        if (-not (Test-Path -LiteralPath $filePath)) {
            $results.Add([ordered]@{
                key = $key
                ghost = $item.ghost
                displayName = $displayName
                filePath = $filePath
                status = "missing_file"
                error = "File was not found."
            })
            continue
        }

        $mimeType = Get-ModelMimeType -filePath $filePath
        $requestBody = @{
            assetType = "Model"
            displayName = $displayName
            description = [string]$item.description
            creationContext = $creationContext
        } | ConvertTo-Json -Depth 20 -Compress

        if ($DryRun) {
            $results.Add([ordered]@{
                key = $key
                ghost = $item.ghost
                displayName = $displayName
                filePath = $filePath
                mimeType = $mimeType
                bytes = (Get-Item -LiteralPath $filePath).Length
                status = "dry_run_ready"
            })
            continue
        }

        Write-Host "Uploading model $displayName..."

        $createResponse = $null
        $createError = $null
        for ($attempt = 1; $attempt -le [Math]::Max(1, $MaxCreateAttempts); $attempt++) {
            try {
                $createResponse = Invoke-OpenCloudCreateAsset -ApiKey $apiKey -RequestBody $requestBody -FilePath $filePath -MimeType $mimeType
                $createError = $null
                break
            } catch {
                $createError = $_.Exception.Message
                if ($attempt -lt [Math]::Max(1, $MaxCreateAttempts)) {
                    Write-Warning "Create attempt $attempt failed for ${key}: $createError"
                    Start-Sleep -Seconds $CreateRetryDelaySeconds
                }
            }
        }

        if ($createError) {
            throw $createError
        }

        if ($createResponse -and $createResponse.PSObject.Properties.Name -contains "errors" -and $createResponse.errors) {
            $results.Add([ordered]@{
                key = $key
                ghost = $item.ghost
                displayName = $displayName
                filePath = $filePath
                status = "create_failed"
                error = ($createResponse.errors | ConvertTo-Json -Compress)
            })
            continue
        }

        $operationId = $null
        if ($createResponse.PSObject.Properties.Name -contains "operationId" -and $createResponse.operationId) {
            $operationId = [string]$createResponse.operationId
        } elseif ($createResponse.PSObject.Properties.Name -contains "path" -and $createResponse.path) {
            $operationId = ([string]$createResponse.path) -replace "^operations/", ""
        }

        if ([string]::IsNullOrWhiteSpace($operationId)) {
            $results.Add([ordered]@{
                key = $key
                ghost = $item.ghost
                displayName = $displayName
                filePath = $filePath
                status = "create_unknown"
                error = "Operation ID was not found."
                rawCreateResponse = ($createResponse | ConvertTo-Json -Depth 20 -Compress)
            })
            continue
        }

        $finalOperation = $null
        for ($i = 1; $i -le $MaxPollAttempts; $i++) {
            Start-Sleep -Seconds $PollIntervalSeconds
            $operation = Invoke-OpenCloudGetOperation -ApiKey $apiKey -OperationId $operationId

            if ($operation.PSObject.Properties.Name -contains "done" -and $operation.done -eq $true) {
                $finalOperation = $operation
                break
            }
        }

        if ($null -eq $finalOperation) {
            $results.Add([ordered]@{
                key = $key
                ghost = $item.ghost
                displayName = $displayName
                filePath = $filePath
                status = "poll_timeout"
                operationId = $operationId
            })
            continue
        }

        $operationError = $null
        if ($finalOperation.PSObject.Properties.Name -contains "error" -and $finalOperation.error) {
            $operationError = $finalOperation.error | ConvertTo-Json -Depth 20 -Compress
        }

        $assetId = Resolve-AssetId -obj $finalOperation
        if ($operationError) {
            $results.Add([ordered]@{
                key = $key
                ghost = $item.ghost
                displayName = $displayName
                filePath = $filePath
                status = "operation_failed"
                operationId = $operationId
                error = $operationError
                rawOperation = ($finalOperation | ConvertTo-Json -Depth 30 -Compress)
            })
            continue
        }

        $results.Add([ordered]@{
            key = $key
            ghost = $item.ghost
            displayName = $displayName
            filePath = $filePath
            status = "uploaded"
            operationId = $operationId
            assetId = $assetId
            assetUri = if ($assetId) { "rbxassetid://$assetId" } else { $null }
            rawOperation = ($finalOperation | ConvertTo-Json -Depth 30 -Compress)
        })
    } catch {
        $results.Add([ordered]@{
            key = $key
            ghost = $item.ghost
            displayName = $displayName
            filePath = $filePath
            status = "exception"
            error = $_.Exception.Message
        })
    }
}

$results | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host "Ghost base model upload pass finished. Results: $OutputPath"

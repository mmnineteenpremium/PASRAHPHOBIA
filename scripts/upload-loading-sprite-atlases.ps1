param(
    [string]$PlanPath = ".codex/asset-imports/20260510-loading-sprite-atlas/roblox-upload-plan.json",
    [string]$SourceRoot = ".codex/asset-imports/20260510-loading-sprite-atlas",
    [string]$OutputPath = ".codex/asset-imports/20260510-loading-sprite-atlas/roblox-upload-success.json",
    [string]$OwnerUserId = "8603977492",
    [int]$PollIntervalSeconds = 3,
    [int]$MaxPollAttempts = 120,
    [int]$MaxCreateAttempts = 3,
    [int]$CreateRetryDelaySeconds = 5
)

$ErrorActionPreference = "Stop"

function Get-OpenCloudApiKey {
    $fromUser = [Environment]::GetEnvironmentVariable("ROBLOX_OPEN_CLOUD_API_KEY", "User")
    if (-not [string]::IsNullOrWhiteSpace($fromUser)) {
        return $fromUser.Trim()
    }

    $fromProcess = [Environment]::GetEnvironmentVariable("ROBLOX_OPEN_CLOUD_API_KEY", "Process")
    if (-not [string]::IsNullOrWhiteSpace($fromProcess)) {
        return $fromProcess.Trim()
    }

    throw "ROBLOX_OPEN_CLOUD_API_KEY tidak ditemukan di User/Process env."
}

function Get-MimeType([string]$filePath) {
    switch ([System.IO.Path]::GetExtension($filePath).ToLowerInvariant()) {
        ".png" { return "image/png" }
        ".jpg" { return "image/jpeg" }
        ".jpeg" { return "image/jpeg" }
        default { return "application/octet-stream" }
    }
}

function Invoke-CurlJson {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Args
    )

    $raw = & curl.exe @Args 2>&1
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "curl gagal (exit=$exitCode): $raw"
    }

    $text = ($raw | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($text)) {
        return $null
    }

    try {
        return $text | ConvertFrom-Json -Depth 100
    } catch {
        throw "Response bukan JSON valid: $text"
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
        $res = $obj.response
        if ($res.PSObject.Properties.Name -contains "assetId" -and $res.assetId) {
            return [string]$res.assetId
        }
        if ($res.PSObject.Properties.Name -contains "path" -and $res.path -match "assets/(\d+)") {
            return $Matches[1]
        }
    }

    if ($obj.PSObject.Properties.Name -contains "path" -and $obj.path -match "assets/(\d+)") {
        return $Matches[1]
    }

    return $null
}

$apiKey = Get-OpenCloudApiKey

if (-not (Test-Path -LiteralPath $PlanPath)) {
    throw "Plan file tidak ditemukan: $PlanPath"
}
if (-not (Test-Path -LiteralPath $SourceRoot)) {
    throw "Source root tidak ditemukan: $SourceRoot"
}

$planItems = Get-Content -LiteralPath $PlanPath -Raw | ConvertFrom-Json
$results = New-Object System.Collections.Generic.List[object]

foreach ($item in $planItems) {
    $fileName = [string]$item.file
    $filePath = Join-Path $SourceRoot $fileName
    if (-not (Test-Path -LiteralPath $filePath)) {
        $results.Add([ordered]@{
            key = $item.key
            displayName = $item.displayName
            file = $fileName
            status = "missing_file"
            error = "File tidak ditemukan: $filePath"
        })
        continue
    }

    $mimeType = Get-MimeType -filePath $filePath
    $requestBody = @{
        assetType = "Image"
        displayName = [string]$item.displayName
        description = [string]$item.description
        creationContext = @{
            creator = @{
                userId = [string]$OwnerUserId
            }
        }
    } | ConvertTo-Json -Depth 10 -Compress

    Write-Host "Uploading $($item.displayName) ($fileName)..."

    try {
        $createResponse = $null
        $createError = $null
        for ($attempt = 1; $attempt -le [Math]::Max(1, $MaxCreateAttempts); $attempt++) {
            try {
                $createResponse = Invoke-CurlJson -Args @(
                    "--silent", "--show-error", "--location",
                    "https://apis.roblox.com/assets/v1/assets",
                    "--header", "x-api-key: $apiKey",
                    "--form", "request=$requestBody",
                    "--form", "fileContent=@$filePath;type=$mimeType"
                )
                $createError = $null
                break
            } catch {
                $createError = $_.Exception.Message
                if ($attempt -lt [Math]::Max(1, $MaxCreateAttempts)) {
                    Write-Warning "Create attempt $attempt failed for $($item.key): $createError"
                    Start-Sleep -Seconds $CreateRetryDelaySeconds
                }
            }
        }

        if ($createError) {
            throw $createError
        }

        if ($createResponse -and $createResponse.PSObject.Properties.Name -contains "errors" -and $createResponse.errors) {
            $results.Add([ordered]@{
                key = $item.key
                displayName = $item.displayName
                file = $fileName
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
                key = $item.key
                displayName = $item.displayName
                file = $fileName
                status = "create_unknown"
                error = "Operation ID tidak ditemukan."
                rawCreateResponse = ($createResponse | ConvertTo-Json -Depth 20 -Compress)
            })
            continue
        }

        $finalOp = $null
        for ($i = 1; $i -le $MaxPollAttempts; $i++) {
            Start-Sleep -Seconds $PollIntervalSeconds
            $op = Invoke-CurlJson -Args @(
                "--silent", "--show-error", "--location",
                "https://apis.roblox.com/assets/v1/operations/$operationId",
                "--header", "x-api-key: $apiKey"
            )

            if ($op.PSObject.Properties.Name -contains "done" -and $op.done -eq $true) {
                $finalOp = $op
                break
            }
        }

        if ($null -eq $finalOp) {
            $results.Add([ordered]@{
                key = $item.key
                displayName = $item.displayName
                file = $fileName
                status = "poll_timeout"
                operationId = $operationId
            })
            continue
        }

        $operationError = $null
        if ($finalOp.PSObject.Properties.Name -contains "error" -and $finalOp.error) {
            $operationError = $finalOp.error | ConvertTo-Json -Depth 20 -Compress
        }

        $assetId = Resolve-AssetId -obj $finalOp
        if ($operationError) {
            $results.Add([ordered]@{
                key = $item.key
                displayName = $item.displayName
                file = $fileName
                status = "operation_failed"
                operationId = $operationId
                error = $operationError
                rawOperation = ($finalOp | ConvertTo-Json -Depth 30 -Compress)
            })
            continue
        }

        $results.Add([ordered]@{
            key = $item.key
            displayName = $item.displayName
            file = $fileName
            status = "uploaded"
            operationId = $operationId
            assetId = $assetId
            assetUri = if ($assetId) { "rbxassetid://$assetId" } else { $null }
            rawOperation = ($finalOp | ConvertTo-Json -Depth 30 -Compress)
        })
    } catch {
        $results.Add([ordered]@{
            key = $item.key
            displayName = $item.displayName
            file = $fileName
            status = "exception"
            error = $_.Exception.Message
        })
    }
}

$results | ConvertTo-Json -Depth 40 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host "Upload selesai. Hasil: $OutputPath"

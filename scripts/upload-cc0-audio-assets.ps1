param(
    [string]$PlanPath = ".codex/asset-imports/20260509-audio-403/roblox-upload-results.json",
    [string]$SourceDir = ".codex/asset-imports/20260509-audio-403/selected",
    [string]$OutputPath = ".codex/asset-imports/20260509-audio-403/roblox-upload-success.json",
    [string]$OwnerUserId = "8603977492",
    [int]$PollIntervalSeconds = 3,
    [int]$MaxPollAttempts = 120
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
        ".ogg" { return "audio/ogg" }
        ".mp3" { return "audio/mpeg" }
        ".wav" { return "audio/wav" }
        ".flac" { return "audio/flac" }
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
    if ($null -eq $obj) { return $null }

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

if (Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue) {
    throw "Roblox Studio masih terbuka. Tutup dulu sebelum upload via Open Cloud."
}

$apiKey = Get-OpenCloudApiKey

if (-not (Test-Path $PlanPath)) {
    throw "Plan file tidak ditemukan: $PlanPath"
}
if (-not (Test-Path $SourceDir)) {
    throw "Source dir tidak ditemukan: $SourceDir"
}

$planItems = Get-Content -Path $PlanPath -Raw | ConvertFrom-Json
$results = New-Object System.Collections.Generic.List[object]

foreach ($item in $planItems) {
    $fileName = [string]$item.file
    $filePath = Join-Path $SourceDir $fileName
    if (-not (Test-Path $filePath)) {
        $results.Add([ordered]@{
            key = $item.key
            displayName = $item.displayName
            file = $fileName
            source = $item.source
            replaces = $item.replaces
            status = "missing_file"
            error = "File tidak ditemukan: $filePath"
        })
        continue
    }

    $mimeType = Get-MimeType -filePath $filePath
    $requestBody = @{
        assetType = "Audio"
        displayName = [string]$item.displayName
        description = "CC0 source: $($item.source). Replacement for legacy asset $($item.replaces)."
        creationContext = @{
            creator = @{
                userId = [string]$OwnerUserId
            }
        }
    } | ConvertTo-Json -Depth 10 -Compress

    Write-Host "Uploading $($item.displayName) ($fileName)..."

    try {
        $createResponse = Invoke-CurlJson -Args @(
            "--silent", "--show-error", "--location",
            "https://apis.roblox.com/assets/v1/assets",
            "--header", "x-api-key: $apiKey",
            "--form", "request=$requestBody",
            "--form", "fileContent=@$filePath;type=$mimeType"
        )

        if ($createResponse -and $createResponse.PSObject.Properties.Name -contains "errors" -and $createResponse.errors) {
            $results.Add([ordered]@{
                key = $item.key
                displayName = $item.displayName
                file = $fileName
                source = $item.source
                replaces = $item.replaces
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
                source = $item.source
                replaces = $item.replaces
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
                source = $item.source
                replaces = $item.replaces
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
                source = $item.source
                replaces = $item.replaces
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
            source = $item.source
            replaces = $item.replaces
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
            source = $item.source
            replaces = $item.replaces
            status = "exception"
            error = $_.Exception.Message
        })
    }
}

$results | ConvertTo-Json -Depth 40 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Upload selesai. Hasil: $OutputPath"

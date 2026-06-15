param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$PromptParts,
    [string]$Model = 'google/gemma-4-31b-it:free',
    [string]$SessionName = 'default',
    [switch]$NewSession,
    [switch]$Interactive
)

$apiKey = $env:OPENROUTER_API_KEY
if (-not $apiKey) {
    $apiKey = [Environment]::GetEnvironmentVariable('OPENROUTER_API_KEY', 'User')
}

if (-not $apiKey) {
    Write-Error 'OPENROUTER_API_KEY is not set in the current process or User environment.'
    exit 2
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$sessionDir = Join-Path $repoRoot '.codex\openrouter-sessions'
$sessionFile = Join-Path $sessionDir ($SessionName + '.json')
$historyFile = Join-Path $sessionDir ($SessionName + '.jsonl')

if (-not (Test-Path $sessionDir)) {
    New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
}

function Get-SessionState {
    if ($NewSession -or -not (Test-Path $sessionFile)) {
        return [ordered]@{
            sessionName = $SessionName
            model = $Model
            createdAt = (Get-Date).ToString('o')
            updatedAt = (Get-Date).ToString('o')
            messages = @()
        }
    }

    try {
        $state = Get-Content -Raw $sessionFile | ConvertFrom-Json
        if (-not $state.messages) {
            $state | Add-Member -NotePropertyName messages -NotePropertyValue @() -Force
        }
        return $state
    } catch {
        return [ordered]@{
            sessionName = $SessionName
            model = $Model
            createdAt = (Get-Date).ToString('o')
            updatedAt = (Get-Date).ToString('o')
            messages = @()
        }
    }
}

function Save-SessionState {
    param([object]$State)
    $State.updatedAt = (Get-Date).ToString('o')
    $State | ConvertTo-Json -Depth 20 | Set-Content -Path $sessionFile
}

function Append-HistoryLine {
    param([string]$Role, [string]$Content, [string]$UsedModel)
    $entry = [ordered]@{
        timestamp = (Get-Date).ToString('o')
        session = $SessionName
        role = $Role
        model = $UsedModel
        content = $Content
    }
    ($entry | ConvertTo-Json -Depth 10 -Compress) | Add-Content -Path $historyFile
}

function Invoke-OpenRouterModel {
    param(
        [string]$CandidateModel,
        [array]$Messages
    )

    $headers = @{
        Authorization = "Bearer $apiKey"
        'Content-Type' = 'application/json'
        'HTTP-Referer' = 'http://localhost'
        'X-OpenRouter-Title' = 'PASRAHPHOBIA Terminal'
    }

    $body = @{
        model = $CandidateModel
        messages = $Messages
    } | ConvertTo-Json -Depth 20

    return Invoke-RestMethod -Uri 'https://openrouter.ai/api/v1/chat/completions' -Method Post -Headers $headers -Body $body -ErrorAction Stop
}

function Invoke-ChatTurn {
    param(
        [string]$UserPrompt,
        [object]$State
    )

    $candidateModels = @(
        $State.model,
        $Model,
        'google/gemma-4-31b-it:free',
        'google/gemma-4-26b-a4b-it:free',
        'openrouter/free'
    ) | Where-Object { $_ } | Select-Object -Unique

    $messages = @()
    foreach ($msg in $State.messages) {
        $messages += @{
            role = $msg.role
            content = $msg.content
        }
    }
    $messages += @{ role = 'user'; content = $UserPrompt }
    $State.messages += @{ role = 'user'; content = $UserPrompt }
    Save-SessionState -State $State
    Append-HistoryLine -Role 'user' -Content $UserPrompt -UsedModel $State.model

    foreach ($candidate in $candidateModels) {
        $attemptDelays = @(0, 15, 15, 15, 20)
        for ($attemptIndex = 0; $attemptIndex -lt $attemptDelays.Count; $attemptIndex++) {
            if ($attemptDelays[$attemptIndex] -gt 0) {
                Start-Sleep -Seconds $attemptDelays[$attemptIndex]
            }

            try {
                $resp = Invoke-OpenRouterModel -CandidateModel $candidate -Messages $messages
                $content = $resp.choices[0].message.content
                if (-not $content) { continue }

                $State.model = $resp.model
                $State.messages += @{ role = 'assistant'; content = $content }
                Save-SessionState -State $State
                Append-HistoryLine -Role 'assistant' -Content $content -UsedModel $resp.model

                if ($resp.model) {
                    Write-Host "[model: $($resp.model)]" -ForegroundColor DarkGray
                }
                Write-Output $content
                return $true
            } catch {
                $msg = $_.ErrorDetails.Message
                $exceptionMessage = $_.Exception.Message
                if ($exceptionMessage -match '429|Too Many Requests' -or $msg -match 'temporarily rate-limited upstream') {
                    Write-Host "Rate-limited on $candidate, retrying..." -ForegroundColor DarkYellow
                    continue
                }
                if ($msg -match 'No allowed providers are available' -or $msg -match 'free') {
                    break
                }
                break
            }
        }
    }

    return $false
}

$state = Get-SessionState

$prompt = if ($PromptParts -and $PromptParts.Count -gt 0) { ($PromptParts -join ' ').Trim() } else { $null }

if (-not $prompt -and -not $Interactive) {
    $Interactive = $true
}

if ($prompt) {
    if (-not (Invoke-ChatTurn -UserPrompt $prompt -State $state)) {
        Write-Error 'No free OpenRouter model succeeded. Try again later or choose a different model.'
        exit 1
    }
    exit 0
}

Write-Host "OpenRouter chat session: $SessionName" -ForegroundColor Cyan
Write-Host "Type /exit to quit, /reset to clear session, /model <slug> to change model." -ForegroundColor DarkGray

while ($true) {
    $inputLine = Read-Host 'You'
    if (-not $inputLine) { continue }

    if ($inputLine -eq '/exit') { break }

    if ($inputLine -eq '/reset') {
        $state = Get-SessionState
        $state.messages = @()
        $state.model = $Model
        Save-SessionState -State $state
        Remove-Item $historyFile -ErrorAction SilentlyContinue
        Write-Host 'Session reset.' -ForegroundColor Yellow
        continue
    }

    if ($inputLine -match '^/model\s+(.+)$') {
        $state.model = $matches[1].Trim()
        Save-SessionState -State $state
        Write-Host "Model set to $($state.model)" -ForegroundColor Yellow
        continue
    }

    if (-not (Invoke-ChatTurn -UserPrompt $inputLine -State $state)) {
        Write-Host 'No free OpenRouter model succeeded. Try again later or choose a different model.' -ForegroundColor Red
    }
}

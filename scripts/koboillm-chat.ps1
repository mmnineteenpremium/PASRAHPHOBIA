param(
    [Parameter(Position = 0, ValueFromRemainingArguments = $true)]
    [string[]]$PromptParts,
    [string]$Model = 'openai/gpt-4o-mini',
    [string]$SessionName = 'default',
    [string]$BaseUrl = '',
    [switch]$NewSession,
    [switch]$Interactive,
    [switch]$ListModels
)

$repoRoot = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $repoRoot '.env'

function Import-DotEnvValue {
    param([string]$Name)
    if (-not (Test-Path $envFile)) { return $null }

    foreach ($line in Get-Content $envFile) {
        if ($line -match '^\s*#') { continue }
        if ($line -match "^\s*$([regex]::Escape($Name))\s*=\s*(.*)\s*$") {
            return $matches[1].Trim().Trim('"').Trim("'")
        }
    }

    return $null
}

function Get-ConfigValue {
    param([string]$Name, [string]$DefaultValue = '')

    $value = [Environment]::GetEnvironmentVariable($Name, 'Process')
    if (-not $value) { $value = [Environment]::GetEnvironmentVariable($Name, 'User') }
    if (-not $value) { $value = Import-DotEnvValue -Name $Name }
    if (-not $value) { $value = $DefaultValue }
    return $value
}

$apiKey = Get-ConfigValue -Name 'KOBOILLM_API_KEY'
if (-not $BaseUrl) {
    $BaseUrl = Get-ConfigValue -Name 'KOBOILLM_BASE_URL' -DefaultValue 'https://api.koboillm.com/v1'
}
$BaseUrl = $BaseUrl.TrimEnd('/')

if (-not $apiKey) {
    Write-Error 'KOBOILLM_API_KEY is not set. Put it in .env, current process env, or User environment.'
    exit 2
}

$sessionDir = Join-Path $repoRoot '.codex\koboillm-sessions'
$sessionFile = Join-Path $sessionDir ($SessionName + '.json')
$historyFile = Join-Path $sessionDir ($SessionName + '.jsonl')

if (-not (Test-Path $sessionDir)) {
    New-Item -ItemType Directory -Path $sessionDir -Force | Out-Null
}

function Invoke-KoboiRequest {
    param(
        [string]$Path,
        [string]$Method = 'Get',
        [object]$Body = $null
    )

    $headers = @{
        Authorization = "Bearer $apiKey"
        'Content-Type' = 'application/json'
    }

    $uri = "$BaseUrl/$($Path.TrimStart('/'))"
    if ($Body) {
        $jsonBody = $Body | ConvertTo-Json -Depth 40
        return Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -Body $jsonBody -ErrorAction Stop
    }

    return Invoke-RestMethod -Uri $uri -Method $Method -Headers $headers -ErrorAction Stop
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
    $State | ConvertTo-Json -Depth 40 | Set-Content -Path $sessionFile
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

function Invoke-ChatTurn {
    param(
        [string]$UserPrompt,
        [object]$State
    )

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

    $body = @{
        model = $State.model
        messages = $messages
    }

    $resp = Invoke-KoboiRequest -Path 'chat/completions' -Method Post -Body $body
    $content = $resp.choices[0].message.content
    if (-not $content) {
        throw 'KoboiLLM returned an empty assistant message.'
    }

    if ($resp.model) { $State.model = $resp.model }
    $State.messages += @{ role = 'assistant'; content = $content }
    Save-SessionState -State $State
    Append-HistoryLine -Role 'assistant' -Content $content -UsedModel $State.model

    Write-Host "[model: $($State.model)]" -ForegroundColor DarkGray
    Write-Output $content
}

if ($ListModels) {
    $models = Invoke-KoboiRequest -Path 'models'
    $models.data | Select-Object id, owned_by | Format-Table -AutoSize
    exit 0
}

$state = Get-SessionState
$prompt = if ($PromptParts -and $PromptParts.Count -gt 0) { ($PromptParts -join ' ').Trim() } else { $null }

if (-not $prompt -and -not $Interactive) {
    $Interactive = $true
}

if ($prompt) {
    Invoke-ChatTurn -UserPrompt $prompt -State $state
    exit 0
}

Write-Host "KoboiLLM chat session: $SessionName" -ForegroundColor Cyan
Write-Host "Base URL: $BaseUrl" -ForegroundColor DarkGray
Write-Host "Type /exit to quit, /reset to clear session, /models to list models, /model <slug> to change model." -ForegroundColor DarkGray

while ($true) {
    $inputLine = Read-Host 'You'
    if (-not $inputLine) { continue }

    if ($inputLine -eq '/exit') { break }

    if ($inputLine -eq '/models') {
        try {
            $models = Invoke-KoboiRequest -Path 'models'
            $models.data | Select-Object id, owned_by | Format-Table -AutoSize
        } catch {
            Write-Host $_.Exception.Message -ForegroundColor Red
        }
        continue
    }

    if ($inputLine -eq '/reset') {
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

    try {
        Invoke-ChatTurn -UserPrompt $inputLine -State $state
    } catch {
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

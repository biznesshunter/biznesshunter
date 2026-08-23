$ErrorActionPreference = "Stop"

$inputFile = ".\news_candidates.json"
$outputFile = ".\radar6_new_businesses.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found" -ForegroundColor Red
    exit 1
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

$results = foreach ($item in $data) {

    $title = [string]$item.title
    $lower = $title.ToLower()

    $score = 0
    $signals = New-Object System.Collections.Generic.List[string]

    # --- NEW COMPANY ---
    if ($lower -match '\b(startup|start-up|new company|new business|new venture|founded|founded in|newly founded)\b') {
        $score += 25
        $signals.Add("NEW COMPANY")
    }

    # --- NEW LAUNCH ---
    if ($lower -match '\b(launch|launched|launches|launching|opens|opening|debut|introduced|introduces|unveils|new location|first location|first clinic|first store)\b') {
        $score += 25
        $signals.Add("NEW LAUNCH")
    }

    # --- NEW MODEL / SERVICE ---
    if ($lower -match '\b(new service|new platform|new marketplace|new model|new concept|new product|new offering|new solution)\b') {
        $score += 20
        $signals.Add("NEW MODEL")
    }

    # --- FIRST MOVE ---
    if ($lower -match '\b(first|first-ever|first time|enters|entry into|expands into|expansion into|first location|first store|first clinic)\b') {
        $score += 20
        $signals.Add("FIRST MOVE")
    }

    # --- PLANNED / UPCOMING ---
    if ($lower -match '\b(planned|plans|will open|set to open|coming soon|expected to open|scheduled to open)\b') {
        $score += 10
        $signals.Add("PLANNED")
    }

    # Cap score
    if ($score -gt 100) {
        $score = 100
    }

    if ($score -ge 60) {
        $verdict = "NEW"
    }
    elseif ($score -ge 35) {
        $verdict = "POSSIBLE NEW"
    }
    else {
        $verdict = "WEAK NEWNESS"
    }

    [PSCustomObject]@{
        title = $title
        url = if ($item.link) { $item.link } else { $null }
        newness_score = $score
        verdict = $verdict
        signals = ($signals -join ", ")
    }
}

$results |
    Sort-Object newness_score -Descending |
    ConvertTo-Json -Depth 5 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " BiznessHunter - Newness Radar" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Input  : $inputFile"
Write-Host "Output : $outputFile"
Write-Host ""
Write-Host "Results : $($results.Count)"
Write-Host ""

$results |
    Sort-Object newness_score -Descending |
    Select-Object -First 30 title,newness_score,verdict,signals |
    Format-Table -AutoSize

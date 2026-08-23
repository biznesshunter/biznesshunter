$data = Get-Content ".\radar4_model_gaps.json" -Raw | ConvertFrom-Json

$results = foreach ($x in $data) {

    $score = [int]$x.gap_score

    if ($x.strong_markets -ge 1) { $score += 10 }
    if ($x.moderate_markets -ge 1) { $score += 5 }
    if ($x.no_signal_markets -ge 1) { $score += 20 }

    $score = [Math]::Min($score,100)

    if ($score -ge 70) {
        $verdict = "GO"
    }
    elseif ($score -ge 50) {
        $verdict = "TEST"
    }
    elseif ($score -ge 30) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "REJECT"
    }

    [PSCustomObject]@{
        business=$x.business
        model=$x.model
        score=$score
        verdict=$verdict
        strong_markets=$x.strong_markets
        moderate_markets=$x.moderate_markets
        no_signal_markets=$x.no_signal_markets
    }
}

$results |
    Sort-Object score -Descending |
    ConvertTo-Json -Depth 5 |
    Set-Content -Encoding UTF8 ".\final_opportunities.json"

Write-Host ""
Write-Host "=========================================="
Write-Host "BIZNESSHUNTER — FINAL RADAR"
Write-Host "=========================================="
Write-Host ""

$results |
    Sort-Object score -Descending |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Résultats : .\final_opportunities.json"

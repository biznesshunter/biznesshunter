$inputFile  = ".\radar11_opportunities_enriched.json"
$nicheFile  = ".\radar14_niches.json"
$outputFile = ".\radar16_final_opportunities.json"

$opps   = Get-Content $inputFile -Raw | ConvertFrom-Json
$niches = Get-Content $nicheFile -Raw | ConvertFrom-Json

$results = foreach ($niche in $niches) {

    $parent = [string]$niche.parent_opportunity
    $articles = [int]$niche.article_count

    # Trouver l'opportunité Radar 11 correspondante
    $match = $opps | Where-Object {
        $parent -like "*$($_.vertical)*" -or
        $parent -like "*$($_.opportunity)*"
    } | Select-Object -First 1

    if (!$match) {
        $match = $opps | Where-Object {
            $_.vertical -eq $niche.vertical
        } | Select-Object -First 1
    }

    if (!$match) { continue }

    $baseScore  = [int]$match.score
    $confidence = [int]$match.confidence
    $replication = [int]$match.replication
    $demand = [int]$match.demand
    $companies = [int]$match.company_count
    $countries = [int]$match.country_count

    # ------------------------------------------------------------
    # VALIDATION
    # ------------------------------------------------------------

    $marketProof = [math]::Min(
        100,
        ($articles * 0.50) +
        ($companies * 0.30) +
        ($confidence * 0.20)
    )

    # ------------------------------------------------------------
    # CONCURRENCE
    # ------------------------------------------------------------

    if ($companies -le 5) {
        $competitionGap = 90
    }
    elseif ($companies -le 15) {
        $competitionGap = 75
    }
    elseif ($companies -le 40) {
        $competitionGap = 60
    }
    elseif ($companies -le 80) {
        $competitionGap = 45
    }
    elseif ($companies -le 150) {
        $competitionGap = 30
    }
    else {
        $competitionGap = 15
    }

    # ------------------------------------------------------------
    # GAP GEOGRAPHIQUE
    # ------------------------------------------------------------

    if ($countries -eq 0) {
        $geoGap = 50
    }
    elseif ($countries -eq 1) {
        $geoGap = 85
    }
    elseif ($countries -eq 2) {
        $geoGap = 70
    }
    elseif ($countries -eq 3) {
        $geoGap = 55
    }
    elseif ($countries -le 5) {
        $geoGap = 40
    }
    else {
        $geoGap = 25
    }

    # ------------------------------------------------------------
    # SCORE FINAL
    # ------------------------------------------------------------

    $gapScore = [math]::Round(
        ($marketProof * 0.25) +
        ($competitionGap * 0.25) +
        ($geoGap * 0.20) +
        ($replication * 0.20) +
        ($demand * 0.10)
    )

    if ($gapScore -ge 70) {
        $verdict = "HIGH GAP"
    }
    elseif ($gapScore -ge 60) {
        $verdict = "PROMISING GAP"
    }
    elseif ($gapScore -ge 50) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "LOW"
    }

    [PSCustomObject]@{
        opportunity      = $parent
        gap_score        = $gapScore
        verdict          = $verdict
        market_proof     = [math]::Round($marketProof)
        competition_gap  = $competitionGap
        geographic_gap   = $geoGap
        replication      = $replication
        demand           = $demand
        confidence       = $confidence
        company_count    = $companies
        country_count    = $countries
        article_count    = $articles
        business_model   = $match.business_model
        vertical         = $match.vertical
    }
}

$results =
    $results |
    Sort-Object gap_score -Descending |
    Select-Object -First 15

$results |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 16 FIX"
Write-Host "========================================"
Write-Host ""
Write-Host "Final opportunities : $($results.Count)"
Write-Host ""

$results |
    Select-Object gap_score,verdict,opportunity,company_count,country_count,replication,competition_gap,geographic_gap |
    Format-Table -Wrap -AutoSize

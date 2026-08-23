Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 20"
Write-Host " FINAL OPPORTUNITY SCORING"
Write-Host "========================================"
Write-Host ""

$raw = Get-Content .\radar19_evidence.json -Raw | ConvertFrom-Json

# Déballage automatique d'un éventuel tableau imbriqué
$evidence = @()

foreach ($item in @($raw)) {
    if ($item -is [System.Array]) {
        $evidence += @($item)
    }
    else {
        $evidence += $item
    }
}

Write-Host "Evidence records : $($evidence.Count)"
Write-Host ""

$result = @()

foreach ($e in $evidence) {

    $gap = [double]$e.gap_score
    $replication = [double]$e.replication
    $competitionGap = [double]$e.competition_gap
    $geographicGap = [double]$e.geographic_gap

    $companyCount = [int]$e.company_count
    $articleCount = [int]$e.article_count
    $countryCount = [int]$e.country_count

    # MARKET PROOF
    if ($companyCount -ge 10 -and $articleCount -ge 10) {
        $marketProof = 100
    }
    elseif ($companyCount -ge 5 -and $articleCount -ge 5) {
        $marketProof = 80
    }
    elseif ($companyCount -ge 2 -and $articleCount -ge 2) {
        $marketProof = 60
    }
    elseif ($companyCount -ge 1 -or $articleCount -ge 1) {
        $marketProof = 35
    }
    else {
        $marketProof = 0
    }

    # GEOGRAPHIC PROOF
    if ($countryCount -ge 5) {
        $geographicProof = 100
    }
    elseif ($countryCount -ge 3) {
        $geographicProof = 80
    }
    elseif ($countryCount -ge 2) {
        $geographicProof = 60
    }
    elseif ($countryCount -eq 1) {
        $geographicProof = 35
    }
    else {
        $geographicProof = 0
    }

    # CONFIDENCE
    $confidence = (
        ($marketProof * 0.55) +
        ($geographicProof * 0.20) +
        ($replication * 0.15) +
        ($competitionGap * 0.10)
    )

    # FINAL SCORE
    $finalScore = (
        ($gap * 0.40) +
        ($marketProof * 0.25) +
        ($replication * 0.15) +
        ($competitionGap * 0.10) +
        ($geographicGap * 0.10)
    )

    $finalScore = [math]::Round($finalScore)
    $confidence = [math]::Round($confidence)

    # VERDICT
    if ($companyCount -eq 0 -and $articleCount -eq 0) {
        $finalScore = [math]::Min($finalScore, 35)
        $verdict = "INSUFFICIENT EVIDENCE"
    }
    elseif ($finalScore -ge 70 -and $confidence -ge 70) {
        $verdict = "HIGH GAP"
    }
    elseif ($finalScore -ge 55 -and $confidence -ge 55) {
        $verdict = "PROMISING GAP"
    }
    elseif ($finalScore -ge 40) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "LOW"
    }

    # WHY
    if ($companyCount -eq 0 -and $articleCount -eq 0) {
        $why = "Aucune preuve source correspondant exactement au modèle et au vertical."
    }
    elseif ($companyCount -ge 5 -and $articleCount -ge 5) {
        $why = "$companyCount entreprises et $articleCount articles soutiennent ce modèle avec une réplication de $replication/100."
    }
    elseif ($companyCount -ge 2 -or $articleCount -ge 2) {
        $why = "Des preuves sources existent mais leur volume reste limité."
    }
    else {
        $why = "Signal encore faible : davantage de preuves sont nécessaires."
    }

    $result += [PSCustomObject]@{
        opportunity       = $e.opportunity
        original_category = $e.original_category
        source_cluster    = $e.source_cluster

        final_score       = $finalScore
        verdict           = $verdict
        confidence        = $confidence

        gap_score         = $gap
        market_proof      = $marketProof
        geographic_proof  = $geographicProof

        company_count     = $companyCount
        country_count     = $countryCount
        article_count     = $articleCount

        replication       = $replication
        competition_gap   = $competitionGap
        geographic_gap    = $geographicGap

        companies         = @($e.companies)
        countries         = @($e.countries)
        source_articles   = @($e.source_articles)
        signals           = @($e.signals)

        evidence_status   = $e.evidence_status
        why               = $why
    }
}

$result = @(
    $result | Sort-Object final_score -Descending
)

$result |
    ConvertTo-Json -Depth 20 |
    Set-Content .\radar20_final_opportunities.json -Encoding UTF8

Write-Host "Output : .\radar20_final_opportunities.json"
Write-Host ""

$result |
    Select-Object opportunity,final_score,verdict,confidence,company_count,article_count,replication |
    Format-Table -AutoSize

Write-Host ""
Write-Host "Final opportunities : $($result.Count)"
Write-Host "HIGH GAP            : $(($result | Where-Object { $_.verdict -eq 'HIGH GAP' }).Count)"
Write-Host "PROMISING GAP       : $(($result | Where-Object { $_.verdict -eq 'PROMISING GAP' }).Count)"
Write-Host "WATCH               : $(($result | Where-Object { $_.verdict -eq 'WATCH' }).Count)"
Write-Host "LOW                 : $(($result | Where-Object { $_.verdict -eq 'LOW' }).Count)"
Write-Host "INSUFFICIENT        : $(($result | Where-Object { $_.verdict -eq 'INSUFFICIENT EVIDENCE' }).Count)"
Write-Host ""
Write-Host "========================================"

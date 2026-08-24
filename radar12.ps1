$inputFile = ".\radar11_ranked_opportunities.json"
$outputFile = ".\radar12_final_opportunities.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

# ============================================================
# BIZNESSHUNTER - RADAR 12
# FINAL OPPORTUNITY VALIDATION ENGINE
# ============================================================

$results = foreach ($item in $data) {

    $companies   = [int]$item.company_count
    $articles    = [int]$item.article_count
    $countries   = [int]$item.country_count

    $replication  = [int]$item.avg_replication
    $capital      = [int]$item.avg_capital_risk
    $regulation   = [int]$item.avg_regulatory_risk

    $marketProof  = [int]$item.market_proof
    $nicheQuality = [int]$item.niche_quality
    $soloOpp      = [int]$item.solo_opportunity

    $model    = [string]$item.business_model
    $vertical = [string]$item.vertical
    $soloFit  = [string]$item.solo_fit

    # ========================================================
    # 1. EVIDENCE QUALITY
    # ========================================================

    # Entreprises indépendantes
    if ($companies -ge 20) {
        $companyEvidence = 100
    }
    elseif ($companies -ge 10) {
        $companyEvidence = 85
    }
    elseif ($companies -ge 5) {
        $companyEvidence = 70
    }
    elseif ($companies -ge 3) {
        $companyEvidence = 55
    }
    elseif ($companies -ge 2) {
        $companyEvidence = 35
    }
    else {
        $companyEvidence = 15
    }

    # Nombre d'articles
    if ($articles -ge 50) {
        $articleEvidence = 100
    }
    elseif ($articles -ge 20) {
        $articleEvidence = 80
    }
    elseif ($articles -ge 10) {
        $articleEvidence = 65
    }
    elseif ($articles -ge 5) {
        $articleEvidence = 50
    }
    elseif ($articles -ge 2) {
        $articleEvidence = 25
    }
    else {
        $articleEvidence = 10
    }

    # Validation géographique
    if ($countries -ge 5) {
        $geoEvidence = 100
    }
    elseif ($countries -ge 3) {
        $geoEvidence = 80
    }
    elseif ($countries -ge 2) {
        $geoEvidence = 60
    }
    elseif ($countries -eq 1) {
        $geoEvidence = 30
    }
    else {
        $geoEvidence = 0
    }

    $evidenceScore = [math]::Round(
        ($companyEvidence * 0.50) +
        ($articleEvidence * 0.25) +
        ($geoEvidence * 0.25)
    )

    # ========================================================
    # 2. SOLO SCORE
    # ========================================================

    switch ($soloFit) {
        "EXCELLENT" { $soloScore = 100 }
        "GOOD"      { $soloScore = 75 }
        "MODERATE"  { $soloScore = 50 }
        "POOR"      { $soloScore = 20 }
        default     { $soloScore = 20 }
    }

    # ========================================================
    # 3. ECONOMIC SCORE
    # ========================================================

    $capitalScore = 100 - $capital
    $regulationScore = 100 - $regulation

    $economicScore = [math]::Round(
        ($replication * 0.45) +
        ($capitalScore * 0.35) +
        ($regulationScore * 0.20)
    )

    # ========================================================
    # 4. MARKET ATTRACTIVENESS
    # ========================================================

    $attractiveness = [math]::Round(
        ($soloScore * 0.25) +
        ($economicScore * 0.30) +
        ($marketProof * 0.25) +
        ($soloOpp * 0.20)
    )

    # ========================================================
    # 5. EVIDENCE PENALTY
    # ========================================================

    # Très important :
    # une idée avec 1 article ne doit pas être classée
    # au même niveau qu'un marché documenté par 40 articles.

    if ($evidenceScore -lt 25) {
        $evidencePenalty = 25
    }
    elseif ($evidenceScore -lt 40) {
        $evidencePenalty = 15
    }
    elseif ($evidenceScore -lt 55) {
        $evidencePenalty = 8
    }
    else {
        $evidencePenalty = 0
    }

    # ========================================================
    # 6. FINAL SCORE
    # ========================================================

    $finalScore = [math]::Round(
        ($attractiveness * 0.65) +
        ($evidenceScore * 0.35) -
        $evidencePenalty
    )

    $finalScore = [math]::Max(
        0,
        [math]::Min(100, $finalScore)
    )

    # ========================================================
    # 7. CONFIDENCE
    # ========================================================

    if (
        $companies -ge 10 -and
        $articles -ge 10 -and
        $countries -ge 2
    ) {
        $confidence = "VERY HIGH"
    }
    elseif (
        $companies -ge 5 -and
        $articles -ge 5
    ) {
        $confidence = "HIGH"
    }
    elseif (
        $companies -ge 3 -and
        $articles -ge 3
    ) {
        $confidence = "MEDIUM"
    }
    else {
        $confidence = "LOW"
    }

    # ========================================================
    # 8. FINAL VERDICT
    # ========================================================

    if (
        $finalScore -ge 75 -and
        $confidence -in @("VERY HIGH","HIGH") -and
        $soloScore -ge 75
    ) {
        $verdict = "VALIDATED"
    }
    elseif (
        $finalScore -ge 70 -and
        $confidence -ge "MEDIUM"
    ) {
        $verdict = "OPPORTUNITY"
    }
    elseif (
        $attractiveness -ge 70 -and
        $confidence -eq "LOW"
    ) {
        $verdict = "EMERGING"
    }
    elseif ($finalScore -ge 50) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "REJECT"
    }

    # ========================================================
    # 9. ACTION
    # ========================================================

    switch ($verdict) {

        "VALIDATED" {
            $action = "BUILD / TEST NOW"
        }

        "OPPORTUNITY" {
            $action = "VALIDATE DEMAND"
        }

        "EMERGING" {
            $action = "COLLECT MORE EVIDENCE"
        }

        "WATCH" {
            $action = "MONITOR"
        }

        "REJECT" {
            $action = "IGNORE"
        }

        default {
            $action = "MONITOR"
        }
    }

    # ========================================================
    # 10. SIGNAL
    # ========================================================

    $signals = @()

    if ($soloScore -ge 75) {
        $signals += "SOLO"
    }

    if ($replication -ge 70) {
        $signals += "REPLICABLE"
    }

    if ($capitalScore -ge 70) {
        $signals += "LOW_CAPITAL"
    }

    if ($regulationScore -ge 70) {
        $signals += "LOW_REGULATION"
    }

    if ($companies -ge 5) {
        $signals += "MULTI_COMPANY"
    }

    if ($countries -ge 2) {
        $signals += "MULTI_COUNTRY"
    }

    if ($evidenceScore -lt 40) {
        $signals += "WEAK_EVIDENCE"
    }

    $signal = $signals -join " | "

    # ========================================================
    # OUTPUT
    # ========================================================

    [PSCustomObject]@{

        final_score = $finalScore
        verdict = $verdict
        action = $action
        confidence = $confidence

        business_model = $model
        vertical = $vertical

        solo_fit = $soloFit

        company_count = $companies
        article_count = $articles
        country_count = $countries

        evidence_score = $evidenceScore
        attractiveness_score = $attractiveness
        economic_score = $economicScore

        avg_replication = $replication
        avg_capital_risk = $capital
        avg_regulatory_risk = $regulation

        market_proof = $marketProof
        solo_opportunity = $soloOpp

        evidence_penalty = $evidencePenalty

        signal = $signal

        source_cluster = $item.source_cluster
    }
}

$results = $results |
    Sort-Object final_score -Descending

$results |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

# ============================================================
# DISPLAY
# ============================================================

Clear-Host

Write-Host ""
Write-Host "=============================================================="
Write-Host " BIZNESSHUNTER - RADAR 12"
Write-Host " FINAL OPPORTUNITY VALIDATION"
Write-Host "=============================================================="
Write-Host ""

Write-Host "Input    : $inputFile"
Write-Host "Output   : $outputFile"
Write-Host "Clusters : $($data.Count)"
Write-Host ""

Write-Host "=============================================================="
Write-Host " TOP OPPORTUNITIES"
Write-Host "=============================================================="
Write-Host ""

$results |
    Select-Object -First 30 `
        final_score,
        verdict,
        action,
        confidence,
        solo_fit,
        business_model,
        vertical,
        company_count,
        article_count,
        country_count,
        evidence_score,
        attractiveness_score,
        economic_score,
        signal |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " VALIDATED / OPPORTUNITY"
Write-Host "=============================================================="
Write-Host ""

$results |
    Where-Object {
        $_.verdict -in @("VALIDATED","OPPORTUNITY")
    } |
    Select-Object `
        final_score,
        verdict,
        confidence,
        business_model,
        vertical,
        company_count,
        article_count,
        country_count,
        solo_fit,
        evidence_score,
        signal |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " EMERGING OPPORTUNITIES"
Write-Host "=============================================================="
Write-Host ""

$results |
    Where-Object {
        $_.verdict -eq "EMERGING"
    } |
    Select-Object `
        final_score,
        verdict,
        confidence,
        business_model,
        vertical,
        company_count,
        article_count,
        country_count,
        solo_fit,
        signal |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " RADAR 12 COMPLETE"
Write-Host "=============================================================="

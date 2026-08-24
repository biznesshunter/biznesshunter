$inputFile = ".\radar10_opportunities.json"
$outputFile = ".\radar11_ranked_opportunities.json"

if (!(Test-Path $inputFile)) {
    Write-Host "ERROR: $inputFile not found"
    exit
}

$data = Get-Content $inputFile -Raw | ConvertFrom-Json

# ============================================================
# BIZNESSHUNTER - RADAR 11
# REAL SOLO OPPORTUNITY ENGINE
# ============================================================

$results = foreach ($item in $data) {

    $companies  = [int]$item.company_count
    $articles   = [int]$item.article_count
    $countries  = [int]$item.country_count

    $validation = [int]$item.market_validation
    $solo       = [int]$item.solo_opportunity

    $replication = [int]$item.avg_replication
    $capital     = [int]$item.avg_capital_risk
    $regulation  = [int]$item.avg_regulatory_risk

    $model    = [string]$item.business_model
    $vertical = [string]$item.vertical

    # ========================================================
    # 1. MARKET PROOF
    # ========================================================

    $companyProof = [math]::Min(100, $companies * 8)

    $articleProof = [math]::Min(100, $articles * 4)

    $countryProof = [math]::Min(100, $countries * 25)

    $marketProof = [math]::Round(
        ($companyProof * 0.45) +
        ($articleProof * 0.20) +
        ($countryProof * 0.35)
    )

    # ========================================================
    # 2. SMALL-SAMPLE BONUS
    # ========================================================
    # On récompense les niches où quelques entreprises
    # montrent déjà un modèle, plutôt que les énormes marchés.

    if ($companies -ge 2 -and $companies -le 10) {
        $smallSampleBonus = 15
    }
    elseif ($companies -gt 10 -and $companies -le 30) {
        $smallSampleBonus = 5
    }
    else {
        $smallSampleBonus = 0
    }

    # ========================================================
    # 3. SOLO FIT
    # ========================================================

    switch ($item.solo_fit) {

        "EXCELLENT" { $soloFit = 100 }
        "GOOD"      { $soloFit = 75 }
        "MODERATE"  { $soloFit = 50 }
        "POOR"      { $soloFit = 20 }

        default     { $soloFit = 20 }
    }

    # ========================================================
    # 4. REPLICATION
    # ========================================================

    $replicationScore = $replication

    # ========================================================
    # 5. CAPITAL
    # ========================================================

    $capitalScore = 100 - $capital

    # ========================================================
    # 6. REGULATION
    # ========================================================

    $regulationScore = 100 - $regulation

    # ========================================================
    # 7. BUSINESS MODEL FIT
    # ========================================================

    switch ($model) {

        "SOFTWARE" {
            $modelFit = 95
        }

        "SUBSCRIPTION" {
            $modelFit = 90
        }

        "MARKETPLACE" {
            $modelFit = 65
        }

        "ON_DEMAND" {
            $modelFit = 60
        }

        "DELIVERY" {
            $modelFit = 40
        }

        "RENTAL" {
            $modelFit = 45
        }

        default {
            $modelFit = 50
        }
    }

    # ========================================================
    # 8. VOLUME PENALTY
    # ========================================================
    # Évite qu'un cluster avec 200 startups gagne automatiquement.

    if ($companies -gt 100) {
        $volumePenalty = 20
    }
    elseif ($companies -gt 50) {
        $volumePenalty = 12
    }
    elseif ($companies -gt 30) {
        $volumePenalty = 7
    }
    elseif ($companies -gt 15) {
        $volumePenalty = 3
    }
    else {
        $volumePenalty = 0
    }

    # ========================================================
    # 9. NICHE QUALITY
    # ========================================================

    $nicheQuality = [math]::Round(
        ($soloFit * 0.30) +
        ($replicationScore * 0.25) +
        ($capitalScore * 0.20) +
        ($regulationScore * 0.15) +
        ($modelFit * 0.10)
    )

    # ========================================================
    # 10. FINAL BH SCORE
    # ========================================================

    $bhScore = [math]::Round(
        ($marketProof * 0.25) +
        ($nicheQuality * 0.40) +
        ($solo * 0.15) +
        ($replicationScore * 0.10) +
        ($capitalScore * 0.05) +
        ($regulationScore * 0.05) +
        $smallSampleBonus -
        $volumePenalty
    )

    $bhScore = [math]::Max(0, [math]::Min(100, $bhScore))

    # ========================================================
    # 11. VERDICT
    # ========================================================

    if (
        $bhScore -ge 75 -and
        $soloFit -ge 75 -and
        $companies -ge 2
    ) {
        $verdict = "HIGH PRIORITY"
    }
    elseif (
        $bhScore -ge 65 -and
        $soloFit -ge 50
    ) {
        $verdict = "PROMISING"
    }
    elseif ($bhScore -ge 50) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "LOW"
    }

    # ========================================================
    # 12. CONFIDENCE
    # ========================================================

    if ($companies -ge 20 -and $countries -ge 3) {
        $confidence = "HIGH"
    }
    elseif ($companies -ge 5 -or $countries -ge 2) {
        $confidence = "MEDIUM"
    }
    else {
        $confidence = "LOW"
    }

    # ========================================================
    # 13. SIGNAL
    # ========================================================

    $signal = ""

    if ($soloFit -ge 75) {
        $signal += "solo-friendly / "
    }

    if ($replicationScore -ge 70) {
        $signal += "highly replicable / "
    }

    if ($capitalScore -ge 70) {
        $signal += "low capital / "
    }

    if ($regulationScore -ge 70) {
        $signal += "low regulation / "
    }

    if ($companies -ge 2 -and $companies -le 10) {
        $signal += "validated niche / "
    }

    if ($countries -ge 2) {
        $signal += "multi-country / "
    }

    $signal = $signal.TrimEnd(" ","/")

    # ========================================================
    # OUTPUT
    # ========================================================

    [PSCustomObject]@{

        bh_score = $bhScore
        verdict = $verdict
        confidence = $confidence

        solo_fit = $item.solo_fit

        business_model = $model
        vertical = $vertical

        company_count = $companies
        article_count = $articles
        country_count = $countries

        market_proof = $marketProof
        niche_quality = $nicheQuality

        solo_opportunity = $solo
        avg_replication = $replication
        avg_capital_risk = $capital
        avg_regulatory_risk = $regulation

        small_sample_bonus = $smallSampleBonus
        volume_penalty = $volumePenalty

        signal = $signal

        source_cluster = $item.cluster_name
    }
}

$results = $results |
    Sort-Object bh_score -Descending

$results |
    ConvertTo-Json -Depth 10 |
    Set-Content $outputFile -Encoding UTF8

# ============================================================
# DISPLAY
# ============================================================

Clear-Host

Write-Host ""
Write-Host "=============================================================="
Write-Host " BIZNESSHUNTER - RADAR 11"
Write-Host " REAL SOLO OPPORTUNITY RANKING"
Write-Host "=============================================================="
Write-Host ""

Write-Host "Input    : $inputFile"
Write-Host "Output   : $outputFile"
Write-Host "Clusters : $($data.Count)"
Write-Host ""

Write-Host "TOP OPPORTUNITIES"
Write-Host "--------------------------------------------------------------"

$results |
    Select-Object -First 30 `
        bh_score,
        verdict,
        confidence,
        solo_fit,
        business_model,
        vertical,
        company_count,
        article_count,
        country_count,
        market_proof,
        niche_quality,
        avg_replication,
        avg_capital_risk,
        avg_regulatory_risk,
        signal |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " TOP SOLO OPPORTUNITIES"
Write-Host "=============================================================="

$results |
    Where-Object {
        $_.solo_fit -in @("EXCELLENT","GOOD") -and
        $_.bh_score -ge 50
    } |
    Select-Object -First 15 `
        bh_score,
        verdict,
        confidence,
        business_model,
        vertical,
        company_count,
        article_count,
        country_count,
        avg_replication,
        avg_capital_risk,
        avg_regulatory_risk,
        signal |
    Format-Table -Wrap -AutoSize

Write-Host ""
Write-Host "=============================================================="
Write-Host " RADAR 11 COMPLETE"
Write-Host "=============================================================="

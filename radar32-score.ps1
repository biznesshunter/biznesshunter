Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 32"
Write-Host " CLIENT FIT"
Write-Host "========================================"
Write-Host ""

$raw = Get-Content .\radar29_opportunities.json -Raw | ConvertFrom-Json
$items = @($raw)

Write-Host "Input opportunities : $($items.Count)"
Write-Host ""

function Clamp-Score {
    param([double]$Value)

    if ($Value -lt 0) { return 0 }
    if ($Value -gt 100) { return 100 }

    return [math]::Round($Value)
}

$feed = @()

foreach ($item in $items) {

    $proof      = [double]$item.proof_score
    $solo       = [double]$item.solo_score
    $automation = [double]$item.automation_score
    $b2c        = [double]$item.b2c_score
    $capital    = [double]$item.capital_score
    $economics  = [double]$item.launch_economics
    $wtp        = [double]$item.willingness_to_pay
    $confidence = [double]$item.confidence

    $companies = [int]$item.company_count
    $articles  = [int]$item.article_count

    # ========================================
    # 1. DEMAND
    # ========================================

    $demand = (
        ($proof * 0.45) +
        ($wtp * 0.30) +
        ($b2c * 0.15) +
        ($confidence * 0.10)
    )

    $demand = Clamp-Score $demand

    # ========================================
    # 2. PROOF QUALITY
    # ========================================

    $proofQuality = $proof

    if ($companies -ge 50) {
        $proofQuality += 10
    }
    elseif ($companies -ge 10) {
        $proofQuality += 7
    }
    elseif ($companies -ge 5) {
        $proofQuality += 4
    }
    elseif ($companies -ge 2) {
        $proofQuality += 2
    }

    if ($articles -ge 100) {
        $proofQuality += 8
    }
    elseif ($articles -ge 20) {
        $proofQuality += 5
    }
    elseif ($articles -ge 5) {
        $proofQuality += 2
    }

    $proofQuality = Clamp-Score $proofQuality

    # ========================================
    # 3. CLIENT ATTRACTIVENESS
    # ========================================

    $clientAttractiveness = (
        ($demand * 0.35) +
        ($b2c * 0.20) +
        ($wtp * 0.20) +
        ($proofQuality * 0.15) +
        ($confidence * 0.10)
    )

    $clientAttractiveness = Clamp-Score $clientAttractiveness

    # ========================================
    # 4. EXECUTION FIT
    # ========================================

    $executionFit = (
        ($solo * 0.25) +
        ($automation * 0.25) +
        ($capital * 0.20) +
        ($economics * 0.20) +
        ($confidence * 0.10)
    )

    $executionFit = Clamp-Score $executionFit

    # ========================================
    # 5. FINAL CLIENT SCORE
    # ========================================

    $clientFit = (
        ($proofQuality * 0.30) +
        ($clientAttractiveness * 0.35) +
        ($executionFit * 0.35)
    )

    # ========================================
    # HARD PROOF CAPS
    # ========================================

    if ($proof -eq 0) {
        $clientFit = [math]::Min($clientFit, 39)
    }
    elseif ($proof -lt 20) {
        $clientFit = [math]::Min($clientFit, 49)
    }
    elseif ($proof -lt 40) {
        $clientFit = [math]::Min($clientFit, 59)
    }

    $clientFit = Clamp-Score $clientFit

    # ========================================
    # VERDICT
    # ========================================

    if (
        $proof -ge 70 -and
        $clientFit -ge 75
    ) {
        $verdict = "TOP OPPORTUNITY"
    }
    elseif (
        $proof -ge 60 -and
        $clientFit -ge 65
    ) {
        $verdict = "STRONG"
    }
    elseif (
        $proof -ge 50 -and
        $clientFit -ge 55
    ) {
        $verdict = "PROMISING"
    }
    elseif (
        $proof -ge 30 -and
        $clientFit -ge 40
    ) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "WEAK"
    }

    $feed += [PSCustomObject]@{
        rank                  = $item.rank
        opportunity           = $item.opportunity
        category              = $item.category
        source_cluster        = $item.source_cluster

        client_fit_score      = $clientFit
        client_verdict        = $verdict

        demand_score          = $demand
        proof_score           = $proof
        proof_quality         = $proofQuality
        client_attractiveness = $clientAttractiveness
        execution_fit         = $executionFit

        solo_score            = $solo
        automation_score      = $automation
        b2c_score             = $b2c
        capital_score         = $capital
        launch_economics      = $economics
        willingness_to_pay    = $wtp
        confidence            = $confidence

        company_count         = $companies
        article_count         = $articles

        companies             = @($item.companies)
        countries             = @($item.countries)
        why                   = $item.why
        source_articles       = @($item.source_articles)
        signals               = @($item.signals)
    }
}

$feed = @(
    $feed |
    Sort-Object client_fit_score -Descending
)

for ($i = 0; $i -lt $feed.Count; $i++) {
    $feed[$i].rank = $i + 1
}

$feed |
    ConvertTo-Json -Depth 20 |
    Set-Content .\radar32_client_opportunities.json -Encoding UTF8

Write-Host ""
Write-Host "Output : .\radar32_client_opportunities.json"
Write-Host ""

$feed |
    Select-Object `
        rank,
        opportunity,
        client_fit_score,
        client_verdict,
        demand_score,
        proof_quality,
        client_attractiveness,
        execution_fit |
    Format-Table -AutoSize

Write-Host ""
Write-Host "========================================"
Write-Host " Radar 32 completed"
Write-Host "========================================"

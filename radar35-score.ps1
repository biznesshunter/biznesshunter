Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 35"
Write-Host " BUSINESS QUALITY + SCALE FIT"
Write-Host "========================================"
Write-Host ""

$raw = Get-Content .\radar33_passive_opportunities.json -Raw | ConvertFrom-Json
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
    $clientFit  = [double]$item.client_fit_score
    $passivity  = [double]$item.passivity_score
    $automation = [double]$item.automation_score
    $solo       = [double]$item.solo_score
    $capital    = [double]$item.capital_score
    $economics  = [double]$item.launch_economics
    $b2c        = [double]$item.b2c_score
    $confidence = [double]$item.confidence
    $wtp        = [double]$item.willingness_to_pay

    $companies = [int]$item.company_count
    $articles  = [int]$item.article_count

    $text = @(
        $item.opportunity
        $item.category
        $item.source_cluster
        $item.why
    ) -join " "

    $text = $text.ToLower()

    # ========================================
    # 1. REVENUE POTENTIAL
    # ========================================

    $revenuePotential = (
        ($clientFit * 0.35) +
        ($wtp * 0.25) +
        ($economics * 0.20) +
        ($b2c * 0.10) +
        ($confidence * 0.10)
    )

    # Transactions pouvant être répétées
    $recurringKeywords = @(
        "location",
        "réservation",
        "abonnement",
        "récurrent",
        "récurrente",
        "mensuel",
        "monthly",
        "subscription",
        "repeat",
        "recurrent"
    )

    foreach ($keyword in $recurringKeywords) {
        if ($text -like "*$keyword*") {
            $revenuePotential += 4
        }
    }

    $revenuePotential = Clamp-Score $revenuePotential

    # ========================================
    # 2. MARGIN FIT
    # ========================================

    $marginFit = (
        ($passivity * 0.30) +
        ($automation * 0.25) +
        ($economics * 0.25) +
        ($capital * 0.20)
    )

    $lowMarginKeywords = @(
        "livraison",
        "transport",
        "restaurant",
        "commerce",
        "magasin",
        "véhicule",
        "véhicules",
        "chantier",
        "construction"
    )

    foreach ($keyword in $lowMarginKeywords) {
        if ($text -like "*$keyword*") {
            $marginFit -= 5
        }
    }

    $marginFit = Clamp-Score $marginFit

    # ========================================
    # 3. SCALE FIT
    # ========================================

    $scaleFit = (
        ($automation * 0.25) +
        ($passivity * 0.25) +
        ($clientFit * 0.20) +
        ($economics * 0.15) +
        ($b2c * 0.10) +
        ($confidence * 0.05)
    )

    $scaleKeywords = @(
        "location",
        "plateforme",
        "marketplace",
        "mise en relation",
        "réservation",
        "booking",
        "en ligne",
        "online",
        "digital",
        "saas",
        "software"
    )

    foreach ($keyword in $scaleKeywords) {
        if ($text -like "*$keyword*") {
            $scaleFit += 5
        }
    }

    $scaleFit = Clamp-Score $scaleFit

    # ========================================
    # 4. OPERATIONAL LEVERAGE
    # ========================================

    $operationalLeverage = (
        ($automation * 0.35) +
        ($solo * 0.25) +
        ($passivity * 0.25) +
        ($capital * 0.15)
    )

    $operationalLeverage = Clamp-Score $operationalLeverage

    # ========================================
    # 5. BUSINESS QUALITY
    # ========================================

    $businessQuality = (
        ($proof * 0.25) +
        ($clientFit * 0.20) +
        ($revenuePotential * 0.15) +
        ($marginFit * 0.15) +
        ($scaleFit * 0.15) +
        ($operationalLeverage * 0.10)
    )

    # ========================================
    # 6. PROOF MULTIPLICITY BONUS
    # ========================================

    if ($companies -ge 50) {
        $businessQuality += 5
    }
    elseif ($companies -ge 10) {
        $businessQuality += 3
    }
    elseif ($companies -ge 5) {
        $businessQuality += 2
    }

    if ($articles -ge 100) {
        $businessQuality += 3
    }
    elseif ($articles -ge 20) {
        $businessQuality += 2
    }

    $businessQuality = Clamp-Score $businessQuality

    # ========================================
    # 7. HARD PROOF CAPS
    # ========================================

    if ($proof -eq 0) {
        $businessQuality = [math]::Min($businessQuality, 39)
    }
    elseif ($proof -lt 20) {
        $businessQuality = [math]::Min($businessQuality, 49)
    }
    elseif ($proof -lt 40) {
        $businessQuality = [math]::Min($businessQuality, 59)
    }

    # ========================================
    # 8. REVENUE BAND
    # ========================================

    if ($revenuePotential -ge 75) {
        $revenueBand = "HIGH"
    }
    elseif ($revenuePotential -ge 55) {
        $revenueBand = "MEDIUM"
    }
    else {
        $revenueBand = "LOW"
    }

    # ========================================
    # 9. €2K/MONTH INDICATOR
    # ========================================
    # INDICATEUR SECONDAIRE UNIQUEMENT.
    # Il ne modifie PAS le score business.

    if (
        $revenuePotential -ge 75 -and
        $scaleFit -ge 65 -and
        $clientFit -ge 65
    ) {
        $twoKPotential = "EASY"
    }
    elseif (
        $revenuePotential -ge 60 -and
        $scaleFit -ge 55
    ) {
        $twoKPotential = "POSSIBLE"
    }
    else {
        $twoKPotential = "DIFFICULT"
    }

    # ========================================
    # 10. VERDICT
    # ========================================

    if (
        $proof -ge 70 -and
        $businessQuality -ge 75 -and
        $scaleFit -ge 65
    ) {
        $verdict = "TOP BUSINESS"
    }
    elseif (
        $proof -ge 60 -and
        $businessQuality -ge 65
    ) {
        $verdict = "STRONG BUSINESS"
    }
    elseif (
        $proof -ge 40 -and
        $businessQuality -ge 55
    ) {
        $verdict = "PROMISING"
    }
    elseif ($businessQuality -ge 40) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "REJECT"
    }

    $feed += [PSCustomObject]@{

        rank                    = $item.rank
        opportunity             = $item.opportunity
        category                = $item.category
        source_cluster          = $item.source_cluster

        business_quality_score  = $businessQuality
        business_verdict        = $verdict

        revenue_potential       = $revenuePotential
        revenue_band            = $revenueBand
        two_k_month_potential   = $twoKPotential

        margin_fit              = $marginFit
        scale_fit               = $scaleFit
        operational_leverage    = $operationalLeverage

        proof_score             = $proof
        client_fit_score        = $clientFit
        passivity_score         = $passivity
        automation_score        = $automation
        solo_score              = $solo
        capital_score           = $capital
        launch_economics        = $economics
        b2c_score               = $b2c
        willingness_to_pay      = $wtp
        confidence              = $confidence

        company_count           = $companies
        article_count           = $articles

        companies               = @($item.companies)
        countries               = @($item.countries)
        why                     = $item.why
        source_articles         = @($item.source_articles)
        signals                 = @($item.signals)
    }
}

# ========================================
# SORT
# ========================================

$feed = @(
    $feed |
    Sort-Object business_quality_score -Descending
)

for ($i = 0; $i -lt $feed.Count; $i++) {
    $feed[$i].rank = $i + 1
}

# ========================================
# OUTPUT
# ========================================

$feed |
    ConvertTo-Json -Depth 20 |
    Set-Content .\radar35_business_opportunities.json -Encoding UTF8

Write-Host ""
Write-Host "Output : .\radar35_business_opportunities.json"
Write-Host ""

$feed |
    Select-Object `
        rank,
        opportunity,
        business_quality_score,
        business_verdict,
        revenue_potential,
        revenue_band,
        twoK_month_potential,
        margin_fit,
        scale_fit,
        operational_leverage |
    Format-Table -AutoSize

Write-Host ""
Write-Host "========================================"
Write-Host " Radar 35 completed"
Write-Host "========================================"

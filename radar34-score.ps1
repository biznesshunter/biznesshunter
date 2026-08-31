Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 34"
Write-Host " ECONOMIC + SCALE FIT"
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

    $passive    = [double]$item.passive_business_fit
    $clientFit  = [double]$item.client_fit_score
    $proof      = [double]$item.proof_score
    $economics  = [double]$item.launch_economics
    $capital    = [double]$item.capital_score
    $automation = [double]$item.automation_score
    $solo       = [double]$item.solo_score
    $b2c        = [double]$item.b2c_score
    $wtp        = [double]$item.willingness_to_pay
    $confidence = [double]$item.confidence

    $text = @(
        $item.opportunity
        $item.category
        $item.source_cluster
        $item.why
    ) -join " "

    $text = $text.ToLower()

    # ========================================
    # 1. MARGIN POTENTIAL
    # ========================================

    $margin = 50

    $highMargin = @(
        "location",
        "réservation",
        "plateforme",
        "marketplace",
        "mise en relation",
        "en ligne",
        "digital",
        "saas",
        "software"
    )

    foreach ($keyword in $highMargin) {
        if ($text -like "*$keyword*") {
            $margin += 6
        }
    }

    $lowMargin = @(
        "livraison",
        "transport",
        "réparation",
        "dépannage",
        "montage",
        "nettoyage",
        "intervention",
        "à domicile",
        "garde",
        "promenade"
    )

    foreach ($keyword in $lowMargin) {
        if ($text -like "*$keyword*") {
            $margin -= 7
        }
    }

    $margin = Clamp-Score $margin

    # ========================================
    # 2. REVENUE FREQUENCY
    # ========================================

    $frequency = 45

    $recurring = @(
        "location",
        "réservation",
        "mensuel",
        "mensuelle",
        "abonnement",
        "récurrent",
        "récurrence",
        "régulier",
        "professionnel",
        "besoins ponctuels"
    )

    foreach ($keyword in $recurring) {
        if ($text -like "*$keyword*") {
            $frequency += 6
        }
    }

    $frequency = Clamp-Score $frequency

    # ========================================
    # 3. SCALABILITY
    # ========================================

    $scalability = (
        ($automation * 0.35) +
        ($capital * 0.20) +
        ($solo * 0.15) +
        ($margin * 0.20) +
        ($frequency * 0.10)
    )

    $scalability = Clamp-Score $scalability

    # ========================================
    # 4. ECONOMIC QUALITY
    # ========================================

    $economicQuality = (
        ($economics * 0.25) +
        ($margin * 0.25) +
        ($frequency * 0.20) +
        ($scalability * 0.20) +
        ($wtp * 0.10)
    )

    $economicQuality = Clamp-Score $economicQuality

    # ========================================
    # 5. FINAL BUSINESS FIT
    # ========================================

    $businessFit = (
        ($proof * 0.20) +
        ($clientFit * 0.20) +
        ($passive * 0.25) +
        ($economicQuality * 0.25) +
        ($scalability * 0.10)
    )

    # ========================================
    # HARD CAPS
    # ========================================

    # Sans preuve sérieuse : pas de business prioritaire
    if ($proof -eq 0) {
        $businessFit = [math]::Min($businessFit, 39)
    }
    elseif ($proof -lt 20) {
        $businessFit = [math]::Min($businessFit, 49)
    }

    # Pas suffisamment passif
    if ($passive -lt 40) {
        $businessFit = [math]::Min($businessFit, 59)
    }

    # Très faible automatisation
    if ($automation -lt 40) {
        $businessFit = [math]::Min($businessFit, 54)
    }

    # Mauvais client fit
    if ($clientFit -lt 40) {
        $businessFit = [math]::Min($businessFit, 54)
    }

    $businessFit = Clamp-Score $businessFit

    # ========================================
    # VERDICT FINAL
    # ========================================

    if (
        $proof -ge 70 -and
        $passive -ge 70 -and
        $clientFit -ge 70 -and
        $economicQuality -ge 70 -and
        $businessFit -ge 75
    ) {
        $verdict = "PRIORITY BUSINESS"
    }
    elseif (
        $proof -ge 60 -and
        $passive -ge 60 -and
        $clientFit -ge 60 -and
        $businessFit -ge 65
    ) {
        $verdict = "STRONG BUSINESS"
    }
    elseif (
        $proof -ge 50 -and
        $businessFit -ge 55
    ) {
        $verdict = "VALIDATE"
    }
    elseif (
        $businessFit -ge 40
    ) {
        $verdict = "WATCH"
    }
    else {
        $verdict = "REJECT"
    }

    $feed += [PSCustomObject]@{

        rank                  = $item.rank
        opportunity           = $item.opportunity
        category              = $item.category
        source_cluster        = $item.source_cluster

        business_fit_score    = $businessFit
        business_verdict      = $verdict

        proof_score           = $proof
        client_fit_score      = $clientFit
        passive_fit_score     = $passive

        economic_quality      = $economicQuality
        margin_score          = $margin
        frequency_score       = $frequency
        scalability_score     = $scalability

        launch_economics      = $economics
        capital_score         = $capital
        automation_score      = $automation
        solo_score            = $solo
        b2c_score             = $b2c
        willingness_to_pay    = $wtp
        confidence            = $confidence

        company_count         = $item.company_count
        article_count         = $item.article_count

        companies             = @($item.companies)
        countries             = @($item.countries)
        why                   = $item.why
        source_articles       = @($item.source_articles)
        signals               = @($item.signals)
    }
}

# ========================================
# SORT
# ========================================

$feed = @(
    $feed |
    Sort-Object business_fit_score -Descending
)

for ($i = 0; $i -lt $feed.Count; $i++) {
    $feed[$i].rank = $i + 1
}

# ========================================
# OUTPUT
# ========================================

$feed |
    ConvertTo-Json -Depth 20 |
    Set-Content .\radar34_business_opportunities.json -Encoding UTF8

Write-Host ""
Write-Host "Output : .\radar34_business_opportunities.json"
Write-Host ""

$feed |
    Select-Object `
        rank,
        opportunity,
        business_fit_score,
        business_verdict,
        proof_score,
        client_fit_score,
        passive_fit_score,
        economic_quality,
        margin_score,
        frequency_score,
        scalability_score |
    Format-Table -AutoSize

Write-Host ""
Write-Host "========================================"
Write-Host " Radar 34 completed"
Write-Host "========================================"

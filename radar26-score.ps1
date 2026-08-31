Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 26"
Write-Host " CAPITAL EFFICIENCY"
Write-Host "========================================"
Write-Host ""

$raw = Get-Content .\radar25_opportunities.json -Raw | ConvertFrom-Json
$items = @($raw)

Write-Host "Input opportunities : $($items.Count)"
Write-Host ""

function Clamp-Score {
    param([double]$Value)
    if ($Value -lt 0) { return 0 }
    if ($Value -gt 100) { return 100 }
    return [math]::Round($Value)
}

function Get-LaunchCostScore {
    param($item)

    $text = @(
        $item.opportunity
        $item.category
        $item.source_cluster
        $item.why
    ) -join " "

    $text = $text.ToLower()

    # Estimation structurelle du coût initial.
    # Ce n'est PAS un filtre absolu.
    $score = 70

    $cheap = @(
        "marketplace",
        "plateforme",
        "réservation",
        "booking",
        "en ligne",
        "online",
        "digital",
        "mise en relation",
        "location",
        "à la demande",
        "on-demand",
        "saas",
        "software"
    )

    foreach ($keyword in $cheap) {
        if ($text -like "*$keyword*") {
            $score += 4
        }
    }

    $expensive = @(
        "restaurant",
        "hôtel",
        "hotel",
        "commerce",
        "magasin",
        "atelier",
        "usine",
        "garage",
        "clinique",
        "construction",
        "chantier",
        "véhicule",
        "véhicules",
        "équipement lourd",
        "entrepôt",
        "warehouse",
        "livraison"
    )

    foreach ($keyword in $expensive) {
        if ($text -like "*$keyword*") {
            $score -= 10
        }
    }

    return Clamp-Score $score
}

function Get-WillingnessToPayScore {
    param($item)

    $text = @(
        $item.opportunity
        $item.category
        $item.source_cluster
        $item.why
    ) -join " "

    $text = $text.ToLower()

    $score = 50

    $highValue = @(
        "automobile",
        "automobile",
        "réparation",
        "services domestiques",
        "petits travaux",
        "location",
        "équipement",
        "véhicule",
        "vétérinaire",
        "professionnel",
        "urgent",
        "à la demande"
    )

    foreach ($keyword in $highValue) {
        if ($text -like "*$keyword*") {
            $score += 6
        }
    }

    $lowValue = @(
        "gratuit",
        "social",
        "contenu",
        "information",
        "comparateur"
    )

    foreach ($keyword in $lowValue) {
        if ($text -like "*$keyword*") {
            $score -= 7
        }
    }

    return Clamp-Score $score
}

$feed = @()

foreach ($item in $items) {

    $launchCost = Get-LaunchCostScore $item
    $willingness = Get-WillingnessToPayScore $item

    $proof = [double]$item.proof_score
    $gap = [double]$item.gap_score
    $solo = [double]$item.solo_score
    $b2c = [double]$item.b2c_score
    $automation = [double]$item.automation_score
    $capital = [double]$item.capital_score

    # Économie de lancement :
    # faible coût + capacité de monétisation.
    $economics = (($launchCost * 0.35) + ($willingness * 0.65))

    $economics = Clamp-Score $economics

    # Score V24.
    $opportunityScore = (
        ($proof * 0.25) +
        ($gap * 0.20) +
        ($solo * 0.15) +
        ($automation * 0.10) +
        ($b2c * 0.05) +
        ($capital * 0.05) +
        ($economics * 0.20)
    )

    $opportunityScore = Clamp-Score $opportunityScore

    if (
        $proof -ge 70 -and
        $solo -ge 65 -and
        $automation -ge 65 -and
        $economics -ge 70
    ) {
        $verdict = "LAUNCH CANDIDATE"
    }
    elseif (
        $proof -ge 50 -and
        $economics -ge 60
    ) {
        $verdict = "VALIDATE"
    }
    elseif ($proof -lt 40) {
        $verdict = "INSUFFICIENT PROOF"
    }
    else {
        $verdict = "WATCH"
    }

    $feed += [PSCustomObject]@{
        rank                 = $item.rank
        opportunity          = $item.opportunity
        category             = $item.category
        source_cluster       = $item.source_cluster

        opportunity_score    = $opportunityScore
        verdict              = $verdict

        proof_score          = $proof
        gap_score            = $gap
        solo_score           = $solo
        b2c_score            = $b2c
        automation_score     = $automation
        capital_score        = $capital

        launch_cost_score    = $launchCost
        willingness_to_pay   = $willingness
        launch_economics     = $economics

        company_count        = $item.company_count
        article_count        = $item.article_count
        confidence           = $item.confidence

        companies            = @($item.companies)
        countries            = @($item.countries)
        why                  = $item.why
        source_articles      = @($item.source_articles)
        signals              = @($item.signals)
    }
}

$feed = @(
    $feed |
    Sort-Object opportunity_score -Descending
)

for ($i = 0; $i -lt $feed.Count; $i++) {
    $feed[$i].rank = $i + 1
}

$feed |
    ConvertTo-Json -Depth 20 |
    Set-Content .\radar26_opportunities.json -Encoding UTF8

Write-Host ""
Write-Host "Output : .\radar26_opportunities.json"
Write-Host ""

$feed |
    Select-Object rank,opportunity,opportunity_score,verdict,launch_cost_score,willingness_to_pay,launch_economics |
    Format-Table -AutoSize

Write-Host ""
Write-Host "========================================"
Write-Host " Radar 26 completed"
Write-Host "========================================"







Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 23"
Write-Host " SOLO + AUTOMATION + B2C"
Write-Host "========================================"
Write-Host ""

$raw = Get-Content .\radar22_opportunities.json -Raw | ConvertFrom-Json
$items = @($raw)

Write-Host "Input opportunities : $($items.Count)"
Write-Host ""

function Clamp-Score {
    param([double]$Value)

    if ($Value -lt 0) { return 0 }
    if ($Value -gt 100) { return 100 }
    return [math]::Round($Value)
}

function Get-SoloScore {
    param($item)

    $text = @(
        $item.opportunity
        $item.category
        $item.source_cluster
        $item.why
    ) -join " "

    $text = $text.ToLower()
    $score = 55

    $positive = @(
        "marketplace",
        "plateforme",
        "réservation",
        "booking",
        "online",
        "en ligne",
        "digital",
        "mise en relation",
        "location",
        "à la demande",
        "on-demand",
        "saas",
        "software"
    )

    foreach ($keyword in $positive) {
        if ($text -like "*$keyword*") {
            $score += 5
        }
    }

    $negative = @(
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
        "artisan",
        "intervention",
        "livraison",
        "nettoyage",
        "réparation",
        "soins",
        "garde",
        "véhicule",
        "véhicules",
        "équipement lourd",
        "entrepôt",
        "warehouse"
    )

    foreach ($keyword in $negative) {
        if ($text -like "*$keyword*") {
            $score -= 8
        }
    }

    return Clamp-Score $score
}

function Get-B2CScore {
    param($item)

    $text = @(
        $item.opportunity
        $item.category
        $item.source_cluster
        $item.why
    ) -join " "

    $text = $text.ToLower()
    $score = 50

    $positive = @(
        "local",
        "locaux",
        "particuliers",
        "particulier",
        "consommateur",
        "maison",
        "domestique",
        "animaux",
        "enfant",
        "automobile",
        "réservation",
        "location",
        "service"
    )

    foreach ($keyword in $positive) {
        if ($text -like "*$keyword*") {
            $score += 5
        }
    }

    return Clamp-Score $score
}

function Get-AutomationScore {
    param($item)

    if ($item.automation_score -ne $null) {
        return Clamp-Score ([double]$item.automation_score)
    }

    return 50
}

$feed = @()

foreach ($item in $items) {

    $solo = Get-SoloScore $item
    $b2c = Get-B2CScore $item
    $automation = Get-AutomationScore $item

    $launch = [double]$item.launch_score
    $proof = [double]$item.proof_score
    $gap = [double]$item.gap_score
    $homeScore = [double]$item.home_score
    $capital = [double]$item.capital_score

    # Score final V23 :
    # preuve + gap restent prioritaires.
    # Solo / B2C / automatisation deviennent des critères de sélection.
    $soloFit = (
        ($solo * 0.45) +
        ($b2c * 0.20) +
        ($automation * 0.35)
    )

    $soloFit = Clamp-Score $soloFit

    $opportunityScore = (
        ($proof * 0.25) +
        ($gap * 0.20) +
        ($homeScore * 0.15) +
        ($capital * 0.10) +
        ($automation * 0.10) +
        ($solo * 0.10) +
        ($b2c * 0.05) +
        ($launch * 0.05)
    )

    $opportunityScore = Clamp-Score $opportunityScore

    if (
        $proof -ge 70 -and
        $solo -ge 70 -and
        $automation -ge 70 -and
        $b2c -ge 60
    ) {
        $verdict = "BEST FIT"
    }
    elseif (
        $proof -ge 55 -and
        $solo -ge 60 -and
        $automation -ge 60
    ) {
        $verdict = "STRONG FIT"
    }
    elseif ($proof -lt 40) {
        $verdict = "INSUFFICIENT PROOF"
    }
    else {
        $verdict = "WATCH"
    }

    $feed += [PSCustomObject]@{
        rank              = $item.rank
        opportunity       = $item.opportunity
        category          = $item.category
        source_cluster    = $item.source_cluster

        opportunity_score = $opportunityScore

        proof_score       = $proof
        gap_score         = $gap
        home_score        = $homeScore
        capital_score     = $capital
        automation_score  = $automation
        solo_score        = $solo
        b2c_score         = $b2c
        solo_fit          = $soloFit
        launch_score      = $launch

        verdict            = $verdict

        company_count      = $item.company_count
        article_count      = $item.article_count
        confidence         = $item.confidence

        companies          = @($item.companies)
        countries          = @($item.countries)
        why                = $item.why
        source_articles    = @($item.source_articles)
        signals            = @($item.signals)
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
    Set-Content .\radar23_opportunities.json -Encoding UTF8

Write-Host ""
Write-Host "Output : .\radar23_opportunities.json"
Write-Host ""

$feed |
    Select-Object rank,opportunity,opportunity_score,verdict,proof_score,gap_score,solo_score,b2c_score,automation_score |
    Format-Table -AutoSize

Write-Host ""
Write-Host "========================================"
Write-Host " Radar 23 completed"
Write-Host "========================================"

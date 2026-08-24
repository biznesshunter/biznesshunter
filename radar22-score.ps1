Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 22"
Write-Host " PROVEN + GAP + HOME LAUNCH"
Write-Host "========================================"
Write-Host ""

$raw = Get-Content .\radar21_final_feed.json -Raw | ConvertFrom-Json
$items = @($raw)

Write-Host "Input opportunities : $($items.Count)"
Write-Host ""

function Clamp-Score {
    param([double]$Value)

    if ($Value -lt 0) { return 0 }
    if ($Value -gt 100) { return 100 }
    return [math]::Round($Value)
}

function Get-ProofScore {
    param($item)

    $score = 0

    # Qualité / volume des preuves déjà disponibles dans V21
    $score += [math]::Min([double]$item.company_count * 7, 35)
    $score += [math]::Min([double]$item.article_count * 4, 25)

    if ($item.market_proof -ne $null) {
        $score += [double]$item.market_proof * 0.20
    }

    if ($item.geographic_proof -ne $null) {
        $score += [double]$item.geographic_proof * 0.20
    }

    return Clamp-Score $score
}

function Get-HomeScore {
    param($item)

    $text = @(
        $item.opportunity
        $item.category
        $item.source_cluster
        $item.why
    ) -join " "

    $text = $text.ToLower()

    $score = 55

    # Signaux fortement compatibles avec une activité pilotable depuis chez soi
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
        "software",
        "saas"
    )

    foreach ($keyword in $positive) {
        if ($text -like "*$keyword*") {
            $score += 5
        }
    }

    # Signaux nécessitant généralement une présence physique importante
    $negative = @(
        "restaurant",
        "hôtel",
        "hotel",
        "commerce",
        "magasin",
        "atelier",
        "usine",
        "construction",
        "chantier",
        "garage",
        "clinique",
        "salon de coiffure",
        "entrepôt",
        "warehouse"
    )

    foreach ($keyword in $negative) {
        if ($text -like "*$keyword*") {
            $score -= 12
        }
    }

    return Clamp-Score $score
}

function Get-CapitalScore {
    param($item)

    $text = @(
        $item.opportunity
        $item.category
        $item.source_cluster
        $item.why
    ) -join " "

    $text = $text.ToLower()

    $score = 65

    $positive = @(
        "marketplace",
        "plateforme",
        "réservation",
        "booking",
        "mise en relation",
        "digital",
        "online",
        "en ligne",
        "location",
        "service"
    )

    foreach ($keyword in $positive) {
        if ($text -like "*$keyword*") {
            $score += 4
        }
    }

    $negative = @(
        "restaurant",
        "commerce",
        "magasin",
        "stock",
        "véhicule",
        "véhicules",
        "atelier",
        "usine",
        "entrepôt",
        "équipement lourd"
    )

    foreach ($keyword in $negative) {
        if ($text -like "*$keyword*") {
            $score -= 10
        }
    }

    return Clamp-Score $score
}

function Get-AutomationScore {
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
        "marketplace",
        "plateforme",
        "réservation",
        "booking",
        "online",
        "en ligne",
        "digital",
        "location",
        "mise en relation",
        "à la demande",
        "on-demand",
        "saas"
    )

    foreach ($keyword in $positive) {
        if ($text -like "*$keyword*") {
            $score += 7
        }
    }

    $negative = @(
        "artisan",
        "intervention",
        "chantier",
        "construction",
        "nettoyage",
        "livraison",
        "réparation",
        "soins",
        "garde"
    )

    foreach ($keyword in $negative) {
        if ($text -like "*$keyword*") {
            $score -= 5
        }
    }

    return Clamp-Score $score
}

function Get-GapScore {
    param($item)

    if ($item.gap_score -ne $null) {
        return Clamp-Score ([double]$item.gap_score)
    }

    if ($item.replication -ne $null) {
        return Clamp-Score ([double]$item.replication)
    }

    return 0
}

$feed = @()

foreach ($item in $items) {

    $proof = Get-ProofScore $item
    $gap = Get-GapScore $item
    $homeScore = Get-HomeScore $item
    $capital = Get-CapitalScore $item
    $automation = Get-AutomationScore $item

    # Launch = combinaison de home + capital + automation
    $launch = (
        ($homeScore * 0.40) +
        ($capital * 0.25) +
        ($automation * 0.35)
    )

    $launch = Clamp-Score $launch

    # Nouveau score principal.
    # La preuve reste volontairement dominante.
    $opportunityScore = (
        ($proof * 0.30) +
        ($gap * 0.25) +
        ($homeScore * 0.20) +
        ($capital * 0.10) +
        ($automation * 0.10) +
        ($launch * 0.05)
    )

    $opportunityScore = Clamp-Score $opportunityScore

    if (
        $proof -ge 70 -and
        $gap -ge 75 -and
        $homeScore -ge 70
    ) {
        $launchVerdict = "HIGH OPPORTUNITY"
    }
    elseif (
        $proof -ge 55 -and
        $gap -ge 60 -and
        $homeScore -ge 60
    ) {
        $launchVerdict = "PROMISING"
    }
    elseif ($proof -lt 40) {
        $launchVerdict = "INSUFFICIENT PROOF"
    }
    else {
        $launchVerdict = "WATCH"
    }

    $feed += [PSCustomObject]@{
        rank                = $item.rank

        opportunity         = $item.opportunity
        category            = $item.category
        source_cluster      = $item.source_cluster

        # Legacy V21
        final_score         = $item.final_score
        verdict             = $item.verdict
        action              = $item.action
        confidence          = $item.confidence
        replication         = $item.replication
        competition_gap     = $item.competition_gap
        geographic_gap      = $item.geographic_gap
        market_proof        = $item.market_proof
        geographic_proof    = $item.geographic_proof
        proof_level         = $item.proof_level

        company_count       = $item.company_count
        country_count       = $item.country_count
        article_count       = $item.article_count

        companies           = @($item.companies)
        countries           = @($item.countries)

        why                 = $item.why
        source_articles     = @($item.source_articles)
        signals             = @($item.signals)
        evidence_status     = $item.evidence_status

        # V22
        proof_score         = $proof
        gap_score           = $gap
        home_score          = $homeScore
        capital_score       = $capital
        automation_score    = $automation
        launch_score        = $launch
        opportunity_score   = $opportunityScore
        launch_verdict      = $launchVerdict
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
    Set-Content .\radar22_opportunities.json -Encoding UTF8

Write-Host ""
Write-Host "Output : .\radar22_opportunities.json"
Write-Host ""

$feed |
    Select-Object rank,opportunity,opportunity_score,proof_score,gap_score,home_score,capital_score,automation_score,launch_verdict |
    Format-Table -AutoSize

Write-Host ""
Write-Host "========================================"
Write-Host " Radar 22 completed"
Write-Host "========================================"




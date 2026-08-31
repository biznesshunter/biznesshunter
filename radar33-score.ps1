Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 33"
Write-Host " PASSIVE FIT"
Write-Host "========================================"
Write-Host ""

$raw = Get-Content .\radar32_client_opportunities.json -Raw | ConvertFrom-Json
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

    $automation = [double]$item.automation_score
    $solo       = [double]$item.solo_score
    $capital    = [double]$item.capital_score
    $economics  = [double]$item.launch_economics
    $b2c        = [double]$item.b2c_score
    $proof      = [double]$item.proof_score
    $clientFit  = [double]$item.client_fit_score

    $text = @(
        $item.opportunity
        $item.category
        $item.source_cluster
        $item.why
    ) -join " "

    $text = $text.ToLower()

    # ========================================
    # 1. AUTOMATION FIT
    # ========================================

    $automationFit = $automation

    $highHumanDependency = @(
        "à domicile",
        "intervention",
        "dépannage",
        "réparation",
        "montage",
        "transport",
        "livraison",
        "promenade",
        "garde",
        "visite",
        "chantier",
        "nettoyage"
    )

    foreach ($keyword in $highHumanDependency) {
        if ($text -like "*$keyword*") {
            $automationFit -= 6
        }
    }

    $automationFit = Clamp-Score $automationFit

    # ========================================
    # 2. SOLO FIT
    # ========================================

    $soloFit = $solo

    $soloPenalty = @(
        "restaurant",
        "professionnel",
        "artisan",
        "chantier",
        "transport",
        "livraison",
        "intervention",
        "à domicile"
    )

    foreach ($keyword in $soloPenalty) {
        if ($text -like "*$keyword*") {
            $soloFit -= 4
        }
    }

    $soloFit = Clamp-Score $soloFit

    # ========================================
    # 3. PASSIVITY
    # ========================================

    $passivity = (
        ($automationFit * 0.40) +
        ($soloFit * 0.25) +
        ($capital * 0.15) +
        ($economics * 0.10) +
        ($b2c * 0.10)
    )

    # Modèles intrinsèquement plus passifs
    $passiveKeywords = @(
        "location",
        "réservation",
        "plateforme",
        "marketplace",
        "mise en relation",
        "en ligne",
        "online",
        "saas",
        "software"
    )

    foreach ($keyword in $passiveKeywords) {
        if ($text -like "*$keyword*") {
            $passivity += 5
        }
    }

    $passivity = Clamp-Score $passivity

    # ========================================
    # 4. HUMAN DEPENDENCY PENALTY
    # ========================================

    $humanPenalty = 0

    $veryHuman = @(
        "à domicile",
        "intervention",
        "réparation",
        "dépannage",
        "montage",
        "transport",
        "livraison",
        "garde",
        "promenade",
        "visite"
    )

    foreach ($keyword in $veryHuman) {
        if ($text -like "*$keyword*") {
            $humanPenalty += 5
        }
    }

    if ($humanPenalty -gt 30) {
        $humanPenalty = 30
    }

    $passivity = Clamp-Score ($passivity - $humanPenalty)

    # ========================================
    # 5. FINAL PASSIVE BUSINESS FIT
    # ========================================

    $passiveBusinessFit = (
        ($clientFit * 0.35) +
        ($passivity * 0.40) +
        ($proof * 0.15) +
        ($economics * 0.10)
    )

    # ========================================
    # HARD CAPS
    # ========================================

    # Une idée sans preuve ne peut pas être excellente
    if ($proof -eq 0) {
        $passiveBusinessFit = [math]::Min($passiveBusinessFit, 39)
    }
    elseif ($proof -lt 20) {
        $passiveBusinessFit = [math]::Min($passiveBusinessFit, 49)
    }

    # Très faible automatisation = pas de business passif
    if ($automation -lt 40) {
        $passiveBusinessFit = [math]::Min($passiveBusinessFit, 59)
    }

    $passiveBusinessFit = Clamp-Score $passiveBusinessFit

    # ========================================
    # VERDICT
    # ========================================

    if (
        $proof -ge 70 -and
        $clientFit -ge 70 -and
        $passivity -ge 75 -and
        $passiveBusinessFit -ge 75
    ) {
        $verdict = "PASSIVE CANDIDATE"
    }
    elseif (
        $proof -ge 60 -and
        $passivity -ge 65 -and
        $passiveBusinessFit -ge 65
    ) {
        $verdict = "STRONG PASSIVE FIT"
    }
    elseif (
        $proof -ge 50 -and
        $passivity -ge 50 -and
        $passiveBusinessFit -ge 55
    ) {
        $verdict = "PARTIAL PASSIVE FIT"
    }
    elseif (
        $passivity -ge 40
    ) {
        $verdict = "ACTIVE BUSINESS"
    }
    else {
        $verdict = "HUMAN INTENSIVE"
    }

    $feed += [PSCustomObject]@{

        rank                   = $item.rank
        opportunity            = $item.opportunity
        category               = $item.category
        source_cluster         = $item.source_cluster

        passive_business_fit   = $passiveBusinessFit
        passive_verdict        = $verdict

        client_fit_score       = $clientFit
        passivity_score        = $passivity
        automation_fit         = $automationFit
        solo_fit               = $soloFit
        human_dependency       = $humanPenalty

        automation_score       = $automation
        solo_score             = $solo
        capital_score          = $capital
        launch_economics       = $economics
        b2c_score              = $b2c
        proof_score            = $proof

        company_count          = $item.company_count
        article_count          = $item.article_count
        confidence             = $item.confidence

        companies              = @($item.companies)
        countries              = @($item.countries)
        why                    = $item.why
        source_articles        = @($item.source_articles)
        signals                = @($item.signals)
    }
}

# ========================================
# SORT
# ========================================

$feed = @(
    $feed |
    Sort-Object passive_business_fit -Descending
)

for ($i = 0; $i -lt $feed.Count; $i++) {
    $feed[$i].rank = $i + 1
}

# ========================================
# OUTPUT
# ========================================

$feed |
    ConvertTo-Json -Depth 20 |
    Set-Content .\radar33_passive_opportunities.json -Encoding UTF8

Write-Host ""
Write-Host "Output : .\radar33_passive_opportunities.json"
Write-Host ""

$feed |
    Select-Object `
        rank,
        opportunity,
        passive_business_fit,
        passive_verdict,
        client_fit_score,
        passivity_score,
        automation_fit,
        solo_fit,
        human_dependency |
    Format-Table -AutoSize

Write-Host ""
Write-Host "========================================"
Write-Host " Radar 33 completed"
Write-Host "========================================"

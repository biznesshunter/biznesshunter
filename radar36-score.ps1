Write-Host ""
Write-Host "========================================"
Write-Host " BiznessHunter - Radar 36"
Write-Host " DUPLICABILITY FIT"
Write-Host "========================================"
Write-Host ""

$raw = Get-Content .\radar35_business_opportunities.json -Raw | ConvertFrom-Json
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
    $business   = [double]$item.business_quality_score
    $passivity  = [double]$item.passivity_score
    $automation = [double]$item.automation_score
    $solo       = [double]$item.solo_score
    $capital    = [double]$item.capital_score
    $economics  = [double]$item.launch_economics
    $confidence = [double]$item.confidence

    $text = @(
        $item.opportunity
        $item.category
        $item.source_cluster
        $item.why
    ) -join " "

    $text = $text.ToLower()

    # ========================================
    # 1. LOW-CAPITAL DUPLICABILITY
    # ========================================

    $capitalFit = (
        ($capital * 0.45) +
        ($economics * 0.35) +
        ($automation * 0.20)
    )

    $expensive = @(
        "restaurant",
        "hôtel",
        "hotel",
        "commerce",
        "magasin",
        "atelier",
        "garage",
        "clinique",
        "construction",
        "chantier",
        "véhicule",
        "véhicules",
        "équipement lourd",
        "entrepôt",
        "warehouse"
    )

    foreach ($keyword in $expensive) {
        if ($text -like "*$keyword*") {
            $capitalFit -= 7
        }
    }

    $capitalFit = Clamp-Score $capitalFit

    # ========================================
    # 2. OPERATIONAL SIMPLICITY
    # ========================================

    $operationalFit = (
        ($automation * 0.35) +
        ($solo * 0.30) +
        ($passivity * 0.20) +
        ($confidence * 0.15)
    )

    $humanHeavy = @(
        "à domicile",
        "intervention",
        "dépannage",
        "réparation",
        "montage",
        "transport",
        "livraison",
        "garde",
        "promenade",
        "visite",
        "chantier",
        "nettoyage"
    )

    foreach ($keyword in $humanHeavy) {
        if ($text -like "*$keyword*") {
            $operationalFit -= 5
        }
    }

    $operationalFit = Clamp-Score $operationalFit

    # ========================================
    # 3. GEOGRAPHIC REPLICABILITY
    # ========================================

    $geographicFit = 70

    $localDependency = @(
        "à domicile",
        "local",
        "locale",
        "transport",
        "livraison",
        "chantier",
        "intervention",
        "nettoyage",
        "réparation",
        "restaurant",
        "magasin"
    )

    foreach ($keyword in $localDependency) {
        if ($text -like "*$keyword*") {
            $geographicFit -= 5
        }
    }

    $replicableKeywords = @(
        "plateforme",
        "marketplace",
        "mise en relation",
        "location",
        "réservation",
        "booking",
        "en ligne",
        "online",
        "digital",
        "software",
        "saas"
    )

    foreach ($keyword in $replicableKeywords) {
        if ($text -like "*$keyword*") {
            $geographicFit += 5
        }
    }

    $geographicFit = Clamp-Score $geographicFit

    # ========================================
    # 4. TESTABILITY
    # ========================================

    $testability = (
        ($capitalFit * 0.35) +
        ($operationalFit * 0.30) +
        ($geographicFit * 0.20) +
        ($confidence * 0.15)
    )

    # Possibilité de tester avant de construire une grosse structure
    $easyTestKeywords = @(
        "location",
        "réservation",
        "plateforme",
        "mise en relation",
        "en ligne",
        "online",
        "à la demande",
        "marketplace"
    )

    foreach ($keyword in $easyTestKeywords) {
        if ($text -like "*$keyword*") {
            $testability += 4
        }
    }

    $testability = Clamp-Score $testability

    # ========================================
    # 5. REGULATORY / COMPLEXITY RISK
    # ========================================

    $risk = 20

    $riskKeywords = @(
        "vétérinaire",
        "clinique",
        "véhicule",
        "véhicules",
        "transport",
        "enfant",
        "crèche",
        "restaurant",
        "construction",
        "chantier",
        "professionnel",
        "artisan"
    )

    foreach ($keyword in $riskKeywords) {
        if ($text -like "*$keyword*") {
            $risk += 6
        }
    }

    if ($risk -gt 80) {
        $risk = 80
    }

    $regulatoryFit = 100 - $risk
    $regulatoryFit = Clamp-Score $regulatoryFit

    # ========================================
    # 6. FINAL DUPLICABILITY
    # ========================================

    $duplicability = (
        ($capitalFit * 0.25) +
        ($operationalFit * 0.20) +
        ($geographicFit * 0.20) +
        ($testability * 0.20) +
        ($regulatoryFit * 0.15)
    )

    # ========================================
    # 7. FINAL REPRODUCTION SCORE
    # ========================================

    $replicationScore = (
        ($business * 0.45) +
        ($duplicability * 0.35) +
        ($proof * 0.20)
    )

    # ========================================
    # HARD PROOF CAPS
    # ========================================

    if ($proof -eq 0) {
        $replicationScore = [math]::Min($replicationScore, 39)
    }
    elseif ($proof -lt 20) {
        $replicationScore = [math]::Min($replicationScore, 49)
    }
    elseif ($proof -lt 40) {
        $replicationScore = [math]::Min($replicationScore, 59)
    }

    $duplicability = Clamp-Score $duplicability
    $replicationScore = Clamp-Score $replicationScore

    # ========================================
    # VERDICT
    # ========================================

    if (
        $proof -ge 70 -and
        $replicationScore -ge 75 -and
        $duplicability -ge 70
    ) {
        $verdict = "REPLICATION CANDIDATE"
    }
    elseif (
        $proof -ge 60 -and
        $replicationScore -ge 65
    ) {
        $verdict = "STRONG REPLICATION FIT"
    }
    elseif (
        $proof -ge 40 -and
        $replicationScore -ge 55
    ) {
        $verdict = "POSSIBLE REPLICATION"
    }
    elseif ($replicationScore -ge 40) {
        $verdict = "DIFFICULT"
    }
    else {
        $verdict = "REJECT"
    }

    $feed += [PSCustomObject]@{

        rank                    = $item.rank
        opportunity             = $item.opportunity
        category                = $item.category
        source_cluster          = $item.source_cluster

        replication_score       = $replicationScore
        replication_verdict     = $verdict

        duplicability_score     = $duplicability
        capital_fit             = $capitalFit
        operational_fit         = $operationalFit
        geographic_fit          = $geographicFit
        testability             = $testability
        regulatory_fit          = $regulatoryFit

        business_quality_score  = $business
        proof_score              = $proof
        passivity_score          = $passivity
        automation_score        = $automation
        solo_score               = $solo
        capital_score            = $capital
        launch_economics         = $economics
        confidence               = $confidence

        companies                = @($item.companies)
        countries                = @($item.countries)
        why                      = $item.why
        source_articles          = @($item.source_articles)
        signals                  = @($item.signals)
    }
}

# ========================================
# SORT
# ========================================

$feed = @(
    $feed |
    Sort-Object replication_score -Descending
)

for ($i = 0; $i -lt $feed.Count; $i++) {
    $feed[$i].rank = $i + 1
}

# ========================================
# OUTPUT
# ========================================

$feed |
    ConvertTo-Json -Depth 20 |
    Set-Content .\radar36_replication_opportunities.json -Encoding UTF8

Write-Host ""
Write-Host "Output : .\radar36_replication_opportunities.json"
Write-Host ""

$feed |
    Select-Object `
        rank,
        opportunity,
        replication_score,
        replication_verdict,
        duplicability_score,
        capital_fit,
        operational_fit,
        geographic_fit,
        testability,
        regulatory_fit |
    Format-Table -AutoSize

Write-Host ""
Write-Host "========================================"
Write-Host " Radar 36 completed"
Write-Host "========================================"

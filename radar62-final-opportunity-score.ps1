$data = Get-Content .\radar61_opportunity_ranking.json -Raw | ConvertFrom-Json

$result = foreach ($item in @($data)) {

    $proof = [int]$item.max_proof_score
    $sources = [int]$item.source_count
    $countries = [int]$item.country_count
    $cities = [int]$item.city_count
    $observations = [int]$item.observation_count
    $liveUrls = [int]$item.live_url_count

    # =========================================
    # 1. PROOF COMPONENT — /30
    # =========================================

    $proofComponent = 0

    if ($proof -ge 90) {
        $proofComponent = 30
    }
    elseif ($proof -ge 75) {
        $proofComponent = 25
    }
    elseif ($proof -ge 65) {
        $proofComponent = 22
    }
    elseif ($proof -ge 50) {
        $proofComponent = 18
    }
    elseif ($proof -ge 30) {
        $proofComponent = 12
    }
    else {
        $proofComponent = 5
    }

    # Bonus diversité
    if ($sources -ge 3) {
        $proofComponent += 2
    }

    if ($countries -ge 3) {
        $proofComponent += 2
    }

    if ($cities -ge 20) {
        $proofComponent += 1
    }

    if ($proofComponent -gt 35) {
        $proofComponent = 35
    }

    # =========================================
    # 2. DEMAND / TRACTION SIGNAL — /20
    # =========================================

    $demandComponent = 0

    if ($observations -ge 150) {
        $demandComponent = 20
    }
    elseif ($observations -ge 100) {
        $demandComponent = 17
    }
    elseif ($observations -ge 60) {
        $demandComponent = 14
    }
    elseif ($observations -ge 40) {
        $demandComponent = 11
    }
    elseif ($observations -ge 20) {
        $demandComponent = 8
    }
    else {
        $demandComponent = 4
    }

    # =========================================
    # 3. REPLICATION SIGNAL — /20
    # =========================================

    $replicationComponent = 0

    if ($countries -ge 3) {
        $replicationComponent += 12
    }
    elseif ($countries -eq 2) {
        $replicationComponent += 8
    }
    elseif ($countries -eq 1) {
        $replicationComponent += 4
    }

    if ($cities -ge 20) {
        $replicationComponent += 8
    }
    elseif ($cities -ge 10) {
        $replicationComponent += 6
    }
    elseif ($cities -ge 5) {
        $replicationComponent += 4
    }
    else {
        $replicationComponent += 2
    }

    # =========================================
    # 4. BUSINESS MODEL SIMPLICITY — /15
    # =========================================

    # Heuristique temporaire basée sur la catégorie.
    # Elle sera remplacée par de vraies données
    # économiques/comportementales dans les versions suivantes.

    $simplicityComponent = 0

    switch -Regex ($item.category) {

        "location_" {
            $simplicityComponent = 13
        }

        "promenade_chien" {
            $simplicityComponent = 11
        }

        "garde_chat" {
            $simplicityComponent = 11
        }

        "menage_" {
            $simplicityComponent = 10
        }

        default {
            $simplicityComponent = 8
        }
    }

    # =========================================
    # 5. AUTOMATION / SOLO POTENTIAL — /10
    # =========================================

    $automationComponent = 0

    switch -Regex ($item.category) {

        "location_" {
            $automationComponent = 9
        }

        "garde_chat" {
            $automationComponent = 7
        }

        "promenade_chien" {
            $automationComponent = 6
        }

        "menage_" {
            $automationComponent = 6
        }

        default {
            $automationComponent = 5
        }
    }

    # =========================================
    # TOTAL
    # =========================================

    $finalScore =
        $proofComponent +
        $demandComponent +
        $replicationComponent +
        $simplicityComponent +
        $automationComponent

    if ($finalScore -gt 100) {
        $finalScore = 100
    }

    # =========================================
    # CLASSIFICATION
    # =========================================

    if ($finalScore -ge 85) {
        $status = "EXCEPTIONAL"
    }
    elseif ($finalScore -ge 75) {
        $status = "HIGH_PRIORITY"
    }
    elseif ($finalScore -ge 65) {
        $status = "PROMISING"
    }
    elseif ($finalScore -ge 50) {
        $status = "WATCH"
    }
    else {
        $status = "REJECT"
    }

    # =========================================
    # CONFIDENCE
    # =========================================

    if ($sources -ge 3 -and $countries -ge 3 -and $cities -ge 15) {
        $confidence = "HIGH"
    }
    elseif ($sources -ge 2 -and $countries -ge 2) {
        $confidence = "MEDIUM"
    }
    else {
        $confidence = "LOW"
    }

    [PSCustomObject]@{

        idea_name = $item.idea_name
        category = $item.category

        final_score = [int]$finalScore
        status = $status
        confidence = $confidence

        proof_component = [int]$proofComponent
        demand_component = [int]$demandComponent
        replication_component = [int]$replicationComponent
        simplicity_component = [int]$simplicityComponent
        automation_component = [int]$automationComponent

        max_proof_score = $proof
        observation_count = $observations
        source_count = $sources
        country_count = $countries
        city_count = $cities
        live_url_count = $liveUrls

        countries = @($item.countries)
        sources = @($item.sources)
        cities = @($item.cities)
    }
}

# =========================================
# SAVE
# =========================================

$result |
    Sort-Object final_score -Descending |
    ConvertTo-Json -Depth 20 |
    Set-Content .\radar62_final_opportunity_score.json -Encoding UTF8

# =========================================
# DISPLAY
# =========================================

Write-Host ""
Write-Host "========================================="
Write-Host "RADAR 62 - FINAL OPPORTUNITY SCORE"
Write-Host "========================================="
Write-Host ""

Write-Host "Opportunités : $($result.Count)"
Write-Host ""

Write-Host "STATUT :"

$result |
    Group-Object status |
    Select-Object Name,Count |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Host ""
Write-Host "TOP OPPORTUNITÉS :"
Write-Host ""

$result |
    Sort-Object final_score -Descending |
    Select-Object -First 15 `
        idea_name,
        final_score,
        status,
        confidence,
        proof_component,
        demand_component,
        replication_component,
        simplicity_component,
        automation_component |
    Format-Table -AutoSize

Write-Host ""
Write-Host "========================================="
Write-Host "Fichier créé : radar62_final_opportunity_score.json"
Write-Host "========================================="
Write-Host ""

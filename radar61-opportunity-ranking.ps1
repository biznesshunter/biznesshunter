$data = Get-Content .\radar60_proof_score.json -Raw | ConvertFrom-Json

# =========================================
# RADAR 61 - OPPORTUNITY RANKING
# =========================================

$groups = $data | Group-Object category

$result = foreach ($group in $groups) {

    $items = @($group.Group)

    $countries = @(
        $items |
        ForEach-Object { $_.country } |
        Where-Object { $_ } |
        Sort-Object -Unique
    )

    $sources = @(
        $items |
        ForEach-Object { @($_.sources) } |
        Where-Object { $_ } |
        Sort-Object -Unique
    )

    $cities = @(
        $items |
        ForEach-Object { @($_.cities) } |
        Where-Object { $_ } |
        Sort-Object -Unique
    )

    $observations = (
        $items |
        Measure-Object observation_count -Sum
    ).Sum

    $maxProof = (
        $items |
        Measure-Object proof_score -Maximum
    ).Maximum

    $liveUrls = (
        $items |
        Measure-Object live_url_count -Sum
    ).Sum

    $urlCount = (
        $items |
        Measure-Object url_count -Sum
    ).Sum

    $sourceCount = $sources.Count
    $countryCount = $countries.Count
    $cityCount = $cities.Count

    # =========================================
    # REPLICATION SIGNAL
    # =========================================

    $replicationScore = 0

    # Preuve
    if ($maxProof -ge 80) {
        $replicationScore += 30
    }
    elseif ($maxProof -ge 60) {
        $replicationScore += 20
    }
    elseif ($maxProof -ge 40) {
        $replicationScore += 10
    }

    # Diversité des marchés
    if ($countryCount -ge 3) {
        $replicationScore += 25
    }
    elseif ($countryCount -ge 2) {
        $replicationScore += 15
    }
    elseif ($countryCount -ge 1) {
        $replicationScore += 5
    }

    # Diversité des sources
    if ($sourceCount -ge 3) {
        $replicationScore += 20
    }
    elseif ($sourceCount -ge 2) {
        $replicationScore += 12
    }
    elseif ($sourceCount -ge 1) {
        $replicationScore += 5
    }

    # Couverture géographique
    if ($cityCount -ge 20) {
        $replicationScore += 15
    }
    elseif ($cityCount -ge 10) {
        $replicationScore += 10
    }
    elseif ($cityCount -ge 5) {
        $replicationScore += 5
    }

    # URLs réellement accessibles
    if ($liveUrls -ge 2) {
        $replicationScore += 10
    }
    elseif ($liveUrls -eq 1) {
        $replicationScore += 5
    }

    if ($replicationScore -gt 100) {
        $replicationScore = 100
    }

    # =========================================
    # OPPORTUNITY STATUS
    # =========================================

    if ($replicationScore -ge 80) {
        $opportunityStatus = "HIGH_PRIORITY"
    }
    elseif ($replicationScore -ge 60) {
        $opportunityStatus = "PROMISING"
    }
    elseif ($replicationScore -ge 40) {
        $opportunityStatus = "WATCH"
    }
    else {
        $opportunityStatus = "LOW_PRIORITY"
    }

    # =========================================
    # REPRESENTATIVE IDEA NAME
    # =========================================

    $ideaName = (
        $items |
        Sort-Object observation_count -Descending |
        Select-Object -First 1
    ).idea_name

    [PSCustomObject]@{

        idea_name = $ideaName
        category  = $group.Name

        countries = $countries
        country_count = $countryCount

        source_count = $sourceCount
        sources = $sources

        city_count = $cityCount
        cities = $cities

        observation_count = [int]$observations

        url_count = [int]$urlCount
        live_url_count = [int]$liveUrls

        max_proof_score = [int]$maxProof

        replication_score = [int]$replicationScore
        opportunity_status = $opportunityStatus
    }
}

# =========================================
# SAVE
# =========================================

$result |
    Sort-Object replication_score -Descending |
    ConvertTo-Json -Depth 20 |
    Set-Content .\radar61_opportunity_ranking.json -Encoding UTF8

# =========================================
# DISPLAY
# =========================================

Write-Host ""
Write-Host "========================================="
Write-Host "RADAR 61 - OPPORTUNITY RANKING"
Write-Host "========================================="
Write-Host ""

Write-Host "Opportunités : $($result.Count)"
Write-Host ""

Write-Host "STATUT :"

$result |
    Group-Object opportunity_status |
    Select-Object Name,Count |
    Sort-Object Name |
    Format-Table -AutoSize

Write-Host ""
Write-Host "TOP OPPORTUNITÉS :"
Write-Host ""

$result |
    Sort-Object replication_score -Descending |
    Select-Object -First 20 `
        idea_name,
        replication_score,
        opportunity_status,
        country_count,
        source_count,
        city_count,
        max_proof_score,
        live_url_count |
    Format-Table -AutoSize

Write-Host ""
Write-Host "========================================="
Write-Host "Fichier créé : radar61_opportunity_ranking.json"
Write-Host "========================================="
Write-Host ""
